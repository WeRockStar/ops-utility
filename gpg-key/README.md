# GPG Keys

## Existing Keys

```bash
gpg --list-secret-keys --keyid-format=long
```

## Generate a New Key
To generate a new GPG key, use the following command:

```bash
gpg --full-generate-key
```

## Exporting Keys
To export your public key, use:
```bash
gpg --armor --export <GPG key ID>
```

## Inform Git and Sign Commits

```bash
git config --global user.signingkey <GPG key ID>
```

## Reference
- [Generating a GPG Key](https://docs.github.com/en/authentication/managing-commit-signature-verification/generating-a-new-gpg-key)
- [Signing Commits with GPG](https://docs.github.com/en/authentication/managing-commit-signature-verification/telling-git-about-your-signing-key)
