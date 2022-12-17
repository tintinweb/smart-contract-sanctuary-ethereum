pragma solidity ^0.8.0;
//SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "base64-sol/base64.sol";

import "./PerchLibrary.sol";
import "./PerchLibrary2.sol";
import "hardhat/console.sol";

// GET LISTED ON OPENSEA: https://testnets.opensea.io/get-listed/step-two

contract Perch is ERC721Enumerable {
    using Strings for uint256;
    using Strings for uint160;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;

    uint256 mintDeadline = block.timestamp + 3650 days;

    address payable public constant recipient =
        payable(0x54179E1770a780F2F541f23CB21252De12977d3c);

    uint256 public constant limit = 1000;
    uint256 public constant curve = 1005; // price increase 0,5% with each purchase
    uint256 public price = 0.002 ether;

    mapping(uint256 => uint256) public parrot_perches;

    //! Properties types
    string[8] public perches;

    constructor() ERC721("ParrotPerch", "PRTPerch") {
        perches = [
            "oak",
            "birch",
            "bones",
            "skateboard",
            "staff",
            "sword",
            "scepter",
            "coffin"
        ];
    }

    function mintItem() public payable returns (uint256) {
        require(block.timestamp < mintDeadline, "DONE MINTING");
        require(msg.value >= price, "NOT ENOUGH");

        price = (price * curve) / 1000;
        _tokenIds.increment();

        uint256 id = _tokenIds.current();
        _mint(msg.sender, id);

        bytes32 predictableRandom = keccak256(
            abi.encodePacked(
                id,
                blockhash(block.number - 1),
                msg.sender,
                address(this)
            )
        );
        parrot_perches[id] = uint256(
            ((uint8(predictableRandom[9]) << 8) |
                uint8(predictableRandom[10])) % 8
        );

        (bool success, ) = recipient.call{value: msg.value}("");
        require(success, "could not send");

        return id;
    }

    // Visibility is `public` to enable it being called by other contracts for composition.
    function renderTokenById(uint256 id) public view returns (string memory) {
        uint256 perch = getPropertiesById(id);

        string memory render = string(
            abi.encodePacked(
                '<g class="cls-1">',
                '<g id="Perch">',
                PerchLibrary.GetPerch(perch),
                Perch2Library.GetPerch(perch),
                "</g>",
                "</g>"
            )
        );

        return render;
    }

    // function generateSVGofTokenById(uint256 id) internal view returns (string memory) {
    function generateSVGofTokenById(uint256 id)
        internal
        view
        returns (string memory)
    {
        string memory svg = string(
            abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="300" height="300" viewBox="0 0 880 880">',
                renderTokenById(id),
                "</svg>"
            )
        );
        return svg;
    }

    function getDescription(uint256 id) public view returns (string memory) {
        require(_exists(id), "!exist");
        uint256 perch = getPropertiesById(id);
        return perches[perch];
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        require(_exists(id), "!exist");

        uint256 perch = getPropertiesById(id);

        string memory name = string(
            abi.encodePacked("Parrot Perch #", id.toString())
        );

        string memory description = string(abi.encodePacked(perches[perch]));
        string memory image = Base64.encode(bytes(generateSVGofTokenById(id)));

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"',
                                name,
                                '","description":"',
                                description,
                                '","external_url":"https://yourCollectible.com/token/',
                                id.toString(),
                                '","attributes":[{"trait_type":"Perch","value":"',
                                perches[perch],
                                '"}], "owner":"',
                                (uint160(ownerOf(id))).toHexString(20),
                                '","image": "',
                                "data:image/svg+xml;base64,",
                                image,
                                '"}'
                            )
                        )
                    )
                )
            );
    }

    // properties of the token of id
    function getPropertiesById(uint256 id) public view returns (uint256 perch) {
        perch = parrot_perches[id];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

pragma solidity >=0.6.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes  internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                            hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                            hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                            hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE_ENCODE;

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
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {} lt(dataPtr, endPtr) {}
            {
               // read 4 characters
               dataPtr := add(dataPtr, 4)
               let input := mload(dataPtr)

               // write 3 bytes
               let output := add(
                   add(
                       shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                       shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                   add(
                       shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
    }
}

pragma solidity ^0.8.0;
//SPDX-License-Identifier: MIT

import "hardhat/console.sol";

// GET LISTED ON OPENSEA: https://testnets.opensea.io/get-listed/step-two

// Defining Library
library PerchLibrary {
    function GetPerch(uint256 index) public pure returns (string memory) {
        string memory perch;

        if (index == 0) {
            perch = string(
                abi.encodePacked(
                    "<defs>",
                    "    <style>",
                    "        .cls-perch-7,",
                    "        .cls-perch-8,",
                    "        .cls-perch-9 {",
                    "            stroke: #000;",
                    "            stroke-miterlimit: 10;",
                    "            stroke-width: 4.33px;",
                    "        }"
                )
            );
            perch = string(
                abi.encodePacked(
                    perch,
                    "        .cls-perch-11 {",
                    "            mix-blend-mode: multiply;",
                    "            fill: #979797;",
                    "            opacity: 0.2;",
                    "        }",
                    "        .cls-perch-12,",
                    "        .cls-perch-7 {",
                    "            fill: #c9b59f;",
                    "        }"
                )
            );
            perch = string(
                abi.encodePacked(
                    perch,
                    "        .cls-perch-8 {",
                    "            fill: #39b34a;",
                    "        }",
                    "        .cls-perch-9 {",
                    "            fill: #8ac43f;",
                    "        }"
                )
            );
            perch = string(
                abi.encodePacked(
                    perch,
                    "        .cls-perch-10 {",
                    "            fill: #8c6239;",
                    "        }",
                    "    </style>",
                    "</defs>"
                )
            );
            perch = string(
                abi.encodePacked(
                    perch,
                    "<polygon",
                    '    class="cls-perch-7"',
                    '    points="752.25 554.02 713.86 538.58 680.05 558.4 752.25 554.02"',
                    "/>",
                    "<path",
                    '    class="cls-perch-8"',
                    '    d="M222.88,635.54s37.69,26.42,39.24,56.73-2.72,40.81.39,53.24C236.48,721,213.55,691.5,222.88,635.54Z"',
                    "/>"
                )
            );
            perch = string(
                abi.encodePacked(
                    perch,
                    "<path",
                    '    class="cls-perch-9"',
                    '    d="M222.49,639.42c.39,4.28,26.81,39.64,10.49,77s-57.51,73.44-45.08,99.87c-39.64-64.51-46.63-109.2-19.43-136.4S222.49,639.42,222.49,639.42Z"',
                    "/>",
                    "<path",
                    '    class="cls-perch-10"',
                    '    d="M217.39,653.15c-10.33,0-22.14-5.54-28.73-13.47-4.15-5-5.83-10.42-4.84-15.71.91-4.9,8-7.12,14.77-9.26,3-.92,6.32-2,7.29-2.84a16.42,16.42,0,0,0,2.1-2.41c1.78-2.29,4.09-5.27,10.7-9.45-35-6.62-63.47-41.88-64.74-43.47l-.16-.2-.11-.22c-.16-.34-3.72-8.35,9.59-17.42.89-.72,4.46-3,13.79-3,1.75,0,3.62.09,5.57.25,6,.5,9.45,2.89,13.76,5.91,6.44,4.51,15.25,10.68,39.69,15.1a111.59,111.59,0,0,0,19.89,2c11.43,0,19-2.38,27-4.9s16.2-5.13,28.51-5.29h1.06c16.19,0,56.94,4.38,96.35,8.62,37,4,71.87,7.73,84.76,7.73l1.6,0c22.74-.76,208.53-62,210.41-62.65l.36-.12h.38c1,0,24.83,1.06,42.68,28.18l1.54,2.33-2.65.91c-13,4.42-35.09,13.6-48,19.07,7.27-.12,17.28-.25,27.51-.25,11.57,0,21.16.16,28.51.47l1.52.07.46,1.44c5.17,16.42,2.52,32.72-2.41,41.59-2.53,4.56-5.76,7.46-9.32,8.37A50.08,50.08,0,0,1,733,606.06c-5.34,0-11.89-.54-21-1.3-9.4-.78-22.26-1.85-39.94-2.81-2.18-.12-4.53-.18-7-.18-33.59,0-83.69,11-123.94,19.86-20.49,4.5-38.18,8.39-48.36,9.55a288.17,288.17,0,0,1-31.63,1.54c-33.5,0-67.74-3.94-91.61-10.54-22-6.1-47.48-9.06-77.85-9.06-5.94,0-11.06.11-15.18.2-10.44.21-12.82,4.19-15.84,9.23-1.95,3.26-4.16,7-8.68,9.85a50.05,50.05,0,0,0-9.09,7.53,49.58,49.58,0,0,1-16,11.26A22.08,22.08,0,0,1,217.39,653.15Z"',
                    "/>"
                )
            );
            perch = string(
                abi.encodePacked(
                    perch,
                    "<path",
                    '    d="M706.29,504.48s23.5.71,40.94,27.21c-19.38,6.6-58.43,23.5-58.43,23.5s18.75-.47,38.61-.47c9.93,0,20.14.12,28.42.47,6.71,21.28,0,44.6-10.2,47.22A48.62,48.62,0,0,1,733,603.9c-10.76,0-26.19-2.22-60.79-4.11q-3.39-.19-7.08-.19c-51.54,0-143.25,26.09-172.55,29.43a286.26,286.26,0,0,1-31.38,1.52c-29.39,0-65-3.25-91-10.46-28.37-7.85-57.91-9.13-78.43-9.13-5.9,0-11.06.11-15.22.19-18.66.39-14.77,12.44-25.65,19.43s-10.1,11.66-24.87,18.66a20,20,0,0,1-8.58,1.74c-15,0-34-12.77-31.45-26.61,1.09-5.82,17.88-7.78,21.38-10.89s3.49-7,17.87-14.76c-37.3-3.11-69.56-43.53-69.56-43.53s-3.11-6.6,8.94-14.76c0,0,2.85-2.57,12.48-2.57,1.6,0,3.4.07,5.4.23,14,1.17,12.43,13.61,53.23,21a114,114,0,0,0,20.28,2c23.45,0,31.43-9.87,55.5-10.18h1c31.06,0,154.15,16.36,181.11,16.36.61,0,1.17,0,1.67,0,23.32-.78,211-62.76,211-62.76m-.64-4.35-.72.24c-64.72,21.37-191.85,62-209.8,62.54-.46,0-1,0-1.53,0-12.77,0-47.63-3.75-84.54-7.72-39.46-4.25-80.26-8.63-96.57-8.64h-1.08c-12.63.17-21,2.82-29.14,5.38-7.82,2.47-15.21,4.81-26.31,4.81a109.33,109.33,0,0,1-19.51-2c-24-4.34-32.56-10.35-38.83-14.74-4.4-3.08-8.2-5.75-14.82-6.3-2-.17-3.94-.25-5.75-.25-9.58,0-13.69,2.35-15.06,3.42C147.48,546.86,151.24,556,151.72,557l.21.46.32.39a159.38,159.38,0,0,0,21.42,21.24c13.53,11.16,26.84,18.49,39.72,21.9a34.14,34.14,0,0,0-7.12,7.11,15.24,15.24,0,0,1-1.83,2.11c-.78.6-4.22,1.69-6.5,2.4-7.08,2.22-15.1,4.74-16.25,10.92-1.11,5.94.73,12,5.3,17.5,7,8.38,19.47,14.24,30.4,14.24a24.28,24.28,0,0,0,10.43-2.16c9.33-4.42,13-8.11,16.63-11.69a48,48,0,0,1,8.73-7.24c4.94-3.17,7.4-7.27,9.37-10.56,3-5,4.78-8,14-8.18,4.1-.09,9.21-.19,15.13-.19,30.17,0,55.45,2.93,77.28,9,24,6.65,58.5,10.62,92.18,10.62A292.62,292.62,0,0,0,493,633.33c10.29-1.17,28-5.07,48.58-9.59,40.15-8.82,90.12-19.81,123.48-19.81,2.4,0,4.71.06,6.85.18,17.65,1,30.5,2,39.89,2.81,9.11.76,15.69,1.31,21.13,1.31a52.36,52.36,0,0,0,13.74-1.63c4.15-1.07,7.84-4.32,10.67-9.42,5.15-9.27,8-26.25,2.58-43.29l-.91-2.89-3-.13c-7.39-.32-17-.47-28.61-.47-5.67,0-11.28,0-16.38.09,12.4-5.16,27.69-11.33,37.59-14.71l5.3-1.8-3.08-4.67c-18.46-28-43.37-29.12-44.42-29.16l-.77,0Z"',
                    "/>",
                    "<path",
                    '    class="cls-perch-11"',
                    '    d="M158.66,545.49c-4.93,5.66-3,9.7-3,9.7s32,40.1,69.14,43.48c7.51-3.57,14.39-8.58,21.18-13.42C213.07,585.26,180.51,569.7,158.66,545.49Z"',
                    "/>"
                )
            );
            perch = string(
                abi.encodePacked(
                    perch,
                    "<ellipse",
                    '    class="cls-perch-12" cx="209.36" cy="634.47" rx="12.01" ry="21.94"',
                    '    transform="translate(-455.88 572.46) rotate(-66.41)"',
                    "/>",
                    "<path",
                    '    class="cls-perch-11"',
                    '    d="M569.41,595c-85.54,33.79-178.76,12.36-267.95,2-15-2.14-33.16-6.42-44.93,5.35-8.84,9.82-14.09,23.23-24.82,31.16,1.14,0,2.28-.07,3.42-.14h0c-1.14.07-2.28.11-3.42.14a31.27,31.27,0,0,1-3,2,31.27,31.27,0,0,0,3-2c-15,.37-29.92-2.32-44.88-1,5.13,13,26.84,22.53,39.14,16.71,14.77-7,14-11.66,24.87-18.66s7-19,25.65-19.43,57.12-1.16,93.65,8.94,91.71,12.44,122.41,8.94,129.89-32,179.63-29.24,59.85,6.12,73.45,2.62c7.1-1.83,12.51-13.69,12.87-27.91h-.24C695,575.56,630.67,573.51,569.41,595Z"',
                    "/>"
                )
            );
        } else if (index == 1) {
            perch = string(
                abi.encodePacked(
                    "<defs>",
                    "    <style>",
                    "        .cls-perch-7,",
                    "        .cls-perch-8 {",
                    "            stroke: #000;",
                    "            stroke-miterlimit: 10;",
                    "            stroke-width: 4.33px;",
                    "        }"
                )
            );
            perch = string(
                abi.encodePacked(
                    perch,
                    "        .cls-perch-9 {",
                    "            mix-blend-mode: multiply;",
                    "            opacity: 0.2;",
                    "            fill: #979797;",
                    "        }",
                    "        .cls-perch-7 {",
                    "            fill: #8cc63f;",
                    "        }"
                )
            );
            perch = string(
                abi.encodePacked(
                    perch,
                    "        .cls-perch-8 {",
                    "            fill: #e4e4e4;",
                    "        }",
                    "    </style>",
                    "</defs>"
                )
            );
            perch = string(
                abi.encodePacked(
                    perch,
                    "<path",
                    '    class="cls-perch-7"',
                    '    d="M228.84,649.79l-.11.16s-48.59,3-56.19,12.15c-7.91,9.5-13.66,39.48-14.42,69.85,21.26-2.28,66-20.5,77.44-27.33,10.82-6.49-4.37-39.66-2-50.14C231.92,653,230.37,651.4,228.84,649.79Z"',
                    "/>"
                )
            );
            perch = string(
                abi.encodePacked(
                    perch,
                    "<path",
                    '    class="cls-perch-7"',
                    '    d="M244.12,661.71c-4.76,0-42.86,7.62-48.57,20.95s16.19,69.53,16.19,69.53,43.81-38.1,46.67-49.53S244.12,661.71,244.12,661.71Z"',
                    "/>"
                )
            );
            perch = string(
                abi.encodePacked(
                    perch,
                    "<path",
                    '    class="cls-perch-8"',
                    '    d="M725.46,678.46c-35.7-3.21-103.74-15.1-166.32-23.61s-346.53-25.52-368-27.39c-36.16-3.14-27.54-73.92-5.86-74.85s65.07-2.59,115.57-3.81,409,31.79,433.49,31.12S761.17,681.67,725.46,678.46Z"',
                    "/>"
                )
            );
            perch = string(
                abi.encodePacked(
                    perch,
                    "<path",
                    '    class="cls-perch-8"',
                    '    d="M238.3,621.18s-11,12.57-12.58,26.72,49.52,33,59.74,15.72c22.8-30.65,67.6-28.3,67.6-28.3"',
                    "/>"
                )
            );
            perch = string(
                abi.encodePacked(
                    perch,
                    "<path",
                    '    class="cls-perch-9"',
                    '    d="M326.62,614.23c-35.54,0-51.08,32.74-73.13,54,13.2,3.66,27.14,3.56,32-4.61,12.91-17.36,32.89-24.13,47.78-26.74,88.36,5.92,191.19,13.25,225.9,18,62.58,8.51,130.62,20.4,166.32,23.61,13.28,1.19,21.3-12.22,24.87-29.5l-1.5-.1C607.45,637.31,468,612.31,326.62,614.23Z"',
                    "/>"
                )
            );
            perch = string(
                abi.encodePacked(
                    perch,
                    "<path",
                    '    class="cls-perch-9"',
                    '    d="M167.14,599.58c2.08,14.29,9.38,26.61,24,27.88,4.13.36,18,1.28,38.05,2.59,3.08-7.25,9-12.82,13-19.37C216.94,612.38,191.7,605.67,167.14,599.58Z"',
                    "/>"
                )
            );
            perch = string(
                abi.encodePacked(
                    perch,
                    "<path",
                    '    d="M192,600.77c-6.94,5.39-4,17,.43,26.8,3.51.27,10.52.75,20.26,1.4C206,616.14,207.64,590.32,192,600.77Z"',
                    "/>"
                )
            );
            perch = string(
                abi.encodePacked(
                    perch,
                    "<path",
                    '    d="M234.29,589.23c1.92,3.84,8.65,0,10.58-3.85,4.18-11.84,3.32-24.69,8.36-35.26-7.27.23-14.21.46-20.77.69C227.8,563.58,227.7,577.52,234.29,589.23Z"',
                    "/>"
                )
            );
            perch = string(
                abi.encodePacked(
                    perch,
                    "<path",
                    '    d="M268.91,636.35c-5.77,1-14.43,5.77-9.62,9.62,9.18,6.12,22.59,9.2,25.3,18.9a10.28,10.28,0,0,0,.87-1.25,60.74,60.74,0,0,1,14-13.51C294.05,639.31,281.14,634.72,268.91,636.35Z"',
                    "/>"
                )
            );
            perch = string(
                abi.encodePacked(
                    perch,
                    "<path",
                    '    d="M301.14,570.15c-6.26,5.48-9.86,15.29-9,27.57.88,13.46,15.21,33.06,21.87,5.45C315.57,591.29,318.55,560.29,301.14,570.15Z"',
                    "/>"
                )
            );
            perch = string(
                abi.encodePacked(
                    perch,
                    "<path",
                    '    d="M366.68,605.14c-7.69,10-4.93,21.85-2,32.59,7.07.48,14.14,1,21.17,1.47-5-10.93-6.12-23.4-11.45-34.06C373.41,603.22,368.6,603.22,366.68,605.14Z"',
                    "/>"
                )
            );
            perch = string(
                abi.encodePacked(
                    perch,
                    "<path",
                    '    d="M417.77,576.28c-7.94,7.08-4.42,50.31,9.66,42.94C439.88,612.7,439.44,567.76,417.77,576.28Z"',
                    "/>"
                )
            );
            perch = string(
                abi.encodePacked(
                    perch,
                    "<path",
                    '    d="M646.12,592.37c-2.62,3.65-1,8-.08,11.46,2.88,10.58,2.88,21.16,4.8,32.7,0,3.85,2.89,7.69,7.7,5.77,2.88-1,6.73-2.89,7.69-5.77,4.81-14.43,4.81-30.78-4.81-42.32C657.25,588.64,651.05,589.12,646.12,592.37Z"',
                    "/>"
                )
            );
            perch = string(
                abi.encodePacked(
                    perch,
                    "<path",
                    '    d="M719.11,609.6c4.81,4.81,12.51-1.92,13.47-8.66,1.25-7.53-.78-15.07-4.21-21.8-3.44,0-10.22-.39-19.7-1C714.64,587.21,710.5,602.55,719.11,609.6Z"',
                    "/>"
                )
            );
            perch = string(
                abi.encodePacked(
                    perch,
                    "<path",
                    '    d="M698.15,644c-4.55-1.56-7.78,5.95-8.74,7.87-4.11,8.91-3.29,13.82-9.21,20.16,7.44,1,14.2,1.74,20.15,2.32C704.85,663.7,710.72,651.83,698.15,644Z"',
                    "/>",
                    "<path",
                    '    d="M456.65,615.3c-8.86,3-5.82,16.11-3.93,28.58l19.95,3C472.32,630.49,471.09,610,456.65,615.3Z"',
                    "/>"
                )
            );
        } else if (index == 2) {
            perch = string(
                abi.encodePacked(
                    "<defs>",
                    "    <style>",
                    "        .cls-perch-8,",
                    "        .cls-perch-9 {",
                    "            mix-blend-mode: multiply;",
                    "            opacity: 0.3;",
                    "        }"
                )
            );
            perch = string(
                abi.encodePacked(
                    perch,
                    "        .cls-perch-6,",
                    "        .cls-perch-8 {",
                    "            fill: #979797;",
                    "        }"
                )
            );
            perch = string(
                abi.encodePacked(
                    perch,
                    "        .cls-perch-7 {",
                    "            fill: #fff6e3;",
                    "        }",
                    "    </style>",
                    "</defs>"
                )
            );
            perch = string(
                abi.encodePacked(
                    perch,
                    "<path",
                    '    class="cls-perch-7"',
                    '    d="M169.4,793.92A45.55,45.55,0,0,1,157,792.11c-18.67-5.3-26.4-18.45-25.87-44,.14-6.75.46-11.88.72-16,.58-9.46.85-13.77-1.77-22-.63-2.06-1.48-4.38-2.77-7.57-.67-1.65-1.4-3.4-2.16-5.2-5.81-13.82-13-31-7.47-44.4,2.63-6.3,7.91-11.09,15.69-14.24,16-6.47,35.38-7.48,54.13-8.46,15.08-.78,30.68-1.6,43.92-5.31,29.8-8.36,307.2-120.94,345.13-140.07,17.74-8.95,33.54-21.43,48.82-33.5,16.13-12.72,31.35-24.75,47.08-31.1a48.54,48.54,0,0,1,18.22-3.75c22.44,0,37.72,17.66,42.51,29.52,1.58,3.9,4.89,8.17,8.4,12.69,7.45,9.62,16.73,21.59,15.44,37.78-1.49,18.5-16.44,24.68-41.75,29.11-7,1.22-15,2.34-23.44,3.52l-5.19.73c-41.86,5.86-215.1,65.39-294.22,101.1-77,34.77-149.95,82.21-162.57,105.76l-1.59,3c-11.49,21.56-28.85,54.15-58.82,54.15Z"',
                    "/>"
                )
            );
            perch = string(
                abi.encodePacked(
                    perch,
                    "<path",
                    '    d="M690.63,418.74c22,0,36.38,18,40.51,28.16,5.13,12.7,25.51,26.61,23.69,49.49-1.38,17.06-15.49,22.87-40,27.15-8.35,1.45-17.91,2.73-28.56,4.23-41.92,5.87-216.77,66.05-294.81,101.28s-151,83.15-163.59,106.71c-11.23,21-28.44,56-58.5,56A43.25,43.25,0,0,1,157.55,790c-16.47-4.68-24.84-15.8-24.3-41.86.47-22,2.8-26.34-1.15-38.66-.69-2.27-1.63-4.77-2.82-7.72-7.7-19-23.69-49.48,4.87-61s68-5.33,97.82-13.7S540.69,505.41,577.48,486.85s65.63-52.36,95.74-64.53a46.36,46.36,0,0,1,17.41-3.58m0-4.33a50.72,50.72,0,0,0-19,3.9c-16,6.47-31.36,18.59-47.61,31.42-15.2,12-30.91,24.41-48.46,33.25-19.06,9.62-101.65,44-175,73.79S246,618.64,230.8,622.91c-13,3.64-28.49,4.45-43.46,5.23-18.92,1-38.48,2-54.82,8.61-8.34,3.37-14,8.56-16.88,15.42-5.91,14.21,1.51,31.87,7.47,46.06.77,1.83,1.49,3.55,2.15,5.18,1.27,3.13,2.1,5.4,2.7,7.37v.05c2.5,7.8,2.25,11.71,1.67,21.17-.26,4.14-.58,9.29-.72,16.08-.55,26.35,7.91,40.57,27.44,46.11a47.48,47.48,0,0,0,13,1.89c31.27,0,49-33.28,60.73-55.3q.81-1.53,1.59-3C243.94,715,317.92,667,393.27,633c36.09-16.3,97.62-39.86,160.58-61.51s114-36.76,133-39.43l5.14-.72c8.49-1.19,16.51-2.31,23.56-3.54,21.06-3.68,41.77-9.11,43.54-31.06,1.36-17-8.21-29.37-15.89-39.28-3.42-4.4-6.64-8.56-8.1-12.18-5-12.41-21-30.87-44.52-30.87Z"',
                    "/>"
                )
            );
            perch = string(
                abi.encodePacked(
                    perch,
                    "<path",
                    '    class="cls-perch-8"',
                    '    d="M754.7,489.48C673.37,510.09,548.55,541,434.18,590.77c-93.83-23.92-139.59,20.8-218.5,39.5,164.28,9.87,94.41,3.67,21.64,81.38-9.84,44.51-93.19,92.43-94.64,12.41.76-26,3.29-28.94-4-46.37-22.67-70.81-26,2.58-6.61,31.82,5.52,19.71-8,77.8,25.46,80.52,37.52,10.67,57.71-30.71,70.34-54.27,28.18-45.83,175.76-116.64,252.17-142.41,57.86-22,176.71-62.07,206.23-65.58C714.08,523.41,760.34,522.12,754.7,489.48Z"',
                    "/>"
                )
            );
            perch = string(
                abi.encodePacked(
                    perch,
                    "<path",
                    '    class="cls-perch-7"',
                    '    d="M726.67,683.75a38.59,38.59,0,0,1-4.09-.22c-17.16-1.79-34.75-10-51.76-17.92-13.69-6.38-27.85-13-41.29-15.91-30.24-6.6-328-37.3-370.5-38.2-1.06,0-2.11,0-3.17,0-18.81,0-37.55,3.41-55.66,6.71-16.56,3-32.21,5.86-46.6,5.86a93.64,93.64,0,0,1-9.57-.47c-35.06-3.67-43.13-36.12-41.55-51.26.44-4.18-.48-9.5-1.45-15.14-2.08-12-4.66-26.92,4.08-40.61,5.22-8.17,12.37-12,22.52-12,7,0,15.6,1.8,28,5.85,6.78,2.21,14.37,5,22.41,7.91l4.87,1.77c39.72,14.46,220.64,43.15,307.27,48.73,17.76,1.14,36,1.72,54.11,1.72,66.35,0,122.24-7.58,139.07-18.86l2.81-1.89c15.6-10.52,37-24.92,58.11-24.92,11.12,0,21,4.08,29.37,12.12,14,13.43,14.66,28.68,2.22,51-3.29,5.89-6,10.27-8.14,13.79-5,8.07-7.21,11.76-8.74,20.22-.41,2.11-.75,4.56-1.1,8-.19,1.78-.36,3.67-.54,5.62-1.74,19.17-4.36,48.14-30.68,48.14Z"',
                    "/>"
                )
            );
            perch = string(
                abi.encodePacked(
                    perch,
                    "<path",
                    '    d="M127.63,506.75c7.5,0,16.54,2.22,27.33,5.74,8,2.63,17.1,6,27.21,9.66C222,536.64,404.59,565.51,490,571c18.23,1.17,36.53,1.72,54.25,1.72,65.32,0,122.81-7.52,140.28-19.23,15.37-10.3,37.94-26.44,59.71-26.44,9.68,0,19.21,3.2,27.88,11.52,12.35,11.86,14.52,25.61,1.82,48.36-10.76,19.25-14.82,22-17.12,34.69-.45,2.33-.79,5-1.13,8.14-2,19.53-2.27,51.82-29.06,51.82a37.23,37.23,0,0,1-3.86-.21c-30.64-3.2-62.54-27.19-92.82-33.8s-329.72-37.37-370.92-38.24l-3.21,0c-36.26,0-72.42,12.57-102.26,12.57a91.86,91.86,0,0,1-9.34-.46c-34-3.56-41-35.27-39.62-48.88s-10.06-35.46,2.29-54.82c5-7.83,11.77-11,20.7-11m0-4.33v0c-10.81,0-18.77,4.25-24.35,13-9.18,14.4-6.52,29.79-4.39,42.15,1,5.48,1.85,10.66,1.44,14.55-1.66,15.84,6.79,49.79,43.48,53.63a95,95,0,0,0,9.79.49c14.59,0,30.32-2.87,47-5.9,18-3.28,36.66-6.68,55.28-6.68,1,0,2.1,0,3.12,0,21.35.45,110.41,8.83,189.21,17s165.45,17.82,180.88,21.19c13.2,2.88,27.25,9.43,40.83,15.76,17.18,8,34.93,16.28,52.46,18.11a40,40,0,0,0,4.31.24c12.54,0,21.52-6.19,26.71-18.4,4.13-9.73,5.24-21.92,6.13-31.71.18-2,.34-3.83.53-5.59.35-3.36.68-5.75,1.07-7.77v-.05c1.45-8.06,3.5-11.41,8.46-19.48,2.17-3.54,4.86-7.94,8.18-13.87,12.84-23,12-39.54-2.61-53.59-8.79-8.44-19.17-12.72-30.87-12.72-21.8,0-43.49,14.61-59.32,25.29l-2.8,1.88c-16.25,10.89-72.94,18.49-137.87,18.49-18.1,0-36.26-.57-54-1.71-39.52-2.55-104.92-10.6-170.67-21s-117.89-21-136-27.58l-4.88-1.78c-8.05-2.94-15.66-5.71-22.46-7.93-12.63-4.12-21.48-6-28.68-6Z"',
                    "/>"
                )
            );
            perch = string(
                abi.encodePacked(
                    perch,
                    '<g class="cls-perch-9">',
                    '    <path class="cls-perch-6"',
                    '    d="M773.2,539.63c-35.07-26.13.9,7.49-21.23,34.74-32.66,31.21-10,103.4-53.26,90.83-88.86-45.79-352.47-60.93-461.65-68.43-44-1.09-85.18,17.49-120.57,11.14,36.74,35.23,91.87-1.38,143.63,2.48,80.07,5.53,245.83,18.1,362.34,38.3,43.94,7.61,76.86,30.32,101.39,33.75,34.26,4.79,30-37.8,34.06-59.76C762.28,602.68,801.48,557.73,773.2,539.63Z"',
                    "    />",
                    "</g>"
                )
            );
        } else if (index == 3) {
            perch = string(
                abi.encodePacked(
                    "<defs>",
                    "    <style>",
                    "        .cls-perch-10,",
                    "        .cls-perch-7,",
                    "        .cls-perch-8,"
                )
            );
            perch = string(
                abi.encodePacked(
                    perch,
                    "        .cls-perch-9 {",
                    "            stroke: #000;",
                    "            stroke-miterlimit: 10;",
                    "            stroke-width: 4.33px;",
                    "        }"
                )
            );
            perch = string(
                abi.encodePacked(
                    perch,
                    "        .cls-perch-7 {",
                    "            fill: #39b34a;",
                    "        }",
                    "        .cls-perch-8 {",
                    "            fill: #8ac43f;",
                    "        }"
                )
            );
            perch = string(
                abi.encodePacked(
                    perch,
                    "        .cls-perch-9 {",
                    "            fill: #333;",
                    "        }",
                    "        .cls-perch-10 {",
                    "            fill: #ffe5ab;",
                    "        }",
                    "    </style>",
                    "</defs>"
                )
            );
            perch = string(
                abi.encodePacked(
                    perch,
                    "<polygon",
                    '    class="cls-perch-7"',
                    '    points="238.9 744.49 235.46 697.44 311.9 692.5 319.72 743.37 238.9 744.49"',
                    "/>"
                )
            );
            perch = string(
                abi.encodePacked(
                    perch,
                    "<ellipse",
                    '    class="cls-perch-8" cx="279.31" cy="743.93" rx="40.41" ry="22.14"',
                    '    transform="translate(-10.24 3.93) rotate(-0.79)"',
                    "/>"
                )
            );
            perch = string(
                abi.encodePacked(
                    perch,
                    "<ellipse",
                    '    class="cls-perch-9" cx="279.31" cy="743.93" rx="11.32" ry="6.2"',
                    '    transform="translate(-10.24 3.93) rotate(-0.79)"',
                    "/>"
                )
            );
            perch = string(
                abi.encodePacked(
                    perch,
                    "<polygon",
                    '    class="cls-perch-7"',
                    '    points="661.42 686.28 652 640.06 577.07 655.97 583.3 707.06 661.42 686.28"',
                    "/>"
                )
            );
            perch = string(
                abi.encodePacked(
                    perch,
                    "<ellipse",
                    '    class="cls-perch-8" cx="622.36" cy="696.67" rx="40.41" ry="22.14"',
                    '    transform="translate(-158.18 183.4) rotate(-14.9)"',
                    "/>"
                )
            );
            perch = string(
                abi.encodePacked(
                    perch,
                    "<ellipse",
                    '    class="cls-perch-9" cx="622.36" cy="696.67" rx="11.32" ry="6.2"',
                    '    transform="translate(-158.18 183.4) rotate(-14.9)"',
                    "/>"
                )
            );
            perch = string(
                abi.encodePacked(
                    perch,
                    "<path",
                    '    class="cls-perch-10"',
                    '    d="M688.17,641.88c-87.46,42-380.09,80.58-477.48,65.78C127.42,701,74.88,544.14,190.34,559.9c93.36,16.15,391.2-22.42,477.48-65.76C772.54,448.82,770.1,604,688.17,641.88Z"',
                    "/>"
                )
            );
            perch = string(
                abi.encodePacked(
                    perch,
                    "<path",
                    '    class="cls-perch-9"',
                    '    d="M681.34,630.36c-87.45,42-380.09,80.58-477.48,65.79-83.27-6.7-135.81-163.53-20.35-147.77C276.88,564.54,574.71,526,661,482.63,765.71,437.3,763.27,592.43,681.34,630.36Z"',
                    "/>"
                )
            );
            perch = string(
                abi.encodePacked(
                    perch,
                    '<circle cx="256.67" cy="600.91" r="6.41" />',
                    '<circle cx="262.72" cy="644.78" r="6.41" />',
                    '<circle cx="304.41" cy="598.56" r="6.41" />',
                    '<circle cx="310.45" cy="642.44" r="6.41" />'
                )
            );
            perch = string(
                abi.encodePacked(
                    perch,
                    '<circle cx="605.48" cy="552.85" r="6.41" />',
                    '<circle cx="611.53" cy="596.73" r="6.41" />',
                    '<circle cx="558.89" cy="563.51" r="6.41" />',
                    '<circle cx="564.93" cy="607.38" r="6.41" />'
                )
            );
        } else {
            perch = string(abi.encodePacked());
        }

        return perch;
    }
}

pragma solidity ^0.8.0;
//SPDX-License-Identifier: MIT

import "hardhat/console.sol";

// GET LISTED ON OPENSEA: https://testnets.opensea.io/get-listed/step-two

// Defining Library
library Perch2Library {
    function GetPerch(uint256 index) public pure returns (string memory) {
        string memory perch;

        if (index == 4) {
            perch = string(
                abi.encodePacked(
                    "<defs>",
                    "    <style>",
                    "        .cls-perch-7 {",
                    "            stroke: #000;",
                    "            stroke-miterlimit: 10;",
                    "            fill: #a56734;",
                    "            stroke-width: 4.48px;",
                    "        }"
                )
            );
            perch = string(
                abi.encodePacked(
                    perch,
                    "    </style>",
                    "</defs>",
                    "<path",
                    '    class="cls-perch-7"',
                    '    d="M771.61,612.1c-9.46-.91-492.82-45.26-518.91-46.35-33.46-.44-48.28,59.2-90.23,59-40.13,1.42-82.15-33.81-78.45-75,3.82-74.49,141.84-73.57,104.6,12.32-19,50-90.85,13.32-55.21-25.5h0c9.56-9.6,24.29,5.5,14.59,14.83-1.68,1.64-4.37,4.75-3.59,7.06,1,3,6.54,6.83,13.65,7.82,8.74-2.22,24.5-29.93,10.34-44.33-7.6-7.25-22.82-8.53-37-3.11-30,10.19-34.34,46.1-13.57,66.23,70.42,60.76,71.83-38.53,135.69-40.06,26.79,1.15,481.4,42.75,520.13,46.44C786.69,592.72,785.45,613.34,771.61,612.1Z"',
                    "/>"
                )
            );
        } else if (index == 5) {
            perch = string(
                abi.encodePacked(
                    "<defs>",
                    "    <style>",
                    "        .cls-perch-13,",
                    "        .cls-perch-7,",
                    "        .cls-perch-9 {",
                    "            stroke: #000;",
                    "            stroke-miterlimit: 10;",
                    "        }"
                )
            );
            perch = string(
                abi.encodePacked(
                    perch,
                    "        .cls-perch-7 {",
                    "            stroke-width: 4.33px;",
                    "        }",
                    "        .cls-perch-7,",
                    "        .cls-perch-9 {",
                    "            fill: #f9cc3d;",
                    "        }"
                )
            );
            perch = string(
                abi.encodePacked(
                    perch,
                    "        .cls-perch-8 {",
                    "            fill: #f7931e;",
                    "        }",
                    "        .cls-perch-9 {",
                    "            stroke-width: 4.67px;",
                    "        }"
                )
            );
            perch = string(
                abi.encodePacked(
                    perch,
                    "        .cls-perch-10 {",
                    "            fill: #ededed;",
                    "        }"
                )
            );
            perch = string(
                abi.encodePacked(
                    perch,
                    "        .cls-perch-11 {",
                    "            fill: #fff;",
                    "        }",
                    "        .cls-perch-12 {",
                    "            fill: #a7b5bc;",
                    "        }"
                )
            );
            perch = string(
                abi.encodePacked(
                    perch,
                    "        .cls-perch-13 {",
                    "            fill: #1b2b30;",
                    "            stroke-width: 4px;",
                    "        }",
                    "    </style>",
                    "</defs>"
                )
            );
            perch = string(
                abi.encodePacked(
                    perch,
                    "<path",
                    '    class="cls-perch-7"',
                    '    d="M106.63,548.61S96.8,655,162.41,667.21c83.85,15.64,98.93-101.78,98.93-101.78l-14.73,7.91s-20,74.24-77.51,64.83c-58.32-9.55-48-83.77-48-83.77Z"',
                    "/>"
                )
            );
            perch = string(
                abi.encodePacked(
                    perch,
                    "<path",
                    '    class="cls-perch-8"',
                    '    d="M159.51,659.16c-50.95-22.07-45.79-87.29-44.9-110l-6-2.22c-7.08,63.34,21.17,140.52,91.82,115C187.57,666.52,174.16,665.51,159.51,659.16Z"',
                    "/>"
                )
            );
            perch = string(
                abi.encodePacked(
                    perch,
                    "<ellipse",
                    '    class="cls-perch-9" cx="280.43" cy="565.85" rx="55.03" ry="14.56"',
                    '    transform="translate(-336.37 701.41) rotate(-76.03)"',
                    "/>"
                )
            );
            perch = string(
                abi.encodePacked(
                    perch,
                    "<path",
                    '    class="cls-perch-8"',
                    '    d="M278.16,599.09c-12.32-1.8,1.12-64.73,10.35-82.13-7,5.7-15.37,23.58-20.87,45.69-10.89,39.63-3.74,79.35,15.46,34.28C281.23,598.46,279.74,599.48,278.16,599.09Z"',
                    "/>"
                )
            );
            perch = string(
                abi.encodePacked(
                    perch,
                    "<path",
                    '    class="cls-perch-10"',
                    '    d="M501.81,650.82c-70.06,0-141.4-19.84-212-59l-1.63-.91.65-1.74c4.05-10.91,7.51-25.73,9.72-41.71l.32-2.3,2.28.48a426.55,426.55,0,0,0,88.47,9.26A423.6,423.6,0,0,0,535.7,529.21c47.84-17.51,90.72-43.09,127.46-76l1.32-1.19,1.42,1.07c21.35,16,46.11,24.17,73.6,24.17,22.64,0,46.35-5.48,70.48-16.28l6.28-2.81-3.54,5.9C776.67,524.12,731,570.87,677.05,603c-53.28,31.72-112.23,47.81-175.23,47.81Z"',
                    "/>"
                )
            );
            perch = string(
                abi.encodePacked(
                    perch,
                    "<path",
                    '    d="M664.6,454.8c22.89,17.19,48.58,24.6,74.9,24.6,23.82,0,48.15-6.07,71.36-16.46-72.58,120.94-184.19,185.71-309,185.71-67.8,0-139.51-19.1-211-58.69,4.77-12.85,8-28.66,9.84-42.16a428.14,428.14,0,0,0,88.92,9.3c100.18,0,199.76-34.85,275-102.3m-.24-5.6-2.65,2.38c-36.53,32.74-79.18,58.18-126.75,75.6a421.57,421.57,0,0,1-145.37,25.59,423.51,423.51,0,0,1-88-9.21l-4.55-1-.64,4.6c-2.2,15.84-5.61,30.49-9.61,41.26l-1.3,3.48,3.26,1.81c35.49,19.66,71.77,34.65,107.82,44.58A397.45,397.45,0,0,0,501.81,653a348.93,348.93,0,0,0,91.9-12.16,340.49,340.49,0,0,0,84.45-36c54.29-32.33,100.18-79.33,136.41-139.71l7.08-11.8L809.09,459c-23.84,10.67-47.26,16.09-69.59,16.09-27,0-51.33-8-72.3-23.74l-2.84-2.14Z"',
                    "/>"
                )
            );
            perch = string(
                abi.encodePacked(
                    perch,
                    "<path",
                    '    class="cls-perch-11"',
                    '    d="M599.88,633.14c3.06-.87,12.69-3.86,14.44-4.46l51.6-173.47q-8.46,7.2-17.25,13.89Z"',
                    "/>"
                )
            );
            perch = string(
                abi.encodePacked(
                    perch,
                    "<path",
                    '    class="cls-perch-11"',
                    '    d="M560,626.45a321.92,321.92,0,0,0,32.11-6.79L634.94,479a410.11,410.11,0,0,1-37.39,24.52Z"',
                    "/>"
                )
            );
            perch = string(
                abi.encodePacked(
                    perch,
                    "<path",
                    '    class="cls-perch-12"',
                    '    d="M290,590c111.15,60.16,217.86,74.23,312.48,44.49,74.19-23.33,127.86-70.45,159.81-105.88A408.5,408.5,0,0,0,810.86,463h0S643.21,682.61,290,590Z"',
                    "/>"
                )
            );
            perch = string(
                abi.encodePacked(
                    perch,
                    "<path",
                    '    class="cls-perch-13"',
                    '    d="M108.42,509.39l165.35,29.69c11.72,7.61.73,42.39-9.69,44.46L106.77,552.92C99.14,531.13,93.69,530.41,108.42,509.39Z"',
                    "/>"
                )
            );
            perch = string(
                abi.encodePacked(
                    perch,
                    "<polygon",
                    '    points="107.21 541.66 274.38 572.31 264.08 583.54 104.65 551.75 107.21 541.66"',
                    "/>"
                )
            );
            perch = string(
                abi.encodePacked(
                    perch,
                    "<path",
                    '    class="cls-perch-7"',
                    '    d="M61.48,498.82c36.47-26.54,76.65,25.95,41.58,54.23C66.63,579.6,26.4,527.1,61.48,498.82Z"',
                    "/>"
                )
            );
            perch = string(
                abi.encodePacked(
                    perch,
                    "<path",
                    '    class="cls-perch-8"',
                    '    d="M50.16,522a31.58,31.58,0,0,1,17.25-24.16c-31.44,22.73-2.74,70.9,32.18,54.21C78.33,568.1,45.72,548.3,50.16,522Z"',
                    "/>"
                )
            );
        } else if (index == 6) {
            perch = string(
                abi.encodePacked(
                    "<defs>",
                    "  <style>",
                    "    .cls-perch-2 {",
                    "      fill: #ff6990;",
                    "    }"
                )
            );
            perch = string(
                abi.encodePacked(
                    perch,
                    "    .cls-perch-15,",
                    "    .cls-perch-16,",
                    "    .cls-perch-19,",
                    "    .cls-perch-2,",
                    "    .cls-perch-4 {",
                    "      stroke: #000;",
                    "      stroke-miterlimit: 10;",
                    "    }"
                )
            );
            perch = string(
                abi.encodePacked(
                    perch,
                    "    .cls-perch-2,",
                    "    .cls-perch-4 {",
                    "      stroke-width: 4.33px;",
                    "    }",
                    "    .cls-perch-4 {",
                    "      fill: #c5f9d0;",
                    "    }"
                )
            );
            perch = string(
                abi.encodePacked(
                    perch,
                    "    .cls-perch-7 {",
                    "      fill: #ffbf40;",
                    "    }",
                    "    .cls-perch-8 {",
                    "      fill: #fad279;",
                    "    }"
                )
            );
            perch = string(
                abi.encodePacked(
                    perch,
                    "    .cls-perch-9 {",
                    "      fill: #92c3d3;",
                    "    }",
                    "    .cls-perch-10 {",
                    "      fill: #acd9ef;",
                    "    }",
                    "    .cls-perch-11 {",
                    "      fill: #81bee2;",
                    "    }"
                )
            );
            perch = string(
                abi.encodePacked(
                    perch,
                    "    .cls-perch-12 {",
                    "      fill: #5fa9e0;",
                    "    }",
                    "    .cls-perch-13 {",
                    "      fill: #5cb2ff;",
                    "    }",
                    "    .cls-perch-14 {",
                    "      fill: #bde6ff;",
                    "    }"
                )
            );
            perch = string(
                abi.encodePacked(
                    perch,
                    "    .cls-perch-15 {",
                    "      fill: #e5005b;",
                    "    }",
                    "    .cls-perch-15,",
                    "    .cls-perch-16,",
                    "    .cls-perch-19 {",
                    "      stroke-width: 4px;",
                    "    }"
                )
            );
            perch = string(
                abi.encodePacked(
                    perch,
                    "    .cls-perch-16 {",
                    "      fill: none;",
                    "    }",
                    "    .cls-perch-17 {",
                    "      fill: #ff8db0;",
                    "    }",
                    "    .cls-perch-18 {",
                    "      fill: #fff;",
                    "    }"
                )
            );
            perch = string(
                abi.encodePacked(
                    perch,
                    "    .cls-perch-19 {",
                    "      fill: #ffd252;",
                    "    }",
                    "    .cls-perch-20 {",
                    "      fill: #fb8525;",
                    "    }",
                    "  </>",
                    "</defs>"
                )
            );
            perch = string(
                abi.encodePacked(
                    perch,
                    '<g id="Scepter" data-name="Scepter">',
                    "  <rect",
                    '    class="cls-perch-7"',
                    '    x="573.15"',
                    '    y="457.07"',
                    '    width="49.05"',
                    '    height="308"',
                    '    transform="translate(-93.61 1113.81) rotate(-81.66)"',
                    "  />"
                )
            );
            perch = string(
                abi.encodePacked(
                    perch,
                    "  <path",
                    '    d="M450.56,566.68l300.77,44.21-6.54,44.57L444,611.25l6.53-44.57m-3.38-4.54-.58,4-6.53,44.57-.58,4,3.95.58,300.77,44.21,4,.58.58-4,6.53-44.57.58-4-4-.58L451.14,562.72l-4-.58Z"',
                    "  />",
                    "  <polygon",
                    '    class="cls-perch-8"',
                    '    points="624.03 592.48 662.02 643.28 615.39 636.45 577.4 585.65 624.03 592.48"',
                    "  />"
                )
            );
            perch = string(
                abi.encodePacked(
                    perch,
                    "  <polygon",
                    '    class="cls-perch-8"',
                    '    points="666.36 598.69 704.35 649.49 685.2 646.68 647.21 595.88 666.36 598.69"',
                    "  />",
                    "  <path",
                    '    class="cls-perch-9"',
                    '    d="M120.93,539.56l34.55,62.75h0a69.67,69.67,0,0,0,35.67-51.16Z"',
                    "  />"
                )
            );
            perch = string(
                abi.encodePacked(
                    perch,
                    "  <path",
                    '    class="cls-perch-10"',
                    '    d="M155.48,602.31l-28.12-66L72.57,590.16C83,606,126.08,623.11,155.48,602.31Z"',
                    "  />",
                    "  <path",
                    '    class="cls-perch-11"',
                    '    d="M125.46,539.83,73,589.42h0a69.65,69.65,0,0,1-19.49-59.24Z"',
                    "  />"
                )
            );
            perch = string(
                abi.encodePacked(
                    perch,
                    "  <path",
                    '    class="cls-perch-12"',
                    '    d="M121.5,541.18l50.16-49.27h0a69.65,69.65,0,0,1,19.49,59.24Z"',
                    "  />",
                    "  <path",
                    '    class="cls-perch-13"',
                    '    d="M171.66,491.91,122,541,88.76,479.76C120.49,460.27,161.11,475.29,171.66,491.91Z"',
                    "  />"
                )
            );
            perch = string(
                abi.encodePacked(
                    perch,
                    "  <path",
                    '    class="cls-perch-10"',
                    '    d="M123.14,541.42,88.76,479.76h0a69.62,69.62,0,0,0-35.67,51.16Z"',
                    "  />",
                    "  <polygon",
                    '    class="cls-perch-14"',
                    '    points="146.17 516.81 162.26 546.92 138.21 571.14 98.06 565.26 81.98 535.15 106.03 510.92 146.17 516.81"',
                    "  />"
                )
            );
            perch = string(
                abi.encodePacked(
                    perch,
                    "  <polygon",
                    '    class="cls-perch-15"',
                    '    points="446.17 566.91 439.46 610.36 256.99 586.62 263.69 543.17 446.17 566.91"',
                    "  />",
                    "  <path",
                    '    class="cls-perch-2"',
                    '    d="M435.45,560.57,428,611.66c-.89,6,3.93,11.71,10.74,12.71h0c6.82,1,13.07-3.07,13.95-9.09l7.49-51.09c.88-6-3.93-11.71-10.75-12.71h0C442.57,550.48,436.33,554.55,435.45,560.57Z"',
                    "  />"
                )
            );
            perch = string(
                abi.encodePacked(
                    perch,
                    "  <path",
                    '    class="cls-perch-2"',
                    '    d="M253.13,534.73l-7.48,51.09c-.89,6,3.93,11.71,10.74,12.71h0c6.82,1,13.06-3.07,13.95-9.09l7.48-51.09c.89-6-3.92-11.71-10.74-12.71h0C260.26,524.64,254,528.71,253.13,534.73Z"',
                    "  />",
                    '  <circle class="cls-perch-15" cx="756.46" cy="634.64" r="28.46" />'
                )
            );
            perch = string(
                abi.encodePacked(
                    perch,
                    '  <circle class="cls-perch-16" cx="123.31" cy="541.39" r="70.68" />',
                    "  <ellipse",
                    '    class="cls-perch-17"',
                    '    cx="767.53"',
                    '    cy="625.37"',
                    '    rx="7.08"',
                    '    ry="14.89"',
                    '    transform="translate(-221.62 583.18) rotate(-36.73)"',
                    "  />"
                )
            );
            perch = string(
                abi.encodePacked(
                    perch,
                    "</g>",
                    "<path",
                    '  class="cls-perch-2"',
                    '  d="M722.71,603.56l-7.49,51.09c-.89,6,3.93,11.71,10.74,12.71h0c6.82,1,13.06-3.07,13.95-9.09l7.49-51.09c.88-6-3.93-11.71-10.75-12.71h0C729.83,593.47,723.59,597.54,722.71,603.56Z"',
                    "/>"
                )
            );
            perch = string(
                abi.encodePacked(
                    perch,
                    "<circle",
                    '  class="cls-perch-18"',
                    '  cx="91.42"',
                    '  cy="476.86"',
                    '  r="24.86"',
                    '  transform="translate(-266.64 148.91) rotate(-36.66)"',
                    "/>"
                )
            );
            perch = string(
                abi.encodePacked(
                    perch,
                    "<circle",
                    '  class="cls-perch-18"',
                    '  cx="132.42"',
                    '  cy="570.4"',
                    '  r="15.23"',
                    '  transform="translate(-93.08 29.99) rotate(-9.58)"',
                    "/>"
                )
            );
            perch = string(
                abi.encodePacked(
                    perch,
                    "<polygon",
                    '  class="cls-perch-19"',
                    '  points="155.72 623.19 180.13 626.77 246.12 582.56 252.66 537.99 202.13 476.7 177.71 473.12 155.72 623.19"',
                    "/>"
                )
            );
            perch = string(
                abi.encodePacked(
                    perch,
                    "<rect",
                    '  class="cls-perch-20"',
                    '  x="105.73"',
                    '  y="539.11"',
                    '  width="147.71"',
                    '  height="21.92"',
                    '  transform="translate(-390.71 647.98) rotate(-81.66)"',
                    "/>"
                )
            );
            perch = string(
                abi.encodePacked(
                    perch,
                    "<path",
                    '  class="cls-perch-4"',
                    '  d="M222.36,499.73a8.41,8.41,0,1,1-9.54,7.1A8.4,8.4,0,0,1,222.36,499.73Z"',
                    "/>"
                )
            );
            perch = string(
                abi.encodePacked(
                    perch,
                    "<path",
                    '  class="cls-perch-4"',
                    '  d="M218,531.37a8.41,8.41,0,1,1-9.55,7.1A8.42,8.42,0,0,1,218,531.37Z"',
                    "/>"
                )
            );
            perch = string(
                abi.encodePacked(
                    perch,
                    "<path",
                    '  class="cls-perch-4"',
                    '  d="M213.67,563a8.41,8.41,0,1,1-9.54,7.11A8.41,8.41,0,0,1,213.67,563Z"',
                    "/>",
                    "<path",
                    '  class="cls-perch-4"',
                    '  d="M209.33,594.65a8.41,8.41,0,1,1-9.55,7.11A8.43,8.43,0,0,1,209.33,594.65Z"',
                    "/>"
                )
            );
        } else if (index == 7) {
            perch = string(
                abi.encodePacked(
                    "<defs>",
                    "  <style>",
                    "    .cls-perch-1 {",
                    "      isolation: isolate;",
                    "    }"
                )
            );
            perch = string(
                abi.encodePacked(
                    perch,
                    "    .cls-perch-10,",
                    "    .cls-perch-11,",
                    "    .cls-perch-12,",
                    "    .cls-perch-13,",
                    "    .cls-perch-14,",
                    "    .cls-perch-15,"
                )
            );
            perch = string(
                abi.encodePacked(
                    perch,
                    "    .cls-perch-16,",
                    "    .cls-perch-4,",
                    "    .cls-perch-7,",
                    "    .cls-perch-8,",
                    "    .cls-perch-9 {",
                    "      stroke: #000;",
                    "      stroke-miterlimit: 10;",
                    "    }"
                )
            );
            perch = string(
                abi.encodePacked(
                    perch,
                    "    .cls-perch-17 {",
                    "      fill: #9b0e00;",
                    "    }",
                    "    .cls-perch-7 {",
                    "      fill: #230d09;",
                    "    }",
                    "    .cls-perch-10,",
                    "    .cls-perch-11,",
                    "    .cls-perch-12,"
                )
            );
            perch = string(
                abi.encodePacked(
                    perch,
                    "    .cls-perch-13,",
                    "    .cls-perch-14,",
                    "    .cls-perch-15,",
                    "    .cls-perch-16,",
                    "    .cls-perch-7,",
                    "    .cls-perch-8,",
                    "    .cls-perch-9 {",
                    "      stroke-width: 3px;",
                    "    }"
                )
            );
            perch = string(
                abi.encodePacked(
                    perch,
                    "    .cls-perch-8 {",
                    "      fill: #724322;",
                    "    }",
                    "    .cls-perch-9 {",
                    "      fill: #683d1f;",
                    "    }"
                )
            );
            perch = string(
                abi.encodePacked(
                    perch,
                    "    .cls-perch-10 {",
                    "      fill: url(#New_Gradient_Swatch_1);",
                    "    }",
                    "    .cls-perch-11 {",
                    "      fill: #845c38;",
                    "    }"
                )
            );
            perch = string(
                abi.encodePacked(
                    perch,
                    "    .cls-perch-12 {",
                    "      fill: url(#New_Gradient_Swatch_1-2);",
                    "    }",
                    "    .cls-perch-13 {",
                    "      fill: url(#linear-perch-gradient);",
                    "    }"
                )
            );
            perch = string(
                abi.encodePacked(
                    perch,
                    "    .cls-perch-14 {",
                    "      fill: #1a4937;",
                    "    }",
                    "    .cls-perch-15 {",
                    "      fill: #245141;",
                    "    }"
                )
            );
            perch = string(
                abi.encodePacked(
                    perch,
                    "    .cls-perch-16 {",
                    "      fill: #446b5d;",
                    "    }",
                    "    .cls-perch-18 {",
                    "      fill: url(#New_Gradient_Swatch_1-3);",
                    "    }",
                    "  </style>"
                )
            );
            perch = string(
                abi.encodePacked(
                    perch,
                    "  <linearGradient",
                    '    id="New_Gradient_Swatch_1"',
                    '    x1="311.53"',
                    '    y1="745.84"',
                    '    x2="788.39"',
                    '    y2="745.84"',
                    '    gradientUnits="userSpaceOnUse"',
                    "  >"
                )
            );
            perch = string(
                abi.encodePacked(
                    perch,
                    '    <stop offset="0" stop-color="#ffd252" />',
                    '    <stop offset="1" stop-color="#dba952" />',
                    "  </linearGradient>",
                    "  <linearGradient"
                )
            );
            perch = string(
                abi.encodePacked(
                    perch,
                    '    id="New_Gradient_Swatch_1-2"',
                    '    x1="119.73"',
                    '    y1="801.65"',
                    '    x2="314.26"',
                    '    y2="801.65"',
                    '    href="#New_Gradient_Swatch_1"',
                    "  />",
                    "  <linearGradient"
                )
            );
            perch = string(
                abi.encodePacked(
                    perch,
                    '    id="linear-perch-gradient"',
                    '    x1="249.4"',
                    '    y1="723.29"',
                    '    x2="609.55"',
                    '    y2="518.83"',
                    '    gradientUnits="userSpaceOnUse"',
                    "  >"
                )
            );
            perch = string(
                abi.encodePacked(
                    perch,
                    '    <stop offset="0" stop-color="#2b644a" />',
                    '    <stop offset="1" stop-color="#32464a" />',
                    "  </linearGradient>",
                    "  <linearGradient",
                    '    id="New_Gradient_Swatch_1-3"',
                    '    x1="303.31"',
                    '    y1="659.73"',
                    '    x2="289.14"'
                )
            );
            perch = string(
                abi.encodePacked(
                    perch,
                    '    y2="592.44"',
                    '    href="#New_Gradient_Swatch_1"',
                    "  />",
                    "</defs>",
                    '<g class="cls-perch-1">'
                )
            );
            perch = string(
                abi.encodePacked(
                    perch,
                    "  <path",
                    '    class="cls-perch-7"',
                    '    d="M740.64,603.25l43.84,37.39L308.59,771.17,121,749.8,125,682Z"',
                    "  />",
                    "  <path",
                    '    class="cls-perch-8"',
                    '    d="M780.12,634.64,306.26,763.41,130,742.41,137,626.13,128.34,629l-7.06,120.62,187.55,21.37L787.56,640.49a.25.25,0,0,0,.09-.44Z"',
                    "  />"
                )
            );
            perch = string(
                abi.encodePacked(
                    perch,
                    "  <path",
                    '    class="cls-perch-9"',
                    '    d="M787.88,641.3l-1.76,69.08L315.31,856.16a.64.64,0,0,1-.84-.57L308.26,771l479.2-130A.33.33,0,0,1,787.88,641.3Z"',
                    "  />",
                    "  <polygon",
                    '    class="cls-perch-10"',
                    '    points="788.39 654.35 787.75 694.04 313.8 837.34 311.53 788.84 788.39 654.35"',
                    "  />"
                )
            );
            perch = string(
                abi.encodePacked(
                    perch,
                    "  <path",
                    '    class="cls-perch-11"',
                    '    d="M308.59,771.17,314.16,856a.51.51,0,0,1-.57.54l-189.5-24.4-3-82.36Z"',
                    "  />",
                    "  <polygon",
                    '    class="cls-perch-12"',
                    '    points="311.53 788.84 314.25 837.34 121.37 813.36 119.73 765.96 311.53 788.84"',
                    "  />"
                )
            );
            perch = string(
                abi.encodePacked(
                    perch,
                    "</g>",
                    '<g class="cls-perch-1">',
                    "  <path",
                    '    class="cls-perch-13"',
                    '    d="M138.11,587.71l127.42-37.1h.08s419.75-8.14,419.8-8.09l90.9,80.42c.18.16-466.91,109-466.91,109h-.11L127.47,705.17a.31.31,0,0,1-.26-.33L137.9,588A.29.29,0,0,1,138.11,587.71Z"',
                    "  />",
                    "  <polygon",
                    '    class="cls-perch-14"',
                    '    points="776.86 623.2 784.1 634.75 310.62 751.43 309.35 731.95 776.86 623.2"',
                    "  />"
                )
            );
            perch = string(
                abi.encodePacked(
                    perch,
                    "  <path",
                    '    class="cls-perch-15"',
                    '    d="M309.35,732l1.27,19.48L115.18,720.59a0,0,0,0,1,0-.06l12-15.4Z"',
                    "  />",
                    "  <path",
                    '    class="cls-perch-16"',
                    '    d="M128.81,597.25,115.19,719.91a.2.2,0,0,0,.35.14l11.65-14.92s10-116.85,10-116.8Z"',
                    "  />"
                )
            );
            perch = string(
                abi.encodePacked(
                    perch,
                    "</g>",
                    "<polygon",
                    '  class="cls-perch-17"',
                    '  points="232.82 646.77 188.29 651.38 186.59 616.22 227.81 611.95 223.82 584.24 260.48 580.44 265.58 608.03 395.1 594.6 411.87 628.21 272 642.71 278.25 676.43 237.69 680.63 232.82 646.77"',
                    "/>"
                )
            );
            perch = string(
                abi.encodePacked(
                    perch,
                    "<path",
                    '  d="M258.71,582.8l5.11,27.59,130-13.48,14.71,29.47L269.45,640.79l6.24,33.73-36.15,3.74-4.87-33.86L190.34,649l-1.49-30.83,41.42-4.29-4-27.71,32.43-3.36m3.53-4.72-4,.41-32.43,3.37-4.48.46.64,4.46L225.35,610l-36.94,3.83-4.08.42.2,4.09L186,649.2l.22,4.57,4.55-.47L231,649.13l4.29,29.75.59,4.11,4.13-.43,36.16-3.74,4.66-.48-.85-4.61-5.39-29.11L409,630.68l6.22-.64-2.8-5.59L397.71,595l-1.34-2.69-3,.31-126,13.07L263,582l-.73-3.93Z"',
                    "/>",
                    "<polygon",
                    '  class="cls-perch-18"',
                    '  points="197.12 625.15 239.29 620.78 235.3 593.08 252.1 591.34 257.21 618.92 389.06 605.25 396.13 619.43 259.91 633.55 266.16 667.27 246.27 669.33 241.4 635.47 197.84 639.98 197.12 625.15"',
                    "/>"
                )
            );
        } else {
            perch = string(abi.encodePacked());
        }

        return perch;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int)", p0));
	}

	function logUint(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
	}

	function log(uint p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
	}

	function log(uint p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
	}

	function log(uint p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
	}

	function log(string memory p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
	}

	function log(uint p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
	}

	function log(uint p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
	}

	function log(uint p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
	}

	function log(uint p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
	}

	function log(uint p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
	}

	function log(uint p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
	}

	function log(uint p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
	}

	function log(uint p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
	}

	function log(uint p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
	}

	function log(uint p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
	}

	function log(uint p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
	}

	function log(bool p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
	}

	function log(bool p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
	}

	function log(bool p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
	}

	function log(address p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
	}

	function log(address p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
	}

	function log(address p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
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