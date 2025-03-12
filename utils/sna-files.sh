#!/usr/bin/env bash

# 도움말 함수 정의
help() {
  echo "사용법: $(basename $0) -d <디렉토리> -t <확장자> -s <문자열> [-p <위치>] (-c <추가_문자열> | -f <추가_파일>) [-x <제외_디렉토리>]"
  echo ""
  echo "Parameters:"
  echo "  -d, --input-dir <디렉토리>: 검색할 디렉토리 (필수, 여러 개 가능)"
  echo "  -t, --file-ext <확장자>: 검색할 파일 확장자 (필수)"
  echo "  -s, --target-str <문자열>: 찾을 문자열 (필수)"
  echo "  -p, --content-position <위치>: 추가할 위치 (옵션, 기본값: top, 'top' 또는 'bottom')"
  echo "  -c, --content-str <추가_문자열>: 찾는 문자열이 없을 경우 추가할 문자열"
  echo "  -f, --content-file <추가_파일>: 찾는 문자열이 없을 경우 추가할 파일 내용"
  echo "  -x, --excluded-dir <제외_디렉토리>: 검색에서 제외할 디렉토리 (옵션, 여러 개 가능)"
  echo ""
  echo "Constraints:"
  echo "  - '-c'와 '-f' 둘 중 하나는 필수 (둘 다 입력 불가, 둘 다 없으면 오류)."
  echo "  - '-p'가 없으면 기본값은 'top'."
  exit 1
}

# 기본값 설정
position="top"  # ❗ 기본값을 `top`으로 설정

# 파라미터 처리 (확장 옵션 지원)
while [[ $# -gt 0 ]]; do
  case "$1" in
    -d|--input-dir)
      directories+=("$(realpath "$2")")
      shift 2
      ;;
    -t|--file-ext)
      ext="$2"
      shift 2
      ;;
    -s|--target-str)
      search_string="$2"
      shift 2
      ;;
    -p|--content-position)
      position="$2"
      shift 2
      ;;
    -c|--content-str)
      add_string="$2"
      shift 2
      ;;
    -f|--content-file)
      add_file="$2"
      shift 2
      ;;
    -x|--excluded-dir)
      exclude_dirs+=("$(realpath "$2")")
      shift 2
      ;;
    -h|--help)
      help
      ;;
    *)
      echo "❌ 알 수 없는 옵션: $1"
      help
      ;;
  esac
done

# 필수 옵션 검증
if [ -z "$directories" ] || [ -z "$ext" ] || [ -z "$search_string" ]; then
  echo "❌ 필수 파라미터가 누락되었습니다."
  help
fi

# 추가할 내용 검증
if [ -n "$add_string" ] && [ -n "$add_file" ]; then
  echo "❌ '-c'와 '-f'는 동시에 사용할 수 없습니다."
  help
elif [ -z "$add_string" ] && [ -z "$add_file" ]; then
  echo "❌ '-c' 또는 '-f' 중 하나는 반드시 입력해야 합니다."
  help
fi

# 추가할 위치 검증
if [[ "$position" != "top" && "$position" != "bottom" ]]; then
  echo "❌ '-p' 옵션 값은 'top' 또는 'bottom' 이어야 합니다."
  help
fi

# 제외 디렉토리 패턴을 위한 배열
exclude_conditions=()
for ex_dir in "${exclude_dirs[@]}"; do
  exclude_conditions+=("-path" "$ex_dir" "-prune")
done

# 여러 디렉토리에서 파일 검색 및 수정 실행
for directory in "${directories[@]}"; do
  if [ ! -d "$directory" ]; then
    echo "❌ 디렉토리 $directory 가 존재하지 않습니다."
    continue
  fi

  # 제외 디렉토리가 있으면 `-prune`을 적용하여 검색, 없으면 일반 검색
  if [ ${#exclude_conditions[@]} -gt 0 ]; then
    find_cmd=(find "$directory" \( "${exclude_conditions[@]}" \) -o -type f -name "*.$ext" -print0)
  else
    find_cmd=(find "$directory" -type f -name "*.$ext" -print0)
  fi

  while IFS= read -r -d '' file; do
    if grep -q "$search_string" "$file"; then
      echo "✅ '$search_string'이 존재하는 파일: $file (변경 없음)"
    else
      echo "⚠️ '$search_string'이 없는 파일: $file (추가 필요)"

      # 추가할 내용 결정
      if [ -n "$add_string" ]; then
        content_to_add="$add_string"
      elif [ -f "$add_file" ]; then
        content_to_add=$(cat "$add_file")
      else
        echo "❌ 추가할 내용이 없습니다."
        continue
      fi

      # 내용 추가
      if [[ "$position" == "top" ]]; then
        echo -e "$content_to_add\n\n$(cat "$file")" > "$file"
      elif [[ "$position" == "bottom" ]]; then
        echo -e "\n$content_to_add" >> "$file"
      fi

      echo "📝 '$file'에 내용 추가됨."
    fi
  done < <("${find_cmd[@]}")
done

echo "✅ 작업 완료!"
exit 0

