PROJECT=click_example
ifeq ("$(shell uname -s)", "Linux*")
	BROWSER=/usr/bin/firefox
else
	BROWSER=open
endif
MOUNT_DIR=$(shell pwd)
MODELS=/opt/models
PORT:=$(shell awk -v min=16384 -v max=32768 'BEGIN{srand(); print int(min+rand()*(max-min+1))}')
SRC_DIR=/usr/src/click_example
USER=$(shell echo $${USER%%@*})
VERSION=$(shell echo $(shell cat click_example/__init__.py | \
			grep "^__version__" | \
			cut -d = -f 2))

include envfile
.PHONY: docs upgrade-packages

deploy: docker-up
	docker container exec $(PROJECT)_python \
		pip3 wheel --wheel-dir=wheels .
	git tag -a v$(VERSION) -m "Version $(VERSION)"
	@echo
	@echo
	@echo Enter the following to push this tag to the repository:
	@echo git push origin v$(VERSION)

docker-down:
	docker-compose -f docker/docker-compose.yml down

docker-rebuild: setup.py
	docker-compose -f docker/docker-compose.yml up -d --build

docker-up:
	docker-compose -f docker/docker-compose.yml up -d

docs: docker-up
	docker container exec $(PROJECT)_python \
		/bin/bash -c "pip install -e . && cd docs && make html"
	${BROWSER} http://localhost:8080


docs-init: docker-up
	rm -rf docs/*
	docker container exec $(PROJECT)_python \
		/bin/bash -c \
			"cd docs \
			 && sphinx-quickstart -q \
				-p $(PROJECT) \
				-a "Timothy Helton" \
				-v $(VERSION) \
				--ext-autodoc \
				--ext-viewcode \
				--makefile \
				--no-batchfile"
	docker-compose -f docker/docker-compose.yml restart nginx
ifeq ("$(shell git remote)", "origin")
	git fetch
	git checkout origin/master -- docs/
else
	docker container run --rm \
		-v `pwd`:/usr/src/$(PROJECT) \
		-w /usr/src/$(PROJECT)/docs \
		ubuntu \
		/bin/bash -c \
			"sed -i -e 's/# import os/import os/g' conf.py \
			 && sed -i -e 's/# import sys/import sys/g' conf.py \
			 && sed -i \"/# sys.path.insert(0, os.path.abspath('.'))/d\" \
				conf.py \
			 && sed -i -e \"/import sys/a \
				sys.path.insert(0, os.path.abspath('../click_example')) \
				\n\nfrom click_example import __version__\" \
				conf.py \
			 && sed -i -e \"s/version = '0.1.0'/version = __version__/g\" \
				conf.py \
			 && sed -i -e \"s/release = '0.1.0'/release = __version__/g\" \
				conf.py \
			 && sed -i -e \"s/alabaster/sphinx_rtd_theme/g\" \
				conf.py \
			 && sed -i \"/   :caption: Contents:/a \
				\\\\\n   package\" \
				index.rst"
	printf "%s\n" \
		"Package Modules" \
		"===============" \
		"" \
		".. toctree::" \
		"    :maxdepth: 2" \
		"" \
		"cli" \
		"---" \
		".. automodule:: cli" \
		"    :members:" \
		"    :show-inheritance:" \
		"    :synopsis: Package commandline interface calls." \
		"" \
	> "docs/package.rst"
endif

docs-view: docker-up
	${BROWSER} http://localhost:8080

ipython: docker-up
	docker container exec -it $(PROJECT)_python ipython

notebook: notebook-server
	sleep 0.5
	${BROWSER} $$(docker container exec \
		$(USER)_notebook_$(PORT) \
		jupyter notebook list | grep -o '^http\S*')

notebook-remove:
	docker container rm -f $$(docker container ls -f name=$(USER)_notebook -q)

notebook-server:
	docker container run -d --rm \
		--name $(USER)_notebook_$(PORT) \
		-p $(PORT):$(PORT) \
		$(PROJECT)_python \
		/bin/bash -c "jupyter notebook \
				--allow-root \
				--ip=0.0.0.0 \
				--port=$(PORT)"

pgadmin: docker-up
	${BROWSER} http://localhost:5000

psql: docker-up
	docker container exec -it $(PROJECT)_postgres \
		psql -U ${POSTGRES_USER} $(PROJECT)

tensorflow:
	docker container run --rm \
		-v `pwd`:/usr/src/$(PROJECT) \
		-w /usr/src/$(PROJECT) \
		ubuntu \
		/bin/bash -c \
			"sed -i -e 's/python-Dockerfile/tensorflow-Dockerfile/g' \
				docker/docker-compose.yml \
			 && sed -i -e \"/'notebook': \['jupyter'\],/a \
				\ \ \ \ \ \ \ \ 'tf-cpu': ['tensorflow'],\
				\n\ \ \ \ \ \ \ \ 'tf-gpu': ['tensorflow-gpu'],\" \
				setup.py"

tensorflow-models: tensorflow docker-rebuild
ifneq ($(wildcard ${MODELS}), )
	echo "Updating TensorFlow Models Repository"
	cd ${MODELS} \
	&& git checkout master \
	&& git pull
	cd ${MOUNT_DIR}
else
	echo "Cloning TensorFlow Models Repository to ${MODELS}"
	mkdir -p ${MODELS}
	git clone https://github.com/tensorflow/models.git ${MODELS}
endif

test: docker-up
	docker container exec $(PROJECT)_python \
		/bin/bash -c "py.test\
				--basetemp=pytest \
				--doctest-modules \
				--ff \
				--pep8 \
				-r all \
				-vvv"

upgrade-packages: docker-up
	docker container exec $(PROJECT)_python \
		/bin/bash -c \
			"pip3 install -U pip \
			 && pip3 freeze | \
				grep -v $(PROJECT) | \
				cut -d = -f 1 > requirements.txt \
			 && pip3 install -U -r requirements.txt \
			 && pip3 freeze > requirements.txt \
			 && sed -i -e '/^-e/d' requirements.txt"
