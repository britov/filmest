#!/bin/sh

echo "flutter clean"
flutter clean


echo "Build our app like usual"
flutter -v build apk --release

### BEGIN MODIFICATIONS

echo "Copy mergeJniLibs to debugSymbols"
cp -R ./build/app/intermediates/transforms/mergeJniLibs/release/0/lib debugSymbols

echo "The libflutter.so here is the same as in the artifacts.zip found with symbols.zip"
cd debugSymbols/armeabi-v7a

echo "Download the corresponding libflutter.so with debug symbols"
ENGINE_VERSION=`cat /Users/mb/development/flutter/bin/internal/engine.version`
gsutil cp gs://flutter_infra/flutter/${ENGINE_VERSION}/android-arm-release/symbols.zip .

echo "Replace libflutter.so"
unzip -o symbols.zip
rm -rf symbols.zip

echo "Upload symbols to Crashlytics"
cd ../../android
./gradlew crashlyticsUploadSymbolsRelease

echo "flutter build"
cd ../
flutter build apk