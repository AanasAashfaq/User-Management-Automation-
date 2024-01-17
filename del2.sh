#!/bin/bash

#disable, delete, add or archive accounts on local system

ARCHIVE_DIR='/archive'

view_account_info() {
    read -p "Enter the username to view account information: " USERNAME

    # Get user information and display it
    echo "~~~~~~~~~~Account Information for ${USERNAME}~~~~~~~~~~"
    echo
    id ${USERNAME}
    echo
    echo "Information about Account"
    #searching patterns
    grep ${USERNAME} /etc/passwd
    echo
    echo "Encrypted Password"
    grep ${USERNAME} /etc/shadow
    exit 1
    # Add any additional information you want to display
}

monitor_user() {
                # grep to find sessions in auth file and awk used for printing
		grep -E 'session opened|session closed' /var/log/auth.log | awk '{print $1, $2, $3, $11, $13}'
		echo 
		echo "List of Users for Administrator"
		exit 1
		
		
	
}

change_password() {
    read -p "Enter the username whose password you want to change: " USERNAME
    passwd ${USERNAME}
}


usage(){
#display the usage and exit
	echo
	echo
	echo -e '\t~~~~~UMS~~~~~'
	echo "Usage ${0} [-cdraR] USER [USERN]..." >&2
	echo '1. Create A local Linux account'
	echo -e '\t-c create user account'
	echo '2. Disable a local linux account' >&2
	echo -e '\t-d Delete account instead of disable' >&2
	echo -e '\t-r Removes Home Directory Associated with account'>&2
	echo -e '\t-a Create an archive of home directory associated with the account' >&2
	echo '3. Audit Report'
	echo -e '\t-R User login/logout Audit Report'
	echo '4. Change Passwords'
	echo -e '\t -p Change Users Passwords'
	exit 1
	
}

usage2(){
#display the usage and exit
	echo
	echo	
	echo -e '\t~~~~~UMS~~~~~'
	echo -e "PRIVILEGES\n Usage ${0} [-cpi] USER [USERN]..." >&2
	echo '1. Create A local Linux account'
	echo -e '\t-c create user account'
	echo '2. Disable a local linux account' >&2
	#echo -e '\t-d Delete account instead of disable' >&2
	#echo -e '\t-r Removes Home Directory Associated with account'>&2
	#echo -e '\t-a Create an archive of home directory associated with the account' >&2
	#echo '3. Audit Report'
	#echo -e '\t-R User login/logout Audit Report'
	echo '3. Change Passwords'
	echo -e '\t -p Change Users Passwords'
	echo '4. View User Account info'
	echo -e '\t -i view user account information'
	exit 1
	
}

if [[ "${UID}" -ne 0 ]]
then 
	echo 'Not an admin'
	exit 1
	
fi

# Parse the Options
while getopts cdraRpi OPTION
do
	case ${OPTION} in
	c) CREATE_USER='true';;
	d) DELETE_USER='true' ;;
	r) REMOVE_OPTION='-r' ;;
	a) ARCHIVE='true' ;;
	R) monitor_user_activity='true';;
           #exit 0 ;;
        p) change_user_password='true';;
        	#exit 0 ;;  
        i) view_acc='true';;
	?) usage ;;
  esac
done
 
#remove the options after process exe
shift "$(( OPTIND - 1 ))"


if [[ $1 -eq 123 ]];then
 if [[ ${monitor_user_activity} = 'true' ]]; then
 monitor_user
 fi
 if [[ ${change_user_password} = 'true' ]]; then
 change_password
 fi
 usage
fi

if [[ $1 -eq 321 ]];then
if [[ ${change_user_password} = 'true' ]]; then
 change_password
 fi
 if [[ ${view_acc} = 'true' ]];then
 view_account_info
 	
 fi
	usage2
fi

# IF USER DOESNT SUPPLY WITH ONE ARUGUMENT
if [[ "$2" -eq 123 || "$2" -eq 321 ]]; then
echo
#echo -e "\tADMING"
if [[ "${#}" -lt 1  ]]
then 
	usage
