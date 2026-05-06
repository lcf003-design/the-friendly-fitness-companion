import os
from pbxproj import XcodeProject

project_path = "The Friendly Fitness Companion/The Friendly Fitness Companion.xcodeproj/project.pbxproj"
project = XcodeProject.load(project_path)

source_dir = "The Friendly Fitness Companion/The Friendly Fitness Companion"

missing_files = ["HennemanMeterView.swift"]

target = project.get_target_by_name("The Friendly Fitness Companion")

for filename in missing_files:
    file_path = os.path.join(source_dir, filename)
    if os.path.exists(file_path):
        results = project.get_files_by_name(filename)
        if not results:
            print(f"Adding {filename} to project")
            project.add_file(file_path, parent=project.get_or_create_group("The Friendly Fitness Companion"), target_name="The Friendly Fitness Companion")
        else:
            print(f"{filename} is already in the project")

project.save()
print("Project saved.")
