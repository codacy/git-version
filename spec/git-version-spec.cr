require "spec"
require "file_utils"
require "./utils"

require "../src/git-version"

include Utils
describe GitVersion do
  it "should get the correct version in master and dev branch" do
    tmp = InTmp.new

    git = GitVersion::Git.new("dev", tmp.@tmpdir)

    tmp.exec %(git init)
    tmp.exec %(git checkout -b master)
    tmp.exec %(git commit --no-gpg-sign --allow-empty --no-gpg-sign -m "1")
    tmp.exec %(git tag "1.0.0")

    version = git.get_version

    version.should eq("1.0.1")

    tmp.exec %(git checkout -b dev)
    tmp.exec %(git commit --no-gpg-sign --allow-empty --no-gpg-sign -m "2")

    tagOnMaster = git.tags_by_branch("master")

    tagOnMaster.should eq(["1.0.0"])

    current_branch = git.current_branch

    current_branch.should eq("dev")

    hash = git.current_commit_hash

    version = git.get_version

    version.should eq("1.0.1-SNAPSHOT.#{hash}")

    tmp.exec %(git checkout -b feature-branch)
    tmp.exec %(touch file2.txt)
    tmp.exec %(git add file2.txt)
    tmp.exec %(git commit --no-gpg-sign -m "new file2.txt")

    tmp.cleanup
  end

  it "should get the correct version feature branch" do
    tmp = InTmp.new

    tmp.exec %(git init)
    tmp.exec %(git checkout -b master)
    tmp.exec %(git commit --no-gpg-sign --allow-empty --no-gpg-sign -m "1")
    tmp.exec %(git tag "1.0.0")

    tmp.exec %(git checkout -b my-fancy.branch)
    tmp.exec %(git commit --no-gpg-sign --allow-empty --no-gpg-sign -m "2")

    git = GitVersion::Git.new("dev", tmp.@tmpdir)

    hash = git.current_commit_hash

    version = git.get_version

    version.should eq("1.0.1-myfancybranch.#{hash}")

    tmp.cleanup
  end

  it "should properly bump the version" do
    tmp = InTmp.new

    tmp.exec %(git init)
    tmp.exec %(git checkout -b master)
    tmp.exec %(git commit --no-gpg-sign --allow-empty --no-gpg-sign -m "1")
    tmp.exec %(git tag "1.0.0")

    tmp.exec %(git checkout -b dev)

    git = GitVersion::Git.new("dev", tmp.@tmpdir)

    tmp.exec %(git commit --no-gpg-sign --allow-empty --no-gpg-sign -m "breaking: XYZ")

    hash = git.current_commit_hash

    version = git.get_version

    version.should eq("2.0.0-SNAPSHOT.#{hash}")

    tmp.exec %(git commit --no-gpg-sign --allow-empty --no-gpg-sign -m "breaking: XYZ")

    hash = git.current_commit_hash

    version = git.get_version

    version.should eq("2.0.0-SNAPSHOT.#{hash}")

    tmp.exec %(git commit --no-gpg-sign --allow-empty --no-gpg-sign -m "feature: XYZ")

    hash = git.current_commit_hash

    version = git.get_version

    version.should eq("2.0.0-SNAPSHOT.#{hash}")

    tmp.cleanup
  end

  it "bump on master after merging in various ways" do
    tmp = InTmp.new

    git = GitVersion::Git.new("dev", tmp.@tmpdir)

    tmp.exec %(git init)
    tmp.exec %(git checkout -b master)
    tmp.exec %(git commit --no-gpg-sign --allow-empty --no-gpg-sign -m "1")
    tmp.exec %(git tag "1.0.0")

    tmp.exec %(git checkout -b my-fancy.branch)
    tmp.exec %(git commit --no-gpg-sign --allow-empty --no-gpg-sign -m "2")

    tmp.exec %(git commit --no-gpg-sign --allow-empty --no-gpg-sign -m "breaking: XYZ")

    tmp.exec %(git checkout master)

    version = git.get_version

    version.should eq("1.0.1")

    tmp.exec %(git merge my-fancy.branch)

    version = git.get_version

    version.should eq("2.0.0")

    tmp.exec %(git tag "2.0.0")

    tmp.exec %(git checkout -b my-fancy.branch2)
    tmp.exec %(git commit --no-gpg-sign --allow-empty --no-gpg-sign -m "breaking: ABC")
    tmp.exec %(git checkout master)

    version = git.get_version

    version.should eq("2.0.1")

    tmp.exec %(git merge --ff-only my-fancy.branch2)

    version = git.get_version

    version.should eq("3.0.0")

    tmp.exec %(git tag "3.0.0")

    tmp.exec %(git checkout -b my-fancy.branch3)
    tmp.exec %(git commit --no-gpg-sign --allow-empty --no-gpg-sign -m "feature: 123")
    tmp.exec %(git checkout master)

    version = git.get_version

    version.should eq("3.0.1")

    tmp.exec %(git merge --no-ff my-fancy.branch3)

    version = git.get_version

    version.should eq("3.1.0")

    tmp.cleanup
  end

  it "correct version on feature after second commit" do
    tmp = InTmp.new

    git = GitVersion::Git.new("dev", tmp.@tmpdir)

    tmp.exec %(git init)
    tmp.exec %(git checkout -b master)
    tmp.exec %(git commit --no-gpg-sign --allow-empty --no-gpg-sign -m "1")
    tmp.exec %(git tag "1.0.0")

    tmp.exec %(# Checkout to dev)
    tmp.exec %(git checkout -b dev)

    # Checkout to FT-1111 from dev and add a commit)
    tmp.exec %(git checkout -b FT-1111)
    tmp.exec %(git commit --no-gpg-sign --allow-empty --no-gpg-sign -m "3")
    tmp.exec %(git commit --no-gpg-sign --allow-empty --no-gpg-sign -m "4")

    hash = git.current_commit_hash

    version = git.get_version

    version.should eq("1.0.1-ft1111.#{hash}")

    tmp.cleanup
  end

  it "should retrieve correct first version on master" do
    tmp = InTmp.new

    git = GitVersion::Git.new("dev", tmp.@tmpdir)

    tmp.exec %(git init)
    tmp.exec %(git checkout -b master)
    tmp.exec %(git commit --no-gpg-sign --allow-empty --no-gpg-sign -m "1")

    version = git.get_version

    version.should eq("0.0.1")

    tmp.cleanup
  end

  it "version properly after 5th commit" do
    tmp = InTmp.new

    git = GitVersion::Git.new("dev", tmp.@tmpdir)

    tmp.exec %(git init)
    tmp.exec %(git checkout -b master)
    tmp.exec %(git commit --no-gpg-sign --allow-empty --no-gpg-sign -m "1")
    tmp.exec %(git commit --no-gpg-sign --allow-empty --no-gpg-sign -m "2")
    tmp.exec %(git tag "1.1.0")
    tmp.exec %(git commit --no-gpg-sign --allow-empty --no-gpg-sign -m "3")
    tmp.exec %(git tag "1.2.0")
    tmp.exec %(git commit --no-gpg-sign --allow-empty --no-gpg-sign -m "4")
    tmp.exec %(git commit --no-gpg-sign --allow-empty --no-gpg-sign -m "5")

    version = git.get_version

    version.should eq("1.2.1")

    tmp.cleanup
  end

  it "version properly with concurrent features" do
    tmp = InTmp.new

    git = GitVersion::Git.new("dev", tmp.@tmpdir)

    tmp.exec %(git init)
    tmp.exec %(git checkout -b master)
    tmp.exec %(git commit --no-gpg-sign --allow-empty --no-gpg-sign -m "1")
    tmp.exec %(git tag "1.0.0")
    tmp.exec %(git checkout -b feature1)
    tmp.exec %(git commit --no-gpg-sign --allow-empty --no-gpg-sign -m "feature: 2")
    hash = git.current_commit_hash
    version = git.get_version
    version.should eq("1.1.0-feature1.#{hash}")

    tmp.exec %(git checkout master)
    tmp.exec %(git checkout -b feature2)
    tmp.exec %(git commit --no-gpg-sign --allow-empty --no-gpg-sign -m "breaking: 3")
    hash = git.current_commit_hash
    version = git.get_version
    version.should eq("2.0.0-feature2.#{hash}")

    tmp.exec %(git checkout master)
    tmp.exec %(git merge feature2)
    version = git.get_version
    version.should eq("2.0.0")
    tmp.exec %(git tag "2.0.0")

    tmp.exec %(git checkout -b feature3)
    tmp.exec %(git commit --no-gpg-sign --allow-empty --no-gpg-sign -m "4")
    hash = git.current_commit_hash
    version = git.get_version
    version.should eq("2.0.1-feature3.#{hash}")

    tmp.exec %(git checkout master)
    tmp.exec %(git merge feature1)
    version = git.get_version
    version.should eq("2.1.0")
    tmp.exec %(git tag "2.1.0")

    tmp.exec %(git merge feature3)
    version = git.get_version
    version.should eq("2.1.1")
    tmp.exec %(git tag "2.1.1")

    tmp.cleanup
  end

  it "version releases with rebase from master" do
    tmp = InTmp.new

    git = GitVersion::Git.new("dev", tmp.@tmpdir)

    tmp.exec %(git init)
    tmp.exec %(git checkout -b master)
    tmp.exec %(git commit --no-gpg-sign --allow-empty --no-gpg-sign -m "1")
    tmp.exec %(git tag "1.0.0")
    tmp.exec %(git checkout -b dev)
    tmp.exec %(git commit --no-gpg-sign --allow-empty --no-gpg-sign -m "2")
    hash = git.current_commit_hash
    version = git.get_version
    version.should eq("1.0.1-SNAPSHOT.#{hash}")

    tmp.exec %(git checkout -b myfeature)
    tmp.exec %(git commit --no-gpg-sign --allow-empty --no-gpg-sign -m "3")
    tmp.exec %(git checkout dev)
    tmp.exec %(git merge myfeature)

    tmp.exec %(git checkout master)
    tmp.exec %(git rebase dev)
    version = git.get_version
    version.should eq("1.0.1")

    tmp.cleanup
  end

  it "bump version only once in presence of merge commit message" do
    tmp = InTmp.new

    git = GitVersion::Git.new("dev", tmp.@tmpdir)

    tmp.exec %(git init)
    tmp.exec %(git checkout -b master)
    tmp.exec %(git commit --no-gpg-sign --allow-empty --no-gpg-sign -m "1")
    tmp.exec %(git tag "1.0.0")
    tmp.exec %(git checkout -b dev)
    tmp.exec %(git commit --no-gpg-sign --allow-empty --no-gpg-sign -m "breaking: 2")

    tmp.exec %(git checkout master)
    tmp.exec %(git commit --no-gpg-sign --allow-empty --no-gpg-sign -m "3")

    tmp.exec %(git checkout dev)
    tmp.exec %(git commit --no-gpg-sign --allow-empty --no-gpg-sign -m "4")
    tmp.exec %(git rebase origin/master)

    tmp.exec %(git checkout master)
    tmp.exec %(git merge --no-ff dev)
    # e.g. commit added when merging by bitbucket, no easy way to produce it automatically...
    tmp.exec %(git commit --no-gpg-sign --allow-empty --no-gpg-sign -m "Merged xyz (123) breaking:")

    version = git.get_version
    version.should eq("2.0.0")

    tmp.cleanup
  end

  it "when in master should not consider pre-release versions for major bumps" do
    tmp = InTmp.new

    git = GitVersion::Git.new("dev", tmp.@tmpdir)

    tmp.exec %(git init)
    tmp.exec %(git checkout -b master)
    tmp.exec %(git commit --no-gpg-sign --allow-empty --no-gpg-sign -m "1")
    tmp.exec %(git tag "1.0.0")
    tmp.exec %(git checkout -b dev)
    tmp.exec %(git commit --no-gpg-sign --allow-empty --no-gpg-sign -m "breaking: 2")

    version = git.get_version
    hash = git.current_commit_hash
    tmp.exec %(git tag "#{version}")
    version.should eq("2.0.0-SNAPSHOT.#{hash}")

    tmp.exec %(git checkout master)
    tmp.exec %(git merge --no-ff dev)

    version = git.get_version
    version.should eq("2.0.0")

    tmp.cleanup
  end

  it "when in master should not consider pre-release versions for minor bumps" do
    tmp = InTmp.new

    git = GitVersion::Git.new("dev", tmp.@tmpdir)

    tmp.exec %(git init)
    tmp.exec %(git checkout -b master)
    tmp.exec %(git commit --no-gpg-sign --allow-empty --no-gpg-sign -m "1")
    tmp.exec %(git tag "1.0.0")
    tmp.exec %(git checkout -b dev)
    tmp.exec %(git commit --no-gpg-sign --allow-empty --no-gpg-sign -m "2")

    version = git.get_version
    hash = git.current_commit_hash
    tmp.exec %(git tag "#{version}")
    version.should eq("1.0.1-SNAPSHOT.#{hash}")

    tmp.exec %(git checkout master)
    tmp.exec %(git merge --no-ff dev)

    version = git.get_version
    version.should eq("1.0.1")

    tmp.cleanup
  end

end
