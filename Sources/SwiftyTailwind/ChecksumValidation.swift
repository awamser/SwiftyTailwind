import Foundation
import TSCBasic

protocol ChecksumValidating {
    func generateChecksumFrom(_ filePath: AbsolutePath) throws -> String
    func compareChecksum(from filePath: AbsolutePath, to checksum: String) throws -> Bool
}

struct ChecksumValidation: ChecksumValidating {
    func generateChecksumFrom(_ filePath: AbsolutePath) throws -> String {
        let checksumGenerationTask = Process()
        checksumGenerationTask.launchPath = "/usr/bin/shasum"
        checksumGenerationTask.arguments = ["-a", "256", filePath.pathString]
        
        let pipe = Pipe()
        checksumGenerationTask.standardOutput = pipe
        checksumGenerationTask.launch()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: data, encoding: String.Encoding.utf8) else {
            throw DownloaderError.errorReadingFilesForChecksumValidation
        }
        
        return output
    }
    
    func compareChecksum(from filePath: AbsolutePath, to checksum: String) throws -> Bool {
        let checksumFileContent = try String(contentsOf: filePath.asURL)
        let lines = checksumFileContent.components(separatedBy: .newlines)
        
        // Extract just the checksum part (first 64 characters before any whitespace)
        let providedChecksum = checksum.trimmingCharacters(in: .whitespacesAndNewlines)
        let actualChecksum = String(providedChecksum.prefix(64))
        
        // Look for matching checksum in the sha256sums.txt file
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.hasPrefix(actualChecksum) {
                return true
            }
        }
        
        return false
    }
}
