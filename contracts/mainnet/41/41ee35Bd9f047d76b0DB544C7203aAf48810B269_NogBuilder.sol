// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./StringUtils.sol";
import "./Structs.sol";
import "./Base64.sol";

library NogBuilder {
    using StringUtils for string;
    using Strings for uint160;
    using Strings for uint256;    

    /* 
    ⌐◨—————————————————————————————————————————————————————————————◨
                            nog colors
    ⌐◨—————————————————————————————————————————————————————————————◨ 
    */  

    function getColorPalette(Structs.Seed memory seed) internal view returns (string memory colorMetadata) {
        bytes memory list;
        for (uint i; i < seed.colors.length; ++i) {
            if (i < seed.colors.length - 1) {
                list = abi.encodePacked(list, string.concat('"#', seed.colors[seed.colorPalette[i]],'", '));
            } else {
                list = abi.encodePacked(list, string.concat('"#', seed.colors[seed.colorPalette[i]],'"'));
            }
        }
        return string(list);
    }

    function getNogColorStyles(Structs.Seed memory seed) internal view returns (string memory nogColorStyles) {
        string memory bg = seed.colors[seed.colorPalette[0]];
        if (seed.backgroundStyle == 1) {
            bg = 'd5d7e1';
        }
        if (seed.backgroundStyle == 2) {
            bg = 'e1d7d5';
        }
        if (seed.backgroundStyle == 3) {
            bg = seed.colors[seed.colorPalette[1]];
        }
        
        return string(
            abi.encodePacked(
                '<style>.shade{fill:',
                seed.shade,
                '}.bg{fill:#',
                bg,
                '}.a{fill:#',
                seed.colors[seed.colorPalette[1]],
                '}.b{fill:#',
                seed.colors[seed.colorPalette[2]],
                '}.c{fill:#',
                seed.colors[seed.colorPalette[3]],
                ';}.d{fill:#',
                seed.colors[seed.colorPalette[4]],
                ';}.e{fill:#',
                seed.colors[seed.colorPalette[5]],
                ';}.y{fill:#',
                'fff',
                '}.p{fill:#',
                '000',
                '}</style>'
            )
        );
    }

    function getColorMetadata(uint frameColorLength, uint16[7] memory colorPalette, string[7] memory colors) internal view returns (string memory colorMetadata) {
        bytes memory list;
        for (uint i; i < frameColorLength; ++i) {
            list = abi.encodePacked(list, string.concat('{"trait_type":"Nog color", "value":"#', colors[colorPalette[i + 1]],'"},'));
        }
        return string(list);
    }
    
    function getColors(address minterAddress) public view returns (string[7] memory) {
        string memory addr = Strings.toHexString(minterAddress);
        string memory color;
        string[7] memory list;
        for (uint i; i < 7; ++i) {
            if (i == 0) {
                color = addr._substring(6, 2);
            } else if (i == 1) {
                color = addr._substring(6, int(i) * 8);
            } else {
                color = addr._substring(6, int(i) * 6);
            }
            list[i] = color;
        }    
        return list;
    }

    /* 
    ⌐◨—————————————————————————————————————————————————————————————◨
                            create nogs
    ⌐◨—————————————————————————————————————————————————————————————◨ 
    */  

    function getTokenIdSvg(Structs.Seed memory seed) internal view returns (string memory svg) {
        string memory backgroundGradient = getBackground(seed);
        string memory shade = string(abi.encodePacked('<path class="shade" d="M0 0h100v100H0z"/>'));
        string memory nogs = string(abi.encodePacked(seed.nogShape));
        string memory shadow;
        if (seed.backgroundStyle == 1 || seed.backgroundStyle == 2) {
            shade = '';
        }
        if (isStringEmpty(seed.shadow) == false) {
            shadow = string(abi.encodePacked(seed.shadow));
        }
        if (isStringEmpty(seed.shadow) == false && seed.hasAnimation == true) {
            // bounce nogs
            nogs = string(abi.encodePacked(
                '<g shape-rendering="optimizeSpeed" transform="translate(-55 -42)">',
                    seed.nogShape,
                    '<defs><path xmlns="http://www.w3.org/2000/svg" id="nogs" d="M53.5 41.2c-.2.7-.3 1.8 0 1.8s.2-1 0-1.8zm0 0c-.2-.8-.3-1.7 0-1.7s.2 1 0 1.7z"/></defs><animateMotion xmlns="http://www.w3.org/2000/svg" dur="8s" repeatCount="indefinite" calcMode="linear"><mpath xmlns:xlink="http://www.w3.org/1999/xlink" xlink:href="#nogs"/></animateMotion>',
                '</g>'
            ));
            shadow = string(abi.encodePacked(seed.shadowAnimation));
        }

        return
            string(
                abi.encodePacked(
                    '<svg viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg" style="shape-rendering:crispedges">',
                        '<defs>',
                            string(abi.encodePacked(getNogColorStyles(seed))),
                        '</defs>',
                        '<svg viewBox="0 0 100 100"><path class="bg" d="M0 0h100v100H0z"/>',
                        shade, 
                            string(abi.encodePacked(backgroundGradient)),
                            string(abi.encodePacked(shadow)),
                        '</svg>',
                        '<svg viewBox="0 0 100 100" class="nogs">',
                            string(abi.encodePacked(nogs)),
                        '</svg>',
                    '</svg>'
                )
            );
    }    

    function buildParts(Structs.Seed memory seed) public view returns (Structs.NogParts memory parts) {
        parts = Structs.NogParts({
            image: string(abi.encodePacked(Base64.encode(bytes(getTokenIdSvg(seed))))),
            colorMetadata: getColorMetadata(seed.frameColorLength, seed.colorPalette, seed.colors),
            colorPalette: getColorPalette(seed)
        });
    }

    function getBackground(Structs.Seed memory seed) public view returns (string memory backgroundGradient) {
        string[5] memory vals = ["22", "33", "44", "55", "66"];
        string[8] memory animations = [
            '',
            '',
            '',
            '',
            string(abi.encodePacked('<animateTransform attributeType="xml" attributeName="transform" type="rotate" from="360 50 50" to="0 50 50" dur="22s" additive="sum" repeatCount="indefinite"/><animateTransform xmlns="http://www.w3.org/2000/svg" attributeType="xml" attributeName="transform" type="scale" values="0.8; 1.8; 0.8" dur="33s" additive="sum" repeatCount="indefinite"/>')),
            string(abi.encodePacked('<animate attributeName="r" values="1; 1.66; 1" dur="18s" repeatCount="indefinite"></animate>')),
            string(abi.encodePacked('<animate attributeName="x2" values="100;',vals[getPseudorandomness(seed.tokenId, 17) % 5],';100" dur="28s" repeatCount="indefinite"></animate><animate attributeName="y2" values="10;85;10" dur="17s" repeatCount="indefinite"></animate>')),
            string(abi.encodePacked('<animate attributeName="x1" values="',vals[getPseudorandomness(seed.tokenId, 17) % 5], ';100;',vals[getPseudorandomness(seed.tokenId, 23) % 5], '" dur="42s" repeatCount="indefinite"></animate><animate attributeName="y1" values="10;66;10" dur="22s" repeatCount="indefinite"></animate>'))
        ];
        
        string memory animation;
        if (seed.hasAnimation == true) {
            animation = animations[seed.backgroundStyle];
        }

        if (isStringEmpty(seed.shadow) == false && seed.hasAnimation == true) {
            animation = '';
        }

        string memory meshGradient = string(abi.encodePacked(
            '<path d="M0 0h100v100H0z" fill="#fff" opacity="0.', vals[getPseudorandomness(seed.tokenId, 13) % 5], '"/>',
            '<g filter="url(#grad)" transform="scale(1.', vals[getPseudorandomness(seed.tokenId, 17) % 5], ') translate(-25 -25)" opacity="0.', vals[getPseudorandomness(seed.tokenId, 23) % 5], '">',
                '<path d="M32.15 0H0v80.55L71 66 32.15 0Z" fill="#', seed.colors[2], '"/><path d="M0 80.55V100h80l-9-34L0 80.55Z" fill="#', seed.colors[3], '"/><path d="M80 100h20V19.687L71 66l9 34Z" fill="#', seed.colors[5], '"/><path d="M100 0H32.15L71 66l29-46.313V0Z" fill="#', seed.colors[2], '"/>',
                '<defs><filter id="grad" x="-50" y="-50" width="200" height="200" filterUnits="userSpaceOnUse" color-interpolation-filters="sRGB"><feBlend result="shape"/><feGaussianBlur stdDeviation="10"/></filter></defs>',
                animation,
            '</g>'
        ));

        string memory gradientRadial = string(abi.encodePacked(
            '<path fill="url(#grad)" d="M-73-17h246v246H-73z" opacity="0.8"  /><defs><radialGradient id="grad" cx="0" cy="0" r="1" gradientTransform="rotate(44.737 -114.098 135.14) scale(165.905)" gradientUnits="userSpaceOnUse"><stop stop-color="#', seed.colors[seed.nogStyle], '"/><stop offset=".6" stop-color="#', seed.colors[seed.nogStyle], '" stop-opacity="0"/>', animation, '</radialGradient></defs>'
        ));

        string memory linearGradient = string(abi.encodePacked(
            '<path fill="url(#grad)" opacity=".66" d="M0 0h100v100H0z"/><defs><linearGradient id="grad" x1="7" y1="8" x2="100" y2="100" gradientUnits="userSpaceOnUse"><stop stop-color="#', seed.colors[seed.nogStyle], '"/><stop offset="1" stop-color="#', seed.colors[seed.nogStyle], '" stop-opacity=".2"/>', animation,'</linearGradient></defs>'
        ));

        string memory lightGradient = string(abi.encodePacked(
            '<path fill="url(#grad)" opacity=".44" d="M0 0h100v100H0z"/><defs><linearGradient id="grad" x1="7" y1="8" x2="100" y2="100" gradientUnits="userSpaceOnUse"><stop stop-color="#fff" stop-opacity=".67"/><stop offset="1" stop-color="#fff" stop-opacity=".21"/>', animation, '</linearGradient></defs>'
        ));
    
        string[8] memory backgrounds = ['', '', '', '', meshGradient, gradientRadial, linearGradient, lightGradient];

        backgroundGradient = string (
            abi.encodePacked(backgrounds[seed.backgroundStyle])
        );
    }

    function getAttributesMetadata(Structs.Seed memory seed) public view returns (string memory extraMetadata) {
        string memory animatedMetadata;
        string memory floatingMetadata;
        string memory bg = string(abi.encodePacked('#',seed.colors[seed.colorPalette[0]]));
        if (seed.hasAnimation && seed.backgroundStyle > 1) {
            animatedMetadata = string(abi.encodePacked(
                '{"trait_type":"Animated", "value":"Animated"},'
            ));
        }
        if (isStringEmpty(seed.shadow) == false) {
            floatingMetadata = string(abi.encodePacked(
                '{"trait_type":"Floating", "value":"Floating"},'
            ));
        }
        if (seed.backgroundStyle == 1) {
            bg = string(abi.encodePacked('Cool'));
        }
        if (seed.backgroundStyle == 2) {
            bg = string(abi.encodePacked('Warm'));
        }
        if (seed.backgroundStyle == 3) {
            bg = string(abi.encodePacked('#',seed.colors[seed.colorPalette[1]]));
        }
        
        return string(abi.encodePacked(
            '{"trait_type":"Nog type", "value":"',
                abi.encodePacked(string(seed.nogStyleName)),
            '"},',
                abi.encodePacked(string(getColorMetadata(seed.frameColorLength, seed.colorPalette, seed.colors))),
            '{"trait_type":"Background type", "value":"',
                abi.encodePacked(string(seed.backgroundStyleName)),
            '"},',    
            '{"trait_type":"Background color", "value":"',
                bg,
            '"},',
            animatedMetadata, 
            floatingMetadata,
            '{"trait_type":"Minted by", "value":"',
                abi.encodePacked(string(uint160(seed.minterAddress).toHexString(20))),
            '"}'
        ));
    }

    /*
    ⌐◨—————————————————————————————————————————————————————————————◨
                           utility functions
    ⌐◨—————————————————————————————————————————————————————————————◨ 
    */  

    function isStringEmpty(string memory val) public view returns(bool) {
        bytes memory checkString = bytes(val);
        if (checkString.length > 0) {
            return false;
        } else {
            return true;
        }
    }

    function getPseudorandomness(uint tokenId, uint num) public view returns (uint256 pseudorandomness) {        
        return uint256(keccak256(abi.encodePacked(num * tokenId * tokenId + 1, msg.sender)));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

pragma solidity ^0.8.15;

/**
 * Strings Library
 * 
 * In summary this is a simple library of string functions which make simple 
 * string operations less tedious in solidity.
 * 
 * Please be aware these functions can be quite gas heavy so use them only when
 * necessary not to clog the blockchain with expensive transactions.
 * 
 * @author James Lockhart <[email protected]>
 */

library StringUtils {

    /**
     * Concat (High gas cost)
     * 
     * Appends two strings together and returns a new value
     * 
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string which will be the concatenated
     *              prefix
     * @param _value The value to be the concatenated suffix
     * @return string The resulting string from combinging the base and value
     */
    function concat(string memory _base, string memory _value)
        internal
        pure
        returns (string memory) {
        bytes memory _baseBytes = bytes(_base);
        bytes memory _valueBytes = bytes(_value);

        assert(_valueBytes.length > 0);

        string memory _tmpValue = new string(_baseBytes.length +
            _valueBytes.length);
        bytes memory _newValue = bytes(_tmpValue);

        uint i;
        uint j;

        for (i = 0; i < _baseBytes.length; i++) {
            _newValue[j++] = _baseBytes[i];
        }

        for (i = 0; i < _valueBytes.length; i++) {
            _newValue[j++] = _valueBytes[i];
        }

        return string(_newValue);
    }

    /**
     * Index Of
     *
     * Locates and returns the position of a character within a string
     * 
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string acting as the haystack to be
     *              searched
     * @param _value The needle to search for, at present this is currently
     *               limited to one character
     * @return int The position of the needle starting from 0 and returning -1
     *             in the case of no matches found
     */
    function indexOf(string memory _base, string memory _value)
        internal
        pure
        returns (int) {
        return _indexOf(_base, _value, 0);
    }

    /**
     * Index Of
     *
     * Locates and returns the position of a character within a string starting
     * from a defined offset
     * 
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string acting as the haystack to be
     *              searched
     * @param _value The needle to search for, at present this is currently
     *               limited to one character
     * @param _offset The starting point to start searching from which can start
     *                from 0, but must not exceed the length of the string
     * @return int The position of the needle starting from 0 and returning -1
     *             in the case of no matches found
     */
    function _indexOf(string memory _base, string memory _value, uint _offset)
        internal
        pure
        returns (int) {
        bytes memory _baseBytes = bytes(_base);
        bytes memory _valueBytes = bytes(_value);

        assert(_valueBytes.length == 1);

        for (uint i = _offset; i < _baseBytes.length; i++) {
            if (_baseBytes[i] == _valueBytes[0]) {
                return int(i);
            }
        }

        return -1;
    }

    /**
     * Length
     * 
     * Returns the length of the specified string
     * 
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string to be measured
     * @return uint The length of the passed string
     */
    function length(string memory _base)
        internal
        pure
        returns (uint) {
        bytes memory _baseBytes = bytes(_base);
        return _baseBytes.length;
    }

    /**
     * Sub String
     * 
     * Extracts the beginning part of a string based on the desired length
     * 
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string that will be used for 
     *              extracting the sub string from
     * @param _length The length of the sub string to be extracted from the base
     * @return string The extracted sub string
     */
    function substring(string memory _base, int _length)
        internal
        pure
        returns (string memory) {
        return _substring(_base, _length, 0);
    }

    /**
     * Sub String
     * 
     * Extracts the part of a string based on the desired length and offset. The
     * offset and length must not exceed the lenth of the base string.
     * 
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string that will be used for 
     *              extracting the sub string from
     * @param _length The length of the sub string to be extracted from the base
     * @param _offset The starting point to extract the sub string from
     * @return string The extracted sub string
     */
    function _substring(string memory _base, int _length, int _offset)
        internal
        pure
        returns (string memory) {
        bytes memory _baseBytes = bytes(_base);

        assert(uint(_offset + _length) <= _baseBytes.length);

        string memory _tmp = new string(uint(_length));
        bytes memory _tmpBytes = bytes(_tmp);

        uint j = 0;
        for (uint i = uint(_offset); i < uint(_offset + _length); i++) {
            _tmpBytes[j++] = _baseBytes[i];
        }

        return string(_tmpBytes);
    }


    function split(string memory _base, string memory _value)
        internal
        pure
        returns (string[] memory splitArr) {
        bytes memory _baseBytes = bytes(_base);

        uint _offset = 0;
        uint _splitsCount = 1;
        while (_offset < _baseBytes.length - 1) {
            int _limit = _indexOf(_base, _value, _offset);
            if (_limit == -1)
                break;
            else {
                _splitsCount++;
                _offset = uint(_limit) + 1;
            }
        }

        splitArr = new string[](_splitsCount);

        _offset = 0;
        _splitsCount = 0;
        while (_offset < _baseBytes.length - 1) {

            int _limit = _indexOf(_base, _value, _offset);
            if (_limit == - 1) {
                _limit = int(_baseBytes.length);
            }

            string memory _tmp = new string(uint(_limit) - _offset);
            bytes memory _tmpBytes = bytes(_tmp);

            uint j = 0;
            for (uint i = _offset; i < uint(_limit); i++) {
                _tmpBytes[j++] = _baseBytes[i];
            }
            _offset = uint(_limit) + 1;
            splitArr[_splitsCount++] = string(_tmpBytes);
        }
        return splitArr;
    }

    /**
     * Compare To
     * 
     * Compares the characters of two strings, to ensure that they have an 
     * identical footprint
     * 
     * @param _base When being used for a data type this is the extended object
     *               otherwise this is the string base to compare against
     * @param _value The string the base is being compared to
     * @return bool Simply notates if the two string have an equivalent
     */
    function compareTo(string memory _base, string memory _value)
        internal
        pure
        returns (bool) {
        bytes memory _baseBytes = bytes(_base);
        bytes memory _valueBytes = bytes(_value);

        if (_baseBytes.length != _valueBytes.length) {
            return false;
        }

        for (uint i = 0; i < _baseBytes.length; i++) {
            if (_baseBytes[i] != _valueBytes[i]) {
                return false;
            }
        }

        return true;
    }

    /**
     * Compare To Ignore Case (High gas cost)
     * 
     * Compares the characters of two strings, converting them to the same case
     * where applicable to alphabetic characters to distinguish if the values
     * match.
     * 
     * @param _base When being used for a data type this is the extended object
     *               otherwise this is the string base to compare against
     * @param _value The string the base is being compared to
     * @return bool Simply notates if the two string have an equivalent value
     *              discarding case
     */
    function compareToIgnoreCase(string memory _base, string memory _value)
        internal
        pure
        returns (bool) {
        bytes memory _baseBytes = bytes(_base);
        bytes memory _valueBytes = bytes(_value);

        if (_baseBytes.length != _valueBytes.length) {
            return false;
        }

        for (uint i = 0; i < _baseBytes.length; i++) {
            if (_baseBytes[i] != _valueBytes[i] &&
            _upper(_baseBytes[i]) != _upper(_valueBytes[i])) {
                return false;
            }
        }

        return true;
    }

    /**
     * Upper
     * 
     * Converts all the values of a string to their corresponding upper case
     * value.
     * 
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string base to convert to upper case
     * @return string 
     */
    function upper(string memory _base)
        internal
        pure
        returns (string memory) {
        bytes memory _baseBytes = bytes(_base);
        for (uint i = 0; i < _baseBytes.length; i++) {
            _baseBytes[i] = _upper(_baseBytes[i]);
        }
        return string(_baseBytes);
    }

    /**
     * Lower
     * 
     * Converts all the values of a string to their corresponding lower case
     * value.
     * 
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string base to convert to lower case
     * @return string 
     */
    function lower(string memory _base)
        internal
        pure
        returns (string memory) {
        bytes memory _baseBytes = bytes(_base);
        for (uint i = 0; i < _baseBytes.length; i++) {
            _baseBytes[i] = _lower(_baseBytes[i]);
        }
        return string(_baseBytes);
    }

    /**
     * Upper
     * 
     * Convert an alphabetic character to upper case and return the original
     * value when not alphabetic
     * 
     * @param _b1 The byte to be converted to upper case
     * @return bytes1 The converted value if the passed value was alphabetic
     *                and in a lower case otherwise returns the original value
     */
    function _upper(bytes1 _b1)
        private
        pure
        returns (bytes1) {

        if (_b1 >= 0x61 && _b1 <= 0x7A) {
            return bytes1(uint8(_b1) - 32);
        }

        return _b1;
    }

    /**
     * Lower
     * 
     * Convert an alphabetic character to lower case and return the original
     * value when not alphabetic
     * 
     * @param _b1 The byte to be converted to lower case
     * @return bytes1 The converted value if the passed value was alphabetic
     *                and in a upper case otherwise returns the original value
     */
    function _lower(bytes1 _b1)
        private
        pure
        returns (bytes1) {

        if (_b1 >= 0x41 && _b1 <= 0x5A) {
            return bytes1(uint8(_b1) + 32);
        }

        return _b1;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.15;

library Structs {
     struct Nog {
        address minterAddress;
        uint16[7] colorPalette;
        uint16 nogStyle;
        uint16 backgroundStyle;
        bool hasShadow;
        bool hasAnimation;
    }

    struct NogStyle {
        string name;
        string shape;
        uint8 frameColorLength;
    }

    struct Seed {
        uint256 tokenId;
        address minterAddress;
        uint16[7] colorPalette;
        string[7] colors;
        uint16 nogStyle;
        string nogStyleName;
        string nogShape;
        uint8 frameColorLength;
        uint16 backgroundStyle;
        string backgroundStyleName;
        string shade;
        string shadow;
        string shadowAnimation;
        bool hasAnimation;
    }

    struct NogParts {
        string image;
        string colorMetadata;
        string colorPalette;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides a function for encoding some bytes in base64
library Base64 {
    string internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(string memory _data) internal pure returns (string memory) {
        return encode(bytes(_data));
    }

    function encode(bytes memory _data) internal pure returns (string memory) {
        if (_data.length == 0) return "";

        // load the table into memory
        string memory table = TABLE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((_data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := _data
            let endPtr := add(dataPtr, mload(_data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {

            } lt(dataPtr, endPtr) {

            } {
                dataPtr := add(dataPtr, 3)

                // read 3 bytes
                let input := mload(dataPtr)

                // write 4 characters
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
                resultPtr := add(resultPtr, 1)
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
                resultPtr := add(resultPtr, 1)
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(6, input), 0x3F)))))
                resultPtr := add(resultPtr, 1)
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(input, 0x3F)))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(_data), 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
        }

        return result;
    }
}