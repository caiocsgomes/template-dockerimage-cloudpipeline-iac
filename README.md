# How to build a pipeline using Cloudformation to push an image to ECR

This repository will show and explain how to build a pipeline as code using Cloudformation. We will connect a github webhook to codepipeline that will trigger it and start codebuild to build the image and push it to ECR.

All the pipeline is written in Cloudformation and no action on the console is necessary, this way we avoid manual steps that are hard to reproduce and can make versioning control.

## Creating the github webhook

Since github will trigger the pipeline when it detects code changes, we need to create a webhook on it. Webhook is basically an integration method. Every time github detects an event, like a push, it will send an HTTP POST payload to the webhook's configured URL with data about the event. Consult the github docs (https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token) and follow the instructions to create it. The 

The `AWS::CodePipeline::Webhook` resource is able to provision the github webhook and register it for you, the only necessary action is to create it on github. For the scopes (permissions) select *admin:repo_hook* and *repo*, it should look like this:

## The ECR Repository

## The artifacts bucket

## How Codepipeline works in stages

## The buildspec file

### Resources

https://docs.aws.amazon.com/codepipeline/latest/userguide/appendix-github-oauth.html#action-reference-GitHub
https://docs.aws.amazon.com/codepipeline/latest/userguide/reference-pipeline-structure.html#action-requirements
https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token

### Commands:
```bash
aws cloudformation create-stack --stack-name flask-api-pipeline --template-body file://pipeline/pipeline.yml  --parameters file://pipeline/parameters-dev.json --capabilities CAPABILITY_IAM
```
```bash
aws cloudformation update-stack --stack-name flask-api-pipeline --template-body file://pipeline/pipeline.yml  --parameters file://pipeline/parameters-dev.json --capabilities CAPABILITY_IAM
```
```bash
aws cloudformation delete-stack --stack-name flask-api-pipeline
```

