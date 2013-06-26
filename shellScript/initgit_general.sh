#!/bin/bash

if [ -d ".git" ]; then
	echo "already exist .git! Skip it."
	exit 1
fi

echo "start init git"
git init

# make some config
git config user.name $name
git config user.email $email

# make .gitignore file
cat > .gitignore << "eof"
*.[oad]
*.so
*.depend
*.[oa].flags
*.map
*.gif
*.ico
*.lo
*.xml
*.cmd
*.svn
*.list
*.old


# file
.gitignore
README
TODO
COPYING
AUTHORS

# bin

# dir


eof

# add file to watch
git add .

echo "start commit..."
git commit -m "initial"


