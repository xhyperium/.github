#!/usr/bin/env bash
# sync-workflows.sh — 将 workflows/*.yml 同步到 .github/workflows/（GHA 可调用源）
#
# 约定：顶层 workflows/ 为编辑与文档入口；.github/workflows/ 为 uses: 实际路径。
# 两边 YAML 必须字节一致。README 可不同：顶层完整文档，.github 侧保留短链。
#
# 用法：
#   bash scripts/sync-workflows.sh          # 同步并校验
#   bash scripts/sync-workflows.sh --check  # 仅校验，不写文件

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="${ROOT}/workflows"
DST="${ROOT}/.github/workflows"
CHECK_ONLY=0

if [[ "${1:-}" == "--check" ]]; then
  CHECK_ONLY=1
fi

if [[ ! -d "${SRC}" || ! -d "${DST}" ]]; then
  echo "FAIL: 缺少 ${SRC} 或 ${DST}" >&2
  exit 1
fi

mapfile -t FILES < <(find "${SRC}" -maxdepth 1 -type f -name '*.yml' -printf '%f\n' | sort)

if [[ ${#FILES[@]} -eq 0 ]]; then
  echo "FAIL: ${SRC} 下无 .yml 文件" >&2
  exit 1
fi

drift=0
for f in "${FILES[@]}"; do
  if [[ ! -f "${DST}/${f}" ]]; then
    echo "MISSING: .github/workflows/${f}"
    drift=1
    if [[ "${CHECK_ONLY}" -eq 0 ]]; then
      /bin/cp -f "${SRC}/${f}" "${DST}/${f}"
      echo "  → copied"
      drift=0
    fi
    continue
  fi
  if ! cmp -s "${SRC}/${f}" "${DST}/${f}"; then
    echo "DRIFT: ${f}"
    if [[ "${CHECK_ONLY}" -eq 1 ]]; then
      drift=1
    else
      /bin/cp -f "${SRC}/${f}" "${DST}/${f}"
      echo "  → synced"
    fi
  else
    echo "OK: ${f}"
  fi
done

# 反向：仅对「可复用模板」ci-*.yml 要求双份一致。
# 本仓自用 workflow（如 meta-validate.yml）只放在 .github/workflows/，不要求镜像。
while IFS= read -r f; do
  base="$(basename "${f}")"
  case "${base}" in
    ci-*.yml)
      if [[ ! -f "${SRC}/${base}" ]]; then
        echo "ORPHAN: .github/workflows/${base} 在 workflows/ 无对应源"
        drift=1
      fi
      ;;
    *)
      echo "LOCAL-ONLY OK: ${base}"
      ;;
  esac
done < <(find "${DST}" -maxdepth 1 -type f -name '*.yml' | sort)

if [[ "${CHECK_ONLY}" -eq 1 && "${drift}" -ne 0 ]]; then
  echo ""
  echo "FAIL: workflow 双份树不一致。运行: bash scripts/sync-workflows.sh" >&2
  exit 1
fi

echo ""
echo "DONE (check_only=${CHECK_ONLY})"
