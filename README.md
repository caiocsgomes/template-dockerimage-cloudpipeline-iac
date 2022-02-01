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
## How Codepipeline works in stages

CodePipeline allows us to build a CI/CD as a workflow, so we build the steps we need for the desired output. In out case we need to get the code from a source repository, build it ans push it to a docker repository. In a production environment we would have other steps, but we are simplifying in a simpler project to get a grasp of how it works.

The first stage on any CodePipeline pipeline must be the *Source*, this is where we get the code to work with. In this stage we define the provider as GitHub and pass the configuration so that the pipeline has access to it. In the *OutputArtifacts* action property we define the name of our output (our code) that will be the input for the next stage.

In the second stage we get the code from the first one and use it to build our docker image. See that the second stage references a code build project in its configurations. Inside the CodeBuild project we define our build environment variables, and everything we need to build ou project. CodeBuild builds code inside a container, so we need to define an image to use as well. CodeBuild will take the source code, copy to the container and build it inside it.

```yml
Pipeline:
  Type: AWS::CodePipeline::Pipeline
  Properties:
    Name: PipelineForFlaskApi
    RoleArn: !GetAtt PipelineRole.Arn
    ArtifactStore:
      Type: S3
      Location: !Ref ArtifactBucket
    Stages:
      - Name: Source
        Actions:
          - Name: Source
            ActionTypeId:
              Category: Source
              Owner: ThirdParty
              Provider: GitHub
              Version: "1"
            OutputArtifacts:
              - Name: SourceCode
            Configuration:
              Owner: !Ref GithubAccount
              Repo: !Ref GithubRepository
              PollForSourceChanges: false
              Branch: !Ref GithubBranch
              OAuthToken: !Ref GithubAuthToken
      - Name: Build
        Actions:
          - Name: Build
            ActionTypeId:
              Category: Build
              Owner: AWS
              Provider: CodeBuild
              Version: "1"
            InputArtifacts:
              - Name: SourceCode
            Configuration:
              ProjectName: !Ref CodeBuildProject
  DependsOn: EcrRepository
CodeBuildProject:
  Type: AWS::CodeBuild::Project
  Properties:
    Artifacts:
      Type: CODEPIPELINE
    Description: "Codebuild project to push flask api image to ecr"
    Environment:
      ComputeType:
        !FindInMap [CodeBuildComputeTypeMap, !Ref GithubBranch, type]
      EnvironmentVariables:
        - Name: AWS_DEFAULT_REGION
          Value: !Ref AWS::Region
        - Name: AWS_ACCOUNT_ID
          Value: !Ref "AWS::AccountId"
        - Name: AWS_ECR_REPOSITORY_URI
          Value: !Sub ${AWS::AccountId}.dkr.ecr.${AWS::Region}.amazonaws.com/${EcrRepository}
        - Name: IMAGE_REPO_NAME
          Value: !Ref GithubRepository
        - Name: IMAGE_TAG
          Value: "latest"
      Image: "aws/codebuild/standard:5.0"
      PrivilegedMode: true
      Type: "LINUX_CONTAINER"
    ServiceRole: !GetAtt CodeBuildRole.Arn
    Source:
      Type: "CODEPIPELINE"
      BuildSpec: pipeline/buildspec.yml
```

Another important file is the [*buildspec.yml*](https://docs.aws.amazon.com/codebuild/latest/userguide/build-spec-ref.html). Inside it we define everything we need to do on the code to build it. So in our case we take the code, build the image and push it to ECR. All of the variables we are using come from the *CodeBuild* project on the *CloudFormation* template.

``` yml
version: 0.2

phases:
  pre_build:
    commands:
      - echo Logging in to Amazon ECR...
      - aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com
  build:
    commands:
      - echo Build started on `date`
      - echo Building the Docker image...
      - cd app/
      - docker build -t $IMAGE_REPO_NAME:$IMAGE_TAG .
      - docker tag $IMAGE_REPO_NAME:$IMAGE_TAG $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$IMAGE_REPO_NAME:$IMAGE_TAG
  post_build:
    commands:
      - echo Build completed on `date`
      - echo Pushing the Docker image...
      - docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$IMAGE_REPO_NAME:$IMAGE_TAG
```

## The artifacts bucket

Artifacts are anything produced by CodePipeline like source code, built applications, etc. CodePipeline moves artifacts between stages. In our case the first stage produces an artifact that is our source code and the second stage uses it to build the application. Since we need storage to do this we need an S3 bucket that will store all the artifacts produced by CodePipeline.

## How to build it

These are the commands to be executed at the root of the project to create, update and delete the pipeline. You need to have the [aws cli](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html) configured to run them, and also replace the *parameters.json* with your variables.

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

