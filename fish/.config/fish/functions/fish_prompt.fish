function fish_prompt
    set -l color_path (set -q fish_color_secondary; and echo $fish_color_secondary; or echo "8e9aaf")
    set -l color_arrow (set -q fish_color_primary; and echo $fish_color_primary; or echo "88d6ba")

    set -l cwd (prompt_pwd --full-length-dirs 1)

    printf "%s%s %s❯%s " (set_color $color_path) $cwd (set_color $color_arrow) (set_color normal)
end

function fish_right_prompt
    if git rev-parse --git-dir > /dev/null 2>&1
        set -l color_git (set -q fish_color_tertiary; and echo $fish_color_tertiary; or echo "a7cce1")
        set -l branch (git branch --show-current 2>/dev/null)
        printf "%s %s%s" (set_color $color_git) $branch (set_color normal)
    end
end
