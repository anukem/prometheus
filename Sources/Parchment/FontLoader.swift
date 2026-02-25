import CoreText
import Foundation

enum FontLoader {
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
            guard let url = Bundle.module.url(forResource: name, withExtension: "ttf") else {
                print("FontLoader: missing \(name).ttf")
                continue
            }
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }
}
