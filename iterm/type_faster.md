# ITERM: Type Faster

The most common way to do this is to use the keyboard settings in MacOs: putting the "Key Repeat"
to the highest setting. But this can still be overriden using specific commands:

```bash
defaults write -g InitialKeyRepeat -int 12
defaults write -g KeyRepeat -int 1
```

Remember that this might persist after restart. Tune to your specific key repeat value.

In case of emergency and it has gone way too fast to handle, use the "Key Repeat" settings and it should go back to the default.
