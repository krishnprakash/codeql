## Overview

GitHub Actions cache poisoning is a technique that allows an attacker to inject malicious content into the Action's cache from unprivileged workflow, potentially leading to code execution in privileged workflows.

An attacker with the ability to run code in the context of the default branch (e.g. through Code Injection or Execution of Untrusted Code) can exploit this to:

1. Steal the cache access token and URL.
2. Overflow the cache to trigger eviction of legitimate entries.
3. Poison cache entries with malicious payloads.
4. Achieve code execution in privileged workflows that restore the poisoned cache.

This allows lateral movement from low-privileged to high-privileged workflows within a repository.

### Cache Structure

In GitHub Actions, cache scopes are primarily determined by the branch structure. Branches are considered the main security boundary for GitHub Actions caching. This means that cache entries are generally scoped to specific branches.

- **Access to Parent Branch Caches**: Feature branches (or child branches) created off of a parent branch (like `main` or `dev`) can access caches from the parent branch. For instance, a feature branch off of `main` will be able to access the cache from `main`.

- **Sibling Branches**: Sibling branches, meaning branches that are created from the same parent but not from each other, do not share caches. For example, two branches created off of `main` will not be able to access each other’s caches directly.

Due to the above design, if something is cached in the context of the default branch (e.g., `main`), it becomes accessible to any feature branch derived from `main`.

## Recommendation

1. Avoid using caching in workflows that handle sensitive operations like releases.
2. If caching must be used:
   - Validate restored cache contents before use.
   - Use short-lived, workflow-specific cache keys.
   - Clear caches regularly.
3. Implement strict isolation between untrusted and privileged workflow execution.
4. Never run untrusted code in the context of the default branch.
5. Sign the cache value cryptographically and verify the signature before usage.

## Example

### Incorrect Usage

The following workflow runs untrusted code in a non-privileged job but in the context of the default branch.

```yaml
name: Vulnerable Workflow
on:
  pull_request_target:
    branches: [main]
permissions: {}
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
        with:
          ref: ${{ github.event.pull_request.head.sha }}
      - name: Run tests
        run: ./run_tests.sh
```

### Correct Usage

The following workflow runs untrusted code in a non-privileged job and the cache is scoped to the Pull Request branch.

```yaml
name: Secure Workflow
on:
  pull_request:
    branches: [main]
permissions: {}
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
        with:
          ref: ${{ github.event.pull_request.head.sha }}
      - name: Run tests
        run: ./run_tests.sh
```

## References

- Adnan Khan's Blog: [The Monsters in Your Build Cache – GitHub Actions Cache Poisoning](https://adnanthekhan.com/2024/05/06/the-monsters-in-your-build-cache-github-actions-cache-poisoning/).
- GitHub Docs: [GitHub Actions Caching Documentation](https://docs.github.com/en/actions/using-workflows/caching-dependencies-to-speed-up-workflows).
- Scribe Security Blog: [Cache Poisoning in GitHub Actions](https://scribesecurity.com/blog/github-cache-poisoning/).
