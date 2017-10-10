#!/bin/bash -e

set -o pipefail

export CURR_JOB=$1
export RES_REL=$2
export AMI_ID=$3
export AMI_TYPE=$4
export SHIPPABLE_NODE_INIT_SCRIPT=$5
export KERNEL_DOWN=$6

export RES_REPO="bldami_repo"
export RES_AWS_CREDS="aws_v2_bits_access"
export RES_PARAMS="baseami_params"

# since resources here have dashes Shippable replaces them and UPPER cases them
export RES_REL_UP=$(echo $RES_REL | awk '{print toupper($0)}')
export RES_REL_VER_NAME=$(eval echo "$"$RES_REL_UP"_VERSIONNAME")
export RES_REL_VER_NAME_DASH=${RES_REL_VER_NAME//./-}

# set the repo path
export RES_REPO_UP=$(echo $RES_REPO | awk '{print toupper($0)}')
export RES_REPO_STATE=$(eval echo "$"$RES_REPO_UP"_STATE")

# Now get AWS keys
export RES_AWS_CREDS_UP=$(echo $RES_AWS_CREDS | awk '{print toupper($0)}')
export RES_AWS_CREDS_INT=$RES_AWS_CREDS_UP"_INTEGRATION"

# since resources here have dashes Shippable replaces them and UPPER cases them
export RES_PARAMS_UP=$(echo $RES_PARAMS | awk '{print toupper($0)}')
export RES_PARAMS_STR=$RES_PARAMS_UP"_PARAMS"

set_context(){
  # now get all the parameters for ami location
  export REGION=$(eval echo "$"$RES_PARAMS_STR"_REGION")
  export VPC_ID=$(eval echo "$"$RES_PARAMS_STR"_VPC_ID")
  export SUBNET_ID=$(eval echo "$"$RES_PARAMS_STR"_SUBNET_ID")
  export SECURITY_GROUP_ID=$(eval echo "$"$RES_PARAMS_STR"_SECURITY_GROUP_ID")

  # now get the AWS keys
  export AWS_ACCESS_KEY_ID=$(eval echo "$"$RES_AWS_CREDS_INT"_ACCESSKEY")
  export AWS_SECRET_ACCESS_KEY=$(eval echo "$"$RES_AWS_CREDS_INT"_SECRETKEY")

  echo "CURR_JOB=$CURR_JOB"
  echo "RES_REL=$RES_REL"
  echo "RES_REPO=$RES_REPO"
  echo "RES_AWS_CREDS=$RES_AWS_CREDS"
  echo "RES_PARAMS=$RES_PARAMS"

  echo "RES_REL_UP=$RES_REPO_UP"
  echo "RES_REL_VER_NAME=$RES_REPO_STATE"
  echo "RES_REL_VER_NAME_DASH=$RES_REL_VER_NAME_DASH"
  echo "RES_REPO_UP=$RES_REPO_UP"
  echo "RES_REPO_STATE=$RES_REPO_STATE"
  echo "RES_AWS_CREDS_UP=$RES_AWS_CREDS_UP"
  echo "RES_AWS_CREDS_INT=$RES_AWS_CREDS_INT"

  echo "RES_PARAMS_UP=$RES_PARAMS_UP"
  echo "RES_PARAMS_STR=$RES_PARAMS_STR"

  echo "REGION=$REGION"
  echo "VPC_ID=$VPC_ID"
  echo "SUBNET_ID=$SUBNET_ID"
  echo "SECURITY_GROUP_ID=$SECURITY_GROUP_ID"
  echo "AWS_ACCESS_KEY_ID=${#AWS_ACCESS_KEY_ID}" #print only length not value
  echo "AWS_SECRET_ACCESS_KEY=${#AWS_SECRET_ACCESS_KEY}" #print only length not value
  echo "AMI_ID=$AMI_ID"
  echo "AMI_TYPE=$AMI_TYPE"
  echo "SHIPPABLE_NODE_INIT_SCRIPT=$SHIPPABLE_NODE_INIT_SCRIPT"
  echo "KERNEL_DOWN=$KERNEL_DOWN"
}

build_ami() {
  pushd "$RES_REPO_STATE/exec"
  echo "-----------------------------------"

  echo "validating AMI template"
  echo "-----------------------------------"
  packer validate execAMITmp.json
  echo "building AMI"
  echo "-----------------------------------"

  packer build -machine-readable -var aws_access_key=$aws_access_key_id \
    -var aws_secret_key=$aws_secret_access_key \
    -var REGION=$REGION \
    -var VPC_ID=$VPC_ID \
    -var SUBNET_ID=$SUBNET_ID \
    -var SECURITY_GROUP_ID=$SECURITY_GROUP_ID \
    -var AMI_ID=$AMI_ID \
    -var AMI_TYPE=$AMI_TYPE \
    -var REL_VER=$RES_REL_VER_NAME \
    -var REL_DASH_VER=$RES_REL_VER_NAME_DASH \
    -var SHIPPABLE_NODE_INIT_SCRIPT=$SHIPPABLE_NODE_INIT_SCRIPT \
    -var KERNEL_DOWN=$KERNEL_DOWN \
    execAMITmp.json 2>&1 | tee output.txt

    #this is to get the ami from output
    echo versionName=$(cat output.txt | awk -F, '$0 ~/artifact,0,id/ {print $6}' \
    | cut -d':' -f 2) > /build/state/$CURR_JOB.env

    echo "RES_REL_VER_NAME=$RES_REL_VER_NAME" >> /build/state/$CURR_JOB.env
    echo "RES_REL_VER_NAME_DASH=$RES_REL_VER_NAME_DASH" >> /build/state/$CURR_JOB.env
  popd
}

main() {
  eval `ssh-agent -s`
  ps -eaf | grep ssh
  which ssh-agent

  set_context
  build_ami
}

main
