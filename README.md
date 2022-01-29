# install-swift

This action allows installing Swift toolchains, with support for both release and development versions.

## Usage

### Inputs

- `version` - The Swift version you want to install. This may either be a release version like `5.5`, or a development
snapshot like `swift-DEVELOPMENT-SNAPSHOT-2021-11-12-a`.

### Example

```yaml
- name: Install Swift
  uses: slashmo/install-swift@v0.1.0
  with:
    version: 5.5
```

After adding this step, all following steps in this job will automatically use the newly installed Swift version:

```yaml
- name: Run Tests
  run: swift test # <-- uses Swift 5.5
```

### Multiple Swift Versions

In case you want to run your GitHub Actions workflow using different versions of Swift, define a
[GitHub Action's matrix](https://docs.github.com/en/actions/learn-github-actions/workflow-syntax-for-github-actions#jobsjob_idstrategymatrix)
to spawn multiple instances of the same job:

```yaml
jobs:
  test:
    name: Run Tests
    strategy:
      matrix:
        swift: [5.5, swift-DEVELOPMENT-SNAPSHOT-2021-11-12-a]
        os: [ubuntu-18.04, ubuntu-20.04, macos-latest]
        fail-fast: false
    runs-on: ${{ matrix.os }}
    steps:
    - name: Install Swift
      uses: slashmo/install-swift@v0.1.0
      with:
        version: ${{ matrix.swift }}
    - name: Checkout
      uses: actions/checkout@v2
    - name: Run Tests
      run: swift test
```

The action will automatically detect the Ubuntu version and install the correct toolchain.

### Caching

`install-swift` automatically caches toolchains based on the [version input](#inputs) and the detected Ubuntu version.
