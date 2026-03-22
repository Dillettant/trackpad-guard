cask "trackpad-guard" do
  version "1.0.0"
  sha256 "2d33b082bad984b441209c1277c62c55eda1fcd1ad5d7eecc0e8d8d83b340335"

  url "https://github.com/Dillettant/trackpad-guard/releases/download/v#{version}/TrackpadGuard-#{version}.dmg"
  name "TrackpadGuard"
  desc "Automatically disable trackpad while typing on macOS"
  homepage "https://github.com/Dillettant/trackpad-guard"

  depends_on macos: ">= :ventura"

  app "TrackpadGuard.app"

  postflight do
    ohai "Grant Accessibility permission:"
    ohai "System Settings → Privacy & Security → Accessibility → enable TrackpadGuard"
  end

  uninstall quit: "com.dillettant.trackpad-guard"

  zap trash: [
    "~/Library/Preferences/com.dillettant.trackpad-guard.plist",
  ]
end
