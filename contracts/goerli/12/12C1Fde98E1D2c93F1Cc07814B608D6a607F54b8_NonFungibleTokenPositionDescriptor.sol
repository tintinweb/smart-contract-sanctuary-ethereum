// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

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

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides a function for encoding some bytes in base64
library Base64 {
    string internal constant TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';
        
        // load the table into memory
        string memory table = TABLE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)
            
            // prepare the lookup table
            let tablePtr := add(table, 1)
            
            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))
            
            // result ptr, jump over length
            let resultPtr := add(result, 32)
            
            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
               dataPtr := add(dataPtr, 3)
               
               // read 3 bytes
               let input := mload(dataPtr)
               
               // write 4 characters
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr( 6, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(        input,  0x3F)))))
               resultPtr := add(resultPtr, 1)
            }
            
            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }
        
        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;



/**
 * @title The interface for generating a description for a staking position in Staking Hub
 * @notice Contracts that implement this interface must return a base64 JSON with the entire description
 */

interface IStakingHubNFTDescriptor {
  /**
   * @notice Generates a staking position's description, both the JSON and the image inside
   * @param hub The address of the staking hub
   * @param stakingPositionId The id of the staking position
   * @return The URI of the ERC721-compliant metadata
   */
  function tokenURI(address hub, uint256 stakingPositionId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IStakingHubPositionManager {

  struct StakingPosition {
    uint256 amount;
    uint256 unclaimedReward;
    uint256 createdAt;
    uint256 updatedAt;
  }

  /**
   * @notice Return the staking position for the given id
   * @dev Will revert :
   *        - TokenId doesn't exist
   * @param tokenId The id of the staking position token
   * @return stakingPosition position The staking position itself
   */
  function getStakingPosition(uint256 tokenId) external view returns (StakingPosition memory stakingPosition);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

import '@openzeppelin/contracts/utils/Strings.sol';

// Based on Uniswap's NFTDescriptor
library DescriptorUtils {
  using Strings for uint256;
  using Strings for uint32;

  function fixedPointToDecimalString(uint256 _value, uint8 _decimals) internal pure returns (string memory) {
    if (_value == 0) {
      return '0.0000';
    }

    bool _priceBelow1 = _value < 10**_decimals;

    // get digit count
    uint256 _temp = _value;
    uint8 _digits;
    while (_temp != 0) {
      _digits++;
      _temp /= 10;
    }
    // don't count extra digit kept for rounding
    _digits = _digits - 1;

    // address rounding
    (uint256 _sigfigs, bool _extraDigit) = _sigfigsRounded(_value, _digits);
    if (_extraDigit) {
      _digits++;
    }

    DecimalStringParams memory _params;
    if (_priceBelow1) {
      // 7 bytes ( "0." and 5 sigfigs) + leading 0's bytes
      _params.bufferLength = _digits >= 5 ? _decimals - _digits + 6 : _decimals + 2;
      _params.zerosStartIndex = 2;
      _params.zerosEndIndex = _decimals - _digits + 1;
      _params.sigfigIndex = _params.bufferLength - 1;
    } else if (_digits >= _decimals + 4) {
      // no decimal in price string
      _params.bufferLength = _digits - _decimals + 1;
      _params.zerosStartIndex = 5;
      _params.zerosEndIndex = _params.bufferLength - 1;
      _params.sigfigIndex = 4;
    } else {
      // 5 sigfigs surround decimal
      _params.bufferLength = 6;
      _params.sigfigIndex = 5;
      _params.decimalIndex = _digits - _decimals + 1;
    }
    _params.sigfigs = _sigfigs;
    _params.isLessThanOne = _priceBelow1;

    return _generateDecimalString(_params);
  }

  function addressToString(address _addr) internal pure returns (string memory) {
    bytes memory _s = new bytes(40);
    for (uint256 _i = 0; _i < 20; _i++) {
      bytes1 _b = bytes1(uint8(uint256(uint160(_addr)) / (2**(8 * (19 - _i)))));
      bytes1 _hi = bytes1(uint8(_b) / 16);
      bytes1 _lo = bytes1(uint8(_b) - 16 * uint8(_hi));
      _s[2 * _i] = _char(_hi);
      _s[2 * _i + 1] = _char(_lo);
    }
    return string(abi.encodePacked('0x', string(_s)));
  }

  struct DecimalStringParams {
    // significant figures of decimal
    uint256 sigfigs;
    // length of decimal string
    uint8 bufferLength;
    // ending index for significant figures (funtion works backwards when copying sigfigs)
    uint8 sigfigIndex;
    // index of decimal place (0 if no decimal)
    uint8 decimalIndex;
    // start index for trailing/leading 0's for very small/large numbers
    uint8 zerosStartIndex;
    // end index for trailing/leading 0's for very small/large numbers
    uint8 zerosEndIndex;
    // true if decimal number is less than one
    bool isLessThanOne;
  }

  function _generateDecimalString(DecimalStringParams memory _params) private pure returns (string memory) {
    bytes memory _buffer = new bytes(_params.bufferLength);
    if (_params.isLessThanOne) {
      _buffer[0] = '0';
      _buffer[1] = '.';
    }

    // add leading/trailing 0's
    for (uint256 _zerosCursor = _params.zerosStartIndex; _zerosCursor < _params.zerosEndIndex + 1; _zerosCursor++) {
      _buffer[_zerosCursor] = bytes1(uint8(48));
    }
    // add sigfigs
    while (_params.sigfigs > 0) {
      if (_params.decimalIndex > 0 && _params.sigfigIndex == _params.decimalIndex) {
        _buffer[_params.sigfigIndex--] = '.';
      }
      uint8 _charIndex = uint8(48 + (_params.sigfigs % 10));
      _buffer[_params.sigfigIndex] = bytes1(_charIndex);
      _params.sigfigs /= 10;
      if (_params.sigfigs > 0) {
        _params.sigfigIndex--;
      }
    }
    return string(_buffer);
  }

  function _sigfigsRounded(uint256 _value, uint8 _digits) private pure returns (uint256, bool) {
    bool _extraDigit;
    if (_digits > 5) {
      _value = _value / (10**(_digits - 5));
    }
    bool _roundUp = _value % 10 > 8;
    _value = _value / 10;
    if (_roundUp) {
      _value = _value + 1;
    }
    // 99999 -> 100000 gives an extra sigfig
    if (_value == 100000) {
      _value /= 10;
      _extraDigit = true;
    }
    return (_value, _extraDigit);
  }

  function _char(bytes1 _b) private pure returns (bytes1) {
    if (uint8(_b) < 10) return bytes1(uint8(_b) + 0x30);
    else return bytes1(uint8(_b) + 0x57);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import './libraries/DescriptorUtils.sol';
import 'base64-sol/base64.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import './interfaces/IStakingHubNFTDescriptor.sol';
import './interfaces/IStakingHubPositionManager.sol';

contract NonFungibleTokenPositionDescriptor is IStakingHubNFTDescriptor {
    struct StakingPositionParams {
        string stakingPositionId;
        uint256 stakedAmount;
        uint256 unclaimedReward;
        uint256 createdAt;
    }

    function tokenURI(
        address hub,
        uint256 stakingPositionId
    ) external view override returns (string memory) {
        uint256 timeNow = block.timestamp;
        IStakingHubPositionManager.StakingPosition
            memory _stakingPosition = IStakingHubPositionManager(hub).getStakingPosition(
                stakingPositionId
            );
        return
            _constructTokenURI(
                StakingPositionParams({
                    stakingPositionId: Strings.toString(stakingPositionId),
                    stakedAmount: _stakingPosition.amount,
                    unclaimedReward: _stakingPosition.unclaimedReward,
                    createdAt: _stakingPosition.createdAt
                }),
                timeNow
            );
    }

    function _constructTokenURI(
        StakingPositionParams memory _params,
        uint256 _timeNow
    ) private pure returns (string memory) {
        string memory _name = _generateName(_params);
        string memory _description = _generateDescription();
        bool isStakingTimeMoreThanTwoWeeks = _isMoreThanTwoWeeks(_params.createdAt, _timeNow);
        string memory _image = Base64.encode(
            bytes(_generateSVG(_params, isStakingTimeMoreThanTwoWeeks, _timeNow))
        );
        return
            string(
                abi.encodePacked(
                    'data:application/json;base64,',
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"',
                                _name,
                                '", "description":"',
                                _description,
                                '", "image": "data:image/svg+xml;base64,',
                                _image,
                                '"}'
                            )
                        )
                    )
                )
            );
    }

    function _isMoreThanTwoWeeks(uint256 _date, uint256 _timeNow) private pure returns (bool) {
        return (_date + 2 weeks) < _timeNow;
    }

    function _generateDescription() private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    'This NFT represents a staking position of PERPI tokens. The holder can redeem the token staked and claim the rewards in ETH.\\n\\n',
                    unicode'⚠️ DISCLAIMER: Due diligence is imperative when assessing any digital assets.'
                )
            );
    }

    function _generateName(
        StakingPositionParams memory _params
    ) private pure returns (string memory) {
        return
            string(abi.encodePacked('Perpi Inu Staking Position - #', _params.stakingPositionId));
    }

    function _generateSVG(
        StakingPositionParams memory _params,
        bool _moreThanTwoWeeks,
        uint256 _timeNow
    ) private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    _generateSVGMeta(_moreThanTwoWeeks),
                    _generateStyleDefs(_moreThanTwoWeeks),
                    _generateSVGForm(_moreThanTwoWeeks),
                    _generateSVGStaticText(_moreThanTwoWeeks),
                    _generateSVGData(_params, _moreThanTwoWeeks, _timeNow),
                    _generateSVGShareRatio(_moreThanTwoWeeks),
                    '</svg>'
                )
            );
    }

    function _generateSVGMeta(bool _moreThanTwoWeeks) private pure returns (string memory) {
        if (_moreThanTwoWeeks) {
            return
                string(
                    abi.encodePacked(
                        '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 415 591">'
                    )
                );
        }
        return
            string(
                abi.encodePacked(
                    '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 415.29 591">'
                )
            );
    }

    function _generateStyleDefs(bool _moreThanTwoWeeks) private pure returns (string memory) {
        if (_moreThanTwoWeeks) {
            return
                string(
                    abi.encodePacked(
                        '<defs>',
                        '<style>@import url("https://fonts.googleapis.com/css?family=Poppins:700,300");@import url("https://fonts.googleapis.com/css?family=Barlow:400");.cls-1{fill:url(#gradiant_29);}.cls-2,.cls-3,.cls-4{fill:#fbfbf9;}.cls-3{font-size:72px;}.cls-3,.cls-4{font-family:Poppins-Bold, Poppins;font-weight:700;}.cls-4{font-size:26px;}.cls-13,.cls-15,.cls-5{fill:#fff;}.cls-11,.cls-6,.cls-9{fill:#fcf34f;}.cls-10,.cls-7,.cls-8{fill:#d6cf56;}.cls-10,.cls-11,.cls-7,.cls-8,.cls-9{stroke:#563c1f;}.cls-7{stroke-miterlimit:10;}.cls-10,.cls-11,.cls-7,.cls-9{stroke-width:0.5px;}.cls-8,.cls-9{stroke-miterlimit:10;}.cls-8{stroke-width:0.75px;}.cls-10,.cls-11,.cls-9{stroke-linecap:round;}.cls-10,.cls-11{stroke-linejoin:round;}.cls-12{fill:#fcff88;}.cls-13{font-size:18px;font-family:CoolveticaRg-Regular, Coolvetica;}.cls-14{letter-spacing:-0.05em;}.cls-15{font-size:14px;font-family:Barlow-Regular, Barlow;}.cls-16{letter-spacing:0em;}.cls-17{letter-spacing:-0.01em;}.cls-18{letter-spacing:-0.01em;}.cls-19{letter-spacing:0em;}.cls-20{letter-spacing:0em;}.cls-21{letter-spacing:-0.01em;}</style>',
                        '<radialGradient id="gradiant_29" cx="46.37" cy="27.22" r="653.72" gradientUnits="userSpaceOnUse"><stop offset="0" stop-color="#16c"/><stop offset="1" stop-color="#063d7e"/></radialGradient>',
                        '</defs>'
                    )
                );
        }
        return
            string(
                abi.encodePacked(
                    '<defs>',
                    '<style>@import url("https://fonts.googleapis.com/css?family=Poppins:700,300");@import url("https://fonts.googleapis.com/css?family=Barlow:400");.cls-1{fill:url(#degrade_22);}.cls-2,.cls-3,.cls-4,.cls-5{fill:#fbfbf9;}.cls-3{font-size:72px;}.cls-3,.cls-5{font-family:Poppins-Bold, Poppins;font-weight:700;}.cls-4{font-size:22px;font-family:Poppins-Light, Poppins;font-weight:300;}.cls-5{font-size:26px;}.cls-6{font-size:18px;font-family:CoolveticaRg-Regular, Coolvetica;}.cls-6,.cls-8{fill:#fff;}.cls-7{letter-spacing:-0.05em;}.cls-8{font-size:14px;font-family:Barlow-Regular, Barlow;}.cls-9{letter-spacing:0em;}.cls-10{letter-spacing:-0.01em;}.cls-11{letter-spacing:-0.01em;}.cls-12{letter-spacing:0em;}.cls-13{letter-spacing:0em;}.cls-14{letter-spacing:-0.01em;}</style>',
                    '<radialGradient id="degrade_22" cx="58.79" cy="45.83" r="606.96" gradientUnits="userSpaceOnUse"><stop offset="0" stop-color="#5e96d9"/><stop offset="1" stop-color="#16c"/></radialGradient>',
                    '</defs>'
                )
            );
    }

    function _generateSVGForm(bool _moreThanTwoWeeks) private pure returns (string memory) {
        if (_moreThanTwoWeeks) {
            return
                string(
                    abi.encodePacked('<rect class="cls-1" width="415" height="591" rx="63.29"/>')
                );
        }
        return
            string(
                abi.encodePacked(
                    '<rect class="cls-1" x="0.29" width="415" height="591" rx="63.29"/>'
                )
            );
    }

    function _generateSVGShareRatio(bool _moreThanTwoWeeks) private pure returns (string memory) {
        if (_moreThanTwoWeeks) {
            return
                string(
                    abi.encodePacked(
                        '<path class="cls-5" d="M193.12,63.88a1.89,1.89,0,0,0,0,3.78A1.85,1.85,0,0,0,195,65.77,1.81,1.81,0,0,0,193.12,63.88Z"/><path class="cls-5" d="M163.35,52c-2.89,0-4.3,2.51-4.3,7.15s1.41,7.16,4.3,7.16,4.3-2.51,4.3-7.16S166.24,52,163.35,52Z"/><path class="cls-5" d="M182.7,52.49a1.84,1.84,0,1,0-1.86,1.89A1.86,1.86,0,0,0,182.7,52.49Z"/><path class="cls-5" d="M141.67,52c-2.89,0-4.3,2.51-4.3,7.15s1.41,7.16,4.3,7.16,4.3-2.51,4.3-7.16S144.55,52,141.67,52Z"/><path class="cls-5" d="M255.4,58.4a4.2,4.2,0,1,0,4.09,4.2A3.93,3.93,0,0,0,255.4,58.4Z"/><path class="cls-5" d="M295.18,29.34H119.82a29.82,29.82,0,1,0,0,59.64H295.18a29.82,29.82,0,0,0,0-59.64ZM128.41,71.2h-5.5V52.94l-4.27,1.16-1.34-4.71,6.3-2.27h4.81Zm13.26.49c-6.23,0-9.81-5.1-9.81-12.53s3.58-12.52,9.81-12.52,9.8,5.09,9.8,12.52S147.89,71.69,141.67,71.69Zm21.68,0c-6.23,0-9.8-5.1-9.8-12.53s3.57-12.52,9.8-12.52,9.81,5.09,9.81,12.52S169.58,71.69,163.35,71.69Zm11.54-19.2a5.83,5.83,0,0,1,6-5.85,5.76,5.76,0,0,1,6,5.85,6,6,0,0,1-11.94,0Zm2.86,14.93,15.55-17.2,2.27,1.3L180,68.76Zm15.41,4.2a5.85,5.85,0,1,1,6-5.85A5.84,5.84,0,0,1,193.16,71.62Zm24,.07c-3.44,0-6.05-1.31-7.4-4.1l4.48-2.54a2.82,2.82,0,0,0,2.92,2c1.24,0,1.86-.37,1.86-1.06,0-1.89-8.46-.9-8.46-6.85,0-3.75,3.16-5.64,6.74-5.64A7.53,7.53,0,0,1,224,57.2l-4.41,2.38a2.49,2.49,0,0,0-2.3-1.52c-.9,0-1.45.34-1.45,1,0,2,8.47.66,8.47,7C224.35,70,220.91,71.69,217.19,71.69Zm26.26-.49h-5.16V61.4a2.83,2.83,0,0,0-3-3.13c-1.9,0-3.2,1.1-3.2,3.54V71.2h-5.16V47.12h5.16v8.5a5.87,5.87,0,0,1,4.92-2.1c3.47,0,6.43,2.48,6.43,7.12Zm21.2,0h-5.16V69.59a6.47,6.47,0,0,1-5.12,2.1c-4.51,0-8.23-4-8.23-9.09s3.72-9.08,8.23-9.08a6.44,6.44,0,0,1,5.12,2.1V54h5.16Zm14.12-11.69c-2.13-.35-5.16.51-5.16,3.92V71.2h-5.16V54h5.16v3.06a5.17,5.17,0,0,1,5.16-3.4Zm18.72,5.16H285.28c.65,1.79,2.24,2.4,4.13,2.4a4.47,4.47,0,0,0,3.3-1.3l4.13,2.37a8.74,8.74,0,0,1-7.5,3.55c-5.88,0-9.53-4-9.53-9.09A8.82,8.82,0,0,1,289,53.52c5,0,8.74,3.89,8.74,9.08A9.88,9.88,0,0,1,297.49,64.67Z"/><path class="cls-5" d="M288.93,58.1a3.55,3.55,0,0,0-3.75,2.71h7.39A3.54,3.54,0,0,0,288.93,58.1Z"/>'
                    )
                );
        }
        return
            string(
                abi.encodePacked(
                    '<path class="cls-2" d="M173.34,50.87a1.87,1.87,0,1,0-1.89,1.93A1.89,1.89,0,0,0,173.34,50.87Z"/><path class="cls-2" d="M294.83,28H120.17a29.64,29.64,0,1,0,0,59.28H294.83a29.64,29.64,0,1,0,0-59.28Zm-153,41.87H125.2v-4l8.21-8.53c1.43-1.46,2.48-2.9,2.48-4.33a2.43,2.43,0,0,0-2.62-2.58,3.92,3.92,0,0,0-3.6,2.65L125,50.28a8.73,8.73,0,0,1,8.25-5.34c4.37,0,8.28,2.86,8.28,7.79,0,2.93-1.57,5.45-3.81,7.68l-4,4.09h8.21Zm11.87.49c-6.32,0-9.95-5.17-9.95-12.72s3.63-12.71,9.95-12.71,10,5.17,10,12.71S160,70.37,153.7,70.37Zm11.71-19.5a5.91,5.91,0,0,1,6.08-5.93,5.85,5.85,0,0,1,6,5.93,6.06,6.06,0,0,1-12.12,0ZM168.31,66,184.1,48.57l2.3,1.33L170.61,67.4ZM184,70.3a5.94,5.94,0,1,1,6-5.94A5.92,5.92,0,0,1,184,70.3Zm24.38.07c-3.49,0-6.15-1.33-7.51-4.16l4.54-2.58a2.87,2.87,0,0,0,3,2.06c1.26,0,1.88-.39,1.88-1.09,0-1.92-8.59-.9-8.59-6.95,0-3.81,3.22-5.73,6.85-5.73a7.64,7.64,0,0,1,6.81,3.74l-4.47,2.41a2.54,2.54,0,0,0-2.34-1.54c-.91,0-1.47.35-1.47,1,0,2,8.6.67,8.6,7.13C215.61,68.66,212.11,70.37,208.34,70.37ZM235,69.88h-5.24v-10a2.88,2.88,0,0,0-3-3.18c-1.92,0-3.25,1.12-3.25,3.6v9.54h-5.24V45.42h5.24v8.63a6,6,0,0,1,5-2.13c3.53,0,6.53,2.52,6.53,7.24Zm21.52,0h-5.24V68.24a6.54,6.54,0,0,1-5.2,2.13c-4.58,0-8.35-4-8.35-9.22s3.77-9.23,8.35-9.23a6.57,6.57,0,0,1,5.2,2.13V52.41h5.24ZM270.83,58c-2.16-.35-5.24.53-5.24,4v7.9h-5.24V52.41h5.24v3.11a5.25,5.25,0,0,1,5.24-3.46Zm19,5.24H277.43c.67,1.82,2.27,2.45,4.2,2.45A4.55,4.55,0,0,0,285,64.36l4.19,2.41a8.84,8.84,0,0,1-7.61,3.6c-6,0-9.68-4-9.68-9.22a9,9,0,0,1,9.29-9.23c5.1,0,8.88,3.95,8.88,9.23A10.08,10.08,0,0,1,289.84,63.24Z"/><path class="cls-2" d="M153.7,50.39c-2.93,0-4.36,2.55-4.36,7.26s1.43,7.27,4.36,7.27,4.37-2.55,4.37-7.27S156.64,50.39,153.7,50.39Z"/><path class="cls-2" d="M247.11,56.88a4.27,4.27,0,1,0,4.16,4.27A4,4,0,0,0,247.11,56.88Z"/><path class="cls-2" d="M183.92,62.44a1.92,1.92,0,0,0,0,3.84,1.89,1.89,0,0,0,1.89-1.92A1.85,1.85,0,0,0,183.92,62.44Z"/><path class="cls-2" d="M281.14,56.57a3.61,3.61,0,0,0-3.81,2.76h7.51A3.59,3.59,0,0,0,281.14,56.57Z"/>'
                )
            );
    }

    function _generateSVGStaticText(bool _moreThanTwoWeeks) private pure returns (string memory) {
        if (_moreThanTwoWeeks) {
            return
                string(
                    abi.encodePacked(
                        '<path class="cls-2" d="M398.11,99.71h11.08v4.89a3.44,3.44,0,0,1-3.59,3.55,3.33,3.33,0,0,1-3.47-3.55V102h-4Zm5.91,4.52c0,1.33.68,1.88,1.65,1.88s1.6-.55,1.6-1.88V102H404Z"/><path class="cls-2" d="M398.11,109h11.08v8.14h-1.94v-5.89h-2.37v5.43h-1.95v-5.43h-2.85v6.16h-2Z"/><path class="cls-2" d="M398.11,124.78H401c1.07,0,1.49-.4,1.49-1.74v-2.47h-4.34v-2.25h11.08v5.62a3.17,3.17,0,0,1-3.2,3.41,2.59,2.59,0,0,1-2.57-1.65c-.32,1-.87,1.35-2.17,1.35h-3.14Zm9.16-4.21h-2.95v2.91c0,1.23.61,1.7,1.47,1.7s1.48-.47,1.48-1.62Z"/><path class="cls-2" d="M398.11,128.38h11.08v4.89a3.43,3.43,0,0,1-3.59,3.55,3.33,3.33,0,0,1-3.47-3.55V130.7h-4ZM404,132.9c0,1.34.68,1.89,1.65,1.89s1.6-.55,1.6-1.89v-2.2H404Z"/><path class="cls-2" d="M398.11,137.71h11.08V140H398.11Z"/><path class="cls-2" d="M17.19,491H6.11v-4.88a3.44,3.44,0,0,1,3.59-3.56,3.34,3.34,0,0,1,3.47,3.56v2.57h4Zm-5.91-4.52c0-1.33-.68-1.88-1.65-1.88S8,485.17,8,486.5v2.21h3.25Z"/><path class="cls-2" d="M17.19,481.7H6.11v-8.14H8.05v5.89h2.37V474h1.95v5.42h2.85v-6.16h2Z"/><path class="cls-2" d="M17.19,466H14.34c-1.07,0-1.49.4-1.49,1.74v2.47h4.34v2.25H6.11v-5.62a3.17,3.17,0,0,1,3.2-3.41A2.58,2.58,0,0,1,11.88,465c.32-1,.87-1.36,2.17-1.36h3.14ZM8,470.16h3v-2.91c0-1.23-.61-1.7-1.46-1.7S8,466,8,467.17Z"/><path class="cls-2" d="M17.19,462.35H6.11v-4.89a3.43,3.43,0,0,1,3.59-3.55,3.33,3.33,0,0,1,3.47,3.55V460h4Zm-5.91-4.52c0-1.33-.68-1.88-1.65-1.88S8,456.5,8,457.83V460h3.25Z"/><path class="cls-2" d="M17.19,453H6.11v-2.32H17.19Z"/>'
                    )
                );
        }
        return
            string(
                abi.encodePacked(
                    '<path class="cls-2" d="M398.73,99.69h11.08v4.89a3.43,3.43,0,0,1-3.59,3.55,3.33,3.33,0,0,1-3.47-3.55V102h-4Zm5.9,4.52c0,1.34.69,1.89,1.66,1.89s1.6-.55,1.6-1.89V102h-3.26Z"/><path class="cls-2" d="M398.73,109h11.08v8.14h-1.94v-5.89H405.5v5.42h-1.95v-5.42H400.7v6.15h-2Z"/><path class="cls-2" d="M398.73,124.76h2.85c1.07,0,1.49-.4,1.49-1.73v-2.47h-4.34v-2.25h11.08v5.62a3.17,3.17,0,0,1-3.21,3.4,2.59,2.59,0,0,1-2.57-1.65c-.31,1-.86,1.35-2.16,1.35h-3.14Zm9.16-4.2h-3v2.9c0,1.24.62,1.7,1.47,1.7s1.49-.46,1.49-1.62Z"/><path class="cls-2" d="M398.73,128.36h11.08v4.89a3.44,3.44,0,0,1-3.59,3.56,3.34,3.34,0,0,1-3.47-3.56v-2.57h-4Zm5.9,4.52c0,1.34.69,1.89,1.66,1.89s1.6-.55,1.6-1.89v-2.2h-3.26Z"/><path class="cls-2" d="M398.73,137.69h11.08V140H398.73Z"/><path class="cls-2" d="M17.81,491H6.73v-4.89a3.43,3.43,0,0,1,3.59-3.55,3.33,3.33,0,0,1,3.47,3.55v2.57h4Zm-5.91-4.52c0-1.34-.68-1.89-1.65-1.89s-1.6.55-1.6,1.89v2.2H11.9Z"/><path class="cls-2" d="M17.81,481.68H6.73v-8.14H8.66v5.89H11V474h2v5.42h2.86v-6.15h2Z"/><path class="cls-2" d="M17.81,465.94H15c-1.06,0-1.48.4-1.48,1.73v2.47h4.34v2.25H6.73v-5.62a3.17,3.17,0,0,1,3.2-3.4A2.57,2.57,0,0,1,12.5,465c.32-1,.87-1.35,2.17-1.35h3.14Zm-9.16,4.2H11.6v-2.9c0-1.24-.62-1.7-1.47-1.7s-1.48.46-1.48,1.61Z"/><path class="cls-2" d="M17.81,462.33H6.73v-4.88a3.44,3.44,0,0,1,3.59-3.56,3.34,3.34,0,0,1,3.47,3.56V460h4Zm-5.91-4.52c0-1.33-.68-1.88-1.65-1.88s-1.6.55-1.6,1.88V460H11.9Z"/><path class="cls-2" d="M17.81,453H6.73v-2.32H17.81Z"/>'
                )
            );
    }

    function _generateSVGData(
        StakingPositionParams memory _params,
        bool _moreThanTwoWeeks,
        uint256 _timeNow
    ) private pure returns (string memory) {
        uint256 stakeRounded = _params.stakedAmount - (_params.stakedAmount % 10 ** 14);
        uint256 rewardRounded = _params.unclaimedReward - (_params.unclaimedReward % 10 ** 14);
        string memory _staked = _amountToReadable(stakeRounded, 18);
        string memory _claimable = _amountToReadable(rewardRounded, 18);
        uint256 _temp = rewardRounded;
        uint8 _digits = 0;
        while (_temp != 0) {
            _digits++;
            _temp /= 10;
        }
        if (_digits <= 18) {
            _claimable = _substring(_claimable, 0, 6);
        }
        uint256 daysSinceCreated = (_timeNow - _params.createdAt) / 1 days;
        string memory _creationDate = Strings.toString(daysSinceCreated);

        if (_moreThanTwoWeeks) {
            return
                string(
                    abi.encodePacked(
                        '<path class="cls-6" d="M211.47,286.06c-7.43-.26-9.52.81-13.68,7,.25-7.43-.81-9.52-7-13.69,7.43.26,9.52-.81,13.68-7C204.25,279.8,205.31,281.9,211.47,286.06Z"/><ellipse class="cls-7" cx="222.01" cy="302.33" rx="3.42" ry="21.81" transform="translate(-144 384.34) rotate(-66.34)"/><path class="cls-8" d="M229.44,345.46c-5,11.45-19.23,16.46-31.5,11.08s-18.22-19.21-13.2-30.66c.12,1.74,1,12.84,10.54,19.88s23.52,7.11,34.16-.3Z"/><path class="cls-9" d="M201.55,294.51l-8.14,10.38a33.32,33.32,0,0,0-11.45,16c-4.18,13.27-.07,32.64,15.39,39.4s32.31-3.62,39.4-15.39c5.56-9.23,4.89-18.82,4.39-22.71.24-3.64.49-7.27.73-10.92-7.18-2.39-14.81-5.23-22.75-8.62-6.25-2.65-12.11-5.39-17.57-8.14ZM198.14,356a22.48,22.48,0,1,1,29.61-11.57A22.46,22.46,0,0,1,198.14,356Z"/><path class="cls-10" d="M210.3,297,222,295.17c-.82,1.88-1.65,3.75-2.47,5.63Z"/><path class="cls-11" d="M232.48,306.46l-9.2-10.74q-1.18,2.71-2.38,5.43l11.58,5.31Z"/><path class="cls-12" d="M226.92,308.06l11.5,4.34c0,2.47,0,5-.08,7.43a36.43,36.43,0,0,1,.49,5.81A34.93,34.93,0,0,1,235.58,341a34.15,34.15,0,0,1-10.17,12.57,29,29,0,0,0,6.26-15.37c.26-2.9.85-10.74-4.54-18a25.17,25.17,0,0,0-15.71-9.47,27.9,27.9,0,0,0,15.5-2.73Z"/><path class="cls-12" d="M186,316.87a27.55,27.55,0,0,1,5.2-6.44,32.72,32.72,0,0,1,4.38-3.52q3.19-4.61,6.41-9.2,2.57,1,5.21,2.06c3.81,1.55,7.45,3.16,10.93,4.78a14.62,14.62,0,0,0-5-.25,13.92,13.92,0,0,0-8.79,4.53,24.39,24.39,0,0,0-21.43,18.93A24.55,24.55,0,0,1,186,316.87Z"/><path class="cls-6" d="M253.28,334.73c-3.23-.11-4.14.36-5.95,3,.11-3.23-.35-4.14-3-5.94,3.23.11,4.14-.36,5.95-3C250.14,332,250.6,332.93,253.28,334.73Z"/>',
                        '<text class="cls-13" transform="translate(148.71 162.75)">Staked amount</text>',
                        '<text class="cls-3" transform="translate(86.9 232.92)">',
                        _staked,
                        '</text><text class="cls-4" transform="translate(152.58 441.88)">',
                        _claimable,
                        '</text><text class="cls-4" transform="translate(162.72 513.88)">',
                        _creationDate,
                        ' days</text>',
                        '<text class="cls-15" transform="translate(152.49 412.39)">Claimable rewards</text>',
                        '<text class="cls-15" transform="translate(167.17 484.39)">Creation date</text>'
                    )
                );
        }

        uint256 daysLeft = (2 weeks - (_timeNow - _params.createdAt)) / 1 days;
        if (daysLeft < 1) {
            daysLeft = 1;
        }
        string memory _evolve = Strings.toString(daysLeft);
        string memory _evolveText = ' days to evolve';
        if (_params.stakedAmount == 0) {
            _evolve = 'Position empty';
            _evolveText = ' - unstaked';
        }
        return
            string(
                abi.encodePacked(
                    '<text class="cls-6" transform="translate(148.09 163.1)">Staked amount</text>',
                    '<text class="cls-3" transform="translate(97.85 232.9)">',
                    _staked,
                    '</text><text class="cls-4" transform="translate(116.22 275.93)">',
                    _evolve,
                    _evolveText,
                    '</text><text class="cls-5" transform="translate(151.96 381.23)">',
                    _claimable,
                    ' ETH</text><text class="cls-5" transform="translate(162.1 453.23)">',
                    _creationDate,
                    ' days ago</text>',
                    '<text class="cls-8" transform="translate(151.87 351.74)">Claimable rewards</text>',
                    '<text class="cls-8" transform="translate(166.55 423.74)">Creation date</text>'
                )
            );
    }

    function _amountToReadable(
        uint256 _amount,
        uint8 _decimals
    ) private pure returns (string memory) {
        return
            string(abi.encodePacked(DescriptorUtils.fixedPointToDecimalString(_amount, _decimals)));
    }

    function _substring(
        string memory str,
        uint startIndex,
        uint endIndex
    ) private pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex - startIndex);
        for (uint i = startIndex; i < endIndex; i++) {
            result[i - startIndex] = strBytes[i];
        }
        return string(result);
    }
}