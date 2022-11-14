/**
 *Submitted for verification at Etherscan.io on 2022-11-14
*/

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/Math.sol


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
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Strings.sol


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

// File: @chainlink/contracts/src/v0.8/interfaces/VRFV2WrapperInterface.sol


pragma solidity ^0.8.0;

interface VRFV2WrapperInterface {
  /**
   * @return the request ID of the most recent VRF V2 request made by this wrapper. This should only
   * be relied option within the same transaction that the request was made.
   */
  function lastRequestId() external view returns (uint256);

  /**
   * @notice Calculates the price of a VRF request with the given callbackGasLimit at the current
   * @notice block.
   *
   * @dev This function relies on the transaction gas price which is not automatically set during
   * @dev simulation. To estimate the price at a specific gas price, use the estimatePrice function.
   *
   * @param _callbackGasLimit is the gas limit used to estimate the price.
   */
  function calculateRequestPrice(uint32 _callbackGasLimit) external view returns (uint256);

  /**
   * @notice Estimates the price of a VRF request with a specific gas limit and gas price.
   *
   * @dev This is a convenience function that can be called in simulation to better understand
   * @dev pricing.
   *
   * @param _callbackGasLimit is the gas limit used to estimate the price.
   * @param _requestGasPriceWei is the gas price in wei used for the estimation.
   */
  function estimateRequestPrice(uint32 _callbackGasLimit, uint256 _requestGasPriceWei) external view returns (uint256);
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

// File: @chainlink/contracts/src/v0.8/VRFV2WrapperConsumerBase.sol


pragma solidity ^0.8.0;



/** *******************************************************************************
 * @notice Interface for contracts using VRF randomness through the VRF V2 wrapper
 * ********************************************************************************
 * @dev PURPOSE
 *
 * @dev Create VRF V2 requests without the need for subscription management. Rather than creating
 * @dev and funding a VRF V2 subscription, a user can use this wrapper to create one off requests,
 * @dev paying up front rather than at fulfillment.
 *
 * @dev Since the price is determined using the gas price of the request transaction rather than
 * @dev the fulfillment transaction, the wrapper charges an additional premium on callback gas
 * @dev usage, in addition to some extra overhead costs associated with the VRFV2Wrapper contract.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFV2WrapperConsumerBase. The consumer must be funded
 * @dev with enough LINK to make the request, otherwise requests will revert. To request randomness,
 * @dev call the 'requestRandomness' function with the desired VRF parameters. This function handles
 * @dev paying for the request based on the current pricing.
 *
 * @dev Consumers must implement the fullfillRandomWords function, which will be called during
 * @dev fulfillment with the randomness result.
 */
abstract contract VRFV2WrapperConsumerBase {
  LinkTokenInterface internal immutable LINK;
  VRFV2WrapperInterface internal immutable VRF_V2_WRAPPER;

  /**
   * @param _link is the address of LinkToken
   * @param _vrfV2Wrapper is the address of the VRFV2Wrapper contract
   */
  constructor(address _link, address _vrfV2Wrapper) {
    LINK = LinkTokenInterface(_link);
    VRF_V2_WRAPPER = VRFV2WrapperInterface(_vrfV2Wrapper);
  }

  /**
   * @dev Requests randomness from the VRF V2 wrapper.
   *
   * @param _callbackGasLimit is the gas limit that should be used when calling the consumer's
   *        fulfillRandomWords function.
   * @param _requestConfirmations is the number of confirmations to wait before fulfilling the
   *        request. A higher number of confirmations increases security by reducing the likelihood
   *        that a chain re-org changes a published randomness outcome.
   * @param _numWords is the number of random words to request.
   *
   * @return requestId is the VRF V2 request ID of the newly created randomness request.
   */
  function requestRandomness(
    uint32 _callbackGasLimit,
    uint16 _requestConfirmations,
    uint32 _numWords
  ) internal returns (uint256 requestId) {
    LINK.transferAndCall(
      address(VRF_V2_WRAPPER),
      VRF_V2_WRAPPER.calculateRequestPrice(_callbackGasLimit),
      abi.encode(_callbackGasLimit, _requestConfirmations, _numWords)
    );
    return VRF_V2_WRAPPER.lastRequestId();
  }

  /**
   * @notice fulfillRandomWords handles the VRF V2 wrapper response. The consuming contract must
   * @notice implement it.
   *
   * @param _requestId is the VRF V2 request ID.
   * @param _randomWords is the randomness result.
   */
  function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal virtual;

  function rawFulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) external {
    require(msg.sender == address(VRF_V2_WRAPPER), "only VRF V2 wrapper can fulfill");
    fulfillRandomWords(_requestId, _randomWords);
  }
}

