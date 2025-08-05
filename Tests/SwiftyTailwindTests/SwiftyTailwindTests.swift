import XCTest
import TSCBasic
@testable import SwiftyTailwind

final class SwiftyTailwindTests: XCTestCase {
    func test_initialize() async throws {
        try await withTemporaryDirectory(removeTreeOnDeinit: true, { tmpDir in
            // Given
            let subject = SwiftyTailwind(directory: tmpDir)
            
            // When
            try await subject.initialize(directory: tmpDir, options: .full)
            
            // Then
            let tailwindCSSPath = tmpDir.appending(component: "tailwind.css")
            XCTAssertTrue(localFileSystem.exists(tailwindCSSPath))
            
            // Verify the CSS file contains v4 configuration
            let content = String(bytes: try localFileSystem.readFileContents(tailwindCSSPath).contents, encoding: .utf8)
            XCTAssertTrue(content?.contains("@import \"tailwindcss\"") == true)
            XCTAssertTrue(content?.contains("@theme") == true)
        })
    }
    
    func test_run() async throws {
        try await withTemporaryDirectory(removeTreeOnDeinit: true, { tmpDir in
            // Given
            let subject = SwiftyTailwind(directory: tmpDir)
            
            let inputCSSPath = tmpDir.appending(component: "input.css")
            let inputCSSContent = """
            @import "tailwindcss";
            
            @layer components {
              .my-button {
                @apply bg-blue-500 text-white px-4 py-2 rounded;
              }
            }
            """
            let outputCSSPath = tmpDir.appending(component: "output.css")
            
            // Create a simple HTML file to trigger CSS generation
            let htmlPath = tmpDir.appending(component: "index.html")
            let htmlContent = """
            <!DOCTYPE html>
            <html>
            <head><title>Test</title></head>
            <body>
                <div class="bg-blue-500 text-white px-4 py-2 rounded">Test</div>
            </body>
            </html>
            """
            try localFileSystem.writeFileContents(htmlPath, bytes: ByteString(htmlContent.utf8))
            try localFileSystem.writeFileContents(inputCSSPath, bytes: ByteString(inputCSSContent.utf8))
            
            // When
            try await subject.run(input: inputCSSPath, output: outputCSSPath, directory: tmpDir)
            
            // Then
            XCTAssertTrue(localFileSystem.exists(outputCSSPath))
            let content = String(bytes: try localFileSystem.readFileContents(outputCSSPath).contents, encoding: .utf8)
            // Check for some basic CSS output (v4 generates different CSS than v3)
            XCTAssertTrue(content?.isEmpty == false)
        })
    }
}
