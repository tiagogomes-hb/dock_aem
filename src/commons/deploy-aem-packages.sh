#!/bin/bash

AEM_PORT=4502
AEM_HOST=localhost
AEM_CREDENTIALS="admin:admin"
MODULE="all"

function usage
{
	echo "usage: ./deploy-aem-packages.sh [-h localhost] [-p 4502] [-u 'user:pass'] [-m (all|third-party|ui.apps|ui.content|ui.newsletters|frontend)] [-s 'C:/path/to/project/root'] [-?]"
}

function help
{
	usage
	echo ""
	echo "---Parameters---"
	echo "-h  | --hostname       - Sets the AEM instance hostname to use. Default is localhost"
    echo "-p  | --port           - Sets the AEM instance port to use. Default is 4502"
	echo "-u  | --user-creds     - AEM user credentials in format user:pass. Default is admin:admin"
	echo "-m  | --module         - AEM module to deploy. Possible values are: all, third-party, ui.apps, ui.content, ui.newsletter, frontend. Default is all"
    echo "-s  | --source-project - Sets the root folder of your project where the AEM packages are built. Use PROJECT_SRC_DIR environment variable alternatively."
	echo "-h  | --help           - Displays this message"
}

function installPackage
{
    if [ ! -f "$PROJECT_SRC_DIR$MODULE_PATH" ]; then
        echo "Package $PROJECT_SRC_DIR$MODULE_PATH does not exist, please build the project first."
        exit 1
    fi

    echo "Installing package $PROJECT_SRC_DIR$MODULE_PATH ..."
	curl -u $AEM_CREDENTIALS --fail -F file=@"$PROJECT_SRC_DIR$MODULE_PATH" -F force=true -F install=true $HOST/crx/packmgr/service.jsp
}

while [ "$1" != "" ]; do
	case $1 in
		-h | --hostname )	    shift
								AEM_HOST=$1
								;;
		-p | --port )	        shift
								AEM_PORT=$1
								;;
		-u | --user-creds )		shift
								AEM_CREDENTIALS=$1
								;;
		-m | --module )		    shift
								MODULE=$1
								;;
        -s | --source-project )	shift
								PROJECT_SRC_DIR=$1
								;;
		-? | --help )		    help
								exit
								;;
		* )						usage
								exit 1
	esac
	shift
done

HOST=http://$AEM_HOST:$AEM_PORT

echo "Using AEM instance at: $HOST"

if [ -z "${PROJECT_SRC_DIR}" ]; then
    echo "PROJECT_SRC_DIR is not defined, please set it to the root folder of your project."
else
    echo "Installing packages built under ${PROJECT_SRC_DIR} into ${HOST} ..."

    case $MODULE in
		all )	        MODULE_PATH=/third-party/target/third-party-1.0-SNAPSHOT.zip
                        installPackage
                        MODULE_PATH=/ui/apps/target/ui.apps-1.0-SNAPSHOT.zip
                        installPackage
                        MODULE_PATH=/ui/content/target/ui.content-1.0-SNAPSHOT.zip
                        installPackage
                        MODULE_PATH=/ui/newsletter/target/ui.newsletter-1.0-SNAPSHOT.zip
                        installPackage
                        MODULE_PATH=/frontend/target/frontend-1.0-SNAPSHOT.zip
                        installPackage
                        ;;
		third-party )	MODULE_PATH=/third-party/target/third-party-1.0-SNAPSHOT.zip
                        installPackage
                        ;;
		ui.apps )		MODULE_PATH=/ui/apps/target/ui.apps-1.0-SNAPSHOT.zip
                        installPackage
                        ;;
		ui.content )    MODULE_PATH=/ui/content/target/ui.content-1.0-SNAPSHOT.zip
                        installPackage
                        ;;
        ui.newsletter )	MODULE_PATH=/ui/newsletter/target/ui.newsletter-1.0-SNAPSHOT.zip
                        installPackage
                        ;;
		frontend )		MODULE_PATH=/frontend/target/frontend-1.0-SNAPSHOT.zip
                        installPackage
                        ;;
        * )				echo "Unknown module: $MODULE"
                        exit 1
	esac

    echo "Project installed."
fi