# Python: `is`

As with most languages, each has its own quirk. One of the quirks of python is that it uses different
object id's for strings with operators such as `*`, `+`, `-`, etc. For example:

```python
>>> a = 'c-'
>>> b = 'c-'
>>> a is b
False
```

And that is because `a`'s object ID is different from `b`'s object ID. The easiest solution to this
is to use `==` instead of `is`

```python
>>> a = 'c-'
>>> b = 'c-'
>>> a == b
True
```

Unless you are sure about the object ID that you are comparing, prefer `==`.
