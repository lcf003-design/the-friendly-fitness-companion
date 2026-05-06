require 'xcodeproj'

project_path = 'The Friendly Fitness Companion/The Friendly Fitness Companion.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.first

target.build_configurations.each do |config|
  config.build_settings['INFOPLIST_KEY_NSHealthShareUsageDescription'] = "The Friendly Fitness Companion uses HealthKit to sync your body measurements and metabolic data."
  config.build_settings['INFOPLIST_KEY_NSHealthUpdateUsageDescription'] = "The Friendly Fitness Companion uses HealthKit to save your workouts and nutrition to Apple Health."
end

project.save
puts "Project saved with HealthKit Info.plist keys."
