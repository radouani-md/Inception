# Bash if: With `[]` and Without `[]`

## Why do we use `[]` with `if`?

In Bash, `if` does not directly evaluate a condition like many other languages.

`if` expects a **command** and checks the command's exit status:

- `0` = success = true
- non-zero = failure = false

`[]` is a command used to **test a condition**.

For example:

```bash
if [ "$age" -gt 18 ]; then
    echo "Adult"
fi