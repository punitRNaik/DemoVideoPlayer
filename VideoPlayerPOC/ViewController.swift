//
//  ViewController.swift
//  VideoPlayerPOC
//
//  Created by PunitNaik on 05/09/23.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
        
    @IBOutlet weak var videoPlayerView: UIView!
    @IBOutlet weak var playPauseButton: UIButton!
    @IBOutlet weak var forwardbutton: UIButton!
    @IBOutlet weak var revindbutton: UIButton!
    @IBOutlet weak var fullScreenButton: UIButton!
    @IBOutlet weak var videoContainer: UIView!
    @IBOutlet weak var bottomViewHolder: UIView!
    @IBOutlet weak var stackView: UIStackView!
    
    @IBOutlet weak var progressView: UIProgressView! {
        didSet {
            self.progressView.progress = 0
        }
    }
    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.register(UINib(nibName: "PageInfoTableViewCell", bundle: nil), forCellReuseIdentifier: "PageInfoTableViewCell")
        }
    }
    
    private var videoURL: URL {
        get {
            guard let videoModel = videoPlayerViewModel else { return URL(fileURLWithPath: "")}
            return videoModel.videoURL
        }
    }
    var pages: [PageData] {
        get {
            guard let videoModel = videoPlayerViewModel else { return []}
            return videoModel.pages
        }
    }
    var videoPlayerViewModel: VideoPlayerViewModel?
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    private var isPlaying = false
    private var currentPageIndex = 0
    private var isFullScreen = false // Flag to track full-screen state
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadData()
    }
  
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        player?.play()
        isPlaying = true
        playPauseButton.setImage(UIImage(systemName: "pause.circle.fill"), for: .normal)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        playerLayer?.frame = videoPlayerView.bounds
    }

    @IBAction func toggleFullScreen(_ sender: UIButton) {
        isFullScreen.toggle() // Toggle the full-screen state
        
        if isFullScreen {
            // Enter full-screen mode
            UIView.animate(withDuration: 0.3) {
                // Expand the video player view to cover the entire screen
                self.stackView.removeArrangedSubview(self.bottomViewHolder)
                self.view.layoutIfNeeded()
            }
        } else {
            // Exit full-screen mode
            UIView.animate(withDuration: 0.3) {
                self.stackView.addArrangedSubview(self.bottomViewHolder)
                self.view.layoutIfNeeded()
            }
        }
    }
    
    @IBAction func togglePlayPause(_ sender: Any) {
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
    
    @IBAction func goToNextPage(_ sender: Any) {

        guard let currentTime = player?.currentTime().seconds.magnitude else {
            return
        }
        updateCurrentPage(currentTime: currentTime)
        currentPageIndex += 1
        print("**********************current index \(currentPageIndex)")

        guard currentPageIndex < pages.count else {
            return
        }
        print("**********************next Index Start index \(pages[currentPageIndex].startTime) next Index end index \(pages[currentPageIndex].endTime)")
        let nextPageStartTime = isPlaying ? pages[currentPageIndex].startTime : pages[currentPageIndex].endTime
        print("**********************jumping to time\(nextPageStartTime)")

        if let nextPageTime = Double(nextPageStartTime) {
            seekToTime(TimeInterval(nextPageTime))
        }
    }
    
    @IBAction func goToPreviousPage(_ sender: Any) {
        
        guard currentPageIndex > 0, let currentTime = player?.currentTime().seconds else {
            return
        }
        updateCurrentPage(currentTime: currentTime)
        currentPageIndex -= 1
        print("**********************current index \(currentPageIndex)")
        guard currentPageIndex > 0 else {
            return
        }
        
        print("**********************next Index Start index \(pages[currentPageIndex].startTime) next Index end index \(pages[currentPageIndex].endTime)")
        let previousPageStartTime = isPlaying ? pages[currentPageIndex].startTime : pages[currentPageIndex].endTime
        print("**********************jumping to time\(previousPageStartTime)")
        print(previousPageStartTime)
        if let prePageTime = Double(previousPageStartTime) {
            seekToTime(TimeInterval(prePageTime), isForward: false)
        }
    }
}



// Implement UITableViewDataSource and UITableViewDelegate for your UITableView
extension ViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return videoPlayerViewModel?.pages.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Implement your UITableViewCell here, including the UILabel and two editable text fields for start and end times.
        // You will also need to populate the values from videoPlayerViewModel.pages[indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "PageInfoTableViewCell", for: indexPath) as! PageInfoTableViewCell
        
        if let pageInfo = videoPlayerViewModel?.pages[indexPath.row] {
            cell.configureCell(model: pageInfo)
            cell.delegate = self
        }
        
        return cell
    }
}

extension ViewController {
    
