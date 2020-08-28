# Create IAM Users With Terraform And Keybase

Provides IAM user management with Terraform scripts. Keybase provides security for initial temporary password.

## Configuration

* Create the `terraform.tfvars` file according to your needs. The profile name corresponds to entries in your `~/.aws/credentials` file.

```bash
cat <<EOF >terraform.tfvars
aws_profile_name = "personal"
region           = "us-east-1"
EOF
```

* Adjust the contents of `iam-groups.tf` as needed. This file defines the `aws_iam_group`, `aws_iam_policy` and `aws_iam_group_policy_attachment` associated with IAM and the users you will create.

    * Here is an example of a group definition.

```
  resource "aws_iam_group" "administrators" {
  name = "administrators"
  path = "/"
}
```

    * Here is an example of a policy definition. I am using pre-defined policies. Custom policies can be used but are a little more involved to define.

```
data "aws_iam_policy" "AdministratorAccess" {
  arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}
```

    * Here is an examlpe of a group policy attachment. Each policy attached to a group requires its own Terraform resource.

```
resource "aws_iam_group_policy_attachment" "administrator" {
  group = aws_iam_group.administrators.name
  policy_arn = data.aws_iam_policy.AdministratorAccess.arn
}
```

* Initialize Terraform.

```bash
terraform init
```

* Apply Terraform using a helper script that ensures a log file is created of all output. Very helpful for validating the application or for debugging when something goes horribly wrong.

```
./tfa
```

