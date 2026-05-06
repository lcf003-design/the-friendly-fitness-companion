require 'xcodeproj'

project_path = 'The Friendly Fitness Companion/The Friendly Fitness Companion.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.first

entitlements_path = 'The Friendly Fitness Companion.entitlements'

# Add the entitlement key to build settings
target.build_configurations.each do |config|
  config.build_settings['CODE_SIGN_ENTITLEMENTS'] = entitlements_path
end

project.save
puts "Project saved with Entitlements."
