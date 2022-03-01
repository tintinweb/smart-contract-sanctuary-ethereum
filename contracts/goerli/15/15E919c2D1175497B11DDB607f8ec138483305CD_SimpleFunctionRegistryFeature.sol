// SPDX-License-Identifier: Apache-2.0

/*

    The file was modified by Agora.

    2022 agora.xyz
    
*/

/*

  Copyright 2020 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity 0.8.12;

import "../fixins/FixinCommon.sol";
import "../storage/LibProxyStorage.sol";
import "../storage/LibSimpleFunctionRegistryStorage.sol";
import "../migrations/LibBootstrap.sol";
import "./interfaces/IFeature.sol";
import "./interfaces/ISimpleFunctionRegistryFeature.sol";

/// @title Basic registry management features.
contract SimpleFunctionRegistryFeature is IFeature, ISimpleFunctionRegistryFeature, FixinCommon {
    /// @notice Name of this feature.
    string public constant override FEATURE_NAME = "SimpleFunctionRegistry";
    /// @notice Version of this feature.
    uint256 public immutable override FEATURE_VERSION = _encodeVersion(1, 0, 0);

    /// @notice Initializes this feature, registering its own functions.
    /// @return success Magic bytes if successful.
    function bootstrap() external returns (bytes4 success) {
        // Register the registration functions (inception vibes).
        _extend(this.extend.selector, _implementation);
        _extend(this._extendSelf.selector, _implementation);
        // Register the rollback function.
        _extend(this.rollback.selector, _implementation);
        // Register getters.
        _extend(this.getRollbackLength.selector, _implementation);
        _extend(this.getRollbackEntryAtIndex.selector, _implementation);
        return LibBootstrap.BOOTSTRAP_SUCCESS;
    }

    /// @notice Roll back to a prior implementation of a function.
    ///      Only directly callable by an authority.
    /// @param selector The function selector.
    /// @param targetImpl The address of an older implementation of the function.
    function rollback(bytes4 selector, address targetImpl) external override onlyOwner {
        (
            LibSimpleFunctionRegistryStorage.Storage storage stor,
            LibProxyStorage.Storage storage proxyStor
        ) = _getStorages();

        address currentImpl = proxyStor.impls[selector];
        if (currentImpl == targetImpl) {
            // Do nothing if already at targetImpl.
            return;
        }
        // Walk history backwards until we find the target implementation.
        address[] storage history = stor.implHistory[selector];
        uint256 i = history.length;
        for (; i > 0; --i) {
            address impl = history[i - 1];
            history.pop();
            if (impl == targetImpl) {
                break;
            }
        }
        if (i == 0) revert NotInRollbackHistory(selector, targetImpl);
        proxyStor.impls[selector] = targetImpl;
        emit ProxyFunctionUpdated(selector, currentImpl, targetImpl);
    }

    /// @notice Register or replace a function.
    ///      Only directly callable by an authority.
    /// @param selector The function selector.
    /// @param impl The implementation contract for the function.
    function extend(bytes4 selector, address impl) external override onlyOwner {
        _extend(selector, impl);
    }

    /// @notice Register or replace a function.
    ///      Only callable from within.
    ///      This function is only used during the bootstrap process and
    ///      should be deregistered by the deployer after bootstrapping is
    ///      complete.
    /// @param selector The function selector.
    /// @param impl The implementation contract for the function.
    function _extendSelf(bytes4 selector, address impl) external onlySelf {
        _extend(selector, impl);
    }

    /// @notice Retrieve the length of the rollback history for a function.
    /// @param selector The function selector.
    /// @return rollbackLength The number of items in the rollback history for
    ///         the function.
    function getRollbackLength(bytes4 selector) external view override returns (uint256 rollbackLength) {
        return LibSimpleFunctionRegistryStorage.getStorage().implHistory[selector].length;
    }

    /// @notice Retrieve an entry in the rollback history for a function.
    /// @param selector The function selector.
    /// @param idx The index in the rollback history.
    /// @return impl An implementation address for the function at
    ///         index `idx`.
    function getRollbackEntryAtIndex(bytes4 selector, uint256 idx) external view override returns (address impl) {
        return LibSimpleFunctionRegistryStorage.getStorage().implHistory[selector][idx];
    }

    /// @notice Register or replace a function.
    /// @param selector The function selector.
    /// @param impl The implementation contract for the function.
    function _extend(bytes4 selector, address impl) private {
        (
            LibSimpleFunctionRegistryStorage.Storage storage stor,
            LibProxyStorage.Storage storage proxyStor
        ) = _getStorages();

        address oldImpl = proxyStor.impls[selector];
        address[] storage history = stor.implHistory[selector];
        history.push(oldImpl);
        proxyStor.impls[selector] = impl;
        emit ProxyFunctionUpdated(selector, oldImpl, impl);
    }

    /// @notice Get the storage buckets for this feature and the proxy.
    /// @return stor Storage bucket for this feature.
    /// @return proxyStor age bucket for the proxy.
    function _getStorages()
        private
        pure
        returns (LibSimpleFunctionRegistryStorage.Storage storage stor, LibProxyStorage.Storage storage proxyStor)
    {
        return (LibSimpleFunctionRegistryStorage.getStorage(), LibProxyStorage.getStorage());
    }
}

// SPDX-License-Identifier: Apache-2.0

/*

    The file was modified by Agora.

    2022 agora.xyz

*/