fi
if [[ "${CREATE_USER}" = 'true' ]]
then
	echo "User create thingy"
	for REAL_VAR in "$1"
	do
		read -p 'Enter the Username to create: ' USER_VAR

	#Get the Contents of description
	#1. get real name

	#read -p 'Enter the name of person who will use the account: ' REAL_VAR

	#Get the Password
	read -p 'Enter the new Password: ' PASSWORD_VAR

	#Confirm password

	#create the account
	useradd -c "${REAL_VAR}" -m ${USER_VAR}

	#Check to see if the useradd succeded

	if [[ "${?}" -ne 0 ]]
	then
 		echo 'the account was not created !!ERROR!!'
 	exit 1
fi

#Set the Password
#echo ${PASSWORD_VAR} | passwd --stdin ${USER_VAR}
echo "${USER_VAR}:${PASSWORD_VAR}" | chpasswd

if [[ "${?}" -ne 0 ]]
then
	echo 'The password could not be set'
	exit 1
fi

# force Password Change on First Login
passwd -e ${USER_VAR}



#Display the username, password, and the host where user was created
echo
echo
echo "~~~~~~Account Created~~~~~~~~"
echo 'Username: '
echo "${USER_VAR}"
echo
echo 'Password: '
echo "${PASSWORD_VAR}"
echo
echo 'Host: '
echo ${HOSTNAME}
	done
	exit 1
fi
fi
#loop through user names



for USERNAME in "$1"
do
	echo "Processing user: ${USERNAME}"
	
	#MAKE SURE THE UID IS ATLEAST 1000 
	# 1000 > ids for users
	 USERID=$(id -u ${USERNAME})
	 if [[ "${USERID}" -lt 1000  ]]
	 then
	 	echo "Refusing to remove the ${USERNAME} account with UID" >&2
	 	exit 1
	 fi
	
#Create an archive
  if [[ "${ARCHIVE}" = 'true' ]]
then 
	#make sure archive directory exists
	if [[ "$2" -eq 123 ]];then
	if [[ ! -d "${ARCHIVE_DIR}" ]]
	then
		#create dir
	        echo "Creating ${ARCHIVE_DIR} directory."
	        mkdir -p ${ARCHIVE_DIR}
		if [[ "${?}" -ne 0 ]]
		then 
			echo "the Directory creation failed"
			exit 1
		fi
	fi
	
	#archive creation sucess now
	#archive the user home directory
	HOME_DIR="/home/${USERNAME}"
	ARCHIVE_FILE="${ARCHIVE_DIR}/${USERNAME}.tgz"
	if [[ -d "${HOME_DIR}" ]]
	then
		echo "archieving the ${HOME_DIR} to ${ARCHIVE_FILE}"
		tar -zcf ${ARCHIVE_FILE} ${HOME_DIR} &> /dev/null
		if [[ "${?}" -ne 0 ]]
		then 
			echo "Could not Create ${ARCHIVE_FILE}" >&2
			exit 1
		fi
	else
		echo "${HOME_DIR} doesnt exist or not dir"
		exit 1
	fi
		exit 1
	fi
	echo "Not An Admin"
	exit 1	
	fi
	
	
	
	
	if [[ "${DELETE_USER}" = 'true' ]]
	then
		if [[ "$2" -eq 123 ]];then
		#"Delete the use"
		userdel ${REMOVE_OPTION} ${USERNAME}
		
		#check to see if del success
		if [[ "${?}" -ne 0 ]]
		then
		 	echo "The account ${USERNAME} Was not deleted"
		 	exit 1
		 fi
		 
		 echo "The acccount deleteion of ${USERNAME} was Success"
		 exit 1
		fi
		echo "Only Administrator have Priviliges to delete account"
		 
	else
		if [[ "$2" -eq 123 || "$2" -eq 321 ]];then
		# setting the account expire date to 0
		chage -E 0 ${USERNAME}
		if [[ "${?}" -ne 0 ]]
		then 
			echo "The account ${USERNAME} was not Disabled" >&2
			exit 1
		fi
		
		echo "The account ${USERNAME} was disabled"
		exit 1
		fi
		echo "Not an admin or IT Support"
	fi
done
exit 1

echo "Not an Admin"
exit 0
		
		
		
		
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	







