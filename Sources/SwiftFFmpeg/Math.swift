//
//  Math.swift
//  SwiftFFmpeg
//
//  Created by sunlubo on 2018/8/9.
//

import CFFmpeg

// MARK: - AVRational

/// Rational number (pair of numerator and denominator).
public typealias AVRational = CFFmpeg.AVRational

extension AVRational {

    public init(num: Int, den: Int) {
        self.init(num: Int32(num), den: Int32(den))
    }

    /// Convert an AVRational to a `double`.
    public var toDouble: Double {
        return av_q2d(self)
    }
    
    /// Get the inverted rational
    public var inverted: AVRational {
        return av_inv_q(self)
    }
}

extension AVRational: Equatable {
    public static func == (lhs: AVRational, rhs: AVRational) -> Bool {
        return av_cmp_q(lhs, rhs) == 0
    }
}

// MARK: - Rescale

/// Rounding methods.
public typealias AVRounding = CFFmpeg.AVRounding

extension AVRounding {
    /// Round toward zero.
    public static let zero = AV_ROUND_ZERO
    /// Round away from zero.
    public static let inf = AV_ROUND_INF
    /// Round toward -infinity.
    public static let down = AV_ROUND_DOWN
    /// Round toward +infinity.
    public static let up = AV_ROUND_UP
    /// Round to nearest and halfway cases away from zero.
    public static let nearInf = AV_ROUND_NEAR_INF

    /// Flag telling rescaling functions to pass `INT64_MIN`/`MAX` through
    /// unchanged, avoiding special cases for #AV_NOPTS_VALUE.
    ///
    /// Unlike other values of the enumeration AVRounding, this value is a
    /// bitmask that must be used in conjunction with another value of the
    /// enumeration through a bitwise OR, in order to set behavior for normal
    /// cases.
    ///
    ///     av_rescale_rnd(3, 1, 2, AV_ROUND_UP | AV_ROUND_PASS_MINMAX);
    ///     // Rescaling 3:
    ///     //     Calculating 3 * 1 / 2
    ///     //     3 / 2 is rounded up to 2
    ///     //     => 2
    ///
    ///     av_rescale_rnd(AV_NOPTS_VALUE, 1, 2, AV_ROUND_UP | AV_ROUND_PASS_MINMAX);
    ///     // Rescaling AV_NOPTS_VALUE:
    ///     //     AV_NOPTS_VALUE == INT64_MIN
    ///     //     AV_NOPTS_VALUE is passed through
    ///     //     => AV_NOPTS_VALUE
    public static let passMinMax = AV_ROUND_PASS_MINMAX

    func union(_ other: AVRounding) -> AVRounding {
        if other != .passMinMax { return self }
        return AVRounding(rawValue | other.rawValue)
    }
}

/// Rescale a integer with specified rounding.
///
/// The operation is mathematically equivalent to `a * b / c`, but writing that
/// directly can overflow, and does not support different rounding methods.
public func rescale<T: BinaryInteger>(_ a: T, _ b: T, _ c: T, _ rnd: AVRounding = .inf) -> Int64 {
    return av_rescale_rnd(Int64(a), Int64(b), Int64(c), rnd)
}

/// Rescale a integer by 2 rational numbers with specified rounding.
///
/// The operation is mathematically equivalent to `a * bq / cq`.
public func rescale<T: BinaryInteger>(_ a: T, _ b: AVRational, _ c: AVRational, _ rnd: AVRounding = .inf) -> Int64 {
    return av_rescale_q_rnd(Int64(a), b, c, rnd)
}
