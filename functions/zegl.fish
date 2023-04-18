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
