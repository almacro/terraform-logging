# Terraform Test User

Creates a dedicated IAM user with minimal permissions for running integration tests.

## Why Use a Dedicated Test User?

1. **Least Privilege**: Only has permissions needed to test the logging module
2. **Isolation**: Separate from production credentials
3. **Auditability**: Easy to track test activity in CloudTrail
4. **Safety**: Cannot accidentally affect production resources

## Permissions Granted

| Resource Pattern | Permissions |
|------------------|-------------|
| `s3:tf-test-*` | Create, configure, delete buckets |
| `iam:role/log-writer-*` | Create, manage roles |
| `iam:role/log-reader-*` | Create, manage roles |
| `iam:policy/log-writer-*` | Create, manage policies |
| `iam:policy/log-reader-*` | Create, manage policies |
| `sts:GetCallerIdentity` | Identity verification |

## Usage

### 1. Create the Test User

```bash
cd test-user
terraform init
terraform apply
```

### 2. Get Credentials

```bash
# View the access key ID
terraform output access_key_id

# View the secret (sensitive)
terraform output -raw secret_access_key

# Or get the full profile config
terraform output -raw aws_profile_config >> ~/.aws/credentials
```

### 3. Configure AWS CLI Profile

Add to `~/.aws/credentials`:
```ini
[terraform-test]
aws_access_key_id = <from output>
aws_secret_access_key = <from output>
```

Add to `~/.aws/config`:
```ini
[profile terraform-test]
region = us-west-1
```

### 4. Run Integration Tests

```bash
cd ..
AWS_PROFILE=terraform-test ./bin/terraform test -test-directory=tests/integration
```

### 5. Use the Test User ARN

The test user ARN can be used as the trusted principal:

```bash
# Get the ARN
cd test-user
terraform output test_user_arn
```

Then in your test variables:
```hcl
variables {
  log_writer_trusted_arns = ["arn:aws:iam::ACCOUNT:user/test/terraform-test-runner"]
  log_reader_trusted_arns = ["arn:aws:iam::ACCOUNT:user/test/terraform-test-runner"]
}
```

## Cleanup

```bash
cd test-user
terraform destroy
```

## Security Notes

- Access keys are stored in Terraform state - protect your state file
- Rotate keys periodically
- Consider using `terraform apply -target=aws_iam_access_key.test_runner` to rotate keys
- The user path `/test/` makes it easy to identify and audit test users
