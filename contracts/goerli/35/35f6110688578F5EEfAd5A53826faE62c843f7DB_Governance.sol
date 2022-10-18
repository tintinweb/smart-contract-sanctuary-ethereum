// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/interfaces/IGovernor.sol";
import "contracts/libraries/errors/GovernanceErrors.sol";

/// @custom:salt Governance
/// @custom:deploy-type deployUpgradeable
contract Governance is IGovernor {
    // dummy contract
    address internal immutable _factory;

    constructor() {
        _factory = msg.sender;
    }

    function updateValue(
        uint256 epoch,
        uint256 key,
        bytes32 value
    ) external {
        if (msg.sender != _factory) {
            revert GovernanceErrors.OnlyFactoryAllowed(msg.sender);
        }
        emit ValueUpdated(epoch, key, value, msg.sender);
    }
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

interface IGovernor {
    event ValueUpdated(
        uint256 indexed epoch,
        uint256 indexed key,
        bytes32 indexed value,
        address who
    );

    event SnapshotTaken(
        uint256 chainId,
        uint256 indexed epoch,
        uint256 height,
        address indexed validator,
        bool isSafeToProceedConsensus,
        bytes signatureRaw
    );

    function updateValue(
        uint256 epoch,
        uint256 key,
        bytes32 value
    ) external;
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

library GovernanceErrors {
    error OnlyFactoryAllowed(address sender);
}