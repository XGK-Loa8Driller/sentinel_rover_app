# iOS Configuration

Add these to your `ios/Runner/Info.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- Existing keys... -->
    
    <!-- Google Maps API Key -->
    <key>GMSApiKey</key>
    <string>YOUR_GOOGLE_MAPS_API_KEY_HERE</string>
    
    <!-- Location Permissions -->
    <key>NSLocationWhenInUseUsageDescription</key>
    <string>We need your location to track the rover and show threats on the map</string>
    
    <key>NSLocationAlwaysUsageDescription</key>
    <string>We need your location to track the rover continuously</string>
    
    <key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
    <string>We need your location to track the rover and show threats on the map</string>
    
    <!-- Bluetooth Permissions -->
    <key>NSBluetoothAlwaysUsageDescription</key>
    <string>We need Bluetooth to connect directly to your Sentinel Rover</string>
    
    <key>NSBluetoothPeripheralUsageDescription</key>
    <string>We need Bluetooth to connect directly to your Sentinel Rover</string>
    
    <!-- Camera Permission -->
    <key>NSCameraUsageDescription</key>
    <string>We need camera access to display the rover's live feed</string>
    
    <!-- Photo Library (if needed) -->
    <key>NSPhotoLibraryUsageDescription</key>
    <string>We need access to save photos from the rover camera</string>
    
</dict>
</plist>
```

## Update Podfile

In `ios/Podfile`, add:

```ruby
platform :ios, '13.0'

target 'Runner' do
  use_frameworks!
  use_modular_headers!

  flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))
  
  # Google Maps
  pod 'GoogleMaps'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
    end
  end
end
```

## Install Pods

```bash
cd ios
pod install
cd ..
```

## Get Google Maps API Key

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project
3. Enable "Maps SDK for iOS"
4. Create API credentials
5. Copy your API key
6. Replace `YOUR_GOOGLE_MAPS_API_KEY_HERE` above

## Background Modes (Optional)

If you want location updates in background, add to Info.plist:

```xml
<key>UIBackgroundModes</key>
<array>
    <string>location</string>
    <string>bluetooth-central</string>
</array>
```
