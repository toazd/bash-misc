#!/usr/bin/env bash
# BSG - A static site generator in bash

# VARIABLES
[[ -z "$EDITOR" ]] && EDITOR="nano"
# version
version="0.1.3"
## colors
RED="\033[01;31m" # red
GRN="\033[01;32m" # green
BLU="\033[01;34m" # blue
MAG="\033[01;35m" # magenta
FG="\033[01;00m"  # foreground
# general
webdir="site"
assets="assets"
cssfile="style.css"
tmpdir="$(mktemp -qd)"
configdir="config"
# configuration file location
config_file="$PWD/.bsg.conf"
alt_config_file="$HOME/.config/bsg/config"


# FUNCTIONS
# display help message
help_message() {
cat << EOF
BSG - Static site generator in bash : version $version
Usage: bsg [option] / bsg [option] [title]]
-------------------------------------------------------
Options:
  --help       	   : Display this help message
  --init	   : Initialize website
  --create [title] : Create a new post file
  --list	   : List current posts
  --remove [title] : Remove post
-------------------------------------------------------
EOF
}

init_site() {
# notify if configuration file is not found
source $config_file 2> /dev/null || source $alt_config_file 2> /dev/null || printf "Configuration file not found!\n\n"

# ask before starting
printf "This will create a new website template in the current directory.$RED Any present files may be overwritten.$FG\n"
read -p "Are you sure? [y/N] " answer
case $answer in
	[Yy]*) printf "Creating website template in $MAG$PWD$FG...\n" ;;
	[Nn]*) exit ;;
esac
mkdir $assets 2> /dev/null && mkdir $assets/$configdir 2> /dev/null
mkdir $webdir 2> /dev/null
touch $assets/$cssfile

# only ask if the configuration file exists
[ -r $alt_config_file ] && {
read -p "Do you want to copy your BSG configuration here? [y/N] " answer
case $answer in
	[Yy]*) printf "Copying configuration file...\n" && [ -r $config_file ] && cp $alt_config_file . ;;
	[Nn]*) printf "\n" ;;
esac
}

mkdir -p "$assets" "$assets/$configdir" "$webdir" 2> /dev/null

case ${answer,,} in
    ("y*")
        printf "%s\n" "Copying configuration file..."[[ -r "$config_file" ]] && cp $alt_config_file .
    ;;
    ("n*") printf "\n" ;;
esac
}




printf "$GRN[Done]$FG Templates created.\n"
# copy configuration file, unless already there
}

# create HTML file
create_html() {
if [ -z $template ]; then
cat > $webdir/$title.html << EOF
<!DOCTYPE html>
<!-- Document built with BSG: The bash static site generator -->
<!-- Post written by: $author -->
<html lang="$language"><head>
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
    <meta name="viewport" content="width=device-width,initial-scale=1" />
    <meta name="description" content="$description">
	<title>$post_title</title>
	<link rel="stylesheet" type="text/css" href="../$assets/$cssfile">
</head>
<body>
<div id="main">
$content
</div>
</body></html>
EOF
else
use_template() {
eval "cat <<EOF
$(<$assets/$template.html)
EOF
" 2> /dev/null
}
if [ $title = "index" ]; then
use_template > $webdir/$title.html
else
[ -d $webdir/$title ] || mkdir $webdir/$title
use_template > $webdir/$title/index.html
fi
fi
}

create_post() {
# notify if configuration file is not found
source $config_file 2> /dev/null || source $alt_config_file 2> /dev/null || printf "Configuration file not found!\n\n"

[ -z $title ] && read -p "No post title was specified. Please specify one: " && title="$REPLY"
[ -d $webdir ] && printf "" || printf "$RED[Warning]$FG The $MAG$webdir$FG folder is missing! BSG could fail to compile!\nThis can be fixed by using the $BLU'--init'$FG flag\n"
printf "Creating post titled: $MAG$title$FG...\n"
# write the blog post
$EDITOR $title.md && postconfig="$assets/$configdir/$title.conf" && $EDITOR $postconfig && content=$(pandoc -f markdown $title.md > $tmpdir/$title.html.tmp && cat $tmpdir/$title.html.tmp)
[ -f $postconfig ] && source $postconfig

create_html
printf "$GRN[Done]$FG Post created.\n"
}

list_posts() {
printf "Current posts in this directory:\n$MAG"
dir *.md # use dir because using ls may interfere with some people's aliases
printf "$FG\n"
printf "To edit a post use the $BLU'--create'$FG flag:\n"
printf "$ bsg --create title\n"
printf "To remove a post use the $BLU'--remove'$FG flag:\n"
printf "$ bsg --remove title\n"
}

remove_post() {

    [[ -z "$title" ]] && read -rp "No post title was specified. Please specify one: " && title="$REPLY"

    printf "%s\n" "Files to remove: $MAG$title.md $title.html$FG"

    read -p "Are you sure you want to remove this post? [y/N] " answer

    case "${answer,,}" in
        y*)
            echo "Removing files..."
        ;;
        n*)
            echo "Files not removed" && exit
        ;;
    esac

    if [[ $title = "index" ]]; then
        rm $title.md $webdir/$title.html
    else
        rm $title.md $webdir/$title/index.html
    fi

    printf "$GRN[Done]$FG Files removed\n"
}


# USE FLAGS
case "$1" in
    ## help message
    ("--help*"|"-h*"|"-H*")
        help_message
    ;;
	## initialize site
	--init*) init_site ;;
	## new post
	--create*) title="$2" && create_post ;;
	## list current posts
	--list*) list_posts ;;
	## remove post
	--remove*) title="$2" && remove_post ;;
esac
