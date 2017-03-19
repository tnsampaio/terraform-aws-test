# terraform-aws-test
Test on how to use terraform to create a complete redmine deployment to AWS

1 - You need to be the onwer and the current user of ssh key applied to instances. IT'll be used to access
the instances to orchestrate the playbook with ansible.
2 - Change the SSH aws_key_pair to reflect your current public key
3 - You need to install and login aws cli tools to be able to build and upload images to ECR
4 - Set environment variable to inform your KEYs to access AWS services, eg:
 #export TF_VAR_username=<aws key>
 #export TF_VAR_password=<aws secret>
5 - Execute terraform:
 #terraform apply

6 - Enjoy it




