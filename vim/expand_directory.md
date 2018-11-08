# Vim: Expand Directory

It's very useful to have a few key strokes to write the current directory in command mode.

```vim
cnoremap %% <C-R>=expand('%:p').'/'<cr>
```

Adding this to the vimconfig, will expand the current directory whenever `%%` is typed. For example:

```
When running this on `~/rails_app/spec/models/user_spec.rb`

:!rspec %%

Will result to:

:!rspec ~/rails_app/spec/models/user_spec.rb/
```

This makes it easier to create macros on the fly and this is probably what Gary Bernhardt uses on his
DestroyAllSoftware videos.

```
:map ,T :!rspec %%
```
