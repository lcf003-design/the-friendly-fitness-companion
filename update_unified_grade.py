import re

path = "The Friendly Fitness Companion/The Friendly Fitness Companion/FoodActionSheetView.swift"
with open(path, "r") as f:
    content = f.read()

content = content.replace(
    "var servingSize: String? = \"1 serving (100g)\"\n}", 
    "var servingSize: String? = \"1 serving (100g)\"\n    var grade: String? = nil\n    var imageUrl: String? = nil\n}"
)
with open(path, "w") as f:
    f.write(content)

path2 = "The Friendly Fitness Companion/The Friendly Fitness Companion/ManageMyFoodsView.swift"
with open(path2, "r") as f:
    content2 = f.read()

content2 = content2.replace(
    "servingSize: result.servingSize)",
    "servingSize: result.servingSize, grade: result.grade, imageUrl: result.imageUrl)"
)
with open(path2, "w") as f:
    f.write(content2)

path3 = "The Friendly Fitness Companion/The Friendly Fitness Companion/FoodLoggerModal.swift"
with open(path3, "r") as f:
    content3 = f.read()

content3 = content3.replace(
    "servingSize: result.servingSize\n",
    "servingSize: result.servingSize,\n                                                grade: result.grade,\n                                                imageUrl: result.imageUrl\n"
)
with open(path3, "w") as f:
    f.write(content3)

