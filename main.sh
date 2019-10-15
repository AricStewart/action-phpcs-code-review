#!/usr/bin/env bash

stars=$(printf "%-30s" "*")

export RTBOT_WORKSPACE="/home/rtbot/github-workspace"
hosts_file="$GITHUB_WORKSPACE/.github/hosts.yml"

rsync -a "$GITHUB_WORKSPACE/" "$RTBOT_WORKSPACE"
rsync -a /root/vip-go-ci-tools/ /home/rtbot/vip-go-ci-tools
chown -R rtbot:rtbot /home/rtbot/

GITHUB_REPO_NAME=${GITHUB_REPOSITORY##*/}
GITHUB_REPO_OWNER=${GITHUB_REPOSITORY%%/*}

if [[ -n "$VAULT_GITHUB_TOKEN" ]] || [[ -n "$VAULT_TOKEN" ]]; then
  export GH_BOT_TOKEN=$(vault read -field=token secret/rtBot-token)
fi

phpcs_standard=''

defaultFiles=(
  '.phpcs.xml'
  'phpcs.xml'
  '.phpcs.xml.dist'
  'phpcs.xml.dist'
)

phpcsfilefound=1

for phpcsfile in "${defaultFiles[@]}"; do
  if [[ -f "$RTBOT_WORKSPACE/$phpcsfile" ]]; then
      phpcs_standard="--phpcs-standard=$RTBOT_WORKSPACE/$phpcsfile"
      phpcsfilefound=0
  fi
done

if [[ $phpcsfilefound -ne 0 ]]; then
    if [[ -n "$1" ]]; then
      phpcs_standard="--phpcs-standard=$1"
    else
      phpcs_standard="--phpcs-standard=WordPress"
    fi
fi

echo "Running with the flag $phpcs_standard\n\n"

echo "Running the following command"
echo "ARIC: GITHUB_SHA:"
echo "$GITHUB_SHA"
echo "`git whatchanged -n 1 $GITHUB_SHA`"
echo "$GITHUB_REF"
echo "$GITHUB_HEAD_REF"
echo "$GITHUB_BASE_REF"
echo "`git log origin/$GITHUB_BASE_REF..origin/$GITHUB_HEAD_REF`"
TARGET=`git log -n 1 --pretty=format:%H --no-merges $GITHUB_SHA`;
echo "New: $TARGET";
echo "`git branch --contains $TARGET`";
echo "OLD: $GITHUB_SHA";
echo "`git branch --contains $GITHUB_SHA`";
echo "now: `git branch`";
echo ""
echo "---- Adjusting the branch ---"
echo "git checkout -b $GITHUB_HEAD_REF origin/$GITHUB_HEAD_REF"
# gosu rtbot bash -c "git checkout -b $GITHUB_HEAD_REF origin/$GITHUB_HEAD_REF"
TARGET=`git log -n 1 --pretty=format:%H --no-merges origin/$GITHUB_HEAD_REF`;
echo "TARGET=$TARGET";
echo ""
echo "---- Attempting command ---"
echo "/home/rtbot/vip-go-ci-tools/vip-go-ci/vip-go-ci.php --repo-owner=$GITHUB_REPO_OWNER --repo-name=$GITHUB_REPO_NAME --commit=$GITHUB_SHA --token=\$GH_BOT_TOKEN --phpcs-path=/home/rtbot/vip-go-ci-tools/phpcs/bin/phpcs --local-git-repo=/home/rtbot/github-workspace --phpcs=true $phpcs_standard --lint=true"
gosu rtbot bash -c "/home/rtbot/vip-go-ci-tools/vip-go-ci/vip-go-ci.php --repo-owner=$GITHUB_REPO_OWNER --repo-name=$GITHUB_REPO_NAME --commit=$GITHUB_SHA --token=$GH_BOT_TOKEN --phpcs-path=/home/rtbot/vip-go-ci-tools/phpcs/bin/phpcs --local-git-repo=/home/rtbot/github-workspace --phpcs=true $phpcs_standard --lint=true"
