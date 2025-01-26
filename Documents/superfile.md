# superfile


## cd on quit

- setting `cd_on_quit` to `true` on `~/.config/superfile/config.toml`

```toml
cd_on_quit = true
```

- update your `shrc` file

    - `.bashrc`
    ```sh
    spf() {
        os=$(uname -s)

        # Linux
        if [[ "$os" == "Linux" ]]; then
            export SPF_LAST_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/superfile/lastdir"
        fi

        # macOS
        if [[ "$os" == "Darwin" ]]; then
            export SPF_LAST_DIR="$HOME/Library/Application Support/superfile/lastdir"
        fi

        command spf "$@"

        [ ! -f "$SPF_LAST_DIR" ] || {
            . "$SPF_LAST_DIR"
            rm -f -- "$SPF_LAST_DIR" > /dev/null
        }
    }
    ```
    - `.zshrc`
    ```sh
    function spf() {
        os=$(uname -s)

        # Linux
        if [[ "$os" == "Linux" ]]; then
            export SPF_LAST_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/superfile/lastdir"
        fi

        # macOS
        if [[ "$os" == "Darwin" ]]; then
            export SPF_LAST_DIR="$HOME/Library/Application Support/superfile/lastdir"
        fi

        command spf "$@"

        [ ! -f "$SPF_LAST_DIR" ] || {
            . "$SPF_LAST_DIR"
            rm -f -- "$SPF_LAST_DIR" > /dev/null
        }
    }
    ```
