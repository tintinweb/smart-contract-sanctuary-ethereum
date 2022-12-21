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

pragma solidity ^0.8.8;

import { IERC173Internal } from '../../interfaces/IERC173Internal.sol';

interface IOwnableInternal is IERC173Internal {
    error Ownable__NotOwner();
    error Ownable__NotTransitiveOwner();
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC173 } from '../../interfaces/IERC173.sol';
import { AddressUtils } from '../../utils/AddressUtils.sol';
import { IOwnableInternal } from './IOwnableInternal.sol';
import { OwnableStorage } from './OwnableStorage.sol';

abstract contract OwnableInternal is IOwnableInternal {
    using AddressUtils for address;
    using OwnableStorage for OwnableStorage.Layout;

    modifier onlyOwner() {
        if (msg.sender != _owner()) revert Ownable__NotOwner();
        _;
    }

    modifier onlyTransitiveOwner() {
        if (msg.sender != _transitiveOwner())
            revert Ownable__NotTransitiveOwner();
        _;
    }

    function _owner() internal view virtual returns (address) {
        return OwnableStorage.layout().owner;
    }

    function _transitiveOwner() internal view virtual returns (address) {
        address owner = _owner();

        while (owner.isContract()) {
            try IERC173(owner).owner() returns (address transitiveOwner) {
                owner = transitiveOwner;
            } catch {
                return owner;
            }
        }

        return owner;
    }

    function _transferOwnership(address account) internal virtual {
        OwnableStorage.layout().setOwner(account);
        emit OwnershipTransferred(msg.sender, account);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

library OwnableStorage {
    struct Layout {
        address owner;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.Ownable');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    function setOwner(Layout storage l, address owner) internal {
        l.owner = owner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title Map implementation with enumeration functions
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts (MIT license)
 */
library EnumerableMap {
    error EnumerableMap__IndexOutOfBounds();
    error EnumerableMap__NonExistentKey();

    struct MapEntry {
        bytes32 _key;
        bytes32 _value;
    }

    struct Map {
        MapEntry[] _entries;
        // 1-indexed to allow 0 to signify nonexistence
        mapping(bytes32 => uint256) _indexes;
    }

    struct AddressToAddressMap {
        Map _inner;
    }

    struct UintToAddressMap {
        Map _inner;
    }

    function at(
        AddressToAddressMap storage map,
        uint256 index
    ) internal view returns (address, address) {
        (bytes32 key, bytes32 value) = _at(map._inner, index);

        return (
            address(uint160(uint256(key))),
            address(uint160(uint256(value)))
        );
    }

    function at(
        UintToAddressMap storage map,
        uint256 index
    ) internal view returns (uint256, address) {
        (bytes32 key, bytes32 value) = _at(map._inner, index);
        return (uint256(key), address(uint160(uint256(value))));
    }

    function contains(
        AddressToAddressMap storage map,
        address key
    ) internal view returns (bool) {
        return _contains(map._inner, bytes32(uint256(uint160(key))));
    }

    function contains(
        UintToAddressMap storage map,
        uint256 key
    ) internal view returns (bool) {
        return _contains(map._inner, bytes32(key));
    }

    function length(
        AddressToAddressMap storage map
    ) internal view returns (uint256) {
        return _length(map._inner);
    }

    function length(
        UintToAddressMap storage map
    ) internal view returns (uint256) {
        return _length(map._inner);
    }

    function get(
        AddressToAddressMap storage map,
        address key
    ) internal view returns (address) {
        return
            address(
                uint160(
                    uint256(_get(map._inner, bytes32(uint256(uint160(key)))))
                )
            );
    }

    function get(
        UintToAddressMap storage map,
        uint256 key
    ) internal view returns (address) {
        return address(uint160(uint256(_get(map._inner, bytes32(key)))));
    }

    function set(
        AddressToAddressMap storage map,
        address key,
        address value
    ) internal returns (bool) {
        return
            _set(
                map._inner,
                bytes32(uint256(uint160(key))),
                bytes32(uint256(uint160(value)))
            );
    }

    function set(
        UintToAddressMap storage map,
        uint256 key,
        address value
    ) internal returns (bool) {
        return _set(map._inner, bytes32(key), bytes32(uint256(uint160(value))));
    }

    function remove(
        AddressToAddressMap storage map,
        address key
    ) internal returns (bool) {
        return _remove(map._inner, bytes32(uint256(uint160(key))));
    }

    function remove(
        UintToAddressMap storage map,
        uint256 key
    ) internal returns (bool) {
        return _remove(map._inner, bytes32(key));
    }

    function toArray(
        AddressToAddressMap storage map
    )
        internal
        view
        returns (address[] memory keysOut, address[] memory valuesOut)
    {
        uint256 len = map._inner._entries.length;

        keysOut = new address[](len);
        valuesOut = new address[](len);

        unchecked {
            for (uint256 i; i < len; ++i) {
                keysOut[i] = address(
                    uint160(uint256(map._inner._entries[i]._key))
                );
                valuesOut[i] = address(
                    uint160(uint256(map._inner._entries[i]._value))
                );
            }
        }
    }

    function toArray(
        UintToAddressMap storage map
    )
        internal
        view
        returns (uint256[] memory keysOut, address[] memory valuesOut)
    {
        uint256 len = map._inner._entries.length;

        keysOut = new uint256[](len);
        valuesOut = new address[](len);

        unchecked {
            for (uint256 i; i < len; ++i) {
                keysOut[i] = uint256(map._inner._entries[i]._key);
                valuesOut[i] = address(
                    uint160(uint256(map._inner._entries[i]._value))
                );
            }
        }
    }

    function keys(
        AddressToAddressMap storage map
    ) internal view returns (address[] memory keysOut) {
        uint256 len = map._inner._entries.length;

        keysOut = new address[](len);

        unchecked {
            for (uint256 i; i < len; ++i) {
                keysOut[i] = address(
                    uint160(uint256(map._inner._entries[i]._key))
                );
            }
        }
    }

    function keys(
        UintToAddressMap storage map
    ) internal view returns (uint256[] memory keysOut) {
        uint256 len = map._inner._entries.length;

        keysOut = new uint256[](len);

        unchecked {
            for (uint256 i; i < len; ++i) {
                keysOut[i] = uint256(map._inner._entries[i]._key);
            }
        }
    }

    function values(
        AddressToAddressMap storage map
    ) internal view returns (address[] memory valuesOut) {
        uint256 len = map._inner._entries.length;

        valuesOut = new address[](len);

        unchecked {
            for (uint256 i; i < len; ++i) {
                valuesOut[i] = address(
                    uint160(uint256(map._inner._entries[i]._value))
                );
            }
        }
    }

    function values(
        UintToAddressMap storage map
    ) internal view returns (address[] memory valuesOut) {
        uint256 len = map._inner._entries.length;

        valuesOut = new address[](len);

        unchecked {
            for (uint256 i; i < len; ++i) {
                valuesOut[i] = address(
                    uint160(uint256(map._inner._entries[i]._value))
                );
            }
        }
    }

    function _at(
        Map storage map,
        uint256 index
    ) private view returns (bytes32, bytes32) {
        if (index >= map._entries.length)
            revert EnumerableMap__IndexOutOfBounds();

        MapEntry storage entry = map._entries[index];
        return (entry._key, entry._value);
    }

    function _contains(
        Map storage map,
        bytes32 key
    ) private view returns (bool) {
        return map._indexes[key] != 0;
    }

    function _length(Map storage map) private view returns (uint256) {
        return map._entries.length;
    }

    function _get(Map storage map, bytes32 key) private view returns (bytes32) {
        uint256 keyIndex = map._indexes[key];
        if (keyIndex == 0) revert EnumerableMap__NonExistentKey();
        unchecked {
            return map._entries[keyIndex - 1]._value;
        }
    }

    function _set(
        Map storage map,
        bytes32 key,
        bytes32 value
    ) private returns (bool) {
        uint256 keyIndex = map._indexes[key];

        if (keyIndex == 0) {
            map._entries.push(MapEntry({ _key: key, _value: value }));
            map._indexes[key] = map._entries.length;
            return true;
        } else {
            unchecked {
                map._entries[keyIndex - 1]._value = value;
            }
            return false;
        }
    }

    function _remove(Map storage map, bytes32 key) private returns (bool) {
        uint256 keyIndex = map._indexes[key];

        if (keyIndex != 0) {
            unchecked {
                MapEntry storage last = map._entries[map._entries.length - 1];

                // move last entry to now-vacant index
                map._entries[keyIndex - 1] = last;
                map._indexes[last._key] = keyIndex;
            }

            // clear last index
            map._entries.pop();
            delete map._indexes[key];

            return true;
        } else {
            return false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC173Internal } from './IERC173Internal.sol';

/**
 * @title Contract ownership standard interface
 * @dev see https://eips.ethereum.org/EIPS/eip-173
 */
interface IERC173 is IERC173Internal {
    /**
     * @notice get the ERC173 contract owner
     * @return conrtact owner
     */
    function owner() external view returns (address);

    /**
     * @notice transfer contract ownership to new account
     * @param account address of new owner
     */
    function transferOwnership(address account) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title Partial ERC173 interface needed by internal functions
 */
interface IERC173Internal {
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title Partial ERC721 interface needed by internal functions
 */
interface IERC721Internal {
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    event Approval(
        address indexed owner,
        address indexed operator,
        uint256 indexed tokenId
    );

    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC721Internal } from '../../../interfaces/IERC721Internal.sol';

/**
 * @title ERC721 base interface
 */
interface IERC721BaseInternal is IERC721Internal {
    error ERC721Base__NotOwnerOrApproved();
    error ERC721Base__SelfApproval();
    error ERC721Base__BalanceQueryZeroAddress();
    error ERC721Base__ERC721ReceiverNotImplemented();
    error ERC721Base__InvalidOwner();
    error ERC721Base__MintToZeroAddress();
    error ERC721Base__NonExistentToken();
    error ERC721Base__NotTokenOwner();
    error ERC721Base__TokenAlreadyMinted();
    error ERC721Base__TransferToZeroAddress();
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { UintUtils } from './UintUtils.sol';

library AddressUtils {
    using UintUtils for uint256;

    error AddressUtils__InsufficientBalance();
    error AddressUtils__NotContract();
    error AddressUtils__SendValueFailed();

    function toString(address account) internal pure returns (string memory) {
        return uint256(uint160(account)).toHexString(20);
    }

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable account, uint256 amount) internal {
        (bool success, ) = account.call{ value: amount }('');
        if (!success) revert AddressUtils__SendValueFailed();
    }

    function functionCall(
        address target,
        bytes memory data
    ) internal returns (bytes memory) {
        return
            functionCall(target, data, 'AddressUtils: failed low-level call');
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory error
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, error);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                'AddressUtils: failed low-level call with value'
            );
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory error
    ) internal returns (bytes memory) {
        if (value > address(this).balance)
            revert AddressUtils__InsufficientBalance();
        return _functionCallWithValue(target, data, value, error);
    }

    /**
     * @notice execute arbitrary external call with limited gas usage and amount of copied return data
     * @dev derived from https://github.com/nomad-xyz/ExcessivelySafeCall (MIT License)
     * @param target recipient of call
     * @param gasAmount gas allowance for call
     * @param value native token value to include in call
     * @param maxCopy maximum number of bytes to copy from return data
     * @param data encoded call data
     * @return success whether call is successful
     * @return returnData copied return data
     */
    function excessivelySafeCall(
        address target,
        uint256 gasAmount,
        uint256 value,
        uint16 maxCopy,
        bytes memory data
    ) internal returns (bool success, bytes memory returnData) {
        returnData = new bytes(maxCopy);

        assembly {
            // execute external call via assembly to avoid automatic copying of return data
            success := call(
                gasAmount,
                target,
                value,
                add(data, 0x20),
                mload(data),
                0,
                0
            )

            // determine whether to limit amount of data to copy
            let toCopy := returndatasize()

            if gt(toCopy, maxCopy) {
                toCopy := maxCopy
            }

            // store the length of the copied bytes
            mstore(returnData, toCopy)

            // copy the bytes from returndata[0:toCopy]
            returndatacopy(add(returnData, 0x20), 0, toCopy)
        }
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory error
    ) private returns (bytes memory) {
        if (!isContract(target)) revert AddressUtils__NotContract();

        (bool success, bytes memory returnData) = target.call{ value: value }(
            data
        );

        if (success) {
            return returnData;
        } else if (returnData.length > 0) {
            assembly {
                let returnData_size := mload(returnData)
                revert(add(32, returnData), returnData_size)
            }
        } else {
            revert(error);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title utility functions for uint256 operations
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts/ (MIT license)
 */
library UintUtils {
    error UintUtils__InsufficientHexLength();

    bytes16 private constant HEX_SYMBOLS = '0123456789abcdef';

    function add(uint256 a, int256 b) internal pure returns (uint256) {
        return b < 0 ? sub(a, -b) : a + uint256(b);
    }

    function sub(uint256 a, int256 b) internal pure returns (uint256) {
        return b < 0 ? add(a, -b) : a - uint256(b);
    }

    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return '0';
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

    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return '0x00';
        }

        uint256 length = 0;

        for (uint256 temp = value; temp != 0; temp >>= 8) {
            unchecked {
                length++;
            }
        }

        return toHexString(value, length);
    }

    function toHexString(
        uint256 value,
        uint256 length
    ) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = '0';
        buffer[1] = 'x';

        unchecked {
            for (uint256 i = 2 * length + 1; i > 1; --i) {
                buffer[i] = HEX_SYMBOLS[value & 0xf];
                value >>= 4;
            }
        }

        if (value != 0) revert UintUtils__InsufficientHexLength();

        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

library ScapesERC721MetadataStorage {
    bytes32 internal constant STORAGE_SLOT =
        keccak256("scapes.storage.ERC721Metadata");

    struct Layout {
        string name;
        string symbol;
        string description;
        string externalBaseURI;
        address scapeBound;
    }

    function layout() internal pure returns (Layout storage d) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            d.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
// Based on solidstate @solidstate/contracts/token/ERC721/base/ERC721BaseStorage.sol
// Changes made:
//  - replace holderTokens with holderBalances, this removes the
//    option to easily upgrade to ERC721Enumerable but lowers gas cost by ~45k per mint
//  - add holderBalancesMerges to separetly track the balance of merged scape tokens

pragma solidity ^0.8.8;

import {EnumerableMap} from "@solidstate/contracts/data/EnumerableMap.sol";

library ERC721BaseStorage {
    using EnumerableMap for EnumerableMap.UintToAddressMap;

    bytes32 internal constant STORAGE_SLOT =
        keccak256("scapes.storage.ERC721Base");

    struct Layout {
        EnumerableMap.UintToAddressMap tokenOwners;
        mapping(address => uint256) holderBalances;
        mapping(address => uint256) holderBalancesMerges;
        mapping(uint256 => address) tokenApprovals;
        mapping(address => mapping(address => bool)) operatorApprovals;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    function exists(Layout storage l, uint256 tokenId)
        internal
        view
        returns (bool)
    {
        return l.tokenOwners.contains(tokenId);
    }

    function totalSupply(Layout storage l) internal view returns (uint256) {
        return l.tokenOwners.length();
    }

    function tokenByIndex(Layout storage l, uint256 index)
        internal
        view
        returns (uint256)
    {
        (uint256 tokenId, ) = l.tokenOwners.at(index);
        return tokenId;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

/// @title Archive of Elements of the ScapeLand
/// @author jalil.eth, akuti.eth | scapes.eth
interface IScapesArchive {
    /// @title Metadata for an archived element from ScapeLand
    /// @param format The format in which the data is stored (PNG/SVG/...)
    /// @param collectionId Documented off chain
    /// @param isObject False implies background
    /// @param width The true pixel width of the element
    /// @param height The true pixel height of the element
    /// @param x The default offset from the left
    /// @param y The default offset from the top
    /// @param zIndex Default z-index of the element
    /// @param canFlipX The element can be flipped horizontally
    /// @param canFlipY Can be flipped vertically without obscuring content
    /// @param seamlessX The element can be tiled horizontally
    /// @param seamlessY The element can be tiled vertically
    /// @param addedAt Automatically freezes after 1 week
    struct ElementMetadata {
        uint8 format;
        uint16 collectionId;
        bool isObject;
        uint16 width;
        uint16 height;
        int16 x;
        int16 y;
        uint8 zIndex;
        bool canFlipX;
        bool canFlipY;
        bool seamlessX;
        bool seamlessY;
        uint64 addedAt;
    }

    /// @title An archived element from ScapeLand
    /// @param data The raw data (normally the image)
    /// @param metadata The elements' configuration data
    struct Element {
        bytes data;
        ElementMetadata metadata;
    }

    /// @notice Get the bare data for an archived item
    /// @param category The category of the element
    /// @param name The identifying name of the element
    function getElement(string memory category, string memory name)
        external
        view
        returns (Element memory item);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

library ScapesMerge {
    struct MergePart {
        uint256 tokenId;
        bool flipX;
        bool flipY;
    }

    struct Merge {
        MergePart[] parts;
        bool isFade;
    }

    function toId(Merge calldata merge_)
        internal
        pure
        returns (uint256 mergeId)
    {
        for (uint256 i = 0; i < merge_.parts.length; i++) {
            MergePart memory part = merge_.parts[i];
            uint256 partDNA = part.tokenId;
            if (part.flipX) {
                partDNA |= 1 << 14;
            }
            if (part.flipY) {
                partDNA |= 1 << 15;
            }
            mergeId |= partDNA << (16 * i);
        }
        mergeId = mergeId << 1;
        if (merge_.isFade) {
            mergeId |= 1;
        }
    }

    function fromId(uint256 mergeId)
        internal
        pure
        returns (Merge memory merge_)
    {
        MergePart[15] memory parts;
        merge_.isFade = mergeId & 1 > 0;
        mergeId >>= 1;
        uint256 numParts;
        for (uint256 i = 0; i < 15; i++) {
            MergePart memory part = parts[i];
            uint256 offset = 16 * i;
            uint256 filter = (1 << (offset + 14)) - (1 << offset);
            part.tokenId = (mergeId & filter) >> offset;
            if (part.tokenId == 0) {
                break;
            }
            part.flipX = mergeId & (1 << (offset + 14)) > 0;
            part.flipY = mergeId & (1 << (offset + 15)) > 0;
            numParts++;
        }
        merge_.parts = new MergePart[](numParts);
        for (uint256 i = 0; i < numParts; i++) {
            merge_.parts[i] = parts[i];
        }
    }

    function getSortedTokenIds(Merge memory merge_, bool unique)
        internal
        pure
        returns (uint256[] memory)
    {
        uint256[] memory tokenIds = new uint256[](merge_.parts.length);
        for (uint256 i = 0; i < merge_.parts.length; i++) {
            tokenIds[i] = merge_.parts[i].tokenId;
        }
        _quickSort(tokenIds, int256(0), int256(tokenIds.length - 1));
        if (!unique) {
            return tokenIds;
        }
        uint256 uniqueCounter;
        uint256 lastTokenId;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (tokenIds[i] != lastTokenId) uniqueCounter++;
            lastTokenId = tokenIds[i];
        }

        uint256[] memory uniqueTokenIds = new uint256[](uniqueCounter);
        uniqueCounter = 0;
        lastTokenId = 0;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (tokenIds[i] != lastTokenId) {
                uniqueTokenIds[uniqueCounter] = tokenIds[i];
                uniqueCounter++;
            }
        }
        return uniqueTokenIds;
    }

    function hasNoFlip(Merge memory merge_) internal pure returns (bool) {
        for (uint256 i = 0; i < merge_.parts.length; i++) {
            if (merge_.parts[i].flipX || merge_.parts[i].flipY) return false;
        }
        return true;
    }

    // Sorts in-place
    function _quickSort(
        uint256[] memory arr,
        int256 left,
        int256 right
    ) internal pure {
        int256 i = left;
        int256 j = right;
        if (i == j) return;
        uint256 pivot = arr[uint256(left + (right - left) / 2)];
        while (i <= j) {
            while (arr[uint256(i)] < pivot) i++;
            while (pivot < arr[uint256(j)]) j--;
            if (i <= j) {
                (arr[uint256(i)], arr[uint256(j)]) = (
                    arr[uint256(j)],
                    arr[uint256(i)]
                );
                i++;
                j--;
            }
        }
        if (left < j) _quickSort(arr, left, j);
        if (i < right) _quickSort(arr, i, right);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {OwnableInternal} from "@solidstate/contracts/access/ownable/OwnableInternal.sol";
import {IERC721BaseInternal} from "@solidstate/contracts/token/ERC721/base/IERC721BaseInternal.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
import {ScapesMetadataInternal, ScapesMetadataStorage, ScapesERC721MetadataStorage} from "./ScapesMetadataInternal.sol";
import {ScapesMerge} from "./ScapesMerge.sol";
import {ERC721BaseStorage} from "../ERC721/solidstate/ERC721BaseStorage.sol";

/// @title ScapesMetadata
/// @author akuti.eth | scapes.eth
/// @notice Adds metadata information to Scapes
/// @dev A facet to add ERC721 metadata extension and additional metadata functions to Scapes
contract ScapesMetadata is
    ScapesMetadataInternal,
    OwnableInternal,
    IERC721BaseInternal
{
    using ERC721BaseStorage for ERC721BaseStorage.Layout;

    /**
     * @notice Get attributes for given Scape
     * @param tokenId token id
     * @return scape struct containing scape attributes
     */
    function getScape(uint256 tokenId)
        external
        view
        returns (ScapesMetadataInternal.Scape memory)
    {
        return _getScape(tokenId, false);
    }

    /**
     * @notice Get image for given token (1-10k scapes, 10k+ merges)
     * @param tokenId token id
     * @return image data uri of an svg image
     */
    function getScapeImage(uint256 tokenId)
        external
        view
        returns (string memory)
    {
        return _getImage(tokenId, true, 0);
    }

    /**
     * @notice Get image for given token (1-10k scapes, 10k+ merges)
     * @param tokenId token id
     * @param base64_ Whether to encode the svg with base64
     * @param scale Image scale multiplier (set to 0 for auto scaling)
     * @return image data uri of an svg image
     */
    function getScapeImage(
        uint256 tokenId,
        bool base64_,
        uint256 scale
    ) external view returns (string memory) {
        return _getImage(tokenId, base64_, scale);
    }

    function convertMergeId(uint256 tokenId)
        external
        pure
        returns (ScapesMerge.Merge memory)
    {
        return ScapesMerge.fromId(tokenId);
    }

    /**
     * @notice Get generated URI for given token
     * @return token URI
     */
    function tokenURI(uint256 tokenId) public view returns (string memory) {
        if (!ERC721BaseStorage.layout().exists(tokenId))
            revert ERC721Base__NonExistentToken();
        return _getJson(tokenId, true);
    }

    /**
     * @notice Get token name
     * @return token name
     */
    function name() public view returns (string memory) {
        return ScapesERC721MetadataStorage.layout().name;
    }

    /**
     * @notice Get token symbol
     * @return token symbol
     */
    function symbol() public view returns (string memory) {
        return ScapesERC721MetadataStorage.layout().symbol;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
import {UintUtils} from "@solidstate/contracts/utils/UintUtils.sol";
import {ScapesMetadataStorage} from "./ScapesMetadataStorage.sol";
import {IScapesArchive} from "./IScapesArchive.sol";
import {ScapesMerge} from "./ScapesMerge.sol";
import {strings} from "./strings.sol";
import {ScapesERC721MetadataStorage} from "../ERC721/ScapesERC721MetadataStorage.sol";

/// @title ScapesMetadataInternal
/// @author akuti.eth
/// @notice The functionality to create Scapes metadata.
/// @dev Internal functions to create Scape and merge images and json metadata.
abstract contract ScapesMetadataInternal {
    using UintUtils for uint256;
    using ScapesMerge for ScapesMerge.Merge;
    using strings for *;

    struct Scape {
        string[] traitNames;
        string[] traitValues;
        uint256 date;
    }

    uint256 internal constant SCAPE_WIDTH = 72;
    address internal constant ARCHIVE_ADDRESS =
        0x37292Aec4BB789A3b35b736BB6F06cca69EbFA46;
    IScapesArchive internal constant _archive = IScapesArchive(ARCHIVE_ADDRESS);
    bytes internal constant LANDMARK_ORDER = bytes("MTPARBC");

    /// @dev Get the DNA of a scape
    /// @param tokenId token id
    function _getDNA(uint256 tokenId) internal view returns (uint256) {
        uint256 i = tokenId % 3;
        uint256 filter = (1 << ((i + 1) * 85)) - (1 << (i * 85));
        return
            (ScapesMetadataStorage.layout().scapeData[tokenId / 3] & filter) >>
            (i * 85);
    }

    /// @dev Create a Scape with a list of its attributes
    /// @param tokenId token id
    /// @param withVairations whether to include trait variations
    function _getScape(uint256 tokenId, bool withVairations)
        internal
        view
        returns (Scape memory scape)
    {
        ScapesMetadataStorage.Layout storage d = ScapesMetadataStorage.layout();
        uint256 dna = _getDNA(tokenId);
        uint256 counter;
        uint256 traitIdx;
        ScapesMetadataStorage.Trait memory trait;
        strings.slice memory dot = ".".toSlice();

        string[10] memory traitNames;
        string[10] memory traitValues;

        for (uint256 i = 0; i < d.traitNames.length; i++) {
            trait = d.traits[d.traitNames[i]];
            traitIdx = (dna & trait.filter) >> trait.shift;
            if (
                traitIdx >= trait.startIdx &&
                traitIdx - trait.startIdx < trait.names.length
            ) {
                traitNames[counter] = d.traitNames[i];
                string memory traitValue = trait.names[
                    traitIdx - trait.startIdx
                ];
                if (!withVairations && bytes(traitValue)[1] == ".") {
                    traitValue = traitValue.toSlice().rsplit(dot).toString();
                }
                traitValues[counter] = traitValue;
                counter++;
            }
        }

        // handle 1001 special case
        if (tokenId == 1001) {
            traitNames[counter] = "Monuments";
            traitValues[counter] = "Skull";
            counter++;
        }

        scape.traitNames = new string[](counter);
        scape.traitValues = new string[](counter);
        for (uint256 i = 0; i < counter; i++) {
            scape.traitNames[i] = traitNames[i];
            scape.traitValues[i] = traitValues[i];
        }
        scape.date = (dna & 0x3fffffff) + 1643828103;
    }

    /**
     * @notice get image for given token (1-10k scapes, 10k+ merges)
     * @param tokenId token id
     * @param base64_ Whether to encode the svg with base64
     * @param scale Image scale multiplier (set to 0 for auto scaling)
     * @return image data uri of an svg image
     */
    function _getImage(
        uint256 tokenId,
        bool base64_,
        uint256 scale
    ) internal view returns (string memory) {
        if (tokenId > 10_000) {
            ScapesMerge.Merge memory merge = ScapesMerge.fromId(tokenId);
            return _getMergeImage(merge, base64_, scale);
        } else {
            ScapesMerge.Merge memory merge;
            merge.parts = new ScapesMerge.MergePart[](1);
            merge.parts[0] = ScapesMerge.MergePart(tokenId, false, false);
            return _getMergeImage(merge, base64_, scale);
        }
    }

    /// @dev Get the merged token image as a data uri
    /// @param merge a merge object which specifies scapes and settings
    /// @param base64_ Whether to encode the svg with base64
    /// @param scale Image scale multiplier (set to 0 for auto scaling)
    function _getMergeImage(
        ScapesMerge.Merge memory merge,
        bool base64_,
        uint256 scale
    ) internal view returns (string memory) {
        // Init variables
        ScapesMetadataStorage.Layout storage d = ScapesMetadataStorage.layout();
        ScapesMerge.MergePart[] memory parts = merge.parts;
        (Scape[] memory scapes, int256[2][] memory xOffsets) = _loadScapeData(
            parts
        );
        uint256[] memory offsetIdxs = new uint256[](parts.length);

        // build svg string
        string memory s = _svgInit(parts.length, scale);
        for (uint256 traitIdx = 0; traitIdx < d.traitNames.length; traitIdx++) {
            // required to translate between X.Name and descriptive name of Scapes Archive
            TraitSVGImageArgs memory args;
            args.traitName = d.traitNames[traitIdx];
            for (uint256 scapeIdx = 0; scapeIdx < parts.length; scapeIdx++) {
                Scape memory scape = scapes[scapeIdx];
                args.traitValue = _getScapeTraitValue(scape, args.traitName);
                if (_empty(args.traitValue)) {
                    continue;
                }

                args.xOffset = int256(SCAPE_WIDTH * scapeIdx);
                if (d.traits[args.traitName].isLandmark) {
                    args.xOffset += xOffsets[scapeIdx][offsetIdxs[scapeIdx]];
                    offsetIdxs[scapeIdx]++;
                }
                if (bytes(args.traitValue)[1] == "F") {
                    // check for UFO
                    args.yOffset = _getUFOOffset(scape);
                } else {
                    args.yOffset = 0;
                }
                args.flipX = parts[scapeIdx].flipX;
                args.centerX = SCAPE_WIDTH * scapeIdx + 36;
                s = string.concat(s, _traitSvgImage(args));
                if (merge.isFade && !d.traits[args.traitName].isLandmark) {
                    if (
                        (!args.flipX && scapeIdx > 0) ||
                        (args.flipX && scapeIdx < parts.length - 1)
                    ) {
                        s = string.concat(
                            s,
                            _traitSvgImage(
                                args,
                                "Fades",
                                string.concat(args.traitValue, " left")
                            )
                        );
                    }
                    if (
                        (args.flipX && scapeIdx > 0) ||
                        (!args.flipX && scapeIdx < parts.length - 1)
                    ) {
                        s = string.concat(
                            s,
                            _traitSvgImage(
                                args,
                                "Fades",
                                string.concat(args.traitValue, " right")
                            )
                        );
                    }
                }
                if (
                    parts[scapeIdx].tokenId == 1001 &&
                    bytes(args.traitName)[0] == "M"
                ) {
                    // handle 1001 special case
                    args.xOffset =
                        int256(SCAPE_WIDTH * scapeIdx) +
                        xOffsets[scapeIdx][offsetIdxs[scapeIdx]];
                    s = string.concat(
                        s,
                        _traitSvgImage(args, "Monuments", "Skull")
                    );
                }
            }
        }
        s = string.concat(s, "</svg>");
        if (base64_) {
            return
                string.concat(
                    "data:image/svg+xml;base64,",
                    Base64.encode(bytes(s))
                );
        }
        return string.concat("data:image/svg+xml;utf8,", s);
    }

    /// @dev Get the token json as a data uri
    /// @param tokenId Token ID of a scape
    /// @param base64_ Whether to encode the json with base64
    function _getJson(uint256 tokenId, bool base64_)
        internal
        view
        returns (string memory)
    {
        if (tokenId > 10_000) {
            return _getJsonMerge(tokenId, base64_);
        }
        ScapesERC721MetadataStorage.Layout
            storage md = ScapesERC721MetadataStorage.layout();
        string memory tokenIdStr = tokenId.toString();

        string memory tokenURI = string.concat(
            '{"name":"Scape #',
            tokenIdStr,
            '","description":"',
            md.description,
            '","image":"',
            _getImage(tokenId, true, 15),
            '","external_url":"',
            md.externalBaseURI,
            tokenIdStr,
            '","attributes":',
            _attributeJson(tokenId),
            "}"
        );
        if (base64_) {
            return
                string.concat(
                    "data:application/json;base64,",
                    Base64.encode(bytes(tokenURI))
                );
        }
        return string.concat("data:application/json;utf8,", tokenURI);
    }

    function _getJsonMerge(uint256 mergeId, bool base64_)
        internal
        view
        returns (string memory)
    {
        ScapesERC721MetadataStorage.Layout
            storage md = ScapesERC721MetadataStorage.layout();
        ScapesMerge.Merge memory merge_ = ScapesMerge.fromId(mergeId);
        uint256[] memory tokenIds = merge_.getSortedTokenIds(true);

        string memory tokenURI = string.concat(
            '{"name":"',
            _mergeName(tokenIds),
            '","description":"',
            md.description,
            _mergeDescription(merge_, tokenIds),
            '","image":"',
            _getMergeImage(merge_, true, 15),
            '","external_url":"',
            md.externalBaseURI,
            mergeId.toString(),
            '","attributes":',
            _mergeAttributeJson(merge_, tokenIds),
            "}"
        );
        if (base64_) {
            return
                string.concat(
                    "data:application/json;base64,",
                    Base64.encode(bytes(tokenURI))
                );
        }
        return string.concat("data:application/json;utf8,", tokenURI);
    }

    function _mergeName(uint256[] memory tokenIds)
        internal
        pure
        returns (string memory)
    {
        if (tokenIds.length == 2) {
            return
                string.concat(
                    "Scape Diptych of #",
                    tokenIds[0].toString(),
                    " and #",
                    tokenIds[1].toString()
                );
        }
        if (tokenIds.length == 3) {
            return
                string.concat(
                    "Scape Triptych of #",
                    tokenIds[0].toString(),
                    ", #",
                    tokenIds[1].toString(),
                    " and #",
                    tokenIds[2].toString()
                );
        }
        return
            string.concat(
                "Scape Polyptych of #",
                tokenIds[0].toString(),
                " and ",
                (tokenIds.length - 1).toString(),
                " more Scapes"
            );
    }

    function _mergeDescription(
        ScapesMerge.Merge memory merge_,
        uint256[] memory tokenIds
    ) internal pure returns (string memory s) {
        s = "\\nThis Scape Merge contains the following Scapes: ";
        s = string.concat(s, "#", tokenIds[0].toString());
        for (uint256 i = 1; i < tokenIds.length; i++) {
            s = string.concat(s, ", #", tokenIds[i].toString());
        }
        // add bot command
        s = string.concat(
            s,
            "\\n\\n`!scape ",
            merge_.isFade ? "fade" : "merge"
        );
        for (uint256 i = 0; i < merge_.parts.length; i++) {
            s = string.concat(
                s,
                " ",
                merge_.parts[i].tokenId.toString(),
                merge_.parts[i].flipX ? "h" : "",
                merge_.parts[i].flipY ? "v" : ""
            );
        }
        s = string.concat(s, "`");
    }

    function _mergeAttributeJson(
        ScapesMerge.Merge memory merge_,
        uint256[] memory tokenIds
    ) internal pure returns (string memory s) {
        s = "[";
        s = _traitJson(s, "Type", merge_.isFade ? "Fade" : "Merge", "");
        s = string.concat(s, ",");
        s = _traitJson(s, "Mirror", merge_.hasNoFlip() ? "No" : "Yes", "");
        s = string.concat(s, ",");
        s = _traitJson(s, "Size", merge_.parts.length, "");
        for (uint256 i = 0; i < tokenIds.length; i++) {
            s = string.concat(s, ",");
            s = _traitJson(
                s,
                "Scape",
                string.concat("#", tokenIds[i].toString()),
                ""
            );
        }
        s = string.concat(s, "]");
    }

    function _svgInit(uint256 n, uint256 scale)
        internal
        pure
        returns (string memory)
    {
        return
            string.concat(
                '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ',
                (SCAPE_WIDTH * n).toString(),
                ' 24" height="',
                scale < 1 ? "100%" : (24 * scale).toString(),
                '" width="',
                scale < 1 ? "100%" : (SCAPE_WIDTH * n * scale).toString(),
                '" style="image-rendering:pixelated;width:100%;height:auto;background-color:black;" preserveAspectRatio="xMaxYMin meet">'
            );
    }

    function _loadScapeData(ScapesMerge.MergePart[] memory parts)
        internal
        view
        returns (Scape[] memory scapes, int256[2][] memory xOffsets)
    {
        scapes = new Scape[](parts.length);
        xOffsets = new int256[2][](parts.length);
        for (uint256 i = 0; i < parts.length; i++) {
            scapes[i] = _getScape(parts[i].tokenId, true);
            xOffsets[i] = _landmarkOffsets(scapes[i]);
        }
    }

    function _getScapeTraitIdx(Scape memory scape, string memory traitName)
        internal
        pure
        returns (uint256)
    {
        for (uint256 i = 0; i < scape.traitNames.length; i++) {
            if (
                keccak256(bytes(scape.traitNames[i])) ==
                keccak256(bytes(traitName))
            ) {
                return i;
            }
        }
        return 404;
    }

    function _getScapeTraitValue(Scape memory scape, string memory traitName)
        internal
        view
        returns (string memory)
    {
        bytes32 traitNameHash = keccak256(bytes(traitName));
        if (
            traitNameHash == keccak256(bytes("Topology")) ||
            traitNameHash == keccak256(bytes("Surface"))
        ) {
            return "";
        }

        uint256 i = _getScapeTraitIdx(scape, traitName);
        if (i == 404) {
            return "";
        }

        string memory traitValue = ScapesMetadataStorage
            .layout()
            .variationNames[scape.traitValues[i]];
        if (_empty(traitValue)) {
            traitValue = scape.traitValues[i];
        }

        if (
            traitNameHash == keccak256(bytes("Planet")) ||
            traitNameHash == keccak256(bytes("Landscape"))
        ) {
            traitValue = string.concat(
                scape.traitValues[i - 1],
                " ",
                scape.traitValues[i]
            );
        }
        return traitValue;
    }

    function _getLandmarkOrder(string memory landmark)
        internal
        pure
        returns (uint256)
    {
        for (uint256 i = 0; i < LANDMARK_ORDER.length; i++) {
            if (bytes(landmark)[0] == LANDMARK_ORDER[i]) {
                return i;
            }
        }
        return 404;
    }

    function _landmarkOffsets(Scape memory scape)
        internal
        view
        returns (int256[2] memory out)
    {
        ScapesMetadataStorage.Layout storage d = ScapesMetadataStorage.layout();
        uint256 nrObjects;
        string memory firstLandmark;
        bool flipLandmarks;
        string memory landscape;
        for (uint256 i = 0; i < scape.traitNames.length; i++) {
            if (d.traits[scape.traitNames[i]].isLandmark) {
                nrObjects++;
                if (nrObjects == 1) {
                    firstLandmark = scape.traitNames[i];
                } else {
                    flipLandmarks =
                        _getLandmarkOrder(firstLandmark) >
                        _getLandmarkOrder(scape.traitNames[i]);
                }
            }
            if (
                keccak256(bytes(scape.traitNames[i])) ==
                keccak256(bytes("Landscape"))
            ) {
                landscape = scape.traitValues[i];
            }
        }
        int256[] memory offsets = d.landmarkOffsets[landscape][nrObjects];
        for (uint256 i = 0; i < offsets.length; i++) {
            out[i] = offsets[flipLandmarks ? offsets.length - i - 1 : i];
        }
    }

    function _attributeJson(uint256 tokenId)
        internal
        view
        returns (string memory out)
    {
        Scape memory scape = _getScape(tokenId, false);
        out = "[";
        for (uint256 i = 0; i < scape.traitNames.length; i++) {
            out = string.concat(
                _traitJson(out, scape.traitNames[i], scape.traitValues[i], ""),
                ","
            );
        }
        out = string.concat(_traitJson(out, "date", scape.date, "date"), "]");
    }

    struct TraitSVGImageArgs {
        string traitName;
        string traitValue;
        int256 xOffset;
        int256 yOffset;
        bool flipX;
        uint256 centerX;
    }

    function _traitSvgImage(TraitSVGImageArgs memory args)
        internal
        view
        returns (string memory)
    {
        return _traitSvgImage(args, args.traitName, args.traitValue);
    }

    function _traitSvgImage(
        TraitSVGImageArgs memory args,
        string memory traitName,
        string memory traitValue
    ) internal view returns (string memory s) {
        IScapesArchive.Element memory element = _archive.getElement(
            traitName,
            traitValue
        );
        if (element.data.length == 0) {
            return s;
        }
        int256 xOffset = args.xOffset + element.metadata.x;
        int256 yOffset = args.yOffset + element.metadata.y;
        s = string.concat(
            '<image x="',
            xOffset < 0 ? "-" : "",
            _abs(xOffset).toString(),
            '" y="',
            yOffset < 0 ? "-" : "",
            _abs(yOffset).toString(),
            '" width="',
            uint256(element.metadata.width).toString(),
            '" height="',
            uint256(element.metadata.height).toString()
        );
        if (args.flipX) {
            s = string.concat(
                s,
                '" transform="scale (-1, 1)" transform-origin="',
                args.centerX.toString()
            );
        }
        s = string.concat(
            s,
            '" href="data:image/png;base64,',
            Base64.encode(element.data),
            '"/>'
        );
    }

    function _traitSvgFadeImage(TraitSVGImageArgs memory args, bool left)
        internal
        view
        returns (string memory s)
    {
        IScapesArchive.Element memory element = _archive.getElement(
            "Fades",
            string.concat(args.traitValue, left ? " left" : " right")
        );
        if (element.data.length > 0) {
            int256 xOffset = args.xOffset + element.metadata.x;
            s = string.concat(
                '<image x="',
                xOffset < 0 ? "-" : "",
                _abs(xOffset).toString()
            );
            if (args.flipX) {
                s = string.concat(
                    s,
                    '" transform="scale (-1, 1)" transform-origin="',
                    args.centerX.toString()
                );
            }
            s = string.concat(
                s,
                '" href="data:image/png;base64,',
                Base64.encode(element.data),
                '"/>'
            );
        }
    }

    function _getRawScapeTraitValue(Scape memory scape, string memory traitName)
        internal
        pure
        returns (string memory)
    {
        uint256 traitIdx = _getScapeTraitIdx(scape, traitName);
        if (traitIdx == 404) {
            return "";
        }
        return scape.traitValues[traitIdx];
    }

    function _hasTrait(Scape memory scape, string memory traitName)
        internal
        pure
        returns (bool)
    {
        uint256 traitIdx = _getScapeTraitIdx(scape, traitName);
        return traitIdx != 404;
    }

    function _hasTrait(
        Scape memory scape,
        string memory traitName,
        string memory traitValue
    ) internal pure returns (bool) {
        uint256 traitIdx = _getScapeTraitIdx(scape, traitName);
        if (traitIdx == 404) {
            return false;
        }
        return
            keccak256(bytes(traitValue)) ==
            keccak256(bytes(scape.traitValues[traitIdx]));
    }

    function _getUFOOffset(Scape memory scape) internal pure returns (int256) {
        if (
            !(_hasTrait(scape, "Planet") ||
                _hasTrait(scape, "Landscape") ||
                _hasTrait(scape, "City"))
        ) {
            if (_hasTrait(scape, "Rocketry", "0.UFO")) {
                return 4;
            }
            return 2;
        }
        return 0;
    }

    function _traitJson(
        string memory s,
        string memory category,
        string memory trait,
        string memory display
    ) internal pure returns (string memory) {
        if (bytes(display).length > 0)
            s = string.concat(s, '{"display_type": "', display, '",');
        else s = string.concat(s, "{");
        return
            string.concat(
                s,
                '"trait_type":"',
                category,
                '","value":"',
                trait,
                '"}'
            );
    }

    function _traitJson(
        string memory s,
        string memory category,
        uint256 trait,
        string memory display
    ) internal pure returns (string memory) {
        if (bytes(display).length > 0)
            s = string.concat(s, '{"display_type": "', display, '",');
        else s = string.concat(s, "{");
        return
            string.concat(
                s,
                '"trait_type":"',
                category,
                '","value":',
                trait.toString(),
                "}"
            );
    }

    function _empty(string memory s) internal pure returns (bool) {
        return bytes(s).length == 0;
    }

    function _abs(int256 x) internal pure returns (uint256) {
        return uint256(x < 0 ? -x : x);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {strings} from "./strings.sol";

library ScapesMetadataStorage {
    using strings for *;

    bytes32 internal constant STORAGE_SLOT =
        keccak256("scapes.storage.Metadata");

    struct Trait {
        uint128 filter;
        uint8 shift;
        uint8 startIdx;
        bool isLandmark;
        string[] names;
    }

    struct Layout {
        uint256[3334] scapeData;
        mapping(string => mapping(uint256 => int256[])) landmarkOffsets;
        mapping(string => string) variationNames;
        string[16] traitNames;
        mapping(string => Trait) traits;
    }

    function layout() internal pure returns (Layout storage d) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            d.slot := slot
        }
    }
}

// SPDX-License-Identifier:	Apache-2.0
/*
 * @title String & slice utility library for Solidity contracts.
 * @author Nick Johnson <[email protected]>
 *
 * @dev Functionality in this library is largely implemented using an
 *      abstraction called a 'slice'. A slice represents a part of a string -
 *      anything from the entire string to a single character, or even no
 *      characters at all (a 0-length slice). Since a slice only has to specify
 *      an offset and a length, copying and manipulating slices is a lot less
 *      expensive than copying and manipulating the strings they reference.
 *
 *      To further reduce gas costs, most functions on slice that need to return
 *      a slice modify the original one instead of allocating a new one; for
 *      instance, `s.split(".")` will return the text up to the first '.',
 *      modifying s to only contain the remainder of the string after the '.'.
 *      In situations where you do not want to modify the original slice, you
 *      can make a copy first with `.copy()`, for example:
 *      `s.copy().split(".")`. Try and avoid using this idiom in loops; since
 *      Solidity has no memory management, it will result in allocating many
 *      short-lived slices that are later discarded.
 *
 *      Functions that return two slices come in two versions: a non-allocating
 *      version that takes the second slice as an argument, modifying it in
 *      place, and an allocating version that allocates and returns the second
 *      slice; see `nextRune` for example.
 *
 *      Functions that have to copy string data will return strings rather than
 *      slices; these can be cast back to slices for further processing if
 *      required.
 *
 *      For convenience, some functions are provided with non-modifying
 *      variants that create a new slice and return both; for instance,
 *      `s.splitNew('.')` leaves s unmodified, and returns two values
 *      corresponding to the left and right parts of the string.
 *
 *      Changes:
 *      - Add SPDX-License-Identifier
 *      - Rename len in memcpy to _len to fix shadowed declaration warning
 */

pragma solidity ^0.8.0;

library strings {
    struct slice {
        uint256 _len;
        uint256 _ptr;
    }

    function memcpy(
        uint256 dest,
        uint256 src,
        uint256 _len
    ) private pure {
        // Copy word-length chunks while possible
        for (; _len >= 32; _len -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

        // Copy remaining bytes
        uint256 mask = type(uint256).max;
        if (_len > 0) {
            mask = 256**(32 - _len) - 1;
        }
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }

    /*
     * @dev Returns a slice containing the entire string.
     * @param self The string to make a slice from.
     * @return A newly allocated slice containing the entire string.
     */
    function toSlice(string memory self) internal pure returns (slice memory) {
        uint256 ptr;
        assembly {
            ptr := add(self, 0x20)
        }
        return slice(bytes(self).length, ptr);
    }

    /*
     * @dev Returns the length of a null-terminated bytes32 string.
     * @param self The value to find the length of.
     * @return The length of the string, from 0 to 32.
     */
    function len(bytes32 self) internal pure returns (uint256) {
        uint256 ret;
        if (self == 0) return 0;
        if (uint256(self) & type(uint128).max == 0) {
            ret += 16;
            self = bytes32(uint256(self) / 0x100000000000000000000000000000000);
        }
        if (uint256(self) & type(uint64).max == 0) {
            ret += 8;
            self = bytes32(uint256(self) / 0x10000000000000000);
        }
        if (uint256(self) & type(uint32).max == 0) {
            ret += 4;
            self = bytes32(uint256(self) / 0x100000000);
        }
        if (uint256(self) & type(uint16).max == 0) {
            ret += 2;
            self = bytes32(uint256(self) / 0x10000);
        }
        if (uint256(self) & type(uint8).max == 0) {
            ret += 1;
        }
        return 32 - ret;
    }

    /*
     * @dev Returns a slice containing the entire bytes32, interpreted as a
     *      null-terminated utf-8 string.
     * @param self The bytes32 value to convert to a slice.
     * @return A new slice containing the value of the input argument up to the
     *         first null.
     */
    function toSliceB32(bytes32 self) internal pure returns (slice memory ret) {
        // Allocate space for `self` in memory, copy it there, and point ret at it
        assembly {
            let ptr := mload(0x40)
            mstore(0x40, add(ptr, 0x20))
            mstore(ptr, self)
            mstore(add(ret, 0x20), ptr)
        }
        ret._len = len(self);
    }

    /*
     * @dev Returns a new slice containing the same data as the current slice.
     * @param self The slice to copy.
     * @return A new slice containing the same data as `self`.
     */
    function copy(slice memory self) internal pure returns (slice memory) {
        return slice(self._len, self._ptr);
    }

    /*
     * @dev Copies a slice to a new string.
     * @param self The slice to copy.
     * @return A newly allocated string containing the slice's text.
     */
    function toString(slice memory self) internal pure returns (string memory) {
        string memory ret = new string(self._len);
        uint256 retptr;
        assembly {
            retptr := add(ret, 32)
        }

        memcpy(retptr, self._ptr, self._len);
        return ret;
    }

    /*
     * @dev Returns the length in runes of the slice. Note that this operation
     *      takes time proportional to the length of the slice; avoid using it
     *      in loops, and call `slice.empty()` if you only need to know whether
     *      the slice is empty or not.
     * @param self The slice to operate on.
     * @return The length of the slice in runes.
     */
    function len(slice memory self) internal pure returns (uint256 l) {
        // Starting at ptr-31 means the LSB will be the byte we care about
        uint256 ptr = self._ptr - 31;
        uint256 end = ptr + self._len;
        for (l = 0; ptr < end; l++) {
            uint8 b;
            assembly {
                b := and(mload(ptr), 0xFF)
            }
            if (b < 0x80) {
                ptr += 1;
            } else if (b < 0xE0) {
                ptr += 2;
            } else if (b < 0xF0) {
                ptr += 3;
            } else if (b < 0xF8) {
                ptr += 4;
            } else if (b < 0xFC) {
                ptr += 5;
            } else {
                ptr += 6;
            }
        }
    }

    /*
     * @dev Returns true if the slice is empty (has a length of 0).
     * @param self The slice to operate on.
     * @return True if the slice is empty, False otherwise.
     */
    function empty(slice memory self) internal pure returns (bool) {
        return self._len == 0;
    }

    /*
     * @dev Returns a positive number if `other` comes lexicographically after
     *      `self`, a negative number if it comes before, or zero if the
     *      contents of the two slices are equal. Comparison is done per-rune,
     *      on unicode codepoints.
     * @param self The first slice to compare.
     * @param other The second slice to compare.
     * @return The result of the comparison.
     */
    function compare(slice memory self, slice memory other)
        internal
        pure
        returns (int256)
    {
        uint256 shortest = self._len;
        if (other._len < self._len) shortest = other._len;

        uint256 selfptr = self._ptr;
        uint256 otherptr = other._ptr;
        for (uint256 idx = 0; idx < shortest; idx += 32) {
            uint256 a;
            uint256 b;
            assembly {
                a := mload(selfptr)
                b := mload(otherptr)
            }
            if (a != b) {
                // Mask out irrelevant bytes and check again
                uint256 mask = type(uint256).max; // 0xffff...
                if (shortest < 32) {
                    mask = ~(2**(8 * (32 - shortest + idx)) - 1);
                }
                unchecked {
                    uint256 diff = (a & mask) - (b & mask);
                    if (diff != 0) return int256(diff);
                }
            }
            selfptr += 32;
            otherptr += 32;
        }
        return int256(self._len) - int256(other._len);
    }

    /*
     * @dev Returns true if the two slices contain the same text.
     * @param self The first slice to compare.
     * @param self The second slice to compare.
     * @return True if the slices are equal, false otherwise.
     */
    function equals(slice memory self, slice memory other)
        internal
        pure
        returns (bool)
    {
        return compare(self, other) == 0;
    }

    /*
     * @dev Extracts the first rune in the slice into `rune`, advancing the
     *      slice to point to the next rune and returning `self`.
     * @param self The slice to operate on.
     * @param rune The slice that will contain the first rune.
     * @return `rune`.
     */
    function nextRune(slice memory self, slice memory rune)
        internal
        pure
        returns (slice memory)
    {
        rune._ptr = self._ptr;

        if (self._len == 0) {
            rune._len = 0;
            return rune;
        }

        uint256 l;
        uint256 b;
        // Load the first byte of the rune into the LSBs of b
        assembly {
            b := and(mload(sub(mload(add(self, 32)), 31)), 0xFF)
        }
        if (b < 0x80) {
            l = 1;
        } else if (b < 0xE0) {
            l = 2;
        } else if (b < 0xF0) {
            l = 3;
        } else {
            l = 4;
        }

        // Check for truncated codepoints
        if (l > self._len) {
            rune._len = self._len;
            self._ptr += self._len;
            self._len = 0;
            return rune;
        }

        self._ptr += l;
        self._len -= l;
        rune._len = l;
        return rune;
    }

    /*
     * @dev Returns the first rune in the slice, advancing the slice to point
     *      to the next rune.
     * @param self The slice to operate on.
     * @return A slice containing only the first rune from `self`.
     */
    function nextRune(slice memory self)
        internal
        pure
        returns (slice memory ret)
    {
        nextRune(self, ret);
    }

    /*
     * @dev Returns the number of the first codepoint in the slice.
     * @param self The slice to operate on.
     * @return The number of the first codepoint in the slice.
     */
    function ord(slice memory self) internal pure returns (uint256 ret) {
        if (self._len == 0) {
            return 0;
        }

        uint256 word;
        uint256 length;
        uint256 divisor = 2**248;

        // Load the rune into the MSBs of b
        assembly {
            word := mload(mload(add(self, 32)))
        }
        uint256 b = word / divisor;
        if (b < 0x80) {
            ret = b;
            length = 1;
        } else if (b < 0xE0) {
            ret = b & 0x1F;
            length = 2;
        } else if (b < 0xF0) {
            ret = b & 0x0F;
            length = 3;
        } else {
            ret = b & 0x07;
            length = 4;
        }

        // Check for truncated codepoints
        if (length > self._len) {
            return 0;
        }

        for (uint256 i = 1; i < length; i++) {
            divisor = divisor / 256;
            b = (word / divisor) & 0xFF;
            if (b & 0xC0 != 0x80) {
                // Invalid UTF-8 sequence
                return 0;
            }
            ret = (ret * 64) | (b & 0x3F);
        }

        return ret;
    }

    /*
     * @dev Returns the keccak-256 hash of the slice.
     * @param self The slice to hash.
     * @return The hash of the slice.
     */
    function keccak(slice memory self) internal pure returns (bytes32 ret) {
        assembly {
            ret := keccak256(mload(add(self, 32)), mload(self))
        }
    }

    /*
     * @dev Returns true if `self` starts with `needle`.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return True if the slice starts with the provided text, false otherwise.
     */
    function startsWith(slice memory self, slice memory needle)
        internal
        pure
        returns (bool)
    {
        if (self._len < needle._len) {
            return false;
        }

        if (self._ptr == needle._ptr) {
            return true;
        }

        bool equal;
        assembly {
            let length := mload(needle)
            let selfptr := mload(add(self, 0x20))
            let needleptr := mload(add(needle, 0x20))
            equal := eq(
                keccak256(selfptr, length),
                keccak256(needleptr, length)
            )
        }
        return equal;
    }

    /*
     * @dev If `self` starts with `needle`, `needle` is removed from the
     *      beginning of `self`. Otherwise, `self` is unmodified.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return `self`
     */
    function beyond(slice memory self, slice memory needle)
        internal
        pure
        returns (slice memory)
    {
        if (self._len < needle._len) {
            return self;
        }

        bool equal = true;
        if (self._ptr != needle._ptr) {
            assembly {
                let length := mload(needle)
                let selfptr := mload(add(self, 0x20))
                let needleptr := mload(add(needle, 0x20))
                equal := eq(
                    keccak256(selfptr, length),
                    keccak256(needleptr, length)
                )
            }
        }

        if (equal) {
            self._len -= needle._len;
            self._ptr += needle._len;
        }

        return self;
    }

    /*
     * @dev Returns true if the slice ends with `needle`.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return True if the slice starts with the provided text, false otherwise.
     */
    function endsWith(slice memory self, slice memory needle)
        internal
        pure
        returns (bool)
    {
        if (self._len < needle._len) {
            return false;
        }

        uint256 selfptr = self._ptr + self._len - needle._len;

        if (selfptr == needle._ptr) {
            return true;
        }

        bool equal;
        assembly {
            let length := mload(needle)
            let needleptr := mload(add(needle, 0x20))
            equal := eq(
                keccak256(selfptr, length),
                keccak256(needleptr, length)
            )
        }

        return equal;
    }

    /*
     * @dev If `self` ends with `needle`, `needle` is removed from the
     *      end of `self`. Otherwise, `self` is unmodified.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return `self`
     */
    function until(slice memory self, slice memory needle)
        internal
        pure
        returns (slice memory)
    {
        if (self._len < needle._len) {
            return self;
        }

        uint256 selfptr = self._ptr + self._len - needle._len;
        bool equal = true;
        if (selfptr != needle._ptr) {
            assembly {
                let length := mload(needle)
                let needleptr := mload(add(needle, 0x20))
                equal := eq(
                    keccak256(selfptr, length),
                    keccak256(needleptr, length)
                )
            }
        }

        if (equal) {
            self._len -= needle._len;
        }

        return self;
    }

    // Returns the memory address of the first byte of the first occurrence of
    // `needle` in `self`, or the first byte after `self` if not found.
    function findPtr(
        uint256 selflen,
        uint256 selfptr,
        uint256 needlelen,
        uint256 needleptr
    ) private pure returns (uint256) {
        uint256 ptr = selfptr;
        uint256 idx;

        if (needlelen <= selflen) {
            if (needlelen <= 32) {
                bytes32 mask;
                if (needlelen > 0) {
                    mask = bytes32(~(2**(8 * (32 - needlelen)) - 1));
                }

                bytes32 needledata;
                assembly {
                    needledata := and(mload(needleptr), mask)
                }

                uint256 end = selfptr + selflen - needlelen;
                bytes32 ptrdata;
                assembly {
                    ptrdata := and(mload(ptr), mask)
                }

                while (ptrdata != needledata) {
                    if (ptr >= end) return selfptr + selflen;
                    ptr++;
                    assembly {
                        ptrdata := and(mload(ptr), mask)
                    }
                }
                return ptr;
            } else {
                // For long needles, use hashing
                bytes32 hash;
                assembly {
                    hash := keccak256(needleptr, needlelen)
                }

                for (idx = 0; idx <= selflen - needlelen; idx++) {
                    bytes32 testHash;
                    assembly {
                        testHash := keccak256(ptr, needlelen)
                    }
                    if (hash == testHash) return ptr;
                    ptr += 1;
                }
            }
        }
        return selfptr + selflen;
    }

    // Returns the memory address of the first byte after the last occurrence of
    // `needle` in `self`, or the address of `self` if not found.
    function rfindPtr(
        uint256 selflen,
        uint256 selfptr,
        uint256 needlelen,
        uint256 needleptr
    ) private pure returns (uint256) {
        uint256 ptr;

        if (needlelen <= selflen) {
            if (needlelen <= 32) {
                bytes32 mask;
                if (needlelen > 0) {
                    mask = bytes32(~(2**(8 * (32 - needlelen)) - 1));
                }

                bytes32 needledata;
                assembly {
                    needledata := and(mload(needleptr), mask)
                }

                ptr = selfptr + selflen - needlelen;
                bytes32 ptrdata;
                assembly {
                    ptrdata := and(mload(ptr), mask)
                }

                while (ptrdata != needledata) {
                    if (ptr <= selfptr) return selfptr;
                    ptr--;
                    assembly {
                        ptrdata := and(mload(ptr), mask)
                    }
                }
                return ptr + needlelen;
            } else {
                // For long needles, use hashing
                bytes32 hash;
                assembly {
                    hash := keccak256(needleptr, needlelen)
                }
                ptr = selfptr + (selflen - needlelen);
                while (ptr >= selfptr) {
                    bytes32 testHash;
                    assembly {
                        testHash := keccak256(ptr, needlelen)
                    }
                    if (hash == testHash) return ptr + needlelen;
                    ptr -= 1;
                }
            }
        }
        return selfptr;
    }

    /*
     * @dev Modifies `self` to contain everything from the first occurrence of
     *      `needle` to the end of the slice. `self` is set to the empty slice
     *      if `needle` is not found.
     * @param self The slice to search and modify.
     * @param needle The text to search for.
     * @return `self`.
     */
    function find(slice memory self, slice memory needle)
        internal
        pure
        returns (slice memory)
    {
        uint256 ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr);
        self._len -= ptr - self._ptr;
        self._ptr = ptr;
        return self;
    }

    /*
     * @dev Modifies `self` to contain the part of the string from the start of
     *      `self` to the end of the first occurrence of `needle`. If `needle`
     *      is not found, `self` is set to the empty slice.
     * @param self The slice to search and modify.
     * @param needle The text to search for.
     * @return `self`.
     */
    function rfind(slice memory self, slice memory needle)
        internal
        pure
        returns (slice memory)
    {
        uint256 ptr = rfindPtr(self._len, self._ptr, needle._len, needle._ptr);
        self._len = ptr - self._ptr;
        return self;
    }

    /*
     * @dev Splits the slice, setting `self` to everything after the first
     *      occurrence of `needle`, and `token` to everything before it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and `token` is set to the entirety of `self`.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @param token An output parameter to which the first token is written.
     * @return `token`.
     */
    function split(
        slice memory self,
        slice memory needle,
        slice memory token
    ) internal pure returns (slice memory) {
        uint256 ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr);
        token._ptr = self._ptr;
        token._len = ptr - self._ptr;
        if (ptr == self._ptr + self._len) {
            // Not found
            self._len = 0;
        } else {
            self._len -= token._len + needle._len;
            self._ptr = ptr + needle._len;
        }
        return token;
    }

    /*
     * @dev Splits the slice, setting `self` to everything after the first
     *      occurrence of `needle`, and returning everything before it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and the entirety of `self` is returned.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @return The part of `self` up to the first occurrence of `delim`.
     */
    function split(slice memory self, slice memory needle)
        internal
        pure
        returns (slice memory token)
    {
        split(self, needle, token);
    }

    /*
     * @dev Splits the slice, setting `self` to everything before the last
     *      occurrence of `needle`, and `token` to everything after it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and `token` is set to the entirety of `self`.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @param token An output parameter to which the first token is written.
     * @return `token`.
     */
    function rsplit(
        slice memory self,
        slice memory needle,
        slice memory token
    ) internal pure returns (slice memory) {
        uint256 ptr = rfindPtr(self._len, self._ptr, needle._len, needle._ptr);
        token._ptr = ptr;
        token._len = self._len - (ptr - self._ptr);
        if (ptr == self._ptr) {
            // Not found
            self._len = 0;
        } else {
            self._len -= token._len + needle._len;
        }
        return token;
    }

    /*
     * @dev Splits the slice, setting `self` to everything before the last
     *      occurrence of `needle`, and returning everything after it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and the entirety of `self` is returned.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @return The part of `self` after the last occurrence of `delim`.
     */
    function rsplit(slice memory self, slice memory needle)
        internal
        pure
        returns (slice memory token)
    {
        rsplit(self, needle, token);
    }

    /*
     * @dev Counts the number of nonoverlapping occurrences of `needle` in `self`.
     * @param self The slice to search.
     * @param needle The text to search for in `self`.
     * @return The number of occurrences of `needle` found in `self`.
     */
    function count(slice memory self, slice memory needle)
        internal
        pure
        returns (uint256 cnt)
    {
        uint256 ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr) +
            needle._len;
        while (ptr <= self._ptr + self._len) {
            cnt++;
            ptr =
                findPtr(
                    self._len - (ptr - self._ptr),
                    ptr,
                    needle._len,
                    needle._ptr
                ) +
                needle._len;
        }
    }

    /*
     * @dev Returns True if `self` contains `needle`.
     * @param self The slice to search.
     * @param needle The text to search for in `self`.
     * @return True if `needle` is found in `self`, false otherwise.
     */
    function contains(slice memory self, slice memory needle)
        internal
        pure
        returns (bool)
    {
        return
            rfindPtr(self._len, self._ptr, needle._len, needle._ptr) !=
            self._ptr;
    }

    /*
     * @dev Returns a newly allocated string containing the concatenation of
     *      `self` and `other`.
     * @param self The first slice to concatenate.
     * @param other The second slice to concatenate.
     * @return The concatenation of the two strings.
     */
    function concat(slice memory self, slice memory other)
        internal
        pure
        returns (string memory)
    {
        string memory ret = new string(self._len + other._len);
        uint256 retptr;
        assembly {
            retptr := add(ret, 32)
        }
        memcpy(retptr, self._ptr, self._len);
        memcpy(retptr + self._len, other._ptr, other._len);
        return ret;
    }

    /*
     * @dev Joins an array of slices, using `self` as a delimiter, returning a
     *      newly allocated string.
     * @param self The delimiter to use.
     * @param parts A list of slices to join.
     * @return A newly allocated string containing all the slices in `parts`,
     *         joined with `self`.
     */
    function join(slice memory self, slice[] memory parts)
        internal
        pure
        returns (string memory)
    {
        if (parts.length == 0) return "";

        uint256 length = self._len * (parts.length - 1);
        for (uint256 i = 0; i < parts.length; i++) length += parts[i]._len;

        string memory ret = new string(length);
        uint256 retptr;
        assembly {
            retptr := add(ret, 32)
        }

        for (uint256 i = 0; i < parts.length; i++) {
            memcpy(retptr, parts[i]._ptr, parts[i]._len);
            retptr += parts[i]._len;
            if (i < parts.length - 1) {
                memcpy(retptr, self._ptr, self._len);
                retptr += self._len;
            }
        }

        return ret;
    }
}