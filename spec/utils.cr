require "uuid"

module Utils
  extend self

  class InTmp
    # on Alpine last available crystal version is 0.26, this brings compatibility with 0.27
    TMP_DIR = {% if env("ALPINE") %} "/tmp" {% else %} Dir.tempdir {% end %}

    def initialize
      folder = UUID.random.to_s

      puts "folder #{folder}"

      @tmpdir = File.expand_path(folder, TMP_DIR)

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
