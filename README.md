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

- The Fly [app](https://fly.io/docs/reference/apps/) is named `digiges-forms` and has a [persistent storage volume](https://fly.io/docs/reference/volumes/) of
  1 GiB size[^4] attached to it named `digiges_forms` with unique ID `vol_450wzml259mdx1xr`. It currently runs on a single [`shared-cpu-1x` instance with
  `512 MB` RAM](https://fly.io/docs/about/pricing/#compute)[^5] and is hosted in the *Frankfurt, Germany* (`fra`)
  [region](https://fly.io/docs/reference/regions/).
- The `digiges-forms` app connects to the PostgreSQL database `formbricks` on our [Neon.tech](https://neon.tech/docs/introduction/about) account.
- Should it prove necessary to expand performance for our main users (located in Switzerland), we could [increase RAM](https://fly.io/docs/flyctl/scale-memory/)
  and/or [switch to a faster CPU](https://fly.io/docs/flyctl/scale-vm/) anytime[^6].
- Should we also want to provide fast access for non-European users, we could [run multiple instances](https://fly.io/docs/apps/scale-count/) of Formbricks [in
  multiple regions](https://fly.io/docs/apps/scale-count/#scale-an-app-s-regions).

[^4]: The volume size can always be [extended](https://fly.io/docs/flyctl/volumes-extend/). To extend it to 5 GiB for example, simply run:

    ``` sh
    flyctl volumes extend vol_450wzml259mdx1xr --size=5
    ```

    Note that this will restart the app.

[^5]: Especially the first start after a new deployment turned out to be memory-intensive (probably the Prisma Client performing the DB migrations): With
    256 MiB RAM, the app used to crash reproducibly, so we increased this to 512 MiB.

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

2.  Set the desired [`ghcr.io/formbricks/formbricks` tag](https://github.com/formbricks/formbricks/pkgs/container/formbricks) in [`fly.toml`](fly.toml)'s
    `build.image` key.

3.  Update the Formbricks configuration in [`fly.toml`](fly.toml)'s `[env]` section and -- for sensitive information -- in the app's [Fly
    secrets](https://fly.io/docs/reference/secrets/) if necessary.

    Documentation of all the environment variables Formbricks supports for configuration should be found [in the
    docs](https://formbricks.com/docs/self-hosting/configuration/environment-variables). If something is missing, the following resources should help:

    - [File `formbricks/turbo.json`](https://github.com/formbricks/formbricks/blame/v3.8.6/turbo.json#L92-L209) lists all supported env vars without further
      info. Use [GitHub's compare
      view](https://docs.github.com/en/pull-requests/committing-changes-to-your-project/viewing-and-comparing-commits/comparing-commits#comparing-tags) to
      compare the desired formbricks release tag with the one that is currently deployed. To e.g. show the diffs between v3.0.0 and v3.1.0, use
      <https://github.com/formbricks/formbricks/compare/v3.0.0...v3.1.0#files_bucket>.
    - [File `.env.example`](https://github.com/formbricks/formbricks/blob/main/.env.example) contains example configuration.

4.  Build and deploy the image:

    ``` sh
    flyctl deploy --ha=false
    ```

5.  Consult the [official migration guide](https://formbricks.com/docs/self-hosting/migration-guide). For Formbricks 4.x and above, all database migrations
    should be done automatically without any further necessary.

## Back up PostgreSQL DB

To create a full dump of the `formbricks` PostgreSQL database, run the following:

``` share
pg_dump --clean \
        --if-exists \
        --format=custom \
        --compress=zstd:9 \
        --no-password \
        --dbname=$(grep -Po "(?<=^DATABASE_URL=').+(?='$)" .secrets) \
        --file=backups/formbricks.$(date --iso-8601=seconds).dump
```

(You need the Git-ignored `.secrets` file for the above to work.)

## License

Code and configuration in this repository are licensed under [`AGPL-3.0-or-later`](https://spdx.org/licenses/AGPL-3.0-or-later.html). See
[LICENSE.md](LICENSE.md).
