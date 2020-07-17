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
or alternatively using `brew cask install fastlane`

# Available Actions
## Android
### android build
```
fastlane android build
```

### android deploy_production
```
fastlane android deploy_production
```

### android deploy_beta
```
fastlane android deploy_beta
```

### android deploy_alpha
```
fastlane android deploy_alpha
```

### android deploy_internal
```
fastlane android deploy_internal
```


----

## iOS
### ios build
```
fastlane ios build
```

### ios deploy_to_testflight
```
fastlane ios deploy_to_testflight
```

### ios deploy_to_app_store
```
fastlane ios deploy_to_app_store
```


----

This README.md is auto-generated and will be re-generated every time [fastlane](https://fastlane.tools) is run.
More information about fastlane can be found on [fastlane.tools](https://fastlane.tools).
The documentation of fastlane can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
