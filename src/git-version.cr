require "file_utils"

require "semantic_version"

module GitVersion
  extend self

  BASE_VERISON_STRING = "0.0.0"
  BASE_VERISON        = SemanticVersion.parse(BASE_VERISON_STRING)

  DEV_BRANCH_SUFFIX = "SNAPSHOT"

  MASTER_BRANCH = "master"

  MAJOR_BUMP_COMMENT = "breaking:"
  MINOR_BUMP_COMMENT = "feature:"

  class Git
    def initialize(@devBranch : String, @folder = FileUtils.pwd)
      #
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

    def tags_by_branch(branch)
      return exec "git tag --merged #{branch}"
    end

    def current_branch
      return (exec "git symbolic-ref --short HEAD")[0]
    end

    def current_commit_hash : String
      cmd = "git rev-parse --verify HEAD --short"
      return (exec cmd)[0].rjust(7, '0')
    end

    def get_bumps(latest)
      begin
        last_commit = (exec "git show-ref -s #{latest}")[0]
        return (exec "git log --pretty=%B #{last_commit}..HEAD")
      rescue
        return [] of String
      end
    end

    def get_version
      cb = current_branch

      branchTags = tags_by_branch(cb)

      latestVersion = BASE_VERISON

      branchTags.each do |tag|
        begin
          currentTag = SemanticVersion.parse(tag)
          if (latestVersion < currentTag)
            latestVersion = currentTag
          end
        rescue
          #
        end
      end

      latestTaggedVersion = latestVersion

      latestVersion =
        SemanticVersion.new(
          latestVersion.major,
          latestVersion.minor,
          latestVersion.patch + 1,
          nil,
          nil,
        )

      get_bumps(latestTaggedVersion).each do |bump|
        commit = bump.downcase
        if commit.includes?(MAJOR_BUMP_COMMENT)
          latestVersion =
            SemanticVersion.new(
              latestVersion.major + 1,
              latestVersion.minor,
              0,
              latestVersion.prerelease,
              latestVersion.build,
            )
        end

        if commit.includes?(MINOR_BUMP_COMMENT)
          latestVersion =
            SemanticVersion.new(
              latestVersion.major,
              latestVersion.minor + 1,
              0,
              latestVersion.prerelease,
              latestVersion.build,
            )
        end
      end

      if cb == MASTER_BRANCH
        #
      elsif cb == @devBranch
        latestVersion =
          SemanticVersion.new(
            latestVersion.major,
            latestVersion.minor,
            latestVersion.patch,
            "#{DEV_BRANCH_SUFFIX}.#{current_commit_hash()}",
            nil
          )
      else
        latestVersion =
          SemanticVersion.new(
            latestVersion.major,
            latestVersion.minor,
            latestVersion.patch,
            "#{cb.downcase.gsub(/[^a-zA-Z0-9]/, "")}.#{current_commit_hash()}",
            nil
          )
      end

      return latestVersion.to_s
    end
  end
end
