//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/utils/Strings.sol";
import "../libraries/Base64.sol";
import "../engines/ShellBaseEngine.sol";
import "../engines/SVGTextEngine.sol";

contract SVGTextExample is ShellBaseEngine, SVGTextEngine {
    using Strings for uint256;

    function name() external pure returns (string memory) {
        return "svg-text-example";
    }

    function mint(
        IShellFramework collection,
        string calldata name_,
        string calldata bio
    ) external returns (uint256) {
        StringStorage[] memory stringData = new StringStorage[](0);
        IntStorage[] memory intData = new IntStorage[](0);

        uint256 tokenId = collection.mint(
            MintEntry({
                to: msg.sender,
                amount: 1,
                options: MintOptions({
                    storeEngine: true,
                    storeMintedTo: true,
                    storeTimestamp: true,
                    storeBlockNumber: true,
                    stringData: stringData,
                    intData: intData
                })
            })
        );

        updateInfo(collection, tokenId, name_, bio);

        return tokenId;
    }

    function updateInfo(
        IShellFramework collection,
        uint256 tokenId,
        string calldata name_,
        string calldata bio
    ) public {
        collection.writeTokenString(
            StorageLocation.ENGINE,
            tokenId,
            "name",
            name_
        );
        collection.writeTokenString(
            StorageLocation.ENGINE,
            tokenId,
            "bio",
            bio
        );
    }

    function _computeName(IShellFramework nft, uint256 tokenId)
        internal
        view
        override
        returns (string memory)
    {
        string memory name_ = nft.readTokenString(
            StorageLocation.ENGINE,
            tokenId,
            "name"
        );
        return string(abi.encodePacked("Member: ", name_));
    }

    function _computeDescription(IShellFramework nft, uint256 tokenId)
        internal
        view
        override
        returns (string memory)
    {
        string memory name_ = nft.readTokenString(
            StorageLocation.ENGINE,
            tokenId,
            "name"
        );
        string memory bio = nft.readTokenString(
            StorageLocation.ENGINE,
            tokenId,
            "bio"
        );
        uint256 mintedTo = nft.readTokenInt(
            StorageLocation.FRAMEWORK,
            tokenId,
            "mintedTo"
        );
        uint256 timestamp = nft.readTokenInt(
            StorageLocation.FRAMEWORK,
            tokenId,
            "timestamp"
        );

        return
            string(
                abi.encodePacked(
                    "Example membership NFT. \\n\\nMember: ",
                    name_,
                    " \\n\\n",
                    bio,
                    " \\n\\nOriginally minted to ",
                    mintedTo.toHexString(20),
                    " \\n\\nMinted at timestamp ",
                    timestamp.toString(),
                    ".\\n\\n Token ID #",
                    tokenId.toString(),
                    ".\\n\\n Powered by https://heyshell.xyz"
                )
            );
    }

    function _computeText(IShellFramework collection, uint256 tokenId)
        internal
        view
        override
        returns (string[] memory)
    {
        string[] memory lines = new string[](4);

        string memory name_ = collection.readTokenString(
            StorageLocation.ENGINE,
            tokenId,
            "name"
        );
        uint256 timestamp = collection.readTokenInt(
            StorageLocation.FRAMEWORK,
            tokenId,
            "timestamp"
        );

        lines[0] = string(abi.encodePacked("Token #", tokenId.toString()));
        lines[1] = string(abi.encodePacked("Member: ", name_));
        lines[2] = string(abi.encodePacked("Joined: ", timestamp.toString()));
        lines[3] = "powered by heyshell.xyz";

        return lines;
    }

    function _computeExternalUrl(IShellFramework, uint256)
        internal
        pure
        override
        returns (string memory)
    {
        return "https://playgrounds.wtf";
    }

    function _computeAttributes(IShellFramework collection, uint256 tokenId)
        internal
        view
        override
        returns (Attribute[] memory)
    {
        Attribute[] memory attributes = new Attribute[](2);
        string memory name_ = collection.readTokenString(
            StorageLocation.ENGINE,
            tokenId,
            "name"
        );
        uint256 timestamp = collection.readTokenInt(
            StorageLocation.FRAMEWORK,
            tokenId,
            "timestamp"
        );
        attributes[0] = Attribute({key: "Name", value: name_});
        attributes[1] = Attribute({key: "Joined", value: timestamp.toString()});
        return attributes;
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
pragma solidity ^0.8.0;

// https://github.com/Brechtpd/base64/blob/main/base64.sol

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides a function for encoding some bytes in base64
library Base64 {
    string internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

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
            for {

            } lt(dataPtr, endPtr) {

            } {
                dataPtr := add(dataPtr, 3)

                // read 3 bytes
                let input := mload(dataPtr)

                // write 4 characters
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(input, 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC165.sol";
import "../IEngine.sol";

// simple starting point for engines
// - default name
// - proper erc165 support
// - no royalties
// - nop on beforeTokenTransfer and afterEngineSet hooks
abstract contract ShellBaseEngine is IEngine {

    // nop
    function beforeTokenTransfer(
        address,
        address,
        address,
        uint256,
        uint256
    ) external pure virtual override {
        return;
    }

    // nop
    function afterEngineSet(uint256) external view virtual override {
        return;
    }

    // no royalties
    function getRoyaltyInfo(
        IShellFramework,
        uint256,
        uint256
    ) external view virtual returns (address receiver, uint256 royaltyAmount) {
        receiver = address(0);
        royaltyAmount = 0;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        pure
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IEngine).interfaceId ||
            interfaceId == type(IERC165).interfaceId;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "./SVGImageEngine.sol";
import "./ShellBaseEngine.sol";

struct TextConfig {
    string bgColor;
    string fgColor;
    string fontFamily;
    uint32 fontSize;
    uint32 height;
    uint32 width;
    uint32 padding;
    uint32 lineHeight;
}

/// @notice Basic text SVG NFT image
abstract contract SVGTextEngine is SVGImageEngine {
    using Strings for uint256;

    /// @notice should return a complete <svg> document
    function _computeSVGDocument(IShellFramework collection, uint256 tokenId)
        internal
        view
        override
        returns (string memory)
    {
        TextConfig memory config = _computeTextConfig(collection, tokenId);
        string[] memory lines = _computeText(collection, tokenId);

        string memory svg = string.concat(
            '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" ',
            'viewBox="0 0 ',
            uint256(config.width).toString(),
            " ",
            uint256(config.height).toString(),
            '">',
            "<style>.base { fill: ",
            config.fgColor,
            "; font-family: ",
            config.fontFamily,
            "; font-size: ",
            uint256(config.fontSize).toString(),
            "px; }</style>",
            '<rect width="100%" height="100%" fill="',
            config.bgColor,
            '" />'
        );

        for (uint256 i = 0; i < lines.length; i++) {
            svg = string.concat(
                svg,
                '<text x="',
                uint256(config.padding).toString(),
                '" y="',
                uint256(config.lineHeight + config.lineHeight * i).toString(),
                '" class="base">',
                lines[i],
                "</text>"
            );
        }

        svg = string.concat(svg, "</svg>");

        return svg;
    }

    /// @notice get the text configuration for a token. Override to change appearance
    function _computeTextConfig(IShellFramework, uint256)
        internal
        view
        virtual
        returns (TextConfig memory)
    {
        return
            TextConfig({
                bgColor: "#222",
                fgColor: "#FDFFFC",
                fontFamily: '"DM Mono", monospace',
                fontSize: 12,
                height: 350,
                width: 350,
                padding: 10,
                lineHeight: 20
            });
    }

    /// @notice return an array of text lines to display. Should be overriden
    function _computeText(IShellFramework collection, uint256 tokenId)
        internal
        view
        virtual
        returns (string[] memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC165.sol";
import "./IShellFramework.sol";

// Required interface for framework engines
// interfaceId = 0x0b1d171c
interface IEngine is IERC165 {
    // Get the name for this engine
    function name() external pure returns (string memory);

    // Called by the framework to resolve a response for tokenURI method
    function getTokenURI(IShellFramework collection, uint256 tokenId)
        external
        view
        returns (string memory);

    // Called by the framework to resolve a response for royaltyInfo method
    function getRoyaltyInfo(
        IShellFramework collection,
        uint256 tokenId,
        uint256 salePrice
    ) external view returns (address receiver, uint256 royaltyAmount);

    // Called by the framework during a transfer, including mints (from=0) and
    // burns (to=0). Cannot break transfer even in the case of reverting, as the
    // collection will wrap the downstream call in a try/catch
    // collection = msg.sender
    function beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256 tokenId,
        uint256 amount
    ) external;

    // Called by the framework whenever an engine is set on a fork, including
    // the collection (fork id = 0). Can be used by engine developers to prevent
    // an engine from being installed in a collection or non-canonical fork if
    // desired
    // collection = msg.sender
    function afterEngineSet(uint256 forkId) external;
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC165.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "./libraries/IOwnable.sol";
import "./IEngine.sol";

// storage flag
enum StorageLocation {
    INVALID,
    // set by the engine at any time, mutable
    ENGINE,
    // set by the engine during minting, immutable
    MINT_DATA,
    // set by the framework during minting or collection creation, immutable
    FRAMEWORK
}

// string key / value
struct StringStorage {
    string key;
    string value;
}

// int key / value
struct IntStorage {
    string key;
    uint256 value;
}

// data provided when minting a new token
struct MintEntry {
    address to;
    uint256 amount;
    MintOptions options;
}

// Data provided by engine when minting a new token
struct MintOptions {
    bool storeEngine;
    bool storeMintedTo;
    bool storeTimestamp;
    bool storeBlockNumber;
    StringStorage[] stringData;
    IntStorage[] intData;
}

// Information about a fork
struct Fork {
    IEngine engine;
    address owner;
}

// Interface for every collection launched by shell.
// Concrete implementations must return true on ERC165 checks for this interface
// (as well as erc165 / 2981)
// interfaceId = TBD
interface IShellFramework is IERC165, IERC2981 {
    // ---
    // Framework errors
    // ---

    // an engine was provided that did no pass the expected erc165 checks
    error InvalidEngine();

    // a write was attempted that is not allowed
    error WriteNotAllowed();

    // an operation was attempted but msg.sender was not the expected engine
    error SenderNotEngine();

    // an operation was attempted but msg.sender was not the fork owner
    error SenderNotForkOwner();

    // a token fork was attempted by an invalid msg.sender
    error SenderCannotFork();

    // ---
    // Framework events
    // ---

    // a fork was created
    event ForkCreated(uint256 forkId, IEngine engine, address owner);

    // a fork had a new engine installed
    event ForkEngineUpdated(uint256 forkId, IEngine engine);

    // a fork had a new owner set
    event ForkOwnerUpdated(uint256 forkId, address owner);

    // a token has been set to a new fork
    event TokenForkUpdated(uint256 tokenId, uint256 forkId);

    // ---
    // Storage events
    // ---

    // A fork string was stored
    event ForkStringUpdated(
        StorageLocation location,
        uint256 forkId,
        string key,
        string value
    );

    // A fork int was stored
    event ForkIntUpdated(
        StorageLocation location,
        uint256 forkId,
        string key,
        uint256 value
    );

    // A token string was stored
    event TokenStringUpdated(
        StorageLocation location,
        uint256 tokenId,
        string key,
        string value
    );

    // A token int was stored
    event TokenIntUpdated(
        StorageLocation location,
        uint256 tokenId,
        string key,
        uint256 value
    );

    // ---
    // Collection base
    // ---

    // called immediately after cloning
    function initialize(
        string calldata name,
        string calldata symbol,
        IEngine engine,
        address owner
    ) external;

    // ---
    // General collection info / metadata
    // ---

    // collection owner (fork 0 owner)
    function owner() external view returns (address);

    // collection name
    function name() external view returns (string memory);

    // collection name
    function symbol() external view returns (string memory);

    // next token id serial number
    function nextTokenId() external view returns (uint256);

    // next fork id serial number
    function nextForkId() external view returns (uint256);

    // ---
    // Fork functionality
    // ---

    // Create a new fork with a specific engine, fork all the tokenIds to the
    // new engine, and return the fork ID
    function createFork(
        IEngine engine,
        address owner,
        uint256[] calldata tokenIds
    ) external returns (uint256);

    // Set the engine for a specific fork. Must be fork owner
    function setForkEngine(uint256 forkId, IEngine engine) external;

    // Set the fork owner. Must be fork owner
    function setForkOwner(uint256 forkId, address owner) external;

    // Set the fork of a specific token. Must be token owner
    function setTokenFork(uint256 tokenId, uint256 forkId) external;

    // Set the fork for several tokens. Must own all tokens
    function setTokenForks(uint256[] memory tokenIds, uint256 forkId) external;

    // ---
    // Fork views
    // ---

    // Get information about a fork
    function getFork(uint256 forkId) external view returns (Fork memory);

    // Get a fork's engine
    function getForkEngine(uint256 forkId) external view returns (IEngine);

    // Get a fork's owner
    function getForkOwner(uint256 forkId) external view returns (address);

    // Get a token's fork ID
    function getTokenForkId(uint256 tokenId) external view returns (uint256);

    // Get a token's engine. getFork(getTokenForkId(tokenId)).engine
    function getTokenEngine(uint256 tokenId) external view returns (IEngine);

    // Determine if a given msg.sender can fork a token
    function canSenderForkToken(address sender, uint256 tokenId)
        external
        view
        returns (bool);

    // ---
    // Engine functionality
    // ---

    // mint new tokens. Only callable by collection engine
    function mint(MintEntry calldata entry) external returns (uint256);

    // ---
    // Storage writes
    // ---

    // Write a string to collection storage. Only callable by collection engine
    function writeForkString(
        StorageLocation location,
        uint256 forkId,
        string calldata key,
        string calldata value
    ) external;

    // Write a string to collection storage. Only callable by collection engine
    function writeForkInt(
        StorageLocation location,
        uint256 forkId,
        string calldata key,
        uint256 value
    ) external;

    // Write a string to token storage. Only callable by token engine
    function writeTokenString(
        StorageLocation location,
        uint256 tokenId,
        string calldata key,
        string calldata value
    ) external;

    // Write a string to token storage. Only callable by token engine
    function writeTokenInt(
        StorageLocation location,
        uint256 tokenId,
        string calldata key,
        uint256 value
    ) external;

    // ---
    // Storage reads
    // ---

    // Read a string from collection storage
    function readForkString(
        StorageLocation location,
        uint256 forkId,
        string calldata key
    ) external view returns (string memory);

    // Read a uint256 from collection storage
    function readForkInt(
        StorageLocation location,
        uint256 forkId,
        string calldata key
    ) external view returns (uint256);

    // Read a string from token storage
    function readTokenString(
        StorageLocation location,
        uint256 tokenId,
        string calldata key
    ) external view returns (string memory);

    // Read a uint256 from token storage
    function readTokenInt(
        StorageLocation location,
        uint256 tokenId,
        string calldata key
    ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Called with the sale price to determine how much royalty is owed and to whom.
     * @param tokenId - the NFT asset queried for royalty information
     * @param salePrice - the sale price of the NFT asset specified by `tokenId`
     * @return receiver - address of who should be sent the royalty payment
     * @return royaltyAmount - the royalty payment amount for `salePrice`
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// (semi) standard ownable interface
interface IOwnable {
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    function owner() external view returns (address);

    function renounceOwnership() external;

    function transferOwnership(address newOwner) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../libraries/Base64.sol";
import "./OnChainMetadataEngine.sol";

/// @notice Extends on chain metadata base engine to use an SVG document in the
/// image metadata field
abstract contract SVGImageEngine is OnChainMetadataEngine {
    function _computeImageUri(IShellFramework collection, uint256 tokenId)
        internal
        view
        override
        returns (string memory)
    {
        return
            string.concat(
                "data:image/svg+xml;base64,",
                Base64.encode(bytes(_computeSVGDocument(collection, tokenId)))
            );
    }

    /// @notice should return a complete <svg> document
    function _computeSVGDocument(IShellFramework collection, uint256 tokenId)
        internal
        view
        virtual
        returns (string memory);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../libraries/Base64.sol";
import "../IShellFramework.sol";
import "../IEngine.sol";

struct Attribute {
    string key;
    string value;
}

abstract contract OnChainMetadataEngine is IEngine {
    // Called by the collection to resolve a response for tokenURI
    function getTokenURI(IShellFramework collection, uint256 tokenId)
        external
        view
        returns (string memory)
    {
        string memory name = _computeName(collection, tokenId);
        string memory description = _computeDescription(collection, tokenId);
        string memory image = _computeImageUri(collection, tokenId);
        string memory externalUrl = _computeExternalUrl(collection, tokenId);
        Attribute[] memory attributes = _computeAttributes(collection, tokenId);

        string memory attributesInnerJson = "";
        for (uint256 i = 0; i < attributes.length; i++) {
            attributesInnerJson = string(
                bytes(
                    abi.encodePacked(
                        attributesInnerJson,
                        i > 0 ? ", " : "",
                        '{"trait_type": "',
                        attributes[i].key,
                        '", "value": "',
                        attributes[i].value,
                        '"}'
                    )
                )
            );
        }

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"',
                                name,
                                '", "description":"',
                                description,
                                '", "image": "',
                                image,
                                '", "external_url": "',
                                externalUrl,
                                '", "attributes": [',
                                attributesInnerJson,
                                "]}"
                            )
                        )
                    )
                )
            );
    }

    // compute the metadata name for a given token
    function _computeName(IShellFramework collection, uint256 tokenId)
        internal
        view
        virtual
        returns (string memory);

    // compute the metadata description for a given token
    function _computeDescription(IShellFramework collection, uint256 tokenId)
        internal
        view
        virtual
        returns (string memory);

    // compute the metadata image field for a given token
    function _computeImageUri(IShellFramework collection, uint256 tokenId)
        internal
        view
        virtual
        returns (string memory);

    // compute the external_url field for a given token
    function _computeExternalUrl(IShellFramework collection, uint256 tokenId)
        internal
        view
        virtual
        returns (string memory);

    function _computeAttributes(IShellFramework collection, uint256 token)
        internal
        view
        virtual
        returns (Attribute[] memory);
}