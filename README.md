# Docker registry cleaner

Docker registry side-car container. Designed to be run alongside with Registry container and clean unneeded tags and layers in periodic manner.

Cleaner runs on file system shared with Registry service. It search for tags to delete and then runs [registry garbage-collect](https://docs.docker.com/registry/garbage-collection/) to purge orphaned layers.

## Environment variables

| Variable          | Default value                 | Description                                                     |
|-------------------|-------------------------------|-----------------------------------------------------------------|
| DRY_RUN           | `"true"`                      | You have to explictly set DRY_RUN=false to actually delete tags |
| REPOS_CLEAN_NEVER | `""`                          | Space separated list of repositories we should never cleanup. Each repo name can be [expr-type regular expression](https://www.gnu.org/software/coreutils/manual/html_node/String-expressions.html). Example: `REPOS_CLEAN_NEVER="public/.*-dotnet importantrepo .*/.*test"` |
| TAGS_CLEAN_NEVER  | `"latest .*-latest v[.0-9]*"` | Space separated list of tags we should never cleanup. Each tag name can be [expr-type regular expression](https://www.gnu.org/software/coreutils/manual/html_node/String-expressions.html). Example: `TAGS_CLEAN_NEVER="latest .*-latest v[.0-9]*"` |
| TAGS_KEEP_N       | `10`                          | How much images we should keep. This setting applies after TAGS_CLEAN_NEVER screening |
| TAGS_KEEP_SEC     | `0`                           | Never delete images created less than TAGS_KEEP_SEC seconds. This setting applies after TAGS_KEEP_N screening |

## Acknowlegement

Inspired by blog post [Automate Docker Registry Cleanup](https://betterprogramming.pub/automate-docker-registry-cleanup-3a1af0aa1535) by Al-Waleed Shihadeh, some bits of scripts and logic used as well.

