import os
import xml.etree.ElementTree as ET
ANDROID_NAMESPACE = "{http://schemas.android.com/apk/res/android}"
def convert_vector_to_svg(input_xml, output_svg):
    tree = ET.parse(input_xml)
    root = tree.getroot()

    # 创建 SVG 根元素
    svg_root = ET.Element("svg", xmlns="http://www.w3.org/2000/svg")

      # 设置 SVG 的基本属性，并处理 None 值
    svg_root.set("width", root.attrib.get(ANDROID_NAMESPACE +"width", "24dp") or "24dp")
    svg_root.set("height", root.attrib.get(ANDROID_NAMESPACE +"height", "24dp") or "24dp")
    viewport_width = root.attrib.get(ANDROID_NAMESPACE +"viewportWidth", "24") or "24"
    viewport_height = root.attrib.get(ANDROID_NAMESPACE +"viewportHeight", "24") or "24"
    svg_root.set("viewBox", f"0 0 {viewport_width} {viewport_height}")

    # 遍历 VectorDrawable 的 path 节点并转换为 SVG 的 path 节点
    for child in root:
        if child.tag == "path":
            svg_path = ET.Element("path")
            
            # 处理 fillColor 和 pathData 的 None 值
            fill_color = "#fff"
            path_data = child.attrib.get(ANDROID_NAMESPACE + "pathData") or ""

            svg_path.set("fill", fill_color)
            svg_path.set("d", path_data)
            svg_root.append(svg_path)

    # 保存为 SVG 文件
    tree = ET.ElementTree(svg_root)
    with open(output_svg, 'wb') as f:
        tree.write(f)
   

def batch_convert(input_folder, output_folder):
    if not os.path.exists(output_folder):
        os.makedirs(output_folder)

    for filename in os.listdir(input_folder):
        if filename.endswith(".xml"):
            input_path = input_folder +  filename
            output_path = output_folder + filename.replace(".xml", ".svg")
            print("convert_vector_to_svg ", input_path, output_path)
            print("")
            convert_vector_to_svg(input_path, output_path)
            print(f"Converted {filename} to SVG.")

if __name__ == "__main__":
    input_folder = "G:/git/ClashMetaForAndroid/design/src/main/res/drawable/"  # 替换为你的输入XML文件夹路径
    output_folder = "G:/git/ClashForHarmonyOS/entry/src/main/resources/base/media/icons/"       # 替换为你想要输出SVG文件的文件夹路径
    batch_convert(input_folder, output_folder)