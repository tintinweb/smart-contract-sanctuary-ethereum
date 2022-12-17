pragma solidity ^0.8.0;
//SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "base64-sol/base64.sol";

import "./BackgroundLibrary.sol";
import "./BackgroundLibrary2.sol";
import "./BackgroundLibrary3.sol";
import "hardhat/console.sol";

// GET LISTED ON OPENSEA: https://testnets.opensea.io/get-listed/step-two

contract Background is ERC721Enumerable {
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

    mapping(uint256 => uint256) public parrot_backgrounds;

    //! Properties types
    string[7] public backgrounds;

    constructor() ERC721("ParrotBackground", "PRTBG") {
        backgrounds = [
            "gradient",
            "cave",
            "forest",
            "jungle",
            "skate rail",
            "beach",
            "party house"
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
        parrot_backgrounds[id] = uint256(
            ((uint8(predictableRandom[11]) << 8) |
                uint8(predictableRandom[12])) % 25
        );

        (bool success, ) = recipient.call{value: msg.value}("");
        require(success, "could not send");

        return id;
    }

    // Visibility is `public` to enable it being called by other contracts for composition.
    function renderTokenById(uint256 id) public view returns (string memory) {
        uint256 bgIndex = getPropertiesById(id);

        string memory render = string(
            abi.encodePacked(
                BackgroundLibrary.GetBackground(bgIndex),
                Background2Library.GetBackground(bgIndex),
                Background3Library.GetBackground(bgIndex)
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
        uint256 bgIndex = getPropertiesById(id);
        if (bgIndex < 9) return backgrounds[0];
        if (bgIndex < 21) {
            uint256 newIndex = ((bgIndex - 9) / 3) + 1;
            return backgrounds[newIndex];
        }

        string memory desc = (bgIndex < 23) ? backgrounds[5] : backgrounds[6];
        return desc;
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        require(_exists(id), "!exist");

        uint256 bgIndex = getPropertiesById(id);
        if (bgIndex < 9) bgIndex = 0;
        else if (bgIndex < 21) {
            bgIndex = ((bgIndex - 9) / 3) + 1;
        } else {
            bgIndex = (bgIndex < 23) ? 5 : 6;
        }

        string memory name = string(
            abi.encodePacked("Parrot Background #", id.toString())
        );

        string memory description = string(
            abi.encodePacked(backgrounds[bgIndex], " background ")
        );
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
                                '","attributes":[{"trait_type":"background","value":"',
                                backgrounds[bgIndex],
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
    function getPropertiesById(uint256 id)
        public
        view
        returns (uint256 bgIndex)
    {
        bgIndex = parrot_backgrounds[id];
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
library BackgroundLibrary {
    function GetBackground(uint256 colorIndex)
        public
        pure
        returns (string memory)
    {
        string memory background;

        if (colorIndex == 0) {
            background = string(
                abi.encodePacked(
                    "<defs>"
                    "   <radialGradient",
                    '       id="radial-bg-gradient-0"',
                    '       cx="868.1"',
                    '       cy="-2326.18"',
                    '       r="559.49"',
                    '       gradientTransform="matrix(0.94, 0, 0, -0.95, -373.49, -1767.37)"',
                    '       gradientUnits="userSpaceOnUse"',
                    "   >",
                    '       <stop offset="0" stop-color="#c8a5db" />',
                    '       <stop offset="1" stop-color="#412951" />',
                    "   </radialGradient>",
                    "</defs>",
                    '<g id="BGs">',
                    '   <rect style="fill: url(#radial-bg-gradient-0)" x="-6.2" y="-0.06" width="883.11" height="888.96" />',
                    "</g>"
                )
            );
        } else if (colorIndex == 1) {
            background = string(
                abi.encodePacked(
                    "<defs>"
                    "   <radialGradient",
                    '       id="radial-bg-gradient-1"',
                    '       cx="441.55"',
                    '       cy="-1967.44"',
                    '       r="443.02"',
                    '       gradientTransform="matrix(1, 0, 0, -1, 0, -1522.96)"',
                    '       gradientUnits="userSpaceOnUse"',
                    "   >",
                    '       <stop offset="0.23" stop-color="#ff4803" />',
                    '       <stop offset="1" stop-color="#ffb93b" />',
                    "   </radialGradient>",
                    "</defs>",
                    '<g id="BGs">',
                    '   <rect style="fill: url(#radial-bg-gradient-1)" x="-6.2" y="-0.06" width="883.11" height="888.96" />',
                    "</g>"
                )
            );
        } else if (colorIndex == 2) {
            background = string(
                abi.encodePacked(
                    "<defs>"
                    "   <radialGradient",
                    '       id="radial-bg-gradient-2"',
                    '       cx="441.55"',
                    '       cy="-1967.44"',
                    '       r="443.02"',
                    '       gradientTransform="matrix(1, 0, 0, -1, 0, -1522.96)"',
                    '       gradientUnits="userSpaceOnUse"',
                    "   >",
                    '       <stop offset="0.3" stop-color="#c8a5db" />',
                    '       <stop offset="1" stop-color="#c5f9d0" />',
                    "   </radialGradient>",
                    "</defs>",
                    '<g id="BGs">',
                    '   <rect style="fill: url(#radial-bg-gradient-2)" x="-6.2" y="-0.06" width="883.11" height="888.96" />',
                    "</g>"
                )
            );
        } else if (colorIndex == 3) {
            background = string(
                abi.encodePacked(
                    "<defs>"
                    "   <radialGradient",
                    '       id="radial-bg-gradient-3"',
                    '       cx="784.61"',
                    '       cy="-4296.57"',
                    '       r="559.49"',
                    '       gradientTransform="matrix(0.95, 0, 0, -0.95, -317.64, -3652.7)"',
                    '       gradientUnits="userSpaceOnUse"',
                    "   >",
                    '       <stop offset="0" stop-color="#9cff55" />',
                    '       <stop offset="1" stop-color="#ff0" />',
                    "   </radialGradient>",
                    "</defs>",
                    '<g id="BGs">',
                    '   <rect style="fill: url(#radial-bg-gradient-3)" x="-6.2" y="-0.06" width="883.11" height="888.96" />',
                    "</g>"
                )
            );
        } else if (colorIndex == 4) {
            background = string(
                abi.encodePacked(
                    "<defs>"
                    "   <radialGradient",
                    '       id="radial-bg-gradient-4"',
                    '       cx="930.24"',
                    '       cy="-4324.8"',
                    '       r="559.49"',
                    '       gradientTransform="matrix(0.94, 0, 0, -0.95, -431.16, -3667.14)"',
                    '       gradientUnits="userSpaceOnUse"',
                    "   >",
                    '       <stop offset="0" stop-color="#93278f" />',
                    '       <stop offset="0.14" stop-color="#993396" />',
                    '       <stop offset="0.38" stop-color="#a753a9" />',
                    '       <stop offset="0.71" stop-color="#bf87c6" />',
                    '       <stop offset="1" stop-color="#d6bbe4" />',
                    "   </radialGradient>",
                    "</defs>",
                    '<g id="BGs">',
                    '   <rect style="fill: url(#radial-bg-gradient-4)" x="-6.2" y="-0.06" width="883.11" height="888.96" />',
                    "</g>"
                )
            );
        } else if (colorIndex == 5) {
            background = string(
                abi.encodePacked(
                    "<defs>"
                    "   <radialGradient",
                    '       id="radial-bg-gradient-5"',
                    '       cx="992.47"',
                    '       cy="-4324.8"',
                    '       r="559.49"',
                    '       gradientTransform="matrix(0.94, 0, 0, -0.95, -490.4, -3667.14)"',
                    '       gradientUnits="userSpaceOnUse"',
                    "   >",
                    '       <stop offset="0" stop-color="#395175" />',
                    '       <stop offset="0.14" stop-color="#345c7d" />',
                    '       <stop offset="0.39" stop-color="#287a93" />',
                    '       <stop offset="0.71" stop-color="#14aab7" />',
                    '       <stop offset="1" stop-color="#00dbdb" />',
                    "   </radialGradient>",
                    "</defs>",
                    '<g id="BGs">',
                    '   <rect style="fill: url(#radial-bg-gradient-5)" x="-6.2" y="-0.06" width="883.11" height="888.96" />',
                    "</g>"
                )
            );
        } else if (colorIndex == 6) {
            background = string(
                abi.encodePacked(
                    "<defs>"
                    "   <radialGradient",
                    '       id="radial-bg-gradient-6"',
                    '       cx="784.61"',
                    '       cy="-6334.12"',
                    '       r="559.49"',
                    '       gradientTransform="matrix(0.95, 0, 0, -0.95, -317.64, -5577.96)"',
                    '       gradientUnits="userSpaceOnUse"',
                    "   >",
                    '       <stop offset="0" stop-color="#c5f9d0" />',
                    '       <stop offset="0.05" stop-color="#b7eac4" />',
                    '       <stop offset="0.23" stop-color="#82b397" />',
                    '       <stop offset="0.41" stop-color="#568572" />',
                    '       <stop offset="0.58" stop-color="#346155" />',
                    '       <stop offset="0.74" stop-color="#1c4841" />',
                    '       <stop offset="0.88" stop-color="#0d3834" />',
                    '       <stop offset="1" stop-color="#083330" />',
                    "   </radialGradient>",
                    "</defs>",
                    '<g id="BGs">',
                    '   <rect style="fill: url(#radial-bg-gradient-6)" x="-6.2" y="-0.06" width="883.11" height="888.96" />',
                    "</g>"
                )
            );
        } else if (colorIndex == 7) {
            background = string(
                abi.encodePacked(
                    "<defs>"
                    "   <radialGradient",
                    '       id="radial-bg-gradient-7"',
                    '       cx="930.24"',
                    '       cy="-6353.57"',
                    '       r="559.49"',
                    '       gradientTransform="matrix(0.94, 0, 0, -0.95, -431.16, -5592.4)"',
                    '       gradientUnits="userSpaceOnUse"',
                    "   >",
                    '       <stop offset="0" stop-color="#db6972" />',
                    '       <stop offset="0.25" stop-color="#dc6c74" />',
                    '       <stop offset="0.44" stop-color="#df767b" />',
                    '       <stop offset="0.61" stop-color="#e48686" />',
                    '       <stop offset="0.77" stop-color="#ec9d96" />',
                    '       <stop offset="0.92" stop-color="#f5bbab" />',
                    '       <stop offset="1" stop-color="#fbcdb8" />',
                    "   </radialGradient>",
                    "</defs>",
                    '<g id="BGs">',
                    '   <rect style="fill: url(#radial-bg-gradient-7)" x="-6.2" y="-0.06" width="883.11" height="888.96" />',
                    "</g>"
                )
            );
        } else if (colorIndex == 8) {
            background = string(
                abi.encodePacked(
                    "<defs>"
                    "   <radialGradient",
                    '       id="radial-bg-gradient-8"',
                    '       cx="992.47"',
                    '       cy="-6353.57"',
                    '       r="559.49"',
                    '       gradientTransform="matrix(0.94, 0, 0, -0.95, -490.4, -5592.4)"',
                    '       gradientUnits="userSpaceOnUse">',
                    "   >",
                    '       <stop offset="0" stop-color="#006837" />',
                    '       <stop offset="0.13" stop-color="#0b7339" />',
                    '       <stop offset="0.35" stop-color="#29903f" />',
                    '       <stop offset="0.65" stop-color="#5abf48" />',
                    '       <stop offset="1" stop-color="#9cff55" />',
                    "   </radialGradient>",
                    "</defs>",
                    '<g id="BGs">',
                    '   <rect style="fill: url(#radial-bg-gradient-8)" x="-6.2" y="-0.06" width="883.11" height="888.96" />',
                    "</g>"
                )
            );
        } else {
            background = string(abi.encodePacked('<g id="BGs">', "</g>"));
        }
        return background;
    }
}

pragma solidity ^0.8.0;
//SPDX-License-Identifier: MIT

import "hardhat/console.sol";

// GET LISTED ON OPENSEA: https://testnets.opensea.io/get-listed/step-two

// Defining Library
library Background2Library {
    function GetBackgroundShade(uint256 index)
        public
        pure
        returns (string memory)
    {
        string memory background;

        if (index == 0) {
            background = string(
                abi.encodePacked(
                    '<g id="BGs">',
                    '<rect class="cls-cv-1" x="-4.53" y="0.76" width="887.12" height="885.85" />',
                    "<path",
                    '  class="cls-cv-2"',
                    '  d="M789.68,447.13C695.19,344.37,436.78,670,651.47,714.36,773,739.47,994.26,669.62,789.68,447.13Z"',
                    "/>"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    "<path",
                    '  class="cls-cv-3"',
                    '  d="M428.14,501.41C514.31,323.52,670.75,178,762.2,310.44c98,142,99.68,52.64,120.39,102.44V.76H-4.53V886.61H882.59V639.89C717.77,676.22,330.6,702.75,428.14,501.41Z"',
                    "/>",
                    "<path",
                    '  class="cls-cv-4"',
                    '  d="M600.86,658.07c-75,7.95-161,33.82-222.29-10.15-56.22-37.86,14.15-73.76-20.24-151.6-26-58.85-2.09-126.2,57.89-169.79,56.1-28.92,65.21,28,89.38-85.61,28.55-79.53,127.95-125.54,204.54-108.61,28.05,6.21,31.87,47.26,56.23,62.49,47,29.38,86,60.65,116.22,96.48V.76H-4.53V886.61H882.59V658.27C804.78,683,686.39,657.68,600.86,658.07Z"',
                    "/>"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    "<path",
                    '  class="cls-cv-5"',
                    '  d="M231.15,626.21c-68.37-45.51-92.45-195.23-3-227.93,31.61-11.56,33.24,50.83,56.14,36.94,47.46-56.74,1.46-213,100.79-240.29,81.85,50.75,103.53-95.9,140.69-22.75,44.09,86.38,83.36,75.86,94.7-20.84C634.31,46.86,781.92,23.62,786.12,138.26c3.27,89.36,17.14,127.35,39.23,130.77,28.2,4.37,21.79-65.38,57.24-61V.76H-4.53V886.61H882.59V658.5C666.07,672.87,415,748.6,231.15,626.21Z"',
                    "/>",
                    "<path",
                    '  class="cls-cv-6"',
                    '  d="M550.78,731.09C444.48,706.9,202,868.39,117.55,596.76,75.84,462.61,151.17,366,208.34,318.62c60.49-48.22,7.58-198.34,67.77-258.28,5.68-11.09,38.05-13,45.41-2.49C370.43,99.44,330.06,359.48,384,348c43.67-9.27,36.23-125.09,46.85-168.43,12.29-46.31,48.33-96.51,97.22-106.29,22.66-.44,23.95,24,39.58,31,86.58-3.81,55,99.32,84.56,94.4,42.37-8.16,16.51-86.86,32.34-130.14,14.13-40.76,71.57-66.82,107.58-38.18C823.3,58,799,117.48,829.06,146.3c13.94,13.36,34.43,14.89,53.53,19.63V.76H-4.53V886.61H882.59V714.31C804.13,765.93,689.88,762.74,550.78,731.09Z"',
                    "/>"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    "<path",
                    '  class="cls-cv-7"',
                    '  d="M884.2,325.73a29.6,29.6,0,0,0-17.93,6.84c-11.34,9.82-15.38,25.47-18.18,40.2C834,447,836.3,523.24,830.41,598.57s-16,234.95-65.4,214c-22.85-20.13-5.06-57.5-9.35-87.64-1.59-11.18-6.43-21.58-10.55-32.08-25.35-64.55,19.21-214.6-23.13-205.32C683.84,509.23,675.8,560.2,673.41,604c-9.34,170.67-58.36,159.89-74.73,236-7.67,35.7-68.42-6.6-95.9,17.44-7.92,6.93-32.74,20.3-52.47,28.33H884.2Z"',
                    "/>",
                    "<path",
                    '  class="cls-cv-7"',
                    '  d="M368.91,885.83c-.47-.75-.93-1.51-1.35-2.31-7.75-14.73-5.37-34-16-46.88-13.34-16.14-41.42-14.78-52.63-32.48-4.86-7.68-5.28-17.26-5.73-26.34a670.15,670.15,0,0,0-18.31-125.61c-4.06-16.58-16.94-37.36-32.59-30.53-8.07,3.52-11.37,13-13.51,21.56-14.08,56.23-15.5,116.61-42.28,168-8.69,16.7-27.77,34.06-43.88,24.33-7.81-4.71-11.15-14.14-13.87-22.84A1991,1991,0,0,1,75.06,600.28c-3.75-19.22-13.94-43.77-33.35-41.19-14.7,2-21.68,18.77-25.83,33Q5.41,628-5,663.9V885.83Z"',
                    "/>",
                    "</g>"
                )
            );
        } else if (index == 1) {
            background = string(
                abi.encodePacked(
                    '<g id="BGs">',
                    '<rect class="cls-fs-1" x="-3.48" y="-3.75" width="888.05" height="889.99" />',
                    '<path class="cls-fs-1" d="M224.5,764h0Z" />',
                    '<path class="cls-fs-1" d="M266.63,555.75l1-.85c0,.14.09.28.13.42Z" />',
                    '<path class="cls-fs-1" d="M266.63,555.75l1.13-.43c0-.14-.09-.28-.13-.42Z" />'
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    "<path",
                    '  class="cls-fs-2"',
                    '  d="M770.91,355.09c10.53-25.4,19.77-84.79,19.77-84.79l1.39.21L805.18-4.64H786.77a3525.15,3525.15,0,0,0-54.92,419.78C745.06,404.59,756.5,389.86,770.91,355.09Z"',
                    "/>",
                    "<path",
                    '  class="cls-fs-2"',
                    '  d="M118.55,288.78l3,4.25Q117,143.9,115.75-4.64H50.9L65.66,186C75.49,218,93.05,252,118.55,288.78Z"',
                    "/>"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    "<path",
                    '  class="cls-fs-2"',
                    '  d="M108.59,344c-6.8-9.52-14.5-20.32-22.9-32.43-4.08-5.87-8-11.69-11.67-17.46l5.64,72.81c6.16,79.61,12.54,161.93,10,243.82-.84,26.54-2.61,53.41-4.32,79.4C80.85,757.61,76.63,821.77,87,884.2H152c-12.59-172-22-345.31-28.14-518.57C119.1,358.75,114,351.66,108.59,344Z"',
                    "/>",
                    "<path",
                    '  class="cls-fs-2"',
                    '  d="M631.41,377.71l-2.82.83c-3.69-12.48-14.83-22.55-27.74-34.21-9.58-8.65-20.1-18.17-28.37-30-.46,70.05,5,141.05,10.36,210L610.7,884.2h16.44A3626,3626,0,0,1,631.41,377.71Z"',
                    "/>"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    "<path",
                    '  class="cls-fs-2"',
                    '  d="M776.88,589.43l8.32-174.54C768.82,440,753.07,450,735.68,461c-2.28,1.45-4.62,2.93-7,4.47a3520.55,3520.55,0,0,0,1.6,418.77h39.64C767.55,785.27,772.28,685.88,776.88,589.43Z"',
                    "/>",
                    "<path",
                    '  class="cls-fs-3"',
                    '  d="M282.43,355.82c1.13,31.12,2.29,63.3,3,94.78A3638.21,3638.21,0,0,1,269.6,884.2h60.28a3698.18,3698.18,0,0,0,15.56-435c-.74-31.86-1.91-64.24-3.05-95.55-4.29-118.56-8.7-240.88,9.44-358.29H291.15C273.73,115.34,278.15,237.41,282.43,355.82Z"',
                    "/>"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    "<path",
                    '  class="cls-fs-4"',
                    '  d="M104.1,690.15c1.72-26,3.49-52.86,4.32-79.4,2.58-81.89-3.8-164.21-10-243.82,0,0-10.33-120.24-14-180.9L69.69-4.64H19.54L48.61,370.79C54.67,449.07,60.93,530,58.45,609.18c-.81,25.67-2.55,52.11-4.24,77.68-4.27,64.81-8.67,131.49,1,197.34h50.59C95.43,821.77,99.65,757.61,104.1,690.15Z"',
                    "/>",
                    "<path",
                    '  class="cls-fs-5"',
                    '  d="M802.07,270.51,786.88,589.43c-4.6,96.45-9.33,195.84-7,294.77h60c-2.4-97.32,2.3-196.08,6.87-291.92L875.25-4.64H815.18Z"',
                    "/>"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    "<path",
                    '  class="cls-fs-6"',
                    '  d="M405.18,884.2h80.07A7759,7759,0,0,0,471.74-4.64H391.53A7677.75,7677.75,0,0,1,405.18,884.2Z"',
                    "/>",
                    "<path",
                    '  class="cls-fs-7"',
                    '  d="M215.75-4.64h-100Q117,143.76,121.51,293l-3-4.25C93.05,252,75.49,218,65.66,186c-7.94-25.78-10.86-50.18-8.82-73.49L17,109.06c-5,57,13.71,117.7,57,185.06,3.72,5.77,7.59,11.59,11.67,17.46,8.4,12.11,16.1,22.91,22.9,32.43,5.45,7.65,10.51,14.74,15.3,21.62C130,538.89,139.44,712.25,152,884.2H252.3C230.56,589.59,218.27,290.74,215.75-4.64Z"',
                    "/>"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    "<path",
                    '  class="cls-fs-8"',
                    '  d="M582.84,524.36c-5.33-68.94-10.82-139.94-10.36-210q.09-14.24.52-28.4c.81-25.68,4.24-77.68,4.24-77.68l-31-2L527.35,205s-3.49,52.86-4.32,79.4c-2.57,81.89,3.8,164.21,10,243.82l27.56,356H610.7Z"',
                    "/>",
                    "<path",
                    '  class="cls-fs-7"',
                    '  d="M790.68,270.3s-9.24,59.39-19.77,84.79c-14.41,34.77-25.85,49.5-39.06,60.05A3525.15,3525.15,0,0,1,786.77-4.64H682Q651.62,157.9,636.17,322.44c-2.85-2.68-5.71-5.27-8.5-7.79-11.09-10-21.56-19.48-26.65-30.41-3.57-7.67-5-17.13-6.53-27.14l-12.21-80.21-36,29.36,8.65,56.87c1.8,11.78,3.83,25.13,9.81,38a87.34,87.34,0,0,0,7.73,13.25c8.27,11.79,18.79,21.31,28.37,30,12.91,11.66,30.56,33.38,30.56,33.38a3626,3626,0,0,0-4.27,506.49H730.29a3520.55,3520.55,0,0,1-1.6-418.77c2.37-1.54,4.71-3,7-4.47,17.39-11,33.14-21,49.52-46.07,7.36-11.29,14.85-25.62,22.66-44.48,12.43-30,22.39-94.3,22.39-94.3Z"',
                    "/>"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    '<path class="cls-fs-1" d="M266.63,36.06l1.13-.13a1.59,1.59,0,0,0-.13-.13Z" />',
                    '<g class="cls-fs-9">',
                    '  <rect class="cls-fs-1" x="-3.48" y="-3.75" width="888.05" height="889.99" />',
                    '  <path class="cls-fs-1" d="M224.5,764h0Z" />',
                    '  <path class="cls-fs-1" d="M266.63,555.75l1-.85c0,.14.09.28.13.42Z" />',
                    '  <path class="cls-fs-1" d="M266.63,555.75l1.13-.43c0-.14-.09-.28-.13-.42Z" />',
                    "</g>"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    "<path",
                    '  class="cls-fs-10"',
                    '  d="M423.34-5l-14.46,69.1,34.68,69.46c11.77,23.59,24.33,48.12,45.73,63.51,33.95,24.42,80.27,19.53,120.29,31.68,35.83,10.88,66,35.34,100.83,49.13C765.26,299.58,826.27,293.22,885,284V-5Z"',
                    "/>",
                    "<path",
                    '  class="cls-fs-11"',
                    '  d="M-6.4,168.18c60.61,9.52,147.57,42.63,196,17.93C223.17,169,252.05,143.22,287,129.19c59.25-23.79,125.88-10.47,189.72-9.55,67.51,1,137.2-13.51,191.8-53.21A211.81,211.81,0,0,0,730.64-5H-6.4Z"',
                    "/>",
                    "</g>"
                )
            );
        } else if (index == 2) {
            background = string(
                abi.encodePacked(
                    '<g id="BGs">',
                    '<rect class="cls-jn-1" x="-3.48" y="-3.75" width="888.05" height="889.99" />',
                    "<path",
                    '  class="cls-jn-2"',
                    '  d="M480.84,209.87C466,315.59,511.37,466.93,644.25,457.52,803.19,446.26,777-76.18,745.81,233.28c-6.36,43.11-15.15,105-31.36,144.77a142.77,142.77,0,0,1-17.66,31c.44.54-15.79,16.8-15.81,16A88,88,0,0,1,661.8,436.3c-21.86,9.15-51.65,8.91-77.07-1.91-16-5.77-39-24.63-49.25-38.95-8.45-10.5-18.54-29.07-22.12-38.08-7.5-17.27-13.22-41.63-15.13-57.31C489.85,286.2,508.78,173.35,480.84,209.87Z"',
                    "/>"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    "<path",
                    '  class="cls-jn-2"',
                    '  d="M879.87,283.71c-5.51-30.81-26.3-93-104.64-165.85-19.84-14.88-24.8,19.84-24.8,19.84s72.33,90.42,86.77,151.89c-62.84-34.91-163-52.83-263.22-61.54C566.25,251.24,561.1,259,561.1,259S793,266.7,808.47,338.85s0,324.67,0,324.67h76.1S881.34,281.32,879.87,283.71Z"',
                    "/>",
                    "<path",
                    '  class="cls-jn-3"',
                    '  d="M795,617.11c-8.15-13.36-32.65-37.14-101.46-26.27a25.06,25.06,0,0,1-25.76-12.73c-54.92-98.68-226.41-86.26-276.63-33.91a25.39,25.39,0,0,1-19.27,7.64c-36.23-1.34-76.85,6.39-107.75,47.69A24.83,24.83,0,0,1,231,605.82c-17.67-11.3-45.14-15-64.56-10.67a53.93,53.93,0,0,1-44.88-10.28c-14.67-11.53-37.09-22.29-83.18-34.14a103.23,103.23,0,0,0-39.78-2.14l-2,342.14H757l41.42-259.67A24.63,24.63,0,0,0,795,617.11Z"',
                    "/>"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    "<path",
                    '  class="cls-jn-2"',
                    '  d="M159.55-3.75c-11.29,28.67,15.07,63.58-6,94.66-26,38.45-103.34,34-155.91,58.51V418.11C25.4,428.51,56.21,432.55,86,434.24c82.52,3.63,178.19,9.36,221.51-74.88,71-70.29,229.55,19.45,266.48-97.51,4.4-21.81-2.26-47.44,12-64.49,15.21-18.15,43.31-14.35,67-12.94,65.41,9.57,112.64-46.89,170.58-58.68,26.4-5.37,43.78-7.66,61.74-3.78V-3.75Z"',
                    "/>",
                    '<path class="cls-jn-4" d="M224.5,764h0Z" />',
                    '<path class="cls-jn-4" d="M266.63,555.75l1-.85c0,.14.09.28.13.42Z" />',
                    '<path class="cls-jn-4" d="M266.63,555.75l1.13-.43c0-.14-.09-.28-.13-.42Z" />'
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    "<path",
                    '  class="cls-jn-5"',
                    '  d="M883.84,889.19v-314c-37.08,6-103.37,23-130,69.17a49.82,49.82,0,0,1-38.27,24.29C674.8,672.85,638.1,696,615.43,717.37a50.46,50.46,0,0,1-63.1,4.93c-32.8-22.43-57.74-31-101.53-29.88a50.74,50.74,0,0,1-24.58-5.55c-65.29-33.8-164.29-28.54-211.69,24.6a51.31,51.31,0,0,1-30.34,16.29C115.6,738.67,37.71,789.25-5.4,857.82v31.37Z"',
                    "/>",
                    "</g>"
                )
            );
        } else if (index == 3) {
            background = string(
                abi.encodePacked(
                    '<g id="BGs">',
                    "<rect",
                    '  class="cls-sk-1"',
                    '  x="-7.52"',
                    '  y="-9.72"',
                    '  width="893.36"',
                    '  height="352.18"',
                    '  transform="translate(878.32 332.73) rotate(-180)"',
                    "/>"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    "<polygon",
                    '  class="cls-sk-2"',
                    '  points="-5.04 885.83 885.28 884.74 887.47 324.61 -9.4 243.97 -5.04 885.83"',
                    "/>",
                    "<polygon",
                    '  class="cls-sk-3"',
                    '  points="-8.31 418.33 887.47 494.61 887.47 410.7 -9.4 338.77 -8.31 418.33"',
                    "/>"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    "<polygon",
                    '  class="cls-sk-4"',
                    '  points="-8.31 598.14 887.47 674.42 887.47 590.51 -9.4 518.58 -8.31 598.14"',
                    "/>",
                    "<polygon",
                    '  class="cls-sk-5"',
                    '  points="-8.31 777.95 887.47 854.23 887.47 770.32 -9.4 698.39 -8.31 777.95"',
                    "/>"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    "<polygon",
                    '  class="cls-sk-6"',
                    '  points="257.59 885.83 882.28 -0.68 883.92 131.45 801.7 253.48 795.72 885.83 739.53 884.63 744.9 334.44 538.05 629.29 532 885.83 475.81 884.63 481.26 710.26 353.49 885.83 257.59 885.83"',
                    "/>"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    "<rect",
                    '  class="cls-sk-7"',
                    '  x="-2.86"',
                    '  y="-1.23"',
                    '  width="884.88"',
                    '  height="882.7"',
                    '  transform="translate(879.15 880.24) rotate(-180)"',
                    "/>",
                    "</g>"
                )
            );
        } else {
            background = string(abi.encodePacked());
        }
        return background;
    }

    function GetBackground(uint256 colorIndex)
        public
        pure
        returns (string memory)
    {
        string memory background;

        if (colorIndex == 9) {
            background = string(
                abi.encodePacked(
                    "<defs>",
                    "  <style>",
                    "    .cls-cv-1 {",
                    "      fill: #bfc9d0;",
                    "    }"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    "    .cls-cv-2 {",
                    "      fill: #e5e9ec;",
                    "    }",
                    "    .cls-cv-3 {",
                    "      fill: #99a9b3;",
                    "    }"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    "    .cls-cv-4 {",
                    "      fill: #738997;",
                    "    }",
                    "    .cls-cv-5 {",
                    "      fill: #4c687b;",
                    "    }"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    "    .cls-cv-6 {",
                    "      fill: #26485e;",
                    "    }",
                    "    .cls-cv-7 {",
                    "      fill: #002842;",
                    "    }",
                    "  </style>",
                    "</defs>",
                    GetBackgroundShade(0)
                )
            );
        } else if (colorIndex == 10) {
            background = string(
                abi.encodePacked(
                    "<defs>",
                    "  <style>",
                    "    .cls-cv-1 {",
                    "      fill: #c3c6c7;",
                    "    }",
                    "    .cls-cv-2 {",
                    "      fill: #e7e8e9;",
                    "    }"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    "    .cls-cv-3 {",
                    "      fill: #9fa4a6;",
                    "    }",
                    "    .cls-cv-4 {",
                    "      fill: #7c8284;",
                    "    }"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    "    .cls-cv-5 {",
                    "      fill: #586063;",
                    "    }",
                    "    .cls-cv-6 {",
                    "      fill: #343e41;",
                    "    }"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    "    .cls-cv-7 {",
                    "      fill: #101c20;",
                    "    }",
                    "  </style>",
                    "</defs>",
                    GetBackgroundShade(0)
                )
            );
        } else if (colorIndex == 11) {
            background = string(
                abi.encodePacked(
                    "<defs>",
                    "  <style>",
                    "    .cls-cv-1 {",
                    "      fill: #ccc3cc;",
                    "    }",
                    "    .cls-cv-2 {",
                    "      fill: #ebe7eb;",
                    "    }"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    "    .cls-cv-3 {",
                    "      fill: #ada0ae;",
                    "    }",
                    "    .cls-cv-4 {",
                    "      fill: #8f7c90;",
                    "    }",
                    "    .cls-cv-5 {",
                    "      fill: #705872;",
                    "    }"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    "    .cls-cv-6 {",
                    "      fill: #523553;",
                    "    }",
                    "    .cls-cv-7 {",
                    "      fill: #331135;",
                    "    }",
                    "  </style>",
                    "</defs>",
                    GetBackgroundShade(0)
                )
            );
        } else if (colorIndex == 12) {
            background = string(
                abi.encodePacked(
                    "<defs>",
                    "  <style>",
                    "    .cls-fs-1 {",
                    "      fill: #066666;",
                    "    }",
                    "    .cls-fs-2 {",
                    "      fill: none;",
                    "    }"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    "    .cls-fs-3,",
                    "    .cls-fs-4,",
                    "    .cls-fs-5,",
                    "    .cls-fs-6,",
                    "    .cls-fs-7,",
                    "    .cls-fs-8 {",
                    "      fill: #fff;",
                    "    }",
                    "    .cls-fs-3 {",
                    "      opacity: 0.55;",
                    "    }"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    "    .cls-fs-4 {",
                    "      opacity: 0.5;",
                    "    }",
                    "    .cls-fs-5 {",
                    "      opacity: 0.6;",
                    "    }"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    "    .cls-fs-6 {",
                    "      opacity: 0.75;",
                    "    }",
                    "    .cls-fs-7 {",
                    "      opacity: 0.9;",
                    "    }",
                    "    .cls-fs-8 {",
                    "      opacity: 0.4;",
                    "    }"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    "    .cls-fs-9 {",
                    "      opacity: 0.1;",
                    "    }",
                    "    .cls-fs-10 {",
                    "      fill: #1fccb3;",
                    "    }"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    "    .cls-fs-11 {",
                    "      fill: #33e5c7;",
                    "    }",
                    "  </style>",
                    "</defs>",
                    GetBackgroundShade(1)
                )
            );
        } else if (colorIndex == 14) {
            background = string(
                abi.encodePacked(
                    "<defs>",
                    "  <style>",
                    "    .cls-fs-1 {",
                    "      fill: #066666;",
                    "    }",
                    "    .cls-fs-2 {",
                    "      fill: #a81349;",
                    "    }"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    "    .cls-fs-3 {",
                    "      fill: none;",
                    "    }",
                    "    .cls-fs-4,",
                    "    .cls-fs-5,",
                    "    .cls-fs-6,"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    "    .cls-fs-7,",
                    "    .cls-fs-8,",
                    "    .cls-fs-9 {",
                    "      fill: #fff;",
                    "    }",
                    "    .cls-fs-4 {",
                    "      opacity: 0.55;",
                    "    }"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    "    .cls-fs-5 {",
                    "      opacity: 0.5;",
                    "    }",
                    "    .cls-fs-6 {",
                    "      opacity: 0.6;",
                    "    }",
                    "    .cls-fs-7 {",
                    "      opacity: 0.75;",
                    "    }"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    "    .cls-fs-8 {",
                    "      opacity: 0.9;",
                    "    }",
                    "    .cls-fs-9 {",
                    "      opacity: 0.4;",
                    "    }"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    "    .cls-fs-10 {",
                    "      fill: #f26489;",
                    "    }",
                    "    .cls-fs-11 {",
                    "      fill: #ff99be;",
                    "    }"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    "    .cls-fs-12 {",
                    "      opacity: 0.1;",
                    "    }",
                    "  </style>",
                    "</defs>",
                    GetBackgroundShade(1)
                )
            );
        } else if (colorIndex == 14) {
            background = string(
                abi.encodePacked(
                    "<defs>",
                    "  <style>",
                    "    .cls-fs-1 {",
                    "      fill: #d35500;",
                    "    }",
                    "    .cls-fs-2 {",
                    "      fill: none;",
                    "    }"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    "    .cls-fs-3,",
                    "    .cls-fs-4,",
                    "    .cls-fs-5,",
                    "    .cls-fs-6,",
                    "    .cls-fs-7,",
                    "    .cls-fs-8 {",
                    "      fill: #fff;",
                    "    }"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    "    .cls-fs-3 {",
                    "      opacity: 0.55;",
                    "    }",
                    "    .cls-fs-4 {",
                    "      opacity: 0.5;",
                    "    }",
                    "    .cls-fs-5 {",
                    "      opacity: 0.6;",
                    "    }"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    "    .cls-fs-6 {",
                    "      opacity: 0.75;",
                    "    }",
                    "    .cls-fs-7 {",
                    "      opacity: 0.9;",
                    "    }",
                    "    .cls-fs-8 {",
                    "      opacity: 0.4;",
                    "    }"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    "    .cls-fs-9 {",
                    "      opacity: 0.1;",
                    "    }",
                    "    .cls-fs-10 {",
                    "      fill: #fb913b;",
                    "    }"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    "    .cls-fs-11 {",
                    "      fill: #fbc26e;",
                    "    }",
                    "  </style>",
                    "</defs>",
                    GetBackgroundShade(1)
                )
            );
        } else if (colorIndex == 15) {
            background = string(
                abi.encodePacked(
                    "<defs>",
                    "  <style>",
                    "    .cls-jn-1 {",
                    "      fill: #c5f9d0;",
                    "    }",
                    "    .cls-jn-2 {",
                    "      fill: #1dcc85;",
                    "    }"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    "    .cls-jn-3 {",
                    "      fill: #056849;",
                    "    }",
                    "    .cls-jn-4 {",
                    "      fill: #059ca0;",
                    "    }"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    "    .cls-jn-5 {",
                    "      fill: #1b2b30;",
                    "    }",
                    "  </style>",
                    "</defs>",
                    GetBackgroundShade(2)
                )
            );
        } else if (colorIndex == 16) {
            background = string(
                abi.encodePacked(
                    "<defs>",
                    "  <style>",
                    "    .cls-jn-1 {",
                    "      fill: #ffbf40;",
                    "    }",
                    "    .cls-jn-2 {",
                    "      fill: #ff8948;",
                    "    }"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    "    .cls-jn-3 {",
                    "      fill: #9e1536;",
                    "    }",
                    "    .cls-jn-4 {",
                    "      fill: #059ca0;",
                    "    }"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    "    .cls-jn-5 {",
                    "      fill: #720e2d;",
                    "    }",
                    "  </style>",
                    "</defs>",
                    GetBackgroundShade(2)
                )
            );
        } else if (colorIndex == 17) {
            background = string(
                abi.encodePacked(
                    "<defs>",
                    "  <style>",
                    "    .cls-jn-1 {",
                    "      fill: #ccf8f8;",
                    "    }",
                    "    .cls-jn-2 {",
                    "      fill: #7deded;",
                    "    }"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    "    .cls-jn-3 {",
                    "      fill: #059ca0;",
                    "    }",
                    "    .cls-jn-4,",
                    "    .cls-jn-5 {",
                    "      fill: #056b68;",
                    "    }"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    "  </style>",
                    "</defs>",
                    GetBackgroundShade(2)
                )
            );
        } else if (colorIndex == 18) {
            background = string(
                abi.encodePacked(
                    "<defs>",
                    "  <style>",
                    "    .cls-sk-1 {",
                    "      fill: url(#linear-bg-gradient);",
                    "    }"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    "    .cls-sk-2 {",
                    "      fill: #00d8a4;",
                    "    }",
                    "    .cls-sk-3 {",
                    "      fill: url(#linear-bg-gradient-2);",
                    "    }"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    "    .cls-sk-4 {",
                    "      fill: url(#linear-bg-gradient-3);",
                    "    }",
                    "    .cls-sk-5 {",
                    "      fill: url(#linear-bg-gradient-4);",
                    "    }"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    "    .cls-sk-6 {",
                    "      fill: url(#linear-bg-gradient-5);",
                    "    }",
                    "    .cls-sk-7 {",
                    "      fill: none;",
                    "    }",
                    "  </style>"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    "  <linearGradient",
                    '    id="linear-bg-gradient"',
                    '    x1="448.17"',
                    '    y1="292.63"',
                    '    x2="430.41"',
                    '    y2="18.34"'
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    '    gradientTransform="matrix(1, 0, 0, -1, -0.84, 332.73)"',
                    '    gradientUnits="userSpaceOnUse"',
                    "  >",
                    '    <stop offset="0" stop-color="#ffe136" />',
                    '    <stop offset="0.05" stop-color="#fcd63b" />'
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    '    <stop offset="0.39" stop-color="#e6845c" />',
                    '    <stop offset="0.68" stop-color="#d64875" />',
                    '    <stop offset="0.89" stop-color="#cc2384" />',
                    '    <stop offset="1" stop-color="#c8158a" />',
                    "  </linearGradient>"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    "  <linearGradient",
                    '    id="linear-bg-gradient-2"',
                    '    x1="-8.31"',
                    '    y1="416.69"',
                    '    x2="888.55"',
                    '    y2="416.69"'
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    '    gradientTransform="matrix(-1, 0, 0, 1, 879.15, 0)"',
                    '    gradientUnits="userSpaceOnUse"',
                    "  >",
                    '    <stop offset="0" stop-color="#8186ed" />',
                    '    <stop offset="1" stop-color="#00cadb" />',
                    "  </linearGradient>"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    "  <linearGradient",
                    '    id="linear-bg-gradient-3"',
                    '    x1="-8.31"',
                    '    y1="596.5"',
                    '    x2="888.55"',
                    '    y2="596.5"',
                    '    href="#linear-bg-gradient-2"'
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    "  />",
                    "  <linearGradient",
                    '    id="linear-bg-gradient-4"',
                    '    x1="-8.31"',
                    '    y1="776.31"',
                    '    x2="888.55"',
                    '    y2="776.31"'
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    '    href="#linear-bg-gradient-2"',
                    "  />",
                    "  <linearGradient",
                    '    id="linear-bg-gradient-5"',
                    '    x1="-4.77"'
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    '    y1="442.58"',
                    '    x2="621.57"',
                    '    y2="442.58"',
                    '    gradientTransform="matrix(-1, 0, 0, 1, 879.15, 0)"',
                    '    gradientUnits="userSpaceOnUse"',
                    "  >"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    '    <stop offset="0" stop-color="#ff9" />',
                    '    <stop offset="1" stop-color="#ffe300" />',
                    "  </linearGradient>",
                    "</defs>",
                    GetBackgroundShade(3)
                )
            );
        } else if (colorIndex == 19) {
            background = string(
                abi.encodePacked(
                    "<defs>",
                    "  <style>",
                    "    .cls-sk-1 {",
                    "      fill: url(#linear-bg-gradient);",
                    "    }"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    "    .cls-sk-2 {",
                    "      fill: #fad279;",
                    "    }",
                    "    .cls-sk-3 {",
                    "      fill: url(#linear-bg-gradient-2);",
                    "    }"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    "    .cls-sk-4 {",
                    "      fill: url(#linear-bg-gradient-3);",
                    "    }",
                    "    .cls-sk-5 {",
                    "      fill: url(#linear-bg-gradient-4);",
                    "    }"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    "    .cls-sk-6 {",
                    "      fill: url(#linear-bg-gradient-5);",
                    "    }",
                    "    .cls-sk-7 {",
                    "      fill: none;",
                    "    }"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    "  </style>",
                    "  <linearGradient",
                    '    id="linear-bg-gradient"',
                    '    x1="448.17"',
                    '    y1="292.63"',
                    '    x2="430.41"'
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    '    y2="18.34"',
                    '    gradientTransform="matrix(1, 0, 0, -1, -0.84, 332.73)"',
                    '    gradientUnits="userSpaceOnUse"',
                    "  >",
                    '    <stop offset="0.1" stop-color="#ff56b0" />'
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    '    <stop offset="1" stop-color="#35eded" />',
                    "  </linearGradient>",
                    "  <linearGradient",
                    '    id="linear-bg-gradient-2"',
                    '    x1="-8.31"',
                    '    y1="416.69"'
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    '    x2="888.55"',
                    '    y2="416.69"',
                    '    gradientTransform="matrix(-1, 0, 0, 1, 879.15, 0)"',
                    '    gradientUnits="userSpaceOnUse"',
                    "  >"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    '    <stop offset="0" stop-color="#f7931e" />',
                    '    <stop offset="1" stop-color="#ffbf40" />',
                    "  </linearGradient>",
                    "  <linearGradient",
                    '    id="linear-bg-gradient-3"'
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    '    x1="-8.31"',
                    '    y1="596.5"',
                    '    x2="888.55"',
                    '    y2="596.5"',
                    '    href="#linear-bg-gradient-2"',
                    "  />",
                    "  <linearGradient",
                    '    id="linear-bg-gradient-4"'
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    '    x1="-8.31"',
                    '    y1="776.31"',
                    '    x2="888.55"',
                    '    y2="776.31"',
                    '    href="#linear-bg-gradient-2"',
                    "  />",
                    "  <linearGradient"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    '    id="linear-bg-gradient-5"',
                    '    x1="-4.77"',
                    '    y1="442.58"',
                    '    x2="621.57"',
                    '    y2="442.58"'
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    '    gradientTransform="matrix(-1, 0, 0, 1, 879.15, 0)"',
                    '    gradientUnits="userSpaceOnUse"',
                    "  >"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    '    <stop offset="0" stop-color="#91f43b" />',
                    '    <stop offset="1" stop-color="#34d97b" />',
                    "  </linearGradient>",
                    "</defs>",
                    GetBackgroundShade(3)
                )
            );
        } else if (colorIndex == 20) {
            background = string(
                abi.encodePacked(
                    "<defs>",
                    "  <style>",
                    "    .cls-sk-1 {",
                    "      fill: url(#linear-bg-gradient);",
                    "    }"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    "    .cls-sk-2 {",
                    "      fill: #f0f;",
                    "    }",
                    "    .cls-sk-3 {",
                    "      fill: url(#linear-bg-gradient-2);",
                    "    }"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    "    .cls-sk-4 {",
                    "      fill: url(#linear-bg-gradient-3);",
                    "    }",
                    "    .cls-sk-5 {",
                    "      fill: url(#linear-bg-gradient-4);",
                    "    }",
                    "    .cls-sk-6 {",
                    "      fill: url(#linear-bg-gradient-5);",
                    "    }"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    "    .cls-sk-7 {",
                    "      fill: none;",
                    "    }",
                    "  </style>",
                    "  <linearGradient"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    '    id="linear-bg-gradient"',
                    '    x1="448.17"',
                    '    y1="292.63"',
                    '    x2="430.41"',
                    '    y2="18.34"'
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    '    gradientTransform="matrix(1, 0, 0, -1, -0.84, 332.73)"',
                    '    gradientUnits="userSpaceOnUse"',
                    "  >",
                    '    <stop offset="0" stop-color="#b4ff33" />',
                    '    <stop offset="1" stop-color="#35eded" />',
                    "  </linearGradient>"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    "  <linearGradient",
                    '    id="linear-bg-gradient-2"',
                    '    x1="-8.31"',
                    '    y1="416.69"',
                    '    x2="888.55"',
                    '    y2="416.69"'
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    '    gradientTransform="matrix(-1, 0, 0, 1, 879.15, 0)"',
                    '    gradientUnits="userSpaceOnUse"',
                    "  >",
                    '    <stop offset="0" stop-color="#9651ff" />',
                    '    <stop offset="1" stop-color="#da00ff" />',
                    "  </linearGradient>"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    "  <linearGradient",
                    '    id="linear-bg-gradient-3"',
                    '    x1="-8.31"',
                    '    y1="596.5"',
                    '    x2="888.55"',
                    '    y2="596.5"'
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    '    href="#linear-bg-gradient-2"',
                    "  />",
                    "  <linearGradient",
                    '    id="linear-bg-gradient-4"',
                    '    x1="-8.31"',
                    '    y1="776.31"',
                    '    x2="888.55"'
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    '    y2="776.31"',
                    '    href="#linear-bg-gradient-2"',
                    "  />",
                    "  <linearGradient",
                    '    id="linear-bg-gradient-5"',
                    '    x1="-4.77"',
                    '    y1="442.58"'
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    '    x2="621.57"',
                    '    y2="442.58"',
                    '    gradientTransform="matrix(-1, 0, 0, 1, 879.15, 0)"',
                    '    gradientUnits="userSpaceOnUse"',
                    "  >"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    '    <stop offset="0.18" stop-color="#ff0" />',
                    '    <stop offset="1" stop-color="#fb8525" />',
                    "  </linearGradient>",
                    "</defs>",
                    GetBackgroundShade(3)
                )
            );
        } else {
            background = string(abi.encodePacked('<g id="BGs">', "</g>"));
        }
        return background;
    }
}

pragma solidity ^0.8.0;
//SPDX-License-Identifier: MIT

import "hardhat/console.sol";

// GET LISTED ON OPENSEA: https://testnets.opensea.io/get-listed/step-two

// Defining Library
library Background3Library {
    function GetBackgroundShade(uint256 index)
        public
        pure
        returns (string memory)
    {
        string memory background;

        if (index == 0) {
            background = string(
                abi.encodePacked(
                    '<g id="BGs">',
                    ' <rect class="c3-2" x="-9.4" y="-11.86" width="900.14" height="418.2" />',
                    ' <rect class="c3-3" x="-9.4" y="396.53" width="900.14" height="372.7" />',
                    " <path",
                    '  class="c3-4"',
                    '  d="M-9.4,555.56c52.28-3.14,229.72.6,215,24.53-9.46,15.34-24.58,17.15-26.15,28.83-1.64,12.14,12,10.58,198.61,26.56,54.31,4.65,42.19,25.87,9,46.28-70.95,43.6,198.08,55.38,505.91,33.38l2.18,107.48H-1.77Z"',
                    " />"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    " <path",
                    '  class="c3-5"',
                    '  d="M894,732.41s-271.18,19-474.31-7.31,114.67-73-122.86-86.19-79.29-45.58-116.31-62.09C155.12,565.5-9.4,563.26-9.4,563.26V888.55H894Z"',
                    " />",
                    " <path",
                    '  class="c3-6"',
                    '  d="M-5.92,782.19C-25.52,554.67,32.85,322.05,151,127.4c3-10.87,19.09-8.45,11.25,3.19-44.58,83.86-75.37,174.9-96,267.4C32.28,552,32.55,733.27,78.14,886.19c-.91.19-68.47,2.91-69.74.73C2.07,854-2.9,815.4-5.92,782.19Z"',
                    " />"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    ' <g class="c3-7">',
                    " <path",
                    '  d="M48.27,505.22,9.68,494.6c.58-3,5.26-25.59,7.13-33.85l35.62,12.94C51.54,479.79,48.79,500.81,48.27,505.22Z"',
                    " />",
                    " <path",
                    '  d="M-2,568.43l44.44,9.86q-.76,17.31-.94,34.61L-6,606.29Q-4.37,587.3-2,568.43Z"',
                    " />",
                    " <path",
                    '  d="M46.57,722.33c1.42,12.9,3.23,28,5.22,40.83,2.21.32-64.42,7.25-59.2.34C-10.91,703.78-18.17,719.26,46.57,722.33Z"',
                    " />"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    " <path",
                    '  d="M88.35,312.9l-24.72-6.81c1.13-3,6.54-16.83,8.13-20.77l22.6,8.21C93.1,297.48,89.1,310.39,88.35,312.9Z"',
                    " />",
                    " <path",
                    '  d="M70.88,377.64Q68.45,387.8,66.23,398c0,.15-.07.3-.1.45L35.29,390q3.36-11.4,7-22.72Z"',
                    " />",
                    " <path",
                    '  d="M141.92,171.08q-3.33,7.14-6.52,14.35l-14.87-5.32q4-7.55,8.15-15Z"',
                    " />"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    " <path",
                    '  d="M118.33,226.28c-1.91,4.84-3.76,9.69-5.6,14.56l-18.88-6.76c2.4-5.2,4.82-10.39,7.3-15.55Z"',
                    " />",
                    " </g>",
                    " <path",
                    ' class="c3-8"',
                    ' d="M-.34,169.22c50.82-38.66,116.24-48,147-48.88-26.11-10.46-85.77-27.57-157.15-2v59.76A96.54,96.54,0,0,1-.34,169.22Z"',
                    " />",
                    " <path",
                    ' class="c3-8"',
                    ' d="M-10.49-2.31c34-10.89,80.9-17,124.27,7.88C150,26.36,158.5,70.29,160,98.76c1.85-44.43-3.64-81.7-11.18-110.89H-10.49Z"',
                    " />"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    " <path",
                    ' class="c3-8"',
                    ' d="M7.79,59.36c69.3-16.85,120.52,29.4,141.41,53C133.63,83.92,82.09,28.69-10.49,19.92V65A157.41,157.41,0,0,1,7.79,59.36Z"',
                    " />",
                    " <path",
                    ' class="c3-9"',
                    ' d="M321.27,131.59C263.46,93.69,200.42,107,172.76,116.67c73.5-50.37,229.48-2.35,229.48-2.35s-41.08-80.92-121.87-78c-56.06,2-90.15,38.37-107.41,64.22,12.48-26.85,27.55-70.77,14.7-112.69H148.81c7.54,29.19,13,66.46,11.18,110.89-1.49-28.47-10-72.4-46.21-93.19C70.41-19.34,23.48-13.2-10.49-2.31V19.92c92.58,8.77,144.12,64,159.69,92.44-20.89-23.6-72.11-69.85-141.41-53A157.41,157.41,0,0,0-10.49,65v53.42c71.38-25.62,131-8.51,157.15,2-30.76.83-96.18,10.22-147,48.88a96.54,96.54,0,0,0-10.15,8.93V286.64C41.29,197.58,129.07,143.13,155.88,128c2.47,11.17,15.73,77.51,24.92,248.79,102-159,29.38-224.74-10.62-247.34C320.25,166.92,338.4,322.69,338.4,322.69S394.26,179.44,321.27,131.59Z"',
                    " />"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    " <path",
                    ' class="c3-10"',
                    ' d="M735,737.38s28.2-15.23,38.49-15.82-2,22.31-2,23.3,40.33,7.48,41.73,12.58c1,3.68-16.6,6.54-45.67,10.48,0,0-1,26.41-10.14,28.5s-22.62-23.89-25.79-25c-4.44-1.58-41.12,12.08-50.8,9.32s24.22-23.75,27.24-25.92-19.78-21.68-15.13-24.7C697.22,727.32,726.25,733.83,735,737.38Z"',
                    " />",
                    " <circle",
                    ' class="c3-11"',
                    ' cx="688.04"',
                    ' cy="184.03"',
                    ' r="104.62"',
                    ' transform="translate(71.39 540.42) rotate(-45)"',
                    " />"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    " <polygon",
                    ' class="c3-12"',
                    ' points="81.43 729.41 184.14 752.04 336.65 774.76 335.28 762.81 81.43 729.41"',
                    " />",
                    " <ellipse",
                    ' class="c3-13"',
                    ' cx="213.79"',
                    ' cy="765.45"',
                    ' rx="30.95"',
                    ' ry="121.45"',
                    ' transform="matrix(0.08, -1, 1, 0.08, -566.72, 915.17)"',
                    " />"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    " <path",
                    ' class="c3-14"',
                    ' d="M307.53,852.88c3.6-.51,17.87-6,21.42-7.71l9.64-74.83-94.34-12.15-10.41,80.86a170,170,0,0,1,22,5.15Z"',
                    " />",
                    " <path",
                    ' class="c3-15"',
                    ' d="M214.62,838.44a165.92,165.92,0,0,1,19.22.61l10.41-80.86L79,736.9q-2.39,18.51-4.76,37c6.08,3.87,11.93,8.16,17.66,12.65C161.74,837.25,204.19,836.66,214.62,838.44Z"',
                    " />",
                    " <path",
                    ' class="c3-16"',
                    ' d="M95.65,757.63l-3.72,28.94c10.65,8.34,20.92,17.35,31.63,25.63,19.35,14.95,41.5,27.94,65.44,28.29,8.57.13,17.08-1.37,25.62-2q4.15-32.21,8.3-64.41Z"',
                    " />"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    " <path",
                    ' class="c3-16"',
                    ' d="M307.53,852.88c1-3.84,8.52-66.15,8.52-66.15L264.14,780,256,844A114,114,0,0,0,307.53,852.88Zm-51.66-8.68"',
                    " />",
                    " <polygon",
                    ' class="c3-17"',
                    ' points="261.37 801.49 261.38 801.49 261.38 801.49 261.37 801.49"',
                    " />",
                    ' <path class="c3-18" d="M245.55,750.7c26.51-89,110.13-60.05,93,19.91Z" />'
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    ' <path class="c3-16" d="M272.94,738.14c11-34.27,52.4-21.15,45.78,9.8Z" />',
                    " <path",
                    ' class="c3-19"',
                    ' d="M314.11,699.53c-11.1-6.44-49.45-8.83-67.46,51.17L81.43,729.41c10.57-50.41,37.41-61.17,66-54.79C315.61,694.58,314.73,699.43,314.11,699.53Z"',
                    " />",
                    " <path",
                    ' class="c3-16"',
                    ' d="M146,674.24c45.14,6.12,68.51,8.77,125.25,16.47-20.52,7.13-35,28.55-40.83,39.73l-125-16.1C115.07,688.08,130.69,676.17,146,674.24Z"',
                    " />",
                    "</g>"
                )
            );
        } else if (index == 1) {
            background = string(
                abi.encodePacked(
                    '<g id="BGs">',
                    ' <rect class="c3-2" x="-5.31" y="-3.47" width="891.19" height="676.5" />',
                    ' <rect class="c3-3" x="-4.14" y="699.53" width="888.61" height="184.63" />',
                    ' <g class="c3-4">',
                    " <path",
                    '  class="c3-5"',
                    '  d="M599.92,694.89c-9.81,1.71-21.71,5.4-23.42,15.21-.85,4.82,1.23,9.89-.1,14.59-1.94,6.81-9.74,9.67-16.31,12.28s-13.92,7.77-12.91,14.77c.86,6,7.3,9.19,13,11.23,22.63,8.17,26.49,25.67,50.53,24.78,29.42-1.09,38-17.4,42-21.75,22.89-24.54,69.41-9,92.76-33.07,2.94-3,5.4-6.74,6-10.92,1.08-7.1-3.44-14.13-9.47-18C733.17,698.26,611.52,692.87,599.92,694.89Z"',
                    " />",
                    " </g>"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    " <path",
                    ' class="c3-6"',
                    ' d="M81.56,93.73c-50.44,23-70.93,80.1-81.82,130.75-44.81,167,146,212,256.67,125.81C343.45,290,391,141.53,308.05,60.36c-56.27-55-268,2.71-274.67,22.85-8.44,25.65,94.71-11.79,106.88-16.33-1,.36,107.52-30.51,158.64,16.51,26.8,21.09,28,94.62,28.1,93.59,3.6,20.13-20.91,122.16-109.46,170.31s-161.28,4.48-160.46,5c-6.24-4.14-46.87-44.05-39.47-88.69,4.05-91,51.72-134.64,51-134,6.05-5.45,18.2-12.94,17.31-12.48C103.21,111.74,98.39,88.6,81.56,93.73Z"',
                    " />",
                    " <path",
                    ' class="c3-6"',
                    ' d="M15.87,205.39c46.31,5.19,52,5.68,102.23,7,24.61.64,34-18.7-14-22.52-1.08-.08-59.86-6.23-88.63-5.81Z"',
                    " />"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    " <path",
                    ' class="c3-6"',
                    ' d="M105.5,130.17C60.34,278.29,93.58,281,97.39,254.32c5.71-40,21.8-94.45,21.49-93.5,2.07-9.82,9.92-19.32,7.89-29.48C123.79,122,109.43,121.07,105.5,130.17Z"',
                    " />",
                    " <path",
                    ' class="c3-6"',
                    ' d="M158.45,137.5c50.18-.13,148.41,4.08,147.38,4,10.32-.58,22,4.2,31.53-.39,8.28-5.25,5.47-19.47-4.33-20.85q-88-6-176.32-5.83C141.88,115.4,143.4,138.65,158.45,137.5Z"',
                    " />"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    " <path",
                    ' class="c3-6"',
                    ' d="M284.55,38.52q-26.18,58.8-48.89,119c-3.54,14.56-28.37,55.21,1.72,50.14,12.85-2.16,32.61-85.83,53.41-125.65,4.08-14.08,16.28-27.58,15-42.37C302.78,30.31,288.6,29.43,284.55,38.52Z"',
                    " />",
                    " <path",
                    ' class="c3-6"',
                    ' d="M60.34,397.62c78.47-69.2,235.39-163.42,234.5-163a619.69,619.69,0,0,1,77.29-33.6c39.11-13.76,11.87-44.27-77.09,7.8C7.26,377.3,28.74,417.78,60.34,397.62Z"',
                    " />",
                    ' <path class="c3-7" d="M136.68,386.78A560.38,560.38,0,0,0,135,458.69" />',
                    ' <path class="c3-7" d="M156.45,378.51,154,429.22" />',
                    ' <path class="c3-7" d="M106.38,378.47c-2.79,9-3.68,33-2.81,42.4" />',
                    ' <path class="c3-7" d="M277.2,313.07a727.26,727.26,0,0,0-2.45,81.79" />'
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    ' <path class="c3-7" d="M262.28,327.89,260.13,372" />',
                    ' <g class="c3-4">',
                    " <path",
                    '  class="c3-5"',
                    '  d="M764.32,267.94c8.25-214.49-255.37-164.8-199.4,43.59,7.61,28.33-2.72,89.36,10.88,89.36,25.06,0,18.52-58.85,26.56-54.43,38,20.91-5.88,248.3,10.42,282.55,6.48,47.79,44.75,11.63,42.56-25.43C651.53,539,644.14,369.24,674.25,312c44.48-57.48,14.58,81.17,34.44,87.64,24,7.82,7.69-60.25,21.75-48.48C760.24,376.1,762.14,324.61,764.32,267.94Z"',
                    " />",
                    " </g>",
                    ' <rect class="c3-8" x="-5.04" y="644.2" width="891.42" height="57.31" />',
                    ' <rect class="c3-9" x="-5.04" y="642.82" width="891.42" height="9.66" />'
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    ' <g class="c3-4">',
                    " <path",
                    '  class="c3-5"',
                    '  d="M663.25,652.62c-3-3.27-5.06-7-8.72-9.8H615.35c-.37,2.91-4.91,9.81-4.91,9.81a11.13,11.13,0,0,0,2.13,14.46,13.46,13.46,0,0,0,15.72.63c1.4-1,2.81-2.34,4.56-2.2a4.5,4.5,0,0,1,3.1,2.06c2.39,3.26,3.58,26.15,3.87,34.08,4.16-.37,11,0,15.19-.13,1,0,2-23.71,7.86-33.59C665.42,663.63,663.25,652.62,663.25,652.62Z"',
                    " />",
                    " </g>",
                    " <polyline",
                    ' class="c3-10"',
                    ' points="568.17 -24.11 560.54 94.67 722.91 221.08 831.89 249.41"',
                    " />"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    ' <line class="c3-10" x1="639" y1="157.88" x2="652.08" y2="298.45" />',
                    ' <g class="c3-11">',
                    " <ellipse",
                    '  class="c3-12"',
                    '  cx="747.69"',
                    '  cy="769.66"',
                    '  rx="12.64"',
                    '  ry="77.01"',
                    '  transform="translate(-29.98 1509.02) rotate(-89.38)"',
                    " />",
                    " </g>"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    " <path",
                    ' class="c3-13"',
                    ' d="M815.51,725.32c-1.53-6.06-6.63-8.29-10.94-9.32s-45.15-5-45.15-5a11.6,11.6,0,0,1,1.4,1.46h0c1.49,1.84,3.21,5.16.41,8.69C755.79,728,697.72,764.54,717.1,766S796,774.58,802,774.14s8.82-4.73,10.31-11.57S817.05,731.39,815.51,725.32Z"',
                    " />",
                    " <path",
                    ' class="c3-14"',
                    ' d="M761.24,721.13c-4.27,5.24-26,5-31.73,5.14-.24,4.63-16,27.16-41.81,21.34-4.91-1.1-4,7.54-4,7.54s11.1,6.74,32.47,10.75c5.36.12,24.7-.23,32.8-2.26s-.68-25.33-.68-25.33,25.32-2,22.33-20.19c-.33-2-4.81-3.58-9.05-4.68A6.15,6.15,0,0,1,761.24,721.13Z"',
                    " />",
                    ' <g class="c3-11">',
                    ' <ellipse class="c3-15" cx="501.24" cy="801.36" rx="85.6" ry="16" />',
                    " </g>"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    " <path",
                    ' class="c3-14"',
                    ' d="M541.11,782.67c-11.1-6.87-4.3-28.78-4.3-28.78s-24.4,4.26-35.84-7c0,0,18.3,37.23,27.3,40.23C535.2,788.66,540.36,786.25,541.11,782.67Z"',
                    " />",
                    " <path",
                    ' class="c3-13"',
                    ' d="M556.49,794c-6.17-5.61-8.62-6.56-11.89-15,0,0-12.59,7.12-13.7,6.84-4.77-3.52-5.56-15.34-4.69-18.82,0,0-20.52-1.64-20.13-25.32-4.21-1.2-23.64,4.25-23.55,23.23L445.82,771s-9.82-1.87-12.24,5.46c-3.32,13.54,6.62,30.73,17.63,20l42.13-6.21C505.55,808.34,545.88,802.2,556.49,794Z"',
                    " />"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    " <path",
                    ' class="c3-14"',
                    ' d="M544.73,809.32s-10.86,1.11-16.47,1.17-11.69-.28-11.69-.28a16.46,16.46,0,0,0,9.61,7.41c6.85,2,8.5,3.94,11.88,2.14S544.73,809.32,544.73,809.32Z"',
                    " />",
                    " <path",
                    ' class="c3-14"',
                    ' d="M506.48,814.61a20,20,0,0,0-3.74-1.52,10.41,10.41,0,0,0-5.76.32c-1.34.64-2.36,1.56-.93,2.12s4.2,2,6.92,2.12a14.92,14.92,0,0,0,4.2-.32Z"',
                    " />"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    " <path",
                    ' class="c3-16"',
                    ' d="M443.22,785.48c-3.8-12.14-6.32-10.14-6-10-1.62,1.27-2.19,6.7-.46,12.43,1.57,5.22,4.6,8.88,6.59,9.7C443.16,797.71,447,797.61,443.22,785.48Z"',
                    " />",
                    ' <g class="c3-4">',
                    " <path",
                    '  class="c3-5"',
                    '  d="M196.21,883.65c5.27-2.92,9.14-6.8,10.27-12,1.37-6.29-2-12.91.16-19,3.15-8.88,15.84-12.62,26.53-16s22.64-10.13,21-19.26c-1.41-7.77-11.87-12-21.08-14.65C196.28,792,190,769.2,150.89,770.36c-47.86,1.42-61.74,22.69-68.35,28.37C61.2,817.08,27.23,818.24-5,821.81v61.84Z"',
                    " />",
                    " </g>",
                    ' <ellipse class="c3-17" cx="269.4" cy="861.6" rx="34.7" ry="15.51" />',
                    "</g>"
                )
            );
        } else {
            background = string(abi.encodePacked());
        }
        return background;
    }

    function GetBackground(uint256 colorIndex)
        public
        pure
        returns (string memory)
    {
        string memory background;

        if (colorIndex == 21) {
            background = string(
                abi.encodePacked(
                    "<defs>",
                    " <style>",
                    " .c3-1 {",
                    "  isolation: isolate;",
                    " }",
                    " .c3-2 {",
                    "  fill: url(#linear-gradient);",
                    " }"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    " .c3-3 {",
                    "  fill: url(#linear-gradient-2);",
                    " }",
                    " .c3-17,",
                    " .c3-4 {",
                    "  fill: #fff;",
                    " }",
                    " .c3-5 {",
                    "  fill: url(#linear-gradient-3);",
                    " }"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    " .c3-6 {",
                    "  fill: #f9cc3d;",
                    " }",
                    " .c3-7 {",
                    "  mix-blend-mode: soft-light;",
                    "  opacity: 0.6;",
                    " }",
                    " .c3-8 {",
                    "  fill: none;",
                    " }"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    " .c3-9 {",
                    "  fill: url(#linear-gradient-4);",
                    " }",
                    " .c3-10 {",
                    "  fill: url(#linear-gradient-5);",
                    " }",
                    " .c3-11 {",
                    "  fill: #fff9c4;",
                    " }"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    " .c3-12 {",
                    "  fill: #72381e;",
                    " }",
                    " .c3-13 {",
                    "  fill: #fff35c;",
                    " }",
                    " .c3-14 {",
                    "  fill: url(#linear-gradient-6);",
                    " }"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    " .c3-15 {",
                    "  fill: url(#linear-gradient-7);",
                    " }",
                    " .c3-16 {",
                    "  fill: #9f5731;",
                    " }",
                    " .c3-17 {",
                    "  fill-opacity: 0.1;",
                    " }"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    " .c3-18 {",
                    "  fill: url(#linear-gradient-8);",
                    " }",
                    " .c3-19 {",
                    "  fill: url(#linear-gradient-9);",
                    " }",
                    " </style>"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    " <linearGradient",
                    ' id="linear-gradient"',
                    ' x1="440.67"',
                    ' y1="157.24"',
                    ' x2="440.67"',
                    ' y2="5.3"',
                    ' gradientUnits="userSpaceOnUse"',
                    " >",
                    ' <stop offset="0" stop-color="#dcfbff" />',
                    ' <stop offset="1" stop-color="#7fe0ff" />',
                    " </linearGradient>"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    " <linearGradient",
                    ' id="linear-gradient-2"',
                    ' x1="440.67"',
                    ' y1="588.1"',
                    ' x2="440.67"',
                    ' y2="337.51"',
                    ' gradientUnits="userSpaceOnUse"',
                    " >",
                    ' <stop offset="0" stop-color="#71c7c0" />',
                    ' <stop offset="1" stop-color="#2dadce" />',
                    " </linearGradient>"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    " <linearGradient",
                    ' id="linear-gradient-3"',
                    ' x1="405.61"',
                    ' y1="670.81"',
                    ' x2="675.67"',
                    ' y2="1297.29"',
                    ' gradientTransform="matrix(-1, 0, 0, 1, 871.66, 0)"',
                    ' gradientUnits="userSpaceOnUse"',
                    " >",
                    ' <stop offset="0" stop-color="#ffe9cf" />',
                    ' <stop offset="1" stop-color="#edb18f" />',
                    " </linearGradient>"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    " <linearGradient",
                    ' id="linear-gradient-4"',
                    ' x1="325.25"',
                    ' y1="39.05"',
                    ' x2="74.61"',
                    ' y2="204.69"',
                    ' gradientTransform="translate(27.66 -6.07) rotate(3.83)"',
                    ' gradientUnits="userSpaceOnUse"',
                    " >",
                    ' <stop offset="0" stop-color="#8cc63f" />',
                    ' <stop offset="1" stop-color="#009245" />',
                    " </linearGradient>"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    " <linearGradient",
                    ' id="linear-gradient-5"',
                    ' x1="744.3"',
                    ' y1="727.05"',
                    ' x2="747.89"',
                    ' y2="805.97"',
                    ' gradientUnits="userSpaceOnUse"',
                    " >",
                    ' <stop offset="0" stop-color="#f2843d" />',
                    ' <stop offset="1" stop-color="#e95e2e" />',
                    " </linearGradient>"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    " <linearGradient",
                    ' id="linear-gradient-6"',
                    ' x1="218.1"',
                    ' y1="798.75"',
                    ' x2="318.86"',
                    ' y2="798.75"',
                    ' gradientTransform="translate(83.58 -11.93) rotate(4.75)"',
                    ' gradientUnits="userSpaceOnUse"',
                    " >",
                    ' <stop offset="0" stop-color="#ffbf40" />',
                    ' <stop offset="1" stop-color="#ffa05b" />',
                    " </linearGradient>"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    " <linearGradient",
                    ' id="linear-gradient-7"',
                    ' x1="52.18"',
                    ' y1="791.63"',
                    ' x2="223.84"',
                    ' y2="791.63"',
                    ' href="#linear-gradient-6"',
                    " />"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    " <linearGradient",
                    ' id="linear-gradient-8"',
                    ' x1="224.51"',
                    ' y1="723.18"',
                    ' x2="319.73"',
                    ' y2="723.18"',
                    ' href="#linear-gradient-6"',
                    " />"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    " <linearGradient",
                    ' id="linear-gradient-9"',
                    ' x1="59.2"',
                    ' y1="712.38"',
                    ' x2="288.67"',
                    ' y2="712.38"',
                    ' href="#linear-gradient-6"',
                    " />",
                    "</defs>"
                )
            );
            background = string(
                abi.encodePacked(background, GetBackgroundShade(0))
            );
        } else if (colorIndex == 22) {
            background = string(
                abi.encodePacked(
                    "<defs>",
                    " <style>",
                    " .c3-1 {",
                    "  isolation: isolate;",
                    " }",
                    " .c3-2 {",
                    "  fill: url(#linear-gradient);",
                    " }"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    " .c3-3 {",
                    "  fill: #ffdb6e;",
                    " }",
                    " .c3-4 {",
                    "  fill: url(#linear-gradient-2);",
                    " }",
                    " .c3-5 {",
                    "  fill: #ffe49f;",
                    " }"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    " .c3-6 {",
                    "  fill: url(#linear-gradient-3);",
                    " }",
                    " .c3-7 {",
                    "  fill: url(#linear-gradient-4);",
                    " }",
                    " .c3-8 {",
                    "  mix-blend-mode: soft-light;",
                    "  opacity: 0.6;",
                    " }"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    " .c3-9 {",
                    "  fill: url(#linear-gradient-5);",
                    " }",
                    " .c3-10 {",
                    "  fill: url(#linear-gradient-6);",
                    " }",
                    " .c3-11 {",
                    "  fill: #72381e;",
                    " }"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    " .c3-12 {",
                    "  fill: #fff35c;",
                    " }",
                    " .c3-13 {",
                    "  fill: url(#linear-gradient-7);",
                    " }",
                    " .c3-14 {",
                    "  fill: url(#linear-gradient-8);",
                    " }"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    " .c3-15 {",
                    "  fill: #5e5731;",
                    " }",
                    " .c3-16 {",
                    "  fill: #9f5731;",
                    " }",
                    " .c3-17 {",
                    "  fill: #fff;",
                    "  fill-opacity: 0.1;",
                    " }"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    " .c3-18 {",
                    "  fill: url(#linear-gradient-9);",
                    " }",
                    " .c3-19 {",
                    "  fill: url(#linear-gradient-10);",
                    " }",
                    " </style>"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    " <linearGradient",
                    ' id="linear-gradient"',
                    ' x1="440.03"',
                    ' y1="605.76"',
                    ' x2="440.03"',
                    ' y2="-9.42"',
                    ' gradientUnits="userSpaceOnUse"',
                    " >",
                    ' <stop offset="0" stop-color="#fff4b5" />',
                    ' <stop offset="0.3" stop-color="#ffdb6e" />',
                    ' <stop offset="0.5" stop-color="#ff73a9" />',
                    ' <stop offset="1" stop-color="#4261bd" />',
                    " </linearGradient>"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    " <linearGradient",
                    ' id="linear-gradient-2"',
                    ' x1="441.78"',
                    ' y1="798.65"',
                    ' x2="441.78"',
                    ' y2="396.53"',
                    ' gradientUnits="userSpaceOnUse"',
                    " >",
                    ' <stop offset="0" stop-color="#db4b87" />',
                    ' <stop offset="0.6" stop-color="#4a53c9" />',
                    ' <stop offset="1" stop-color="#f7675f" />',
                    " </linearGradient>"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    " <linearGradient",
                    ' id="linear-gradient-3"',
                    ' x1="451.63"',
                    ' y1="696.63"',
                    ' x2="358.45"',
                    ' y2="989.23"',
                    ' gradientUnits="userSpaceOnUse"',
                    " >",
                    ' <stop offset="0" stop-color="#ff6990" />',
                    ' <stop offset="0.95" stop-color="#7c1860" />',
                    " </linearGradient>"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    " <linearGradient",
                    ' id="linear-gradient-4"',
                    ' x1="-9.65"',
                    ' y1="504.09"',
                    ' x2="164.34"',
                    ' y2="504.09"',
                    ' gradientUnits="userSpaceOnUse"',
                    " >",
                    ' <stop offset="0" stop-color="#9c005d" />',
                    ' <stop offset="0.43" stop-color="#ff73a9" />',
                    ' <stop offset="1" stop-color="#ffc36e" />',
                    " </linearGradient>"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    " <linearGradient",
                    ' id="linear-gradient-5"',
                    ' x1="361.61"',
                    ' y1="203.13"',
                    ' x2="-14.35"',
                    ' y2="159"',
                    ' gradientUnits="userSpaceOnUse"',
                    " >",
                    ' <stop offset="0" stop-color="#059ca0" />',
                    ' <stop offset="1" stop-color="#472a4a" />',
                    " </linearGradient>"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    " <linearGradient",
                    ' id="linear-gradient-6"',
                    ' x1="720.64"',
                    ' y1="726.16"',
                    ' x2="763.14"',
                    ' y2="796.45"',
                    ' gradientUnits="userSpaceOnUse"',
                    " >",
                    ' <stop offset="0" stop-color="#e95e2e" />',
                    ' <stop offset="1" stop-color="#811c5d" />',
                    " </linearGradient>"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    " <linearGradient",
                    ' id="linear-gradient-7"',
                    ' x1="299.79"',
                    ' y1="795.37"',
                    ' x2="400.55"',
                    ' y2="795.37"',
                    ' gradientTransform="translate(1.89 -15.32) rotate(4.75)"',
                    ' gradientUnits="userSpaceOnUse"',
                    " >",
                    ' <stop offset="0" stop-color="#ffbf40" />',
                    ' <stop offset="1" stop-color="#ffa05b" />',
                    " </linearGradient>"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    " <linearGradient",
                    ' id="linear-gradient-8"',
                    ' x1="133.87"',
                    ' y1="788.24"',
                    ' x2="305.53"',
                    ' y2="788.24"',
                    ' gradientTransform="translate(1.89 -15.32) rotate(4.75)"',
                    ' gradientUnits="userSpaceOnUse"',
                    " >",
                    ' <stop offset="0" stop-color="#ffa05b" />',
                    ' <stop offset="1" stop-color="#5b8994" />',
                    " </linearGradient>"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    " <linearGradient",
                    ' id="linear-gradient-9"',
                    ' x1="306.2"',
                    ' y1="719.79"',
                    ' x2="401.42"',
                    ' y2="719.79"',
                    ' href="#linear-gradient-7"',
                    " />"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    " <linearGradient",
                    ' id="linear-gradient-10"',
                    ' x1="140.88"',
                    ' y1="709"',
                    ' x2="370.36"',
                    ' y2="709"',
                    ' href="#linear-gradient-8"',
                    " />",
                    "</defs>"
                )
            );
            background = string(
                abi.encodePacked(background, GetBackgroundShade(0))
            );
        } else if (colorIndex == 23) {
            background = string(
                abi.encodePacked(
                    "<defs>",
                    " <style>",
                    " .c3-1 {",
                    "  isolation: isolate;",
                    " }",
                    " .c3-2 {",
                    "  fill: #ffbdc0;",
                    " }",
                    " .c3-3 {",
                    "  fill: #056b68;",
                    " }"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    " .c3-10,",
                    " .c3-11,",
                    " .c3-17,",
                    " .c3-4 {",
                    "  mix-blend-mode: multiply;",
                    " }",
                    " .c3-17,",
                    " .c3-4 {",
                    "  opacity: 0.49;",
                    " }"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    " .c3-17,",
                    " .c3-5 {",
                    "  fill: #a56734;",
                    " }",
                    " .c3-6 {",
                    "  fill: #8cc63f;",
                    " }",
                    " .c3-10,",
                    " .c3-7 {",
                    "  fill: none;",
                    "  stroke-miterlimit: 10;",
                    " }"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    " .c3-7 {",
                    "  stroke: #8cc63f;",
                    "  stroke-width: 5px;",
                    " }",
                    " .c3-8 {",
                    "  fill: #fff2d4;",
                    " }",
                    " .c3-9 {",
                    "  fill: #efd7a5;",
                    " }"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    " .c3-10 {",
                    "  stroke: #ddacb0;",
                    "  stroke-width: 4px;",
                    " }",
                    " .c3-12 {",
                    "  fill: #e6e6e8;",
                    " }",
                    " .c3-13 {",
                    "  fill: #78371e;",
                    " }"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    " .c3-14 {",
                    "  fill: #a04b30;",
                    " }",
                    " .c3-15 {",
                    "  fill: #e6e6e6;",
                    " }",
                    " .c3-16 {",
                    "  fill: #592515;",
                    " }",
                    " </style>",
                    "</defs>"
                )
            );
            background = string(
                abi.encodePacked(background, GetBackgroundShade(1))
            );
        } else if (colorIndex == 24) {
            background = string(
                abi.encodePacked(
                    "<defs>",
                    " <style>",
                    " .c3-1 {",
                    "  isolation: isolate;",
                    " }",
                    " .c3-2 {",
                    "  fill: #9ae4da;",
                    " }"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    " .c3-3 {",
                    "  fill: #740b00;",
                    " }",
                    " .c3-10,",
                    " .c3-11,",
                    " .c3-17,",
                    " .c3-4 {",
                    "  mix-blend-mode: multiply;",
                    " }"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    " .c3-17,",
                    " .c3-4 {",
                    "  opacity: 0.49;",
                    " }",
                    " .c3-17,",
                    " .c3-5 {",
                    "  fill: #871f4e;",
                    " }",
                    " .c3-6 {",
                    "  fill: #93278f;",
                    " }"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    " .c3-10,",
                    " .c3-7 {",
                    "  fill: none;",
                    "  stroke-miterlimit: 10;",
                    " }",
                    " .c3-7 {",
                    "  stroke: #93278f;",
                    "  stroke-width: 5px;",
                    " }"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    " .c3-8 {",
                    "  fill: #fff2d4;",
                    " }",
                    " .c3-9 {",
                    "  fill: #efd7a5;",
                    " }",
                    " .c3-10 {",
                    "  stroke: #98c7e5;",
                    "  stroke-width: 4px;",
                    " }"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    " .c3-12 {",
                    "  fill: #e6e6e8;",
                    " }",
                    " .c3-13 {",
                    "  fill: #117f20;",
                    " }",
                    " .c3-14 {",
                    "  fill: #48ba13;",
                    " }"
                )
            );
            background = string(
                abi.encodePacked(
                    background,
                    " .c3-15 {",
                    "  fill: #e6e6e6;",
                    " }",
                    " .c3-16 {",
                    "  fill: #0b4f0f;",
                    " }",
                    " </style>",
                    "</defs>"
                )
            );
            background = string(
                abi.encodePacked(background, GetBackgroundShade(1))
            );
        } else {
            background = string(abi.encodePacked());
        }
        return background;
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