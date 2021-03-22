#!/usr/bin/env bash

help(){
	echo "[Usage]"
	echo "./deploy.sh -c {config} -s {settings.xml} -g {groupId} -a {artifactId} -r {repositoryId} -u {repository-url} -p {package} -d --no-pull --no-build --no-remote"
	echo "-c|--config      : configuration filepath."
	echo "                   default: ./build-config.properties"
	echo "-s|--settings    : maven 'setttings.xml' filepath."
	echo "                   mvn        : -s|--settings"
	echo "                   config-file: mvn.settings"
	echo "-g|--groupId     : maven GroupID"
	echo "                   mvn        : -DgroupId"
	echo "                   config-file: mvn.groupId"
	echo "-a|--artifactId  : maven ArtifactID, -DartifactId"
	echo "                   mvn        : -DargifactId"
	echo "                   config-file: mvn.artifactId"
	echo "-r|--repositoryId: (optional) \${servers.server.id} in 'settings.xml', -DrepositoryId"
	echo "                   Need to deploy to remote repository."
	echo "                   mvn        : -DrepositoryId"
	echo "                   config-file: mvn.repositoryId"
	echo "-u|--url         : Repository Url, -Durl"
	echo "                   format: {url}(|{url})?"
	echo "                   Remote url starts with 'http', local url starts with 'file'."
	echo "                   mvn        : -Durl"
	echo "                   config-file: mvn.url-remote"
	echo "                                mvn.url-local"
	echo "-p|--package     : Package Type. -Dpackageing"
	echo "                   mvn        : -Dpackageing"
	echo "                   config-file: mvn.packageing"
	echo "--no-pull        : DO NOT 'git pull'"
	echo "--no-build       : DO NOT 'gradle build'"
	echo "--no-remote      : DO NOT 'deploy to remote url'"
	echo "--force-build    : DO 'gradle build'"
	echo
}

# 
# Split the string with the delimieter and return a string at the specifi index.
# 
# @param $1 string
# @param $2 delim
# @param $3 index
cut_str(){
	echo $(cut -d$2 -f$3 <<< $1)
}

#
# Concate strings with the delimiter.
# 
# @param $1  delim
# @param $2~ strings
#
# @return concatenated string
concat(){
	_str=""
	_delim=""
	_args=("$@")
	_val=""

	for ((idx=0; idx<${#_args[@]}; ++idx));
	do
		_val=${_args[idx]}

		if [ "$idx" == 0 ];
		then
			# assign 'delimiter'
			_delim=$_val
		elif [ "$idx" == 1 ];
		then
			# assign 'first string'
			_str=$_val
		else
			# concatenet strings
			_str=$_str$_delim$_val
		fi
	done

	echo $_str
}

#
# @param $1 value
# @param $2 msg
# @param $3 allow
#
is_empty(){
	if [ -z "$1" ];
	then
		echo $2
		if [ "$3" != "allow" ];
		then
			help
			exit 1
		fi
	fi
}

# Declare variables.
CONFIG_FILE="./build-config.properties"

MVN_SETTINGS=""
MVN_GOAL="deploy:deploy-file"
MVN_GROUP_ID=""
MVN_REPO_ID=""
MVN_URL_REMOTE=""
MVN_URL_LOCAL=""
MVN_PACKAGEING=""

PULL="true"
BUILD="true"
DEPLOY_REMOTE="true"
FORCE_BUILD="false"
#
# @param $1 binding type
# @param $2 variable name
# @param $3 value
log_bind_var(){
	_msg=""
	if [ "$1" == "arg" ];
	then
		_msg="Assign Argument"
	elif [ "$1" == "conf" ];
	then
		_msg="Assign Configuration"
	fi
	
	printf "[%-20s] %-15s = %s\n" "$_msg" "$2" "$3"
}


#
# Set the url to matched variable.
# @param $1 url
# @param $2 binding type
#
set_url(){
	if [ -z "$1" ];
	then
		return 0
	fi

	if [[ $1 == http* ]];
	then
		bind_variable "MVN_URL_REMOTE" "$1" "" "$2"
	elif [[ $1 == file* ]];
	then
		bind_variable "MVN_URL_LOCAL" "$1" "" "$2"
	else
		echo "---------------------------------------------------------------"
		echo "---------------------------------------------------------------"
		echo "---  Invalid url pattern. url=$1"
		echo "---------------------------------------------------------------"
		echo "---------------------------------------------------------------"
	
		help

		exit 1
	fi
}

# Read Parameters
echo
echo "+++ start to bind variables with arguments"
while [ "$1" != "" ]; do
	case $1 in
		-c | --config)
			shift
			CONFIG_FILE=$1
			log_bind_var "arg" "CONFIG_FILE" "$1"
			;;
		-s | --settings)
			shift
			MVN_SETTINGS=$1
			log_bind_var "arg" "MVN_SETTINGS" "$1"
			;;
		-g | --groupId)
			shift
			MVN_GROUP_ID=$1
			log_bind_var "arg" "MVN_GROUP_ID" "$1"
			;;
		-a | --artifactId)
			shift
			MVN_ARTIFACT_ID=$1
			log_bind_var "arg" "MVN_ARTIFACT_ID" "$1"
			;;
		-r | --repositoryID)
			shift
			MVN_REPO_ID=$1
			log_bind_var "arg" "MVN_REPO_ID" "$1"
			;;
		-u | --url)
			shift
			_url=$(cut_str $1 "|" 1)

			set_url $_url "arg"

			_url=$(cut_str $1 "|" 2)
			if [ ! -z "$_url" ];
			then
				set_url $_url "arg"
			fi
			;;
		-p | --packageing)
			shift
			MVN_PACKAGEING=$1
			log_bind_var "arg" "MVN_PACKAGEING" "$1"
			;;
		--no-pull)
			PULL="false"
			log_bind_var "arg" "PULL" "false"
			;;
		--no-build)
			BUILD="false"
			log_bind_var "arg" "BUILD" "false"
			;;
		--no-remote)
			DEPLOY_REMOTE="false"
			log_bind_var "arg" "DEPLOY_REMOTE" "false"
			;;
		--force-build)
			FORCE_BUILD="true"
			log_bind_var "arg" "FORCE_BUILD" "true"
			;;
		-h | --help)
			help
			exit 0
			;;
		*)
			echo "----------------------------------------------------"
			echo "----------------------------------------------------"
			echo "----------------------------------------------------"
			echo "--- Unknown arguments. arg=$1"
			echo "----------------------------------------------------"
			echo "----------------------------------------------------"
			echo

			help
			exit 2
			;;
	esac
	shift
