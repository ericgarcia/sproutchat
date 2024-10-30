## Setting up AWS
This is the login url for this project:
```
https://d-9067d92e28.awsapps.com/start
```

This is the account ID:
```
468435965000
```

### How to Use SSO Profiles with eksctl or Other Tools
Since eksctl and some other AWS tools may not directly recognize SSO profiles, you can use a few methods to work around this:

#### 1. Run aws sso login Manually When Required:

If you get an authentication error, run:
```bash
aws sso login --profile AdministratorAccess-468435965000
```
This will refresh the SSO session token for your profile.
#### 2. Set Environment Variables After SSO Login:

After logging in with aws sso login, you can export environment variables for temporary credentials if needed:
```bash
export AWS_PROFILE=AdministratorAccess-468435965000
```

To verify that you're logged in correctly after using AWS SSO, you can run a few commands to check the authentication status and ensure your profile is working as expected. Here’s how:

### 1. **List Your AWS Identity**

Run the following command to confirm that your credentials are valid and that you’re logged in with the correct profile:

```bash
aws sts get-caller-identity --profile AdministratorAccess-468435965000
```

This command should output details about your account, such as:
- **Account ID**
- **User/Role ARN**
- **User ID**

If you see an error, such as `ExpiredToken` or `AccessDenied`, this means your session might have expired, or there’s an issue with your SSO setup.

### 2. **Check AWS Resource Access**

You can run a simple command to confirm access to a specific service, like EC2, within the intended region:

```bash
aws ec2 describe-instances --profile AdministratorAccess-468435965000 --region us-east-1
```

This should return a list of EC2 instances if they exist in that region, or an empty response if no instances are running. If there’s an authentication issue, it will provide an error message.

### 3. **Confirm Environment Variable Setting (Optional)**

Since you’ve exported the `AWS_PROFILE` environment variable, verify it by running:

```bash
echo $AWS_PROFILE
```

It should output `AdministratorAccess-468435965000`. This confirms that your shell session is using the correct profile.

These steps will ensure that your AWS SSO login and profile configuration are working correctly.

The response `{"Reservations": []}` indicates that your AWS credentials and profile are working correctly, but there are no EC2 instances currently running in the `us-east-1` region for your account.

To double-check that everything is set up correctly, here are a few additional verification steps:

1. **Confirm Other AWS Resources**: If you have other resources like S3 buckets, you can list them to ensure access.
   ```bash
   aws s3 ls --profile AdministratorAccess-468435965000
   ```

2. **Attempt a Simple EC2 Action**: Try launching a small EC2 instance as a further test.
   ```bash
   aws ec2 run-instances \
       --profile AdministratorAccess-468435965000 \
       --region us-east-1 \
       --image-id ami-0aada1758622f91bb \
       --instance-type t2.micro \
       --key-name dev_key \
       --security-group-ids sg-0478f052a083dfd5b
   ```
   Replace `my-key-pair` and `sg-xxxxxxxx` with your actual key pair name and security group ID.

3. **Verify AWS Account Permissions**: If launching an instance doesn’t work, there may be permission restrictions in place within your AWS account. In that case, you may need to contact your administrator to ensure your AWS SSO role (`AdministratorAccess-468435965000`) has sufficient EC2 permissions.

If the above actions are successful, you can be confident your login and profile are set up correctly!