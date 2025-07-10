require "file_utils"

require "semantic_version"

module GitVersion
  extend self

  BASE_VERSION_STRING = "0.0.0"
  BASE_VERSION        = SemanticVersion.parse(BASE_VERSION_STRING)

  DEV_BRANCH_SUFFIX = "SNAPSHOT"

  class Git
    def initialize(@dev_branch : String, @release_branch : String, @minor_identifier : String, @major_identifier : String,
                   @folder = FileUtils.pwd, @prefix : String = "", @log_paths : String = "", @skip_prerelease : Bool = false)
      @major_id_is_regex = false
      @minor_id_is_regex = false
      if match = /\/(.*)\//.match(@major_identifier)
        @major_identifier = match[1]
        @major_id_is_regex = true
      end
      if match = /\/(.*)\//.match(@minor_identifier)
        @minor_identifier = match[1]
        @minor_id_is_regex = true
      end
      #
    end

    private def add_prefix(version : String) : String
      return "#{@prefix}#{version}"
    end

    private def strip_prefix(version : String) : String | Nil
      version.lchop?(@prefix)
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

    def log_paths_filter
      @log_paths.empty? ? "" : "-- #{@log_paths}"
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
      sha = (exec cmd)[0].strip
      return "sha." + sha
    end

    def current_commit_hash_without_prefix : String
      cmd = "git rev-parse --verify HEAD --short"
      return (exec cmd)[0].strip
    end

    def commits_distance(tag : String | Nil)
      if tag.nil?
        return (exec "git rev-list --count HEAD")[0]
      else
        return (exec "git rev-list --count HEAD ^#{tag}")[0]
      end
    rescue
      return 0
    end

    def get_commits_since(tag : String | Nil)
      if !tag.nil? && (exec "git tag -l #{tag}").any?
        last_commit = (exec "git show-ref -s #{tag}")[0]
        return (exec "git log --pretty=%B #{last_commit}..HEAD #{log_paths_filter}")
      else
        return (exec "git log --pretty=%B")
      end
    rescue
      return [] of String
    end

    def get_previous_tag_and_version : Tuple(String | Nil, SemanticVersion)
      cb = current_branch_or_tag

      branch_tags = tags_by_branch(cb)

      previous_version = BASE_VERSION
      previous_tag = nil

      branch_tags.each do |tag|
        begin
          tag_without_prefix = strip_prefix(tag)
          if tag_without_prefix.nil?
            next
          end
          current_version = SemanticVersion.parse(tag_without_prefix)
          if !current_version.prerelease.identifiers.empty?
            next
          elsif (previous_version < current_version)
            previous_version = current_version
            previous_tag = tag
          end
        rescue
          #
        end
      end
      return {previous_tag, previous_version}
    end

    def get_previous_version : String
      lt, lv = get_previous_tag_and_version
      return lt ? lt : add_prefix(lv.to_s)
    end

    def get_new_version
      previous_tag, previous_version = get_previous_tag_and_version

      previous_version =
        SemanticVersion.new(
          previous_version.major,
          previous_version.minor,
          previous_version.patch + 1,
          nil,
          nil,
        )

      major = false
      get_commits_since(previous_tag).each do |c|
        commit = c.downcase
        match = if @major_id_is_regex
          /^#{@major_identifier}/.match(commit)
        else
          /^#{@major_identifier}/.match(commit)
        end
        if match
          previous_version =
            SemanticVersion.new(
              previous_version.major + 1,
              0,
              0,
              previous_version.prerelease,
              previous_version.build,
            )
          major = true
          break
        end
      end

      if !major
        get_commits_since(previous_tag).each do |c|
          commit = c.downcase
          match = if @minor_id_is_regex
            /#{@minor_identifier}/.match(commit)
          else
            commit.includes?(@minor_identifier)
          end
          if match
            previous_version =
              SemanticVersion.new(
                previous_version.major,
                previous_version.minor + 1,
                0,
                previous_version.prerelease,
                previous_version.build,
              )
            break
          end
        end
      end

      cb = current_branch_or_tag

      if ! @skip_prerelease
        cb = current_branch_or_tag

        if cb == @release_branch
          #
          elsif cb == @dev_branch
          prerelease = [DEV_BRANCH_SUFFIX, commits_distance(previous_tag), current_commit_hash()] of String | Int32
          previous_version =
            SemanticVersion.new(
              previous_version.major,
              previous_version.minor,
              previous_version.patch,
              SemanticVersion::Prerelease.new(prerelease),
              nil
            )
        else
          branch_sanitized_name = cb.downcase.gsub(/[^a-zA-Z0-9]/, "")[0,30]
          prerelease = [branch_sanitized_name, commits_distance(previous_tag), current_commit_hash()] of String | Int32
          previous_version =
            SemanticVersion.new(
              previous_version.major,
              previous_version.minor,
              previous_version.patch,
              SemanticVersion::Prerelease.new(prerelease),
              nil
            )
        end
      end
      return add_prefix(previous_version.to_s)
    end

  end
end