done
echo "------------------------------------------------"
#
# Read a property
#
# @param $1 property name
# @param $2 default value
#
prop(){
	if [ ! -z ${CONFIG_FILE} ];
	then
		_value=$(grep -v -e "^#" ${CONFIG_FILE} | grep -w "${1}" | cut -d"=" -f2-)
		if [ ! -z $_value ];
		then
			echo "$_value"
		else
			echo "$2"
		fi
	else
		echo "$2"
	fi
}

#
# Assign the value to the variable if a current value is equal to $3.
# 
# @param $1 variable
# @param $2 new value
# @param $3 a value to be changed.
# @param $3 binding type
bind_variable(){
	# value reference (${variable}, not variable
	_val_ref=\$$1

	# current value
	_val=$(eval echo $_val_ref)

	# assign a value when current value is not assigned.
	if [ "$_val" == "$3" ];
	then
		eval $1=\"$2\"
		log_bind_var "$4" "$1" "$2"
	fi
}

#
# @param $1 variable
# @param $2 value
# @param $3 value-1
# @param $4 value-2
set_value(){
	if [ "$3" == "$4" ];
	then
		eval $1=\"$2\"
	else
		echo "\$3=$3"
		echo "\$4=$4"
	fi
}

# bind variable with a configuration file.
echo
echo "+++ start to bind variables with configuration file."
bind_variable "MVN_SETTINGS" "$(prop 'mvn.settings')" "" "conf"
bind_variable "MVN_GROUP_ID" "$(prop 'mvn.groupId')" "" "conf"
bind_variable "MVN_REPO_ID" "$(prop 'mvn.repositoryId')" "" "conf"
set_url "$(prop 'mvn.url.remote')" "conf"
set_url "$(prop 'mvn.url.local')" "conf"
bind_variable "MVN_PACKAGEING" "$(prop 'mvn.packageing')" "" "conf"
echo "----------------------------"

# validate configurations.
echo 
echo "+++ start to validate variables"
is_empty "$CONFIG_FILE" "'Configuration' is Mandatory!!!"
is_empty "$MVN_SETTINGS" "Reference a System Default. \${user.dir}/.mvn/settings.xml" "allow"
is_empty "$MVN_GROUP_ID" "'groupId' is Mandatory!!!"
is_empty "$MVN_REPO_ID" "If deploy to a remote url, 'repositoryId' is Mandatory!!!" "allow"
is_empty "$MVN_URL_REMOTE" "If deploy to a remote url, remote 'url' is Mandatory!!!" "allow"
is_empty "$MVN_URL_LOCAL" "If deploy to a local url, local 'url' is Mandatory!!!" "allow"
is_empty "$MVN_PACKAGEING" "'packageing' is Mandatory!!!"
echo "---------------------------------"

