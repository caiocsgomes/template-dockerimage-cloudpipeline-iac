#Resources

https://docs.aws.amazon.com/codepipeline/latest/userguide/appendix-github-oauth.html#action-reference-GitHub
https://docs.aws.amazon.com/codepipeline/latest/userguide/reference-pipeline-structure.html#action-requirements

#Commands:
```bash
aws cloudformation create-stack --stack-name flask-api-pipeline --template-body file://pipeline/pipeline.yml  --parameters file://pipeline/parameters-dev.json --capabilities CAPABILITY_IAM
```
```bash
aws cloudformation update-stack --stack-name flask-api-pipeline --template-body file://pipeline/pipeline.yml  --parameters file://pipeline/parameters-dev.json --capabilities CAPABILITY_IAM
```
```bash
aws cloudformation delete-stack --stack-name flask-api-pipeline
```

