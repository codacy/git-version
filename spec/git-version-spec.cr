require "spec"
require "file_utils"
require "./utils"

require "../src/git-version"

include Utils
describe GitVersion do
  it "should get the correct version in master and dev branch" do
    tmp = InTmp.new

    begin
      git = GitVersion::Git.new("dev", "master", tmp.@tmpdir)

      tmp.exec %(git init)
      tmp.exec %(git checkout -b #{git.release_branch})
      tmp.exec %(git commit --no-gpg-sign --allow-empty -m "1")
      tmp.exec %(git tag "1.0.0")

      version = git.get_new_version

      version.should eq("1.0.1")

      tmp.exec %(git checkout -b dev)
      tmp.exec %(git commit --no-gpg-sign --allow-empty -m "2")

      tag_on_master = git.tags_by_branch("#{git.release_branch}")

      tag_on_master.should eq(["1.0.0"])

      current_branch = git.current_branch_or_tag

      current_branch.should eq("#{git.dev_branch}")

      hash = git.current_commit_hash

      version = git.get_new_version

      version.should eq("1.0.1-SNAPSHOT.1.#{hash}")

      tmp.exec %(git checkout -b feature-branch)
      tmp.exec %(touch file2.txt)
      tmp.exec %(git add file2.txt)
      tmp.exec %(git commit --no-gpg-sign -m "new file2.txt")
    ensure
      tmp.cleanup
    end
  end

  it "should get the correct version feature branch" do
    tmp = InTmp.new

    begin
      tmp.exec %(git init)
      tmp.exec %(git checkout -b master)
      tmp.exec %(git commit --no-gpg-sign --allow-empty -m "1")
      tmp.exec %(git tag "1.0.0")

      tmp.exec %(git checkout -b my-fancy.branch)
      tmp.exec %(git commit --no-gpg-sign --allow-empty -m "2")

      git = GitVersion::Git.new("dev", "master", tmp.@tmpdir)

      hash = git.current_commit_hash

      version = git.get_new_version

      version.should eq("1.0.1-myfancybranch.1.#{hash}")
    ensure
      tmp.cleanup
    end
  end

  it "should properly bump the version" do
    tmp = InTmp.new

    begin
      tmp.exec %(git init)
      tmp.exec %(git checkout -b master)
      tmp.exec %(git commit --no-gpg-sign --allow-empty -m "1")
      tmp.exec %(git tag "1.0.0")

      tmp.exec %(git checkout -b dev)

      git = GitVersion::Git.new("dev", "master", tmp.@tmpdir)

      tmp.exec %(git commit --no-gpg-sign --allow-empty -m "breaking: XYZ")

      hash = git.current_commit_hash

      version = git.get_new_version

      version.should eq("2.0.0-SNAPSHOT.1.#{hash}")

      tmp.exec %(git commit --no-gpg-sign --allow-empty -m "breaking: XYZ")

      hash = git.current_commit_hash

      version = git.get_new_version

      version.should eq("2.0.0-SNAPSHOT.2.#{hash}")

      tmp.exec %(git commit --no-gpg-sign --allow-empty -m "feature: XYZ")

      hash = git.current_commit_hash

      version = git.get_new_version

      version.should eq("2.0.0-SNAPSHOT.3.#{hash}")
    ensure
      tmp.cleanup
    end
  end

  it "bump on master after merging in various ways" do
    tmp = InTmp.new

    begin
      git = GitVersion::Git.new("dev", "master", tmp.@tmpdir)

      tmp.exec %(git init)
      tmp.exec %(git checkout -b master)
      tmp.exec %(git commit --no-gpg-sign --allow-empty -m "1")
      tmp.exec %(git tag "1.0.0")

      tmp.exec %(git checkout -b my-fancy.branch)
      tmp.exec %(git commit --no-gpg-sign --allow-empty -m "2")

      tmp.exec %(git commit --no-gpg-sign --allow-empty -m "breaking: XYZ")

      tmp.exec %(git checkout master)

      version = git.get_new_version

      version.should eq("1.0.1")

      tmp.exec %(git merge my-fancy.branch)

      version = git.get_new_version

      version.should eq("2.0.0")

      tmp.exec %(git tag "2.0.0")

      tmp.exec %(git checkout -b my-fancy.branch2)
      tmp.exec %(git commit --no-gpg-sign --allow-empty -m "breaking: ABC")
      tmp.exec %(git checkout master)

      version = git.get_new_version

      version.should eq("2.0.1")

      tmp.exec %(git merge --ff-only my-fancy.branch2)

      version = git.get_new_version

      version.should eq("3.0.0")

      tmp.exec %(git tag "3.0.0")

      tmp.exec %(git checkout -b my-fancy.branch3)
      tmp.exec %(git commit --no-gpg-sign --allow-empty -m "feature: 123")
      tmp.exec %(git checkout master)

      version = git.get_new_version

      version.should eq("3.0.1")

      tmp.exec %(git merge --no-gpg-sign --no-ff my-fancy.branch3)

      version = git.get_new_version

      version.should eq("3.1.0")
    ensure
      tmp.cleanup
    end
  end

  it "correct version on feature after second commit" do
    tmp = InTmp.new

    begin
      git = GitVersion::Git.new("dev", "master", tmp.@tmpdir)

      tmp.exec %(git init)
      tmp.exec %(git checkout -b master)
      tmp.exec %(git commit --no-gpg-sign --allow-empty -m "1")
      tmp.exec %(git tag "1.0.0")

      tmp.exec %(# Checkout to dev)
      tmp.exec %(git checkout -b dev)

      # Checkout to FT-1111 from dev and add a commit)
      tmp.exec %(git checkout -b FT-1111)
      tmp.exec %(git commit --no-gpg-sign --allow-empty -m "3")
      tmp.exec %(git commit --no-gpg-sign --allow-empty -m "4")

      hash = git.current_commit_hash

      version = git.get_new_version

      version.should eq("1.0.1-ft1111.2.#{hash}")
    ensure
      tmp.cleanup
    end
  end

  it "should retrieve correct first version on master" do
    tmp = InTmp.new

    begin
      git = GitVersion::Git.new("dev", "master", tmp.@tmpdir)

      tmp.exec %(git init)
      tmp.exec %(git checkout -b master)
      tmp.exec %(git commit --no-gpg-sign --allow-empty -m "1")

      version = git.get_new_version

      version.should eq("0.0.1")
    ensure
      tmp.cleanup
    end
  end

  it "version properly after 5th commit" do
    tmp = InTmp.new

    begin
      git = GitVersion::Git.new("dev", "master", tmp.@tmpdir)

      tmp.exec %(git init)
      tmp.exec %(git checkout -b master)
      tmp.exec %(git commit --no-gpg-sign --allow-empty -m "1")
      tmp.exec %(git commit --no-gpg-sign --allow-empty -m "2")
      tmp.exec %(git tag "1.1.0")
      tmp.exec %(git commit --no-gpg-sign --allow-empty -m "3")
      tmp.exec %(git tag "1.2.0")
      tmp.exec %(git commit --no-gpg-sign --allow-empty -m "4")
      tmp.exec %(git commit --no-gpg-sign --allow-empty -m "5")

      version = git.get_new_version

      version.should eq("1.2.1")
    ensure
      tmp.cleanup
    end
  end

  it "version properly with concurrent features" do
    tmp = InTmp.new

    begin
      git = GitVersion::Git.new("dev", "master", tmp.@tmpdir)

      tmp.exec %(git init)
      tmp.exec %(git checkout -b master)
      tmp.exec %(git commit --no-gpg-sign --allow-empty -m "1")
      tmp.exec %(git tag "1.0.0")
      tmp.exec %(git checkout -b feature1)
      tmp.exec %(git commit --no-gpg-sign --allow-empty -m "feature: 2")
      hash = git.current_commit_hash
      version = git.get_new_version
      version.should eq("1.1.0-feature1.1.#{hash}")

      tmp.exec %(git checkout master)
      tmp.exec %(git checkout -b feature2)
      tmp.exec %(git commit --no-gpg-sign --allow-empty -m "breaking: 3")
      hash = git.current_commit_hash
      version = git.get_new_version
      version.should eq("2.0.0-feature2.1.#{hash}")

      tmp.exec %(git checkout master)
      tmp.exec %(git merge feature2)
      version = git.get_new_version
      version.should eq("2.0.0")
      tmp.exec %(git tag "2.0.0")

      tmp.exec %(git checkout -b feature3)
      tmp.exec %(git commit --no-gpg-sign --allow-empty -m "4")
      hash = git.current_commit_hash
      version = git.get_new_version
      version.should eq("2.0.1-feature3.1.#{hash}")

      tmp.exec %(git checkout master)
      tmp.exec %(git merge --no-gpg-sign feature1)
      version = git.get_new_version
      version.should eq("2.1.0")
      tmp.exec %(git tag "2.1.0")

      tmp.exec %(git merge --no-gpg-sign feature3)
      version = git.get_new_version
      version.should eq("2.1.1")
      tmp.exec %(git tag "2.1.1")
    ensure
      tmp.cleanup
    end
  end

  it "version releases with rebase from master" do
    tmp = InTmp.new

    begin
      git = GitVersion::Git.new("dev", "master", tmp.@tmpdir)

      tmp.exec %(git init)
      tmp.exec %(git checkout -b master)
      tmp.exec %(git commit --no-gpg-sign --allow-empty -m "1")
      tmp.exec %(git tag "1.0.0")
      tmp.exec %(git checkout -b dev)
      tmp.exec %(git commit --no-gpg-sign --allow-empty -m "2")
      hash = git.current_commit_hash
      version = git.get_new_version
      version.should eq("1.0.1-SNAPSHOT.1.#{hash}")

      tmp.exec %(git checkout -b myfeature)
      tmp.exec %(git commit --no-gpg-sign --allow-empty -m "3")
      tmp.exec %(git checkout dev)
      tmp.exec %(git merge myfeature)

      tmp.exec %(git checkout master)
      tmp.exec %(git rebase --no-gpg-sign dev)
      version = git.get_new_version
      version.should eq("1.0.1")
    ensure
      tmp.cleanup
    end
  end

  it "bump version only once in presence of merge commit message" do
    tmp = InTmp.new

    begin
      git = GitVersion::Git.new("dev", "master", tmp.@tmpdir)

      tmp.exec %(git init)
      tmp.exec %(git checkout -b master)
      tmp.exec %(git commit --no-gpg-sign --allow-empty -m "1")
      tmp.exec %(git tag "1.0.0")
      tmp.exec %(git checkout -b dev)
      tmp.exec %(git commit --no-gpg-sign --allow-empty -m "breaking: 2")

      tmp.exec %(git checkout master)
      tmp.exec %(git commit --no-gpg-sign --allow-empty -m "3")

      tmp.exec %(git checkout dev)
      tmp.exec %(git commit --no-gpg-sign --allow-empty -m "4")
      tmp.exec %(git rebase --no-gpg-sign master)

      tmp.exec %(git checkout master)
      tmp.exec %(git merge --no-gpg-sign --no-ff dev)
      # e.g. commit added when merging by bitbucket, no easy way to produce it automatically...
      tmp.exec %(git commit --no-gpg-sign --allow-empty -m "Merged xyz (123) breaking:")

      version = git.get_new_version
      version.should eq("2.0.0")
    ensure
      tmp.cleanup
    end
  end

  it "when in master should not consider pre-release versions for major bumps" do
    tmp = InTmp.new

    begin
      git = GitVersion::Git.new("dev", "master", tmp.@tmpdir)

      tmp.exec %(git init)
      tmp.exec %(git checkout -b master)
      tmp.exec %(git commit --no-gpg-sign --allow-empty -m "1")
      tmp.exec %(git tag "1.0.0")
      tmp.exec %(git checkout -b dev)
      tmp.exec %(git commit --no-gpg-sign --allow-empty -m "breaking: 2")

      version = git.get_new_version
      hash = git.current_commit_hash
      tmp.exec %(git tag "#{version}")
      version.should eq("2.0.0-SNAPSHOT.1.#{hash}")

      tmp.exec %(git checkout master)
      tmp.exec %(git merge --no-gpg-sign --no-ff dev)

      version = git.get_new_version
      version.should eq("2.0.0")
    ensure
      tmp.cleanup
    end
  end

  it "when in master should not consider pre-release versions for minor bumps" do
    tmp = InTmp.new

    begin
      git = GitVersion::Git.new("dev", "master", tmp.@tmpdir)

      tmp.exec %(git init)
      tmp.exec %(git checkout -b master)
      tmp.exec %(git commit --no-gpg-sign --allow-empty -m "1")
      tmp.exec %(git tag "1.0.0")
      tmp.exec %(git checkout -b dev)
      tmp.exec %(git commit --no-gpg-sign --allow-empty -m "2")

      version = git.get_new_version
      hash = git.current_commit_hash
      tmp.exec %(git tag "#{version}")
      version.should eq("1.0.1-SNAPSHOT.1.#{hash}")

      tmp.exec %(git checkout master)
      tmp.exec %(git merge --no-gpg-sign --no-ff dev)

      version = git.get_new_version
      version.should eq("1.0.1")
    ensure
      tmp.cleanup
    end
  end

  it "bump properly major and reset minor" do
    tmp = InTmp.new

    begin
      git = GitVersion::Git.new("dev", "master", tmp.@tmpdir)

      tmp.exec %(git init)
      tmp.exec %(git checkout -b master)
      tmp.exec %(git commit --no-gpg-sign --allow-empty -m "1")
      tmp.exec %(git tag "0.1.0")
      tmp.exec %(git commit --no-gpg-sign --allow-empty -m ":breaking: 2")

      version = git.get_new_version
      version.should eq("1.0.0")
    ensure
      tmp.cleanup
    end
  end

  it "should bump the breaking even with a pre-release tag" do
    tmp = InTmp.new

    begin
      git = GitVersion::Git.new("dev", "master", tmp.@tmpdir)

      tmp.exec %(git init)
      tmp.exec %(git checkout -b master)
      tmp.exec %(git commit --no-gpg-sign --allow-empty -m "1")
      tmp.exec %(git tag "0.1.0")
      tmp.exec %(git commit --no-gpg-sign --allow-empty -m "feature: 2")
      tmp.exec %(git tag "0.2.0-asd")
      tmp.exec %(git commit --no-gpg-sign --allow-empty -m ":breaking: 2")

      version = git.get_new_version
      version.should eq("1.0.0")
    ensure
      tmp.cleanup
    end
  end

  it "should bump the breaking even without any other tag" do
    tmp = InTmp.new

    begin
      git = GitVersion::Git.new("dev", "master", tmp.@tmpdir)

      tmp.exec %(git init)
      tmp.exec %(git checkout -b master)
      tmp.exec %(git commit --no-gpg-sign --allow-empty -m "breaking: 1")

      version = git.get_new_version
      version.should eq("1.0.0")
    ensure
      tmp.cleanup
    end
  end

  it "should fallback to tag detection if in detached HEAD(on a tag)" do
    tmp = InTmp.new

    begin
      git = GitVersion::Git.new("dev", "master", tmp.@tmpdir)

      tmp.exec %(git init)
      tmp.exec %(git checkout -b master)
      tmp.exec %(git commit --no-gpg-sign --allow-empty -m "breaking: 1")
      tmp.exec %(git tag v1)
      tmp.exec %(git checkout v1)

      version = git.get_new_version
      hash = git.current_commit_hash
      version.should eq("1.0.0-v1.1.#{hash}")
    ensure
      tmp.cleanup
    end
  end

  it "should properly manage prefixes" do
    tmp = InTmp.new

    begin
      git = GitVersion::Git.new("dev", "master", tmp.@tmpdir, "v")

      tmp.exec %(git init)
      tmp.exec %(git checkout -b master)
      tmp.exec %(git commit --no-gpg-sign --allow-empty -m "feature: 1")
      tmp.exec %(git tag "v1.1.0")
      tmp.exec %(git commit --no-gpg-sign --allow-empty -m "2")

      version = git.get_new_version
      version.should eq("v1.1.1")
    ensure
      tmp.cleanup
    end
  end

  it "non-prefixed tags should be ignored if prefix is enabled" do
    tmp = InTmp.new

    begin
      git = GitVersion::Git.new("dev", "master", tmp.@tmpdir, "v")

      tmp.exec %(git init)
      tmp.exec %(git checkout -b master)
      tmp.exec %(git commit --no-gpg-sign --allow-empty -m "1")
      tmp.exec %(git tag "1.0.0")

      version = git.get_new_version
      version.should eq("v0.0.1")
    ensure
      tmp.cleanup
    end
  end

  it "should properly manage a tag with only prefix" do
    tmp = InTmp.new

    begin
      git = GitVersion::Git.new("dev", "master", tmp.@tmpdir, "v")

      tmp.exec %(git init)
      tmp.exec %(git checkout -b master)
      tmp.exec %(git commit --no-gpg-sign --allow-empty -m "1")
      tmp.exec %(git tag "v")

      version = git.get_new_version
      version.should eq("v0.0.1")
    ensure
      tmp.cleanup
    end
  end

  it "should count the commits distance" do
    tmp = InTmp.new

    begin
      git = GitVersion::Git.new("dev", "master", tmp.@tmpdir)

      tmp.exec %(git init)
      tmp.exec %(git checkout -b master)
      tmp.exec %(git checkout -b v1)
      tmp.exec %(git commit --no-gpg-sign --allow-empty -m "breaking: 1")
      tmp.exec %(git commit --no-gpg-sign --allow-empty -m "breaking: 2")
      tmp.exec %(git commit --no-gpg-sign --allow-empty -m "breaking: 3")

      version = git.get_new_version
      hash = git.current_commit_hash
      version.should eq("1.0.0-v1.3.#{hash}")
    ensure
      tmp.cleanup
    end
  end

  it "ignore non log-path filtered breaking messages" do
    tmp = InTmp.new

    begin
      git = GitVersion::Git.new("dev", "master", tmp.@tmpdir, "", "dir2/")

      tmp.exec %(git init)
      tmp.exec %(git checkout -b master)
      tmp.exec %(git checkout -b v1)
      tmp.exec %(git commit --no-gpg-sign --allow-empty -m "1")
      # Create dir1 and tag 1.0.0
      tmp.exec %(mkdir dir1 && touch dir1/dummy_file)
      tmp.exec %(git add dir1/)
      tmp.exec %(git commit --no-gpg-sign -m "breaking: 2")
      tmp.exec %(git tag "1.0.0")
      # Create dir2 and commit
      tmp.exec %(mkdir dir2 && touch dir2/dummy_file)
      tmp.exec %(git add dir2/)
      tmp.exec %(git commit --no-gpg-sign -m "3")

      # git-version on dir2 should ignore tag on commit with dir1
      version = git.get_new_version
      hash = git.current_commit_hash
      version.should eq("1.0.1-v1.1.#{hash}")
    ensure
      tmp.cleanup
    end
  end

  it "ignore log-path filtered breaking messages with multiple paths" do
    tmp = InTmp.new

    begin
      git = GitVersion::Git.new("dev", "master", tmp.@tmpdir, "", "dir1/ dir3/")

      tmp.exec %(git init)
      tmp.exec %(git checkout -b master)
      # Create dir1 and tag 1.0.0
      base_dir = "dir1"
      tmp.exec %(mkdir #{base_dir} && touch #{base_dir}/dummy_file)
      tmp.exec %(git add #{base_dir}/)
      tmp.exec %(git commit --no-gpg-sign -m "breaking: 1")
      tmp.exec %(git tag "1.0.0")

      tmp.exec %(git checkout -b dev)
      # Create dir2 and commit breaking (to be ignored)
      base_dir = "dir2"
      tmp.exec %(mkdir #{base_dir} && touch #{base_dir}/dummy_file)
      tmp.exec %(git add #{base_dir}/)
      tmp.exec %(git commit --no-gpg-sign -m "breaking: 2")

      # Create dir3 and commit non-breaking
      base_dir = "dir3"
      tmp.exec %(mkdir #{base_dir} && touch #{base_dir}/dummy_file)
      tmp.exec %(git add #{base_dir}/)
      tmp.exec %(git commit --no-gpg-sign -m "3")

      tmp.exec %(git checkout master)
      tmp.exec %(git merge --no-gpg-sign --no-ff dev)

      # git-version should ignore the breaking tag on commit with dir2
      version = git.get_new_version
      version.should eq("1.0.1")
    ensure
      tmp.cleanup
    end
  end

  it "accept log-path filtered breaking messages with multiple paths" do
    tmp = InTmp.new

    begin
      git = GitVersion::Git.new("dev", "master", tmp.@tmpdir, "", "dir2/ dir3/")

      tmp.exec %(git init)
      tmp.exec %(git checkout -b master)
      # Create dir1 and tag 1.0.0
      base_dir = "dir1"
      tmp.exec %(mkdir #{base_dir} && touch #{base_dir}/dummy_file)
      tmp.exec %(git add #{base_dir}/)
      tmp.exec %(git commit --no-gpg-sign -m "breaking: 1")
      tmp.exec %(git tag "1.0.0")

      tmp.exec %(git checkout -b dev)
      # Create dir2 and commit breaking
      base_dir = "dir2"
      tmp.exec %(mkdir #{base_dir} && touch #{base_dir}/dummy_file)
      tmp.exec %(git add #{base_dir}/)
      tmp.exec %(git commit --no-gpg-sign -m "breaking: 2")
      # Create dir3 and commit non-breaking
      base_dir = "dir3"
      tmp.exec %(mkdir #{base_dir} && touch #{base_dir}/dummy_file)
      tmp.exec %(git add #{base_dir}/)
      tmp.exec %(git commit --no-gpg-sign -m "3")

      tmp.exec %(git checkout master)
      tmp.exec %(git merge --no-gpg-sign --no-ff dev)

      # git-version should accept the breaking tag on commit with dir2
      version = git.get_new_version
      version.should eq("2.0.0")
    ensure
      tmp.cleanup
    end
  end

  it "accept breaking messages if part of the log-path filter" do
    tmp = InTmp.new

    begin
      git = GitVersion::Git.new("dev", "master", tmp.@tmpdir, "", "dir1/")

      tmp.exec %(git init)
      tmp.exec %(git checkout -b master)
      tmp.exec %(git checkout -b v1)
      tmp.exec %(git commit --no-gpg-sign --allow-empty -m "1")
      tmp.exec %(git tag "1.0.0")

      tmp.exec %(mkdir dir1 && touch dir1/dummy_file)
      tmp.exec %(git add dir1/)
      tmp.exec %(git commit --no-gpg-sign -m "breaking: 2")

      version = git.get_new_version
      hash = git.current_commit_hash
      version.should eq("2.0.0-v1.1.#{hash}")
    ensure
      tmp.cleanup
    end
  end

  it "monorepo log-path filter (multiple dirs, multiple prefixes)" do
    tmp = InTmp.new

    begin
      git = GitVersion::Git.new("dev", "master", tmp.@tmpdir, "dir2-", "dir2/ dir3/")

      tmp.exec %(git init)
      tmp.exec %(git checkout -b master)

      # Create dir1 and tag dir1-1.0.0
      base_dir = "dir1"
      tmp.exec %(mkdir #{base_dir} && touch #{base_dir}/dummy_file)
      tmp.exec %(git add #{base_dir}/)
      tmp.exec %(git commit --no-gpg-sign -m "breaking: 1")
      tmp.exec %(git tag "dir1-1.0.0")

      # Create dir2 and tag dir2-1.0.0
      base_dir = "dir2"
      tmp.exec %(mkdir #{base_dir} && touch #{base_dir}/dummy_file)
      tmp.exec %(git add #{base_dir}/)
      tmp.exec %(git commit --no-gpg-sign -m "breaking: 2")
      tmp.exec %(git tag "dir2-1.0.0")

      tmp.exec %(git checkout -b dev)

      # Create dir2 and commit breaking
      base_dir = "dir2"
      tmp.exec %(mkdir -p #{base_dir} && touch #{base_dir}/dummy_file_2)
      tmp.exec %(git add #{base_dir}/)
      tmp.exec %(git commit --no-gpg-sign -m "breaking: 3")

      # git-version should accept the breaking tag on commit with dir2
      version = git.get_new_version
      hash = git.current_commit_hash
      version.should eq("dir2-2.0.0-SNAPSHOT.1.#{hash}")
    ensure
      tmp.cleanup
    end
  end
end

it "get latest version - first commit" do
  tmp = InTmp.new

  begin
    git = GitVersion::Git.new("dev", "master", tmp.@tmpdir)

    tmp.exec %(git init)
    tmp.exec %(git checkout -b master)
    tmp.exec %(git commit --no-gpg-sign --allow-empty -m "1")


    # git-version should accept the breaking tag on commit with dir2
    version = git.get_latest_version
    hash = git.current_commit_hash
    version.should eq("0.0.0")
  ensure
    tmp.cleanup
  end
end

it "get latest version - first commit w/ prefix" do
  tmp = InTmp.new

  begin
    git = GitVersion::Git.new("dev", "master", tmp.@tmpdir, "v")

    tmp.exec %(git init)
    tmp.exec %(git checkout -b master)
    tmp.exec %(git commit --no-gpg-sign --allow-empty -m "1")

    # git-version should accept the breaking tag on commit with dir2
    version = git.get_latest_version
    hash = git.current_commit_hash
    version.should eq("v0.0.0")
  ensure
    tmp.cleanup
  end
end

it "get latest version - pre-tagged" do
  tmp = InTmp.new

  begin
    git = GitVersion::Git.new("dev", "master", tmp.@tmpdir, "v")

    tmp.exec %(git init)
    tmp.exec %(git checkout -b master)
    tmp.exec %(git commit --no-gpg-sign --allow-empty -m "1")
    tmp.exec %(git tag "v1.0.0")

    # git-version should accept the breaking tag on commit with dir2
    version = git.get_latest_version
    hash = git.current_commit_hash
    version.should eq("v1.0.0")
  ensure
    tmp.cleanup
  end
end
