// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

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
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = _setInitializedVersion(1);
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
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
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
     */
    function _disableInitializers() internal virtual {
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
// OpenZeppelin Contracts v4.4.1 (utils/StorageSlot.sol)

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
library StorageSlot {
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
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "./InjectorContextHolder.sol";

contract ChainConfig is InjectorContextHolder, IChainConfig {

    event ActiveValidatorsLengthChanged(uint32 prevValue, uint32 newValue);
    event EpochBlockIntervalChanged(uint32 prevValue, uint32 newValue);
    event MisdemeanorThresholdChanged(uint32 prevValue, uint32 newValue);
    event FelonyThresholdChanged(uint32 prevValue, uint32 newValue);
    event ValidatorJailEpochLengthChanged(uint32 prevValue, uint32 newValue);
    event UndelegatePeriodChanged(uint32 prevValue, uint32 newValue);
    event MinValidatorStakeAmountChanged(uint256 prevValue, uint256 newValue);
    event MinStakingAmountChanged(uint256 prevValue, uint256 newValue);

    struct ConsensusParams {
        uint32 activeValidatorsLength;
        uint32 epochBlockInterval;
        uint32 misdemeanorThreshold;
        uint32 felonyThreshold;
        uint32 validatorJailEpochLength;
        uint32 undelegatePeriod;
        uint256 minValidatorStakeAmount;
        uint256 minStakingAmount;
    }

    ConsensusParams private _consensusParams;

    constructor(
        IStaking stakingContract,
        ISlashingIndicator slashingIndicatorContract,
        ISystemReward systemRewardContract,
        IStakingPool stakingPoolContract,
        IGovernance governanceContract,
        IChainConfig chainConfigContract,
        IRuntimeUpgrade runtimeUpgradeContract,
        IDeployerProxy deployerProxyContract
    ) InjectorContextHolder(
        stakingContract,
        slashingIndicatorContract,
        systemRewardContract,
        stakingPoolContract,
        governanceContract,
        chainConfigContract,
        runtimeUpgradeContract,
        deployerProxyContract
    ) {
    }
    // only owner
    function initialize(
        uint32 activeValidatorsLength,
        uint32 epochBlockInterval,
        uint32 misdemeanorThreshold,
        uint32 felonyThreshold,
        uint32 validatorJailEpochLength,
        uint32 undelegatePeriod,
        uint256 minValidatorStakeAmount,
        uint256 minStakingAmount
    ) external initializer {
        _consensusParams.activeValidatorsLength = activeValidatorsLength;
        emit ActiveValidatorsLengthChanged(0, activeValidatorsLength);
        _consensusParams.epochBlockInterval = epochBlockInterval;
        emit EpochBlockIntervalChanged(0, epochBlockInterval);
        _consensusParams.misdemeanorThreshold = misdemeanorThreshold;
        emit MisdemeanorThresholdChanged(0, misdemeanorThreshold);
        _consensusParams.felonyThreshold = felonyThreshold;
        emit FelonyThresholdChanged(0, felonyThreshold);
        _consensusParams.validatorJailEpochLength = validatorJailEpochLength;
        emit ValidatorJailEpochLengthChanged(0, validatorJailEpochLength);
        _consensusParams.undelegatePeriod = undelegatePeriod;
        emit UndelegatePeriodChanged(0, undelegatePeriod);
        _consensusParams.minValidatorStakeAmount = minValidatorStakeAmount;
        emit MinValidatorStakeAmountChanged(0, minValidatorStakeAmount);
        _consensusParams.minStakingAmount = minStakingAmount;
        emit MinStakingAmountChanged(0, minStakingAmount);
    }

    function getActiveValidatorsLength() external view override returns (uint32) {
        return _consensusParams.activeValidatorsLength;
    }

    function setActiveValidatorsLength(uint32 newValue) external override onlyFromGovernance {
        uint32 prevValue = _consensusParams.activeValidatorsLength;
        _consensusParams.activeValidatorsLength = newValue;
        emit ActiveValidatorsLengthChanged(prevValue, newValue);
    }

    function getEpochBlockInterval() external view override returns (uint32) {
        return _consensusParams.epochBlockInterval;
    }

    function setEpochBlockInterval(uint32 newValue) external override onlyFromGovernance {
        uint32 prevValue = _consensusParams.epochBlockInterval;
        _consensusParams.epochBlockInterval = newValue;
        emit EpochBlockIntervalChanged(prevValue, newValue);
    }

    function getMisdemeanorThreshold() external view override returns (uint32) {
        return _consensusParams.misdemeanorThreshold;
    }

    function setMisdemeanorThreshold(uint32 newValue) external override onlyFromGovernance {
        uint32 prevValue = _consensusParams.misdemeanorThreshold;
        _consensusParams.misdemeanorThreshold = newValue;
        emit MisdemeanorThresholdChanged(prevValue, newValue);
    }

    function getFelonyThreshold() external view override returns (uint32) {
        return _consensusParams.felonyThreshold;
    }

    function setFelonyThreshold(uint32 newValue) external override onlyFromGovernance {
        uint32 prevValue = _consensusParams.felonyThreshold;
        _consensusParams.felonyThreshold = newValue;
        emit FelonyThresholdChanged(prevValue, newValue);
    }

    function getValidatorJailEpochLength() external view override returns (uint32) {
        return _consensusParams.validatorJailEpochLength;
    }

    function setValidatorJailEpochLength(uint32 newValue) external override onlyFromGovernance {
        uint32 prevValue = _consensusParams.validatorJailEpochLength;
        _consensusParams.validatorJailEpochLength = newValue;
        emit ValidatorJailEpochLengthChanged(prevValue, newValue);
    }

    function getUndelegatePeriod() external view override returns (uint32) {
        return _consensusParams.undelegatePeriod;
    }

    function setUndelegatePeriod(uint32 newValue) external override onlyFromGovernance {
        uint32 prevValue = _consensusParams.undelegatePeriod;
        _consensusParams.undelegatePeriod = newValue;
        emit UndelegatePeriodChanged(prevValue, newValue);
    }

    function getMinValidatorStakeAmount() external view returns (uint256) {
        return _consensusParams.minValidatorStakeAmount;
    }

    function setMinValidatorStakeAmount(uint256 newValue) external override onlyFromGovernance {
        uint256 prevValue = _consensusParams.minValidatorStakeAmount;
        _consensusParams.minValidatorStakeAmount = newValue;
        emit MinValidatorStakeAmountChanged(prevValue, newValue);
    }

    function getMinStakingAmount() external view returns (uint256) {
        return _consensusParams.minStakingAmount;
    }

    function setMinStakingAmount(uint256 newValue) external override onlyFromGovernance {
        uint256 prevValue = _consensusParams.minStakingAmount;
        _consensusParams.minStakingAmount = newValue;
        emit MinStakingAmountChanged(prevValue, newValue);
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/StorageSlot.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./libs/Multicall.sol";

import "./interfaces/IChainConfig.sol";
import "./interfaces/IGovernance.sol";
import "./interfaces/ISlashingIndicator.sol";
import "./interfaces/ISystemReward.sol";
import "./interfaces/IValidatorSet.sol";
import "./interfaces/IStaking.sol";
import "./interfaces/IRuntimeUpgrade.sol";
import "./interfaces/IStakingPool.sol";
import "./interfaces/IInjectorContextHolder.sol";
import "./interfaces/IDeployerProxy.sol";

abstract contract InjectorContextHolder is Initializable, Multicall, IInjectorContextHolder, Ownable {

    // default layout offset, it means that all inherited smart contract's storage layout must start from 100
    uint256 internal constant _LAYOUT_OFFSET = 100;
    uint256 internal constant _SKIP_OFFSET = 10;


    // BSC compatible smart contracts
    IStaking internal  _STAKING_CONTRACT;
    ISlashingIndicator internal immutable _SLASHING_INDICATOR_CONTRACT;
    ISystemReward internal immutable _SYSTEM_REWARD_CONTRACT;
    IStakingPool internal  _STAKING_POOL_CONTRACT;
    IGovernance internal immutable _GOVERNANCE_CONTRACT;
    IChainConfig internal immutable _CHAIN_CONFIG_CONTRACT;
    IRuntimeUpgrade internal immutable _RUNTIME_UPGRADE_CONTRACT;
    IDeployerProxy internal immutable _DEPLOYER_PROXY_CONTRACT;

    // delayed initializer input data (only for parlia mode)
    bytes internal _delayedInitializer;

    // already used fields
    uint256[_SKIP_OFFSET] private __removed;
    // reserved (2 for init and initializer)
    uint256[_LAYOUT_OFFSET - _SKIP_OFFSET - 2] private __reserved;

    error OnlyCoinbase(address coinbase);
    error OnlySlashingIndicator();
    error OnlyGovernance();
    error OnlyBlock(uint64 blockNumber);

    constructor(
        IStaking stakingContract,
        ISlashingIndicator slashingIndicatorContract,
        ISystemReward systemRewardContract,
        IStakingPool stakingPoolContract,
        IGovernance governanceContract,
        IChainConfig chainConfigContract,
        IRuntimeUpgrade runtimeUpgradeContract,
        IDeployerProxy deployerProxyContract
    ) {
        _STAKING_CONTRACT = stakingContract;
        _SLASHING_INDICATOR_CONTRACT = slashingIndicatorContract;
        _SYSTEM_REWARD_CONTRACT = systemRewardContract;
        _STAKING_POOL_CONTRACT = stakingPoolContract;
        _GOVERNANCE_CONTRACT = governanceContract;
        _CHAIN_CONFIG_CONTRACT = chainConfigContract;
        _RUNTIME_UPGRADE_CONTRACT = runtimeUpgradeContract;
        _DEPLOYER_PROXY_CONTRACT = deployerProxyContract;
    }

    function useDelayedInitializer(bytes memory delayedInitializer) external onlyBlock(0) {
        _delayedInitializer = delayedInitializer;
    }

    function init() external onlyBlock(1) virtual {
        if (_delayedInitializer.length > 0) {
            _selfDelegateCall(_delayedInitializer);
        }
    }

    function isInitialized() public view override returns (bool) {
        // openzeppelin's class "Initializable" doesnt expose any methods for fetching initialisation status
        StorageSlot.Uint256Slot storage initializedSlot = StorageSlot.getUint256Slot(bytes32(0x0000000000000000000000000000000000000000000000000000000000000000));
        return initializedSlot.value > 0;
    }

    modifier onlyFromCoinbase() virtual {
        if (msg.sender != block.coinbase) revert OnlyCoinbase(block.coinbase);
        _;
    }

    modifier onlyFromSlashingIndicator() virtual {
        if (ISlashingIndicator(msg.sender) != _SLASHING_INDICATOR_CONTRACT) revert OnlySlashingIndicator();
        _;
    }

    modifier onlyFromGovernance() virtual {
        if (msg.sender != owner()) revert OnlyGovernance();
        _;
    }

    modifier onlyBlock(uint64 blockNumber) virtual {
        if (block.number != blockNumber) revert OnlyBlock(blockNumber);
        _;
    }

    function setstaking(IStaking  newStaking) public onlyOwner{
        _STAKING_CONTRACT = newStaking;
    }

    function getstaking() external view  returns (IStaking) {
        return _STAKING_CONTRACT;
    }
    function setstakingPool(IStakingPool  newStakingpool) public onlyOwner{
        _STAKING_POOL_CONTRACT = newStakingpool;
    }

    function getstakingPool() external view  returns (IStakingPool) {
        return _STAKING_POOL_CONTRACT;
    }

}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

interface IChainConfig {

    function getActiveValidatorsLength() external view returns (uint32);

    function setActiveValidatorsLength(uint32 newValue) external;

    function getEpochBlockInterval() external view returns (uint32);

    function setEpochBlockInterval(uint32 newValue) external;

    function getMisdemeanorThreshold() external view returns (uint32);

    function setMisdemeanorThreshold(uint32 newValue) external;

    function getFelonyThreshold() external view returns (uint32);

    function setFelonyThreshold(uint32 newValue) external;

    function getValidatorJailEpochLength() external view returns (uint32);

    function setValidatorJailEpochLength(uint32 newValue) external;

    function getUndelegatePeriod() external view returns (uint32);

    function setUndelegatePeriod(uint32 newValue) external;

    function getMinValidatorStakeAmount() external view returns (uint256);

    function setMinValidatorStakeAmount(uint256 newValue) external;

    function getMinStakingAmount() external view returns (uint256);

    function setMinStakingAmount(uint256 newValue) external;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

interface IDeployerProxy {

    function registerDeployedContract(address account, address impl) external;

    function checkContractActive(address impl) external;

    function isDeployer(address account) external view returns (bool);

    function getContractState(address contractAddress) external view returns (uint8 state, address impl, address deployer);

    function isBanned(address account) external view returns (bool);

    function addDeployer(address account) external;

    function banDeployer(address account) external;

    function unbanDeployer(address account) external;

    function removeDeployer(address account) external;

    function disableContract(address contractAddress) external;

    function enableContract(address contractAddress) external;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

interface IGovernance {

    function getVotingSupply() external view returns (uint256);

    function getVotingPower(address validator) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "./ISlashingIndicator.sol";
import "./ISystemReward.sol";
import "./IGovernance.sol";
import "./IStaking.sol";
import "./IDeployerProxy.sol";
import "./IStakingPool.sol";
import "./IChainConfig.sol";

interface IInjectorContextHolder {

    function useDelayedInitializer(bytes memory delayedInitializer) external;

    function init() external;

    function isInitialized() external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

interface IRuntimeUpgrade {

    function isEIP1967() external view returns (bool);

    function upgradeSystemSmartContract(address payable account, bytes calldata bytecode, bytes calldata data) external payable;

    function deploySystemSmartContract(address payable account, bytes calldata bytecode, bytes calldata data) external payable;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

interface ISlashingIndicator {

    function slash(address validator) external;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "./IValidatorSet.sol";

interface IStaking is IValidatorSet {

    function currentEpoch() external view returns (uint64);

    function nextEpoch() external view returns (uint64);

    function isValidatorActive(address validator) external view returns (bool);

    function isValidator(address validator) external view returns (bool);

    function getValidatorStatus(address validator) external view returns (
        address ownerAddress,
        uint8 status,
        uint256 totalDelegated,
        uint32 slashesCount,
        uint64 changedAt,
        uint64 jailedBefore,
        uint64 claimedAt,
        uint16 commissionRate,
        uint96 totalRewards
    );

    function getValidatorStatusAtEpoch(address validator, uint64 epoch) external view returns (
        address ownerAddress,
        uint8 status,
        uint256 totalDelegated,
        uint32 slashesCount,
        uint64 changedAt,
        uint64 jailedBefore,
        uint64 claimedAt,
        uint16 commissionRate,
        uint96 totalRewards
    );

    function getValidatorByOwner(address owner) external view returns (address);

    function registerValidator(address validator, uint16 commissionRate) payable external;

    function addValidator(address validator) external;

    function removeValidator(address validator) external;

    function activateValidator(address validator) external;

    function disableValidator(address validator) external;

    function releaseValidatorFromJail(address validator) external;

    function getValidatorDelegation(address validator, address delegator) external view returns (
        uint256 delegatedAmount,
        uint64 atEpoch
    );

    function delegate(address validator) payable external;

    function undelegate(address validator, uint256 amount) external;

    function getValidatorFee(address validator) external view returns (uint256);

    function getPendingValidatorFee(address validator) external view returns (uint256);

    function claimValidatorFee(address validator) external;

    function getDelegatorFee(address validator, address delegator) external view returns (uint256);

    function getPendingDelegatorFee(address validator, address delegator) external view returns (uint256);

    function claimDelegatorFee(address validator) external;

    function calcAvailableForRedelegateAmount(address validator, address delegator) external view returns (uint256 amountToStake, uint256 rewardsDust);

    function claimPendingUndelegates(address validator) external;

    function redelegateDelegatorFee(address validator) external;

    function slash(address validator) external;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

interface IStakingPool {

    function getStakedAmount(address validator, address staker) external view returns (uint256);

    function stake(address validator) external payable;

    function unstake(address validator, uint256 amount) external;

    function claimableRewards(address validator, address staker) external view returns (uint256);

    function claim(address validator) external;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

interface ISystemReward {

    function updateDistributionShare(address[] calldata accounts, uint16[] calldata shares) external;

    function getSystemFee() external view returns (uint256);

    function claimSystemFee() external;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

interface IValidatorSet {

    function getValidators() external view returns (address[] memory);

    function deposit(address validator) external payable;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.7;

contract Multicall {

    function multicall(bytes[] calldata data) external returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            // this is an optimized a bit multicall w/o using of Address library (it safes a lot of bytecode)
            results[i] = _selfDelegateCall(data[i]);
        }
        return results;
    }

    function _selfDelegateCall(bytes memory data) internal returns (bytes memory _result) {
        (bool success, bytes memory returnData) = address(this).delegatecall(data);
        if (success) {
            return returnData;
        }
        if (returnData.length > 0) {
            assembly {
                revert(add(32, returnData), mload(returnData))
            }
        } else {
            revert();
        }
    }
}