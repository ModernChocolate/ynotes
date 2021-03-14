fastlane documentation
================
# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```
xcode-select --install
```

Install _fastlane_ using
```
[sudo] gem install fastlane -NV
```
or alternatively using `brew install fastlane`

# Available Actions
### beta
```
fastlane beta
```

### githubrelease
```
fastlane githubrelease
```

### local_test
```
fastlane local_test
```


----

## Android
### android gh_actions_beta_release
```
fastlane android gh_actions_beta_release
```
Deploy to closed beta track

----

## android_prod_promote
### android_prod_promote gh_actions_beta_release
```
fastlane android_prod_promote gh_actions_beta_release
```
Promote to prod track

----

This README.md is auto-generated and will be re-generated every time [fastlane](https://fastlane.tools) is run.
More information about fastlane can be found on [fastlane.tools](https://fastlane.tools).
The documentation of fastlane can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
