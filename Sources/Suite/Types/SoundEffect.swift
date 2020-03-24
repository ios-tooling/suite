//
//  SoundEffect.swift
//
//  Created by Ben Gottlieb on 3/16/19.
//

import Foundation
import AVFoundation
import OpenAL
import AudioToolbox

#if os(OSX)
	import AppKit
#else
	import UIKit
#endif


public class SoundEffect: Equatable {
	private static var cachedSounds: [String: SoundEffect] = [:]
	private static var playingSounds: [SoundEffect] = []
    private static var isAmbient = false
	public static var disableAllSounds = Gestalt.runningOnSimulator
	var player: AVAudioPlayer!
	var original: SoundEffect?
	weak var dequeueTimer: Timer?
	public var isPlaying = false
	public private(set) var isLooping = false
	var startedAt: Date?
	var pausedAt: Date?
	var completion: (() -> Void)?
	public var volume: Float = 1.0 { didSet {
		self.actualPlayer?.volume = volume
	}}
	
	init(original: SoundEffect) {
		self.original = original
	}
	
	public init?(url: URL, preload: Bool = true, uncached: Bool = false) {
		if let original = SoundEffect.cachedSounds[url.absoluteString] {
			self.original = original
		} else {
			do {
				self.player = try AVAudioPlayer(contentsOf: url, fileTypeHint: nil)
                
			} catch {
				print("Error loading sound at \(url): \(error)")
				return nil
			}
			if preload { self.player.prepareToPlay() }
			if !uncached { SoundEffect.cachedSounds[url.absoluteString] = self }
		}
	}
	
	public init?(data: Data?, preload: Bool = true, uncached: Bool = false) {
		guard let data = data else { return nil }
		
		do {
			self.player = try AVAudioPlayer(data: data, fileTypeHint: nil)
		} catch {
			print("Error loading sound from data: \(error)")
			return nil
		}
		#if os(iOS)
        	self.makeAmbient()
		#endif
		if preload { self.player.prepareToPlay() }
	}
	
    
	#if os(iOS)
    func makeAmbient() {
		if #available(iOS 10.0, iOSApplicationExtension 10.0, *) {
        	if !SoundEffect.isAmbient {
            	SoundEffect.isAmbient = true
				try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
				try? AVAudioSession.sharedInstance().setActive(true)
			}
        }
    }
	#endif
	
	@available(iOS 9.0, iOSApplicationExtension 9.0, OSX 10.11, *)
	convenience public init?(named name: String, in bundle: Bundle? = nil, preload: Bool = true, uncached: Bool = false) {
		if let existing = SoundEffect.cachedSounds[name] {
			self.init(original: existing)
		} else {
			if let data = NSDataAsset(name: name, bundle: bundle ?? Bundle.main)?.data {
				self.init(data: data, preload: preload, uncached: uncached)
			} else if let url = Bundle.main.url(forResource: name, withExtension: nil) {
				self.init(url: url, preload: preload, uncached: uncached)
				if !uncached { SoundEffect.cachedSounds[name] = self }
			} else if let data = NSDataAsset(name: name, bundle: bundle ?? Bundle.main)?.data {
				self.init(data: data, preload: preload, uncached: uncached)
				if !uncached { SoundEffect.cachedSounds[name] = self }
			} else {
				print("Unable to locate a sound named \(name) in \(bundle?.description ?? "--")")
				self.init(data: nil, preload: false, uncached: false)
			}
		}
	}
	
	public func loop(fadingInOver fadeIn: TimeInterval = 0) {
		self.player.numberOfLoops = -1
		if self.isLooping { return }
		
		self.isLooping = true
		if self.isPlaying { return }
		self.play(fadingInOver: fadeIn)
	}
	
	public func stop(fadingOutOver fadeOut: TimeInterval = 0) {
		if #available(iOS 10.0, iOSApplicationExtension 10.0, OSX 10.12, OSXApplicationExtension 10.12, *), fadeOut > 0 {
			self.actualPlayer.setVolume(0, fadeDuration: fadeOut)
			DispatchQueue.main.asyncAfter(deadline: .now() + fadeOut) {
				self.stop()
			}
			return
		}

		self.player.numberOfLoops = 0
		self.isLooping = false
		self.actualPlayer.stop()
		self.stopPlaying()
	}

	func registerAsPlayingFor(duration: TimeInterval? = nil) {
		if !SoundEffect.playingSounds.contains(self) { SoundEffect.playingSounds.append(self) }
		self.dequeueTimer?.invalidate()
		if let dur = duration {
			self.dequeueTimer = Timer.scheduledTimer(timeInterval: dur * 1.001, target: self, selector: #selector(finishPlaying), userInfo: nil, repeats: false)
		}
	}
	
	func stopPlaying() {
		_ = SoundEffect.playingSounds.remove(self)
		self.isPlaying = false
		self.pausedAt = nil
		self.startedAt = nil
		self.dequeueTimer?.invalidate()
	}
	
	@objc func finishPlaying() {
		self.stopPlaying()
		self.completion?()
		self.completion = nil
	}
	
	public static func ==(lhs: SoundEffect, rhs: SoundEffect) -> Bool {
		return lhs === rhs
	}
}

extension SoundEffect {
	public var duration: TimeInterval? { return self.player?.duration }
	var actualPlayer: AVAudioPlayer! { return self.player ?? self.original!.player }
	@discardableResult public func play(fadingInOver fadeIn: TimeInterval = 0, completion: (() -> Void)? = nil) -> Bool {
		if SoundEffect.disableAllSounds { return false }

		self.completion = completion
		if let startedAt = self.startedAt, let pausedAt = self.pausedAt {
			let elapsed = pausedAt.timeIntervalSince(startedAt)
			self.registerAsPlayingFor(duration: self.actualPlayer.duration - elapsed)
		} else {
			self.pausedAt = nil
			self.startedAt = Date()
			self.isPlaying = true
			self.registerAsPlayingFor(duration: self.actualPlayer.duration)
		}

		if fadeIn > 0 { self.actualPlayer.volume = 0 }
		if !self.actualPlayer.play() { return false }

		if #available(iOS 10.0, iOSApplicationExtension 10.0, OSX 10.12, OSXApplicationExtension 10.12, *), fadeIn > 0 {
			self.actualPlayer.setVolume(self.volume, fadeDuration: fadeIn)
		}
		return true
	}
	
	public func pause() {
		self.isPlaying = true
		self.actualPlayer.pause()
		self.pausedAt = Date()
		self.dequeueTimer?.invalidate()
	}
}