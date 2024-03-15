This is a sample for nixpkgs [PR](https://github.com/NixOS/nixpkgs/pull/296134)

Provide your Github username and PAT token with `packages:read` scope to access github nuget feed (even for public packages)
```
nix run github:anpin/nuget-to-nix-with-private-feed#run-nuget-to-nix $GH_USER $GH_PAT
```
