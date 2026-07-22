#!/usr/bin/env bash
# check-workspace-deps.sh — 检查 Cargo workspace 成员是否绕过 [workspace.dependencies] 内联钉第三方 version
#
# 对齐：rulesets/rust/RULES.md R-DEP-004
# 用法：
#   bash scripts/check-workspace-deps.sh           # 当前目录为 crate/workspace 根
#   bash scripts/check-workspace-deps.sh /path/to/repo
# 退出码：0 通过或非 workspace 跳过；1 发现违规；2 用法/环境错误
#
# 允许：
#   - 根 Cargo.toml 的 [workspace.dependencies]
#   - 成员：foo.workspace = true / foo = { workspace = true, ... }
#   - path 依赖（可带 version，与目标 package 对齐由人工/项目门禁保证）
#   - git / registry 以外的 path-only 表项
# 禁止：
#   - 成员中第三方依赖写 version = "…" 且无 workspace = true

set -euo pipefail

ROOT="${1:-.}"
ROOT="$(cd "$ROOT" && pwd)"
ROOT_TOML="${ROOT}/Cargo.toml"

if [[ ! -f "$ROOT_TOML" ]]; then
  echo "error: 未找到 ${ROOT_TOML}" >&2
  exit 2
fi

# 非 workspace：跳过（单 crate 见 RULES §9.2）
if ! grep -qE '^\[workspace\]' "$ROOT_TOML"; then
  echo "info: 非 Cargo workspace，跳过 R-DEP-004 检查（见 rulesets/rust/RULES.md §9.2）"
  exit 0
fi

# 收集成员路径：优先 cargo metadata
members=()
if command -v cargo >/dev/null 2>&1; then
  # package manifest_path list（含根若为 virtual 则可能无 package）
  while IFS= read -r mp; do
    [[ -n "$mp" ]] || continue
    # 跳过根 workspace 清单本身（版本声明合法位置）
    if [[ "$mp" == "$ROOT_TOML" ]]; then
      continue
    fi
    members+=("$mp")
  done < <(
    cargo metadata --manifest-path "$ROOT_TOML" --no-deps --format-version 1 2>/dev/null \
      | python3 -c '
import json,sys
try:
    data=json.load(sys.stdin)
except Exception:
    sys.exit(0)
root=data.get("workspace_root","")
for p in data.get("packages",[]):
    mp=p.get("manifest_path","")
    if mp:
        print(mp)
' 2>/dev/null || true
  )
fi

# fallback：解析 workspace.members（字面路径与单层 * glob）
if [[ ${#members[@]} -eq 0 ]]; then
  echo "info: cargo metadata 不可用或无成员 package，尝试解析 [workspace] members"
  # 抽出 members 数组内所有 "…" 路径（兼容单行/多行）
  while IFS= read -r m; do
    [[ -n "$m" ]] || continue
    if [[ "$m" == *"*"* ]]; then
      shopt -s nullglob
      for d in "${ROOT}"/${m}; do
        if [[ -f "${d}/Cargo.toml" ]]; then
          members+=("${d}/Cargo.toml")
        fi
      done
      shopt -u nullglob
    else
      if [[ -f "${ROOT}/${m}/Cargo.toml" ]]; then
        members+=("${ROOT}/${m}/Cargo.toml")
      elif [[ -f "${ROOT}/${m}" ]]; then
        members+=("${ROOT}/${m}")
      fi
    fi
  done < <(
    awk '
      /^\[workspace\]/ { in_ws=1; next }
      # 仍在 [workspace] 主表内；遇到其它表结束（含 [workspace.dependencies]）
      in_ws && /^\[/ { in_ws=0; in_mem=0 }
      in_ws && /^members[[:space:]]*=/ { in_mem=1 }
      in_ws && in_mem {
        print
        if ($0 ~ /\]/) in_mem=0
      }
    ' "$ROOT_TOML" | grep -oE '"[^"]+"' | tr -d '"'
  )
fi

if [[ ${#members[@]} -eq 0 ]]; then
  echo "warn: 未解析到成员 Cargo.toml；若为 virtual workspace 请确认 members 配置"
  exit 0
fi

# 去重
mapfile -t members < <(printf '%s\n' "${members[@]}" | sort -u)

violations=0
report() {
  local file="$1" line_no="$2" text="$3"
  echo "FAIL: ${file}:${line_no}: 成员内联第三方 version（违反 R-DEP-004）"
  echo "      ${text}"
  violations=$((violations + 1))
}

scan_manifest() {
  local file="$1"
  # 只扫 dependency 相关表；跳过 [package] 等
  local in_deps=0
  local line_no=0
  local line
  # SC2094: report 仅 echo，不写回 $file
  # shellcheck disable=SC2094
  while IFS= read -r line || [[ -n "$line" ]]; do
    line_no=$((line_no + 1))
    # section headers
    if [[ "$line" =~ ^\[ ]]; then
      if [[ "$line" =~ ^\[(dependencies|dev-dependencies|build-dependencies|target\..*\.(dependencies|dev-dependencies|build-dependencies))\] ]]; then
        in_deps=1
      else
        in_deps=0
      fi
      continue
    fi
    [[ "$in_deps" -eq 1 ]] || continue
    # 空行/注释
    [[ "$line" =~ ^[[:space:]]*# ]] && continue
    [[ "$line" =~ ^[[:space:]]*$ ]] && continue

    # workspace = true 整行或表内含 workspace = true → 合法
    if [[ "$line" =~ workspace[[:space:]]*=[[:space:]]*true ]]; then
      continue
    fi

    # path 依赖 → 允许（可含 version）
    if [[ "$line" =~ path[[:space:]]*= ]]; then
      continue
    fi

    # package.workspace 简写：serde.workspace = true
    if [[ "$line" =~ \.workspace[[:space:]]*=[[:space:]]*true ]]; then
      continue
    fi

    # 内联 version = "..." 或 version = '...'
    if [[ "$line" =~ version[[:space:]]*= ]]; then
      report "$file" "$line_no" "$line"
      continue
    fi

    # 简写 foo = "1.0" （字符串版本）
    if [[ "$line" =~ ^[[:space:]]*[A-Za-z0-9_-]+[[:space:]]*=[[:space:]]*[\"\'][0-9] ]]; then
      report "$file" "$line_no" "$line"
      continue
    fi
  done < "$file"
}

echo "check-workspace-deps: root=${ROOT}"
echo "check-workspace-deps: scanning ${#members[@]} member manifest(s)"

for mp in "${members[@]}"; do
  if [[ ! -f "$mp" ]]; then
    echo "warn: 跳过不存在的 manifest: $mp"
    continue
  fi
  scan_manifest "$mp"
done

if [[ "$violations" -gt 0 ]]; then
  echo ""
  echo "共 ${violations} 处违规。修复：将 version 上收到根 [workspace.dependencies]，成员改用 workspace = true。"
  echo "详见：rulesets/rust/RULES.md §9.1 R-DEP-004"
  exit 1
fi

echo "ok: R-DEP-004 成员依赖引用检查通过"
exit 0
