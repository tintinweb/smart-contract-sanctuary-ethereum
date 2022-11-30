// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "./interfaces/IBeacon.sol";
import "./interfaces/IOwnable.sol";
import "./interfaces/IUUPS.sol";

contract EnsoBeacon is IBeacon {
    address public admin;
    address public delegate;
    address public factory;
    address public coreImplementation;
    address public fallbackImplementation;

    address public pendingAdmin;
    address public pendingDelegate;
    address public pendingCoreImplementation;
    address public pendingFactoryImplementation;
    bytes public pendingFactoryUpgradeData;

    uint256 public delay;
    uint256 public upgradeTimestamp;

    event CoreUpgraded(address previousImplementation, address newImplementation);
    event FallbackUpgraded(address previousImplementation, address newImplementation);
    event EmergencyUpgrade();
    event AdministrationTransferred(address previousAdmin, address newAdmin);
    event AdministrationTransferStarted(address previousAdmin, address newAdmin);
    event DelegationTransferred(address previousDelegate, address newDelegate);
    event DelegationTransferStarted(address previousDelegate, address newDelegate);
    event Factory(address newFactory);
    event Delay(uint256 newDelay);

    error InvalidImplementation();
    error InvalidAccount();
    error NotPermitted();
    error NoPendingUpgrade();
    error Wait();

    modifier onlyAdmin {
        if (msg.sender != admin) revert NotPermitted();
        _;
    }

    modifier onlyDelegate {
        if (msg.sender != delegate) revert NotPermitted();
        _;
    }

    constructor(
        address coreImplementation_,
        address fallbackImplementation_
    ) {
        admin = msg.sender;
        delegate = msg.sender;
        coreImplementation = coreImplementation_;
        fallbackImplementation = fallbackImplementation_;
    }

    // @notice The current core implementation
    // @dev Called by proxy contracts to get the implementation address
    function implementation() external view override returns (address) {
        return coreImplementation;
    }

    // @notice Switch from the core implementation to the fallback implemenation
    function emergencyUpgrade() external onlyDelegate {
        _upgradeCore(fallbackImplementation);
        emit EmergencyUpgrade();
    }

    // @notice Finalize the new core implementation
    function finalizeUpgrade() external {
        // Load timestamp and check
        uint256 timestamp = upgradeTimestamp;
        if (timestamp == 0) revert NoPendingUpgrade();
        if (timestamp + delay > block.timestamp) revert Wait();
        delete upgradeTimestamp;
        // Load implementation data and check
        address newImplementation = pendingCoreImplementation;
        address factoryImplementation = pendingFactoryImplementation;
        bytes memory data = pendingFactoryUpgradeData;
        if (newImplementation == address(0)) revert InvalidImplementation(); // sanity check
        delete pendingCoreImplementation;
        delete pendingFactoryImplementation;
        delete pendingFactoryUpgradeData;
        // Upgrade
        _upgradeCore(newImplementation);
        if (factoryImplementation != address(0)) _upgradeFactory(factoryImplementation, data);
    }

    // @notice Initialize an upgrade to a new core implementation
    // @param newImplementation The address of the new core implementation
    // @param factoryImplementation Optionally include a new factory implementation to upgrade the factory simultaneously. Pass zero address if no upgrade is needed
    // @param data Calldata for upgrading the new factory. Pass zero bytes if factory is not being upgraded or no additional call needs to be made
    function upgradeCore(
        address newImplementation,
        address factoryImplementation,
        bytes memory data
    ) external onlyAdmin {
        if (newImplementation == address(0)) revert InvalidImplementation();
        upgradeTimestamp = block.timestamp;
        pendingCoreImplementation = newImplementation;
        // If the following is null data, at least we ensure that any old pending values are overwritten
        pendingFactoryImplementation = factoryImplementation;
        pendingFactoryUpgradeData = data;
    }

    // @notice Upgrade the fallback implementation
    // @param newImplementation The address of the new fallback implementation
    function upgradeFallback(address newImplementation) external onlyAdmin {
        if (newImplementation == address(0)) revert InvalidImplementation();
        if (newImplementation == fallbackImplementation) revert InvalidImplementation();
        address previousImplementation = fallbackImplementation;
        fallbackImplementation = newImplementation;
        emit FallbackUpgraded(previousImplementation, newImplementation);
    }

    // @notice Upgrade the factory implementation
    // @param newImplementation The address of the new factory implementation
    // @param data Calldata for upgrading the new factory. Pass zero bytes if no additional call needs to be made
    function upgradeFactory(address newImplementation, bytes memory data) external onlyAdmin {
        _upgradeFactory(newImplementation, data);
    }

    // @notice Initiate transfer of the admin role
    // @notice newAdmin The address of the new admin
    function transferAdministration(address newAdmin) external onlyAdmin {
        if (newAdmin == address(0)) revert InvalidAccount();
        if (newAdmin == admin) revert InvalidAccount();
        pendingAdmin = newAdmin;
        emit AdministrationTransferStarted(admin, newAdmin);
    }

    // @notice Accept new admin role
    // @dev Only the pending admin can call this function
    function acceptAdministration() external {
        if (msg.sender != pendingAdmin) revert NotPermitted();
        delete pendingAdmin;
        address previousAdmin = admin;
        admin = msg.sender;
        emit AdministrationTransferred(previousAdmin, msg.sender);
    }

    // @notice Renounce admin role. No upgrades can be done if this function is called.
    // @dev This function renounes both the admin and the delegate roles.
    function renounceAdministration() external onlyAdmin {
        address previousAdmin = admin;
        address previousDelegate = delegate;
        delete admin;
        delete delegate;
        delete pendingAdmin;
        delete pendingDelegate;
        emit AdministrationTransferred(previousAdmin, address(0));
        emit DelegationTransferred(previousDelegate, address(0));
    }

    // @notice Initiate transfer of the delegate role
    // @notice newDelegate The address of the new delegate
    function transferDelegation(address newDelegate) external onlyAdmin {
        if (newDelegate == address(0)) revert InvalidAccount();
        if (newDelegate == delegate) revert InvalidAccount();
        pendingDelegate = newDelegate;
        emit DelegationTransferStarted(delegate, newDelegate);
    }

    // @notice Accept new delegate role
    // @dev Only the pending delegate can call this function
    function acceptDelegation() external {
        if (msg.sender != pendingDelegate) revert NotPermitted();
        delete pendingDelegate;
        address previousDelegate = delegate;
        delegate = msg.sender;
        emit DelegationTransferred(previousDelegate, msg.sender);
    }

    // @notice Renounce delegate role. Emergency upgrades cannot happen while this role remain unfilled.
    // @dev The admin can alway give this role to another address with the transferDelegation function
    function renounceDelegation() external onlyDelegate {
        address previousDelegate = delegate;
        delete delegate;
        emit DelegationTransferred(previousDelegate, address(0));
    }

    // @notice Transfer ownership of a contract that is owned by this contract
    // @param ownable The address of the contract that is getting it's ownership transferred
    // @param newOwner The address of the new owner
    function transferOwnership(address ownable, address newOwner) external onlyAdmin {
        IOwnable(ownable).transferOwnership(newOwner);
    }

    // @notice Accept ownership of another contract by this contract
    // @param ownable The address of the contract that is getting it's ownership transferred
    function acceptOwnership(address ownable) external onlyAdmin {
        IOwnable(ownable).acceptOwnership();
    }

    // @notice Set the current factory address in state
    // @param newFactory The address of the new factory
    function setFactory(address newFactory) external onlyAdmin {
        factory = newFactory;
        emit Factory(newFactory);
    }

    // @notice Update the delay between in initiating an upgrade and finalizing the upgrade
    // @param newDelay The new delay in seconds
    function setDelay(uint256 newDelay) external onlyAdmin {
        delay = newDelay;
        emit Delay(newDelay);
    }

    // @notice Internal function for setting the new core implementation
    // @param newImplementation The address of the new implementation
    function _upgradeCore(address newImplementation) internal {
        if (newImplementation == address(0)) revert InvalidImplementation();
        //if (newImplementation == coreImplementation) revert InvalidImplementation();
        address previousImplementation = coreImplementation;
        coreImplementation = newImplementation;
        emit CoreUpgraded(previousImplementation, newImplementation);
    }

    // @notice Internal function for upgrading the factory implementation
    // @param newImplementation The address of the new factory implementation
    // @param data Calldata for upgrading the new factory. Pass zero bytes if no additional call needs to be made
    function _upgradeFactory(address newImplementation, bytes memory data) internal {
        if (data.length > 0) {
            IUUPS(factory).upgradeToAndCall(newImplementation, data);
        } else {
            IUUPS(factory).upgradeTo(newImplementation);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IBeacon {
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IOwnable {
    function transferOwnership(address newOwner) external;

    function acceptOwnership() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IUUPS {
    function upgradeTo(address newImplementation) external;

    function upgradeToAndCall(address newImplementation, bytes calldata data) external;
}