/*

  Copyright 2020 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity 0.8.12;

/// @title Common storage helpers
library LibStorage {
    /// @notice What to bit-shift a storage ID by to get its slot.
    ///      This gives us a maximum of 2**128 inline fields in each bucket.
    uint256 private constant STORAGE_SLOT_EXP = 128;

    /// @notice Storage IDs for feature storage buckets.
    ///      WARNING: APPEND-ONLY.
    enum StorageId {
        Proxy,
        SimpleFunctionRegistry,
        Ownable,
        TokenFactory,
        MerkleDistributorFactory,
        MerkleVestingFactory,
        Test
    }

    /// @notice Get the storage slot given a storage ID. We assign unique, well-spaced
    ///     slots to storage bucket variables to ensure they do not overlap.
    ///     See: https://solidity.readthedocs.io/en/v0.8.12/assembly.html#access-to-external-variables-functions-and-libraries
    /// @param storageId An entry in `StorageId`
    /// @return slot The storage slot.
    function getStorageSlot(StorageId storageId) internal pure returns (uint256 slot) {
        // This should never overflow with a reasonable `STORAGE_SLOT_EXP`
        // because Solidity will do a range check on `storageId` during the cast.
        return (uint256(storageId) + 1) << STORAGE_SLOT_EXP;
    }
}

// SPDX-License-Identifier: Apache-2.0

/*

    The file was modified by Agora.

    2022 agora.xyz
    
*/

/*

  Copyright 2020 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity 0.8.12;

import "./LibStorage.sol";

/// @title Storage helpers for the `SimpleFunctionRegistry` feature.
library LibSimpleFunctionRegistryStorage {
    /// @notice Storage bucket for this feature.
    struct Storage {
        // Mapping of function selector -> implementation history.
        mapping(bytes4 => address[]) implHistory;
    }

    /// @notice Get the storage bucket for this contract.
    function getStorage() internal pure returns (Storage storage stor) {
        uint256 storageSlot = LibStorage.getStorageSlot(LibStorage.StorageId.SimpleFunctionRegistry);
        // Dip into assembly to change the slot pointed to by the local
        // variable `stor`.
        // See https://solidity.readthedocs.io/en/v0.8.12/assembly.html?highlight=slot#access-to-external-variables-functions-and-libraries
        assembly {
            stor.slot := storageSlot
        }
    }
}

// SPDX-License-Identifier: Apache-2.0

/*

    The file was modified by Agora.

    2022 agora.xyz
    
*/

