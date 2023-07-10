//
//  ContentView.swift
//  ResumableUploadExample
//
//  Created by Marius Kleidl on 09.07.23.
//

import SwiftUI

func createTestBuffer(sizeInMB: Int) -> Data {
    let bufferSize = sizeInMB * 1024 * 1024 // Convert MB to bytes
    var buffer = Data(count: bufferSize)
    buffer.withUnsafeMutableBytes { rawBufferPointer in
        let pointer = rawBufferPointer.bindMemory(to: UInt8.self)
        let bufferPointer = UnsafeMutableBufferPointer(start: pointer.baseAddress, count: bufferSize)
        let repeatingPattern: UInt8 = 0xFF // You can change the pattern if desired
        bufferPointer.initialize(repeating: repeatingPattern)
    }
    return buffer
}

enum UploadState {
    case notStarted
    case running(URLSession, URLSessionUploadTask)
    case paused(URLSession, Data)
}

struct ContentView: View {
    // The URL of the server endpoint to upload the data
    let UPLOAD_URL = URL(string: "http://192.168.0.136:8080/upload")!
    
    // The data to be uploaded
    let UPLOAD_DATA = createTestBuffer(sizeInMB: 5)
    
    @State var log = ""
    @State var uploadState = UploadState.notStarted
    
    var body: some View {
        VStack() {
            switch uploadState {
            case .notStarted:
                Button("Start Upload", action: startUpload).buttonStyle(.borderedProminent)
            case .running:
                Button("Pause Upload", action: pauseUpload).buttonStyle(.borderedProminent)
            case .paused:
                Button("Resume Upload", action: resumeUpload).buttonStyle(.borderedProminent)
            }
            Text(log)
        }
    }
    
    func startUpload() {
        guard case .notStarted = uploadState else {
            return
        }
        
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)
        
        // Create a URLRequest with the upload URL
        var request = URLRequest(url: UPLOAD_URL)
        request.httpMethod = "POST"
        
        // Create an upload task with the request and data
        let task = session.uploadTask(with: request, from: UPLOAD_DATA) { data, response, error in
            handleUploadTaskResult(data, response, error, session)
        }
        
        // Start the upload task
        task.resume()
        uploadState = .running(session, task)
    }
    
    func pauseUpload() {
        guard case .running(let session, let uploadTask) = uploadState else {
            return
        }
        
        uploadTask.cancel() { result in
            guard let resumeData = result else {
                log("Cancelled, but upload cannot be resumed")
                uploadState = .notStarted
                return
            }
            
            uploadState = .paused(session, resumeData)
        }
    }
    
    func resumeUpload() {
        guard case .paused(let session, let resumeData) = uploadState else {
            return
        }
        
        let newUploadTask = session.uploadTask(withResumeData: resumeData) { data, response, error in
            handleUploadTaskResult(data, response, error, session)
        }
        newUploadTask.resume()

        uploadState = .running(session, newUploadTask)
    }
    
    func handleUploadTaskResult(_ data: Data?, _ response: URLResponse?, _ error: Error?, _ session: URLSession) {
        // Handle the response and error
        
        if let error = error {
            log("Error: \(error.localizedDescription)")
            
            if let urlError = error as? URLError, let resumeData = urlError.uploadTaskResumeData {
                log("\(resumeData)")
                uploadState = .paused(session, resumeData)
            } else {
                uploadState = .notStarted
            }
            
            return
        }
        
        if let httpResponse = response as? HTTPURLResponse {
            log("Status code: \(httpResponse.statusCode)")
        }
        
        if let responseData = data {
            // Handle the response data
            let responseString = String(data: responseData, encoding: .utf8)
            log("Response: \(responseString ?? "")")
        }
        
        uploadState = .notStarted
    }
    
    func log(_ message: String) {
        print(message)
        log += "\(message)\n"
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
