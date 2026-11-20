.PHONY: audit

# Fail when a locked Hex package has a security advisory or is retired.
audit:
	mix hex.audit
