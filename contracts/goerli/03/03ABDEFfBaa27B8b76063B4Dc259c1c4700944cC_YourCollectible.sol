pragma solidity ^0.8.0;
//SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "base64-sol/base64.sol";

import "./RDHStrings.sol";
import "./SVGenStyle.sol";
import "./SVGenBody.sol";
import "./SVGenEye.sol";
import "./SVGenMouth.sol";
import "./SVGenLeaf.sol";

contract YourCollectible is ERC721Enumerable, Ownable {
    using RDHStrings for uint160;
    using RDHStrings for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;

    constructor() ERC721("Radish Planet", "RDH") {}

    mapping(uint256 => uint256) public birth;
    mapping(uint256 => uint256) public genes;
    uint256 public limit = 99999;
    uint256 public price = 0.001 ether;

    // half funds go to buidlguidl.eth
    address payable public constant buidlguidl =
        payable(0xa81a6a910FeD20374361B35C451a4a44F86CeD46);

    function mintItem() public payable returns (uint256) {
        // At most 99999 Radish NFTs
        require(_tokenIds.current() <= limit, "LIMIT");
        require(msg.value >= price, "0.001 Ether");

        _tokenIds.increment();

        uint256 id = _tokenIds.current();
        _mint(msg.sender, id);

        bytes32 predictableRandom = keccak256(
            abi.encodePacked(
                blockhash(block.number - 1),
                msg.sender,
                address(this),
                block.chainid,
                id
            )
        );

        genes[id] = uint256(predictableRandom);
        birth[id] = block.timestamp;

        // half to owner
        (bool success0, ) = payable(owner()).call{value: (msg.value / 2)}("");
        require(success0, "!PAY0");

        // half to buidlguidl
        (bool success1, ) = buidlguidl.call{
            value: (msg.value - (msg.value / 2))
        }("");
        require(success1, "!PAY1");

        return id;
    }

    function updateLimit(uint256 _limit) public onlyOwner {
        require(_limit > limit, "!IL");
        limit = _limit;
    }

    function updatePrice(uint256 _price) public onlyOwner {
        price = _price;
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        require(_exists(id), "!EXIST");

        bytes memory name = abi.encodePacked("Radish #", id.toString());
        bytes memory description = abi.encodePacked(
            "I am Radish #",
            id.toString(),
            ", all is well!"
        );
        uint256 gene = genes[id];
        string memory image = Base64.encode(
            abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" width="400" height="400" version="1.1">',
                SVGenStyle.style(gene, block.timestamp - birth[id]),
                '<rect class="background" x="1" y="1" rx="3" ry="3" width="398" height="398" />',
                SVGenLeaf.leafs(gene),
                SVGenBody.body(gene),
                SVGenEye.eyes(gene),
                SVGenMouth.mouth(gene),
                "</svg>"
            )
        );

        uint256 body = uint256(gene) % uint256(5);
        bool differentEyes = (uint256(uint8(gene >> 32)) % uint256(1000)) ==
            uint256(0);
        uint256 leftEye = uint256(uint8(gene >> 40)) % uint256(44);
        uint256 rightEye = differentEyes
            ? uint256(uint8(gene >> 64)) % uint256(44)
            : leftEye;
        uint256 mouth = uint256(uint8(gene >> 72)) % uint256(14);
        uint256 leafsCount = uint256(1) +
            (uint256(uint8(gene >> 104)) % uint256(5));
        bool hasColorChangingLeaf = uint256(uint8(gene >> 124)) %
            uint256(1000) ==
            0;

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
                                '","attributes":[{"trait_type":"body","value":"B-',
                                body.toString(),
                                '"},{"trait_type":"left eye","value":"E-',
                                leftEye.toString(),
                                '"},{"trait_type":"right eye","value":"E-',
                                rightEye.toString(),
                                '"},{"trait_type":"different eyes","value":"',
                                differentEyes ? "YES(1/1000)" : "NO",
                                '"},{"trait_type":"mouth","value":"M-',
                                mouth.toString(),
                                '"},{"trait_type":"leafs","value":"',
                                leafsCount.toString(),
                                '"},{"trait_type":"color-changing leaf","value":"',
                                hasColorChangingLeaf ? "HAS(1/1000)" : "NONE",
                                '"}],"owner":"',
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library RDHStrings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) external pure returns (string memory) {
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
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) external pure returns (string memory) {
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

pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT

import "./RDHStrings.sol";

library SVGenStyle {
    using RDHStrings for uint256;

    function hslColor(
        uint256 hue,
        uint256 saturation,
        uint256 lightness
    ) internal pure returns (bytes memory) {
        return
            abi.encodePacked(
                "hsl(",
                hue.toString(),
                ",",
                saturation.toString(),
                "%,",
                lightness.toString(),
                "%)"
            );
    }

    function style(uint256 _shape, uint256 _age)
        external
        pure
        returns (bytes memory)
    {
        uint256 hue = (uint256(359) * uint256(uint16(_shape))) / 65535;
        uint256 saturation = (uint256(100) * uint256(uint16(_shape >> 8))) /
            65535;
        uint256 lightness = uint256(40) +
            (uint256(15) * uint256(uint16(_shape >> 16))) /
            65535;

        bytes memory color = hslColor(hue, saturation, lightness);

        hue = (hue + 30) % 360;
        lightness += 10;
        bytes memory mouth = hslColor(hue, saturation, lightness);
        lightness += 10;
        bytes memory eye = hslColor(hue, saturation, lightness);
        lightness += 10;
        bytes memory leaf = hslColor(hue, saturation, lightness);
        lightness += 10;
        bytes memory branch = hslColor(hue, saturation, lightness);

        unchecked {
            hue = (hue + (_age / (1 days)) * uint256(30)) % uint256(360);
        }
        bytes memory leafVar = hslColor(hue, saturation, lightness);

        return
            abi.encodePacked(
                '<style type="text/css"><![CDATA[',
                // background
                ".background{fill:",
                color,
                ";stroke:white;stroke-width:1;fill-opacity:0.2}",
                // body
                ".body{fill:",
                color,
                ";stroke:white;stroke-width:5}",
                // eye
                ".eye_l{fill:",
                eye,
                ";stroke:white;stroke-width:3}",
                ".eye_r{fill:",
                eye,
                ";stroke:white;stroke-width:3}",
                ".eye_c{fill:",
                eye,
                ";stroke:white;stroke-width:1}",
                ".eye_opacity{fill:",
                eye,
                ";stroke:white;stroke-width:3;fill-opacity:0.3}",
                // mouth
                ".mouth{fill:",
                mouth,
                ";stroke:white;stroke-width:3}",
                ".mouth_opacity{fill:",
                mouth,
                ";stroke:white;stroke-width:3;fill-opacity:0.3}",
                // branch
                ".branch{fill:",
                branch,
                ";stroke:white;stroke-width:4;fill-opacity:0.5}",
                // leaf
                ".leaf{fill:",
                leaf,
                "; stroke:white; stroke-width:5}",
                // leaf_var
                ".leaf_var{fill:",
                leafVar,
                "; stroke:white; stroke-width:5}",
                "]]></style>"
            );
    }
}

pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT

import "./RDHStrings.sol";

library SVGenBody {
    
    using RDHStrings for uint256;

    // create body part
    function body(uint256 _shape) external pure returns (bytes memory) {
        // top point
        uint256 topX = 200;
        uint256 topY = 100;
        // bottom point
        uint256 bottomX = 200;
        uint256 bottomY = uint256(300) +
            (uint256(75) * uint256(uint8(_shape))) /
            uint256(255);
        // left point
        uint256 delta = (uint256(50) * uint256(uint8(_shape >> 8))) /
            uint256(255);
        uint256 leftX = 50 + delta;
        uint256 leftY = 200;
        // right point
        uint256 rightX = uint256(350) - delta;
        uint256 rightY = 200;

        // body type:
        // 0: circle/ellipse
        // 1: rectangle/square
        // 2: triangle
        // 3: diamond
        // 4: oval
        uint256 bodyType = uint256(_shape) % uint256(5);

        if (bodyType == 0) {
            // circle/eclipse
            uint256 cx = 200;
            uint256 cy = (topY + bottomY) / uint256(2);
            uint256 rx = (rightX - leftX) / uint256(2);
            uint256 ry = (bottomY - topY) / uint256(2);
            return
                abi.encodePacked(
                    '<ellipse class="body" cx="',
                    cx.toString(),
                    '" cy="',
                    cy.toString(),
                    '" rx="',
                    rx.toString(),
                    '" ry="',
                    ry.toString(),
                    '"/>'
                );
        } else if (bodyType == 1) {
            // rectangle/square
            uint256 width = rightX - leftX;
            uint256 height = bottomY - topY;
            uint256 r = (((width > height ? height : width) / uint256(4)) *
                uint256(uint8(_shape >> 16))) / uint256(255);
            return
                abi.encodePacked(
                    '<rect class="body" x="',
                    leftX.toString(),
                    '" y="',
                    topY.toString(),
                    '" width="',
                    width.toString(),
                    '" height="',
                    height.toString(),
                    '" rx="',
                    r.toString(),
                    '" ry="',
                    r.toString(),
                    '" />'
                );
        } else if (bodyType == 2) {
            // triangle
            return
                abi.encodePacked(
                    '<polygon class="body" points="',
                    leftX.toString(),
                    ",",
                    topY.toString(),
                    " ",
                    rightX.toString(),
                    ",",
                    topY.toString(),
                    " 200,",
                    bottomY.toString(),
                    '"/>'
                );
        } else if (bodyType == 3) {
            // diamond
            return
                abi.encodePacked(
                    '<polygon class="body" points="',
                    leftX.toString(),
                    ",",
                    leftY.toString(),
                    " ",
                    topX.toString(),
                    ",",
                    topY.toString(),
                    " ",
                    rightX.toString(),
                    ",",
                    rightY.toString(),
                    " ",
                    bottomX.toString(),
                    ",",
                    bottomY.toString(),
                    '"/>'
                );
        } else {
            // oval
            uint256 controlY = topY /
                2 +
                ((leftY - topY / 2) * uint256(uint8(_shape >> 24))) /
                uint256(255);
            return
                abi.encodePacked(
                    '<path class="body" d="M',
                    bottomX.toString(),
                    ",",
                    bottomY.toString(),
                    " Q0,",
                    controlY.toString(),
                    " ",
                    topX.toString(),
                    ",",
                    topY.toString(),
                    " Q400,",
                    controlY.toString(),
                    " ",
                    bottomX.toString(),
                    ",",
                    bottomY.toString(),
                    ' Z"/>'
                );
        }
    }
}

pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT

import "./RDHStrings.sol";
import "./SVGen.sol";

library SVGenEye {
    using RDHStrings for uint256;

    // create single eye
    function eye(
        uint256 eyeType,
        uint256 eyeSize,
        uint256 x,
        uint256 y,
        bool isLeft
    ) public pure returns (bytes memory) {
        bytes memory emptyStringBytes = abi.encodePacked("");
        string memory eyeClass = isLeft ? "eye_l" : "eye_r";
        uint256 r = eyeSize / uint256(2);
        if (eyeType == 0) {
            return
                abi.encodePacked(
                    SVGen.genCircle(x, y, r, eyeClass),
                    SVGen.genCircle(x, y, uint256(3), eyeClass)
                );
        } else if (eyeType == 1) {
            return SVGen.genHalfCircle(x, y, r, true, false, eyeClass);
        } else if (eyeType >= 2 && eyeType <= 4) {
            return
                abi.encodePacked(
                    SVGen.genCircle(x, y, eyeSize / 2, eyeClass),
                    eyeType >= 3
                        ? SVGen.genCircle(x, y, eyeSize / 4, eyeClass)
                        : emptyStringBytes,
                    eyeType == 4
                        ? SVGen.genCircle(x, y, eyeSize / 8, "eye_c")
                        : emptyStringBytes
                );
        } else if (eyeType >= 5 && eyeType <= 7) {
            uint256 cornerRadius = uint256(eyeSize % 2 == 0 ? 0 : 3);
            return
                abi.encodePacked(
                    SVGen.genRect(
                        x,
                        y,
                        eyeSize,
                        eyeSize,
                        cornerRadius,
                        cornerRadius,
                        eyeClass
                    ),
                    eyeType >= 6
                        ? SVGen.genRect(
                            x,
                            y,
                            eyeSize / uint256(2),
                            eyeSize / uint256(2),
                            cornerRadius,
                            cornerRadius,
                            eyeClass
                        )
                        : emptyStringBytes,
                    eyeType >= 7
                        ? SVGen.genRect(
                            x,
                            y,
                            eyeSize / uint256(4),
                            eyeSize / uint256(4),
                            1,
                            1,
                            "eye_c"
                        )
                        : emptyStringBytes
                );
        } else if (eyeType == 8 || eyeType == 9) {
            return
                abi.encodePacked(
                    SVGen.genDownTriangle(x, y, r, eyeClass),
                    eyeType == 9
                        ? SVGen.genLine(x, y + r, x, y - r, eyeClass)
                        : emptyStringBytes
                );
        } else if (eyeType == 10 || eyeType == 11) {
            return
                abi.encodePacked(
                    SVGen.genUpTriangle(x, y, r, eyeClass),
                    eyeType == 11
                        ? SVGen.genLine(x, y + r, x, y - r, eyeClass)
                        : emptyStringBytes
                );
        } else if (eyeType == 12) {
            uint256 rr = r - 5;
            return
                abi.encodePacked(
                    SVGen.genCircle(x, y, r, eyeClass),
                    SVGen.genRhombus(x, y, rr, eyeClass)
                );
        } else if (eyeType == 13 || eyeType == 14) {
            return
                abi.encodePacked(
                    eyeType == 14
                        ? SVGen.genCircle(x, y, r, eyeClass)
                        : emptyStringBytes,
                    SVGen.genLine(x, y + r, x, y - r, eyeClass),
                    SVGen.genLine(x - r, y, x + r, y, eyeClass)
                );
        } else if (eyeType >= 15 && eyeType <= 17) {
            return
                abi.encodePacked(
                    eyeType == 15 || eyeType == 16
                        ? SVGen.genUpArrow(x, y, r, "eye_opacity")
                        : emptyStringBytes,
                    eyeType == 17 || eyeType == 16
                        ? SVGen.genDownArrow(x, y, r, "eye_opacity")
                        : emptyStringBytes
                );
        } else if (eyeType == 18 || eyeType == 19) {
            uint256 rr = r / uint256(2);
            return
                abi.encodePacked(
                    eyeType == 19
                        ? SVGen.genCircle(x, y, r, eyeClass)
                        : emptyStringBytes,
                    SVGen.genLine(x - rr, y - rr, x + rr, y + rr, eyeClass),
                    SVGen.genLine(x - rr, y + rr, x + rr, y - rr, eyeClass)
                );
        } else if (eyeType == 20 || eyeType == 21) {
            uint256 rr = r / uint256(2);
            return
                abi.encodePacked(
                    SVGen.genRect(x, y, eyeSize, eyeSize, 0, 0, "eye_opacity"),
                    eyeType == 20
                        ? SVGen.genRect(
                            x - rr,
                            y - rr,
                            r,
                            r,
                            0,
                            0,
                            "eye_opacity"
                        )
                        : SVGen.genRect(
                            x - rr,
                            y + rr,
                            r,
                            r,
                            0,
                            0,
                            "eye_opacity"
                        ),
                    eyeType == 20
                        ? SVGen.genRect(
                            x + rr,
                            y + rr,
                            r,
                            r,
                            0,
                            0,
                            "eye_opacity"
                        )
                        : SVGen.genRect(
                            x + rr,
                            y - rr,
                            r,
                            r,
                            0,
                            0,
                            "eye_opacity"
                        )
                );
        } else if (eyeType == 22 || eyeType == 23) {
            uint256 rr = r - uint256(5);
            return
                abi.encodePacked(
                    eyeType == 23
                        ? SVGen.genCircle(x, y, r, eyeClass)
                        : emptyStringBytes,
                    SVGen.genLine(x - rr, y, x + rr, y, eyeClass)
                );
        } else if (eyeType == 24) {
            uint256 rr = r / uint256(4);
            return
                abi.encodePacked(
                    SVGen.genLine(x - r, y - rr, x + r, y - rr, eyeClass),
                    SVGen.genLine(x - r, y + rr, x + r, y + rr, eyeClass),
                    SVGen.genLine(x - rr, y - r, x - rr, y + r, eyeClass),
                    SVGen.genLine(x + rr, y - r, x + rr, y + r, eyeClass)
                );
        } else if (eyeType >= 25 && eyeType <= 27) {
            return
                abi.encodePacked(
                    SVGen.genRhombus(x, y, r, eyeClass),
                    eyeType == 25
                        ? SVGen.genLine(x - r, y, x + r, y, eyeClass)
                        : emptyStringBytes,
                    eyeType == 25
                        ? SVGen.genLine(x, y - r, x, y + r, eyeClass)
                        : emptyStringBytes,
                    eyeType == 26
                        ? SVGen.genCircle(x, y, 3, eyeClass)
                        : emptyStringBytes,
                    eyeType == 27
                        ? SVGen.genRhombus(x, y, r / uint256(2), eyeClass)
                        : emptyStringBytes
                );
        } else if (eyeType == 28 || eyeType == 29) {
            uint256 rr = r / uint256(2);
            return
                abi.encodePacked(
                    SVGen.genCircle(x, y, r, eyeClass),
                    eyeType == 28
                        ? SVGen.genRect(x, y, rr, rr, 0, 0, eyeClass)
                        : SVGen.genUpTriangle(x, y, rr, eyeClass)
                );
        } else if (eyeType == 30 || eyeType == 31) {
            return SVGen.genHeart(x, y, r, eyeType == 30, eyeClass);
        } else if (eyeType == 32 || eyeType == 33) {
            uint256 rr = r / uint256(2);
            return
                abi.encodePacked(
                    SVGen.genRect(x, y, eyeSize, eyeSize, 0, 0, eyeClass),
                    eyeType == 32
                        ? SVGen.genLine(x - rr, y, x + rr, y, eyeClass)
                        : SVGen.genLine(x, y - rr, x, y + rr, eyeClass)
                );
        } else if (eyeType == 34) {
            uint256 rr = (r * uint256(3)) / uint256(4);
            return
                abi.encodePacked(
                    SVGen.genUpTriangle(x, y, rr, "eye_opacity"),
                    SVGen.genDownTriangle(x, y, rr, "eye_opacity")
                );
        } else if (eyeType == 35 || eyeType == 36) {
            uint256 rr = r / uint256(2);
            return
                abi.encodePacked(
                    SVGen.genRhombus(x, y, r, eyeClass),
                    eyeType == 35
                        ? SVGen.genLine(x - rr, y, x + rr, y, eyeClass)
                        : SVGen.genLine(x, y - rr, x, y + rr, eyeClass)
                );
        } else if (eyeType == 37 || eyeType == 38) {
            uint256 rr = r / uint256(2);
            return
                abi.encodePacked(
                    eyeType == 37
                        ? SVGen.genCircle(x, y, r, eyeClass)
                        : emptyStringBytes,
                    SVGen.genLine(x, y - rr, x, y + rr, eyeClass)
                );
        } else if (eyeType == 39) {
            return SVGen.genCircle(x, y, 3, eyeClass);
        } else if (eyeType == 40) {
            uint256 rr = r / uint256(2);
            return
                abi.encodePacked(
                    SVGen.genLine(x - r, y, x + r, y, eyeClass),
                    SVGen.genLine(x - rr, y - rr, x - rr, y + rr, eyeClass),
                    SVGen.genLine(x + rr, y - rr, x + rr, y + rr, eyeClass)
                );
        } else if (eyeType == 41 || eyeType == 42) {
            return SVGen.genHalfCircle(x, y, r, false, eyeType == 42, eyeClass);
        } else {
            // eyeType == 43
            return SVGen.genHalfCircle(x, y, r, true, true, eyeClass);
        }
    }

    // create eyes
    function eyes(uint256 _shape) external pure returns (bytes memory) {
        bool hasSameEyes = (uint256(uint8(_shape >> 32)) % uint256(1000)) !=
            uint256(0);
        uint256 totalEyeType = 44;
        uint256 eyeType = uint256(uint8(_shape >> 40)) % totalEyeType;

        uint256 lx = 150;
        uint256 rx = 250;
        uint256 y = uint256(150) +
            (uint256(50) * uint256(uint8(_shape >> 48))) /
            uint256(255);
        uint256 eyeSize = uint256(20) +
            (uint256(20) * uint256(uint8(_shape >> 56))) /
            uint256(255);

        if (hasSameEyes) {
            return
                abi.encodePacked(
                    eye(eyeType, eyeSize, lx, y, true),
                    eye(eyeType, eyeSize, rx, y, false)
                );
        } else {
            uint256 eyeTypeAnother = uint256(uint8(_shape >> 64)) %
                totalEyeType;
            return
                abi.encodePacked(
                    eye(eyeType, eyeSize, lx, y, true),
                    eye(eyeTypeAnother, eyeSize, rx, y, false)
                );
        }
    }
}

pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT

import "./RDHStrings.sol";
import "./SVGen.sol";

library SVGenMouth {
    using RDHStrings for uint256;

    // create mouth
    function mouth(uint256 _shape) public pure returns (bytes memory) {
        uint256 mouthType = uint256(uint8(_shape >> 72)) % uint256(14);
        uint256 x = 200;
        uint256 y = 250 +
            ((uint256(30) * uint256(uint8(_shape >> 80))) / uint256(255));
        uint256 w = 20 +
            ((uint256(60) * uint256(uint8(_shape >> 88))) / uint256(255));
        uint256 h = 20 +
            ((uint256(30) * uint256(uint8(_shape >> 96))) / uint256(255));
        uint256 minSide = (w > h ? h : w);
        uint256 radius = minSide / uint256(2);

        string memory class = "mouth";
        if (mouthType == 0) {
            return SVGen.genCircle(x, y, radius, class);
        } else if (mouthType == 1) {
            uint256 cornerRadius = uint256(5) +
                ((radius / uint256(2)) * uint256(uint8(_shape >> 104))) /
                uint256(255);
            return SVGen.genRect(x, y, w, h, cornerRadius, cornerRadius, class);
        } else if (mouthType == 2) {
            return SVGen.genDownTriangle(x, y, radius, class);
        } else if (mouthType == 3) {
            return SVGen.genUpTriangle(x, y, radius, class);
        } else if (mouthType == 4) {
            uint256 r = w / uint256(2);
            return
                abi.encodePacked(
                    SVGen.genLine(
                        x - r,
                        y - uint256(5),
                        x + r,
                        y - uint256(5),
                        class
                    ),
                    SVGen.genLine(
                        x - r,
                        y + uint256(5),
                        x + r,
                        y + uint256(5),
                        class
                    )
                );
        } else if (mouthType == 5) {
            uint256 r = w / uint256(2);
            return SVGen.genLine(x - r, y, x + r, y, class);
        } else if (mouthType == 6) {
            uint256 r = radius / uint256(2);
            uint256 yy = y - r / uint256(2);
            class = "mouth_opacity";
            return
                abi.encodePacked(
                    SVGen.genHalfCircle(x - r, y, r, false, false, class),
                    SVGen.genHalfCircle(x + r, y, r, false, false, class),
                    SVGen.genLine(x - r, yy, x + r, yy, class)
                );
        } else if (mouthType == 7) {
            uint256 ww = w / uint256(2);
            uint256 hh = h / uint256(2);
            return
                abi.encodePacked(
                    SVGen.genLine(x - ww, y, x, y + hh, class),
                    SVGen.genLine(x, y + hh, x + ww, y, class)
                );
        } else if (mouthType == 8) {
            return
                SVGen.genEllipse(x, y, w / uint256(2), h / uint256(2), class);
        } else if (mouthType == 9 || mouthType == 10) {
            return
                SVGen.genHalfCircle(
                    x,
                    y,
                    radius,
                    false,
                    mouthType == 10,
                    class
                );
        } else if (mouthType == 11) {
            uint256 rr = radius / uint256(2);
            uint256 rrr = 3;
            return
                abi.encodePacked(
                    SVGen.genHalfCircle(x, y, radius, false, false, class),
                    SVGen.genLine(
                        x - radius - rrr,
                        y - rr + rrr,
                        x - radius + rrr,
                        y - rr - rrr,
                        class
                    ),
                    SVGen.genLine(
                        x + radius - rrr,
                        y - rr - rrr,
                        x + radius + rrr,
                        y - rr + rrr,
                        class
                    )
                );
        } else if (mouthType == 12) {
            uint256 hh = 8;
            uint256 ww = w / uint256(2);
            return
                abi.encodePacked(
                    SVGen.genLine(x - ww, y - hh, x + ww, y - hh, class),
                    SVGen.genLine(x - ww, y, x + ww, y, class),
                    SVGen.genLine(x - ww, y + hh, x + ww, y + hh, class)
                );
        } else {
            // mouthType == 13
            uint256 hh = 8;
            uint256 w1 = w / uint256(2);
            uint256 w2 = (w * uint256(618)) / uint256(2000);
            uint256 w3 = (w * uint256(190962)) / uint256(1000000);
            return
                abi.encodePacked(
                    SVGen.genLine(x - w1, y - hh, x + w1, y - hh, class),
                    SVGen.genLine(x - w2, y, x + w2, y, class),
                    SVGen.genLine(x - w3, y + hh, x + w3, y + hh, class)
                );
        }
    }
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

import "./RDHStrings.sol";
import "./SVGen.sol";

library SVGenLeaf {
    using RDHStrings for uint256;

    /// create leaf
    function leaf(
        uint256 leafType,
        uint256 x,
        uint256 y,
        uint256 size,
        string memory class
    ) public pure returns (bytes memory) {
        uint256 r = size / uint256(2);
        if (leafType == 0) {
            return
                abi.encodePacked(
                    SVGen.genQuadArc(x, y, 200, 110, 200, 200, "branch"),
                    SVGen.genCircle(x, y, r, class)
                );
        } else if (leafType == 1) {
            return
                abi.encodePacked(
                    SVGen.genQuadArc(x, y, 200, 110, 200, 200, "branch"),
                    SVGen.genRhombus(x, y, r, class)
                );
        } else if (leafType == 2) {
            return
                abi.encodePacked(
                    SVGen.genQuadArc(x, y, 200, 110, 200, 200, "branch"),
                    SVGen.genRect(x, y, size, size, 0, 0, class)
                );
        } else if (leafType == 3) {
            return
                abi.encodePacked(
                    SVGen.genQuadArc(x, y, 200, 110, 200, 200, "branch"),
                    SVGen.genUpTriangle(x, y, r, class)
                );
        } else {
            // leafType == 4
            return
                abi.encodePacked(
                    SVGen.genQuadArc(x, y, 200, 110, 200, 200, "branch"),
                    SVGen.genDownTriangle(x, y, r, class)
                );
        }
    }

    /// create leafs
    function leafs(uint256 _shape) public pure returns (bytes memory) {
        uint256 leafCount = uint256(1) +
            (uint256(uint8(_shape >> 104)) % uint256(5));
        uint256 leafSize = uint256(20) +
            ((uint256(20) * uint256(uint8(_shape >> 112))) / uint256(255));

        uint256 leafType1 = uint256(uint8(_shape >> 120)) % uint256(5);

        string memory class = "leaf";
        // 1 / 1000 HAS COLOR-CHANGING LEAF
        string memory classVar = uint256(uint8(_shape >> 124)) %
            uint256(1000) ==
            0
            ? "leaf_var"
            : class;
        if (leafCount == 1) {
            return leaf(leafType1, 200, 50, leafSize, class);
        } else {
            uint256 leafType2 = uint256(uint8(_shape >> 128)) % uint256(5);
            if (leafCount == 2) {
                return
                    abi.encodePacked(
                        leaf(leafType1, 150, 50, leafSize, class),
                        leaf(leafType2, 250, 50, leafSize, classVar)
                    );
            } else {
                uint256 leafType3 = uint256(uint8(_shape >> 136)) % uint256(5);
                if (leafCount == 3) {
                    return
                        abi.encodePacked(
                            leaf(leafType1, 100, 50, leafSize, class),
                            leaf(leafType2, 200, 50, leafSize, class),
                            leaf(leafType3, 300, 50, leafSize, classVar)
                        );
                } else {
                    uint256 leafType4 = uint256(uint8(_shape >> 144)) %
                        uint256(5);
                    if (leafCount == 4) {
                        return
                            abi.encodePacked(
                                leaf(leafType1, 50, 50, leafSize, class),
                                leaf(leafType2, 150, 50, leafSize, class),
                                leaf(leafType3, 250, 50, leafSize, class),
                                leaf(leafType4, 350, 50, leafSize, classVar)
                            );
                    } else {
                        uint256 leafType5 = uint256(uint8(_shape >> 152)) %
                            uint256(5);
                        return
                            abi.encodePacked(
                                leaf(leafType1, 50, 50, leafSize, class),
                                leaf(leafType2, 150, 50, leafSize, class),
                                leaf(leafType3, 200, 50, leafSize, class),
                                leaf(leafType4, 250, 50, leafSize, class),
                                leaf(leafType5, 350, 50, leafSize, classVar)
                            );
                    }
                }
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

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
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
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
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
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
            "ERC721: approve caller is not token owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

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
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");

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
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
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
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
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
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
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
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
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

        _afterTokenTransfer(address(0), to, tokenId);
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

        _afterTokenTransfer(owner, address(0), tokenId);
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
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
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
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
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

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

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
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
                /// @solidity memory-safe-assembly
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

pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT

import "./RDHStrings.sol";

library SVGen {
    using RDHStrings for uint256;

    ////// generate common object //////

    /// generate circle with center (cx, cy) and radius and the svg class.
    function genCircle(
        uint256 cx,
        uint256 cy,
        uint256 radius,
        string memory class
    ) public pure returns (bytes memory) {
        return
            abi.encodePacked(
                '<circle class="',
                class,
                '" cx="',
                cx.toString(),
                '" cy="',
                cy.toString(),
                '" r="',
                radius.toString(),
                '" />'
            );
    }

    /// generate rect with center (cx, cy), width, height, cornerRadiusX, cornerRadiusY and the svg class.
    function genRect(
        uint256 cx,
        uint256 cy,
        uint256 width,
        uint256 height,
        uint256 cornerRadiusX,
        uint256 cornerRadiusY,
        string memory class
    ) external pure returns (bytes memory) {
        return
            abi.encodePacked(
                '<rect class="',
                class,
                '" x="',
                (cx - width / uint256(2)).toString(),
                '" y="',
                (cy - height / uint256(2)).toString(),
                '" width="',
                width.toString(),
                '" height="',
                height.toString(),
                '" rx="',
                cornerRadiusX.toString(),
                '" ry="',
                cornerRadiusY.toString(),
                '" />'
            );
    }

    /// generate rhombus with center (cx, cy), radius and the svg class
    function genRhombus(
        uint256 cx,
        uint256 cy,
        uint256 radius,
        string memory class
    ) external pure returns (bytes memory) {
        return
            abi.encodePacked(
                '<polygon class="',
                class,
                '" points="',
                (cx - radius).toString(),
                ",",
                cy.toString(),
                " ",
                cx.toString(),
                ",",
                (cy - radius).toString(),
                " ",
                (cx + radius).toString(),
                ",",
                cy.toString(),
                " ",
                cx.toString(),
                ",",
                (cy + radius).toString(),
                '"/>'
            );
    }

    /// generate up triangle △ with center (cx, cy), radius and the svg class
    function genUpTriangle(
        uint256 cx,
        uint256 cy,
        uint256 radius,
        string memory class
    ) external pure returns (bytes memory) {
        return
            abi.encodePacked(
                '<polygon class="',
                class,
                '" points="',
                (cx - radius).toString(),
                ",",
                (cy + radius).toString(),
                " ",
                (cx + radius).toString(),
                ",",
                (cy + radius).toString(),
                " ",
                cx.toString(),
                ",",
                (cy - radius).toString(),
                '"/>'
            );
    }

    /// generate down triangle with center (cx, cy), radius and the svg class
    function genDownTriangle(
        uint256 cx,
        uint256 cy,
        uint256 radius,
        string memory class
    ) external pure returns (bytes memory) {
        return
            abi.encodePacked(
                '<polygon class="',
                class,
                '" points="',
                (cx - radius).toString(),
                ",",
                (cy - radius).toString(),
                " ",
                (cx + radius).toString(),
                ",",
                (cy - radius).toString(),
                " ",
                cx.toString(),
                ",",
                (cy + radius).toString(),
                '"/>'
            );
    }

    /// generate strait line from (x1, y1) to (x2, y2)
    function genLine(
        uint256 x1,
        uint256 y1,
        uint256 x2,
        uint256 y2,
        string memory class
    ) external pure returns (bytes memory) {
        return
            abi.encodePacked(
                '<path class="',
                class,
                '" d="M',
                x1.toString(),
                ",",
                y1.toString(),
                " L",
                x2.toString(),
                ",",
                y2.toString(),
                '"/>'
            );
    }

    /// generate up arrow with center (cx, cy), radius and the svg class.
    function genUpArrow(
        uint256 cx,
        uint256 cy,
        uint256 radius,
        string memory class
    ) external pure returns (bytes memory) {
        return
            abi.encodePacked(
                '<path class="',
                class,
                '" d="M',
                (cx - radius).toString(),
                ",",
                (cy + radius).toString(),
                " L",
                cx.toString(),
                ",",
                (cy - radius).toString(),
                " L",
                (cx + radius).toString(),
                ",",
                (cy + radius).toString(),
                '"/>'
            );
    }

    /// generate down arrow with center (cx, cy), radius and the svg class.
    function genDownArrow(
        uint256 cx,
        uint256 cy,
        uint256 radius,
        string memory class
    ) external pure returns (bytes memory) {
        return
            abi.encodePacked(
                '<path class="',
                class,
                '" d="M',
                (cx - radius).toString(),
                ",",
                (cy - radius).toString(),
                " L",
                cx.toString(),
                ",",
                (cy + radius).toString(),
                " L",
                (cx + radius).toString(),
                ",",
                (cy - radius).toString(),
                '"/>'
            );
    }

    /// generate heart with center (cx, cy), radius, top is flat param and the svg class.
    function genHeart(
        uint256 cx,
        uint256 cy,
        uint256 radius,
        bool isFlat,
        string memory class
    ) external pure returns (bytes memory) {
        uint256 ty = cy -
            (isFlat ? radius : ((uint256(4) * radius) / uint256(5)));
        uint256 rr = (radius * uint256(3)) / uint256(2);
        return
            abi.encodePacked(
                '<path class="',
                class,
                '" d="M',
                cx.toString(),
                ",",
                (cy + radius).toString(),
                " Q",
                (cx - rr).toString(),
                ",",
                (cy - radius).toString(),
                " ",
                cx.toString(),
                ",",
                ty.toString(),
                " Q",
                (cx + rr).toString(),
                ",",
                (cy - radius).toString(),
                " ",
                cx.toString(),
                ",",
                (cy + radius).toString(),
                ' Z"/>'
            );
    }

    /// generate half circle with center (cx, cy), radius and the svg class.
    function genHalfCircle(
        uint256 cx,
        uint256 cy,
        uint256 radius,
        bool isTop,
        bool closed,
        string memory class
    ) external pure returns (bytes memory) {
        string memory radiusString = radius.toString();
        uint256 rr = radius / uint256(2);
        string memory yString = (isTop ? (cy + rr) : (cy - rr)).toString();
        return
            abi.encodePacked(
                '<path class="',
                class,
                '" d="M ',
                (cx - radius).toString(),
                ",",
                yString,
                " A ",
                radiusString,
                " ",
                radiusString,
                isTop ? " 0 0 1 " : " 0 0 0 ",
                (cx + radius).toString(),
                " ",
                yString,
                closed ? ' Z"/>' : '"/>'
            );
    }

    /// generate ellipse with center (cx, cy), radius x, radius y and the svg class.
    function genEllipse(
        uint256 cx,
        uint256 cy,
        uint256 radiusX,
        uint256 radiusY,
        string memory class
    ) external pure returns (bytes memory) {
        return
            abi.encodePacked(
                '<ellipse class="',
                class,
                '" cx="',
                cx.toString(),
                '" cy="',
                cy.toString(),
                '" rx="',
                radiusX.toString(),
                '" ry="',
                radiusY.toString(),
                '"/>'
            );
    }

    /// generate quad arc with (startX, startY), (controlX, controlY), (endX, endY) and the svg class.
    function genQuadArc(
        uint256 startX,
        uint256 startY,
        uint256 controlX,
        uint256 controlY,
        uint256 endX,
        uint256 endY,
        string memory class
    ) external pure returns (bytes memory) {
        return
            abi.encodePacked(
                '<path class="',
                class,
                '" d="M',
                startX.toString(),
                ",",
                startY.toString(),
                " Q",
                controlX.toString(),
                ",",
                controlY.toString(),
                " ",
                endX.toString(),
                ",",
                endY.toString(),
                '" />'
            );
    }
}