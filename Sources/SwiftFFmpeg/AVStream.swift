//
//  AVStream.swift
//  SwiftFFmpeg
//
//  Created by sunlubo on 2018/6/29.
//

import CFFmpeg

// MARK: - AVDiscard

public typealias AVDiscard = CFFmpeg.AVDiscard

extension AVDiscard {
    /// discard nothing
    public static let none = AVDISCARD_NONE
    /// discard useless packets like 0 size packets in avi
    public static let `default` = AVDISCARD_DEFAULT
    /// discard all non reference
    public static let nonRef = AVDISCARD_NONREF
    /// discard all bidirectional frames
    public static let bidir = AVDISCARD_BIDIR
    /// discard all non intra frames
    public static let nonIntra = AVDISCARD_NONINTRA
    /// discard all frames except keyframes
    public static let nonKey = AVDISCARD_NONKEY
    /// discard all
    public static let all = AVDISCARD_ALL
}

// MARK: - Audio

internal typealias CAVCodecParameters = CFFmpeg.AVCodecParameters

/// This class describes the properties of an encoded stream.
public final class AVCodecParameters {
    internal let parametersPtr: UnsafeMutablePointer<CAVCodecParameters>
    internal var parameters: CAVCodecParameters { return parametersPtr.pointee }
    private var freeWhenDone: Bool
    
    internal init(parametersPtr: UnsafeMutablePointer<CAVCodecParameters>, freeWhenDone: Bool = false) {
        self.parametersPtr = parametersPtr
        self.freeWhenDone = freeWhenDone
    }
    
    public convenience init() {
        guard let parametersPtr = avcodec_parameters_alloc() else {
            fatalError("avcodec_parameters_alloc")
        }
        self.init(parametersPtr: parametersPtr, freeWhenDone: true)
    }
    
    public convenience init(with parameters: AVCodecParameters) throws {
        self.init()
        try copy(from: parameters)
    }

    /// General type of the encoded data.
    public var mediaType: AVMediaType {
        get { return parameters.codec_type }
        set { parametersPtr.pointee.codec_type = newValue }
    }

    /// Specific type of the encoded data (the codec used).
    public var codecId: AVCodecID {
        get { return parameters.codec_id }
        set { parametersPtr.pointee.codec_id = newValue }
    }

    /// Additional information about the codec (corresponds to the AVI FOURCC).
    public var codecTag: UInt32 {
        get { return parameters.codec_tag }
        set { parametersPtr.pointee.codec_tag = newValue }
    }

    /// The average bitrate of the encoded data (in bits per second).
    public var bitRate: Int {
        get { return Int(parameters.bit_rate) }
        set { parametersPtr.pointee.bit_rate = Int64(newValue) }
    }
    
    /// Copy and replace self with the specified parameters
    internal func copy(from parameters: AVCodecParameters) throws {
        try throwIfFail(avcodec_parameters_copy(parametersPtr, parameters.parametersPtr))
    }
    
    deinit {
        guard freeWhenDone else { return }
        var ptr: UnsafeMutablePointer<CAVCodecParameters>? = parametersPtr
        avcodec_parameters_free(&ptr)
    }
}

// MARK: - Video

extension AVCodecParameters {

    /// Pixel format.
    public var pixFmt: AVPixelFormat {
        return AVPixelFormat(parameters.format)
    }

    /// The width of the video frame in pixels.
    public var width: Int {
        get { return Int(parameters.width) }
        set { parametersPtr.pointee.width = Int32(newValue) }
    }
    
    /// The height of the video frame in pixels.
    public var height: Int {
        get { return Int(parameters.height) }
        set { parametersPtr.pointee.height = Int32(newValue) }
    }

    /// The aspect ratio (width / height) which a single pixel should have when displayed.
    ///
    /// When the aspect ratio is unknown / undefined, the numerator should be
    /// set to 0 (the denominator may have any value).
    public var sampleAspectRatio: AVRational {
        return parameters.sample_aspect_ratio
    }

    /// Number of delayed frames.
    public var videoDelay: Int {
        return Int(parameters.video_delay)
    }
}

// MARK: - Audio

extension AVCodecParameters {

    /// Sample format.
    public var sampleFmt: AVSampleFormat {
        return AVSampleFormat(parameters.format)
    }

    /// The channel layout bitmask. May be 0 if the channel layout is
    /// unknown or unspecified, otherwise the number of bits set must be equal to
    /// the channels field.
    public var channelLayout: AVChannelLayout {
        return AVChannelLayout(rawValue: parameters.channel_layout)
    }