/*

  Copyright 2020 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity 0.8.12;

import "./LibStorage.sol";

/// @title Storage helpers for the proxy contract.
library LibProxyStorage {
    /// @notice Storage bucket for proxy contract.
    struct Storage {
        // Mapping of function selector -> function implementation
        mapping(bytes4 => address) impls;
        // The owner of the proxy contract.
        address owner;
    }

    /// @notice Get the storage bucket for this contract.
    function getStorage() internal pure returns (Storage storage stor) {
        uint256 storageSlot = LibStorage.getStorageSlot(LibStorage.StorageId.Proxy);
        // Dip into assembly to change the slot pointed to by the local
        // variable `stor`.
        // See https://solidity.readthedocs.io/en/v0.8.12/assembly.html?highlight=slot#access-to-external-variables-functions-and-libraries
        assembly {
            stor.slot := storageSlot
        }
    }
}

// SPDX-License-Identifier: Apache-2.0

/*

    The file was modified by Agora.

    2022 agora.xyz
    
*/

/*

  Copyright 2020 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity 0.8.12;

library LibBootstrap {
    /// @notice Magic bytes returned by the bootstrapper to indicate success.
    ///      This is `keccack('BOOTSTRAP_SUCCESS')`.
    bytes4 internal constant BOOTSTRAP_SUCCESS = 0xd150751b;

    /// @notice Error thrown when a delegatecall to a bootstrap function failed.
    /// @param target The address that was attempted to be called.
    /// @param resultData The result bytes of the call.
    error BootstrapCallFailed(address target, bytes resultData);

    /// @notice Perform a delegatecall and ensure it returns the magic bytes.
    /// @param target The call target.
    /// @param data The call data.
    function delegatecallBootstrapFunction(address target, bytes memory data) internal {
        (bool success, bytes memory resultData) = target.delegatecall(data);
        if (!success || resultData.length != 32 || abi.decode(resultData, (bytes4)) != BOOTSTRAP_SUCCESS) {
            revert BootstrapCallFailed(target, resultData);
        }
    }
}

// SPDX-License-Identifier: Apache-2.0

/*

    The file was modified by Agora.

    2022 agora.xyz
    
*/

/*

  Copyright 2020 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity 0.8.12;

import "../features/interfaces/IOwnableFeature.sol";
import "../features/interfaces/ISimpleFunctionRegistryFeature.sol";

/// @title Common feature utilities.
abstract contract FixinCommon {
    /// @notice The implementation address of this feature.
    address internal immutable _implementation;

    /// @notice Error thrown when a function only callable by self was called by another address.
    /// @param caller The caller of the function.
    error OnlyCallableBySelf(address caller);

    /// @notice Error thrown when a function only callable by the owner was called by another address.
    /// @param caller The caller of the function.
    /// @param owner The owner's address.
    error OnlyOwner(address caller, address owner);

    /// @notice The caller must be this contract.
    modifier onlySelf() virtual {
        if (msg.sender != address(this)) revert OnlyCallableBySelf(msg.sender);
        _;
    }

    /// @notice The caller of this function must be the owner.
    modifier onlyOwner() virtual {
        {
            address owner = IOwnableFeature(address(this)).owner();
            if (msg.sender != owner) revert OnlyOwner(msg.sender, owner);
        }
        _;
    }

    constructor() {
        // Remember this feature's original address.
        _implementation = address(this);
    }

    /// @notice Registers a function implemented by this feature at `_implementation`.
    ///      Can and should only be called within a `migrate()`.
    /// @param selector The selector of the function whose implementation
    ///        is at `_implementation`.
    function _registerFeatureFunction(bytes4 selector) internal {
        ISimpleFunctionRegistryFeature(address(this)).extend(selector, _implementation);
    }

    /// @notice Encode a feature version as a `uint256`.
    /// @param major The major version number of the feature.
    /// @param minor The minor version number of the feature.
    /// @param revision The revision number of the feature.
    /// @return encodedVersion The encoded version number.
    function _encodeVersion(
        uint32 major,
        uint32 minor,
        uint32 revision
    ) internal pure returns (uint256 encodedVersion) {
        return (uint256(major) << 64) | (uint256(minor) << 32) | uint256(revision);
    }
}

// SPDX-License-Identifier: Apache-2.0

/*

    The file was modified by Agora.

    2022 agora.xyz
    
*/

