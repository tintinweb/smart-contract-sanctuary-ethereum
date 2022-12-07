// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library Denominations {
  address public constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
  address public constant BTC = 0xbBbBBBBbbBBBbbbBbbBbbbbBBbBbbbbBbBbbBBbB;

  // Fiat currencies follow https://en.wikipedia.org/wiki/ISO_4217
  address public constant USD = address(840);
  address public constant GBP = address(826);
  address public constant EUR = address(978);
  address public constant JPY = address(392);
  address public constant KRW = address(410);
  address public constant CNY = address(156);
  address public constant AUD = address(36);
  address public constant CAD = address(124);
  address public constant CHF = address(756);
  address public constant ARS = address(32);
  address public constant PHP = address(608);
  address public constant NZD = address(554);
  address public constant SGD = address(702);
  address public constant NGN = address(566);
  address public constant ZAR = address(710);
  address public constant RUB = address(643);
  address public constant INR = address(356);
  address public constant BRL = address(986);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorInterface {
  function latestAnswer() external view returns (int256);

  function latestTimestamp() external view returns (uint256);

  function latestRound() external view returns (uint256);

  function getAnswer(uint256 roundId) external view returns (int256);

  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);

  event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AggregatorInterface.sol";
import "./AggregatorV3Interface.sol";

interface AggregatorV2V3Interface is AggregatorInterface, AggregatorV3Interface {}

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
pragma abicoder v2;

import "./AggregatorV2V3Interface.sol";

interface FeedRegistryInterface {
  struct Phase {
    uint16 phaseId;
    uint80 startingAggregatorRoundId;
    uint80 endingAggregatorRoundId;
  }

  event FeedProposed(
    address indexed asset,
    address indexed denomination,
    address indexed proposedAggregator,
    address currentAggregator,
    address sender
  );
  event FeedConfirmed(
    address indexed asset,
    address indexed denomination,
    address indexed latestAggregator,
    address previousAggregator,
    uint16 nextPhaseId,
    address sender
  );

  // V3 AggregatorV3Interface

  function decimals(address base, address quote) external view returns (uint8);

  function description(address base, address quote) external view returns (string memory);

  function version(address base, address quote) external view returns (uint256);

