# bash 자동 완성 파일 등록 방법

bash 자동 완성(bash completion) 파일을 개인 사용자 및 전체 사용자에 대해 등록하는 방법은 다음과 같습니다.

## 개인 사용자 등록

1.  **자동 완성 파일 위치:**
    * 개인 사용자의 자동 완성 파일은 일반적으로 `~/.bash_completion.d/` 디렉토리에 위치합니다. 이 디렉토리가 없다면 생성해야 합니다.

        ```bash
        mkdir -p ~/.bash_completion.d/
        ```

2.  **자동 완성 파일 복사:**
    * 자동 완성 파일을 `~/.bash_completion.d/` 디렉토리에 복사합니다. 예를 들어, `my_completion.bash`라는 파일을 복사하려면 다음과 같이 합니다.

        ```bash
        cp my_completion.bash ~/.bash_completion.d/
        ```

3.  **`.bashrc` 파일 수정:**
    * `~/.bashrc` 파일에 다음 내용을 추가하여 자동 완성 기능을 활성화합니다.

        ```bash
        if [[ -f ~/.bash_completion ]]; then
            . ~/.bash_completion
        fi
        for i in ~/.bash_completion.d/*; do
            if [[ -f $i ]]; then
                . $i
            fi
        done
        ```

4.  **`.bashrc` 파일 적용:**
    * 변경된 `.bashrc` 파일을 적용하기 위해 다음 명령어를 실행하거나 새 터미널을 엽니다.

        ```bash
        source ~/.bashrc
        ```

## 전체 사용자 등록

1.  **자동 완성 파일 위치:**
    * 전체 사용자의 자동 완성 파일은 일반적으로 `/etc/bash_completion.d/` 디렉토리에 위치합니다. 이 디렉토리가 없다면 생성해야 합니다.

        ```bash
        sudo mkdir -p /etc/bash_completion.d/
        ```

2.  **자동 완성 파일 복사:**
    * 자동 완성 파일을 `/etc/bash_completion.d/` 디렉토리에 복사합니다. 예를 들어, `my_completion.bash`라는 파일을 복사하려면 다음과 같이 합니다.

        ```bash
        sudo cp my_completion.bash /etc/bash_completion.d/
        ```

3.  **`/etc/bash.bashrc` 파일 수정:**
    * `/etc/bash.bashrc` 파일에 다음 내용을 추가하여 자동 완성 기능을 활성화합니다.

        ```bash
        if [[ -f /etc/bash_completion ]]; then
            . /etc/bash_completion
        fi
        for i in /etc/bash_completion.d/*; do
            if [[ -f $i ]]; then
                . $i
            fi
        done
        ```

4.  **`/etc/bash.bashrc` 파일 적용:**
    * 변경된 `/etc/bash.bashrc` 파일을 적용하기 위해 다음 명령어를 실행하거나 새 터미널을 엽니다.

        ```bash
        source /etc/bash.bashrc
        ```

## 참고 사항

* 자동 완성 파일은 일반적으로 `.bash` 확장자를 가지며, bash 스크립트 형식으로 작성됩니다.
* 자동 완성 파일의 내용은 특정 명령어에 대한 자동 완성 규칙을 정의합니다.
* 자동 완성 기능이 제대로 작동하지 않으면, 자동 완성 파일의 내용이나 권한을 확인해야 합니다.
