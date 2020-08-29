#!/bin/bash

#
# A script this complex should be written in Python so that the list of
# valid IAM groups could be automatically generated from the
# iam-groups.tf file.
#

# Remove the set of user files. This will ensure that users removed from
# the accounts.txt file are also deleted from AWS.
rm -f iam-group-membership.tf iam-user-*.if

VALID_IAM_GROUPS="administrators,console_users,developers"

for LINE in $(cat accounts.txt)
do
  echo "$LINE" | grep --silent "^#"
  [[ $? == 0 ]] && continue
  IAM_USER=$(echo $LINE | cut -d',' -f1)
  KEYBASE_ACCOUNT=$(echo $LINE | cut -d',' -f2)
  IAM_GROUP=$(echo $LINE | cut -d',' -f3)

  echo $VALID_IAM_GROUPS | grep --silent $IAM_GROUP
  if [ $? != 0 ]
  then
    echo "Invalid IAM Group. Please use one of these: $VALID_IAM_GROUPS"
    exit 1
  fi

  BANNER=$(figlet -f standard $(echo $IAM_USER | tr '[:lower:]' '[:upper:]') | sed -e 's/^/# /')
  USER_TF_FILE="iam-user-$IAM_USER.tf"

  echo "Processed: $IAM_USER"

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
resource "local_file" "${IAM_USER}_password" {
  sensitive_content = "-----BEGIN PGP MESSAGE-----\nComment: https://keybase.io/download\nVersion: Keybase Go 1.0.10 (linux)\n\n\${aws_iam_user_login_profile.${IAM_USER}.encrypted_password}\n-----END PGP MESSAGE-----\n"
  filename = "encrypted_password.$IAM_USER.txt"
  file_permission = "0600"
}
EOF

done

ADMINISTRATORS=""
CONSOLE_USERS=""
DEVELOPERS=""

for LINE in $(cat accounts.txt)
do
  echo "$LINE" | grep --silent "^#"
  [[ $? == 0 ]] && continue
  IAM_USER=$(echo $LINE | cut -d',' -f1)
  KEYBASE_ACCOUNT=$(echo $LINE | cut -d',' -f2)
  IAM_GROUP=$(echo $LINE | cut -d',' -f3)

  if [ $IAM_GROUP == "administrators" ]; then
    if [ "$ADMINISTRATORS" == "" ]; then
      ADMINISTRATORS="aws_iam_user.$IAM_USER.name"
    else
      ADMINISTRATORS="$ADMINISTRATORS,aws_iam_user.$IAM_USER.name"
    fi
  fi

  if [ $IAM_GROUP == "console_users" ]; then
    if [ "$CONSOLE_USERS" == "" ]; then
      CONSOLE_USERS="aws_iam_user.$IAM_USER.name"
    else
      CONSOLE_USERS="$CONSOLE_USERS,aws_iam_user.$IAM_USER.name"
    fi
  fi

  if [ $IAM_GROUP == "developers" ]; then
    if [ "$DEVELOPERS" == "" ]; then
      DEVELOPERS="aws_iam_user.$IAM_USER.name"
    else
      DEVELOPERS="$DEVELOPERS,aws_iam_user.$IAM_USER.name"
    fi
  fi

done

cat <<EOF > iam-group-membership.tf
resource "aws_iam_group_membership" "administrators" {
  name = "group-membership-administrators"
  users = [
    $ADMINISTRATORS
  ]
  group = aws_iam_group.administrators.name
}
resource "aws_iam_group_membership" "console_users" {
  name = "group-membership-console-users"
  users = [
    $CONSOLE_USERS
  ]
  group = aws_iam_group.console_users.name
}
resource "aws_iam_group_membership" "developers" {
  name = "group-membership-developers"
  users = [
    $DEVELOPERS
  ]
  group = aws_iam_group.developers.name
}
EOF
