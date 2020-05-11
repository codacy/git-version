require "file_utils"

require "semantic_version"

module GitVersion
  extend self

  BASE_VERSION_STRING = "0.0.0"
  BASE_VERSION        = SemanticVersion.parse(BASE_VERSION_STRING)

  DEV_BRANCH_SUFFIX = "SNAPSHOT"

  MAJOR_BUMP_COMMENT = "breaking:"
  MINOR_BUMP_COMMENT = "feature:"

  class Git
    def initialize(@dev_branch : String, @release_branch : String = "master", @folder = FileUtils.pwd, @prefix : String = "")
      #
    end

    private def add_prefix(version : String) : String
      return "#{@prefix}#{version}"
    end

    private def strip_prefix(version : String) : String | Nil
      stripped = version.lstrip(@prefix)
      if @prefix != "" && stripped.size >= version.size
        nil
      else
        stripped
      end
    end

    private def exec(cmd)
      strout = IO::Memory.new

      if !Process.run(
           command: cmd,
           shell: true,
           output: strout,
           error: Process::Redirect::Close,
           chdir: @folder
         ).success?
        raise "[ERROR] Command #{cmd} failed."
      end

      return strout.to_s.split('\n', remove_empty: true)
    end

    def dev_branch
      return @dev_branch
    end

    def release_branch
      return @release_branch
    end

    def tags_by_branch(branch)
      return exec "git tag --merged #{branch}"
    end

    def current_branch_or_tag
      return (exec "git symbolic-ref --short HEAD")[0]
    rescue
      return (exec "git describe --tags")[0]
    end

    def current_commit_hash : String
      cmd = "git rev-parse --verify HEAD --short"
      return (exec cmd)[0].rjust(7, '0')
    end

    def commits_distance
      return (exec "git rev-list --count HEAD ^#{@dev_branch}")[0]
    rescue
      begin
        return (exec "git rev-list --count HEAD ^#{@release_branch}")[0]
      rescue
        return 0
      end
    end

    def get_bumps(latest)
      latest_exists = (exec "git tag -l #{latest}")
      if latest_exists.any?
        last_commit = (exec "git show-ref -s #{latest}")[0]
        return (exec "git log --pretty=%B #{last_commit}..HEAD")
      else
        return (exec "git log --pretty=%B")
      end
    rescue
      return [] of String
    end

    def get_version
      cb = current_branch_or_tag

      branch_tags = tags_by_branch(cb)

      latest_version = BASE_VERSION

      branch_tags.each do |tag|
        begin
          tag_without_prefix = strip_prefix(tag)
          if tag_without_prefix.nil?
            next
          end
          current_tag = SemanticVersion.parse(tag_without_prefix)
          if !current_tag.prerelease.identifiers.empty?
            next
          elsif (latest_version < current_tag)
            latest_version = current_tag
          end
        rescue
          #
        end
      end

      latest_tagged_version = latest_version

      latest_version =
        SemanticVersion.new(
          latest_version.major,
          latest_version.minor,
          latest_version.patch + 1,
          nil,
          nil,
        )

      major = false
      get_bumps(latest_tagged_version).each do |bump|
        commit = bump.downcase
        if commit.includes?(MAJOR_BUMP_COMMENT)
          latest_version =
            SemanticVersion.new(
              latest_version.major + 1,
              0,
              0,
              latest_version.prerelease,
              latest_version.build,
            )
          major = true
          break
        end
      end

      if !major
        get_bumps(latest_tagged_version).each do |bump|
          commit = bump.downcase
          if commit.includes?(MINOR_BUMP_COMMENT)
            latest_version =
              SemanticVersion.new(
                latest_version.major,
                latest_version.minor + 1,
                0,
                latest_version.prerelease,
                latest_version.build,
              )
            break
          end
        end
      end

      if cb == @release_branch
        #
      elsif cb == @dev_branch
        prerelease = [DEV_BRANCH_SUFFIX, current_commit_hash()] of String | Int32
        latest_version =
          SemanticVersion.new(
            latest_version.major,
            latest_version.minor,
            latest_version.patch,
            SemanticVersion::Prerelease.new(prerelease),
            nil
          )
      else
        branch_sanitized_name = cb.downcase.gsub(/[^a-zA-Z0-9]/, "")
        prerelease = [branch_sanitized_name, commits_distance(), current_commit_hash()] of String | Int32
        latest_version =
          SemanticVersion.new(
            latest_version.major,
            latest_version.minor,
            latest_version.patch,
            SemanticVersion::Prerelease.new(prerelease),
            nil
          )
      end

      return add_prefix(latest_version.to_s)
    end
  end
end
