// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/// @title GnosisSafeStorage - Storage layout of the Safe contracts to be used in libraries
/// @author Richard Meissner - <[email protected]>
contract GnosisSafeStorage {
    // From /common/Singleton.sol
    address internal singleton;
    // From /common/ModuleManager.sol
    mapping(address => address) internal modules;
    // From /common/OwnerManager.sol
    mapping(address => address) internal owners;
    uint256 internal ownerCount;
    uint256 internal threshold;

    // From /GnosisSafe.sol
    bytes32 internal nonce;
    bytes32 internal domainSeparator;
    mapping(bytes32 => uint256) internal signedMessages;
    mapping(address => mapping(bytes32 => uint256)) internal approvedHashes;
}

// SPDX-License-Identifier: GPL
pragma solidity ^0.8.7;
import "@gnosis.pm/safe-contracts/contracts/examples/libraries/GnosisSafeStorage.sol";

// adopted from: https://github.com/safe-global/safe-contracts/blob/main/contracts/examples/libraries/Migrate_1_3_0_to_1_2_0.sol
contract UpdateSingleton is GnosisSafeStorage {
    address public immutable self;

    constructor() {
        self = address(this);
    }

    event ChangedMasterCopy(address singleton);

    bytes32 private guard;

    function update(address targetSingleton) public {
        require(targetSingleton != address(0), "Invalid singleton address provided");

        // Can only be called via a delegatecall.
        require(address(this) != self, "Migration should only be called via delegatecall");

        singleton = targetSingleton;
        emit ChangedMasterCopy(singleton);
    }
}