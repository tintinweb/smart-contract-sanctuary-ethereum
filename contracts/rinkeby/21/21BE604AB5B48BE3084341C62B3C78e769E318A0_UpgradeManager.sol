// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import {IUpgradeManager} from "./IUpgradeManager.sol";

/// @title UpgradeManager
/// @author Rohan Kulkarni
/// @notice This contract allows DAOs to opt-in to implementation upgrades registered by the Nouns Builder DAO
contract UpgradeManager is IUpgradeManager {
    ///                                                          ///
    ///                          CONSTRUCTOR                     ///
    ///                                                          ///

    /// @param _registrar The address of the Nouns Builder DAO registrar
    constructor(address _registrar) {
        registrar = _registrar;
    }

    ///                                                          ///
    ///                            STORAGE                       ///
    ///                                                          ///

    /// @notice If a contract is a registered upgrade for an original implementation
    /// @dev Original address => Upgrade address
    mapping(address => mapping(address => bool)) private upgrades;

    /// @notice If an upgraded implementation has been registered for its original implementation
    /// @param _prevImpl The address of the original implementation
    /// @param _newImpl The address of the upgraded implementation
    function isValidUpgrade(address _prevImpl, address _newImpl) external view override returns (bool) {
        return upgrades[_prevImpl][_newImpl];
    }

    ///                                                          ///
    ///                       REGISTER UPGRADE                   ///
    ///                                                          ///

    /// @notice Emitted when an upgrade is registered
    /// @param prevImpl The address of the previous implementation
    /// @param newImpl The address of the registered upgrade
    event UpgradeRegistered(address prevImpl, address newImpl);

    /// @notice Registers an implementation as a valid upgrade
    /// @param _prevImpl The address of the original implementation
    /// @param _newImpl The address of the implementation valid to upgrade to
    function registerUpgrade(address _prevImpl, address _newImpl) external {
        // Ensure the caller is the registrar
        require(msg.sender == registrar, "ONLY_REGISTRAR");

        // Register the upgrade
        upgrades[_prevImpl][_newImpl] = true;

        emit UpgradeRegistered(_prevImpl, _newImpl);
    }

    ///                                                          ///
    ///                      UNREGISTER UPGRADE                  ///
    ///                                                          ///

    /// @notice Emitted when an upgrade is unregistered
    /// @param prevImpl The address of the previous implementation
    /// @param newImpl The address of the unregistered upgrade
    event UpgradeUnregistered(address prevImpl, address newImpl);

    /// @notice Unregisters an implementation
    /// @param _prevImpl The address of the implementation to revert back to
    /// @param _newImpl The address of the implementation to unregister
    function unregisterUpgrade(address _prevImpl, address _newImpl) external {
        // Ensure the caller is the registrar
        require(msg.sender == registrar, "ONLY_REGISTRAR");

        // Unregister the upgraded implementation
        delete upgrades[_prevImpl][_newImpl];

        emit UpgradeUnregistered(_prevImpl, _newImpl);
    }

    ///                                                          ///
    ///                        UPDATE REGISTRAR                  ///
    ///                                                          ///

    /// @notice The address of the registrar
    address public registrar;

    /// @notice Emitted when the registrar is updated
    /// @param registrar The address of the new registrar
    event RegistrarUpdated(address registrar);

    /// @notice Updates the registrar
    /// @param _registrar The address of the new registrar
    function setRegistrar(address _registrar) external {
        // Ensure the caller is the registrar
        require(msg.sender == registrar, "ONLY_REGISTRAR");

        // Update the registrar address
        registrar = _registrar;

        emit RegistrarUpdated(registrar);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

/// @title IUpgradeManager
/// @author Rohan Kulkarni
/// @notice Interface for the Upgrade Manager
interface IUpgradeManager {
    /// @notice If an upgraded implementation has been registered for its original implementation
    /// @param _prevImpl The address of the original implementation
    /// @param _newImpl The address of the upgraded implementation
    function isValidUpgrade(address _prevImpl, address _newImpl) external returns (bool);
}