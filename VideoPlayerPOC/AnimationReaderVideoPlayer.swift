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

class VideoPlayerView: UIView {
    private let videoVM: VideoPlayerViewModel
    private var videoURL: URL {
        get {
            return videoVM.videoURL
        }
    }
    private var pages: [PageData] {
        get {
            return videoVM.pages
        }
    }
    
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    private var isPlaying = false
    private var currentPageIndex = 0
    
    private lazy var playPauseButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "play.circle.fill"), for: .normal)
        button.addTarget(self, action: #selector(togglePlayPause), for: .touchUpInside)
        return button
    }()
    
    private lazy var nextPageButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "forward.fill"), for: .normal)
        button.addTarget(self, action: #selector(goToNextPage), for: .touchUpInside)
        return button
    }()
    
    private lazy var prevPageButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "backward.fill"), for: .normal)
        button.addTarget(self, action: #selector(goToPreviousPage), for: .touchUpInside)
        return button
    }()
    
    private lazy var tapGestureRecognizer: UITapGestureRecognizer = {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture))
        return tapGesture
    }()
    
    private lazy var seekBar: UIProgressView = {
        let progressView = UIProgressView(progressViewStyle: .default)
        progressView.tintColor = .red
        return progressView
    }()
    
    init(frame: CGRect, viewModel:  VideoPlayerViewModel) {
        self.videoVM = viewModel
        super.init(frame: frame)
        setupUI()
        setupPlayer()
        addTapGesture()
        updateProgressBar()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .black
        
        addSubview(playPauseButton)
        addSubview(nextPageButton)
        addSubview(prevPageButton)
        addSubview(seekBar)
        
        playPauseButton.translatesAutoresizingMaskIntoConstraints = false
        nextPageButton.translatesAutoresizingMaskIntoConstraints = false
        prevPageButton.translatesAutoresizingMaskIntoConstraints = false
        seekBar.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            playPauseButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            playPauseButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            
            nextPageButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            nextPageButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            
            prevPageButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            prevPageButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            seekBar.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            seekBar.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            seekBar.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -20)
        ])
    }
    
    private func updateProgressBar() {
        player?.addPeriodicTimeObserver(forInterval: CMTime(seconds: 1, preferredTimescale: 1), queue: .main) { [weak self] time in
            guard let self = self else { return }
            
            let currentTime = time.seconds
            print("current time \(currentTime)")
            
            self.seekBar.progress = Float(currentTime / (Double(self.videoVM.pages.last!.endTime) ?? 1))
            
            print("seek bar progress \(Float(currentTime / (Double(self.videoVM.pages.last!.endTime) ?? 1)))")
            
            for (index, pageInfo) in self.videoVM.pages.enumerated() {
                if let starttime = Double(pageInfo.startTime), let endTime = Double(pageInfo.endTime) {
                    if currentTime >= starttime && currentTime <= endTime {
                        self.currentPageIndex = index
                        print("current Index\(index)")
                        break
                    }
                }
            }
        }
    }
    
    private func addTapGesture() {
        addGestureRecognizer(tapGestureRecognizer)
    }
    
    @objc private func handleTapGesture() {
        togglePlayPause()
    }
    
    private func setupPlayer() {
        let asset = AVAsset(url: videoURL)
        let playerItem = AVPlayerItem(asset: asset)
        player = AVPlayer(playerItem: playerItem)
        playerLayer = AVPlayerLayer(player: player)
        playerLayer?.frame = bounds
        playerLayer?.videoGravity = .resize
        layer.addSublayer(playerLayer!)
        NotificationCenter.default.addObserver(self, selector: #selector(playerItemDidPlayToEndTime), name: .AVPlayerItemNewErrorLogEntry, object: nil)
        
        player?.play()
        isPlaying = true
    }
        
    @objc private func togglePlayPause() {
        print("isPlaying\(isPlaying)")
        if isPlaying {
            player?.pause()
            playPauseButton.setImage(UIImage(systemName: "play.circle.fill"), for: .normal)
        } else {
            player?.play()
            playPauseButton.setImage(UIImage(systemName: "pause.circle.fill"), for: .normal)
        }
        isPlaying.toggle()
    }
    
    @objc func playerItemDidPlayToEndTime(_ notification: Notification) {
        if let errorLog = player?.currentItem?.errorLog() {
            for logEntry in errorLog.events {
                print("AVPlayer Error Log: \(logEntry)")
            }
        }
    }
    
    @objc private func goToNextPage() {
        guard currentPageIndex < pages.count - 1 else {
            return
        }
        let nextPageStartTime = pages[currentPageIndex + 1].startTime
        print(nextPageStartTime)
        if let nextPageTime = Double(nextPageStartTime) {
            seekToTime(TimeInterval(nextPageTime))
            currentPageIndex += 1
        }
        
    }
    
    @objc private func goToPreviousPage() {
        guard currentPageIndex > 0 else {
            return
        }
        
        let previousPageStartTime = pages[currentPageIndex - 1].startTime
        print(previousPageStartTime)
        if let prePageTime = Double(previousPageStartTime) {
            seekToTime(TimeInterval(prePageTime))
            currentPageIndex -= 1
        }        
    }
    
    private func seekToTime(_ time: TimeInterval) {
        //        let timeCM = CMTime(seconds: time, preferredTimescale: 600)
        //        print(timeCM)
        //        player?.seek(to: timeCM, toleranceBefore: .zero, toleranceAfter: .zero)
        
        guard let currentTime = self.player?.currentTime() else { return }
        let seekTime10Sec = CMTimeGetSeconds(currentTime).advanced(by: 10)
        let seekTime = CMTime(value: CMTimeValue(seekTime10Sec), timescale: 1)
        self.player?.seek(to: seekTime, completionHandler: { completed in
        })
    }
}
