#!/usr/bin/env bash

# 도움말 함수 정의
help() {
  echo "사용법: $(basename $0) -d <디렉토리> -t <확장자> -s <문자열> -e <o|x> [-o <출력_파일>] [-x <제외_디렉토리>]"
  echo ""
  echo "Parameters:"
  echo "  -d <디렉토리>: 검색할 디렉토리 (필수, 여러 개 가능)"
  echo "  -t <확장자>: 검색할 파일 확장자 (필수, 대소문자 무시)"
  echo "  -s <문자열>: 찾을 문자열 (필수)"
  echo "  -e <o|x>: 문자열 존재 여부 ('o': 존재하는 파일, 'x': 존재하지 않는 파일)"
  echo "  -o <출력_파일>: 결과를 출력할 파일 경로 (옵션)"
  echo "  -x <제외_디렉토리>: 검색에서 제외할 디렉토리 (옵션, 여러 개 가능)"
  echo ""
  exit 1
}

# 파라미터 처리
while getopts "d:t:s:e:o:x:h" opt; do
  case $opt in
    d) directories+=("$(realpath "$OPTARG")") ;;  # ❗ 절대경로 변환
    t) ext="$OPTARG" ;;
    s) search_string="$OPTARG" ;;
    e) existence="$OPTARG" ;;
    o) output="$OPTARG" ;;
    x) exclude_dirs+=("$(realpath "$OPTARG")") ;;  # ❗ 제외 디렉토리도 절대경로 변환
    h) help ;;
    \?) help ;;
  esac
done

# 입력된 디렉토리가 없으면 현재 디렉토리를 사용
if [ ${#directories[@]} -eq 0 ]; then
  directories=("$(pwd)")
fi

# 필수 파라미터 확인
if [ -z "$directories" ] || [ -z "$ext" ] || [ -z "$search_string" ] || [ -z "$existence" ]; then
  echo "필수 파라미터가 누락되었습니다."
  help
fi

# 검색 결과 저장 변수
declare -A dir_count
declare -A subdir_count
declare -A found_files
total_count=0

# 존재 여부 값 소문자로 변환
existence_lower=$(echo "$existence" | tr '[:upper:]' '[:lower:]')

# 제외 디렉토리 패턴 생성 (find에서 제외 처리)
exclude_patterns=()
for ex_dir in "${exclude_dirs[@]}"; do
  exclude_patterns+=("-path \"$ex_dir\" -prune -o")
done

# 여러 디렉토리에서 검색 실행
for directory in "${directories[@]}"; do
  if [ ! -d "$directory" ]; then
    echo "디렉토리 $directory 가 존재하지 않습니다."
    continue
  fi

  # 제외 디렉토리 패턴을 추가하여 검색
  find_cmd="find \"$directory\" ${exclude_patterns[*]} -type f -name \"*.$ext\" -print0"
  
  while IFS= read -r -d '' file; do
    if grep -Iq "$search_string" "$file"; then
      file_has_string=true
    else
      file_has_string=false
    fi

    # 존재 여부 필터링
    if [[ ("$existence_lower" == "o" && "$file_has_string" == true) ||
        ("$existence_lower" == "x" && "$file_has_string" == false) ]]; then
      rel_path="${file#$directory/}"  # 상대 경로
      found_files["$directory"]+="$rel_path"$'\n'
      dir_name=$(dirname "$rel_path")
      ((subdir_count["$directory|$dir_name"]++))
      ((dir_count["$directory"]++))
      ((total_count++))
    fi
  done < <(eval "$find_cmd")
done

# 결과 출력
if [ -n "$output" ]; then
  exec > "$output" 2>&1
fi

echo "=========================="
echo " 검색 요청사항"
echo "=========================="
echo "검색 디렉토리:"
for directory in "${directories[@]}"; do
  echo "- $directory"
done | sort
echo "파일 확장자: $ext"
echo "찾을 문자열: $search_string"
echo "존재 여부: $existence"
if [ -n "$output" ]; then
  echo "출력 파일: $output"
fi
if [ ${#exclude_dirs[@]} -gt 0 ]; then
  echo "제외 디렉토리:"
  for ex_dir in "${exclude_dirs[@]}"; do
    echo "- $ex_dir"
  done | sort
fi
echo "--------------------------"
echo "검색된 파일 개수"
echo "- $total_count 개"
echo "--------------------------"
echo "디렉토리별 파일 개수"
for dir in $(printf "%s\n" "${directories[@]}" | sort); do
  count=${dir_count["$dir"]:-0}
  echo "- $dir: $count 개"
  for key in $(printf "%s\n" "${!subdir_count[@]}" | sort); do
    IFS='|' read -r base sub <<< "$key"
    if [[ "$base" == "$dir" ]]; then
      echo "  + $sub: ${subdir_count["$key"]} 개"
    fi
  done
done
echo "--------------------------"
echo "검색된 파일"
for dir in $(printf "%s\n" "${directories[@]}" | sort); do
  echo "- $dir"
  echo "${found_files["$dir"]}" | sort | sed '/^$/d' | sed 's/^/  + /'
done
echo "--------------------------"

exit 0

