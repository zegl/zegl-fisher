function prx
    git fetch origin
    git rebase -i origin/main --autosquash
    git push -u origin HEAD --force
    gh pr create
    gh pr merge --auto
end