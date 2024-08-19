# Homebrew Formula for ACL2s

## How do I install these formulae?

`brew install acl2s/acl2s/acl2s`

Or `brew tap acl2s/acl2s` and then `brew install acl2s`.

## Documentation

`brew help`, `man brew` or check [Homebrew's documentation](https://docs.brew.sh).

## Testing Locally

To test the formula locally, one can use the `test-docker/build.sh`
script. If the build fails and you'd like to debug it, you can use
`test-docker/debug.sh` which should work on a fairly modern version of
Docker/BuildKit. `debug.sh` should drop you into a Bash shell if the
build fails for any reason, so you can explore any log files to try
and understand the failure.

## Generating bottles

Run the following commands:
```
brew update
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
`bottle do` block that points to the GitHub release. See https://github.com/acl2s/homebrew-acl2s/commit/0e07ff1fbceaef42a1a68e027ec185584885c48b
for an example of what the final block should look like.
