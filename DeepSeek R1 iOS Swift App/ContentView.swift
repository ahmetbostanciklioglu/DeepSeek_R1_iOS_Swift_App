//
//  ContentView.swift
//  DeepSeek R1 iOS Swift App
//
//  Created by Ahmet Bostancıklıoğlu on 31.01.2025.
//

import SwiftUI

import AIProxy

let togetherAIService = AIProxy.togetherAIService(
    partialKey: "v2|829ebe1b|93N4l6FLPMy3sQS4",
    serviceURL: "https://api.aiproxy.pro/2b91580c/032fdfed"
)

struct ContentView: View {
    
    @State private var streamedResponse = ""
    @State private var isLoading = false
    
    
    var body: some View {
        VStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    //User prompt text
                    Text("What are some fun things to do in New York?")
                        .padding()
                        .background()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                    
                    //Check for assistant prompt text
                    if !streamedResponse.isEmpty || isLoading {
                        Text(streamedResponse)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)
                    }
                }
                .padding()
            }
            //if assistant prompt isLoading shows ProgressView
            if isLoading {
                ProgressView()
                    .padding()
            }
        }
        .task {
            //streamResponse function
            await streamResponse()
        }
    }
    
    private func streamResponse() async {
        isLoading = true
        
        do {
            // The request is sent to backend
            let requestBody = TogetherAIChatCompletionRequestBody(
                messages: [
                    TogetherAIMessage(content: "What are some fun things to do in New York?",
                                      role: .user)
                ],
                model: "deepseek-ai/DeepSeek-R1")
            
            //Request body go to togetherAIService
            let stream = try await togetherAIService.streamingChatCompletionRequest(body: requestBody)
            
            for try await chunk in stream {
                if let content = chunk.choices.first?.delta.content {
                    // Update the UI with the new content
                    await MainActor.run {
                        streamedResponse += content
                    }
                }
            }
            
        } catch AIProxyError.unsuccessfulRequest(let statusCode, let responseBody){
            print("Received \(statusCode) status code with response body: \(responseBody)")
            
            await MainActor.run {
                streamedResponse = "Error: Failed to get response from the server."
            }
        } catch {
            print("Could not create TogetherAI streaming chat completion: \(error.localizedDescription)")
            
            await MainActor.run {
                streamedResponse = "Error: \(error.localizedDescription)"
            }
        }
        
        await MainActor.run {
            isLoading = false
        }
    }
    
}



#Preview {
    ContentView()
}
