// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ConfirmedOwnerWithProposal.sol";

/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwner is ConfirmedOwnerWithProposal {
  constructor(address newOwner) ConfirmedOwnerWithProposal(newOwner, address(0)) {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/OwnableInterface.sol";

/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwnerWithProposal is OwnableInterface {
  address private s_owner;
  address private s_pendingOwner;

  event OwnershipTransferRequested(address indexed from, address indexed to);
  event OwnershipTransferred(address indexed from, address indexed to);

  constructor(address newOwner, address pendingOwner) {
    require(newOwner != address(0), "Cannot set owner to zero");

    s_owner = newOwner;
    if (pendingOwner != address(0)) {
      _transferOwnership(pendingOwner);
    }
  }

  /**
   * @notice Allows an owner to begin transferring ownership to a new address,
   * pending.
   */
  function transferOwnership(address to) public override onlyOwner {
    _transferOwnership(to);
  }

  /**
   * @notice Allows an ownership transfer to be completed by the recipient.
   */
  function acceptOwnership() external override {
    require(msg.sender == s_pendingOwner, "Must be proposed owner");

    address oldOwner = s_owner;
    s_owner = msg.sender;
    s_pendingOwner = address(0);

    emit OwnershipTransferred(oldOwner, msg.sender);
  }

  /**
   * @notice Get the current owner
   */
  function owner() public view override returns (address) {
    return s_owner;
  }

  /**
   * @notice validate, transfer ownership, and emit relevant events
   */
  function _transferOwnership(address to) private {
    require(to != msg.sender, "Cannot transfer to self");

    s_pendingOwner = to;

    emit OwnershipTransferRequested(s_owner, to);
  }

  /**
   * @notice validate access
   */
  function _validateOwnership() internal view {
    require(msg.sender == s_owner, "Only callable by owner");
  }

  /**
   * @notice Reverts if called by anyone other than the contract owner.
   */
  modifier onlyOwner() {
    _validateOwnership();
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface OwnableInterface {
  function owner() external returns (address);

  function transferOwnership(address recipient) external;

  function acceptOwnership() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract TypeAndVersionInterface {
  function typeAndVersion() external pure virtual returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

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
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import {ConfirmedOwner} from "chainlink/contracts/src/v0.8/ConfirmedOwner.sol";
import {IExchanger} from "./interfaces/IExchanger.sol";
import {IVerifierProxy} from "./interfaces/IVerifierProxy.sol";
import {IERC165} from "openzeppelin-contracts/interfaces/IERC165.sol";
import {TypeAndVersionInterface} from "chainlink/contracts/src/v0.8/interfaces/TypeAndVersionInterface.sol";
import {Strings} from "openzeppelin-contracts/utils/Strings.sol";

contract Exchanger is IExchanger, TypeAndVersionInterface, ConfirmedOwner {
    IVerifierProxy private s_verifierProxyAddress;
    bytes private s_lookupURL; // Must be accessible to client (ex. 'https://<mercury host>/')
    uint8 private s_maxDelay; // Max block delay from commitment to execution (ex. 3 blocks)

    mapping(bytes32 => uint256) private s_commitmentReceived;

    event TradeCommitted(bytes32 commitment);
    event TradeExecuted(
        bytes32 currencySrc,
        bytes32 currencyDst,
        uint256 amountSrc,
        uint256 minAmountDst,
        address sender,
        address receiver,
        int192 median
    );
    event SetDelay(uint8 maxDelay);
    event SetLookupURL(string url);
    event SetVerifierProxy(IVerifierProxy verifierProxyAddress);

    error OffchainLookup(
        address sender,
        string[] urls,
        bytes callData,
        bytes4 callbackFunction,
        bytes extraData
    );
    error TradeExceedsWindow(uint256 blocknumber, uint256 tradeWindow);
    error FeedIDMismatch(bytes32 reportFeedID, bytes32 commitmentFeedID);
    error ReportBlockMismatch(
        uint256 reportBlocknumber,
        uint256 commitmentBlocknumber
    );

    constructor(
        IVerifierProxy verifierProxyAddress,
        string memory lookupURL,
        uint8 maxDelay
    ) ConfirmedOwner(msg.sender) {
        s_verifierProxyAddress = verifierProxyAddress;
        s_lookupURL = abi.encode(lookupURL);
        s_maxDelay = maxDelay;
    }

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId)
        external
        pure
        override
        returns (bool)
    {
        return
            interfaceId ==
            this.commitTrade.selector ^
                this.resolveTrade.selector ^
                this.resolveTradeWithReport.selector ^
                this.getDelay.selector ^
                this.setDelay.selector ^
                this.getLookupURL.selector ^
                this.setLookupURL.selector ^
                this.getVerifierProxyAddress.selector ^
                this.setVerifierProxyAddress.selector;
    }

    /// @inheritdoc TypeAndVersionInterface
    function typeAndVersion() external pure override returns (string memory) {
        return "Exchanger 0.0.1";
    }

    /// @inheritdoc IExchanger
    function commitTrade(bytes32 commitment) external {
        s_commitmentReceived[commitment] = block.number;

        // Optionally perform other protocol functions

        emit TradeCommitted(commitment);
    }

    /// @inheritdoc IExchanger
    function resolveTrade(Commitment memory commitment) external view {
        bytes32 commitmentHash = keccak256(
            abi.encode(
                commitment.feedID,
                commitment.currencySrc,
                commitment.currencyDst,
                commitment.amountSrc,
                commitment.minAmountDst,
                commitment.sender,
                commitment.receiver
            )
        );

        uint256 commitmentBlock = s_commitmentReceived[commitmentHash];

        string[] memory readUrl = new string[](1);
        readUrl[0] = _ccipReadURL(commitment.feedID, commitmentBlock);

        // EIP 3668 offchain-lookup error https://eips.ethereum.org/EIPS/eip-3668
        revert OffchainLookup(
            msg.sender,
            readUrl,
            "",
            this.resolveTradeWithReport.selector,
            abi.encode(commitment)
        );
    }

    // Example for feedID = "ETH-USD": https://<mercury host>/?feedIDHex=0x2430f68ea2e8d4151992bb7fc3a4c472087a6149bf7e0232704396162ab7c1f7&L2Blocknumber=1000
    function _ccipReadURL(bytes32 feedID, uint256 commitmentBlock)
        private
        view
        returns (string memory url)
    {
        return
            string(
                abi.encodePacked(
                    s_lookupURL,
                    "?feedIDHex=",
                    Strings.toHexString(uint256(feedID)),
                    "&L2Blocknumber=",
                    Strings.toString(commitmentBlock)
                )
            );
    }

    /// @inheritdoc IExchanger
    function resolveTradeWithReport(
        bytes memory chainlinkBlob,
        bytes memory encodedCommitment
    ) external {
        Commitment memory commitment = abi.decode(
            encodedCommitment,
            (Commitment)
        );
        bytes32 commitmentHash = keccak256(
            abi.encode(
                commitment.feedID,
                commitment.currencySrc,
                commitment.currencyDst,
                commitment.amountSrc,
                commitment.minAmountDst,
                commitment.sender,
                commitment.receiver
            )
        );

        if (block.number > s_commitmentReceived[commitmentHash] + s_maxDelay)
            revert TradeExceedsWindow(
                block.number,
                s_commitmentReceived[commitmentHash] + s_maxDelay
            );

        bytes memory verifierResponse = IVerifierProxy(s_verifierProxyAddress)
            .verify(chainlinkBlob);

        (
            bytes32 feedID,
            int192 median,
            uint64 observationsBlocknumber,
            uint32 observationsTimestamp
        ) = abi.decode(verifierResponse, (bytes32, int192, uint64, uint32));

        if (feedID != commitment.feedID)
            revert FeedIDMismatch(feedID, commitment.feedID);

        if (observationsBlocknumber != s_commitmentReceived[commitmentHash])
            revert ReportBlockMismatch(
                observationsBlocknumber,
                s_commitmentReceived[commitmentHash]
            );

        emit TradeExecuted(
            commitment.currencySrc,
            commitment.currencyDst,
            commitment.amountSrc,
            commitment.minAmountDst,
            commitment.sender,
            commitment.receiver,
            median
        );
    }

    /// @inheritdoc IExchanger
    function getDelay() external view returns (uint8 maxDelay) {
        return s_maxDelay;
    }

    /// @inheritdoc IExchanger
    function setDelay(uint8 maxDelay) external onlyOwner {
        s_maxDelay = maxDelay;
        emit SetDelay(s_maxDelay);
    }

    /// @inheritdoc IExchanger
    function getLookupURL() external view returns (string memory url) {
        return abi.decode(s_lookupURL, (string));
    }

    /// @inheritdoc IExchanger
    function setLookupURL(string memory url) external onlyOwner {
        s_lookupURL = abi.encodePacked(url);
        emit SetLookupURL(url);
    }

    /// @inheritdoc IExchanger
    function getVerifierProxyAddress()
        external
        view
        returns (IVerifierProxy verifierProxyAddress)
    {
        return s_verifierProxyAddress;
    }

    /// @inheritdoc IExchanger
    function setVerifierProxyAddress(IVerifierProxy verifierProxyAddress)
        external
        onlyOwner
    {
        s_verifierProxyAddress = verifierProxyAddress;
        emit SetVerifierProxy(s_verifierProxyAddress);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC165} from "openzeppelin-contracts/interfaces/IERC165.sol";
import {IVerifierProxy} from "./IVerifierProxy.sol";

interface IExchanger is IERC165 {
    struct Commitment {
        bytes32 feedID;
        bytes32 currencySrc;
        bytes32 currencyDst;
        uint256 amountSrc;
        uint256 minAmountDst;
        address sender;
        address receiver;
    }

    /**
     * @notice Allows user to commit to a trade with the current block number saved.
     * @param commitment The keccak256 hashed commitment.
     */
    function commitTrade(bytes32 commitment) external;

    /** @notice Client can call this to fetch offchain price feed report
     * from the server URL by reverting with OffchainLookup error.
     * @param commitment Original struct for the commitment params
     */
    function resolveTrade(Commitment memory commitment) external view;

    /** @notice Callback for resolveTrade to resolve the trade using the
     * fetched report digest. Validates that the original commitment
     * meets all requirements before trade is executed.
     * @param chainlinkBlob Blob from the report server containing signed
     * price report for a given block.
     * @param encodedCommitment Encoded commitment details from resolveTrade.
     */
    function resolveTradeWithReport(
        bytes memory chainlinkBlob,
        bytes memory encodedCommitment
    ) external;

    /** @notice Get the maximum number of blocks that the execution block
     * can be delayed from the commitment block.
     * @return maxDelay Maximum delay in blocks
     */
    function getDelay() external view returns (uint8 maxDelay);

    /** @notice Set the maximum number of blocks that the execution block
     * can be delayed from the commitment block.
     * @param maxDelay Maximum delay in blocks
     */
    function setDelay(uint8 maxDelay) external;

    /** @notice Get the lookup URL for the server that returns price
     * report digests.
     * @return url Offchain lookup URL
     */
    function getLookupURL() external view returns (string memory url);

    /** @notice Set the lookup URL for the server that returns price
     * report digests.
     * @param url String base URL for the offchain server (ex. https://host.server/)
     */
    function setLookupURL(string memory url) external;

    /** @notice Set the Verifier Proxy Address.
     * @return verifierProxyAddress Address of the VerifierProxy contract
     */
    function getVerifierProxyAddress()
        external
        view
        returns (IVerifierProxy verifierProxyAddress);

    /** @notice Set the Verifier Proxy Address.
     * @param verifierProxyAddress Address of the VerifierProxy contract
     */
    function setVerifierProxyAddress(IVerifierProxy verifierProxyAddress)
        external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

interface IVerifierProxy {
    /**
     * @notice Verifies that the data encoded has been signed
     * correctly by routing to the correct verifier.
     * @param signedReport The encoded data to be verified.
     * @return verifierResponse The encoded response from the verifier.
     */
    function verify(bytes memory signedReport)
        external
        returns (bytes memory verifierResponse);

    /**
     * @notice Sets a new verifier for a config digest
     * @param configDigest The config digest to set
     * @param verifierAddr The address of the valdiator contract that verifies
     * reports for a given config digest.
     */
    function setVerifier(bytes32 configDigest, address verifierAddr) external;

    /**
     * @notice Removes a verifier
     * @param configDigest The config digest of the verifier to remove
     */
    function unsetVerifier(bytes32 configDigest) external;

    /**
     * @notice Retrieves the verifier address that verifies reports
     * for a config digest.
     * @param configDigest The config digest to query for
     * @return verifierAddr The address of the valdiator contract that verifies
     * reports for a given config digest.
     */
    function getVerifier(bytes32 configDigest)
        external
        view
        returns (address verifierAddr);
}