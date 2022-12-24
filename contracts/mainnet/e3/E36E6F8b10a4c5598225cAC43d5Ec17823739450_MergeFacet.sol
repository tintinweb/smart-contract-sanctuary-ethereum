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

/**
 * @title Set implementation with enumeration functions
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts (MIT license)
 */
library EnumerableSet {
    error EnumerableSet__IndexOutOfBounds();

    struct Set {
        bytes32[] _values;
        // 1-indexed to allow 0 to signify nonexistence
        mapping(bytes32 => uint256) _indexes;
    }

    struct Bytes32Set {
        Set _inner;
    }

    struct AddressSet {
        Set _inner;
    }

    struct UintSet {
        Set _inner;
    }

    function at(
        Bytes32Set storage set,
        uint256 index
    ) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    function at(
        AddressSet storage set,
        uint256 index
    ) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    function at(
        UintSet storage set,
        uint256 index
    ) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    function contains(
        Bytes32Set storage set,
        bytes32 value
    ) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    function contains(
        AddressSet storage set,
        address value
    ) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    function contains(
        UintSet storage set,
        uint256 value
    ) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    function indexOf(
        Bytes32Set storage set,
        bytes32 value
    ) internal view returns (uint256) {
        return _indexOf(set._inner, value);
    }

    function indexOf(
        AddressSet storage set,
        address value
    ) internal view returns (uint256) {
        return _indexOf(set._inner, bytes32(uint256(uint160(value))));
    }

    function indexOf(
        UintSet storage set,
        uint256 value
    ) internal view returns (uint256) {
        return _indexOf(set._inner, bytes32(value));
    }

    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function add(
        Bytes32Set storage set,
        bytes32 value
    ) internal returns (bool) {
        return _add(set._inner, value);
    }

    function add(
        AddressSet storage set,
        address value
    ) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    function remove(
        Bytes32Set storage set,
        bytes32 value
    ) internal returns (bool) {
        return _remove(set._inner, value);
    }

    function remove(
        AddressSet storage set,
        address value
    ) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    function remove(
        UintSet storage set,
        uint256 value
    ) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    function toArray(
        Bytes32Set storage set
    ) internal view returns (bytes32[] memory) {
        return set._inner._values;
    }

    function toArray(
        AddressSet storage set
    ) internal view returns (address[] memory) {
        bytes32[] storage values = set._inner._values;
        address[] storage array;

        assembly {
            array.slot := values.slot
        }

        return array;
    }

    function toArray(
        UintSet storage set
    ) internal view returns (uint256[] memory) {
        bytes32[] storage values = set._inner._values;
        uint256[] storage array;

        assembly {
            array.slot := values.slot
        }

        return array;
    }

    function _at(
        Set storage set,
        uint256 index
    ) private view returns (bytes32) {
        if (index >= set._values.length)
            revert EnumerableSet__IndexOutOfBounds();
        return set._values[index];
    }

    function _contains(
        Set storage set,
        bytes32 value
    ) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    function _indexOf(
        Set storage set,
        bytes32 value
    ) private view returns (uint256) {
        unchecked {
            return set._indexes[value] - 1;
        }
    }

    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    function _add(
        Set storage set,
        bytes32 value
    ) private returns (bool status) {
        if (!_contains(set, value)) {
            set._values.push(value);
            set._indexes[value] = set._values.length;
            status = true;
        }
    }

    function _remove(
        Set storage set,
        bytes32 value
    ) private returns (bool status) {
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            unchecked {
                bytes32 last = set._values[set._values.length - 1];

                // move last value to now-vacant index

                set._values[valueIndex - 1] = last;
                set._indexes[last] = valueIndex;
            }
            // clear last index

            set._values.pop();
            delete set._indexes[value];

            status = true;
        }
    }
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

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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

/**
 * @title ERC-721 Non-Fungible Token Standard, optional child extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 *
 * A child token does not store it's own token balances and does not support
 * minting, transfer, approval. All view methods are passed along to the
 * parent contract.
 */
interface IChild {
    error ERC721Child__InvalidCaller();
    error ERC721Child__NonExistentToken();
    error ERC721Child__ApprovalNotSupported();
    error ERC721Child__TransferNotSupported();

    /**
     * @dev Returns the parent collection.
     */
    function parent() external view returns (address);

