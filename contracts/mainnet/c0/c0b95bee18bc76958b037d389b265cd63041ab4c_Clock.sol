// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @creator: Pak
/// @author: manifold.xyz

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                        //
//                                                                                                                        //
//       ,ad8888ba,   88888888888  888b      88   ad88888ba     ,ad8888ba,    88888888ba   88888888888  88888888ba,       //
//      d8"'    `"8b  88           8888b     88  d8"     "8b   d8"'    `"8b   88      "8b  88           88      `"8b      //
//  ████████████████████████████████████████████████████████████████████████████████████████████████████████████████████  //
//  ████████████████████████████████████████████████████████████████████████████████████████████████████████████████████  //
//  ████████████████████████████████████████████████████████████████████████████████████████████████████████████████████  //
//  ████████████████████████████████████████████████████████████████████████████████████████████████████████████████████  //
//      Y8a.    .a8P  88           88     `8888  Y8a     a8P   Y8a.    .a8P   88     `8b   88           88      .a8P      //
//       `"Y8888Y"'   88888888888  88      `888   "Y88888P"     `"Y8888Y"'    88      `8b  88888888888  88888888Y"'       //
//                                                                                                                        //
//                                                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Clock {

    using Strings for uint256;

    string constant private _DAYS_TAG = '<DAYS>';
    string[] private _imageParts;

    constructor() {
        _imageParts.push("<svg xmlns='http://www.w3.org/2000/svg' width='1000' height='1000' viewBox='0 0 1000 1000'>");
            _imageParts.push("<style>@font-face {font-family: 'D';src: ");
            _imageParts.push("url('data:font/woff2;charset=utf-8;base64,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') format('woff2');");
            _imageParts.push("font-weight: normal; font-style: normal; font-display: swap; }");
            _imageParts.push(".f { width: 100%; height: 100%; }");
            _imageParts.push(".b { fill: black; }");
            _imageParts.push(".a { animation: o 2s ease-out forwards; }");
            _imageParts.push("@keyframes o { 10% { opacity: 1; } 100% { opacity: 0; } }");
            _imageParts.push("@keyframes t { 0% { opacity: 0.8; } 50% { opacity: 1; } 100% { opacity: 1; } }");
            _imageParts.push("tspan { fill: white; font-family: 'D'; font-size: 100px; text-transform: uppercase; text-anchor: middle; animation: t 1s ease-out infinite; }");
            _imageParts.push("</style>");
            _imageParts.push("<rect class='b f' />");
            _imageParts.push(_DAYS_TAG);
            _imageParts.push("<rect class='b f a' />");
        _imageParts.push("</svg>");
    }

    function metadata() external view returns(string memory) {
        return string(abi.encodePacked('data:application/json;utf8,{"name":"Clock", "description":"',_daysIncarceratedString(),'", "created_by":"Pak", "image":"data:image/svg+xml;utf8,',
            svg(),
            '"}'));
    }

    function svg() public view returns(string memory) {
        bytes memory byteString;
        for (uint i = 0; i < _imageParts.length; i++) {
            if (_checkTag(_imageParts[i], _DAYS_TAG)) {
                byteString = abi.encodePacked(byteString, _renderDaysIncarcerated());
            } else {
                byteString = abi.encodePacked(byteString, _imageParts[i]);
            }
        }
        return string(byteString);
    }

    function _checkTag(string storage a, string memory b) private pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }
    
    function _renderDaysIncarcerated() private view returns(string memory) {
        string[10] memory onesArray = ['','one','two','three','four', 'five','six','seven','eight','nine'];
        string[10] memory teensArray = ['ten','eleven','twelve','thirteen', 'fourteen','fifteen','sixteen', 'seventeen','eighteen','nineteen'];
        string[8] memory tensArray = ['twenty','thirty','forty','fifty', 'sixty','seventy','eighty','ninety'];
        
        uint256 numberOfDays = (block.timestamp - 1554977700)/86400;
        if (numberOfDays > 99999) numberOfDays = 99999;
        uint256 thousands = numberOfDays/1000;
        uint256 hundreds = (numberOfDays % 1000)/100;
        uint256 onesAndTens = numberOfDays % 100;

        string memory lines;
        uint8 lineCount;
        if (thousands > 0) {
            if (thousands < 10) {
                lines = string(abi.encodePacked(lines, "<tspan x='500'>", onesArray[thousands], "</tspan>"));
                lineCount += 2;
            } else if (thousands >= 10 && thousands < 20) {
                lines = string(abi.encodePacked(lines, "<tspan x='500'>", teensArray[thousands % 10], "</tspan>"));
                lineCount += 2;
            } else {
                uint256 ones = thousands % 10;
                uint256 tens = thousands/10;
                lines = string(abi.encodePacked(lines, "<tspan x='500'>", tensArray[tens-2], "</tspan>"));
                lines = string(abi.encodePacked(lines, "<tspan x='500' dy='1em'>", onesArray[ones], "</tspan>"));
                lineCount += 3;
            }
            lines = string(abi.encodePacked(lines, "<tspan x='500' dy='1em'>thousand</tspan>"));
        }
        if (hundreds > 0) {
            lines = string(abi.encodePacked(lines, "<tspan x='500'",lineCount > 0 ? " dy='1em'" : "",">", onesArray[hundreds], "</tspan>"));
            lines = string(abi.encodePacked(lines, "<tspan x='500' dy='1em'>hundred</tspan>"));
            lineCount += 2;
        }
        if (onesAndTens > 0) {
            if (onesAndTens < 10) {
                lines = string(abi.encodePacked(lines, "<tspan x='500'",lineCount > 0 ? " dy='1em'" : "",">", onesArray[onesAndTens], "</tspan>"));
                lineCount += 1;
            } else if (onesAndTens >= 10 && onesAndTens < 20) {
                lines = string(abi.encodePacked(lines, "<tspan x='500'",lineCount > 0 ? " dy='1em'" : "",">", teensArray[onesAndTens % 10], "</tspan>"));
                lineCount += 1;
            } else {
                uint256 ones = onesAndTens % 10;
                uint256 tens = onesAndTens/10;
                lines = string(abi.encodePacked(lines, "<tspan x='500'",lineCount > 0 ? " dy='1em'" : "",">", tensArray[tens-2], "</tspan>"));
                lines = string(abi.encodePacked(lines, "<tspan x='500' dy='1em'>", onesArray[ones], "</tspan>"));
                lineCount += 2;
            }
        }
        return string(abi.encodePacked("<svg y='",(582-uint256(lineCount)*50).toString(),"' overflow='visible'><text>",lines,"</text></svg>"));
    }

    function _daysIncarceratedString() private view returns(string memory) {
        string[10] memory onesArray = ['','one','two','three','four', 'five','six','seven','eight','nine'];
        
        uint256 numberOfDays = (block.timestamp - 1554977700)/86400;
        if (numberOfDays > 99999) numberOfDays = 99999;
        uint256 thousands = numberOfDays/1000;
        uint256 hundreds = (numberOfDays % 1000)/100;
        uint256 onesAndTens = numberOfDays % 100;

        bytes memory daysByteString;
        if (thousands > 0) {
            daysByteString = abi.encodePacked(daysByteString, _onesAndTensString(thousands), " thousand");
        }
        if (hundreds > 0) {
            daysByteString = abi.encodePacked(daysByteString, " ", onesArray[hundreds], " hundred");
        }
        if (onesAndTens > 0) {
           daysByteString = abi.encodePacked(daysByteString, " ", _onesAndTensString(onesAndTens));
        }
        return string(daysByteString);
    }

    function _onesAndTensString(uint256 onesAndTens) private pure returns(string memory) {
        require(onesAndTens < 100, "Invalid value");
        string[10] memory onesArray = ['','one','two','three','four', 'five','six','seven','eight','nine'];
        string[10] memory teensArray = ['ten','eleven','twelve','thirteen', 'fourteen','fifteen','sixteen', 'seventeen','eighteen','nineteen'];
        string[8] memory tensArray = ['twenty','thirty','forty','fifty', 'sixty','seventy','eighty','ninety'];

        uint256 ones = onesAndTens % 10;
        if (onesAndTens < 10) {
            return onesArray[ones];
        } else if (onesAndTens >= 10 && onesAndTens < 20) {
            return teensArray[ones];
        } else {
            uint256 tens = onesAndTens/10;
            return string(abi.encodePacked(tensArray[tens-2], " ", onesArray[ones]));
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
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