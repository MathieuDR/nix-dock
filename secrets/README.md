# Secrets

We have 2 different type of *sensitive* information.

1. Secrets
2. PII

The secrets are encrypted through [agenix](agenix) whilst the PII is encrypted on git using [git-agecrypt](git-agecrypt).

The main difference is that agenix encrypts these secrets (tokens, passwords etc) and puts these in the `/nix/store` of the server. During the activation these will be decrypted.

The git-agecrypt decrypts this on our local machine and have these secrets available during evaluation and thus will end up in the `/nix/store` directory.

It is important that we make sure that no actual passwords or secrets ends up in [PII.json](./PII.json).

## How to create secrets

**Creating the secret**
Edit a secret `agenix -e 'name'`, example: `agenix -e restic/password.age`
*Note:* To specify the SSH key to use, use the `-i` argument, to specify the **identity**. `agenix -e restic/password.age -i ~/.shh/id_rsa`.

Add them to `secrets/secrets.nix` and add the public key of the used private key.

**Using the secret in the nix configuration**

In the root add the following values
```
age.secrets = {
    "name".file = <path_to_age_file>;
};
```

Which then can be used somewhere else with the following line `config.age.secrets."name".path;`

## How to add a PII file
Follow the [git-agecrypt](git-agecrypt) git instructions.

## Current PII information
If you want to use my configuration, and want to recreate the `PII.json` file. These are the keys.

```
caddyEmail
domain
email
git
git.userEmail
glance
glance.linear
host
location
location.city
location.country
location.lat
location.long
user
```

Created with the following command `jq -r 'paths | join(".")' file.json | sort | uniq`.
## Notes
Finding the public key: `ssh-keyscan <IP>`

[age]: https://github.com/FiloSottile/age
[agenix]: https://github.com/ryantm/agenix
[git-agecrypt]: https://github.com/vlaci/git-agecrypt
