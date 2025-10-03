# forms.digitale-gesellschaft.ch

[![Health](https://status.digig.es/api/v1/endpoints/back-end_forms-(formbricks)/health/badge.svg)](https://status.digig.es/endpoints/back-end_forms-(formbricks))
[![Uptime (30 days)](https://status.digig.es/api/v1/endpoints/back-end_forms-(formbricks)/uptimes/30d/badge.svg)](https://status.digig.es/endpoints/back-end_forms-(formbricks))
[![Response time (30 days)](https://status.digig.es/api/v1/endpoints/back-end_forms-(formbricks)/response-times/30d/badge.svg)](https://status.digig.es/endpoints/back-end_forms-(formbricks))

This repository contains code and configuration related to *Digitale Gesellschaft*'s survey tool available under
[**`forms.digitale-gesellschaft.ch`**](https://forms.digitale-gesellschaft.ch/).

We rely on [**Formbricks**](https://formbricks.com/) which we host on [Fly](https://fly.io/).

Sensitive configuration data is stored via [Fly secrets](https://fly.io/docs/reference/secrets/). Currently this includes the following environment variables:

- `CRON_SECRET`[^1]
- `DATABASE_URL`
- `ENCRYPTION_KEY`[^2]
- `NEXTAUTH_SECRET`[^3]
- `SMTP_PASSWORD`
- `SMTP_USER`

[^1]: Mustn't exceed 256 bits / 32 bytes in binary representation.

[^2]: Mustn't exceed 256 bits / 32 bytes in binary representation.

[^3]: Mustn't exceed 256 bits / 32 bytes in binary representation.

## Hosting details

- The Fly [app](https://fly.io/docs/reference/apps/) is named `digiges-forms`, currently runs on a single [`shared-cpu-1x` instance with `512 MB`
  RAM](https://fly.io/docs/about/pricing/#compute)[^4] and is hosted in the *Frankfurt, Germany* (`fra`) [region](https://fly.io/docs/reference/regions/).

- The `digiges-forms` app connects to the `formbricks` PostgreSQL database on our `pg-digiges` [Aiven](https://aiven.io/docs/products/postgresql) service hosted
  on [DigitalOcean](https://www.digitalocean.com/) in the *Frankfurt, Germany* (`fra`) region.

  Note that Aiven's Postgres cluster TLS certificates are [signed by its own private CA](https://aiven.io/docs/platform/concepts/tls-ssl-certificates), so we
  have to [manually](https://aiven.io/docs/platform/concepts/tls-ssl-certificates#certificate-requirements) specify the right certificate file when connecting,
  e.g.:

  ``` sh
  PGSSLROOTCERT=aiven.io_ca.pem psql --dbname=$(grep -Po "(?<=^DATABASE_URL=').+(?='$)" .secrets)
  ```

- Formbricks [requires](https://formbricks.com/docs/self-hosting/setup/cluster-setup#redis-configuration) a Redis-compatible key value store, even for a
  single-machine deployment. We use [Valkey](https://valkey.io/), managed by [Aiven](https://aiven.io/docs/products/postgresql) as service `valkey-digiges`,
  hosted on [DigitalOcean](https://www.digitalocean.com/) in the *Frankfurt, Germany* (`fra`) region.

- Formbricks also [requires](https://formbricks.com/docs/self-hosting/configuration/file-uploads) an S3-compatible[^5] object storage bucket to store static
  user file uploads. We use a [Tigris](https://www.tigrisdata.com/) bucket named `digiges-forms` attached to our Fly app.

- To cope with higher demand when conducting surveys, we can [increase RAM](https://fly.io/docs/flyctl/scale-memory/) and/or [switch to a faster
  CPU](https://fly.io/docs/flyctl/scale-vm/) as needed[^6]. It's recommended to allocate at least `1024 MB` RAM before running any serious survey.

  We could also scale horizontally, i.e. [run multiple instances](https://fly.io/docs/apps/scale-count/) of Formbricks, even [in multiple
  regions](https://fly.io/docs/launch/scale-count/#scale-an-apps-regions).

[^4]: Especially the first start after a new deployment turned out to be memory-intensive (probably the Prisma Client performing the DB migrations): With
    256 MiB RAM, the app used to crash reproducibly, so we increased this to 512 MiB.

[^5]: Note that we can't use [Backblaze B2](https://www.backblaze.com/cloud-storage) since its S3-compatible API doesn't implement the [POST
    Object](https://docs.aws.amazon.com/AmazonS3/latest/API/RESTObjectPOST.html) operation that Formbricks uses to upload files.

[^6]: Note that scaling automatically restarts the app. The most relevant documentation on (auto)scaling Fly apps includes:

    - [Scale Machine CPU and RAM](https://fly.io/docs/apps/scale-machine/)
    - [Scale the Number of Machines](https://fly.io/docs/apps/scale-count/)
    - [Automatically Stop and Start Machines](https://fly.io/docs/apps/autostart-stop/)

## Admin access

We can directly connect to the `digiges-forms` app via an [SSH tunnel](https://fly.io/docs/flyctl/ssh-console/) to perform any low-level administration tasks.
To do so, run:

``` sh
flyctl ssh console --app digiges-forms
```

## Deploy new Formbricks release

To deploy a new `digiges-forms` release on Fly, follow these steps:

1.  Create a local snapshot of the database, see [below](#back-up-postgresql-db).

2.  Set the desired [`ghcr.io/formbricks/formbricks` tag](https://github.com/formbricks/formbricks/pkgs/container/formbricks) in the [`Dockerfile`](Dockerfile).

3.  Update the Formbricks configuration in [`fly.toml`](fly.toml)'s `[env]` section and -- for sensitive information -- in the app's [Fly
    secrets](https://fly.io/docs/reference/secrets/) if necessary.

    Documentation of all the environment variables Formbricks supports for configuration should be found [in the
    docs](https://formbricks.com/docs/self-hosting/configuration/environment-variables). If something is missing, the following resources should help:

    - [File `turbo.json`](https://github.com/formbricks/formbricks/blame/4.0.1/turbo.json#L113-L220) lists all supported env vars without further info. Use
      [GitHub's compare
      view](https://docs.github.com/en/pull-requests/committing-changes-to-your-project/viewing-and-comparing-commits/comparing-commits#comparing-tags) to
      compare the desired formbricks release tag with the one that is currently deployed. To e.g. show the diffs between version 4.0.0 and 4.0.1, use
      <https://github.com/formbricks/formbricks/compare/4.0.0...4.0.1#files_bucket>.
    - [File `.env.example`](https://github.com/formbricks/formbricks/blob/main/.env.example) contains example configuration.

4.  Build and deploy the image:

    ``` sh
    flyctl deploy --ha=false --app digiges-forms
    ```

5.  Consult the [official migration guide](https://formbricks.com/docs/self-hosting/migration-guide). For Formbricks 4.x and above, all database migrations
    should be done automatically without any further action necessary.

## Back up PostgreSQL DB

To create a full dump of the `formbricks` PostgreSQL database, run the following:

``` sh
PGSSLROOTCERT=aiven.io_ca.pem pg_dump \
  --clean \
  --if-exists \
  --format=custom \
  --compress=zstd:9 \
  --no-password \
  --dbname=$(grep -Po "(?<=^DATABASE_URL=').+(?='$)" .secrets) \
  --file=backups/formbricks.$(date --iso-8601=seconds).dump
```

(You need the Git-ignored `.secrets` file for the above to work.)

## Restore PostgreSQL DB

To restore a full dump of the `formbricks` PostgreSQL database, run the following:

``` sh
PGSSLROOTCERT=aiven.io_ca.pem pg_restore \
  --clean \
  --if-exists \
  --single-transaction \
  --no-owner \
  --no-acl \
  --no-password \
  --dbname=$(grep -Po "(?<=^DATABASE_URL=').+(?='$)" .secrets) \
  backups/formbricks.2025-10-03T16:58:10+02:00.dump
```

(You need the Git-ignored `.secrets` file for the above to work or change the `--dbname=` value to restore to a different DB location.)

## License

Code and configuration in this repository are licensed under [`AGPL-3.0-or-later`](https://spdx.org/licenses/AGPL-3.0-or-later.html). See
[LICENSE.md](LICENSE.md).
