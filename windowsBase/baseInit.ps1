$ErrorActionPreference = "Stop"

$NODE_ARCHITECTURE = "x86_64"
$NODE_OPERATING_SYSTEM = "WindowsServer_2016"
$SHIPPABLE_RELEASE_VERSION = "master"
$SHIPPABLE_AMI_VERSION = "master"
$EXEC_IMAGE = "drydock/w16reqproc:master"
$REQKICK_DIR = "$env:USERPROFILE/Shippable/reqKick"
$NODE_SCRIPTS_LOCATION = "$env:USERPROFILE/node"
$NODE_SHIPCTL_LOCATION = "$NODE_SCRIPTS_LOCATION/shipctl"
$INIT_SCRIPT_NAME = "Docker_17.06.ps1"
$NODE_SCRIPTS_DOWNLOAD_LOCATION = "$env:TEMP/node.zip"
$NODE_DOWNLOAD_URL = "http://shippable-artifacts.s3.amazonaws.com/node/master/node-master.zip"
$REQKICK_DOWNLOAD_URL = "http://shippable-artifacts.s3.amazonaws.com/reqKick/master/reqKick-master.zip"
$SHIPPABLE_FIREWALL_RULE_NAME = "shippable-docker"

Function __process_msg([string] $msg) {
  echo "|___ $msg"
}

__process_msg "downloading node scripts zip package"
Invoke-RestMethod "$NODE_DOWNLOAD_URL" -OutFile $NODE_SCRIPTS_DOWNLOAD_LOCATION

__process_msg "creating node scripts dir"
mkdir -p $NODE_SCRIPTS_LOCATION

__process_msg "extracting node scripts"
Expand-Archive $NODE_SCRIPTS_DOWNLOAD_LOCATION -DestinationPath $NODE_SCRIPTS_LOCATION

__process_msg "Initializing node"
& "$NODE_SCRIPTS_LOCATION/initScripts/$NODE_ARCHITECTURE/$NODE_OPERATING_SYSTEM/$INIT_SCRIPT_NAME"
