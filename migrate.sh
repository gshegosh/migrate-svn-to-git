#!/bin/bash
REPO_PATH=/work/oldsvns/svnrepos/old-nkrop
#PROJECT=asseco/skalk
#PROJECT=nKrop/ec
PROJECT=Ostar/PoolDisp

rm -rf ./git
mkdir -p ./git
cd ./git

cat <<EOF > tmprules
create repository $PROJECT
end repository

# Note: rules must end in a slash

match /$PROJECT/trunk/
  repository $PROJECT
  branch master
end match

match /$PROJECT/branches/([^/]+)/
  repository $PROJECT
  branch \1
  substitute branch s/ /_/
end match

match /$PROJECT/tags/([^/]+)/
  repository $PROJECT
  branch tag_\1
  substitute branch s/ /_/
end match

# ignore the rest
match .*
end match
EOF

svn-all-fast-export $REPO_PATH --svn-ignore --stats --propcheck --rules tmprules

git clone $PROJECT repo
cd repo

(IFS='
'
for ref in `git for-each-ref --format='%(refname:short)'`; do
  if [[ $ref == origin/HEAD* ]]; then
    # ignore origin/HEAD
    :
  elif [[ $ref == origin/tag_* ]]; then
    echo -n "TAG    "
    tag=${ref/origin\/tag_/}
    echo -n "$tag :: "
    git checkout $ref
    git tag $tag
    git checkout origin/master
  elif [[ $ref == origin* ]]; then
    echo -n "BRANCH "
    branch=${ref/origin\//}
    git checkout $ref -b $branch
    git checkout origin/master
  elif [[ $ref == backups* ]]; then
    echo -n "BACKUP "
    git tag -d $ref
  fi
  echo "$ref"
done)

git remote rm origin
git repack -a -d -f