// File: @chainlink/contracts/src/v0.8/interfaces/OwnableInterface.sol


pragma solidity ^0.8.0;

interface OwnableInterface {
  function owner() external returns (address);

  function transferOwnership(address recipient) external;

  function acceptOwnership() external;
}

// File: @chainlink/contracts/src/v0.8/ConfirmedOwnerWithProposal.sol


pragma solidity ^0.8.0;


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

// File: @chainlink/contracts/src/v0.8/ConfirmedOwner.sol


pragma solidity ^0.8.0;


/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwner is ConfirmedOwnerWithProposal {
  constructor(address newOwner) ConfirmedOwnerWithProposal(newOwner, address(0)) {}
}

// File: item-maker.sol


pragma solidity ^0.8.13;




interface itemDescriber {
    function calculateCombatRating(uint256, uint256, uint256)external returns (uint256);
    function describeItem(uint256, uint256, uint256, uint256) external returns (string memory); //QR, CR, Item Type, Material
}
interface itemMaker {
    function setBuild(bool, bool, bool, bool, bool, bool, bool, bool) external; //_jewelry, _helmet, _sword, _platinum, _gold, _copper, _nickel, _iron) 
    function setValues (string memory, string memory, string memory, string memory) external; //_itemType, _material, _quality, _armorClass 
    function setDescription(string memory) external; //owner, spender
    function safeMint(address) external;
}
interface ironToken {
    function transferFrom(address, address, uint) external returns (bool); //from to amount
    function allowance(address, address) external returns (uint256); //owner, spender
}
interface copperToken {
    function transferFrom(address, address, uint) external returns (bool); //from to amount
    function allowance(address, address) external returns (uint256); //owner, spender
}
interface nickelToken {
    function transferFrom(address, address, uint) external returns (bool); //from to amount
    function allowance(address, address) external returns (uint256); //owner, spender
}
interface goldToken {
    function transferFrom(address, address, uint) external returns (bool); //from to amount
    function allowance(address, address) external returns (uint256); //owner, spender
}
interface platinumToken {
    function transferFrom(address, address, uint) external returns (bool); //from to amount
    function allowance(address, address) external returns (uint256); //owner, spender
}
interface wETHContract {
    function deposit() external payable;
    function transfer(address, uint) external;
    function withdraw(uint256) external;
    function approve(address, uint) external;
}
interface SwapContract {
    function setUserAddress(address) external;
    function setOreAmount(uint256) external;
    function swapExactOutputSingle(uint256, uint256) external;
}

