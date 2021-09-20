#!/bin/sh

set -f

# REPOS_CLEAN_NEVER - space separated list of repositories we should never run cleanup.
#   Each repo name can be expr-type regular expression
#   Example: REPOS_CLEAN_NEVER="public/.*-dotnet importantrepo .*/.*test"
: ${REPOS_CLEAN_NEVER:=""}

# TAGS_CLEAN_NEVER - space separated list of tags we should never run cleanup.
#   Each tag name can be expr-type regular expression
#   Example: TAGS_CLEAN_NEVER="latest .*-latest v[.0-9]*"
: ${TAGS_CLEAN_NEVER:="latest .*-latest v[.0-9]*"}

# TAGS_KEEP_N - how much images we should keep.
# This setting applies after TAGS_CLEAN_NEVER screening
: ${TAGS_KEEP_N:=10}

# TAGS_KEEP_SEC - never delete images created less than TAGS_KEEP_SEC seconds
# This setting applies after TAGS_KEEP_N screening
: ${TAGS_KEEP_SEC:=0}


: ${VOLUME:="/var/lib/registry"}
: ${CONFIG:="/etc/docker/registry/config.yml"}

REPO="${VOLUME}/docker/registry/v2/repositories/"
TIME_NOW=$(date +%s)

[[ "${DRY_RUN}" != "false" ]] && DRY_RUN=true

item_in_list() {
  local item="$1"
  local list="$2"

  for val in $list; do
    [[ `expr "X${item}X" : "X${val}X"` != '0' ]] && return 0;
  done
  return 1
}

prefly_checks() {
  $DRY_RUN && echo "Running in dry-run mode. Set env DRY_RUN=false to actually clean your repo"

  #Check registry dir
  if [ ! -d ${VOLUME} ]; then
    echo "VOLUME directory doesn't exist. VOLUME=${VOLUME}"
    exit 1
  fi

  if [ ! -d ${REPO} ]; then
    echo "Repository directory doesn't exist, nothing to clean. REPO=${REPO}"
    exit 1
  fi
}

print_summary() {
  if $DRY_RUN; then
    echo "DRY_RUN over"
  else
    echo "Disk usage before and after:"
    echo "${DF_BEFORE}"
    echo
    echo "${DF_AFTER}"
  fi
}

start_cleanup() {
  local repository

  # disk usage before run
  DF_BEFORE=$(df -Ph ${REPO})

  # Iterate repositories
  # Since there is could be namespaced ('user/image/') and non-namespaced paths ('image/')
  # we have to find _layers, _manifests or _uploads dirs and then normalise output
  REPOS=$(find ${REPO} -name _layers | sed "s:${REPO}::; s:/_layers::")
  for repository in ${REPOS}; do
    item_in_list "${repository}" "${REPOS_CLEAN_NEVER}" && echo "Skip ${repository} because of REPOS_CLEAN_NEVER" && continue
    echo "Processing repo ${repository}"
    process_repo "${repository}"
  done

  # Run registry garbage collector to delete orphaned layers
  if $DRY_RUN; then
    echo "Skip running in DRY_RUN mode 'registry garbage-collect ${CONFIG} --delete-untagged=true'"
  else
    echo "Running registry garbage-collect"
    registry garbage-collect ${CONFIG} --delete-untagged=true
  fi

  # disk usage after run
  DF_AFTER=$(df -Ph ${REPO})
}

process_repo() {
  local repository="$1"

  local repo_path="${REPO}${repository}"
  local num=0
  local tag

  echo ">> ${repo_path}"
  TAGS=$(cd ${repo_path}/_manifests/tags && ls -t)
  for tag in ${TAGS}; do
    local tag_path="${repo_path}/_manifests/tags/${tag}"

    # screen TAGS_CLEAN_NEVER
    item_in_list "${tag}" "${TAGS_CLEAN_NEVER}" && echo ". skip ${tag} because of TAGS_CLEAN_NEVER" && continue

    # screen TAGS_KEEP_N most recently created tags
    num=$(expr ${num} + 1)
    [ "${num}" -le "${TAGS_KEEP_N}" ] && echo ". skip ${tag} because of TAGS_KEEP_N (${num}/${TAGS_KEEP_N})" && continue

    # screen tags younger TAGS_KEEP_SEC seconds
    local timestamp=$(stat -c %Y ${tag_path})
    local age=$(expr ${TIME_NOW} - ${timestamp})
    [ "${age}" -le "${TAGS_KEEP_SEC}" ] && echo ". skip ${tag} because of TAGS_KEEP_SEC (${age} <= ${TAGS_KEEP_SEC})" && continue

    # actually delete tag
    if $DRY_RUN; then
      echo ". to be deleted ${tag} (DRY-RUN)"
    else
      echo ". deleting tag ${tag}"
      rm -rf ${tag_path}
    fi
  done
}

prefly_checks
start_cleanup
print_summary
