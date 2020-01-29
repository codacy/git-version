require "file_utils"

require "semantic_version"

module GitVersion
  extend self

  BASE_VERISON_STRING = "0.0.0"
  BASE_VERISON        = SemanticVersion.parse(BASE_VERISON_STRING)

  DEV_BRANCH_SUFFIX = "SNAPSHOT"

  MAJOR_BUMP_COMMENT = "breaking:"
  MINOR_BUMP_COMMENT = "feature:"

  class Git
    def initialize(@dev_branch : String, @release_branch : String = "master", @patch_cmd : (String | Nil) = nil, @folder = FileUtils.pwd)
      #
    end

    private def attemptExec(cmd, ver)
      if cmd
        puts cmd.gsub("<version>", ver)
        Process.run(
          command: cmd.gsub("<version>", ver),
          shell: true,
          output: Process::Redirect::Close,
          error: Process::Redirect::Close,
          chdir: @folder
        ).success?
      else
        false
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

      latest_version = BASE_VERISON

      branch_tags.each do |tag|
        begin
          current_tag = SemanticVersion.parse(tag)
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
        prerelease = [cb.downcase.gsub(/[^a-zA-Z0-9]/, ""), current_commit_hash()] of String | Int32
        latest_version =
          SemanticVersion.new(
            latest_version.major,
            latest_version.minor,
            latest_version.patch,
            SemanticVersion::Prerelease.new(prerelease),
            nil
          )
      end

      while attemptExec(@patch_cmd, latest_version.to_s)
        latest_version =
          SemanticVersion.new(
            latest_version.major,
            latest_version.minor,
            latest_version.patch + 1,
            latest_version.prerelease,
            latest_version.build,
          )
      end

      return latest_version.to_s
    end
  end
end