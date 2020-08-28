#!/bin/bash

IAM_USER=$1
KEYBASE_ACCOUNT=$2
IAM_ROLE=$3

if [ -z $IAM_USER ]
then
  echo "Usage: $0 <iam_user> <keybase_account> <iam_role>"
  echo "  Missing iam user parameter."
  exit 1
fi

if [ -z $KEYBASE_ACCOUNT ]
then
  echo "Usage: $0 <iam_user> <keybase_account> <iam_role>"
  echo "  Missing keybase account parameter."
  exit 1
fi

if [ -z $IAM_ROLE ]
then
  echo "Usage: $0 <iam_user> <keybase_account> <iam_role>"
  echo "  Missing iam role parameter."
  exit 1
fi

VALID_IAM_ROLES="administrators,console_users,developers"

echo $VALID_IAM_ROLES | grep $IAM_ROLE
if [ $? != 0 ]
then
  echo "Invalid IAM Role. Please use one of these: $VALID_IAM_ROLES"
  exit 1
fi

BANNER=$(figlet -f standard $(echo $IAM_USER | tr '[:lower:]' '[:upper:]') | sed -e 's/^/# /')
USER_TF_FILE="user-$IAM_USER.tf"

cat <<EOF > $USER_TF_FILE
$BANNER

resource "aws_iam_user" "$IAM_USER" {
  name = "$IAM_USER"
}
resource "aws_iam_access_key" "$IAM_USER" {
  user = aws_iam_user.$IAM_USER.id
}
resource "aws_iam_user_login_profile" "$IAM_USER" {
  user    = aws_iam_user.$IAM_USER.id
  pgp_key = "keybase:$KEYBASE_ACCOUNT"
}
resource "aws_iam_group_membership" "$IAM_USER" {
  name = "group-membership-$IAM_USER"
  users = [
    aws_iam_user.$IAM_USER.name
  ]
  group = aws_iam_group.$IAM_ROLE.name
}
resource "local_file" "${IAM_USER}_password" {
  sensitive_content = "-----BEGIN PGP MESSAGE-----\nComment: https://keybase.io/download\nVersion: Keybase Go 1.0.10 (linux)\n\n\${aws_iam_user_login_profile.davidm.encrypted_password}\n-----END PGP MESSAGE-----\n"
  filename = "encrypted_password.$IAM_USER.txt"
  file_permission = "0600"
}
EOF

cat $USER_TF_FILE
