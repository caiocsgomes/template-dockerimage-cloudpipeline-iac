# How to build a pipeline using Cloudformation to push a Docker image to ECR

This repository will show and explain how to build a pipeline as code using Cloudformation. We will connect a github webhook to codepipeline that will trigger it and start codebuild to build the Docker image and push it to ECR.

All the pipeline is written in Cloudformation and no action on the console is necessary, this way we avoid manual steps that are hard to reproduce and can make versioning control.

All of the code is in this repository, and the steps to build it are at the end of this guide, on the [how to build](https://github.com/caiocsgomes/image-pipeline-cloudformation#the-ecr-repository) section.

The `pipeline` folder contains the codepipeline files. `pipeline.yml` with the Cloudformation stack to create the pipeline, the `buildspec.yml` with the Codebuild specification to build the image and push to ECR and the `parameters.json` with all parameters used on the pipeline.

The `app` folder contains a simple python app that we will use as an example to build an image, our focus here is on the pipeline as code. In the next sections we will dive in each component and steps required to build it.

## Creating the github webhook

Since github will trigger the pipeline when it detects code changes, we need to create a webhook on it. A webhook is basically an integration method. Every time github detects an event, like a push, it will send an HTTP POST payload to the webhook's configured URL with data about the event. Consult the [github docs](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token) and follow the instructions to create it.

The [`AWS::CodePipeline::Webhook`](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-codepipeline-webhook.html) resource is able to provision the github webhook and register it for you, the only necessary action is to create it on github. For the scopes (permissions) select *admin:repo_hook* and *repo*, it should look like this:

![webhook permissions](https://github.com/caiocsgomes/image-pipeline-cloudformation/blob/media/webhook_permission.png)

The parameter **GithubAuthToken** is your personal token generated on this step. The other important parameter is the **Branch**, the pipeline will trigger with changes to this branch only.

``` yml
Webhook:
    Type: "AWS::CodePipeline::Webhook"
    Properties:
      Authentication: "GITHUB_HMAC"
      AuthenticationConfiguration:
        SecretToken: !Ref GithubAuthToken
      RegisterWithThirdParty: true
      TargetPipeline: !Ref Pipeline
      TargetAction: Source
      TargetPipelineVersion: !GetAtt Pipeline.Version
      Filters:
        - JsonPath: "$.ref"
          MatchEquals: refs/heads/{Branch}
```
## The ECR Repository

The [`AWS::ECR::Repository`](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-ecr-repository.html) creates a container registry where we can push our images, I usually name them with my github repository name.

``` yml
EcrRepository:
    Type: AWS::ECR::Repository
    Properties:
      RepositoryName: !Ref GithubRepository
```

## The artifacts bucket

## How Codepipeline works in stages

## The buildspec file

## How to build it

These are the commands to be executed at the root of the project to create, update and delete the pipeline. You need to have the [aws cli](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html) configured to run them.

```bash
# create the stack
aws cloudformation create-stack --stack-name my-iaas-pipeline --template-body file://pipeline/pipeline.yml  --parameters file://pipeline/parameters.json --capabilities CAPABILITY_IAM
```

```bash
# update the stack
aws cloudformation update-stack --stack-name my-iaas-pipeline --template-body file://pipeline/pipeline.yml  --parameters file://pipeline/parameters.json --capabilities CAPABILITY_IAM
```

```bash
# delete the stack
aws cloudformation delete-stack --stack-name my-iaas-pipeline
```

