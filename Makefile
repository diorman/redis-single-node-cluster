.PHONY: shellcheck
shellcheck:
	@find ./ -name '*.sh' | xargs shellcheck
