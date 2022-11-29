/**
 *Submitted for verification at Etherscan.io on 2022-11-29
*/

// File: @openzeppelin/contracts/utils/math/Math.sol


// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// File: @openzeppelin/contracts/utils/Strings.sol


// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;


/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: @chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol


pragma solidity ^0.8.4;

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness. It ensures 2 things:
 * @dev 1. The fulfillment came from the VRFCoordinator
 * @dev 2. The consumer contract implements fulfillRandomWords.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constructor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash). Create subscription, fund it
 * @dev and your consumer contract as a consumer of it (see VRFCoordinatorInterface
 * @dev subscription management functions).
 * @dev Call requestRandomWords(keyHash, subId, minimumRequestConfirmations,
 * @dev callbackGasLimit, numWords),
 * @dev see (VRFCoordinatorInterface for a description of the arguments).
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomWords method.
 *
 * @dev The randomness argument to fulfillRandomWords is a set of random words
 * @dev generated from your requestId and the blockHash of the request.
 *
 * @dev If your contract could have concurrent requests open, you can use the
 * @dev requestId returned from requestRandomWords to track which response is associated
 * @dev with which randomness request.
 * @dev See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ.
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request. It is for this reason that
 * @dev that you can signal to an oracle you'd like them to wait longer before
 * @dev responding to the request (however this is not enforced in the contract
 * @dev and so remains effective only in the case of unmodified oracle software).
 */
abstract contract VRFConsumerBaseV2 {
  error OnlyCoordinatorCanFulfill(address have, address want);
  address private immutable vrfCoordinator;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   */
  constructor(address _vrfCoordinator) {
    vrfCoordinator = _vrfCoordinator;
  }

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBaseV2 expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomWords the VRF output expanded to the requested number of words
   */
  function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal virtual;

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external {
    if (msg.sender != vrfCoordinator) {
      revert OnlyCoordinatorCanFulfill(msg.sender, vrfCoordinator);
    }
    fulfillRandomWords(requestId, randomWords);
  }
}

// File: @chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol


pragma solidity ^0.8.0;

interface VRFCoordinatorV2Interface {
  /**
   * @notice Get configuration relevant for making requests
   * @return minimumRequestConfirmations global min for request confirmations
   * @return maxGasLimit global max for request gas limit
   * @return s_provingKeyHashes list of registered key hashes
   */
  function getRequestConfig()
    external
    view
    returns (
      uint16,
      uint32,
      bytes32[] memory
    );

  /**
   * @notice Request a set of random words.
   * @param keyHash - Corresponds to a particular oracle job which uses
   * that key for generating the VRF proof. Different keyHash's have different gas price
   * ceilings, so you can select a specific one to bound your maximum per request cost.
   * @param subId  - The ID of the VRF subscription. Must be funded
   * with the minimum subscription balance required for the selected keyHash.
   * @param minimumRequestConfirmations - How many blocks you'd like the
   * oracle to wait before responding to the request. See SECURITY CONSIDERATIONS
   * for why you may want to request more. The acceptable range is
   * [minimumRequestBlockConfirmations, 200].
   * @param callbackGasLimit - How much gas you'd like to receive in your
   * fulfillRandomWords callback. Note that gasleft() inside fulfillRandomWords
   * may be slightly less than this amount because of gas used calling the function
   * (argument decoding etc.), so you may need to request slightly more than you expect
   * to have inside fulfillRandomWords. The acceptable range is
   * [0, maxGasLimit]
   * @param numWords - The number of uint256 random values you'd like to receive
   * in your fulfillRandomWords callback. Note these numbers are expanded in a
   * secure way by the VRFCoordinator from a single random value supplied by the oracle.
   * @return requestId - A unique identifier of the request. Can be used to match
   * a request to a response in fulfillRandomWords.
   */
  function requestRandomWords(
    bytes32 keyHash,
    uint64 subId,
    uint16 minimumRequestConfirmations,
    uint32 callbackGasLimit,
    uint32 numWords
  ) external returns (uint256 requestId);

  /**
   * @notice Create a VRF subscription.
   * @return subId - A unique subscription id.
   * @dev You can manage the consumer set dynamically with addConsumer/removeConsumer.
   * @dev Note to fund the subscription, use transferAndCall. For example
   * @dev  LINKTOKEN.transferAndCall(
   * @dev    address(COORDINATOR),
   * @dev    amount,
   * @dev    abi.encode(subId));
   */
  function createSubscription() external returns (uint64 subId);

