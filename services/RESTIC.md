# Restic Backup Service
## Overview

Restic is used to create and manage backups of our critical data to a Backblaze B2 bucket. This setup ensures that our data is securely stored off-site and can be easily restored if needed.

[Inspiration](https://www.arthurkoziel.com/restic-backups-b2-nixos/)

## Backblaze B2 Setup

1. Authorize your account `backblaze-b2 authorize-account`.

2. Create B2 bucket
`backblaze-b2 create_bucket nixserver-hetzner-bucket allPrivate --default-server-side-encryption=SSE-B2 --lifecycle-rules='[{"daysFromHidingToDeleting": 30, "daysFromUploadingToHiding": null, "fileNamePrefix": ""}]'`
    - allPrivate: Visabilty
    - defaultServerSideEncryption: Encryption, optional since restic encrypts data already too.
    - lifeCycleRules: Delete old, overwritten files. Backblaze keeps these files indefinitely but Restic takes care of this for us.

3. Create Bucket key `backblaze-b2 create-key --bucket nixserver-hetzner-bucket nixserver-hetzner-key "deleteFiles, listAllBucketNames, listBuckets, listFiles, readBucketEncryption, readBucketReplications, readBuckets, readFiles, shareFiles, writeBucketEncryption, writeBucketReplications, writeFiles"`

## Restic Configuration

1. Create Restic password file `restic/password`
    This password is the restic password that will encrypt and decrypt the backed up files.
2. Create environment secret file `restic/env`
    We put our B2 info in here: `B2_ACCOUNT_ID` & `B2_ACCOUNT_KEY`. We got them from create the bucket application key.
3. Create Repository secret file `restic/repository`
    This file contains the destination of our restic repository. In our case it would be `b2:nixserver-hetzner-bucket`

## Usage

In the services add the paths to be backed up under `services.restic.backups.b2.paths`.
