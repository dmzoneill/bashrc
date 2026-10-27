# bashrc

My modular Bash configuration.

## How it works

`00-loader.sh` sources every script in `scripts.d` in order, then calls
`load-secrets`.

- `00-aliases.sh` and `01-modern-hints.sh` set aliases and hints.
- `00-lazy-secrets.sh` provides helpers that register secrets and load them from
  `pass` (GPG) or the system keyring only when needed, so no secret values are
  stored in this repository.
- The numbered scripts set environment variables for tools and services such as
  GitHub, GitLab, Jira, Slack, AI providers, Cloudflare, Docker, PyPI and npm.

## Usage

Clone the repository to `~/.bashrc.d` and add this line to `~/.bashrc`:

```sh
. ~/.bashrc.d/00-loader.sh
```

## License

Licensed under the Apache License 2.0. See [LICENSE](LICENSE).
