# Fetching PR review comments

Command recipes for the triage-pr-reviews skill. Resolve `owner` / `repo` first:

```bash
gh repo view --json owner,name -q '.owner.login + "/" + .name'
```

## REST — the three comment sources

Comments live in three separate REST endpoints — fetch all of them (`--paginate` handles paging):

| Source | Command | Content |
|--------|---------|---------|
| **Inline review comments** | `gh api repos/{owner}/{repo}/pulls/{number}/comments --paginate` | Comments anchored to a diff line (`path` / `line` / `diff_hunk` available) |
| **Review summary** | `gh api repos/{owner}/{repo}/pulls/{number}/reviews --paginate` | Top-level review `body` (Approve / RequestChanges / Comment) |
| **Issue comments** | `gh api repos/{owner}/{repo}/issues/{number}/comments --paginate` | General PR conversation comments |

## GraphQL — thread resolution state

When thread resolution state (`isResolved`) is needed:

```bash
gh api graphql --paginate -F owner=<owner> -F repo=<repo> -F num=<number> -f query='
  query($owner:String!,$repo:String!,$num:Int!,$endCursor:String){
    repository(owner:$owner,name:$repo){
      pullRequest(number:$num){
        reviewThreads(first:100,after:$endCursor){
          pageInfo{ hasNextPage endCursor }
          nodes{
            id
            isResolved
            comments(first:100){
              pageInfo{ hasNextPage endCursor }
              nodes{ id author{login} body path line }
            }
          }
        }
      }
    }
  }'
```

`--paginate` exhausts the outer thread connection. If any nested `comments.pageInfo.hasNextPage` is
true, exhaust that thread separately:

```bash
gh api graphql --paginate -F thread=<thread-id> -f query='
  query($thread:ID!,$endCursor:String){
    node(id:$thread){
      ... on PullRequestReviewThread {
        comments(first:100,after:$endCursor){
          pageInfo{ hasNextPage endCursor }
          nodes{ id author{login} body path line }
        }
      }
    }
  }'
```

Replace that thread's embedded comment page with the paginated result, keyed by comment `id` so
the first page is not counted twice. Do not classify the review until every connection is
exhausted.
