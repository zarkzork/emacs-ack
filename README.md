= M-x ack = 

Command for using ack on current project. Project asumed to be
current git repo. Arguments to M-x ack is passed directly to ack.

== Installation ==

Add to your `.emacs`
on linux:

```lisp
(require 'ack)
```

On mac os x

```lisp
(require 'ack)
(setq ack-command "ack")
```

== Usage ==

Simply M-x ack RET and pass all arguments you want to pass to ack. 