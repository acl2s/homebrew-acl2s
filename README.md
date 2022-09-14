# Mister-walter Acl2s

## How do I install these formulae?

`brew install mister-walter/acl2s/<formula>`

Or `brew tap mister-walter/acl2s` and then `brew install <formula>`.

## Documentation

`brew help`, `man brew` or check [Homebrew's documentation](https://docs.brew.sh).

## Generating bottles

Run the following commands:
```
brew uninstall acl2s
brew install --build-bottle acl2s
brew bottle acl2s
brew uninstall acl2s # if you don't want to keep using the homebrew build of acl2s
brew unlink sbcl # if you don't want to keep using the homebrew build of sbcl
```

The `brew bottle` command will generate a bottle file ending in
`bottle.tar.gz` or `bottle.<n>.tar.gz` for some integer n, and it will
also print out a `bottle do` block. This block should be added to the
recipe after a bottle has been generated for each OS/architecture
desired. A release should also be created on GitHub, where all of the
bottles should be uploaded. A `root_url` entry should be added in the
`bottle do` block that points to the GitHub release. See https://github.com/mister-walter/homebrew-acl2s/commit/0e07ff1fbceaef42a1a68e027ec185584885c48b
for an example of what the final block should look like.
