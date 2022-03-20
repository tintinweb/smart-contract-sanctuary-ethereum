/**
 *Submitted for verification at Etherscan.io on 2022-03-20
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)



// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)



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
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/IERC2981.sol)





/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be payed in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}
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


// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)



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

interface IPersonalizedSVG {
    function getSVG(
        string memory,
        string memory,
        string memory
    ) external pure returns (string memory);
}

contract PersonalizedSVG is IPersonalizedSVG {
    using Strings for uint256;

    //===== State =====//

    struct RgbColor {
        uint256 r;
        uint256 g;
        uint256 b;
    }

    //===== public Functions =====//

    function getSVG(
        string memory memberName,
        string memory tokenName,
        string memory tokenId
    ) public pure returns (string memory) {
        string memory output = _buildOutput(memberName, tokenName, tokenId);
        return
            string(
                abi.encodePacked(
                    "data:image/svg+xml;base64,",
                    Base64.encode(bytes(output))
                )
            );
    }

    //===== Private Functions =====//

    function _random(string memory input) private pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    function _pluckColor(string memory seed1, string memory seed2)
        private
        pure
        returns (RgbColor memory)
    {
        RgbColor memory rgb = RgbColor(
            _random(string(abi.encodePacked(seed1, seed2))) % 255,
            _random(seed1) % 255,
            _random(seed2) % 255
        );
        return rgb;
    }

    function _rotateColor(RgbColor memory rgb)
        private
        pure
        returns (RgbColor memory)
    {
        RgbColor memory rotated = RgbColor(
            (rgb.r + 128) % 255,
            (rgb.g + 128) % 255,
            (rgb.b + 128) % 255
        );
        return rotated;
    }

    function _colorToString(RgbColor memory rgb)
        private
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "rgba",
                    "(",
                    rgb.r.toString(),
                    ",",
                    rgb.g.toString(),
                    ",",
                    rgb.b.toString(),
                    ", 1)"
                )
            );
    }

    function _buildOutput(
        string memory memberName,
        string memory tokenName,
        string memory tokenId
    ) private pure returns (string memory) {
        RgbColor memory rgb1 = _pluckColor(memberName, tokenName);
        RgbColor memory rgb2 = _rotateColor(rgb1);
        string memory color1 = _colorToString(rgb1);
        string memory output = string(
            abi.encodePacked(
                '<svg width="300" height="400" viewBox="0 0 300 400" fill="none" xmlns="http://www.w3.org/2000/svg"><rect width="300" height="400" rx="140" fill="url(#paint0_radial_1_3)"/><style>.main { font: 24px sans-serif; fill:',
                color1,
                '; }</style><text x="50%" y="176px" text-anchor="middle" class="main">',
                memberName,
                '</text><text x="50%" y="206px" text-anchor="middle" class="main">',
                tokenName,
                '</text><text x="50%" y="236px" text-anchor="middle" class="main">',
                tokenId
            )
        );
        return
            string(
                abi.encodePacked(
                    output,
                    '</text><defs><radialGradient id="paint0_radial_1_3" cx="0" cy="0" r="1" gradientUnits="userSpaceOnUse" gradientTransform="translate(150 200) rotate(90) scale(207 170)"><stop stop-color="',
                    _colorToString(rgb2),
                    '"/><stop offset="1" stop-color="',
                    color1,
                    '"/></radialGradient></defs></svg>'
                )
            );
    }
}

interface IERC721Partial {
    function name() external view returns (string memory);

    function ownerOf(uint256) external view returns (address);
}

// Fits ENS' reverse records (main name)
interface INameRecord {
    function getNames(address[] calldata)
        external
        view
        returns (string[] memory);
}

contract SquadzDescriptor is PersonalizedSVG {
    // to be replaced by some name system later
    INameRecord public constant nameRecord = INameRecord(address(0));

    function _computeName(IShellFramework collection, uint256 tokenId)
        internal
        view
        returns (string memory)
    {
        address owner = IERC721Partial(address(collection)).ownerOf(tokenId);
        require(owner != address(0), "no token");
        address[] memory addresses = new address[](1);
        addresses[0] = owner;
        if (address(nameRecord) != address(0)) {
            try nameRecord.getNames(addresses) returns (string[] memory names) {
                return names[0];
            } catch {
                return Strings.toHexString(uint256(uint160(owner)));
            }
        }
        return Strings.toHexString(uint256(uint160(owner)));
    }

    function _computeDescription(IShellFramework collection, uint256 tokenId)
        internal
        view
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "Squadz NFT: ",
                    IERC721Partial(address(collection)).name(),
                    " \\n\\nIssued to ",
                    Strings.toHexString(
                        uint256(
                            uint160(
                                IERC721Partial(address(collection)).ownerOf(
                                    tokenId
                                )
                            )
                        )
                    ),
                    ".\\n\\n Token ID #",
                    Strings.toString(tokenId),
                    ".\\n\\n Powered by https://heyshell.xyz"
                )
            );
    }

    function _computeImageUri(IShellFramework collection, uint256 tokenId)
        internal
        view
        returns (string memory)
    {
        return
            getSVG(
                _computeName(collection, tokenId),
                IERC721Partial(address(collection)).name(),
                Strings.toString(tokenId)
            );
    }

    function _computeExternalUrl(IShellFramework collection, uint256)
        internal
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "https://squadz.xyz/",
                    Strings.toHexString(uint256(uint160(address(collection))))
                )
            );
    }
}

interface IERC721 {
    function balanceOf(address) external view returns (uint256);
}

contract SquadzEngine is SquadzDescriptor, ShellBaseEngine {
    //-------------------
    // State
    //-------------------

    /* Length of time a token is active */
    uint256 public constant baseExpiry = 365 days;

    /* Minimum time between mints for admins */
    uint256 public constant baseCooldown = 8 hours;

    /* Power bonus for having an active token */
    uint8 public constant baseBonus = 10;

    /* Max power from held tokens */
    uint8 public constant baseMax = 20;

    /* Key strings */
    string private constant _EXPIRY = "EXPIRY";
    string private constant _COOLDOWN = "COOLDOWN";
    string private constant _BONUS = "BONUS";
    string private constant _MAX = "MAX";

    //-------------------
    // Events
    //-------------------

    event SetCollectionConfig(
        address indexed collection,
        uint256 indexed fork,
        uint256 expiry,
        uint256 cooldown,
        uint256 bonus,
        uint256 max
    );

    //-------------------
    // External functions
    //-------------------

    function name() external pure returns (string memory) {
        return "Squadz Engine v0.0.1";
    }

    function getTokenURI(IShellFramework collection, uint256 tokenId)
        external
        view
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"',
                                _computeName(collection, tokenId),
                                '", "description":"',
                                _computeDescription(collection, tokenId),
                                '", "image": "',
                                _computeImageUri(collection, tokenId),
                                '", "external_url": "',
                                _computeExternalUrl(collection, tokenId),
                                '"}'
                            )
                        )
                    )
                )
            );
    }

    function powerOfAt(
        IShellFramework collection,
        uint256 fork,
        address member,
        uint256 timestamp
    ) external view returns (uint256 power) {
        (bool active, ) = isActiveAdmin(collection, fork, member, timestamp);
        (, , uint256 bonus, uint256 max) = getCollectionConfig(
            collection,
            fork
        );
        if (active) power += bonus;
        uint256 balance = IERC721(address(collection)).balanceOf(member);
        balance > max ? power += max : power += balance;
    }

    function batchMint(
        IShellFramework collection,
        uint256 fork,
        address[] calldata toAddresses,
        bool[] calldata adminBools
    ) external {
        require(toAddresses.length == adminBools.length, "array mismatch");
        for (uint256 i = 0; i < toAddresses.length; i++) {
            mint(collection, fork, toAddresses[i], adminBools[i]);
        }
    }

    /* No transfers! */
    function beforeTokenTransfer(
        address,
        address from,
        address,
        uint256,
        uint256
    ) external pure override {
        require(from == address(0), "Only mints");
    }

    // To set cooldown, bonus, or max to 0, set them to type(uint256).max

    function setCollectionConfig(
        IShellFramework collection,
        uint256 fork,
        uint256 expiry,
        uint256 cooldown,
        uint256 bonus,
        uint256 max
    ) external {
        require(collection.getForkOwner(fork) == msg.sender, "owner only");
        require(expiry != 0, "expiry 0");
        require(cooldown != 0, "cooldown 0");
        require(bonus != 0, "bonus 0");
        require(max != 0, "max 0");

        (
            uint256 currentExpiry,
            uint256 currentCooldown,
            uint256 currentBonus,
            uint256 currentMax
        ) = getCollectionConfig(collection, fork);

        if (expiry != currentExpiry)
            collection.writeForkInt(
                StorageLocation.ENGINE,
                fork,
                _EXPIRY,
                expiry
            );

        if (cooldown != currentCooldown)
            collection.writeForkInt(
                StorageLocation.ENGINE,
                fork,
                _COOLDOWN,
                cooldown
            );

        if (bonus != currentBonus)
            collection.writeForkInt(
                StorageLocation.ENGINE,
                fork,
                _BONUS,
                bonus
            );

        if (max != currentMax)
            collection.writeForkInt(StorageLocation.ENGINE, fork, _MAX, max);

        emit SetCollectionConfig(
            address(collection),
            fork,
            expiry,
            cooldown,
            bonus,
            max
        );
    }

    function removeAdmin(
        IShellFramework collection,
        uint256 fork,
        address member
    ) external {
        require(collection.getForkOwner(fork) == msg.sender, "owner only");
        (uint256 tokenId, uint256 timestamp, bool admin) = latestTokenOf(
            collection,
            fork,
            member
        );
        if (admin)
            // rewrite the latest token with admin == false
            _writeLatestToken(collection, fork, tokenId, member, timestamp, 0);
    }

    //-------------------
    // Public functions
    //-------------------

    function mint(
        IShellFramework collection,
        uint256 fork,
        address to,
        bool admin
    ) public returns (uint256 tokenId) {
        StringStorage[] memory stringData = new StringStorage[](0);
        IntStorage[] memory intData = new IntStorage[](0);

        tokenId = collection.mint(
            MintEntry({
                to: to,
                amount: 1,
                options: MintOptions({
                    storeEngine: false,
                    storeMintedTo: false,
                    storeTimestamp: false,
                    storeBlockNumber: false,
                    stringData: stringData,
                    intData: intData
                })
            })
        );

        _writeMintData(collection, fork, to, tokenId, admin);
    }

    function getCollectionConfig(IShellFramework collection, uint256 fork)
        public
        view
        returns (
            uint256 expiry,
            uint256 cooldown,
            uint256 bonus,
            uint256 max
        )
    {
        expiry = collection.readForkInt(StorageLocation.ENGINE, fork, _EXPIRY);
        if (expiry == 0) expiry = baseExpiry;

        cooldown = collection.readForkInt(
            StorageLocation.ENGINE,
            fork,
            _COOLDOWN
        );
        if (cooldown == 0) cooldown = baseCooldown;
        else if (cooldown == type(uint256).max) cooldown = 0;

        bonus = collection.readForkInt(StorageLocation.ENGINE, fork, _BONUS);
        if (bonus == 0) bonus = uint256(baseBonus);
        else if (bonus == type(uint256).max) bonus = 0;

        max = collection.readForkInt(StorageLocation.ENGINE, fork, _MAX);
        if (max == 0) max = uint256(baseMax);
        else if (max == type(uint256).max) max = 0;
    }

    function latestTokenOf(
        IShellFramework collection,
        uint256 fork,
        address member
    )
        public
        view
        returns (
            uint256 tokenId,
            uint256 timestamp,
            bool admin
        )
    {
        uint256 res = collection.readForkInt(
            StorageLocation.ENGINE,
            fork,
            _latestTokenKey(member)
        );
        uint256 adminInt = res & 1;
        adminInt == 1 ? admin = true : admin = false;
        timestamp = uint256(uint128(res) >> 1);
        tokenId = res >> 128;
    }

    function isActiveAdmin(
        IShellFramework collection,
        uint256 fork,
        address member,
        uint256 timestamp
    ) public view returns (bool, bool) {
        (uint256 expiry, , , ) = getCollectionConfig(collection, fork);
        (, uint256 mintedAt, bool admin) = latestTokenOf(
            collection,
            fork,
            member
        );
        if (mintedAt == 0 || mintedAt + expiry < timestamp)
            return (false, admin);
        return (true, admin);
    }

    //-------------------
    // Private functions
    //-------------------

    function _latestMintOf(
        IShellFramework collection,
        uint256 fork,
        address admin
    ) private view returns (uint256) {
        return
            collection.readForkInt(
                StorageLocation.ENGINE,
                fork,
                _latestMintKey(admin)
            );
    }

    function _writeMintData(
        IShellFramework collection,
        uint256 fork,
        address to,
        uint256 tokenId,
        bool admin
    ) private {
        require(tokenId <= type(uint128).max, "max tokens");
        if (admin) {
            require(collection.getForkOwner(fork) == msg.sender, "owner only");
        } else if (collection.getForkOwner(fork) != msg.sender) {
            // check sender is admin
            (bool senderActive, bool senderAdmin) = isActiveAdmin(
                collection,
                fork,
                msg.sender,
                block.timestamp
            );
            require(senderActive && senderAdmin, "owner, admin only");
            // check cooldown is up
            (, uint256 cooldown, , ) = getCollectionConfig(collection, fork);
            uint256 latestMint = _latestMintOf(collection, fork, msg.sender);
            if (latestMint != 0)
                require(latestMint + cooldown <= block.timestamp, "cooldown");
        }

        uint256 adminInt = 1;
        if (!admin) adminInt = 0;
        _writeLatestToken(
            collection,
            fork,
            tokenId,
            to,
            block.timestamp,
            adminInt
        );
        collection.writeForkInt(
            StorageLocation.ENGINE,
            fork,
            _latestMintKey(msg.sender),
            block.timestamp
        );
    }

    function _writeLatestToken(
        IShellFramework collection,
        uint256 fork,
        uint256 tokenId,
        address to,
        uint256 timestamp,
        uint256 adminInt
    ) private {
        collection.writeForkInt(
            StorageLocation.ENGINE,
            fork,
            _latestTokenKey(to),
            (tokenId << 128) | (timestamp << 1) | adminInt
        );
    }

    function _latestTokenKey(address member)
        private
        pure
        returns (string memory)
    {
        return string(abi.encodePacked("LATEST_TOKEN", member));
    }

    function _latestMintKey(address admin)
        private
        pure
        returns (string memory)
    {
        return string(abi.encodePacked("LATEST_MINT", admin));
    }
}