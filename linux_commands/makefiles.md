# Linux Commands: make

## HELP

I heard that it's an old programmers habbit to have makefiles but to me, `Makefiles` make it easy to
run different apps consistently. One of the things that make it easy for me is having a consisten
`help` target.

```make
.PHONY: help
help: ## display this message
	@grep --no-filename -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| sort | awk 'BEGIN {FS = ":.*?## "} \
		{printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
```

By adding this block of code, any time we run `make help` from the the directory where the Makefile
is in, a helpful message will appear. To add a help message on a make target, just add `##` after the
target. For example:

```make
.PHONY: merp
merp: ## just a merpy message
  @echo "merpy message"
```

## Variable checks
Another helpful command that I have come accross is using `check_variable`. This can ensure that the
target will run successfully. And if not, it will print out a helpful message.

```make
check_variable = \
        $(strip $(foreach 1,$1, $(call __check_variable,$1,$(strip $(value 2)))))
__check_variable = \
        $(if $(value $1),, $(error Variable undefined: $1$(if $2, ($2))))

```

To use it, add it inside your target. For example:

```make
.PHONY: merp
merp: ## just a merpy message
	$(call check_variable, MERP_VALUE, Please specify a `MERP_VALUE` (eg. 'message'))
  @echo "merpy ${MERP_VALUE}"
```

```make
$> make merp
Makefile:22: *** Variable undefined: MERP_VALUE (Please specify a `MERP_VALUE` (eg. 'message')).  Stop.

$> MERP_VALUE=derp make merp
merpy derp
```
