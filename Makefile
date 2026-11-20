.PHONY: all help setup deps audit fmt fmt-check lint test coverage compile assets-check ci

MIX ?= mix

all:
	$(MAKE) fmt
	$(MAKE) ci

help:
	@echo "Targets:"
	@echo "  setup         Install the dependencies (mix setup)"
	@echo "  deps          Get the dependencies (mix deps.get)"
	@echo "  audit         Fail when a locked package has a security advisory or is retired (mix hex.audit)"
	@echo "  fmt           Format the code (mix format)"
	@echo "  fmt-check     Fail when the code is not formatted"
	@echo "  lint          Run credo"
	@echo "  test          Run the tests"
	@echo "  coverage      Run the tests with coverage; fail below 100% (writes cover/lcov.info)"
	@echo "  compile       Compile in the test env with warnings as errors"
	@echo "  assets-check  Rebuild the JS bundles; fail when the committed bundles are stale"
	@echo "  ci            Run the checks of the CI workflow (.github/workflows/test.yml)"
	@echo "  all           Run fmt, then ci"

setup:
	$(MIX) setup

deps:
	$(MIX) deps.get

# Fails when a locked package has a security advisory or is retired.
audit:
	$(MIX) hex.audit

fmt:
	$(MIX) format

fmt-check:
	$(MIX) format --check-formatted

lint:
	$(MIX) credo

test:
	$(MIX) test

coverage:
	$(MIX) coveralls.lcov

compile:
	env MIX_ENV=test $(MIX) compile --warnings-as-errors

# The bundles are committed because apps load them straight from deps/.
assets-check:
	$(MIX) esbuild.install --if-missing
	$(MIX) assets.build
	git diff --exit-code -- priv/static/odyssey_hooks.min.js priv/static/odyssey_web_components.min.js

# The same checks, in the same order, as .github/workflows/test.yml.
ci:
	$(MAKE) deps
	$(MAKE) audit
	$(MAKE) assets-check
	$(MAKE) fmt-check
	$(MAKE) lint
	$(MAKE) coverage
