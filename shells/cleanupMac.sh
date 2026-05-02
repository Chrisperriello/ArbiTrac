flutter clean
flutter pub get
cd macos
rm -rf Pods
rm Podfile.lock
pod install
cd ..
flutter run