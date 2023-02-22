// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/FixedPointMathLib.sol)
/// @author Inspired by USM (https://github.com/usmfum/USM/blob/master/contracts/WadMath.sol)
library FixedPointMathLib {
    /*//////////////////////////////////////////////////////////////
                    SIMPLIFIED FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant MAX_UINT256 = 2**256 - 1;

    uint256 internal constant WAD = 1e18; // The scalar of ETH and most ERC20s.

    function mulWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, y, WAD); // Equivalent to (x * y) / WAD rounded down.
    }

    function mulWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, y, WAD); // Equivalent to (x * y) / WAD rounded up.
    }

    function divWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, WAD, y); // Equivalent to (x * WAD) / y rounded down.
    }

    function divWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, WAD, y); // Equivalent to (x * WAD) / y rounded up.
    }

    /*//////////////////////////////////////////////////////////////
                    LOW LEVEL FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function mulDivDown(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to require(denominator != 0 && (y == 0 || x <= type(uint256).max / y))
            if iszero(mul(denominator, iszero(mul(y, gt(x, div(MAX_UINT256, y)))))) {
                revert(0, 0)
            }

            // Divide x * y by the denominator.
            z := div(mul(x, y), denominator)
        }
    }

    function mulDivUp(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to require(denominator != 0 && (y == 0 || x <= type(uint256).max / y))
            if iszero(mul(denominator, iszero(mul(y, gt(x, div(MAX_UINT256, y)))))) {
                revert(0, 0)
            }

            // If x * y modulo the denominator is strictly greater than 0,
            // 1 is added to round up the division of x * y by the denominator.
            z := add(gt(mod(mul(x, y), denominator), 0), div(mul(x, y), denominator))
        }
    }

    function rpow(
        uint256 x,
        uint256 n,
        uint256 scalar
    ) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            switch x
            case 0 {
                switch n
                case 0 {
                    // 0 ** 0 = 1
                    z := scalar
                }
                default {
                    // 0 ** n = 0
                    z := 0
                }
            }
            default {
                switch mod(n, 2)
                case 0 {
                    // If n is even, store scalar in z for now.
                    z := scalar
                }
                default {
                    // If n is odd, store x in z for now.
                    z := x
                }

                // Shifting right by 1 is like dividing by 2.
                let half := shr(1, scalar)

                for {
                    // Shift n right by 1 before looping to halve it.
                    n := shr(1, n)
                } n {
                    // Shift n right by 1 each iteration to halve it.
                    n := shr(1, n)
                } {
                    // Revert immediately if x ** 2 would overflow.
                    // Equivalent to iszero(eq(div(xx, x), x)) here.
                    if shr(128, x) {
                        revert(0, 0)
                    }

                    // Store x squared.
                    let xx := mul(x, x)

                    // Round to the nearest number.
                    let xxRound := add(xx, half)

                    // Revert if xx + half overflowed.
                    if lt(xxRound, xx) {
                        revert(0, 0)
                    }

                    // Set x to scaled xxRound.
                    x := div(xxRound, scalar)

                    // If n is even:
                    if mod(n, 2) {
                        // Compute z * x.
                        let zx := mul(z, x)

                        // If z * x overflowed:
                        if iszero(eq(div(zx, x), z)) {
                            // Revert if x is non-zero.
                            if iszero(iszero(x)) {
                                revert(0, 0)
                            }
                        }

                        // Round to the nearest number.
                        let zxRound := add(zx, half)

                        // Revert if zx + half overflowed.
                        if lt(zxRound, zx) {
                            revert(0, 0)
                        }

                        // Return properly scaled zxRound.
                        z := div(zxRound, scalar)
                    }
                }
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                        GENERAL NUMBER UTILITIES
    //////////////////////////////////////////////////////////////*/

    function sqrt(uint256 x) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            let y := x // We start y at x, which will help us make our initial estimate.

            z := 181 // The "correct" value is 1, but this saves a multiplication later.

            // This segment is to get a reasonable initial estimate for the Babylonian method. With a bad
            // start, the correct # of bits increases ~linearly each iteration instead of ~quadratically.

            // We check y >= 2^(k + 8) but shift right by k bits
            // each branch to ensure that if x >= 256, then y >= 256.
            if iszero(lt(y, 0x10000000000000000000000000000000000)) {
                y := shr(128, y)
                z := shl(64, z)
            }
            if iszero(lt(y, 0x1000000000000000000)) {
                y := shr(64, y)
                z := shl(32, z)
            }
            if iszero(lt(y, 0x10000000000)) {
                y := shr(32, y)
                z := shl(16, z)
            }
            if iszero(lt(y, 0x1000000)) {
                y := shr(16, y)
                z := shl(8, z)
            }

            // Goal was to get z*z*y within a small factor of x. More iterations could
            // get y in a tighter range. Currently, we will have y in [256, 256*2^16).
            // We ensured y >= 256 so that the relative difference between y and y+1 is small.
            // That's not possible if x < 256 but we can just verify those cases exhaustively.

            // Now, z*z*y <= x < z*z*(y+1), and y <= 2^(16+8), and either y >= 256, or x < 256.
            // Correctness can be checked exhaustively for x < 256, so we assume y >= 256.
            // Then z*sqrt(y) is within sqrt(257)/sqrt(256) of sqrt(x), or about 20bps.

            // For s in the range [1/256, 256], the estimate f(s) = (181/1024) * (s+1) is in the range
            // (1/2.84 * sqrt(s), 2.84 * sqrt(s)), with largest error when s = 1 and when s = 256 or 1/256.

            // Since y is in [256, 256*2^16), let a = y/65536, so that a is in [1/256, 256). Then we can estimate
            // sqrt(y) using sqrt(65536) * 181/1024 * (a + 1) = 181/4 * (y + 65536)/65536 = 181 * (y + 65536)/2^18.

            // There is no overflow risk here since y < 2^136 after the first branch above.
            z := shr(18, mul(z, add(y, 65536))) // A mul() is saved from starting z at 181.

            // Given the worst case multiplicative error of 2.84 above, 7 iterations should be enough.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // If x+1 is a perfect square, the Babylonian method cycles between
            // floor(sqrt(x)) and ceil(sqrt(x)). This statement ensures we return floor.
            // See: https://en.wikipedia.org/wiki/Integer_square_root#Using_only_integer_division
            // Since the ceil is rare, we save gas on the assignment and repeat division in the rare case.
            // If you don't care whether the floor or ceil square root is returned, you can remove this statement.
            z := sub(z, lt(div(x, z), z))
        }
    }

    function unsafeMod(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Mod x by y. Note this will return
            // 0 instead of reverting if y is zero.
            z := mod(x, y)
        }
    }

    function unsafeDiv(uint256 x, uint256 y) internal pure returns (uint256 r) {
        /// @solidity memory-safe-assembly
        assembly {
            // Divide x by y. Note this will return
            // 0 instead of reverting if y is zero.
            r := div(x, y)
        }
    }

    function unsafeDivUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Add 1 to x * y if x % y > 0. Note this will
            // return 0 instead of reverting if y is zero.
            z := add(gt(mod(x, y), 0), div(x, y))
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Safe unsigned integer casting library that reverts on overflow.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeCastLib.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeCast.sol)
library SafeCastLib {
    function safeCastTo248(uint256 x) internal pure returns (uint248 y) {
        require(x < 1 << 248);

        y = uint248(x);
    }

    function safeCastTo224(uint256 x) internal pure returns (uint224 y) {
        require(x < 1 << 224);

        y = uint224(x);
    }

    function safeCastTo192(uint256 x) internal pure returns (uint192 y) {
        require(x < 1 << 192);

        y = uint192(x);
    }

    function safeCastTo160(uint256 x) internal pure returns (uint160 y) {
        require(x < 1 << 160);

        y = uint160(x);
    }

    function safeCastTo128(uint256 x) internal pure returns (uint128 y) {
        require(x < 1 << 128);

        y = uint128(x);
    }

    function safeCastTo96(uint256 x) internal pure returns (uint96 y) {
        require(x < 1 << 96);

        y = uint96(x);
    }

    function safeCastTo64(uint256 x) internal pure returns (uint64 y) {
        require(x < 1 << 64);

        y = uint64(x);
    }

    function safeCastTo32(uint256 x) internal pure returns (uint32 y) {
        require(x < 1 << 32);

        y = uint32(x);
    }

    function safeCastTo24(uint256 x) internal pure returns (uint24 y) {
        require(x < 1 << 24);

        y = uint24(x);
    }

    function safeCastTo16(uint256 x) internal pure returns (uint16 y) {
        require(x < 1 << 16);

        y = uint16(x);
    }

    function safeCastTo8(uint256 x) internal pure returns (uint8 y) {
        require(x < 1 << 8);

        y = uint8(x);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that is not stored
/// @notice Contains view functions to provide information about the pool that is computed rather than stored on the
/// blockchain. The functions here may have variable gas costs.
interface IUniswapV3PoolDerivedState {
    /// @notice Returns the cumulative tick and liquidity as of each timestamp `secondsAgo` from the current block timestamp
    /// @dev To get a time weighted average tick or liquidity-in-range, you must call this with two values, one representing
    /// the beginning of the period and another for the end of the period. E.g., to get the last hour time-weighted average tick,
    /// you must call it with secondsAgos = [3600, 0].
    /// @dev The time weighted average tick represents the geometric time weighted average price of the pool, in
    /// log base sqrt(1.0001) of token1 / token0. The TickMath library can be used to go from a tick value to a ratio.
    /// @param secondsAgos From how long ago each cumulative tick and liquidity value should be returned
    /// @return tickCumulatives Cumulative tick values as of each `secondsAgos` from the current block timestamp
    /// @return secondsPerLiquidityCumulativeX128s Cumulative seconds per liquidity-in-range value as of each `secondsAgos` from the current block
    /// timestamp
    function observe(uint32[] calldata secondsAgos)
        external
        view
        returns (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128s);

    /// @notice Returns a snapshot of the tick cumulative, seconds per liquidity and seconds inside a tick range
    /// @dev Snapshots must only be compared to other snapshots, taken over a period for which a position existed.
    /// I.e., snapshots cannot be compared if a position is not held for the entire period between when the first
    /// snapshot is taken and the second snapshot is taken.
    /// @param tickLower The lower tick of the range
    /// @param tickUpper The upper tick of the range
    /// @return tickCumulativeInside The snapshot of the tick accumulator for the range
    /// @return secondsPerLiquidityInsideX128 The snapshot of seconds per liquidity for the range
    /// @return secondsInside The snapshot of seconds per liquidity for the range
    function snapshotCumulativesInside(int24 tickLower, int24 tickUpper)
        external
        view
        returns (
            int56 tickCumulativeInside,
            uint160 secondsPerLiquidityInsideX128,
            uint32 secondsInside
        );
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.13;

import {SafeCastLib} from "solmate/utils/SafeCastLib.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";

import {IUniswapV3PoolDerivedState} from "v3-core/interfaces/pool/IUniswapV3PoolDerivedState.sol";

/// @title Uniswap v3 Price-out-of-range Oracle
/// @author zefram.eth
/// @notice Flashloan-proof Uniswap v3 price-out-of-range oracle for querying if a position is out of range onchain
/// @dev Allows anyone to take a recording of a position over a time window to see for what proportion of the window
/// was the position in range. If the proportion is above the threshold (set at deploy-time) then it's state becomes
/// IN_RANGE, otherwise it becomes OUT_OF_RANGE.
contract UniswapPoorOracle {
    /// -----------------------------------------------------------------------
    /// Library usage
    /// -----------------------------------------------------------------------

    using SafeCastLib for uint256;
    using FixedPointMathLib for uint256;

    /// -----------------------------------------------------------------------
    /// Errors
    /// -----------------------------------------------------------------------

    /// @notice Thrown when trying to finish a recording when there is no recording or
    /// the length of the recording is invalid.
    error UniswapPoorOracle__NoValidRecording();

    /// @notice Thrown when trying to start a recording for a position when there's already
    /// one in progress.
    error UniswapPoorOracle__RecordingAlreadyInProgress();

    /// -----------------------------------------------------------------------
    /// Enums
    /// -----------------------------------------------------------------------

    /// @notice The in-range state of a position.
    /// - UNKNOWN means a recording has never been taken.
    /// - IN_RANGE means it was in range at the time of the last recording.
    /// - OUT_OF_RANGE means it was out of range at the time of the last recording.
    enum PositionState {
        UNKNOWN,
        IN_RANGE,
        OUT_OF_RANGE
    }

    /// -----------------------------------------------------------------------
    /// Structs
    /// -----------------------------------------------------------------------

    /// @notice The state of a recording.
    /// @param startTime The Unix timestamp when the recording was started, in seconds.
    /// @param startSecondsInside The secondsInside value of the position at the start of the recording.
    struct RecordingState {
        uint64 startTime;
        uint32 startSecondsInside;
    }

    /// -----------------------------------------------------------------------
    /// Immutable parameters
    /// -----------------------------------------------------------------------

    /// @notice The threshold for determining whether a position is in range.
    /// Scaled by 1e18. Should be a value between 0 and 1e18.
    uint256 public immutable inRangeThreshold;

    /// @notice The minimum length of a valid recording, in seconds.
    /// @dev The larger it is, the more secure the resulting state is (in the sense that
    /// it's expensive to manipulate), but the more time a recording takes. In addition, a
    /// longer recording is less useful after a point, since the normal volatility of the
    /// assets in the pool would come into play and affect the result. Should in general be
    /// somewhere between 30 minutes and 24 hours.
    uint256 public immutable recordingMinLength;

    /// @notice The maximum length of a valid recording, in seconds.
    /// @dev Prevents recordings that are so long that the normal volatility of the assets
    /// in the pool come into play.
    uint256 public immutable recordingMaxLength;

    /// -----------------------------------------------------------------------
    /// State variables
    /// -----------------------------------------------------------------------

    /// @dev The current in-range state of a position. Keyed by getPositionKey().
    mapping(bytes32 => PositionState) internal _positionState;

    /// @dev The state of a recording. Recordings are deleted after they are finished.
    /// Keyed by getPositionKey().
    mapping(bytes32 => RecordingState) internal _recordingState;

    /// -----------------------------------------------------------------------
    /// Constructor
    /// -----------------------------------------------------------------------

    constructor(uint256 inRangeThreshold_, uint256 recordingMinLength_, uint256 recordingMaxLength_) {
        inRangeThreshold = inRangeThreshold_;
        recordingMinLength = recordingMinLength_;
        recordingMaxLength = recordingMaxLength_;
    }

    /// -----------------------------------------------------------------------
    /// User actions
    /// -----------------------------------------------------------------------

    /// @notice Starts a new recording. Will revert if either tickLower or tickUpper hasn't been
    /// initialized in the Uniswap pool (which wouldn't be the case if a position [tickLower, tickUpper]
    /// exists).
    /// @dev If a recording already exists for the position but it's length is more than the maximum,
    /// it simply gets overwritten.
    /// @param pool The Uniswap V3 pool
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    function startRecording(address pool, int24 tickLower, int24 tickUpper) external {
        bytes32 key = getPositionKey(pool, tickLower, tickUpper);

        // ensure no active recording is in progress
        {
            uint256 startTime = _recordingState[key].startTime;
            if (startTime != 0 && block.timestamp - startTime <= recordingMaxLength) {
                revert UniswapPoorOracle__RecordingAlreadyInProgress();
            }
        }

        // query uniswap pool
        (,, uint32 secondsInside) = IUniswapV3PoolDerivedState(pool).snapshotCumulativesInside(tickLower, tickUpper);

        // create new recording
        _recordingState[key] =
            RecordingState({startTime: block.timestamp.safeCastTo64(), startSecondsInside: secondsInside});
    }

    /// @notice Finishes a recording and returns the resulting in-range state of the position.
    /// @param pool The Uniswap V3 pool
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @return state The resulting state of the position
    function finishRecording(address pool, int24 tickLower, int24 tickUpper) external returns (PositionState state) {
        bytes32 key = getPositionKey(pool, tickLower, tickUpper);

        RecordingState memory recording = _recordingState[key];

        // ensure there is a valid recording
        uint256 recordingLength = block.timestamp - recording.startTime;
        if (
            !(recording.startTime != 0 && recordingLength >= recordingMinLength && recordingLength <= recordingMaxLength)
        ) {
            revert UniswapPoorOracle__NoValidRecording();
        }

        // query uniswap pool
        (,, uint256 secondsInside) = IUniswapV3PoolDerivedState(pool).snapshotCumulativesInside(tickLower, tickUpper);
        uint256 proportionInRange = (secondsInside - recording.startSecondsInside).divWadDown(recordingLength);

        // update position state
        state = proportionInRange >= inRangeThreshold ? PositionState.IN_RANGE : PositionState.OUT_OF_RANGE;
        _positionState[key] = state;

        // delete recording
        delete _recordingState[key];
    }

    /// -----------------------------------------------------------------------
    /// View functions
    /// -----------------------------------------------------------------------

    /// @notice Returns the in-range state of a position based on the last recording
    /// taken.
    /// @param pool The Uniswap V3 pool
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @return state The current state of the position
    function getPositionState(address pool, int24 tickLower, int24 tickUpper)
        external
        view
        returns (PositionState state)
    {
        return _positionState[getPositionKey(pool, tickLower, tickUpper)];
    }

    /// @notice Returns the in-range state of a position based on the last recording
    /// taken, using the position's key as input.
    /// @param key The key of the position as computed by getPositionKey()
    /// @return state The current state of the position
    function getPositionStateFromKey(bytes32 key) external view returns (PositionState state) {
        return _positionState[key];
    }

    /// @notice Computes the key of a position used by _positionState and _recordingState.
    /// @param pool The Uniswap V3 pool
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @return The key of the position
    function getPositionKey(address pool, int24 tickLower, int24 tickUpper) public pure returns (bytes32) {
        return keccak256(abi.encode(pool, tickLower, tickUpper));
    }
}