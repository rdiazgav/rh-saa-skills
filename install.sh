#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILLS_SRC="$REPO_DIR/skills"
AGENTS_SRC="$REPO_DIR/agents"

usage() {
  cat <<EOF
Usage: $(basename "$0") [update]

  (no args)   Symlink all skills into ~/.cursor/skills/ and ~/.claude/skills/,
              and Claude Code subagents into ~/.claude/agents/
  update      Pull the latest version from git, then re-link

A tool is skipped only if its home directory (~/.cursor or ~/.claude) does not exist.
Missing skills/ or agents/ subdirectories are created.

EOF
}

# link_dirs <source-parent> <tool-home> <subdir> <tool-name>
# Symlinks every directory under <source-parent> into <tool-home>/<subdir>/.
link_dirs() {
  local src_parent="$1"
  local tool_home="$2"
  local subdir="$3"
  local tool_name="$4"
  local target_base="$tool_home/$subdir"

  if [[ ! -d "$src_parent" ]]; then
    return
  fi

  if [[ ! -d "$tool_home" ]]; then
    echo "  Skipping $tool_name $subdir ($tool_home does not exist)"
    return
  fi

  mkdir -p "$target_base"

  for src_dir in "$src_parent"/*/; do
    [[ -d "$src_dir" ]] || continue
    local name target
    name="$(basename "$src_dir")"
    target="$target_base/$name"

    if [[ -L "$target" ]]; then
      echo "  $tool_name/$subdir/$name: symlink already exists, updating"
      rm "$target"
      ln -s "$src_dir" "$target"
    elif [[ -e "$target" ]]; then
      echo "  $tool_name/$subdir/$name: WARNING - a local directory already exists, skipping"
      echo "    Remove $target manually if you want the shared version"
    else
      ln -s "$src_dir" "$target"
      echo "  $tool_name/$subdir/$name: linked"
    fi
  done
}

link_all() {
  echo "Linking skills..."
  link_dirs "$SKILLS_SRC" "$HOME/.cursor" "skills" "Cursor"
  link_dirs "$SKILLS_SRC" "$HOME/.claude" "skills" "Claude Code"
  echo ""
  echo "Linking Claude Code subagents..."
  link_dirs "$AGENTS_SRC" "$HOME/.claude" "agents" "Claude Code"
}

case "${1:-}" in
  -h|--help)
    usage
    exit 0
    ;;
  update)
    echo "Pulling latest version..."
    git -C "$REPO_DIR" pull --ff-only
    echo ""
    link_all
    echo ""
    echo "Done. Skills and agents are up to date."
    ;;
  "")
    link_all
    echo ""
    echo "Done. Run '$(basename "$0") update' to pull and re-link later."
    echo "Restart any running Claude Code session so it picks up new agents."
    ;;
  *)
    echo "Unknown command: $1"
    usage
    exit 1
    ;;
esac
