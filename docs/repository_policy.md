# Repository Data Policy

## T0 Rule

T0 customer and vehicle data never enters Git. Repository visibility is not a
control exception: the same rule applies to public and private repositories,
branches, tags, pull requests, releases, Actions artifacts, Git LFS, and
encrypted archives.

## Allowed

- reviewed source code without operational paths, schemas, or credentials;
- generalized documentation;
- approved cohort-level aggregate research metrics;
- synthetic fixtures written from scratch and not derived from real records;
- empty environment-variable examples.

## Prohibited

- raw, sampled, masked, perturbed, or exported customer and vehicle data;
- names, identifiers, addresses, phone numbers, plates, chassis identifiers,
  work orders, service histories, or row-level scores;
- database dumps, spreadsheets, screenshots, console output, and logs;
- fitted models, model frames, preprocessing objects, caches, checkpoints,
  prospective lists, monitoring registries, and explainability output;
- any artifact that can reconstruct an individual, vehicle, service event, or
  small operational segment.

## Required Release Check

Before every commit or push:

1. build an exact staged allowlist;
2. verify ignored T0 directories and extensions remain untracked;
3. scan staged text for credentials, local paths, identifiers, and prohibited
   field names;
4. scan the complete reachable Git history for prohibited artifacts;
5. stop the release if any result is uncertain.
