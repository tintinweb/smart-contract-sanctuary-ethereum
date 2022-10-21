/**
 *Submitted for verification at Etherscan.io on 2022-10-21
*/

// SPDX-License-Identifier: Apache-2.0-or-later
/*

 Copyright 2022 Rigo Intl.

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

pragma solidity >=0.8.0 <0.9.0;

interface IRigoblockPoolProxy {
    /// @notice Emitted when implementation written to proxy storage.
    /// @dev Emitted also at first variable initialization.
    /// @param newImplementation Address of the new implementation.
    event Upgraded(address indexed newImplementation);
}

interface IRigoblockPoolProxyFactory {
    /// @notice Emitted when a new pool is created.
    /// @param poolAddress Address of the new pool.
    event PoolCreated(address poolAddress);

    /// @notice Emitted when a new implementation is set by the Rigoblock Dao.
    /// @param implementation Address of the new implementation.
    event Upgraded(address indexed implementation);

    /// @notice Emitted when registry address is upgraded by the Rigoblock Dao.
    /// @param registry Address of the new registry.
    event RegistryUpgraded(address indexed registry);

    /// @notice Returns the implementation address for the pool proxies.
    /// @return Address of the implementation.
    function implementation() external view returns (address);

    /// @notice Creates a new Rigoblock pool.
    /// @param name String of the name.
    /// @param symbol String of the symbol.
    /// @param baseToken Address of the base token.
    /// @return newPoolAddress Address of the new pool.
    /// @return poolId Id of the new pool.
    function createPool(
        string calldata name,
        string calldata symbol,
        address baseToken
    ) external returns (address newPoolAddress, bytes32 poolId);

    /// @notice Allows Rigoblock Dao to update factory pool implementation.
    /// @param newImplementation Address of the new implementation contract.
    function setImplementation(address newImplementation) external;

    /// @notice Allows owner to update the registry.
    /// @param newRegistry Address of the new registry.
    function setRegistry(address newRegistry) external;

    /// @notice Returns the address of the pool registry.
    /// @return Address of the registry.
    function getRegistry() external view returns (address);

    /// @notice Pool initialization parameters.
    /// @params name String of the name (max 31 characters).
    /// @params symbol bytes8 symbol.
    /// @params owner Address of the owner.
    /// @params baseToken Address of the base token.
    struct Parameters {
        string name;
        bytes8 symbol;
        address owner;
        address baseToken;
    }

    /// @notice Returns the pool initialization parameters at proxy deploy.
    /// @return Tuple of the pool parameters.
    function parameters() external view returns (Parameters memory);
}

/// @title RigoblockPoolProxy - Proxy contract forwards calls to the implementation address returned by the admin.
/// @author Gabriele Rigo - <[email protected]>
contract RigoblockPoolProxy is IRigoblockPoolProxy {
    // implementation slot is used to store implementation address, a contract which implements the pool logic.
    // Reduced deployment cost by using internal variable.
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /// @notice Sets address of implementation contract.
    constructor() payable {
        // store implementation address in implementation slot value
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        address implementation = IRigoblockPoolProxyFactory(msg.sender).implementation();
        getImplementation().implementation = implementation;
        emit Upgraded(implementation);

        // initialize pool
        // abi.encodeWithSelector(IRigoblockPool.initializePool.selector)
        (, bytes memory returnData) = implementation.delegatecall(abi.encodeWithSelector(0x250e6de0));

        // we must assert initialization didn't fail, otherwise it could fail silently and still deploy the pool.
        require(returnData.length == 0, "POOL_INITIALIZATION_FAILED_ERROR");
    }

    /* solhint-disable no-complex-fallback */
    /// @notice Fallback function forwards all transactions and returns all received return data.
    fallback() external payable {
        address implementation = getImplementation().implementation;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            calldatacopy(0, 0, calldatasize())
            let success := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            if eq(success, 0) {
                revert(0, returndatasize())
            }
            return(0, returndatasize())
        }
    }

    /* solhint-enable no-complex-fallback */

    /// @notice Implementation slot is accessed directly.
    /// @dev Saves gas compared to using storage slot library.
    /// @param implementation Address of the implementation.
    struct ImplementationSlot {
        address implementation;
    }

    /// @notice Method to read/write from/to implementation slot.
    /// @return s Storage slot of the pool implementation.
    function getImplementation() private pure returns (ImplementationSlot storage s) {
        assembly {
            s.slot := _IMPLEMENTATION_SLOT
        }
    }
}