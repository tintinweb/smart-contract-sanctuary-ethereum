//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library AccessError {
    error Unauthorized(address addr);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../errors/AccessError.sol";

library OwnableStorage {
    struct Data {
        bool initialized;
        address owner;
        address nominatedOwner;
    }

    function load() internal pure returns (Data storage store) {
        bytes32 s = keccak256(abi.encode("Ownable"));
        assembly {
            store.slot := s
        }
    }

    function onlyOwner() internal view {
        if (msg.sender != getOwner()) {
            revert AccessError.Unauthorized(msg.sender);
        }
    }

    function getOwner() internal view returns (address) {
        return OwnableStorage.load().owner;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library SetUtil {
    // ----------------------------------------
    // Uint support
    // ----------------------------------------

    struct UintSet {
        Bytes32Set raw;
    }

    function add(UintSet storage set, uint value) internal {
        add(set.raw, bytes32(value));
    }

    function remove(UintSet storage set, uint value) internal {
        remove(set.raw, bytes32(value));
    }

    function replace(
        UintSet storage set,
        uint value,
        uint newValue
    ) internal {
        replace(set.raw, bytes32(value), bytes32(newValue));
    }

    function contains(UintSet storage set, uint value) internal view returns (bool) {
        return contains(set.raw, bytes32(value));
    }

    function length(UintSet storage set) internal view returns (uint) {
        return length(set.raw);
    }

    function valueAt(UintSet storage set, uint position) internal view returns (uint) {
        return uint(valueAt(set.raw, position));
    }

    function positionOf(UintSet storage set, uint value) internal view returns (uint) {
        return positionOf(set.raw, bytes32(value));
    }

    function values(UintSet storage set) internal view returns (uint[] memory) {
        bytes32[] memory store = values(set.raw);
        uint[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // ----------------------------------------
    // Address support
    // ----------------------------------------

    struct AddressSet {
        Bytes32Set raw;
    }

    function add(AddressSet storage set, address value) internal {
        add(set.raw, bytes32(uint256(uint160(value))));
    }

    function remove(AddressSet storage set, address value) internal {
        remove(set.raw, bytes32(uint256(uint160(value))));
    }

    function replace(
        AddressSet storage set,
        address value,
        address newValue
    ) internal {
        replace(set.raw, bytes32(uint256(uint160(value))), bytes32(uint256(uint160(newValue))));
    }

    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return contains(set.raw, bytes32(uint256(uint160(value))));
    }

    function length(AddressSet storage set) internal view returns (uint) {
        return length(set.raw);
    }

    function valueAt(AddressSet storage set, uint position) internal view returns (address) {
        return address(uint160(uint256(valueAt(set.raw, position))));
    }

    function positionOf(AddressSet storage set, address value) internal view returns (uint) {
        return positionOf(set.raw, bytes32(uint256(uint160(value))));
    }

    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = values(set.raw);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // ----------------------------------------
    // Core bytes32 support
    // ----------------------------------------

    error PositionOutOfBounds();
    error ValueNotInSet();
    error ValueAlreadyInSet();

    struct Bytes32Set {
        bytes32[] _values;
        mapping(bytes32 => uint) _positions; // Position zero is never used.
    }

    function add(Bytes32Set storage set, bytes32 value) internal {
        if (contains(set, value)) {
            revert ValueAlreadyInSet();
        }

        set._values.push(value);
        set._positions[value] = set._values.length;
    }

    function remove(Bytes32Set storage set, bytes32 value) internal {
        uint position = set._positions[value];
        if (position == 0) {
            revert ValueNotInSet();
        }

        uint index = position - 1;
        uint lastIndex = set._values.length - 1;

        // If the element being deleted is not the last in the values,
        // move the last element to its position.
        if (index != lastIndex) {
            bytes32 lastValue = set._values[lastIndex];

            set._values[index] = lastValue;
            set._positions[lastValue] = position;
        }

        // Remove the last element in the values.
        set._values.pop();
        delete set._positions[value];
    }

    function replace(
        Bytes32Set storage set,
        bytes32 value,
        bytes32 newValue
    ) internal {
        if (!contains(set, value)) {
            revert ValueNotInSet();
        }

        if (contains(set, newValue)) {
            revert ValueAlreadyInSet();
        }

        uint position = set._positions[value];
        uint index = position - 1;

        set._values[index] = newValue;
        set._positions[newValue] = position;
    }

    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return set._positions[value] != 0;
    }

    function length(Bytes32Set storage set) internal view returns (uint) {
        return set._values.length;
    }

    function valueAt(Bytes32Set storage set, uint position) internal view returns (bytes32) {
        if (position == 0 || position > set._values.length) {
            revert PositionOutOfBounds();
        }

        uint index = position - 1;

        return set._values[index];
    }

    function positionOf(Bytes32Set storage set, bytes32 value) internal view returns (uint) {
        if (!contains(set, value)) {
            revert ValueNotInSet();
        }

        return set._positions[value];
    }

    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return set._values;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Interface for feature flags
interface IFeatureFlagModule {
    /// @notice Set a feature flag to either allow all or not
    function setFeatureFlagAllowAll(bytes32 feature, bool allowAll) external;

    /// @notice Add an address and give it permission for a feature flag
    function addToFeatureFlagAllowlist(bytes32 feature, address permissioned) external;

    /// @notice Remove an address and remove its permission for a feature flag
    function removeFromFeatureFlagAllowlist(bytes32 feature, address permissioned) external;

    /// @notice Returns allowAll boolean value for a feature flag
    function getFeatureFlagAllowAll(bytes32 feature) external view returns (bool);

    /// @notice Returns the addresses that have permission for a feature flag
    function getFeatureFlagAllowlist(bytes32 feature) external view returns (address[] memory);

    /// @notice Check if address has access to feature
    function isFeatureAllowed(bytes32 feature, address addressToCheck) external view returns (bool);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@synthetixio/core-contracts/contracts/ownership/OwnableStorage.sol";
import "../storage/FeatureFlag.sol";

import "../interfaces/IFeatureFlagModule.sol";

contract FeatureFlagModule is IFeatureFlagModule {
    using SetUtil for SetUtil.AddressSet;

    event FeatureFlagAllowAllSet(bytes32 feature, bool value);
    event FeatureFlagAllowlistAdded(bytes32 feature, address account);
    event FeatureFlagAllowlistRemoved(bytes32 feature, address account);

    function setFeatureFlagAllowAll(bytes32 feature, bool allowAll) external override {
        OwnableStorage.onlyOwner();
        FeatureFlag.load(feature).allowAll = allowAll;

        emit FeatureFlagAllowAllSet(feature, allowAll);
    }

    function addToFeatureFlagAllowlist(bytes32 feature, address permissioned) external override {
        OwnableStorage.onlyOwner();
        FeatureFlag.load(feature).permissionedAddresses.add(permissioned);

        emit FeatureFlagAllowlistAdded(feature, permissioned);
    }

    function removeFromFeatureFlagAllowlist(bytes32 feature, address permissioned) external override {
        OwnableStorage.onlyOwner();
        FeatureFlag.load(feature).permissionedAddresses.remove(permissioned);

        emit FeatureFlagAllowlistRemoved(feature, permissioned);
    }

    function getFeatureFlagAllowAll(bytes32 feature) external view override returns (bool) {
        return FeatureFlag.load(feature).allowAll;
    }

    function getFeatureFlagAllowlist(bytes32 feature) external view override returns (address[] memory) {
        return FeatureFlag.load(feature).permissionedAddresses.values();
    }

    function isFeatureAllowed(bytes32 feature, address addressToCheck) external view override returns (bool) {
        return FeatureFlag.hasAccess(feature, addressToCheck);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@synthetixio/core-contracts/contracts/utils/SetUtil.sol";

library FeatureFlag {
    using SetUtil for SetUtil.AddressSet;

    error FeatureUnavailable();

    struct Data {
        bytes32 name;
        bool allowAll;
        SetUtil.AddressSet permissionedAddresses;
    }

    function load(bytes32 featureName) internal pure returns (Data storage store) {
        bytes32 s = keccak256(abi.encode("FeatureFlag", featureName));
        assembly {
            store.slot := s
        }
    }

    function ensureAccessToFeature(bytes32 feature) internal view {
        if (!hasAccess(feature, msg.sender)) {
            revert FeatureUnavailable();
        }
    }

    function hasAccess(bytes32 feature, address value) internal view returns (bool) {
        Data storage store = FeatureFlag.load(feature);

        return store.allowAll || store.permissionedAddresses.contains(value);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {FeatureFlagModule as BaseFeatureFlagModule} from "@synthetixio/core-modules/contracts/modules/FeatureFlagModule.sol";

/**
 * @title Module that allows disabling certain system features.
 *
 * Users will not be able to interact with certain functions associated to disabled features.
 */
// solhint-disable-next-line no-empty-blocks
contract FeatureFlagModule is BaseFeatureFlagModule {

}