// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface VRFCoordinatorV2Interface {
  /**
   * @notice Get configuration relevant for making requests
   * @return minimumRequestConfirmations global min for request confirmations
   * @return maxGasLimit global max for request gas limit
   * @return s_provingKeyHashes list of registered key hashes
   */
  function getRequestConfig()
    external
    view
    returns (
      uint16,
      uint32,
      bytes32[] memory
    );

  /**
   * @notice Request a set of random words.
   * @param keyHash - Corresponds to a particular oracle job which uses
   * that key for generating the VRF proof. Different keyHash's have different gas price
   * ceilings, so you can select a specific one to bound your maximum per request cost.
   * @param subId  - The ID of the VRF subscription. Must be funded
   * with the minimum subscription balance required for the selected keyHash.
   * @param minimumRequestConfirmations - How many blocks you'd like the
   * oracle to wait before responding to the request. See SECURITY CONSIDERATIONS
   * for why you may want to request more. The acceptable range is
   * [minimumRequestBlockConfirmations, 200].
   * @param callbackGasLimit - How much gas you'd like to receive in your
   * fulfillRandomWords callback. Note that gasleft() inside fulfillRandomWords
   * may be slightly less than this amount because of gas used calling the function
   * (argument decoding etc.), so you may need to request slightly more than you expect
   * to have inside fulfillRandomWords. The acceptable range is
   * [0, maxGasLimit]
   * @param numWords - The number of uint256 random values you'd like to receive
   * in your fulfillRandomWords callback. Note these numbers are expanded in a
   * secure way by the VRFCoordinator from a single random value supplied by the oracle.
   * @return requestId - A unique identifier of the request. Can be used to match
   * a request to a response in fulfillRandomWords.
   */
  function requestRandomWords(
    bytes32 keyHash,
    uint64 subId,
    uint16 minimumRequestConfirmations,
    uint32 callbackGasLimit,
    uint32 numWords
  ) external returns (uint256 requestId);

  /**
   * @notice Create a VRF subscription.
   * @return subId - A unique subscription id.
   * @dev You can manage the consumer set dynamically with addConsumer/removeConsumer.
   * @dev Note to fund the subscription, use transferAndCall. For example
   * @dev  LINKTOKEN.transferAndCall(
   * @dev    address(COORDINATOR),
   * @dev    amount,
   * @dev    abi.encode(subId));
   */
  function createSubscription() external returns (uint64 subId);

  /**
   * @notice Get a VRF subscription.
   * @param subId - ID of the subscription
   * @return balance - LINK balance of the subscription in juels.
   * @return reqCount - number of requests for this subscription, determines fee tier.
   * @return owner - owner of the subscription.
   * @return consumers - list of consumer address which are able to use this subscription.
   */
  function getSubscription(uint64 subId)
    external
    view
    returns (
      uint96 balance,
      uint64 reqCount,
      address owner,
      address[] memory consumers
    );

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @param newOwner - proposed new owner of the subscription
   */
  function requestSubscriptionOwnerTransfer(uint64 subId, address newOwner) external;

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @dev will revert if original owner of subId has
   * not requested that msg.sender become the new owner.
   */
  function acceptSubscriptionOwnerTransfer(uint64 subId) external;

  /**
   * @notice Add a consumer to a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - New consumer which can use the subscription
   */
  function addConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Remove a consumer from a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - Consumer to remove from the subscription
   */
  function removeConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Cancel a subscription
   * @param subId - ID of the subscription
   * @param to - Where to send the remaining LINK to
   */
  function cancelSubscription(uint64 subId, address to) external;

  /*
   * @notice Check to see if there exists a request commitment consumers
   * for all consumers and keyhashes for a given sub.
   * @param subId - ID of the subscription
   * @return true if there exists at least one unfulfilled request for the subscription, false
   * otherwise.
   */
  function pendingRequestExists(uint64 subId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate the implementation's compatibility when performing an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/PullPayment.sol)

pragma solidity ^0.8.0;

import "../utils/escrow/EscrowUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Simple implementation of a
 * https://consensys.github.io/smart-contract-best-practices/development-recommendations/general/external-calls/#favor-pull-over-push-for-external-calls[pull-payment]
 * strategy, where the paying contract doesn't interact directly with the
 * receiver account, which must withdraw its payments itself.
 *
 * Pull-payments are often considered the best practice when it comes to sending
 * Ether, security-wise. It prevents recipients from blocking execution, and
 * eliminates reentrancy concerns.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 *
 * To use, derive from the `PullPayment` contract, and use {_asyncTransfer}
 * instead of Solidity's `transfer` function. Payees can query their due
 * payments with {payments}, and retrieve them with {withdrawPayments}.
 *
 * @custom:storage-size 51
 */
abstract contract PullPaymentUpgradeable is Initializable {
    EscrowUpgradeable private _escrow;

    function __PullPayment_init() internal onlyInitializing {
        __PullPayment_init_unchained();
    }

    function __PullPayment_init_unchained() internal onlyInitializing {
        _escrow = new EscrowUpgradeable();
        _escrow.initialize();
    }

    /**
     * @dev Withdraw accumulated payments, forwarding all gas to the recipient.
     *
     * Note that _any_ account can call this function, not just the `payee`.
     * This means that contracts unaware of the `PullPayment` protocol can still
     * receive funds this way, by having a separate account call
     * {withdrawPayments}.
     *
     * WARNING: Forwarding all gas opens the door to reentrancy vulnerabilities.
     * Make sure you trust the recipient, or are either following the
     * checks-effects-interactions pattern or using {ReentrancyGuard}.
     *
     * @param payee Whose payments will be withdrawn.
     *
     * Causes the `escrow` to emit a {Withdrawn} event.
     */
    function withdrawPayments(address payable payee) public virtual {
        _escrow.withdraw(payee);
    }

    /**
     * @dev Returns the payments owed to an address.
     * @param dest The creditor's address.
     */
    function payments(address dest) public view returns (uint256) {
        return _escrow.depositsOf(dest);
    }

    /**
     * @dev Called by the payer to store the sent amount as credit to be pulled.
     * Funds sent in this way are stored in an intermediate {Escrow} contract, so
     * there is no danger of them being spent before withdrawal.
     *
     * @param dest The destination address of the funds.
     * @param amount The amount to transfer.
     *
     * Causes the `escrow` to emit a {Deposited} event.
     */
    function _asyncTransfer(address dest, uint256 amount) internal virtual {
        _escrow.deposit{value: amount}(dest);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/escrow/Escrow.sol)

pragma solidity ^0.8.0;

import "../../access/OwnableUpgradeable.sol";
import "../AddressUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @title Escrow
 * @dev Base escrow contract, holds funds designated for a payee until they
 * withdraw them.
 *
 * Intended usage: This contract (and derived escrow contracts) should be a
 * standalone contract, that only interacts with the contract that instantiated
 * it. That way, it is guaranteed that all Ether will be handled according to
 * the `Escrow` rules, and there is no need to check for payable functions or
 * transfers in the inheritance tree. The contract that uses the escrow as its
 * payment method should be its owner, and provide public methods redirecting
 * to the escrow's deposit and withdraw.
 */
contract EscrowUpgradeable is Initializable, OwnableUpgradeable {
    function __Escrow_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Escrow_init_unchained() internal onlyInitializing {
    }
    function initialize() public virtual initializer {
        __Escrow_init();
    }
    using AddressUpgradeable for address payable;

    event Deposited(address indexed payee, uint256 weiAmount);
    event Withdrawn(address indexed payee, uint256 weiAmount);

    mapping(address => uint256) private _deposits;

    function depositsOf(address payee) public view returns (uint256) {
        return _deposits[payee];
    }

    /**
     * @dev Stores the sent amount as credit to be withdrawn.
     * @param payee The destination address of the funds.
     *
     * Emits a {Deposited} event.
     */
    function deposit(address payee) public payable virtual onlyOwner {
        uint256 amount = msg.value;
        _deposits[payee] += amount;
        emit Deposited(payee, amount);
    }

    /**
     * @dev Withdraw accumulated balance for a payee, forwarding all gas to the
     * recipient.
     *
     * WARNING: Forwarding all gas opens the door to reentrancy vulnerabilities.
     * Make sure you trust the recipient, or are either following the
     * checks-effects-interactions pattern or using {ReentrancyGuard}.
     *
     * @param payee The address whose funds will be withdrawn and transferred to.
     *
     * Emits a {Withdrawn} event.
     */
    function withdraw(address payable payee) public virtual onlyOwner {
        uint256 payment = _deposits[payee];

        _deposits[payee] = 0;

        payee.sendValue(payment);

        emit Withdrawn(payee, payment);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


// DO NOT CHANGE: this is the timestamp of the first Saturday evening in seconds since the Unix
// Epoch. It's used to align the allowed drawing windows with Saturday evenings.
uint constant FIRST_SATURDAY_EVENING = 244800;


struct DrawData {
  uint256 blockNumber;
  uint8[6] numbers;
  uint64[][5] winners;
}

struct PrizeData {
  uint64 ticket;
  uint256 prize;
}


library Drawing {
  function choose(uint n, uint k) public pure returns (uint) {
    if (k > n) {
      return 0;
    } else if (k == 0) {
      return 1;
    } else if (k * 2 > n) {
      return choose(n, n - k);
    } else {
      return n * choose(n - 1, k - 1) / k;
    }
  }

  function getCurrentDrawingWindow() public view returns (uint) {
    return FIRST_SATURDAY_EVENING + (block.timestamp - FIRST_SATURDAY_EVENING) / 7 days * 7 days;
  }

  function _ceil(uint time, uint window) private pure returns (uint) {
    return (time + window - 1) / window * window;
  }

  function nextDrawTime() public view returns (uint) {
    return FIRST_SATURDAY_EVENING + _ceil(block.timestamp - FIRST_SATURDAY_EVENING, 7 days);
  }

  function getRandomNumbersWithoutRepetitions(uint256 randomness)
      public pure returns (uint8[6] memory numbers)
  {
    uint8[90] memory source;
    for (uint8 i = 1; i <= 90; i++) {
      source[i - 1] = i;
    }
    for (uint i = 0; i < 6; i++) {
      uint j = i + randomness % (90 - i);
      randomness /= 90;
      numbers[i] = source[j];
      source[j] = source[i];
    }
  }

  function sortNumbersByTicketCount(uint64[][90] storage ticketsByNumber, uint8[6] memory numbers)
      public view returns (uint8[6] memory)
  {
    for (uint i = 0; i < numbers.length - 1; i++) {
      uint j = i;
      for (uint k = j + 1; k < numbers.length; k++) {
        if (ticketsByNumber[numbers[k] - 1].length < ticketsByNumber[numbers[j] - 1].length) {
          j = k;
        }
      }
      if (j != i) {
        uint8 t = numbers[i];
        numbers[i] = numbers[j];
        numbers[j] = t;
      }
    }
    return numbers;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol';
import '@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/PullPaymentUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol';

import './Drawing.sol';
import './TicketIndex.sol';
import './TicketSet.sol';
import './UserTickets.sol';


// This is in USD cents, so it's $1.50
uint constant BASE_TICKET_PRICE_USD = 150;

// ChainLink USD price feed (8 decimals)
address constant USD_PRICE_FEED = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;

// Width of the weekly drawing window.
uint constant DRAWING_WINDOW_WIDTH = 4 hours;


contract Lottery is UUPSUpgradeable, OwnableUpgradeable, PausableUpgradeable,
    PullPaymentUpgradeable, ReentrancyGuardUpgradeable
{
  using AddressUpgradeable for address payable;
  using UserTickets for TicketData[];
  using TicketSet for uint64[];
  using TicketIndex for uint64[][90];

  enum State {OPEN, DRAWING, DRAWN, CLOSING}

  VRFCoordinatorV2Interface private _vrfCoordinator;

  uint256 public baseTicketPrice;

  uint64 public nextTicketId;
  uint64 public currentRound;

  State public state;
  uint public nextDrawTime;

  mapping (address => TicketData[]) public ticketsByPlayer;

  address payable[] public playersByTicket;
  uint64[][90][] public ticketsByNumber;
  DrawData[] public draws;

  event NewTicketPrice(uint indexed round, uint256 price);
  event Ticket(uint indexed round, address indexed player, uint8[] numbers);
  event VRFRequest(uint indexed round, uint256 requestId);
  event Draw(uint indexed round, uint8[6] numbers, uint256 currentBalance);
  event CloseRound(uint indexed round, uint256 currentBalance);

  // Accept funds from ICO and possibly other sources in the future.
  receive() external payable {}

  function initialize(address vrfCoordinator) public initializer {
    __UUPSUpgradeable_init();
    __Ownable_init();
    __Pausable_init();
    __PullPayment_init();
    __ReentrancyGuard_init();
    _vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator);
    _updateTicketPrice();
    nextTicketId = 0;
    currentRound = 0;
    ticketsByNumber.push();
    draws.push();
    state = State.OPEN;
    nextDrawTime = Drawing.nextDrawTime();
  }

  function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

  function _updateTicketPrice() private {
    AggregatorV3Interface priceFeed = AggregatorV3Interface(USD_PRICE_FEED);
    (, int256 price, , , ) = priceFeed.latestRoundData();
    baseTicketPrice = BASE_TICKET_PRICE_USD *
        uint256(10 ** (16 + priceFeed.decimals())) / uint256(price);
    emit NewTicketPrice(currentRound, baseTicketPrice);
  }

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }

  function getTicketPrice(uint8[] calldata playerNumbers) public view returns (uint256) {
    require(state == State.OPEN, 'please wait for the next round');
    require(playerNumbers.length >= 6, 'too few numbers');
    require(playerNumbers.length <= 90, 'too many numbers');
    for (uint i = 0; i < playerNumbers.length; i++) {
      require(playerNumbers[i] > 0 && playerNumbers[i] <= 90, 'invalid numbers');
      for (uint j = i + 1; j < playerNumbers.length; j++) {
        require(playerNumbers[i] != playerNumbers[j], 'duplicate numbers');
      }
    }
    return baseTicketPrice * Drawing.choose(playerNumbers.length, 6);
  }

  function buyTicket(uint8[] calldata playerNumbers) public payable whenNotPaused nonReentrant {
    uint256 ticketPrice = getTicketPrice(playerNumbers);
    require(msg.value == ticketPrice, 'incorrect value, please check the price of your ticket');
    uint64 ticketId = nextTicketId++;
    ticketsByPlayer[msg.sender].push(TicketData({
      id: ticketId,
      round: currentRound,
      timestamp: uint64(block.timestamp),
      cardinality: uint64(playerNumbers.length)
    }));
    playersByTicket.push(payable(msg.sender));
    for (uint i = 0; i < playerNumbers.length; i++) {
      ticketsByNumber[currentRound][playerNumbers[i] - 1].push(ticketId);
    }
    emit Ticket(currentRound, msg.sender, playerNumbers);
    payable(owner()).sendValue(msg.value / 10);
  }

  function getTickets(address player, uint64 round) public view returns (uint64[] memory ids) {
    return ticketsByPlayer[player].getTickets(round);
  }

  function getTicket(uint64 round, uint64 ticketId)
      public view returns (address player, uint256 timestamp, uint8[] memory numbers)
  {
    player = playersByTicket[ticketId];
    require(player != address(0), 'invalid ticket');
    TicketData storage ticket = ticketsByPlayer[player].getTicket(ticketId);
    timestamp = ticket.timestamp;
    uint8[90] memory temp;
    uint count = 0;
    for (uint8 number = 0; number < 90; number++) {
      if (ticketsByNumber[round][number].contains(ticketId)) {
        temp[count++] = number + 1;
      }
    }
    numbers = new uint8[](count);
    for (uint i = 0; i < count; i++) {
      numbers[i] = temp[i];
    }
  }

  function canDraw() public view returns (bool) {
    if (block.timestamp < nextDrawTime) {
      return false;
    } else {
      return block.timestamp < Drawing.getCurrentDrawingWindow() + DRAWING_WINDOW_WIDTH;
    }
  }

  function draw(uint64 vrfSubscriptionId, bytes32 vrfKeyHash, uint32 callbackGasLimit)
      public onlyOwner
  {
    require(state == State.OPEN, 'invalid state');
    require(canDraw(), 'the next drawing window has not started yet');
    state = State.DRAWING;
    nextDrawTime += 7 days;
    uint256 vrfRequestId = _vrfCoordinator.requestRandomWords(
        vrfKeyHash,
        vrfSubscriptionId,
        /*requestConfirmations=*/10,
        callbackGasLimit,
        /*numWords=*/1);
    emit VRFRequest(currentRound, vrfRequestId);
  }

  function rawFulfillRandomWords(uint256, uint256[] memory randomWords) external whenNotPaused {
    require(msg.sender == address(_vrfCoordinator), 'permission denied');
    require(state == State.DRAWING, 'invalid state');
    draws[currentRound].numbers = Drawing.sortNumbersByTicketCount(
        ticketsByNumber[currentRound],
        Drawing.getRandomNumbersWithoutRepetitions(randomWords[0]));
    state = State.DRAWN;
    emit Draw(currentRound, draws[currentRound].numbers, address(this).balance);
  }

  function getDrawData(uint64 round)
      public view returns (uint256 blockNumber, uint8[6] memory numbers, uint64[][5] memory winners)
  {
    require(round < draws.length, 'invalid round number');
    require(round < draws.length - 1 || state > State.DRAWING, 'invalid state');
    DrawData storage data = draws[round];
    return (data.blockNumber, data.numbers, data.winners);
  }

  function findWinners() public onlyOwner {
    require(state == State.DRAWN, 'please call draw() first');
    draws[currentRound].winners = ticketsByNumber[currentRound].findWinningTickets(
        draws[currentRound].numbers);
    state = State.CLOSING;
  }

  function _getTicket(uint64 id) private view returns (TicketData storage) {
    return ticketsByPlayer[playersByTicket[id]].getTicket(id);
  }

  function _calculatePrizes(uint64[][5] storage winners) private view returns (PrizeData[] memory) {
    PrizeData[][5] memory prizes;
    uint count = 0;
    for (int i = 4; i >= 0; i--) {
      count += winners[uint(i)].length;
      prizes[uint(i)] = new PrizeData[](count);
    }
    uint offset = 0;
    for (int i = 4; i >= 0; i--) {
      uint ui = uint(i);
      uint maxMatches = ui + 2;
      for (uint j = 0; j < winners[ui].length; j++) {
        TicketData storage ticket = _getTicket(winners[ui][j]);
        for (int k = i; k >= 0; k--) {
          uint matches = uint(k) + 2;
          prizes[ui][offset + j] = PrizeData({
            ticket: winners[ui][j],
            prize: Drawing.choose(maxMatches, matches) *
                Drawing.choose(ticket.cardinality - maxMatches, 6 - matches)
          });
        }
      }
      offset += winners[ui].length;
    }
    uint256 jackpot = address(this).balance;
    for (uint i = 0; i < prizes.length; i++) {
      uint totalWeight = 0;
      for (uint j = 0; j < prizes[i].length; j++) {
        totalWeight += prizes[i][j].prize;
      }
      if (totalWeight > 0) {
        for (uint j = 0; j < prizes[i].length; j++) {
          uint weight = prizes[i][j].prize;
          prizes[i][j].prize = jackpot * weight * 18 / (totalWeight * 100);
        }
      } else {
        for (uint j = 0; j < prizes[i].length; j++) {
          prizes[i][j].prize = 0;
        }
      }
    }
    for (uint i = prizes.length - 1; i > 0; i--) {
      for (uint j = 0; j < prizes[i].length; j++) {
        prizes[0][j].prize += prizes[i][j].prize;
      }
    }
    return prizes[0];
  }

  function _reset() private {
    currentRound++;
    ticketsByNumber.push();
    draws.push();
    state = State.OPEN;
    _updateTicketPrice();
  }

  function closeRound() public onlyOwner {
    require(state == State.CLOSING, 'please call findWinners() first');
    uint256 jackpot = address(this).balance;
    PrizeData[] memory prizes = _calculatePrizes(draws[currentRound].winners);
    for (uint i = 0; i < prizes.length; i++) {
      _asyncTransfer(playersByTicket[prizes[i].ticket], prizes[i].prize);
    }
    emit CloseRound(currentRound, jackpot);
    delete prizes;
    _reset();
  }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './TicketSet.sol';


library TicketIndex {
  using TicketSet for uint64[];

  function findWinningTickets(uint64[][90] storage ticketsByNumber, uint8[6] storage numbers)
      public view returns (uint64[][5] memory winners)
  {
    winners = [
      new uint64[](0),  // tickets matching exactly 2 numbers
      new uint64[](0),  // tickets matching exactly 3 numbers
      new uint64[](0),  // tickets matching exactly 4 numbers
      new uint64[](0),  // tickets matching exactly 5 numbers
      new uint64[](0)   // tickets matching exactly 6 numbers
    ];
    uint8[6] memory i = [0, 0, 0, 0, 0, 0];
    for (i[0] = 0; i[0] < numbers.length; i[0]++) {
      uint64[] memory tickets0 = ticketsByNumber[numbers[i[0]] - 1];
      if (tickets0.length > 0) {
        for (i[1] = i[0] + 1; i[1] < numbers.length; i[1]++) {
          uint64[] memory tickets1 = tickets0.intersect(
              ticketsByNumber[numbers[i[1]] - 1]);
          if (tickets1.length > 0) {
            tickets0 = tickets0.subtract(tickets1);
            for (i[2] = i[1] + 1; i[2] < numbers.length; i[2]++) {
              uint64[] memory tickets2 = tickets1.intersect(
                  ticketsByNumber[numbers[i[2]] - 1]);
              if (tickets2.length > 0) {
                tickets1 = tickets1.subtract(tickets2);
                for (i[3] = i[2] + 1; i[3] < numbers.length; i[3]++) {
                  uint64[] memory tickets3 = tickets2.intersect(
                      ticketsByNumber[numbers[i[3]] - 1]);
                  if (tickets3.length > 0) {
                    tickets2 = tickets2.subtract(tickets3);
                    for (i[4] = i[3] + 1; i[4] < numbers.length; i[4]++) {
                      uint64[] memory tickets4 = tickets3.intersect(
                          ticketsByNumber[numbers[i[4]] - 1]);
                      if (tickets4.length > 0) {
                        tickets3 = tickets3.subtract(tickets4);
                        for (i[5] = i[4] + 1; i[5] < numbers.length; i[5]++) {
                          uint64[] memory tickets5 = tickets4.intersect(
                              ticketsByNumber[numbers[i[5]] - 1]);
                          if (tickets5.length > 0) {
                            tickets4 = tickets4.subtract(tickets5);
                            winners[4] = winners[4].union(tickets5);
                          }
                          delete tickets5;
                        }
                        winners[3] = winners[3].union(tickets4);
                      }
                      delete tickets4;
                    }
                    winners[2] = winners[2].union(tickets3);
                  }
                  delete tickets3;
                }
                winners[1] = winners[1].union(tickets2);
              }
              delete tickets2;
            }
            winners[0] = winners[0].union(tickets1);
          }
          delete tickets1;
        }
      }
      delete tickets0;
    }
    delete i;
    for (uint j = 0; j < winners.length - 1; j++) {
      for (uint k = j + 1; k < winners.length; k++) {
        winners[j] = winners[j].subtract(winners[k]);
      }
    }
  }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


library TicketSet {
  function contains(uint64[] storage array, uint64 ticketId) public view returns (bool) {
    uint i = 0;
    uint j = array.length;
    while (j > i) {
      uint k = i + ((j - i) >> 1);
      if (ticketId < array[k]) {
        j = k;
      } else if (ticketId > array[k]) {
        i = k + 1;
      } else {
        return true;
      }
    }
    return false;
  }

  function _advanceTo(uint64[] memory array, uint offset, uint64 minValue)
      private pure returns (uint)
  {
    uint i = 1;
    uint j = 2;
    while (offset + j < array.length && array[offset + j] < minValue) {
      i = j + 1;
      j <<= 1;
    }
    while (i < j) {
      uint k = i + ((j - i) >> 1);
      if (offset + k >= array.length || array[offset + k] > minValue) {
        j = k;
      } else if (array[offset + k] < minValue) {
        i = k + 1;
      } else {
        return offset + k;
      }
    }
    return offset + i;
  }

  function _advanceToStorage(uint64[] storage array, uint offset, uint64 minValue)
      private view returns (uint)
  {
    uint i = 1;
    uint j = 2;
    while (offset + j < array.length && array[offset + j] < minValue) {
      i = j + 1;
      j <<= 1;
    }
    while (i < j) {
      uint k = i + ((j - i) >> 1);
      if (offset + k >= array.length || array[offset + k] > minValue) {
        j = k;
      } else if (array[offset + k] < minValue) {
        i = k + 1;
      } else {
        return offset + k;
      }
    }
    return offset + i;
  }

  function _shrink(uint64[] memory array, uint count)
      private pure returns (uint64[] memory result)
  {
    if (count < array.length) {
      result = new uint64[](count);
      for (uint i = 0; i < result.length; i++) {
        result[i] = array[i];
      }
      delete array;
    } else {
      result = array;
    }
  }

  function intersect(uint64[] memory first, uint64[] storage second)
      public view returns (uint64[] memory result)
  {
    uint capacity = second.length < first.length ? second.length : first.length;
    result = new uint64[](capacity);
    uint i = 0;
    uint j = 0;
    uint k = 0;
    while (i < first.length && j < second.length) {
      if (first[i] < second[j]) {
        i = _advanceTo(first, i, second[j]);
      } else if (second[j] < first[i]) {
        j = _advanceToStorage(second, j, first[i]);
      } else {
        result[k++] = first[i];
        i++;
        j++;
      }
    }
    return _shrink(result, k);
  }

  function subtract(uint64[] memory left, uint64[] memory right)
      public pure returns (uint64[] memory)
  {
    if (right.length == 0) {
      return left;
    }
    uint i = 0;
    uint j = 0;
    uint k = 0;
    while (i < left.length && j < right.length) {
      if (left[i] < right[j]) {
        left[k++] = left[i++];
      } else if (left[i] > right[j]) {
        j = _advanceTo(right, j, left[i]);
      } else {
        i++;
        j++;
      }
    }
    while (i < left.length) {
      left[k++] = left[i++];
    }
    return _shrink(left, k);
  }

  function union(uint64[] memory left, uint64[] memory right)
      public pure returns (uint64[] memory result)
  {
    if (right.length == 0) {
      return left;
    }
    result = new uint64[](left.length + right.length);
    uint i = 0;
    uint j = 0;
    uint k = 0;
    while (i < left.length && j < right.length) {
      if (left[i] < right[j]) {
        result[k++] = left[i++];
      } else if (left[i] > right[j]) {
        result[k++] = right[j++];
      } else {
        result[k++] = left[i];
        i++;
        j++;
      }
    }
    while (i < left.length) {
      result[k++] = left[i++];
    }
    delete left;
    while (j < right.length) {
      result[k++] = right[j++];
    }
    return _shrink(result, k);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


struct TicketData {
  uint64 id;
  uint64 round;
  uint64 timestamp;
  uint64 cardinality;
}


library UserTickets {
  function _lowerBound(TicketData[] storage tickets, uint64 round) private view returns (uint64) {
    uint64 i = 0;
    uint64 j = uint64(tickets.length);
    while (j > i) {
      uint64 k = i + ((j - i) >> 1);
      if (round > tickets[k].round) {
        i = k + 1;
      } else {
        j = k;
      }
    }
    return i;
  }

  function _upperBound(TicketData[] storage tickets, uint64 round) private view returns (uint64) {
    uint64 i = 0;
    uint64 j = uint64(tickets.length);
    while (j > i) {
      uint64 k = i + ((j - i) >> 1);
      if (round < tickets[k].round) {
        j = k;
      } else {
        i = k + 1;
      }
    }
    return j;
  }

  function getTickets(TicketData[] storage tickets, uint64 round)
      public view returns (uint64[] memory ids)
  {
    uint64 min = _lowerBound(tickets, round);
    uint64 max = _upperBound(tickets, round);
    ids = new uint64[](max - min);
    for (uint64 i = min; i < max; i++) {
      ids[i - min] = tickets[i].id;
    }
  }

  function getTicket(TicketData[] storage tickets, uint64 ticketId)
      public view returns (TicketData storage)
  {
    uint64 i = 0;
    uint64 j = uint64(tickets.length);
    while (j > i) {
      uint64 k = i + ((j - i) >> 1);
      if (ticketId < tickets[k].id) {
        j = k;
      } else if (ticketId > tickets[k].id) {
        i = k + 1;
      } else {
        return tickets[k];
      }
    }
    revert('invalid ticket ID');
  }
}