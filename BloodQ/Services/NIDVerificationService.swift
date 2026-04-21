//
//  NIDVerificationService.swift
//  BloodQ
//
//

import Foundation
import UIKit

class NIDVerificationService {
    static let shared = NIDVerificationService()
    
    private let apiKey = "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"
    private let apiURL = "https://openrouter.ai/api/v1/chat/completions"
    
    struct NIDData: Codable {
        var isValid: Bool
        var nidNumber: String?
        var name: String?
        var dateOfBirth: String?
        var confidence: Double
        var errorMessage: String?
    }
    
    // Verify NID
    func verifyNID(frontImage: UIImage, backImage: UIImage, completion: @escaping (Result<NIDData, Error>) -> Void) {
        
        guard let frontBase64 = convertImageToBase64(image: frontImage),
              let backBase64 = convertImageToBase64(image: backImage) else {
            completion(.failure(NSError(domain: "NIDVerification", code: -1, 
                                       userInfo: [NSLocalizedDescriptionKey: "Failed to process images"])))
            return
        }
        
        let prompt = """
        You are a National ID card verification system. Analyze the provided front and back images of a Bangladesh National ID card.
        
        Your task:
        1. Verify if both images appear to be authentic Bangladesh NID cards
        2. Check for obvious signs of tampering or fake documents
        3. Extract the following information from the FRONT side:
           - NID Number
           - Full Name (in English)
           - Date of Birth
        
        Respond ONLY with a valid JSON object in this exact format:
        {
          "isValid": true/false,
          "nidNumber": "extracted NID number or null",
          "name": "extracted name or null",
          "dateOfBirth": "YYYY-MM-DD or null",
          "confidence": 0.0 to 1.0,
          "errorMessage": "reason if invalid, otherwise null"
        }
        
        Criteria for validity:
        - Both images must clearly show a Bangladesh NID card
        - Text must be readable and properly formatted
        - No obvious signs of photo manipulation
        - Card structure matches official format
        
        If the images don't meet these criteria, set isValid to false and provide a clear errorMessage.
        """
        
        let messages: [[String: Any]] = [
            [
                "role": "user",
                "content": [
                    ["type": "text", "text": prompt],
                    ["type": "image_url", "image_url": ["url": "data:image/jpeg;base64,\(frontBase64)"]],
                    ["type": "image_url", "image_url": ["url": "data:image/jpeg;base64,\(backBase64)"]]
                ]
            ]
        ]
        
        let requestBody: [String: Any] = [
            "model": "nvidia/nemotron-nano-12b-v2-vl:free",
            "messages": messages,
            "temperature": 0.1,
            "max_tokens": 1000
        ]
        
        guard let url = URL(string: apiURL) else {
            completion(.failure(NSError(domain: "NIDVerification", code: -1,
                                       userInfo: [NSLocalizedDescriptionKey: "Invalid API URL"])))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "NIDVerification", code: -1,
                                           userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let choices = json["choices"] as? [[String: Any]],
                   let firstChoice = choices.first,
                   let message = firstChoice["message"] as? [String: Any],
                   let content = message["content"] as? String {
                    
                    // Parse the JSON response from Gemini
                    let cleanedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
                        .replacingOccurrences(of: "```json", with: "")
                        .replacingOccurrences(of: "```", with: "")
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    if let jsonData = cleanedContent.data(using: .utf8) {
                        let nidData = try JSONDecoder().decode(NIDData.self, from: jsonData)
                        completion(.success(nidData))
                    } else {
                        completion(.failure(NSError(domain: "NIDVerification", code: -1,
                                                   userInfo: [NSLocalizedDescriptionKey: "Failed to parse response"])))
                    }
                } else {
                    completion(.failure(NSError(domain: "NIDVerification", code: -1,
                                               userInfo: [NSLocalizedDescriptionKey: "Invalid API response"])))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    // Helper Methods
    private func convertImageToBase64(image: UIImage) -> String? {
        // Resize image to reduce size
        let maxSize: CGFloat = 1024
        let size = image.size
        let ratio = min(maxSize / size.width, maxSize / size.height)
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        guard let resized = resizedImage,
              let imageData = resized.jpegData(compressionQuality: 0.8) else {
            return nil
        }
        
        return imageData.base64EncodedString()
    }
}
