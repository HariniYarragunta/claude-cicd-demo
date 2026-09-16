# From Project Creation to CI/CD — Command Reference

End-to-end walkthrough, with every command, for taking a project from
`mkdir` to a working CI/CD pipeline on GitHub and GitLab. Examples use this
repo (`claude-cicd-demo`, a Node.js project testing `add()` in
[`src/math.js`](src/math.js)) but the commands apply to any project.

---

## 1. Create the project

```bash
mkdir claude-cicd-demo
cd claude-cicd-demo

# Initialize a Node.js project (creates package.json)
npm init -y

# Initialize git
git init
git branch -M main
```

`npm init -y` accepts all defaults. Edit `package.json` afterward to set
`"type": "module"` and a `test` script:

```json
{
  "name": "claude-cicd-demo",
  "version": "1.0.0",
  "type": "module",
  "scripts": {
    "test": "node --test"
  }
}
```

## 2. Add a `.gitignore`

```bash
echo "node_modules/" >> .gitignore
echo ".env" >> .gitignore
```

## 3. Write source code and tests

```bash
mkdir src
```

`src/math.js`:

```js
export function add(a, b) {
  return a + b;
}
```

`src/math.test.js` (uses Node's built-in test runner — no dependency
needed):

```js
import { test } from "node:test";
import assert from "node:assert/strict";
import { add } from "./math.js";

test("add() sums two positive numbers", () => {
  assert.equal(add(2, 3), 5);
});
```

## 4. Run it locally

```bash
npm install      # installs any listed dependencies (none currently)
npm test         # runs `node --test`, executes src/math.test.js
```

---

## 5. Git commands — everyday workflow

```bash
git status                     # what's changed / staged / untracked
git add src/math.js            # stage a specific file
git add .                      # stage everything (careful with secrets/.env)
git commit -m "Add math module"
git log --oneline -10          # recent history
git diff                       # unstaged changes
git diff --staged              # staged changes

git branch                     # list local branches
git checkout -b bug-fix        # create + switch to a new branch
git switch main                # switch branches (newer alternative)

git push -u origin main        # first push, sets upstream
git push                       # subsequent pushes
git pull                       # fetch + merge from remote
git fetch                      # fetch without merging

git merge bug-fix              # merge a branch into the current one
git rebase main                # replay current branch's commits onto main
```

---

## 6. Connect to a remote — GitHub

```bash
# Create the repo on GitHub first (via UI, or with GitHub CLI):
gh repo create claude-cicd-demo --public --source=. --remote=origin

# ...or if the repo already exists:
git remote add origin https://github.com/<user>/claude-cicd-demo.git

git push -u origin main
```

This repo's actual remotes (for reference):

```
origin  https://github.com/HariniYarragunta/claude-github-demo.git
cicd    https://github.com/HariniYarragunta/claude-cicd-demo.git
```

Useful `gh` CLI commands once connected:

```bash
gh repo view --web             # open the repo in a browser
gh pr create                   # open a PR from the current branch
gh pr list
gh pr checkout 12              # check out PR #12 locally
gh pr merge 12 --squash
gh run list                    # recent Actions workflow runs
gh run view <run-id> --log     # view logs for a run
gh workflow list
gh secret set ANTHROPIC_API_KEY   # add a repo secret from the CLI
```

## 7. GitHub Actions — add CI

```bash
mkdir -p .github/workflows
```

`.github/workflows/ci.yml`:

```yaml
name: CI

on:
  push:
    branches: [main]
  pull_request:

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 20
      - run: npm install
      - run: npm test
```

```bash
git add .github/workflows/ci.yml
git commit -m "Add CI workflow"
git push
```

Then open a PR (`gh pr create`) or push to `main` — the pipeline runs
automatically. Check it with `gh run list` / `gh run watch`, or the repo's
**Actions** tab.

---

## 8. Connect to a remote — GitLab

```bash
# Create the project on GitLab first (via UI, or with glab CLI):
glab repo create claude-cicd-demo --public

# ...or if it already exists:
git remote add gitlab https://gitlab.com/<user>/claude-cicd-demo.git

git push -u gitlab main
```

Useful `glab` CLI commands once connected:

```bash
glab repo view --web
glab mr create                 # open a merge request
glab mr list
glab mr checkout 12
glab mr merge 12
glab ci status                 # pipeline status for current branch
glab ci view                   # open pipeline logs
glab variable set ANTHROPIC_API_KEY   # add a CI/CD variable from the CLI
```

## 9. GitLab CI/CD — add a pipeline

`.gitlab-ci.yml` at the repo root:

```yaml
image: node:20

stages:
  - test

test:
  stage: test
  script:
    - npm install
    - npm test
  rules:
    - if: '$CI_PIPELINE_SOURCE == "merge_request_event"'
    - if: '$CI_COMMIT_BRANCH == "main"'
```

```bash
git add .gitlab-ci.yml
git commit -m "Add GitLab CI pipeline"
git push gitlab main
```

Check the pipeline under **CI/CD → Pipelines** in the GitLab UI, or via
`glab ci status`.

---

## 10. Quick-reference command cheat sheet

| Task | Command |
|---|---|
| Init a Node project | `npm init -y` |
| Init a git repo | `git init` |
| Stage + commit | `git add . && git commit -m "message"` |
| New branch | `git checkout -b <name>` |
| Push new branch | `git push -u origin <name>` |
| Add a GitHub remote | `git remote add origin <url>` |
| Add a GitLab remote | `git remote add gitlab <url>` |
| Create a GitHub repo from CLI | `gh repo create <name> --public --source=. --remote=origin` |
| Create a GitLab repo from CLI | `glab repo create <name> --public` |
| Open a GitHub PR | `gh pr create` |
| Open a GitLab MR | `glab mr create` |
| Watch a GitHub Actions run | `gh run watch` |
| Check a GitLab pipeline | `glab ci status` |
| Add a GitHub secret | `gh secret set <NAME>` |
| Add a GitLab CI/CD variable | `glab variable set <NAME>` |
| Run tests locally | `npm test` |
| Tag a release | `git tag v1.0.0 && git push origin v1.0.0` |

See [CI-CD-GUIDE.md](CI-CD-GUIDE.md) for the deeper explanation of the
`math.js`-specific pipeline and the Claude-powered workflows already in this
repo's `.github/workflows/`.