    /**
     * @dev Initialize token ownership by calling it from the parent contract.
     *
     * Only call this once in case the child contract after the parent contract.
     * Emits a {Transfer} event from ZeroAddress to current owner per token.
     */
    function init(uint256 tokenIdStart, uint256 tokenIdEnd) external;

    /**
     * @dev Update token ownership from by calling it from the parent contract.
     *
     * Emits a {Transfer} event.
     */
    function update(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {IERC721BaseInternal} from "@solidstate/contracts/token/ERC721/base/IERC721BaseInternal.sol";

interface IERC721MarketplaceInternal is IERC721BaseInternal {
    error ERC721Marketplace__NonExistentOffer();
    error ERC721Marketplace__InvalidArguments();
    error ERC721Marketplace__PaymentFailed();
    error ERC721Marketplace__InvalidValue();
    error ERC721Marketplace__InvalidPrice();

    event OfferCreated(
        uint256 indexed tokenId,
        uint256 indexed value,
        address indexed to
    );
    event OfferWithdrawn(uint256 indexed tokenId);
    event Sale(
        uint256 indexed tokenId,
        address indexed from,
        address indexed to,
        uint256 value
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

library ScapesMarketplaceStorage {
    bytes32 internal constant STORAGE_SLOT =
        keccak256("scapes.storage.Marketplace");

    struct Offer {
        uint80 price;
        uint80 specificBuyerPrice;
        uint80 lastPrice;
        address specificBuyer;
    }

    struct Layout {
        address beneficiary;
        uint256 bps;
        mapping(uint256 => Offer) offers;
    }

    function layout() internal pure returns (Layout storage d) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            d.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import {ERC721BaseInternal} from "./solidstate/ERC721BaseInternal.sol";
import {ScapesERC721MetadataStorage} from "./ScapesERC721MetadataStorage.sol";
import {IChild} from "./IChild.sol";
import {ScapesMerge} from "../metadata/ScapesMerge.sol";

import {ScapesMarketplaceStorage} from "./marketplace/ScapesMarketplaceStorage.sol";
import {IERC721MarketplaceInternal} from "./marketplace/IERC721MarketplaceInternal.sol";

/// @title MergeFacet
/// @author akuti.eth | scapes.eth
/// @notice This contract adds functionality to mint/burn merges.
/// @dev The facet adds merging to Scapes diamond contract.
contract MergeFacet is ERC721BaseInternal, IERC721MarketplaceInternal {
    error ScapesERC721__InvalidArgument();
    using ScapesMerge for ScapesMerge.Merge;

    uint256 internal constant MIN_MERGE_SIZE = 2;
    uint256 internal constant MAX_MERGE_SIZE = 8;

    /**
     * @notice Ceate and mint a merge out of multiple Scapes.
     * @dev Transfer Scape tokens to the contract and mint a merge Scape.
     * @param merge_ Merge settings
     */
    function merge(ScapesMerge.Merge memory merge_) external {
        _merge(merge_.toId(), merge_);
    }

    /**
     * @notice Ceate and mint a merge out of multiple Scapes.
     * @dev Transfer Scape tokens to the contract and mint a merge Scape.
     * @param mergeTokenId token Id of the merge
     */
    function merge(uint256 mergeTokenId) external {
        _merge(mergeTokenId, ScapesMerge.fromId(mergeTokenId));
    }

    /**
     * @notice Burn a merge and receive its Scapes.
     * @dev Burn the merge scape and transfer the contained Scapes form the contract.
     * @param merge_ Merge settings
     */
    function purge(ScapesMerge.Merge memory merge_) external {
        _purge(merge_.toId(), merge_);
    }

    /**
     * @notice Burn a merge and receive its Scapes.
     * @dev Burn the merge scape and transfer the contained Scapes form the contract.
     * @param mergeTokenId token Id of the merge
     */
    function purge(uint256 mergeTokenId) external {
        _purge(mergeTokenId, ScapesMerge.fromId(mergeTokenId));
    }

    function _merge(uint256 mergeTokenId, ScapesMerge.Merge memory merge_)
        internal
    {
        if (
            merge_.parts.length < MIN_MERGE_SIZE ||
            merge_.parts.length > MAX_MERGE_SIZE
        ) revert ScapesERC721__InvalidArgument();
        for (uint256 i = 0; i < merge_.parts.length; i++) {
            // transfer all containing tokens, it is supposed to fail when tokens are repeated
            uint256 tokenId = merge_.parts[i].tokenId;
            if (!_isApprovedOrOwner(msg.sender, tokenId))
                revert ERC721Base__NotOwnerOrApproved();
            _transfer(msg.sender, address(this), tokenId);
        }
        _safeMint(msg.sender, mergeTokenId);
    }

    function _purge(uint256 mergeTokenId, ScapesMerge.Merge memory merge_)
        internal
    {
        if (_ownerOf(mergeTokenId) != msg.sender)
            revert ERC721Base__NotTokenOwner();
        _burn(mergeTokenId);
        for (uint256 i = 0; i < merge_.parts.length; i++) {
            _safeTransfer(
                address(this),
                msg.sender,
                merge_.parts[i].tokenId,
                ""
            );
        }
    }

    /**
     * @inheritdoc ERC721BaseInternal
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721BaseInternal) {
        if (
            from != address(0) &&
            ScapesMarketplaceStorage.layout().offers[tokenId].price > 0
        ) {
            ScapesMarketplaceStorage.Layout storage d = ScapesMarketplaceStorage
                .layout();
            d.offers[tokenId].price = 0;
            d.offers[tokenId].specificBuyer = address(0);
            emit OfferWithdrawn(tokenId);
        }
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @inheritdoc ERC721BaseInternal
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721BaseInternal) {
        IChild(ScapesERC721MetadataStorage.layout().scapeBound).update(
            from,
            to,
            tokenId
        );
        super._afterTokenTransfer(from, to, tokenId);
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
// Based on solidstate @solidstate/contracts/token/ERC721/base/ERC721BaseInternal.sol
// Changes made:
//  - store a holder balance instead of the individual tokens, this removes the
//    option to easily upgrade to ERC721Enumerable but lowers gas cost by ~45k per mint
//  - update balance in mint, transfer and burn functions separate balance for normal
//    tokens and merged tokens
//  - update balanceOf to return the combined balance
//  - add _afterTokenTransfer hook

pragma solidity ^0.8.8;

import {IERC721Receiver} from "@solidstate/contracts/interfaces/IERC721Receiver.sol";
import {EnumerableMap} from "@solidstate/contracts/data/EnumerableMap.sol";
import {EnumerableSet} from "@solidstate/contracts/data/EnumerableSet.sol";
import {AddressUtils} from "@solidstate/contracts/utils/AddressUtils.sol";
import {IERC721BaseInternal} from "@solidstate/contracts/token/ERC721/base/IERC721BaseInternal.sol";
import {ERC721BaseStorage} from "./ERC721BaseStorage.sol";

/**
 * @title Base ERC721 internal functions
 */
abstract contract ERC721BaseInternal is IERC721BaseInternal {
    using ERC721BaseStorage for ERC721BaseStorage.Layout;
    using AddressUtils for address;
    using EnumerableMap for EnumerableMap.UintToAddressMap;
    using EnumerableSet for EnumerableSet.UintSet;

    uint256 internal constant MERGES_TRESHOLD = 130_000;

    function _balanceOf(address account)
        internal
        view
        virtual
        returns (uint256)
    {
        if (account == address(0)) revert ERC721Base__BalanceQueryZeroAddress();
        return ERC721BaseStorage.layout().holderBalances[account];
    }

    function _balanceOfMerges(address account)
        internal
        view
        virtual
        returns (uint256)
    {
        if (account == address(0)) revert ERC721Base__BalanceQueryZeroAddress();
        return ERC721BaseStorage.layout().holderBalancesMerges[account];
    }

    function _ownerOf(uint256 tokenId) internal view virtual returns (address) {
        address owner = ERC721BaseStorage.layout().tokenOwners.get(tokenId);
        if (owner == address(0)) revert ERC721Base__InvalidOwner();
        return owner;
    }

    function _getApproved(uint256 tokenId)
        internal
        view
        virtual
        returns (address)
    {
        ERC721BaseStorage.Layout storage l = ERC721BaseStorage.layout();

        if (!l.exists(tokenId)) revert ERC721Base__NonExistentToken();

        return l.tokenApprovals[tokenId];
    }

    function _isApprovedForAll(address account, address operator)
        internal
        view
        virtual
        returns (bool)
    {
        return ERC721BaseStorage.layout().operatorApprovals[account][operator];
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        virtual
        returns (bool)
    {
        if (!ERC721BaseStorage.layout().exists(tokenId))
            revert ERC721Base__NonExistentToken();

        address owner = _ownerOf(tokenId);

        return (spender == owner ||
            _getApproved(tokenId) == spender ||
            _isApprovedForAll(owner, spender));
    }

    function _mint(address to, uint256 tokenId) internal virtual {
        if (to == address(0)) revert ERC721Base__MintToZeroAddress();

        ERC721BaseStorage.Layout storage l = ERC721BaseStorage.layout();

        if (l.exists(tokenId)) revert ERC721Base__TokenAlreadyMinted();

        _beforeTokenTransfer(address(0), to, tokenId);
        unchecked {
            if (tokenId > MERGES_TRESHOLD) l.holderBalancesMerges[to] += 1;
            else l.holderBalances[to] += 1;
        }
        l.tokenOwners.set(tokenId, to);

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        if (!_checkOnERC721Received(address(0), to, tokenId, data))
            revert ERC721Base__ERC721ReceiverNotImplemented();
    }

    function _burn(uint256 tokenId) internal virtual {
        address owner = _ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        _approve(address(0), tokenId);

        ERC721BaseStorage.Layout storage l = ERC721BaseStorage.layout();
        unchecked {
            if (tokenId > MERGES_TRESHOLD) l.holderBalancesMerges[owner] -= 1;
            else l.holderBalances[owner] -= 1;
        }
        l.tokenOwners.remove(tokenId);

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        if (_ownerOf(tokenId) != from) revert ERC721Base__NotTokenOwner();
        if (to == address(0)) revert ERC721Base__TransferToZeroAddress();

        _beforeTokenTransfer(from, to, tokenId);

        _approve(address(0), tokenId);

        ERC721BaseStorage.Layout storage l = ERC721BaseStorage.layout();
        unchecked {
            if (tokenId > MERGES_TRESHOLD) {
                l.holderBalancesMerges[from] -= 1;
                l.holderBalancesMerges[to] += 1;
            } else {
                l.holderBalances[from] -= 1;
                l.holderBalances[to] += 1;
            }
        }
        l.tokenOwners.set(tokenId, to);

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        if (!_checkOnERC721Received(from, to, tokenId, data))
            revert ERC721Base__ERC721ReceiverNotImplemented();
    }

    function _approve(address operator, uint256 tokenId) internal virtual {
        ERC721BaseStorage.layout().tokenApprovals[tokenId] = operator;
        emit Approval(_ownerOf(tokenId), operator, tokenId);
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual returns (bool) {
        if (!to.isContract()) {
            return true;
        }

        bytes memory returnData = to.functionCall(
            abi.encodeWithSelector(
                IERC721Receiver(to).onERC721Received.selector,
                msg.sender,
                from,
                tokenId,
                data
            ),
            "ERC721: transfer to non ERC721Receiver implementer"
        );

        bytes4 returnValue = abi.decode(returnData, (bytes4));
        return returnValue == type(IERC721Receiver).interfaceId;
    }

    /**
     * @notice ERC721 hook, called before externally called approvals for processing of included message value
     * @param operator beneficiary of approval
     * @param tokenId id of transferred token
     * @param value message value
     */
    function _handleApproveMessageValue(
        address operator,
        uint256 tokenId,
        uint256 value
    ) internal virtual {}

    /**
     * @notice ERC721 hook, called before externally called transfers for processing of included message value
     * @param from sender of token
     * @param to receiver of token
     * @param tokenId id of transferred token
     * @param value message value
     */
    function _handleTransferMessageValue(
        address from,
        address to,
        uint256 tokenId,
        uint256 value
    ) internal virtual {}

    /**
     * @notice ERC721 hook, called before all transfers including mint and burn
     * @dev function should be overridden and new implementation must call super
     * @param from sender of token
     * @param to receiver of token
     * @param tokenId id of transferred token
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @notice ERC721 hook, called after all transfers including mint and burn
     * @dev function should be overridden and new implementation must call super
     * @param from sender of token
     * @param to receiver of token
     * @param tokenId id of transferred token
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
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

    function toId(Merge memory merge_) internal pure returns (uint256 mergeId) {
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