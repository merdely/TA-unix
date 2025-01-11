TEMP_DIR := $(shell mktemp -d)
WORK_DIR := $(TEMP_DIR)/TA-unix

all: release

release:
	mkdir -p $(WORK_DIR)
	cp -R . $(WORK_DIR)/
	rm -Rf $(WORK_DIR)/Makefile $(WORK_DIR)/.git $(WORK_DIR)/local $(WORK_DIR)/ta-for-unix-and-linux-*.tgz
	tar -C $(WORK_DIR) -czf ./ta-for-unix-and-linux-`head -n1 VERSION`.tgz TA-unix
	rm -Rf $(TEMP_DIR)

clean:
	rm -Rf ./ta-for-unix-and-linux-*.tgz $(TEMP_DIR)
