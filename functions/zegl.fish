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
    set trunkname $(ztrunkname)
    set current_branch_name (git branch --show-current)

    # if on trunk, warn and exit
    if test $current_branch_name = $trunkname
        echo "You are on the trunk branch. Are you sure that you want to force push it? (y/n)"
        read -k1 -n1
        echo
        if test $REPLY != "y"
            exit 1
        end
    end

    git push -u origin HEAD --force
end

function zfuture
    set trunkname $(ztrunkname)
    set ghusername $(gh api user | jq -r '.login')

    # if on branch tmp_future, warn and exit
    if test (git branch --show-current) = "tmp_future"
        echo "You are on the tmp_future branch, please switch to another branch before running this script"
        exit 1
    end

    set_color green; echo "Z: Preparing..."
    set_color normal;

    git branch -D tmp_future
    git checkout -b tmp_future
    git fetch origin
    git reset --hard $trunkname

    # All heads that are not merged into the trunk
    set unmerged_ids $(gh pr list --author "$ghusername" --json headRefOid --jq '.[] | .headRefOid')

    for id in $unmerged_ids
        set_color green; echo "Z: Applying PR $id"
        set_color normal;

        set pr_commits $(git log --oneline $trunkname..$id)

        for commit in $pr_commits
            set commit_hash (echo $commit | awk '{print $1}')

            set short (git log --pretty=oneline --abbrev-commit -n1 $commit_hash)

            set_color green; echo "Z: Cherry Picking $short"
            set_color normal;

            git cherry-pick $commit_hash
        end
    end

    git branch -D future
    git checkout -b future
    git branch -D tmp_future

    set_color green; echo "Z: All done, welcome to the future!"
    set_color normal;
end

function zco
    set branch $(git for-each-ref --sort=-committerdate refs/heads/ --format='%(refname:short)' | head -n 20 | fzf)
    if test -n "$branch"
        git checkout $branch
    end
end

function znotify --description "znotify <title> <message>"
    set title $argv[1]
    set --erase argv[1]
    curl -X POST "https://sn.30cm.org/v1/push" -H 'Content-Type: application/json' -d '{"auth":"'"$SN_30CM_ORG_AUTH"'","message":"'"$argv"'", "title":"'"$title"'"}'
    echo "Sent! 🔔"
end
