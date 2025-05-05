---
date: 2025-04-21
authors:
  - deepak
categories:
  - tech
tags:
  - python
description:
    - Simplifying python mono repos with UV workspaces
title: Python Monorepos with UV
---

# Introduction

If you've spent any time as a Python developer lately, you've definitely heard of [UV](https://github.com/astral-sh/uv) - the blazing-fast Python package and project manager that's solving so many problems in the Python ecosystem. 
At [Valkyrie](https://github.com/deepakdinesh1123/valkyrie), we initially started using UV in our Python SDK. But when we began working on an MCP server
I found myself wondering how to effectively manage multiple Python projects in the same repository.

# The Monorepo Headaches

Anyone who's tried housing multiple Python projects in a single repo has likely run into these frustrations:

- Creating separate virtual environments for each project quickly becomes wasteful - you end up with duplicate dependencies everywhere
- When one project needs to depend on another project in the same repo, the dependency management gets messy fast
- You find yourself copy-pasting nearly identical `setup.py` or `pyproject.toml` configs across projects

These pain points had me searching for a better way to structure our codebase.

# Enter UV Workspaces

Thankfully, UV offers [workspaces](https://docs.astral.sh/uv/concepts/projects/workspaces/) - an elegant solution to all these problems. You can define each project as a workspace member and manage them together, which simplifies your workflow.

Getting started with workspaces in an existing project is straightforward. You can run:

```bash
uv init <project_name>
```

Or you can manually edit the `pyproject.toml` of your root project to include new members like this:

```toml
[project]
name = "python-project"
version = "0.1.0"
description = "python-project"
readme = "README.md"
requires-python = ">=3.12"
dependencies = ["project1", "project2"]

[tool.uv.sources]
project2 = { workspace = true }
project1 = { workspace = true }

[tool.uv.workspace]
members = ["project1", "<path>/project2"]
```

The beauty of this approach is that you can now:
- Define dependencies at either the workspace level (shared across all projects) or at the individual project level
- Easily declare one project as a dependency of another, and UV will handle building everything in the right order
- Maintain a single virtual environment while still keeping your projects logically separated

For example, here's how you'd set up project1 to depend on project2 within the workspace:

```toml
[project]
name = "project1"
version = "0.1.0"
description = "python project"
readme = "README.md"
requires-python = ">=3.12"
dependencies = [
 "project2",
]

[tool.uv.sources]
project2 = { workspace = true }
```

When you create an environment, UV builds all the projects and resolves the dependencies correctly.

You can check out how we use UV workspaces at valkyrie [here](https://github.com/deepakdinesh1123/valkyrie)

**Word of Caution**: 
Python doesn't provide true dependency isolation, so UV can't guarantee that a package uses only its declared dependencies and nothing else. With workspaces specifically, there's no mechanism preventing packages from importing dependencies declared by another workspace member.
So make sure to use workspaces only when you are certain that member projects don't have conflicting dependencies and they are related to each other and share common dependencies

Have you tried using UV workspaces for your Python projects yet? I'd love to hear about your experience.