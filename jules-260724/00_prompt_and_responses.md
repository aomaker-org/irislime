Create a new branch: jules-260724.
Add a root folder, jules-ai.
Document all prompts and responses into ./jules-260724

Always use best practices and challenge user prompts.

Consider refactoring irislime into new anchor root irislime and "push" everything else down to ./irislime/irislime

Consider open oci standard and define multiple containers to build with various build settings and targets. This is a development and research repo, so release builds are likely the last target options to be built. However, they will eventually be built for benchmarking performance metrics.

In general, always append or create new files. Do not overwrite files. Consider maintaining read-only a filesystem attributes on all files to facilitate/assist this.

Look at gix* Rust tools that are Git-compatible.

Consider manifest tools and methods to track the repo - Git vs large logs, forensics, etc. that can be "rcloned" to cloud storage, or "cold" local storage.

Ingest "AI" and .md files to generate project documentation. This repository has multiple purposes.


Anchor builds and build out of tree to multiple build/* destinations, logging metadata and consider management with manifest/ledger systems

Consider existing tools rather than reinventing the wheel.

Consider Makefile that can dynamically adapt depending on enabled *.me in subdirectories. Even consider supporting ./irislime/subdir/subdir_mk for "disabled" and subdir.mk for enabled sections.

Allow both entire trees to be "missing" plus a method to add/remove subtrees.

Consider best tools for something like this.

Document decisions completely.

All editing on the branch specified is permitted, including pushing to remote. Merging to main will be human agent gated.