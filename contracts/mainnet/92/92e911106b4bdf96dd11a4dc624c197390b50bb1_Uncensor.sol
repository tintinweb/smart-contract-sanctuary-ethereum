// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @creator: Pak
/// @author: manifold.xyz

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                        //
//                                                                                                                        //
//       ,ad8888ba,   88888888888  888b      88   ad88888ba     ,ad8888ba,    88888888ba   88888888888  88888888ba,       //
//      d8"'    `"8b  88           8888b     88  d8"     "8b   d8"'    `"8b   88      "8b  88           88      `"8b      //
//     d8'            88           88 `8b    88  Y8,          d8'        `8b  88      ,8P  88           88        `8b     //
//     88             88aaaaa      88  `8b   88  `Y8aaaaa,    88          88  88aaaaaa8P'  88aaaaa      88         88     //
//     88             88"""""      88   `8b  88    `"""""8b,  88          88  88""""88'    88"""""      88         88     //
//     Y8,            88           88    `8b 88          `8b  Y8,        ,8P  88    `8b    88           88         8P     //
//      Y8a.    .a8P  88           88     `8888  Y8a     a8P   Y8a.    .a8P   88     `8b   88           88      .a8P      //
//       `"Y8888Y"'   88888888888  88      `888   "Y88888P"     `"Y8888Y"'    88      `8b  88888888888  88888888Y"'       //
//                                                                                                                        //
//                                                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Uncensor {

    using Strings for uint256;
    
    string constant private _MESSAGE_TAG = '<MESSAGE>';
    string[] private _imageParts;

    constructor() {
        _imageParts.push("<svg xmlns='http://www.w3.org/2000/svg' width='1000' height='1000'>");
            _imageParts.push("<defs><rect id='r' width='1000' height='1000'/></defs>");
            _imageParts.push("<style>@font-face {font-family: 'DC';src: ");
            _imageParts.push("url('data:font/woff2;charset=utf-8;base64,d09GMgABAAAAAAsQAA8AAAAAGLgAAAq0AAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAP0ZGVE0cGh4bjAQcghoGYACCShEICoxsiUsLPgABNgIkA3gEIAWNKwdeG88VsxEWbBwAIN1Isv/qgDeUPrqFGYQYTSJmMKAbGCq4cboq/CjnURS++i0o7rYVDp0DfyxPPO6qqssGhzA8rB8hySz8P+X1/2ufqlYl3ZfKo+YUP8S5R4LSH/AIzDJc1t4FCRCsQoGw7U10eLz2L3BR3gXtLnCR1yL55dX1fX0BFJO7LQCLJFCI4A/rcl7PVFip4FHtvifJLHxQrPtf+73ad0K8CUu6AYnjgXSEzUT4l/38IEC0CSsGoWB82KeA4AglOzK6RtXIKlkj6ys7jF0AJhbYGYBTcWkH9BUDAqjeeMcMkJ6yLweAT3rumEdADDQDhhBdCA8YICBwLTeSmzx19mKSDQc3bGTophMO7mbstoNbdjFz94bDe1mKB8giIKAlCycnQtfGHpqnHE5hwsopieGTFi6ubPKUJWzOvNls4bw5bNHCiWzxwlmWKf5ttGvLwb0UAQHCY4AootxMPNDOWE7mZj5TXkO1VJhqdIsessQWWoJV2C2u2XW6M90d3hs0b+bJ/gZ8E/cE4D/hgkQMh/ySkRXZ3VR652DUnmh91P3AvTa8YIBKQuSmDO0uFLuKNIhFg+WBg6QpJ4ZmnZDrvNNUKQ2GUFi6/8n5n1I4FWhmvV+YNPoDgSfQ2a4orlQ3Nay7gz0yFAb0maQZGnVapu1WxX3NbeyNodBAYPtntyus6qT1HxOGGQAXXP8UCbuggYFcKaJq1Tjdjg2DdAYs31/sUgX+Eph0ojCNIWbMLOYw8lnAIpaw7GTBVicbtmuKNw5V9UHzQvcN+2l4xgGfSZ5BoiwLdreVHjo4tXta73D3DbdJ4EICVd0QMJ50VYILMf3HKQsoe3w3ZLPLClIJzUnvD6aM/mmgLwQkRQrS0Hz/jchCDqJO8lCAIpSgLFqgVbRBu6q4cLCqXbPoBHYYrNkGVeAFQZEuU/THixRDsBRHIfd5UqBESqJkwkJZCRtp5xWbymlQ9wALhs4CneQWHdy2ude4hhVWaMwjg8PHOyQQEhISCAkJHxCRkJBASCDHiKfIeImHeIRPgmmAbJCecwgeQboc1X8e9CRfarUtP7BJ26heCDYZOjbEF/HSoWDfHKD3BCLNFKIRRLgFSTSqnzwnoE4hSENksyXxcCA8hMfTW7uLvTMcFPCD7K+csYrimQZN+Yxo194AOVrYO1ldUYHN+gW5+NHkg54TzEOFnvNQyZExzw6zJthDA6d/qBkYq/8s7qCE/NkB76b3GGopDlGPqAAgQNBnstFIK6KWn3//U1iw5eTALuz+MOtutJb50gMoAACJCL1aAJbMWjYXSFhp+P+PvOAj/mZ0FYCZvQQkOLB/MToRAJNxCOjEMxDI4xFGwsoskDAhq+8UAQAoDwIAZIBh5ETgaPO5fOGQwXzwYP6M8O8QolZZoO27MTpxb9DbYAeT+iMzHMKQ7GjJ6L0purpSqSeEOPSOfX2cL4f6uBKa6mpLg4tNhXJcCpuCTwiJggKycnnEEF1UHfQmpy/ernL6/MNhZVT7tM54LARfk546yaYl6eg0XLj0pJYV7w5598hnic/1/S5M4fTq4tHfjnLRu9UV1fR/aXT93VDUd1YBypWJiQiUYc5g2wRxejowvXg22iLG+a3KdyU+3CIX+eCC4Qa/LqJ9XNCaXje8M3bZm8S9T2+cVRFpRfBfjFJ2i1asGt26fK9YC5wsmogqnhS4OAGlWGQVdwnVqNHIpDqAljXV0olmj0usSDoLVGZobZjXHmeZcJKWJ4IQfXtp2MxQrbjm5Mfqz/NsaiAShynzKWiKVTomECqVpthar1OXlaOnOw6KLvte2FamgKKYjJqBGFhp2AErOOXEpApdOqHUH1mggYKhoEMt0OPiKFZ/UoA/5EtMdReJFaLxh9tFApDiZ3HSGHaQ2/hAobHk4YXE1FFs+QGxIH9HAOOPzGx5K7XQeBvlORkP28Si8dD8vkiNJX2DRW2UOV5v2cR0VCsFlOwlMdIRxQxc8goM3KOLcQK//4Chbfou414infMTDSM11/CdcDWCsbYQgHFKPk0GmbbgIU1hOjmfxicUdgYG9iDoFAgysHMGMIDxApSJcg+9d40VBTCOoeDKAXqgA1QVgm4VOvMghUZu9IbuVUV4vbCxTeZ+8GFG/JqmmiM0CebGug6uptM0aJ3VwmqV4VnDlqeJg1sXsPM+zC63FD3JBt4ylbauCto6LxM8AQHPMsD1K3flqGOVPc4myOdR1ehwK1LHemL/VDz9ap4pgdqu7u6a/Or1mzQ87e3bd8Dsy4PCX0atvApDj2hy42TlRu4xnkV4oBaMIT1QexLgJAMjhp+zcxNe/JaSk8WV4RHmafjb3vlotJ4neCfYohdc8WUZeUbf51/zdN800NPcCrY20eD7mcmDU4pK5AuhWsMCvR9i/fUCr1Zol5MV3YJIhl9MP74YhYB7IEqcWqCbnKi/8abbiidY1CPYJyw+Ntw3yIXHK0KMtkJJ9bGWho4d74mToUcTY1Ljkov07frBfPQQuokORgPHC9gt0jEz02OkW8NNOnE6E4xciuv1ffczwRXKBaxGsFoQIxVgpt13+EE5UGCq8IMwXRGf/SU+HNjOnnEvxT7GfsyfDduILi1jyWApACv/ju8WFDiCUxae2P1Hxple/DOK1TXcKFgL/dCk0FP0IZxmXzHSkPtuz+4us15MsBQoYgAI1jfyy9wb6e06CEPrDuLhQHOAe8Aas8+mziwTZYxNZpa+8NKtQjNeYxY4KnqyNyHM1oHtBEKsze5Oj3zb0POP75usNyjbPKYbG95106h/nfR+9lG36I2AbgbjADBACBgPAECicxEAMIrNTRJNPEVGge/IsUhd5GmwRsoR20TK02DHqEBfq1KRXm4slahxp1NEg3uAYhrd71RhlN9HtdT6p6kO7z+5dj1NuRoc8iVgIxAkBnMtGRXeI8fN/Eae/vqJcrTaQMrT3+ZRgelWS0Um2i8q0e3WU0R/dznFDHSvUIWNHqJaEn8d1VH06busZ7D/kkmHodY420jFEjuMSWdwMdwZ82ch9OQJ00K24/VUmNsucUCKQESJVAEc1FXieuCIBf+l1+6/Rfj0dMvI0tuLIT3dkvcgMh7smfsmmCVSShNaW5ER8q5bgSUbslZ/wpZUpr91JVlruDbAQiS2V0Ab8GTnoQCjqHRz9Ks/Q6GJjIUhopk5Z+XdvXizkmtRWFwui08h2JAH2XQS4iy2gOCIcLuSyBXsmAEDcoQvEJGyZbrI5qGmDzDqF574VqVcehdhqz9Jm53ycC9vq7ylWK5r+Yqw0UNbl8gtOxBOxOPJSTo2Dwx0HD+IwHGBeuR7wQcAXA1CGwqwFNmUun2tW3mow3mxzbNUXZ/9zAV+5dQWg5idDSS5H4E2ckwtqpaWymapDlP/2HrKq01qWR1VOjO+5oRoBcl5o3o6hhXE3cyqbek/VsjVDT1aSFQID/LKsPSKnDZsKZKKOBWw8J1pp/FCozmasVV7G0eNqmaBDudi+InXY7zfHJtGlTTdLkKt5Pmx0BnZyp3zHEpyqXmyWg3NUfvZ0ugmvAtZHMhnE6Hyo7ZVebrjDkujfYFbTTeOoedZDvq2WA7MPPcvgSrGqUVfkhQbI9sMNvNmugFinL5u3Lpz78GjJ88UKo3OYLLYHC6PL7Bdr968AwAA') format('woff2');");
            _imageParts.push("font-weight: normal; font-style: normal; font-display: swap;}");
            _imageParts.push("* { user-select: none; position: relative; }");
            _imageParts.push(".b { fill: #eee; }");
            _imageParts.push(".a { animation: f 2s ease-out forwards; }");
            _imageParts.push("@keyframes f { 10% { opacity: 1; } 100% { opacity: 0; } }");
            _imageParts.push(".c { color: black; width: 1000px; height: 1000px; display: flex; justify-content: center; align-items: center; position: fixed; }");
            _imageParts.push(".t { font-family: 'DC'; font-size: 70px; line-height: 70px; text-align: center; text-transform: uppercase; width: 800px; }");
            _imageParts.push(".m { display: inline; word-wrap: break-word; }");
            _imageParts.push(".m::before { content: '");
            _imageParts.push(_MESSAGE_TAG);
            _imageParts.push("'; }</style>");
            _imageParts.push("<g><use class='b' href='%23r'/><foreignObject width='1000' height='1000'><div xmlns='http://www.w3.org/1999/xhtml'><div class='c'><div class='t'><div class='m'></div></div></div></div></foreignObject></g>");
        _imageParts.push("</svg>");
    }

    function metadata(uint256 tokenId, string memory message, uint256 value) external view returns(string memory) {
        return string(abi.encodePacked('data:application/json;utf8,{"name":"Uncensored #',tokenId.toString(),' - ',_toUpperCase(message),'", "description":"',_toUpperCase(message),'", "created_by":"Pak", "image":"data:image/svg+xml;utf8,',
            svg(tokenId, message, value),
            '","attributes":[{"trait_type":"Censored","value":"False"},{"trait_type":"Initial Price","value":',_valueString(value),'}]}'));
    }

    function _toUpperCase(string memory message) private pure returns (string memory) {
        bytes memory messageBytes = bytes(message);
        bytes memory upperMessageBytes = new bytes(messageBytes.length);
        for (uint i = 0; i < messageBytes.length; i++) {
            bytes1 char = messageBytes[i];
            if (char >= 0x61 && char <= 0x7A) {
                // So we add 32 to make it lowercase
                upperMessageBytes[i] = bytes1(uint8(char) - 32);
            } else {
                upperMessageBytes[i] = char;
            }
        }
        return string(upperMessageBytes);
    }

    function _valueString(uint256 value) private pure returns (string memory) {
        uint256 eth = value/10**18;
        uint256 decimal4 = value/10**14 - eth*10**4;
        return string(abi.encodePacked(eth.toString(), '.', _decimal4ToString(decimal4)));
    }

    function _decimal4ToString(uint256 decimal4) private pure returns (string memory) {
        bytes memory decimal4Characters = new bytes(4);
        for (uint i = 0; i < 4; i++) {
            decimal4Characters[3 - i] = bytes1(uint8(0x30 + decimal4 % 10));
            decimal4 /= 10;
        }
        return string(abi.encodePacked(decimal4Characters));
    }

    function svg(uint256, string memory message, uint256) public view returns(string memory) {
        bytes memory byteString;
        for (uint i = 0; i < _imageParts.length; i++) {
            if (_checkTag(_imageParts[i], _MESSAGE_TAG)) {
                byteString = abi.encodePacked(byteString, message);
            } else {
                byteString = abi.encodePacked(byteString, _imageParts[i]);
            }
        }
        return string(byteString);
    }

    function _checkTag(string storage a, string memory b) private pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
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