# Copy Path

파일·폴더의 전체 경로를 우클릭 한 번으로 복사하는 도구입니다. 최근 복사한 경로를 다시 복사하거나 바로 열 수도 있습니다.

| 폴더 | 내용 |
|---|---|
| [macos/](macos) | macOS Finder 확장 (Swift, Finder Sync). `macos/build.sh`로 `Copy Path.app`을 빌드합니다. |
| [windows/](windows) | Windows 11 탐색기 우클릭 메뉴 (PowerShell). 설치 방법은 [windows/README.txt](windows/README.txt)에 있습니다. |
| [releases/](releases) | Windows용 배포 ZIP |

## 메뉴

- **Copy Path**: 선택한 파일·폴더의 전체 경로를 따옴표 없이 복사합니다.
- **Recent Paths**: 최근 복사한 경로 10개 중 하나를 다시 복사합니다.
- **Open Paths**: 최근 경로의 파일은 기본 앱으로, 폴더는 탐색기(Finder)로 엽니다.

## Windows 사용자는 prompt-expert를 권장합니다

Windows 기능은 [prompt-expert](https://github.com/uengine-oss/prompt-expert)에 통합되었습니다.
prompt-expert는 같은 메뉴를 PowerShell 창 깜빡임 없이 제공하고, Alt 키 음성 받아쓰기도 함께 들어 있습니다.
설치할 때 예전 PowerShell 버전의 메뉴를 정리하고 최근 경로 기록은 그대로 가져옵니다.
