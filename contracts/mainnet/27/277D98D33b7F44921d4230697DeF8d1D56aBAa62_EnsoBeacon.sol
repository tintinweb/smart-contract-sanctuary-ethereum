// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.16;

import "./interfaces/IBeacon.sol";
import "./interfaces/IOwnable.sol";
import "./interfaces/IUUPS.sol";
import "./access/Timelock.sol";

contract EnsoBeacon is IBeacon, Timelock {

    uint256 constant public MAX_DELAY = 2419200; // 4 weeks

    address public admin;
    address public delegate;
    address public factory;
    address public coreImplementation;
    address public fallbackImplementation;

    address public pendingAdmin;
    address public pendingDelegate;

    event CoreUpgraded(address previousImplementation, address newImplementation, bool finalized);
    event FallbackUpgraded(address previousImplementation, address newImplementation, bool finalized);
    event EmergencyUpgrade();
    event AdministrationTransferred(address previousAdmin, address newAdmin);
    event AdministrationTransferStarted(address previousAdmin, address newAdmin);
    event DelegationTransferred(address previousDelegate, address newDelegate);
    event DelegationTransferStarted(address previousDelegate, address newDelegate);
    event Delay(uint256 newDelay, bool finalized);

    error InvalidImplementation();
    error InvalidAccount();
    error InvalidDelay();
    error NotPermitted();
    error FactorySet();

    modifier onlyAdmin() {
        if (msg.sender != admin) revert NotPermitted();
        _;
    }

    modifier onlyDelegate() {
        if (msg.sender != delegate) revert NotPermitted();
        _;
    }

    constructor(address admin_, address coreImplementation_, address fallbackImplementation_) {
        admin = admin_;
        delegate = admin_;
        coreImplementation = coreImplementation_;
        fallbackImplementation = fallbackImplementation_;
    }

    // @notice The current core implementation
    // @dev Called by proxy contracts to get the implementation address
    function implementation() external view override returns (address) {
        return coreImplementation;
    }

    // @notice Switch from the core implementation to the fallback implementation
    function emergencyUpgrade() external onlyDelegate {
        _upgradeCore(fallbackImplementation);
        emit EmergencyUpgrade();
    }

    // @notice Initialize an upgrade to a new core implementation
    // @param newImplementation The address of the new core implementation
    // @param factoryImplementation Optionally include a new factory implementation to upgrade the factory simultaneously. Pass zero address if no upgrade is needed
    // @param factoryUpgradeData Calldata for upgrading the new factory. Pass zero bytes if factory is not being upgraded or no additional call needs to be made
    function upgradeCore(
        address newImplementation,
        address factoryImplementation,
        bytes memory factoryUpgradeData
    ) external onlyAdmin {
        address currentImplementation = coreImplementation;
        if (newImplementation == address(0)) revert InvalidImplementation();
        if (newImplementation == currentImplementation) revert InvalidImplementation();
        bytes32 key = this.upgradeCore.selector;
        bytes memory data = abi.encode(newImplementation, factoryImplementation, factoryUpgradeData);
        _startTimelock(key, data);
        emit CoreUpgraded(currentImplementation, newImplementation, false);
    }

    // @notice Finalize the new core implementation
    function finalizeCore() external {
        // Resolve timelock
        bytes32 key = this.upgradeCore.selector;
        (address newImplementation, address factoryImplementation, bytes memory factoryUpgradeData) = abi.decode(
            _resolveTimelock(key), (address, address, bytes)
        );
        // Upgrade
        _upgradeCore(newImplementation);
        if (factoryImplementation != address(0)) _upgradeFactory(factoryImplementation, factoryUpgradeData);
    }

    // @notice Initialize an upgrade to a new fallback implementation
    // @param newImplementation The address of the new fallback implementation
    function upgradeFallback(address newImplementation) external onlyAdmin {
        address currentImplementation = fallbackImplementation;
        if (newImplementation == address(0)) revert InvalidImplementation();
        if (newImplementation == currentImplementation) revert InvalidImplementation();
        bytes32 key = this.upgradeFallback.selector;
        bytes memory data = abi.encode(newImplementation);
        _startTimelock(key, data);
        emit FallbackUpgraded(currentImplementation, newImplementation, false);
    }

    // @notice Finalize the new fallback implementation
    function finalizeFallback() external {
        // Resolve timelock
        bytes32 key = this.upgradeFallback.selector;
        (address newImplementation) = abi.decode(
            _resolveTimelock(key), (address)
        );
        // Upgrade
        if (newImplementation == address(0)) revert InvalidImplementation(); // sanity check
        address previousImplementation = fallbackImplementation;
        fallbackImplementation = newImplementation;
        emit FallbackUpgraded(previousImplementation, newImplementation, true);
    }

    // @notice Upgrade the factory implementation
    // @param newImplementation The address of the new factory implementation
    // @param data Calldata for upgrading the new factory. Pass zero bytes if no additional call needs to be made
    function upgradeFactory(address newImplementation, bytes memory data) external onlyAdmin {
        if (newImplementation == address(0)) revert InvalidImplementation();
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
    // @dev This function renounces both the admin and the delegate roles.
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
    // @dev The admin can always give this role to another address with the transferDelegation function
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

    // @notice Set the factory address. Once set, the factory cannot be changed
    // @param newFactory The address of the new factory
    function setFactory(address newFactory) external onlyAdmin {
        if (factory != address(0)) revert FactorySet();
        if (newFactory == address(0)) revert InvalidAccount();
        factory = newFactory;
    }

    // @notice Initiate an update of the delay value
    // @param newDelay The new delay in seconds
    function updateDelay(uint256 newDelay) external onlyAdmin {
        if (newDelay > MAX_DELAY) revert InvalidDelay();
        // Set timelock
        bytes32 key = this.updateDelay.selector;
        bytes memory data = abi.encode(newDelay);
        _startTimelock(key, data);
        emit Delay(newDelay, false);
    }

    // @notice Finalize the delay in state
    function finalizeDelay() external {
        // Resolve timelock
        bytes32 key = this.updateDelay.selector;
        (uint256 newDelay) = abi.decode(
            _resolveTimelock(key), (uint256)
        );
        if (newDelay > MAX_DELAY) revert InvalidDelay(); // sanity check
        // Set delay
        delay = newDelay;
        emit Delay(newDelay, true);
    }

    // @notice Internal function for setting the new core implementation
    // @param newImplementation The address of the new implementation
    function _upgradeCore(address newImplementation) internal {
        if (newImplementation == address(0)) revert InvalidImplementation();
        //if (newImplementation == coreImplementation) revert InvalidImplementation();
        address previousImplementation = coreImplementation;
        coreImplementation = newImplementation;
        emit CoreUpgraded(previousImplementation, newImplementation, true);
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

    // @notice Internal function to check timelock and reset it after timelock has matured
    // @param key The bytes32 key that represents the function that is timelocked
    // @return The bytes data that is stored by the timelock
    function _resolveTimelock(bytes32 key) internal returns (bytes memory data) {
        _checkTimelock(key);
        data = _getTimelockValue(key);
        _resetTimelock(key);
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.16;


abstract contract Timelock {

    uint256 constant public UNSET_TIMESTAMP = 1;
    bytes constant public UNSET_VALUE = new bytes(0x01); 

    uint256 public delay;
    mapping(bytes32 => TimelockData) public timelockData;

    struct TimelockData {
        uint256 timestamp;
        bytes value;
    }
    
    error NoTimelock();
    error Wait();

    // @notice Internal function to initiate a timelock
    // @param key The bytes32 key that represents the function that is timelocked
    // @param value The bytes value that is stored until the timelock completes
    function _startTimelock(bytes32 key, bytes memory value) internal {
        TimelockData storage td = timelockData[key]; 
        td.timestamp = block.timestamp;
        td.value = value;
    }

    // @notice Internal function to check the current status of a timelock and revert if the timelock has not matured
    // @param key The bytes32 key that represents the function that is timelocked
    function _checkTimelock(bytes32 key) internal view {
        TimelockData memory td = timelockData[key]; 
        if (td.timestamp < 2) revert NoTimelock();
        if (block.timestamp < td.timestamp + delay) revert Wait();
    }

    // @notice Internal function to view the value stored for a timelock
    // @return The bytes value that is stored until the timelock completes
    function _getTimelockValue(bytes32 key) internal view returns(bytes memory) {
        return timelockData[key].value; 
    }

    // @notice Reset the timelock
    // @param key The bytes32 key that represents the function that is timelocked
    function _resetTimelock(bytes32 key) internal {
        TimelockData storage td = timelockData[key];
        // By not deleting TimelockData, we save gas on subsequent actions
        td.timestamp = UNSET_TIMESTAMP; 
        td.value = UNSET_VALUE;
    }
}

// SPDX-License-Identifier: GPL-3.0-only
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