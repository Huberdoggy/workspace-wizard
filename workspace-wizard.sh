#!/usr/bin/env bash
# init globally accessible array to track changed files
changed_file_arr=()
echo "Length of array: ${#changed_file_arr}"
printf '\n%s' "${changed_file_arr[*]}"

init_check() {
	# Check wether its a first time use or not
	if [[ -z ${CONF_REPO} && -z ${CONF_DEST} ]]; then
	  # show first time setup menu
		initial_setup
	else
		# Run the standard opts menu
	  manage
	fi
}

initial_setup() {
	echo -e "\n\nFirst time use, Set up Workspace Wizard"
	echo -e "....................................\n"
	read -p "Enter repository URL of Kyle's config files => " -r CONF_REPO
	# Syntax - will default under $HOME if CONF_DEST isn't specified
	read -p "Where should I clone $(basename "${CONF_REPO}") (${HOME}/..): " -r CONF_DEST
	CONF_DEST=${CONF_DEST:-$HOME}
	if [[ -d "$HOME/$CONF_DEST" ]]; then
		# Dir exists, so clone the repo in the destination directory
		# Syntax for specified clone dir - git -C <path> <repo>
		if git -C "${HOME}/${CONF_DEST}" clone "${CONF_REPO}"; then
			add_env "$CONF_REPO" "$CONF_DEST"
			echo -e "\nWorkspace Wizard successfully configured!\nGoodbye"
		else
			# invalid arguments to exit, Repository Not Found
			echo -e "\n$CONF_REPO Unavailable. Exiting"
			exit 1
		fi
	else
		echo -e "\n$CONF_DEST Not a Valid directory"
		exit 1
	fi
}

add_env() {
	# export environment variables - for now, I'm just using condition for Bash
	# since that's the shell I always use
	echo -e "\nExporting env variables CONF_DEST & CONF_REPO ..."

	current_shell=$(basename "$SHELL")
	if [[ $current_shell == "bash" ]]; then
	  # Args order from previous funtion get added as vars to .bash_profile
		echo "export CONF_REPO=$1" >> "$HOME"/.bash_profile
		echo "export CONF_DEST=$2" >> "$HOME"/.bash_profile
	else
	  # Placeholder for other shells
		echo "Couldn't export CONF_REPO and CONF_DEST."
		echo "Consider exporting them manually".
		exit 1
	fi
	echo -e "Configuration for SHELL: $current_shell has been updated.\n"
	cat "$HOME"/.bash_profile | egrep -i --color=always "(conf_repo|conf_dest).*"
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
			[1]* )    show_diff_check;;
			[2]* )    conf_push;;
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
    # Run MacOS specific function
    run_mac
  else # Placeholder to do later...
    echo "Could not determine operating system. Exiting..."
    exit 1
  fi

}

run_mac() {
      # init an empty array.
      all_conf_files=()
      echo -e "\n\nIt appears you're running on a Mac with Java installed."
      echo -e "Wizard will also check for custom IntelliJ IDE option files in known locations."
      while read -r value; do
      all_conf_files+=("$value")
      done < <(find "${HOME}"/Library/ "${HOME}" -maxdepth 4 \
      -type f ! -wholename "\/*\/*\/shell-stuff/*" \( -name "*rc" -or -name "*.vmoptions" -or -name "*.properties" -or -name ".bash*" \)\
      | egrep -v "disable|zsh|nvm|prettier|history")
      printf "\n\n%s" "ALL KYLE'S CONFIG FILES FROM FILTER LOCATED:"
      printf "\n%s" "${all_conf_files[@]}"
      echo
}

diff_check() {
  # If called from conf_push, this will be empty
	# if [[ -z $1 ]]; then
	  # init globally accessible array to track changed files
		# MOVED - to global scope due to Bash 3.2 limitations of -g flag
	# fi

  conf_files_repo=()
	# Conf files in repository
	while read -r value; do
	conf_files_repo+=("$value")
	done < <( find "${HOME}/${CONF_DEST}/$(basename "${CONF_REPO}" | cut -c 1-14)" -maxdepth 1 -type f\
	\( -name "*rc" -or -name "*.vmoptions" -or -name "*.properties" -or -name ".bash*" \) )
	# check length here
	for (( i=0; i<"${#conf_files_repo[@]}"; i++))
	do
	  # Like my locate function, just trim the file name from path
		conf_file_name=$(basename "${conf_files_repo[$i]}")
		# compare the HOME version of file to that of repo
		# For testing, allow common lines to be shown
		if [[ $conf_file_name =~ idea\.* ]]; then
		  diff=$(colordiff -u --suppress-common-lines\
		  "${conf_files_repo[$i]}" "${HOME}"/Library/Application\ Support/JetBrains/IntelliJIdea2022.1/"${conf_file_name}")
		elif [[ $conf_file_name =~ \.bash* ]]; then
		  diff=$(colordiff -u --suppress-common-lines\
		  "${conf_files_repo[$i]}" "${HOME}/${conf_file_name}")
		else
		  diff=$(colordiff -u --suppress-common-lines\
		  "${conf_files_repo[$i]}" "${HOME}"/.config/htop/"${conf_file_name}")
		fi
		if [[ $diff != "" ]]; then
			if [[ $1 == "show" ]]; then
				printf "\n\n%s" "$(tput setaf 6)Running diff between local version of ${conf_file_name} and$(tput sgr0)"
				printf "\n%s\n\n" "$(tput setaf 6)Remote copy at ${CONF_REPO}$(tput sgr0)"
				printf "%s\n\n" "$diff"
			fi
			  # Append any changes to our other array
			  changed_file_arr+=("${conf_file_name}")
		fi
	done
	if [[ ${#changed_file_arr} == 0 ]]; then
		echo -e "\n\nNo Changes in conf files."
		return
	fi
}

show_diff_check() {
	diff_check "show"
}


conf_push () {
  diff_check
  echo -e "\nThe following of Kyle's config files were changed : "
  # Doing this to ensure that running menu options back to back doesn't dupe changed files
  sorted_unique_files=($(echo "${changed_file_arr[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' '))
  for file in "${sorted_unique_files[@]}"; do
    echo "$file"
    if [[ "$file" =~ \.bash* ]]; then
      cp "${HOME}/$file" "${HOME}/${CONF_DEST}/$(basename "${CONF_REPO}" | cut -c 1-14)"
    elif [[ $file =~ idea\.* ]]; then
      cp "${HOME}/Library/Application\ Support/JetBrains/IntelliJIdea2022.1/$file"\
      "${HOME}/${CONF_DEST}/$(basename "${CONF_REPO}" | cut -c 1-14)"
    else
      cp "${HOME}/.config/htop/$file" "${HOME}/${CONF_DEST}/$(basename "${CONF_REPO}" | cut -c 1-14)"
    fi
  done

  # For shortened Git command usage
  conf_repo="${HOME}/${CONF_DEST}/$(basename "${CONF_REPO}" | cut -c 1-14)"
  git -C "$conf_repo" add --all

  echo -e "Enter your commit message (CTRL + D to confirm it) => "
  commit=$(</dev/stdin)

  git -C "$conf_repo" commit -m "$commit"

  # And push it
  git -C "$conf_repo" push
}
# Test find functions
init_check
