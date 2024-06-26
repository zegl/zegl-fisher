function ztrunkname
    if git rev-parse --verify main &> /dev/null ;
        echo "origin/main"
    else
        echo "origin/master"
    end
end

function zpr
    set trunk $(ztrunkname)
    git fetch origin
    git rebase -i $trunk --autosquash
    git push -u origin HEAD --force
    gh pr create --fill
    gh pr merge --auto
end


function zrb
    git fetch origin
    git rebase -i $(ztrunkname) --autosquash
end


function zrbs
    git stash
    git fetch origin
    git rebase -i $(ztrunkname) --autosquash
    git stash pop
end

function zfup
    git log -n 50 --pretty=format:'%h %s' --no-merges | fzf | cut -c -7 | xargs -o git commit --fixup
end

function zpp
    git push -u origin HEAD --force
end


function znotify --description "znotify <title> <message>"
    set title $argv[1]
    set --erase argv[1]
    curl -X POST "https://sn.30cm.org/v1/push" -H 'Content-Type: application/json' -d '{"auth":"'"$SN_30CM_ORG_AUTH"'","message":"'"$argv"'", "title":"'"$title"'"}'
    echo "Sent! 🔔"
end
