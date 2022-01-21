all: validate_templates create_pipeline_stack

validate_templates:
	aws cloudformation validate-template --template-body file://pipeline/pipeline.yml

create_pipeline_stack:
	aws cloudformation create-stack \
	--stack-name flask-api-pipeline \
	--template-body file://pipeline/pipeline.yml  \
	--parameters file://pipeline/parameters-dev.json \
	--capabilities CAPABILITY_IAM

update_pipeline_stack:
	aws cloudformation update-stack \
	--stack-name flask-api-pipeline \
	--template-body file://pipeline/pipeline.yml  \
	--parameters file://pipeline/parameters-dev.json \
	--capabilities CAPABILITY_IAM