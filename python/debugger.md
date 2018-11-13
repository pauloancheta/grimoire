# Python: Debugger

In Ruby, it is very useful to use pry when trying to debug a running code. It opens up a terminal
and it is easy to examine what each line results in to. In python, one way of achieving this is to
use `code`. Here's an example usage:

```python
# test.py
import code

a = 1
code.interact(local=dict(globals(), **locals()))
```

When running this (`python test.py`), it results to:
```python
$> python test.py
Python 3.5.2 (default, Mar 14 2017, 10:39:55)
[GCC 4.2.1 Compatible Apple LLVM 8.0.0 (clang-800.0.42.1)] on darwin
Type "help", "copyright", "credits" or "license" for more information.
(InteractiveConsole)
>>>
```
