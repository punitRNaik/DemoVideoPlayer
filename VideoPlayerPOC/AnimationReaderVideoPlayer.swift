//
//  AnimationReaderVideoPlayer.swift
//  VideoPlayerPOC
//
//  Created by PunitNaik on 05/09/23.
//

import UIKit
import AVFoundation

class VideoPlayerViewModel {
    let videoURL: URL
    var pages: [PageData]
    
    init(videoURL: URL, pages: [PageData]) {
        self.videoURL = videoURL
        self.pages = pages
    }
}

