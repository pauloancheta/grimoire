# Vim: New Line

Google no more for the new line character search for vim. `\r`. It's very simple but I always forget.

## Usage:

```
#example text
this is my text

:%s/is my/is\rmy/

# results to
this is
my text
```
