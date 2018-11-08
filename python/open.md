# Python: Open

When opening a file, ensure that it is closed after it has finished writing to remove unexpected behaviour.

```python
stream = open("somefile.yml", "r")
table = yaml.load(stream)

# convert it to

with open("somefile.yml", "r") as stream:
    table = yaml.load(stream)
```
