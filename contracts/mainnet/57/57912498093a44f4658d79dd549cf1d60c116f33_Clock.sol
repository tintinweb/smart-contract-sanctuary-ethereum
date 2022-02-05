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

contract Clock {

    string constant private _DAYS_TAG = '<DAYS>';
    string[] private _imageParts;

    constructor() {
        _imageParts.push("<svg xmlns='http://www.w3.org/2000/svg' width='1000' height='1000'>");
            _imageParts.push("<defs><rect id='r' width='1000' height='1000'/></defs>");
            _imageParts.push("<style>@font-face {font-family: 'D';src: ");
            _imageParts.push("url('data:font/woff2;charset=utf-8;base64,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') format('woff2');");
            _imageParts.push("font-weight: normal; font-style: normal; font-display: swap; }");
            _imageParts.push("* { user-select: none; position: relative; }");
            _imageParts.push(".b { fill: black; }");
            _imageParts.push(".a { animation: f 2s ease-out forwards; }");
            _imageParts.push("@keyframes f { 10% { opacity: 1; } 100% { opacity: 0; } }");
            _imageParts.push(".c { color: white; width: 1000px; height: 1000px; display: flex; justify-content: center; align-items: center; position: fixed; animation: t 1s ease-out infinite; }");
            _imageParts.push(".t { font-family: 'D'; font-size: 100px; line-height: 100px; text-align: center; text-transform: uppercase; width: 800px; }");
            _imageParts.push(".m { display: inline; word-wrap: break-word; word-spacing: 1000px; }");
            _imageParts.push(".censor { transform: scale(1.1, 1); }");
            _imageParts.push("@keyframes t { 0% { opacity: 0.8; } 50% { opacity: 1; } 100% { opacity: 1; } }");
            _imageParts.push(".m::before { content: '");
                _imageParts.push(_DAYS_TAG);
            _imageParts.push("'; }</style>");
            _imageParts.push("<g><use class='b' href='%23r'/><foreignObject width='1000' height='1000'><div xmlns='http://www.w3.org/1999/xhtml'><div class='c'><div class='t'><div class='m'></div></div></div></div></foreignObject><use class='b a' href='%23r'/></g>");
        _imageParts.push("</svg>");
    }

    function metadata() external view returns(string memory) {
        return string(abi.encodePacked('data:application/json;utf8,{"name":"Clock", "description":"',daysIncarcerated(),'", "created_by":"Pak", "image":"data:image/svg+xml;utf8,',
            svg(),
            '"}'));
    }

    function svg() public view returns(string memory) {
        bytes memory byteString;
        for (uint i = 0; i < _imageParts.length; i++) {
            if (_checkTag(_imageParts[i], _DAYS_TAG)) {
                byteString = abi.encodePacked(byteString, daysIncarcerated());
            } else {
                byteString = abi.encodePacked(byteString, _imageParts[i]);
            }
        }
        return string(byteString);
    }

    function _checkTag(string storage a, string memory b) private pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }
    
    function daysIncarcerated() public view returns(string memory) {
        string[10] memory onesArray = ['','one','two','three','four', 'five','six','seven','eight','nine'];
        
        uint256 numberOfDays = (block.timestamp - 1554977700)/86400;
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

    function _onesAndTensString(uint256 onesAndTens) internal pure returns(string memory) {
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