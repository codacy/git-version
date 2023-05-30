# git-version

[![Codacy Badge](https://api.codacy.com/project/badge/Grade/c811f6b557ee4e44ad373084015ba0b3)](https://www.codacy.com/gh/codacy/git-version?utm_source=github.com&amp;utm_medium=referral&amp;utm_content=codacy/git-version&amp;utm_campaign=Badge_Grade)
[![CircleCI](https://circleci.com/gh/codacy/git-version.svg?style=svg)](https://circleci.com/gh/codacy/git-version)
[![](https://images.microbadger.com/badges/version/codacy/git-version.svg)](https://microbadger.com/images/codacy/git-version "Get your own version badge on microbadger.com")

The goal of this tool is to have a simple versioning system that we can use to track the different releases. The tool prints the current version (e.g. to be used for tagging) depending on the git history and commit messages.

The versioning scheme is assumed to be __Semver__ based.

## Usage

```yaml
# .github/workflows/version.yml
name: Git Version

on:
  push:
    branches:
      - master

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout Code
        uses: actions/checkout@v3
        with:
          ref: ${{ github.head_ref }}   # checkout the correct branch name
          fetch-depth: 0                # fetch the whole repo history

      - name: Git Version
        id: version
        uses: codacy/git-version@2.7.1
      
      - name: Use the version
        run: |
          echo ${{ steps.version.outputs.version }}
      - name: Use the previous version
        run: |
          echo ${{ steps.version.outputs.previous-version }}
```

### Mono-Repo

You can use git-version to version different modules in a mono-repo structure.
This can be achieved by using different `prefixes` and `log-path` filters for
different modules.

Assuming the following directory structure, we can use git-version to generate
version with prefix `module1-x.x.x` for changes in the `module1/` directory
and  `module2-x.x.x` for changes in the `module2/` directory.

```sh
.
├── Dockerfile
├── Makefile
├── README.md
├── module1
│   ├── Dockerfile
│   └── src/
└── module2
    ├── Dockerfile
    └── src/
```

With github actions you can create different workflows that are triggered
when changes happen on different directories.

```yaml
# .github/workflows/module1.yml
name: Version Module 1

on:
  pull_request:
    paths:
      - .github/workflows/module1.yml
      - module1/**
  push:
    paths:
      - .github/workflows/module1.yml
      - module1/**
    branches:
      - master

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout Code
        uses: actions/checkout@v3
        with:
          ref: ${{ github.head_ref }}   # checkout the correct branch name
          fetch-depth: 0                # fetch the whole repo history

      - name: Git Version
        uses: codacy/git-version@2.5.4
        with:
          prefix: module1-
          log-path: module1/
```

```yaml
# .github/workflows/module2.yml
name: Version Module 2

on:
  pull_request:
    paths:
      - .github/workflows/module2.yml
      - module2/**
  push:
    paths:
      - .github/workflows/module2.yml
      - module2/**
    branches:
      - master

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout Code
        uses: actions/checkout@v3
        with:
          ref: ${{ github.head_ref }}   # checkout the correct branch name
          fetch-depth: 0                # fetch the whole repo history

      - name: Git Version
        uses: codacy/git-version@2.5.4
        with:
          prefix: module2-
          log-path: module2/
```

## Versioning Model

Creates a version with the format `MAJOR.MINOR.PATCH`

_To use this you need to be in the working dir of a git project:_
```
$ ./git-version
1.0.0
```

Versions are incremented since the last tag. The patch version is incremented by default, unless there is at least one commit since the last tag, containing a minor or major identifier (defaults to `feature:` or `breaking:`) in the message.

On branches other than the master/main and development branch (default to `master` and `dev`) the version is a variation of the latest common tag with the master/main branch, and has the following format:

`{MAJOR}.{MINOR}.{PATCH}-{sanitized-branch-name}.{commits-distance}.{hash}`

On the development branch the format is the following:

`{MAJOR}.{MINOR}.{PATCH}-SNAPSHOT.{hash}`

_Example:_
```
---A---B---C <= Master (tag: 1.0.1)        L <= Master (git-version: 1.0.2)
            \                             /
             D---E---F---G---H---I---J---K <= Foo (git-version: 1.0.2-foo.8.5e30d83)
```

_Example2 (with dev branch):_
```
---A---B---C <= Master (tag: 1.0.1)        L <= Master (git-version: 1.0.2)
            \                             / <= Fast-forward merges to master (same commit id)
             C                           L <= Dev (git-version: 1.0.2-SNAPSHOT.5e30d83)
              \                         /
               E---F---G---H---I---J---K <= Foo (new_version: 1.0.1-foo.7.5e30d83)
```

_Example3 (with breaking message):_
```
---A---B---C <= Master (tag: 1.0.1)        L <= Master (git-version: 2.0.0)
            \                             /
             D---E---F---G---H---I---J---K <= Foo (git-version: 2.0.0-foo.8.5e30d83)
                                         \\
                                         message: "breaking: removed api parameter"
```

### Configuration

You can configure the action with various inputs, a list of which has been provided below:

| Name             | Description                                                                                     | Default Value |
|------------------|-------------------------------------------------------------------------------------------------|---------------|
| tool-version     | The version of the tool to run                                                                  | latest        |
| release-branch   | The name of the master/main branch                                                              | master        |
| dev-branch       | The name of the development branch                                                              | dev           |
| minor-identifier | The string used to identify a minor release (wrap with '/' to match using a regular expression) | feature:      |
| major-identifier | The string used to identify a major release (wrap with '/' to match using a regular expression) | breaking:     |
| prefix           | The prefix used for the version name                                                            |               |
| log-paths        | The paths used to calculate changes (comma-separated)                                           |               |

## Requirements

To use this tool you will need to install a few dependencies:

Ubuntu:
```
sudo apt-get install \
  libevent-dev \
  git
```

Fedora:
```
sudo dnf -y install \
  libevent-devel \
  git
```

Alpine:
```
apk add --update --no-cache --force-overwrite \
  gc-dev pcre-dev libevent-dev \
  git
```

OsX:
```
brew install \
  libevent \
  git
```


## CircleCI

Use this image directly on CircleCI for simple steps

```
version: 2
jobs:
  build:
    machine: true
    working_directory: /app
    steps:
      - checkout
      - run:
          name: get new version
          command: |
            NEW_VERSION=$(docker run --rm -v $(pwd):/repo codacy/git-version)
            echo $NEW_VERSION
```

## Build and Publish

The pipeline in `circleci` can deploy this for you when the code is pushed to the remote.

To compile locally you need to install [crystal](https://crystal-lang.org/install/) and possibly [all required libraries](https://github.com/crystal-lang/crystal/wiki/All-required-libraries)

You can also run everything locally using the makefile.

To get the list of available commands:
```
$ make help
```

## Credits

Great inspiration for this tool has been taken from: [GitVersion](https://github.com/GitTools/GitVersion)

## What is Codacy

[Codacy](https://www.codacy.com/) is an Automated Code Review Tool that monitors your technical debt, helps you improve your code quality, teaches best practices to your developers, and helps you save time in Code Reviews.

### Among Codacy’s features

- Identify new Static Analysis issues
- Commit and Pull Request Analysis with GitHub, BitBucket/Stash, GitLab (and also direct git repositories)
- Auto-comments on Commits and Pull Requests
- Integrations with Slack, HipChat, Jira, YouTrack
- Track issues in Code Style, Security, Error Proneness, Performance, Unused Code and other categories

Codacy also helps keep track of Code Coverage, Code Duplication, and Code Complexity.

Codacy supports PHP, Python, Ruby, Java, JavaScript, and Scala, among others.

## Free for Open Source

Codacy is free for Open Source projects.

## License

git-version is available under the Apache 2 license. See the [LICENSE](./LICENSE) file for more info.