    private func setupPlayer(url: URL) {
//        let asset = AVAsset(url: url)
//        let playerItem = AVPlayerItem(asset: asset)
//        player = AVPlayer(playerItem: playerItem)
        
        player = AVPlayer(url: url)
        playerLayer = AVPlayerLayer(player: player)
        playerLayer?.videoGravity = .resize
        videoPlayerView.layer.addSublayer(playerLayer!)
        NotificationCenter.default.addObserver(self, selector: #selector(playerItemDidPlayToEndTime), name: .AVPlayerItemNewErrorLogEntry, object: nil)
    }
    
    private func updateProgressBar() {
        player?.addPeriodicTimeObserver(forInterval: CMTime(seconds: 1, preferredTimescale: 1), queue: .main) { [weak self] time in
            guard let self = self else { return }
            let currentTime = time.seconds
            let totalSeconds = 558.0
            if currentTime == 0 {
                self.currentPageIndex = 0
            }
            self.progressView.progress = Float(currentTime / totalSeconds)
            for (index, pageInfo) in pages.enumerated() {
                if let starttime = Double(pageInfo.startTime), let endTime = Double(pageInfo.endTime)  {
                    if currentTime > starttime && currentTime < endTime  {
//                        self.currentPageIndex = pageInfo.pageIndex
//                        print("current Index inside update Progress \(pageInfo.pageIndex)")
                        break
                    }
                }
            }
        }
    }
    
    private func updateCurrentPage(currentTime: Double) {
        for (index, pageInfo) in pages.enumerated() {
            if let starttime = Double(pageInfo.startTime), let endTime = Double(pageInfo.endTime)  {
                print("outside current time  \(currentTime) starttime \(starttime) endTime \(endTime)")
                if currentTime >= starttime && currentTime <= endTime  {
                    print("inside current time  \(currentTime) starttime \(starttime) endTime \(endTime)")

                    self.currentPageIndex = pageInfo.pageIndex
                    print("current Index inside update Progress \(pageInfo.pageIndex)")
                    break
                }
            }
        }
    }
    
    
    
    func downloadFile(from url: URL, completion: @escaping (URL?, Error?) -> Void) {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let localURL = documentsDirectory.appendingPathComponent("downloaded_video.mp4")
        // Check if the file already exists locally
        if FileManager.default.fileExists(atPath: localURL.path) {
            completion(localURL, nil)
            return
        }
        
        let downloadTask = URLSession.shared.downloadTask(with: url) { (tempURL, response, error) in
            if let error = error {
                completion(nil, error)
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                completion(nil, NSError(domain: "DownloadError", code: -1, userInfo: nil)) // Handle non-successful status code
                return
            }
            
            guard let tempURL = tempURL else {
                completion(nil, NSError(domain: "DownloadError", code: -2, userInfo: nil)) // Handle empty tempURL
                return
            }
            
            do {
                try FileManager.default.moveItem(at: tempURL, to: localURL)
                completion(localURL, nil) // File downloaded successfully
            } catch {
                completion(nil, error) // Handle move error
            }
        }
        
        downloadTask.resume()
    }
    
    private func seekToTime(_ time: TimeInterval, isForward: Bool = true) {
        print("seek to time jump \(time)")
        player?.pause()
        let cmTime = CMTimeMakeWithSeconds(time, preferredTimescale: 600) // 600 is a common timescale, you can adjust it
        let advanceTime = CMTimeGetSeconds(cmTime).advanced(by: 0)
        let seekTime = CMTime(value: CMTimeValue(advanceTime), timescale: 1)
        self.player?.seek(to: seekTime, completionHandler: { completed in
//            if isForward {
//                self.currentPageIndex += 1
//            } else {
//                self.currentPageIndex -= 1
//            }
//            self.player?.play()
            print("seek to time jump completed \(time) is completed \(completed)")
        })
    }
    
    private func loadData() {
        if let viewModel = JSONLoader.loadVideoPlayerViewModel(fromJSONFile: "VideoJson") {
            // Use viewModel for your video player
            print(viewModel.videoURL)
            print(viewModel.pages)
            videoPlayerViewModel = viewModel
            // Create VideoPlayerView
            downloadFile(from: viewModel.videoURL) {[weak self] url, error in
                
                if let localURL = url {
                    // File downloaded successfully, 'localURL' points to the downloaded file
                    print("Downloaded file: \(localURL)")
                    DispatchQueue.main.async {
                                                
                        self?.setupPlayer(url: localURL)
                        self?.updateProgressBar()
                    }
                } else if let error = error {
                    // Handle the download error
                    print("Download error: \(error)")
                }
            }
        } else {
            print("Failed to load JSON data.")
        }
    }
}

extension ViewController: PageInfoTableViewCellDelegate {
    func didTapChange(model: PageData?) {
        guard let model = model else { return }
        if let index = videoPlayerViewModel?.pages.firstIndex(where: { $0.pageIndex == model.pageIndex }) {
            // Modify the 'PageData' at the found index.
            videoPlayerViewModel?.pages[index].startTime = model.startTime
            videoPlayerViewModel?.pages[index].endTime = model.endTime
        }
    }
}

struct VideoPlayerData: Codable {
    let bookURL: String
    let pages: [PageData]
}

struct PageData: Codable {
    let pageIndex: Int
    var startTime: String
    var endTime: String
}
