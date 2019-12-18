# Makefile does following things:
# 1) Packages Terraform modules to a zip file
#    Usage: make package
# 2) Check: Check if module is already present in AWS S3 Registry
#	 Usage: make check AWS_ACCESS_KEY_ID="" AWS_SECRET_ACCESS_KEY=""
# 3) Publishes compressed modules file to AWS S3 Registry.
#    If packaged module is already present the script  exits with error message.
#    Usage: make push AWS_ACCESS_KEY_ID="" AWS_SECRET_ACCESS_KEY=""
# 4) Clean: Remove the zipped file from local
#	 Usage: make clean


#!make
include config.properties
SHELL := /bin/bash

INFO=$(shell echo `date +%Y-%m-%d-%H:%M:%S` [INFO])
ERROR=$(shell echo `date +%Y-%m-%d-%H:%M:%S` [ERROR])
WARN=$(shell echo `date +%Y-%m-%d-%H:%M:%S` [WARN])

MOD_FILENAME=$(MOD_NAME_PREFIX)$(MOD_VERSION)$(MOD_PACKAGE_EXT)

define check_var_defined
$(if $(1),,$(error $(2) is not defined))
endef

define check_module_exists
@MOD_CHECK=`aws s3 ls s3://$(1)/$(2)`;  		\
if [[ $${MOD_CHECK} =~ .*$(2).* ]]; then		\
	echo $(ERROR) Module $(2) Already Exists;	\
	exit 1;										\
else 											\
	echo $(INFO) Uploading Module  $(2) to $(1);\
fi
endef

check-aws-defined:
	$(call check_var_defined,$(AWS_ACCESS_KEY_ID),AWS_ACCESS_KEY_ID)
	$(call check_var_defined,$(AWS_SECRET_ACCESS_KEY),AWS_SECRET_ACCESS_KEY)
	$(call check_var_defined,$(MOD_AWS_BUCKET_NAME),MOD_AWS_BUCKET_NAME)

check-mod-defined:
	$(call check_var_defined,$(MOD_NAME_PREFIX),MOD_NAME_PREFIX)
	$(call check_var_defined,$(MOD_VERSION),MOD_VERSION)
	$(call check_var_defined,$(MOD_PACKAGE_EXT),MOD_PACKAGE_EXT)

package:| check-mod-defined
	@echo $(INFO) Package IBM module
	@tar -cvzf $(MOD_FILENAME) *
	@echo $(INFO) Successfuly packaged IBM module
		
check:|  check-aws-defined check-mod-defined
	@echo $(INFO) Check if Module $(MOD_FILENAME) is already available in AWS S3 $(MOD_AWS_BUCKET_NAME)
	$(call check_module_exists,$(MOD_AWS_BUCKET_NAME),$(MOD_FILENAME))

push: check
	@aws s3 cp $(MOD_FILENAME) s3://$(MOD_AWS_BUCKET_NAME)/
	@echo $(INFO) Successfully Uploaded Module  $(MOD_FILENAME) to $(MOD_AWS_BUCKET_NAME)

clean:| check-mod-defined
	@rm -fv ./$(MOD_FILENAME)

all: check-aws-defined check-mod-defined package check push clean

.PHONY: push package check clean all check-aws-defined check-mod-defined
