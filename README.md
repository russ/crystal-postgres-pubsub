# Crystal Postgres Pubsub Experiments

Start the server.

```
crystal src/server.cr
```


Start the worker.

```
crystal src/worker.cr
```


Post a new job.

```
curl -X POST -d '{"url":"google.com"}' -H 'Content-Type: application/json' http://localhost:6662/jobs/special_job
```
