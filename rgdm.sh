#!/bin/bash

# settings
name="media"
title="Media"

# config defaults
config_file="rclone.conf"
remote_drive="GDrive:path/to/media/"
config_local_secret="$name-local-secret"
config_remote_secret="$name-remote-secret"
local_secret="secret/$name"
local_decrypted="decrypted/$name"

# colors
red=`tput setaf 1`
green=`tput setaf 2`
yellow=`tput setaf 3`
blue=`tput setaf 4`
magenta=`tput setaf 5`
cyan=`tput setaf 6`
reset=`tput sgr0`

# header bar length based on title length
header_bar_len=$((${#title} + 39))

# print header bar
print_header() {
  printf "${red}"
  printf '%0.s=' $(seq 1 $header_bar_len)
  printf '\n'
  echo "${red}=====     ${green}Welcome to RGDrive ${title}     ${red}====="
  printf '%0.s=' $(seq 1 $header_bar_len)
  printf '\n'
  echo "${reset}"
}

# print help info
print_help() {
  print_header
  echo "${green}Available commands:${reset}"
  echo "   ${yellow}encrypt [file]${reset} - ${cyan}Encrypt file to the local secret folder.${reset}"
  echo "   ${yellow}decrypt${reset} - ${cyan}Decrypt the local secret folder to the local decrypted/$name folder.${reset}"
  echo "   ${yellow}upload${reset} - ${cyan}Upload files in local secret folder to Google Drive $remote_drive folder.${reset}"
  echo "   ${yellow}encrypt_upload [file]${reset} - ${cyan}Encrypt while uploading file to Google Drive $remote_drive folder.${reset}"
  echo "   ${yellow}download [file]${reset} - ${cyan}Download and decrypt files from Google Drive $remote_drive folder to local decrypted/media folder.${reset}"
  echo "   ${yellow}search_download [query]${reset} - ${cyan}Search ls/ls_$name.txt and prompt to download all results.${reset}"
  echo "   ${yellow}mount [drive letter]${reset} - ${cyan}Mount Google Drive $remote_drive folder to [drive letter]: drive.${reset}"
  echo
  echo "   ${yellow}ls${reset} - ${cyan}List files on Google Drive $remote_drive folder.${reset}"
  echo "   ${yellow}ls_file${reset} - ${cyan}List files on Google Drive $remote_drive folder to ls/ls_$name.txt.${reset}"
  echo "   ${yellow}lsd${reset} - ${cyan}List files and their encrypted filenames on Google Drive $remote_drive folder.${reset}"
  echo "   ${yellow}lsd_file${reset} - ${cyan}List files and their encrypted filenames on Google Drive $remote_drive folder to ls/lsd_$name.txt.${reset}"
  echo
  echo "   ${yellow}search_ls [query]${reset} - ${cyan}Search ls/ls_$name.txt.${reset}"
  echo "   ${yellow}search_lsd [query]${reset} - ${cyan}Search ls/lsd_$name.txt.${reset}"
  echo "   ${yellow}search_remote_ls [query]${reset} - ${cyan}Search Google Drive $remote_drive folder using ls.${reset}"
  echo
  echo "   ${yellow}size${reset} - ${cyan}Show size of Google Drive $remote_drive folder.${reset}"
  echo "   ${yellow}help${reset} - ${cyan}Help interface.${reset}"
}

# parse commands
rg_parse() {
  case "$1" in
    "encrypt")
      # ignore first parameter
      shift
      for file in "$@"
      do
	      echo "${yellow}Encrypting $file...${reset}"
	      rclone --config $config_file copy "$file" $config_local_secret:
      done
      ;;
    "decrypt")
      echo "${yellow}Decrypting...${reset}"
      rclone --config $config_file copy $config_local_secret: $local_decrypted
      echo "${yellow}Done!${reset}"
      ;;
    "upload")
      echo "${yellow}Uploading...${reset}"
      rclone --config $config_file copy $local_secret $remote_drive -v
      echo "${yellow}Done!${reset}"
      ;;
    "encrypt_upload")
      # ignore first parameter
      shift
      for file in "$@"
      do
        echo "${yellow}Encrypting and uploading $file...${reset}"
        rclone --config $config_file copy "$file" $config_remote_secret: -v
      done
      echo "${yellow}Done!${reset}"
      ;;
    "download")
      # ignore first parameter
      shift
      for file in "$@"
      do
        echo "${yellow}Downloading $file...${reset}"
        rclone --config $config_file copy $config_remote_secret:"$file" $local_decrypted -v
      done
      echo "${yellow}Done!${reset}"
      ;;
    "search_download")
      # search list
      # remove leading spaces that are treated as multiple columns, name is second column, filter name
      results=`sed 's/^ *//' "ls/ls_$name.txt" | cut -d " " -f2- | egrep -i "$2"`

      # display results
      printf "${yellow}Results:${reset}\n"
      echo $results
      printf "\n"

      # prompt to download
      # -s: do not echo input character. -n 1: read only 1 character (separated by space)
      read -p "Press ENTER to download or any other key to exit." -s -n 1 key
      if [[ $key != "" ]]; then
        # did not press enter
        printf "\n"
        exit 1
      fi
      printf "\n"

      # make newlines the only separator
      IFS=$'\n'
      for file in $results; do
        printf "\n${yellow}Downloading $file...${reset}\n"
        rclone --config $config_file copy $config_remote_secret:"$file" $local_decrypted -v
      done
      echo "${yellow}Done!${reset}"
      ;;
    "mount")
      echo "${yellow}Mounting to drive $2...${reset}"
      rclone --config $config_file mount $config_remote_secret: $2: --allow-other
      ;;
    "ls")
      echo "${yellow}Listing files and sizes...${reset}"
      rclone --config $config_file ls $config_remote_secret:
      ;;
    "ls_file")
      echo "${yellow}Listing files to ls/ls_$name.txt...${reset}"
      mkdir -p ls
      rclone --config $config_file ls $config_remote_secret: >"ls/ls_$name.txt" 2>&1
      ;;
    "lsd")
      echo "${yellow}Listing directories...${reset}"
      rclone --config $config_file lsd --crypt-show-mapping $config_remote_secret:
      ;;
    "lsd_file")
      echo "${yellow}Listing directories to ls/lsd_$name.txt...${reset}"
      mkdir -p ls
      rclone --config $config_file lsd --crypt-show-mapping $config_remote_secret: >"ls/lsd_$name.txt" 2>&1
      ;;
    "search_ls")
      echo "${yellow}Searching files for $2...${reset}"
      cat "ls/ls_$name.txt" | egrep -i "$2" | sort -k 2
      ;;
    "search_lsd")
      echo "${yellow}Searching directories for $2...${reset}"
      cat "ls/lsd_$name.txt" | egrep -i "$2" | sort -k 2
      ;;
    "search_remote_ls")
      echo "${yellow}Searching remote files for $2...${reset}"
      cat <(rclone --config $config_file ls $config_remote_secret:) | egrep -i "$2" | sort -k 2
      ;;
    "size")
      echo "${yellow}Computing size...${reset}"
      rclone --config $config_file size $config_remote_secret:
      ;;
    "help")
      print_help
      ;;
  esac
}

# check arguments
if [ $# -lt 1 ]; then
  echo "Usage: ./$(basename "$0") [cmd]"
  exit 1
fi

# parse
rg_parse "$@"
