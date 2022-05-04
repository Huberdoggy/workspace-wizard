#!/usr/bin/env bash

init_check() {
	# Check wether its a first time use or not
	if [[ -z ${DOT_REPO} && -z ${DOT_DEST} ]]; then
	    # show first time setup menu
		# initial_setup
		# Inverse logic for testing - run the user menu function =>
		manage
	else
	  echo "Env vars are set"
		# repo_check
	  #manage
	fi
}

initial_setup() {
	echo -e "\n\nFirst time use, Set up Workspace Wizard"
	echo -e "....................................\n"
	read -p "Enter repository URL of Kyle's config files => " -r DOT_REPO
	# Syntax - will default under $HOME if DOT_DEST isn't specified
	read -p "Where should I clone $(basename "${DOT_REPO}") (${HOME}/..): " -r DOT_DEST
	DOT_DEST=${DOT_DEST:-$HOME}
	if [[ -d "$HOME/$DOT_DEST" ]]; then
		# Dir exists, so clone the repo in the destination directory
		# Syntax for specified clone dir - git -C <path> <repo>
		if git -C "${HOME}/${DOT_DEST}" clone "${DOT_REPO}"; then
			add_env "$DOT_REPO" "$DOT_DEST"
			echo -e "\nWorkspace Wizard successfully configured!"
			echo -e "\nGoodbye"
		else
			# invalid arguments to exit, Repository Not Found
			echo -e "\n$DOT_REPO Unavailable. Exiting"
			exit 1
		fi
	else
		echo -e "\n$DOT_DEST Not a Valid directory"
		exit 1
	fi
}

add_env() {
	# export environment variables - for now, I'm just using condition for Bash
	# since that's the shell I always use
	echo -e "\nExporting env variables DOT_DEST & DOT_REPO ..."

	current_shell=$(basename "$SHELL")
	if [[ $current_shell == "bash" ]]; then
	  # Args order from previous funtion get added as vars to .bashrc
		echo "export DOT_REPO=$1" >> "$HOME"/.bashrc
		echo "export DOT_DEST=$2" >> "$HOME"/.bashrc
	else
	  # Placeholder for other shells
		echo "Couldn't export DOT_REPO and DOT_DEST."
		echo "Consider exporting them manually".
		exit 1
	fi
	echo -e "Configuration for SHELL: $current_shell has been updated."
}

manage() {
  echo "$(figlet -cf cybermedium 'Workspace Wizard')" | lolcat
  echo -e "'\n'$(figlet -ckf term 'By Kyle Huber')" | lolcat
	while :
	do
		echo -e "$(tput setaf 6)\n\t\t[1] Show Diff$(tput sgr0)"
		echo -e "$(tput setaf 6)\t\t[2] Push changed config files to Github$(tput sgr0)"
		echo -e "$(tput setaf 6)\t\t[3] Pull latest changes from Github$(tput sgr0)"
		echo -e "$(tput setaf 6)\t\t[4] Locate and display your customized config files$(tput sgr0)"
		echo -e "$(tput setaf 6)\t\t[q|Q] Quit session$(tput sgr0)"
		# Default choice is [1], -n 1 only allows 1 char input
		echo
		read -p "What do you wish to do? => " -n 1 -r USER_INPUT
		USER_INPUT=${USER_INPUT:-1} # to set the default (see above)
		case $USER_INPUT in
			[1]* )    echo -e "\nTODO show_diff_check";;
			[2]* )    echo -e "\nTODO conf_push";;
			[3]* )    echo -e "\nTODO conf_pull";;
			[4]* )    find_conf_files;;
			[q/Q]* )  clear
			          exit;;
			* )       printf "\n%s\n" "Invalid Input, Try Again";;
		esac
	done
}

find_conf_files() {
  printf "\n"
  os_type=$(uname)
  if [[ $os_type == "Darwin" && -n $(java --version) ]]; then
    # init 2 empty arrays. Only one will be used depending on choice from input
    home_conf_files=()
    all_conf_files=()
    echo -e "\n\nIt appears you're running on a Mac with Java installed."
    read -p "Would you like to check for custom IntelliJ option files in known locations? [y/n/q]? " -n 1 -r RESPONSE
    case $RESPONSE in
      [n/N]*) while read -r value; do
                home_conf_files+=( $(basename "$value") )
                done < <( find "${HOME}" -maxdepth 4\
                 -type f \( -name "*rc" -or -name ".bash*" \)\
                  | egrep -v "disable|zsh|nvm|prettier|history")
                  printf "\n\n%s" "BASH AND .RC FILES LOCATED:"
                  printf "\n%s" "${home_conf_files[@]}"
                  echo
                  ;;
      [y/Y]*) while read -r value; do
                all_conf_files+=( $(basename "$value") )
                done < <(find ~/Library/ "${HOME}" -maxdepth 4 \
                -type f \( -name "*rc" -or -name "*.vmoptions" -or -name "*.properties" -or -name ".bash*" \)\
                 | egrep -v "disable|zsh|nvm|prettier|history")
                printf "\n\n%s" "ALL KYLE'S CONFIG FILES FROM FILTER LOCATED:"
                printf "\n%s" "${all_conf_files[@]}"
                echo
                ;;
      [q/Q]*) echo -e "\n\nOkay run the program again when desired\nGoodbye!"
              exit;;
      *)      printf "\n%s\n" "Unknown option. Exiting.."
              exit 1
              ;;
    esac
  else # Placeholder to do later...
    echo "Could not determine operating system. Exiting..."
    exit 1
  fi

}

# Test find functions
init_check