contract ItemMakerContract is VRFV2WrapperConsumerBase, ConfirmedOwner{
    using Strings for uint256;
    event RequestFulfilled(uint256 requestId, uint256 randomNum, address requestor);

    wETHContract internal constant weth = wETHContract(0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6);
    SwapContract internal constant swCon = SwapContract(0x3cEc895e2802E1A2e731e87A476e63682C7BdF4a);

    address internal itemDescriberContractAddress = 0xE93fDFaB027cb135eF2d8419214498918B7d98E4;
    itemDescriber itemDescriberContract = itemDescriber(itemDescriberContractAddress);

    address internal itemMakerContractAddress = 0x54630734636bA61Dd1Ede7E4481Ab0F36ABBDF0D;
    itemMaker itemMakerContract = itemMaker(itemMakerContractAddress);

    address internal ironContractAddress = 0xd020ee009eBa367b279546C9Ed47Ba49A0Bcb159;
    ironToken iTC = ironToken(ironContractAddress); //Iron Token

    address internal copperContractAddress = 0x07FC989B730Fd2F6Fe72c9A3294213cea3DA768e;
    copperToken cTC = copperToken(copperContractAddress); //Copper Token

    address internal nickelContractAddress = 0x2efe634FAD801A68b86Bbbf153935fd6222A1236;
    nickelToken nTC = nickelToken(nickelContractAddress); //Nickel Token

    address internal goldContractAddress = 0x01F1Fb3293546e257c7fa94fF04B5ab314bdEe50;
    goldToken gTC = goldToken(goldContractAddress); //Gold Token

    address internal platinumContractAddress = 0xffb97Dc57c5D891560aAE5AF5460Fcf69a217E64;
    platinumToken pTC = platinumToken(platinumContractAddress); //Platinum Token

    address internal msgSender;

    uint256 public linkIn = 1300000000000000000;
    uint256 internal whichItem;
    uint256 internal whichMetal;
    uint256 internal flatRanNum1;
    uint256 internal flatRanNum2;
    uint256 internal flatRanNum3;
    uint256 internal ironCount;
    uint256 internal ironAllowance;
    uint256 internal nickelCount;
    uint256 internal nickelAllowance;
    uint256 internal copperCount;
    uint256 internal copperAllowance;
    uint256 internal goldCount;
    uint256 internal goldAllowance;
    uint256 internal platinumCount;
    uint256 internal platinumAllowance;

    string internal combatRating;
    string internal qualityScore;

    uint256 internal jewelryCost;
    uint256 internal helmetCost;
    uint256 internal swordCost;

    string internal fullDesc;
   
    mapping(uint256 => uint256) public mapIdToWord1; //Quality to ID
    mapping(uint256 => uint256) public mapIdToWord2; //CR to ID
    mapping(uint256 => uint256) public mapIdToItem; //ID to Item
    mapping(uint256 => uint256) public mapIdToMetal; //ID to Metal
    mapping(uint256 => address) public mapIdToAddress; //Address to ID
    mapping(uint256 => bool) public mapIdToFulfilled; //Completion Status to ID
    
    uint256 public lastRequestID;

    uint32 callbackGasLimit = 800000;
    uint16 requestConfirmations = 3;
    
    // Address LINK - hardcoded for Goerli
    address linkAddress = 0x326C977E6efc84E512bB9C30f76E30c160eD06FB;
    // address WRAPPER - hardcoded for Goerli
    address wrapperAddress = 0x708701a1DfF4f478de54383E49a627eD4852C816;

    constructor() ConfirmedOwner(msg.sender) VRFV2WrapperConsumerBase(linkAddress, wrapperAddress) payable{
        jewelryCost = 10;
        helmetCost = 100;
        swordCost = 200;
    }
    function getLINKandMint(uint256 _whichItem, uint256 _whichMetal) private{
        bool sT = false; //Successful Transfer

        if (_whichItem == 1){     
            if (_whichMetal == 1){
                sT = pTC.transferFrom(msg.sender, address(this), jewelryCost);
            }
            else if (_whichMetal == 2){
                sT = gTC.transferFrom(msg.sender, address(this), jewelryCost);
            }
            else if (_whichMetal == 3){
                sT = cTC.transferFrom(msg.sender, address(this), jewelryCost);
            }
            else if (_whichMetal == 4){
                sT = nTC.transferFrom(msg.sender, address(this), jewelryCost);
            }
            else if (_whichMetal == 5){
                sT = iTC.transferFrom(msg.sender, address(this), jewelryCost);
            }
        }
        else if (_whichItem == 2){     
            if (_whichMetal == 1){
                sT = pTC.transferFrom(msg.sender, address(this), helmetCost);
            }
            else if (_whichMetal == 2){
                sT = gTC.transferFrom(msg.sender, address(this), helmetCost);
            }
            else if (_whichMetal == 3){
                sT = cTC.transferFrom(msg.sender, address(this), helmetCost);
            }
            else if (_whichMetal == 4){
                sT = nTC.transferFrom(msg.sender, address(this), helmetCost);
            }
            else if (_whichMetal == 5){
                sT = iTC.transferFrom(msg.sender, address(this), helmetCost);
            }
        }
        else if (_whichItem == 3){     
            if (_whichMetal == 1){
                sT = pTC.transferFrom(msg.sender, address(this), swordCost);
            }
            else if (_whichMetal == 2){
                sT = gTC.transferFrom(msg.sender, address(this), swordCost);
            }
            else if (_whichMetal == 3){
                sT = cTC.transferFrom(msg.sender, address(this), swordCost);
            }
            else if (_whichMetal == 4){
                sT = nTC.transferFrom(msg.sender, address(this), swordCost);
            }
            else if (_whichMetal == 5){
                sT = iTC.transferFrom(msg.sender, address(this), swordCost);
            }
        }
        
        if (sT){
            whichItem = _whichItem;
            whichMetal = _whichMetal;     
            //Mint Random Token
            requestRandomWords();
        }

    }
    function makeItem(uint256 _whichItem, uint256 _whichMetal) external payable {
        //1 platinum, 2 gold, 3 copper, 4 nickel, 5 iron || 1 jewelry, 2 helmet, 3 sword
        msgSender = msg.sender;
        weth.deposit{value: msg.value}();
        weth.approve(address(swCon), msg.value);
        swCon.swapExactOutputSingle(linkIn, msg.value);

        //Jewelry
        if (_whichItem == 1){
            if (_whichMetal == 1){
                //Check Allowance
                platinumAllowance = pTC.allowance(msg.sender, address(this));
                require (platinumAllowance >= jewelryCost, "Not enough PLATINUM approved.");
                getLINKandMint(1,1); 
            }
            else if (_whichMetal == 2){
                //Check Allowance
                goldAllowance = gTC.allowance(msg.sender, address(this));
                require (goldAllowance >= jewelryCost, "Not enough GOLD approved.");
                getLINKandMint(1,2); 
            }
            else if (_whichMetal == 3){
                //Check Allowance
                copperAllowance = cTC.allowance(msg.sender, address(this));
                require (copperAllowance >= jewelryCost, "Not enough COPPER approved."); 
                getLINKandMint(1,3); 
            }
            else if (_whichMetal == 4){
                //Check Allowance
                nickelAllowance = nTC.allowance(msg.sender, address(this));
                require (nickelAllowance >= jewelryCost, "Not enough NICKEL approved.");
                getLINKandMint(1,4); 
            }
            else if (_whichMetal == 5){
                //Check Allowance
                ironAllowance = iTC.allowance(msg.sender, address(this));
                require (ironAllowance >= jewelryCost, "Not enough IRON approved.");
                getLINKandMint(1,5); 
            }
        }
        //Helmet
        else if (_whichItem == 2){
            if (_whichMetal == 1){
                //Check Allowance
                platinumAllowance = pTC.allowance(msg.sender, address(this));
                require (platinumAllowance >= helmetCost, "Not enough PLATINUM approved.");
                getLINKandMint(2,1); 
            }
            else if (_whichMetal == 2){
                //Check Allowance
                goldAllowance = gTC.allowance(msg.sender, address(this));
                require (goldAllowance >= helmetCost, "Not enough GOLD approved."); 
                getLINKandMint(2,2); 
            }
            else if (_whichMetal == 3){
                //Check Allowance
                copperAllowance = cTC.allowance(msg.sender, address(this));
                require (copperAllowance >= helmetCost, "Not enough COPPER approved.");
                getLINKandMint(2,3); 
            }
            else if (_whichMetal == 4){
                //Check Allowance
                nickelAllowance = nTC.allowance(msg.sender, address(this));
                require (nickelAllowance >= helmetCost, "Not enough NICKEL approved.");
                getLINKandMint(2,4); 
            }
            else if (_whichMetal == 5){
                //Check Allowance
                ironAllowance = iTC.allowance(msg.sender, address(this));
                require (ironAllowance >= helmetCost, "Not enough IRON approved.");
                getLINKandMint(2,5); 
            }
        }
        //Sword
        else if (_whichItem == 3){
            if (_whichMetal == 1){
                //Check Allowance
                platinumAllowance = pTC.allowance(msg.sender, address(this));
                require (platinumAllowance >= swordCost, "Not enough PLATINUM approved.");
                getLINKandMint(3,1); 
            }
            else if (_whichMetal == 2){
                //Check Allowance
                goldAllowance = gTC.allowance(msg.sender, address(this));
                require (goldAllowance >= swordCost, "Not enough GOLD approved.");
                getLINKandMint(3,2);  
            }
            else if (_whichMetal == 3){
                //Check Allowance
                copperAllowance = cTC.allowance(msg.sender, address(this));
                require (copperAllowance >= swordCost, "Not enough COPPER approved."); 
                getLINKandMint(3,3); 
            }
            else if (_whichMetal == 4){
                //Check Allowance
                nickelAllowance = nTC.allowance(msg.sender, address(this));
                require (nickelAllowance >= swordCost, "Not enough NICKEL approved.");
                getLINKandMint(3,4); 
            }
            else if (_whichMetal == 5){
                //Check Allowance
                ironAllowance = iTC.allowance(msg.sender, address(this));
                require (ironAllowance >= swordCost, "Not enough IRON approved.");
                getLINKandMint(3,5); 
            }
        }
    }

    function setLinkIn(uint256 _linkIn) public onlyOwner {
        linkIn = _linkIn;
    }
    
    function requestRandomWords() private returns (uint256 requestId) {
        requestId = requestRandomness(callbackGasLimit, requestConfirmations, 2);
    
        //New Ones
        mapIdToAddress[requestId] = msg.sender;
        mapIdToItem[requestId] = whichItem;
        mapIdToMetal[requestId] = whichMetal;
        mapIdToFulfilled[requestId] = false;
        lastRequestID = requestId;
        return requestId;
    }

    function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal override {
        require(mapIdToFulfilled[_requestId] == false, 'request fulfilled already');
        mapIdToFulfilled[_requestId] = true;
        flatRanNum1 = (_randomWords[0] % 100) + 1; //Quality
        flatRanNum2 = (_randomWords[1] % 60) + 1; //Combat Rating
        mapIdToWord1[_requestId] = flatRanNum1; //Store it.
        mapIdToWord2[_requestId] = flatRanNum2; //Store it.
        mintItem(_requestId);
        //emit RequestFulfilled(_requestId, flatRanNum, mapIdToAddress[_requestId]); //ID, NUM, Requestor
    }

    function mintItem(uint256 _requestId) private{
        
        //Call Describe Function Here;
        uint256 totalCR = itemDescriberContract.calculateCombatRating(mapIdToWord1[_requestId], mapIdToWord2[_requestId], mapIdToMetal[_requestId]); //uint256 _qualityRating, uint256 _combatRating, uint256 _itemMaterial
        fullDesc = itemDescriberContract.describeItem(mapIdToWord1[_requestId], mapIdToWord2[_requestId],mapIdToItem[_requestId],mapIdToMetal[_requestId]);   //QR, CR, Item Type, Material);

        //Set Description
        itemMakerContract.setDescription(fullDesc);
        
        //Stringify These for Base64 Conversion in Item Metadata
        qualityScore = mapIdToWord1[_requestId].toString();
        combatRating = totalCR.toString();


       //Jewelry
       if (mapIdToItem[_requestId] == 1){
           if (mapIdToMetal[_requestId] == 1){
               itemMakerContract.setBuild(true, false, false, true, false, false, false, false); //_jewelry, _helmet, _sword, _platinum, _gold, _copper, _nickel, _iron)
               itemMakerContract.setValues ("Jewelry", "Platinum", qualityScore, combatRating); //_itemType, _material, _quality, _armorClass
           }
           else if (mapIdToMetal[_requestId] == 2){
               itemMakerContract.setBuild(true, false, false, false, true, false, false, false);
               itemMakerContract.setValues ("Jewelry", "Gold", qualityScore, combatRating);
           }
           else if (mapIdToMetal[_requestId] == 3){
               itemMakerContract.setBuild(true, false, false, false, false, true, false, false);
               itemMakerContract.setValues ("Jewelry", "Copper", qualityScore, combatRating);
           }
           else if (mapIdToMetal[_requestId] == 4){
               itemMakerContract.setBuild(true, false, false, false, false, false, true, false);
               itemMakerContract.setValues ("Jewelry", "Nickel", qualityScore, combatRating);
           }
           else if (mapIdToMetal[_requestId] == 5){
               itemMakerContract.setBuild(true, false, false, false, false, false, false, true);
               itemMakerContract.setValues ("Jewelry", "Iron", qualityScore, combatRating);
           }   
       }
       //Helmet
       else if (mapIdToItem[_requestId] == 2){
           if (mapIdToMetal[_requestId] == 1){
               itemMakerContract.setBuild(false, true, false, true, false, false, false, false); //_jewelry, _helmet, _sword, _platinum, _gold, _copper, _nickel, _iron)
               itemMakerContract.setValues ("Helmet", "Platinum", qualityScore, combatRating); //_itemType, _material, _quality, _armorClass
           }
           else if (mapIdToMetal[_requestId] == 2){
               itemMakerContract.setBuild(false, true, false, false, true, false, false, false);
               itemMakerContract.setValues ("Helmet", "Gold", qualityScore, combatRating);
           }
           else if (mapIdToMetal[_requestId] == 3){
               itemMakerContract.setBuild(false, true, false, false, false, true, false, false);
               itemMakerContract.setValues ("Helmet", "Copper", qualityScore, combatRating);
           }
           else if (mapIdToMetal[_requestId] == 4){
               itemMakerContract.setBuild(false, true, false, false, false, false, true, false);
               itemMakerContract.setValues ("Helmet", "Nickel", qualityScore, combatRating);
           }
           else if (mapIdToMetal[_requestId] == 5){
               itemMakerContract.setBuild(false, true, false, false, false, false, false, true);
               itemMakerContract.setValues ("Helmet", "Iron", qualityScore, combatRating);
           }  
       }
       //Sword
       else if (mapIdToItem[_requestId] == 3){
           if (mapIdToMetal[_requestId] == 1){
               itemMakerContract.setBuild(false, false, true, true, false, false, false, false); 
               itemMakerContract.setValues ("Sword", "Platinum", qualityScore, combatRating); 
           }
           else if (mapIdToMetal[_requestId] == 2){
               itemMakerContract.setBuild(false, false, true, false, true, false, false, false);
               itemMakerContract.setValues ("Sword", "Gold", qualityScore, combatRating);
           }
           else if (mapIdToMetal[_requestId] == 3){
               itemMakerContract.setBuild(false, false, true, false, false, true, false, false);
               itemMakerContract.setValues ("Sword", "Copper", qualityScore, combatRating);
           }
           else if (mapIdToMetal[_requestId] == 4){
               itemMakerContract.setBuild(false, false, true, false, false, false, true, false);
               itemMakerContract.setValues ("Sword", "Nickel", qualityScore, combatRating);
           }
           else if (mapIdToMetal[_requestId] == 5){
               itemMakerContract.setBuild(false, false, true, false, false, false, false, true);
               itemMakerContract.setValues ("Sword", "Iron", qualityScore, combatRating);
           }  
       }
       itemMakerContract.safeMint(mapIdToAddress[_requestId]);
       withdrawLink();
    }
    
    function changeItemMakerContractOwnership(address _itemMakerContractAddress) public onlyOwner {
        itemMakerContractAddress = _itemMakerContractAddress;
    }
    function changeItemDescriberContractOwnership(address _itemDescriberContractAddress) public onlyOwner {
        itemDescriberContractAddress = _itemDescriberContractAddress;
    }
    function changeJewleryCost(uint256 _jewelryCost) public onlyOwner{
        jewelryCost = _jewelryCost;
    }
    function changeHelmetCost(uint256 _helmetCost) public onlyOwner{
        helmetCost = _helmetCost;
    }
    function changeSwordCost(uint256 _swordCost) public onlyOwner{
        swordCost = _swordCost;
    }
    function withdrawLink() public {
        LinkTokenInterface link = LinkTokenInterface(linkAddress);
        require(link.transfer(address(owner()), link.balanceOf(address(this))), 'Unable to transfer');
    }
}