# /document-commit-push

This command automates the process of updating documentation, adding a changelog entry, and committing and pushing all changes.

## Arguments

-   `summary`: A string summarizing the changes. This will be used in the changelog and commit message.

## Behavior

1.  Analyzes staged git changes.
2.  Updates any relevant documentation in the `/docs` directory.
3.  Adds a new entry to `CHANGELOG.md`.
4.  Commits all changes with a conventional commit message.
5.  Pushes the commit to the remote repository.
