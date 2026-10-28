# zegl-fisher 🎣

Fish for cool kids.

Aliases, functions, etc for [fish](https://fishshell.com/) with [fisher](https://github.com/jorgebucaran/fisher).

```
fisher install zegl/zegl-fisher
```

## Functions

* `zpr` – Create a PR
* `zrb` – Rebase on the trunk. Will use autosquash to automatically fixup commits created with zfup
* `zrbs` – Rebase on the trunk with stash
* `zfup` – Create a fixup commit interactively
* `zpp` – Force push the current branch to the remote
* `zfuture` – Cherry pick all unmerged PRs into a new branch
* `zco` – Interactive branch checkout
* `zreflog` – Browse the reflog with fzf, previewing each commit
* `zprl` – Print a Markdown link to the current branch's PR, like `` `(+12/-3)` Title [#123](url) ``
* `zgr` – cd to the git root
* `zc` – Start a new Claude Code session or resume one from the last 7 days in this dir (fzf)

### Low level functions

* `ztrunkname` – Get the name of the trunk branch