    /// The number of audio channels.
    public var channelCount: Int {
        return Int(parameters.channels)
    }

    /// The number of audio samples per second.
    public var sampleRate: Int {
        return Int(parameters.sample_rate)
    }

    /// Audio frame size, if known. Required by some formats to be static.
    public var frameSize: Int {
        return Int(parameters.frame_size)
    }
}

// MARK: - AVStream

internal typealias CAVStream = CFFmpeg.AVStream

/// Stream structure.
public final class AVStream {
    internal let streamPtr: UnsafeMutablePointer<CAVStream>
    internal var stream: CAVStream { return streamPtr.pointee }

    internal init(streamPtr: UnsafeMutablePointer<CAVStream>) {
        self.streamPtr = streamPtr
    }

    /// Format-specific stream ID.
    ///
    /// - encoding: Set by the user, replaced by libavformat if left unset.
    /// - decoding: Set by libavformat.
    public var id: Int32 {
        get { return stream.id }
        set { streamPtr.pointee.id = newValue }
    }

    /// Stream index in `AVFormatContext`.
    public var index: Int {
        return Int(stream.index)
    }

    /// This is the fundamental unit of time (in seconds) in terms of which frame timestamps are represented.
    ///
    /// - encoding: May be set by the caller before `writeHeader` to provide a hint to the muxer about
    ///   the desired timebase. In `writeHeader`, the muxer will overwrite this field with the timebase
    ///   that will actually be used for the timestamps written into the file (which may or may not be related to
    ///   the user-provided one, depending on the format).
    /// - decoding: Set by libavformat.
    public var timebase: AVRational {
        get { return stream.time_base }
        set { streamPtr.pointee.time_base = newValue }
    }

    /// pts of the first frame of the stream in presentation order, in stream time base.
    public var startTime: Int64 {
        return stream.start_time
    }

    public var duration: Int64 {
        return stream.duration
    }

    /// Number of frames in this stream if known or 0.
    public var frameCount: Int {
        return Int(stream.nb_frames)
    }

    /// Selects which packets can be discarded at will and do not need to be demuxed.
    public var discard: AVDiscard {
        get { return stream.discard }
        set { streamPtr.pointee.discard = newValue }
    }

    /// sample aspect ratio (0 if unknown)
    ///
    /// - encoding: Set by user.
    /// - decoding: Set by libavformat.
    public var sampleAspectRatio: AVRational {
        return stream.sample_aspect_ratio
    }

    public var metadata: [String: String] {
        var dict = [String: String]()
        var tag: UnsafeMutablePointer<AVDictionaryEntry>?
        while let next = av_dict_get(stream.metadata, "", tag, AV_DICT_IGNORE_SUFFIX) {
            dict[String(cString: next.pointee.key)] = String(cString: next.pointee.value)
            tag = next
        }
        return dict
    }

    /// Average framerate.
    ///
    /// - demuxing: May be set by libavformat when creating the stream or in `findStreamInfo`.
    /// - muxing: May be set by the caller before `writeHeader`.
    public var averageFramerate: AVRational {
        return stream.avg_frame_rate
    }

    /// Real base framerate of the stream.
    /// This is the lowest framerate with which all timestamps can be represented accurately
    /// (it is the least common multiple of all framerates in the stream). Note, this value is just a guess!
    /// For example, if the time base is 1/90000 and all frames have either approximately 3600 or 1800 timer ticks,
    /// then realFramerate will be 50/1.
    public var realFramerate: AVRational {
        return stream.r_frame_rate
    }

    /// Codec parameters associated with this stream.
    ///
    /// - demuxing: filled by libavformat on stream creation or in `findStreamInfo`.
    /// - muxing: Filled by the caller before `writeHeader`.
    public var codecpar: AVCodecParameters {
        return AVCodecParameters(parametersPtr: stream.codecpar)
    }

    public var mediaType: AVMediaType {
        return codecpar.mediaType
    }

    /// Copy the contents of src to dst.
    ///
    /// - Throws: AVError
    public func setParameters(_ codecpar: AVCodecParameters) throws {
        try throwIfFail(avcodec_parameters_copy(stream.codecpar, codecpar.parametersPtr))
    }

    /// Fill the parameters struct based on the values from the supplied codec context.
    ///
    /// - Throws: AVError
    public func copyParameters(from codecCtx: AVCodecContext) throws {
        try throwIfFail(avcodec_parameters_from_context(stream.codecpar, codecCtx.ctxPtr))
    }
}
