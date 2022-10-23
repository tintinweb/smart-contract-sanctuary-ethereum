// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

struct Semi {
    uint8 semiType;
    uint8 x;
    uint8 y;
}

interface ISemiNFT {
    function semis(uint256) external view returns (Semi memory);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function balanceOf(address owner) external view returns (uint256 balance);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
    function tokenByIndex(uint256 index) external view returns (uint256);
}

contract Renderer is Ownable {
    using Strings for uint256;
    using Strings for uint8;

    ISemiNFT public nftContract;
    string public soundBaseURI = "https://raw.githubusercontent.com/avcdsld/code-as-art/main/semi/metadata/sounds/";
    string public soundURIPostfix = ".mp3";
    string public percentEncodedImageBaseURI = "https%3A%2F%2Fraw.githubusercontent.com%2Favcdsld%2Fcode-as-art%2Fmain%2Fsemi%2Fmetadata%2Fimages%2F";
    string public imageURIPostfix = ".png";

    function setNftContract(address contractAddress) public onlyOwner {
        nftContract = ISemiNFT(contractAddress);
    }

    function setSoundBaseURI(string memory uri) public onlyOwner {
        soundBaseURI = uri;
    }

    function setSoundURIPostfix(string memory str) public onlyOwner {
        soundURIPostfix = str;
    }

    function setPercentEncodedImageBaseURI(string memory uri) public onlyOwner {
        percentEncodedImageBaseURI = uri;
    }

    function setImageURIPostfix(string memory str) public onlyOwner {
        imageURIPostfix = str;
    }

    function tokenURI(uint256 tokenId) public view returns (string memory) {
        Semi memory semi = nftContract.semis(tokenId);

        string[4] memory svgParts;
        svgParts[0] = '%253Csvg%250D%250AviewBox%253D%25220%252C%25200%252C%2520256%252C%2520256%2522%250D%250Axmlns%253D%2522http%253A%252F%252Fwww.w3.org%252F2000%252Fsvg%2522%250D%250Aclass%253D%2522content%2522%250D%250A%253E%250D%250A';
        svgParts[1] = string.concat(
            '%253Ccircle%2520cx%253D%2522',
            (semi.x + 15).toString(),
            '%2522%2520cy%253D%2522',
            (semi.y + 15).toString(),
            '%2522%2520r%253D%252215%2522%2520fill%253D%2522%2523fffdb3%2522%2520%252F%253E'
        );
        address owner = nftContract.ownerOf(tokenId);
        uint256 balance = nftContract.balanceOf(owner);
        for (uint256 i = 0; i < balance; i++) {
            uint256 id = nftContract.tokenOfOwnerByIndex(owner, i);
            Semi memory s = nftContract.semis(id);
            svgParts[2] = string.concat(
                svgParts[2],
                '%253Cimage%250D%250Ax%253D%2522',
                s.x.toString(),
                '%2522%250D%250Ay%253D%2522',
                s.y.toString(),
                '%2522%250D%250Awidth%253D%252230%2522%250D%250Aheight%253D%252230%2522%250D%250ApreserveAspectRatio%253D%2522xMidYMid%2520meet%2522%250D%250Axlink%253Ahref%253D%2522',
                percentEncodedImageBaseURI,
                s.semiType.toString(),
                imageURIPostfix,
                '%2522%250D%250Adata-type%253D%2522',
                s.semiType.toString(),
                '%2522%252F%253E%250D%250A'
            );
        }
        svgParts[3] = '%253C%252Fsvg%253E';

        string memory js = string.concat(
            'const semis = document.querySelectorAll("image");',
            'for (let i = 0, l = semis.length; l > i; i++) {',
            ' const file = semis[i].getAttribute("data-type");',
            ' const src = `',
            soundBaseURI,
            '${file}',
            soundURIPostfix,
            '`;',
            ' const audio = new Audio(src);',
            ' semis[i].addEventListener("mousedown", () => {',
            '  audio.currentTime = 0;',
            '  audio.play();',
            ' });',
            '}'
        );

        string memory html = string.concat(
            '%253C%2521DOCTYPE%2520html%253E%253Chtml%253E%253Chead%253E%253Cmeta%2520charset%253D%2522utf-8%2522%2520%252F%253E%253Ctitle%253ESemi%253C%252Ftitle%253E%253Cstyle%253Ebody%257Bmargin%253A0px%253B%257D.container%257Bposition%253Arelative%253Bwidth%253A100vmin%253Bheight%253A100vmin%253Bbackground-color%253A%2523f4f4f4%253B%257D.content%257Bposition%253Aabsolute%253Btop%253A0%253Bleft%253A0%253B%257D%253C%252Fstyle%253E%253C%252Fhead%253E%253Cbody%253E%253Cdiv%2520class%253D%2522container%2522%253E%250D%250A',
            svgParts[0], svgParts[1], svgParts[2], svgParts[3],
            '%253C%252Fdiv%253E%253Cscript%2520src%253D%2522data%253Atext%252Fjavascript%253Bbase64%252C',
            Base64.encode(bytes(js)),
            '%2522%253E%253C%252Fscript%253E%253C%252Fbody%253E%253C%252Fhtml%253E%250D%250A'
        );

        string memory json = string.concat(
            'data:application/json,',
            "%7B",
            '%22name%22%3A%20%22Semi%20%23', tokenId.toString(), '%22%2C',
            '%22description%22%3A%20%22Semi%22%2C',
            '%22animation_url%22%3A%20%22data%3Atext%2Fhtml%2C', html, '%22',
            "%7D"
        );

        return json;
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Base64.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 *
 * _Available since v4.5._
 */
library Base64 {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        /// @solidity memory-safe-assembly
        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
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