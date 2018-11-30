#!/bin/bash

# settings
name="media"
vault_dir="000"
title="Media"

# config defaults
config_file="config/rclone_vault.conf"
remote_drive="gdrive:Vault/$vault_dir/"
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

# print config
print_config() {
  echo "${green}Configuration${reset}"
  echo "${yellow}Config file:${reset} $config_file"
  echo "${yellow}Remote drive:${reset} $remote_drive"
  echo "${yellow}Config local secret:${reset} $config_local_secret"
  echo "${yellow}Config remote secret:${reset} $config_remote_secret"
  echo "${yellow}Local secret:${reset} $local_secret"
  echo "${yellow}Local decrypted:${reset} $local_decrypted"
  echo
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
  echo "   ${yellow}mount [drive letter]${reset} - ${cyan}Mount Google Drive $remote_drive folder to [drive letter]: drive.${reset}"
  echo
  echo "   ${yellow}ls${reset} - ${cyan}List files on Google Drive $remote_drive folder.${reset}"
  echo "   ${yellow}ls_file${reset} - ${cyan}List files on Google Drive $remote_drive folder to ls/ls_$name.txt.${reset}"
  echo "   ${yellow}lse${reset} - ${cyan}List files and their encrypted filenames on Google Drive $remote_drive folder.${reset}"
  echo "   ${yellow}lse_file${reset} - ${cyan}List files and their encrypted filenames on Google Drive $remote_drive folder to ls/lse_$name.txt.${reset}"
  echo
  echo "   ${yellow}search_ls [query]${reset} - ${cyan}Search ls/ls_$name.txt.${reset}"
  echo "   ${yellow}search_lse [query]${reset} - ${cyan}Search ls/lse_$name.txt.${reset}"
  echo
  echo "   ${yellow}size${reset} - ${cyan}Show size of Google Drive $remote_drive folder.${reset}"
  echo "   ${yellow}config${reset} - ${cyan}Show config.${reset}"
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
        rclone --config $config_file copy --transfers 32 --checkers 16 "$file" $config_remote_secret: -v
      done
      echo "${yellow}Done!${reset}"
      ;;
    "download")
      # ignore first parameter
      shift
      for file in "$@"
      do
        echo "${yellow}Downloading $file...${reset}"
        rclone --config $config_file copy --transfers 32 --checkers 16 $config_remote_secret:"$file" $local_decrypted -v
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
    "lse")
      echo "${yellow}Listing encrypted names...${reset}"
      rclone --config $config_file lsd --crypt-show-mapping $config_remote_secret:
      ;;
    "lse_file")
      echo "${yellow}Listing encrypted names to ls/lse_$name.txt...${reset}"
      mkdir -p ls
      rclone --config $config_file lsd --crypt-show-mapping $config_remote_secret: >"ls/lse_$name.txt" 2>&1
      ;;
    "search_ls")
      echo "${yellow}Searching files for $2...${reset}"
      cat "ls/ls_$name.txt" | egrep -i "$2" | sort -k 2
      ;;
    "search_lse")
      echo "${yellow}Searching encrypted names for $2...${reset}"
      cat "ls/lse_$name.txt" | egrep -i "$2" | sort -k 2
      ;;
    "size")
      echo "${yellow}Computing size...${reset}"
      rclone --config $config_file size $config_remote_secret:
      ;;
    "config")
      print_config
      ;;
    "help")
      print_help
      ;;
    *)
      echo "Error: invalid command"
      exit 1
  esac
}

# check arguments
if [ $# -lt 1 ]; then
  echo "Usage: ./$(basename "$0") [cmd]"
  exit 1
fi

# parse
rg_parse "$@"
