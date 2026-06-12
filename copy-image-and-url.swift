import AppKit

guard CommandLine.arguments.count >= 2 else {
    FileHandle.standardError.write("usage: copy-image-and-url <path>\n".data(using: .utf8)!)
    exit(1)
}

let path = CommandLine.arguments[1]
let url = URL(fileURLWithPath: path)

guard let data = try? Data(contentsOf: url) else {
    FileHandle.standardError.write("could not read file at \(path)\n".data(using: .utf8)!)
    exit(1)
}

let pb = NSPasteboard.general
pb.clearContents()
pb.writeObjects([url as NSURL])
if let item = pb.pasteboardItems?.first {
    item.setData(data, forType: .png)
    item.setString(path, forType: .string)
}
