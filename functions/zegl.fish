function ztrunkname --description "Get the name of the trunk branch"
    if git rev-parse --verify main &> /dev/null ;
        echo "origin/main"
    else
        echo "origin/master"
    end
end

function zpr --description "Create a PR"
    set trunk $(ztrunkname)
    git fetch origin
    git rebase -i $trunk --autosquash
    git push -u origin HEAD --force
    gh pr create --fill
    gh pr merge --auto
end

function zrb --description "Rebase on the trunk. Will use autosquash to automatically fixup commits created with zfup"
    git fetch origin
    git rebase -i $(ztrunkname) --autosquash
end

function zrbs --description "Rebase on the trunk with stash"
    git stash
    git fetch origin
    git rebase -i $(ztrunkname) --autosquash
    git stash pop
end

function zfup --description "Create a fixup commit interactively"
    git log -n 50 --pretty=format:'%h %s' --no-merges | fzf | cut -c -7 | xargs -o git commit --fixup
end

function zpp --description "Force push the current branch to the remote"
    set trunkname $(ztrunkname)
    set current_branch_name (git branch --show-current)

    # if on trunk, warn and exit
    if test "origin/$current_branch_name" = $trunkname
        echo "🚫 You are on the trunk branch. Refusing to fource push it, sorry! 🚫"
        return 1
    end

    git push -u origin HEAD --force
end

function zfuture --description "Cherry pick all unmerged PRs into a new branch"
    set trunkname $(ztrunkname)
    set ghusername $(gh api user | jq -r '.login')

    # if on branch tmp_future, warn and exit
    if test (git branch --show-current) = "tmp_future"
        echo "You are on the tmp_future branch, please switch to another branch before running this script"
        return 1
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

function zco --description "Interactive branch checkout"
    set branch $(git for-each-ref --sort=-committerdate refs/heads/ --format='%(refname:short)' | head -n 20 | fzf)
    if test -n "$branch"
        git checkout $branch
    end
end

function zreflog --description "Show reflog and preview commits"
    git reflog | fzf --preview 'git show {1}' --preview-window=right:70%
end

function znotify --description "znotify <title> <message>"
    set title $argv[1]
    set --erase argv[1]
    curl -X POST "https://sn.30cm.org/v1/push" -H 'Content-Type: application/json' -d '{"auth":"'"$SN_30CM_ORG_AUTH"'","message":"'"$argv"'", "title":"'"$title"'"}'
    echo "Sent! 🔔"
end

function zprl --description "Create a pretty link to the current branch"
    gh pr view --json title,number,additions,deletions,url --template '\`(+{{.additions}}/-{{.deletions}})\` {{.title}} [#{{.number}}]({{.url}})'
end

function zgr --description "cd to git root"
    cd (git rev-parse --show-toplevel)
end

function zc --description "Start a new Claude Code session or resume one from the last 7 days in this dir"
    set -l project_dir ~/.claude/projects/(string replace -ar '[^a-zA-Z0-9]' '-' $PWD)
    # sessions-index.json stopped being updated, read titles from the transcripts instead
    set -l files (find $project_dir -maxdepth 1 -name '*.jsonl' -mtime -7 2>/dev/null)

    set -l sessions
    if test (count $files) -gt 0
        set sessions (jq -rn '
            def day: localtime | strftime("%Y-%m-%d");
            def epoch: .[0:19] + "Z" | fromdate;
            def pretty: epoch as $t
                | ($t | day) as $d
                | (if $d == (now | day) then "Today" elif $d == (now - 86400 | day) then "Yesterday" else $t | localtime | strftime("%a") end)
                | (. + "         ")[0:9] + " " + ($t | localtime | strftime("%H:%M"));
            reduce inputs as $l ({}; (input_filename | split("/") | last | rtrimstr(".jsonl")) as $id
                | .[$id].ts = ($l.timestamp // .[$id].ts)
                | if $l.type == "ai-title" then .[$id].title = $l.aiTitle else . end
                | if .[$id].prompt == null and $l.type == "user" and ($l.isMeta | not)
                    and ($l.message.content | type) == "string" and ($l.message.content | startswith("<") | not)
                  then .[$id].prompt = $l.message.content else . end)
            # file mtime can be bumped without activity, filter on the last message instead
            | to_entries[] | select(.value.ts and (.value.title // .value.prompt) and (.value.ts | epoch) > now - 7 * 86400)
            | [.value.ts, (.value.ts | pretty), .key, ((.value.title // .value.prompt) | gsub("[\r\n\t ]+"; " ") | .[0:100])] | @tsv
        ' $files 2>/dev/null | sort -r | while read -l -d \t ts when id title
            echo $when\t$title\t$id
        end)
    end

    set -l choice (printf '%s\n' "+ New session" $sessions | fzf --delimiter \t --with-nth 1,2 --no-sort --height 40% --reverse --prompt "claude> ")
    test -z "$choice"; and return

    set -l session_id (string split \t $choice)[3]
    if test -n "$session_id"
        claude --resume $session_id $argv
    else
        claude $argv
    end
end
