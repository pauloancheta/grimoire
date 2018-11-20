# Terminal: ag hidden files

By default, silver-searcher will not traverse through the hidden files. This makes sense since we don't
want to look at the `.git/` directory most of the time.

The best way around this is to use the `~/.agignore` file so that silver-searcher does not look at
`.git`. And use `--hidden` flag to search through the hidden files.

```
# ~/.agignore
.git
```

```sh
$> ag --hidden something_hidden
.test_file
1:something hidden
```

However, if in case you wanted to traverse through folders that are in `.agignore`, use `-u` flag
to search through all of them
