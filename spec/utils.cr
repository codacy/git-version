require "uuid"

module Utils
  extend self

  class InTmp
    def initialize
      folder = UUID.random.to_s

      puts "folder #{folder}"

      @tmpdir = File.expand_path(folder, Dir.tempdir)

      FileUtils.rm_rf(@tmpdir)
      FileUtils.mkdir(@tmpdir)
    end

    def exec(cmd)
      Process.run(
        command: cmd,
        shell: true,
        output: STDOUT,
        error: STDERR,
        chdir: @tmpdir
      ).success?
    end

    def cleanup
      FileUtils.rm_rf(@tmpdir)
    end
  end
end