/*

  Copyright 2020 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.8.0;

/// @title Basic registry management features.
interface ISimpleFunctionRegistryFeature {
    /// @notice Error thrown when the requested function selector is not in the target implementation.
    /// @param selector The function selector.
    /// @param implementation The address supposed to include an older implementation of the function.
    error NotInRollbackHistory(bytes4 selector, address implementation);

    /// @notice A function implementation was updated via `extend()` or `rollback()`.
    /// @param selector The function selector.
    /// @param oldImpl The implementation contract address being replaced.
    /// @param newImpl The replacement implementation contract address.
    event ProxyFunctionUpdated(bytes4 indexed selector, address oldImpl, address newImpl);

    /// @notice Roll back to a prior implementation of a function.
    /// @param selector The function selector.
    /// @param targetImpl The address of an older implementation of the function.
    function rollback(bytes4 selector, address targetImpl) external;

    /// @notice Register or replace a function.
    /// @param selector The function selector.
    /// @param impl The implementation contract for the function.
    function extend(bytes4 selector, address impl) external;

    /// @notice Retrieve the length of the rollback history for a function.
    /// @param selector The function selector.
    /// @return rollbackLength The number of items in the rollback history for
    ///         the function.
    function getRollbackLength(bytes4 selector) external view returns (uint256 rollbackLength);

    /// @notice Retrieve an entry in the rollback history for a function.
    /// @param selector The function selector.
    /// @param idx The index in the rollback history.
    /// @return impl An implementation address for the function at
    ///         index `idx`.
    function getRollbackEntryAtIndex(bytes4 selector, uint256 idx) external view returns (address impl);
}

// SPDX-License-Identifier: Apache-2.0

/*

    The file was modified by Agora.

    2022 agora.xyz
    
*/

/*

  Copyright 2020 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.8.0;

interface IOwnableV06 {
    /// @notice Emitted by Ownable when ownership is transferred.
    /// @param previousOwner The previous owner of the contract.
    /// @param newOwner The new owner of the contract.
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @notice Transfers ownership of the contract to a new address.
    /// @param newOwner The address that will become the owner.
    function transferOwnership(address newOwner) external;

    /// @notice The owner of this contract.
    /// @return ownerAddress The owner address.
    function owner() external view returns (address ownerAddress);
}

/// @title Owner management and migration features.
interface IOwnableFeature is IOwnableV06 {
    /// @notice Emitted when `migrate()` is called.
    /// @param caller The caller of `migrate()`.
    /// @param migrator The migration contract.
    /// @param newOwner The address of the new owner.
    event Migrated(address caller, address migrator, address newOwner);

    /// @notice Error thrown when attempting to transfer the ownership to the zero address.
    error TransferOwnerToZero();

    /// @notice Execute a migration function in the context of the TokenXyz contract.
    ///      The result of the function being called should be the magic bytes
    ///      0x2c64c5ef (`keccak('MIGRATE_SUCCESS')`). Only callable by the owner.
    ///      The owner will be temporarily set to `address(this)` inside the call.
    ///      Before returning, the owner will be set to `newOwner`.
    /// @param target The migrator contract address.
    /// @param newOwner The address of the new owner.
    /// @param data The call data.
    function migrate(
        address target,
        bytes calldata data,
        address newOwner
    ) external;
}

// SPDX-License-Identifier: Apache-2.0

/*

    The file was modified by Agora.

    2022 agora.xyz
    
*/

/*

  Copyright 2020 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.8.0;

/// @title Basic interface for a feature contract.
interface IFeature {
    // solhint-disable func-name-mixedcase

    /// @notice The name of this feature set.
    function FEATURE_NAME() external view returns (string memory name);

    /// @notice The version of this feature set.
    function FEATURE_VERSION() external view returns (uint256 version);
}