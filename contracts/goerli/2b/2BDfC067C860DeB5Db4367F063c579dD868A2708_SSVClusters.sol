// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import "../interfaces/functions/IFnSSVClusters.sol";
import "../interfaces/events/IEvSSVClusters.sol";
import "../libraries/Types.sol";
import "../libraries/ClusterLib.sol";
import "../libraries/OperatorLib.sol";
import "../libraries/DAOLib.sol";
import "../libraries/NetworkLib.sol";
import "../libraries/CoreLib.sol";
import "../libraries/SSVStorage.sol";

contract SSVClusters is IFnSSVClusters, IEvSSVClusters {
    using ClusterLib for Cluster;
    using OperatorLib for Operator;
    using NetworkLib for Network;
    using DAOLib for DAO;

    uint64 private constant MIN_OPERATORS_LENGTH = 4;
    uint64 private constant MAX_OPERATORS_LENGTH = 13;
    uint64 private constant MODULO_OPERATORS_LENGTH = 3;
    uint64 private constant PUBLIC_KEY_LENGTH = 48;

    function registerValidator(
        bytes calldata publicKey,
        uint64[] memory operatorIds,
        bytes calldata sharesData,
        uint256 amount,
        Cluster memory cluster
    ) external override {
        StorageData storage s = SSVStorage.load();

        uint operatorsLength = operatorIds.length;
        {
            if (
                operatorsLength < MIN_OPERATORS_LENGTH ||
                operatorsLength > MAX_OPERATORS_LENGTH ||
                operatorsLength % MODULO_OPERATORS_LENGTH != 1
            ) {
                revert InvalidOperatorIdsLength();
            }

            if (publicKey.length != PUBLIC_KEY_LENGTH) revert InvalidPublicKeyLength();

            bytes32 hashedPk = keccak256(abi.encodePacked(publicKey, msg.sender));

            if (s.validatorPKs[hashedPk].hashedOperatorIds != bytes32(0)) {
                revert ValidatorAlreadyExists();
            }

            s.validatorPKs[hashedPk] = Validator({
                hashedOperatorIds: keccak256(abi.encodePacked(operatorIds)),
                active: true
            });
        }
        bytes32 hashedCluster = keccak256(abi.encodePacked(msg.sender, operatorIds));

        {
            bytes32 clusterData = s.clusters[hashedCluster];
            if (clusterData == bytes32(0)) {
                if (
                    cluster.validatorCount != 0 ||
                    cluster.networkFeeIndex != 0 ||
                    cluster.index != 0 ||
                    cluster.balance != 0 ||
                    !cluster.active
                ) {
                    revert IncorrectClusterState();
                }
            } else if (clusterData != cluster.hashClusterData()) {
                revert IncorrectClusterState();
            } else {
                cluster.validateClusterIsNotLiquidated();
            }
        }

        cluster.balance += amount;

        uint64 burnRate;

        if (cluster.active) {
            uint64 clusterIndex;

            for (uint i; i < operatorsLength; ) {
                uint64 operatorId = operatorIds[i];
                {
                    if (i + 1 < operatorsLength) {
                        if (operatorId > operatorIds[i + 1]) {
                            revert UnsortedOperatorsList();
                        } else if (operatorId == operatorIds[i + 1]) {
                            revert OperatorsListNotUnique();
                        }
                    }
                }

                Operator memory operator = s.operators[operatorId];
                if (operator.snapshot.block == 0) {
                    revert OperatorDoesNotExist();
                }
                if (
                    operator.whitelisted &&
                    s.operatorsWhitelist[operatorId] != address(0) &&
                    s.operatorsWhitelist[operatorId] != msg.sender
                ) {
                    revert CallerNotWhitelisted();
                }
                operator.updateSnapshot();
                if (++operator.validatorCount > s.validatorsPerOperatorLimit) {
                    revert ExceedValidatorLimit();
                }
                clusterIndex += operator.snapshot.index;
                burnRate += operator.fee;

                s.operators[operatorId] = operator;

                unchecked {
                    ++i;
                }
            }
            cluster.updateClusterData(clusterIndex, s.network.currentNetworkFeeIndex());

            s.dao.updateDAO(true, 1);
        }

        ++cluster.validatorCount;

        if (
            cluster.isLiquidatable(
                burnRate,
                s.network.networkFee,
                s.minimumBlocksBeforeLiquidation,
                s.minimumLiquidationCollateral
            )
        ) {
            revert InsufficientBalance();
        }

        s.clusters[hashedCluster] = cluster.hashClusterData();

        if (amount != 0) {
            CoreLib.deposit(amount);
        }

        emit ValidatorAdded(msg.sender, operatorIds, publicKey, sharesData, cluster);
    }

    function removeValidator(
        bytes calldata publicKey,
        uint64[] calldata operatorIds,
        Cluster memory cluster
    ) external override {
        StorageData storage s = SSVStorage.load();

        bytes32 hashedValidator = keccak256(abi.encodePacked(publicKey, msg.sender));

        bytes32 validatorHashedOpsIds = s.validatorPKs[hashedValidator].hashedOperatorIds;

        if (validatorHashedOpsIds == bytes32(0)) {
            revert ValidatorDoesNotExist();
        } else if (validatorHashedOpsIds != keccak256(abi.encodePacked(operatorIds))) {
            revert IncorrectValidatorState();
        }

        bytes32 hashedCluster = cluster.validateHashedCluster(msg.sender, operatorIds);

        {
            if (cluster.active) {
                (uint64 clusterIndex, ) = OperatorLib.updateOperators(operatorIds, false, 1, s);

                cluster.updateClusterData(clusterIndex, s.network.currentNetworkFeeIndex());

                s.dao.updateDAO(false, 1);
            }
        }

        --cluster.validatorCount;

        delete s.validatorPKs[hashedValidator];

        s.clusters[hashedCluster] = cluster.hashClusterData();

        emit ValidatorRemoved(msg.sender, operatorIds, publicKey, cluster);
    }

    function liquidate(address owner, uint64[] memory operatorIds, Cluster memory cluster) external override {
        bytes32 hashedCluster = cluster.validateHashedCluster(owner, operatorIds);
        cluster.validateClusterIsNotLiquidated();

        StorageData storage s = SSVStorage.load();

        (uint64 clusterIndex, uint64 burnRate) = OperatorLib.updateOperators(
            operatorIds,
            false,
            cluster.validatorCount,
            s
        );

        cluster.updateBalance(clusterIndex, s.network.currentNetworkFeeIndex());

        uint256 balanceLiquidatable;

        if (
            owner != msg.sender &&
            !cluster.isLiquidatable(
                burnRate,
                s.network.networkFee,
                s.minimumBlocksBeforeLiquidation,
                s.minimumLiquidationCollateral
            )
        ) {
            revert ClusterNotLiquidatable();
        }

        s.dao.updateDAO(false, cluster.validatorCount);

        if (cluster.balance != 0) {
            balanceLiquidatable = cluster.balance;
            cluster.balance = 0;
        }
        cluster.index = 0;
        cluster.networkFeeIndex = 0;
        cluster.active = false;

        s.clusters[hashedCluster] = cluster.hashClusterData();

        if (balanceLiquidatable != 0) {
            CoreLib.transferBalance(msg.sender, balanceLiquidatable);
        }

        emit ClusterLiquidated(owner, operatorIds, cluster);
    }

    function reactivate(uint64[] calldata operatorIds, uint256 amount, Cluster memory cluster) external override {
        bytes32 hashedCluster = cluster.validateHashedCluster(msg.sender, operatorIds);
        if (cluster.active) revert ClusterAlreadyEnabled();

        StorageData storage s = SSVStorage.load();

        (uint64 clusterIndex, uint64 burnRate) = OperatorLib.updateOperators(operatorIds, true, cluster.validatorCount, s);

        cluster.balance += amount;
        cluster.active = true;
        cluster.index = clusterIndex;
        cluster.networkFeeIndex = s.network.currentNetworkFeeIndex();

        uint64 networkFee = s.network.networkFee;

        s.dao.updateDAO(true, cluster.validatorCount);

        if (
            cluster.isLiquidatable(
                burnRate,
                networkFee,
                s.minimumBlocksBeforeLiquidation,
                s.minimumLiquidationCollateral
            )
        ) {
            revert InsufficientBalance();
        }

        s.clusters[hashedCluster] = cluster.hashClusterData();

        if (amount > 0) {
            CoreLib.deposit(amount);
        }

        emit ClusterReactivated(msg.sender, operatorIds, cluster);
    }

    function deposit(
        address owner,
        uint64[] calldata operatorIds,
        uint256 amount,
        Cluster memory cluster
    ) external override {
        bytes32 hashedCluster = cluster.validateHashedCluster(owner, operatorIds);

        cluster.balance += amount;

        SSVStorage.load().clusters[hashedCluster] = cluster.hashClusterData();

        CoreLib.deposit(amount);

        emit ClusterDeposited(owner, operatorIds, amount, cluster);
    }

    function withdraw(uint64[] calldata operatorIds, uint256 amount, Cluster memory cluster) external override {
        bytes32 hashedCluster = cluster.validateHashedCluster(msg.sender, operatorIds);
        cluster.validateClusterIsNotLiquidated();

        StorageData storage s = SSVStorage.load();

        uint64 burnRate;
        if (cluster.active) {
            uint64 clusterIndex;
            {
                uint operatorsLength = operatorIds.length;
                for (uint i; i < operatorsLength; ) {
                    Operator storage operator = SSVStorage.load().operators[operatorIds[i]];
                    clusterIndex +=
                        operator.snapshot.index +
                        (uint64(block.number) - operator.snapshot.block) *
                        operator.fee;
                    burnRate += operator.fee;
                    unchecked {
                        ++i;
                    }
                }
            }

            cluster.updateClusterData(clusterIndex, s.network.currentNetworkFeeIndex());
        }
        if (cluster.balance < amount) revert InsufficientBalance();

        cluster.balance -= amount;

        if (
            cluster.active &&
            cluster.validatorCount != 0 &&
            cluster.isLiquidatable(
                burnRate,
                s.network.networkFee,
                s.minimumBlocksBeforeLiquidation,
                s.minimumLiquidationCollateral
            )
        ) {
            revert InsufficientBalance();
        }

        s.clusters[hashedCluster] = cluster.hashClusterData();

        CoreLib.transferBalance(msg.sender, amount);

        emit ClusterWithdrawn(msg.sender, operatorIds, amount, cluster);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (access/Ownable2Step.sol)

pragma solidity ^0.8.0;

import "./OwnableUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership} and {acceptOwnership}.
 *
 * This module is used through inheritance. It will make available all functions
 * from parent (Ownable).
 */
abstract contract Ownable2StepUpgradeable is Initializable, OwnableUpgradeable {
    function __Ownable2Step_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable2Step_init_unchained() internal onlyInitializing {
    }
    address private _pendingOwner;

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual override {
        delete _pendingOwner;
        super._transferOwnership(newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwnership() external {
        address sender = _msgSender();
        require(pendingOwner() == sender, "Ownable2Step: caller is not the new owner");
        _transferOwnership(sender);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
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
// OpenZeppelin Contracts (last updated v4.8.3) (interfaces/IERC1967.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC-1967: Proxy Storage Slots. This interface contains the events defined in the ERC.
 *
 * _Available since v4.9._
 */
interface IERC1967Upgradeable {
    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Emitted when the beacon is changed.
     */
    event BeaconUpgraded(address indexed beacon);
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
// OpenZeppelin Contracts (last updated v4.8.3) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../interfaces/IERC1967Upgradeable.sol";
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
abstract contract ERC1967UpgradeUpgradeable is Initializable, IERC1967Upgradeable {
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
library Counters {
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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import "../ISSVNetworkCore.sol";

interface IEvSSVClusters is ISSVNetworkCore {
    /**
     * @dev Emitted when the validator has been added.
     * @param publicKey The public key of a validator.
     * @param operatorIds The operator ids list.
     * @param shares snappy compressed shares(a set of encrypted and public shares).
     * @param cluster All the cluster data.
     */
    event ValidatorAdded(address indexed owner, uint64[] operatorIds, bytes publicKey, bytes shares, Cluster cluster);

    /**
     * @dev Emitted when the validator is removed.
     * @param publicKey The public key of a validator.
     * @param operatorIds The operator ids list.
     * @param cluster All the cluster data.
     */
    event ValidatorRemoved(address indexed owner, uint64[] operatorIds, bytes publicKey, Cluster cluster);

    event ClusterLiquidated(address indexed owner, uint64[] operatorIds, Cluster cluster);

    event ClusterReactivated(address indexed owner, uint64[] operatorIds, Cluster cluster);

    event ClusterWithdrawn(address indexed owner, uint64[] operatorIds, uint256 value, Cluster cluster);

    event ClusterDeposited(address indexed owner, uint64[] operatorIds, uint256 value, Cluster cluster);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

interface IEvSSVDAO {
    event OperatorFeeIncreaseLimitUpdated(uint64 value);

    event DeclareOperatorFeePeriodUpdated(uint64 value);

    event ExecuteOperatorFeePeriodUpdated(uint64 value);

    event LiquidationThresholdPeriodUpdated(uint64 value);

    event MinimumLiquidationCollateralUpdated(uint256 value);

     /**
     * @dev Emitted when the network fee is updated.
     * @param oldFee The old fee
     * @param newFee The new fee
     */
    event NetworkFeeUpdated(uint256 oldFee, uint256 newFee);

    /**
     * @dev Emitted when transfer fees are withdrawn.
     * @param value The amount of tokens withdrawn.
     * @param recipient The recipient address.
     */
    event NetworkEarningsWithdrawn(uint256 value, address recipient);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import "./../ISSVNetworkCore.sol";

interface IEvSSVOperators is ISSVNetworkCore {
    /**
     * @dev Emitted when a new operator has been added.
     * @param operatorId operator's ID.
     * @param owner Operator's ethereum address that can collect fees.
     * @param publicKey Operator's public key. Will be used to encrypt secret shares of validators keys.
     * @param fee Operator's fee.
     */
    event OperatorAdded(uint64 indexed operatorId, address indexed owner, bytes publicKey, uint256 fee);

    /**
     * @dev Emitted when operator has been removed.
     * @param operatorId operator's ID.
     */
    event OperatorRemoved(uint64 indexed operatorId);

    /**
     * @dev Emitted when the whitelist of an operator is updated.
     * @param operatorId operator's ID.
     * @param whitelisted operator's new whitelisted address.
     */
    event OperatorWhitelistUpdated(uint64 indexed operatorId, address whitelisted);
    event OperatorFeeDeclared(address indexed owner, uint64 indexed operatorId, uint256 blockNumber, uint256 fee);

    event OperatorFeeCancellationDeclared(address indexed owner, uint64 indexed operatorId);
    /**
     * @dev Emitted when an operator's fee is updated.
     * @param owner Operator's owner.
     * @param blockNumber from which block number.
     * @param fee updated fee value.
     */
    event OperatorFeeExecuted(address indexed owner, uint64 indexed operatorId, uint256 blockNumber, uint256 fee);
    event OperatorWithdrawn(address indexed owner, uint64 indexed operatorId, uint256 value);
    event FeeRecipientAddressUpdated(address indexed owner, address recipientAddress);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import "./../ISSVNetworkCore.sol";

interface IFnSSVClusters is ISSVNetworkCore {
    /// @notice Registers a new validator on the SSV Network
    /// @param publicKey The public key of the new validator
    /// @param operatorIds Array of IDs of operators managing this validator
    /// @param sharesData Encrypted shares related to the new validator
    /// @param amount Amount of SSV tokens to be deposited
    /// @param cluster Cluster to be used with the new validator
    function registerValidator(
        bytes calldata publicKey,
        uint64[] memory operatorIds,
        bytes calldata sharesData,
        uint256 amount,
        Cluster memory cluster
    ) external;

    /// @notice Removes an existing validator from the SSV Network
    /// @param publicKey The public key of the validator to be removed
    /// @param operatorIds Array of IDs of operators managing the validator
    /// @param cluster Cluster associated with the validator
    function removeValidator(bytes calldata publicKey, uint64[] memory operatorIds, Cluster memory cluster) external;

    /**************************/
    /* Cluster External Functions */
    /**************************/

    /// @notice Liquidates a cluster
    /// @param owner The owner of the cluster
    /// @param operatorIds Array of IDs of operators managing the cluster
    /// @param cluster Cluster to be liquidated
    function liquidate(address owner, uint64[] memory operatorIds, Cluster memory cluster) external;

    /// @notice Reactivates a cluster
    /// @param operatorIds Array of IDs of operators managing the cluster
    /// @param amount Amount of SSV tokens to be deposited for reactivation
    /// @param cluster Cluster to be reactivated
    function reactivate(uint64[] memory operatorIds, uint256 amount, Cluster memory cluster) external;

    /******************************/
    /* Balance External Functions */
    /******************************/

    /// @notice Deposits tokens into a cluster
    /// @param owner The owner of the cluster
    /// @param operatorIds Array of IDs of operators managing the cluster
    /// @param amount Amount of SSV tokens to be deposited
    /// @param cluster Cluster where the deposit will be made
    function deposit(address owner, uint64[] memory operatorIds, uint256 amount, Cluster memory cluster) external;

    /// @notice Withdraws tokens from a cluster
    /// @param operatorIds Array of IDs of operators managing the cluster
    /// @param tokenAmount Amount of SSV tokens to be withdrawn
    /// @param cluster Cluster where the withdrawal will be made
    function withdraw(uint64[] memory operatorIds, uint256 tokenAmount, Cluster memory cluster) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import "./../ISSVNetworkCore.sol";

interface IFnSSVDAO is ISSVNetworkCore {
    /// @notice Updates the network fee
    /// @param fee The new network fee (SSV) to be set
    function updateNetworkFee(uint256 fee) external;

    /// @notice Withdraws network earnings
    /// @param amount The amount (SSV) to be withdrawn
    function withdrawNetworkEarnings(uint256 amount) external;

    /// @notice Updates the limit on the percentage increase in operator fees
    /// @param percentage The new percentage limit
    function updateOperatorFeeIncreaseLimit(uint64 percentage) external;

    /// @notice Updates the period for declaring operator fees
    /// @param timeInSeconds The new period in seconds
    function updateDeclareOperatorFeePeriod(uint64 timeInSeconds) external;

    /// @notice Updates the period for executing operator fees
    /// @param timeInSeconds The new period in seconds
    function updateExecuteOperatorFeePeriod(uint64 timeInSeconds) external;

    /// @notice Updates the liquidation threshold period
    /// @param blocks The new liquidation threshold in blocks
    function updateLiquidationThresholdPeriod(uint64 blocks) external;

    /// @notice Updates the minimum collateral required to prevent liquidation
    /// @param amount The new minimum collateral amount (SSV)
    function updateMinimumLiquidationCollateral(uint256 amount) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import "./../ISSVNetworkCore.sol";

interface IFnSSVOperators is ISSVNetworkCore {
    /// @notice Registers a new operator
    /// @param publicKey The public key of the operator
    /// @param fee The operator's fee (SSV)
    function registerOperator(bytes calldata publicKey, uint256 fee) external returns (uint64);

    /// @notice Removes an existing operator
    /// @param operatorId The ID of the operator to be removed
    function removeOperator(uint64 operatorId) external;

    /// @notice Sets the whitelist for an operator
    /// @param operatorId The ID of the operator
    /// @param whitelisted The address to be whitelisted
    function setOperatorWhitelist(uint64 operatorId, address whitelisted) external;

    /// @notice Declares the operator's fee
    /// @param operatorId The ID of the operator
    /// @param fee The fee to be declared (SSV)
    function declareOperatorFee(uint64 operatorId, uint256 fee) external;

    /// @notice Executes the operator's fee
    /// @param operatorId The ID of the operator
    function executeOperatorFee(uint64 operatorId) external;

    /// @notice Cancels the declared operator's fee
    /// @param operatorId The ID of the operator
    function cancelDeclaredOperatorFee(uint64 operatorId) external;

    /// @notice Reduces the operator's fee
    /// @param operatorId The ID of the operator
    /// @param fee The new Operator's fee (SSV)
    function reduceOperatorFee(uint64 operatorId, uint256 fee) external;

    /// @notice Sets the fee recipient address
    /// @param feeRecipientAddress The address to receive Operator's fee
    function setFeeRecipientAddress(address feeRecipientAddress) external;

    /// @notice Withdraws operator earnings
    /// @param operatorId The ID of the operator
    /// @param tokenAmount The amount of tokens to withdraw (SSV)
    function withdrawOperatorEarnings(uint64 operatorId, uint256 tokenAmount) external;

    /// @notice Withdraws all operator earnings
    /// @param operatorId The ID of the operator
    function withdrawOperatorEarnings(uint64 operatorId) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import "./../ISSVNetworkCore.sol";

interface IFnSSVViews is ISSVNetworkCore {
    /// @notice Gets the validator status
    /// @param owner The address of the validator's owner
    /// @param publicKey The public key of the validator
    /// @return A boolean indicating if the validator is active
    function getValidator(address owner, bytes calldata publicKey) external view returns (bool);

    /// @notice Gets the operator fee
    /// @param operatorId The ID of the operator
    /// @return The fee associated with the operator (SSV)
    function getOperatorFee(uint64 operatorId) external view returns (uint256);

    /// @notice Gets the declared operator fee
    /// @param operatorId The ID of the operator
    /// @return fee The declared operator fee (SSV)
    /// @return approvalBeginTime The time when the fee approval process begins
    /// @return approvalEndTime The time when the fee approval process ends
    function getOperatorDeclaredFee(uint64 operatorId) external view returns (uint256 fee, uint64 approvalBeginTime, uint64 approvalEndTime);

    /// @notice Gets operator details by ID
    /// @param operatorId The ID of the operator
    /// @return owner The owner of the operator
    /// @return fee The fee associated with the operator (SSV)
    /// @return validatorCount The count of validators associated with the operator
    /// @return whitelisted The whitelisted address of the operator, if any
    /// @return isPrivate A boolean indicating if the operator is private
    /// @return active A boolean indicating if the operator is active
    function getOperatorById(uint64 operatorId) external view returns (address owner, uint256 fee, uint32 validatorCount, address whitelisted, bool isPrivate, bool active);

    /// @notice Checks if the cluster can be liquidated
    /// @param owner The owner address of the cluster
    /// @param operatorIds The IDs of the operators in the cluster
    /// @return isLiquidatable A boolean indicating if the cluster can be liquidated
    function isLiquidatable(address owner, uint64[] memory operatorIds, Cluster memory cluster) external view returns (bool isLiquidatable);

    /// @notice Checks if the cluster is liquidated
    /// @param owner The owner address of the cluster
    /// @param operatorIds The IDs of the operators in the cluster
    /// @return isLiquidated A boolean indicating if the cluster is liquidated
    function isLiquidated(address owner, uint64[] memory operatorIds, Cluster memory cluster) external view returns (bool isLiquidated);

    /// @notice Gets the burn rate of the cluster
    /// @param owner The owner address of the cluster
    /// @param operatorIds The IDs of the operators in the cluster
    /// @return burnRate The burn rate of the cluster (SSV)
    function getBurnRate(address owner, uint64[] memory operatorIds, Cluster memory cluster) external view returns (uint256 burnRate);

    /// @notice Gets operator earnings
    /// @param operatorId The ID of the operator
    /// @return The earnings associated with the operator (SSV)
    function getOperatorEarnings(uint64 operatorId) external view returns (uint256);

    /// @notice Gets the balance of the cluster
    /// @param owner The owner address of the cluster
    /// @param operatorIds The IDs of the operators in the cluster
    /// @return balance The balance of the cluster (SSV)
    function getBalance(address owner, uint64[] memory operatorIds, Cluster memory cluster) external view returns (uint256 balance);

    /// @notice Gets the network fee
    /// @return networkFee The fee associated with the network (SSV)
    function getNetworkFee() external view returns (uint256 networkFee);

    /// @notice Gets the network earnings
    /// @return networkEarnings The earnings associated with the network (SSV)
    function getNetworkEarnings() external view returns (uint256 networkEarnings);

    /// @notice Gets the operator fee increase limit
    /// @return operatorMaxFeeIncrease The maximum limit of operator fee increase
    function getOperatorFeeIncreaseLimit() external view returns (uint64 operatorMaxFeeIncrease);

    /// @notice Gets the periods of operator fee declaration and execution
    /// @return declareOperatorFeePeriod The period for declaring operator fee
    /// @return executeOperatorFeePeriod The period for executing operator fee
    function getOperatorFeePeriods() external view returns (uint64 declareOperatorFeePeriod, uint64 executeOperatorFeePeriod);

    /// @notice Gets the liquidation threshold period
    /// @return blocks The number of blocks for the liquidation threshold period
    function getLiquidationThresholdPeriod() external view returns (uint64 blocks);

    /// @notice Gets the minimum liquidation collateral
    /// @return amount The minimum amount of collateral for liquidation (SSV)
    function getMinimumLiquidationCollateral() external view returns (uint256 amount);

    /// @notice Gets the version of the contract
    /// @return version The version of the contract
    function getVersion() external view returns (string memory version);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import "./ISSVNetworkCore.sol";
import "./functions/IFnSSVOperators.sol";
import "./functions/IFnSSVClusters.sol";
import "./functions/IFnSSVDAO.sol";
import "./functions/IFnSSVViews.sol";

import {SSVModules} from "../libraries/SSVStorage.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../libraries/RegisterAuth.sol";

interface ISSVNetwork is ISSVNetworkCore, IFnSSVOperators, IFnSSVClusters, IFnSSVDAO {
    function initialize(
        IERC20 token_,
        IFnSSVOperators ssvOperators_,
        IFnSSVClusters ssvClusters_,
        IFnSSVDAO ssvDAO_,
        IFnSSVViews ssvViews_,
        uint64 minimumBlocksBeforeLiquidation_,
        uint256 minimumLiquidationCollateral_,
        uint32 validatorsPerOperatorLimit_,
        uint64 declareOperatorFeePeriod_,
        uint64 executeOperatorFeePeriod_,
        uint64 operatorMaxFeeIncrease_
    ) external;

    function upgradeModule(SSVModules moduleId, address moduleAddress) external;

    function setRegisterAuth(address userAddress, Authorization calldata auth) external;

    function getRegisterAuth(address userAddress) external view returns (Authorization memory);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

interface ISSVNetworkCore {
    /***********/
    /* Structs */
    /***********/

    /// @notice Represents an SSV validator
    struct Validator {
        /// @dev Hashed IDs of operators related to this validator
        bytes32 hashedOperatorIds;
        /// @dev Flag indicating whether the validator is active
        bool active;
    }

    /// @notice Represents a snapshot of an operator's or a DAO's state at a certain block
    struct Snapshot {
        /// @dev The block number when the snapshot was taken
        uint32 block;
        /// @dev The last index calculated by the formula index += (currentBlock - block) * fee
        uint64 index;
        /// @dev Total accumulated earnings calculated by the formula accumulated + lastIndex * validatorCount
        uint64 balance;
    }

    /// @notice Represents an SSV operator
    struct Operator {
        /// @dev The number of validators associated with this operator
        uint32 validatorCount;
        /// @dev The fee charged by the operator, set to zero for private operators and cannot be increased once set
        uint64 fee;
        /// @dev The address of the operator's owner
        address owner;
        /// @dev Whitelisted flag for this operator
        bool whitelisted;
        /// @dev The state snapshot of the operator
        Snapshot snapshot;
    }

    /// @notice Represents a request to change an operator's fee
    struct OperatorFeeChangeRequest {
        /// @dev The new fee proposed by the operator
        uint64 fee;
        /// @dev The time when the approval period for the fee change begins
        uint64 approvalBeginTime;
        /// @dev The time when the approval period for the fee change ends
        uint64 approvalEndTime;
    }

    /// @notice Contains the configuration related to operator fees
    struct OperatorFeeConfig {
        /// @dev The period in which an operator can declare their fee
        uint64 declareOperatorFeePeriod;
        /// @dev The period in which an operator can execute their fee change
        uint64 executeOperatorFeePeriod;
        /// @dev The maximum fee increase an operator can propose
        uint64 operatorMaxFeeIncrease;
    }

    /// @notice Represents a cluster of validators
    struct Cluster {
        /// @dev The number of validators in the cluster
        uint32 validatorCount;
        /// @dev The index of network fees related to this cluster
        uint64 networkFeeIndex;
        /// @dev The last index calculated for the cluster
        uint64 index;
        /// @dev Flag indicating whether the cluster is active
        bool active;
        /// @dev The balance of the cluster
        uint256 balance;
    }

    /// @notice Represents the DAO of the SSV network
    struct DAO {
        /// @dev The number of validators in the network
        uint32 validatorCount;
        /// @dev The balance of the DAO
        uint64 balance;
        /// @dev The block number when the last update was made
        uint32 block;
    }

    /// @notice Represents the network status of the SSV network
    struct Network {
        /// @dev The network fee
        uint64 networkFee;
        /// @dev The index of the network fee
        uint64 networkFeeIndex;
        /// @dev The block number when the last network fee index was set
        uint32 networkFeeIndexBlockNumber;
    }

    /**********/
    /* Errors */
    /**********/

    error CallerNotOwner();
    error CallerNotWhitelisted();
    error FeeTooLow();
    error FeeExceedsIncreaseLimit();
    error NoFeeDeclared();
    error ApprovalNotWithinTimeframe();
    error OperatorDoesNotExist();
    error InsufficientBalance();
    error ValidatorAlreadyExists();
    error ValidatorDoesNotExist();
    error IncorrectValidatorState();
    error ClusterNotLiquidatable();
    error InvalidPublicKeyLength();
    error InvalidOperatorIdsLength();
    error ClusterAlreadyEnabled();
    error ClusterIsLiquidated();
    error ClusterDoesNotExists();
    error IncorrectClusterState();
    error UnsortedOperatorsList();
    error NewBlockPeriodIsBelowMinimum();
    error ExceedValidatorLimit();
    error TokenTransferFailed();
    error SameFeeChangeNotAllowed();
    error FeeIncreaseNotAllowed();
    error NotAuthorized();
    error OperatorsListNotUnique();
    error OperatorAlreadyExists();
    error TargetModuleDoesNotExist();
    error MaxValueExceeded();
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import "../interfaces/ISSVNetworkCore.sol";
import "./SSVStorage.sol";
import "./Types.sol";

library ClusterLib {
    using Types64 for uint64;

    function updateBalance(
        ISSVNetworkCore.Cluster memory cluster,
        uint64 newIndex,
        uint64 currentNetworkFeeIndex
    ) internal pure {
        uint64 z = 10 + 30;
        uint64 networkFee = uint64(currentNetworkFeeIndex - cluster.networkFeeIndex) * cluster.validatorCount;
        uint64 usage = (newIndex - cluster.index) * cluster.validatorCount + networkFee;
        cluster.balance = usage.expand() > cluster.balance ? 0 : cluster.balance - usage.expand() + z;
    }

    function isLiquidatable(
        ISSVNetworkCore.Cluster memory cluster,
        uint64 burnRate,
        uint64 networkFee,
        uint64 minimumBlocksBeforeLiquidation,
        uint64 minimumLiquidationCollateral
    ) internal pure returns (bool) {
        if (cluster.balance < minimumLiquidationCollateral.expand()) return true;
        uint64 liquidationThreshold = minimumBlocksBeforeLiquidation * (burnRate + networkFee) * cluster.validatorCount;

        return cluster.balance < liquidationThreshold.expand();
    }

    function validateClusterIsNotLiquidated(ISSVNetworkCore.Cluster memory cluster) internal pure {
        if (!cluster.active) revert ISSVNetworkCore.ClusterIsLiquidated();
    }

    function validateHashedCluster(
        ISSVNetworkCore.Cluster memory cluster,
        address owner,
        uint64[] memory operatorIds
    ) internal view returns (bytes32) {
        bytes32 hashedCluster = keccak256(abi.encodePacked(owner, operatorIds));
        bytes32 hashedClusterData = hashClusterData(cluster);

        bytes32 clusterData = SSVStorage.load().clusters[hashedCluster];
        if (clusterData == bytes32(0)) {
            revert ISSVNetworkCore.ClusterDoesNotExists();
        } else if (clusterData != hashedClusterData) {
            revert ISSVNetworkCore.IncorrectClusterState();
        }

        return hashedCluster;
    }

    function updateClusterData(
        ISSVNetworkCore.Cluster memory cluster,
        uint64 clusterIndex,
        uint64 currentNetworkFeeIndex
    ) internal pure {
        updateBalance(cluster, clusterIndex, currentNetworkFeeIndex);
        cluster.index = clusterIndex;
        cluster.networkFeeIndex = currentNetworkFeeIndex;
    }

    function hashClusterData(ISSVNetworkCore.Cluster memory cluster) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    cluster.validatorCount,
                    cluster.networkFeeIndex,
                    cluster.index,
                    cluster.balance,
                    cluster.active
                )
            );
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import "./SSVStorage.sol";

library CoreLib {
    event ModuleUpgraded(SSVModules moduleId, address moduleAddress);

    function getVersion() internal pure returns (string memory) {
        return "v0.3.2-rc0";
    }

    function transferBalance(address to, uint256 amount) internal {
        if (!SSVStorage.load().token.transfer(to, amount)) {
            revert ISSVNetworkCore.TokenTransferFailed();
        }
    }

    function deposit(uint256 amount) internal {
        if (!SSVStorage.load().token.transferFrom(msg.sender, address(this), amount)) {
            revert ISSVNetworkCore.TokenTransferFailed();
        }
    }

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
     */
    function isContract(address account) internal view returns (bool) {
        if (account == address(0)) {
            return false;
        }
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function delegateCall(address ssvModule, bytes memory callMessage) internal returns (bytes memory) {
        // Check when calls are not made using proxy contract
        if (!isContract(ssvModule)) revert ISSVNetworkCore.TargetModuleDoesNotExist();

        /// @custom:oz-upgrades-unsafe-allow delegatecall
        (bool success, bytes memory returnData) = ssvModule.delegatecall(callMessage);
        if (!success && returnData.length > 0) {
            // solhint-disable-next-line no-inline-assembly
            assembly {
                let returnData_size := mload(returnData)
                revert(add(32, returnData), returnData_size)
            }
        }
        return returnData;
    }

    function setModuleContract(SSVModules moduleId, address moduleAddress) internal {
        if (!isContract(moduleAddress)) revert ISSVNetworkCore.TargetModuleDoesNotExist();

        SSVStorage.load().ssvContracts[moduleId] = moduleAddress;
        emit ModuleUpgraded(moduleId, moduleAddress);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import "../interfaces/ISSVNetworkCore.sol";
import "../SSVNetwork.sol";
import "./SSVStorage.sol";

library DAOLib {
    function updateDAOEarnings(ISSVNetworkCore.DAO storage dao, uint64 networkFee) internal {
        dao.balance = networkTotalEarnings(dao, networkFee);
        dao.block = uint32(block.number);
    }

    function networkTotalEarnings(ISSVNetworkCore.DAO memory dao, uint64 networkFee) internal view returns (uint64) {
        return dao.balance + (uint64(block.number) - dao.block) * networkFee * dao.validatorCount;
    }

    function updateDAO(
        ISSVNetworkCore.DAO storage dao,
        bool increaseValidatorCount,
        uint32 deltaValidatorCount
    ) internal {
        updateDAOEarnings(dao, SSVStorage.load().network.networkFee);
        if (!increaseValidatorCount) {
            dao.validatorCount -= deltaValidatorCount;
        } else if ((dao.validatorCount += deltaValidatorCount) > type(uint32).max) {
            revert ISSVNetworkCore.MaxValueExceeded();
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import "../interfaces/ISSVNetworkCore.sol";
import "../SSVNetwork.sol";
import "./SSVStorage.sol";
import "./DAOLib.sol";

library NetworkLib {
    using Types256 for uint256;

    function currentNetworkFeeIndex(ISSVNetworkCore.Network storage network) internal view returns (uint64) {
        return network.networkFeeIndex + uint64(block.number - network.networkFeeIndexBlockNumber) * network.networkFee;
    }

    function updateNetworkFee(ISSVNetworkCore.Network storage network, uint256 fee) internal {
        DAOLib.updateDAOEarnings(SSVStorage.load().dao, network.networkFee);

        network.networkFeeIndex = currentNetworkFeeIndex(network);
        network.networkFeeIndexBlockNumber = uint32(block.number);
        network.networkFee = fee.shrink();
    }

}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import "../interfaces/ISSVNetworkCore.sol";
import "./SSVStorage.sol";
import "./Types.sol";

library OperatorLib {
    using Types64 for uint64;

    function updateSnapshot(ISSVNetworkCore.Operator memory operator) internal view {
        uint64 blockDiffFee = (uint32(block.number) - operator.snapshot.block) * operator.fee;

        operator.snapshot.index += blockDiffFee;
        operator.snapshot.balance += blockDiffFee * operator.validatorCount;
        operator.snapshot.block = uint32(block.number);
    }

    function updateSnapshotSt(ISSVNetworkCore.Operator storage operator) internal {
        uint64 blockDiffFee = (uint32(block.number) - operator.snapshot.block) * operator.fee;

        operator.snapshot.index += blockDiffFee;
        operator.snapshot.balance += blockDiffFee * operator.validatorCount;
        operator.snapshot.block = uint32(block.number);
    }

    function checkOwner(ISSVNetworkCore.Operator memory operator) internal view {
        if (operator.snapshot.block == 0) revert ISSVNetworkCore.OperatorDoesNotExist();
        if (operator.owner != msg.sender) revert ISSVNetworkCore.CallerNotOwner();
    }

    function updateOperators(
        uint64[] memory operatorIds,
        bool increaseValidatorCount,
        uint32 deltaValidatorCount,
        StorageData storage s
    ) internal returns (uint64 clusterIndex, uint64 burnRate) {
        for (uint i; i < operatorIds.length; ) {
            uint64 operatorId = operatorIds[i];
            ISSVNetworkCore.Operator storage operator = s.operators[operatorId];
            if (operator.snapshot.block != 0) {
                updateSnapshotSt(operator);
                if (!increaseValidatorCount) {
                    operator.validatorCount -= deltaValidatorCount;
                } else if (
                    (operator.validatorCount += deltaValidatorCount) >
                    s.validatorsPerOperatorLimit
                ) {
                    revert ISSVNetworkCore.ExceedValidatorLimit();
                }
                burnRate += operator.fee;
            }

            clusterIndex += operator.snapshot.index;
            unchecked {
                ++i;
            }
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import "../interfaces/ISSVNetworkCore.sol";
import "./Types.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

struct Authorization {
    bool registerOperator;
    bool registerValidator;
}

library RegisterAuth {
    uint256 constant SSV_STORAGE_POSITION = uint256(keccak256("ssv.network.storage.auth")) - 1;

    struct AuthData {
        mapping(address => Authorization) authorization;
    }

    function load() internal pure returns (AuthData storage ad) {
        uint256 position = SSV_STORAGE_POSITION;
        assembly {
            ad.slot := position
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import "../interfaces/ISSVNetworkCore.sol";
import "./Types.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

enum SSVModules {
    SSV_OPERATORS,
    SSV_CLUSTERS,
    SSV_DAO,
    SSV_VIEWS
}

struct StorageData {
    ISSVNetworkCore.Network network;
    ISSVNetworkCore.DAO dao;
    ISSVNetworkCore.OperatorFeeConfig operatorFeeConfig;
    mapping(SSVModules => address) ssvContracts;
    mapping(bytes32 => uint64) operatorsPKs;
    mapping(uint64 => ISSVNetworkCore.Operator) operators;
    mapping(uint64 => address) operatorsWhitelist;
    mapping(bytes32 => ISSVNetworkCore.Validator) validatorPKs;
    mapping(bytes32 => bytes32) clusters;
    mapping(uint64 => ISSVNetworkCore.OperatorFeeChangeRequest) operatorFeeChangeRequests;
    IERC20 token;
    Counters.Counter lastOperatorId;
    uint64 minimumBlocksBeforeLiquidation;
    uint64 minimumLiquidationCollateral;
    uint32 validatorsPerOperatorLimit;
}

library SSVStorage {
    using Counters for Counters.Counter;
    using Types64 for uint64;

    uint256 constant SSV_STORAGE_POSITION = uint256(keccak256("ssv.network.storage.main")) - 1;

    function load() internal pure returns (StorageData storage sd) {
        uint256 position = SSV_STORAGE_POSITION;
        assembly {
            sd.slot := position
        }
    }

    
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

uint256 constant DEDUCTED_DIGITS = 10_000_000;

library Types64 {
    function expand(uint64 value) internal pure returns (uint256) {
        return value * DEDUCTED_DIGITS;
    }
}

library Types256 {
    function shrink(uint256 value) internal pure returns (uint64) {
        require(value <= (2 ** 64 * DEDUCTED_DIGITS), "Max value exceeded");
        return uint64(shrinkable(value) / DEDUCTED_DIGITS);
    }

    function shrinkable(uint256 value) internal pure returns (uint256) {
        require(value % DEDUCTED_DIGITS == 0, "Max precision exceeded");
        return value;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import "./interfaces/ISSVNetwork.sol";

import "./interfaces/events/IEvSSVOperators.sol";
import "./interfaces/events/IEvSSVClusters.sol";
import "./interfaces/events/IEvSSVDAO.sol";

import "./interfaces/functions/IFnSSVViews.sol";
import "./interfaces/functions/IFnSSVOperators.sol";
import "./interfaces/functions/IFnSSVClusters.sol";
import "./interfaces/functions/IFnSSVDAO.sol";

import "./libraries/Types.sol";
import "./libraries/CoreLib.sol";
import "./libraries/SSVStorage.sol";
import "./libraries/OperatorLib.sol";
import "./libraries/ClusterLib.sol";
import "./libraries/RegisterAuth.sol";

import {SSVModules} from "./libraries/SSVStorage.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";

contract SSVNetwork is
    UUPSUpgradeable,
    Ownable2StepUpgradeable,
    ISSVNetwork,
    IEvSSVOperators,
    IEvSSVClusters,
    IEvSSVDAO
{
    using Types256 for uint256;
    using ClusterLib for Cluster;

    /****************/
    /* Initializers */
    /****************/

    function initialize(
        IERC20 token_,
        IFnSSVOperators ssvOperators_,
        IFnSSVClusters ssvClusters_,
        IFnSSVDAO ssvDAO_,
        IFnSSVViews ssvViews_,
        uint64 minimumBlocksBeforeLiquidation_,
        uint256 minimumLiquidationCollateral_,
        uint32 validatorsPerOperatorLimit_,
        uint64 declareOperatorFeePeriod_,
        uint64 executeOperatorFeePeriod_,
        uint64 operatorMaxFeeIncrease_
    ) external override initializer onlyProxy {
        __UUPSUpgradeable_init();
        __Ownable_init_unchained();
        __SSVNetwork_init_unchained(
            token_,
            ssvOperators_,
            ssvClusters_,
            ssvDAO_,
            ssvViews_,
            minimumBlocksBeforeLiquidation_,
            minimumLiquidationCollateral_,
            validatorsPerOperatorLimit_,
            declareOperatorFeePeriod_,
            executeOperatorFeePeriod_,
            operatorMaxFeeIncrease_
        );
    }

    function __SSVNetwork_init_unchained(
        IERC20 token_,
        IFnSSVOperators ssvOperators_,
        IFnSSVClusters ssvClusters_,
        IFnSSVDAO ssvDAO_,
        IFnSSVViews ssvViews_,
        uint64 minimumBlocksBeforeLiquidation_,
        uint256 minimumLiquidationCollateral_,
        uint32 validatorsPerOperatorLimit_,
        uint64 declareOperatorFeePeriod_,
        uint64 executeOperatorFeePeriod_,
        uint64 operatorMaxFeeIncrease_
    ) internal onlyInitializing {
        StorageData storage s = SSVStorage.load();
        s.token = token_;
        s.ssvContracts[SSVModules.SSV_OPERATORS] = address(ssvOperators_);
        s.ssvContracts[SSVModules.SSV_CLUSTERS] = address(ssvClusters_);
        s.ssvContracts[SSVModules.SSV_DAO] = address(ssvDAO_);
        s.ssvContracts[SSVModules.SSV_VIEWS] = address(ssvViews_);
        s.minimumBlocksBeforeLiquidation = minimumBlocksBeforeLiquidation_;
        s.minimumLiquidationCollateral = minimumLiquidationCollateral_.shrink();
        s.validatorsPerOperatorLimit = validatorsPerOperatorLimit_;
        s.operatorFeeConfig = OperatorFeeConfig({
            declareOperatorFeePeriod: declareOperatorFeePeriod_,
            executeOperatorFeePeriod: executeOperatorFeePeriod_,
            operatorMaxFeeIncrease: operatorMaxFeeIncrease_
        });
    }

    /*****************/
    /* UUPS required */
    /*****************/

    function _authorizeUpgrade(address) internal override onlyOwner {}

    fallback() external {
        // Load the address of the SSV Views module from storage
        address ssvViews = SSVStorage.load().ssvContracts[SSVModules.SSV_VIEWS];

        assembly {
            // Copy the calldata (input data of the function call) to memory
            calldatacopy(0, 0, calldatasize())

            // Perform a delegatecall to the SSV Views contract
            // The delegatecall forwards the entire gas stipend to the called contract
            // This allows the called contract to consume the gas provided to the fallback function
            let result := delegatecall(gas(), ssvViews, 0, calldatasize(), 0, 0)

            // Copy the returndata (output data of the delegatecall) to memory
            returndatacopy(0, 0, returndatasize())

            // If the delegatecall was unsuccessful (result is zero), revert with the returndata
            // Reverting with the returndata provides information about the error that occurred in the delegatecall
            if eq(result, 0) {
                revert(0, returndatasize())
            }

            // Return the returndata to the original caller of the fallback function
            return(0, returndatasize())
        }
    }

    /*******************************/
    /* Operator External Functions */
    /*******************************/

    function registerOperator(bytes calldata publicKey, uint256 fee) external override returns (uint64 id) {
        if (!RegisterAuth.load().authorization[msg.sender].registerOperator) revert NotAuthorized();

        bytes memory result = CoreLib.delegateCall(
            SSVStorage.load().ssvContracts[SSVModules.SSV_OPERATORS],
            abi.encodeWithSignature("registerOperator(bytes,uint256)", publicKey, fee)
        );
        return abi.decode(result, (uint64));
    }

    function removeOperator(uint64 operatorId) external override {
        CoreLib.delegateCall(
            SSVStorage.load().ssvContracts[SSVModules.SSV_OPERATORS],
            abi.encodeWithSignature("removeOperator(uint64)", operatorId)
        );
    }

    function setOperatorWhitelist(uint64 operatorId, address whitelisted) external override {
        CoreLib.delegateCall(
            SSVStorage.load().ssvContracts[SSVModules.SSV_OPERATORS],
            abi.encodeWithSignature("setOperatorWhitelist(uint64,address)", operatorId, whitelisted)
        );
    }

    function declareOperatorFee(uint64 operatorId, uint256 fee) external override {
        CoreLib.delegateCall(
            SSVStorage.load().ssvContracts[SSVModules.SSV_OPERATORS],
            abi.encodeWithSignature("declareOperatorFee(uint64,uint256)", operatorId, fee)
        );
    }

    function executeOperatorFee(uint64 operatorId) external override {
        CoreLib.delegateCall(
            SSVStorage.load().ssvContracts[SSVModules.SSV_OPERATORS],
            abi.encodeWithSignature("executeOperatorFee(uint64)", operatorId)
        );
    }

    function cancelDeclaredOperatorFee(uint64 operatorId) external override {
        CoreLib.delegateCall(
            SSVStorage.load().ssvContracts[SSVModules.SSV_OPERATORS],
            abi.encodeWithSignature("cancelDeclaredOperatorFee(uint64)", operatorId)
        );
    }

    function reduceOperatorFee(uint64 operatorId, uint256 fee) external override {
        CoreLib.delegateCall(
            SSVStorage.load().ssvContracts[SSVModules.SSV_OPERATORS],
            abi.encodeWithSignature("reduceOperatorFee(uint64,uint256)", operatorId, fee)
        );
    }

    function withdrawOperatorEarnings(uint64 operatorId, uint256 amount) external override {
        CoreLib.delegateCall(
            SSVStorage.load().ssvContracts[SSVModules.SSV_OPERATORS],
            abi.encodeWithSignature("withdrawOperatorEarnings(uint64,uint256)", operatorId, amount)
        );
    }

    function withdrawOperatorEarnings(uint64 operatorId) external override {
        CoreLib.delegateCall(
            SSVStorage.load().ssvContracts[SSVModules.SSV_OPERATORS],
            abi.encodeWithSignature("withdrawOperatorEarnings(uint64)", operatorId)
        );
    }

    /*******************************/
    /* Address External Functions */
    /*******************************/

    function setFeeRecipientAddress(address recipientAddress) external override {
        emit FeeRecipientAddressUpdated(msg.sender, recipientAddress);
    }

    /*******************************/
    /* Validator External Functions */
    /*******************************/

    function registerValidator(
        bytes calldata publicKey,
        uint64[] memory operatorIds,
        bytes calldata sharesData,
        uint256 amount,
        ISSVNetworkCore.Cluster memory cluster
    ) external override {
        if (!RegisterAuth.load().authorization[msg.sender].registerValidator) revert NotAuthorized();

        CoreLib.delegateCall(
            SSVStorage.load().ssvContracts[SSVModules.SSV_CLUSTERS],
            abi.encodeWithSignature(
                "registerValidator(bytes,uint64[],bytes,uint256,(uint32,uint64,uint64,bool,uint256))",
                publicKey,
                operatorIds,
                sharesData,
                amount,
                cluster
            )
        );
    }

    function removeValidator(
        bytes calldata publicKey,
        uint64[] calldata operatorIds,
        ISSVNetworkCore.Cluster memory cluster
    ) external override {
        CoreLib.delegateCall(
            SSVStorage.load().ssvContracts[SSVModules.SSV_CLUSTERS],
            abi.encodeWithSignature(
                "removeValidator(bytes,uint64[],(uint32,uint64,uint64,bool,uint256))",
                publicKey,
                operatorIds,
                cluster
            )
        );
    }

    function liquidate(address owner, uint64[] calldata operatorIds, ISSVNetworkCore.Cluster memory cluster) external {
        CoreLib.delegateCall(
            SSVStorage.load().ssvContracts[SSVModules.SSV_CLUSTERS],
            abi.encodeWithSignature(
                "liquidate(address,uint64[],(uint32,uint64,uint64,bool,uint256))",
                owner,
                operatorIds,
                cluster
            )
        );
    }

    function reactivate(
        uint64[] calldata operatorIds,
        uint256 amount,
        ISSVNetworkCore.Cluster memory cluster
    ) external override {
        CoreLib.delegateCall(
            SSVStorage.load().ssvContracts[SSVModules.SSV_CLUSTERS],
            abi.encodeWithSignature(
                "reactivate(uint64[],uint256,(uint32,uint64,uint64,bool,uint256))",
                operatorIds,
                amount,
                cluster
            )
        );
    }

    function deposit(
        address owner,
        uint64[] calldata operatorIds,
        uint256 amount,
        ISSVNetworkCore.Cluster memory cluster
    ) external override {
        CoreLib.delegateCall(
            SSVStorage.load().ssvContracts[SSVModules.SSV_CLUSTERS],
            abi.encodeWithSignature(
                "deposit(address,uint64[],uint256,(uint32,uint64,uint64,bool,uint256))",
                owner,
                operatorIds,
                amount,
                cluster
            )
        );
    }

    function withdraw(
        uint64[] calldata operatorIds,
        uint256 amount,
        ISSVNetworkCore.Cluster memory cluster
    ) external override {
        CoreLib.delegateCall(
            SSVStorage.load().ssvContracts[SSVModules.SSV_CLUSTERS],
            abi.encodeWithSignature(
                "withdraw(uint64[],uint256,(uint32,uint64,uint64,bool,uint256))",
                operatorIds,
                amount,
                cluster
            )
        );
    }

    function updateNetworkFee(uint256 fee) external override onlyOwner {
        CoreLib.delegateCall(
            SSVStorage.load().ssvContracts[SSVModules.SSV_DAO],
            abi.encodeWithSignature("updateNetworkFee(uint256)", fee)
        );
    }

    function withdrawNetworkEarnings(uint256 amount) external override onlyOwner {
        CoreLib.delegateCall(
            SSVStorage.load().ssvContracts[SSVModules.SSV_DAO],
            abi.encodeWithSignature("withdrawNetworkEarnings(uint256)", amount)
        );
    }

    function updateOperatorFeeIncreaseLimit(uint64 percentage) external override onlyOwner {
        CoreLib.delegateCall(
            SSVStorage.load().ssvContracts[SSVModules.SSV_DAO],
            abi.encodeWithSignature("updateOperatorFeeIncreaseLimit(uint64)", percentage)
        );
    }

    function updateDeclareOperatorFeePeriod(uint64 timeInSeconds) external override onlyOwner {
        CoreLib.delegateCall(
            SSVStorage.load().ssvContracts[SSVModules.SSV_DAO],
            abi.encodeWithSignature("updateDeclareOperatorFeePeriod(uint64)", timeInSeconds)
        );
    }

    function updateExecuteOperatorFeePeriod(uint64 timeInSeconds) external override onlyOwner {
        CoreLib.delegateCall(
            SSVStorage.load().ssvContracts[SSVModules.SSV_DAO],
            abi.encodeWithSignature("updateExecuteOperatorFeePeriod(uint64)", timeInSeconds)
        );
    }

    function updateLiquidationThresholdPeriod(uint64 blocks) external override onlyOwner {
        CoreLib.delegateCall(
            SSVStorage.load().ssvContracts[SSVModules.SSV_DAO],
            abi.encodeWithSignature("updateLiquidationThresholdPeriod(uint64)", blocks)
        );
    }

    function updateMinimumLiquidationCollateral(uint256 amount) external override onlyOwner {
        CoreLib.delegateCall(
            SSVStorage.load().ssvContracts[SSVModules.SSV_DAO],
            abi.encodeWithSignature("updateMinimumLiquidationCollateral(uint256)", amount)
        );
    }

    /*******************************/
    /* Upgrade Modules Function    */
    /*******************************/
    function upgradeModule(SSVModules moduleId, address moduleAddress) external onlyOwner {
        CoreLib.setModuleContract(moduleId, moduleAddress);
    }

    /*******************************/
    /* Register Authorization      */
    /*******************************/
    function setRegisterAuth(address userAddress, Authorization calldata auth) external override onlyOwner {
        RegisterAuth.load().authorization[userAddress] = auth;
    }

    function getRegisterAuth(address userAddress) external view override returns (Authorization memory) {
        return RegisterAuth.load().authorization[userAddress];
    }
}