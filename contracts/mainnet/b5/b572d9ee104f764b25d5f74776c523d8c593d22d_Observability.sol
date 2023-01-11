// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import {IObservability, IObservabilityEvents} from "./interface/IObservability.sol";

contract Observability is IObservability, IObservabilityEvents {
    /// @notice Emitted when a new clone is deployed
    function emitCloneDeployed(address owner, address clone) external override {
        emit CloneDeployed(msg.sender, owner, clone);
    }

    /// @notice Emitted when a sale has occured
    function emitSale(
        address to,
        uint256 pricePerToken,
        uint256 amount
    ) external override {
        emit Sale(msg.sender, to, pricePerToken, amount);
    }

    /// @notice Emitted when funds have been withdrawn
    function emitFundsWithdrawn(
        address withdrawnBy,
        address withdrawnTo,
        uint256 amount
    ) external override {
        emit FundsWithdrawn(msg.sender, withdrawnBy, withdrawnTo, amount);
    }

    /// @notice Emitted when a new implementation is registered
    function emitDeploymentTargetRegistererd(address impl) external override {
        emit DeploymentTargetRegistered(impl);
    }

    /// @notice Emitted when an implementation is unregistered
    function emitDeploymentTargetUnregistered(address impl) external override {
        emit DeploymentTargetUnregistered(impl);
    }

    /// @notice Emitted when a new upgrade is registered
    function emitUpgradeRegistered(
        address prevImpl,
        address impl
    ) external override {
        emit UpgradeRegistered(prevImpl, impl);
    }

    /// @notice Emitted when an upgrade is unregistered
    function emitUpgradeUnregistered(
        address prevImpl,
        address impl
    ) external override {
        emit UpgradeUnregistered(prevImpl, impl);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

interface IObservabilityEvents {
    /// @notice Emitted when a new clone is deployed
    event CloneDeployed(
        address indexed factory,
        address indexed owner,
        address clone
    );

    /// @notice Emitted when a sale has occured
    event Sale(
        address indexed clone,
        address indexed to,
        uint256 pricePerToken,
        uint256 amount
    );

    /// @notice Emitted when funds have been withdrawn
    event FundsWithdrawn(
        address indexed clone,
        address indexed withdrawnBy,
        address indexed withdrawnTo,
        uint256 amount
    );

    /// @notice Emitted when a new implementation is registered
    event DeploymentTargetRegistered(address indexed impl);

    /// @notice Emitted when an implementation is unregistered
    event DeploymentTargetUnregistered(address indexed impl);

    /// @notice Emitted when an upgrade is registered
    /// @param prevImpl The address of the previous implementation
    /// @param newImpl The address of the registered upgrade
    event UpgradeRegistered(address indexed prevImpl, address indexed newImpl);

    /// @notice Emitted when an upgrade is unregistered
    /// @param prevImpl The address of the previous implementation
    /// @param newImpl The address of the unregistered upgrade
    event UpgradeUnregistered(
        address indexed prevImpl,
        address indexed newImpl
    );
}

interface IObservability {
    function emitCloneDeployed(address owner, address clone) external;

    function emitSale(
        address to,
        uint256 pricePerToken,
        uint256 amount
    ) external;

    function emitFundsWithdrawn(
        address withdrawnBy,
        address withdrawnTo,
        uint256 amount
    ) external;

    function emitDeploymentTargetRegistererd(address impl) external;

    function emitDeploymentTargetUnregistered(address imp) external;

    function emitUpgradeRegistered(address prevImpl, address impl) external;

    function emitUpgradeUnregistered(address prevImpl, address impl) external;
}