# validate cross configurations
echo
echo "+++ start to cross-validate"
echo " >>> remote 'url' x 'repositoryId'"
if [[ ! -z "$MVN_URL_REMOTE" ]] && [[ -z "$MVN_REPO_ID" ]];
then
	echo
	echo "---------------------------------------------------------------"
	echo "---------------------------------------------------------------"
	echo "------ If deploy to remote url, MUST set 'repositoryId'. ------"
	echo "---------------------------------------------------------------"
	echo "---------------------------------------------------------------"
	echo

	help

	exit 1
fi
echo "-----------------------------------"

UPDATED_SRC=""
# @param $1 directory
# 
git_pull(){
	echo
	echo "==============================================================="
	echo "+++ git pull '$1'"

	cd $1

	UPDATED_SRC=$(git pull)

	echo
	echo $UPDATED_SRC

	cd ..
}

#
# Build a package
#
# @param $1 directory
# @param $2 build command
#
build(){
	echo
	echo "==============================================================="
	echo "+++ build '$1'"

	cd $1

	echo
	echo "gradle $2"

	echo
	gradle $2

	cd ..
}

#
# Deploy to maven repository
# 
# @param $1 directory
# @param $2 file
# @param $3 url
#
make_mvn_cmd(){
	_filepath=$1"/"$2
	_file=$2
	_artifactId=$(cut_str ${_file/.jar} - 1)
	_version=$(cut_str ${_file/.jar} - 2)
	_classifier=$(cut_str ${_file/.jar} - 3)

	_url=$3

	is_empty "$_artifactId" "Not Found 'artifactId'. file=$_file"
	is_empty "$_artifactId" "Not Found 'version'. file=$_file"

	_delim="\n\t"
	_cmd="mvn"
	if [ ! -z "${MVN_SETTINGS}" ];
	then
		_cmd="$_cmd --settings $MVN_SETTINGS"
	fi
	_cmd=$(concat "$_delim" "$_cmd" "$MVN_GOAL")
	_cmd=$(concat "$_delim" "$_cmd" "-DgroupId=$MVN_GROUP_ID")
	_cmd=$(concat "$_delim" "$_cmd" "-DartifactId=$_artifactId")
	_cmd=$(concat "$_delim" "$_cmd" "-Dversion=$_version")
	_cmd=$(concat "$_delim" "$_cmd" "-Dpackageing=$MVN_PACKAGEING")
	_cmd=$(concat "$_delim" "$_cmd" "-Dfile=$_filepath")
	if [ ! -z "$MVN_REPO_ID" ];
	then
		_cmd=$(concat "$_delim" "$_cmd" "-DrepositoryId=$MVN_REPO_ID")
	fi
	_cmd=$(concat "$_delim" "$_cmd" "-Durl=$_url")

	if [ -z "$_classifier" ];
	then
		_cmd=$(concat "$_delim" "$_cmd" "-DgeneratePom=true")
	else
		_cmd=$(concat "$_delim" "$_cmd" "-Dclassifier=$_classifier")
	fi

	echo $_cmd
}


BUILD_LIB="build/libs"

# 
# Deploy a package
# 
# @param $1 directory
# @param $2 url
#
mvn_deploy(){
	_build_dir=$(pwd)"/"$1"/"$BUILD_LIB
	_ls_cmd="eval ls -Al $_build_dir | grep -E ^- | awk '{print \$9}'"
	_files=$($_ls_cmd)
	_url=$2

	for file in $_files 
	do
		echo
		echo "============================================================"
		echo "+++ deploy '$file' to repository."
		echo "------------------------------------------------------------"
		mvn_cmd=$(make_mvn_cmd "$_build_dir" "$file" "$_url")

		# If -e is effect, the following sequences are recognized: '\\', '\n', '\r', '\t'
		echo -e $mvn_cmd
		# replace '\n\t' to ' '
		mvn_cmd=$(echo -e $mvn_cmd)
		echo
		{
			$mvn_cmd
		}||{
			echo
			echo
			echo "Oooooooooooooooooooooooooooooooops"
			exit 1
		}
	done
}



