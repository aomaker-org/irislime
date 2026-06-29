
# Git Workflows, Branch Retention, & Trunk Protection

This module documents the authoritative version control methodology, branching constraints, and merge strategies governing development tracking within the IrisLime ecosystem.

## 1. The Branch Retention Mandate

This project enforces a strict architectural policy: **Historical development and feature branches are never deleted from the remote origin server.**

In Git, a branch is merely a mutable pointer file containing a 40-character SHA hash referencing a specific node in the commit graph. Deleting a branch pointer eliminates the human-readable index referencing that line of development. Over time, unreferenced commits are permanently scrubbed by Git's garbage collection subroutines (`git gc`).

By completely retaining all feature branches on the remote server, we maintain an immutable, non-destructive audit trail of every validation sprint, intermediate experiment, and configuration failure. This ensures that the low-level workspace history is fully discoverable. To prevent branch clutter, completed feature heads are systematically isolated within structural folder paths on the server:

* `archive/feature-onboarding-and-testing-harness`
* `checkpoint/20260625-sycl-patch`

## 2. Technical Rationale for the Squash Merge

When a feature branch passes validation testing, it is consolidated into the production trunk (`main`) strictly using the **Squash and Merge** primitive (`gh pr merge <id> --squash`).

During local development iterations, engineers and automated execution blocks generate numerous granular micro-commits. These often represent incomplete states of the codebase—debugging hooks, trial-and-error compiler fixes, or intermediate log failures. Injecting these raw micro-commits directly into the primary tracking tree introduces historical pollution.

A squash merge takes the entire aggregated delta of the feature branch and condenses it into a *single, brand-new commit* applied directly to the head of the production branch.

### Why We Squash: Four Core Engineering Objectives

1. **Strictly Linear History**: It eliminates multi-parent merge web topologies. The production history remains a straight, easily read line.
2. **Guaranteed Atomic Commit Boundaries**: Every single commit on `main` is guaranteed to represent a completely stable, fully compiling software state. The production branch transitions instantly from working pre-feature code to working post-feature code.
3. **Optimized Troubleshooting via `git bisect**`: When looking for an engine regression, `git bisect` utilizes a binary search through the timeline. If the branch history contains broken, non-compiling micro-commits, `git bisect` frequently halts on intermediate broken states where test suites cannot execute. Squashing ensures every search hop lands on a clean, valid compilation milestone.
4. **Separation of Concerns**: High-level intent is documented on `main`, while low-level step-by-step developer implementation metrics remain safely archived on the un-deleted feature branches.

## 3. Automated Validation Gates (Trunk Protection)

To scale the repository safely from a single human operator to multiple automated agents, the production branch (`main`) is locked behind strict branch protection boundaries:

* **No Direct Pushes**: All code insertions must transition through a verified Pull Request canvas.
* **Mandatory Squash Linearization**: Disallows standard 3-way merges to prevent history fractures.
* **Force-Push Prohibition**: Direct blocks are placed against `git push --force` strings, ensuring the underlying historical graph cannot be modified or overwritten.
