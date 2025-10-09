TEMP_DIR := $(shell mktemp -d)
WORK_DIR := $(TEMP_DIR)/TA-unix
VERSION := $(shell head -n1 VERSION)
TAR_FILE := ./ta-for-unix-and-linux-$(VERSION).tgz

all: release

updateversion:
ifndef NEW
	$(error NEW is not specified. Usage make NEW=<newversion> updateversion)
endif
	sed -ri "s/$(VERSION)/$(NEW)/g" app.manifest appserver/static/js/build/globalConfig.json default/app.conf VERSION

release:
	mkdir -p $(WORK_DIR)
	cp -R . $(WORK_DIR)/
	rm -Rf $(WORK_DIR)/Makefile $(WORK_DIR)/.git $(WORK_DIR)/local $(WORK_DIR)/bin/__pycache__ $(WORK_DIR)/ta-for-unix-and-linux-*.tgz
	tar -C $(TEMP_DIR) -czf $(TAR_FILE) TA-unix
	test -d $(HOME)/Downloads && cp $(TAR_FILE) $(HOME)/Downloads
	rm -Rf $(TEMP_DIR)

clean:
	rm -Rf ./ta-for-unix-and-linux-*.tgz $(TEMP_DIR)
