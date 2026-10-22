TESTS_INIT=tests/minimal_init.lua
TESTS_DIR=tests/

.PHONY: test setup vimdoc

setup:
	@bash scripts/install-dev-dependencies.sh

vimdoc:
	@PATH="$(CURDIR)/vendor/panvimdoc:$$PATH" bash scripts/generate-vimdoc.sh

test:
	@nvim \
		--headless \
		--noplugin \
		-u ${TESTS_INIT} \
		-c "PlenaryBustedDirectory ${TESTS_DIR} { minimal_init = '${TESTS_INIT}' }"
