
build-wheel:
	python setup.py bdist_wheel


add-extension:
	az extension add --source ./dist/apim_tf_export-0.0.1-py2.py3-none-any.whl --yes --upgrade

terraform-init:
	cd example \
	&& terraform init

deploy-dev:
	./scripts/tf-apply.sh --environment dev

deploy-test:
	./scripts/tf-apply.sh --environment test
