# ci-git-version
[![Codacy Badge](https://api.codacy.com/project/badge/Grade/b6c44b6714ec4f289a548955130f1b1f)](https://www.codacy.com?utm_source=github.com&amp;utm_medium=referral&amp;utm_content=codacy/ci-git-version&amp;utm_campaign=Badge_Grade)
[![](https://images.microbadger.com/badges/version/codacy/ci-git-version.svg)](https://microbadger.com/images/codacy/ci-git-version "Get your own version badge on microbadger.com")

Git versioning used in Codacy.

The goal is to have a simple versioning system for our internal projects that we can use to track the different releases.

This tools returns a different version depending on your current HEAD and commit messages.

## Semver based Versioning Model

Creates a version with the format `MAJOR-MINOR-PATCH`

**To use this you need to be in the working dir of a git project:**
```
$ docker run -e TYPE=semver -v $(pwd):/repo codacy/ci-git-version
1.0.0
```

Versions are incremented in master. The patch version is incremented by default, unless there is at least one commit since the last tag, containing `feature:` or `breaking:` in the message.

On other branches the version is a variation of the latest common tag with master, and has the following format:

`MAJOR-MINOR-PATCH-{number-of-commits}-{hash}-{branch}`

*Example:*
```
---A---B---C <= Master (tag: 1.0.1)        L <= Master (new_version: 1.0.2)
            \                             /
             D---E---F---G---H---I---J---K <= Foo (new_version: 1.0.1-8-K.Foo)
```


*Example2 (with dev branch):*
```
---A---B---C <= Master (tag: 1.0.1)        L <= Master (new_version: 1.0.2)
            \                             / <= Fast-forward merges to master (same commit id)
             C                           L <= Dev (new_version: 1.0.1-8-L.Dev)
              \                         /
               E---F---G---H---I---J---K <= Foo (new_version: 1.0.1-7-K.Foo)
```

*Example3 (with breaking message):*
```
---A---B---C <= Master (tag: 1.0.1)        L <= Master (new_version: 2.0.0)
            \                             /
             D---E---F---G---H---I---J---K <= Foo (new_version: 1.0.1-8-K.Foo)
                                         \\
                                         message: "breaking: removed api parameter"
```


## Date based Versioning Model

Creates a version with the format `YYYY-MM-{incremental-number}`

**To use this you need to be in the working dir of a git project:**
```
$ docker run -v $(pwd):/repo codacy/ci-git-version
2018.08.1
```

The main version is only incremented on the master branch.
On other branches the version is a variation of the latest common tag with master, and has the following format:

`YYYY-MM-{incremental-number}-{number-of-commits}-{hash}-{branch}`

*Example:*
```
---A---B---C <= Master (tag: 2018.08.1)    L <= Master (new_version: 2018.08.2)
            \                             /
             D---E---F---G---H---I---J---K <= Foo (new_version: 2018.08.1-8-K.Foo)
```


*Example2 (with dev branch):*
```
---A---B---C <= Master (tag: 2018.08.1)    L <= Master (new_version: 2018.08.2)
            \                             / <= Fast-forward merges to master (same commit id)
             C                           L <= Dev (new_version: 2018.08.1-8-L.Dev)
              \                         /
               E---F---G---H---I---J---K <= Foo (new_version: 2018.08.1-7-K.Foo)
```

#### CircleCI

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
            NEW_VERSION=$(docker run -v $(pwd):/repo codacy/ci-git-version)
            echo $NEW_VERSION
```
# Build and Publish

The pipeline in `circleci` can deploy this for you when the code is pushed to the remote.

You can also run everything locally using the makefile
```
$ make help
---------------------------------------------------------------------------------------------------------
build and deploy help
---------------------------------------------------------------------------------------------------------
build                          build docker image
get-next-version-number        get next version number
git-tag                        tag the current commit with the next version and push
push-docker-image              push the docker image to the registry (DOCKER_USER and DOCKER_PASS mandatory)
push-latest-docker-image       push the docker image with the "latest" tag to the registry (DOCKER_USER and DOCKER_PASS mandatory)
```
