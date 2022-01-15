all: validate_templates create_stack

validate_templates:
	aws cloudformation validate-template --template-body file://pipeline/pipeline.yml

create_stack:
	aws cloudformation create-stack \
	--stack-name flask-api-pipeline \
	--template-body file://pipeline/pipeline.yml  \
	--parameters file://pipeline/parameters-dev.json \
	--capabilities CAPABILITY_IAM