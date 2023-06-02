// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../Auctions/DutchAuction.sol';
import '../Auctions/EnglishAuction.sol';
import '../Auctions/FixedPriceSale.sol';
import '../NFT/NFUToken.sol';
import '../TokenLiquidator.sol';
import './Deployer_v005.sol';
import './Factories/NFTRewardDataSourceFactory.sol';

/**
 * @notice This version of the deployer adds the ability to deploy NFTRewardDataSourceDelegate instances and related contracts to allow projects to issue NFTs to contributing accounts.
 */
/// @custom:oz-upgrades-unsafe-allow external-library-linking
contract Deployer_v006 is Deployer_v005 {
  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  function initialize(
    DutchAuctionHouse _dutchAuctionSource,
    EnglishAuctionHouse _englishAuctionSource,
    FixedPriceSale _fixedPriceSaleSource,
    NFUToken _nfuTokenSource,
    NFUMembership _nfuMembershipSource,
    ITokenLiquidator _tokenLiquidator
  ) public virtual override reinitializer(6) {
    __Ownable_init();
    __UUPSUpgradeable_init();

    dutchAuctionSource = _dutchAuctionSource;
    englishAuctionSource = _englishAuctionSource;
    fixedPriceSaleSource = _fixedPriceSaleSource;
    nfuTokenSource = _nfuTokenSource;
    nfuMembershipSource = _nfuMembershipSource;
    tokenLiquidator = _tokenLiquidator;
  }

  function deployOpenTieredTokenUriResolver(
    string memory _baseUri
  ) external returns (address resolver) {
    resolver = NFTRewardDataSourceFactory.createOpenTieredTokenUriResolver(_baseUri);
    emit Deployment('OpenTieredTokenUriResolver', resolver);
  }

  function deployOpenTieredPriceResolver(
    address _contributionToken,
    OpenRewardTier[] memory _tiers
  ) external returns (address resolver) {
    resolver = NFTRewardDataSourceFactory.createOpenTieredPriceResolver(_contributionToken, _tiers);
    emit Deployment('OpenTieredPriceResolver', resolver);
  }

  function deployTieredTokenUriResolver(
    string memory _baseUri,
    uint256[] memory _idRange
  ) external returns (address resolver) {
    resolver = NFTRewardDataSourceFactory.createTieredTokenUriResolver(_baseUri, _idRange);
    emit Deployment('TieredTokenUriResolver', resolver);
  }

  function deployTieredPriceResolver(
    address _contributionToken,
    uint256 _mintCap,
    uint256 _userMintCap,
    RewardTier[] memory _tiers
  ) external returns (address resolver) {
    resolver = NFTRewardDataSourceFactory.createTieredPriceResolver(
      _contributionToken,
      _mintCap,
      _userMintCap,
      _tiers
    );

    emit Deployment('TieredPriceResolver', resolver);
  }

  function deployNFTRewardDataSource(
    uint256 _projectId,
    IJBDirectory _jbxDirectory,
    uint256 _maxSupply,
    JBTokenAmount memory _minContribution,
    string memory _name,
    string memory _symbol,
    string memory _uri,
    IToken721UriResolver _tokenUriResolverAddress,
    string memory _contractMetadataUri,
    address _admin,
    IPriceResolver _priceResolver
  ) external returns (address datasource) {
    datasource = NFTRewardDataSourceFactory.createNFTRewardDataSource(
      _projectId,
      _jbxDirectory,
      _maxSupply,
      _minContribution,
      _name,
      _symbol,
      _uri,
      _tokenUriResolverAddress,
      _contractMetadataUri,
      _admin,
      _priceResolver
    );

    emit Deployment('NFTRewardDataSourceDelegate', datasource);
  }
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
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

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
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
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
// OpenZeppelin Contracts (last updated v4.8.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(account),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlEnumerable.sol";
import "./AccessControl.sol";
import "../utils/structs/EnumerableSet.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerable is IAccessControlEnumerable, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(bytes32 => EnumerableSet.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view virtual override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view virtual override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {_grantRole} to track enumerable memberships
     */
    function _grantRole(bytes32 role, address account) internal virtual override {
        super._grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {_revokeRole} to track enumerable memberships
     */
    function _revokeRole(bytes32 role, address account) internal virtual override {
        super._revokeRole(role, account);
        _roleMembers[role].remove(account);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable is IAccessControl {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create(0, 0x09, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create2(0, 0x09, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(add(ptr, 0x38), deployer)
            mstore(add(ptr, 0x24), 0x5af43d82803e903d91602b57fd5bf3ff)
            mstore(add(ptr, 0x14), implementation)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73)
            mstore(add(ptr, 0x58), salt)
            mstore(add(ptr, 0x78), keccak256(add(ptr, 0x0c), 0x37))
            predicted := keccak256(add(ptr, 0x43), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
abstract contract ReentrancyGuard {
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

    constructor() {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4;

import "prb-math/contracts/PRBMath.sol";

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /*//////////////////////////////////////////////////////////////
                         METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    function tokenURI(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                      ERC721 BALANCE/OWNER STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) internal _ownerOf;

    mapping(address => uint256) internal _balanceOf;

    function ownerOf(uint256 id) public view virtual returns (address owner) {
        require((owner = _ownerOf[id]) != address(0), "NOT_MINTED");
    }

    function balanceOf(address owner) public view virtual returns (uint256) {
        require(owner != address(0), "ZERO_ADDRESS");

        return _balanceOf[owner];
    }

    /*//////////////////////////////////////////////////////////////
                         ERC721 APPROVAL STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public virtual {
        address owner = _ownerOf[id];

        require(msg.sender == owner || isApprovedForAll[owner][msg.sender], "NOT_AUTHORIZED");

        getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        require(from == _ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from || isApprovedForAll[from][msg.sender] || msg.sender == getApproved[id],
            "NOT_AUTHORIZED"
        );

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            _balanceOf[from]--;

            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        delete getApproved[id];

        emit Transfer(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes calldata data
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");

        require(_ownerOf[id] == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = _ownerOf[id];

        require(owner != address(0), "NOT_MINTED");

        // Ownership check above ensures no underflow.
        unchecked {
            _balanceOf[owner]--;
        }

        delete _ownerOf[id];

        delete getApproved[id];

        emit Transfer(owner, address(0), id);
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL SAFE MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    function _safeMint(address to, uint256 id) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _safeMint(
        address to,
        uint256 id,
        bytes memory data
    ) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721TokenReceiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import '@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol';

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './../interfaces/IJBOperatable.sol';

/** 
  @notice
  Modifiers to allow access to functions based on the message sender's operator status.

  @dev
  Adheres to -
  IJBOperatable: General interface for the methods in this contract that interact with the blockchain's state according to the protocol's rules.
*/
abstract contract JBOperatable is IJBOperatable {
  //*********************************************************************//
  // --------------------------- custom errors -------------------------- //
  //*********************************************************************//
  error UNAUTHORIZED();

  //*********************************************************************//
  // ---------------------------- modifiers ---------------------------- //
  //*********************************************************************//

  /** 
    @notice
    Only allows the speficied account or an operator of the account to proceed. 

    @param _account The account to check for.
    @param _domain The domain namespace to look for an operator within. 
    @param _permissionIndex The index of the permission to check for. 
  */
  modifier requirePermission(
    address _account,
    uint256 _domain,
    uint256 _permissionIndex
  ) {
    _requirePermission(_account, _domain, _permissionIndex);
    _;
  }

  /** 
    @notice
    Only allows the speficied account, an operator of the account to proceed, or a truthy override flag. 

    @param _account The account to check for.
    @param _domain The domain namespace to look for an operator within. 
    @param _permissionIndex The index of the permission to check for. 
    @param _override A condition to force allowance for.
  */
  modifier requirePermissionAllowingOverride(
    address _account,
    uint256 _domain,
    uint256 _permissionIndex,
    bool _override
  ) {
    _requirePermissionAllowingOverride(_account, _domain, _permissionIndex, _override);
    _;
  }

  //*********************************************************************//
  // ---------------- public immutable stored properties --------------- //
  //*********************************************************************//

  /** 
    @notice 
    A contract storing operator assignments.
  */
  IJBOperatorStore public override operatorStore;

  //*********************************************************************//
  // -------------------------- internal views ------------------------- //
  //*********************************************************************//

  /** 
    @notice
    Require the message sender is either the account or has the specified permission.

    @param _account The account to allow.
    @param _domain The domain namespace within which the permission index will be checked.
    @param _permissionIndex The permission index that an operator must have within the specified domain to be allowed.
  */
  function _requirePermission(
    address _account,
    uint256 _domain,
    uint256 _permissionIndex
  ) internal view {
    if (
      msg.sender != _account &&
      !operatorStore.hasPermission(msg.sender, _account, _domain, _permissionIndex) &&
      !operatorStore.hasPermission(msg.sender, _account, 0, _permissionIndex)
    ) revert UNAUTHORIZED();
  }

  /** 
    @notice
    Require the message sender is either the account, has the specified permission, or the override condition is true.

    @param _account The account to allow.
    @param _domain The domain namespace within which the permission index will be checked.
    @param _domain The permission index that an operator must have within the specified domain to be allowed.
    @param _override The override condition to allow.
  */
  function _requirePermissionAllowingOverride(
    address _account,
    uint256 _domain,
    uint256 _permissionIndex,
    bool _override
  ) internal view {
    if (
      !_override &&
      msg.sender != _account &&
      !operatorStore.hasPermission(msg.sender, _account, _domain, _permissionIndex) &&
      !operatorStore.hasPermission(msg.sender, _account, 0, _permissionIndex)
    ) revert UNAUTHORIZED();
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

enum JBBallotState {
  Active,
  Approved,
  Failed
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';

import '../../interfaces/IJBDirectory.sol';
import '../../libraries/JBConstants.sol';
import '../../libraries/JBTokens.sol';
import '../../structs/JBSplit.sol';

import '../Utils/JBSplitPayerUtil.sol';

import './INFTAuction.sol';

interface IDutchAuctionHouse is INFTAuction {
  event CreateDutchAuction(
    address seller,
    IERC721 collection,
    uint256 item,
    uint256 startingPrice,
    uint256 endingPrice,
    uint256 expiration,
    string memo
  );

  event PlaceDutchBid(
    address bidder,
    IERC721 collection,
    uint256 item,
    uint256 bidAmount,
    string memo
  );

  event ConcludeDutchAuction(
    address seller,
    address bidder,
    IERC721 collection,
    uint256 item,
    uint256 closePrice,
    string memo
  );
}

struct DutchAuctionData {
  uint256 info; // seller, start time
  uint256 prices;
  uint256 bid;
}

contract DutchAuctionHouse is
  AccessControl,
  JBSplitPayerUtil,
  ReentrancyGuard,
  IDutchAuctionHouse,
  Initializable
{
  bytes32 public constant AUTHORIZED_SELLER_ROLE = keccak256('AUTHORIZED_SELLER_ROLE');

  //*********************************************************************//
  // --------------------------- custom errors ------------------------- //
  //*********************************************************************//

  /**
   * @notice Fee rate cap set to 10%.
   */
  uint256 public constant FEE_RATE_CAP = 100000000;

  //*********************************************************************//
  // --------------------- public stored properties -------------------- //
  //*********************************************************************//

  /**
   * @notice Collection of active auctions.
   */
  mapping(bytes32 => DutchAuctionData) public auctions;

  /**
   * @notice Juicebox splits for active auctions.
   */
  mapping(bytes32 => JBSplit[]) public auctionSplits;

  /**
   * @notice Timestamp of contract deployment, used as auction expiration offset.
   */
  uint256 public deploymentOffset;

  uint256 public projectId;
  IJBPaymentTerminal public feeReceiver;
  IJBDirectory public directory;
  uint256 public settings; // periodDuration(64), allowPublicAuctions(bool), feeRate (32)

  /**
   * @notice Contract initializer to make deployment more flexible.
   *
   * @param _projectId Project that manages this auction contract.
   * @param _feeReceiver An instance of IJBPaymentTerminal which will get auction fees.
   * @param _feeRate Fee percentage expressed in terms of JBConstants.SPLITS_TOTAL_PERCENT (1000000000).
   * @param _allowPublicAuctions A flag to allow anyone to create an auction on this contract rather than only accounts with the `AUTHORIZED_SELLER_ROLE` permission.
   * @param _periodDuration Number of seconds for each pricing period.
   * @param _owner Contract admin. Granted admin and seller roles.
   * @param _directory JBDirectory instance to enable JBX integration.
   *
   * @dev feeReceiver addToBalanceOf will be called to send fees.
   */
  function initialize(
    uint256 _projectId,
    IJBPaymentTerminal _feeReceiver,
    uint256 _feeRate,
    bool _allowPublicAuctions,
    uint256 _periodDuration,
    address _owner,
    IJBDirectory _directory
  ) public initializer {
    deploymentOffset = block.timestamp;

    projectId = _projectId;
    feeReceiver = _feeReceiver; // TODO: lookup instead
    settings = setBoolean(_feeRate, 32, _allowPublicAuctions);
    settings |= uint256(uint64(_periodDuration)) << 33;
    directory = _directory;

    _grantRole(DEFAULT_ADMIN_ROLE, _owner);
    _grantRole(AUTHORIZED_SELLER_ROLE, _owner);
  }

  /**
   * @notice Creates a new auction for an item from an ERC721 contract. This is a Dutch auction which begins at startingPrice and drops in equal increments to endingPrice by exipration. Price reduction happens at the interval specified in periodDuration. Number of periods is determined automatically and price decrement is the price difference over number of periods. Generates a "CreateDutchAuction" event.
   *
   * @dev startingPrice and endingPrice must each fit into uint96.
   *
   * @dev WARNING, if using a JBSplits collection, make sure each of the splits is properly configured. The default project and default reciever during split processing is set to 0 and will therefore result in loss of funds if the split doesn't provide sufficient instructions.
   *
   * @param collection ERC721 contract.
   * @param item Token id to list.
   * @param startingPrice Starting price for the auction from which it will drop.
   * @param endingPrice Minimum price for the auction at which it will end at expiration time.
   * @param _duration Seconds from block time at which the auction concludes.
   * @param saleSplits Juicebox splits collection that will receive auction proceeds.
   * @param _memo Text to publish as part of the creation event.
   */
  function create(
    IERC721 collection,
    uint256 item,
    uint256 startingPrice,
    uint256 endingPrice,
    uint256 _duration,
    JBSplit[] calldata saleSplits,
    string calldata _memo
  ) external override nonReentrant {
    if (!getBoolean(settings, 32) && !hasRole(AUTHORIZED_SELLER_ROLE, msg.sender)) {
      revert NOT_AUTHORIZED();
    }

    bytes32 auctionId = keccak256(abi.encodePacked(address(collection), item));
    DutchAuctionData memory auctionDetails = auctions[auctionId];

    if (auctionDetails.info != 0) {
      revert AUCTION_EXISTS();
    }

    if (startingPrice > type(uint96).max) {
      revert INVALID_PRICE();
    }

    if (endingPrice > type(uint96).max || endingPrice >= startingPrice) {
      revert INVALID_PRICE();
    }

    // TODO: Check that expiration - now > periodDuration

    {
      // scope to reduce stack depth
      uint256 auctionInfo = uint256(uint160(msg.sender));
      auctionInfo |= uint256(uint64(block.timestamp - deploymentOffset)) << 160;

      uint256 auctionPrices = uint256(uint96(startingPrice));
      auctionPrices |= uint256(uint96(endingPrice)) << 96;
      auctionPrices |= uint256(uint64(block.timestamp - deploymentOffset + _duration)) << 192;

      auctions[auctionId] = DutchAuctionData(auctionInfo, auctionPrices, 0);
    }

    uint256 length = saleSplits.length;
    for (uint256 i = 0; i < length; i += 1) {
      auctionSplits[auctionId].push(saleSplits[i]);
    }

    collection.transferFrom(msg.sender, address(this), item);

    emit CreateDutchAuction(
      msg.sender,
      collection,
      item,
      startingPrice,
      endingPrice,
      block.timestamp + _duration,
      _memo
    );
  }

  /**
   * @notice Places a bid on an existing auction. Refunds previous bid if needed. The contract will only store the highest bid. The bid can be below current price in anticipation of the auction eventually reaching that price. The bid must be at or above the end price. Generates a "PlaceBid" event.
   *
   * @param collection ERC721 contract.
   * @param item Token id to bid on.
   */
  function bid(
    IERC721 collection,
    uint256 item,
    string calldata _memo
  ) external payable override nonReentrant {
    bytes32 auctionId = keccak256(abi.encodePacked(collection, item));
    DutchAuctionData memory auctionDetails = auctions[auctionId];

    if (auctionDetails.info == 0) {
      revert INVALID_AUCTION();
    }

    uint256 expiration = uint256(uint64(auctionDetails.prices >> 192));
    if (block.timestamp > deploymentOffset + expiration) {
      revert AUCTION_ENDED();
    }

    if (auctionDetails.bid != 0) {
      uint256 currentBidAmount = uint96(auctionDetails.bid >> 160);
      if (currentBidAmount >= msg.value) {
        revert INVALID_BID();
      }

      address(uint160(auctionDetails.bid)).call{value: currentBidAmount, gas: 2300}(''); // ignores the result to prevent higher bids from being placed by malicious contracts
    } else {
      uint256 endingPrice = uint256(uint96(auctionDetails.prices >> 96));
      // TODO: consider allowing this as a means of caputuring market info
      if (endingPrice > msg.value) {
        revert INVALID_BID();
      }
    }

    uint256 newBid = uint256(uint160(msg.sender));
    newBid |= uint256(uint96(msg.value)) << 160;

    auctions[auctionId].bid = newBid;

    // TODO: consider allowing a bid over the current minimum price to tranfer the token immediately without calling settle

    emit PlaceDutchBid(msg.sender, collection, item, msg.value, _memo);
  }

  /**
   * @notice Settles the auction after expiration if no valid bids were received by sending the item back to the seller. If a valid bid matches the current price at the time of settle call, the item is sent to the bidder. Proceeds will be distributed separately by calling `distributeProceeds`. Generates a "ConcludeAuction" event.
   *
   * @param collection ERC721 contract.
   * @param item Token id to settle.
   */
  function settle(
    IERC721 collection,
    uint256 item,
    string calldata _memo
  ) external override nonReentrant {
    bytes32 auctionId = keccak256(abi.encodePacked(collection, item));
    DutchAuctionData memory auctionDetails = auctions[auctionId];

    if (auctionDetails.info == 0) {
      revert INVALID_AUCTION();
    }

    uint256 lastBidAmount = uint256(uint96(auctionDetails.bid >> 160));
    uint256 minSettlePrice = currentPrice(collection, item);

    if (minSettlePrice < lastBidAmount) {
      address buyer = address(uint160(auctionDetails.bid));

      collection.transferFrom(address(this), buyer, item);

      emit ConcludeDutchAuction(
        address(uint160(auctionDetails.info)),
        buyer,
        collection,
        item,
        lastBidAmount,
        _memo
      );
    } else {
      uint256 expiration = uint256(uint64(auctionDetails.prices >> 192));
      if (block.timestamp > deploymentOffset + expiration) {
        // NOTE: return token back to seller after auction expiration if highest bid was below settlement price
        collection.transferFrom(address(this), address(uint160(auctionDetails.info)), item);

        delete auctions[auctionId];
        delete auctionSplits[auctionId];

        emit ConcludeDutchAuction(
          address(uint160(auctionDetails.info)),
          address(0),
          collection,
          item,
          0,
          _memo
        );
      }
    }
  }

  /**
   * @notice This trustless method removes the burden of distributing auction proceeds to the seller-configured splits from the buyer (or anyone else) calling settle().
   */
  function distributeProceeds(IERC721 _collection, uint256 _item) external override nonReentrant {
    bytes32 auctionId = keccak256(abi.encodePacked(_collection, _item));
    DutchAuctionData memory auctionDetails = auctions[auctionId];

    if (auctionDetails.info == 0) {
      revert INVALID_AUCTION();
    }

    uint256 lastBidAmount = uint256(uint96(auctionDetails.bid >> 160));
    uint256 minSettlePrice = currentPrice(_collection, _item);

    if (minSettlePrice > lastBidAmount) {
      // nothing to distribute no valid bid
      revert INVALID_PRICE();
    }

    if (_collection.ownerOf(_item) == address(this)) {
      // proceeds can be collected, but we still own the token, send it to the bidder
      address buyer = address(uint160(auctionDetails.bid));
      _collection.transferFrom(address(this), buyer, _item);
    }

    if (uint32(settings) != 0) {
      // feeRate > 0
      uint256 fee = PRBMath.mulDiv(
        lastBidAmount,
        uint32(settings),
        JBConstants.SPLITS_TOTAL_PERCENT
      );
      feeReceiver.addToBalanceOf{value: fee}(projectId, fee, JBTokens.ETH, '', '');

      unchecked {
        lastBidAmount -= fee;
      }
    }

    delete auctions[auctionId];

    if (auctionSplits[auctionId].length != 0) {
      lastBidAmount = payToSplits(
        auctionSplits[auctionId],
        lastBidAmount,
        JBTokens.ETH,
        18,
        directory,
        0,
        payable(address(0))
      );

      delete auctionSplits[auctionId];

      if (lastBidAmount > 0) {
        payable(address(uint160(auctionDetails.info))).transfer(lastBidAmount);
      }
    } else {
      payable(address(uint160(auctionDetails.info))).transfer(lastBidAmount);
    }
  }

  // TODO: consider an acceptLowBid function for the seller to execute after auction expiration

  function timeLeft(IERC721 collection, uint256 item) public view returns (uint256) {
    bytes32 auctionId = keccak256(abi.encodePacked(collection, item));
    DutchAuctionData memory auctionDetails = auctions[auctionId];

    if (auctionDetails.info == 0) {
      revert INVALID_AUCTION();
    }

    uint256 expiration = deploymentOffset + uint256(uint64(auctionDetails.prices >> 192));

    if (block.timestamp > expiration) {
      return 0;
    }

    return expiration - block.timestamp;
  }

  /**
   * @notice Returns the current price for an items subject to the price range and elapsed duration.
   *
   * @param collection ERC721 contract.
   * @param item Token id to get the price of.
   */
  function currentPrice(
    IERC721 collection,
    uint256 item
  ) public view override returns (uint256 price) {
    bytes32 auctionId = keccak256(abi.encodePacked(collection, item));
    DutchAuctionData memory auctionDetails = auctions[auctionId];

    if (auctionDetails.info == 0) {
      revert INVALID_AUCTION();
    }

    uint256 endTime = uint256(uint64(auctionDetails.prices >> 192));
    uint256 startTime = uint256(uint64(auctionDetails.info >> 160));
    uint256 periods = (endTime - startTime) / uint64(uint256(settings) >> 33);
    uint256 startingPrice = uint256(uint96(auctionDetails.prices));
    uint256 endingPrice = uint256(uint96(auctionDetails.prices >> 96));
    uint256 periodPrice = (startingPrice - endingPrice) / periods;
    uint256 elapsedPeriods = (block.timestamp - deploymentOffset - startTime) /
      uint64(uint256(settings) >> 33);
    price = startingPrice - elapsedPeriods * periodPrice;
  }

  /**
   * @notice A way to update auction splits in case current configuration cannot be processed correctly. Can only be executed by the seller address. Setting an empty collection will send auction proceeds, less fee, to the seller account.
   */
  function updateAuctionSplits(
    IERC721 _collection,
    uint256 _item,
    JBSplit[] calldata _saleSplits
  ) external override {
    bytes32 auctionId = keccak256(abi.encodePacked(_collection, _item));
    DutchAuctionData memory auctionDetails = auctions[auctionId];

    if (auctionDetails.info == 0) {
      revert INVALID_AUCTION();
    }

    if (address(uint160(auctionDetails.info)) != msg.sender) {
      revert NOT_AUTHORIZED();
    }

    delete auctionSplits[auctionId];

    uint256 length = _saleSplits.length;
    for (uint256 i = 0; i != length; ) {
      auctionSplits[auctionId].push(_saleSplits[i]);
      unchecked {
        ++i;
      }
    }
  }

  /**
   * @notice Change fee rate, admin only.
   *
   * @param _feeRate Fee percentage expressed in terms of JBConstants.SPLITS_TOTAL_PERCENT (1000000000).
   */
  function setFeeRate(uint256 _feeRate) external override onlyRole(DEFAULT_ADMIN_ROLE) {
    if (_feeRate > FEE_RATE_CAP) {
      revert INVALID_FEERATE();
    }

    settings |= uint256(uint32(_feeRate));
  }

  /**
   * @param _allowPublicAuctions Sets or clears the flag to enable users other than admin role to create auctions.
   */
  function setAllowPublicAuctions(
    bool _allowPublicAuctions
  ) external override onlyRole(DEFAULT_ADMIN_ROLE) {
    settings = setBoolean(settings, 32, _allowPublicAuctions);
  }

  /**
   * @param _feeReceiver JBX terminal to send fees to.
   *
   * @dev addToBalanceOf on the feeReceiver will be called to send fees.
   */
  function setFeeReceiver(
    IJBPaymentTerminal _feeReceiver
  ) external override onlyRole(DEFAULT_ADMIN_ROLE) {
    feeReceiver = _feeReceiver;
  }

  function addAuthorizedSeller(address _seller) external override onlyRole(DEFAULT_ADMIN_ROLE) {
    _grantRole(AUTHORIZED_SELLER_ROLE, _seller);
  }

  function removeAuthorizedSeller(address _seller) external override onlyRole(DEFAULT_ADMIN_ROLE) {
    _revokeRole(AUTHORIZED_SELLER_ROLE, _seller);
  }

  function supportsInterface(bytes4 _interfaceId) public view override returns (bool) {
    return
      _interfaceId == type(IDutchAuctionHouse).interfaceId || super.supportsInterface(_interfaceId);
  }

  // TODO: consider admin functions to recover eth & token balances

  //*********************************************************************//
  // ------------------------------ utils ------------------------------ //
  //*********************************************************************//

  function getBoolean(uint256 _source, uint256 _index) internal pure returns (bool) {
    uint256 flag = (_source >> _index) & uint256(1);
    return (flag == 1 ? true : false);
  }

  function setBoolean(
    uint256 _source,
    uint256 _index,
    bool _value
  ) internal pure returns (uint256 update) {
    if (_value) {
      update = _source | (uint256(1) << _index);
    } else {
      update = _source & ~(uint256(1) << _index);
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';

import '../../interfaces/IJBDirectory.sol';
import '../../libraries/JBConstants.sol';
import '../../libraries/JBTokens.sol';
import '../../structs/JBSplit.sol';

import '../Utils/JBSplitPayerUtil.sol';

import './INFTAuction.sol';

interface IEnglishAuctionHouse is INFTAuction {
  event CreateEnglishAuction(
    address seller,
    IERC721 collection,
    uint256 item,
    uint256 startingPrice,
    uint256 reservePrice,
    uint256 expiration,
    string memo
  );

  event PlaceEnglishBid(
    address bidder,
    IERC721 collection,
    uint256 item,
    uint256 bidAmount,
    string memo
  );

  event ConcludeEnglishAuction(
    address seller,
    address bidder,
    IERC721 collection,
    uint256 item,
    uint256 closePrice,
    string memo
  );
}

struct EnglishAuctionData {
  address seller;
  uint256 prices;
  uint256 bid;
}

contract EnglishAuctionHouse is
  AccessControl,
  JBSplitPayerUtil,
  ReentrancyGuard,
  IEnglishAuctionHouse,
  Initializable
{
  bytes32 public constant AUTHORIZED_SELLER_ROLE = keccak256('AUTHORIZED_SELLER_ROLE');

  //*********************************************************************//
  // --------------------------- custom errors ------------------------- //
  //*********************************************************************//

  error AUCTION_IN_PROGRESS();

  /**
   * @notice Fee rate cap set to 10%.
   */
  uint256 public constant FEE_RATE_CAP = 100000000;

  //*********************************************************************//
  // --------------------- public stored properties -------------------- //
  //*********************************************************************//

  /**
   * @notice Collection of active auctions.
   */
  mapping(bytes32 => EnglishAuctionData) public auctions;

  /**
   * @notice Juicebox splits for active auctions.
   */
  mapping(bytes32 => JBSplit[]) public auctionSplits;

  /**
   * @notice Timestamp of contract deployment, used as auction expiration offset.
   */
  uint256 public deploymentOffset;

  uint256 public projectId;
  IJBPaymentTerminal public feeReceiver;
  IJBDirectory public directory;
  uint256 public settings; // allowPublicAuctions(bool), feeRate (32)

  /**
   * @notice Contract initializer to make deployment more flexible.
   *
   * @param _projectId Project that manages this auction contract.
   * @param _feeReceiver An instance of IJBPaymentTerminal which will get auction fees.
   * @param _feeRate Fee percentage expressed in terms of JBConstants.SPLITS_TOTAL_PERCENT (1000000000).
   * @param _allowPublicAuctions A flag to allow anyone to create an auction on this contract rather than only accounts with the `AUTHORIZED_SELLER_ROLE` permission.
   * @param _owner Contract admin. Granted admin and seller roles.
   * @param _directory JBDirectory instance to enable JBX integration.
   *
   * @dev feeReceiver addToBalanceOf will be called to send fees.
   */
  function initialize(
    uint256 _projectId,
    IJBPaymentTerminal _feeReceiver,
    uint256 _feeRate,
    bool _allowPublicAuctions,
    address _owner,
    IJBDirectory _directory
  ) public initializer {
    deploymentOffset = block.timestamp;

    projectId = _projectId;
    feeReceiver = _feeReceiver; // TODO: lookup instead
    settings = setBoolean(_feeRate, 32, _allowPublicAuctions);
    directory = _directory;

    _grantRole(DEFAULT_ADMIN_ROLE, _owner);
    _grantRole(AUTHORIZED_SELLER_ROLE, _owner);
  }

  /**
   * @notice Creates a new auction for an item from an ERC721 contract.
   *
   * @dev startingPrice and reservePrice must each fit into uint96. expiration is 64 bit.
   *
   * @dev WARNING, if using a JBSplits collection, make sure each of the splits is properly configured. The default project and default reciever during split processing is set to 0 and will therefore result in loss of funds if the split doesn't provide sufficient instructions.
   *
   * @param _collection ERC721 contract.
   * @param item Token id to list.
   * @param startingPrice Minimum auction price. 0 is a valid price.
   * @param reservePrice Reserve price at which the item will be sold once the auction expires. Below this price, the item will be returned to the seller.
   * @param _duration Seconds from block time at which the auction concludes.
   * @param _saleSplits Juicebox splits collection that will receive auction proceeds.
   * @param _memo Text to publish as part of the creation event.
   */
  function create(
    IERC721 _collection,
    uint256 item,
    uint256 startingPrice,
    uint256 reservePrice,
    uint256 _duration,
    JBSplit[] calldata _saleSplits,
    string calldata _memo
  ) external override nonReentrant {
    if (!getBoolean(settings, 32) && !hasRole(AUTHORIZED_SELLER_ROLE, msg.sender)) {
      revert NOT_AUTHORIZED();
    }

    bytes32 auctionId = keccak256(abi.encodePacked(address(_collection), item));
    EnglishAuctionData memory auctionDetails = auctions[auctionId];

    if (auctionDetails.seller != address(0)) {
      revert AUCTION_EXISTS();
    }

    if (startingPrice > type(uint96).max) {
      revert INVALID_PRICE();
    }

    if (reservePrice > type(uint96).max) {
      revert INVALID_PRICE();
    }

    uint256 expiration = block.timestamp - deploymentOffset + _duration;

    if (expiration > type(uint64).max) {
      revert INVALID_DURATION();
    }

    {
      // scope to reduce stack depth
      uint256 auctionPrices = uint256(uint96(startingPrice));
      auctionPrices |= uint256(uint96(reservePrice)) << 96;
      auctionPrices |= uint256(uint64(expiration)) << 192;

      auctions[auctionId] = EnglishAuctionData(msg.sender, auctionPrices, 0);
    }

    uint256 length = _saleSplits.length;
    for (uint256 i = 0; i < length; ) {
      auctionSplits[auctionId].push(_saleSplits[i]);
      unchecked {
        ++i;
      }
    }

    _collection.transferFrom(msg.sender, address(this), item);

    emit CreateEnglishAuction(
      msg.sender,
      _collection,
      item,
      startingPrice,
      reservePrice,
      expiration,
      _memo
    );
  }

  /**
   * @notice Places a bid on an existing auction. Refunds previous bid if needed.
   *
   * @param _collection ERC721 contract.
   * @param _item Token id to bid on.
   */
  function bid(
    IERC721 _collection,
    uint256 _item,
    string calldata _memo
  ) external payable override nonReentrant {
    bytes32 auctionId = keccak256(abi.encodePacked(_collection, _item));
    EnglishAuctionData memory auctionDetails = auctions[auctionId];

    if (auctionDetails.seller == address(0)) {
      revert INVALID_AUCTION();
    }

    uint256 expiration = uint256(uint64(auctionDetails.prices >> 192));

    if (block.timestamp > deploymentOffset + expiration) {
      revert AUCTION_ENDED();
    }

    if (auctionDetails.bid != 0) {
      uint256 currentBidAmount = uint96(auctionDetails.bid >> 160);
      if (currentBidAmount >= msg.value) {
        revert INVALID_BID();
      }

      address(uint160(auctionDetails.bid)).call{value: currentBidAmount, gas: 2300}('');
    } else {
      uint256 startingPrice = uint256(uint96(auctionDetails.prices));
      // TODO: consider allowing this as a means of caputuring market info
      if (startingPrice > msg.value) {
        revert INVALID_BID();
      }
    }

    uint256 newBid = uint256(uint160(msg.sender));
    newBid |= uint256(uint96(msg.value)) << 160;

    auctions[auctionId].bid = newBid;

    emit PlaceEnglishBid(msg.sender, _collection, _item, msg.value, _memo);
  }

  /**
   * @notice Settles the auction after expiration by either sending the item to the winning bidder or sending it back to the seller in the event that no bids met the reserve price.
   *
   * @param collection ERC721 contract.
   * @param item Token id to settle.
   */
  function settle(
    IERC721 collection,
    uint256 item,
    string calldata _memo
  ) external override nonReentrant {
    bytes32 auctionId = keccak256(abi.encodePacked(collection, item));
    EnglishAuctionData memory auctionDetails = auctions[auctionId];

    if (auctionDetails.seller == address(0)) {
      revert INVALID_AUCTION();
    }

    uint256 expiration = uint256(uint64(auctionDetails.prices >> 192));
    if (block.timestamp < deploymentOffset + expiration) {
      revert AUCTION_IN_PROGRESS();
    }

    uint256 lastBidAmount = uint256(uint96(auctionDetails.bid >> 160));
    uint256 reservePrice = uint256(uint96(auctionDetails.prices >> 96));
    if (reservePrice <= lastBidAmount) {
      address buyer = address(uint160(auctionDetails.bid));

      collection.transferFrom(address(this), buyer, item);

      emit ConcludeEnglishAuction(
        auctionDetails.seller,
        buyer,
        collection,
        item,
        lastBidAmount,
        _memo
      );
    } else {
      collection.transferFrom(address(this), auctionDetails.seller, item);

      if (lastBidAmount != 0) {
        payable(address(uint160(auctionDetails.bid))).transfer(lastBidAmount);
      }

      delete auctions[auctionId];
      delete auctionSplits[auctionId];

      emit ConcludeEnglishAuction(auctionDetails.seller, address(0), collection, item, 0, _memo);
    }
  }

  /**
   * @notice This trustless method removes the burden of distributing auction proceeds to the seller-configured splits from the buyer (or anyone else) calling settle().
   */
  function distributeProceeds(IERC721 _collection, uint256 _item) external override nonReentrant {
    bytes32 auctionId = keccak256(abi.encodePacked(_collection, _item));
    EnglishAuctionData memory auctionDetails = auctions[auctionId];

    if (auctionDetails.seller == address(0)) {
      revert INVALID_AUCTION();
    }

    uint256 expiration = uint256(uint64(auctionDetails.prices >> 192));
    if (block.timestamp < deploymentOffset + expiration) {
      revert AUCTION_IN_PROGRESS();
    }

    uint256 lastBidAmount = uint256(uint96(auctionDetails.bid >> 160));
    uint256 reservePrice = uint256(uint96(auctionDetails.prices >> 96));
    if (reservePrice <= lastBidAmount) {
      if (_collection.ownerOf(_item) == address(this)) {
        // proceeds can be collected, but we still own the token, send it to the bidder
        address buyer = address(uint160(auctionDetails.bid));
        _collection.transferFrom(address(this), buyer, _item);
        emit ConcludeEnglishAuction(
          auctionDetails.seller,
          address(0),
          _collection,
          _item,
          lastBidAmount,
          ''
        );
      }

      if (uint32(settings) != 0) {
        // feeRate > 0
        uint256 fee = PRBMath.mulDiv(
          lastBidAmount,
          uint32(settings),
          JBConstants.SPLITS_TOTAL_PERCENT
        );
        feeReceiver.addToBalanceOf{value: fee}(projectId, fee, JBTokens.ETH, '', '');

        unchecked {
          lastBidAmount -= fee;
        }
      }

      delete auctions[auctionId];

      if (auctionSplits[auctionId].length != 0) {
        lastBidAmount = payToSplits(
          auctionSplits[auctionId],
          lastBidAmount,
          JBTokens.ETH,
          18,
          directory,
          0,
          payable(address(0))
        );
        delete auctionSplits[auctionId];

        if (lastBidAmount > 0) {
          // in case splits don't cover 100%, transfer remainder to seller
          payable(auctionDetails.seller).transfer(lastBidAmount);
        }
      } else {
        payable(auctionDetails.seller).transfer(lastBidAmount);
      }
    }
  }

  // TODO: consider an acceptLowBid function for the seller to execute after auction expiration

  /**
   * @notice Returns the number of seconds to the end of the current auction.
   */
  function timeLeft(IERC721 _collection, uint256 _item) public view returns (uint256) {
    bytes32 auctionId = keccak256(abi.encodePacked(_collection, _item));
    EnglishAuctionData memory auctionDetails = auctions[auctionId];

    if (auctionDetails.seller == address(0)) {
      revert INVALID_AUCTION();
    }

    uint256 expiration = deploymentOffset + uint256(uint64(auctionDetails.prices >> 192));

    if (block.timestamp > expiration) {
      return 0;
    }

    return expiration - block.timestamp;
  }

  /**
   * @notice Returns current bid for a given item even if it is below the reserve.
   */
  function currentPrice(
    IERC721 _collection,
    uint256 _item
  ) public view override returns (uint256 price) {
    bytes32 auctionId = keccak256(abi.encodePacked(_collection, _item));
    EnglishAuctionData memory auctionDetails = auctions[auctionId];

    if (auctionDetails.seller == address(0)) {
      revert INVALID_AUCTION();
    }

    price = uint256(uint96(auctionDetails.bid >> 160));
  }

  /**
   * @notice A way to update auction splits in case current configuration cannot be processed correctly. Can only be executed by the seller address. Setting an empty collection will send auction proceeds, less fee, to the seller account.
   */
  function updateAuctionSplits(
    IERC721 _collection,
    uint256 _item,
    JBSplit[] calldata _saleSplits
  ) external override {
    bytes32 auctionId = keccak256(abi.encodePacked(_collection, _item));
    EnglishAuctionData memory auctionDetails = auctions[auctionId];

    if (auctionDetails.seller == address(0)) {
      revert INVALID_AUCTION();
    }

    if (auctionDetails.seller != msg.sender) {
      revert NOT_AUTHORIZED();
    }

    delete auctionSplits[auctionId];

    uint256 length = _saleSplits.length;
    for (uint256 i = 0; i != length; ) {
      auctionSplits[auctionId].push(_saleSplits[i]);
      ++i;
    }
  }

  /**
   * @notice Change fee rate, admin only.
   *
   * @param _feeRate Fee percentage expressed in terms of JBConstants.SPLITS_TOTAL_PERCENT (1_000_000_000).
   */
  function setFeeRate(uint256 _feeRate) external override onlyRole(DEFAULT_ADMIN_ROLE) {
    if (_feeRate > FEE_RATE_CAP) {
      revert INVALID_FEERATE();
    }

    settings |= uint256(uint32(_feeRate));
  }

  /**
   * @notice Sets or clears the flag to enable users other than admin role to create auctions.
   */
  function setAllowPublicAuctions(
    bool _allowPublicAuctions
  ) external override onlyRole(DEFAULT_ADMIN_ROLE) {
    settings = setBoolean(settings, 32, _allowPublicAuctions);
  }

  /**
   * @param _feeReceiver JBX terminal to send fees to.
   *
   * @dev addToBalanceOf on the feeReceiver will be called to send fees.
   */
  function setFeeReceiver(
    IJBPaymentTerminal _feeReceiver
  ) external override onlyRole(DEFAULT_ADMIN_ROLE) {
    feeReceiver = _feeReceiver;
  }

  function addAuthorizedSeller(address _seller) external override onlyRole(DEFAULT_ADMIN_ROLE) {
    _grantRole(AUTHORIZED_SELLER_ROLE, _seller);
  }

  function removeAuthorizedSeller(address _seller) external override onlyRole(DEFAULT_ADMIN_ROLE) {
    _revokeRole(AUTHORIZED_SELLER_ROLE, _seller);
  }

  function supportsInterface(bytes4 _interfaceId) public view override returns (bool) {
    return
      _interfaceId == type(IEnglishAuctionHouse).interfaceId ||
      super.supportsInterface(_interfaceId);
  }

  // TODO: consider admin functions to recover eth & token balances

  //*********************************************************************//
  // ------------------------------ utils ------------------------------ //
  //*********************************************************************//

  function getBoolean(uint256 _source, uint256 _index) internal pure returns (bool) {
    uint256 flag = (_source >> _index) & uint256(1);
    return (flag == 1 ? true : false);
  }

  function setBoolean(
    uint256 _source,
    uint256 _index,
    bool _value
  ) internal pure returns (uint256 update) {
    if (_value) {
      update = _source | (uint256(1) << _index);
    } else {
      update = _source & ~(uint256(1) << _index);
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';

import '../../interfaces/IJBDirectory.sol';
import '../../libraries/JBConstants.sol';
import '../../libraries/JBTokens.sol';
import '../../structs/JBSplit.sol';

import '../Utils/JBSplitPayerUtil.sol';

interface IFixedPriceSale {
  event CreateFixedPriceSale(
    address seller,
    IERC721 collection,
    uint256 item,
    uint256 price,
    uint256 expiration,
    string memo
  );

  event ConcludeFixedPriceSale(
    address seller,
    address buyer,
    IERC721 collection,
    uint256 item,
    uint256 closePrice,
    string memo
  );

  error SALE_EXISTS();
  error INVALID_SALE();
  error SALE_ENDED();
  error SALE_IN_PROGRESS();
  error INVALID_PRICE();
  error INVALID_DURATION();
  error INVALID_FEERATE();
  error NOT_AUTHORIZED();

  function create(
    IERC721 _collection,
    uint256 _item,
    uint256 _price,
    uint256 _duration,
    JBSplit[] calldata _saleSplits,
    string calldata _memo
  ) external;

  function takeOffer(IERC721, uint256, string calldata) external payable;

  function distributeProceeds(IERC721, uint256) external;

  function currentPrice(IERC721, uint256) external view returns (uint256);

  function updateSaleSplits(IERC721, uint256, JBSplit[] calldata) external;

  function setFeeRate(uint256) external;

  function setAllowPublicSales(bool) external;

  function setFeeReceiver(IJBPaymentTerminal) external;

  function addAuthorizedSeller(address) external;

  function removeAuthorizedSeller(address) external;
}

struct SaleData {
  address seller;
  /** @notice Bit-packed price (96bits) and expiration seconds offset (64bits) */
  uint256 condition;
  /** @notice Sale price (96bits) */
  uint256 sale;
}

contract FixedPriceSale is
  AccessControl,
  JBSplitPayerUtil,
  ReentrancyGuard,
  IFixedPriceSale,
  Initializable
{
  bytes32 public constant AUTHORIZED_SELLER_ROLE = keccak256('AUTHORIZED_SELLER_ROLE');

  /**
   * @notice Fee rate cap set to 10%.
   */
  uint256 public constant FEE_RATE_CAP = 100000000;

  //*********************************************************************//
  // --------------------- public stored properties -------------------- //
  //*********************************************************************//

  /**
   * @notice Collection of active sales.
   */
  mapping(bytes32 => SaleData) public sales;

  /**
   * @notice Juicebox splits for active sales.
   */
  mapping(bytes32 => JBSplit[]) public saleSplits;

  /**
   * @notice Timestamp of contract deployment, used as sale expiration offset to reduce the number of bits needed to store sale expiration.
   */
  uint256 public deploymentOffset;

  uint256 public projectId;
  IJBPaymentTerminal public feeReceiver;
  IJBDirectory public directory;
  uint256 public settings; // allowPublicSales(bool), feeRate (32)

  /**
   * @notice Contract initializer to make deployment more flexible.
   *
   * @param _projectId Project that manages this sales contract.
   * @param _feeReceiver An instance of IJBPaymentTerminal which will get sale fees.
   * @param _feeRate Fee percentage expressed in terms of JBConstants.SPLITS_TOTAL_PERCENT (1000000000).
   * @param _allowPublicSales A flag to allow anyone to create a sale on this contract rather than only accounts with the `AUTHORIZED_SELLER_ROLE` permission.
   * @param _owner Contract admin. Granted admin and seller roles.
   * @param _directory JBDirectory instance to enable JBX integration.
   *
   * @dev feeReceiver.addToBalanceOf will be called to send fees.
   */
  function initialize(
    uint256 _projectId,
    IJBPaymentTerminal _feeReceiver,
    uint256 _feeRate,
    bool _allowPublicSales,
    address _owner,
    IJBDirectory _directory
  ) public initializer {
    deploymentOffset = block.timestamp;

    projectId = _projectId;
    feeReceiver = _feeReceiver;
    settings = setBoolean(_feeRate, 32, _allowPublicSales);
    directory = _directory;

    _grantRole(DEFAULT_ADMIN_ROLE, _owner);
    _grantRole(AUTHORIZED_SELLER_ROLE, _owner);
  }

  /**
   * @notice Creates a new sale listing for an item from an ERC721 collection.
   *
   * @dev _price must fit into uint96, expiration is 64 bit.
   *
   * @dev WARNING, if using a JBSplits collection, make sure each of the splits is properly configured. The default project and default receiver during split processing is set to 0 and will therefore result in loss of funds if the split doesn't provide sufficient instructions.
   *
   * @param _collection ERC721 contract.
   * @param _item Token id to list.
   * @param _price Sale price at which the sale can be completed.
   * @param _duration Seconds from block time at which the sale concludes.
   * @param _saleSplits Juicebox splits collection that will receive sale proceeds.
   * @param _memo Text to publish as part of the creation event.
   */
  function create(
    IERC721 _collection,
    uint256 _item,
    uint256 _price,
    uint256 _duration,
    JBSplit[] calldata _saleSplits,
    string calldata _memo
  ) external override nonReentrant {
    if (!getBoolean(settings, 32)) {
      if (!hasRole(AUTHORIZED_SELLER_ROLE, msg.sender)) {
        revert NOT_AUTHORIZED();
      }
    }

    bytes32 saleId = keccak256(abi.encodePacked(address(_collection), _item));
    SaleData memory saleDetails = sales[saleId];

    if (saleDetails.seller != address(0)) {
      revert SALE_EXISTS();
    }

    if (_price > type(uint96).max) {
      revert INVALID_PRICE();
    }

    uint256 expiration = block.timestamp - deploymentOffset + _duration;

    if (expiration > type(uint64).max) {
      revert INVALID_DURATION();
    }

    {
      // scope to reduce stack depth
      uint256 saleCondition = uint256(uint96(_price));
      saleCondition |= uint256(uint64(expiration)) << 96;

      sales[saleId] = SaleData(msg.sender, saleCondition, 0);
    }

    uint256 length = _saleSplits.length;
    for (uint256 i; i != length; ) {
      saleSplits[saleId].push(_saleSplits[i]);
      unchecked {
        ++i;
      }
    }

    _collection.transferFrom(msg.sender, address(this), _item);

    emit CreateFixedPriceSale(msg.sender, _collection, _item, _price, expiration, _memo);
  }

  /**
   * @notice Completes the sale if during validity period by either sending the item to the buyer or sending it back to the seller in the event that the sale period ended.
   *
   * @param collection ERC721 contract.
   * @param item Token id to settle.
   */
  function takeOffer(
    IERC721 collection,
    uint256 item,
    string calldata _memo
  ) external payable override nonReentrant {
    bytes32 saleId = keccak256(abi.encodePacked(collection, item));
    SaleData memory saleDetails = sales[saleId];

    if (saleDetails.seller == address(0)) {
      revert INVALID_SALE();
    }

    uint256 expiration = uint256(uint64(saleDetails.condition >> 96));
    if (block.timestamp > deploymentOffset + expiration) {
      revert SALE_ENDED();
    }

    uint256 expectedPrice = uint256(uint96(saleDetails.condition));
    if (msg.value >= expectedPrice) {
      sales[saleId].sale = msg.value;

      collection.transferFrom(address(this), msg.sender, item);

      emit ConcludeFixedPriceSale(
        saleDetails.seller,
        msg.sender,
        collection,
        item,
        msg.value,
        _memo
      );
    }
  }

  /**
   * @notice This trustless method removes the burden of distributing sale proceeds to the seller-configured splits from the buyer (or anyone else) calling settle(). The call will iterate saleSplits for a given sale or send the proceeds to the seller account.
   */
  function distributeProceeds(IERC721 _collection, uint256 _item) external override nonReentrant {
    bytes32 saleId = keccak256(abi.encodePacked(_collection, _item));
    SaleData memory saleDetails = sales[saleId];

    if (saleDetails.seller == address(0)) {
      revert INVALID_SALE();
    }

    uint256 expiration = uint256(uint64(saleDetails.condition >> 96));
    if (block.timestamp < deploymentOffset + expiration) {
      if (saleDetails.sale == 0) {
        revert SALE_IN_PROGRESS();
      }
    }

    if (saleDetails.sale == 0) {
      _collection.transferFrom(address(this), saleDetails.seller, _item);

      delete sales[saleId];
      delete saleSplits[saleId];

      emit ConcludeFixedPriceSale(saleDetails.seller, address(0), _collection, _item, 0, '');

      return;
    }

    uint256 saleAmount = uint256(uint96(saleDetails.sale));

    if (uint32(settings) != 0) {
      // feeRate > 0
      uint256 fee = PRBMath.mulDiv(saleAmount, uint32(settings), JBConstants.SPLITS_TOTAL_PERCENT);
      feeReceiver.addToBalanceOf{value: fee}(projectId, fee, JBTokens.ETH, '', '');

      unchecked {
        saleAmount -= fee;
      }
    }

    delete sales[saleId];

    if (saleSplits[saleId].length != 0) {
      saleAmount = payToSplits(
        saleSplits[saleId],
        saleAmount,
        JBTokens.ETH,
        18,
        directory,
        0,
        payable(address(0))
      );
      delete saleSplits[saleId];

      if (saleAmount > 0) {
        // in case splits don't cover 100%, transfer remainder to seller
        payable(saleDetails.seller).transfer(saleAmount);
      }
    } else {
      payable(saleDetails.seller).transfer(saleAmount);
    }
  }

  /**
   * @notice Returns the number of seconds to the end of the sale for a given item.
   */
  function timeLeft(IERC721 _collection, uint256 _item) public view returns (uint256) {
    bytes32 saleId = keccak256(abi.encodePacked(_collection, _item));
    SaleData memory saleDetails = sales[saleId];

    if (saleDetails.seller == address(0)) {
      revert INVALID_SALE();
    }

    uint256 expiration = deploymentOffset + uint256(uint64(saleDetails.condition >> 96));

    if (block.timestamp > expiration) {
      return 0;
    }

    return expiration - block.timestamp;
  }

  /**
   * @notice Returns current bid for a given item even if it is below the reserve.
   */
  function currentPrice(
    IERC721 _collection,
    uint256 _item
  ) public view override returns (uint256 price) {
    bytes32 saleId = keccak256(abi.encodePacked(_collection, _item));
    SaleData memory saleDetails = sales[saleId];

    if (saleDetails.seller == address(0)) {
      revert INVALID_SALE();
    }

    uint256 expiration = deploymentOffset + uint256(uint64(saleDetails.condition >> 96));
    if (block.timestamp > expiration) {
      price = 0;
    } else {
      price = uint256(uint96(saleDetails.condition));
    }
  }

  /**
   * @notice A way to update sale splits in case current configuration cannot be processed correctly. Can only be executed by the seller address. Setting an empty collection will send sale proceeds, less fee, to the seller account.
   */
  function updateSaleSplits(
    IERC721 _collection,
    uint256 _item,
    JBSplit[] calldata _saleSplits
  ) external override {
    bytes32 saleId = keccak256(abi.encodePacked(_collection, _item));
    SaleData memory saleDetails = sales[saleId];

    if (saleDetails.seller == address(0)) {
      revert INVALID_SALE();
    }

    if (saleDetails.seller != msg.sender) {
      revert NOT_AUTHORIZED();
    }

    delete saleSplits[saleId];

    uint256 length = _saleSplits.length;
    for (uint256 i; i != length; ) {
      saleSplits[saleId].push(_saleSplits[i]);
      unchecked {
        ++i;
      }
    }
  }

  /**
   * @notice Change fee rate, admin only.
   *
   * @param _feeRate Fee percentage expressed in terms of JBConstants.SPLITS_TOTAL_PERCENT (1_000_000_000).
   */
  function setFeeRate(uint256 _feeRate) external override onlyRole(DEFAULT_ADMIN_ROLE) {
    if (_feeRate > FEE_RATE_CAP) {
      revert INVALID_FEERATE();
    }

    settings |= uint256(uint32(_feeRate));
  }

  /**
   * @notice Sets or clears the flag to enable users other than admin role to create sales.
   */
  function setAllowPublicSales(
    bool _allowPublicSales
  ) external override onlyRole(DEFAULT_ADMIN_ROLE) {
    settings = setBoolean(settings, 32, _allowPublicSales);
  }

  /**
   * @param _feeReceiver JBX terminal to send fees to.
   *
   * @dev addToBalanceOf on the feeReceiver will be called to send fees.
   */
  function setFeeReceiver(
    IJBPaymentTerminal _feeReceiver
  ) external override onlyRole(DEFAULT_ADMIN_ROLE) {
    feeReceiver = _feeReceiver;
  }

  function addAuthorizedSeller(address _seller) external override onlyRole(DEFAULT_ADMIN_ROLE) {
    _grantRole(AUTHORIZED_SELLER_ROLE, _seller);
  }

  function removeAuthorizedSeller(address _seller) external override onlyRole(DEFAULT_ADMIN_ROLE) {
    _revokeRole(AUTHORIZED_SELLER_ROLE, _seller);
  }

  function supportsInterface(bytes4 _interfaceId) public view override returns (bool) {
    return
      _interfaceId == type(IFixedPriceSale).interfaceId || super.supportsInterface(_interfaceId);
  }

  // TODO: consider admin functions to recover eth & token balances

  //*********************************************************************//
  // ------------------------------ utils ------------------------------ //
  //*********************************************************************//

  function getBoolean(uint256 _source, uint256 _index) internal pure returns (bool) {
    uint256 flag = (_source >> _index) & uint256(1);
    return (flag == 1 ? true : false);
  }

  function setBoolean(
    uint256 _source,
    uint256 _index,
    bool _value
  ) internal pure returns (uint256 update) {
    if (_value) {
      update = _source | (uint256(1) << _index);
    } else {
      update = _source & ~(uint256(1) << _index);
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';

import '../../structs/JBSplit.sol';
import '../../interfaces/IJBPaymentTerminal.sol';

interface INFTAuction {
  error AUCTION_EXISTS();
  error INVALID_AUCTION();
  error AUCTION_ENDED();
  error INVALID_BID();
  error INVALID_PRICE();
  error INVALID_DURATION();
  error INVALID_FEERATE();
  error NOT_AUTHORIZED();

  event PlaceBid(address bidder, IERC721 collection, uint256 item, uint256 bidAmount, string memo);

  event ConcludeAuction(
    address seller,
    address bidder,
    IERC721 collection,
    uint256 item,
    uint256 closePrice,
    string memo
  );

  function create(
    IERC721,
    uint256,
    uint256,
    uint256,
    uint256,
    JBSplit[] calldata,
    string calldata
  ) external;

  function bid(IERC721, uint256, string calldata) external payable;

  function settle(IERC721, uint256, string calldata) external;

  function distributeProceeds(IERC721, uint256) external;

  function currentPrice(IERC721, uint256) external view returns (uint256);

  function updateAuctionSplits(IERC721, uint256, JBSplit[] calldata) external;

  function setFeeRate(uint256) external;

  function setAllowPublicAuctions(bool) external;

  function setFeeReceiver(IJBPaymentTerminal) external;

  function addAuthorizedSeller(address) external;

  function removeAuthorizedSeller(address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol';

import '../../abstract/JBOperatable.sol';
import '../../libraries/JBOperations.sol';
import '../../interfaces/IJBDirectory.sol';
import '../../interfaces/IJBProjects.sol';
import '../../interfaces/IJBOperatorStore.sol';
import './Factories/NFTokenFactory.sol';

/**
 * @notice
 */
/// @custom:oz-upgrades-unsafe-allow external-library-linking
contract Deployer_v001 is JBOperatable, OwnableUpgradeable, UUPSUpgradeable {
  event Deployment(string contractType, address contractAddress);

  uint256 constant PLATFORM_PROJECT_ID = 1;

  IJBDirectory internal jbxDirectory;
  IJBProjects internal jbxProjects;
  IMintFeeOracle internal feeOracle;

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  function initialize(
    address _jbxDirectory,
    address _jbxProjects,
    address _jbxOperatorStore
  ) public virtual initializer {
    __Ownable_init();
    __UUPSUpgradeable_init();

    operatorStore = IJBOperatorStore(_jbxOperatorStore);
    jbxDirectory = IJBDirectory(_jbxDirectory);
    jbxProjects = IJBProjects(_jbxProjects);
  }

  function _authorizeUpgrade(address) internal override onlyOwner {}

  /**
   * @dev This creates a token that can be minted immediately, to discourage this, unitPrice can be set high, then mint period can be defined before setting price to a "reasonable" value.
   */
  function deployNFToken(
    address payable _owner,
    string memory _name,
    string memory _symbol,
    string memory _baseUri,
    string memory _contractUri,
    uint256 _maxSupply,
    uint256 _unitPrice,
    uint256 _mintAllowance,
    bool _reveal
  ) external returns (address token) {
    token = NFTokenFactory.createNFToken(
      _owner,
      CommonNFTAttributes({
        name: _name,
        symbol: _symbol,
        baseUri: _baseUri,
        revealed: _reveal,
        contractUri: _contractUri,
        maxSupply: _maxSupply,
        unitPrice: _unitPrice,
        mintAllowance: _mintAllowance
      }),
      PermissionValidationComponents({
        jbxOperatorStore: operatorStore,
        jbxDirectory: jbxDirectory,
        jbxProjects: jbxProjects
      }),
      feeOracle
    );
    emit Deployment('NFToken', token);
  }

  function setMintFeeOracle(
    IMintFeeOracle _feeOracle
  )
    external
    requirePermissionAllowingOverride(
      jbxProjects.ownerOf(PLATFORM_PROJECT_ID),
      PLATFORM_PROJECT_ID,
      JBOperations.MANAGE_PAYMENTS,
      (msg.sender == address(jbxDirectory.controllerOf(PLATFORM_PROJECT_ID)))
    )
  {
    feeOracle = _feeOracle;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './Deployer_v001.sol';
import './Factories/MixedPaymentSplitterFactory.sol';

/**
 * @notice
 */
/// @custom:oz-upgrades-unsafe-allow external-library-linking
contract Deployer_v002 is Deployer_v001 {
  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  function initialize() public virtual reinitializer(2) {
    __Ownable_init();
    __UUPSUpgradeable_init();
  }

  function deployMixedPaymentSplitter(
    string memory _name,
    address[] memory _payees,
    uint256[] memory _projects,
    uint256[] memory _shares,
    IJBDirectory _jbxDirectory,
    address _owner
  ) external returns (address splitter) {
    splitter = MixedPaymentSplitterFactory.createMixedPaymentSplitter(
      _name,
      _payees,
      _projects,
      _shares,
      _jbxDirectory,
      _owner
    );

    emit Deployment('MixedPaymentSplitter', splitter);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../Auctions/DutchAuction.sol';
import '../Auctions/EnglishAuction.sol';
import '../Auctions/FixedPriceSale.sol';
import './Deployer_v002.sol';
import './Factories/AuctionsFactory.sol';

/**
 * @notice This version of the deployer adds the ability to create DutchAuctionHouse, EnglishAuctionHouse and FixedPriceSale contracts.
 */
/// @custom:oz-upgrades-unsafe-allow external-library-linking
contract Deployer_v003 is Deployer_v002 {
  DutchAuctionHouse internal dutchAuctionSource;
  EnglishAuctionHouse internal englishAuctionSource;
  FixedPriceSale internal fixedPriceSaleSource;

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  function initialize(
    address _dutchAuctionSource,
    address _englishAuctionSource,
    address _fixedPriceSaleSource
  ) public virtual override reinitializer(3) {
    // NOTE: clashes with Deployer_001
    __Ownable_init();
    __UUPSUpgradeable_init();

    dutchAuctionSource = DutchAuctionHouse(_dutchAuctionSource);
    englishAuctionSource = EnglishAuctionHouse(_englishAuctionSource);
    fixedPriceSaleSource = FixedPriceSale(_fixedPriceSaleSource);
  }

  function deployDutchAuction(
    uint256 _projectId,
    IJBPaymentTerminal _feeReceiver,
    uint256 _feeRate,
    bool _allowPublicAuctions,
    uint256 _periodDuration,
    address _owner,
    IJBDirectory _directory
  ) external returns (address auction) {
    auction = AuctionsFactory.createDutchAuction(
      address(dutchAuctionSource),
      _projectId,
      _feeReceiver,
      _feeRate,
      _allowPublicAuctions,
      _periodDuration,
      _owner,
      _directory
    );

    emit Deployment('DutchAuctionHouse', auction);
  }

  function deployEnglishAuction(
    uint256 _projectId,
    IJBPaymentTerminal _feeReceiver,
    uint256 _feeRate,
    bool _allowPublicAuctions,
    address _owner,
    IJBDirectory _directory
  ) external returns (address auction) {
    auction = AuctionsFactory.createEnglishAuction(
      address(englishAuctionSource),
      _projectId,
      _feeReceiver,
      _feeRate,
      _allowPublicAuctions,
      _owner,
      _directory
    );

    emit Deployment('EnglishAuctionHouse', auction);
  }

  function deployFixedPriceSale(
    uint256 _projectId,
    IJBPaymentTerminal _feeReceiver,
    uint256 _feeRate,
    bool _allowPublicSales,
    address _owner,
    IJBDirectory _directory
  ) external returns (address sale) {
    sale = AuctionsFactory.createFixedPriceSale(
      address(fixedPriceSaleSource),
      _projectId,
      _feeReceiver,
      _feeRate,
      _allowPublicSales,
      _owner,
      _directory
    );

    emit Deployment('FixedPriceSale', sale);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../Auctions/DutchAuction.sol';
import '../Auctions/EnglishAuction.sol';
import '../Auctions/FixedPriceSale.sol';
import '../NFT/NFUMembership.sol';
import '../NFT/NFUToken.sol';
import './Deployer_v003.sol';
import './Factories/NFUTokenFactory.sol';
import './Factories/NFUMembershipFactory.sol';

/**
 * @notice This version of the deployer adds the ability to create ERC721 NFTs from a reusable instance.
 */
/// @custom:oz-upgrades-unsafe-allow external-library-linking
contract Deployer_v004 is Deployer_v003 {
  NFUToken internal nfuTokenSource;
  NFUMembership internal nfuMembershipSource;

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  /**
   * @dev This function clashes with initialize in Deployer_v001, for this reason instead of having typed arguments, they're addresses.
   */
  function initialize(
    DutchAuctionHouse _dutchAuctionSource,
    EnglishAuctionHouse _englishAuctionSource,
    FixedPriceSale _fixedPriceSaleSource,
    NFUToken _nfuTokenSource,
    NFUMembership _nfuMembershipSource
  ) public virtual reinitializer(4) {
    __Ownable_init();
    __UUPSUpgradeable_init();

    dutchAuctionSource = _dutchAuctionSource;
    englishAuctionSource = _englishAuctionSource;
    fixedPriceSaleSource = _fixedPriceSaleSource;
    nfuTokenSource = _nfuTokenSource;
    nfuMembershipSource = _nfuMembershipSource;
  }

  /**
   * @dev This creates a token that can be minted immediately, to discourage this, unitPrice can be set high, then mint period can be defined before setting price to a "reasonable" value.
   */
  function deployNFUToken(
    address payable _owner,
    string memory _name,
    string memory _symbol,
    string memory _baseUri,
    string memory _contractUri,
    uint256 _maxSupply,
    uint256 _unitPrice,
    uint256 _mintAllowance,
    bool _reveal
  ) external returns (address token) {
    token = NFUTokenFactory.createNFUToken(
      address(nfuTokenSource),
      _owner,
      CommonNFTAttributes({
        name: _name,
        symbol: _symbol,
        baseUri: _baseUri,
        revealed: _reveal,
        contractUri: _contractUri,
        maxSupply: _maxSupply,
        unitPrice: _unitPrice,
        mintAllowance: _mintAllowance
      }),
      PermissionValidationComponents({
        jbxOperatorStore: operatorStore,
        jbxDirectory: jbxDirectory,
        jbxProjects: jbxProjects
      }),
      feeOracle
    );

    emit Deployment('NFUToken', token);
  }

  /**
   * @dev This creates a token that can be minted immediately, to discourage this, unitPrice can be set high, then mint period can be defined before setting price to a "reasonable" value.
   */
  function deployNFUMembership(
    address _owner,
    string memory _name,
    string memory _symbol,
    string memory _baseUri,
    string memory _contractUri,
    uint256 _maxSupply,
    uint256 _unitPrice,
    uint256 _mintAllowance,
    uint256 _mintEnd,
    TransferType _transferType
  ) external returns (address token) {
    token = NFUMembershipFactory.createNFUMembership(
      address(nfuMembershipSource),
      _owner,
      _name,
      _symbol,
      _baseUri,
      _contractUri,
      _maxSupply,
      _unitPrice,
      _mintAllowance,
      _mintEnd,
      _transferType
    );

    emit Deployment('NFUMembership', token);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../Auctions/DutchAuction.sol';
import '../Auctions/EnglishAuction.sol';
import '../Auctions/FixedPriceSale.sol';
import '../NFT/NFUToken.sol';
import '../TokenLiquidator.sol';
import './Deployer_v004.sol';
import './Factories/PaymentProcessorFactory.sol';

/**
 * @notice This version of the deployer adds the ability to deploy PaymentProcessor instances to allow project to accept payments in various ERC20 tokens.
 */
/// @custom:oz-upgrades-unsafe-allow external-library-linking
contract Deployer_v005 is Deployer_v004 {
  ITokenLiquidator internal tokenLiquidator;

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  function initialize(
    DutchAuctionHouse _dutchAuctionSource,
    EnglishAuctionHouse _englishAuctionSource,
    FixedPriceSale _fixedPriceSaleSource,
    NFUToken _nfuTokenSource,
    NFUMembership _nfuMembershipSource,
    ITokenLiquidator _tokenLiquidator
  ) public virtual reinitializer(5) {
    __Ownable_init();
    __UUPSUpgradeable_init();

    dutchAuctionSource = _dutchAuctionSource;
    englishAuctionSource = _englishAuctionSource;
    fixedPriceSaleSource = _fixedPriceSaleSource;
    nfuTokenSource = _nfuTokenSource;
    nfuMembershipSource = _nfuMembershipSource;
    tokenLiquidator = _tokenLiquidator;
  }

  function deployPaymentProcessor(
    IJBDirectory _jbxDirectory,
    IJBOperatorStore _jbxOperatorStore,
    IJBProjects _jbxProjects,
    uint256 _jbxProjectId,
    bool _ignoreFailures,
    bool _defaultLiquidation
  ) external returns (address processor) {
    processor = PaymentProcessorFactory.createPaymentProcessor(
      _jbxDirectory,
      _jbxOperatorStore,
      _jbxProjects,
      tokenLiquidator,
      _jbxProjectId,
      _ignoreFailures,
      _defaultLiquidation
    );

    emit Deployment('PaymentProcessor', processor);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/proxy/Clones.sol';
import '@openzeppelin/contracts/utils/introspection/IERC165.sol';

import '../../../interfaces/IJBDirectory.sol';
import '../../../interfaces/IJBPaymentTerminal.sol';

import '../../Auctions/DutchAuction.sol';
import '../../Auctions/EnglishAuction.sol';
import '../../Auctions/FixedPriceSale.sol';

library AuctionsFactory {
  error INVALID_SOURCE_CONTRACT();

  function createDutchAuction(
    address _source,
    uint256 _projectId,
    IJBPaymentTerminal _feeReceiver,
    uint256 _feeRate,
    bool _allowPublicAuctions,
    uint256 _periodDuration,
    address _owner,
    IJBDirectory _directory
  ) public returns (address auctionClone) {
    if (!IERC165(_source).supportsInterface(type(IDutchAuctionHouse).interfaceId)) {
      revert INVALID_SOURCE_CONTRACT();
    }

    auctionClone = Clones.clone(_source);
    DutchAuctionHouse(auctionClone).initialize(
      _projectId,
      _feeReceiver,
      _feeRate,
      _allowPublicAuctions,
      _periodDuration,
      _owner,
      _directory
    );
  }

  function createEnglishAuction(
    address _source,
    uint256 _projectId,
    IJBPaymentTerminal _feeReceiver,
    uint256 _feeRate,
    bool _allowPublicAuctions,
    address _owner,
    IJBDirectory _directory
  ) public returns (address auctionClone) {
    if (!IERC165(_source).supportsInterface(type(IEnglishAuctionHouse).interfaceId)) {
      revert INVALID_SOURCE_CONTRACT();
    }

    auctionClone = Clones.clone(_source);
    EnglishAuctionHouse(auctionClone).initialize(
      _projectId,
      _feeReceiver,
      _feeRate,
      _allowPublicAuctions,
      _owner,
      _directory
    );
  }

  function createFixedPriceSale(
    address _source,
    uint256 _projectId,
    IJBPaymentTerminal _feeReceiver,
    uint256 _feeRate,
    bool _allowPublicSales,
    address _owner,
    IJBDirectory _directory
  ) public returns (address auctionClone) {
    if (!IERC165(_source).supportsInterface(type(IFixedPriceSale).interfaceId)) {
      revert INVALID_SOURCE_CONTRACT();
    }

    auctionClone = Clones.clone(_source);
    FixedPriceSale(auctionClone).initialize(
      _projectId,
      _feeReceiver,
      _feeRate,
      _allowPublicSales,
      _owner,
      _directory
    );
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../../MixedPaymentSplitter.sol';
import '../../../interfaces/IJBDirectory.sol';

/**
 * @notice Creates an instance of MixedPaymentSplitter contract
 */
library MixedPaymentSplitterFactory {
  function createMixedPaymentSplitter(
    string memory _name,
    address[] memory _payees,
    uint256[] memory _projects,
    uint256[] memory _shares,
    IJBDirectory _jbxDirectory,
    address _owner
  ) public returns (address) {
    MixedPaymentSplitter s = new MixedPaymentSplitter(
      _name,
      _payees,
      _projects,
      _shares,
      _jbxDirectory,
      _owner
    );

    return address(s);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../../NFT/NFToken.sol';

import '../../NFT/interfaces/IMintFeeOracle.sol';

/**
 * @notice Creates an instance of NFToken contract
 */
library NFTokenFactory {
  /**
   * @notice In addition to taking the parameters requires by the NFToken contract, the `_owner` argument will be used to assign ownership after contract deployment.
   */
  function createNFToken(
    address payable _owner,
    CommonNFTAttributes memory _commonNFTAttributes,
    PermissionValidationComponents memory _permissionValidationComponents,
    IMintFeeOracle _feeOracle
  ) external returns (address) {
    NFToken t = new NFToken(_commonNFTAttributes, _permissionValidationComponents, _feeOracle);

    abdicate(t, _owner);

    return address(t);
  }

  function abdicate(NFToken _t, address payable _owner) private {
    _t.setPayoutReceiver(_owner);
    _t.setRoyalties(_owner, 0);

    _t.grantRole(0x00, _owner); // AccessControl.DEFAULT_ADMIN_ROLE
    _t.grantRole(keccak256('MINTER_ROLE'), _owner);
    _t.grantRole(keccak256('REVEALER_ROLE'), _owner);

    _t.revokeRole(keccak256('REVEALER_ROLE'), address(this));
    _t.revokeRole(keccak256('MINTER_ROLE'), address(this));
    _t.revokeRole(0x00, address(this));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../../../interfaces/IJBDirectory.sol';

import '../../NFTRewards/NFTRewardDataSourceDelegate.sol';
import '../../NFTRewards/OpenTieredTokenUriResolver.sol';
import '../../NFTRewards/OpenTieredPriceResolver.sol';
import '../../NFTRewards/TieredTokenUriResolver.sol';
import '../../NFTRewards/TieredPriceResolver.sol';

import '../../interfaces/IPriceResolver.sol';
import '../../interfaces/IToken721UriResolver.sol';

/**
 * @notice Deploys instances of NFTRewardDataSourceDelegate and supporting contracts.
 */
library NFTRewardDataSourceFactory {
  function createOpenTieredTokenUriResolver(string memory _baseUri) public returns (address) {
    OpenTieredTokenUriResolver c = new OpenTieredTokenUriResolver(_baseUri);

    return address(c);
  }

  function createOpenTieredPriceResolver(address _contributionToken, OpenRewardTier[] memory _tiers)
    public
    returns (address)
  {
    OpenTieredPriceResolver c = new OpenTieredPriceResolver(_contributionToken, _tiers);

    return address(c);
  }

  function createTieredTokenUriResolver(string memory _baseUri, uint256[] memory _idRange)
    public
    returns (address)
  {
    TieredTokenUriResolver c = new TieredTokenUriResolver(_baseUri, _idRange);

    return address(c);
  }

  function createTieredPriceResolver(
    address _contributionToken,
    uint256 _mintCap,
    uint256 _userMintCap,
    RewardTier[] memory _tiers
  ) public returns (address) {
    TieredPriceResolver c = new TieredPriceResolver(
      _contributionToken,
      _mintCap,
      _userMintCap,
      _tiers
    );

    return address(c);
  }

  function createNFTRewardDataSource(
    uint256 _projectId,
    IJBDirectory _jbxDirectory,
    uint256 _maxSupply,
    JBTokenAmount memory _minContribution,
    string memory _name,
    string memory _symbol,
    string memory _uri,
    IToken721UriResolver _tokenUriResolverAddress,
    string memory _contractMetadataUri,
    address _admin,
    IPriceResolver _priceResolver
  ) public returns (address) {
    NFTRewardDataSourceDelegate ds = new NFTRewardDataSourceDelegate(
      _projectId,
      _jbxDirectory,
      _maxSupply,
      _minContribution,
      _name,
      _symbol,
      _uri,
      _tokenUriResolverAddress,
      _contractMetadataUri,
      _admin,
      _priceResolver
    );

    return address(ds);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/proxy/Clones.sol';

import '../../NFT/NFUMembership.sol';

/**
 * @notice Clones an instance of NFUToken contract for a new owner.
 */
library NFUMembershipFactory {
  /**
   * @notice In addition to taking the parameters requires by the NFUToken contract, the `_owner` argument will be used to assign ownership after contract deployment.
   *
   * @dev mintPeriodStart and mintPeriodEnd are set to 0 allowing immediate minting. These constrants can be set with a call to `updateMintPeriod`.
   *
   * @param _source Known-good deployment of NFUToken contract.
   */
  function createNFUMembership(
    address _source,
    address _owner,
    string memory _name,
    string memory _symbol,
    string memory _baseUri,
    string memory _contractUri,
    uint256 _maxSupply,
    uint256 _unitPrice,
    uint256 _mintAllowance,
    uint256 _mintEnd,
    TransferType _transferType
  ) external returns (address token) {
    token = Clones.clone(_source);

    NFUMembership(token).initialize(
      _owner,
      _name,
      _symbol,
      _baseUri,
      _contractUri,
      _maxSupply,
      _unitPrice,
      _mintAllowance,
      0,
      _mintEnd,
      _transferType
    );
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/proxy/Clones.sol';

import '../../NFT/NFUToken.sol';

/**
 * @notice Clones an instance of NFUToken contract for a new owner.
 */
library NFUTokenFactory {
  /**
   * @notice In addition to taking the parameters requires by the NFUToken contract, the `_owner` argument will be used to assign ownership after contract deployment.
   *
   * @dev mintPeriodStart and mintPeriodEnd are set to 0 allowing immediate minting. These constrants can be set with a call to `updateMintPeriod`.
   *
   * @param _source Known-good deployment of NFUToken contract.
   */
  function createNFUToken(
    address _source,
    address payable _owner,
    CommonNFTAttributes memory _commonNFTAttributes,
    PermissionValidationComponents memory _permissionValidationComponents,
    IMintFeeOracle _feeOracle
  ) external returns (address token) {
    token = Clones.clone(_source);

    NFUToken(token).initialize(
      _owner,
      _commonNFTAttributes,
      _permissionValidationComponents,
      _feeOracle
    );
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../../PaymentProcessor.sol';
import '../../../interfaces/IJBDirectory.sol';
import '../../../interfaces/IJBOperatorStore.sol';
import '../../../interfaces/IJBProjects.sol';
import '../../TokenLiquidator.sol';

/**
 * @notice Creates an instance of PaymentProcessor contract
 */
library PaymentProcessorFactory {
  /**
   * @notice Deploys a PaymentProcessor.
   */
  function createPaymentProcessor(
    IJBDirectory _jbxDirectory,
    IJBOperatorStore _jbxOperatorStore,
    IJBProjects _jbxProjects,
    ITokenLiquidator _liquidator,
    uint256 _jbxProjectId,
    bool _ignoreFailures,
    bool _defaultLiquidation
  ) external returns (address paymentProcessor) {
    PaymentProcessor p = new PaymentProcessor(
      _jbxDirectory,
      _jbxOperatorStore,
      _jbxProjects,
      _liquidator,
      _jbxProjectId,
      _ignoreFailures,
      _defaultLiquidation
    );

    return address(p);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './IToken721UriResolver.sol';
import './ITokenSupplyDetails.sol';

interface INFTRewardDataSourceDelegate is ITokenSupplyDetails {
  function transfer(address _to, uint256 _id) external;

  function mint(address) external returns (uint256);

  function burn(address, uint256) external;

  function isOwner(address, uint256) external view returns (bool);

  function contractURI() external view returns (string memory);

  function setContractUri(string calldata _contractMetadataUri) external;

  function setTokenUri(string calldata _uri) external;

  function setTokenUriResolver(IToken721UriResolver _tokenUriResolverAddress) external;

  function setTransferrable(bool _transferrable) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../../structs/JBTokenAmount.sol';
import './ITokenSupplyDetails.sol';

interface IPriceResolver {
  function validateContribution(
    address account,
    JBTokenAmount calldata contribution,
    ITokenSupplyDetails token
  ) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
  @notice
  Intended to serve custom ERC721 token URIs.
 */
interface IToken721UriResolver {
  function tokenURI(uint256) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './IToken721UriResolver.sol';

interface ITokenSupplyDetails {
  /**
    @notice Should return the total number of tokens in this contract. For ERC721 this would be the number of unique token ids. For ERC1155 this would be the number of unique token ids and their individual supply. For ERC20 this would be total supply of the token.
   */
  function totalSupply() external view returns (uint256);

  /**
    @notice For ERC1155 this would be the supply of a particular token for the given id. For ERC721 this would be 0 or 1 depending on whether or not the given token has been minted.
   */
  function tokenSupply(uint256) external view returns (uint256);

  /**
    @notice Total holder balance regardless of token id within the contract.
   */
  function totalOwnerBalance(address) external view returns (uint256);

  /**
    @notice For ERC1155 this would be the token count held by the address in the given token id. For ERC721 this would be 0 or 1 depending on ownership of the specified token id by the address. For ERC20 this would be the token balance of the address.
   */
  function ownerTokenBalance(address, uint256) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/utils/Address.sol';

import '../interfaces/IJBDirectory.sol';
import '../libraries/JBTokens.sol';

/**
 * @title MixedPaymentSplitter
 *
 * @notice Allows payments to be distributed to addresses or JBX projects with appropriately configured terminals.
 *
 * @dev based on OpenZeppelin finance/PaymentSplitter.sol v4.7.0
 */
contract MixedPaymentSplitter is Ownable {
  //*********************************************************************//
  // --------------------------- custom events ------------------------- //
  //*********************************************************************//

  event PayeeAdded(address account, uint256 shares);
  event ProjectAdded(uint256 project, uint256 shares);
  event PaymentReleased(address account, uint256 amount);
  event ProjectPaymentReleased(uint256 projectId, uint256 amount);
  event TokenPaymentReleased(IERC20 indexed token, address account, uint256 amount);
  event TokenProjectPaymentReleased(IERC20 indexed token, uint256 projectId, uint256 amount);
  event PaymentReceived(address from, uint256 amount);

  //*********************************************************************//
  // --------------------------- custom errors ------------------------- //
  //*********************************************************************//

  error INVALID_LENGTH();
  error INVALID_DIRECTORY();
  error MISSING_PROJECT_TERMINAL();
  error INVALID_PAYEE();
  error INVALID_SHARE();
  error PAYMENT_FAILURE();
  error NO_SHARE();
  error NOTHING_DUE();
  error INVALID_SHARE_TOTAL();

  //*********************************************************************//
  // --------------------- public stored properties -------------------- //
  //*********************************************************************//

  /**
   * @dev Total number of shares available.
   */
  uint256 public constant SHARE_WHOLE = 1_000_000;

  /**
   * @dev Total number of shares already assigned to payees.
   */
  uint256 public assignedShares;

  /**
   * @dev Map of shares belonging to addresses, wether EOA or contracts. The map key is encoded such that bottom 160 bits are an address and top 96 bits are a JBX project id.
   */
  mapping(uint256 => uint256) private shares;

  /**
   * @dev Total amount of Ether paid out.
   */
  uint256 public totalReleased;

  /**
   * @dev Map of released Ether payments. The key is encoded such that bottom 160 bits are an address and top 96 bits are a JBX project id.
   */
  mapping(uint256 => uint256) public released;

  /**
   * @dev Total amount of token balances paid out.
   */
  mapping(IERC20 => uint256) public _erc20TotalReleased;

  /**
   * @dev Map of released token payments. The key is encoded such that bottom 160 bits are an address and top 96 bits are a JBX project id.
   */
  mapping(IERC20 => mapping(uint256 => uint256)) public _erc20Released;

  IJBDirectory jbxDirectory;
  string public name;

  //*********************************************************************//
  // -------------------------- constructor ---------------------------- //
  //*********************************************************************//

  /**
   * @dev It's possible to deploy this contract with partial subscription and then call addPayee to bring it to full 100%.
   *
   * @param _name Name for this split configuration.
   * @param _payees Payable addresses to send payment portion to.
   * @param _projects Juicebox project ids to send payment portion to.
   * @param _shares Share assignment in the same order as payees and projects parameters. Share total is 1_000_000.
   * @param _jbxDirectory Juicebox directory contract
   * @param _owner Admin of the contract.
   */
  constructor(
    string memory _name,
    address[] memory _payees,
    uint256[] memory _projects,
    uint256[] memory _shares,
    IJBDirectory _jbxDirectory,
    address _owner
  ) {
    if (_payees.length == 0 && _projects.length == 0) {
      revert INVALID_LENGTH();
    }

    if (_shares.length == 0) {
      revert INVALID_LENGTH();
    }

    if (_payees.length + _projects.length != _shares.length) {
      revert INVALID_LENGTH();
    }

    if (_projects.length != 0 && address(_jbxDirectory) == address(0)) {
      revert INVALID_DIRECTORY();
    }

    jbxDirectory = _jbxDirectory;
    name = _name;

    for (uint256 i; i != _payees.length; ) {
      _addPayee(_payees[i], _shares[i]);
      ++i;
    }

    for (uint256 i; i != _projects.length; ) {
      _addProject(_projects[i], _shares[_payees.length + i]);
      ++i;
    }

    _transferOwnership(_owner);
  }

  //*********************************************************************//
  // ------------------------- external views -------------------------- //
  //*********************************************************************//

  receive() external payable virtual {
    emit PaymentReceived(msg.sender, msg.value);
  }

  /**
   * @notice Returns pending Ether payment for a given address.
   */
  function pending(address _account) public view returns (uint256) {
    uint256 totalReceived = address(this).balance + totalReleased;
    return
      _pendingPayment(
        uint256(uint160(_account)),
        totalReceived,
        released[uint256(uint160(_account))]
      );
  }

  /**
   * @notice Returns pending Ether payment for a given JBX project.
   */
  function pending(uint256 _projectId) public view returns (uint256) {
    uint256 totalReceived = address(this).balance + totalReleased;
    return _pendingPayment(_projectId << 160, totalReceived, released[_projectId << 160]);
  }

  /**
   * @notice Returns pending payment for a given address in a given token.
   */
  function pending(IERC20 _token, address _account) public view returns (uint256) {
    uint256 totalReceived = _token.balanceOf(address(this)) + _erc20TotalReleased[_token];
    return
      _pendingPayment(
        uint256(uint160(_account)),
        totalReceived,
        _erc20Released[_token][uint256(uint160(_account))]
      );
  }

  /**
   * @notice Returns pending payment for a given JBX project in a given token
   */
  function pending(IERC20 _token, uint256 _projectId) public view returns (uint256) {
    uint256 totalReceived = _token.balanceOf(address(this)) + _erc20TotalReleased[_token];
    return
      _pendingPayment(_projectId << 160, totalReceived, _erc20Released[_token][_projectId << 160]);
  }

  //*********************************************************************//
  // ---------------------- external transactions ---------------------- //
  //*********************************************************************//

  /**
   * @notice A trustless function to distribute a pending Ether payment to a given address. Will revert for various reasons like address not having a share or having no pending payment.
   */
  function distribute(address payable _account) external virtual {
    if (shares[uint256(uint160(address(_account)))] == 0) {
      revert NO_SHARE();
    }

    uint256 payment = pending(_account);
    if (payment == 0) {
      revert NOTHING_DUE();
    }

    unchecked {
      totalReleased += payment;
      released[uint256(uint160(address(_account)))] += payment;
    }

    Address.sendValue(_account, payment);
    emit PaymentReleased(_account, payment);
  }

  /**
   * @notice A trustless function to distribute a pending Ether payment to a JBX project. Will revert for various reasons like project not having a share or having no pending payment or a registered Ether terminal.
   */
  function distribute(uint256 _projectId) public virtual {
    uint256 key = _projectId << 160;
    if (shares[key] == 0) {
      revert NO_SHARE();
    }

    uint256 payment = pending(_projectId);
    if (payment == 0) {
      revert NOTHING_DUE();
    }

    unchecked {
      totalReleased += payment;
      released[key] += payment;
    }

    IJBPaymentTerminal terminal = jbxDirectory.primaryTerminalOf(_projectId, JBTokens.ETH);
    if (address(terminal) == address(0)) {
      revert PAYMENT_FAILURE();
    }

    terminal.addToBalanceOf{value: payment}(
      _projectId,
      payment,
      JBTokens.ETH,
      string(abi.encodePacked(name, ' split payment')),
      ''
    );
    emit ProjectPaymentReleased(_projectId, payment);
  }

  /**
   * @notice A trustless function to distribute a pending token payment to a given address. Will revert for various reasons like address not having a share or having no pending payment.
   */
  function distribute(IERC20 _token, address _account) public virtual {
    if (shares[uint256(uint160(_account))] == 0) {
      revert NO_SHARE();
    }

    uint256 payment = pending(_token, _account);
    if (payment == 0) {
      revert NOTHING_DUE();
    }

    unchecked {
      _erc20TotalReleased[_token] += payment;
      _erc20Released[_token][uint256(uint160(_account))] += payment;
    }

    bool sent = IERC20(_token).transfer(_account, payment);
    if (!sent) {
      revert PAYMENT_FAILURE();
    }
    emit TokenPaymentReleased(_token, _account, payment);
  }

  /**
   * @notice A trustless function to distribute a pending token payment to a JBX project. Will revert for various reasons like project not having a share or having no pending payment or a registered token terminal.
   */
  function distribute(IERC20 _token, uint256 _projectId) public virtual {
    uint256 key = _projectId << 160;
    if (shares[key] == 0) {
      revert NO_SHARE();
    }

    uint256 payment = pending(_token, _projectId);
    if (payment == 0) {
      revert NOTHING_DUE();
    }

    unchecked {
      _erc20TotalReleased[_token] += payment;
      _erc20Released[_token][key] += payment;
    }

    IJBPaymentTerminal terminal = jbxDirectory.primaryTerminalOf(_projectId, address(_token));
    if (address(terminal) == address(0)) {
      revert PAYMENT_FAILURE();
    }

    _token.approve(address(terminal), payment);
    terminal.addToBalanceOf(
      _projectId,
      payment,
      JBTokens.ETH,
      string(abi.encodePacked(name, ' split payment')),
      ''
    );
    emit TokenProjectPaymentReleased(_token, _projectId, payment);
  }

  //*********************************************************************//
  // --------------------- privileged transactions --------------------- //
  //*********************************************************************//

  function addPayee(address _account, uint256 _shares) external onlyOwner {
    _addPayee(_account, _shares);
  }

  function addPayee(uint256 _projectId, uint256 _shares) external onlyOwner {
    _addProject(_projectId, _shares);
  }

  function withdraw() external onlyOwner {
    // TODO
  }

  //*********************************************************************//
  // ---------------------- private transactions ----------------------- //
  //*********************************************************************//

  function _pendingPayment(
    uint256 _key,
    uint256 _totalReceived,
    uint256 _alreadyReleased
  ) private view returns (uint256) {
    return ((_totalReceived * shares[_key]) / SHARE_WHOLE) - _alreadyReleased;
  }

  function _addPayee(address _account, uint256 _shares) private {
    if (_account == address(0)) {
      revert INVALID_PAYEE();
    }

    if (_shares == 0) {
      revert INVALID_SHARE();
    }

    uint256 k = uint256(uint160(_account));

    shares[k] = _shares;
    assignedShares += _shares;

    if (assignedShares > SHARE_WHOLE) {
      revert INVALID_SHARE_TOTAL();
    }

    emit PayeeAdded(_account, _shares);
  }

  function _addProject(uint256 _projectId, uint256 _shares) private {
    if (_projectId > type(uint96).max || _projectId == 0) {
      revert INVALID_PAYEE();
    }

    if (address(jbxDirectory.primaryTerminalOf(_projectId, JBTokens.ETH)) == address(0)) {
      revert MISSING_PROJECT_TERMINAL();
    }

    if (_shares == 0) {
      revert INVALID_SHARE();
    }

    uint256 k = _projectId << 160;

    shares[k] += _shares;
    assignedShares += _shares;

    if (assignedShares > SHARE_WHOLE) {
      revert INVALID_SHARE_TOTAL();
    }

    emit ProjectAdded(_projectId, _shares);
  }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/AccessControlEnumerable.sol';
import '@openzeppelin/contracts/interfaces/IERC2981.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/utils/Strings.sol';

import '../interfaces/INFTPriceResolver.sol';
import '../interfaces/IOperatorFilter.sol';
import './ERC721FU.sol';

enum TransferType {
  SOUL_BOUND,
  DEACTIVATE,
  STANDARD
}

/**
 * @notice This is a reduced implementation similar to BaseNFT but with limitations on token transfers. This functionality was originally described in https://github.com/tankbottoms/juice-interface-svelte/issues/752.
 */
abstract contract BaseMembership is ERC721FU, AccessControlEnumerable, ReentrancyGuard {
  using Strings for uint256;

  bytes32 public constant MINTER_ROLE = keccak256('MINTER_ROLE');
  bytes32 public constant REVEALER_ROLE = keccak256('REVEALER_ROLE');

  /**
   * @notice NFT provenance hash reassignment prohibited.
   */
  error PROVENANCE_REASSIGNMENT();

  /**
   * @notice Base URI assignment along with the "revealed" flag can only be done once.
   */
  error ALREADY_REVEALED();

  /**
   * @notice User mint allowance exhausted.
   */
  error ALLOWANCE_EXHAUSTED();

  /**
   * @notice mint() function received an incorrect payment, expected payment returned as argument.
   */
  error INCORRECT_PAYMENT(uint256);

  /**
   * @notice Token supply exhausted, all tokens have been minted.
   */
  error SUPPLY_EXHAUSTED();

  /**
   * @notice Various payment failures caused by incorrect contract condiguration.
   */
  error PAYMENT_FAILURE();

  error MINT_NOT_STARTED();
  error MINT_CONCLUDED();

  error INVALID_TOKEN();

  error INVALID_RATE();

  error MINTING_PAUSED();

  error CALLER_BLOCKED();

  /**
   * @notice This ERC721 implementation is soul-bound, transfers and approvals are disabled. Tokens can be minted subject to OperatorFilter is any and can be burned by priviliged users.
   */
  error TRANSFER_DISABLED();

  /**
   * @notice Prevents minting outside of the mint period if set. Can be set only to have a start or only and end date.
   */
  modifier onlyDuringMintPeriod() {
    uint256 start = mintPeriod >> 128;
    if (start != 0) {
      if (start > block.timestamp) {
        revert MINT_NOT_STARTED();
      }
    }

    uint256 end = uint128(mintPeriod);
    if (end != 0) {
      if (end < block.timestamp) {
        revert MINT_CONCLUDED();
      }
    }

    _;
  }
  /**
   * @notice Prevents minting by blocked addresses and contracts hashes.
   */
  modifier callerNotBlocked(address account) {
    if (address(operatorFilter) != address(0)) {
      if (!operatorFilter.mayTransfer(account)) {
        revert CALLER_BLOCKED();
      }
    }

    _;
  }

  uint256 public maxSupply;
  uint256 public unitPrice;

  /**
   * @notice Maximum number of NFTs a single address can own. For SOUL_BOUND configuration this number should be 1.
   */
  uint256 public mintAllowance;
  uint256 public mintPeriod;
  uint256 public totalSupply;

  string public baseUri;
  string public contractUri;
  string public provenanceHash;

  /**
   * @notice Revealed flag.
   *
   * @dev changes the way tokenUri(uint256) works.
   */
  bool public isRevealed;

  /**
   * @notice Pause minting flag
   */
  bool public isPaused;

  /**
   * @notice Address that receives payments from mint operations.
   */
  address payable public payoutReceiver;

  /**
   * @notice Address that receives payments from secondary sales.
   */
  address payable public royaltyReceiver;

  /**
   * @notice Royalty rate expressed in bps.
   */
  uint256 public royaltyRate;

  TransferType public transferType;

  mapping(uint256 => bool) public activeTokens;
  mapping(address => bool) public activeAddresses;

  INFTPriceResolver public priceResolver;
  IOperatorFilter public operatorFilter;

  //*********************************************************************//
  // ----------------------------- ERC721 ------------------------------ //
  //*********************************************************************//

  /**
   * @notice Apply transfer type condition.
   */
  function approve(address _spender, uint256 _id) public virtual override {
    if (transferType == TransferType.SOUL_BOUND) {
      revert TRANSFER_DISABLED();
    }

    ERC721FU.approve(_spender, _id);
  }

  /**
   * @notice Apply transfer type condition.
   */
  function setApprovalForAll(address _operator, bool _approved) public virtual override {
    if (transferType == TransferType.SOUL_BOUND) {
      revert TRANSFER_DISABLED();
    }

    ERC721FU.setApprovalForAll(_operator, _approved);
  }

  /**
   * @notice Apply transfer type condition.
   */
  function transferFrom(address _from, address _to, uint256 _id) public virtual override {
    if (transferType == TransferType.SOUL_BOUND) {
      revert TRANSFER_DISABLED();
    }

    ERC721FU.transferFrom(_from, _to, _id);

    if (transferType == TransferType.DEACTIVATE) {
      activeTokens[_id] = false;
    }
  }

  /**
   * @notice Apply transfer type condition.
   */
  function safeTransferFrom(address _from, address _to, uint256 _id) public virtual override {
    if (transferType == TransferType.SOUL_BOUND) {
      revert TRANSFER_DISABLED();
    }

    ERC721FU.safeTransferFrom(_from, _to, _id);

    if (transferType == TransferType.DEACTIVATE) {
      activeTokens[_id] = false;
    }
  }

  /**
   * @notice Apply transfer type condition.
   */
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _id,
    bytes calldata _data
  ) public virtual override {
    if (transferType == TransferType.SOUL_BOUND) {
      revert TRANSFER_DISABLED();
    }

    ERC721FU.safeTransferFrom(_from, _to, _id, _data);

    if (transferType == TransferType.DEACTIVATE) {
      activeTokens[_id] = false;
    }
  }

  //*********************************************************************//
  // ------------------------- external views -------------------------- //
  //*********************************************************************//

  /**
   * @notice Get contract metadata to make OpenSea happy.
   */
  function contractURI() public view returns (string memory) {
    return contractUri;
  }

  /**
   * @dev If the token has been set as "revealed", returned uri will append the token id
   */
  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory uri) {
    if (_ownerOf[_tokenId] == address(0)) {
      uri = '';
    } else {
      uri = !isRevealed ? baseUri : string(abi.encodePacked(baseUri, _tokenId.toString()));
    }
  }

  /**
   * @notice EIP2981 implementation for royalty distribution.
   *
   * @param _tokenId Token id.
   * @param _salePrice NFT sale price to derive royalty amount from.
   */
  function royaltyInfo(
    uint256 _tokenId,
    uint256 _salePrice
  ) external view virtual returns (address receiver, uint256 royaltyAmount) {
    if (_salePrice == 0 || _ownerOf[_tokenId] != address(0)) {
      receiver = address(0);
      royaltyAmount = 0;
    } else {
      receiver = royaltyReceiver == address(0) ? address(this) : royaltyReceiver;
      royaltyAmount = (_salePrice * royaltyRate) / 10_000;
    }
  }

  /**
   * @dev rari-capital version of ERC721 reverts when owner is address(0), usually that means it's not minted, this is problematic for several workflows. This function simply returns an address.
   */
  function ownerOf(uint256 _tokenId) public view override returns (address owner) {
    owner = _ownerOf[_tokenId];
  }

  function mintPeriodStart() external view returns (uint256 start) {
    start = mintPeriod >> 128;
  }

  function mintPeriodEnd() external view returns (uint256 end) {
    end = uint256(uint128(mintPeriod));
  }

  function getMintPrice(address _minter) external view returns (uint256) {
    // TODO: virtual
    if (address(priceResolver) == address(0)) {
      return unitPrice;
    }

    return priceResolver.getPriceWithParams(address(this), _minter, totalSupply + 1, '');
  }

  function isActive(uint256 _tokenId) external view returns (bool) {
    address tokenOwner = _ownerOf[_tokenId];
    if (tokenOwner == address(0)) {
      return false;
    }

    return activeAddresses[tokenOwner] || activeTokens[_tokenId];
  }

  //*********************************************************************//
  // ---------------------- external transactions ---------------------- //
  //*********************************************************************//

  /**
   * @notice Mints a token to the calling account. Must be paid in Ether if price is non-zero.
   *
   * @dev Proceeds are forwarded to the default Juicebox terminal for the project id set in the constructor. Payment will fail if the terminal is not set in the jbx directory.
   */
  function mint()
    external
    payable
    virtual
    nonReentrant
    onlyDuringMintPeriod
    callerNotBlocked(msg.sender)
    returns (uint256 tokenId)
  {
    tokenId = mintActual(msg.sender);
  }

  /**
   * @notice Mints a token to the provided account rather than the caller. Must be paid in Ether if price is non-zero.
   *
   * @dev Proceeds are forwarded to the default Juicebox terminal for the project id set in the constructor. Payment will fail if the terminal is not set in the jbx directory.
   */
  function mint(
    address _account
  )
    external
    payable
    virtual
    nonReentrant
    onlyDuringMintPeriod
    callerNotBlocked(msg.sender)
    returns (uint256 tokenId)
  {
    tokenId = mintActual(_account);
  }

  //*********************************************************************//
  // --------------------- privileged transactions --------------------- //
  //*********************************************************************//

  /**
   * @notice Privileged operation callable by accounts with MINTER_ROLE permission to mint the next NFT id to the provided address.
   *
   * @dev Note, this function is not subject to mintAllowance.
   */
  function mintFor(
    address _account
  ) external virtual onlyRole(MINTER_ROLE) returns (uint256 tokenId) {
    if (totalSupply == maxSupply) {
      revert SUPPLY_EXHAUSTED();
    }

    unchecked {
      ++totalSupply;
    }
    tokenId = totalSupply;
    _mint(_account, tokenId);
  }

  /**
   * @notice Privileged operation callable by accounts with MINTER_ROLE permission to burn a token.
   */
  function revoke(uint256 _tokenId) external virtual onlyRole(MINTER_ROLE) {
    _burn(_tokenId);
  }

  function setPause(bool pause) external onlyRole(DEFAULT_ADMIN_ROLE) {
    isPaused = pause;
  }

  function addMinter(address _account) external onlyRole(DEFAULT_ADMIN_ROLE) {
    _grantRole(MINTER_ROLE, _account);
  }

  function removeMinter(address _account) external onlyRole(DEFAULT_ADMIN_ROLE) {
    _revokeRole(MINTER_ROLE, _account);
  }

  function addRevealer(address _account) external onlyRole(DEFAULT_ADMIN_ROLE) {
    _grantRole(REVEALER_ROLE, _account);
  }

  function removeRevealer(address _account) external onlyRole(DEFAULT_ADMIN_ROLE) {
    _revokeRole(REVEALER_ROLE, _account);
  }

  /**
   * @notice Set provenance hash.
   *
   * @dev This operation can only be executed once.
   */
  function setProvenanceHash(string memory _provenanceHash) external onlyRole(DEFAULT_ADMIN_ROLE) {
    if (bytes(provenanceHash).length != 0) {
      revert PROVENANCE_REASSIGNMENT();
    }
    provenanceHash = _provenanceHash;
  }

  /**
    @notice Metadata URI for token details in OpenSea format.
   */
  function setContractURI(string memory _contractUri) external onlyRole(DEFAULT_ADMIN_ROLE) {
    contractUri = _contractUri;
  }

  /**
   * @notice Allows adjustment of minting period.
   *
   * @param _mintPeriodStart New minting period start.
   * @param _mintPeriodEnd New minting period end.
   */
  function updateMintPeriod(
    uint256 _mintPeriodStart,
    uint256 _mintPeriodEnd
  ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    mintPeriod = (_mintPeriodStart << 128) | _mintPeriodEnd;
  }

  function updateUnitPrice(uint256 _unitPrice) external onlyRole(DEFAULT_ADMIN_ROLE) {
    unitPrice = _unitPrice;
  }

  function updatePriceResolver(
    INFTPriceResolver _priceResolver
  ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    priceResolver = _priceResolver;
  }

  function updateOperatorFilter(
    IOperatorFilter _operatorFilter
  ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    operatorFilter = _operatorFilter;
  }

  /**
   * @notice Set NFT metadata base URI.
   *
   * @dev URI must include the trailing slash.
   */
  function setBaseURI(string memory _baseUri, bool _reveal) external onlyRole(REVEALER_ROLE) {
    if (isRevealed && !_reveal) {
      revert ALREADY_REVEALED();
    }

    baseUri = _baseUri;
    isRevealed = _reveal;
  }

  /**
   * @notice Allows owner to transfer ERC20 balances.
   */
  function transferTokenBalance(
    IERC20 token,
    address to,
    uint256 amount
  ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    token.transfer(to, amount);
  }

  function setPayoutReceiver(
    address payable _payoutReceiver
  ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    payoutReceiver = _payoutReceiver;
  }

  /**
   * @notice Sets royalty info
   *
   * @param _royaltyReceiver Payable royalties receiver.
   * @param _royaltyRate Rate expressed in bps, can only be set once.
   */
  function setRoyalties(
    address _royaltyReceiver,
    uint16 _royaltyRate
  ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    royaltyReceiver = payable(_royaltyReceiver);

    if (_royaltyRate > 10_000) {
      revert INVALID_RATE();
    }

    if (royaltyRate == 0) {
      royaltyRate = _royaltyRate;
    }
  }

  function activateToken(uint256 _tokenId, bool _active) external onlyRole(DEFAULT_ADMIN_ROLE) {
    if (_ownerOf[_tokenId] == address(0)) {
      revert INVALID_TOKEN();
    }

    activeTokens[_tokenId] = _active;
  }

  function activateAddress(address _account, bool _active) external onlyRole(DEFAULT_ADMIN_ROLE) {
    activeAddresses[_account] = _active;
  }

  //*********************************************************************//
  // ---------------------- internal transactions ---------------------- //
  //*********************************************************************//

  /**
   * @notice Accepts Ether payment and forwards it to the appropriate jbx terminal during the mint phase.
   *
   * @dev This version of the NFT does not directly accept Ether and will fail to process mint payment if there is no payoutReceiver set.
   *
   * @dev In case of multi-mint where the amount passed to the transaction is greater than the cost of a single mint, it would be up to the caller of this function to refund the difference. Here we'll take only the required amount to mint the tokens we're allowed to.
   */
  function processPayment() internal virtual returns (uint256 balance, uint256 refund) {
    uint256 accountBalance = _balanceOf[msg.sender];
    if (accountBalance == mintAllowance) {
      revert ALLOWANCE_EXHAUSTED();
    }

    uint256 expectedPrice = unitPrice;
    if (address(priceResolver) != address(0)) {
      expectedPrice = priceResolver.getPrice(address(this), msg.sender, 0);
    }

    uint256 mintCost = msg.value; // TODO: - platformMintFee;

    if (mintCost < expectedPrice) {
      revert INCORRECT_PAYMENT(expectedPrice);
    }

    if (mintCost == 0 || mintCost == expectedPrice) {
      balance = 1;
      refund = 0;
    } else if (mintCost > expectedPrice) {
      if (address(priceResolver) != address(0)) {
        // TODO: pending changes to INFTPriceResolver
        balance = 1;
        refund = mintCost - expectedPrice;
      } else {
        balance = mintCost / expectedPrice;

        if (totalSupply + balance > maxSupply) {
          // reduce to max supply
          balance -= totalSupply + balance - maxSupply;
        }

        if (accountBalance + balance > mintAllowance) {
          // reduce to mint allowance; since we're here, final balance shouuld be >= 1
          balance -= accountBalance + balance - mintAllowance;
        }

        refund = mintCost - (balance * expectedPrice);
      }
    }

    if (payoutReceiver != address(0)) {
      (bool success, ) = payoutReceiver.call{value: mintCost - refund}('');
      if (!success) {
        revert PAYMENT_FAILURE();
      }
    } else {
      revert PAYMENT_FAILURE();
    }

    // transfer platform fee
  }

  /**
   * @notice Function to consolidate functionality for external mint calls.
   *
   * @dev External calls should be validated by modifiers like `onlyDuringMintPeriod` and `callerNotBlocked`.
   *
   * @param _account Address to assign the new token to.
   */
  function mintActual(address _account) internal virtual returns (uint256 tokenId) {
    if (totalSupply == maxSupply) {
      revert SUPPLY_EXHAUSTED();
    }

    if (isPaused) {
      revert MINTING_PAUSED();
    }

    (uint256 balance, uint256 refund) = processPayment();

    for (; balance != 0; ) {
      unchecked {
        ++totalSupply;
      }
      tokenId = totalSupply;
      _mint(_account, tokenId);
      unchecked {
        --balance;
      }
    }

    if (refund != 0) {
      msg.sender.call{value: refund}('');
    }
  }

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(
    bytes4 interfaceId
  ) public view virtual override(AccessControlEnumerable, ERC721FU) returns (bool) {
    return
      interfaceId == type(IERC2981).interfaceId || // 0x2a55205a
      AccessControlEnumerable.supportsInterface(interfaceId) ||
      ERC721FU.supportsInterface(interfaceId);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/AccessControlEnumerable.sol';
import '@openzeppelin/contracts/interfaces/IERC2981.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/utils/Strings.sol';

import '../interfaces/INFTPriceResolver.sol';
import '../interfaces/IOperatorFilter.sol';
import './ERC721FU.sol';

/**
 * @notice Uniswap IQuoter interface snippet taken from uniswap v3 periphery library.
 */
interface IQuoter {
  function quoteExactInputSingle(
    address tokenIn,
    address tokenOut,
    uint24 fee,
    uint256 amountIn,
    uint160 sqrtPriceLimitX96
  ) external returns (uint256 amountOut);
}

abstract contract BaseNFT is ERC721FU, AccessControlEnumerable, ReentrancyGuard {
  using Strings for uint256;

  bytes32 public constant MINTER_ROLE = keccak256('MINTER_ROLE');
  bytes32 public constant REVEALER_ROLE = keccak256('REVEALER_ROLE');

  address public constant WETH9 = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
  address public constant DAI = address(0x6B175474E89094C44Da98b954EedeAC495271d0F);

  /**
   * @notice NFT provenance hash reassignment prohibited.
   */
  error PROVENANCE_REASSIGNMENT();

  /**
   * @notice Base URI assignment along with the "revealed" flag can only be done once.
   */
  error ALREADY_REVEALED();

  /**
   * @notice User mint allowance exhausted.
   */
  error ALLOWANCE_EXHAUSTED();

  /**
   * @notice mint() function received an incorrect payment, expected payment returned as argument.
   */
  error INCORRECT_PAYMENT(uint256);

  /**
   * @notice Token supply exhausted, all tokens have been minted.
   */
  error SUPPLY_EXHAUSTED();

  /**
   * @notice Various payment failures caused by incorrect contract condiguration.
   */
  error PAYMENT_FAILURE();

  error MINT_NOT_STARTED();
  error MINT_CONCLUDED();

  error INVALID_TOKEN();

  error INVALID_RATE();

  error MINTING_PAUSED();

  error CALLER_BLOCKED();

  /**
   * @notice Prevents minting outside of the mint period if set. Can be set only to have a start or only and end date.
   */
  modifier onlyDuringMintPeriod() {
    uint256 start = mintPeriod >> 128;
    if (start != 0) {
      if (start > block.timestamp) {
        revert MINT_NOT_STARTED();
      }
    }

    uint256 end = uint128(mintPeriod);
    if (end != 0) {
      if (end < block.timestamp) {
        revert MINT_CONCLUDED();
      }
    }

    _;
  }
  /**
   * @notice Prevents minting by blocked addresses and contracts hashes.
   */
  modifier callerNotBlocked(address account) {
    if (address(operatorFilter) != address(0)) {
      if (!operatorFilter.mayTransfer(account)) {
        revert CALLER_BLOCKED();
      }
    }

    _;
  }

  IQuoter public constant uniswapQuoter = IQuoter(0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6);

  uint256 public maxSupply;
  uint256 public unitPrice;
  uint256 public mintAllowance;
  uint256 public mintPeriod;
  uint256 public totalSupply;

  string public baseUri;
  string public contractUri;
  string public provenanceHash;

  /**
   * @notice Revealed flag.
   *
   * @dev changes the way tokenUri(uint256) works.
   */
  bool public isRevealed;

  /**
   * @notice Pause minting flag
   */
  bool public isPaused;

  /**
   * @notice If set, token ids will not be sequential, but instead based on minting account, current blockNumber, and optionally, price of eth.
   */
  bool public randomizedMint;

  /**
   * @notice Address that receives payments from mint operations.
   */
  address payable public payoutReceiver;

  /**
   * @notice Address that receives payments from secondary sales.
   */
  address payable public royaltyReceiver;

  /**
   * @notice Royalty rate expressed in bps.
   */
  uint256 public royaltyRate;

  INFTPriceResolver public priceResolver;
  IOperatorFilter public operatorFilter;

  //*********************************************************************//
  // ----------------------------- ERC721 ------------------------------ //
  //*********************************************************************//

  /**
   * @dev Override to apply callerNotBlocked modifier in case there is an OperatorFilter set
   */
  function transferFrom(
    address _from,
    address _to,
    uint256 _id
  ) public virtual override callerNotBlocked(msg.sender) {
    super.transferFrom(_from, _to, _id);
  }

  /**
   * @dev Override to apply callerNotBlocked modifier in case there is an OperatorFilter set
   */
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _id
  ) public virtual override callerNotBlocked(msg.sender) {
    super.safeTransferFrom(_from, _to, _id);
  }

  /**
   * @dev Override to apply callerNotBlocked modifier in case there is an OperatorFilter set
   */
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _id,
    bytes calldata _data
  ) public virtual override callerNotBlocked(msg.sender) {
    super.safeTransferFrom(_from, _to, _id, _data);
  }

  //*********************************************************************//
  // ------------------------- external views -------------------------- //
  //*********************************************************************//

  /**
   * @notice Get contract metadata to make OpenSea happy.
   */
  function contractURI() public view returns (string memory) {
    return contractUri;
  }

  /**
   * @dev If the token has been set as "revealed", returned uri will append the token id
   */
  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory uri) {
    if (_ownerOf[_tokenId] == address(0)) {
      uri = '';
    } else {
      uri = !isRevealed ? baseUri : string(abi.encodePacked(baseUri, _tokenId.toString()));
    }
  }

  /**
   * @notice EIP2981 implementation for royalty distribution.
   *
   * @param _tokenId Token id.
   * @param _salePrice NFT sale price to derive royalty amount from.
   */
  function royaltyInfo(
    uint256 _tokenId,
    uint256 _salePrice
  ) external view virtual returns (address receiver, uint256 royaltyAmount) {
    if (_salePrice == 0 || _ownerOf[_tokenId] != address(0)) {
      receiver = address(0);
      royaltyAmount = 0;
    } else {
      receiver = royaltyReceiver == address(0) ? address(this) : royaltyReceiver;
      royaltyAmount = (_salePrice * royaltyRate) / 10_000;
    }
  }

  /**
   * @dev rari-capital version of ERC721 reverts when owner is address(0), usually that means it's not minted, this is problematic for several workflows. This function simply returns an address.
   */
  function ownerOf(uint256 _tokenId) public view override returns (address owner) {
    owner = _ownerOf[_tokenId];
  }

  function mintPeriodStart() external view returns (uint256 start) {
    start = mintPeriod >> 128;
  }

  function mintPeriodEnd() external view returns (uint256 end) {
    end = uint256(uint128(mintPeriod));
  }

  function getMintPrice(address _minter) external view virtual returns (uint256 expectedPrice) {
    if (address(priceResolver) == address(0)) {
      return unitPrice + feeExtras(unitPrice);
    }

    expectedPrice = priceResolver.getPriceWithParams(address(this), _minter, totalSupply + 1, '');
    return expectedPrice + feeExtras(expectedPrice);
  }

  //*********************************************************************//
  // ---------------------- external transactions ---------------------- //
  //*********************************************************************//

  /**
   * @notice Mints a token to the calling account. Must be paid in Ether if price is non-zero.
   *
   * @dev Proceeds are forwarded to the default Juicebox terminal for the project id set in the constructor. Payment will fail if the terminal is not set in the jbx directory.
   */
  function mint()
    external
    payable
    virtual
    nonReentrant
    onlyDuringMintPeriod
    callerNotBlocked(msg.sender)
    returns (uint256 tokenId)
  {
    tokenId = mintActual(msg.sender);
  }

  /**
   * @notice Mints a token to the provided account rather than the caller. Must be paid in Ether if price is non-zero.
   *
   * @dev Proceeds are forwarded to the default Juicebox terminal for the project id set in the constructor. Payment will fail if the terminal is not set in the jbx directory.
   */
  function mint(
    address _account
  )
    external
    payable
    virtual
    nonReentrant
    onlyDuringMintPeriod
    callerNotBlocked(msg.sender)
    returns (uint256 tokenId)
  {
    tokenId = mintActual(_account);
  }

  /**
   * @notice Accepts Ether payment and forwards it to the appropriate jbx terminal during the mint phase.
   *
   * @dev This version of the NFT does not directly accept Ether and will fail to process mint payment if there is no payoutReceiver set.
   *
   * @dev In case of multi-mint where the amount passed to the transaction is greater than the cost of a single mint, it would be up to the caller of this function to refund the difference. Here we'll take only the required amount to mint the tokens we're allowed to.
   */
  function processPayment() internal virtual returns (uint256 balance, uint256 refund) {
    uint256 accountBalance = _balanceOf[msg.sender];
    if (accountBalance == mintAllowance) {
      revert ALLOWANCE_EXHAUSTED();
    }

    uint256 expectedPrice = unitPrice;
    if (address(priceResolver) != address(0)) {
      expectedPrice = priceResolver.getPrice(address(this), msg.sender, 0);
    }

    expectedPrice += feeExtras(expectedPrice);

    if (msg.value < expectedPrice) {
      revert INCORRECT_PAYMENT(expectedPrice);
    }

    if (msg.value == 0 || msg.value == expectedPrice) {
      balance = 1;
      refund = 0;
    } else if (msg.value > expectedPrice) {
      if (address(priceResolver) != address(0)) {
        // TODO: pending changes to INFTPriceResolver
        balance = 1;
        refund = msg.value - expectedPrice;
      } else {
        balance = msg.value / expectedPrice;

        if (totalSupply + balance > maxSupply) {
          // reduce to max supply
          balance -= totalSupply + balance - maxSupply;
        }

        if (accountBalance + balance > mintAllowance) {
          // reduce to mint allowance; since we're here, final balance shouuld be >= 1
          balance -= accountBalance + balance - mintAllowance;
        }

        refund = msg.value - (balance * expectedPrice);
      }
    }

    if (payoutReceiver != address(0)) {
      (bool success, ) = payoutReceiver.call{value: msg.value - refund}('');
      if (!success) {
        revert PAYMENT_FAILURE();
      }
    } else {
      revert PAYMENT_FAILURE();
    }
  }

  //*********************************************************************//
  // --------------------- privileged transactions --------------------- //
  //*********************************************************************//

  /**
   * @notice Privileged operation callable by accounts with MINTER_ROLE permission to mint the next NFT id to the provided address.
   */
  function mintFor(
    address _account
  ) external virtual onlyRole(MINTER_ROLE) returns (uint256 tokenId) {
    if (totalSupply == maxSupply) {
      revert SUPPLY_EXHAUSTED();
    }

    unchecked {
      ++totalSupply;
    }
    tokenId = generateTokenId(_account, 0);
    _mint(_account, tokenId);
  }

  function setPause(bool pause) external onlyRole(DEFAULT_ADMIN_ROLE) {
    isPaused = pause;
  }

  function addMinter(address _account) external onlyRole(DEFAULT_ADMIN_ROLE) {
    _grantRole(MINTER_ROLE, _account);
  }

  function removeMinter(address _account) external onlyRole(DEFAULT_ADMIN_ROLE) {
    _revokeRole(MINTER_ROLE, _account);
  }

  function addRevealer(address _account) external onlyRole(DEFAULT_ADMIN_ROLE) {
    _grantRole(REVEALER_ROLE, _account);
  }

  function removeRevealer(address _account) external onlyRole(DEFAULT_ADMIN_ROLE) {
    _revokeRole(REVEALER_ROLE, _account);
  }

  /**
   * @notice Set provenance hash.
   *
   * @dev This operation can only be executed once.
   */
  function setProvenanceHash(string memory _provenanceHash) external onlyRole(DEFAULT_ADMIN_ROLE) {
    if (bytes(provenanceHash).length != 0) {
      revert PROVENANCE_REASSIGNMENT();
    }
    provenanceHash = _provenanceHash;
  }

  /**
    @notice Metadata URI for token details in OpenSea format.
   */
  function setContractURI(string memory _contractUri) external onlyRole(DEFAULT_ADMIN_ROLE) {
    contractUri = _contractUri;
  }

  /**
   * @notice Allows adjustment of minting period.
   *
   * @param _mintPeriodStart New minting period start.
   * @param _mintPeriodEnd New minting period end.
   */
  function updateMintPeriod(
    uint256 _mintPeriodStart,
    uint256 _mintPeriodEnd
  ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    mintPeriod = (_mintPeriodStart << 128) | _mintPeriodEnd;
  }

  function updateUnitPrice(uint256 _unitPrice) external onlyRole(DEFAULT_ADMIN_ROLE) {
    unitPrice = _unitPrice;
  }

  function updatePriceResolver(
    INFTPriceResolver _priceResolver
  ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    priceResolver = _priceResolver;
  }

  function updateOperatorFilter(
    IOperatorFilter _operatorFilter
  ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    operatorFilter = _operatorFilter;
  }

  function setRandomizedMint(bool _randomizedMint) external onlyRole(DEFAULT_ADMIN_ROLE) {
    randomizedMint = _randomizedMint;
  }

  /**
   * @notice Set NFT metadata base URI.
   *
   * @dev URI must include the trailing slash.
   */
  function setBaseURI(string memory _baseUri, bool _reveal) external onlyRole(REVEALER_ROLE) {
    if (isRevealed && !_reveal) {
      revert ALREADY_REVEALED();
    }

    baseUri = _baseUri;
    isRevealed = _reveal;
  }

  /**
   * @notice Allows owner to transfer ERC20 balances.
   */
  function transferTokenBalance(
    IERC20 token,
    address to,
    uint256 amount
  ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    token.transfer(to, amount);
  }

  function setPayoutReceiver(
    address payable _payoutReceiver
  ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    payoutReceiver = _payoutReceiver;
  }

  /**
   * @notice Sets royalty info
   *
   * @param _royaltyReceiver Payable royalties receiver.
   * @param _royaltyRate Rate expressed in bps, can only be set once.
   */
  function setRoyalties(
    address _royaltyReceiver,
    uint16 _royaltyRate
  ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    royaltyReceiver = payable(_royaltyReceiver);

    if (_royaltyRate > 10_000) {
      revert INVALID_RATE();
    }

    if (royaltyRate == 0) {
      royaltyRate = _royaltyRate;
    }
  }

  /**
   * @notice Function to consolidate functionality for external mint calls.
   *
   * @dev External calls should be validated by modifiers like `onlyDuringMintPeriod` and `callerNotBlocked`.
   *
   * @param _account Address to assign the new token to.
   */
  function mintActual(address _account) internal virtual returns (uint256 tokenId) {
    if (totalSupply == maxSupply) {
      revert SUPPLY_EXHAUSTED();
    }

    if (isPaused) {
      revert MINTING_PAUSED();
    }

    (uint256 balance, uint256 refund) = processPayment();

    for (; balance != 0; ) {
      unchecked {
        ++totalSupply;
      }
      tokenId = generateTokenId(_account, msg.value); // NOTE: this call requires totalSupply to be incremented by 1
      _mint(_account, tokenId);
      unchecked {
        --balance;
      }
    }

    if (refund != 0) {
      _account.call{value: refund}('');
    }
  }

  function feeExtras(uint256) internal view virtual returns (uint256 fee) {
    fee = 0;
  }

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(
    bytes4 interfaceId
  ) public view virtual override(AccessControlEnumerable, ERC721FU) returns (bool) {
    return
      interfaceId == type(IERC2981).interfaceId || // 0x2a55205a
      AccessControlEnumerable.supportsInterface(interfaceId) ||
      ERC721FU.supportsInterface(interfaceId);
  }

  /**
   * @notice Generates a token id based on provided parameters. Id range is 1...(maxSupply + 1), 0 is considered invalid and never returned.
   *
   * @dev If randomizedMint is set token id will be based on account value, current price of eth for the amount provided (via Uniswap), current block number. Collisions are resolved via increment.
   */
  function generateTokenId(
    address _account,
    uint256 _amount
  ) internal virtual returns (uint256 tokenId) {
    if (!randomizedMint) {
      tokenId = totalSupply;
    } else {
      uint256 ethPrice;
      if (_amount != 0) {
        ethPrice = uniswapQuoter.quoteExactInputSingle(
          WETH9,
          DAI,
          3000, // fee
          _amount,
          0 // sqrtPriceLimitX96
        );
      }

      tokenId =
        uint256(keccak256(abi.encodePacked(_account, block.number, ethPrice))) %
        (maxSupply + 1);

      // resolve token id collisions
      while (tokenId == 0 || _ownerOf[tokenId] != address(0)) {
        tokenId = ++tokenId % (maxSupply + 1);
      }
    }
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC721TokenReceiver} from '@rari-capital/solmate/src/tokens/ERC721.sol';

/**
 * @notice This contract is based on the rari-capital Solmate ERC721 implementation, but removes the constructor the make it upgradeable, the U in ERC721FU.
 * @notice Modern, minimalist, and gas efficient ERC-721 implementation.
 * @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
 */
abstract contract ERC721FU {
  /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

  event Transfer(address indexed from, address indexed to, uint256 indexed id);

  event Approval(address indexed owner, address indexed spender, uint256 indexed id);

  event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

  /*//////////////////////////////////////////////////////////////
                         METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

  string public name;

  string public symbol;

  function tokenURI(uint256 id) public view virtual returns (string memory);

  /*//////////////////////////////////////////////////////////////
                      ERC721 BALANCE/OWNER STORAGE
    //////////////////////////////////////////////////////////////*/

  mapping(uint256 => address) internal _ownerOf;

  mapping(address => uint256) internal _balanceOf;

  function ownerOf(uint256 id) public view virtual returns (address owner) {
    require((owner = _ownerOf[id]) != address(0), 'NOT_MINTED');
  }

  function balanceOf(address owner) public view virtual returns (uint256) {
    require(owner != address(0), 'ZERO_ADDRESS');

    return _balanceOf[owner];
  }

  /*//////////////////////////////////////////////////////////////
                         ERC721 APPROVAL STORAGE
    //////////////////////////////////////////////////////////////*/

  mapping(uint256 => address) public getApproved;

  mapping(address => mapping(address => bool)) public isApprovedForAll;

  /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

  function approve(address spender, uint256 id) public virtual {
    address owner = _ownerOf[id];

    require(msg.sender == owner || isApprovedForAll[owner][msg.sender], 'NOT_AUTHORIZED');

    getApproved[id] = spender;

    emit Approval(owner, spender, id);
  }

  function setApprovalForAll(address operator, bool approved) public virtual {
    isApprovedForAll[msg.sender][operator] = approved;

    emit ApprovalForAll(msg.sender, operator, approved);
  }

  function transferFrom(
    address from,
    address to,
    uint256 id
  ) public virtual {
    require(from == _ownerOf[id], 'WRONG_FROM');

    require(to != address(0), 'INVALID_RECIPIENT');

    require(
      msg.sender == from || isApprovedForAll[from][msg.sender] || msg.sender == getApproved[id],
      'NOT_AUTHORIZED'
    );

    // Underflow of the sender's balance is impossible because we check for
    // ownership above and the recipient's balance can't realistically overflow.
    unchecked {
      _balanceOf[from]--;

      _balanceOf[to]++;
    }

    _ownerOf[id] = to;

    delete getApproved[id];

    emit Transfer(from, to, id);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 id
  ) public virtual {
    transferFrom(from, to, id);

    require(
      to.code.length == 0 ||
        ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, '') ==
        ERC721TokenReceiver.onERC721Received.selector,
      'UNSAFE_RECIPIENT'
    );
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 id,
    bytes calldata data
  ) public virtual {
    transferFrom(from, to, id);

    require(
      to.code.length == 0 ||
        ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
        ERC721TokenReceiver.onERC721Received.selector,
      'UNSAFE_RECIPIENT'
    );
  }

  /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

  function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
    return
      interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
      interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
      interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
  }

  /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

  function _mint(address to, uint256 id) internal virtual {
    require(to != address(0), 'INVALID_RECIPIENT');

    require(_ownerOf[id] == address(0), 'ALREADY_MINTED');

    // Counter overflow is incredibly unrealistic.
    unchecked {
      _balanceOf[to]++;
    }

    _ownerOf[id] = to;

    emit Transfer(address(0), to, id);
  }

  function _burn(uint256 id) internal virtual {
    address owner = _ownerOf[id];

    require(owner != address(0), 'NOT_MINTED');

    // Ownership check above ensures no underflow.
    unchecked {
      _balanceOf[owner]--;
    }

    delete _ownerOf[id];

    delete getApproved[id];

    emit Transfer(owner, address(0), id);
  }

  /*//////////////////////////////////////////////////////////////
                        INTERNAL SAFE MINT LOGIC
    //////////////////////////////////////////////////////////////*/

  function _safeMint(address to, uint256 id) internal virtual {
    _mint(to, id);

    require(
      to.code.length == 0 ||
        ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, '') ==
        ERC721TokenReceiver.onERC721Received.selector,
      'UNSAFE_RECIPIENT'
    );
  }

  function _safeMint(
    address to,
    uint256 id,
    bytes memory data
  ) internal virtual {
    _mint(to, id);

    require(
      to.code.length == 0 ||
        ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, data) ==
        ERC721TokenReceiver.onERC721Received.selector,
      'UNSAFE_RECIPIENT'
    );
  }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

interface IMintFeeOracle {
  function fee(uint256 _projectId, uint256 _price) external view returns (uint256);

  function setFeeRate(uint256 _feeRate, uint256 _projectId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

enum PriceFunction {
  LINEAR,
  EXP,
  CONSTANT
}

interface INFTPriceResolver {
  error UNSUPPORTED_OPERATION();

  function getPrice(
    address _token,
    address _minter,
    uint256 _tokenid
  ) external view returns (uint256);

  function getPriceWithParams(
    address _token,
    address _minter,
    uint256 _tokenid,
    bytes calldata _params
  ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './IOperatorFilter.sol';

interface IOperatorFilter {
  function mayTransfer(address operator) external view returns (bool);

  function registerAddress(address _account, bool _blocked) external;

  function registerCodeHash(bytes32 _codeHash, bool _locked) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';

import '../../abstract/JBOperatable.sol';
import '../../interfaces/IJBDirectory.sol';
import '../../libraries/JBOperations.sol';

import '../structs.sol';
import './components/BaseNFT.sol';
import './interfaces/IMintFeeOracle.sol';

/**
 * @notice ERC721
 */
contract NFToken is BaseNFT, JBOperatable {
  IJBDirectory public immutable jbxDirectory;
  IERC721 public immutable jbxProjects;

  IMintFeeOracle public immutable feeOracle;

  uint256 public projectId;

  //*********************************************************************//
  // -------------------------- constructor ---------------------------- //
  //*********************************************************************//

  /**
   * @notice Creates the NFT contract.
   *
   */
  constructor(
    CommonNFTAttributes memory _commonNFTAttributes,
    PermissionValidationComponents memory _permissionValidationComponents,
    IMintFeeOracle _feeOracle
  ) {
    name = _commonNFTAttributes.name;
    symbol = _commonNFTAttributes.symbol;

    baseUri = _commonNFTAttributes.baseUri;
    isRevealed = _commonNFTAttributes.revealed;
    contractUri = _commonNFTAttributes.contractUri;
    maxSupply = _commonNFTAttributes.maxSupply;
    unitPrice = _commonNFTAttributes.unitPrice;
    mintAllowance = _commonNFTAttributes.mintAllowance;

    payoutReceiver = payable(msg.sender);
    royaltyReceiver = payable(msg.sender);

    operatorStore = _permissionValidationComponents.jbxOperatorStore; // JBOperatable

    jbxDirectory = _permissionValidationComponents.jbxDirectory;
    jbxProjects = _permissionValidationComponents.jbxProjects;

    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _grantRole(MINTER_ROLE, msg.sender);
    _grantRole(REVEALER_ROLE, msg.sender);

    feeOracle = _feeOracle;
  }

  function setProjectId(
    uint256 _projectId
  )
    external
    requirePermissionAllowingOverride(
      jbxProjects.ownerOf(_projectId),
      _projectId,
      JBOperations.MANAGE_PAYMENTS,
      (msg.sender == address(jbxDirectory.controllerOf(_projectId)))
    )
  {
    projectId = _projectId;
  }

  function feeExtras(uint256 expectedPrice) internal view override returns (uint256 fee) {
    if (address(0) == address(feeOracle)) {
      fee = 0;
    } else {
      fee = feeOracle.fee(projectId, expectedPrice);
    }
  }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import './components/BaseMembership.sol';

contract NFUMembership is BaseMembership {
  error INVALID_OPERATION();

  //*********************************************************************//
  // -------------------------- initializer ---------------------------- //
  //*********************************************************************//

  /**
   * @dev This contract is meant to be deployed via the `Deployer` which makes `Clone`s. The `Deployer` itself has a reference to a known-good copy. When the platform admin is deploying the `Deployer` and the source `NFUToken` the constructor will lock that contract to the platform admin. When the deployer is making copies of it the source storage isn't taken so the Deployer will call `initialize` to set the admin to the correct account.
   */
  constructor() {
    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _grantRole(MINTER_ROLE, msg.sender);
    _grantRole(REVEALER_ROLE, msg.sender);
  }

  /**
   * @notice Initializes token state. Used by the Deployer contract to set NFT parameters and contract ownership.
   *
   * @param _owner Token admin.
   * @param _name Token name. Name must not be blank.
   * @param _symbol Token symbol.
   * @param _baseUri Base URI, initially expected to point at generic, "unrevealed" metadata json.
   * @param _contractUri OpenSea-style contract metadata URI.
   * @param _maxSupply Max NFT supply.
   * @param _unitPrice Price per token expressed in Ether.
   * @param _mintAllowance Per-user mint cap.
   * @param _mintPeriodStart Start of the minting period in seconds.
   * @param _mintPeriodEnd End of the minting period in seconds.
   */
  function initialize(
    address _owner,
    string memory _name,
    string memory _symbol,
    string memory _baseUri,
    string memory _contractUri,
    uint256 _maxSupply,
    uint256 _unitPrice,
    uint256 _mintAllowance,
    uint256 _mintPeriodStart,
    uint256 _mintPeriodEnd,
    TransferType _transferType
  ) public {
    if (bytes(name).length != 0) {
      // NOTE: prevent re-init
      revert INVALID_OPERATION();
    }

    if (getRoleMemberCount(DEFAULT_ADMIN_ROLE) != 0) {
      if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) {
        revert INVALID_OPERATION();
      }
    } else {
      _grantRole(DEFAULT_ADMIN_ROLE, _owner);
      _grantRole(MINTER_ROLE, _owner);
      _grantRole(REVEALER_ROLE, _owner);
    }

    name = _name;
    symbol = _symbol;

    baseUri = _baseUri;
    contractUri = _contractUri;
    maxSupply = _maxSupply;
    unitPrice = _unitPrice;
    mintAllowance = _mintAllowance;
    mintPeriod = (_mintPeriodStart << 128) | _mintPeriodEnd;

    transferType = _transferType;

    payoutReceiver = payable(_owner);
    royaltyReceiver = payable(_owner);
  }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';

import '../../abstract/JBOperatable.sol';
import '../../interfaces/IJBDirectory.sol';
import '../../libraries/JBOperations.sol';

import '../structs.sol';
import './components/BaseNFT.sol';
import './interfaces/IMintFeeOracle.sol';

contract NFUToken is BaseNFT, JBOperatable {
  error INVALID_OPERATION();

  IJBDirectory public jbxDirectory;
  IERC721 public jbxProjects;

  IMintFeeOracle public feeOracle;

  uint256 public projectId;

  //*********************************************************************//
  // -------------------------- initializer ---------------------------- //
  //*********************************************************************//

  /**
   * @dev This contract is meant to be deployed via the `Deployer` which makes `Clone`s. The `Deployer` itself has a reference to a known-good copy. When the platform admin is deploying the `Deployer` and the source `NFUToken` the constructor will lock that contract to the platform admin. When the deployer is making copies of it the source storage isn't taken so the Deployer will call `initialize` to set the admin to the correct account.
   */
  constructor() {
    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _grantRole(MINTER_ROLE, msg.sender);
    _grantRole(REVEALER_ROLE, msg.sender);
  }

  /**
   * @notice Initializes token state. Used by the Deployer contract to set NFT parameters and contract ownership.
   *
   * @param _owner Token admin.
   */
  function initialize(
    address payable _owner,
    CommonNFTAttributes memory _commonNFTAttributes,
    PermissionValidationComponents memory _permissionValidationComponents,
    IMintFeeOracle _feeOracle
  ) public {
    if (bytes(name).length != 0) {
      // NOTE: prevent re-init
      revert INVALID_OPERATION();
    }

    if (getRoleMemberCount(DEFAULT_ADMIN_ROLE) != 0) {
      if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) {
        revert INVALID_OPERATION();
      }
    } else {
      _grantRole(DEFAULT_ADMIN_ROLE, _owner);
      _grantRole(MINTER_ROLE, _owner);
      _grantRole(REVEALER_ROLE, _owner);
    }

    name = _commonNFTAttributes.name;
    symbol = _commonNFTAttributes.symbol;

    baseUri = _commonNFTAttributes.baseUri;
    isRevealed = _commonNFTAttributes.revealed;
    contractUri = _commonNFTAttributes.contractUri;
    maxSupply = _commonNFTAttributes.maxSupply;
    unitPrice = _commonNFTAttributes.unitPrice;
    mintAllowance = _commonNFTAttributes.mintAllowance;

    payoutReceiver = _owner;
    royaltyReceiver = _owner;

    operatorStore = _permissionValidationComponents.jbxOperatorStore; // JBOperatable

    jbxDirectory = _permissionValidationComponents.jbxDirectory;
    jbxProjects = _permissionValidationComponents.jbxProjects;

    feeOracle = _feeOracle;
  }

  function setProjectId(
    uint256 _projectId
  )
    external
    requirePermissionAllowingOverride(
      jbxProjects.ownerOf(_projectId),
      _projectId,
      JBOperations.MANAGE_PAYMENTS,
      (msg.sender == address(jbxDirectory.controllerOf(_projectId)))
    )
  {
    projectId = _projectId;
  }

  function feeExtras(uint256 expectedPrice) internal view override returns (uint256 fee) {
    if (address(0) == address(feeOracle)) {
      fee = 0;
    } else {
      fee = feeOracle.fee(projectId, expectedPrice);
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import {ERC721 as ERC721Rari} from '@rari-capital/solmate/src/tokens/ERC721.sol';

import '../../interfaces/IJBDirectory.sol';
import '../../interfaces/IJBFundingCycleDataSource.sol';
import '../../interfaces/IJBPayDelegate.sol';
import '../../interfaces/IJBRedemptionDelegate.sol';
import '../interfaces/INFTRewardDataSourceDelegate.sol';
import '../interfaces/IPriceResolver.sol';
import '../interfaces/IToken721UriResolver.sol';
import '../interfaces/ITokenSupplyDetails.sol';

import '../../structs/JBDidPayData.sol';
import '../../structs/JBDidRedeemData.sol';
import '../../structs/JBRedeemParamsData.sol';
import '../../structs/JBTokenAmount.sol';

/**
 * @title Juicebox data source delegate that offers project contributors NFTs.
 *
 * @notice This contract allows project creators to reward contributors with NFTs. Intended use is to incentivize initial project support by minting a limited number of NFTs to the first N contributors.
 *
 * @notice One use case is enabling the project to mint an NFT for anyone contributing any amount without a mint limit. Set minContribution.value to 0 and maxSupply to uint256.max to do this. To mint NFTs to the first 100 participants contributing 1000 DAI or more, set minContribution.value to 1000000000000000000000 (3 + 18 zeros), minContribution.token to 0x6B175474E89094C44Da98b954EedeAC495271d0F and maxSupply to 100.
 *
 * @dev Keep in mind that this PayDelegate and RedeemDelegate implementation will simply pass through the weight and reclaimAmount it is called with.
 */
contract NFTRewardDataSourceDelegate is
  ERC721Rari,
  Ownable,
  INFTRewardDataSourceDelegate,
  IJBFundingCycleDataSource,
  IJBPayDelegate,
  IJBRedemptionDelegate
{
  using Strings for uint256;

  //*********************************************************************//
  // --------------------------- custom errors ------------------------- //
  //*********************************************************************//
  error INVALID_PAYMENT_EVENT();
  error INCORRECT_OWNER();
  error INVALID_ADDRESS();
  error INVALID_TOKEN();
  error SUPPLY_EXHAUSTED();
  error NON_TRANSFERRABLE();
  error INVALID_REQUEST(string);

  //*********************************************************************//
  // -------------------------- constructor ---------------------------- //
  //*********************************************************************//

  /**
   * @notice Project id of the project this configuration is associated with.
   */
  uint256 private _projectId;

  /**
   * @notice Platform directory.
   */
  IJBDirectory private _directory;

  /**
   * @notice Minimum contribution amount to trigger NFT distribution, denominated in some currency defined as part of this object.
   *
   * @dev Only one NFT will be minted for any amount at or above this value.
   */
  JBTokenAmount private _minContribution;

  /**
   * @notice NFT mint cap as part of this configuration.
   */
  uint256 private _maxSupply;

  /**
   * @notice Current supply.
   *
   * @dev Also used to check if rewards supply was exhausted and as nextTokenId
   */
  uint256 private _supply;

  /**
   * @notice Token base uri.
   */
  string private _baseUri;

  /**
   * @notice Custom token uri resolver, superceeds base uri.
   */
  IToken721UriResolver private _tokenUriResolver;

  /**
   * @notice Contract opensea-style metadata uri.
   */
  string private _contractUri;

  IPriceResolver private priceResolver;

  bool private transferrable;

  /**
   * @param projectId JBX project id this reward is associated with.
   * @param directory JBX directory.
   * @param maxSupply Total number of reward tokens to distribute.
   * @param minContribution Minimum contribution amount to be eligible for this reward.
   * @param _name The name of the token.
   * @param _symbol The symbol that the token should be represented by.
   * @param _uri Token base URI.
   * @param _tokenUriResolverAddress Custom uri resolver.
   * @param _contractMetadataUri Contract metadata uri.
   * @param _admin Set an alternate owner.
   * @param _priceResolver Custom uri resolver.
   */
  constructor(
    uint256 projectId,
    IJBDirectory directory,
    uint256 maxSupply,
    JBTokenAmount memory minContribution,
    string memory _name,
    string memory _symbol,
    string memory _uri,
    IToken721UriResolver _tokenUriResolverAddress,
    string memory _contractMetadataUri,
    address _admin,
    IPriceResolver _priceResolver
  ) ERC721Rari(_name, _symbol) {
    // JBX
    _projectId = projectId;
    _directory = directory;
    _maxSupply = maxSupply;
    _minContribution = minContribution;

    // ERC721
    _baseUri = _uri;
    _tokenUriResolver = _tokenUriResolverAddress;
    _contractUri = _contractMetadataUri;

    if (_admin != address(0)) {
      _transferOwnership(_admin);
    }

    priceResolver = _priceResolver;

    transferrable = true;
  }

  //*********************************************************************//
  // ------------------- IJBFundingCycleDataSource --------------------- //
  //*********************************************************************//

  function payParams(JBPayParamsData calldata _data)
    external
    view
    override
    returns (
      uint256 weight,
      string memory memo,
      JBPayDelegateAllocation[] memory delegateAllocations
    )
  {
    weight = _data.weight;
    memo = _data.memo;
    delegateAllocations = new JBPayDelegateAllocation[](1);
    delegateAllocations[0] = JBPayDelegateAllocation({
      delegate: IJBPayDelegate(address(this)),
      amount: _data.amount.value
    });
  }

  function redeemParams(JBRedeemParamsData calldata _data)
    external
    view
    override
    returns (
      uint256 reclaimAmount,
      string memory memo,
      JBRedemptionDelegateAllocation[] memory delegateAllocations
    )
  {
    reclaimAmount = _data.reclaimAmount.value;
    memo = _data.memo;
    // delegateAllocations = new JBRedemptionDelegateAllocation[](0);
  }

  //*********************************************************************//
  // ------------------------ IJBPayDelegate --------------------------- //
  //*********************************************************************//

  /**
   * @notice Part of IJBPayDelegate, this function will mint an NFT to the contributor (_data.beneficiary) if conditions are met.
   *
   * @dev This function will revert if the terminal calling it does not belong to the registered project id.
   *
   * @dev This function will also revert due to ERC721 mint issue, which may interfere with contribution processing. These are unlikely and include beneficiary being the 0 address or the beneficiary already holding the token id being minted. The latter should not happen given that mint is only controlled by this function.
   *
   * @param _data Juicebox project contribution data.
   */
  function didPay(JBDidPayData calldata _data) external payable override {
    if (
      !_directory.isTerminalOf(_projectId, IJBPaymentTerminal(msg.sender)) ||
      _data.projectId != _projectId
    ) {
      revert INVALID_PAYMENT_EVENT();
    }

    if (_supply == _maxSupply) {
      return;
    }

    if (address(priceResolver) != address(0)) {
      uint256 tokenId = priceResolver.validateContribution(_data.beneficiary, _data.amount, this);

      if (tokenId == 0) {
        return;
      }

      _mint(_data.beneficiary, tokenId);

      _supply += 1;
    } else if (
      (_data.amount.value >= _minContribution.value &&
        _data.amount.token == _minContribution.token) || _minContribution.value == 0
    ) {
      uint256 tokenId = _supply;
      _mint(_data.beneficiary, tokenId);

      _supply += 1;
    }
  }

  //*********************************************************************//
  // -------------------- IJBRedemptionDelegate ------------------------ //
  //*********************************************************************//

  /**
   * @notice NFT redemption is not supported.
   */
  // solhint-disable-next-line
  function didRedeem(JBDidRedeemData calldata _data) external payable override {
    // not a supported workflow for NFTs
  }

  //*********************************************************************//
  // ---------------------------- IERC165 ------------------------------ //
  //*********************************************************************//

  function supportsInterface(bytes4 _interfaceId)
    public
    view
    override(ERC721Rari, IERC165)
    returns (bool)
  {
    return
      _interfaceId == type(IJBFundingCycleDataSource).interfaceId ||
      _interfaceId == type(IJBPayDelegate).interfaceId ||
      _interfaceId == type(IJBRedemptionDelegate).interfaceId ||
      super.supportsInterface(_interfaceId); // check with rari-ERC721
  }

  //*********************************************************************//
  // ---------------------- ITokenSupplyDetails ------------------------ //
  //*********************************************************************//

  function totalSupply() public view override returns (uint256) {
    return _supply;
  }

  function tokenSupply(uint256 _tokenId) public view override returns (uint256) {
    return _ownerOf[_tokenId] != address(0) ? 1 : 0;
  }

  function totalOwnerBalance(address _account) public view override returns (uint256) {
    if (_account == address(0)) {
      revert INVALID_ADDRESS();
    }

    return _balanceOf[_account];
  }

  function ownerTokenBalance(address _account, uint256 _tokenId)
    public
    view
    override
    returns (uint256)
  {
    return _ownerOf[_tokenId] == _account ? 1 : 0;
  }

  //*********************************************************************//
  // ----------------------------- ERC721 ------------------------------ //
  //*********************************************************************//

  /**
   * @notice Returns the full URI for the asset.
   */
  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    if (_ownerOf[tokenId] == address(0)) {
      revert INVALID_TOKEN();
    }

    if (address(_tokenUriResolver) != address(0)) {
      return _tokenUriResolver.tokenURI(tokenId);
    }

    return bytes(_baseUri).length > 0 ? string(abi.encodePacked(_baseUri, tokenId.toString())) : '';
  }

  /**
   * @notice Returns the contract metadata uri.
   */
  function contractURI() public view override returns (string memory contractUri) {
    contractUri = _contractUri;
  }

  /**
   * @notice Transfer tokens to an account.
   *
   * @param _to The destination address.
   * @param _id NFT id to transfer.
   */
  function transfer(address _to, uint256 _id) public override {
    if (!transferrable) {
      revert NON_TRANSFERRABLE();
    }
    transferFrom(msg.sender, _to, _id);
  }

  /**
   * @notice Transfer tokens between accounts.
   *
   * @param _from The originating address.
   * @param _to The destination address.
   * @param _id The amount of the transfer, as a fixed point number with 18 decimals.
   */
  function transferFrom(
    address _from,
    address _to,
    uint256 _id
  ) public override {
    if (!transferrable) {
      revert NON_TRANSFERRABLE();
    }
    super.transferFrom(_from, _to, _id);
  }

  /**
   * @notice Confirms that the given address owns the provided token.
   */
  function isOwner(address _account, uint256 _id) public view override returns (bool) {
    return _ownerOf[_id] == _account;
  }

  // TODO: this will cause issues for some price resolvers
  function mint(address _account) external override onlyOwner returns (uint256 tokenId) {
    if (_supply == _maxSupply) {
      revert SUPPLY_EXHAUSTED();
    }

    tokenId = _supply;
    _mint(_account, tokenId);

    _supply += 1;
  }

  /**
   * @notice This function is intended to allow NFT management for non-transferrable NFTs where the holder is unable to perform any action on the token, so we let the admin of the contract burn them.
   */
  function burn(address _account, uint256 _tokenId) external override onlyOwner {
    if (transferrable) {
      revert INVALID_REQUEST('Token is tranferrable');
    }

    if (!isOwner(_account, _tokenId)) {
      revert INCORRECT_OWNER();
    }

    _burn(_tokenId);
  }

  /**
   * @notice Owner-only function to set a contract metadata uri to contain opensea-style metadata.
   *
   * @param _contractMetadataUri New metadata uri.
   */
  function setContractUri(string calldata _contractMetadataUri) external override onlyOwner {
    _contractUri = _contractMetadataUri;
  }

  /**
   * @notice Owner-only function to set a new token base uri.
   *
   * @param _uri New base uri.
   */
  function setTokenUri(string calldata _uri) external override onlyOwner {
    _baseUri = _uri;
  }

  /**
   * @notice Owner-only function to set a token uri resolver. If set to address(0), value of baseUri will be used instead.
   *
   * @param _tokenUriResolverAddress New uri resolver contract.
   */
  function setTokenUriResolver(IToken721UriResolver _tokenUriResolverAddress)
    external
    override
    onlyOwner
  {
    _tokenUriResolver = _tokenUriResolverAddress;
  }

  function setTransferrable(bool _transferrable) external override onlyOwner {
    transferrable = _transferrable;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../../structs/JBTokenAmount.sol';
import '../interfaces/IPriceResolver.sol';
import '../interfaces/ITokenSupplyDetails.sol';

/**
  @dev Token id 0 has special meaning in NFTRewardDataSourceDelegate where minting will be skipped.
  @dev An example tier collecting might look like this:
  [ { contributionFloor: 1 ether }, { contributionFloor: 5 ether }, { contributionFloor: 10 ether } ]
 */
struct OpenRewardTier {
  /** @notice Minimum contribution to qualify for this tier. */
  uint256 contributionFloor;
}

contract OpenTieredPriceResolver is IPriceResolver {
  address public contributionToken;
  OpenRewardTier[] public tiers;

  //*********************************************************************//
  // --------------------------- custom errors ------------------------- //
  //*********************************************************************//
  error INVALID_PRICE_SORT_ORDER(uint256);
  error INVALID_ID_SORT_ORDER(uint256);

  /**
    @notice This price resolver allows project admins to define multiple reward tiers for contributions and issue NFTs to people who contribute at those levels. 

    @dev This pride resolver requires a custom token uri resolver which is defined in OpenTieredTokenUriResolver.

    @dev Tiers list must be sorted by floor otherwise contributors won't be rewarded properly.

    @dev There is a limit of 255 tiers.

    @param _contributionToken Token used for contributions, use JBTokens.ETH to specify ether.
    @param _tiers Sorted tier collection.
   */
  constructor(address _contributionToken, OpenRewardTier[] memory _tiers) {
    contributionToken = _contributionToken;

    if (_tiers.length > type(uint8).max) {
      revert();
    }

    if (_tiers.length > 0) {
      tiers.push(_tiers[0]);
      for (uint256 i = 1; i < _tiers.length; i++) {
        if (_tiers[i].contributionFloor < _tiers[i - 1].contributionFloor) {
          revert INVALID_PRICE_SORT_ORDER(i);
        }

        tiers.push(_tiers[i]);
      }
    }
  }

  /**
    @notice Returns the token id that should be minted for a given contribution for the contributor account.

    @dev If token id 0 is returned, the mint should be skipped. This function specifically does not revert so that it doesn't interrupt the contribution flow since NFT rewards are optional.

    @dev Since this contract is agnostic of the token type it operates on, ERC721 or ERC1155, the token id being returned is not checked for collisions.

    @param account Address sending the contribution.
    @param contribution Contribution amount.
    ignored ITokenSupplyDetails
   */
  function validateContribution(
    address account,
    JBTokenAmount calldata contribution,
    ITokenSupplyDetails
  ) public view override returns (uint256 tokenId) {
    if (contribution.token != contributionToken) {
      return 0;
    }

    tokenId = 0;
    uint256 tiersLength = tiers.length;
    for (uint256 i; i < tiersLength; ) {
      if (
        (tiers[i].contributionFloor <= contribution.value && i == tiers.length - 1) ||
        (tiers[i].contributionFloor <= contribution.value &&
          tiers[i + 1].contributionFloor > contribution.value)
      ) {
        tokenId = i | (uint248(uint256(keccak256(abi.encodePacked(account, block.number)))) << 8);
        break;
      }
      unchecked {
        ++i;
      }
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/Strings.sol';

import '../interfaces/IToken721UriResolver.sol';

contract OpenTieredTokenUriResolver is IToken721UriResolver {
  using Strings for uint256;

  string public baseUri;

  /**
    @notice An ERC721-style token URI resolver that appends token id to the end of a base uri.

    @dev This contract is meant to go with NFTs minted using OpenTieredPriceResolver. The URI returned from tokenURI is based on the low 8 bits of the token id provided.

    @param _baseUri Root URI
    */
  constructor(string memory _baseUri) {
    baseUri = _baseUri;
  }

  function tokenURI(uint256 _tokenId) external view override returns (string memory uri) {
    uri = string(abi.encodePacked(baseUri, uint256(uint8(_tokenId)).toString()));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../../structs/JBTokenAmount.sol';
import '../interfaces/IPriceResolver.sol';
import '../interfaces/ITokenSupplyDetails.sol';

/**
  @dev Token id 0 has special meaning in NFTRewardDataSourceDelegate where minting will be skipped.
  @dev An example tier collecting might look like this:
  [ { contributionFloor: 1 ether, idCeiling: 1001, remainingAllowance: 1000 }, { contributionFloor: 5 ether, idCeiling: 1501, remainingAllowance: 500 }, { contributionFloor: 10 ether, idCeiling: 1511, remainingAllowance: 10 }]
 */
struct RewardTier {
  /** @notice Minimum contribution to qualify for this tier. */
  uint256 contributionFloor;
  /** @notice Highest token id in this tier. */
  uint256 idCeiling;
  /**
    @notice Remaining number of tokens in this tier.
    @dev Together with idCeiling this enables for consecutive, increasing token ids to be issued to contributors.
  */
  uint256 remainingAllowance;
}

contract TieredPriceResolver is IPriceResolver {
  address public contributionToken;
  uint256 public globalMintAllowance;
  uint256 public userMintCap;
  RewardTier[] public tiers;

  //*********************************************************************//
  // --------------------------- custom errors ------------------------- //
  //*********************************************************************//
  error INVALID_PRICE_SORT_ORDER(uint256);
  error INVALID_ID_SORT_ORDER(uint256);

  /**
    @notice This price resolver allows project admins to define multiple reward tiers for contributions and issue NFTs to people who contribute at those levels. It is also possible to limit total number of NFTs issues and total number of NFTs issued per account regardless of the contribution amount. Let's say the total number of NFTs defined in the tiers is 10k, the global mint cap can limit that number to 5000 across all tiers.

    @dev Tiers list must be sorted by floor otherwise contributors won't be rewarded properly.

    @param _contributionToken Token used for contributions, use JBTokens.ETH to specify ether.
    @param _mintCap Global mint cap, this allows limiting total NFT supply in addition to the limits already defined in the tiers.
    @param _userMintCap Per-account mint cap.
    @param _tiers Sorted tier collection.
   */
  constructor(
    address _contributionToken,
    uint256 _mintCap, // TODO: reconsider this and use token.MaxSupply instead
    uint256 _userMintCap,
    RewardTier[] memory _tiers
  ) {
    contributionToken = _contributionToken;
    globalMintAllowance = _mintCap;
    userMintCap = _userMintCap;

    if (_tiers.length > 0) {
      tiers.push(_tiers[0]);
      for (uint256 i = 1; i < _tiers.length; i++) {
        if (_tiers[i].contributionFloor < _tiers[i - 1].contributionFloor) {
          revert INVALID_PRICE_SORT_ORDER(i);
        }

        if (_tiers[i].idCeiling - _tiers[i].remainingAllowance < _tiers[i - 1].idCeiling) {
          revert INVALID_ID_SORT_ORDER(i);
        }

        tiers.push(_tiers[i]);
      }
    }
  }

  /**
    @notice Returns the token id that should be minted for a given contribution for the contributor account.

    @dev If token id 0 is returned, the mint should be skipped. This function specifically does not revert so that it doesn't interrupt the contribution flow since NFT rewards are optional and may be exhausted during project or funding cycle lifetime.

    @param account Address sending the contribution.
    @param contribution Contribution amount.
    @param token Reward token to be issued as a reward, used to read token data only.
   */
  function validateContribution(
    address account,
    JBTokenAmount calldata contribution,
    ITokenSupplyDetails token
  ) public override returns (uint256 tokenId) {
    if (contribution.token != contributionToken) {
      return 0;
    }

    if (globalMintAllowance == 0) {
      return 0;
    }

    if (token.totalOwnerBalance(account) >= userMintCap) {
      return 0;
    }

    tokenId = 0;
    uint256 tiersLength = tiers.length;
    for (uint256 i; i < tiersLength; i++) {
      if (
        tiers[i].contributionFloor <= contribution.value &&
        i == tiersLength - 1 &&
        tiers[i].remainingAllowance > 0
      ) {
        tokenId = tiers[i].idCeiling - tiers[i].remainingAllowance;
        unchecked {
          --tiers[i].remainingAllowance;
          --globalMintAllowance;
        }
        break;
      } else if (
        tiers[i].contributionFloor <= contribution.value &&
        tiers[i + 1].contributionFloor > contribution.value &&
        tiers[i].remainingAllowance > 0
      ) {
        tokenId = tiers[i].idCeiling - tiers[i].remainingAllowance;
        unchecked {
          --tiers[i].remainingAllowance;
          --globalMintAllowance;
        }
        break;
      }
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/Strings.sol';

import '../interfaces/IToken721UriResolver.sol';

/**
 * @dev Implements pseudo ERC1155 functionality into an ERC721 token while maintaining unique token id and serving the same metadata for some range of ids.
 */
contract TieredTokenUriResolver is IToken721UriResolver {
  using Strings for uint256;
  error INVALID_ID_SORT_ORDER(uint256);
  error ID_OUT_OF_RANGE();

  string public baseUri;
  uint256[] public idRange;

  /**
    @notice An ERC721-style token URI resolver that appends tier to the end of a base uri.

    @dev This contract is meant to go with NFTs minted using TieredPriceResolver. The URI returned from tokenURI is based on where the given id fits in the range provided to the constructor.

    @param _baseUri Root URI
    @param _idRange List of token id cutoffs between tiers; must be sorted ascending.
    */
  constructor(string memory _baseUri, uint256[] memory _idRange) {
    baseUri = _baseUri;

    // idRange = new uint256[](_idRange.length - 1);
    for (uint256 i; i != _idRange.length; ) {
      if (i != 0) {
        if (idRange[i - 1] > _idRange[i]) {
          revert INVALID_ID_SORT_ORDER(i);
        }
      }
      idRange.push(_idRange[i]);
      unchecked {
        ++i;
      }
    }
  }

  function tokenURI(uint256 _tokenId) external view override returns (string memory uri) {
    uint256 tier;
    for (uint256 i; i != idRange.length; ) {
      if (_tokenId < idRange[i]) {
        tier = i + 1;
        break;
      }
      unchecked {
        ++i;
      }
    }

    if (tier == 0) {
      revert ID_OUT_OF_RANGE();
    }

    uri = string(abi.encodePacked(baseUri, tier.toString()));
  }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';

import '../abstract/JBOperatable.sol';
import '../interfaces/IJBDirectory.sol';
import '../interfaces/IJBOperatorStore.sol';
import '../interfaces/IJBProjects.sol';
import '../interfaces/IJBPaymentTerminal.sol';
import '../libraries/JBOperations.sol';
import '../libraries/JBTokens.sol';
import './TokenLiquidator.sol';

/**
 * @notice Project payment collection contract.
 *
 * This contract is functionally similar to JBETHERC20ProjectPayer, but it adds several useful features. This contract can accept a token and liquidate it on Uniswap if an appropriate terminal doesn't exist. This contract can be configured accept and retain the payment if certain failures occur, like funding cycle misconfiguration. This contract expects to have access to a project terminal for Eth and WETH. WETH terminal will be used to submit liquidation proceeds.
 */
contract PaymentProcessor is JBOperatable, ReentrancyGuard {
  error PAYMENT_FAILURE();
  error INVALID_ADDRESS();
  error INVALID_AMOUNT();

  struct TokenSettings {
    bool accept;
    bool liquidate;
  }

  address public constant WETH9 = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
  ISwapRouter public constant uniswapRouter =
    ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);

  IJBDirectory jbxDirectory;
  IJBProjects jbxProjects;
  ITokenLiquidator liquidator;
  uint256 jbxProjectId;
  bool ignoreFailures;
  bool defaultLiquidation;

  mapping(IERC20 => TokenSettings) tokenPreferences;

  /**
   * @notice This contract serves as a proxy between the payer and the Juicebox platform. It allows payment acceptance in case of Juicebox project misconfiguration. It allows acceptance of ERC20 tokens via liquidation even if there is no corresponding Juicebox payment terminal.
   *
   * @param _jbxDirectory Juicebox directory.
   * @param _jbxOperatorStore Juicebox operator store.
   * @param _jbxProjects Juicebox project registry.
   * @param _liquidator Platform liquidator contract.
   * @param _jbxProjectId Juicebox project id to pay into.
   * @param _ignoreFailures If payment forwarding to the Juicebox terminal fails, Ether will be retained in this contract and ERC20 tokens will be processed per stored instructions. Setting this to false will `revert` failed payment operations.
   * @param _defaultLiquidation Setting this to true will automatically attempt to convert the incoming ERC20 tokens into WETH via Uniswap unless there are specific settings for the given token. Setting it to false will attempt to send the tokens to an appropriate Juicebox terminal, on failure, _ignoreFailures will be followed.
   */
  constructor(
    IJBDirectory _jbxDirectory,
    IJBOperatorStore _jbxOperatorStore,
    IJBProjects _jbxProjects,
    ITokenLiquidator _liquidator,
    uint256 _jbxProjectId,
    bool _ignoreFailures,
    bool _defaultLiquidation
  ) {
    operatorStore = _jbxOperatorStore;

    jbxDirectory = _jbxDirectory;
    jbxProjects = _jbxProjects;
    liquidator = _liquidator;
    jbxProjectId = _jbxProjectId;
    ignoreFailures = _ignoreFailures;
    defaultLiquidation = _defaultLiquidation;
  }

  //*********************************************************************//
  // ----------------------- public transactions ----------------------- //
  //*********************************************************************//

  /**
   * @notice Forwards incoming Ether to Juicebox terminal.
   */
  receive() external payable {
    _processPayment(jbxProjectId, '', new bytes(0));
  }

  /**
   * @notice Forwards incoming Ether to Juicebox terminal.
   *
   * @param _memo Memo for the payment, can be blank, will be forwarded to the Juicebox terminal for event publication.
   * @param _metadata Metadata for the payment, can be blank, will be forwarded to the Juicebox terminal for event publication.
   */
  function processPayment(
    string memory _memo,
    bytes memory _metadata
  ) external payable nonReentrant {
    _processPayment(jbxProjectId, _memo, _metadata);
  }

  /**
   * @notice Forwards incoming tokens to a Juicebox terminal, optionally liquidates them.
   *
   * @dev Tokens for the given amount must already be approved for this contract.
   *
   * @dev If the incoming token is explicitly listed via `setTokenPreferences`, `accept` setting will be applied. Otherwise, if `defaultLiquidation` is enabled, that will be used. Otherwise if ignoreFailures is enabled, token amount will be transferred and stored in this contract. If none of the previous conditions are met, the function will revert.
   *
   * @param _token ERC20 token.
   * @param _amount Token amount to withdraw from the sender.
   * @param _minValue Optional minimum Ether liquidation value.
   * @param _memo Memo for the payment, can be blank, will be forwarded to the Juicebox terminal for event publication.
   * @param _metadata Metadata for the payment, can be blank, will be forwarded to the Juicebox terminal for event publication.
   */
  function processPayment(
    IERC20 _token,
    uint256 _amount,
    uint256 _minValue,
    string memory _memo,
    bytes memory _metadata
  ) external nonReentrant {
    TokenSettings memory settings = tokenPreferences[_token];
    if (settings.accept) {
      _processPayment(
        _token,
        _amount,
        _minValue,
        jbxProjectId,
        _memo,
        _metadata,
        settings.liquidate
      );
    } else if (defaultLiquidation) {
      _processPayment(_token, _amount, _minValue, jbxProjectId, _memo, _metadata, true);
    } else if (ignoreFailures) {
      _token.transferFrom(msg.sender, address(this), _amount);
    } else {
      revert PAYMENT_FAILURE();
    }
  }

  function canProcess(IERC20 _token) external view returns (bool accept) {
    accept = tokenPreferences[_token].accept || defaultLiquidation;
  }

  //*********************************************************************//
  // --------------------- privileged transactions --------------------- //
  //*********************************************************************//

  /**
   * @notice Registers specific preferences for a given token. This feature is optional. If no tokens are explicitly set as "acceptable" and defaultLiquidate is set to false, token payments into this contract will be rejected.
   *
   * @param _token Token to accept.
   * @param _acceptToken Acceptance flag, setting it to false removes the associated record from the registry.
   * @param _liquidateToken Liquidation flag, it's possible to accept a token and forward it as is to a terminal, accept it and retain it in this contract or accept it and liduidate it for WETH via Uniswap.
   */
  function setTokenPreferences(
    IERC20 _token,
    bool _acceptToken,
    bool _liquidateToken
  )
    external
    requirePermissionAllowingOverride(
      jbxProjects.ownerOf(jbxProjectId),
      jbxProjectId,
      JBOperations.MANAGE_PAYMENTS,
      (msg.sender == address(jbxDirectory.controllerOf(jbxProjectId)))
    )
  {
    if (!_acceptToken) {
      delete tokenPreferences[_token];
    } else {
      tokenPreferences[_token] = TokenSettings(_acceptToken, _liquidateToken);
    }
  }

  /**
   * @notice Allows the contract manager (an account with JBOperations.MANAGE_PAYMENTS permission for this project) to set operation parameters. The most-restrictive more is false-false, in which case only the tokens explicitly set as `accept` via setTokenPreferences will be processed.
   *
   * @param _ignoreFailures Ignore some payment failures, this results in processPayment() calls succeeding in more cases and the contract accumulating an Ether or token balance.
   * @param _defaultLiquidation If a given token doesn't have a specific configuration, the payment would still be accepted and liquidated into WETH as part of the payment transaction.
   */
  function setDefaults(
    bool _ignoreFailures,
    bool _defaultLiquidation
  )
    external
    requirePermissionAllowingOverride(
      jbxProjects.ownerOf(jbxProjectId),
      jbxProjectId,
      JBOperations.MANAGE_PAYMENTS,
      (msg.sender == address(jbxDirectory.controllerOf(jbxProjectId)))
    )
  {
    ignoreFailures = _ignoreFailures;
    defaultLiquidation = _defaultLiquidation;
  }

  /**
   * @notice Allows a caller with JBOperations.MANAGE_PAYMENTS permission for the given project, or the project controller to transfer an Ether balance held in this contract.
   */
  function transferBalance(
    address payable _destination,
    uint256 _amount
  )
    external
    nonReentrant
    requirePermissionAllowingOverride(
      jbxProjects.ownerOf(jbxProjectId),
      jbxProjectId,
      JBOperations.MANAGE_PAYMENTS,
      (msg.sender == address(jbxDirectory.controllerOf(jbxProjectId)))
    )
  {
    if (_destination == address(0)) {
      revert INVALID_ADDRESS();
    }

    if (_amount == 0 || _amount > (payable(address(this))).balance) {
      revert INVALID_AMOUNT();
    }

    _destination.transfer(_amount);
  }

  /**
   * @notice Allows a caller with JBOperations.MANAGE_PAYMENTS permission for the given project, or the project controller to transfer an ERC20 token balance associated with this contract.
   *
   * @param _destination Account to assign token balance to.
   * @param _token ERC20 token to operate on.
   * @param _amount Token amount to transfer.
   *
   * @return ERC20 transfer function result.
   */
  function transferTokens(
    address _destination,
    IERC20 _token,
    uint256 _amount
  )
    external
    nonReentrant
    requirePermissionAllowingOverride(
      jbxProjects.ownerOf(jbxProjectId),
      jbxProjectId,
      JBOperations.MANAGE_PAYMENTS,
      (msg.sender == address(jbxDirectory.controllerOf(jbxProjectId)))
    )
    returns (bool)
  {
    if (_destination == address(0)) {
      revert INVALID_ADDRESS();
    }

    return _token.transfer(_destination, _amount);
  }

  //*********************************************************************//
  // ---------------------- internal transactions ---------------------- //
  //*********************************************************************//

  /**
   * @notice Ether payment processing.
   */
  function _processPayment(
    uint256 _jbxProjectId,
    string memory _memo,
    bytes memory _metadata
  ) internal virtual {
    IJBPaymentTerminal terminal = jbxDirectory.primaryTerminalOf(_jbxProjectId, JBTokens.ETH);

    if (address(terminal) == address(0) && !ignoreFailures) {
      revert PAYMENT_FAILURE();
    }

    if (address(terminal) != address(0)) {
      (bool success, ) = address(terminal).call{value: msg.value}(
        abi.encodeWithSelector(
          terminal.pay.selector,
          _jbxProjectId,
          msg.value,
          JBTokens.ETH,
          msg.sender,
          0,
          false,
          _memo,
          _metadata
        )
      );

      if (!success) {
        revert PAYMENT_FAILURE();
      }
    }
  }

  /**
     * @notice Token payment processing that optionally liquidates incoming tokens for Ether.
     * 
     * @dev The result of this function depends on existence of a `tokenPreferences` record for the given token, `ignoreFailures` and
    `defaultLiquidation` global settings.
     *
     * @dev This function will still revert, regardless of `ignoreFailures`, if there is a liquidation event and the ether proceeds are below `_minValue`, unless that parameter is `0`.
     * 
     * @param _token ERC20 token to accept.
     * @param _amount Amount of token to expect.
     * @param _minValue Minimum required Ether value for token amount. Receiving less than this from Uniswap will cause a revert even is ignoreFailures is set.
     * @param _jbxProjectId Juicebox project id.
     * @param _memo IJBPaymentTerminal memo.
     * @param _metadata IJBPaymentTerminal metadata.
     * @param _liquidateToken Liquidation flag, if set the token will be converted into Ether and deposited into the project's Ether terminal.
     */
  function _processPayment(
    IERC20 _token,
    uint256 _amount,
    uint256 _minValue,
    uint256 _jbxProjectId,
    string memory _memo,
    bytes memory _metadata,
    bool _liquidateToken
  ) internal {
    if (_liquidateToken) {
      _liquidate(_token, _amount, _minValue, _jbxProjectId, _memo, _metadata);
      return;
    }

    IJBPaymentTerminal terminal = jbxDirectory.primaryTerminalOf(_jbxProjectId, address(_token));

    if (address(terminal) == address(0) && !ignoreFailures) {
      revert PAYMENT_FAILURE();
    }

    if (address(terminal) == address(0) && defaultLiquidation) {
      _liquidate(_token, _amount, _minValue, _jbxProjectId, _memo, _metadata);
      return;
    }

    if (!_token.transferFrom(msg.sender, address(this), _amount)) {
      revert PAYMENT_FAILURE();
    }

    _token.approve(address(terminal), _amount);

    (bool success, ) = address(terminal).call(
      abi.encodeWithSelector(
        terminal.pay.selector,
        jbxProjectId,
        _amount,
        address(_token),
        msg.sender,
        0,
        false,
        _memo,
        _metadata
      )
    );

    _token.approve(address(terminal), 0);

    if (success) {
      return;
    }

    if (!ignoreFailures) {
      revert PAYMENT_FAILURE();
    }

    if (ignoreFailures && defaultLiquidation) {
      _liquidate(_token, _amount, _minValue, _jbxProjectId, _memo, _metadata);

      return;
    }
  }

  /**
   * @dev Liquidates tokens for Eth or WETH from the transaction sender.
   */
  function _liquidate(
    IERC20 _token,
    uint256 _amount,
    uint256 _minValue,
    uint256 _jbxProjectId,
    string memory _memo,
    bytes memory _metadata
  ) internal {
    _token.transferFrom(msg.sender, address(this), _amount);
    _token.approve(address(liquidator), _amount);

    uint256 remainingAmount = liquidator.liquidateTokens(
      _token,
      _amount,
      _minValue,
      _jbxProjectId,
      msg.sender,
      _memo,
      _metadata
    );
    if (remainingAmount != 0) {
      _token.transfer(msg.sender, remainingAmount);
    }

    _token.approve(address(liquidator), 0);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../interfaces/IJBDirectory.sol';
import '../interfaces/IJBProjects.sol';
import '../interfaces/IJBOperatorStore.sol';

/**
 * @notice A struct that contains all the components needed to validate permissions using JBOperatable.
 */
struct PermissionValidationComponents {
  IJBDirectory jbxDirectory;
  IJBProjects jbxProjects;
  IJBOperatorStore jbxOperatorStore;
}

struct CommonNFTAttributes {
  string name;
  string symbol;
  string baseUri;
  bool revealed;
  string contractUri;
  uint256 maxSupply;
  uint256 unitPrice;
  uint256 mintAllowance;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';

import '../abstract/JBOperatable.sol';
import '../interfaces/IJBDirectory.sol';
import '../interfaces/IJBOperatorStore.sol';
import '../interfaces/IJBProjects.sol';
import '../interfaces/IJBPaymentTerminal.sol';
import '../libraries/JBOperations.sol';
import '../libraries/JBTokens.sol';

interface IWETH9 is IERC20 {
  function deposit() external payable;

  function withdraw(uint256) external;
}

enum TokenLiquidatorError {
  NO_TERMINALS_FOUND,
  INPUT_TOKEN_BLOCKED,
  INPUT_TOKEN_TRANSFER_FAILED,
  INPUT_TOKEN_APPROVAL_FAILED,
  ETH_TRANSFER_FAILED
}

interface ITokenLiquidator {
  receive() external payable;

  function liquidateTokens(
    IERC20 _token,
    uint256 _amount,
    uint256 _minValue,
    uint256 _jbxProjectId,
    address _beneficiary,
    string memory _memo,
    bytes memory _metadata
  ) external returns (uint256);

  function withdrawFees() external;

  function setProtocolFee(uint256 _feeBps) external;

  function setUniswapPoolFee(uint24 _uniswapPoolFee) external;

  function blockToken(IERC20 _token) external;

  function unblockToken(IERC20 _token) external;
}

contract TokenLiquidator is ITokenLiquidator, JBOperatable {
  enum TokenLiquidatorPaymentType {
    ETH_TO_SENDER, // TODO
    ETH_TO_TERMINAL,
    WETH_TO_TERMINAL
  }

  error LIQUIDATION_FAILURE(TokenLiquidatorError _errorCode);

  event AllowTokenLiquidation(IERC20 token);
  event PreventLiquidation(IERC20 token);

  address public constant WETH9 = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
  ISwapRouter public constant uniswapRouter =
    ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);

  uint256 internal constant FEE_CAP_BPS = 500; // 5%
  uint256 internal constant PROTOCOL_PROJECT_ID = 1;

  IJBDirectory public jbxDirectory;
  IJBProjects public jbxProjects;
  uint256 public feeBps;
  mapping(IERC20 => bool) blockedTokens;
  uint24 public uniswapPoolFee;

  IJBPaymentTerminal transientTerminal;
  uint256 transientProjectId;
  address transientBeneficiary;
  string transientMemo;
  bytes transientMetadata;
  address transientSender;

  /**
   * @param _jbxDirectory Juicebox directory for payment terminal lookup.
   * @param _feeBps Protocol swap fee.
   * @param  _uniswapPoolFee Uniswap pool fee.
   */
  constructor(
    IJBDirectory _jbxDirectory,
    IJBOperatorStore _jbxOperatorStore,
    IJBProjects _jbxProjects,
    uint256 _feeBps,
    uint24 _uniswapPoolFee
  ) {
    if (_feeBps > FEE_CAP_BPS) {
      revert();
    }

    operatorStore = _jbxOperatorStore;

    jbxDirectory = _jbxDirectory;
    jbxProjects = _jbxProjects;
    feeBps = _feeBps;
    uniswapPoolFee = _uniswapPoolFee;
  }

  receive() external payable override {}

  /**
   * @notice Swap incoming token for Ether/WETH and deposit the proceeeds into the appropriate Juicebox terminal.
   *
   * @dev If _minValue is specified, will call exactOutputSingle, otherwise exactInputSingle on uniswap v3.
   * @dev msg.sender here is expected to be an instance of PaymentProcessor which would retain the sale proceeds if they cannot be forwarded to the Ether or WETH terminal for the given project.
   *
   * @param _token Token to liquidate
   * @param _amount Token amount to liquidate.
   * @param _minValue Minimum required Ether/WETH value for the incoming token amount.
   * @param _jbxProjectId Juicebox project ID to pay into.
   * @param _beneficiary IJBPaymentTerminal beneficiary argument.
   * @param _memo IJBPaymentTerminal memo argument.
   * @param _metadata IJBPaymentTerminal metadata argument.
   */
  function liquidateTokens(
    IERC20 _token,
    uint256 _amount,
    uint256 _minValue,
    uint256 _jbxProjectId,
    address _beneficiary,
    string memory _memo,
    bytes memory _metadata
  ) external override returns (uint256 remainingAmount) {
    if (blockedTokens[_token]) {
      revert LIQUIDATION_FAILURE(TokenLiquidatorError.INPUT_TOKEN_BLOCKED);
    }

    if (!_token.transferFrom(msg.sender, address(this), _amount)) {
      revert LIQUIDATION_FAILURE(TokenLiquidatorError.INPUT_TOKEN_TRANSFER_FAILED);
    }

    TokenLiquidatorPaymentType paymentDestination;

    IJBPaymentTerminal ethTerminal = jbxDirectory.primaryTerminalOf(_jbxProjectId, JBTokens.ETH);

    if (ethTerminal != IJBPaymentTerminal(address(0))) {
      transientTerminal = ethTerminal;
      transientProjectId = _jbxProjectId;
      transientBeneficiary = _beneficiary;
      transientMemo = _memo;
      transientMetadata = _metadata;
      transientSender = msg.sender;

      paymentDestination = TokenLiquidatorPaymentType.ETH_TO_TERMINAL;
    } else {
      IJBPaymentTerminal wethTerminal = jbxDirectory.primaryTerminalOf(_jbxProjectId, WETH9);

      if (wethTerminal != IJBPaymentTerminal(address(0))) {
        transientTerminal = wethTerminal; // NOTE: transfers to a WETH terminal happen here, no need to set transient state
        paymentDestination = TokenLiquidatorPaymentType.WETH_TO_TERMINAL;
      }
    }

    if (transientTerminal == IJBPaymentTerminal(address(0))) {
      revert LIQUIDATION_FAILURE(TokenLiquidatorError.NO_TERMINALS_FOUND);
    }

    if (!_token.approve(address(uniswapRouter), _amount)) {
      revert LIQUIDATION_FAILURE(TokenLiquidatorError.INPUT_TOKEN_APPROVAL_FAILED);
    }

    uint256 swapProceeds;
    if (_minValue == 0) {
      ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
        tokenIn: address(_token),
        tokenOut: WETH9,
        fee: uniswapPoolFee,
        recipient: address(this),
        deadline: block.timestamp,
        amountIn: _amount,
        amountOutMinimum: 0,
        sqrtPriceLimitX96: 0
      });

      swapProceeds = uniswapRouter.exactInputSingle(params);
    } else {
      ISwapRouter.ExactOutputSingleParams memory params = ISwapRouter.ExactOutputSingleParams({
        tokenIn: address(_token),
        tokenOut: WETH9,
        fee: uniswapPoolFee,
        recipient: address(this),
        deadline: block.timestamp,
        amountOut: _minValue,
        amountInMaximum: _amount,
        sqrtPriceLimitX96: 0
      });

      uint256 amountSpent = uniswapRouter.exactOutputSingle(params); // NOTE: this will revert if _minValue is not received
      swapProceeds = _minValue;

      if (amountSpent < _amount) {
        remainingAmount = _amount - amountSpent;
        _token.transfer(msg.sender, remainingAmount);
      }
    }

    _token.approve(address(uniswapRouter), 0);

    uint256 fee = (swapProceeds * feeBps) / 10_000;
    uint256 projectProceeds = swapProceeds - fee;

    if (paymentDestination == TokenLiquidatorPaymentType.ETH_TO_TERMINAL) {
      IWETH9(WETH9).withdraw(projectProceeds); // NOTE: will end up in receive()
      transientTerminal.pay{value: projectProceeds}(
        transientProjectId,
        projectProceeds,
        JBTokens.ETH,
        transientBeneficiary,
        0,
        false,
        transientMemo,
        transientMetadata
      );
    } else if (paymentDestination == TokenLiquidatorPaymentType.WETH_TO_TERMINAL) {
      IERC20(WETH9).approve(address(transientTerminal), projectProceeds);

      transientTerminal.pay(
        _jbxProjectId,
        projectProceeds,
        WETH9,
        _beneficiary,
        0,
        false,
        _memo,
        _metadata
      );

      IERC20(WETH9).approve(address(transientTerminal), 0);
      transientTerminal = IJBPaymentTerminal(address(0));
    }
  }

  /**
   * @notice A trustless way for withdraw WETH and Ether balances from this contract into the platform (project 1) terminal.
   */
  function withdrawFees() external override {
    IJBPaymentTerminal protocolTerminal = jbxDirectory.primaryTerminalOf(
      PROTOCOL_PROJECT_ID,
      WETH9
    );

    uint256 wethBalance = IERC20(WETH9).balanceOf(address(this));
    IERC20(WETH9).approve(address(protocolTerminal), wethBalance);

    protocolTerminal.pay(
      PROTOCOL_PROJECT_ID,
      wethBalance,
      WETH9,
      address(0),
      0,
      false,
      'TokenLiquidator fees',
      ''
    );

    IERC20(WETH9).approve(address(protocolTerminal), 0);

    if (address(this).balance != 0) {
      protocolTerminal = jbxDirectory.primaryTerminalOf(PROTOCOL_PROJECT_ID, JBTokens.ETH);
      protocolTerminal.pay{value: address(this).balance}(
        transientProjectId,
        address(this).balance,
        JBTokens.ETH,
        address(0),
        0,
        false,
        'TokenLiquidator fees',
        ''
      );
    }
  }

  /**
   * @notice Set protocol liquidation fee. This share of the swap proceeds will be taken out and kept for the protocol. Expressed in basis points.
   */
  function setProtocolFee(
    uint256 _feeBps
  )
    external
    override
    requirePermissionAllowingOverride(
      jbxProjects.ownerOf(PROTOCOL_PROJECT_ID),
      PROTOCOL_PROJECT_ID,
      JBOperations.MANAGE_PAYMENTS,
      (msg.sender == address(jbxDirectory.controllerOf(PROTOCOL_PROJECT_ID)))
    )
  {
    if (_feeBps > FEE_CAP_BPS) {
      revert();
    }

    feeBps = _feeBps;
  }

  /**
   * @notice Set Uniswap pool fee.
   */
  function setUniswapPoolFee(
    uint24 _uniswapPoolFee
  )
    external
    override
    requirePermissionAllowingOverride(
      jbxProjects.ownerOf(PROTOCOL_PROJECT_ID),
      PROTOCOL_PROJECT_ID,
      JBOperations.MANAGE_PAYMENTS,
      (msg.sender == address(jbxDirectory.controllerOf(PROTOCOL_PROJECT_ID)))
    )
  {
    uniswapPoolFee = _uniswapPoolFee;
  }

  /**
   * @notice Prevent liquidation of a specific token through the contract.
   */
  function blockToken(
    IERC20 _token
  )
    external
    override
    requirePermissionAllowingOverride(
      jbxProjects.ownerOf(PROTOCOL_PROJECT_ID),
      PROTOCOL_PROJECT_ID,
      JBOperations.MANAGE_PAYMENTS,
      (msg.sender == address(jbxDirectory.controllerOf(PROTOCOL_PROJECT_ID)))
    )
  {
    blockedTokens[_token] = true;
    emit PreventLiquidation(_token);
  }

  /**
   * @notice Remove a previously blocked token from the block list.
   */
  function unblockToken(
    IERC20 _token
  )
    external
    override
    requirePermissionAllowingOverride(
      jbxProjects.ownerOf(PROTOCOL_PROJECT_ID),
      PROTOCOL_PROJECT_ID,
      JBOperations.MANAGE_PAYMENTS,
      (msg.sender == address(jbxDirectory.controllerOf(PROTOCOL_PROJECT_ID)))
    )
  {
    if (blockedTokens[_token]) {
      delete blockedTokens[_token];
      emit AllowTokenLiquidation(_token);
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@paulrberg/contracts/math/PRBMath.sol';

import '../../structs/JBSplit.sol';
import '../../interfaces/IJBDirectory.sol';
import '../../interfaces/IJBSplitsPayer.sol';
import '../../interfaces/IJBSplitsStore.sol';
import '../../libraries/JBConstants.sol';
import '../../libraries/JBTokens.sol';

abstract contract JBSplitPayerUtil {
  event DistributeToSplit(
    uint256 indexed projectId,
    uint256 indexed domain,
    uint256 indexed group,
    JBSplit split,
    uint256 amount,
    address defaultBeneficiary,
    address caller
  );

  //*********************************************************************//
  // -------------------------- custom errors -------------------------- //
  //*********************************************************************//
  error TERMINAL_NOT_FOUND();
  error INCORRECT_DECIMAL_AMOUNT();

  function payToSplits(
    JBSplit[] memory _splits,
    uint256 _amount,
    address _token,
    uint256 _decimals,
    IJBDirectory _directory,
    uint256 defaultProjectId,
    address payable _defaultBeneficiary
  ) public returns (uint256 leftoverAmount) {
    // Set the leftover amount to the initial balance.
    leftoverAmount = _amount;

    // Settle between all splits.
    for (uint256 i = 0; i < _splits.length; i++) {
      // Get a reference to the split being iterated on.
      JBSplit memory _split = _splits[i];

      // The amount to send towards the split.
      uint256 _splitAmount = PRBMath.mulDiv(
        _amount,
        _split.percent,
        JBConstants.SPLITS_TOTAL_PERCENT
      );

      if (_splitAmount > 0) {
        // Transfer tokens to the split.
        // If there's an allocator set, transfer to its `allocate` function.
        if (_split.allocator != IJBSplitAllocator(address(0))) {
          // Create the data to send to the allocator.
          JBSplitAllocationData memory _data = JBSplitAllocationData(
            _token,
            _splitAmount,
            _decimals,
            defaultProjectId,
            0,
            _split
          );

          // Approve the `_amount` of tokens for the split allocator to transfer tokens from this contract.
          if (_token != JBTokens.ETH)
            IERC20(_token).approve(address(_split.allocator), _splitAmount);

          // If the token is ETH, send it in msg.value.
          uint256 _payableValue = _token == JBTokens.ETH ? _splitAmount : 0;

          // Trigger the allocator's `allocate` function.
          _split.allocator.allocate{value: _payableValue}(_data);

          // Otherwise, if a project is specified, make a payment to it.
        } else if (_split.projectId != 0) {
          if (_split.preferAddToBalance) {
            _addToBalanceOf(_directory, _split.projectId, _token, _splitAmount, _decimals, '', '');
          } else {
            _pay(
              _directory,
              _split.projectId,
              _token,
              _splitAmount,
              _decimals,
              _split.beneficiary != address(0) ? _split.beneficiary : _defaultBeneficiary,
              0,
              _split.preferClaimed,
              '',
              ''
            );
          }
        } else {
          // Transfer the ETH.
          if (_token == JBTokens.ETH)
            Address.sendValue(
              // Get a reference to the address receiving the tokens. If there's a beneficiary, send the funds directly to the beneficiary. Otherwise send to the msg.sender.
              _split.beneficiary != address(0) ? _split.beneficiary : payable(_defaultBeneficiary),
              _splitAmount
            );
            // Or, transfer the ERC20.
          else {
            IERC20(_token).transfer(
              // Get a reference to the address receiving the tokens. If there's a beneficiary, send the funds directly to the beneficiary. Otherwise send to the msg.sender.
              _split.beneficiary != address(0) ? _split.beneficiary : _defaultBeneficiary,
              _splitAmount
            );
          }
        }

        // Subtract from the amount to be sent to the beneficiary.
        leftoverAmount = leftoverAmount - _splitAmount;
      }

      emit DistributeToSplit(0, 0, 0, _split, _splitAmount, _defaultBeneficiary, msg.sender);
    }
  }

  function _pay(
    IJBDirectory _directory,
    uint256 _projectId,
    address _token,
    uint256 _amount,
    uint256 _decimals,
    address _beneficiary,
    uint256 _minReturnedTokens,
    bool _preferClaimedTokens,
    string memory _memo,
    bytes memory _metadata
  ) internal {
    // Find the terminal for the specified project.
    IJBPaymentTerminal _terminal = _directory.primaryTerminalOf(_projectId, _token);

    // There must be a terminal.
    if (_terminal == IJBPaymentTerminal(address(0))) {
      revert TERMINAL_NOT_FOUND();
    }

    // The amount's decimals must match the terminal's expected decimals.
    if (_terminal.decimalsForToken(_token) != _decimals) {
      revert INCORRECT_DECIMAL_AMOUNT();
    }

    // Approve the `_amount` of tokens from the destination terminal to transfer tokens from this contract.
    if (_token != JBTokens.ETH) {
      IERC20(_token).approve(address(_terminal), _amount);
    }

    // If the token is ETH, send it in msg.value.
    uint256 _payableValue = _token == JBTokens.ETH ? _amount : 0;

    // Send funds to the terminal.
    // If the token is ETH, send it in msg.value.
    _terminal.pay{value: _payableValue}(
      _projectId,
      _amount, // ignored if the token is JBTokens.ETH.
      _token,
      _beneficiary != address(0) ? _beneficiary : msg.sender,
      _minReturnedTokens,
      _preferClaimedTokens,
      _memo,
      _metadata
    );
  }

  function _addToBalanceOf(
    IJBDirectory _directory,
    uint256 _projectId,
    address _token,
    uint256 _amount,
    uint256 _decimals,
    string memory _memo,
    bytes memory _metadata
  ) internal {
    // Find the terminal for the specified project.
    IJBPaymentTerminal _terminal = _directory.primaryTerminalOf(_projectId, _token);

    // There must be a terminal.
    if (_terminal == IJBPaymentTerminal(address(0))) {
      revert TERMINAL_NOT_FOUND();
    }

    // The amount's decimals must match the terminal's expected decimals.
    if (_terminal.decimalsForToken(_token) != _decimals) {
      revert INCORRECT_DECIMAL_AMOUNT();
    }

    // Approve the `_amount` of tokens from the destination terminal to transfer tokens from this contract.
    if (_token != JBTokens.ETH) {
      IERC20(_token).approve(address(_terminal), _amount);
    }

    // If the token is ETH, send it in msg.value.
    uint256 _payableValue = _token == JBTokens.ETH ? _amount : 0;

    // Add to balance so tokens don't get issued.
    _terminal.addToBalanceOf{value: _payableValue}(_projectId, _amount, _token, _memo, _metadata);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './IJBFundingCycleStore.sol';
import './IJBPaymentTerminal.sol';
import './IJBProjects.sol';

interface IJBDirectory {
  event SetController(uint256 indexed projectId, address indexed controller, address caller);

  event AddTerminal(uint256 indexed projectId, IJBPaymentTerminal indexed terminal, address caller);

  event SetTerminals(uint256 indexed projectId, IJBPaymentTerminal[] terminals, address caller);

  event SetPrimaryTerminal(
    uint256 indexed projectId,
    address indexed token,
    IJBPaymentTerminal indexed terminal,
    address caller
  );

  event SetIsAllowedToSetFirstController(address indexed addr, bool indexed flag, address caller);

  function projects() external view returns (IJBProjects);

  function fundingCycleStore() external view returns (IJBFundingCycleStore);

  function controllerOf(uint256 _projectId) external view returns (address);

  function isAllowedToSetFirstController(address _address) external view returns (bool);

  function terminalsOf(uint256 _projectId) external view returns (IJBPaymentTerminal[] memory);

  function isTerminalOf(uint256 _projectId, IJBPaymentTerminal _terminal)
    external
    view
    returns (bool);

  function primaryTerminalOf(uint256 _projectId, address _token)
    external
    view
    returns (IJBPaymentTerminal);

  function setControllerOf(uint256 _projectId, address _controller) external;

  function setTerminalsOf(uint256 _projectId, IJBPaymentTerminal[] calldata _terminals) external;

  function setPrimaryTerminalOf(
    uint256 _projectId,
    address _token,
    IJBPaymentTerminal _terminal
  ) external;

  function setIsAllowedToSetFirstController(address _address, bool _flag) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/introspection/IERC165.sol';
import './../enums/JBBallotState.sol';

interface IJBFundingCycleBallot is IERC165 {
  function duration() external view returns (uint256);

  function stateOf(
    uint256 _projectId,
    uint256 _configuration,
    uint256 _start
  ) external view returns (JBBallotState);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/introspection/IERC165.sol';
import './../structs/JBPayDelegateAllocation.sol';
import './../structs/JBPayParamsData.sol';
import './../structs/JBRedeemParamsData.sol';
import './../structs/JBRedemptionDelegateAllocation.sol';

/**
  @title
  Datasource

  @notice
  The datasource is called by JBPaymentTerminal on pay and redemption, and provide an extra layer of logic to use 
  a custom weight, a custom memo and/or a pay/redeem delegate

  @dev
  Adheres to:
  IERC165 for adequate interface integration
*/
interface IJBFundingCycleDataSource is IERC165 {
  /**
    @notice
    The datasource implementation for JBPaymentTerminal.pay(..)

    @param _data the data passed to the data source in terminal.pay(..), as a JBPayParamsData struct:
                  IJBPaymentTerminal terminal;
                  address payer;
                  JBTokenAmount amount;
                  uint256 projectId;
                  uint256 currentFundingCycleConfiguration;
                  address beneficiary;
                  uint256 weight;
                  uint256 reservedRate;
                  string memo;
                  bytes metadata;

    @return weight the weight to use to override the funding cycle weight
    @return memo the memo to override the pay(..) memo
    @return delegateAllocations The amount to send to delegates instead of adding to the local balance.
  */
  function payParams(JBPayParamsData calldata _data)
    external
    returns (
      uint256 weight,
      string memory memo,
      JBPayDelegateAllocation[] memory delegateAllocations
    );

  /**
    @notice
    The datasource implementation for JBPaymentTerminal.redeemTokensOf(..)

    @param _data the data passed to the data source in terminal.redeemTokensOf(..), as a JBRedeemParamsData struct:
                    IJBPaymentTerminal terminal;
                    address holder;
                    uint256 projectId;
                    uint256 currentFundingCycleConfiguration;
                    uint256 tokenCount;
                    uint256 totalSupply;
                    uint256 overflow;
                    JBTokenAmount reclaimAmount;
                    bool useTotalOverflow;
                    uint256 redemptionRate;
                    uint256 ballotRedemptionRate;
                    string memo;
                    bytes metadata;

    @return reclaimAmount The amount to claim, overriding the terminal logic.
    @return memo The memo to override the redeemTokensOf(..) memo.
    @return delegateAllocations The amount to send to delegates instead of adding to the beneficiary.
  */
  function redeemParams(JBRedeemParamsData calldata _data)
    external
    returns (
      uint256 reclaimAmount,
      string memory memo,
      JBRedemptionDelegateAllocation[] memory delegateAllocations
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './../enums/JBBallotState.sol';
import './../structs/JBFundingCycle.sol';
import './../structs/JBFundingCycleData.sol';

interface IJBFundingCycleStore {
  event Configure(
    uint256 indexed configuration,
    uint256 indexed projectId,
    JBFundingCycleData data,
    uint256 metadata,
    uint256 mustStartAtOrAfter,
    address caller
  );

  event Init(uint256 indexed configuration, uint256 indexed projectId, uint256 indexed basedOn);

  function latestConfigurationOf(uint256 _projectId) external view returns (uint256);

  function get(uint256 _projectId, uint256 _configuration)
    external
    view
    returns (JBFundingCycle memory);

  function latestConfiguredOf(uint256 _projectId)
    external
    view
    returns (JBFundingCycle memory fundingCycle, JBBallotState ballotState);

  function queuedOf(uint256 _projectId) external view returns (JBFundingCycle memory fundingCycle);

  function currentOf(uint256 _projectId) external view returns (JBFundingCycle memory fundingCycle);

  function currentBallotStateOf(uint256 _projectId) external view returns (JBBallotState);

  function configureFor(
    uint256 _projectId,
    JBFundingCycleData calldata _data,
    uint256 _metadata,
    uint256 _mustStartAtOrAfter
  ) external returns (JBFundingCycle memory fundingCycle);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './IJBOperatorStore.sol';

interface IJBOperatable {
  function operatorStore() external view returns (IJBOperatorStore);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './../structs/JBOperatorData.sol';

interface IJBOperatorStore {
  event SetOperator(
    address indexed operator,
    address indexed account,
    uint256 indexed domain,
    uint256[] permissionIndexes,
    uint256 packed
  );

  function permissionsOf(
    address _operator,
    address _account,
    uint256 _domain
  ) external view returns (uint256);

  function hasPermission(
    address _operator,
    address _account,
    uint256 _domain,
    uint256 _permissionIndex
  ) external view returns (bool);

  function hasPermissions(
    address _operator,
    address _account,
    uint256 _domain,
    uint256[] calldata _permissionIndexes
  ) external view returns (bool);

  function setOperator(JBOperatorData calldata _operatorData) external;

  function setOperators(JBOperatorData[] calldata _operatorData) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/introspection/IERC165.sol';
import './../structs/JBDidPayData.sol';

/**
  @title
  Pay delegate

  @notice
  Delegate called after JBTerminal.pay(..) logic completion (if passed by the funding cycle datasource)

  @dev
  Adheres to:
  IERC165 for adequate interface integration
*/
interface IJBPayDelegate is IERC165 {
  /**
    @notice
    This function is called by JBPaymentTerminal.pay(..), after the execution of its logic

    @dev
    Critical business logic should be protected by an appropriate access control
    
    @param _data the data passed by the terminal, as a JBDidPayData struct:
                  address payer;
                  uint256 projectId;
                  uint256 currentFundingCycleConfiguration;
                  JBTokenAmount amount;
                  JBTokenAmount forwardedAmount;
                  uint256 projectTokenCount;
                  address beneficiary;
                  bool preferClaimedTokens;
                  string memo;
                  bytes metadata;
  */
  function didPay(JBDidPayData calldata _data) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/introspection/IERC165.sol';

interface IJBPaymentTerminal is IERC165 {
  function acceptsToken(address _token, uint256 _projectId) external view returns (bool);

  function currencyForToken(address _token) external view returns (uint256);

  function decimalsForToken(address _token) external view returns (uint256);

  // Return value must be a fixed point number with 18 decimals.
  function currentEthOverflowOf(uint256 _projectId) external view returns (uint256);

  function pay(
    uint256 _projectId,
    uint256 _amount,
    address _token,
    address _beneficiary,
    uint256 _minReturnedTokens,
    bool _preferClaimedTokens,
    string calldata _memo,
    bytes calldata _metadata
  ) external payable returns (uint256 beneficiaryTokenCount);

  function addToBalanceOf(
    uint256 _projectId,
    uint256 _amount,
    address _token,
    string calldata _memo,
    bytes calldata _metadata
  ) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import './../structs/JBProjectMetadata.sol';
import './IJBTokenUriResolver.sol';

interface IJBProjects is IERC721 {
  event Create(
    uint256 indexed projectId,
    address indexed owner,
    JBProjectMetadata metadata,
    address caller
  );

  event SetMetadata(uint256 indexed projectId, JBProjectMetadata metadata, address caller);

  event SetTokenUriResolver(IJBTokenUriResolver indexed resolver, address caller);

  function count() external view returns (uint256);

  function metadataContentOf(uint256 _projectId, uint256 _domain)
    external
    view
    returns (string memory);

  function tokenUriResolver() external view returns (IJBTokenUriResolver);

  function createFor(address _owner, JBProjectMetadata calldata _metadata)
    external
    returns (uint256 projectId);

  function setMetadataOf(uint256 _projectId, JBProjectMetadata calldata _metadata) external;

  function setTokenUriResolver(IJBTokenUriResolver _newResolver) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/introspection/IERC165.sol';
import './../structs/JBDidRedeemData.sol';

/**
  @title
  Redemption delegate

  @notice
  Delegate called after JBTerminal.redeemTokensOf(..) logic completion (if passed by the funding cycle datasource)

  @dev
  Adheres to:
  IERC165 for adequate interface integration
*/
interface IJBRedemptionDelegate is IERC165 {
  /**
    @notice
    This function is called by JBPaymentTerminal.redeemTokensOf(..), after the execution of its logic

    @dev
    Critical business logic should be protected by an appropriate access control
    
    @param _data the data passed by the terminal, as a JBDidRedeemData struct:
                address holder;
                uint256 projectId;
                uint256 currentFundingCycleConfiguration;
                uint256 projectTokenCount;
                JBTokenAmount reclaimedAmount;
                JBTokenAmount forwardedAmount;
                address payable beneficiary;
                string memo;
                bytes metadata;
  */
  function didRedeem(JBDidRedeemData calldata _data) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/introspection/IERC165.sol';
import '../structs/JBSplitAllocationData.sol';

/**
  @title
  Split allocator

  @notice
  Provide a way to process a single split with extra logic

  @dev
  Adheres to:
  IERC165 for adequate interface integration

  @dev
  The contract address should be set as an allocator in the adequate split
*/
interface IJBSplitAllocator is IERC165 {
  /**
    @notice
    This function is called by JBPaymentTerminal.distributePayoutOf(..), during the processing of the split including it

    @dev
    Critical business logic should be protected by an appropriate access control. The token and/or eth are optimistically transfered
    to the allocator for its logic.
    
    @param _data the data passed by the terminal, as a JBSplitAllocationData struct:
                  address token;
                  uint256 amount;
                  uint256 decimals;
                  uint256 projectId;
                  uint256 group;
                  JBSplit split;
  */
  function allocate(JBSplitAllocationData calldata _data) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/introspection/IERC165.sol';
import './../structs/JBSplit.sol';
import './../structs/JBGroupedSplits.sol';
import './IJBSplitsStore.sol';

interface IJBSplitsPayer is IERC165 {
  event SetDefaultSplitsReference(
    uint256 indexed projectId,
    uint256 indexed domain,
    uint256 indexed group,
    address caller
  );
  event Pay(
    uint256 indexed projectId,
    address beneficiary,
    address token,
    uint256 amount,
    uint256 decimals,
    uint256 leftoverAmount,
    uint256 minReturnedTokens,
    bool preferClaimedTokens,
    string memo,
    bytes metadata,
    address caller
  );

  event AddToBalance(
    uint256 indexed projectId,
    address beneficiary,
    address token,
    uint256 amount,
    uint256 decimals,
    uint256 leftoverAmount,
    string memo,
    bytes metadata,
    address caller
  );

  event DistributeToSplitGroup(
    uint256 indexed projectId,
    uint256 indexed domain,
    uint256 indexed group,
    address caller
  );

  event DistributeToSplit(
    JBSplit split,
    uint256 amount,
    address defaultBeneficiary,
    address caller
  );

  function defaultSplitsProjectId() external view returns (uint256);

  function defaultSplitsDomain() external view returns (uint256);

  function defaultSplitsGroup() external view returns (uint256);

  function splitsStore() external view returns (IJBSplitsStore);

  function initialize(
    uint256 _defaultSplitsProjectId,
    uint256 _defaultSplitsDomain,
    uint256 _defaultSplitsGroup,
    uint256 _defaultProjectId,
    address payable _defaultBeneficiary,
    bool _defaultPreferClaimedTokens,
    string memory _defaultMemo,
    bytes memory _defaultMetadata,
    bool _preferAddToBalance,
    address _owner
  ) external;

  function setDefaultSplitsReference(
    uint256 _projectId,
    uint256 _domain,
    uint256 _group
  ) external;

  function setDefaultSplits(
    uint256 _projectId,
    uint256 _domain,
    uint256 _group,
    JBGroupedSplits[] memory _splitsGroup
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './../structs/JBGroupedSplits.sol';
import './../structs/JBSplit.sol';
import './IJBDirectory.sol';
import './IJBProjects.sol';

interface IJBSplitsStore {
  event SetSplit(
    uint256 indexed projectId,
    uint256 indexed domain,
    uint256 indexed group,
    JBSplit split,
    address caller
  );

  function projects() external view returns (IJBProjects);

  function directory() external view returns (IJBDirectory);

  function splitsOf(
    uint256 _projectId,
    uint256 _domain,
    uint256 _group
  ) external view returns (JBSplit[] memory);

  function set(
    uint256 _projectId,
    uint256 _domain,
    JBGroupedSplits[] memory _groupedSplits
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IJBTokenUriResolver {
  function getUri(uint256 _projectId) external view returns (string memory tokenUri);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
  @notice
  Global constants used across Juicebox contracts.
*/
library JBConstants {
  uint256 public constant MAX_RESERVED_RATE = 10_000;
  uint256 public constant MAX_REDEMPTION_RATE = 10_000;
  uint256 public constant MAX_DISCOUNT_RATE = 1_000_000_000;
  uint256 public constant SPLITS_TOTAL_PERCENT = 1_000_000_000;
  uint256 public constant MAX_FEE = 1_000_000_000;
  uint256 public constant MAX_FEE_DISCOUNT = 1_000_000_000;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @notice Defines permissions as indicies in a uint256, as such, must be between 1 and 255.
 */
library JBOperations {
  uint256 public constant RECONFIGURE = 1;
  uint256 public constant REDEEM = 2;
  uint256 public constant MIGRATE_CONTROLLER = 3;
  uint256 public constant MIGRATE_TERMINAL = 4;
  uint256 public constant PROCESS_FEES = 5;
  uint256 public constant SET_METADATA = 6;
  uint256 public constant ISSUE = 7;
  uint256 public constant SET_TOKEN = 8;
  uint256 public constant MINT = 9;
  uint256 public constant BURN = 10;
  uint256 public constant CLAIM = 11;
  uint256 public constant TRANSFER = 12;
  uint256 public constant REQUIRE_CLAIM = 13; // unused in v3
  uint256 public constant SET_CONTROLLER = 14;
  uint256 public constant SET_TERMINALS = 15;
  uint256 public constant SET_PRIMARY_TERMINAL = 16;
  uint256 public constant USE_ALLOWANCE = 17;
  uint256 public constant SET_SPLITS = 18;
  uint256 public constant MANAGE_PAYMENTS = 254;
  uint256 public constant MANAGE_ROLES = 255;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library JBTokens {
  /** 
    @notice 
    The ETH token address in Juicebox is represented by 0x000000000000000000000000000000000000EEEe.
  */
  address public constant ETH = address(0x000000000000000000000000000000000000EEEe);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './JBTokenAmount.sol';

/** 
  @member payer The address from which the payment originated.
  @member projectId The ID of the project for which the payment was made.
  @member currentFundingCycleConfiguration The configuration of the funding cycle during which the payment is being made.
  @member amount The amount of the payment. Includes the token being paid, the value, the number of decimals included, and the currency of the amount.
  @member forwardedAmount The amount of the payment that is being sent to the delegate. Includes the token being paid, the value, the number of decimals included, and the currency of the amount.
  @member projectTokenCount The number of project tokens minted for the beneficiary.
  @member beneficiary The address to which the tokens were minted.
  @member preferClaimedTokens A flag indicating whether the request prefered to mint project tokens into the beneficiaries wallet rather than leaving them unclaimed. This is only possible if the project has an attached token contract.
  @member memo The memo that is being emitted alongside the payment.
  @member metadata Extra data to send to the delegate.
*/
struct JBDidPayData {
  address payer;
  uint256 projectId;
  uint256 currentFundingCycleConfiguration;
  JBTokenAmount amount;
  JBTokenAmount forwardedAmount;
  uint256 projectTokenCount;
  address beneficiary;
  bool preferClaimedTokens;
  string memo;
  bytes metadata;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './JBTokenAmount.sol';

/** 
  @member holder The holder of the tokens being redeemed.
  @member projectId The ID of the project with which the redeemed tokens are associated.
  @member currentFundingCycleConfiguration The configuration of the funding cycle during which the redemption is being made.
  @member projectTokenCount The number of project tokens being redeemed.
  @member reclaimedAmount The amount reclaimed from the treasury. Includes the token being reclaimed, the value, the number of decimals included, and the currency of the amount.
  @member forwardedAmount The amount of the payment that is being sent to the delegate. Includes the token being paid, the value, the number of decimals included, and the currency of the amount.
  @member beneficiary The address to which the reclaimed amount will be sent.
  @member memo The memo that is being emitted alongside the redemption.
  @member metadata Extra data to send to the delegate.
*/
struct JBDidRedeemData {
  address holder;
  uint256 projectId;
  uint256 currentFundingCycleConfiguration;
  uint256 projectTokenCount;
  JBTokenAmount reclaimedAmount;
  JBTokenAmount forwardedAmount;
  address payable beneficiary;
  string memo;
  bytes metadata;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './../interfaces/IJBFundingCycleBallot.sol';

/** 
  @member number The funding cycle number for the cycle's project. Each funding cycle has a number that is an increment of the cycle that directly preceded it. Each project's first funding cycle has a number of 1.
  @member configuration The timestamp when the parameters for this funding cycle were configured. This value will stay the same for subsequent funding cycles that roll over from an originally configured cycle.
  @member basedOn The `configuration` of the funding cycle that was active when this cycle was created.
  @member start The timestamp marking the moment from which the funding cycle is considered active. It is a unix timestamp measured in seconds.
  @member duration The number of seconds the funding cycle lasts for, after which a new funding cycle will start. A duration of 0 means that the funding cycle will stay active until the project owner explicitly issues a reconfiguration, at which point a new funding cycle will immediately start with the updated properties. If the duration is greater than 0, a project owner cannot make changes to a funding cycle's parameters while it is active – any proposed changes will apply to the subsequent cycle. If no changes are proposed, a funding cycle rolls over to another one with the same properties but new `start` timestamp and a discounted `weight`.
  @member weight A fixed point number with 18 decimals that contracts can use to base arbitrary calculations on. For example, payment terminals can use this to determine how many tokens should be minted when a payment is received.
  @member discountRate A percent by how much the `weight` of the subsequent funding cycle should be reduced, if the project owner hasn't configured the subsequent funding cycle with an explicit `weight`. If it's 0, each funding cycle will have equal weight. If the number is 90%, the next funding cycle will have a 10% smaller weight. This weight is out of `JBConstants.MAX_DISCOUNT_RATE`.
  @member ballot An address of a contract that says whether a proposed reconfiguration should be accepted or rejected. It can be used to create rules around how a project owner can change funding cycle parameters over time.
  @member metadata Extra data that can be associated with a funding cycle.
*/
struct JBFundingCycle {
  uint256 number;
  uint256 configuration;
  uint256 basedOn;
  uint256 start;
  uint256 duration;
  uint256 weight;
  uint256 discountRate;
  IJBFundingCycleBallot ballot;
  uint256 metadata;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './../interfaces/IJBFundingCycleBallot.sol';

/** 
  @member duration The number of seconds the funding cycle lasts for, after which a new funding cycle will start. A duration of 0 means that the funding cycle will stay active until the project owner explicitly issues a reconfiguration, at which point a new funding cycle will immediately start with the updated properties. If the duration is greater than 0, a project owner cannot make changes to a funding cycle's parameters while it is active – any proposed changes will apply to the subsequent cycle. If no changes are proposed, a funding cycle rolls over to another one with the same properties but new `start` timestamp and a discounted `weight`.
  @member weight A fixed point number with 18 decimals that contracts can use to base arbitrary calculations on. For example, payment terminals can use this to determine how many tokens should be minted when a payment is received.
  @member discountRate A percent by how much the `weight` of the subsequent funding cycle should be reduced, if the project owner hasn't configured the subsequent funding cycle with an explicit `weight`. If it's 0, each funding cycle will have equal weight. If the number is 90%, the next funding cycle will have a 10% smaller weight. This weight is out of `JBConstants.MAX_DISCOUNT_RATE`.
  @member ballot An address of a contract that says whether a proposed reconfiguration should be accepted or rejected. It can be used to create rules around how a project owner can change funding cycle parameters over time.
*/
struct JBFundingCycleData {
  uint256 duration;
  uint256 weight;
  uint256 discountRate;
  IJBFundingCycleBallot ballot;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './JBSplit.sol';

/** 
  @member group The group indentifier.
  @member splits The splits to associate with the group.
*/
struct JBGroupedSplits {
  uint256 group;
  JBSplit[] splits;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/** 
  @member operator The address of the operator.
  @member domain The domain within which the operator is being given permissions. A domain of 0 is a wildcard domain, which gives an operator access to all domains.
  @member permissionIndexes The indexes of the permissions the operator is being given.
*/
struct JBOperatorData {
  address operator;
  uint256 domain;
  uint256[] permissionIndexes;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../interfaces/IJBPayDelegate.sol';

/** 
 @member delegate A delegate contract to use for subsequent calls.
 @member amount The amount to send to the delegate.
*/
struct JBPayDelegateAllocation {
  IJBPayDelegate delegate;
  uint256 amount;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './../interfaces/IJBPaymentTerminal.sol';
import './JBTokenAmount.sol';

/** 
  @member terminal The terminal that is facilitating the payment.
  @member payer The address from which the payment originated.
  @member amount The amount of the payment. Includes the token being paid, the value, the number of decimals included, and the currency of the amount.
  @member projectId The ID of the project being paid.
  @member currentFundingCycleConfiguration The configuration of the funding cycle during which the payment is being made.
  @member beneficiary The specified address that should be the beneficiary of anything that results from the payment.
  @member weight The weight of the funding cycle during which the payment is being made.
  @member reservedRate The reserved rate of the funding cycle during which the payment is being made.
  @member memo The memo that was sent alongside the payment.
  @member metadata Extra data provided by the payer.
*/
struct JBPayParamsData {
  IJBPaymentTerminal terminal;
  address payer;
  JBTokenAmount amount;
  uint256 projectId;
  uint256 currentFundingCycleConfiguration;
  address beneficiary;
  uint256 weight;
  uint256 reservedRate;
  string memo;
  bytes metadata;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/** 
  @member content The metadata content.
  @member domain The domain within which the metadata applies.
*/
struct JBProjectMetadata {
  string content;
  uint256 domain;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './../interfaces/IJBPaymentTerminal.sol';
import './JBTokenAmount.sol';

/** 
  @member terminal The terminal that is facilitating the redemption.
  @member holder The holder of the tokens being redeemed.
  @member projectId The ID of the project whos tokens are being redeemed.
  @member currentFundingCycleConfiguration The configuration of the funding cycle during which the redemption is being made.
  @member tokenCount The proposed number of tokens being redeemed, as a fixed point number with 18 decimals.
  @member totalSupply The total supply of tokens used in the calculation, as a fixed point number with 18 decimals.
  @member overflow The amount of overflow used in the reclaim amount calculation.
  @member reclaimAmount The amount that should be reclaimed by the redeemer using the protocol's standard bonding curve redemption formula. Includes the token being reclaimed, the reclaim value, the number of decimals included, and the currency of the reclaim amount.
  @member useTotalOverflow If overflow across all of a project's terminals is being used when making redemptions.
  @member redemptionRate The redemption rate of the funding cycle during which the redemption is being made.
  @member memo The proposed memo that is being emitted alongside the redemption.
  @member metadata Extra data provided by the redeemer.
*/
struct JBRedeemParamsData {
  IJBPaymentTerminal terminal;
  address holder;
  uint256 projectId;
  uint256 currentFundingCycleConfiguration;
  uint256 tokenCount;
  uint256 totalSupply;
  uint256 overflow;
  JBTokenAmount reclaimAmount;
  bool useTotalOverflow;
  uint256 redemptionRate;
  string memo;
  bytes metadata;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../interfaces/IJBRedemptionDelegate.sol';

/** 
 @member delegate A delegate contract to use for subsequent calls.
 @member amount The amount to send to the delegate.
*/
struct JBRedemptionDelegateAllocation {
  IJBRedemptionDelegate delegate;
  uint256 amount;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './../interfaces/IJBSplitAllocator.sol';

/** 
  @member preferClaimed A flag that only has effect if a projectId is also specified, and the project has a token contract attached. If so, this flag indicates if the tokens that result from making a payment to the project should be delivered claimed into the beneficiary's wallet, or unclaimed to save gas.
  @member preferAddToBalance A flag indicating if a distribution to a project should prefer triggering it's addToBalance function instead of its pay function.
  @member percent The percent of the whole group that this split occupies. This number is out of `JBConstants.SPLITS_TOTAL_PERCENT`.
  @member projectId The ID of a project. If an allocator is not set but a projectId is set, funds will be sent to the protocol treasury belonging to the project who's ID is specified. Resulting tokens will be routed to the beneficiary with the claimed token preference respected.
  @member beneficiary An address. The role the of the beneficary depends on whether or not projectId is specified, and whether or not an allocator is specified. If allocator is set, the beneficiary will be forwarded to the allocator for it to use. If allocator is not set but projectId is set, the beneficiary is the address to which the project's tokens will be sent that result from a payment to it. If neither allocator or projectId are set, the beneficiary is where the funds from the split will be sent.
  @member lockedUntil Specifies if the split should be unchangeable until the specified time, with the exception of extending the locked period.
  @member allocator If an allocator is specified, funds will be sent to the allocator contract along with all properties of this split.
*/
struct JBSplit {
  bool preferClaimed;
  bool preferAddToBalance;
  uint256 percent;
  uint256 projectId;
  address payable beneficiary;
  uint256 lockedUntil;
  IJBSplitAllocator allocator;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './JBSplit.sol';

/** 
  @member token The token being sent to the split allocator.
  @member amount The amount being sent to the split allocator, as a fixed point number.
  @member decimals The number of decimals in the amount.
  @member projectId The project to which the split belongs.
  @member group The group to which the split belongs.
  @member split The split that caused the allocation.
*/
struct JBSplitAllocationData {
  address token;
  uint256 amount;
  uint256 decimals;
  uint256 projectId;
  uint256 group;
  JBSplit split;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/* 
  @member token The token the payment was made in.
  @member value The amount of tokens that was paid, as a fixed point number.
  @member decimals The number of decimals included in the value fixed point number.
  @member currency The expected currency of the value.
**/
struct JBTokenAmount {
  address token;
  uint256 value;
  uint256 decimals;
  uint256 currency;
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4;

/// @notice Emitted when the result overflows uint256.
error PRBMath__MulDivFixedPointOverflow(uint256 prod1);

/// @notice Emitted when the result overflows uint256.
error PRBMath__MulDivOverflow(uint256 prod1, uint256 denominator);

/// @notice Emitted when one of the inputs is type(int256).min.
error PRBMath__MulDivSignedInputTooSmall();

/// @notice Emitted when the intermediary absolute result overflows int256.
error PRBMath__MulDivSignedOverflow(uint256 rAbs);

/// @notice Emitted when the input is MIN_SD59x18.
error PRBMathSD59x18__AbsInputTooSmall();

/// @notice Emitted when ceiling a number overflows SD59x18.
error PRBMathSD59x18__CeilOverflow(int256 x);

/// @notice Emitted when one of the inputs is MIN_SD59x18.
error PRBMathSD59x18__DivInputTooSmall();

/// @notice Emitted when one of the intermediary unsigned results overflows SD59x18.
error PRBMathSD59x18__DivOverflow(uint256 rAbs);

/// @notice Emitted when the input is greater than 133.084258667509499441.
error PRBMathSD59x18__ExpInputTooBig(int256 x);

/// @notice Emitted when the input is greater than 192.
error PRBMathSD59x18__Exp2InputTooBig(int256 x);

/// @notice Emitted when flooring a number underflows SD59x18.
error PRBMathSD59x18__FloorUnderflow(int256 x);

/// @notice Emitted when converting a basic integer to the fixed-point format overflows SD59x18.
error PRBMathSD59x18__FromIntOverflow(int256 x);

/// @notice Emitted when converting a basic integer to the fixed-point format underflows SD59x18.
error PRBMathSD59x18__FromIntUnderflow(int256 x);

/// @notice Emitted when the product of the inputs is negative.
error PRBMathSD59x18__GmNegativeProduct(int256 x, int256 y);

/// @notice Emitted when multiplying the inputs overflows SD59x18.
error PRBMathSD59x18__GmOverflow(int256 x, int256 y);

/// @notice Emitted when the input is less than or equal to zero.
error PRBMathSD59x18__LogInputTooSmall(int256 x);

/// @notice Emitted when one of the inputs is MIN_SD59x18.
error PRBMathSD59x18__MulInputTooSmall();

/// @notice Emitted when the intermediary absolute result overflows SD59x18.
error PRBMathSD59x18__MulOverflow(uint256 rAbs);

/// @notice Emitted when the intermediary absolute result overflows SD59x18.
error PRBMathSD59x18__PowuOverflow(uint256 rAbs);

/// @notice Emitted when the input is negative.
error PRBMathSD59x18__SqrtNegativeInput(int256 x);

/// @notice Emitted when the calculating the square root overflows SD59x18.
error PRBMathSD59x18__SqrtOverflow(int256 x);

/// @notice Emitted when addition overflows UD60x18.
error PRBMathUD60x18__AddOverflow(uint256 x, uint256 y);

/// @notice Emitted when ceiling a number overflows UD60x18.
error PRBMathUD60x18__CeilOverflow(uint256 x);

/// @notice Emitted when the input is greater than 133.084258667509499441.
error PRBMathUD60x18__ExpInputTooBig(uint256 x);

/// @notice Emitted when the input is greater than 192.
error PRBMathUD60x18__Exp2InputTooBig(uint256 x);

/// @notice Emitted when converting a basic integer to the fixed-point format format overflows UD60x18.
error PRBMathUD60x18__FromUintOverflow(uint256 x);

/// @notice Emitted when multiplying the inputs overflows UD60x18.
error PRBMathUD60x18__GmOverflow(uint256 x, uint256 y);

/// @notice Emitted when the input is less than 1.
error PRBMathUD60x18__LogInputTooSmall(uint256 x);

/// @notice Emitted when the calculating the square root overflows UD60x18.
error PRBMathUD60x18__SqrtOverflow(uint256 x);

/// @notice Emitted when subtraction underflows UD60x18.
error PRBMathUD60x18__SubUnderflow(uint256 x, uint256 y);

/// @dev Common mathematical functions used in both PRBMathSD59x18 and PRBMathUD60x18. Note that this shared library
/// does not always assume the signed 59.18-decimal fixed-point or the unsigned 60.18-decimal fixed-point
/// representation. When it does not, it is explicitly mentioned in the NatSpec documentation.
library PRBMath {
    /// STRUCTS ///

    struct SD59x18 {
        int256 value;
    }

    struct UD60x18 {
        uint256 value;
    }

    /// STORAGE ///

    /// @dev How many trailing decimals can be represented.
    uint256 internal constant SCALE = 1e18;

    /// @dev Largest power of two divisor of SCALE.
    uint256 internal constant SCALE_LPOTD = 262144;

    /// @dev SCALE inverted mod 2^256.
    uint256 internal constant SCALE_INVERSE =
        78156646155174841979727994598816262306175212592076161876661_508869554232690281;

    /// FUNCTIONS ///

    /// @notice Calculates the binary exponent of x using the binary fraction method.
    /// @dev Has to use 192.64-bit fixed-point numbers.
    /// See https://ethereum.stackexchange.com/a/96594/24693.
    /// @param x The exponent as an unsigned 192.64-bit fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function exp2(uint256 x) internal pure returns (uint256 result) {
        unchecked {
            // Start from 0.5 in the 192.64-bit fixed-point format.
            result = 0x800000000000000000000000000000000000000000000000;

            // Multiply the result by root(2, 2^-i) when the bit at position i is 1. None of the intermediary results overflows
            // because the initial result is 2^191 and all magic factors are less than 2^65.
            if (x & 0x8000000000000000 > 0) {
                result = (result * 0x16A09E667F3BCC909) >> 64;
            }
            if (x & 0x4000000000000000 > 0) {
                result = (result * 0x1306FE0A31B7152DF) >> 64;
            }
            if (x & 0x2000000000000000 > 0) {
                result = (result * 0x1172B83C7D517ADCE) >> 64;
            }
            if (x & 0x1000000000000000 > 0) {
                result = (result * 0x10B5586CF9890F62A) >> 64;
            }
            if (x & 0x800000000000000 > 0) {
                result = (result * 0x1059B0D31585743AE) >> 64;
            }
            if (x & 0x400000000000000 > 0) {
                result = (result * 0x102C9A3E778060EE7) >> 64;
            }
            if (x & 0x200000000000000 > 0) {
                result = (result * 0x10163DA9FB33356D8) >> 64;
            }
            if (x & 0x100000000000000 > 0) {
                result = (result * 0x100B1AFA5ABCBED61) >> 64;
            }
            if (x & 0x80000000000000 > 0) {
                result = (result * 0x10058C86DA1C09EA2) >> 64;
            }
            if (x & 0x40000000000000 > 0) {
                result = (result * 0x1002C605E2E8CEC50) >> 64;
            }
            if (x & 0x20000000000000 > 0) {
                result = (result * 0x100162F3904051FA1) >> 64;
            }
            if (x & 0x10000000000000 > 0) {
                result = (result * 0x1000B175EFFDC76BA) >> 64;
            }
            if (x & 0x8000000000000 > 0) {
                result = (result * 0x100058BA01FB9F96D) >> 64;
            }
            if (x & 0x4000000000000 > 0) {
                result = (result * 0x10002C5CC37DA9492) >> 64;
            }
            if (x & 0x2000000000000 > 0) {
                result = (result * 0x1000162E525EE0547) >> 64;
            }
            if (x & 0x1000000000000 > 0) {
                result = (result * 0x10000B17255775C04) >> 64;
            }
            if (x & 0x800000000000 > 0) {
                result = (result * 0x1000058B91B5BC9AE) >> 64;
            }
            if (x & 0x400000000000 > 0) {
                result = (result * 0x100002C5C89D5EC6D) >> 64;
            }
            if (x & 0x200000000000 > 0) {
                result = (result * 0x10000162E43F4F831) >> 64;
            }
            if (x & 0x100000000000 > 0) {
                result = (result * 0x100000B1721BCFC9A) >> 64;
            }
            if (x & 0x80000000000 > 0) {
                result = (result * 0x10000058B90CF1E6E) >> 64;
            }
            if (x & 0x40000000000 > 0) {
                result = (result * 0x1000002C5C863B73F) >> 64;
            }
            if (x & 0x20000000000 > 0) {
                result = (result * 0x100000162E430E5A2) >> 64;
            }
            if (x & 0x10000000000 > 0) {
                result = (result * 0x1000000B172183551) >> 64;
            }
            if (x & 0x8000000000 > 0) {
                result = (result * 0x100000058B90C0B49) >> 64;
            }
            if (x & 0x4000000000 > 0) {
                result = (result * 0x10000002C5C8601CC) >> 64;
            }
            if (x & 0x2000000000 > 0) {
                result = (result * 0x1000000162E42FFF0) >> 64;
            }
            if (x & 0x1000000000 > 0) {
                result = (result * 0x10000000B17217FBB) >> 64;
            }
            if (x & 0x800000000 > 0) {
                result = (result * 0x1000000058B90BFCE) >> 64;
            }
            if (x & 0x400000000 > 0) {
                result = (result * 0x100000002C5C85FE3) >> 64;
            }
            if (x & 0x200000000 > 0) {
                result = (result * 0x10000000162E42FF1) >> 64;
            }
            if (x & 0x100000000 > 0) {
                result = (result * 0x100000000B17217F8) >> 64;
            }
            if (x & 0x80000000 > 0) {
                result = (result * 0x10000000058B90BFC) >> 64;
            }
            if (x & 0x40000000 > 0) {
                result = (result * 0x1000000002C5C85FE) >> 64;
            }
            if (x & 0x20000000 > 0) {
                result = (result * 0x100000000162E42FF) >> 64;
            }
            if (x & 0x10000000 > 0) {
                result = (result * 0x1000000000B17217F) >> 64;
            }
            if (x & 0x8000000 > 0) {
                result = (result * 0x100000000058B90C0) >> 64;
            }
            if (x & 0x4000000 > 0) {
                result = (result * 0x10000000002C5C860) >> 64;
            }
            if (x & 0x2000000 > 0) {
                result = (result * 0x1000000000162E430) >> 64;
            }
            if (x & 0x1000000 > 0) {
                result = (result * 0x10000000000B17218) >> 64;
            }
            if (x & 0x800000 > 0) {
                result = (result * 0x1000000000058B90C) >> 64;
            }
            if (x & 0x400000 > 0) {
                result = (result * 0x100000000002C5C86) >> 64;
            }
            if (x & 0x200000 > 0) {
                result = (result * 0x10000000000162E43) >> 64;
            }
            if (x & 0x100000 > 0) {
                result = (result * 0x100000000000B1721) >> 64;
            }
            if (x & 0x80000 > 0) {
                result = (result * 0x10000000000058B91) >> 64;
            }
            if (x & 0x40000 > 0) {
                result = (result * 0x1000000000002C5C8) >> 64;
            }
            if (x & 0x20000 > 0) {
                result = (result * 0x100000000000162E4) >> 64;
            }
            if (x & 0x10000 > 0) {
                result = (result * 0x1000000000000B172) >> 64;
            }
            if (x & 0x8000 > 0) {
                result = (result * 0x100000000000058B9) >> 64;
            }
            if (x & 0x4000 > 0) {
                result = (result * 0x10000000000002C5D) >> 64;
            }
            if (x & 0x2000 > 0) {
                result = (result * 0x1000000000000162E) >> 64;
            }
            if (x & 0x1000 > 0) {
                result = (result * 0x10000000000000B17) >> 64;
            }
            if (x & 0x800 > 0) {
                result = (result * 0x1000000000000058C) >> 64;
            }
            if (x & 0x400 > 0) {
                result = (result * 0x100000000000002C6) >> 64;
            }
            if (x & 0x200 > 0) {
                result = (result * 0x10000000000000163) >> 64;
            }
            if (x & 0x100 > 0) {
                result = (result * 0x100000000000000B1) >> 64;
            }
            if (x & 0x80 > 0) {
                result = (result * 0x10000000000000059) >> 64;
            }
            if (x & 0x40 > 0) {
                result = (result * 0x1000000000000002C) >> 64;
            }
            if (x & 0x20 > 0) {
                result = (result * 0x10000000000000016) >> 64;
            }
            if (x & 0x10 > 0) {
                result = (result * 0x1000000000000000B) >> 64;
            }
            if (x & 0x8 > 0) {
                result = (result * 0x10000000000000006) >> 64;
            }
            if (x & 0x4 > 0) {
                result = (result * 0x10000000000000003) >> 64;
            }
            if (x & 0x2 > 0) {
                result = (result * 0x10000000000000001) >> 64;
            }
            if (x & 0x1 > 0) {
                result = (result * 0x10000000000000001) >> 64;
            }

            // We're doing two things at the same time:
            //
            //   1. Multiply the result by 2^n + 1, where "2^n" is the integer part and the one is added to account for
            //      the fact that we initially set the result to 0.5. This is accomplished by subtracting from 191
            //      rather than 192.
            //   2. Convert the result to the unsigned 60.18-decimal fixed-point format.
            //
            // This works because 2^(191-ip) = 2^ip / 2^191, where "ip" is the integer part "2^n".
            result *= SCALE;
            result >>= (191 - (x >> 64));
        }
    }

    /// @notice Finds the zero-based index of the first one in the binary representation of x.
    /// @dev See the note on msb in the "Find First Set" Wikipedia article https://en.wikipedia.org/wiki/Find_first_set
    /// @param x The uint256 number for which to find the index of the most significant bit.
    /// @return msb The index of the most significant bit as an uint256.
    function mostSignificantBit(uint256 x) internal pure returns (uint256 msb) {
        if (x >= 2**128) {
            x >>= 128;
            msb += 128;
        }
        if (x >= 2**64) {
            x >>= 64;
            msb += 64;
        }
        if (x >= 2**32) {
            x >>= 32;
            msb += 32;
        }
        if (x >= 2**16) {
            x >>= 16;
            msb += 16;
        }
        if (x >= 2**8) {
            x >>= 8;
            msb += 8;
        }
        if (x >= 2**4) {
            x >>= 4;
            msb += 4;
        }
        if (x >= 2**2) {
            x >>= 2;
            msb += 2;
        }
        if (x >= 2**1) {
            // No need to shift x any more.
            msb += 1;
        }
    }

    /// @notice Calculates floor(x*y÷denominator) with full precision.
    ///
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv.
    ///
    /// Requirements:
    /// - The denominator cannot be zero.
    /// - The result must fit within uint256.
    ///
    /// Caveats:
    /// - This function does not work with fixed-point numbers.
    ///
    /// @param x The multiplicand as an uint256.
    /// @param y The multiplier as an uint256.
    /// @param denominator The divisor as an uint256.
    /// @return result The result as an uint256.
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
        // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2^256 + prod0.
        uint256 prod0; // Least significant 256 bits of the product
        uint256 prod1; // Most significant 256 bits of the product
        assembly {
            let mm := mulmod(x, y, not(0))
            prod0 := mul(x, y)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        // Handle non-overflow cases, 256 by 256 division.
        if (prod1 == 0) {
            unchecked {
                result = prod0 / denominator;
            }
            return result;
        }

        // Make sure the result is less than 2^256. Also prevents denominator == 0.
        if (prod1 >= denominator) {
            revert PRBMath__MulDivOverflow(prod1, denominator);
        }

        ///////////////////////////////////////////////
        // 512 by 256 division.
        ///////////////////////////////////////////////

        // Make division exact by subtracting the remainder from [prod1 prod0].
        uint256 remainder;
        assembly {
            // Compute remainder using mulmod.
            remainder := mulmod(x, y, denominator)

            // Subtract 256 bit number from 512 bit number.
            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
        // See https://cs.stackexchange.com/q/138556/92363.
        unchecked {
            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 lpotdod = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by lpotdod.
                denominator := div(denominator, lpotdod)

                // Divide [prod1 prod0] by lpotdod.
                prod0 := div(prod0, lpotdod)

                // Flip lpotdod such that it is 2^256 / lpotdod. If lpotdod is zero, then it becomes one.
                lpotdod := add(div(sub(0, lpotdod), lpotdod), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * lpotdod;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /// @notice Calculates floor(x*y÷1e18) with full precision.
    ///
    /// @dev Variant of "mulDiv" with constant folding, i.e. in which the denominator is always 1e18. Before returning the
    /// final result, we add 1 if (x * y) % SCALE >= HALF_SCALE. Without this, 6.6e-19 would be truncated to 0 instead of
    /// being rounded to 1e-18.  See "Listing 6" and text above it at https://accu.org/index.php/journals/1717.
    ///
    /// Requirements:
    /// - The result must fit within uint256.
    ///
    /// Caveats:
    /// - The body is purposely left uncommented; see the NatSpec comments in "PRBMath.mulDiv" to understand how this works.
    /// - It is assumed that the result can never be type(uint256).max when x and y solve the following two equations:
    ///     1. x * y = type(uint256).max * SCALE
    ///     2. (x * y) % SCALE >= SCALE / 2
    ///
    /// @param x The multiplicand as an unsigned 60.18-decimal fixed-point number.
    /// @param y The multiplier as an unsigned 60.18-decimal fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function mulDivFixedPoint(uint256 x, uint256 y) internal pure returns (uint256 result) {
        uint256 prod0;
        uint256 prod1;
        assembly {
            let mm := mulmod(x, y, not(0))
            prod0 := mul(x, y)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        if (prod1 >= SCALE) {
            revert PRBMath__MulDivFixedPointOverflow(prod1);
        }

        uint256 remainder;
        uint256 roundUpUnit;
        assembly {
            remainder := mulmod(x, y, SCALE)
            roundUpUnit := gt(remainder, 499999999999999999)
        }

        if (prod1 == 0) {
            unchecked {
                result = (prod0 / SCALE) + roundUpUnit;
                return result;
            }
        }

        assembly {
            result := add(
                mul(
                    or(
                        div(sub(prod0, remainder), SCALE_LPOTD),
                        mul(sub(prod1, gt(remainder, prod0)), add(div(sub(0, SCALE_LPOTD), SCALE_LPOTD), 1))
                    ),
                    SCALE_INVERSE
                ),
                roundUpUnit
            )
        }
    }

    /// @notice Calculates floor(x*y÷denominator) with full precision.
    ///
    /// @dev An extension of "mulDiv" for signed numbers. Works by computing the signs and the absolute values separately.
    ///
    /// Requirements:
    /// - None of the inputs can be type(int256).min.
    /// - The result must fit within int256.
    ///
    /// @param x The multiplicand as an int256.
    /// @param y The multiplier as an int256.
    /// @param denominator The divisor as an int256.
    /// @return result The result as an int256.
    function mulDivSigned(
        int256 x,
        int256 y,
        int256 denominator
    ) internal pure returns (int256 result) {
        if (x == type(int256).min || y == type(int256).min || denominator == type(int256).min) {
            revert PRBMath__MulDivSignedInputTooSmall();
        }

        // Get hold of the absolute values of x, y and the denominator.
        uint256 ax;
        uint256 ay;
        uint256 ad;
        unchecked {
            ax = x < 0 ? uint256(-x) : uint256(x);
            ay = y < 0 ? uint256(-y) : uint256(y);
            ad = denominator < 0 ? uint256(-denominator) : uint256(denominator);
        }

        // Compute the absolute value of (x*y)÷denominator. The result must fit within int256.
        uint256 rAbs = mulDiv(ax, ay, ad);
        if (rAbs > uint256(type(int256).max)) {
            revert PRBMath__MulDivSignedOverflow(rAbs);
        }

        // Get the signs of x, y and the denominator.
        uint256 sx;
        uint256 sy;
        uint256 sd;
        assembly {
            sx := sgt(x, sub(0, 1))
            sy := sgt(y, sub(0, 1))
            sd := sgt(denominator, sub(0, 1))
        }

        // XOR over sx, sy and sd. This is checking whether there are one or three negative signs in the inputs.
        // If yes, the result should be negative.
        result = sx ^ sy ^ sd == 0 ? -int256(rAbs) : int256(rAbs);
    }

    /// @notice Calculates the square root of x, rounding down.
    /// @dev Uses the Babylonian method https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method.
    ///
    /// Caveats:
    /// - This function does not work with fixed-point numbers.
    ///
    /// @param x The uint256 number for which to calculate the square root.
    /// @return result The result as an uint256.
    function sqrt(uint256 x) internal pure returns (uint256 result) {
        if (x == 0) {
            return 0;
        }

        // Set the initial guess to the least power of two that is greater than or equal to sqrt(x).
        uint256 xAux = uint256(x);
        result = 1;
        if (xAux >= 0x100000000000000000000000000000000) {
            xAux >>= 128;
            result <<= 64;
        }
        if (xAux >= 0x10000000000000000) {
            xAux >>= 64;
            result <<= 32;
        }
        if (xAux >= 0x100000000) {
            xAux >>= 32;
            result <<= 16;
        }
        if (xAux >= 0x10000) {
            xAux >>= 16;
            result <<= 8;
        }
        if (xAux >= 0x100) {
            xAux >>= 8;
            result <<= 4;
        }
        if (xAux >= 0x10) {
            xAux >>= 4;
            result <<= 2;
        }
        if (xAux >= 0x8) {
            result <<= 1;
        }

        // The operations can never overflow because the result is max 2^127 when it enters this block.
        unchecked {
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1; // Seven iterations should be enough
            uint256 roundedDownResult = x / result;
            return result >= roundedDownResult ? roundedDownResult : result;
        }
    }
}