  function latestRoundData(address base, address quote)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function getRoundData(
    address base,
    address quote,
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  // V2 AggregatorInterface

  function latestAnswer(address base, address quote) external view returns (int256 answer);

  function latestTimestamp(address base, address quote) external view returns (uint256 timestamp);

  function latestRound(address base, address quote) external view returns (uint256 roundId);

  function getAnswer(
    address base,
    address quote,
    uint256 roundId
  ) external view returns (int256 answer);

  function getTimestamp(
    address base,
    address quote,
    uint256 roundId
  ) external view returns (uint256 timestamp);

  // Registry getters

  function getFeed(address base, address quote) external view returns (AggregatorV2V3Interface aggregator);

  function getPhaseFeed(
    address base,
    address quote,
    uint16 phaseId
  ) external view returns (AggregatorV2V3Interface aggregator);

  function isFeedEnabled(address aggregator) external view returns (bool);

  function getPhase(
    address base,
    address quote,
    uint16 phaseId
  ) external view returns (Phase memory phase);

  // Round helpers

  function getRoundFeed(
    address base,
    address quote,
    uint80 roundId
  ) external view returns (AggregatorV2V3Interface aggregator);

  function getPhaseRange(
    address base,
    address quote,
    uint16 phaseId
  ) external view returns (uint80 startingRoundId, uint80 endingRoundId);

  function getPreviousRoundId(
    address base,
    address quote,
    uint80 roundId
  ) external view returns (uint80 previousRoundId);

  function getNextRoundId(
    address base,
    address quote,
    uint80 roundId
  ) external view returns (uint80 nextRoundId);

  // Feed management

  function proposeFeed(
    address base,
    address quote,
    address aggregator
  ) external;

  function confirmFeed(
    address base,
    address quote,
    address aggregator
  ) external;

  // Proposed aggregator

  function getProposedFeed(address base, address quote)
    external
    view
    returns (AggregatorV2V3Interface proposedAggregator);

  function proposedGetRoundData(
    address base,
    address quote,
    uint80 roundId
  )
    external
    view
    returns (
      uint80 id,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function proposedLatestRoundData(address base, address quote)
    external
    view
    returns (
      uint80 id,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  // Phases
  function getCurrentPhaseId(address base, address quote) external view returns (uint16 currentPhaseId);
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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20Upgradeable.sol";

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20PermitUpgradeable {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/draft-IERC20PermitUpgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20PermitUpgradeable token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library CountersUpgradeable {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/BitMaps.sol)
pragma solidity ^0.8.0;

/**
 * @dev Library for managing uint256 to bool mapping in a compact and efficient way, providing the keys are sequential.
 * Largely inspired by Uniswap's https://github.com/Uniswap/merkle-distributor/blob/master/contracts/MerkleDistributor.sol[merkle-distributor].
 */
library BitMapsUpgradeable {
    struct BitMap {
        mapping(uint256 => uint256) _data;
    }

    /**
     * @dev Returns whether the bit at `index` is set.
     */
    function get(BitMap storage bitmap, uint256 index) internal view returns (bool) {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        return bitmap._data[bucket] & mask != 0;
    }

    /**
     * @dev Sets the bit at `index` to the boolean `value`.
     */
    function setTo(
        BitMap storage bitmap,
        uint256 index,
        bool value
    ) internal {
        if (value) {
            set(bitmap, index);
        } else {
            unset(bitmap, index);
        }
    }

    /**
     * @dev Sets the bit at `index`.
     */
    function set(BitMap storage bitmap, uint256 index) internal {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        bitmap._data[bucket] |= mask;
    }

    /**
     * @dev Unsets the bit at `index`.
     */
    function unset(BitMap storage bitmap, uint256 index) internal {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        bitmap._data[bucket] &= ~mask;
    }
}

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/interfaces/IERC20Upgradeable.sol";

interface IERC20Extended is IERC20Upgradeable {
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

interface IPriceOracle {
    /// @notice Get Price Aggregator address
    /// @param _base Base currency address
    /// @param _quote Quote currency address
    /// @return Chainlink aggregator for base/quote
    function priceAggregator(address _base, address _quote) external view returns (AggregatorV3Interface);

    /// @dev Set a new chainlink price aggregator
    /// @param _base Base currency address
    /// @param _quote Quote currency address
    function setAggregator(address _base, address _quote, address _aggregator) external;

    /// @notice Get price of `_base` in `quote`
    /// @param _base Base currency address
    /// @param _quote Quote currency address
    /// @return basePrice Base price in quote
    function getPrice(address _base, address _quote) external view returns (uint256 basePrice);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IRealEstateERC1155 {
    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function nextRealEstateId() external view returns (uint256);

    function setMinter(address _minter) external;

    function setBurner(address _burner) external;

    function mint(uint256 _id, address _to, uint256 _amount) external;

    function burn(uint256 _id, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IRealEstateReserves {
    function deposit(uint256 _id, uint256 _amount, address _currency) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { IERC20Extended } from "../interfaces/IERC20Extended.sol";
import { SafeERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import { FeedRegistryInterface } from "@chainlink/contracts/src/v0.8/interfaces/FeedRegistryInterface.sol";
import { Denominations } from "@chainlink/contracts/src/v0.8/Denominations.sol";

import { IUniswapV2Router01 } from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol";

import { IRealEstateReserves } from "../interfaces/IRealEstateReserves.sol";
import { IPriceOracle } from "../interfaces/IPriceOracle.sol";

/// @title IRO Finance
/// @author Horizon DAO (Yuri Fernandes)
/// @dev Library contain functions to perform financial computations
///     for the InitialRealEstateOffering contract
library IROFinance {
    using SafeERC20Upgradeable for IERC20Extended;

    /// @dev Number of decimals of ETH
    uint8 public constant ETH_DECIMALS = 18;

    /// @dev The denominator and maximum value for slippage
    uint16 public constant SLIPPAGE_DENOMINATOR = 10000;

    /// @dev The denominator and maximum value for fee
    uint16 public constant FEE_DENOMINATOR = 10000;

    /// @dev The denominator and maximum value for share
    uint16 public constant SHARE_DENOMINATOR = 10000;

    /// @dev The swap fee in basis points (0.3%)
    uint16 public constant SWAP_FEE = 30;

    /// @dev Structure that holds all financial types
    ///     used to swap tokens and consult relative prices
    struct Finance {
        IUniswapV2Router01 swapRouter;
        IPriceOracle priceOracle;
        address weth;
        address baseCurrency;
    }

    /// @dev Initialize the Finance structure
    /// @param _finance Finance structure
    /// @param _swapRouter Address of the Uniswap/Sushiswap router used to swap tokens
    /// @param _priceOracle Price Oracle address
    /// @param _weth WETH contract address
    /// @param _baseCurrency Address of the token used as the base precification currency
    function initializeFinance(
        Finance storage _finance,
        address _swapRouter,
        address _priceOracle,
        address _weth,
        address _baseCurrency
    ) internal {
        _finance.swapRouter = IUniswapV2Router01(_swapRouter);
        _finance.priceOracle = IPriceOracle(_priceOracle);
        _finance.weth = _weth;
        _finance.baseCurrency = _baseCurrency;
    }

    /// @dev Process commit payment
    /// @param _finance Finance structure
    /// @param _unitPrice Unit price of the token
    /// @param _paymentToken The address of the token being used for payment
    /// @param _amountToPay Expected amount to pay (without slippage)
    /// @param _amountToPurchase Amount of tokens to purchase
    /// @param _slippage Swap slippage in basis points
    /// @param _relativePath Swap path relative to the origin and end currency
    function processPayment(
        Finance memory _finance,
        uint256 _unitPrice,
        address _paymentToken,
        uint256 _amountToPay,
        uint256 _amountToPurchase,
        uint16 _slippage,
        address[] memory _relativePath
    ) internal returns (uint256 valueInBase) {
        valueInBase = _amountToPurchase * _unitPrice;
        if (_paymentToken == _finance.baseCurrency) {
            require(valueInBase == _amountToPay, "Invalid amount");
            IERC20Extended(_paymentToken).safeTransferFrom(msg.sender, address(this), valueInBase);
        } else if (_paymentToken != address(0)) {
            uint256 valueWithSlippage = (_amountToPay * SLIPPAGE_DENOMINATOR + _slippage) / SLIPPAGE_DENOMINATOR;
            IERC20Extended(_paymentToken).safeTransferFrom(msg.sender, address(this), valueWithSlippage);
            IERC20Extended(_paymentToken).safeApprove(address(_finance.swapRouter), valueWithSlippage);
            address[] memory path = new address[](_relativePath.length + 2);
            path[0] = _paymentToken;
            for (uint256 i = 0; i < _relativePath.length; i++) {
                path[i + 1] = _relativePath[i];
            }
            path[path.length - 1] = _finance.baseCurrency;
            uint256[] memory amounts = _finance.swapRouter.swapTokensForExactTokens(
                valueInBase,
                valueWithSlippage,
                path,
                address(this),
                block.timestamp
            );
            if (amounts[0] < valueWithSlippage) {
                sendErc20(msg.sender, valueWithSlippage - amounts[0], _paymentToken);
            }
        } else {
            uint256 valueWithSlippage = (_amountToPay * SLIPPAGE_DENOMINATOR + _slippage) / SLIPPAGE_DENOMINATOR;
            require(msg.value >= valueWithSlippage, "Not enough ethers sent");
            address[] memory path = new address[](_relativePath.length + 2);
            path[0] = _finance.weth;
            for (uint256 i = 0; i < _relativePath.length; i++) {
                path[i + 1] = _relativePath[i];
            }
            path[path.length - 1] = _finance.baseCurrency;
            uint256[] memory amounts = _finance.swapRouter.swapETHForExactTokens{ value: valueWithSlippage }(
                valueInBase,
                path,
                address(this),
                block.timestamp
            );
            if (amounts[0] < msg.value) {
                sendEther(msg.sender, msg.value - amounts[0]);
            }
        }
    }

    /// @notice Get the expected price of an IRO purchase (without slippage)
    /// @param _finance Finance structure
    /// @param _unitPrice Unit price of the token
    /// @param _currency Payment token address
    /// @param _amountToPurchase Amount of IRO tokens to purchase
    /// @param _pathLength Swap path length
    function expectedPrice(
        Finance memory _finance,
        uint256 _unitPrice,
        address _currency,
        uint256 _amountToPurchase,
        uint256 _pathLength
    ) internal view returns (uint256) {
        uint256 valueInBase = _amountToPurchase * _unitPrice;
        if (_currency == _finance.baseCurrency) {
            return valueInBase;
        }
        return
            (convertBaseToPaymentToken(_finance, valueInBase, _currency) *
                (FEE_DENOMINATOR + (_pathLength - 1) * SWAP_FEE)) / FEE_DENOMINATOR;
    }

    /// @notice Get the price with slippage
    /// @param _finance Finance structure
    /// @param _unitPrice Unit price of the token
    /// @param _paymentToken Payment token address
    /// @param _amountToPurchase Amount of IRO tokens to purchase
    /// @param _slippage Swap slippage in basis points
    /// @param _pathLength Swap path length
    function priceWithSlippage(
        Finance memory _finance,
        uint256 _unitPrice,
        address _paymentToken,
        uint256 _amountToPurchase,
        uint16 _slippage,
        uint256 _pathLength
    ) internal view returns (uint256) {
        uint256 expectedPrice_ = expectedPrice(_finance, _unitPrice, _paymentToken, _amountToPurchase, _pathLength);
        if (_paymentToken == _finance.baseCurrency) return expectedPrice_;
        return (expectedPrice_ * (SLIPPAGE_DENOMINATOR + _slippage)) / SLIPPAGE_DENOMINATOR;
    }

    /// @dev Convert token share to amount
    /// @param _totalFunding Total IRO funding
    /// @param _unitPrice IRO token unit price
    /// @param _share Token share
    /// @return amount Amount of tokens
    function shareToAmount(
        uint256 _totalFunding,
        uint256 _unitPrice,
        uint16 _share
    ) internal pure returns (uint256 amount) {
        uint256 totalPurchased = _totalFunding / _unitPrice;
        amount = (totalPurchased * _share) / (IROFinance.SHARE_DENOMINATOR - _share);
    }

    /// @dev Distribute funds during IRO withdrawal
    /// @param _finance Finance structure
    /// @param _listingOwner The listing owner of the IRO
    /// @param _treasury Treasury contract address
    /// @param _realEstateReserves RealEstateReserves contract address
    /// @param _realEstateId ID of the RealEstate token to receive the funds
    /// @param _totalFunding Total funds from the IRO
    /// @param _listingOwnerFee Fee requested by the listing owner
    /// @param _treasuryFee Treasury fee
    function distributeFunds(
        Finance memory _finance,
        address _listingOwner,
        address _treasury,
        IRealEstateReserves _realEstateReserves,
        uint256 _realEstateId,
        uint256 _totalFunding,
        uint256 _listingOwnerFee,
        uint256 _treasuryFee
    )
        internal
        returns (
            uint256 listingOwnerAmount,
            uint256 treasuryAmount,
            uint256 realEstateReservesAmount,
            bool realEstateReservesSet
        )
    {
        if (_listingOwnerFee > 0) {
            listingOwnerAmount = (_listingOwnerFee * _totalFunding) / FEE_DENOMINATOR;
            sendErc20(_listingOwner, listingOwnerAmount, _finance.baseCurrency);
        }
        treasuryAmount = (_treasuryFee * _totalFunding) / FEE_DENOMINATOR;
        realEstateReservesAmount = _totalFunding - (listingOwnerAmount + treasuryAmount);
        if (address(_realEstateReserves) != address(0)) {
            realEstateReservesSet = true;
            if (treasuryAmount > 0) {
                sendErc20(_treasury, treasuryAmount, _finance.baseCurrency);
            }

            if (realEstateReservesAmount > 0) {
                IERC20Extended(_finance.baseCurrency).safeApprove(
                    address(_realEstateReserves),
                    realEstateReservesAmount
                );
                _realEstateReserves.deposit(_realEstateId, realEstateReservesAmount, _finance.baseCurrency);
            }
        } else {
            sendErc20(_treasury, _totalFunding - listingOwnerAmount, _finance.baseCurrency);
        }
    }

    /// @dev Utility function to send an amount of ethers to a given address
    /// @param _to Address to send ethers
    /// @param _amount Amount of ethers to send
    function sendEther(address _to, uint256 _amount) internal {
        (bool success, ) = _to.call{ value: _amount }("");
        require(success, "Failed sending ethers");
    }

    /// @dev Utility function to send an amount of ERC20 tokens to a given address
    /// @param _to Address to send tokens
    /// @param _amount Amount of tokens to send
    /// @param _token Address of the token to send
    function sendErc20(address _to, uint256 _amount, address _token) internal {
        IERC20Extended(_token).safeTransfer(_to, _amount);
    }

    /// @dev Convert a base currency amount to a given payment token
    /// @param _finance Finance structure
    /// @param _valueInBase Value in base tokens
    /// @param _paymentToken Payment token address
    /// @return Price in payment tokens
    function convertBaseToPaymentToken(
        Finance memory _finance,
        uint256 _valueInBase,
        address _paymentToken
    ) internal view returns (uint256) {
        uint256 paymentTokenPriceInBase = _finance.priceOracle.getPrice(_paymentToken, _finance.baseCurrency);
        uint8 paymentTokenDecimals = IERC20Extended(_paymentToken).decimals();

        return (_valueInBase * 10 ** uint256(paymentTokenDecimals)) / paymentTokenPriceInBase;
    }

    /// @dev Get the number of decimals of a token
    /// @param _token Token address
    /// @return Number of decimals
    function _getTokenDecimals(address _token) private view returns (uint8) {
        if (_token == address(0)) return ETH_DECIMALS;
        return IERC20Extended(_token).decimals();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { CountersUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import { BitMapsUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/structs/BitMapsUpgradeable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import { IRealEstateERC1155 } from "../interfaces/IRealEstateERC1155.sol";
import { IRealEstateReserves } from "../interfaces/IRealEstateReserves.sol";
import { IROFinance } from "../libraries/IROFinance.sol";

/// @title Initial Real Estate Offering (IRO)
/// @author Horizon DAO (Yuri Fernandes)
/// @notice Used to run IROs, mint tokens to RealEstateNFT
///     and distribute funds
contract InitialRealEstateOffering is OwnableUpgradeable, UUPSUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using BitMapsUpgradeable for BitMapsUpgradeable.BitMap;
    using IROFinance for IROFinance.Finance;

    /// @dev IRO status enum
    enum Status {
        PENDING,
        ONGOING,
        SUCCESS,
        FAIL
    }

    /// @dev Initial Real Estate Offerring structure
    /// @dev Since timestamps are 64 bit integers, last IRO
    ///     should finish at 21 de julho de 2554 11:34:33.709 UTC.
    struct IRO {
        address listingOwner;
        uint64 start;
        uint16 treasuryFee;
        uint16 listingOwnerFee;
        uint16 listingOwnerShare;
        uint64 end;
        uint256 softCap;
        uint256 hardCap;
        uint256 unitPrice;
        uint256 totalFunding;
    }

    struct WhitelistedCurrency {
        bool whitelisted;
        address[] relativePath;
    }

    /// @notice Treasury contract address
    address public treasury;

    /// @notice RealEstateNFT contract address
    IRealEstateERC1155 public realEstateNft;

    /// @notice RealEstateReserves contract address
    IRealEstateReserves public realEstateReserves;

    /// @notice Structure composed by the addresses
    ///     of contracts responsible for making financial operations
    IROFinance.Finance public finance;

    /// @dev Next available IRO ID
    CountersUpgradeable.Counter private _nextAvailableId;

    /// @dev mapping (iroId => iro)
    mapping(uint256 => IRO) private _iros;

    /// @dev mapping (iroId => user => commit)
    mapping(uint256 => mapping(address => uint256)) public commits;

    /// @dev mapping (iroId => realEstateId)
    mapping(uint256 => uint256) public realEstateId;

    /// @dev mapping (currencyAddress => WhitelistedCurrency)
    mapping(address => WhitelistedCurrency) public whitelistedCurrency;

    /// @dev Points out whether funds have been withdrawn from IRO
    BitMapsUpgradeable.BitMap private _fundsWithdrawn;

    /// @dev Points out whether the listingOwner has claimed it's share
    BitMapsUpgradeable.BitMap private _listingOwnerClaimed;

    /// @dev Whether an ID has already been set in the RealEstateNFT contract for the IRO
    BitMapsUpgradeable.BitMap private _realEstateIdSet;

    /// @dev Emitted when a new IRO is created
    event CreateIRO(
        uint256 indexed _id,
        address indexed _listingOwner,
        uint256 _unitPrice,
        uint16 _listingOwnerShare,
        uint16 _treasuryFee,
        uint64 _start,
        uint64 _end
    );

    /// @dev Emitted when a new Commit is made to an IRO
    event Commit(
        uint256 indexed _iroId,
        address indexed _user,
        address indexed _currency,
        uint256 _amountInBase,
        uint256 _purchasedTokens
    );

    /// @dev Emitted when `whitelistCurrency` is executed
    event WhitelistCurrency(address indexed _by, address indexed _currency, bool indexed _whitelist);

    /// @dev Emitted when tokens are claimed by investors
    event TokensClaimed(uint256 indexed _iroId, address indexed _by, address indexed _to, uint256 _amount);

    /// @dev Emitted when the listing owner claims it's shares of the tokens
    event OwnerTokensClaimed(uint256 indexed _iroId, address indexed _by, address indexed _to, uint256 _amount);

    /// @dev Emitted when an investors withdraw it's funds after an IRO fails
    event CashBack(uint256 indexed _iroId, address indexed _by, address indexed _to, uint256 _commitAmount);

    /// @dev Emitted when a new base currency is set
    event SetBaseCurrency(address indexed _by, address indexed _baseCurrency);

    /// @dev Emitted when the currency relative path is updated
    event PathUpdated(address indexed _by, address indexed _currency);

    event SetTreasury(address indexed _by, address indexed _treasury);

    event SetRealEstateReserves(address indexed _by, address indexed _realEstateReserves);

    /// @dev Emitted when funds from an IRO are withdrawn
    event FundsWithdrawn(
        uint256 indexed _iroId,
        address indexed _by,
        bool indexed _realEstateFundsSet,
        uint256 _listingOwnerAmount,
        uint256 _treasuryAmount,
        uint256 _realEstateFundsAmount
    );

    /// @dev Initialize IRO contract
    /// @param _realEstateNft RealEstateNFT contract address
    /// @param _treasury Treasury contract address
    /// @param _realEstateReserves RealEstateReserves contract address
    /// @param _baseCurrency Base token used to precify the IRO tokens
    /// @param _priceFeedRegistry Chainlink Price Feed Registry address
    /// @param _swapRouter Uniswap or Sushiswap swap router
    /// @param _weth WETH contract address
    function initialize(
        address _owner,
        address _realEstateNft,
        address _treasury,
        address _realEstateReserves,
        address _baseCurrency,
        address _priceFeedRegistry,
        address _swapRouter,
        address _weth
    ) external initializer {
        require(_realEstateNft != address(0), "!_realEstateNft");
        require(_treasury != address(0), "!_treasury");
        require(_baseCurrency != address(0), "!_baseCurrency");
        require(_priceFeedRegistry != address(0), "!_priceFeedRegistry");
        require(_swapRouter != address(0), "!_swapRouter");
        require(_weth != address(0), "!_weth");
        realEstateNft = IRealEstateERC1155(_realEstateNft);
        treasury = _treasury;
        realEstateReserves = IRealEstateReserves(_realEstateReserves);
        finance.initializeFinance(_swapRouter, _priceFeedRegistry, _weth, _baseCurrency);
        whitelistedCurrency[address(0)].whitelisted = true;
        _transferOwnership(_owner);
    }

    /// @dev Set a new base price token
    /// @param _baseCurrency Base price token address (ERC20)
    function setBaseCurrency(address _baseCurrency) external onlyOwner {
        require(_baseCurrency != address(0), "!_baseCurrency");
        finance.baseCurrency = _baseCurrency;
        emit SetBaseCurrency(msg.sender, _baseCurrency);
    }

    /// @dev Set new treasury
    /// @param _treasury Treasury address
    function setTreasury(address _treasury) external onlyOwner {
        require(_treasury != address(0), "!_treasury");
        treasury = _treasury;
        emit SetTreasury(msg.sender, _treasury);
    }

    /// @dev Set new real estate reserves
    /// @param _realEstateReserves RealEstateReseres address
    function setRealEstateReserves(address _realEstateReserves) external onlyOwner {
        require(_realEstateReserves != address(0), "!_realEstateReserves");
        realEstateReserves = IRealEstateReserves(_realEstateReserves);
        emit SetRealEstateReserves(msg.sender, _realEstateReserves);
    }

    /// @dev Create new IRO
    /// @param _listingOwner Listing owner address
    /// @param _listingOwnerFee Listing owner fee in basis points
    /// @param _listingOwnerShare Listing owner share of IRO tokens in basis points
    /// @param _treasuryFee Treasury fee percentage in basis points
    /// @param _duration Duration of the IRO in seconds
    /// @param _softCap Minimum fundraising in base price token
    /// @param _hardCap Maximum fundraising in base price token
    /// @param _unitPrice Price per unit of IRO token in base price token
    /// @param _startOffset Time before IRO begins
    function createIRO(
        address _listingOwner,
        uint16 _listingOwnerFee,
        uint16 _listingOwnerShare,
        uint16 _treasuryFee,
        uint64 _duration,
        uint256 _softCap,
        uint256 _hardCap,
        uint256 _unitPrice,
        uint64 _startOffset
    ) external onlyOwner {
        require(_listingOwnerShare <= IROFinance.SHARE_DENOMINATOR, "Invalid owner share");
        require(_treasuryFee <= IROFinance.FEE_DENOMINATOR, "Invalid treasury fee");
        require((_hardCap - _softCap) % _unitPrice == 0, "Caps should be multiples of unitPrice");

        uint256 currentId = iroLength();
        uint64 start_ = now64() + _startOffset;
        uint64 end_ = start_ + _duration;
        _iros[currentId] = IRO({
            listingOwner: _listingOwner,
            start: start_,
            treasuryFee: _treasuryFee,
            listingOwnerFee: _listingOwnerFee,
            listingOwnerShare: _listingOwnerShare,
            end: end_,
            softCap: _softCap,
            hardCap: _hardCap,
            unitPrice: _unitPrice,
            totalFunding: 0
        });
        _nextAvailableId.increment();

        emit CreateIRO(currentId, _listingOwner, _unitPrice, _listingOwnerShare, _treasuryFee, start_, end_);
    }

    /// @notice Commit to an IRO
    /// @param _iroId ID of the IRO
    /// @param _currency Currency address
    /// @param _amountToPay Expected amount to pay (without slippage)
    /// @param _amountToPurchase Amount of IRO tokens to purchase
    /// @param _slippage Slippage in basis points when swapping token by
    ///     base currency (not applicable when paying directly with it)
    function commit(
        uint256 _iroId,
        address _currency,
        uint256 _amountToPay,
        uint256 _amountToPurchase,
        uint16 _slippage
    ) external payable {
        require(_amountToPurchase > 0, "_amountToPurchase should be greater than zero");
        WhitelistedCurrency memory whitelistedCurrency_ = whitelistedCurrency[_currency];
        require(_currency == finance.baseCurrency || whitelistedCurrency_.whitelisted, "Currency not allowed");
        require(_slippage <= IROFinance.SLIPPAGE_DENOMINATOR, "Invalid _slippage");
        IRO memory iro = getIRO(_iroId);
        require(_getStatus(iro) == Status.ONGOING, "IRO is not active");
        require(iro.totalFunding + _amountToPurchase * iro.unitPrice <= iro.hardCap, "Hardcap reached");
        if (_currency != address(0) && msg.value > 0) {
            IROFinance.sendEther(msg.sender, msg.value);
        }

        uint256 valueInBase = finance.processPayment(
            iro.unitPrice,
            _currency,
            _amountToPay,
            _amountToPurchase,
            _slippage,
            whitelistedCurrency_.relativePath
        );

        commits[_iroId][msg.sender] += _amountToPurchase;
        _iros[_iroId].totalFunding += valueInBase;

        emit Commit(_iroId, msg.sender, _currency, valueInBase, _amountToPurchase);
    }

    /// @dev Enable receiving ETH
    receive() external payable {}

    /// @notice Claim purchased tokens when IRO successful or
    ///     get back commit amount in base currency if IRO failed
    /// @param _iroId ID of the IRO
    /// @param _to Address to send the claimed tokens
    function claim(uint256 _iroId, address _to) external {
        IRO memory iro = getIRO(_iroId);
        Status status = _getStatus(iro);
        require(status > Status.ONGOING, "IRO not finished");
        uint256 commitAmount = commits[_iroId][msg.sender];
        require(commitAmount > 0, "Nothing to mint");
        if (status == Status.SUCCESS) {
            uint256 amountToMint = commitAmount / iro.unitPrice;
            realEstateNft.mint(_retrieveRealEstateId(_iroId), msg.sender, amountToMint);
            emit TokensClaimed(_iroId, msg.sender, _to, amountToMint);
        } else {
            IROFinance.sendErc20(_to, commitAmount, finance.baseCurrency);
            commits[_iroId][msg.sender] = 0;
            emit CashBack(_iroId, msg.sender, _to, commitAmount);
        }
    }

    /// @notice Claim listing owner tokens
    /// @param _iroId ID of the IRO
    /// @param _to Address to send the tokens
    function listingOwnerClaim(uint256 _iroId, address _to) external {
        IRO memory iro = getIRO(_iroId);
        require(msg.sender == iro.listingOwner, "!allowed");
        require(!_listingOwnerClaimed.get(_iroId), "Already claimed");
        require(_getStatus(iro) == Status.SUCCESS, "IRO not successful");
        require(iro.listingOwnerShare > 0, "Nothing to claim");
        uint256 listingOwnerAmount = IROFinance.shareToAmount(iro.totalFunding, iro.unitPrice, iro.listingOwnerShare);
        realEstateNft.mint(_retrieveRealEstateId(_iroId), _to, listingOwnerAmount);
        _listingOwnerClaimed.set(_iroId);
        emit OwnerTokensClaimed(_iroId, msg.sender, _to, listingOwnerAmount);
    }

    /// @notice Withdraw and distribute funds from successful IROs
    /// @param _iroId ID of the IRO
    function withdraw(uint256 _iroId) external {
        IRO memory iro = getIRO(_iroId);
        require(_getStatus(iro) == Status.SUCCESS, "IRO not successful");
        require(!_fundsWithdrawn.get(_iroId), "Already withdrawn");
        (
            uint256 listingOwnerAmount,
            uint256 treasuryAmount,
            uint256 realEstateReservesAmount,
            bool realEstateReservesSet
        ) = finance.distributeFunds(
                iro.listingOwner,
                treasury,
                realEstateReserves,
                _retrieveRealEstateId(_iroId),
                iro.totalFunding,
                iro.listingOwnerFee,
                iro.treasuryFee
            );
        _fundsWithdrawn.set(_iroId);
        emit FundsWithdrawn(
            _iroId,
            msg.sender,
            realEstateReservesSet,
            listingOwnerAmount,
            treasuryAmount,
            realEstateReservesAmount
        );
    }

    /// @dev Whitelist currencies
    /// @param _currency Currency ERC20 address
    /// @param _whitelist Whether to whitelist
    function whitelistCurrency(address _currency, bool _whitelist) external onlyOwner {
        require(_currency != address(0), "!invalid address");
        whitelistedCurrency[_currency].whitelisted = _whitelist;
        emit WhitelistCurrency(msg.sender, _currency, _whitelist);
    }

    /// @dev Update relative swap router path of a currency
    /// @param _currency Currency ERC20 address
    /// @param _relativePath Swap relative path
    function setrelativePath(address _currency, address[] memory _relativePath) external onlyOwner {
        require(_currency != address(0), "!invalid address");
        whitelistedCurrency[_currency].relativePath = _relativePath;
        emit PathUpdated(msg.sender, _currency);
    }

    /// @notice Get the expected price of an IRO purchase (without slippage)
    /// @notice Takes into account swap fees
    /// @param _iroId ID of the IRO
    /// @param _currency Currency address
    /// @param _amountToPurchase Amount of IRO tokens to purchase
    function expectedPrice(
        uint256 _iroId,
        address _currency,
        uint256 _amountToPurchase
    ) external view returns (uint256) {
        WhitelistedCurrency memory whitelistedCurrency_ = whitelistedCurrency[_currency];
        require(whitelistedCurrency_.whitelisted, "Currency is not available");
        IRO memory iro = getIRO(_iroId);
        return
            finance.expectedPrice(
                iro.unitPrice,
                _currency,
                _amountToPurchase,
                whitelistedCurrency_.relativePath.length + 2
            );
    }

    /// @notice Get the price with slippage
    /// @notice Takes into account swap fees
    /// @param _iroId ID of the IRO
    /// @param _currency Currency address
    /// @param _amountToPurchase Amount of IRO tokens to purchase
    /// @param _slippage Swap slippage in basis points
    function priceWithSlippage(
        uint256 _iroId,
        address _currency,
        uint256 _amountToPurchase,
        uint16 _slippage
    ) external view returns (uint256) {
        WhitelistedCurrency memory whitelistedCurrency_ = whitelistedCurrency[_currency];
        require(whitelistedCurrency_.whitelisted, "Currency is not available");
        IRO memory iro = getIRO(_iroId);
        return
            finance.priceWithSlippage(
                iro.unitPrice,
                _currency,
                _amountToPurchase,
                _slippage,
                whitelistedCurrency_.relativePath.length + 2
            );
    }

    /// @notice Get the amount of remaining IRO tokens
    /// @param _iroId ID of the IRO
    function remainingTokens(uint256 _iroId) external view returns (uint256) {
        IRO memory iro = getIRO(_iroId);
        return (iro.hardCap - iro.totalFunding) / iro.unitPrice;
    }

    /// @notice Get IRO status
    /// @param _iroId ID of the IRO
    function getStatus(uint256 _iroId) external view returns (Status) {
        IRO memory iro = _iros[_iroId];
        return _getStatus(iro);
    }

    /// @notice Check slippage denominator
    function slippageDenominator() external pure returns (uint16) {
        return IROFinance.SLIPPAGE_DENOMINATOR;
    }

    /// @notice Check fee denominator
    function feeDenominator() external pure returns (uint16) {
        return IROFinance.FEE_DENOMINATOR;
    }

    /// @notice Check share denominator
    function shareDenominator() external pure returns (uint16) {
        return IROFinance.SHARE_DENOMINATOR;
    }

    /// @notice Get IRO
    /// @param _iroId ID of the IRO
    function getIRO(uint256 _iroId) public view returns (IRO memory) {
        require(_iroId < iroLength(), "_iroId out-of-bounds");
        return _iros[_iroId];
    }

    /// @notice Get current time (uint64)
    function now64() public view returns (uint64) {
        return uint64(block.timestamp);
    }

    /// @notice Get total amount of IROs
    function iroLength() public view returns (uint256) {
        return _nextAvailableId.current();
    }

    /// @dev Retrieve the realEstateId associated with a given IRO
    /// @dev If none is assigned, assigns a new one
    /// @param _iroId ID of the IRO
    function _retrieveRealEstateId(uint256 _iroId) internal returns (uint256 _realEstateId) {
        if (!_realEstateIdSet.get(_iroId)) {
            _realEstateId = realEstateNft.nextRealEstateId();
            realEstateId[_iroId] = _realEstateId;
            _realEstateIdSet.set(_iroId);
        } else {
            _realEstateId = realEstateId[_iroId];
        }
    }

    /// @inheritdoc UUPSUpgradeable
    function _authorizeUpgrade(address newImplementation) internal virtual override onlyOwner {}

    /// @dev Get status of an IRO
    /// @param _iro IRO structure
    function _getStatus(IRO memory _iro) internal view returns (Status) {
        if (now64() <= _iro.start) return Status.PENDING;
        if (now64() < _iro.end) {
            if (_iro.totalFunding == _iro.hardCap) return Status.SUCCESS;
            return Status.ONGOING;
        }
        if (now64() >= _iro.end) {
            if (_iro.totalFunding < _iro.softCap) return Status.FAIL;
            return Status.SUCCESS;
        }
        return Status.FAIL;
    }
}