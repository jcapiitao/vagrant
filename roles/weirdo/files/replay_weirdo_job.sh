#!/bin/bash

# Script to replay weirdo jobs run in CI
#
# example:
#       replay_weirdo_job.sh <weirdo_job_type> <scenario> <patch_number> <patch_set>
#       replay_weirdo_job.sh packstack 1 30357 11
#

BASE_LOG_URL="https://logserver.rdoproject.org"
CENTOS_VERS=8

help_usage() {
    echo "ERROR: syntax error."
    echo "     usage: replay_weirdo_job.sh [packstack|puppet] <scenario> <patch_number> [patch_set]"
    echo "Exemple:"
    echo "            replay_weirdo_job.sh packstack 1 30357"
    echo "            replay_weirdo_job.sh packstack 1 30357 11"
}

if [ $# -ne 3 ] && [ $# -ne 4 ]; then
    help_usage
    exit 1
fi

if [[ ! $1 == "packstack" ]] && [[ ! $1 == "puppet" ]]; then
    help_usage
    exit 1
fi

weirdo_job_type=$1
scenario=$2
patch_number=$3

check_utility() {
    if ! hash $1 2>/dev/null
    then
         echo "'$1' was not found in PATH"
         exit 1
    fi
}

# We check if required utilities are available
check_utility jq
check_utility gzip
#current_patch_set=$(ssh -p 29418 ${RDO_GERRIT_USER}@review.rdoproject.org gerrit query --current-patch-set --format=JSON $patch_number | jq --raw-output '.currentPatchSet.number' | head -n 1)

last_two_digit=$(echo $patch_number | awk '{print substr($0,length-1,2)}')
log_url="$BASE_LOG_URL/$last_two_digit/$patch_number"
current_patch_set=$(curl -sL $log_url | grep -e "\[DIR\]" | sed 's/.*href="\(.*\)\/".*/\1/' | tail -n 1)
patch_set=${4:-$current_patch_set}
log_url="$BASE_LOG_URL/$last_two_digit/$patch_number/$patch_set/check"
weirdo_job_name=$(curl -sL $log_url | grep -e "\[DIR\]" | sed 's/.*href="\(.*\)\/".*/\1/' | grep $weirdo_job_type | grep $scenario)
log_url="$BASE_LOG_URL/$last_two_digit/$patch_number/$patch_set/check/$weirdo_job_name/"

curl -o /dev/null -sIfL $log_url
if [ ! $? -eq 0 ]; then
	echo "$log_url is not accessible"
	exit 1
fi

zuul_job_hash=$(curl -sL $log_url | grep -e "\[DIR\]" | sed 's/.*href="\(.*\)\/".*/\1/' | tail -n 1)
log_url=$log_url$zuul_job_hash/

curl -o /dev/null -sIfL $log_url
if [ ! $? -eq 0 ]; then
	echo "$log_url is not accessible"
	exit 1
fi

journalctl_url=$log_url/logs/journalctl.txt.gz
journalctl_file=/tmp/journalctl_$zuul_job_hash.txt
journalctl_file_compressed=$journalctl_file.gz

curl --output $journalctl_file_compressed -sfL $journalctl_url
if [ ! $? -eq 0 ]; then
	echo "Could not download journalctl log file from '$journalctl_url'"
	exit 1
fi

gzip -f -d $journalctl_file_compressed
repo=$(grep -A 6 "/etc/yum.repos.d/delorean-zuul-repo.repo" $journalctl_file | tail -n 6 | sed 's/^\s*//g')
if [[ $weirdo_job_name =~ "weirdo-dlrn-master" ]]; then
    if [[ -z $repo ]]; then
        echo "Could not get delorean-zuul-repo content in $journalctl_file"
        exit 1
    else
        echo "$repo" > /etc/yum.repos.d/delorean-zuul-repo.repo
    fi

    job_cmds=$(sed '0,/export\ WORKSPACE="\/home\/zuul\/workspace"/d' $journalctl_file | sed '/_uses_shell/,$d' | sed 's/^\s*//g')
    if [[ -z $job_cmds ]]; then
        echo "Could not get the job commands in $journalctl_file"
        exit 1
    else
        echo "$job_cmds" > /tmp/replay_$zuul_job_hash.sh
        sed -i '1d' /tmp/replay_$zuul_job_hash.sh
    fi
elif [[ $weirdo_job_name =~ "validate-buildsys-tags" ]]; then
    job_cmds=$(sed '/MASTER=".*/,$!d' $journalctl_file | sed '/.*_uses_shell.*/,$d' | sed 's/^\s*//g' )
    if [ -z "$job_cmds" ]; then
        echo "Could not get the job commands in $journalctl_file"
        exit 1
    else
        echo "$job_cmds" > /tmp/replay_$zuul_job_hash.sh
    fi
fi

# We change the workspace
sed -i "s|/home/zuul/src/review.rdoproject.org/rdo-infra/weirdo|${HOME}/weirdo|" /tmp/replay_$zuul_job_hash.sh
# We delete the first line which is a cd
chmod u+x /tmp/replay_$zuul_job_hash.sh
echo "Review the script before executing it."
echo "bash /tmp/replay_$zuul_job_hash.sh"
