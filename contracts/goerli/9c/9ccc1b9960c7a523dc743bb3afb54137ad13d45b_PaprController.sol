// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = a * b
            // Compute the product mod 2**256 and mod 2**256 - 1
            // then use the Chinese Remainder Theorem to reconstruct
            // the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2**256 + prod0
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(a, b, not(0))
                prod0 := mul(a, b)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division
            if (prod1 == 0) {
                require(denominator > 0);
                assembly {
                    result := div(prod0, denominator)
                }
                return result;
            }

            // Make sure the result is less than 2**256.
            // Also prevents denominator == 0
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0]
            // Compute remainder using mulmod
            uint256 remainder;
            assembly {
                remainder := mulmod(a, b, denominator)
            }
            // Subtract 256 bit number from 512 bit number
            assembly {
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator
            // Compute largest power of two divisor of denominator.
            // Always >= 1.
            uint256 twos = (type(uint256).max - denominator + 1) & denominator;
            // Divide denominator by power of two
            assembly {
                denominator := div(denominator, twos)
            }

            // Divide [prod1 prod0] by the factors of two
            assembly {
                prod0 := div(prod0, twos)
            }
            // Shift in bits from prod1 into prod0. For this we need
            // to flip `twos` such that it is 2**256 / twos.
            // If twos is zero, then it becomes one
            assembly {
                twos := add(div(sub(0, twos), twos), 1)
            }
            prod0 |= prod1 * twos;

            // Invert denominator mod 2**256
            // Now that denominator is an odd number, it has an inverse
            // modulo 2**256 such that denominator * inv = 1 mod 2**256.
            // Compute the inverse by starting with a seed that is correct
            // correct for four bits. That is, denominator * inv = 1 mod 2**4
            uint256 inv = (3 * denominator) ^ 2;
            // Now use Newton-Raphson iteration to improve the precision.
            // Thanks to Hensel's lifting lemma, this also works in modular
            // arithmetic, doubling the correct bits in each step.
            inv *= 2 - denominator * inv; // inverse mod 2**8
            inv *= 2 - denominator * inv; // inverse mod 2**16
            inv *= 2 - denominator * inv; // inverse mod 2**32
            inv *= 2 - denominator * inv; // inverse mod 2**64
            inv *= 2 - denominator * inv; // inverse mod 2**128
            inv *= 2 - denominator * inv; // inverse mod 2**256

            // Because the division is now exact we can divide by multiplying
            // with the modular inverse of denominator. This will give us the
            // correct result modulo 2**256. Since the precoditions guarantee
            // that the outcome is less than 2**256, this is the final result.
            // We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inv;
            return result;
        }
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        result = mulDiv(a, b, denominator);
        unchecked {
            if (mulmod(a, b, denominator) > 0) {
                require(result < type(uint256).max);
                result++;
            }
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

/// @title Math library for computing sqrt prices from ticks and vice versa
/// @notice Computes sqrt price for ticks of size 1.0001, i.e. sqrt(1.0001^tick) as fixed point Q64.96 numbers. Supports
/// prices between 2**-128 and 2**128
library TickMath {
    /// @dev The minimum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**-128
    int24 internal constant MIN_TICK = -887272;
    /// @dev The maximum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**128
    int24 internal constant MAX_TICK = -MIN_TICK;

    /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

    /// @notice Calculates sqrt(1.0001^tick) * 2^96
    /// @dev Throws if |tick| > max tick
    /// @param tick The input tick for the above formula
    /// @return sqrtPriceX96 A Fixed point Q64.96 number representing the sqrt of the ratio of the two assets (token1/token0)
    /// at the given tick
    function getSqrtRatioAtTick(int24 tick) internal pure returns (uint160 sqrtPriceX96) {
        unchecked {
            uint256 absTick = tick < 0 ? uint256(-int256(tick)) : uint256(int256(tick));
            require(absTick <= uint256(int256(MAX_TICK)), "T");

            uint256 ratio = absTick & 0x1 != 0
                ? 0xfffcb933bd6fad37aa2d162d1a594001
                : 0x100000000000000000000000000000000;
            if (absTick & 0x2 != 0) ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
            if (absTick & 0x4 != 0) ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
            if (absTick & 0x8 != 0) ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
            if (absTick & 0x10 != 0) ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
            if (absTick & 0x20 != 0) ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
            if (absTick & 0x40 != 0) ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
            if (absTick & 0x80 != 0) ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
            if (absTick & 0x100 != 0) ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
            if (absTick & 0x200 != 0) ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
            if (absTick & 0x400 != 0) ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
            if (absTick & 0x800 != 0) ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
            if (absTick & 0x1000 != 0) ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
            if (absTick & 0x2000 != 0) ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
            if (absTick & 0x4000 != 0) ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
            if (absTick & 0x8000 != 0) ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
            if (absTick & 0x10000 != 0) ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
            if (absTick & 0x20000 != 0) ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
            if (absTick & 0x40000 != 0) ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
            if (absTick & 0x80000 != 0) ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;

            if (tick > 0) ratio = type(uint256).max / ratio;

            // this divides by 1<<32 rounding up to go from a Q128.128 to a Q128.96.
            // we then downcast because we know the result always fits within 160 bits due to our tick input constraint
            // we round up in the division so getTickAtSqrtRatio of the output price is always consistent
            sqrtPriceX96 = uint160((ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1));
        }
    }

    /// @notice Calculates the greatest tick value such that getRatioAtTick(tick) <= ratio
    /// @dev Throws in case sqrtPriceX96 < MIN_SQRT_RATIO, as MIN_SQRT_RATIO is the lowest value getRatioAtTick may
    /// ever return.
    /// @param sqrtPriceX96 The sqrt ratio for which to compute the tick as a Q64.96
    /// @return tick The greatest tick for which the ratio is less than or equal to the input ratio
    function getTickAtSqrtRatio(uint160 sqrtPriceX96) internal pure returns (int24 tick) {
        unchecked {
            // second inequality must be < because the price can never reach the price at the max tick
            require(sqrtPriceX96 >= MIN_SQRT_RATIO && sqrtPriceX96 < MAX_SQRT_RATIO, "R");
            uint256 ratio = uint256(sqrtPriceX96) << 32;

            uint256 r = ratio;
            uint256 msb = 0;

            assembly {
                let f := shl(7, gt(r, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(6, gt(r, 0xFFFFFFFFFFFFFFFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(5, gt(r, 0xFFFFFFFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(4, gt(r, 0xFFFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(3, gt(r, 0xFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(2, gt(r, 0xF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(1, gt(r, 0x3))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := gt(r, 0x1)
                msb := or(msb, f)
            }

            if (msb >= 128) r = ratio >> (msb - 127);
            else r = ratio << (127 - msb);

            int256 log_2 = (int256(msb) - 128) << 64;

            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(63, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(62, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(61, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(60, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(59, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(58, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(57, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(56, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(55, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(54, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(53, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(52, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(51, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(50, f))
            }

            int256 log_sqrt10001 = log_2 * 255738958999603826347141; // 128.128 number

            int24 tickLow = int24((log_sqrt10001 - 3402992956809132418596140100660247210) >> 128);
            int24 tickHi = int24((log_sqrt10001 + 291339464771989622907027621153398088495) >> 128);

            tick = tickLow == tickHi ? tickLow : getSqrtRatioAtTick(tickHi) <= sqrtPriceX96 ? tickHi : tickLow;
        }
    }

    function getTicks(int24 tickSpacing) internal pure returns (int24 minTick, int24 maxTick) {
        minTick = (MIN_TICK / tickSpacing) * tickSpacing;
        maxTick = (MAX_TICK / tickSpacing) * tickSpacing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (access/Ownable2Step.sol)

pragma solidity ^0.8.0;

import "./Ownable.sol";

/**
 * @dev Contract module which provides access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership} and {acceptOwnership}.
 *
 * This module is used through inheritance. It will make available all functions
 * from parent (Ownable).
 */
abstract contract Ownable2Step is Ownable {
    address private _pendingOwner;

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual override {
        delete _pendingOwner;
        super._transferOwnership(newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwnership() external {
        address sender = _msgSender();
        require(pendingOwner() == sender, "Ownable2Step: caller is not the new owner");
        _transferOwnership(sender);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

// Inspired by https://github.com/ZeframLou/trustus
abstract contract ReservoirOracle {
    // --- Structs ---

    struct Message {
        bytes32 id;
        bytes payload;
        // The UNIX timestamp when the message was signed by the oracle
        uint256 timestamp;
        // ECDSA signature or EIP-2098 compact signature
        bytes signature;
    }

    // --- Errors ---

    error InvalidMessage();

    // --- Fields ---

    address immutable RESERVOIR_ORACLE_ADDRESS;

    // --- Constructor ---

    constructor(address reservoirOracleAddress) {
        RESERVOIR_ORACLE_ADDRESS = reservoirOracleAddress;
    }

    // --- Internal methods ---

    function _verifyMessage(
        bytes32 id,
        uint256 validFor,
        Message memory message
    ) internal view virtual returns (bool success) {
        // Ensure the message matches the requested id
        if (id != message.id) {
            return false;
        }

        // Ensure the message timestamp is valid
        if (
            message.timestamp > block.timestamp ||
            message.timestamp + validFor < block.timestamp
        ) {
            return false;
        }

        bytes32 r;
        bytes32 s;
        uint8 v;

        // Extract the individual signature fields from the signature
        bytes memory signature = message.signature;
        if (signature.length == 64) {
            // EIP-2098 compact signature
            bytes32 vs;
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
                s := and(
                    vs,
                    0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
                )
                v := add(shr(255, vs), 27)
            }
        } else if (signature.length == 65) {
            // ECDSA signature
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
        } else {
            return false;
        }

        address signerAddress = ecrecover(
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    // EIP-712 structured-data hash
                    keccak256(
                        abi.encode(
                            keccak256(
                                "Message(bytes32 id,bytes payload,uint256 timestamp)"
                            ),
                            message.id,
                            keccak256(message.payload),
                            message.timestamp
                        )
                    )
                )
            ),
            v,
            r,
            s
        );

        // Ensure the signer matches the designated oracle address
        return signerAddress == RESERVOIR_ORACLE_ADDRESS;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Contract that enables a single call to call multiple methods on itself.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/Multicallable.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/Multicallable.sol)
/// @dev WARNING!
/// Multicallable is NOT SAFE for use in contracts with checks / requires on `msg.value`
/// (e.g. in NFT minting / auction contracts) without a suitable nonce mechanism.
/// It WILL open up your contract to double-spend vulnerabilities / exploits.
/// See: (https://www.paradigm.xyz/2021/08/two-rights-might-make-a-wrong/)
abstract contract Multicallable {
    /// @dev Apply `DELEGATECALL` with the current contract to each calldata in `data`,
    /// and store the `abi.encode` formatted results of each `DELEGATECALL` into `results`.
    /// If any of the `DELEGATECALL`s reverts, the entire transaction is reverted,
    /// and the error is bubbled up.
    function multicall(bytes[] calldata data) public payable returns (bytes[] memory results) {
        assembly {
            if data.length {
                results := mload(0x40) // Point `results` to start of free memory.
                mstore(results, data.length) // Store `data.length` into `results`.
                results := add(results, 0x20)

                // `shl` 5 is equivalent to multiplying by 0x20.
                let end := shl(5, data.length)
                // Copy the offsets from calldata into memory.
                calldatacopy(results, data.offset, end)
                // Pointer to the top of the memory (i.e. start of the free memory).
                let memPtr := add(results, end)
                end := add(results, end)

                for {} 1 {} {
                    // The offset of the current bytes in the calldata.
                    let o := add(data.offset, mload(results))
                    // Copy the current bytes from calldata to the memory.
                    calldatacopy(
                        memPtr,
                        add(o, 0x20), // The offset of the current bytes' bytes.
                        calldataload(o) // The length of the current bytes.
                    )
                    if iszero(delegatecall(gas(), address(), memPtr, calldataload(o), 0x00, 0x00)) {
                        // Bubble up the revert if the delegatecall reverts.
                        returndatacopy(0x00, 0x00, returndatasize())
                        revert(0x00, returndatasize())
                    }
                    // Append the current `memPtr` into `results`.
                    mstore(results, memPtr)
                    results := add(results, 0x20)
                    // Append the `returndatasize()`, and the return data.
                    mstore(memPtr, returndatasize())
                    returndatacopy(add(memPtr, 0x20), 0x00, returndatasize())
                    // Advance the `memPtr` by `returndatasize() + 0x20`,
                    // rounded up to the next multiple of 32.
                    memPtr := and(add(add(memPtr, returndatasize()), 0x3f), 0xffffffffffffffe0)
                    if iszero(lt(results, end)) { break }
                }
                // Restore `results` and allocate memory for it.
                results := mload(0x40)
                mstore(0x40, memPtr)
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /*//////////////////////////////////////////////////////////////
                         METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    function tokenURI(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                      ERC721 BALANCE/OWNER STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) internal _ownerOf;

    mapping(address => uint256) internal _balanceOf;

    function ownerOf(uint256 id) public view virtual returns (address owner) {
        require((owner = _ownerOf[id]) != address(0), "NOT_MINTED");
    }

    function balanceOf(address owner) public view virtual returns (uint256) {
        require(owner != address(0), "ZERO_ADDRESS");

        return _balanceOf[owner];
    }

    /*//////////////////////////////////////////////////////////////
                         ERC721 APPROVAL STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public virtual {
        address owner = _ownerOf[id];

        require(msg.sender == owner || isApprovedForAll[owner][msg.sender], "NOT_AUTHORIZED");

        getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        require(from == _ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from || isApprovedForAll[from][msg.sender] || msg.sender == getApproved[id],
            "NOT_AUTHORIZED"
        );

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            _balanceOf[from]--;

            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        delete getApproved[id];

        emit Transfer(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        transferFrom(from, to, id);

        if (to.code.length != 0)
            require(
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "") ==
                    ERC721TokenReceiver.onERC721Received.selector,
                "UNSAFE_RECIPIENT"
            );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes calldata data
    ) public virtual {
        transferFrom(from, to, id);

        if (to.code.length != 0)
            require(
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
                    ERC721TokenReceiver.onERC721Received.selector,
                "UNSAFE_RECIPIENT"
            );
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");

        require(_ownerOf[id] == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = _ownerOf[id];

        require(owner != address(0), "NOT_MINTED");

        // Ownership check above ensures no underflow.
        unchecked {
            _balanceOf[owner]--;
        }

        delete _ownerOf[id];

        delete getApproved[id];

        emit Transfer(owner, address(0), id);
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL SAFE MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    function _safeMint(address to, uint256 id) internal virtual {
        _mint(to, id);

        if (to.code.length != 0)
            require(
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, "") ==
                    ERC721TokenReceiver.onERC721Received.selector,
                "UNSAFE_RECIPIENT"
            );
    }

    function _safeMint(
        address to,
        uint256 id,
        bytes memory data
    ) internal virtual {
        _mint(to, id);

        if (to.code.length != 0)
            require(
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, data) ==
                    ERC721TokenReceiver.onERC721Received.selector,
                "UNSAFE_RECIPIENT"
            );
    }
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721TokenReceiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/FixedPointMathLib.sol)
library FixedPointMathLib {
    /*//////////////////////////////////////////////////////////////
                    SIMPLIFIED FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

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

    function powWad(int256 x, int256 y) internal pure returns (int256) {
        // Equivalent to x to the power of y because x ** y = (e ** ln(x)) ** y = e ** (ln(x) * y)
        return expWad((lnWad(x) * y) / int256(WAD)); // Using ln(x) means x must be greater than 0.
    }

    function expWad(int256 x) internal pure returns (int256 r) {
        unchecked {
            // When the result is < 0.5 we return zero. This happens when
            // x <= floor(log(0.5e18) * 1e18) ~ -42e18
            if (x <= -42139678854452767551) return 0;

            // When the result is > (2**255 - 1) / 1e18 we can not represent it as an
            // int. This happens when x >= floor(log((2**255 - 1) / 1e18) * 1e18) ~ 135.
            if (x >= 135305999368893231589) revert("EXP_OVERFLOW");

            // x is now in the range (-42, 136) * 1e18. Convert to (-42, 136) * 2**96
            // for more intermediate precision and a binary basis. This base conversion
            // is a multiplication by 1e18 / 2**96 = 5**18 / 2**78.
            x = (x << 78) / 5**18;

            // Reduce range of x to (-½ ln 2, ½ ln 2) * 2**96 by factoring out powers
            // of two such that exp(x) = exp(x') * 2**k, where k is an integer.
            // Solving this gives k = round(x / log(2)) and x' = x - k * log(2).
            int256 k = ((x << 96) / 54916777467707473351141471128 + 2**95) >> 96;
            x = x - k * 54916777467707473351141471128;

            // k is in the range [-61, 195].

            // Evaluate using a (6, 7)-term rational approximation.
            // p is made monic, we'll multiply by a scale factor later.
            int256 y = x + 1346386616545796478920950773328;
            y = ((y * x) >> 96) + 57155421227552351082224309758442;
            int256 p = y + x - 94201549194550492254356042504812;
            p = ((p * y) >> 96) + 28719021644029726153956944680412240;
            p = p * x + (4385272521454847904659076985693276 << 96);

            // We leave p in 2**192 basis so we don't need to scale it back up for the division.
            int256 q = x - 2855989394907223263936484059900;
            q = ((q * x) >> 96) + 50020603652535783019961831881945;
            q = ((q * x) >> 96) - 533845033583426703283633433725380;
            q = ((q * x) >> 96) + 3604857256930695427073651918091429;
            q = ((q * x) >> 96) - 14423608567350463180887372962807573;
            q = ((q * x) >> 96) + 26449188498355588339934803723976023;

            assembly {
                // Div in assembly because solidity adds a zero check despite the unchecked.
                // The q polynomial won't have zeros in the domain as all its roots are complex.
                // No scaling is necessary because p is already 2**96 too large.
                r := sdiv(p, q)
            }

            // r should be in the range (0.09, 0.25) * 2**96.

            // We now need to multiply r by:
            // * the scale factor s = ~6.031367120.
            // * the 2**k factor from the range reduction.
            // * the 1e18 / 2**96 factor for base conversion.
            // We do this all at once, with an intermediate result in 2**213
            // basis, so the final right shift is always by a positive amount.
            r = int256((uint256(r) * 3822833074963236453042738258902158003155416615667) >> uint256(195 - k));
        }
    }

    function lnWad(int256 x) internal pure returns (int256 r) {
        unchecked {
            require(x > 0, "UNDEFINED");

            // We want to convert x from 10**18 fixed point to 2**96 fixed point.
            // We do this by multiplying by 2**96 / 10**18. But since
            // ln(x * C) = ln(x) + ln(C), we can simply do nothing here
            // and add ln(2**96 / 10**18) at the end.

            // Reduce range of x to (1, 2) * 2**96
            // ln(2^k * x) = k * ln(2) + ln(x)
            int256 k = int256(log2(uint256(x))) - 96;
            x <<= uint256(159 - k);
            x = int256(uint256(x) >> 159);

            // Evaluate using a (8, 8)-term rational approximation.
            // p is made monic, we will multiply by a scale factor later.
            int256 p = x + 3273285459638523848632254066296;
            p = ((p * x) >> 96) + 24828157081833163892658089445524;
            p = ((p * x) >> 96) + 43456485725739037958740375743393;
            p = ((p * x) >> 96) - 11111509109440967052023855526967;
            p = ((p * x) >> 96) - 45023709667254063763336534515857;
            p = ((p * x) >> 96) - 14706773417378608786704636184526;
            p = p * x - (795164235651350426258249787498 << 96);

            // We leave p in 2**192 basis so we don't need to scale it back up for the division.
            // q is monic by convention.
            int256 q = x + 5573035233440673466300451813936;
            q = ((q * x) >> 96) + 71694874799317883764090561454958;
            q = ((q * x) >> 96) + 283447036172924575727196451306956;
            q = ((q * x) >> 96) + 401686690394027663651624208769553;
            q = ((q * x) >> 96) + 204048457590392012362485061816622;
            q = ((q * x) >> 96) + 31853899698501571402653359427138;
            q = ((q * x) >> 96) + 909429971244387300277376558375;
            assembly {
                // Div in assembly because solidity adds a zero check despite the unchecked.
                // The q polynomial is known not to have zeros in the domain.
                // No scaling required because p is already 2**96 too large.
                r := sdiv(p, q)
            }

            // r is in the range (0, 0.125) * 2**96

            // Finalization, we need to:
            // * multiply by the scale factor s = 5.549…
            // * add ln(2**96 / 10**18)
            // * add k * ln(2)
            // * multiply by 10**18 / 2**96 = 5**18 >> 78

            // mul s * 5e18 * 2**96, base is now 5**18 * 2**192
            r *= 1677202110996718588342820967067443963516166;
            // add ln(2) * k * 5e18 * 2**192
            r += 16597577552685614221487285958193947469193820559219878177908093499208371 * k;
            // add ln(2**96 / 10**18) * 5e18 * 2**192
            r += 600920179829731861736702779321621459595472258049074101567377883020018308;
            // base conversion: mul 2**18 / 2**192
            r >>= 174;
        }
    }

    /*//////////////////////////////////////////////////////////////
                    LOW LEVEL FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function mulDivDown(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
                revert(0, 0)
            }

            // Divide z by the denominator.
            z := div(z, denominator)
        }
    }

    function mulDivUp(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
                revert(0, 0)
            }

            // First, divide z - 1 by the denominator and add 1.
            // We allow z - 1 to underflow if z is 0, because we multiply the
            // end result by 0 if z is zero, ensuring we return 0 if z is zero.
            z := mul(iszero(iszero(z)), add(div(sub(z, 1), denominator), 1))
        }
    }

    function rpow(
        uint256 x,
        uint256 n,
        uint256 scalar
    ) internal pure returns (uint256 z) {
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

    function log2(uint256 x) internal pure returns (uint256 r) {
        require(x > 0, "UNDEFINED");

        assembly {
            r := shl(7, lt(0xffffffffffffffffffffffffffffffff, x))
            r := or(r, shl(6, lt(0xffffffffffffffff, shr(r, x))))
            r := or(r, shl(5, lt(0xffffffff, shr(r, x))))
            r := or(r, shl(4, lt(0xffff, shr(r, x))))
            r := or(r, shl(3, lt(0xff, shr(r, x))))
            r := or(r, shl(2, lt(0xf, shr(r, x))))
            r := or(r, shl(1, lt(0x3, shr(r, x))))
            r := or(r, lt(0x1, shr(r, x)))
        }
    }

    function unsafeMod(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assembly {
            // z will equal 0 if y is 0, unlike in Solidity where it will revert.
            z := mod(x, y)
        }
    }

    function unsafeDiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assembly {
            // z will equal 0 if y is 0, unlike in Solidity where it will revert.
            z := div(x, y)
        }
    }

    /// @dev Will return 0 instead of reverting if y is zero.
    function unsafeDivUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assembly {
            // Add 1 to x * y if x % y > 0.
            z := add(gt(mod(x, y), 0), div(x, y))
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @notice Safe unsigned integer casting library that reverts on overflow.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/SafeCastLib.sol)
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

    function safeCastTo8(uint256 x) internal pure returns (uint8 y) {
        require(x < 1 << 8);

        y = uint8(x);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Caution! This library won't check that a token has code, responsibility is delegated to the caller.
library SafeTransferLib {
    /*//////////////////////////////////////////////////////////////
                             ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool success;

        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(success, "ETH_TRANSFER_FAILED");
    }

    /*//////////////////////////////////////////////////////////////
                            ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // We'll write our calldata to this slot below, but restore it later.
            let memPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(0, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(4, from) // Append the "from" argument.
            mstore(36, to) // Append the "to" argument.
            mstore(68, amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because that's the total length of our calldata (4 + 32 * 3)
                // Counterintuitively, this call() must be positioned after the or() in the
                // surrounding and() because and() evaluates its arguments from right to left.
                call(gas(), token, 0, 0, 100, 0, 32)
            )

            mstore(0x60, 0) // Restore the zero slot to zero.
            mstore(0x40, memPointer) // Restore the memPointer.
        }

        require(success, "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // We'll write our calldata to this slot below, but restore it later.
            let memPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(0, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(4, to) // Append the "to" argument.
            mstore(36, amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because that's the total length of our calldata (4 + 32 * 2)
                // Counterintuitively, this call() must be positioned after the or() in the
                // surrounding and() because and() evaluates its arguments from right to left.
                call(gas(), token, 0, 0, 68, 0, 32)
            )

            mstore(0x60, 0) // Restore the zero slot to zero.
            mstore(0x40, memPointer) // Restore the memPointer.
        }

        require(success, "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // We'll write our calldata to this slot below, but restore it later.
            let memPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(0, 0x095ea7b300000000000000000000000000000000000000000000000000000000)
            mstore(4, to) // Append the "to" argument.
            mstore(36, amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because that's the total length of our calldata (4 + 32 * 2)
                // Counterintuitively, this call() must be positioned after the or() in the
                // surrounding and() because and() evaluates its arguments from right to left.
                call(gas(), token, 0, 0, 68, 0, 32)
            )

            mstore(0x60, 0) // Restore the zero slot to zero.
            mstore(0x40, memPointer) // Restore the memPointer.
        }

        require(success, "APPROVE_FAILED");
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title The interface for the Uniswap V3 Factory
/// @notice The Uniswap V3 Factory facilitates creation of Uniswap V3 pools and control over the protocol fees
interface IUniswapV3Factory {
    /// @notice Emitted when the owner of the factory is changed
    /// @param oldOwner The owner before the owner was changed
    /// @param newOwner The owner after the owner was changed
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);

    /// @notice Emitted when a pool is created
    /// @param token0 The first token of the pool by address sort order
    /// @param token1 The second token of the pool by address sort order
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks
    /// @param pool The address of the created pool
    event PoolCreated(
        address indexed token0,
        address indexed token1,
        uint24 indexed fee,
        int24 tickSpacing,
        address pool
    );

    /// @notice Emitted when a new fee amount is enabled for pool creation via the factory
    /// @param fee The enabled fee, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks for pools created with the given fee
    event FeeAmountEnabled(uint24 indexed fee, int24 indexed tickSpacing);

    /// @notice Returns the current owner of the factory
    /// @dev Can be changed by the current owner via setOwner
    /// @return The address of the factory owner
    function owner() external view returns (address);

    /// @notice Returns the tick spacing for a given fee amount, if enabled, or 0 if not enabled
    /// @dev A fee amount can never be removed, so this value should be hard coded or cached in the calling context
    /// @param fee The enabled fee, denominated in hundredths of a bip. Returns 0 in case of unenabled fee
    /// @return The tick spacing
    function feeAmountTickSpacing(uint24 fee) external view returns (int24);

    /// @notice Returns the pool address for a given pair of tokens and a fee, or address 0 if it does not exist
    /// @dev tokenA and tokenB may be passed in either token0/token1 or token1/token0 order
    /// @param tokenA The contract address of either token0 or token1
    /// @param tokenB The contract address of the other token
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @return pool The pool address
    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (address pool);

    /// @notice Creates a pool for the given two tokens and fee
    /// @param tokenA One of the two tokens in the desired pool
    /// @param tokenB The other of the two tokens in the desired pool
    /// @param fee The desired fee for the pool
    /// @dev tokenA and tokenB may be passed in either order: token0/token1 or token1/token0. tickSpacing is retrieved
    /// from the fee. The call will revert if the pool already exists, the fee is invalid, or the token arguments
    /// are invalid.
    /// @return pool The address of the newly created pool
    function createPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external returns (address pool);

    /// @notice Updates the owner of the factory
    /// @dev Must be called by the current owner
    /// @param _owner The new owner of the factory
    function setOwner(address _owner) external;

    /// @notice Enables a fee amount with the given tickSpacing
    /// @dev Fee amounts may never be removed once enabled
    /// @param fee The fee amount to enable, denominated in hundredths of a bip (i.e. 1e-6)
    /// @param tickSpacing The spacing between ticks to be enforced for all pools created with the given fee amount
    function enableFeeAmount(uint24 fee, int24 tickSpacing) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import './pool/IUniswapV3PoolImmutables.sol';
import './pool/IUniswapV3PoolState.sol';
import './pool/IUniswapV3PoolDerivedState.sol';
import './pool/IUniswapV3PoolActions.sol';
import './pool/IUniswapV3PoolOwnerActions.sol';
import './pool/IUniswapV3PoolEvents.sol';

/// @title The interface for a Uniswap V3 Pool
/// @notice A Uniswap pool facilitates swapping and automated market making between any two assets that strictly conform
/// to the ERC20 specification
/// @dev The pool interface is broken up into many smaller pieces
interface IUniswapV3Pool is
    IUniswapV3PoolImmutables,
    IUniswapV3PoolState,
    IUniswapV3PoolDerivedState,
    IUniswapV3PoolActions,
    IUniswapV3PoolOwnerActions,
    IUniswapV3PoolEvents
{

}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissionless pool actions
/// @notice Contains pool methods that can be called by anyone
interface IUniswapV3PoolActions {
    /// @notice Sets the initial price for the pool
    /// @dev Price is represented as a sqrt(amountToken1/amountToken0) Q64.96 value
    /// @param sqrtPriceX96 the initial sqrt price of the pool as a Q64.96
    function initialize(uint160 sqrtPriceX96) external;

    /// @notice Adds liquidity for the given recipient/tickLower/tickUpper position
    /// @dev The caller of this method receives a callback in the form of IUniswapV3MintCallback#uniswapV3MintCallback
    /// in which they must pay any token0 or token1 owed for the liquidity. The amount of token0/token1 due depends
    /// on tickLower, tickUpper, the amount of liquidity, and the current price.
    /// @param recipient The address for which the liquidity will be created
    /// @param tickLower The lower tick of the position in which to add liquidity
    /// @param tickUpper The upper tick of the position in which to add liquidity
    /// @param amount The amount of liquidity to mint
    /// @param data Any data that should be passed through to the callback
    /// @return amount0 The amount of token0 that was paid to mint the given amount of liquidity. Matches the value in the callback
    /// @return amount1 The amount of token1 that was paid to mint the given amount of liquidity. Matches the value in the callback
    function mint(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount,
        bytes calldata data
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Collects tokens owed to a position
    /// @dev Does not recompute fees earned, which must be done either via mint or burn of any amount of liquidity.
    /// Collect must be called by the position owner. To withdraw only token0 or only token1, amount0Requested or
    /// amount1Requested may be set to zero. To withdraw all tokens owed, caller may pass any value greater than the
    /// actual tokens owed, e.g. type(uint128).max. Tokens owed may be from accumulated swap fees or burned liquidity.
    /// @param recipient The address which should receive the fees collected
    /// @param tickLower The lower tick of the position for which to collect fees
    /// @param tickUpper The upper tick of the position for which to collect fees
    /// @param amount0Requested How much token0 should be withdrawn from the fees owed
    /// @param amount1Requested How much token1 should be withdrawn from the fees owed
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);

    /// @notice Burn liquidity from the sender and account tokens owed for the liquidity to the position
    /// @dev Can be used to trigger a recalculation of fees owed to a position by calling with an amount of 0
    /// @dev Fees must be collected separately via a call to #collect
    /// @param tickLower The lower tick of the position for which to burn liquidity
    /// @param tickUpper The upper tick of the position for which to burn liquidity
    /// @param amount How much liquidity to burn
    /// @return amount0 The amount of token0 sent to the recipient
    /// @return amount1 The amount of token1 sent to the recipient
    function burn(
        int24 tickLower,
        int24 tickUpper,
        uint128 amount
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Swap token0 for token1, or token1 for token0
    /// @dev The caller of this method receives a callback in the form of IUniswapV3SwapCallback#uniswapV3SwapCallback
    /// @param recipient The address to receive the output of the swap
    /// @param zeroForOne The direction of the swap, true for token0 to token1, false for token1 to token0
    /// @param amountSpecified The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)
    /// @param sqrtPriceLimitX96 The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
    /// value after the swap. If one for zero, the price cannot be greater than this value after the swap
    /// @param data Any data to be passed through to the callback
    /// @return amount0 The delta of the balance of token0 of the pool, exact when negative, minimum when positive
    /// @return amount1 The delta of the balance of token1 of the pool, exact when negative, minimum when positive
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);

    /// @notice Receive token0 and/or token1 and pay it back, plus a fee, in the callback
    /// @dev The caller of this method receives a callback in the form of IUniswapV3FlashCallback#uniswapV3FlashCallback
    /// @dev Can be used to donate underlying tokens pro-rata to currently in-range liquidity providers by calling
    /// with 0 amount{0,1} and sending the donation amount(s) from the callback
    /// @param recipient The address which will receive the token0 and token1 amounts
    /// @param amount0 The amount of token0 to send
    /// @param amount1 The amount of token1 to send
    /// @param data Any data to be passed through to the callback
    function flash(
        address recipient,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;

    /// @notice Increase the maximum number of price and liquidity observations that this pool will store
    /// @dev This method is no-op if the pool already has an observationCardinalityNext greater than or equal to
    /// the input observationCardinalityNext.
    /// @param observationCardinalityNext The desired minimum number of observations for the pool to store
    function increaseObservationCardinalityNext(uint16 observationCardinalityNext) external;
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Events emitted by a pool
/// @notice Contains all events emitted by the pool
interface IUniswapV3PoolEvents {
    /// @notice Emitted exactly once by a pool when #initialize is first called on the pool
    /// @dev Mint/Burn/Swap cannot be emitted by the pool before Initialize
    /// @param sqrtPriceX96 The initial sqrt price of the pool, as a Q64.96
    /// @param tick The initial tick of the pool, i.e. log base 1.0001 of the starting price of the pool
    event Initialize(uint160 sqrtPriceX96, int24 tick);

    /// @notice Emitted when liquidity is minted for a given position
    /// @param sender The address that minted the liquidity
    /// @param owner The owner of the position and recipient of any minted liquidity
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity minted to the position range
    /// @param amount0 How much token0 was required for the minted liquidity
    /// @param amount1 How much token1 was required for the minted liquidity
    event Mint(
        address sender,
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted when fees are collected by the owner of a position
    /// @dev Collect events may be emitted with zero amount0 and amount1 when the caller chooses not to collect fees
    /// @param owner The owner of the position for which fees are collected
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount0 The amount of token0 fees collected
    /// @param amount1 The amount of token1 fees collected
    event Collect(
        address indexed owner,
        address recipient,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount0,
        uint128 amount1
    );

    /// @notice Emitted when a position's liquidity is removed
    /// @dev Does not withdraw any fees earned by the liquidity position, which must be withdrawn via #collect
    /// @param owner The owner of the position for which liquidity is removed
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity to remove
    /// @param amount0 The amount of token0 withdrawn
    /// @param amount1 The amount of token1 withdrawn
    event Burn(
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted by the pool for any swaps between token0 and token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the output of the swap
    /// @param amount0 The delta of the token0 balance of the pool
    /// @param amount1 The delta of the token1 balance of the pool
    /// @param sqrtPriceX96 The sqrt(price) of the pool after the swap, as a Q64.96
    /// @param liquidity The liquidity of the pool after the swap
    /// @param tick The log base 1.0001 of price of the pool after the swap
    event Swap(
        address indexed sender,
        address indexed recipient,
        int256 amount0,
        int256 amount1,
        uint160 sqrtPriceX96,
        uint128 liquidity,
        int24 tick
    );

    /// @notice Emitted by the pool for any flashes of token0/token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the tokens from flash
    /// @param amount0 The amount of token0 that was flashed
    /// @param amount1 The amount of token1 that was flashed
    /// @param paid0 The amount of token0 paid for the flash, which can exceed the amount0 plus the fee
    /// @param paid1 The amount of token1 paid for the flash, which can exceed the amount1 plus the fee
    event Flash(
        address indexed sender,
        address indexed recipient,
        uint256 amount0,
        uint256 amount1,
        uint256 paid0,
        uint256 paid1
    );

    /// @notice Emitted by the pool for increases to the number of observations that can be stored
    /// @dev observationCardinalityNext is not the observation cardinality until an observation is written at the index
    /// just before a mint/swap/burn.
    /// @param observationCardinalityNextOld The previous value of the next observation cardinality
    /// @param observationCardinalityNextNew The updated value of the next observation cardinality
    event IncreaseObservationCardinalityNext(
        uint16 observationCardinalityNextOld,
        uint16 observationCardinalityNextNew
    );

    /// @notice Emitted when the protocol fee is changed by the pool
    /// @param feeProtocol0Old The previous value of the token0 protocol fee
    /// @param feeProtocol1Old The previous value of the token1 protocol fee
    /// @param feeProtocol0New The updated value of the token0 protocol fee
    /// @param feeProtocol1New The updated value of the token1 protocol fee
    event SetFeeProtocol(uint8 feeProtocol0Old, uint8 feeProtocol1Old, uint8 feeProtocol0New, uint8 feeProtocol1New);

    /// @notice Emitted when the collected protocol fees are withdrawn by the factory owner
    /// @param sender The address that collects the protocol fees
    /// @param recipient The address that receives the collected protocol fees
    /// @param amount0 The amount of token0 protocol fees that is withdrawn
    /// @param amount0 The amount of token1 protocol fees that is withdrawn
    event CollectProtocol(address indexed sender, address indexed recipient, uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that never changes
/// @notice These parameters are fixed for a pool forever, i.e., the methods will always return the same values
interface IUniswapV3PoolImmutables {
    /// @notice The contract that deployed the pool, which must adhere to the IUniswapV3Factory interface
    /// @return The contract address
    function factory() external view returns (address);

    /// @notice The first of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token0() external view returns (address);

    /// @notice The second of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token1() external view returns (address);

    /// @notice The pool's fee in hundredths of a bip, i.e. 1e-6
    /// @return The fee
    function fee() external view returns (uint24);

    /// @notice The pool tick spacing
    /// @dev Ticks can only be used at multiples of this value, minimum of 1 and always positive
    /// e.g.: a tickSpacing of 3 means ticks can be initialized every 3rd tick, i.e., ..., -6, -3, 0, 3, 6, ...
    /// This value is an int24 to avoid casting even though it is always positive.
    /// @return The tick spacing
    function tickSpacing() external view returns (int24);

    /// @notice The maximum amount of position liquidity that can use any tick in the range
    /// @dev This parameter is enforced per tick to prevent liquidity from overflowing a uint128 at any point, and
    /// also prevents out-of-range liquidity from being used to prevent adding in-range liquidity to a pool
    /// @return The max amount of liquidity per tick
    function maxLiquidityPerTick() external view returns (uint128);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissioned pool actions
/// @notice Contains pool methods that may only be called by the factory owner
interface IUniswapV3PoolOwnerActions {
    /// @notice Set the denominator of the protocol's % share of the fees
    /// @param feeProtocol0 new protocol fee for token0 of the pool
    /// @param feeProtocol1 new protocol fee for token1 of the pool
    function setFeeProtocol(uint8 feeProtocol0, uint8 feeProtocol1) external;

    /// @notice Collect the protocol fee accrued to the pool
    /// @param recipient The address to which collected protocol fees should be sent
    /// @param amount0Requested The maximum amount of token0 to send, can be 0 to collect fees in only token1
    /// @param amount1Requested The maximum amount of token1 to send, can be 0 to collect fees in only token0
    /// @return amount0 The protocol fee collected in token0
    /// @return amount1 The protocol fee collected in token1
    function collectProtocol(
        address recipient,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that can change
/// @notice These methods compose the pool's state, and can change with any frequency including multiple times
/// per transaction
interface IUniswapV3PoolState {
    /// @notice The 0th storage slot in the pool stores many values, and is exposed as a single method to save gas
    /// when accessed externally.
    /// @return sqrtPriceX96 The current price of the pool as a sqrt(token1/token0) Q64.96 value
    /// tick The current tick of the pool, i.e. according to the last tick transition that was run.
    /// This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(sqrtPriceX96) if the price is on a tick
    /// boundary.
    /// observationIndex The index of the last oracle observation that was written,
    /// observationCardinality The current maximum number of observations stored in the pool,
    /// observationCardinalityNext The next maximum number of observations, to be updated when the observation.
    /// feeProtocol The protocol fee for both tokens of the pool.
    /// Encoded as two 4 bit values, where the protocol fee of token1 is shifted 4 bits and the protocol fee of token0
    /// is the lower 4 bits. Used as the denominator of a fraction of the swap fee, e.g. 4 means 1/4th of the swap fee.
    /// unlocked Whether the pool is currently locked to reentrancy
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );

    /// @notice The fee growth as a Q128.128 fees of token0 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal0X128() external view returns (uint256);

    /// @notice The fee growth as a Q128.128 fees of token1 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal1X128() external view returns (uint256);

    /// @notice The amounts of token0 and token1 that are owed to the protocol
    /// @dev Protocol fees will never exceed uint128 max in either token
    function protocolFees() external view returns (uint128 token0, uint128 token1);

    /// @notice The currently in range liquidity available to the pool
    /// @dev This value has no relationship to the total liquidity across all ticks
    function liquidity() external view returns (uint128);

    /// @notice Look up information about a specific tick in the pool
    /// @param tick The tick to look up
    /// @return liquidityGross the total amount of position liquidity that uses the pool either as tick lower or
    /// tick upper,
    /// liquidityNet how much liquidity changes when the pool price crosses the tick,
    /// feeGrowthOutside0X128 the fee growth on the other side of the tick from the current tick in token0,
    /// feeGrowthOutside1X128 the fee growth on the other side of the tick from the current tick in token1,
    /// tickCumulativeOutside the cumulative tick value on the other side of the tick from the current tick
    /// secondsPerLiquidityOutsideX128 the seconds spent per liquidity on the other side of the tick from the current tick,
    /// secondsOutside the seconds spent on the other side of the tick from the current tick,
    /// initialized Set to true if the tick is initialized, i.e. liquidityGross is greater than 0, otherwise equal to false.
    /// Outside values can only be used if the tick is initialized, i.e. if liquidityGross is greater than 0.
    /// In addition, these values are only relative and must be used only in comparison to previous snapshots for
    /// a specific position.
    function ticks(int24 tick)
        external
        view
        returns (
            uint128 liquidityGross,
            int128 liquidityNet,
            uint256 feeGrowthOutside0X128,
            uint256 feeGrowthOutside1X128,
            int56 tickCumulativeOutside,
            uint160 secondsPerLiquidityOutsideX128,
            uint32 secondsOutside,
            bool initialized
        );

    /// @notice Returns 256 packed tick initialized boolean values. See TickBitmap for more information
    function tickBitmap(int16 wordPosition) external view returns (uint256);

    /// @notice Returns the information about a position by the position's key
    /// @param key The position's key is a hash of a preimage composed by the owner, tickLower and tickUpper
    /// @return _liquidity The amount of liquidity in the position,
    /// Returns feeGrowthInside0LastX128 fee growth of token0 inside the tick range as of the last mint/burn/poke,
    /// Returns feeGrowthInside1LastX128 fee growth of token1 inside the tick range as of the last mint/burn/poke,
    /// Returns tokensOwed0 the computed amount of token0 owed to the position as of the last mint/burn/poke,
    /// Returns tokensOwed1 the computed amount of token1 owed to the position as of the last mint/burn/poke
    function positions(bytes32 key)
        external
        view
        returns (
            uint128 _liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    /// @notice Returns data about a specific observation index
    /// @param index The element of the observations array to fetch
    /// @dev You most likely want to use #observe() instead of this method to get an observation as of some amount of time
    /// ago, rather than at a specific index in the array.
    /// @return blockTimestamp The timestamp of the observation,
    /// Returns tickCumulative the tick multiplied by seconds elapsed for the life of the pool as of the observation timestamp,
    /// Returns secondsPerLiquidityCumulativeX128 the seconds per in range liquidity for the life of the pool as of the observation timestamp,
    /// Returns initialized whether the observation has been initialized and the values are safe to use
    function observations(uint256 index)
        external
        view
        returns (
            uint32 blockTimestamp,
            int56 tickCumulative,
            uint160 secondsPerLiquidityCumulativeX128,
            bool initialized
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Safe casting methods
/// @notice Contains methods for safely casting between types
library SafeCast {
    /// @notice Cast a uint256 to a uint160, revert on overflow
    /// @param y The uint256 to be downcasted
    /// @return z The downcasted integer, now type uint160
    function toUint160(uint256 y) internal pure returns (uint160 z) {
        require((z = uint160(y)) == y);
    }

    /// @notice Cast a int256 to a int128, revert on overflow or underflow
    /// @param y The int256 to be downcasted
    /// @return z The downcasted integer, now type int128
    function toInt128(int256 y) internal pure returns (int128 z) {
        require((z = int128(y)) == y);
    }

    /// @notice Cast a uint256 to a int256, revert on overflow
    /// @param y The uint256 to be casted
    /// @return z The casted integer, now type int256
    function toInt256(uint256 y) internal pure returns (int256 z) {
        require(y < 2**255);
        z = int256(y);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {ERC721} from "solmate/tokens/ERC721.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";

import {INFTEDA} from "./interfaces/INFTEDA.sol";
import {EDAPrice} from "./libraries/EDAPrice.sol";

abstract contract NFTEDA is INFTEDA {
    using SafeTransferLib for ERC20;

    error AuctionExists();
    error InvalidAuction();
    /// @param received The amount of payment received
    /// @param expected The expected payment amount
    error InsufficientPayment(uint256 received, uint256 expected);
    /// @param currentPrice The current auction price
    /// @param maxPrice The passed max price the purchaser is willing to pay
    error MaxPriceTooLow(uint256 currentPrice, uint256 maxPrice);

    /// @inheritdoc INFTEDA
    function auctionCurrentPrice(INFTEDA.Auction calldata auction) public view virtual returns (uint256) {
        uint256 id = auctionID(auction);
        uint256 startTime = auctionStartTime(id);
        if (startTime == 0) {
            revert InvalidAuction();
        }

        return _auctionCurrentPrice(id, startTime, auction);
    }

    /// @inheritdoc INFTEDA
    function auctionID(INFTEDA.Auction memory auction) public pure virtual returns (uint256) {
        return uint256(keccak256(abi.encode(auction)));
    }

    /// @inheritdoc INFTEDA
    function auctionStartTime(uint256 id) public view virtual returns (uint256);

    /// @notice Creates an auction defined by the passed `auction`
    /// @dev assumes the nft being sold is already controlled by the auction contract
    /// @dev does no validation the auction, aside that it does not exist.
    /// @dev if paymentAsset = address(0), purchase will not revert
    /// @param auction The defintion of the auction
    /// @return id the id of the auction
    function _startAuction(INFTEDA.Auction memory auction) internal virtual returns (uint256 id) {
        id = auctionID(auction);

        if (auctionStartTime(id) != 0) {
            revert AuctionExists();
        }

        _setAuctionStartTime(id);

        emit StartAuction(
            id,
            auction.auctionAssetID,
            auction.auctionAssetContract,
            auction.nftOwner,
            auction.perPeriodDecayPercentWad,
            auction.secondsInPeriod,
            auction.startPrice,
            auction.paymentAsset
            );
    }

    /// @notice purchases the NFT being sold in `auction`, reverts if current auction price exceed maxPrice
    /// @param auction The auction selling the NFT
    /// @param maxPrice The maximum the caller is willing to pay
    function _purchaseNFT(INFTEDA.Auction memory auction, uint256 maxPrice, address sendTo)
        internal
        virtual
        returns (uint256 startTime, uint256 price)
    {
        uint256 id = auctionID(auction);
        startTime = auctionStartTime(id);

        if (startTime == 0) {
            revert InvalidAuction();
        }
        price = _auctionCurrentPrice(id, startTime, auction);

        if (price > maxPrice) {
            revert MaxPriceTooLow(price, maxPrice);
        }

        _clearAuctionState(id);

        auction.auctionAssetContract.safeTransferFrom(address(this), sendTo, auction.auctionAssetID);

        auction.paymentAsset.safeTransferFrom(msg.sender, address(this), price);

        emit EndAuction(id, price);
    }

    /// @notice Sets the time at which the auction was started
    /// @dev abstracted to a function to allow developer some freedom with how to store auction state
    /// @param id The id of the auction
    function _setAuctionStartTime(uint256 id) internal virtual;

    /// @notice Clears all stored state for the auction
    /// @dev abstracted to a function to allow developer some freedom with how to store auction state
    /// @param id The id of the auction
    function _clearAuctionState(uint256 id) internal virtual;

    /// @notice Returns the current price of the passed auction, reverts if no such auction exists
    /// @dev startTime is passed, optimized for cases where the auctionId has already been computed
    /// @dev and startTime looked it up
    /// @param id The ID of the auction
    /// @param startTime The start time of the auction
    /// @param auction The auction for which the caller wants to know the current price
    /// @return price the current amount required to purchase the NFT being sold in this auction
    function _auctionCurrentPrice(uint256 id, uint256 startTime, INFTEDA.Auction memory auction)
        internal
        view
        virtual
        returns (uint256)
    {
        return EDAPrice.currentPrice(
            auction.startPrice, block.timestamp - startTime, auction.secondsInPeriod, auction.perPeriodDecayPercentWad
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";

import {INFTEDA} from "../interfaces/INFTEDA.sol";
import {NFTEDA} from "../NFTEDA.sol";

contract NFTEDAStarterIncentive is NFTEDA {
    struct AuctionState {
        /// @dev the time the auction started
        uint96 startTime;
        /// @dev who called to start the auction
        address starter;
    }

    /// @notice emitted when auction creator discount is set
    /// @param discount the new auction creator discount
    /// expressed as a percent scaled by 1e18
    /// i.e. 1e18 = 100%
    event SetAuctionCreatorDiscount(uint256 discount);

    /// @notice The percent discount the creator of an auction should
    /// receive, compared to the current price
    /// 1e18 = 100%
    uint256 public auctionCreatorDiscountPercentWad;
    uint256 internal _pricePercentAfterDiscount;

    /// @notice returns the auction state for a given auctionID
    /// @dev auctionID => AuctionState
    mapping(uint256 => AuctionState) public auctionState;

    constructor(uint256 _auctionCreatorDiscountPercentWad) {
        _setCreatorDiscount(_auctionCreatorDiscountPercentWad);
    }

    /// @inheritdoc INFTEDA
    function auctionStartTime(uint256 id) public view virtual override returns (uint256) {
        return auctionState[id].startTime;
    }

    /// @inheritdoc NFTEDA
    function _setAuctionStartTime(uint256 id) internal virtual override {
        auctionState[id] = AuctionState({startTime: uint96(block.timestamp), starter: msg.sender});
    }

    /// @inheritdoc NFTEDA
    function _clearAuctionState(uint256 id) internal virtual override {
        delete auctionState[id];
    }

    /// @inheritdoc NFTEDA
    function _auctionCurrentPrice(uint256 id, uint256 startTime, INFTEDA.Auction memory auction)
        internal
        view
        virtual
        override
        returns (uint256)
    {
        uint256 price = super._auctionCurrentPrice(id, startTime, auction);

        if (msg.sender == auctionState[id].starter) {
            price = FixedPointMathLib.mulWadUp(price, _pricePercentAfterDiscount);
        }

        return price;
    }

    /// @notice sets the discount offered to auction creators
    /// @param _auctionCreatorDiscountPercentWad the percent off the spot auction price the creator will be offered
    /// scaled by 1e18, i.e. 1e18 = 1 = 100%
    function _setCreatorDiscount(uint256 _auctionCreatorDiscountPercentWad) internal virtual {
        auctionCreatorDiscountPercentWad = _auctionCreatorDiscountPercentWad;
        _pricePercentAfterDiscount = FixedPointMathLib.WAD - _auctionCreatorDiscountPercentWad;

        emit SetAuctionCreatorDiscount(_auctionCreatorDiscountPercentWad);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {ERC721} from "solmate/tokens/ERC721.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";

interface INFTEDA {
    /// @notice struct containing all auction info
    /// @dev this struct is never stored, only a hash of it
    struct Auction {
        // the nft owner
        address nftOwner;
        // the nft token id
        uint256 auctionAssetID;
        // the nft contract address
        ERC721 auctionAssetContract;
        // How much the auction price will decay in each period
        // expressed as percent scaled by 1e18, i.e. 1e18 = 100%
        uint256 perPeriodDecayPercentWad;
        // the number of seconds in the period over which perPeriodDecay occurs
        uint256 secondsInPeriod;
        // the auction start price
        uint256 startPrice;
        // the payment asset and quote asset for startPrice
        ERC20 paymentAsset;
    }

    /// @notice emitted when an auction is started
    /// @param auctionID the id of the auction that was started
    /// @param auctionAssetID the token id of the ERC721 asset being auctioned
    /// @param auctionAssetContract the contract address of the ERC721 asset being auctioned
    /// @param nftOwner the owner of the ERC721 asset being auctioned
    /// @param perPeriodDecayPercentWad How much the auction price will decay in each period
    /// @param secondsInPeriod the number of seconds in the period over which perPeriodDecay occurs
    /// @param startPrice the starting price of the auction
    /// @param paymentAsset the payment asset and quote asset for startPrice
    event StartAuction(
        uint256 indexed auctionID,
        uint256 indexed auctionAssetID,
        ERC721 indexed auctionAssetContract,
        address nftOwner,
        uint256 perPeriodDecayPercentWad,
        uint256 secondsInPeriod,
        uint256 startPrice,
        ERC20 paymentAsset
    );

    /// @param auctionID the id of the auction that has ended
    /// @param price the price that the purchaser paid to receive the ERC721 asset being auctioned
    event EndAuction(uint256 indexed auctionID, uint256 price);

    /// @notice Returns the current price of the passed auction, reverts if no such auction exists
    /// @param auction The auction for which the caller wants to know the current price
    /// @return price the current amount required to purchase the NFT being sold in this auction
    function auctionCurrentPrice(Auction calldata auction) external view returns (uint256);

    /// @notice Returns a uint256 used to identify the auction
    /// @dev Derived from the auction. Identitical auctions cannot exist simultaneously
    /// @param auction The auction to get an ID for
    /// @return id the id of this auction
    function auctionID(Auction memory auction) external pure returns (uint256);

    /// @notice Returns the time at which startAuction was most recently successfully called for the given auction id
    /// @param id The id of the auction
    function auctionStartTime(uint256 id) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";

library EDAPrice {
    /// @notice returns the current price of an exponential price decay auction defined by the passed params
    /// @dev reverts if perPeriodDecayPercentWad >= 1e18
    /// @dev reverts if uint256 secondsInPeriod = 0
    /// @dev reverts if startPrice * multiplier overflows
    /// @dev reverts if lnWad(percentWadRemainingPerPeriod) * ratio) overflows
    /// @param startPrice the starting price of the auction
    /// @param secondsElapsed the seconds elapsed since auction start
    /// @param secondsInPeriod the seconds over which the price should decay perPeriodDecayPercentWad
    /// @param perPeriodDecayPercentWad the percent the price should decay during secondsInPeriod, 100% = 1e18
    /// @return price the current auction price
    function currentPrice(
        uint256 startPrice,
        uint256 secondsElapsed,
        uint256 secondsInPeriod,
        uint256 perPeriodDecayPercentWad
    ) internal pure returns (uint256) {
        uint256 ratio = FixedPointMathLib.divWadDown(secondsElapsed, secondsInPeriod);
        uint256 percentWadRemainingPerPeriod = FixedPointMathLib.WAD - perPeriodDecayPercentWad;
        // percentWadRemainingPerPeriod can be safely cast because < 1e18
        // ratio can be safely cast because will not overflow unless ratio > int256.max,
        // which would require secondsElapsed > int256.max, i.e. > 5.78e76 or 1.8e69 years
        int256 multiplier = FixedPointMathLib.powWad(int256(percentWadRemainingPerPeriod), int256(ratio));
        // casting to uint256 is safe because percentWadRemainingPerPeriod is non negative
        uint256 price = startPrice * uint256(multiplier);
        return (price / FixedPointMathLib.WAD);
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.17;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {ERC721, ERC721TokenReceiver} from "solmate/tokens/ERC721.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";
import {INFTEDA, NFTEDAStarterIncentive} from "./NFTEDA/extensions/NFTEDAStarterIncentive.sol";
import {Ownable2Step} from "openzeppelin-contracts/access/Ownable2Step.sol";
import {Multicallable} from "solady/utils/Multicallable.sol";

import {PaprToken} from "./PaprToken.sol";
import {UniswapOracleFundingRateController} from "./UniswapOracleFundingRateController.sol";
import {ReservoirOracleUnderwriter} from "./ReservoirOracleUnderwriter.sol";
import {IPaprController} from "./interfaces/IPaprController.sol";
import {UniswapHelpers} from "./libraries/UniswapHelpers.sol";

contract PaprController is
    IPaprController,
    UniswapOracleFundingRateController,
    ERC721TokenReceiver,
    Multicallable,
    Ownable2Step,
    ReservoirOracleUnderwriter,
    NFTEDAStarterIncentive
{
    using SafeTransferLib for ERC20;

    /// @dev what 1 = 100% is in basis points (bips)
    uint256 public constant BIPS_ONE = 1e4;

    bool public override liquidationsLocked;

    /// @inheritdoc IPaprController
    bool public immutable override token0IsUnderlying;

    /// @inheritdoc IPaprController
    uint256 public immutable override maxLTV;

    /// @inheritdoc IPaprController
    uint256 public immutable override liquidationAuctionMinSpacing = 2 days;

    /// @inheritdoc IPaprController
    uint256 public immutable override perPeriodAuctionDecayWAD = 0.7e18;

    /// @inheritdoc IPaprController
    uint256 public immutable override auctionDecayPeriod = 1 days;

    /// @inheritdoc IPaprController
    uint256 public immutable override auctionStartPriceMultiplier = 3;

    /// @inheritdoc IPaprController
    /// @dev Set to 10%
    uint256 public immutable override liquidationPenaltyBips = 1000;

    /// @inheritdoc IPaprController
    mapping(ERC721 => mapping(uint256 => address)) public override collateralOwner;

    /// @inheritdoc IPaprController
    mapping(ERC721 => bool) public override isAllowed;

    /// @dev account => asset => vaultInfo
    mapping(address => mapping(ERC721 => IPaprController.VaultInfo)) private _vaultInfo;

    /// @dev does not validate args
    /// e.g. does not check whether underlying or oracleSigner are address(0)
    constructor(
        string memory name,
        string memory symbol,
        uint256 _maxLTV,
        uint256 indexMarkRatioMax,
        uint256 indexMarkRatioMin,
        ERC20 underlying,
        address oracleSigner
    )
        NFTEDAStarterIncentive(1e17)
        UniswapOracleFundingRateController(underlying, new PaprToken(name, symbol), indexMarkRatioMax, indexMarkRatioMin)
        ReservoirOracleUnderwriter(oracleSigner, address(underlying))
    {
        maxLTV = _maxLTV;
        token0IsUnderlying = address(underlying) < address(papr);
        uint256 underlyingONE = 10 ** underlying.decimals();
        uint160 initSqrtRatio;

        // initialize the pool at 1:1
        if (token0IsUnderlying) {
            initSqrtRatio = UniswapHelpers.oneToOneSqrtRatio(underlyingONE, 1e18);
        } else {
            initSqrtRatio = UniswapHelpers.oneToOneSqrtRatio(1e18, underlyingONE);
        }

        address _pool = UniswapHelpers.deployAndInitPool(address(underlying), address(papr), 10000, initSqrtRatio);

        _init(underlyingONE, _pool);
    }

    /// @inheritdoc IPaprController
    function addCollateral(IPaprController.Collateral[] calldata collateralArr) external override {
        for (uint256 i = 0; i < collateralArr.length;) {
            _addCollateralToVault(msg.sender, collateralArr[i]);
            collateralArr[i].addr.transferFrom(msg.sender, address(this), collateralArr[i].id);
            unchecked {
                ++i;
            }
        }
    }

    /// @inheritdoc IPaprController
    function removeCollateral(
        address sendTo,
        IPaprController.Collateral[] calldata collateralArr,
        ReservoirOracleUnderwriter.OracleInfo calldata oracleInfo
    ) external override {
        uint256 cachedTarget = updateTarget();
        uint256 oraclePrice;
        ERC721 collateralAddr;

        for (uint256 i = 0; i < collateralArr.length;) {
            if (i == 0) {
                collateralAddr = collateralArr[i].addr;
                oraclePrice =
                    underwritePriceForCollateral(collateralAddr, ReservoirOracleUnderwriter.PriceKind.LOWER, oracleInfo);
            } else {
                if (collateralAddr != collateralArr[i].addr) {
                    revert CollateralAddressesDoNotMatch();
                }
            }

            _removeCollateral(sendTo, collateralArr[i], oraclePrice, cachedTarget);

            unchecked {
                ++i;
            }
        }
    }

    /// @inheritdoc IPaprController
    function increaseDebt(
        address mintTo,
        ERC721 asset,
        uint256 amount,
        ReservoirOracleUnderwriter.OracleInfo calldata oracleInfo
    ) external override {
        _increaseDebt({account: msg.sender, asset: asset, mintTo: mintTo, amount: amount, oracleInfo: oracleInfo});
    }

    /// @inheritdoc IPaprController
    function reduceDebt(address account, ERC721 asset, uint256 amount) external override {
        uint256 debt = _vaultInfo[account][asset].debt;
        _reduceDebt({
            account: account,
            asset: asset,
            burnFrom: msg.sender,
            accountDebt: debt,
            amountToReduce: amount > debt ? debt : amount
        });
    }

    /// @notice Handler for safeTransferFrom of an NFT
    /// @dev Should be preferred to `addCollateral` if only one NFT is being added
    /// to avoid approval call and save gas
    /// @param from the current owner of the nft
    /// @param _id the id of the NFT
    /// @param data encoded IPaprController.OnERC721ReceivedArgs
    /// @return selector indicating succesful receiving of the NFT
    function onERC721Received(address, address from, uint256 _id, bytes calldata data)
        external
        override
        returns (bytes4)
    {
        IPaprController.OnERC721ReceivedArgs memory request = abi.decode(data, (IPaprController.OnERC721ReceivedArgs));

        IPaprController.Collateral memory collateral = IPaprController.Collateral(ERC721(msg.sender), _id);

        _addCollateralToVault(from, collateral);

        if (request.swapParams.minOut > 0) {
            _increaseDebtAndSell(from, request.proceedsTo, ERC721(msg.sender), request.swapParams, request.oracleInfo);
        } else if (request.debt > 0) {
            _increaseDebt(from, collateral.addr, request.proceedsTo, request.debt, request.oracleInfo);
        }

        return ERC721TokenReceiver.onERC721Received.selector;
    }

    /// CONVENIENCE SWAP FUNCTIONS ///

    /// @inheritdoc IPaprController
    function increaseDebtAndSell(
        address proceedsTo,
        ERC721 collateralAsset,
        IPaprController.SwapParams calldata params,
        ReservoirOracleUnderwriter.OracleInfo calldata oracleInfo
    ) external override returns (uint256 amountOut) {
        bool hasFee = params.swapFeeBips != 0;

        (amountOut,) = UniswapHelpers.swap(
            pool,
            hasFee ? address(this) : proceedsTo,
            !token0IsUnderlying,
            params.amount,
            params.minOut,
            params.sqrtPriceLimitX96,
            params.deadline,
            abi.encode(msg.sender, collateralAsset, oracleInfo)
        );

        if (hasFee) {
            uint256 fee = amountOut * params.swapFeeBips / BIPS_ONE;
            underlying.safeTransfer(params.swapFeeTo, fee);
            underlying.safeTransfer(proceedsTo, amountOut - fee);
        }
    }

    /// @inheritdoc IPaprController
    function buyAndReduceDebt(address account, ERC721 collateralAsset, IPaprController.SwapParams calldata params)
        external
        override
        returns (uint256)
    {
        bool hasFee = params.swapFeeBips != 0;

        (uint256 amountOut, uint256 amountIn) = UniswapHelpers.swap(
            pool,
            msg.sender,
            token0IsUnderlying,
            params.amount,
            params.minOut,
            params.sqrtPriceLimitX96,
            params.deadline,
            abi.encode(msg.sender)
        );

        if (hasFee) {
            underlying.safeTransferFrom(msg.sender, params.swapFeeTo, amountIn * params.swapFeeBips / BIPS_ONE);
        }

        uint256 debt = _vaultInfo[account][collateralAsset].debt;
        _reduceDebt({
            account: account,
            asset: collateralAsset,
            burnFrom: msg.sender,
            accountDebt: debt,
            amountToReduce: amountOut > debt ? debt : amountOut
        });

        return amountOut;
    }

    function uniswapV3SwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata _data) external {
        if (msg.sender != address(pool)) {
            revert("wrong caller");
        }

        bool isUnderlyingIn;
        uint256 amountToPay;
        if (amount0Delta > 0) {
            amountToPay = uint256(amount0Delta);
            isUnderlyingIn = token0IsUnderlying;
        } else {
            require(amount1Delta > 0); // swaps entirely within 0-liquidity regions are not supported

            amountToPay = uint256(amount1Delta);
            isUnderlyingIn = !(token0IsUnderlying);
        }

        if (isUnderlyingIn) {
            address payer = abi.decode(_data, (address));
            underlying.safeTransferFrom(payer, msg.sender, amountToPay);
        } else {
            (address account, ERC721 asset, ReservoirOracleUnderwriter.OracleInfo memory oracleInfo) =
                abi.decode(_data, (address, ERC721, ReservoirOracleUnderwriter.OracleInfo));
            _increaseDebt(account, asset, msg.sender, amountToPay, oracleInfo);
        }
    }

    /// LIQUIDATION AUCTION FUNCTIONS ///

    /// @inheritdoc IPaprController
    function purchaseLiquidationAuctionNFT(
        Auction calldata auction,
        uint256 maxPrice,
        address sendTo,
        ReservoirOracleUnderwriter.OracleInfo calldata oracleInfo
    ) external override {
        uint256 price = _purchaseNFTAndUpdateVaultIfNeeded(auction, maxPrice, sendTo);
        --_vaultInfo[auction.nftOwner][auction.auctionAssetContract].auctionCount;

        uint256 count = _vaultInfo[auction.nftOwner][auction.auctionAssetContract].count;
        uint256 collateralValueCached;

        if (count != 0) {
            collateralValueCached = underwritePriceForCollateral(
                auction.auctionAssetContract, ReservoirOracleUnderwriter.PriceKind.TWAP, oracleInfo
            ) * count;
        }

        uint256 debtCached = _vaultInfo[auction.nftOwner][auction.auctionAssetContract].debt;
        uint256 maxDebtCached = count == 0 ? 0 : _maxDebt(collateralValueCached, updateTarget());
        /// anything above what is needed to bring this vault under maxDebt is considered excess
        uint256 neededToSaveVault;
        uint256 excess;
        unchecked {
            neededToSaveVault = maxDebtCached > debtCached ? 0 : debtCached - maxDebtCached;
            excess = price > neededToSaveVault ? price - neededToSaveVault : 0;
        }
        uint256 remaining;

        if (excess > 0) {
            remaining = _handleExcess(excess, neededToSaveVault, debtCached, auction);
        } else {
            _reduceDebt(auction.nftOwner, auction.auctionAssetContract, address(this), debtCached, price);
            // no excess, so price <= neededToSaveVault, meaning debtCached >= price
            unchecked {
                remaining = debtCached - price;
            }
        }

        if (
            count == 0 && remaining != 0 && _vaultInfo[auction.nftOwner][auction.auctionAssetContract].auctionCount == 0
        ) {
            /// there will be debt left with no NFTs, set it to 0
            _reduceDebtWithoutBurn(auction.nftOwner, auction.auctionAssetContract, remaining, remaining);
        }
    }

    /// @inheritdoc IPaprController
    function startLiquidationAuction(
        address account,
        IPaprController.Collateral calldata collateral,
        ReservoirOracleUnderwriter.OracleInfo calldata oracleInfo
    ) external override returns (INFTEDA.Auction memory auction) {
        if (liquidationsLocked) {
            revert LiquidationsLocked();
        }

        uint256 cachedTarget = updateTarget();

        IPaprController.VaultInfo storage info = _vaultInfo[account][collateral.addr];

        // check collateral belongs to account
        if (collateralOwner[collateral.addr][collateral.id] != account) {
            revert IPaprController.InvalidCollateralAccountPair();
        }

        uint256 oraclePrice =
            underwritePriceForCollateral(collateral.addr, ReservoirOracleUnderwriter.PriceKind.TWAP, oracleInfo);
        if (!(info.debt > _maxDebt(oraclePrice * info.count, cachedTarget))) {
            revert IPaprController.NotLiquidatable();
        }

        if (block.timestamp - info.latestAuctionStartTime < liquidationAuctionMinSpacing) {
            revert IPaprController.MinAuctionSpacing();
        }

        info.latestAuctionStartTime = uint40(block.timestamp);
        --info.count;
        ++info.auctionCount;

        emit RemoveCollateral(account, collateral.addr, collateral.id);

        delete collateralOwner[collateral.addr][collateral.id];

        _startAuction(
            auction = Auction({
                nftOwner: account,
                auctionAssetID: collateral.id,
                auctionAssetContract: collateral.addr,
                perPeriodDecayPercentWad: perPeriodAuctionDecayWAD,
                secondsInPeriod: auctionDecayPeriod,
                // start price is frozen price * auctionStartPriceMultiplier,
                // converted to papr value at the current contract price
                startPrice: (oraclePrice * auctionStartPriceMultiplier) * FixedPointMathLib.WAD / cachedTarget,
                paymentAsset: papr
            })
        );
    }

    /// OWNER FUNCTIONS ///

    /// @inheritdoc IPaprController
    function setPool(address _pool) external override onlyOwner {
        _setPool(_pool);
        emit UpdatePool(_pool);
    }

    /// @inheritdoc IPaprController
    function setFundingPeriod(uint256 _fundingPeriod) external override onlyOwner {
        _setFundingPeriod(_fundingPeriod);
        emit UpdateFundingPeriod(_fundingPeriod);
    }

    /// @inheritdoc IPaprController
    function setLiquidationsLocked(bool locked) external override onlyOwner {
        liquidationsLocked = locked;
        emit UpdateLiquidationsLocked(locked);
    }

    /// @inheritdoc IPaprController
    function setAllowedCollateral(IPaprController.CollateralAllowedConfig[] calldata collateralConfigs)
        external
        override
        onlyOwner
    {
        for (uint256 i = 0; i < collateralConfigs.length;) {
            if (address(collateralConfigs[i].collateral) == address(0)) revert IPaprController.InvalidCollateral();

            isAllowed[collateralConfigs[i].collateral] = collateralConfigs[i].allowed;
            emit AllowCollateral(collateralConfigs[i].collateral, collateralConfigs[i].allowed);
            unchecked {
                ++i;
            }
        }
    }

    /// VIEW FUNCTIONS ///

    /// @inheritdoc IPaprController
    function maxDebt(uint256 totalCollateraValue) external view override returns (uint256) {
        if (_lastUpdated == block.timestamp) {
            return _maxDebt(totalCollateraValue, _target);
        }

        return _maxDebt(totalCollateraValue, newTarget());
    }

    /// @inheritdoc IPaprController
    function vaultInfo(address account, ERC721 asset)
        external
        view
        override
        returns (IPaprController.VaultInfo memory)
    {
        return _vaultInfo[account][asset];
    }

    /// INTERNAL NON-VIEW ///

    function _addCollateralToVault(address account, IPaprController.Collateral memory collateral) internal {
        if (!isAllowed[collateral.addr]) {
            revert IPaprController.InvalidCollateral();
        }

        collateralOwner[collateral.addr][collateral.id] = account;
        ++_vaultInfo[account][collateral.addr].count;

        emit AddCollateral(account, collateral.addr, collateral.id);
    }

    function _removeCollateral(
        address sendTo,
        IPaprController.Collateral calldata collateral,
        uint256 oraclePrice,
        uint256 cachedTarget
    ) internal {
        if (collateralOwner[collateral.addr][collateral.id] != msg.sender) {
            revert IPaprController.OnlyCollateralOwner();
        }

        delete collateralOwner[collateral.addr][collateral.id];

        uint16 newCount;
        unchecked {
            newCount = _vaultInfo[msg.sender][collateral.addr].count - 1;
            _vaultInfo[msg.sender][collateral.addr].count = newCount;
        }

        uint256 debt = _vaultInfo[msg.sender][collateral.addr].debt;
        uint256 max = _maxDebt(oraclePrice * newCount, cachedTarget);

        if (debt != 0 && !(debt < max)) {
            revert IPaprController.ExceedsMaxDebt(debt, max);
        }

        collateral.addr.safeTransferFrom(address(this), sendTo, collateral.id);

        emit RemoveCollateral(msg.sender, collateral.addr, collateral.id);
    }

    function _increaseDebt(
        address account,
        ERC721 asset,
        address mintTo,
        uint256 amount,
        ReservoirOracleUnderwriter.OracleInfo memory oracleInfo
    ) internal {
        if (!isAllowed[asset]) {
            revert IPaprController.InvalidCollateral();
        }

        uint256 cachedTarget = updateTarget();

        uint256 newDebt = _vaultInfo[account][asset].debt + amount;
        uint256 oraclePrice =
            underwritePriceForCollateral(asset, ReservoirOracleUnderwriter.PriceKind.LOWER, oracleInfo);

        uint256 max = _maxDebt(_vaultInfo[account][asset].count * oraclePrice, cachedTarget);

        if (!(newDebt < max)) revert IPaprController.ExceedsMaxDebt(newDebt, max);

        if (newDebt >= 1 << 184) revert IPaprController.DebtAmountExceedsUint184();

        _vaultInfo[account][asset].debt = uint184(newDebt);
        PaprToken(address(papr)).mint(mintTo, amount);

        emit IncreaseDebt(account, asset, amount);
    }

    function _reduceDebt(address account, ERC721 asset, address burnFrom, uint256 accountDebt, uint256 amountToReduce)
        internal
    {
        _reduceDebtWithoutBurn(account, asset, accountDebt, amountToReduce);
        PaprToken(address(papr)).burn(burnFrom, amountToReduce);
    }

    function _reduceDebtWithoutBurn(address account, ERC721 asset, uint256 accountDebt, uint256 amountToReduce)
        internal
    {
        _vaultInfo[account][asset].debt = uint184(accountDebt - amountToReduce);
        emit ReduceDebt(account, asset, amountToReduce);
    }

    /// same as increaseDebtAndSell but takes args in memory
    /// to work with onERC721Received
    function _increaseDebtAndSell(
        address account,
        address proceedsTo,
        ERC721 collateralAsset,
        IPaprController.SwapParams memory params,
        ReservoirOracleUnderwriter.OracleInfo memory oracleInfo
    ) internal {
        bool hasFee = params.swapFeeBips != 0;

        (uint256 amountOut,) = UniswapHelpers.swap(
            pool,
            hasFee ? address(this) : proceedsTo,
            !token0IsUnderlying,
            params.amount,
            params.minOut,
            params.sqrtPriceLimitX96,
            params.deadline,
            abi.encode(account, collateralAsset, oracleInfo)
        );

        if (hasFee) {
            uint256 fee = amountOut * params.swapFeeBips / BIPS_ONE;
            underlying.safeTransfer(params.swapFeeTo, fee);
            underlying.safeTransfer(proceedsTo, amountOut - fee);
        }
    }

    function _purchaseNFTAndUpdateVaultIfNeeded(Auction calldata auction, uint256 maxPrice, address sendTo)
        internal
        returns (uint256)
    {
        (uint256 startTime, uint256 price) = _purchaseNFT(auction, maxPrice, sendTo);

        if (startTime == _vaultInfo[auction.nftOwner][auction.auctionAssetContract].latestAuctionStartTime) {
            _vaultInfo[auction.nftOwner][auction.auctionAssetContract].latestAuctionStartTime = 0;
        }

        return price;
    }

    function _handleExcess(uint256 excess, uint256 neededToSaveVault, uint256 debtCached, Auction calldata auction)
        internal
        returns (uint256 remaining)
    {
        uint256 fee = excess * liquidationPenaltyBips / BIPS_ONE;
        uint256 credit;
        // excess is a % of fee and so is <= fee
        unchecked {
            credit = excess - fee;
        }
        uint256 totalOwed = credit + neededToSaveVault;

        PaprToken(address(papr)).burn(address(this), fee);

        if (totalOwed > debtCached) {
            // we owe them more papr than they have in debt
            // so we pay down debt and send them the rest
            _reduceDebt(auction.nftOwner, auction.auctionAssetContract, address(this), debtCached, debtCached);
            // totalOwed > debtCached
            unchecked {
                papr.transfer(auction.nftOwner, totalOwed - debtCached);
            }
        } else {
            // reduce vault debt
            _reduceDebt(auction.nftOwner, auction.auctionAssetContract, address(this), debtCached, totalOwed);
            // debtCached >= totalOwed
            unchecked {
                remaining = debtCached - totalOwed;
            }
        }
    }

    /// INTERNAL VIEW ///

    function _maxDebt(uint256 totalCollateraValue, uint256 cachedTarget) internal view returns (uint256) {
        uint256 maxLoanUnderlying = totalCollateraValue * maxLTV;
        return maxLoanUnderlying / cachedTarget;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import {ERC20} from "solmate/tokens/ERC20.sol";

contract PaprToken is ERC20 {
    error ControllerOnly();

    address immutable controller;

    modifier onlyController() {
        if (msg.sender != controller) {
            revert ControllerOnly();
        }
        _;
    }

    constructor(string memory name, string memory symbol)
        ERC20(string.concat("papr ", name), string.concat("papr", symbol), 18)
    {
        controller = msg.sender;
    }

    function mint(address to, uint256 amount) external onlyController {
        _mint(to, amount);
    }

    function burn(address account, uint256 amount) external onlyController {
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {ERC721} from "solmate/tokens/ERC721.sol";
import {ReservoirOracle} from "@reservoir/ReservoirOracle.sol";

contract ReservoirOracleUnderwriter {
    /// @notice The kind of floor price to use from the oracle
    /// @dev SPOT is the floor price at the time of the oracle message
    /// @dev TWAP is the average weighted floor price over the last TWAP_SECONDS
    /// @dev LOWER is the minimum of SPOT and TWAP
    /// @dev UPPER is the maximum of SPOT and TWAP
    /// @dev see https://docs.reservoir.tools/reference/getoraclecollectionstopbidv2 for more details
    enum PriceKind {
        SPOT,
        TWAP,
        LOWER,
        UPPER
    }

    /// @notice The signature of a message from our oracle signer
    struct Sig {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    /// @notice The message and signature from our oracle signer
    struct OracleInfo {
        ReservoirOracle.Message message;
        Sig sig;
    }

    /// @notice the amount of time to use for the TWAP
    uint256 constant TWAP_SECONDS = 7 days;

    /// @notice the maximum time a given signed oracle message is valid for
    uint256 constant VALID_FOR = 20 minutes;

    /// @dev constant values used in checking signatures
    bytes32 constant MESSAGE_SIG_HASH = keccak256("Message(bytes32 id,bytes payload,uint256 timestamp)");
    bytes32 constant TOP_BID_SIG_HASH =
        keccak256("ContractWideCollectionTopBidPrice(uint8 kind,uint256 twapSeconds,address contract)");

    /// @notice the signing address the contract expects from the oracle message
    address public immutable oracleSigner;

    /// @notice address of the currency we are receiving oracle prices in
    address public immutable quoteCurrency;

    error IncorrectOracleSigner();
    error WrongIdentifierFromOracleMessage();
    error WrongCurrencyFromOracleMessage();
    error OracleMessageTimestampInvalid();

    constructor(address _oracleSigner, address _quoteCurrency) {
        oracleSigner = _oracleSigner;
        quoteCurrency = _quoteCurrency;
    }

    /// @notice returns the price of an asset from a signed oracle message
    /// @param asset the address of the ERC721 asset to underwrite the price for
    /// @param priceKind the kind of price the function expects the oracle message to contain
    /// @param oracleInfo the message and signature from our oracle signer
    /// @return oraclePrice the price of the asset, expressed in quoteCurrency units
    /// @dev reverts if the signer of the oracle message is incorrect
    /// @dev reverts if the oracle message was signed longer than VALID_FOR ago
    /// @dev reverts if the oracle message is for the wrong ERC721 asset, wrong price kind, or wrong quote currency
    function underwritePriceForCollateral(ERC721 asset, PriceKind priceKind, OracleInfo memory oracleInfo)
        public
        view
        returns (uint256)
    {
        address signerAddress = ecrecover(
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    // EIP-712 structured-data hash
                    keccak256(
                        abi.encode(
                            MESSAGE_SIG_HASH,
                            oracleInfo.message.id,
                            keccak256(oracleInfo.message.payload),
                            oracleInfo.message.timestamp
                        )
                    )
                )
            ),
            oracleInfo.sig.v,
            oracleInfo.sig.r,
            oracleInfo.sig.s
        );

        if (signerAddress != oracleSigner) {
            revert IncorrectOracleSigner();
        }

        bytes32 expectedId = keccak256(abi.encode(TOP_BID_SIG_HASH, priceKind, TWAP_SECONDS, asset));

        if (oracleInfo.message.id != expectedId) {
            revert WrongIdentifierFromOracleMessage();
        }

        if (
            oracleInfo.message.timestamp > block.timestamp || oracleInfo.message.timestamp + VALID_FOR < block.timestamp
        ) {
            revert OracleMessageTimestampInvalid();
        }

        (address oracleQuoteCurrency, uint256 oraclePrice) = abi.decode(oracleInfo.message.payload, (address, uint256));
        if (oracleQuoteCurrency != quoteCurrency) {
            revert WrongCurrencyFromOracleMessage();
        }

        return oraclePrice;
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";
import {SafeCastLib} from "solmate/utils/SafeCastLib.sol";

import {OracleLibrary} from "./libraries/OracleLibrary.sol";
import {UniswapHelpers} from "./libraries/UniswapHelpers.sol";
import {
    IUniswapOracleFundingRateController,
    IFundingRateController
} from "./interfaces/IUniswapOracleFundingRateController.sol";

contract UniswapOracleFundingRateController is IUniswapOracleFundingRateController {
    /// @inheritdoc IFundingRateController
    ERC20 public immutable underlying;
    /// @inheritdoc IFundingRateController
    ERC20 public immutable papr;
    /// @inheritdoc IFundingRateController
    uint256 public fundingPeriod;
    /// @inheritdoc IUniswapOracleFundingRateController
    address public pool;
    /// @dev the max value of target / mark, used as a guard in _multiplier
    uint256 public immutable targetMarkRatioMax;
    /// @dev the min value of target / mark, used as a guard in _multiplier
    uint256 public immutable targetMarkRatioMin;
    // single slot, write together
    uint128 internal _target;
    int56 internal _lastCumulativeTick;
    uint48 internal _lastUpdated;
    int24 internal _lastTwapTick;

    constructor(ERC20 _underlying, ERC20 _papr, uint256 _targetMarkRatioMax, uint256 _targetMarkRatioMin) {
        underlying = _underlying;
        papr = _papr;

        targetMarkRatioMax = _targetMarkRatioMax;
        targetMarkRatioMin = _targetMarkRatioMin;

        _setFundingPeriod(4 weeks);
    }

    /// @inheritdoc IFundingRateController
    function updateTarget() public override returns (uint256 nTarget) {
        if (_lastUpdated == block.timestamp) {
            return _target;
        }

        (int56 latestCumulativeTick, int24 latestTwapTick) = _latestTwapTickAndTickCumulative();
        nTarget = _newTarget(latestTwapTick, _target);

        _target = SafeCastLib.safeCastTo128(nTarget);
        // will not overflow for 8000 years
        _lastUpdated = uint48(block.timestamp);
        _lastCumulativeTick = latestCumulativeTick;
        _lastTwapTick = latestTwapTick;

        emit UpdateTarget(nTarget);
    }

    /// @inheritdoc IFundingRateController
    function newTarget() public view override returns (uint256) {
        if (_lastUpdated == block.timestamp) {
            return _target;
        }
        (, int24 latestTwapTick) = _latestTwapTickAndTickCumulative();
        return _newTarget(latestTwapTick, _target);
    }

    /// @inheritdoc IFundingRateController
    function mark() public view returns (uint256) {
        if (_lastUpdated == block.timestamp) {
            return _mark(_lastTwapTick);
        }
        (, int24 latestTwapTick) = _latestTwapTickAndTickCumulative();
        return _mark(latestTwapTick);
    }

    /// @inheritdoc IFundingRateController
    function lastUpdated() external view override returns (uint256) {
        return _lastUpdated;
    }

    /// @inheritdoc IFundingRateController
    function target() external view override returns (uint256) {
        return _target;
    }

    /// @notice initializes the controller, setting pool and target
    /// @dev assumes pool is initialized, does not check that pool tokens
    /// match papr and underlying
    /// @param _target_ the start value of target
    /// @param _pool the pool address to use
    function _init(uint256 _target_, address _pool) internal {
        if (_lastUpdated != 0) revert AlreadyInitialized();

        _setPool(_pool);

        _lastUpdated = uint48(block.timestamp);
        _target = SafeCastLib.safeCastTo128(_target_);
        _lastCumulativeTick = OracleLibrary.latestCumulativeTick(pool);
        _lastTwapTick = UniswapHelpers.poolCurrentTick(pool);

        emit UpdateTarget(_target_);
    }

    /// @notice Updates `pool`
    /// @dev reverts if new pool does not have same token0 and token1 as `pool`
    /// @dev if pool = address(0), does NOT check that tokens match papr and underlying
    function _setPool(address _pool) internal {
        address currentPool = pool;
        if (currentPool != address(0) && !UniswapHelpers.poolsHaveSameTokens(currentPool, _pool)) {
            revert PoolTokensDoNotMatch();
        }
        if (!UniswapHelpers.isUniswapPool(_pool)) revert InvalidUniswapV3Pool();

        pool = _pool;

        emit SetPool(_pool);
    }

    /// @notice Updates fundingPeriod
    /// @dev reverts if period is longer than 90 days or less than 7
    function _setFundingPeriod(uint256 _fundingPeriod) internal {
        if (_fundingPeriod < 28 days) revert FundingPeriodTooShort();
        if (_fundingPeriod > 365 days) revert FundingPeriodTooLong();

        fundingPeriod = _fundingPeriod;

        emit SetFundingPeriod(_fundingPeriod);
    }

    /// @dev internal function to allow optimized SLOADs
    function _newTarget(int24 latestTwapTick, uint256 cachedTarget) internal view returns (uint256) {
        return FixedPointMathLib.mulWadDown(cachedTarget, _multiplier(_mark(latestTwapTick), cachedTarget));
    }

    /// @dev internal function to allow optimized SLOADs
    function _mark(int24 twapTick) internal view returns (uint256) {
        return OracleLibrary.getQuoteAtTick(twapTick, 1e18, address(papr), address(underlying));
    }

    /// @dev reverts if block.timestamp - _lastUpdated == 0
    function _latestTwapTickAndTickCumulative() internal view returns (int56 tickCumulative, int24 twapTick) {
        tickCumulative = OracleLibrary.latestCumulativeTick(pool);
        twapTick = OracleLibrary.timeWeightedAverageTick(
            _lastCumulativeTick, tickCumulative, int56(uint56(block.timestamp - _lastUpdated))
        );
    }

    /// @notice The multiplier to apply to target() to get newTarget()
    /// @dev Computes the funding rate for the time since _lastUpdated
    /// 1 = 1e18, i.e.
    /// > 1e18 means positive funding rate
    /// < 1e18 means negative funding rate
    /// sub 1e18 to get percent change
    /// @return multiplier used to obtain newTarget()
    function _multiplier(uint256 _mark_, uint256 cachedTarget) internal view returns (uint256) {
        uint256 period = block.timestamp - _lastUpdated;
        uint256 periodRatio = FixedPointMathLib.divWadDown(period, fundingPeriod);
        uint256 targetMarkRatio;
        if (_mark_ == 0) {
            targetMarkRatio = targetMarkRatioMax;
        } else {
            targetMarkRatio = FixedPointMathLib.divWadDown(cachedTarget, _mark_);
            if (targetMarkRatio > targetMarkRatioMax) {
                targetMarkRatio = targetMarkRatioMax;
            } else if (targetMarkRatio < targetMarkRatioMin) {
                targetMarkRatio = targetMarkRatioMin;
            }
        }

        // safe to cast because targetMarkRatio > 0
        return uint256(FixedPointMathLib.powWad(int256(targetMarkRatio), int256(periodRatio)));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {ERC20} from "solmate/tokens/ERC20.sol";

interface IFundingRateController {
    /// @notice emitted when target is updated
    /// @param newTarget the new target value
    event UpdateTarget(uint256 newTarget);

    event SetFundingPeriod(uint256 fundingPeriod);

    error AlreadyInitialized();
    error FundingPeriodTooShort();
    error FundingPeriodTooLong();

    /// @notice Updates target and returns new target
    /// @dev if block.timestamp == lastUpdated() then just returns target()
    /// @return Target the new target value
    function updateTarget() external returns (uint256);

    /// @notice The timestamp at which target was last updated
    /// @return lastUpdated the timestamp (in seconds) at which target was last updated
    function lastUpdated() external view returns (uint256);

    /// @notice The target value of one whole unit of papr in underlying units.
    /// @dev Target represents the 0% funding rate value. If mark() is equal to this
    /// value, then funding rates are 0 and newTarget() will equal target().
    /// @return target The value of one whole unit of papr in underlying units.
    /// Example: if papr has 18 decimals and underlying 6 decimals, then
    ///  target = 1e6 means 1e18 papr is worth 1e6 underlying, according to target
    function target() external view returns (uint256);

    /// @notice The value of new value of target() if updateTarget() were called right now
    /// @dev If mark() > target(), newTarget() will be less than target(), positive funding/negative interest
    /// @dev If mark() < target(), newTarget() will be greater than target(), negative funding/positive interest
    /// @return newTarget The up to date target value for this block
    function newTarget() external view returns (uint256);

    /// @notice The market value of a whole unit of papr in underlying units
    /// @return mark market papr price, quoted in underlying
    function mark() external view returns (uint256);

    /// @notice The papr token, the value of which is intended to
    /// reflect in-kind funding payments via target() changing in value
    /// @return papr the ERC20 token (address)
    function papr() external view returns (ERC20);

    /// @notice The underlying token that is used to quote the value of papr
    /// @return underlying the ERC20 token (address)
    function underlying() external view returns (ERC20);

    /// @notice The period over which funding is paid
    /// @dev a shorter funding period means volatility has a greater impact
    /// on funding => target, longer period means the inverse
    /// @return fundingPeriod in seconds over which funding is paid
    function fundingPeriod() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {ReservoirOracleUnderwriter} from "../ReservoirOracleUnderwriter.sol";
import {ERC721} from "solmate/tokens/ERC721.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {INFTEDA} from "../NFTEDA/extensions/NFTEDAStarterIncentive.sol";

interface IPaprController {
    /// @notice collateral for a vault
    struct Collateral {
        /// @dev address of the collateral, cast to ERC721
        ERC721 addr;
        /// @dev tokenId of the collateral
        uint256 id;
    }

    /// @notice vault information for a vault
    struct VaultInfo {
        /// @dev number of collateral tokens in the vault
        uint16 count;
        /// @dev number of auctions on going for this vault
        uint16 auctionCount;
        /// @dev start time of last auction the vault underwent, 0 if no auction has been started
        uint40 latestAuctionStartTime;
        /// @dev debt of the vault, expressed in papr token units
        uint184 debt;
    }

    /// @notice parameters describing a swap
    /// @dev increaseDebtAndSell has the input token as papr and output token as the underlying
    /// @dev buyAndReduceDebt has the input token as the underlying and output token as papr
    struct SwapParams {
        /// @dev amount of input token to swap
        uint256 amount;
        /// @dev minimum amount of output token to be received
        uint256 minOut;
        /// @dev sqrt price limit for the swap
        uint160 sqrtPriceLimitX96;
        /// @dev optional address to receive swap fees
        address swapFeeTo;
        /// @dev optional swap fee in bips
        uint256 swapFeeBips;
        /// @dev timestamp after which the swap should not be executed
        uint256 deadline;
    }

    /// @notice parameters to be encoded in safeTransferFrom collateral addition
    struct OnERC721ReceivedArgs {
        /// @dev address to send proceeds to if minting debt or swapping
        address proceedsTo;
        /// @dev debt is ignored in favor of `swapParams.amount` of minOut > 0
        uint256 debt;
        /// @dev optional swapParams
        SwapParams swapParams;
        /// @dev oracle information associated with collateral being sent
        ReservoirOracleUnderwriter.OracleInfo oracleInfo;
    }

    /// @notice parameters to change what collateral addresses can be used for a vault
    struct CollateralAllowedConfig {
        ERC721 collateral;
        bool allowed;
    }

    /// @notice emitted when an address increases the debt balance of their vault
    /// @param account address increasing their debt
    /// @param collateralAddress address of the collateral token
    /// @param amount amount of debt added
    /// @dev vaults are uniquely identified by the address of the vault owner and the address of the collateral token used in the vault
    event IncreaseDebt(address indexed account, ERC721 indexed collateralAddress, uint256 amount);

    /// @notice emitted when a user adds collateral to their vault
    /// @param account address adding collateral
    /// @param collateralAddress contract address of the ERC721 collateral added
    /// @param tokenId token id of the ERC721 collateral added
    event AddCollateral(address indexed account, ERC721 indexed collateralAddress, uint256 indexed tokenId);

    /// @notice emitted when a user removes collateral from their vault
    /// @param account address removing collateral
    /// @param collateralAddress contract address of the ERC721 collateral removed
    /// @param tokenId token id of the ERC721 collateral removed
    event RemoveCollateral(address indexed account, ERC721 indexed collateralAddress, uint256 indexed tokenId);

    /// @notice emitted when a user reduces the debt balance of their vault
    /// @param account address reducing their debt
    /// @param collateralAddress address of the collateral token
    /// @param amount amount of debt removed
    event ReduceDebt(address indexed account, ERC721 indexed collateralAddress, uint256 amount);

    /// @notice emitted when the owner sets whether a token address is allowed to serve as collateral for a vault
    /// @param collateral address of the collateral token
    /// @param isAllowed whether the collateral is allowed
    event AllowCollateral(ERC721 indexed collateral, bool isAllowed);

    /// @notice emitted when the owner sets a new funding period for the controller
    /// @param newPeriod new funding period that was set, in seconds
    event UpdateFundingPeriod(uint256 newPeriod);

    /// @notice emitted when the owner sets a new Uniswap V3 pool for the controller
    /// @param newPool address of the new Uniswap V3 pool that was set
    event UpdatePool(address indexed newPool);

    /// @notice emitted when the owner sets whether or not liquidations for the controller are locked
    /// @param locked whether or not the owner set liquidations to be locked or not
    event UpdateLiquidationsLocked(bool locked);

    /// @param vaultDebt how much debt the vault has
    /// @param maxDebt the max debt the vault is allowed to have
    error ExceedsMaxDebt(uint256 vaultDebt, uint256 maxDebt);

    error InvalidCollateral();

    error MinAuctionSpacing();

    error NotLiquidatable();

    error InvalidCollateralAccountPair();

    error AccountHasNoDebt();

    error OnlyCollateralOwner();

    error DebtAmountExceedsUint184();

    error CollateralAddressesDoNotMatch();

    error LiquidationsLocked();

    /// @notice adds collateral to msg.senders vault for collateral.addr
    /// @dev use safeTransferFrom to save gas if only sending one NFT
    /// @param collateral collateral to add
    function addCollateral(IPaprController.Collateral[] calldata collateral) external;

    /// @notice removes collateral from msg.senders vault
    /// @dev all collateral must be from same contract address
    /// @dev oracleInfo price must be type LOWER
    /// @param sendTo address to send the collateral to when removed
    /// @param collateralArr array of IPaprController.Collateral to be removed
    /// @param oracleInfo oracle information for the collateral being removed
    function removeCollateral(
        address sendTo,
        IPaprController.Collateral[] calldata collateralArr,
        ReservoirOracleUnderwriter.OracleInfo calldata oracleInfo
    ) external;

    /// @notice increases debt balance of the vault uniquely identified by msg.sender and the collateral address
    /// @dev oracleInfo price must be type LOWER
    /// @param mintTo address to mint the debt to
    /// @param asset address of the collateral token used to mint the debt
    /// @param amount amount of debt to mint
    /// @param oracleInfo oracle information for the collateral being used to mint debt
    function increaseDebt(
        address mintTo,
        ERC721 asset,
        uint256 amount,
        ReservoirOracleUnderwriter.OracleInfo calldata oracleInfo
    ) external;

    /// @notice removes and burns debt from the vault uniquely identified by account and the collateral address
    /// @param account address reducing their debt
    /// @param asset address of the collateral token the user would like to remove debt from
    /// @param amount amount of debt to remove
    function reduceDebt(address account, ERC721 asset, uint256 amount) external;

    /// @notice mints debt and swaps the debt for the controller's underlying token on Uniswap
    /// @dev oracleInfo price must be type LOWER
    /// @param proceedsTo address to send the proceeds to
    /// @param collateralAsset address of the collateral token used to mint the debt
    /// @param params parameters for the swap
    /// @param oracleInfo oracle information for the collateral being used to mint debt
    /// @return amount amount of underlying token received by the user
    function increaseDebtAndSell(
        address proceedsTo,
        ERC721 collateralAsset,
        IPaprController.SwapParams calldata params,
        ReservoirOracleUnderwriter.OracleInfo calldata oracleInfo
    ) external returns (uint256);

    /// @notice removes debt from a vault and burns it by swapping the controller's underlying token for Papr tokens using the Uniswap V3 pool
    /// @param account address reducing their debt
    /// @param collateralAsset address of the collateral token the user would like to remove debt from
    /// @param params parameters for the swap
    /// @return amount amount of debt received from the swap and burned
    function buyAndReduceDebt(address account, ERC721 collateralAsset, IPaprController.SwapParams calldata params)
        external
        returns (uint256);

    /// @notice purchases a liquidation auction with the controller's papr token
    /// @dev oracleInfo price must be type TWAP
    /// @param auction auction to purchase
    /// @param maxPrice maximum price to pay for the auction
    /// @param sendTo address to send the collateral to if auction is won
    function purchaseLiquidationAuctionNFT(
        INFTEDA.Auction calldata auction,
        uint256 maxPrice,
        address sendTo,
        ReservoirOracleUnderwriter.OracleInfo calldata oracleInfo
    ) external;

    /// @notice starts a liquidation auction for a vault if it is liquidatable
    /// @dev oracleInfo price must be type TWAP
    /// @param account address of the user who's vault to liquidate
    /// @param collateral collateral to liquidate
    /// @param oracleInfo oracle information for the collateral being liquidated
    /// @return auction auction that was started
    function startLiquidationAuction(
        address account,
        IPaprController.Collateral calldata collateral,
        ReservoirOracleUnderwriter.OracleInfo calldata oracleInfo
    ) external returns (INFTEDA.Auction memory auction);

    /// @notice sets the Uniswap V3 pool that is used to determine mark
    /// @dev owner function
    /// @param _pool address of the Uniswap V3 pool
    function setPool(address _pool) external;

    /// @notice sets the funding period for interest payments
    /// @param _fundingPeriod new funding period in seconds
    function setFundingPeriod(uint256 _fundingPeriod) external;

    /// @notice sets value of liquidationsLocked
    /// @dev owner function for use in emergencies
    /// @param locked new value for liquidationsLocked
    function setLiquidationsLocked(bool locked) external;

    /// @notice sets whether a collateral is allowed to be used to mint debt
    /// @dev owner function
    /// @param collateralConfigs configuration settings indicating whether a collateral is allowed or not
    function setAllowedCollateral(IPaprController.CollateralAllowedConfig[] calldata collateralConfigs) external;

    /// @notice returns who owns a collateral token in a vault
    /// @param collateral address of the collateral
    /// @param tokenId tokenId of the collateral
    function collateralOwner(ERC721 collateral, uint256 tokenId) external view returns (address);

    /// @notice returns whether a token address is allowed to serve as collateral for a vault
    /// @param collateral address of the collateral token
    function isAllowed(ERC721 collateral) external view returns (bool);

    /// @notice if liquidations are currently locked, meaning startLiquidationAuciton will revert
    /// @dev for use in case of emergencies
    /// @return liquidationsLocked whether liquidations are locked
    function liquidationsLocked() external view returns (bool);

    /// @notice boolean indicating whether token0 in pool is the underlying token
    function token0IsUnderlying() external view returns (bool);

    /// @notice maximum LTV a vault can have, expressed as a decimal scaled by 1e18
    function maxLTV() external view returns (uint256);

    /// @notice minimum time that must pass before consecutive collateral is liquidated from the same vault
    function liquidationAuctionMinSpacing() external view returns (uint256);

    /// @notice amount the price of an auction decreases by per auctionDecayPeriod, expressed as a decimal scaled by 1e18
    function perPeriodAuctionDecayWAD() external view returns (uint256);

    /// @notice amount of time that perPeriodAuctionDecayWAD is applied to, expressed in seconds
    function auctionDecayPeriod() external view returns (uint256);

    /// @notice the multiplier for the starting price of an auction, applied to the current price of the collateral in papr tokens
    function auctionStartPriceMultiplier() external view returns (uint256);

    /// @notice fee paid by the vault owner when their vault is liquidated if there was excess debt credited to their vault, in bips
    function liquidationPenaltyBips() external view returns (uint256);

    /// @notice returns the maximum debt that can be minted for a given collateral value
    /// @param totalCollateraValue total value of the collateral
    /// @return maxDebt maximum debt that can be minted, expressed in terms of the papr token
    function maxDebt(uint256 totalCollateraValue) external view returns (uint256);

    /// @notice returns information about a vault
    /// @param account address of the vault owner
    /// @param asset address of the collateral token associated with the vault
    /// @return vaultInfo VaultInfo struct representing information about a vault
    function vaultInfo(address account, ERC721 asset) external view returns (IPaprController.VaultInfo memory);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {IFundingRateController} from "./IFundingRateController.sol";

interface IUniswapOracleFundingRateController is IFundingRateController {
    /// @notice emitted when pool is set
    /// @param pool the new pool value
    event SetPool(address indexed pool);

    /// @notice emitted if _setPool is called with a pool
    /// that's tokens do not match pool()
    error PoolTokensDoNotMatch();
    error InvalidUniswapV3Pool();

    /// @notice The address of the Uniswap pool used for mark()
    /// @return pool address of the pool
    function pool() external returns (address);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

import {IUniswapV3Pool} from "v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import {TickMath} from "fullrange/libraries/TickMath.sol";
import {FullMath} from "fullrange/libraries/FullMath.sol";

library OracleLibrary {
    /// from https://github.com/Uniswap/v3-periphery/blob/main/contracts/libraries/OracleLibrary.sol#L49
    function getQuoteAtTick(int24 tick, uint128 baseAmount, address baseToken, address quoteToken)
        internal
        pure
        returns (uint256 quoteAmount)
    {
        unchecked {
            uint160 sqrtRatioX96 = TickMath.getSqrtRatioAtTick(tick);

            // Calculate quoteAmount with better precision if it doesn't overflow when multiplied by itself
            if (sqrtRatioX96 <= type(uint128).max) {
                uint256 ratioX192 = uint256(sqrtRatioX96) * sqrtRatioX96;
                quoteAmount = baseToken < quoteToken
                    ? FullMath.mulDiv(ratioX192, baseAmount, 1 << 192)
                    : FullMath.mulDiv(1 << 192, baseAmount, ratioX192);
            } else {
                uint256 ratioX128 = FullMath.mulDiv(sqrtRatioX96, sqrtRatioX96, 1 << 64);
                quoteAmount = baseToken < quoteToken
                    ? FullMath.mulDiv(ratioX128, baseAmount, 1 << 128)
                    : FullMath.mulDiv(1 << 128, baseAmount, ratioX128);
            }
        }
    }

    // adapted from https://github.com/Uniswap/v3-periphery/blob/main/contracts/libraries/OracleLibrary.sol#L30-L40
    function timeWeightedAverageTick(int56 startTick, int56 endTick, int56 twapDuration)
        internal
        pure
        returns (int24 twat)
    {
        require(twapDuration != 0, "BP");

        unchecked {
            int56 delta = endTick - startTick;

            twat = int24(delta / twapDuration);

            // Always round to negative infinity
            if (delta < 0 && (delta % (twapDuration) != 0)) {
                twat--;
            }

            twat;
        }
    }

    // adapted from https://github.com/Uniswap/v3-periphery/blob/main/contracts/libraries/OracleLibrary.sol#L21-L28
    function latestCumulativeTick(address pool) internal view returns (int56) {
        uint32[] memory secondAgos = new uint32[](1);
        secondAgos[0] = 0;
        (int56[] memory tickCumulatives,) = IUniswapV3Pool(pool).observe(secondAgos);
        return tickCumulatives[0];
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
// from https://github.com/Uniswap/v3-periphery/blob/main/contracts/libraries/PoolAddress.sol
// with updates for solc 8
pragma solidity >=0.8.0;

/// @title Provides functions for deriving a pool address from the factory, tokens, and the fee
library PoolAddress {
    bytes32 internal constant POOL_INIT_CODE_HASH = 0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54;

    /// @notice The identifying key of the pool
    struct PoolKey {
        address token0;
        address token1;
        uint24 fee;
    }

    /// @notice Returns PoolKey: the ordered tokens with the matched fee levels
    /// @param tokenA The first token of a pool, unsorted
    /// @param tokenB The second token of a pool, unsorted
    /// @param fee The fee level of the pool
    /// @return Poolkey The pool details with ordered token0 and token1 assignments
    function getPoolKey(address tokenA, address tokenB, uint24 fee) internal pure returns (PoolKey memory) {
        if (tokenA > tokenB) (tokenA, tokenB) = (tokenB, tokenA);
        return PoolKey({token0: tokenA, token1: tokenB, fee: fee});
    }

    /// @notice Deterministically computes the pool address given the factory and PoolKey
    /// @param factory The Uniswap V3 factory contract address
    /// @param key The PoolKey
    /// @return pool The contract address of the V3 pool
    function computeAddress(address factory, PoolKey memory key) internal pure returns (address pool) {
        require(key.token0 < key.token1);
        pool = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            factory,
                            keccak256(abi.encode(key.token0, key.token1, key.fee)),
                            POOL_INIT_CODE_HASH
                        )
                    )
                )
            )
        );
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

import {IUniswapV3Pool} from "v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import {IUniswapV3Factory} from "v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import {TickMath} from "fullrange/libraries/TickMath.sol";
import {FullMath} from "fullrange/libraries/FullMath.sol";
import {SafeCast} from "v3-core/contracts/libraries/SafeCast.sol";

import {PoolAddress} from "./PoolAddress.sol";

library UniswapHelpers {
    using SafeCast for uint256;

    /// @param minOut The minimum out amount the user wanted
    /// @param actualOut The actual out amount the user received
    error TooLittleOut(uint256 minOut, uint256 actualOut);

    /// @param deadline The minimum out amount the user wanted
    /// @param currentTimestamp The actual out amount the user received
    error PassedDeadline(uint256 deadline, uint256 currentTimestamp);

    IUniswapV3Factory constant FACTORY = IUniswapV3Factory(0x1F98431c8aD98523631AE4a59f267346ea31F984);

    /// @notice executes a swap on the Uniswap
    /// @param pool The pool to swap on
    /// @param recipient The address to send the output to
    /// @param zeroForOne Whether to swap token0 for token1 or vice versa
    /// @param amountSpecified The amount of token0 or token1 to swap
    /// @param minOut The minimum amount of token0 or token1 to receive
    /// @param sqrtPriceLimitX96 The price limit for the swap
    /// @param deadline timestamp after which the swap should revert
    /// @param data Any data to pass to the uniswap callback handler
    /// @return amountOut The amount of token0 or token1 received
    /// @return amountIn The amount of token0 or token1 sent
    function swap(
        address pool,
        address recipient,
        bool zeroForOne,
        uint256 amountSpecified,
        uint256 minOut,
        uint160 sqrtPriceLimitX96,
        uint256 deadline,
        bytes memory data
    ) internal returns (uint256 amountOut, uint256 amountIn) {
        if (block.timestamp > deadline) revert PassedDeadline(deadline, block.timestamp);

        (int256 amount0, int256 amount1) = IUniswapV3Pool(pool).swap(
            recipient,
            zeroForOne,
            amountSpecified.toInt256(),
            sqrtPriceLimitX96 == 0
                ? (zeroForOne ? TickMath.MIN_SQRT_RATIO + 1 : TickMath.MAX_SQRT_RATIO - 1)
                : sqrtPriceLimitX96,
            data
        );

        if (zeroForOne) {
            amountOut = uint256(-amount1);
            amountIn = uint256(amount0);
        } else {
            amountOut = uint256(-amount0);
            amountIn = uint256(amount1);
        }

        if (amountOut < minOut) {
            revert TooLittleOut(amountOut, minOut);
        }
    }

    /// @notice initializes a UniswapV3 pool with the given sqrt ratio
    /// @param tokenA the first token in the pool
    /// @param tokenB the second token in the pool
    /// @param feeTier the fee tier of the pool
    /// @param sqrtRatio the sqrt ratio to initialize the pool with
    /// @return pool the address of the newly created pool
    function deployAndInitPool(address tokenA, address tokenB, uint24 feeTier, uint160 sqrtRatio)
        internal
        returns (address)
    {
        IUniswapV3Pool pool = IUniswapV3Pool(FACTORY.createPool(tokenA, tokenB, feeTier));
        pool.initialize(sqrtRatio);

        return address(pool);
    }

    /// @notice returns the current price tick of a UniswapV3 pool
    /// @param pool the address of the pool
    /// @return tick the current price tick of the pool
    function poolCurrentTick(address pool) internal returns (int24) {
        (, int24 tick,,,,,) = IUniswapV3Pool(pool).slot0();

        return tick;
    }

    /// @notice returns whether or not two pools have the same tokens
    /// @param pool1 the first pool
    /// @param pool2 the second pool
    /// @return same whether or not the two pools have the same tokens
    function poolsHaveSameTokens(address pool1, address pool2) internal view returns (bool) {
        return IUniswapV3Pool(pool1).token0() == IUniswapV3Pool(pool2).token0()
            && IUniswapV3Pool(pool1).token1() == IUniswapV3Pool(pool2).token1();
    }

    /// @notice returns whether or not a pool is a UniswapV3 pool
    /// @param pool the address of the pool
    /// @return isUniswapPool whether or not the pool is a UniswapV3 pool
    function isUniswapPool(address pool) internal view returns (bool) {
        IUniswapV3Pool p = IUniswapV3Pool(pool);
        PoolAddress.PoolKey memory k = PoolAddress.getPoolKey(p.token0(), p.token1(), p.fee());
        return pool == PoolAddress.computeAddress(address(FACTORY), k);
    }

    /// @notice returns the sqrt ratio at which token0 and token1 are trading at 1:1
    /// @param token0ONE 10 ** token0.decimals()
    /// @param token1ONE 10 ** token1.decimals()
    /// @return sqrtRatio at which token0 and token1 are trading at 1:1
    function oneToOneSqrtRatio(uint256 token0ONE, uint256 token1ONE) internal pure returns (uint160) {
        return TickMath.getSqrtRatioAtTick(TickMath.getTickAtSqrtRatio(uint160((token1ONE << 96) / token0ONE)) / 2);
    }
}