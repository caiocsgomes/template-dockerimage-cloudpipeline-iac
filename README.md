# How to build a pipeline using Cloudformation to push an image to ECR

This repository will show and explain how to build a pipeline as code using Cloudformation. We will connect a github webhook to codepipeline that will trigger it and start codebuild to build the image and push it to ECR

## Creating the github webhook

## The ECR Repository

## The artifacts bucket

## How Codepipeline works in stages

## The buildspec file

### Resources

https://docs.aws.amazon.com/codepipeline/latest/userguide/appendix-github-oauth.html#action-reference-GitHub
https://docs.aws.amazon.com/codepipeline/latest/userguide/reference-pipeline-structure.html#action-requirements

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

