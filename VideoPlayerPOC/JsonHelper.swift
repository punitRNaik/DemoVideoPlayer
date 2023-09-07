//
//  JsonHelper.swift
//  VideoPlayerPOC
//
//  Created by PunitNaik on 05/09/23.
//

import Foundation

class JSONLoader {
    static func loadVideoPlayerViewModel(fromJSONFile jsonFileName: String) -> VideoPlayerViewModel? {
        guard let jsonFileURL = Bundle.main.url(forResource: jsonFileName, withExtension: "json") else {
            return nil
        }
        
        do {
            let jsonData = try Data(contentsOf: jsonFileURL)
            let decoder = JSONDecoder()
            let decodedData = try decoder.decode(VideoPlayerData.self, from: jsonData)
            
            let videoURL = URL(string: decodedData.bookURL)!
            let pages = decodedData.pages.map {
                PageData(pageIndex: $0.pageIndex,
                         startTime: $0.startTime,
                         endTime: $0.endTime)
            }
            
            return VideoPlayerViewModel(videoURL: videoURL, pages: pages)
        } catch {
            print("Error decoding JSON: \(error)")
            return nil
        }
    }
}
