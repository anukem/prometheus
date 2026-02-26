import CoreText
import Foundation

enum FontLoader {
    private final class BundleMarker {}

    static func registerFonts() {
        let fonts = [
            "IBMPlexSerif-Light",
            "IBMPlexSerif-LightItalic",
            "IBMPlexSerif-Regular",
            "IBMPlexSerif-Italic",
            "IBMPlexSerif-SemiBold",
            "IBMPlexSerif-SemiBoldItalic",
        ]
        for name in fonts {
            guard let url = fontURL(named: name) else {
                print("FontLoader: missing \(name).ttf")
                continue
            }
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }

    private static func fontURL(named name: String) -> URL? {
        let filename = "\(name).ttf"
        for directory in fontSearchDirectories() {
            let candidate = directory.appendingPathComponent(filename)
            if FileManager.default.fileExists(atPath: candidate.path) {
                return candidate
            }
        }
        return nil
    }

    private static func fontSearchDirectories() -> [URL] {
        var directories: [URL] = []

        if let resourceURL = Bundle.main.resourceURL {
            directories.append(resourceURL)
            directories.append(resourceURL.appendingPathComponent("Fonts", isDirectory: true))
            directories.append(resourceURL.appendingPathComponent("Parchment_Parchment.bundle", isDirectory: true))
            directories.append(resourceURL.appendingPathComponent("Parchment_Parchment.bundle/Fonts", isDirectory: true))
        }

        if let markerResourceURL = Bundle(for: BundleMarker.self).resourceURL {
            directories.append(markerResourceURL)
            directories.append(markerResourceURL.appendingPathComponent("Fonts", isDirectory: true))
        }

        for bundle in Bundle.allBundles + Bundle.allFrameworks {
            guard let resourceURL = bundle.resourceURL else { continue }
            directories.append(resourceURL)
            directories.append(resourceURL.appendingPathComponent("Fonts", isDirectory: true))
        }

        return directories
    }
}
