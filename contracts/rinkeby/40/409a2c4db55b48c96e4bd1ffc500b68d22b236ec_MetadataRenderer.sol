// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import {LibUintToString} from "sol2string/contracts/LibUintToString.sol";
import {UriEncode} from "sol-uriencode/src/UriEncode.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";

import {UUPS} from "../../lib/proxy/UUPS.sol";
import {Ownable} from "../../lib/utils/Ownable.sol";
import {Strings} from "../../lib/utils/Strings.sol";

import {MetadataRendererStorageV1} from "./storage/MetadataRendererStorageV1.sol";
import {IMetadataRenderer} from "./IMetadataRenderer.sol";
import {IManager} from "../../manager/IManager.sol";

/// @title Metadata Renderer
/// @author Iain Nash & Rohan Kulkarni
/// @notice This contract stores, renders, and generates the attributes for an associated token contract
contract MetadataRenderer is IMetadataRenderer, UUPS, Ownable, MetadataRendererStorageV1 {
    ///                                                          ///
    ///                          IMMUTABLES                      ///
    ///                                                          ///

    /// @notice The contract upgrade manager
    IManager private immutable manager;

    ///                                                          ///
    ///                          CONSTRUCTOR                     ///
    ///                                                          ///

    /// @param _manager The address of the contract upgrade manager
    constructor(address _manager) payable initializer {
        manager = IManager(_manager);
    }

    ///                                                          ///
    ///                          INITIALIZER                     ///
    ///                                                          ///

    /// @notice Initializes an instance of a DAO's metadata renderer
    /// @param _initStrings The encoded token and metadata init strings
    /// @param _token The address of the ERC-721 token
    /// @param _founder The address of the founder responsible for adding
    function initialize(
        bytes calldata _initStrings,
        address _token,
        address _founder,
        address _treasury
    ) external initializer {
        // Decode the token initialization strings
        (string memory _name, , string memory _description, string memory _contractImage, string memory _rendererBase) = abi.decode(
            _initStrings,
            (string, string, string, string, string)
        );

        // Store the renderer settings
        settings.name = _name;
        settings.description = _description;
        settings.contractImage = _contractImage;
        settings.rendererBase = _rendererBase;
        settings.token = _token;
        settings.treasury = _treasury;

        // Initialize ownership to the founder
        __Ownable_init(_founder);
    }

    ///                                                          ///
    ///                     PROPERTIES & ITEMS                   ///
    ///                                                          ///

    /// @notice The number of properties
    function propertiesCount() external view returns (uint256) {
        return properties.length;
    }

    /// @notice The number of items in a property
    /// @param _propertyId The property id
    function itemsCount(uint256 _propertyId) external view returns (uint256) {
        return properties[_propertyId].items.length;
    }

    /// @notice Adds properties and/or items to be pseudo-randomly chosen from for token generation to choose from attribute generations
    /// @param _names The names of the properties to add
    /// @param _items The items to add to each property
    /// @param _ipfsGroup The IPFS base URI and extension
    function addProperties(
        string[] calldata _names,
        ItemParam[] calldata _items,
        IPFSGroup calldata _ipfsGroup
    ) external onlyOwner {
        // Cache the existing amount of IPFS data stored
        uint256 dataLength = ipfsData.length;

        // If this is the first time adding properties and/or items:
        if (dataLength == 0) {
            // Transfer ownership to the DAO treasury
            transferOwnership(settings.treasury);
        }

        // Add the IPFS group information
        ipfsData.push(_ipfsGroup);

        // Cache the number of existing properties
        uint256 numStoredProperties = properties.length;

        // Cache the number of new properties adding
        uint256 numNewProperties = _names.length;

        // Cache the number of new items adding
        uint256 numNewItems = _items.length;

        unchecked {
            // For each new property:
            for (uint256 i = 0; i < numNewProperties; ++i) {
                // Append storage space
                properties.push();

                // Compute the property id
                uint256 propertyId = numStoredProperties + i;

                // Store the property name
                properties[propertyId].name = _names[i];

                emit PropertyAdded(propertyId, _names[i]);
            }

            // For each new item:
            for (uint256 i = 0; i < numNewItems; ++i) {
                // Cache the associated property id
                uint256 _propertyId = _items[i].propertyId;

                // Offset the IDs for new properties
                if (_items[i].isNewProperty) {
                    _propertyId += numStoredProperties;
                }

                // Get the storage location of the other items for the property
                // Property IDs under the hood are offset by 1
                Item[] storage propertyItems = properties[_propertyId].items;

                // Append storage space
                propertyItems.push();

                // Get the index of the
                // Cannot underflow as the array push() ensures the length to be at least 1
                uint256 newItemIndex = propertyItems.length - 1;

                // Store the new item
                Item storage newItem = propertyItems[newItemIndex];

                // Store its associated metadata
                newItem.name = _items[i].name;
                newItem.referenceSlot = uint16(dataLength);

                emit ItemAdded(_propertyId, newItemIndex);
            }
        }
    }

    ///                                                          ///
    ///                     ATTRIBUTE GENERATION                 ///
    ///                                                          ///

    /// @notice Generates attributes for a token
    /// @dev Called by the token upon mint()
    /// @param _tokenId The ERC-721 token id
    function generate(uint256 _tokenId) external {
        // Ensure the caller is the token contract
        if (msg.sender != settings.token) revert ONLY_TOKEN();

        // Compute some randomness for the token id
        uint256 seed = _generateSeed(_tokenId);

        // Get the location to where the attributes should be stored after generation
        uint16[16] storage tokenAttributes = attributes[_tokenId];

        // Cache the number of total properties to choose from
        uint256 numProperties = properties.length;

        // Store the number of properties in the first slot of the token's array for reference
        tokenAttributes[0] = uint16(numProperties);

        // Used to store the number of items in each property
        uint256 numItems;

        unchecked {
            // For each property:
            for (uint256 i = 0; i < numProperties; ++i) {
                // Get the number of items to choose from
                numItems = properties[i].items.length;

                // Use the token's seed to selec an item
                tokenAttributes[i + 1] = uint16(seed % numItems);

                // Adjust the randomness
                seed >>= 16;
            }
        }
    }

    /// @notice The properties and query string for a generated token
    /// @param _tokenId The ERC-721 token id
    function getAttributes(uint256 _tokenId) public view returns (bytes memory aryAttributes, bytes memory queryString) {
        // Compute its query string
        queryString = abi.encodePacked(
            "?contractAddress=",
            Strings.toHexString(uint256(uint160(address(this))), 20),
            "&tokenId=",
            Strings.toString(_tokenId)
        );

        // Get the attributes for the given token
        uint16[16] memory tokenAttributes = attributes[_tokenId];

        // Cache the number of properties stored when the token was minted
        uint256 numProperties = tokenAttributes[0];

        // Ensure the token
        if (numProperties == 0) revert TOKEN_NOT_MINTED(_tokenId);

        unchecked {
            uint256 lastProperty = numProperties - 1;

            // For each of the token's properties:
            for (uint256 i = 0; i < numProperties; ++i) {
                // Check if this is the last iteration
                bool isLast = i == lastProperty;

                // Get the property data
                Property memory property = properties[i];

                // Get the index of its generated attribute for this property
                uint256 attribute = tokenAttributes[i + 1];

                // Get the associated item data
                Item memory item = property.items[attribute];

                aryAttributes = abi.encodePacked(aryAttributes, '"', property.name, '": "', item.name, '"', isLast ? "" : ",");
                queryString = abi.encodePacked(queryString, "&images=", _getItemImage(item, property.name));
            }
        }
    }

    /// @dev Generates a psuedo-random seed for a token id
    function _generateSeed(uint256 _tokenId) private view returns (uint256) {
        return uint256(keccak256(abi.encode(_tokenId, blockhash(block.number), block.coinbase, block.timestamp)));
    }

    /// @dev Encodes the string from an item in a property
    function _getItemImage(Item memory _item, string memory _propertyName) private view returns (string memory) {
        return
            UriEncode.uriEncode(
                string(
                    abi.encodePacked(ipfsData[_item.referenceSlot].baseUri, _propertyName, "/", _item.name, ipfsData[_item.referenceSlot].extension)
                )
            );
    }

    ///                                                          ///
    ///                            URIs                          ///
    ///                                                          ///

    /// @notice The contract URI
    function contractURI() external view returns (string memory) {
        return
            _encodeAsJson(
                abi.encodePacked(
                    '{"name": "',
                    settings.name,
                    '", "description": "',
                    settings.description,
                    '", "image": "',
                    settings.contractImage,
                    '"}'
                )
            );
    }

    /// @notice The token URI
    /// @param _tokenId The ERC-721 token id
    function tokenURI(uint256 _tokenId) external view returns (string memory) {
        (bytes memory aryAttributes, bytes memory queryString) = getAttributes(_tokenId);
        return
            _encodeAsJson(
                abi.encodePacked(
                    '{"name": "',
                    settings.name,
                    " #",
                    LibUintToString.toString(_tokenId),
                    '", "description": "',
                    settings.description,
                    '", "image": "',
                    settings.rendererBase,
                    queryString,
                    '", "properties": {',
                    aryAttributes,
                    "}}"
                )
            );
    }

    /// @notice Encodes s
    function _encodeAsJson(bytes memory _jsonBlob) private pure returns (string memory) {
        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(_jsonBlob)));
    }

    ///                                                          ///
    ///                                                          ///
    ///                                                          ///

    function token() external view returns (address) {
        return settings.token;
    }

    function treasury() external view returns (address) {
        return settings.treasury;
    }

    function contractImage() external view returns (string memory) {
        return settings.contractImage;
    }

    function rendererBase() external view returns (string memory) {
        return settings.rendererBase;
    }

    function description() external view returns (string memory) {
        return settings.description;
    }

    ///                                                          ///
    ///                       UPDATE SETTINGS                    ///
    ///                                                          ///

    /// @notice Updates the contract image
    /// @param _newImage The new contract image
    function updateContractImage(string memory _newImage) external onlyOwner {
        emit ContractImageUpdated(settings.contractImage, _newImage);

        settings.contractImage = _newImage;
    }

    /// @notice Updates the renderer base
    /// @param _newRendererBase The new renderer base
    function updateRendererBase(string memory _newRendererBase) external onlyOwner {
        emit RendererBaseUpdated(settings.rendererBase, _newRendererBase);

        settings.rendererBase = _newRendererBase;
    }

    ///                                                          ///
    ///                        UPGRADE CONTRACT                  ///
    ///                                                          ///

    /// @notice Ensures the caller is authorized to upgrade the contract to a valid implementation
    /// @dev This function is called in UUPS `upgradeTo` & `upgradeToAndCall`
    /// @param _impl The address of the new implementation
    function _authorizeUpgrade(address _impl) internal view override onlyOwner {
        if (!manager.isValidUpgrade(_getImplementation(), _impl)) revert INVALID_UPGRADE(_impl);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

library LibUintToString {
    uint256 private constant MAX_UINT256_STRING_LENGTH = 78;
    uint8 private constant ASCII_DIGIT_OFFSET = 48;

    /// @dev Converts a `uint256` value to a string.
    /// @param n The integer to convert.
    /// @return nstr `n` as a decimal string.
    function toString(uint256 n) 
        internal 
        pure 
        returns (string memory nstr) 
    {
        if (n == 0) {
            return "0";
        }
        // Overallocate memory
        nstr = new string(MAX_UINT256_STRING_LENGTH);
        uint256 k = MAX_UINT256_STRING_LENGTH;
        // Populate string from right to left (lsb to msb).
        while (n != 0) {
            assembly {
                let char := add(
                    ASCII_DIGIT_OFFSET,
                    mod(n, 10)
                )
                mstore(add(nstr, k), char)
                k := sub(k, 1)
                n := div(n, 10)
            }
        }
        assembly {
            // Shift pointer over to actual start of string.
            nstr := add(nstr, k)
            // Store actual string length.
            mstore(nstr, sub(MAX_UINT256_STRING_LENGTH, k))
        }
        return nstr;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

library UriEncode {
    string internal constant _TABLE = "0123456789abcdef";

    function uriEncode(string memory uri)
        internal
        pure
        returns (string memory)
    {
        bytes memory bytesUri = bytes(uri);

        string memory table = _TABLE;

        // Max size is worse case all chars need to be encoded
        bytes memory result = new bytes(3 * bytesUri.length);

        /// @solidity memory-safe-assembly
        assembly {
            // Get the lookup table
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Keep track of the final result size string length
            let resultSize := 0

            for {
                let dataPtr := bytesUri
                let endPtr := add(bytesUri, mload(bytesUri))
            } lt(dataPtr, endPtr) {

            } {
                // advance 1 byte
                dataPtr := add(dataPtr, 1)
                let input := and(mload(dataPtr), 127)

                // Check if is valid URI character
                let isValidUriChar := or(
                    and(gt(input, 96), lt(input, 134)), // a 97 / z 133
                    or(
                        and(gt(input, 64), lt(input, 91)), // A 65 / Z 90
                        or(
                          and(gt(input, 47), lt(input, 58)), // 0 48 / 9 57
                          or(
                            or(
                              eq(input, 46), // . 46
                              eq(input, 95)  // _ 95
                            ),
                            or(
                              eq(input, 45),  // - 45
                              eq(input, 126)  // ~ 126
                            )
                          )
                        )
                    )
                )

                switch isValidUriChar
                // If is valid uri character copy character over and increment the result
                case 1 {
                    mstore8(resultPtr, input)
                    resultPtr := add(resultPtr, 1)
                    resultSize := add(resultSize, 1)
                }
                // If the char is not a valid uri character, uriencode the character
                case 0 {
                    mstore8(resultPtr, 37)
                    resultPtr := add(resultPtr, 1)
                    // table[character >> 4] (take the last 4 bits)
                    mstore8(resultPtr, mload(add(tablePtr, shr(4, input))))
                    resultPtr := add(resultPtr, 1)
                    // table & 15 (take the first 4 bits)
                    mstore8(resultPtr, mload(add(tablePtr, and(input, 15))))
                    resultPtr := add(resultPtr, 1)
                    resultSize := add(resultSize, 3)
                }
            }

            // Set size of result string in memory
            mstore(result, resultSize)
        }

        return string(result);
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import {IERC1822Proxiable} from "./IERC1822.sol";
import {Address} from "../utils/Address.sol";
import {StorageSlot} from "../utils/StorageSlot.sol";

/// @notice Modified from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/proxy/utils/UUPSUpgradeable.sol
abstract contract UUPS is IERC1822Proxiable {
    ///                                                          ///
    ///                          CONSTANTS                       ///
    ///                                                          ///

    /// @dev keccak256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /// @dev keccak256 hash of "eip1967.proxy.implementation" subtracted by 1
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    ///                                                          ///
    ///                          IMMUTABLES                      ///
    ///                                                          ///

    address private immutable __self = address(this);

    ///                                                          ///
    ///                            EVENTS                        ///
    ///                                                          ///

    event Upgraded(address indexed impl);

    ///                                                          ///
    ///                            ERRORS                        ///
    ///                                                          ///

    error INVALID_UPGRADE(address impl);

    error ONLY_DELEGATECALL();

    error NO_DELEGATECALL();

    error ONLY_PROXY();

    error INVALID_UUID();

    error NOT_UUPS();

    error INVALID_TARGET();

    ///                                                          ///
    ///                          MODIFIERS                       ///
    ///                                                          ///

    modifier onlyProxy() {
        if (address(this) == __self) revert ONLY_DELEGATECALL();
        if (_getImplementation() != __self) revert ONLY_PROXY();
        _;
    }

    modifier notDelegated() {
        if (address(this) != __self) revert NO_DELEGATECALL();
        _;
    }

    ///                                                          ///
    ///                          FUNCTIONS                       ///
    ///                                                          ///

    function _authorizeUpgrade(address _impl) internal virtual;

    function proxiableUUID() external view notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    function upgradeTo(address _impl) external onlyProxy {
        _authorizeUpgrade(_impl);
        _upgradeToAndCallUUPS(_impl, "", false);
    }

    function upgradeToAndCall(address _impl, bytes memory _data) external payable onlyProxy {
        _authorizeUpgrade(_impl);
        _upgradeToAndCallUUPS(_impl, _data, true);
    }

    function _upgradeToAndCallUUPS(
        address _impl,
        bytes memory _data,
        bool _forceCall
    ) internal {
        if (StorageSlot.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(_impl);
        } else {
            try IERC1822Proxiable(_impl).proxiableUUID() returns (bytes32 slot) {
                if (slot != _IMPLEMENTATION_SLOT) revert INVALID_UUID();
            } catch {
                revert NOT_UUPS();
            }

            _upgradeToAndCall(_impl, _data, _forceCall);
        }
    }

    function _upgradeToAndCall(
        address _impl,
        bytes memory _data,
        bool _forceCall
    ) internal {
        _upgradeTo(_impl);

        if (_data.length > 0 || _forceCall) {
            Address.functionDelegateCall(_impl, _data);
        }
    }

    function _upgradeTo(address _impl) internal {
        _setImplementation(_impl);

        emit Upgraded(_impl);
    }

    function _setImplementation(address _impl) private {
        if (!Address.isContract(_impl)) revert INVALID_TARGET();

        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = _impl;
    }

    function _getImplementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import {Initializable} from "../proxy/Initializable.sol";

contract OwnableStorageV1 {
    address public owner;
    address public pendingOwner;
}

abstract contract Ownable is Initializable, OwnableStorageV1 {
    event OwnerUpdated(address indexed prevOwner, address indexed newOwner);

    event OwnerPending(address indexed owner, address indexed pendingOwner);

    event OwnerCanceled(address indexed owner, address indexed canceledOwner);

    error ONLY_OWNER();

    error ONLY_PENDING_OWNER();

    error INCORRECT_PENDING_OWNER();

    modifier onlyOwner() {
        if (msg.sender != owner) revert ONLY_OWNER();
        _;
    }

    modifier onlyPendingOwner() {
        if (msg.sender != pendingOwner) revert ONLY_PENDING_OWNER();
        _;
    }

    function __Ownable_init(address _owner) internal onlyInitializing {
        owner = _owner;

        emit OwnerUpdated(address(0), _owner);
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        emit OwnerUpdated(owner, _newOwner);

        owner = _newOwner;
    }

    function safeTransferOwnership(address _newOwner) public onlyOwner {
        pendingOwner = _newOwner;

        emit OwnerPending(owner, _newOwner);
    }

    function cancelOwnershipTransfer(address _pendingOwner) public onlyOwner {
        if (_pendingOwner != pendingOwner) revert INCORRECT_PENDING_OWNER();

        emit OwnerCanceled(owner, _pendingOwner);

        delete pendingOwner;
    }

    function acceptOwnership() public onlyPendingOwner {
        emit OwnerUpdated(owner, msg.sender);

        owner = pendingOwner;

        delete pendingOwner;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

/// @notice Modified from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Strings.sol
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    error INSUFFICIENT_HEX_LENGTH();

    function toString(uint256 _value) internal pure returns (string memory) {
        unchecked {
            if (_value == 0) {
                return "0";
            }

            uint256 temp = _value;
            uint256 digits;

            while (temp != 0) {
                digits++;

                temp /= 10;
            }

            bytes memory buffer = new bytes(digits);

            while (_value != 0) {
                digits -= 1;

                buffer[digits] = bytes1(uint8(48 + uint256(_value % 10)));

                _value /= 10;
            }

            return string(buffer);
        }
    }

    function toHexString(uint256 _value) internal pure returns (string memory) {
        unchecked {
            if (_value == 0) {
                return "0x00";
            }

            uint256 temp = _value;

            uint256 length = 0;

            while (temp != 0) {
                length++;

                temp >>= 8;
            }
            return toHexString(_value, length);
        }
    }

    function toHexString(uint256 _value, uint256 length) internal pure returns (string memory) {
        unchecked {
            uint256 bufferSize = 2 * length + 2;

            bytes memory buffer = new bytes(bufferSize);

            buffer[0] = "0";
            buffer[1] = "x";

            uint256 start = bufferSize - 1;

            for (uint256 i = start; i > 1; --i) {
                buffer[i] = _HEX_SYMBOLS[_value & 0xf];

                _value >>= 4;
            }

            if (_value != 0) revert INSUFFICIENT_HEX_LENGTH();

            return string(buffer);
        }
    }

    function toHexString(address _addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(_addr)), 20);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import {MetadataRendererTypesV1} from "../types/MetadataRendererTypesV1.sol";

contract MetadataRendererStorageV1 is MetadataRendererTypesV1 {
    Settings internal settings;

    IPFSGroup[] internal ipfsData;
    Property[] internal properties;

    mapping(uint256 => uint16[16]) internal attributes;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import {MetadataRendererTypesV1} from "./types/MetadataRendererTypesV1.sol";

interface IMetadataRenderer is MetadataRendererTypesV1 {
    ///                                                          ///
    ///                                                          ///
    ///                                                          ///

    event PropertyAdded(uint256 id, string name);

    event ItemAdded(uint256 propertyId, uint256 index);

    event ContractImageUpdated(string prevImage, string newImage);

    event RendererBaseUpdated(string prevRendererBase, string newRendererBase);

    ///                                                          ///
    ///                                                          ///
    ///                                                          ///

    error ONLY_TOKEN();

    error TOKEN_NOT_MINTED(uint256 tokenId);

    ///                                                          ///
    ///                                                          ///
    ///                                                          ///

    function initialize(
        bytes calldata initStrings,
        address token,
        address founders,
        address treasury
    ) external;

    function addProperties(
        string[] calldata names,
        ItemParam[] calldata items,
        IPFSGroup calldata ipfsGroup
    ) external;

    function updateContractImage(string memory newContractImage) external;

    function updateRendererBase(string memory newRendererBase) external;

    function propertiesCount() external view returns (uint256);

    function itemsCount(uint256 propertyId) external view returns (uint256);

    function generate(uint256 tokenId) external;

    function getAttributes(uint256 tokenId) external view returns (bytes memory aryAttributes, bytes memory queryString);

    function tokenURI(uint256 tokenId) external view returns (string memory);

    function contractURI() external view returns (string memory);

    function token() external view returns (address);

    function treasury() external view returns (address);

    function contractImage() external view returns (string memory);

    function rendererBase() external view returns (string memory);

    function description() external view returns (string memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

/// @title IManager
/// @author Rohan Kulkarni
/// @notice The Manager external interface
interface IManager {
    ///                                                          ///
    ///                                                          ///
    ///                                                          ///

    /// @notice Emitted when a DAO is deployed
    /// @param token The address of the token
    /// @param metadata The address of the metadata renderer
    /// @param auction The address of the auction
    /// @param timelock The address of the timelock
    /// @param governor The address of the governor
    event DAODeployed(address token, address metadata, address auction, address timelock, address governor);

    /// @notice Emitted when an upgrade is registered
    /// @param baseImpl The address of the previous implementation
    /// @param upgradeImpl The address of the registered upgrade
    event UpgradeRegistered(address baseImpl, address upgradeImpl);

    /// @notice Emitted when an upgrade is unregistered
    /// @param baseImpl The address of the base contract
    /// @param upgradeImpl The address of the upgrade
    event UpgradeUnregistered(address baseImpl, address upgradeImpl);

    ///                                                          ///
    ///                                                          ///
    ///                                                          ///

    error FOUNDER_REQUIRED();

    ///                                                          ///
    ///                                                          ///
    ///                                                          ///

    /// @notice The ownership config for each founder
    /// @param wallet A wallet or multisig address
    /// @param allocationFrequency The frequency of tokens minted to them (eg. Every 10 tokens to Nounders)
    /// @param vestingEnd The timestamp that their vesting will end
    struct FounderParams {
        address wallet;
        uint256 allocationFrequency;
        uint256 vestingEnd;
    }

    /// @notice The DAO's ERC-721 token and metadata config
    /// @param initStrings The encoded
    struct TokenParams {
        bytes initStrings; // name, symbol, description, contract image, renderer base
    }

    struct AuctionParams {
        uint256 reservePrice;
        uint256 duration;
    }

    struct GovParams {
        uint256 timelockDelay; // The time between a proposal and its execution
        uint256 votingDelay; // The number of blocks after a proposal that voting is delayed
        uint256 votingPeriod; // The number of blocks that voting for a proposal will take place
        uint256 proposalThresholdBPS; // The number of votes required for a voter to become a proposer
        uint256 quorumVotesBPS; // The number of votes required to support a proposal
    }

    ///                                                          ///
    ///                                                          ///
    ///                                                          ///

    function deploy(
        FounderParams[] calldata _founderParams,
        TokenParams calldata tokenParams,
        AuctionParams calldata auctionParams,
        GovParams calldata govParams
    )
        external
        returns (
            address token,
            address metadataRenderer,
            address auction,
            address timelock,
            address governor
        );

    function getAddresses(address token)
        external
        returns (
            address metadataRenderer,
            address auction,
            address timelock,
            address governor
        );

    function isValidUpgrade(address _baseImpl, address _upgradeImpl) external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

interface IERC1822Proxiable {
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

/// @notice Modified from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol
library Address {
    error INVALID_TARGET();

    error DELEGATE_CALL_FAILED();

    function isContract(address _account) internal view returns (bool rv) {
        assembly {
            rv := gt(extcodesize(_account), 0)
        }
    }

    function functionDelegateCall(address _target, bytes memory _data) internal returns (bytes memory) {
        if (!isContract(_target)) revert INVALID_TARGET();

        (bool success, bytes memory returndata) = _target.delegatecall(_data);

        return verifyCallResult(success, returndata);
    }

    function verifyCallResult(bool _success, bytes memory _returndata) internal pure returns (bytes memory) {
        if (_success) {
            return _returndata;
        } else {
            if (_returndata.length > 0) {
                assembly {
                    let returndata_size := mload(_returndata)

                    revert(add(32, _returndata), returndata_size)
                }
            } else {
                revert DELEGATE_CALL_FAILED();
            }
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

/// @notice https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/StorageSlot.sol
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import {Address} from "../utils/Address.sol";

contract InitializableStorageV1 {
    uint8 internal _initialized;
    bool internal _initializing;
}

/// @notice Modified from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/proxy/utils/Initializable.sol
abstract contract Initializable is InitializableStorageV1 {
    event Initialized(uint256 version);

    error ADDRESS_ZERO();

    error INVALID_INIT();

    error NOT_INITIALIZING();

    error ALREADY_INITIALIZED();

    modifier onlyInitializing() {
        if (!_initializing) revert NOT_INITIALIZING();
        _;
    }

    modifier initializer() {
        bool isTopLevelCall = !_initializing;

        if ((!isTopLevelCall || _initialized != 0) && (Address.isContract(address(this)) || _initialized != 1)) revert ALREADY_INITIALIZED();

        _initialized = 1;

        if (isTopLevelCall) {
            _initializing = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;

            emit Initialized(1);
        }
    }

    modifier reinitializer(uint8 _version) {
        if (_initializing || _initialized >= _version) revert ALREADY_INITIALIZED();

        _initialized = _version;

        _initializing = true;

        _;

        _initializing = false;

        emit Initialized(_version);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

interface MetadataRendererTypesV1 {
    struct ItemParam {
        uint256 propertyId;
        string name;
        bool isNewProperty;
    }

    struct IPFSGroup {
        string baseUri;
        string extension;
    }

    struct Item {
        uint16 referenceSlot;
        string name;
    }

    struct Property {
        string name;
        Item[] items;
    }

    struct Settings {
        address token;
        address treasury;
        string name;
        string description;
        string contractImage;
        string rendererBase;
    }
}