  /**
   * @notice Get a VRF subscription.
   * @param subId - ID of the subscription
   * @return balance - LINK balance of the subscription in juels.
   * @return reqCount - number of requests for this subscription, determines fee tier.
   * @return owner - owner of the subscription.
   * @return consumers - list of consumer address which are able to use this subscription.
   */
  function getSubscription(uint64 subId)
    external
    view
    returns (
      uint96 balance,
      uint64 reqCount,
      address owner,
      address[] memory consumers
    );

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @param newOwner - proposed new owner of the subscription
   */
  function requestSubscriptionOwnerTransfer(uint64 subId, address newOwner) external;

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @dev will revert if original owner of subId has
   * not requested that msg.sender become the new owner.
   */
  function acceptSubscriptionOwnerTransfer(uint64 subId) external;

  /**
   * @notice Add a consumer to a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - New consumer which can use the subscription
   */
  function addConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Remove a consumer from a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - Consumer to remove from the subscription
   */
  function removeConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Cancel a subscription
   * @param subId - ID of the subscription
   * @param to - Where to send the remaining LINK to
   */
  function cancelSubscription(uint64 subId, address to) external;

  /*
   * @notice Check to see if there exists a request commitment consumers
   * for all consumers and keyhashes for a given sub.
   * @param subId - ID of the subscription
   * @return true if there exists at least one unfulfilled request for the subscription, false
   * otherwise.
   */
  function pendingRequestExists(uint64 subId) external view returns (bool);
}

// File: @chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol


pragma solidity ^0.8.0;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);

  function approve(address spender, uint256 value) external returns (bool success);

  function balanceOf(address owner) external view returns (uint256 balance);

  function decimals() external view returns (uint8 decimalPlaces);

  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);

  function increaseApproval(address spender, uint256 subtractedValue) external;

  function name() external view returns (string memory tokenName);

  function symbol() external view returns (string memory tokenSymbol);

  function totalSupply() external view returns (uint256 totalTokensIssued);

  function transfer(address to, uint256 value) external returns (bool success);

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool success);
}

// File: GamoFlip.sol



pragma solidity ^0.8.7;






