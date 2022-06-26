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

import "./InjectorContextHolder.sol";


contract Staking is InjectorContextHolder, IStaking {


    /**
     * This constant indicates precision of storing compact balances in the storage or floating point. Since default
     * balance precision is 256 bits it might gain some overhead on the storage because we don't need to store such huge
     * amount range. That is why we compact balances in uint112 values instead of uint256. By managing this value
     * you can set the precision of your balances, aka min and max possible staking amount. This value depends
     * mostly on your asset price in USD, for example ETH costs 4000$ then if we use 1 ether precision it takes 4000$
     * as min amount that might be problematic for users to do the stake. We can set 1 gwei precision and in this case
     * we increase min staking amount in 1e9 times, but also decreases max staking amount or total amount of staked assets.
     *
     * Here is an universal formula, if your asset is cheap in USD equivalent, like ~1$, then use 1 ether precision,
     * otherwise it might be better to use 1 gwei precision or any other amount that your want.
     *
     * Also be careful with setting `minValidatorStakeAmount` and `minStakingAmount`, because these values has
     * the same precision as specified here. It means that if you set precision 1 ether, then min staking amount of 10
     * tokens should have 10 raw value. For 1 gwei precision 10 tokens min amount should be stored as 10000000000.
     *
     * For the 112 bits we have ~32 decimals lg(2**112)=33.71 (lets round to 32 for simplicity). We split this amount
     * into integer (24) and for fractional (8) parts. It means that we can have only 8 decimals after zero.
     *
     * Based in current params we have next min/max values:
     * - min staking amount: 0.00000001 or 1e-8
     * - max staking amount: 1000000000000000000000000 or 1e+24
     *
     * WARNING: precision must be a 1eN format (A=1, N>0)
     */
    uint256 internal constant BALANCE_COMPACT_PRECISION = 1e10;
    /**
     * Here is min/max commission rates. Lets don't allow to set more than 30% of validator commission, because it's
     * too big commission for validator. Commission rate is a percents divided by 100 stored with 0 decimals as percents*100 (=pc/1e2*1e4)
     *
     * Here is some examples:
     * + 0.3% => 0.3*100=30
     * + 3% => 3*100=300
     * + 30% => 30*100=3000
     */
    uint16 internal constant COMMISSION_RATE_MIN_VALUE = 0; // 0%
    uint16 internal constant COMMISSION_RATE_MAX_VALUE = 3000; // 30%
    /**
     * This gas limit is used for internal transfers, BSC doesn't support berlin and it
     * might cause problems with smart contracts who used to stake transparent proxies or
     * beacon proxies that have a lot of expensive SLOAD instructions.
     */
    uint64 internal constant TRANSFER_GAS_LIMIT = 30_000;
    /**
     * Some items are stored in the queues and we must iterate though them to
     * execute one by one. Somtimes gas might not be enough for the tx execution.
     */
    uint32 internal constant CLAIM_BEFORE_GAS = 100_000;

    // validator events
    event ValidatorAdded(address indexed validator, address owner, uint8 status, uint16 commissionRate);
    event ValidatorModified(address indexed validator, address owner, uint8 status, uint16 commissionRate);
    event ValidatorRemoved(address indexed validator);
    event ValidatorOwnerClaimed(address indexed validator, uint256 amount, uint64 epoch);
    event ValidatorSlashed(address indexed validator, uint32 slashes, uint64 epoch);
    event ValidatorJailed(address indexed validator, uint64 epoch);
    event ValidatorDeposited(address indexed validator, uint256 amount, uint64 epoch);
    event ValidatorReleased(address indexed validator, uint64 epoch);

    // staker events
    event Delegated(address indexed validator, address indexed staker, uint256 amount, uint64 epoch);
    event Undelegated(address indexed validator, address indexed staker, uint256 amount, uint64 epoch);
    event Claimed(address indexed validator, address indexed staker, uint256 amount, uint64 epoch);
    event Redelegated(address indexed validator, address indexed staker, uint256 amount, uint256 dust, uint64 epoch);

    enum ValidatorStatus {
        NotFound,
        Active,
        Pending,
        Jail
    }

    struct ValidatorSnapshot {
        uint96 totalRewards;
        uint112 totalDelegated;
        uint32 slashesCount;
        uint16 commissionRate;
    }

    struct Validator {
        address validatorAddress;
        address ownerAddress;
        ValidatorStatus status;
        uint64 changedAt;
        uint64 jailedBefore;
        uint64 claimedAt;
    }

    struct DelegationOpDelegate {
        uint112 amount;
        uint64 epoch;
    }

    struct DelegationOpUndelegate {
        uint112 amount;
        uint64 epoch;
    }

    struct ValidatorDelegation {
        DelegationOpDelegate[] delegateQueue;
        uint64 delegateGap;
        DelegationOpUndelegate[] undelegateQueue;
        uint64 undelegateGap;
    }

    // mapping from validator address to validator
    mapping(address => Validator) internal _validatorsMap;
    // mapping from validator owner to validator address
    mapping(address => address) internal _validatorOwners;
    // list of all validators that are in validators mapping
    address[] internal _activeValidatorsList;
    // mapping with stakers to validators at epoch (validator -> delegator -> delegation)
    mapping(address => mapping(address => ValidatorDelegation)) internal _validatorDelegations;
    // mapping with validator snapshots per each epoch (validator -> epoch -> snapshot)
    mapping(address => mapping(uint64 => ValidatorSnapshot)) internal _validatorSnapshots;

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

    function initialize(address[] calldata validators, address[] calldata owners, uint256[] calldata initialStakes, uint16 commissionRate) external initializer {
        require(validators.length == owners.length && validators.length == initialStakes.length);
        uint256 totalStakes = 0;
        for (uint256 i = 0; i < validators.length; i++) {
            _addValidator(validators[i], owners[i], ValidatorStatus.Active, commissionRate, initialStakes[i], 0);
            totalStakes += initialStakes[i];
        }
        require(address(this).balance == totalStakes);
    }

    function getValidatorDelegation(address validatorAddress, address delegator) external view override returns (
        uint256 delegatedAmount,
        uint64 atEpoch
    ) {
        ValidatorDelegation memory delegation = _validatorDelegations[validatorAddress][delegator];
        if (delegation.delegateQueue.length == 0) {
            return (delegatedAmount = 0, atEpoch = 0);
        }
        DelegationOpDelegate memory snapshot = delegation.delegateQueue[delegation.delegateQueue.length - 1];
        return (delegatedAmount = uint256(snapshot.amount) * BALANCE_COMPACT_PRECISION, atEpoch = snapshot.epoch);
    }

    function getValidatorStatus(address validatorAddress) external view override returns (
        address ownerAddress,
        uint8 status,
        uint256 totalDelegated,
        uint32 slashesCount,
        uint64 changedAt,
        uint64 jailedBefore,
        uint64 claimedAt,
        uint16 commissionRate,
        uint96 totalRewards
    ) {
        Validator memory validator = _validatorsMap[validatorAddress];
        ValidatorSnapshot memory snapshot = _validatorSnapshots[validator.validatorAddress][validator.changedAt];
        return (
        ownerAddress = validator.ownerAddress,
        status = uint8(validator.status),
        totalDelegated = uint256(snapshot.totalDelegated) * BALANCE_COMPACT_PRECISION,
        slashesCount = snapshot.slashesCount,
        changedAt = validator.changedAt,
        jailedBefore = validator.jailedBefore,
        claimedAt = validator.claimedAt,
        commissionRate = snapshot.commissionRate,
        totalRewards = snapshot.totalRewards
        );
    }

    function getValidatorStatusAtEpoch(address validatorAddress, uint64 epoch) external view returns (
        address ownerAddress,
        uint8 status,
        uint256 totalDelegated,
        uint32 slashesCount,
        uint64 changedAt,
        uint64 jailedBefore,
        uint64 claimedAt,
        uint16 commissionRate,
        uint96 totalRewards
    ) {
        Validator memory validator = _validatorsMap[validatorAddress];
        ValidatorSnapshot memory snapshot = _touchValidatorSnapshotImmutable(validator, epoch);
        return (
        ownerAddress = validator.ownerAddress,
        status = uint8(validator.status),
        totalDelegated = uint256(snapshot.totalDelegated) * BALANCE_COMPACT_PRECISION,
        slashesCount = snapshot.slashesCount,
        changedAt = validator.changedAt,
        jailedBefore = validator.jailedBefore,
        claimedAt = validator.claimedAt,
        commissionRate = snapshot.commissionRate,
        totalRewards = snapshot.totalRewards
        );
    }

    function getValidatorByOwner(address owner) external view override returns (address) {
        return _validatorOwners[owner];
    }

    function releaseValidatorFromJail(address validatorAddress) external override {
        // make sure validator is in jail
        Validator memory validator = _validatorsMap[validatorAddress];
        require(validator.status == ValidatorStatus.Jail, "bad status");
        // only validator owner
        require(msg.sender == validator.ownerAddress, "only owner");
        require(currentEpoch() >= validator.jailedBefore, "still in jail");
        // release validator from jail
        _releaseValidatorFromJail(validator);
    }

    function forceUnJailValidator(address validatorAddress) external onlyFromGovernance {
        // make sure validator is in jail
        Validator memory validator = _validatorsMap[validatorAddress];
        require(validator.status == ValidatorStatus.Jail, "bad status");
        // release validator from jail
        _releaseValidatorFromJail(validator);
    }

    function _releaseValidatorFromJail(Validator memory validator) internal {
        address validatorAddress = validator.validatorAddress;
        // update validator status
        validator.status = ValidatorStatus.Active;
        validator.jailedBefore = 0;
        _validatorsMap[validatorAddress] = validator;
        _activeValidatorsList.push(validatorAddress);
        // emit event
        emit ValidatorReleased(validatorAddress, currentEpoch());
    }

    function delegate(address validatorAddress) payable external override {
        _delegateTo(msg.sender, validatorAddress, msg.value);
    }

    function undelegate(address validatorAddress, uint256 amount) external override {
        _undelegateFrom(msg.sender, validatorAddress, amount);
    }

    function currentEpoch() public view returns (uint64) {
        return uint64(block.number / _CHAIN_CONFIG_CONTRACT.getEpochBlockInterval());
    }

    function nextEpoch() public view returns (uint64) {
        return currentEpoch() + 1;
    }

    function _touchValidatorSnapshot(Validator memory validator, uint64 epoch) internal returns (ValidatorSnapshot storage) {
        ValidatorSnapshot storage snapshot = _validatorSnapshots[validator.validatorAddress][epoch];
        // if snapshot is already initialized then just return it
        if (snapshot.totalDelegated > 0) {
            return snapshot;
        }
        // find previous snapshot to copy parameters from it
        ValidatorSnapshot memory lastModifiedSnapshot = _validatorSnapshots[validator.validatorAddress][validator.changedAt];
        // last modified snapshot might store zero value, for first delegation it might happen and its not critical
        snapshot.totalDelegated = lastModifiedSnapshot.totalDelegated;
        snapshot.commissionRate = lastModifiedSnapshot.commissionRate;
        // we must save last affected epoch for this validator to be able to restore total delegated
        // amount in the future (check condition upper)
        if (epoch > validator.changedAt) {
            validator.changedAt = epoch;
        }
        return snapshot;
    }

    function _touchValidatorSnapshotImmutable(Validator memory validator, uint64 epoch) internal view returns (ValidatorSnapshot memory) {
        ValidatorSnapshot memory snapshot = _validatorSnapshots[validator.validatorAddress][epoch];
        // if snapshot is already initialized then just return it
        if (snapshot.totalDelegated > 0) {
            return snapshot;
        }
        // find previous snapshot to copy parameters from it
        ValidatorSnapshot memory lastModifiedSnapshot = _validatorSnapshots[validator.validatorAddress][validator.changedAt];
        // last modified snapshot might store zero value, for first delegation it might happen and its not critical
        snapshot.totalDelegated = lastModifiedSnapshot.totalDelegated;
        snapshot.commissionRate = lastModifiedSnapshot.commissionRate;
        // return existing or new snapshot
        return snapshot;
    }

    function _delegateTo(address fromDelegator, address toValidator, uint256 amount) internal {
        // check is minimum delegate amount
        require(amount >= _CHAIN_CONFIG_CONTRACT.getMinStakingAmount() && amount != 0, "too low");
        require(amount % BALANCE_COMPACT_PRECISION == 0, "no remainder");
        // make sure amount is greater than min staking amount
        // make sure validator exists at least
        Validator memory validator = _validatorsMap[toValidator];
        require(validator.status != ValidatorStatus.NotFound, "not found");
        uint64 atEpoch = nextEpoch();
        // Lets upgrade next snapshot parameters:
        // + find snapshot for the next epoch after current block
        // + increase total delegated amount in the next epoch for this validator
        // + re-save validator because last affected epoch might change
        ValidatorSnapshot storage validatorSnapshot = _touchValidatorSnapshot(validator, atEpoch);
        validatorSnapshot.totalDelegated += uint112(amount / BALANCE_COMPACT_PRECISION);
        _validatorsMap[toValidator] = validator;
        // if last pending delegate has the same next epoch then its safe to just increase total
        // staked amount because it can't affect current validator set, but otherwise we must create
        // new record in delegation queue with the last epoch (delegations are ordered by epoch)
        ValidatorDelegation storage delegation = _validatorDelegations[toValidator][fromDelegator];
        if (delegation.delegateQueue.length > 0) {
            DelegationOpDelegate storage recentDelegateOp = delegation.delegateQueue[delegation.delegateQueue.length - 1];
            // if we already have pending snapshot for the next epoch then just increase new amount,
            // otherwise create next pending snapshot. (tbh it can't be greater, but what we can do here instead?)
            if (recentDelegateOp.epoch >= atEpoch) {
                recentDelegateOp.amount += uint112(amount / BALANCE_COMPACT_PRECISION);
            } else {
                delegation.delegateQueue.push(DelegationOpDelegate({epoch : atEpoch, amount : recentDelegateOp.amount + uint112(amount / BALANCE_COMPACT_PRECISION)}));
            }
        } else {
            // there is no any delegations at al, lets create the first one
            delegation.delegateQueue.push(DelegationOpDelegate({epoch : atEpoch, amount : uint112(amount / BALANCE_COMPACT_PRECISION)}));
        }
        // emit event with the next epoch
        emit Delegated(toValidator, fromDelegator, amount, atEpoch);
    }

    function _undelegateFrom(address toDelegator, address fromValidator, uint256 amount) internal {
        // check minimum delegate amount
        require(amount >= _CHAIN_CONFIG_CONTRACT.getMinStakingAmount() && amount != 0, "too low");
        require(amount % BALANCE_COMPACT_PRECISION == 0, "no remainder");
        // make sure validator exists at least
        Validator memory validator = _validatorsMap[fromValidator];
        uint64 beforeEpoch = nextEpoch();
        // Lets upgrade next snapshot parameters:
        // + find snapshot for the next epoch after current block
        // + increase total delegated amount in the next epoch for this validator
        // + re-save validator because last affected epoch might change
        ValidatorSnapshot storage validatorSnapshot = _touchValidatorSnapshot(validator, beforeEpoch);
        require(validatorSnapshot.totalDelegated >= uint112(amount / BALANCE_COMPACT_PRECISION), "insufficient balance");
        validatorSnapshot.totalDelegated -= uint112(amount / BALANCE_COMPACT_PRECISION);
        _validatorsMap[fromValidator] = validator;
        // if last pending delegate has the same next epoch then its safe to just increase total
        // staked amount because it can't affect current validator set, but otherwise we must create
        // new record in delegation queue with the last epoch (delegations are ordered by epoch)
        ValidatorDelegation storage delegation = _validatorDelegations[fromValidator][toDelegator];
        require(delegation.delegateQueue.length > 0, "insufficient balance");
        DelegationOpDelegate storage recentDelegateOp = delegation.delegateQueue[delegation.delegateQueue.length - 1];
        require(recentDelegateOp.amount >= uint64(amount / BALANCE_COMPACT_PRECISION), "insufficient balance");
        uint112 nextDelegatedAmount = recentDelegateOp.amount - uint112(amount / BALANCE_COMPACT_PRECISION);
        if (recentDelegateOp.epoch >= beforeEpoch) {
            // decrease total delegated amount for the next epoch
            recentDelegateOp.amount = nextDelegatedAmount;
        } else {
            // there is no pending delegations, so lets create the new one with the new amount
            delegation.delegateQueue.push(DelegationOpDelegate({epoch : beforeEpoch, amount : nextDelegatedAmount}));
        }
        // create new undelegate queue operation with soft lock
        delegation.undelegateQueue.push(DelegationOpUndelegate({amount : uint112(amount / BALANCE_COMPACT_PRECISION), epoch : beforeEpoch + _CHAIN_CONFIG_CONTRACT.getUndelegatePeriod()}));
        // emit event with the next epoch number
        emit Undelegated(fromValidator, toDelegator, amount, beforeEpoch);
    }

    function _transferDelegatorRewards(address validator, address delegator, uint64 beforeEpochExclude, bool withRewards, bool withUndelegates) internal {
        ValidatorDelegation storage delegation = _validatorDelegations[validator][delegator];
        // claim rewards and undelegates
        uint256 availableFunds = 0;
        if (withRewards) {
            availableFunds += _processDelegateQueue(validator, delegation, beforeEpochExclude);
        }
        if (withUndelegates) {
            availableFunds += _processUndelegateQueue(delegation, beforeEpochExclude);
        }
        // for transfer claim mode just all rewards to the user
        _safeTransferWithGasLimit(payable(delegator), availableFunds);
        // emit event
        emit Claimed(validator, delegator, availableFunds, beforeEpochExclude);
    }

    function _redelegateDelegatorRewards(address validator, address delegator, uint64 beforeEpochExclude, bool withRewards, bool withUndelegates) internal {
        ValidatorDelegation storage delegation = _validatorDelegations[validator][delegator];
        // claim rewards and undelegates
        uint256 availableFunds = 0;
        if (withRewards) {
            availableFunds += _processDelegateQueue(validator, delegation, beforeEpochExclude);
        }
        if (withUndelegates) {
            availableFunds += _processUndelegateQueue(delegation, beforeEpochExclude);
        }
        (uint256 amountToStake, uint256 rewardsDust) = _calcAvailableForRedelegateAmount(availableFunds);
        // if we have something to re-stake then delegate it to the validator
        if (amountToStake > 0) {
            _delegateTo(delegator, validator, amountToStake);
        }
        // if we have dust from staking then send it to user (we can't keep them in the contract)
        if (rewardsDust > 0) {
            _safeTransferWithGasLimit(payable(delegator), rewardsDust);
        }
        // emit event
        emit Redelegated(validator, delegator, amountToStake, rewardsDust, beforeEpochExclude);
    }

    function _processDelegateQueue(address validator, ValidatorDelegation storage delegation, uint64 beforeEpochExclude) internal returns (uint256 availableFunds) {
        uint64 delegateGap = delegation.delegateGap;
        for (uint256 queueLength = delegation.delegateQueue.length; delegateGap < queueLength && gasleft() > CLAIM_BEFORE_GAS;) {
            DelegationOpDelegate memory delegateOp = delegation.delegateQueue[delegateGap];
            if (delegateOp.epoch >= beforeEpochExclude) {
                break;
            }
            uint256 voteChangedAtEpoch = 0;
            if (delegateGap < queueLength - 1) {
                voteChangedAtEpoch = delegation.delegateQueue[delegateGap + 1].epoch;
            }
            for (; delegateOp.epoch < beforeEpochExclude && (voteChangedAtEpoch == 0 || delegateOp.epoch < voteChangedAtEpoch) && gasleft() > CLAIM_BEFORE_GAS; delegateOp.epoch++) {
                ValidatorSnapshot memory validatorSnapshot = _validatorSnapshots[validator][delegateOp.epoch];
                if (validatorSnapshot.totalDelegated == 0) {
                    continue;
                }
                (uint256 delegatorFee, /*uint256 ownerFee*/, /*uint256 systemFee*/) = _calcValidatorSnapshotEpochPayout(validatorSnapshot);
                availableFunds += delegatorFee * delegateOp.amount / validatorSnapshot.totalDelegated;
            }
            // if we have reached end of the delegation list then lets stay on the last item, but with updated latest processed epoch
            if (delegateGap >= queueLength - 1) {
                delegation.delegateQueue[delegateGap] = delegateOp;
                break;
            }
            delete delegation.delegateQueue[delegateGap];
            ++delegateGap;
        }
        delegation.delegateGap = delegateGap;
        return availableFunds;
    }

    function _processUndelegateQueue(ValidatorDelegation storage delegation, uint64 beforeEpochExclude) internal returns (uint256 availableFunds) {
        uint64 undelegateGap = delegation.undelegateGap;
        for (uint256 queueLength = delegation.undelegateQueue.length; undelegateGap < queueLength  && gasleft() > CLAIM_BEFORE_GAS;) {
            DelegationOpUndelegate memory undelegateOp = delegation.undelegateQueue[undelegateGap];
            if (undelegateOp.epoch > beforeEpochExclude) {
                break;
            }
            availableFunds += uint256(undelegateOp.amount) * BALANCE_COMPACT_PRECISION;
            delete delegation.undelegateQueue[undelegateGap];
            ++undelegateGap;
        }
        delegation.undelegateGap = undelegateGap;
        return availableFunds;
    }

    function _calcDelegatorRewardsAndPendingUndelegates(address validator, address delegator, uint64 beforeEpoch, bool withUndelegate) internal view returns (uint256) {
        ValidatorDelegation memory delegation = _validatorDelegations[validator][delegator];
        uint256 availableFunds = 0;
        // process delegate queue to calculate staking rewards
        while (delegation.delegateGap < delegation.delegateQueue.length) {
            DelegationOpDelegate memory delegateOp = delegation.delegateQueue[delegation.delegateGap];
            if (delegateOp.epoch >= beforeEpoch) {
                break;
            }
            uint256 voteChangedAtEpoch = 0;
            if (delegation.delegateGap < delegation.delegateQueue.length - 1) {
                voteChangedAtEpoch = delegation.delegateQueue[delegation.delegateGap + 1].epoch;
            }
            for (; delegateOp.epoch < beforeEpoch && (voteChangedAtEpoch == 0 || delegateOp.epoch < voteChangedAtEpoch); delegateOp.epoch++) {
                ValidatorSnapshot memory validatorSnapshot = _validatorSnapshots[validator][delegateOp.epoch];
                if (validatorSnapshot.totalDelegated == 0) {
                    continue;
                }
                (uint256 delegatorFee, /*uint256 ownerFee*/, /*uint256 systemFee*/) = _calcValidatorSnapshotEpochPayout(validatorSnapshot);
                availableFunds += delegatorFee * delegateOp.amount / validatorSnapshot.totalDelegated;
            }
            ++delegation.delegateGap;
        }
        // process all items from undelegate queue
        while (withUndelegate && delegation.undelegateGap < delegation.undelegateQueue.length) {
            DelegationOpUndelegate memory undelegateOp = delegation.undelegateQueue[delegation.undelegateGap];
            if (undelegateOp.epoch > beforeEpoch) {
                break;
            }
            availableFunds += uint256(undelegateOp.amount) * BALANCE_COMPACT_PRECISION;
            ++delegation.undelegateGap;
        }
        // return available for claim funds
        return availableFunds;
    }

    function _claimValidatorOwnerRewards(Validator storage validator, uint64 beforeEpoch) internal {
        uint256 availableFunds = 0;
        uint256 systemFee = 0;
        uint64 claimAt = validator.claimedAt;
        for (; claimAt < beforeEpoch && gasleft() > CLAIM_BEFORE_GAS; claimAt++) {
            ValidatorSnapshot memory validatorSnapshot = _validatorSnapshots[validator.validatorAddress][claimAt];
            (/*uint256 delegatorFee*/, uint256 ownerFee, uint256 slashingFee) = _calcValidatorSnapshotEpochPayout(validatorSnapshot);
            availableFunds += ownerFee;
            systemFee += slashingFee;
        }
        validator.claimedAt = claimAt;
        _safeTransferWithGasLimit(payable(validator.ownerAddress), availableFunds);

        emit ValidatorOwnerClaimed(validator.validatorAddress, availableFunds, beforeEpoch);
    }

    function _calcValidatorOwnerRewards(Validator memory validator, uint64 beforeEpoch) internal view returns (uint256) {
        uint256 availableFunds = 0;
        for (; validator.claimedAt < beforeEpoch; validator.claimedAt++) {
            ValidatorSnapshot memory validatorSnapshot = _validatorSnapshots[validator.validatorAddress][validator.claimedAt];
            (/*uint256 delegatorFee*/, uint256 ownerFee, /*uint256 systemFee*/) = _calcValidatorSnapshotEpochPayout(validatorSnapshot);
            availableFunds += ownerFee;
        }
        return availableFunds;
    }

    function _calcValidatorSnapshotEpochPayout(ValidatorSnapshot memory validatorSnapshot) internal view returns (uint256 delegatorFee, uint256 ownerFee, uint256 systemFee) {
        // detect validator slashing to transfer all rewards to treasury
        if (validatorSnapshot.slashesCount >= _CHAIN_CONFIG_CONTRACT.getMisdemeanorThreshold()) {
            return (delegatorFee = 0, ownerFee = 0, systemFee = validatorSnapshot.totalRewards);
        } else if (validatorSnapshot.totalDelegated == 0) {
            return (delegatorFee = 0, ownerFee = validatorSnapshot.totalRewards, systemFee = 0);
        }
        // ownerFee_(18+4-4=18) = totalRewards_18 * commissionRate_4 / 1e4
        ownerFee = uint256(validatorSnapshot.totalRewards) * validatorSnapshot.commissionRate / 1e4;
        // delegatorRewards = totalRewards - ownerFee
        delegatorFee = validatorSnapshot.totalRewards - ownerFee;
        // default system fee is zero for epoch
        systemFee = 0;
    }

    function registerValidator(address validatorAddress, uint16 commissionRate) payable external override {
        uint256 initialStake = msg.value;
        // // initial stake amount should be greater than minimum validator staking amount
        require(initialStake >= _CHAIN_CONFIG_CONTRACT.getMinValidatorStakeAmount(), "too low");
        require(initialStake % BALANCE_COMPACT_PRECISION == 0, "no remainder");
        // add new validator as pending
        _addValidator(validatorAddress, msg.sender, ValidatorStatus.Pending, commissionRate, initialStake, nextEpoch());
    }

    function addValidator(address account) external onlyFromGovernance virtual override {
        _addValidator(account, account, ValidatorStatus.Active, 0, 0, nextEpoch());
    }

    function _addValidator(address validatorAddress, address validatorOwner, ValidatorStatus status, uint16 commissionRate, uint256 initialStake, uint64 sinceEpoch) internal {
        // validator commission rate
        require(commissionRate >= COMMISSION_RATE_MIN_VALUE && commissionRate <= COMMISSION_RATE_MAX_VALUE, "bad commission");
        // init validator default params
        Validator memory validator = _validatorsMap[validatorAddress];
        require(_validatorsMap[validatorAddress].status == ValidatorStatus.NotFound, "already exist");
        validator.validatorAddress = validatorAddress;
        validator.ownerAddress = validatorOwner;
        validator.status = status;
        validator.changedAt = sinceEpoch;
        _validatorsMap[validatorAddress] = validator;
        // save validator owner
        require(_validatorOwners[validatorOwner] == address(0x00), "owner in use");
        _validatorOwners[validatorOwner] = validatorAddress;
        // add new validator to array
        if (status == ValidatorStatus.Active) {
            _activeValidatorsList.push(validatorAddress);
        }
        // push initial validator snapshot at zero epoch with default params
        _validatorSnapshots[validatorAddress][sinceEpoch] = ValidatorSnapshot(0, uint112(initialStake / BALANCE_COMPACT_PRECISION), 0, commissionRate);
        // delegate initial stake to validator owner
        ValidatorDelegation storage delegation = _validatorDelegations[validatorAddress][validatorOwner];
        require(delegation.delegateQueue.length == 0);
        delegation.delegateQueue.push(DelegationOpDelegate(uint112(initialStake / BALANCE_COMPACT_PRECISION), sinceEpoch));
        emit Delegated(validatorAddress, validatorOwner, initialStake, sinceEpoch);
        // emit event
        emit ValidatorAdded(validatorAddress, validatorOwner, uint8(status), commissionRate);
    }

    function removeValidator(address account) external onlyFromGovernance virtual override {
        Validator memory validator = _validatorsMap[account];
        require(validator.status != ValidatorStatus.NotFound, "not found");
        // don't allow to remove validator w/ active delegations
        ValidatorSnapshot memory snapshot = _validatorSnapshots[validator.validatorAddress][validator.changedAt];
        require(snapshot.totalDelegated == 0, "has delegations");
        // remove validator from active list if exists
        _removeValidatorFromActiveList(account);
        // remove from validators map
        delete _validatorOwners[validator.ownerAddress];
        delete _validatorsMap[account];
        // emit event about it
        emit ValidatorRemoved(account);
    }

    function _removeValidatorFromActiveList(address validatorAddress) internal {
        // find index of validator in validator set
        int256 indexOf = - 1;
        for (uint256 i = 0; i < _activeValidatorsList.length; i++) {
            if (_activeValidatorsList[i] != validatorAddress) continue;
            indexOf = int256(i);
            break;
        }
        // remove validator from array (since we remove only active it might not exist in the list)
        if (indexOf >= 0) {
            if (_activeValidatorsList.length > 1 && uint256(indexOf) != _activeValidatorsList.length - 1) {
                _activeValidatorsList[uint256(indexOf)] = _activeValidatorsList[_activeValidatorsList.length - 1];
            }
            _activeValidatorsList.pop();
        }
    }

    function activateValidator(address validatorAddress) external onlyFromGovernance virtual override {
        Validator memory validator = _validatorsMap[validatorAddress];
        require(_validatorsMap[validatorAddress].status == ValidatorStatus.Pending, "bad status");
        _activeValidatorsList.push(validatorAddress);
        validator.status = ValidatorStatus.Active;
        _validatorsMap[validatorAddress] = validator;
        ValidatorSnapshot storage snapshot = _touchValidatorSnapshot(validator, nextEpoch());
        emit ValidatorModified(validatorAddress, validator.ownerAddress, uint8(validator.status), snapshot.commissionRate);
    }

    function disableValidator(address validatorAddress) external onlyFromGovernance virtual override {
        Validator memory validator = _validatorsMap[validatorAddress];
        require(validator.status == ValidatorStatus.Active || validator.status == ValidatorStatus.Jail, "bad status");
        _removeValidatorFromActiveList(validatorAddress);
        validator.status = ValidatorStatus.Pending;
        _validatorsMap[validatorAddress] = validator;
        ValidatorSnapshot storage snapshot = _touchValidatorSnapshot(validator, nextEpoch());
        emit ValidatorModified(validatorAddress, validator.ownerAddress, uint8(validator.status), snapshot.commissionRate);
    }

    function isValidatorActive(address account) external override view returns (bool) {
        if (_validatorsMap[account].status != ValidatorStatus.Active) {
            return false;
        }
        address[] memory topValidators = getValidators();
        for (uint256 i = 0; i < topValidators.length; i++) {
            if (topValidators[i] == account) return true;
        }
        return false;
    }

    function isValidator(address account) external override view returns (bool) {
        return _validatorsMap[account].status != ValidatorStatus.NotFound;
    }

    function getValidators() public view override returns (address[] memory) {
        uint256 n = _activeValidatorsList.length;
        address[] memory orderedValidators = new address[](n);
        for (uint256 i = 0; i < n; i++) {
            orderedValidators[i] = _activeValidatorsList[i];
        }
        // we need to select k top validators out of n
        uint256 k = _CHAIN_CONFIG_CONTRACT.getActiveValidatorsLength();
        if (k > n) {
            k = n;
        }
        for (uint256 i = 0; i < k; i++) {
            uint256 nextValidator = i;
            Validator memory currentMax = _validatorsMap[orderedValidators[nextValidator]];
            ValidatorSnapshot memory maxSnapshot = _validatorSnapshots[currentMax.validatorAddress][currentMax.changedAt];
            for (uint256 j = i + 1; j < n; j++) {
                Validator memory current = _validatorsMap[orderedValidators[j]];
                ValidatorSnapshot memory currentSnapshot = _validatorSnapshots[current.validatorAddress][current.changedAt];
                if (maxSnapshot.totalDelegated < currentSnapshot.totalDelegated) {
                    nextValidator = j;
                    currentMax = current;
                    maxSnapshot = currentSnapshot;
                }
            }
            address backup = orderedValidators[i];
            orderedValidators[i] = orderedValidators[nextValidator];
            orderedValidators[nextValidator] = backup;
        }
        // this is to cut array to first k elements without copying
        assembly {
            mstore(orderedValidators, k)
        }
        return orderedValidators;
    }

    function deposit(address validatorAddress) external payable  virtual override {
        _depositFee(validatorAddress);
    }

    function _depositFee(address validatorAddress) internal {
        require(msg.value > 0);
        // make sure validator is active
        Validator memory validator = _validatorsMap[validatorAddress];
        require(validator.status != ValidatorStatus.NotFound, "not found");
        uint64 epoch = currentEpoch();
        // increase total pending rewards for validator for current epoch
        ValidatorSnapshot storage currentSnapshot = _touchValidatorSnapshot(validator, epoch);
        currentSnapshot.totalRewards += uint96(msg.value);
        // emit event
        emit ValidatorDeposited(validatorAddress, msg.value, epoch);
    }

    function getValidatorFee(address validatorAddress) external override view returns (uint256) {
        // make sure validator exists at least
        Validator memory validator = _validatorsMap[validatorAddress];
        if (validator.status == ValidatorStatus.NotFound) {
            return 0;
        }
        // calc validator rewards
        return _calcValidatorOwnerRewards(validator, currentEpoch());
    }

    function getPendingValidatorFee(address validatorAddress) external override view returns (uint256) {
        // make sure validator exists at least
        Validator memory validator = _validatorsMap[validatorAddress];
        if (validator.status == ValidatorStatus.NotFound) {
            return 0;
        }
        // calc validator rewards
        return _calcValidatorOwnerRewards(validator, nextEpoch());
    }

    function claimValidatorFee(address validatorAddress) external override {
        // make sure validator exists at least
        Validator storage validator = _validatorsMap[validatorAddress];
        // only validator owner can claim deposit fee
        require(msg.sender == validator.ownerAddress, "only owner");
        // claim all validator fees
        _claimValidatorOwnerRewards(validator, currentEpoch());
    }

    function getDelegatorFee(address validatorAddress, address delegatorAddress) external override view returns (uint256) {
        return _calcDelegatorRewardsAndPendingUndelegates(validatorAddress, delegatorAddress, currentEpoch(), true);
    }

    function getPendingDelegatorFee(address validatorAddress, address delegatorAddress) external override view returns (uint256) {
        return _calcDelegatorRewardsAndPendingUndelegates(validatorAddress, delegatorAddress, nextEpoch(), true);
    }

    function claimDelegatorFee(address validatorAddress) external override {
        // claim all confirmed delegator fees including undelegates
        _transferDelegatorRewards(validatorAddress, msg.sender, currentEpoch(), true, true);
    }

    function claimPendingUndelegates(address validator) external override {
        // claim only pending undelegates
        _transferDelegatorRewards(validator, msg.sender, currentEpoch(), false, true);
    }

    function _calcAvailableForRedelegateAmount(uint256 claimableRewards) internal view returns (uint256 amountToStake, uint256 rewardsDust) {
        // for redelegate we must split amount into stake-able and dust
        amountToStake = (claimableRewards / BALANCE_COMPACT_PRECISION) * BALANCE_COMPACT_PRECISION;
        if (amountToStake < _CHAIN_CONFIG_CONTRACT.getMinStakingAmount()) {
            return (0, claimableRewards);
        }
        // if we have dust remaining after re-stake then send it to user (we can't keep it in the contract)
        return (amountToStake, claimableRewards - amountToStake);
    }

    function calcAvailableForRedelegateAmount(address validator, address delegator) external view override returns (uint256 amountToStake, uint256 rewardsDust) {
        uint256 claimableRewards = _calcDelegatorRewardsAndPendingUndelegates(validator, delegator, currentEpoch(), false);
        return _calcAvailableForRedelegateAmount(claimableRewards);
    }

    function redelegateDelegatorFee(address validator) external override {
        // claim rewards in the redelegate mode (check function code for more info)
        _redelegateDelegatorRewards(validator, msg.sender, currentEpoch(), true, false);
    }

    function _safeTransferWithGasLimit(address payable recipient, uint256 amount) internal virtual {
        (bool success,) = recipient.call{value : amount, gas : TRANSFER_GAS_LIMIT}("");
        require(success);
    }

    function _unsafeTransfer(address payable recipient, uint256 amount) internal virtual {
        (bool success,) = payable(address(recipient)).call{value : amount}("");
        require(success);
    }

    function slash(address validatorAddress) external onlyFromSlashingIndicator virtual override {
        _slashValidator(validatorAddress);
    }

    function _slashValidator(address validatorAddress) internal {
        // make sure validator exists
        Validator memory validator = _validatorsMap[validatorAddress];
        require(validator.status != ValidatorStatus.NotFound, "not found");
        uint64 epoch = currentEpoch();
        // increase slashes for current epoch
        ValidatorSnapshot storage currentSnapshot = _touchValidatorSnapshot(validator, epoch);
        uint32 slashesCount = currentSnapshot.slashesCount + 1;
        currentSnapshot.slashesCount = slashesCount;
        // if validator has a lot of misses then put it in jail for 1 week (if epoch is 1 day)
        if (slashesCount == _CHAIN_CONFIG_CONTRACT.getFelonyThreshold()) {
            validator.jailedBefore = currentEpoch() + _CHAIN_CONFIG_CONTRACT.getValidatorJailEpochLength();
            validator.status = ValidatorStatus.Jail;
            _removeValidatorFromActiveList(validatorAddress);
            _validatorsMap[validatorAddress] = validator;
            emit ValidatorJailed(validatorAddress, epoch);
        } else {
            // validator state might change, lets update it
            _validatorsMap[validatorAddress] = validator;
        }
        // emit event
        emit ValidatorSlashed(validatorAddress, slashesCount, epoch);
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "./interfaces/IInjectorContextHolder.sol";
import "./interfaces/IStaking.sol";
import "./interfaces/IStakingPool.sol";

import "./InjectorContextHolder.sol";
import "./Staking.sol";

contract StakingPool is InjectorContextHolder, IStakingPool {

    event Stake(address indexed validator, address indexed staker, uint256 amount);
    event Unstake(address indexed validator, address indexed staker, uint256 amount);
    event Claim(address indexed validator, address indexed staker, uint256 amount);

    struct ValidatorPool {
        address validatorAddress;
        uint256 sharesSupply;
        uint256 totalStakedAmount;
        uint256 dustRewards;
        uint256 pendingUnstake;
    }

    struct PendingUnstake {
        uint256 amount;
        uint256 shares;
        uint64 epoch;
    }

    // validator pools (validator => pool)
    mapping(address => ValidatorPool) internal _validatorPools;
    // pending undelegates (validator => staker => pending unstake)
    mapping(address => mapping(address => PendingUnstake)) _pendingUnstakes;
    // allocated shares (validator => staker => shares)
    mapping(address => mapping(address => uint256)) _stakerShares;

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

    function initialize() external initializer {
    }

    function getStakedAmount(address validator, address staker) external view returns (uint256) {
        ValidatorPool memory validatorPool = _getValidatorPool(validator);
        return _stakerShares[validator][staker] * 1e18 / _calcRatio(validatorPool);
    }

    function getShares(address validator, address staker) external view returns (uint256) {
        return _stakerShares[validator][staker];
    }

    function getValidatorPool(address validator) external view returns (ValidatorPool memory) {
        ValidatorPool memory validatorPool = _getValidatorPool(validator);
        (uint256 amountToStake, uint256 dustRewards) = _calcUnclaimedDelegatorFee(validatorPool);
        validatorPool.totalStakedAmount += amountToStake;
        validatorPool.dustRewards += dustRewards;
        return validatorPool;
    }

    function getRatio(address validator) external view returns (uint256) {
        ValidatorPool memory validatorPool = _getValidatorPool(validator);
        return _calcRatio(validatorPool);
    }

    modifier advanceStakingRewards(address validator) {
        {
            ValidatorPool memory validatorPool = _getValidatorPool(validator);
            // claim rewards from staking contract
            (uint256 amountToStake, uint256 dustRewards) = _calcUnclaimedDelegatorFee(validatorPool);
            // increase total accumulated rewards
            validatorPool.totalStakedAmount += amountToStake;
            validatorPool.dustRewards += dustRewards;
            // save validator pool changes
            _validatorPools[validator] = validatorPool;
            // if we have something to redelegate then do this right now
            if (amountToStake > 0) {
                _STAKING_CONTRACT.redelegateDelegatorFee(validatorPool.validatorAddress);
            }
        }
        _;
    }

    function _getValidatorPool(address validator) internal view returns (ValidatorPool memory) {
        ValidatorPool memory validatorPool = _validatorPools[validator];
        validatorPool.validatorAddress = validator;
        return validatorPool;
    }

    function _calcUnclaimedDelegatorFee(ValidatorPool memory validatorPool) internal view returns (uint256 amountToStake, uint256 dustRewards) {
        return _STAKING_CONTRACT.calcAvailableForRedelegateAmount(validatorPool.validatorAddress, address(this));
    }

    function _calcRatio(ValidatorPool memory validatorPool) internal view returns (uint256) {
        (uint256 stakedAmount, /*uint256 dustRewards*/) = _calcUnclaimedDelegatorFee(validatorPool);
        uint256 stakeWithRewards = validatorPool.totalStakedAmount + stakedAmount;
        if (stakeWithRewards == 0) {
            return 1e18;
        }
        // we're doing upper rounding here
        return (validatorPool.sharesSupply * 1e18 + stakeWithRewards - 1) / stakeWithRewards;
    }

    function stake(address validator) external payable advanceStakingRewards(validator) override {
        ValidatorPool memory validatorPool = _getValidatorPool(validator);
        uint256 shares = msg.value * _calcRatio(validatorPool) / 1e18;
        // increase total accumulated shares for the staker
        _stakerShares[validator][msg.sender] += shares;
        // increase staking params for ratio calculation
        validatorPool.totalStakedAmount += msg.value;
        validatorPool.sharesSupply += shares;
        // save validator pool
        _validatorPools[validator] = validatorPool;
        // delegate these tokens to the staking contract
        _STAKING_CONTRACT.delegate{value : msg.value}(validator);
        // emit event
        emit Stake(validator, msg.sender, msg.value);
    }

    function unstake(address validator, uint256 amount) external advanceStakingRewards(validator) override {
        ValidatorPool memory validatorPool = _getValidatorPool(validator);
        require(validatorPool.totalStakedAmount > 0, "nothing to unstake");
        // make sure user doesn't have pending undelegates (we don't support it here)
        require(_pendingUnstakes[validator][msg.sender].epoch == 0, "undelegate pending");
        // calculate shares and make sure user have enough balance
        uint256 shares = amount * _calcRatio(validatorPool) / 1e18;
        require(shares <= _stakerShares[validator][msg.sender], "not enough shares");
        // save new undelegate
        _pendingUnstakes[validator][msg.sender] = PendingUnstake({
        amount : amount,
        shares : shares,
        epoch : _STAKING_CONTRACT.nextEpoch() + _CHAIN_CONFIG_CONTRACT.getUndelegatePeriod()
        });
        validatorPool.pendingUnstake += amount;
        _validatorPools[validator] = validatorPool;
        // undelegate
        _STAKING_CONTRACT.undelegate(validator, amount);
        // emit event
        emit Unstake(validator, msg.sender, amount);
    }

    function claimableRewards(address validator, address staker) external view override returns (uint256) {
        return _pendingUnstakes[validator][staker].amount;
    }

    function claim(address validator) external advanceStakingRewards(validator) override {
        PendingUnstake memory pendingUnstake = _pendingUnstakes[validator][msg.sender];
        uint256 amount = pendingUnstake.amount;
        uint256 shares = pendingUnstake.shares;
        // claim undelegate rewards
        _STAKING_CONTRACT.claimPendingUndelegates(validator);
        // make sure user have pending unstake
        require(pendingUnstake.epoch > 0, "nothing to claim");
        require(pendingUnstake.epoch <= _STAKING_CONTRACT.currentEpoch(), "not ready");
        // updates shares and validator pool params
        _stakerShares[validator][msg.sender] -= shares;
        ValidatorPool memory validatorPool = _getValidatorPool(validator);
        validatorPool.sharesSupply -= shares;
        validatorPool.totalStakedAmount -= amount;
        validatorPool.pendingUnstake -= amount;
        _validatorPools[validator] = validatorPool;
        // remove pending claim
        delete _pendingUnstakes[validator][msg.sender];
        // its safe to use call here (state is clear)
        require(address(this).balance >= amount, "not enough balance");
        payable(address(msg.sender)).transfer(amount);
        // emit event
        emit Claim(validator, msg.sender, amount);
    }

    receive() external payable {
        require(address(msg.sender) == address(_STAKING_CONTRACT), "not a staking contract");
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