# ##############################################
# --- git pull, gradle build, maven deploy --- #
# ##############################################
{
	BUILD_MARMOT_COMMON="true"
	BUILD_MARMOT_CLIENT="true"
	BUILD_UTILS="true"
	
	not_updated(){	
		echo
		echo "'$1' sources has not updated..."
	}

	if [ "$PULL" == "true" ];
	then
		echo
		echo
		echo "############################################################################"
		echo "+++ START to 'GIT PULL' projects "

		_git_uptodate="Already up-to-date."
	
		# marmot.common
		git_pull "marmot.common"
		set_value "BUILD_MARMOT_COMMON" "false" "$UPDATED_SRC" "$_git_uptodate"

		# marmot.client
		git_pull "marmot.client"
		set_value "BUILD_MARMOT_CLIENT" "false" "$UPDATED_SRC" "$_git_uptodate"

		# utils
		git_pull "utils"
		set_value "BUILD_UTILS" "false" "$UPDATED_SRC" "$_git_uptodate"

		echo
		echo "Completed 'git pull' all."
		echo " - marmot.common"
		echo " - marmot.client"
		echo " - utils"
	
		echo "============================================================================"

	fi

	if [ "$FORCE_BUILD" == "true" ];
	then
		BUILD="true"
		BUILD_MARMOT_COMMON="true"
		BUILD_MARMOT_CLIENT="true"
		BUILD_UTILS="true"
	fi

	
	DEPLOY_MARMOT_COMMON="false"
	DEPLOY_MARMOT_CLIENT="false"
	DEPLOY_UTILS="false"

	if [ "$BUILD" == "true" ];
	then
		
		sleep 0.2

		echo
		echo
		echo "############################################################################"
		echo "+++ START to 'BUILD' projects "
	
		# marmot.common
		if [ "$BUILD_MARMOT_COMMON" == "true" ];
		then
			build "marmot.common" "clean generateProto"
			build "marmot.common" "assemble"

			DEPLOY_MARMOT_COMMON="true"
		else
			not_updated "marmot.common"
		fi

		sleep 0.2

		# marmot.client
		if [ "$BUILD_MARMOT_CLIENT" == "true" ];
		then
			build "marmot.client" "assemble"

			DEPLOY_MARMOT_CLIENT="true"
		else
			not_updated "marmot.client"
		fi

		sleep 0.2

		# utils
		if [ "$BUILD_UTILS" == "true" ];
		then
			build "utils" "assemble"

			DEPLOY_UTILS="true"
		else
			not_updated "utils"
		fi

		echo
		echo "Completed build all."
		echo " - marmot.common"
		echo " - marmot.client"
		echo " - utils"

		echo "============================================================================"
	fi

	sleep 0.2

	echo
	echo
	echo "############################################################################"
	echo "+++ START to 'DEPLOY' to repository."

	# deploy to remote
	if [[ ! -z "$MVN_URL_REMOTE" ]] && [[ "$DEPLOY_REMOTE" == "true" ]] ;
	then

		if [ "$DEPLOY_MARMOT_COMMON" == "true" ];
		then
			mvn_deploy "marmot.common" "$MVN_URL_REMOTE"
		else
			not_updated "marmot.common"
		fi

		sleep 0.2
		
		if [ "$DEPLOY_MARMOT_CLIENT" == "true" ];
		then
			mvn_deploy "marmot.client" "$MVN_URL_REMOTE"
		else
			not_updated "marmot.client"
		fi

		sleep 0.2

		if [ "$DEPLOY_UTILS" == "true" ];
		then
			mvn_deploy "utils" "$MVN_URL_REMOTE"
		else
			not_updated "utils"
		fi

		echo
		echo "Complete remote deployment."
		echo " - marmot.common"
		echo " - marmot.client"
		echo " - utils"
	
	fi

	# deploy to local
	if [ ! -z "$MVN_URL_LOCAL" ];
	then

		sleep 0.2

		if [ "$DEPLOY_MARMOT_COMMON" == "true" ];
		then
			mvn_deploy "marmot.common" "$MVN_URL_LOCAL"
		else
			not_updated "marmot.common"
		fi
		
		sleep 0.2

		if [ "$DEPLOY_MARMOT_CLIENT" == "true" ];
		then
			mvn_deploy "marmot.client" "$MVN_URL_LOCAL"
		else
			not_updated "marmot.client"
		fi

		sleep 0.2
		
		if [ "$DEPLOY_UTILS" == "true" ];
		then
			mvn_deploy "utils" "$MVN_URL_LOCAL"
		else
			not_updated "utils"
		fi

		echo
		echo "Complete local deployment."
		echo " - marmot.common"
		echo " - marmot.client"
		echo " - utils"

	fi

	echo "============================================================================"

	exit 0

}||{
	echo "Oooooooooooooooooooooooops!!!"
	echo "Failed to build...."
}
