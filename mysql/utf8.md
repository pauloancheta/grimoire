# MySql: UTF8

MySql utf-8 is different from the real utf-8 which causes emojis to cause an error 🤣.
To avoid these errors, use `utf8mb4` as a default to the database.

```
ALTER TABLE {your table_name} CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci
```

For more context, read this:
https://medium.com/@adamhooper/in-mysql-never-use-utf8-use-utf8mb4-11761243e434
