# MY WORKOUT

Source: https://github.com/jalju0804/my-workout (private)

`main` push -> tests -> GHCR `sha-<commit>` image -> this directory's
`app/kustomization.yaml` image tag -> Argo CD sync.
The application workflow uses a dedicated repository deploy key, stored in its
`MANIFEST_DEPLOY_KEY` Actions secret. No cluster credentials are used by CI.

Target: `home-dev`, namespace `my-workout`, single replica, `Recreate` deployment.
SQLite is stored at `/data/workout.sqlite3` on `my-workout-data` PVC.
Do not increase replicas or switch to rolling updates while using this database.
The init container backs up before pending migrations, then migrates and seeds.
Argo CD pruning/deletion is disabled for both PVC resources. The underlying
`local-path` StorageClass still deletes its volume if the PVC is manually deleted.

Required out-of-Git secrets in namespace `my-workout`:

- `my-workout`: `DJANGO_SECRET_KEY`, stable across deployments and restores.
- `ghcr-secret`: `kubernetes.io/dockerconfigjson`, credentials with access to the private image.

Create the application once:

```sh
kubectl --context home-dev apply -f my-workout/application.yaml
```

Provision the personal account once, after the first rollout:

```sh
kubectl --context home-dev -n my-workout exec -it deployment/my-workout -- python manage.py createsuperuser
```

Only a ClusterIP service is included until the private HTTPS access route is
configured. `/healthz/` is the only unauthenticated HTTP health endpoint and
does not expose workout data.

The CronJob performs a daily online backup at 03:00 Asia/Seoul, retaining 30
daily and 12 monthly copies on `my-workout-backups`. Both PVCs currently use
the same node's local disk: this protects against application mistakes, not
loss of the node/disk. Copy backups to another machine before relying on
disaster recovery. `BACKUP_ALERT_URL` can be added to the runtime Secret.

Rollback application code by pinning an earlier published image tag; this does
not roll back the SQLite schema. For an incompatible schema rollback, stop the
app and restore a matching backup before starting the old image.
