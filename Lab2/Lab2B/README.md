# Lab 2B

## What 2B Is

2B is about making `/api/public-feed` cacheable at the edge by having the app return:

```
Cache-Control: public, s-maxage=30, max-age=0
```

## Relationship to 2A

2A already configured CloudFront to honor the origin's cache headers for `/api/public-feed`.

## What I Need To Do

1. Make sure the app has a `GET /api/public-feed` route
2. Make the route return the correct `Cache-Control` header
3. Verify the route works with curl
4. Save proof in the deliverables folder

## Verification

Example command:

```bash
curl -sI "https://app.cloudyjones.xyz/api/public-feed"
```

Expect to see `Cache-Control: public, s-maxage=30, max-age=0` in the response headers and a 200 status. Save the output to `deliverables/proof/` (e.g. `proof-public-feed-headers.txt`).

## Deliverables

- **deliverables/docs/2b_what_this_proves.txt** — What each proof file shows
- **deliverables/docs/2b_cache_explanation.txt** — Short written cache key and forwarding explanation
- **deliverables/docs/chewbacca_haiku.txt** — Haiku (Japanese only)
- **deliverables/docs/2b_done_checklist.txt** — Checklist for 2B completion
- **deliverables/proof/** — Save curl outputs here (static, api/list, public-feed)