contract GamoFlip is VRFConsumerBaseV2, ReentrancyGuard {

    /////////////////////////////////// ChainLink Variables ///////////////////////////////////
    VRFCoordinatorV2Interface COORDINATOR;
    LinkTokenInterface LINKTOKEN;

    // Goerli coordinator. For other networks,
    // see https://docs.chain.link/docs/vrf-contracts/#configurations
    address vrfCoordinator = 0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D;

    // Goerli LINK token contract. For other networks, see
    // https://docs.chain.link/docs/vrf-contracts/#configurations
    address link_token_contract = 0x326C977E6efc84E512bB9C30f76E30c160eD06FB;

    // The gas lane to use, which specifies the maximum gas price to bump to.
    // For a list of available gas lanes on each network,
    // see https://docs.chain.link/docs/vrf-contracts/#configurations
    bytes32 keyHash =
        0x79d3d8832d904592c0bf9818b621522c988bb8b0c05cdc3b15aea1b6e8db0c15;

    // A reasonable default is 100000, but this value could be different
    // on other networks.
    uint32 callbackGasLimit = 2500000;

    // The default is 3, but you can set this higher.
    uint16 requestConfirmations = 3;

    // For this example, retrieve 2 random values in one request.
    // Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.
    uint32 numWords = 1;

    uint256[] public s_randomWords;
    uint256 public s_requestId;
    uint256 public s_requestId2;
    uint64 public s_subscriptionId;
    bool public result;

    /////////////////////////////////// Gamoflip Variables ///////////////////////////////////
    address public owner;
    uint public nextFlip;
    uint public nextDegen;
    uint[] public validAmounts;
    uint public feePercentage;

    // Structs
    struct flip {
        uint id;
        bool exists;
        address degen;
        uint flipResult;
        uint choice;
        uint result;
        uint date;
        uint ethBetted;
        int ethWon;
        int ethLost;
    }

    struct preFlip {
        string requestId;
        uint flipId;
        bool exists;
        address degen;
        uint choice;
        uint date;
        uint ethBetted;
        bool open;
        uint randomWord;
    }

    struct degen {
        uint id;
        bool exists;
        address degenAddress;
        uint lastFlip;
    }

    struct approvedDegen {
        address degen;
        bool exists;
    }

    // Mappings
    mapping(uint256 => flip) public Flips;
    mapping (uint256 => address) public IdsToDegens;
    mapping (address => degen) public Degens;
    mapping (address => approvedDegen) public ApprovedDegens;
    mapping (string => preFlip) public PreFlips;


    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    //Events
    event RequestSent(uint256 requestId, uint flipId, address degen);
    event RequestFulfilled(uint256 requestId, uint flipId);
    event Test(uint id, uint id2);

    constructor() VRFConsumerBaseV2(vrfCoordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        LINKTOKEN = LinkTokenInterface(link_token_contract);
        owner = msg.sender;
        //Create a new subscription when you deploy the contract.
        createNewSubscription();
        validAmounts = [10000000000000000, 20000000000000000, 25000000000000000, 50000000000000000, 75000000000000000, 100000000000000000];
        nextFlip = 1;
        nextDegen = 1;
        feePercentage = 5;
    }

    // Helper Functions
    receive() external payable {}

    function withdrawEth() external onlyOwner nonReentrant {
        require(tx.origin == msg.sender, "Nice Try");
        (bool os,) = payable(owner).call{value:address(this).balance}("");
        require(os);
    }

    ////////////////////////////////////// ChainLink Functions /////////////////////////////////////////
    
    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {
        //s_randomWords = randomWords;
        //uint randomNumber = randomWords[0];
        string memory stringReq = numberToString(requestId);
        preFlip storage getPreFlip = PreFlips[stringReq];
        getPreFlip.randomWord = randomWords[0];
        //distribute(getPreFlip.degen, getPreFlip.choice, getPreFlip.ethBetted, randomWords[0], getPreFlip.flipId);
        emit RequestFulfilled(requestId, getPreFlip.flipId);
    }

    // Create a new subscription when the contract is initially deployed.
    function createNewSubscription() private onlyOwner {
        s_subscriptionId = COORDINATOR.createSubscription();
        // Add this contract as a consumer of its own subscription.
        COORDINATOR.addConsumer(s_subscriptionId, address(this));
    }

    // Assumes this contract owns link.
    // 1000000000000000000 = 1 LINK
    function topUpSubscription(uint256 amount) external {
        LINKTOKEN.transferAndCall(
            address(COORDINATOR),
            amount,
            abi.encode(s_subscriptionId)
        );
    }

    function addConsumer(address consumerAddress) external onlyOwner {
        // Add a consumer contract to the subscription.
        COORDINATOR.addConsumer(s_subscriptionId, consumerAddress);
    }

    function removeConsumer(address consumerAddress) external onlyOwner {
        // Remove a consumer contract from the subscription.
        COORDINATOR.removeConsumer(s_subscriptionId, consumerAddress);
    }

    function cancelSubscription() external onlyOwner {
        // Cancel the subscription and send the remaining LINK to a wallet address.
        COORDINATOR.cancelSubscription(s_subscriptionId, msg.sender);
        s_subscriptionId = 0;
    }

    // Transfer this contract's funds to an address.
    // 1000000000000000000 = 1 LINK
    function withdraw(uint256 amount, address to) external onlyOwner {
        require(tx.origin == msg.sender, "Nice Try");
        LINKTOKEN.transfer(to, amount);
    }

    function changeCallBackGasLimit(uint32 amount) external onlyOwner {
        callbackGasLimit = amount;
    }

    function changeKeyHash(bytes32 amount) external onlyOwner {
        keyHash = amount;
    }

    ////////////////////////////////////// GAMOFLIP Functions /////////////////////////////////////////

    function doTestEvent(uint id, uint id2) external onlyOwner {
        emit Test(id, id2);
    }

    function getHigestOrderDigit(uint number) internal pure returns (uint) {
        while (number >= 10) {
            number /= 10;
        }
        return number;
    }

    function flipEth(bool expectation) payable external nonReentrant {
        require(msg.value == validAmounts[0] || msg.value == validAmounts[1] || msg.value == validAmounts[2] || msg.value == validAmounts[3] || msg.value == validAmounts[4] || msg.value == validAmounts[5], "You can't bet this ETH amount");
        require(tx.origin == msg.sender, "Nice Try");

        s_requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );

        string memory stringRequest = numberToString(s_requestId);

        preFlip storage newPreFlip = PreFlips[stringRequest];
        newPreFlip.requestId = numberToString(s_requestId);
        newPreFlip.flipId = nextFlip;
        newPreFlip.exists = true;
        newPreFlip.degen = msg.sender;
        if (expectation) {
            newPreFlip.choice = 1;
        } else {
            newPreFlip.choice = 2;
        }
        newPreFlip.date = block.timestamp;
        newPreFlip.ethBetted = msg.value;
        newPreFlip.open = true;

        emit RequestSent(s_requestId, newPreFlip.flipId, newPreFlip.degen);

        nextFlip++;
    }

    function stringToNumber(string memory numString) public pure returns(uint) {
        uint  val=0;
        bytes   memory stringBytes = bytes(numString);
        for (uint  i =  0; i<stringBytes.length; i++) {
            uint exp = stringBytes.length - i;
            bytes1 ival = stringBytes[i];
            uint8 uval = uint8(ival);
           uint jval = uval - uint(0x30);
   
           val +=  (uint(jval) * (10**(exp-1))); 
        }
        return val;
    }

    function numberToString(uint num) public pure returns (string memory) {
        string memory memoryString = Strings.toString(num);
        return memoryString;
    }

    // Assumes the subscription is funded sufficiently.
    function getResults(uint choice, uint ethBetted, uint flipId, string memory requestId) external nonReentrant {
        require(tx.origin == msg.sender, "Nice Try");

        require(keccak256(abi.encodePacked(PreFlips[requestId].requestId)) == keccak256(abi.encodePacked(requestId)));
        require(PreFlips[requestId].degen == msg.sender, "Not correct degen");
        require(PreFlips[requestId].open == true, "Flip closed");
        require(PreFlips[requestId].choice == choice, "Not correct choice");
        require(PreFlips[requestId].ethBetted == ethBetted, "Not correct amount");
        require(PreFlips[requestId].flipId == flipId, "Not correct id");

        degen storage newDegen = Degens[msg.sender];

        if (newDegen.exists == false) {
            newDegen.id = nextDegen;
            newDegen.exists = true;
            newDegen.degenAddress = msg.sender;

            IdsToDegens[nextDegen] = msg.sender;
            nextDegen++;
        }

        newDegen.lastFlip = block.timestamp;

        bool victory = false;

        // Get Heads Or Tails Depending On The Request Id Value
        if ((PreFlips[requestId].randomWord % 2) == 0) {

            if (choice == 1) {
                flip storage newFlip = Flips[flipId];
                newFlip.id = flipId;
                newFlip.exists = true;
                newFlip.degen = msg.sender;
                newFlip.flipResult = 1;
                newFlip.choice = 1;
                newFlip.result = 1;
                newFlip.date = block.timestamp;
                newFlip.ethBetted = ethBetted;
                newFlip.ethWon = int256(ethBetted);
                newFlip.ethLost = 0;

                victory = true;

            } else {
                flip storage newFlip = Flips[flipId];
                newFlip.id = flipId;
                newFlip.exists = true;
                newFlip.degen = msg.sender;
                newFlip.flipResult = 1;
                newFlip.choice = 2;
                newFlip.result = 2;
                newFlip.date = block.timestamp;
                newFlip.ethBetted = ethBetted;
                newFlip.ethWon = 0;
                newFlip.ethLost = int256(ethBetted);
            }

        } else {

            if (choice == 2) {
                flip storage newFlip = Flips[flipId];
                newFlip.id = flipId;
                newFlip.exists = true;
                newFlip.degen = msg.sender;
                newFlip.flipResult = 2;
                newFlip.choice = 2;
                newFlip.result = 1;
                newFlip.date = block.timestamp;
                newFlip.ethBetted = ethBetted;
                newFlip.ethWon = int256(ethBetted);
                newFlip.ethLost = 0;

                victory = true;

            } else {
                flip storage newFlip = Flips[flipId];
                newFlip.id = flipId;
                newFlip.exists = true;
                newFlip.degen = msg.sender;
                newFlip.flipResult = 2;
                newFlip.choice = 1;
                newFlip.result = 2;
                newFlip.date = block.timestamp;
                newFlip.ethBetted = ethBetted;
                newFlip.ethWon = 0;
                newFlip.ethLost = int256(ethBetted);
            }
        }

        if (victory) {
            // Get amount to reward minus fees.
            uint amountToPay = (ethBetted * 2) - ((ethBetted * feePercentage) / 100);
            (bool success,) = payable(msg.sender).call{value: amountToPay}("");
            require(success, "Address: unable to send value, recipient may have reverted");
        }

        preFlip storage userPreFlip = PreFlips[requestId];
        userPreFlip.open = false;
    }

    function changeFeePercentage(uint newFee) external onlyOwner {
        feePercentage = newFee;
    }

    function changeValidAmounts(uint newAmount1, uint newAmount2, uint newAmount3, uint newAmount4, uint newAmount5, uint newAmount6) external onlyOwner {
        validAmounts[0] = newAmount1;
        validAmounts[1] = newAmount2;
        validAmounts[2] = newAmount3;
        validAmounts[3] = newAmount4;
        validAmounts[4] = newAmount5;
        validAmounts[5] = newAmount6;
    }

    function getPlayerFlipsTotal(address player) public view returns (flip[] memory filteredFlips) {
        flip[] memory flipsTemp = new flip[](nextFlip - 1);
        uint count;
        for (uint i = 0; i < (nextFlip); i++) {
            if (Flips[i].degen == player) {
                flipsTemp[count] = Flips[i];
                count++;
            }
        }

        filteredFlips = new flip[](count);
        for (uint i = 0; i < count; i++) {
            filteredFlips[i] = flipsTemp[i];
        }

        return filteredFlips;
    }

    function getPlayerFlipsToday(address player) public view returns (flip[] memory filteredFlips) {
        flip[] memory flipsTemp = new flip[](nextFlip - 1);
        uint count;
        uint dayAgo = block.timestamp - (1 * 1 days);
        for (uint i = 0; i < (nextFlip); i++) {
            if (Flips[i].degen == player && Flips[i].date >= dayAgo && Flips[i].date <= block.timestamp) {
                flipsTemp[count] = Flips[i];
                count++;
            }
        }

        filteredFlips = new flip[](count);
        for (uint i = 0; i < count; i++) {
            filteredFlips[i] = flipsTemp[i];
        }

        return filteredFlips;
    }

    function getPlayerProfitsToday(address player) public view returns (int) {
        int wins;
        int losses;
        flip[] memory userFlips = getPlayerFlipsToday(player);
        // Get Wins
        for (uint i = 0; i < userFlips.length; i++) {
            wins += userFlips[i].ethWon;
        }
        // Get Losses
        for (uint i = 0; i < userFlips.length; i++) {
            losses += userFlips[i].ethLost;
        }
        // Get Pnl
        int pnl = wins - losses;
        return pnl;
    }

    function getPlayerProfitsTotal(address player) public view returns (int) {
        int wins;
        int losses;
        flip[] memory userFlips = getPlayerFlipsTotal(player);
        // Get Wins
        for (uint i = 0; i < userFlips.length; i++) {
            wins += userFlips[i].ethWon;
        }
        // Get Losses
        for (uint i = 0; i < userFlips.length; i++) {
            losses += userFlips[i].ethLost;
        }
        // Get Pnl
        int pnl = wins - losses;
        return pnl;
    }

    function getAllFlips() public view returns (flip[] memory filteredFlips) {
        flip[] memory flipsTemp = new flip[](nextFlip - 1);
        uint count;
        for (uint i = 0; i < (nextFlip); i++) {
            if (Flips[i].exists == true) {
                flipsTemp[count] = Flips[i];
                count++;
            }
        }

        filteredFlips = new flip[](count);
        for (uint i = 0; i < count; i++) {
            filteredFlips[i] = flipsTemp[i];
        }

        return filteredFlips;
    }

    function getAllFlipsToday() public view returns (flip[] memory filteredFlips) {
        flip[] memory flipsTemp = new flip[](nextFlip - 1);
        uint count;
        uint dayAgo = block.timestamp - (1 * 1 days);
        for (uint i = 0; i < (nextFlip); i++) {
            if (Flips[i].exists == true && Flips[i].date >= dayAgo && Flips[i].date <= block.timestamp) {
                flipsTemp[count] = Flips[i];
                count++;
            }
        }

        filteredFlips = new flip[](count);
        for (uint i = 0; i < count; i++) {
            filteredFlips[i] = flipsTemp[i];
        }

        return filteredFlips;
    }

    function getAllFlipsTodayNumber() public view returns (uint) {
        flip[] memory flipsTemp = getAllFlipsToday();
        return flipsTemp.length;
    }

    function getTotalEthFlipped() public view returns (uint) {
        uint total;
        flip[] memory userFlips = getAllFlips();
        // Get Total Flipped
        for (uint i = 0; i < userFlips.length; i++) {
            total += userFlips[i].ethBetted;
        }
        return total;
    }

    function getTotalEthFlippedToday() public view returns (uint) {
        uint total;
        flip[] memory userFlips = getAllFlipsToday();
        // Get Total Flipped
        for (uint i = 0; i < userFlips.length; i++) {
            total += userFlips[i].ethBetted;
        }
        return total;
    }

    function getAllFlipsNumber() public view returns (uint) {
        flip[] memory flipsTemp = getAllFlips();
        return flipsTemp.length;
    }

    function getAllWins() public view returns (flip[] memory filteredFlips) {
        flip[] memory flipsTemp = new flip[](nextFlip - 1);
        uint count;
        for (uint i = 0; i < (nextFlip); i++) {
            if (Flips[i].result == 1) {
                flipsTemp[count] = Flips[i];
                count++;
            }
        }

        filteredFlips = new flip[](count);
        for (uint i = 0; i < count; i++) {
            filteredFlips[i] = flipsTemp[i];
        }

        return filteredFlips;
    }

    function getAllWinsToday() public view returns (flip[] memory filteredFlips) {
        flip[] memory flipsTemp = new flip[](nextFlip - 1);
        uint count;
        uint dayAgo = block.timestamp - (1 * 1 days);
        for (uint i = 0; i < (nextFlip); i++) {
            if (Flips[i].result == 1 && Flips[i].date >= dayAgo && Flips[i].date <= block.timestamp) {
                flipsTemp[count] = Flips[i];
                count++;
            }
        }

        filteredFlips = new flip[](count);
        for (uint i = 0; i < count; i++) {
            filteredFlips[i] = flipsTemp[i];
        }

        return filteredFlips;
    }

    function getAllWinsTodayNumber() public view returns (uint) {
        flip[] memory flipsTemp = getAllWinsToday();
        return flipsTemp.length;
    }

    function getTotalEthWon() public view returns (int) {
        int total;
        flip[] memory userFlips = getAllFlips();
        // Get Total Flipped
        for (uint i = 0; i < userFlips.length; i++) {
            total += userFlips[i].ethWon;
        }
        return total;
    }

    function getTotalEthWonToday() public view returns (int) {
        int total;
        flip[] memory userFlips = getAllFlipsToday();
        // Get Total Flipped
        for (uint i = 0; i < userFlips.length; i++) {
            total += userFlips[i].ethWon;
        }
        return total;
    }

    function getAllWinsNumber() public view returns (uint) {
        flip[] memory flipsTemp = getAllWins();
        return flipsTemp.length;
    }

    function getAllRugs() public view returns (flip[] memory filteredFlips) {
        flip[] memory flipsTemp = new flip[](nextFlip - 1);
        uint count;
        for (uint i = 0; i < (nextFlip); i++) {
            if (Flips[i].result == 2) {
                flipsTemp[count] = Flips[i];
                count++;
            }
        }

        filteredFlips = new flip[](count);
        for (uint i = 0; i < count; i++) {
            filteredFlips[i] = flipsTemp[i];
        }

        return filteredFlips;
    }

    function getAllRugsNumber() public view returns (uint) {
        flip[] memory flipsTemp = getAllRugs();
        return flipsTemp.length;
    }

    function getAllRugsToday() public view returns (flip[] memory filteredFlips) {
        flip[] memory flipsTemp = new flip[](nextFlip - 1);
        uint count;
        uint dayAgo = block.timestamp - (1 * 1 days);
        for (uint i = 0; i < (nextFlip); i++) {
            if (Flips[i].result == 2 && Flips[i].date >= dayAgo && Flips[i].date <= block.timestamp) {
                flipsTemp[count] = Flips[i];
                count++;
            }
        }

        filteredFlips = new flip[](count);
        for (uint i = 0; i < count; i++) {
            filteredFlips[i] = flipsTemp[i];
        }

        return filteredFlips;
    }

    function getAllRugsTodayNumber() public view returns (uint) {
        flip[] memory flipsTemp = getAllRugsToday();
        return flipsTemp.length;
    }

    function getTotalEthRugged() public view returns (int) {
        int total;
        flip[] memory userFlips = getAllFlips();
        // Get Total Flipped
        for (uint i = 0; i < userFlips.length; i++) {
            total += userFlips[i].ethLost;
        }
        return total;
    }

    function getTotalEthRuggedToday() public view returns (int) {
        int total;
        flip[] memory userFlips = getAllFlipsToday();
        // Get Total Flipped
        for (uint i = 0; i < userFlips.length; i++) {
            total += userFlips[i].ethLost;
        }
        return total;
    }
}