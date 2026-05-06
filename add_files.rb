require 'xcodeproj'

project_path = 'The Friendly Fitness Companion/The Friendly Fitness Companion.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.first

source_dir = 'The Friendly Fitness Companion/The Friendly Fitness Companion'
group = project.main_group.find_subpath('The Friendly Fitness Companion', true)

# Find all swift files
Dir.glob("#{source_dir}/*.swift").each do |file|
  filename = File.basename(file)
  
  # Check if file is already in the project
  file_ref = group.files.find { |f| f.path == filename || f.name == filename }
  
  if file_ref.nil?
    puts "Adding #{filename} to project"
    file_ref = group.new_file(filename)
  end
  
  # Check if file is in the target's build phases
  build_phase = target.source_build_phase
  unless build_phase.files_references.include?(file_ref)
    puts "Adding #{filename} to target build phase"
    build_phase.add_file_reference(file_ref)
  end
end

project.save
puts "Project saved."
