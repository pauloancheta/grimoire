# Linux Commands: less

When traversing through long logs, it is usually compelling to put them into a file and then
delete them after. But often, piping to `less` is enough. For example:

```bash
$ tail --follow | less
```

Given this example, it is now possible to use "vim-like" searches using `/`.

It is also very useful when trying to view an ugly formatted json.

```bash
$ cat ugly.json
{'hello': {'hola': 'mundo'}}

$ jq -C . data.json |less -R
{
  "hello": {
    "holla": "mundo"
  }
}
```
