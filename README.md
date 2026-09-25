# Nexus Service Account Token Connectivity

Minimal GitHub Actions demo that checks HTTPS connectivity, authenticates to a Nexus Repository Cloud instance with a Sonatype service account token (SAT), and publishes a small demo archive to the hosted `raw` repository.

**Target:** [sonatype.dev.repo.saas.sonatype.dev](https://sonatype.dev.repo.saas.sonatype.dev/)

The workflow calls the Nexus REST API root using HTTP Basic authentication. It expects the service account name in `NEXUS_USERNAME` and the complete `sat.*` token in `NEXUS_TOKEN`. Sonatype documents this username/token pairing for Basic authentication. See [Service Account Tokens](https://help.sonatype.com/en/service-account-tokens.html).

## Configure GitHub Actions

1. In the repository, open **Settings → Secrets and variables → Actions**.
2. Add repository secrets:
   - `NEXUS_USERNAME`: your Nexus service account name (for example, `githubActions`)
   - `NEXUS_TOKEN`: the complete service account token beginning with `sat.`
3. Open **Actions → Nexus connectivity check → Run workflow**. It also runs on pushes to the default branch.

Each successful run uploads `nexus-sat-connectivity-demo.tar.gz` to:

```
https://sonatype.dev.repo.saas.sonatype.dev/repository/raw/connectivity-demo/github-actions/<run-id>-<attempt>/nexus-sat-connectivity-demo.tar.gz
```

The unique run path avoids overwriting prior demo packages. The archive contains this README and a small text manifest with the workflow run ID and timestamp.

The workflow never prints credentials or sends them to an untrusted action. It prints the HTTP status and response content type only. A successful authenticated request indicates connectivity and authentication; a 401 usually means the credentials were rejected, while DNS/TLS/timeout errors indicate a network or endpoint issue. Publishing also requires the token to have upload permission on the `raw` hosted repository.

## Local check

You can run the same probe locally without placing credentials in a command argument:

```sh
export NEXUS_USERNAME='githubActions'
read -s NEXUS_TOKEN
export NEXUS_TOKEN
./scripts/check-nexus.sh
```

The probe uses `curl --user` and does not enable verbose output.

## Notes

- Store the token only as a GitHub Actions secret or in a local secret manager. Never commit it.
- Use a time-limited, least-privileged Nexus token when possible.
- This demo checks the REST API root, not a repository-specific browse or publish permission. A 403 response can still demonstrate successful authentication with insufficient access to the root endpoint; adjust the probe to a repository URL that the service account is allowed to read if needed.
- GitHub-hosted runners need network access to the Nexus cloud hostname. If the instance restricts inbound traffic, a GitHub-hosted runner may not be able to reach it.
