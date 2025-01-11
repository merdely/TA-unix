TEMP_DIR := $(shell mktemp -d)
WORK_DIR := $(TEMP_DIR)/TA-unix
TAR_FILE := ./ta-for-unix-and-linux-`head -n1 VERSION`.tgz

all: release

release:
	mkdir -p $(WORK_DIR)
	cp -R . $(WORK_DIR)/
	rm -Rf $(WORK_DIR)/Makefile $(WORK_DIR)/.git $(WORK_DIR)/local $(WORK_DIR)/bin/__pycache__ $(WORK_DIR)/ta-for-unix-and-linux-*.tgz
	tar -C $(TEMP_DIR) -czf $(TAR_FILE) TA-unix
	test -d $(HOME)/Downloads && cp $(TAR_FILE) $(HOME)/Downloads
	rm -Rf $(TEMP_DIR)

clean:
	rm -Rf ./ta-for-unix-and-linux-*.tgz $(TEMP_DIR)
