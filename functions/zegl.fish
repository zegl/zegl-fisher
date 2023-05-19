function zpr
    git fetch origin
    git rebase -i origin/main --autosquash
    git push -u origin HEAD --force
    gh pr create --fill
    gh pr merge --auto
end


function zrb
    git fetch origin
    git rebase -i origin/main --autosquash
end


function zrbs
    git stash
    git fetch origin
    git rebase -i origin/main --autosquash
    git stash pop
end

function zfup
    git log -n 50 --pretty=format:'%h %s' --no-merges | fzf | cut -c -7 | xargs -o git commit --fixup
end