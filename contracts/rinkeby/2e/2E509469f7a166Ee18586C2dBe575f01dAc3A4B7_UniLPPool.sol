// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import {CorePool} from "./CorePool.sol";
import {UniLPPool} from "./UniLPPool.sol";

import {ErrorHandler} from "../lib/ErrorHandler.sol";
import {Stake} from "../lib/Stake.sol";
import {SafeCast} from "../lib/SafeCast.sol";

import {IFactory} from "../interface/IFactory.sol";
import {ICorePool} from "../interface/ICorePool.sol";

contract UniLPPool is Initializable, CorePool {
    using ErrorHandler for bytes4;

    function initialize(
        address dlp_,
        address run_,
        address _poolToken,
        address factory_,
        uint64 _initTime,
        uint32 _weight
    ) external initializer {
        // calls internal v2 migrator initializer
        __CorePool_init(dlp_, run_, _poolToken, factory_, _initTime, _weight);
    }

    function getTotalReserves()
        external
        view
        virtual
        override
        returns (uint256 totalReserves)
    {
        totalReserves = poolTokenReserve;
    }

    /**
     * @notice This function can be called only by DLP core pool.
     *
     * @dev Uses DLP pool as a router by receiving the _staker address and executing
     *      the internal `_claimYieldRewards()`.
     * @dev Its usage allows claiming multiple pool contracts in one transaction.
     *
     * @param _staker user address
     * @param _useRun whether it should claim pendingYield as DLP or RUN
     */
    function claimYieldRewardsFromRouter(address _staker, bool _useRun)
        external
        virtual
    {
        // checks if contract is paused
        _requireNotPaused();
        // checks if caller is the DLP pool
        _requirePoolIsValid();

        // calls internal _claimYieldRewards function (in CorePool.sol)
        _claimYieldRewards(_staker, _useRun);
    }


        /**
     * @notice This function can be called only by DLP core pool.
     *
     * @dev Uses DLP pool as a router by receiving the _staker address and executing
     *      the internal `_claimVaultRewards()`.
     * @dev Its usage allows claiming multiple pool contracts in one transaction.
     *
     * @param _staker user address
     */
    function claimVaultRewardsFromRouter(address _staker) external virtual {
        // checks if contract is paused
        _requireNotPaused();
        // checks if caller is the DLP pool
        _requirePoolIsValid();

        // calls internal _claimVaultRewards function (in CorePool.sol)
        _claimVaultRewards(_staker);
    }

    /**
     * @dev Checks if caller is DLP pool.
     * @dev We are using an internal function instead of a modifier in order to
     *      reduce the contract's bytecode size.
     */
    function _requirePoolIsValid() internal view virtual {
        // we're using selector to simplify input and state validation
        // internal function simulated selector is `bytes4(keccak256("_requirePoolIsValid()"))`
        bytes4 fnSelector = 0x250f303f;

        // checks if pool is the DLP pool
        bool poolIsValid = address(_factory.pools(_dlp)) == msg.sender;
        fnSelector.verifyState(poolIsValid, 0);
    }
}

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
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/UUPSUpgradeable.sol)

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
     * implementation. It is used to validate that the this implementation remains valid after an upgrade.
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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
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

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import {SafeMathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

import {SafeCast} from "../lib/SafeCast.sol";
import {Timestamp} from "../lib/Timestamp.sol";
import {ICorePool} from "../interface/ICorePool.sol";
import {ErrorHandler} from "../lib/ErrorHandler.sol";
import {Stake} from "../lib/Stake.sol";
import {VoteEarn} from "../lib/VoteEarn.sol";
import {IFactory} from "../interface/IFactory.sol";
import {ICorePool} from "../interface/ICorePool.sol";

import {VaultRecipient} from "../lib/VaultRecipient.sol";
import {IDLPPool} from "../interface/IDLPPool.sol";

/**
 * @title Core Pool
 *
 * @notice An abstract contract containing common logic for DLP and DLP/ETH ULP pools.
 *
 * @dev Base smart contract for DLP and LP pool. Stores each pool user by mapping
 *      its address to the user struct. User struct stores  stakes, which fit
 *      in 1 storage slot each (by using the Stake lib), total weights, pending
 *      yield and revenue distributions. DLP and LP stakes can
 *      be made through flexible stake mode, which only increments the flexible
 *      balance of a given user, or through locked staking. Locked staking creates
 *      a new Stake element fitting 1 storage slot with its value and lock duration.
 *      .Every time a stake or unstake related function is called,
 *      it updates pending values, but don't require instant claimings. Rewards
 *      claiming are executed in separate functions, and in the case of yield,
 *      it also requires the user checking whether DLP or RUN is wanted as the yield reward.
 *
 * @dev Deployment and initialization.
 *      After proxy is deployed and attached to the implementation, it should be
 *      registered by the PoolFactory contract
 *      Additionally, 3 token instance addresses must be defined on deployment:
 *          - DLP token address
 *          - RUN token address, used to mint RUN rewards
 *          - pool token address, it can be DLP token address, DLP/ETH pair address, and others
 *
 * @dev Pool weight defines the fraction of the yield current pool receives among the other pools,
 *      pool factory is responsible for the weight synchronization between the pools.
 * @dev The weight is logically 15% for DLP pool and 75% for DLP/ETH pool initially.
 *      It can be changed through ICCPs and new flash pools added in the protocol.
 *      Since Solidity doesn't support fractions the weight is defined by the division of
 *      pool weight by total pools weight (sum of all registered pools within the factory).
 * @dev For DLP Pool we use 150 as weight and for DLP/ETH ULP pool - 750.
 *
 */
abstract contract CorePool is
    Initializable,
    UUPSUpgradeable,
    VaultRecipient,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable,
    Timestamp
{
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeCast for uint256;
    using Stake for Stake.Data;
    using ErrorHandler for bytes4;
    using Stake for uint256;
    using SafeMathUpgradeable for uint256;
    using VoteEarn for uint256;

    /// @dev Data structure representing token holder using a pool.
    struct User {
        /// @dev pending yield rewards to be claimed
        uint128 pendingYield;
        /// @dev pending revenue distribution to be claimed
        uint128 pendingRevDis;
        /// @dev pending additional distribution to be claimed
        uint128 pendingAdditional;
        /// @dev Total weight
        uint248 totalWeight;
        /// @dev Checkpoint variable for yield calculation
        uint256 yieldRewardsPerWeightPaid;
        /// @dev Checkpoint variable for vault rewards calculation
        uint256 vaultRewardsPerWeightPaid;
        /// @dev Checkpoint variable for Additional rewards calculation
        uint256 additionalRewardsPerWeightPaid;
        /// @dev An array of holder's stakes
        Stake.Data[] stakes;
    }

    /// @dev Data structure used in `unstakeLockedMultiple()` function.
    struct UnstakeParameter {
        uint256 stakeId;
        uint256 value;
    }

    /// @dev Token holder storage, maps token holder address to their data record.
    mapping(address => User) public users;

    /// @dev Link to RUN ERC20 Token instance.
    address internal _run;

    /// @dev Link to DLP ERC20 Token instance.
    address internal _dlp;

    /// @dev Link to the pool token instance, for example DLP or DLP/ETH pair.
    address public poolToken;

    /// @dev Pool weight, initial values are 150 for DLP pool and 750 for DLP/ETH.
    uint32 public weight;

    /// @dev Timestamp of the last yield distribution event.
    uint64 public lastYieldDistribution;

    /// @dev Used to calculate yield rewards.
    /// @dev This value is different from "reward per token" used in flash pool.
    /// @dev Note: stakes are different in duration and "weight" reflects that.
    uint256 public yieldRewardsPerWeight;

    /// @dev Used to calculate additional yield rewards.
    /// @dev This value is different from "reward per token" used in flash pool.
    /// @dev Note: stakes are different in duration and "weight" reflects that.
    uint256 public additionalYieldRewardsPerWeight;

    /// @dev Timestamp of the last additional yield distribution event.
    uint64 public lastAdditionalYieldDistribution;

    /**
     * @dev DLP/second determines Additional yield farming reward base
     *      used by the yield pools controlled by the factory.
     */
    uint256 public dlpAdditionalPerSecond;

    /// @dev Used to calculate rewards, keeps track of the tokens weight locked in staking.
    uint256 public globalWeight;

    /// @dev Pool tokens value available in the pool;
    ///      pool token examples are DLP (DLP core pool) or DLP/ETH pair (LP core pool).
    /// @dev For LP core pool this value doesnt' count for DLP tokens received as Vault rewards
    ///      while for DLP core pool it does count for such tokens as well.
    uint256 public poolTokenReserve;

    /// @dev Flag indicating pool type, false means "core pool".
    bool public constant isFlashPool = false;

    ///@dev Total DLP transferred from dividend to pool
    uint256 public valutTotalAmount;
    ///@dev Total DLP dividends distributed
    uint256 public valutConsumeAmount;

    ///@dev Total additional DLP transfers
    uint256 public additionalTotalAmount;
    ///@dev Remaining Total additional DLP transfers
    uint256 public additionalRemainingTotalAmount;
    ///@dev  Total additional transfer DLP consumed
    uint256 public additionalConsumeAmount;

    /**
     * @dev Fired in _stake() and stakeAsPool() in DLPPool contract.
     * @param by address that executed the stake function (user or pool)
     * @param from token holder address, the tokens will be returned to that address
     * @param stakeId id of the new stake created
     * @param value value of tokens staked
     * @param lockUntil timestamp indicating when tokens should unlock (max 2 years)
     */
    event LogStake(
        address indexed by,
        address indexed from,
        uint256 stakeId,
        uint256 value,
        uint64 lockUntil
    );

    /**
     * @dev Fired in `unstakeLocked()`.
     *
     * @param to address receiving the tokens (user)
     * @param stakeId id value of the stake
     * @param value number of tokens unstaked
     * @param isYield whether stake struct unstaked was coming from yield or not
     * @param isAdditional whether stake struct unstaked was coming from Additional yield or not

     */
    event LogUnstakeLocked(
        address indexed to,
        uint256 stakeId,
        uint256 value,
        bool isYield,
        bool isAdditional
    );

    /**
     * @dev Fired in `unstakeLockedMultiple()`.
     *
     * @param to address receiving the tokens (user)
     * @param totalValue total number of tokens unstaked
     * @param unstakingYield whether unstaked tokens had isYield flag true or false
     * @param unstakingAdditionalYield whether unstaked tokens had isAdditional flag true or false
     */
    event LogUnstakeLockedMultiple(
        address indexed to,
        uint256 totalValue,
        bool unstakingYield,
        bool unstakingAdditionalYield
    );

    /**
     * @dev Fired in `_sync()`, `sync()` and dependent functions (stake, unstake, etc.).
     *
     * @param by an address which performed an operation
     * @param yieldRewardsPerWeight updated yield rewards per weight value
     * @param lastYieldDistribution usually, current timestamp
     */
    event LogSync(
        address indexed by,
        uint256 yieldRewardsPerWeight,
        uint64 lastYieldDistribution
    );
    /**
     * @dev Fired in `_additional()`, `sync()` and dependent functions (stake, unstake, etc.).
     *
     * @param by an address which performed an operation
     * @param additionalYieldRewardsPerWeight updated additional yield rewards per weight value
     * @param lastAdditionalYieldDistribution usually, current timestamp
     */
    event LogAdditionalSync(
        address indexed by,
        uint256 additionalYieldRewardsPerWeight,
        uint64 lastAdditionalYieldDistribution
    );

    /**
     * @dev Fired in `_claimYieldRewards()`.
     *
     * @param by an address which claimed the rewards (staker or dlp pool contract
     *            in case of a multiple claim call)
     * @param from an address which received the yield
     * @param run flag indicating if reward was paid (minted) in run
     * @param value value of yield paid
     * @param pendingAdditionalYieldToClaim value of additional yield paid
     */
    event LogClaimYieldRewards(
        address indexed by,
        address indexed from,
        bool run,
        uint256 value,
        uint256 pendingAdditionalYieldToClaim
    );

    /**
     * @dev Fired in `_claimVaultRewards()`.
     *
     * @param by an address which claimed the rewards (staker or DLP pool contract
     *            in case of a multiple claim call)
     * @param from an address which received the yield
     * @param value value of yield paid
     */
    event LogClaimVaultRewards(
        address indexed by,
        address indexed from,
        uint256 value
    );

    /**
     * @dev Fired in `_updateRewards()`.
     *
     * @param by an address which processed the rewards (staker or DLP pool contract
     *            in case of a multiple claim call)
     * @param from an address which received the yield
     * @param yieldValue value of yield processed
     * @param revDisValue value of revenue distribution processed
     * @param additionalYieldValue value of additional yield processed
     */
    event LogUpdateRewards(
        address indexed by,
        address indexed from,
        uint256 yieldValue,
        uint256 revDisValue,
        uint256 additionalYieldValue
    );

    /**
     * @dev fired in `moveFundsFromWallet()`.
     *
     * @param from user asking migration
     * @param to new user address
     * @param previousTotalWeight total weight of `from` before moving to a new address
     * @param newTotalWeight total weight of `to` after moving to a new address
     * @param previousYield pending yield of `from` before moving to a new address
     * @param newYield pending yield of `to` after moving to a new address
     * @param previousRevDis pending revenue distribution of `from` before moving to a new address
     * @param newRevDis pending revenue distribution of `to` after moving to a new address
     * @param previousAdditionalYield pending additional yield of `from` before moving to a new address
     * @param newAdditionalYield pending additional yield of `to` after moving to a new address
     */
    event LogMoveFundsFromWallet(
        address indexed from,
        address indexed to,
        uint248 previousTotalWeight,
        uint248 newTotalWeight,
        uint128 previousYield,
        uint128 newYield,
        uint128 previousRevDis,
        uint128 newRevDis,
        uint128 previousAdditionalYield,
        uint128 newAdditionalYield
    );

    /**
     * @dev Fired in `receiveVaultRewards()`.
     *
     * @param by an address that sent the rewards, always a vault
     * @param value amount of tokens received
     */
    event LogReceiveVaultRewards(address indexed by, uint256 value);

    /**
     * @dev Fired in `receiveAdditionalRewards()`.
     *
     * @param by an address that sent the rewards, always a Additional
     * @param value amount of tokens received
     */
    event LogReceiveAdditionalRewards(address indexed by, uint256 value);

    /**
     * @dev Fired in `_updateAdditionalDLPPerSecond()`.
     *
     * @param by an address which executed an action
     * @param newDlpPerSecond new AdditionalDLP/second value
     */
    event LogUpdateAdditionalDLPPerSecond(
        address indexed by,
        uint256 newDlpPerSecond
    );

    /**
     * @dev Used in child contracts to initialize the pool.
     *
     * @param dlp_ DLP ERC20 Token address
     * @param run_ RUN ERC20 Token address
     * @param _poolToken token the pool operates on, for example DLP or DLP/ETH pair
     * @param factory_ PoolFactory contract address
     * @param _initTime initial timestamp used to calculate the rewards
     *      note: _initTime is set to the future effectively meaning _sync() calls will do nothing
     *           before _initTime
     * @param _weight number representing the pool's weight, which in _sync calls
     *        is used by checking the total pools weight in the PoolFactory contract
     */
    function __CorePool_init(
        address dlp_,
        address run_,
        address _poolToken,
        address factory_,
        uint64 _initTime,
        uint32 _weight
    ) internal initializer {
        // we're using selector to simplify input and state validation
        // internal function simulated selector is
        // `bytes4(keccak256("__CorePool_init(address,address,address,address,uint64,uint32)"))`
        bytes4 fnSelector = 0x243f7620;
        // verify the inputs
        fnSelector.verifyNonZeroInput(uint160(_poolToken), 2);
        fnSelector.verifyNonZeroInput(_initTime, 4);
        fnSelector.verifyNonZeroInput(_weight, 5);

        __FactoryControlled_init(factory_);
        __ReentrancyGuard_init();
        __Pausable_init();

        // save the inputs into internal state variables
        _dlp = dlp_;
        _run = run_;
        poolToken = _poolToken;
        weight = _weight;
        // init the dependent internal state variables
        lastYieldDistribution = _initTime;
        //init the dependent internal state variables
        lastAdditionalYieldDistribution = _initTime;
    }

    /**
     * @notice Calculates current yield rewards value available for address specified.
     *
     * @dev See `_pendingRewards()` for further details.
     *
     * @dev External `pendingRewards()` returns pendingYield and pendingRevDis
     *         accumulated with already stored user.pendingYield and user.pendingRevDis.
     *
     * @param _staker an address to calculate yield rewards value for
     */
    function pendingRewards(address _staker)
        external
        view
        virtual
        returns (
            uint256 pendingYield,
            uint256 pendingAdditional,
            uint256 pendingRevDis
        )
    {
        this.pendingRewards.selector.verifyNonZeroInput(uint160(_staker), 0);
        // `newYieldRewardsPerWeight` will be the stored or recalculated value for `yieldRewardsPerWeight`
        uint256 newYieldRewardsPerWeight;
        // gas savings
        uint256 _lastYieldDistribution = lastYieldDistribution;

        // based on the rewards per weight value, calculate pending rewards;
        User storage user = users[_staker];
        // initializes both variables from one storage slot
        uint256 userWeight = uint256(user.totalWeight);

        // if smart contract state was not updated recently, `yieldRewardsPerWeight` value
        // is outdated and we need to recalculate it in order to calculate pending rewards correctly
        if (_now256() > _lastYieldDistribution && globalWeight != 0) {
            uint256 endTime = _factory.endTime();
            uint256 multiplier = _now256() > endTime
                ? endTime.sub(_lastYieldDistribution)
                : _now256() - _lastYieldDistribution;

            uint256 dlpRewards = (multiplier *
                weight *
                _factory.dlpPerSecond()) / _factory.totalWeight();
            // recalculated value for `yieldRewardsPerWeight`
            newYieldRewardsPerWeight =
                dlpRewards.getRewardPerWeight(globalWeight) +
                yieldRewardsPerWeight;
        } else {
            // if smart contract state is up to date, we don't recalculate
            newYieldRewardsPerWeight = yieldRewardsPerWeight;
        }

        // `newAdditionalYieldRewardsPerWeight` will be the stored or recalculated value for `additionalYieldRewardsPerWeight`
        uint256 newAdditionalYieldRewardsPerWeight;
        // gas savings
        uint256 _lastAdditionYieldDistribution = lastAdditionalYieldDistribution;
        // if smart contract state was not updated recently, `additionalYieldRewardsPerWeight` value
        // is outdated and we need to recalculate it in order to calculate pending rewards correctly
        if (_now256() > _lastAdditionYieldDistribution && globalWeight != 0) {
            uint256 multiplier = _now256() - _lastAdditionYieldDistribution;
            uint256 dlpRewards = multiplier * dlpAdditionalPerSecond;
            // recalculated value for `yieldRewardsPerWeight`
            newAdditionalYieldRewardsPerWeight =
                dlpRewards.getRewardPerWeight(globalWeight) +
                additionalYieldRewardsPerWeight;
        } else {
            // if smart contract state is up to date, we don't recalculate
            newAdditionalYieldRewardsPerWeight = additionalYieldRewardsPerWeight;
        }

        pendingYield =
            userWeight.earned(
                newYieldRewardsPerWeight,
                user.yieldRewardsPerWeightPaid
            ) +
            user.pendingYield;

        pendingRevDis =
            userWeight.earned(
                vaultRewardsPerWeight,
                user.vaultRewardsPerWeightPaid
            ) +
            user.pendingRevDis;

        pendingAdditional =
            userWeight.earned(
                newAdditionalYieldRewardsPerWeight,
                user.additionalRewardsPerWeightPaid
            ) +
            user.pendingAdditional;
    }

    /**
     * @notice Returns total staked token balance for the given address.
     * @dev Loops through stakes and returns total balance.
     * @notice Expected to be called externally through `eth_call`. Gas shouldn't
     *         be an issue here.
     *
     * @param _user an address to query balance for
     * @return balance total staked token balance
     */
    function balanceOf(address _user)
        external
        view
        virtual
        returns (uint256 balance)
    {
        // gets storage pointer to _user
        User storage user = users[_user];
        // loops over each user stake and adds to the total balance.
        for (uint256 i = 0; i < user.stakes.length; i++) {
            balance += user.stakes[i].value;
        }
    }

    /**
     * @dev Returns the sum of poolTokenReserve with the deposit reserves in Pool.
     * @dev In DLP Pool contract the DAO stores the reserve value, and
     *      in the ULP pool we're able to query it from the  lp pool contract.
     */
    function getTotalReserves()
        external
        view
        virtual
        returns (uint256 totalReserves);

    /**
     * @notice Returns information on the given stake for the given address.
     *
     * @dev See getStakesLength.
     *
     * @param _user an address to query stake for
     * @param _stakeId zero-indexed stake ID for the address specified
     * @return stake info as Stake structure
     */
    function getStake(address _user, uint256 _stakeId)
        external
        view
        virtual
        returns (Stake.Data memory)
    {
        // read stake at specified index and return
        return users[_user].stakes[_stakeId];
    }

    /**
     * @notice Returns number of stakes for the given address. Allows iteration over stakes.
     *
     * @dev See `getStake()`.
     *
     * @param _user an address to query stake length for
     * @return number of stakes for the given address
     */
    function getStakesLength(address _user)
        external
        view
        virtual
        returns (uint256)
    {
        // read stakes array length and return
        return users[_user].stakes.length;
    }

    /**
     * @notice Returns Stake.Data of stakes for msg.sender. Allows iteration over stakes.
     *
     * @dev See `getStake()`.
     *
     * @return Stake.Data of stakes for msg.sender
     */
    function getUserStakes()
        external
        view
        virtual
        returns (Stake.Data[] memory)
    {
        // read stakes array info and return
        return users[_msgSender()].stakes;
    }

    /**
     * @dev Set paused/unpaused state in the pool contract.
     *
     * @param _shouldPause whether the contract should be paused/unpausd
     */
    function pause(bool _shouldPause) external {
        // checks if caller is authorized to pause
        _requireIsFactoryController();
        // checks bool input and pause/unpause the contract depending on
        // msg.sender's request
        if (_shouldPause) {
            _pause();
        } else {
            _unpause();
        }
    }

    /**
     * @notice Stakes specified value of tokens for the specified value of time,
     *      and pays pending yield rewards if any.
     *
     * @dev Requires value to stake and lock duration to be greater than zero.
     *
     * @param _value value of tokens to stake
     * @param _lockDuration stake duration as unix timestamp
     */
    function stake(uint256 _value, uint64 _lockDuration)
        external
        virtual
        nonReentrant
    {
        // checks if the contract is in a paused state
        _requireNotPaused();
        // we're using selector to simplify input and state validation
        bytes4 fnSelector = this.stake.selector;
        // validate the inputs
        fnSelector.verifyNonZeroInput(_value, 1);
        fnSelector.verifyInput(
            _lockDuration >= Stake.MIN_STAKE_PERIOD &&
                _lockDuration <= Stake.MAX_STAKE_PERIOD,
            2
        );

        // get a link to user data struct, we will write to it later
        User storage user = users[msg.sender];
        // update user state
        _updateReward(msg.sender);

        // calculates until when a stake is going to be locked
        uint64 lockUntil = (_now256()).toUint64() + _lockDuration;
        // stake weight formula rewards for locking
        uint256 stakeWeight = (((lockUntil - _now256()) *
            Stake.WEIGHT_MULTIPLIER) /
            Stake.MAX_STAKE_PERIOD +
            Stake.BASE_WEIGHT) * _value;
        //
        uint256 voteAmount = _value.voteEarned(_lockDuration);
        // makes sure stakeWeight is valid
        assert(stakeWeight > 0);
        // create and save the stake (append it to stakes array)
        Stake.Data memory userStake = Stake.Data({
            value: (_value).toUint120(),
            lockedFrom: (_now256()).toUint64(),
            lockedUntil: lockUntil,
            isYield: false,
            isAdditional: false
        });
        // pushes new stake to `stakes` array
        user.stakes.push(userStake);
        // update user weight
        user.totalWeight += (stakeWeight).toUint248();
        // update global weight value and global pool token count
        globalWeight += stakeWeight;
        poolTokenReserve += _value;

        // transfer `_value`
        IERC20Upgradeable(poolToken).safeTransferFrom(
            address(msg.sender),
            address(this),
            _value
        );
        _factory.updateVote(msg.sender, voteAmount, true);

        // emit an event
        emit LogStake(
            msg.sender,
            msg.sender,
            (user.stakes.length - 1),
            _value,
            lockUntil
        );
    }

    /**
     * @dev Moves msg.sender stake data to a new address.
     * @dev We process all rewards,
     *      clean the previous user (msg.sender), add the previous user data to
     *      the desired address and update subYieldRewards/subVaultRewards values
     *      in order to make sure both addresses will have rewards cleaned.
     *
     * @param _to new user address, needs to be a fresh address with no stakes
     */

    function moveFundsFromWallet(address _to) public virtual {
        // checks if the contract is in a paused state
        _requireNotPaused();
        // gets storage pointer to msg.sender user struct
        User storage previousUser = users[msg.sender];
        // gets storage pointer to desired address user struct
        User storage newUser = users[_to];

        // We process update global and user's rewards
        // before moving the user funds to a new wallet.
        _updateReward(msg.sender);

        // we're using selector to simplify input and state validation
        bytes4 fnSelector = this.moveFundsFromWallet.selector;
        // validate input is set
        fnSelector.verifyNonZeroInput(uint160(_to), 0);
        // verify new user records are empty
        fnSelector.verifyState(
            newUser.totalWeight == 0 &&
                newUser.stakes.length == 0 &&
                newUser.yieldRewardsPerWeightPaid == 0 &&
                newUser.vaultRewardsPerWeightPaid == 0 &&
                newUser.additionalRewardsPerWeightPaid == 0,
            0
        );
        // saves previous user total weight
        uint248 previousTotalWeight = previousUser.totalWeight;
        // saves previous user pending yield
        uint128 previousYield = previousUser.pendingYield;
        // saves previous user pending rev dis
        uint128 previousRevDis = previousUser.pendingRevDis;

        // saves previous user pending additional yield
        uint128 previousAdditionalYield = previousUser.pendingAdditional;

        // It's expected to have all previous user values
        // migrated to the new user address (_to).
        // We recalculate yield and vault rewards values
        // to make sure new user pending yield and pending rev dis to be stored
        // at newUser.pendingYield and newUser.pendingRevDis is 0, since we just processed
        // all pending rewards calling _updateReward.
        newUser.totalWeight = previousTotalWeight;
        newUser.pendingYield = previousYield;
        newUser.pendingRevDis = previousRevDis;
        newUser.pendingAdditional = previousAdditionalYield;
        newUser.yieldRewardsPerWeightPaid = yieldRewardsPerWeight;
        newUser.vaultRewardsPerWeightPaid = vaultRewardsPerWeight;
        newUser
            .additionalRewardsPerWeightPaid = additionalYieldRewardsPerWeight;
        newUser.stakes = previousUser.stakes;
        delete previousUser.totalWeight;
        delete previousUser.pendingYield;
        delete previousUser.pendingRevDis;
        delete previousUser.pendingAdditional;
        delete previousUser.stakes;

        // emits an event
        emit LogMoveFundsFromWallet(
            msg.sender,
            _to,
            previousTotalWeight,
            newUser.totalWeight,
            previousYield,
            newUser.pendingYield,
            previousRevDis,
            newUser.pendingRevDis,
            previousAdditionalYield,
            newUser.pendingAdditional
        );
    }

    /**
     * @notice Service function to synchronize pool state with current time.
     *
     * @dev Can be executed by anyone at any time, but has an effect only when
     *      at least one second passes between synchronizations.
     * @dev Executed internally when staking, unstaking, processing rewards in order
     *      for calculations to be correct and to reflect state progress of the contract.
     * @dev When timing conditions are not met (executed too frequently, or after factory
     *      end time), function doesn't throw and exits silently.
     */
    function sync() external virtual {
        _requireNotPaused();
        // calls internal function
        _sync();
        _additional();
    }

    /**
     * @dev Calls internal `_claimYieldRewards()` passing `msg.sender` as `_staker`.
     *
     * @notice Pool state is updated before calling the internal function.
     */
    function claimYieldRewards(bool _useRun) external virtual {
        // checks if the contract is in a paused state
        _requireNotPaused();
        // calls internal function
        _claimYieldRewards(msg.sender, _useRun);
    }

    /**
     * @dev Calls internal `_claimVaultRewards()` passing `msg.sender` as `_staker`.
     *
     * @notice Pool state is updated before calling the internal function.
     */
    function claimVaultRewards() external virtual {
        // checks if the contract is in a paused state
        _requireNotPaused();
        // calls internal function
        _claimVaultRewards(msg.sender);
    }

    /**
     * @dev Claims both revenue distribution and yield rewards in one call.
     *
     */
    function claimAllRewards(bool _useRun) external virtual {
        // checks if the contract is in a paused state
        _requireNotPaused();
        // calls internal yield and vault rewards functions
        _claimVaultRewards(msg.sender);
        _claimYieldRewards(msg.sender, _useRun);
    }

    /**
     * @dev Executed by the Additional to transfer Additional rewards DLP from the Additional
     *      into the pool.
     *
     * @dev This function is executed only for DLP core pools.
     *
     * @param _value amount of DLP rewards to transfer into the pool
     */
    function receiveAdditionalRewards(uint256 _value) external virtual {
        // always sync the pool state vars before moving forward
        _sync();
        _additional();
        // checks if the contract is in a paused state
        _requireNotPaused();
        // checks if msg.sender is the vault contract
        _requireIsVault();
        // return silently if there is no reward to receive
        if (_value == 0) {
            return;
        }
        // transfers DLP from the Vault contract to the pool
        IERC20Upgradeable(_dlp).safeTransferFrom(
            msg.sender,
            address(this),
            _value
        );
        additionalTotalAmount = additionalTotalAmount.add(_value);
        additionalRemainingTotalAmount = additionalRemainingTotalAmount.add(
            _value
        );

        _updateAdditionalDLPPerSecond();

        // emits an event
        emit LogReceiveAdditionalRewards(msg.sender, _value);
    }

    /**
     * @dev Executed by the vault to transfer vault rewards DLP from the vault
     *      into the pool.
     *
     * @dev This function is executed only for DLP core pools.
     *
     * @param _value amount of DLP rewards to transfer into the pool
     */
    function receiveVaultRewards(uint256 _value) external virtual {
        // always sync the pool state vars before moving forward
        _sync();
        _additional();

        // checks if the contract is in a paused state
        _requireNotPaused();
        // checks if msg.sender is the vault contract
        _requireIsVault();
        // we're using selector to simplify input and state validation
        bytes4 fnSelector = this.receiveVaultRewards.selector;
        // return silently if there is no reward to receive
        if (_value == 0) {
            return;
        }
        // verify weight is not zero
        fnSelector.verifyState(globalWeight > 0, 0);
        // we update vaultRewardsPerWeight value,
        // expecting to distribute revenue distribution correctly to all users
        vaultRewardsPerWeight += _value.getRewardPerWeight(globalWeight);

        // transfers DLP from the Vault contract to the pool
        IERC20Upgradeable(_dlp).safeTransferFrom(
            msg.sender,
            address(this),
            _value
        );
        valutTotalAmount = valutTotalAmount.add(_value);
        // emits an event
        emit LogReceiveVaultRewards(msg.sender, _value);
    }

    /**
     * @dev Executed by the factory to modify pool weight; the factory is expected
     *      to keep track of the total pools weight when updating.
     *
     * @dev Set weight to zero to disable the pool.
     *
     * @param _weight new weight to set for the pool
     */
    function setWeight(uint32 _weight) external virtual {
        // update pool state using current weight value
        _sync();
        _additional();
        // verify function is executed by the factory
        this.setWeight.selector.verifyAccess(msg.sender == address(_factory));

        // set the new weight value
        weight = _weight;
    }

    /**
     * @dev Unstakes a stake that has been previously locked, and is now in an unlocked
     *      state. If the stake has the isYield flag set to true, then the contract
     *      requests DLP to be minted by the PoolFactory. Otherwise it transfers DLP or LP
     *      from the contract balance.
     *
     * @param _stakeId stake ID to unstake from, zero-indexed
     * @param _value value of tokens to unstake
     */
    function unstake(uint256 _stakeId, uint256 _value) external virtual {
        // checks if the contract is in a paused state
        _requireNotPaused();
        // we're using selector to simplify input and state validation
        bytes4 fnSelector = this.unstake.selector;

        // verify a value is set
        fnSelector.verifyNonZeroInput(_value, 0);
        // get a link to user data struct, we will write to it later
        User storage user = users[msg.sender];
        // get a link to the corresponding stake, we may write to it later
        Stake.Data storage userStake = user.stakes[_stakeId];
        // checks if stake is unlocked already
        fnSelector.verifyState(_now256() > userStake.lockedUntil, 0);
        // stake structure may get deleted, so we save isYield flag to be able to use it
        // we also save stakeValue for gasSavings
        (uint120 stakeValue, bool isYield, bool isAdditional) = (
            userStake.value,
            userStake.isYield,
            userStake.isAdditional
        );
        // verify available balance
        fnSelector.verifyInput(stakeValue >= _value, 1);

        // and process current pending rewards if any
        _updateReward(msg.sender);
        // store stake weight
        uint256 previousWeight = userStake.weight();
        // value used to save new weight after updates in storage
        uint256 newWeight;
        uint256 voteAmount = _value.voteEarned(
            userStake.lockedUntil - userStake.lockedFrom
        );

        // update the stake, or delete it if its depleted
        if (stakeValue - _value == 0) {
            // deletes stake struct, no need to save new weight because it stays 0
            delete user.stakes[_stakeId];
        } else {
            userStake.value -= (_value).toUint120();
            // saves new weight to memory
            newWeight = userStake.weight();
        }
        // update user record
        user.totalWeight = uint248(
            user.totalWeight - previousWeight + newWeight
        );
        // update global weight variable
        globalWeight = globalWeight - previousWeight + newWeight;
        // update global pool token count
        poolTokenReserve -= _value;

        // if the stake was created by the pool itself as a yield reward
        if (isYield) {
            if (isAdditional) {
                uint256 costAdmount = additionalTotalAmount.sub(
                    additionalConsumeAmount
                );
                if (costAdmount < _value) {
                    revert();
                }
                additionalConsumeAmount = additionalConsumeAmount.add(_value);
                IERC20Upgradeable(poolToken).safeTransfer(msg.sender, _value);
            } else {
                // mint the yield via the factory
                _factory.mintYieldTo(msg.sender, _value, false);
            }
        } else {
            // otherwise just return tokens back to holder
            IERC20Upgradeable(poolToken).safeTransfer(msg.sender, _value);
        }

        _factory.updateVote(msg.sender, voteAmount, false);

        // emits an event
        emit LogUnstakeLocked(
            msg.sender,
            _stakeId,
            _value,
            isYield,
            isAdditional
        );
    }

    /**
     * @dev Executes unstake on multiple stakeIds. See `unstakeLocked()`.
     * @dev Optimizes gas by requiring all unstakes to be made either in yield stakes
     *      or in non yield stakes. That way we can transfer or mint tokens in one call.
     *
     * @notice User is required to either mint DLP or unstake pool tokens in the function call.
     *         There's no way to do both operations in one call.
     *
     * @param _stakes array of stakeIds and values to be unstaked in each stake from
     *                the msg.sender
     * @param _unstakingYield whether all stakeIds have isYield flag set to true or false,
     *                        i.e if we're minting DLP or transferring pool tokens
     * @param _unstakingAdditionalYield whether all stakeIds have isAdditional flag set to true or false,
     *                        i.e if we're minting DLP or transferring pool tokens
     */
    function unstakeMultiple(
        UnstakeParameter[] calldata _stakes,
        bool _unstakingYield,
        bool _unstakingAdditionalYield
    ) external virtual {
        // checks if the contract is in a paused state
        _requireNotPaused();
        // we're using selector to simplify input and state validation
        bytes4 fnSelector = this.unstakeMultiple.selector;
        // verifies if user has passed any value to be unstaked
        fnSelector.verifyNonZeroInput(_stakes.length, 0);
        // gets storage pointer to the user
        User storage user = users[msg.sender];

        _updateReward(msg.sender);

        // initialize variables that expect to receive the total
        // weight to be removed from the user and the value to be
        // unstaked from the pool.
        uint256 weightToRemove;
        uint256 valueToUnstake;
        uint256 totalVoteAmount;

        for (uint256 i = 0; i < _stakes.length; i++) {
            // destructure calldata parameters
            (uint256 _stakeId, uint256 _value) = (
                _stakes[i].stakeId,
                _stakes[i].value
            );
            Stake.Data storage userStake = user.stakes[_stakeId];
            // checks if stake is unlocked already
            fnSelector.verifyState(_now256() > userStake.lockedUntil, i * 3);
            // checks if unstaking value is valid
            fnSelector.verifyNonZeroInput(_value, 1);
            // stake structure may get deleted, so we save isYield flag to be able to use it
            // we also save stakeValue for gas savings
            (uint120 stakeValue, bool isYield, bool isAdditional) = (
                userStake.value,
                userStake.isYield,
                userStake.isAdditional
            );
            // verifies if the selected stake is yield (i.e DLP to be minted)
            // or not, the function needs to either mint yield or transfer tokens
            // and can't do both operations at the same time.
            fnSelector.verifyState(isYield == _unstakingYield, i * 3 + 1);

            // checks if there's enough tokens to unstake
            fnSelector.verifyState(stakeValue >= _value, i * 3 + 2);

            if (_unstakingAdditionalYield) {
                fnSelector.verifyState(
                    isAdditional == _unstakingAdditionalYield,
                    i * 3 + 3
                );
            }

            // store stake weight
            uint256 previousWeight = userStake.weight();
            // value used to save new weight after updates in storage
            uint256 newWeight;
            uint256 voteAmount = _value.voteEarned(
                userStake.lockedUntil - userStake.lockedFrom
            );

            // update the stake, or delete it if its depleted
            if (stakeValue - _value == 0) {
                // deletes stake struct, no need to save new weight because it stays 0
                delete user.stakes[_stakeId];
            } else {
                // removes _value from the stake with safe cast
                userStake.value -= (_value).toUint120();
                // saves new weight to memory
                newWeight = userStake.weight();
            }

            // updates the values initialized earlier with the amounts that
            // need to be subtracted (weight) and transferred (value to unstake)
            weightToRemove += previousWeight - newWeight;
            valueToUnstake += _value;
            totalVoteAmount += voteAmount;
        }
        // subtracts weight
        user.totalWeight -= (weightToRemove).toUint248();
        // update global variable
        globalWeight -= weightToRemove;
        // update pool token count
        poolTokenReserve -= valueToUnstake;
        // if the stake was created by the pool itself as a yield reward
        if (_unstakingYield) {
            if (_unstakingAdditionalYield) {
                uint256 costAdmount = additionalTotalAmount.sub(
                    additionalConsumeAmount
                );
                if (costAdmount < valueToUnstake) {
                    revert();
                }
                additionalConsumeAmount = additionalConsumeAmount.add(
                    valueToUnstake
                );
                IERC20Upgradeable(poolToken).safeTransfer(
                    msg.sender,
                    valueToUnstake
                );
            }
            // mint the yield via the factory
            _factory.mintYieldTo(msg.sender, valueToUnstake, false);
        } else {
            // otherwise just return tokens back to holder
            IERC20Upgradeable(poolToken).safeTransfer(
                msg.sender,
                valueToUnstake
            );
        }

        _factory.updateVote(msg.sender, totalVoteAmount, false);

        // emits an event
        emit LogUnstakeLockedMultiple(
            msg.sender,
            valueToUnstake,
            _unstakingYield,
            _unstakingAdditionalYield
        );
    }

    /**
     * @dev Checks if pool is paused.
     * @dev We use this internal function instead of the modifier coming from
     *      Pausable contract in order to decrease contract's bytecode size.
     */
    function _requireNotPaused() internal view virtual {
        // we're using selector to simplify input and state validation
        // internal function simulated selector is `bytes4(keccak256("_requireNotPaused()"))`
        bytes4 fnSelector = 0xabb87a6f;
        // checks paused variable value from Pausable Open Zeppelin
        fnSelector.verifyState(!paused(), 0);
    }

    /**
     * @dev Used internally, mostly by children implementations, see `sync()`.
     *
     * @dev Updates smart contract state (`yieldRewardsPerWeight`, `lastYieldDistribution`),
     *      updates factory state via `updateDLPPerSecond`
     */
    function _sync() internal virtual {
        // gas savings
        IFactory factory_ = _factory;
        // update DLP per second value in factory if required
        if (factory_.shouldUpdateRatio()) {
            uint256 upTime = factory_.lastRatioUpdate() +
                factory_.secondsPerUpdate();
            if (
                _now256() > lastYieldDistribution &&
                lastYieldDistribution < upTime
            ) {
                _updateYieldRewardsPerWeight(factory_.dlpPerSecond());
            }
            factory_.updateDLPPerSecond();
        }
        _updateYieldRewardsPerWeight(factory_.dlpPerSecond());
    }

    function _updateYieldRewardsPerWeight(uint256 _dlpPerSecond)
        internal
        virtual
    {
        IFactory factory_ = _factory;
        // check bound conditions and if these are not met -
        // exit silently, without emitting an event
        uint256 endTime = factory_.endTime();
        if (lastYieldDistribution >= endTime) {
            return;
        }
        if (_now256() <= lastYieldDistribution) {
            return;
        }
        // if locking weight is zero - update only `lastYieldDistribution` and exit
        if (globalWeight == 0) {
            lastYieldDistribution = (_now256()).toUint64();
            return;
        }
        // to calculate the reward we need to know how many seconds passed, and reward per second
        uint256 currentTimestamp = _now256() > endTime ? endTime : _now256();

        uint256 secondsPassed = currentTimestamp - lastYieldDistribution;
        // calculate the reward
        uint256 dlpReward = (secondsPassed * _dlpPerSecond * weight) /
            factory_.totalWeight();

        // update rewards per weight and `lastYieldDistribution`
        yieldRewardsPerWeight += dlpReward.getRewardPerWeight(globalWeight);
        lastYieldDistribution = (currentTimestamp).toUint64();

        // emit an event
        emit LogSync(msg.sender, yieldRewardsPerWeight, lastYieldDistribution);
    }

    /**
     * @dev Must be called every time user.totalWeight is changed.
     * @dev Syncs the global pool state, processes the user pending rewards (if any),
     *      and updates check points values stored in the user struct.
     *
     * @param _staker user address
     */
    function _updateReward(address _staker) internal virtual {
        // update pool state
        _sync();
        _additional();
        // gets storage reference to the user
        User storage user = users[_staker];
        // gas savings
        uint256 userTotalWeight = uint256(user.totalWeight);

        // calculates pending yield to be added
        uint256 pendingYield = userTotalWeight.earned(
            yieldRewardsPerWeight,
            user.yieldRewardsPerWeightPaid
        );
        // calculates pending reenue distribution to be added
        uint256 pendingRevDis = userTotalWeight.earned(
            vaultRewardsPerWeight,
            user.vaultRewardsPerWeightPaid
        );
        //calculates pending additional  yield to be added
        uint256 pendingAdditionalYield = userTotalWeight.earned(
            additionalYieldRewardsPerWeight,
            user.additionalRewardsPerWeightPaid
        );

        // increases stored user.pendingYield with value returned
        user.pendingYield += pendingYield.toUint128();
        // increases stored user.pendingRevDis with value returned
        user.pendingRevDis += pendingRevDis.toUint128();

        // increases stored user.pendingRevDis with value returned
        user.pendingAdditional += pendingAdditionalYield.toUint128();

        // updates user checkpoint values for future calculations
        user.yieldRewardsPerWeightPaid = yieldRewardsPerWeight;
        user.vaultRewardsPerWeightPaid = vaultRewardsPerWeight;
        user.additionalRewardsPerWeightPaid = additionalYieldRewardsPerWeight;

        // emit an event
        emit LogUpdateRewards(
            msg.sender,
            _staker,
            pendingYield,
            pendingRevDis,
            pendingAdditionalYield
        );
    }

    /**
     * @dev claims all pendingYield from _staker using DLP or RUN.
     *
     * @notice RUN is minted straight away to _staker wallet, DLP is created as
     *         a new stake and locked for Stake.MAX_STAKE_PERIOD.
     *
     * @param _staker user address
     * @param _useRun whether the user wants to claim DLP or run
     */
    function _claimYieldRewards(address _staker, bool _useRun)
        internal
        virtual
    {
        // get link to a user data structure, we will write into it later
        User storage user = users[_staker];
        // update user state
        _updateReward(_staker);
        // check pending yield rewards to claim and save to memory
        uint256 pendingYieldToClaim = uint256(user.pendingYield);
        // check pending additional yield rewards to claim and save to memory
        uint256 pendingAdditionalYieldToClaim = uint256(user.pendingAdditional);
        // if pending yield is zero - just return silently
        if (pendingYieldToClaim == 0 && pendingAdditionalYieldToClaim == 0)
            return;

        // clears user pending yield
        user.pendingYield = 0;
        // clears user pending yield
        user.pendingAdditional = 0;

        // if run is requested
        if (_useRun) {
            // - mint run
            uint256 _pendingYield = pendingYieldToClaim +
                pendingAdditionalYieldToClaim;
            _factory.mintYieldTo(_staker, _pendingYield, true);
        } else if (poolToken == _dlp) {
            if (pendingYieldToClaim > 0) {
                _yieldStake(user, pendingYieldToClaim, false);
            }
            if (pendingAdditionalYieldToClaim > 0) {
                _yieldStake(user, pendingAdditionalYieldToClaim, true);
            }
        } else {
            // for other pools - stake as pool
            address dlpPool = _factory.getPoolAddress(_dlp);
            if (pendingYieldToClaim > 0) {
                IDLPPool(dlpPool).stakeAsPool(
                    _staker,
                    pendingYieldToClaim,
                    false
                );
            }
            if (pendingAdditionalYieldToClaim > 0) {
                IDLPPool(dlpPool).stakeAsPool(
                    _staker,
                    pendingAdditionalYieldToClaim,
                    true
                );
            }
        }

        // emits an event
        emit LogClaimYieldRewards(
            msg.sender,
            _staker,
            _useRun,
            pendingYieldToClaim,
            pendingAdditionalYieldToClaim
        );
    }

    /**
     *
     *@dev  Re investment pledge for reward
     * @param  user user struct
     * @param pendingYieldToClaim Reward to be received
     * @param isAdditional Whether it is an additional reward
     */
    function _yieldStake(
        User storage user,
        uint256 pendingYieldToClaim,
        bool isAdditional
    ) internal {
        // calculate pending yield weight,
        // 2e6 is the bonus weight when staking for 1 year
        uint256 stakeWeight = pendingYieldToClaim *
            Stake.YIELD_STAKE_WEIGHT_MULTIPLIER;

        uint256 lockUntil = (_now256()).toUint64() + Stake.MAX_STAKE_PERIOD;
        // if the pool is DLP Pool - create new DLP stake
        // and save it - push it into stakes array
        Stake.Data memory newStake = Stake.Data({
            value: (pendingYieldToClaim).toUint120(),
            lockedFrom: (_now256()).toUint64(),
            lockedUntil: lockUntil.toUint64(), // staking yield for 1 year
            isYield: true,
            isAdditional: isAdditional
        });
        uint256 voteAmount = pendingYieldToClaim.voteEarned(
            Stake.MAX_STAKE_PERIOD
        );
        // add memory stake to storage
        user.stakes.push(newStake);
        // updates total user weight with the newly created stake's weight
        user.totalWeight += (stakeWeight).toUint248();

        // update global variable
        globalWeight += stakeWeight;
        // update reserve count
        poolTokenReserve += pendingYieldToClaim;
        _factory.updateVote(msg.sender, voteAmount, true);
        // emit an events
        emit LogStake(
            msg.sender,
            msg.sender,
            (user.stakes.length - 1),
            pendingYieldToClaim,
            lockUntil.toUint64()
        );
    }

    /**
     * @dev Claims all pendingRevDis from _staker using DLP.
     * @dev DLP is sent straight away to _staker address.
     *
     * @param _staker user address
     */
    function _claimVaultRewards(address _staker) internal virtual {
        // get link to a user data structure, we will write into it later
        User storage user = users[_staker];
        // update user state
        _updateReward(_staker);
        // check pending yield rewards to claim and save to memory
        uint256 pendingRevDis = uint256(user.pendingRevDis);
        // if pending yield is zero - just return silently
        if (pendingRevDis == 0) return;
        //Insufficient Balance - just return silently
        if (valutTotalAmount.sub(valutConsumeAmount) < pendingRevDis) {
            revert();
        }
        valutConsumeAmount = valutConsumeAmount.add(pendingRevDis);
        // clears user pending revenue distribution
        user.pendingRevDis = 0;

        IERC20Upgradeable(_dlp).safeTransfer(_staker, pendingRevDis);

        // emits an event
        emit LogClaimVaultRewards(msg.sender, _staker, pendingRevDis);
    }

    /**
     * @dev Used internally, mostly by children implementations, see `sync()`.
     *
     * @dev Updates smart contract state (`additionalYieldRewardsPerWeight`, `lastAdditionalYieldDistribution`),
     *      updates factory state via `updateDLPPerSecond`
     */
    function _additional() internal virtual {
        // gas savings
        IFactory factory_ = _factory;
        // update DLP per second value in factory if required
        if (
            factory_.shouldUpdateAdditionalRatio() &&
            additionalRemainingTotalAmount > 0
        ) {
            uint256 upTime = factory_.lastAdditionalRatioUpdate() +
                factory_.secondsPerUpdate();
            if (
                _now256() > lastAdditionalYieldDistribution &&
                lastAdditionalYieldDistribution < upTime
            ) {
                _updateAdditionalYieldRewardsPerWeight(dlpAdditionalPerSecond);
            }
            _updateAdditionalDLPPerSecond();
        }
        _updateAdditionalYieldRewardsPerWeight(dlpAdditionalPerSecond);
    }

    function _updateAdditionalYieldRewardsPerWeight(
        uint256 _dlpAdditionalPerSecond
    ) internal virtual {
        if (_now256() <= lastAdditionalYieldDistribution) {
            return;
        }
        // if locking weight is zero - update only `lastAdditionalYieldDistribution` and exit
        if (globalWeight == 0) {
            lastAdditionalYieldDistribution = (_now256()).toUint64();
            return;
        }

        // to calculate the reward we need to know how many seconds passed, and reward per second
        uint256 currentTimestamp = _now256();

        uint256 secondsPassed = currentTimestamp -
            lastAdditionalYieldDistribution;

        // calculate the reward
        uint256 dlpReward = secondsPassed * _dlpAdditionalPerSecond;

        // update rewards per weight and `lastAdditionalYieldDistribution`
        additionalYieldRewardsPerWeight += dlpReward.getRewardPerWeight(
            globalWeight
        );
        lastAdditionalYieldDistribution = (currentTimestamp).toUint64();

        // emit an event
        emit LogAdditionalSync(
            msg.sender,
            additionalYieldRewardsPerWeight,
            lastAdditionalYieldDistribution
        );
    }

    /**
     * @notice Decreases DLP/second reward by 3%, can be executed
     *      no more than once per `secondsPerUpdate` seconds.
     */
    function _updateAdditionalDLPPerSecond() internal virtual {
      // gas savings
        IFactory factory_ = _factory;
        if (additionalRemainingTotalAmount <= 0) {
            return;
        }
        //3% of the remaining quantity as reward
        uint256 unlockAmount = (additionalRemainingTotalAmount * 3) / 100;
        //Remaining quantity
        additionalRemainingTotalAmount = additionalRemainingTotalAmount.sub(
            unlockAmount
        );
        // decreases DLP/second reward by 3%.
        dlpAdditionalPerSecond = unlockAmount / factory_.secondsPerUpdate();

        // emit an event
        emit LogUpdateAdditionalDLPPerSecond(
            msg.sender,
            dlpAdditionalPerSecond
        );
    }



    /**
     * @dev See UUPSUpgradeable `_authorizeUpgrade()`.
     * @dev Just checks if `msg.sender` == `factory.owner()` i.e eDAO multisig address.
     * @dev eDAO multisig is responsible by handling upgrades and executing other
     *      admin actions approved by the Council.
     */
    function _authorizeUpgrade(address) internal view virtual override {
        // checks caller is factory.owner()
        _requireIsFactoryController();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Errors Library.
 *
 * @notice Introduces some very common input and state validation for smart contracts,
 *      such as non-zero input validation, general boolean expression validation, access validation.
 *
 * @notice Throws pre-defined errors instead of string error messages to reduce gas costs.
 *
 * @notice Since the library handles only very common errors, concrete smart contracts may
 *      also introduce their own error types and handling.
 *
 */
library ErrorHandler {
    /**
     * @notice Thrown on zero input at index specified in a function specified.
     *
     * @param fnSelector function selector, defines a function where error was thrown
     * @param paramIndex function parameter index which caused an error thrown
     */
    error ZeroInput(bytes4 fnSelector, uint8 paramIndex);

    /**
     * @notice Thrown on invalid input at index specified in a function specified.
     *
     * @param fnSelector function selector, defines a function where error was thrown
     * @param paramIndex function parameter index which caused an error thrown
     */
    error InvalidInput(bytes4 fnSelector, uint8 paramIndex);

    /**
     * @notice Thrown on invalid state in a function specified.
     *
     * @param fnSelector function selector, defines a function where error was thrown
     * @param errorCode unique error code determining the exact place in code where error was thrown
     */
    error InvalidState(bytes4 fnSelector, uint256 errorCode);

    /**
     * @notice Thrown on invalid access to a function specified.
     *
     * @param fnSelector function selector, defines a function where error was thrown
     * @param addr an address which access was denied, usually transaction sender
     */
    error AccessDenied(bytes4 fnSelector, address addr);

    /**
     * @notice Verifies an input is set (non-zero).
     *
     * @param fnSelector function selector, defines a function which called the verification
     * @param value a value to check if it's set (non-zero)
     * @param paramIndex function parameter index which is verified
     */
    function verifyNonZeroInput(
        bytes4 fnSelector,
        uint256 value,
        uint8 paramIndex
    ) internal pure {
        if (value == 0) {
            revert ZeroInput(fnSelector, paramIndex);
        }
    }

    /**
     * @notice Verifies an input is correct.
     *
     * @param fnSelector function selector, defines a function which called the verification
     * @param expr a boolean expression used to verify the input
     * @param paramIndex function parameter index which is verified
     */
    function verifyInput(
        bytes4 fnSelector,
        bool expr,
        uint8 paramIndex
    ) internal pure {
        if (!expr) {
            revert InvalidInput(fnSelector, paramIndex);
        }
    }

    /**
     * @notice Verifies smart contract state is correct.
     *
     * @param fnSelector function selector, defines a function which called the verification
     * @param expr a boolean expression used to verify the contract state
     * @param errorCode unique error code determining the exact place in code which is verified
     */
    function verifyState(
        bytes4 fnSelector,
        bool expr,
        uint256 errorCode
    ) internal pure {
        if (!expr) {
            revert InvalidState(fnSelector, errorCode);
        }
    }

    /**
     * @notice Verifies an access to the function.
     *
     * @param fnSelector function selector, defines a function which called the verification
     * @param expr a boolean expression used to verify the access
     */
    function verifyAccess(bytes4 fnSelector, bool expr) internal view {
        if (!expr) {
            revert AccessDenied(fnSelector, msg.sender);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Stake library used by DLP pool and Uniswap LP Pool.
 *
 * @dev Responsible to manage weight calculation and store important constants
 *      related to stake period, base weight and multipliers utilized.
 */
library Stake {
    struct Data {
        /// @dev token amount staked
        uint120 value;
        /// @dev locking period - from
        uint64 lockedFrom;
        /// @dev locking period - until
        uint64 lockedUntil;
        /// @dev indicates if the stake was created as a yield reward
        bool isYield;
        ///@dev Is it the dividend generated by DLP transferred in by the foundation
        bool isAdditional;
    }

    /**
     * @dev Stake weight is proportional to stake value and time locked, precisely
     *      "stake value wei multiplied by (fraction of the year locked plus one)".
     * @dev To avoid significant precision loss due to multiplication by "fraction of the year" [0, 1],
     *      weight is stored multiplied by 1e6 constant, as an integer.
     * @dev Corner case 1: if time locked is zero, weight is stake value multiplied by 1e6 + base weight
     * @dev Corner case 2: if time locked is two years, division of
            (lockedUntil - lockedFrom) / MAX_STAKE_PERIOD is 1e6, and
     *      weight is a stake value multiplied by 2 * 1e6.
     */
    uint256 internal constant WEIGHT_MULTIPLIER = 1e6;

    /**
     * @dev Minimum weight value, if result of multiplication using WEIGHT_MULTIPLIER
     *      is 0 (e.g stake flexible), then BASE_WEIGHT is used.
     */
    uint256 internal constant BASE_WEIGHT = 1e6;
    /**
     * @dev Minimum period that someone can lock a stake for.
     */
    uint256 internal constant MIN_STAKE_PERIOD = 1 hours;

    /**
     * @dev Maximum period that someone can lock a stake for.
     */
    uint256 internal constant MAX_STAKE_PERIOD = 12 hours;

    /**
     * @dev Rewards per weight are stored multiplied by 1e20 as uint.
     */
    uint256 internal constant REWARD_PER_WEIGHT_MULTIPLIER = 1e20;

    /**
     * @dev When we know beforehand that staking is done for yield instead of
     *      executing `weight()` function we use the following constant.
     */
    uint256 internal constant YIELD_STAKE_WEIGHT_MULTIPLIER = 2 * 1e6;

    function weight(Data storage _self) internal view returns (uint256) {
        return
            uint256(
                (((_self.lockedUntil - _self.lockedFrom) * WEIGHT_MULTIPLIER) / MAX_STAKE_PERIOD + BASE_WEIGHT) *
                    _self.value

            );
    }

    /**
     * @dev Converts stake weight (not to be mixed with the pool weight) to
     *      DLP reward value, applying the 10^12 division on weight
     *
     * @param _weight stake weight
     * @param _rewardPerWeight DLP reward per weight
     * @param _rewardPerWeightPaid last reward per weight value used for user earnings
     * @return reward value normalized to 10^12
     */
    function earned(
        uint256 _weight,
        uint256 _rewardPerWeight,
        uint256 _rewardPerWeightPaid
    ) internal pure returns (uint256) {
        // apply the formula and return
        return (_weight * (_rewardPerWeight - _rewardPerWeightPaid)) / REWARD_PER_WEIGHT_MULTIPLIER;
    }

    /**
     * @dev Converts reward DLP value to stake weight (not to be mixed with the pool weight),
     *      applying the 10^12 multiplication on the reward.
     *      - OR -
     * @dev Converts reward DLP value to reward/weight if stake weight is supplied as second
     *      function parameter instead of reward/weight.
     *
     * @param _reward yield reward
     * @param _globalWeight total weight in the pool
     * @return reward per weight value
     */
    function getRewardPerWeight(uint256 _reward, uint256 _globalWeight) internal pure returns (uint256) {
        // apply the reverse formula and return
        return (_reward * REWARD_PER_WEIGHT_MULTIPLIER) / _globalWeight;
    }


}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeCast.sol)

pragma solidity ^0.8.0;

import { ErrorHandler } from "./ErrorHandler.sol";

/**
 * @notice Copied from OpenZeppelin's SafeCast.sol, adapted to use just in the required
 * uint sizes.
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    using ErrorHandler for bytes4;

    /**
     * @dev Returns the downcasted uint248 from uint256, reverting on
     * overflow (when the input is greater than largest uint248).
     *
     * Counterpart to Solidity's `uint248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     */
    function toUint248(uint256 _value) internal pure returns (uint248) {
        // we're using selector to simplify input and state validation
        // internal function simulated selector is `bytes4(keccak256("toUint248(uint256))"))`
        bytes4 fnSelector = 0x3fd72672;
        fnSelector.verifyInput(_value <= type(uint248).max, 0);

        return uint248(_value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 _value) internal pure returns (uint128) {
        // we're using selector to simplify input and state validation
        // internal function simulated selector is `bytes4(keccak256("toUint128(uint256))"))`
        bytes4 fnSelector = 0x809fdd33;
        fnSelector.verifyInput(_value <= type(uint128).max, 0);

        return uint128(_value);
    }

    /**
     * @dev Returns the downcasted uint120 from uint256, reverting on
     * overflow (when the input is greater than largest uint120).
     *
     * Counterpart to Solidity's `uint120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     */
    function toUint120(uint256 _value) internal pure returns (uint120) {
        // we're using selector to simplify input and state validation
        // internal function simulated selector is `bytes4(keccak256("toUint120(uint256))"))`
        bytes4 fnSelector = 0x1e4e4bad;
        fnSelector.verifyInput(_value <= type(uint120).max, 0);

        return uint120(_value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 _value) internal pure returns (uint64) {
        // we're using selector to simplify input and state validation
        // internal function simulated selector is `bytes4(keccak256("toUint64(uint256))"))`
        bytes4 fnSelector = 0x2665fad0;
        fnSelector.verifyInput(_value <= type(uint64).max, 0);

        return uint64(_value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 _value) internal pure returns (uint32) {
        // we're using selector to simplify input and state validation
        // internal function simulated selector is `bytes4(keccak256("toUint32(uint256))"))`
        bytes4 fnSelector = 0xc8193255;
        fnSelector.verifyInput(_value <= type(uint32).max, 0);

        return uint32(_value);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ICorePool} from "./ICorePool.sol";

interface IFactory {
    function owner() external view returns (address);

    function dlpPerSecond() external view returns (uint192);

    function totalWeight() external view returns (uint32);

    function secondsPerUpdate() external view returns (uint32);

    function endTime() external view returns (uint32);

    function lastRatioUpdate() external view returns (uint32);

    function lastAdditionalRatioUpdate()external view returns (uint32);

    function pools(address _poolToken) external view returns (ICorePool);

    function poolExists(address _poolAddress) external view returns (bool);

    function getPoolAddress(address poolToken) external view returns (address);

    function getPoolData(address _poolToken)
        external
        view
        returns (
            address,
            address,
            uint32,
            bool
        );

    function shouldUpdateRatio() external view returns (bool);

    function registerPool(ICorePool pool) external;

    function updateDLPPerSecond() external;

    function mintYieldTo(
        address _to,
        uint256 _value,
        bool _useRUN
    ) external;

    function changePoolWeight(address pool, uint32 weight) external;

    function shouldUpdateAdditionalRatio() external returns (bool);

    function updateVote(address _to, uint256 _value,bool _isAdd) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Stake} from "../lib/Stake.sol";

interface ICorePool {
    function users(address _user)
        external
        view
        returns (
            uint128,
            uint128,
            uint256,
            uint256,
            uint256
        );

    function poolToken() external view returns (address);

    function isFlashPool() external view returns (bool);

    function weight() external view returns (uint32);

    function lastYieldDistribution() external view returns (uint64);

    function yieldRewardsPerWeight() external view returns (uint256);

    function globalWeight() external view returns (uint256);

    function pendingRewards(address _user)
        external
        view
        returns (uint256, uint256);

    function poolTokenReserve() external view returns (uint256);

    function balanceOf(address _user) external view returns (uint256);

    function getTotalReserves() external view returns (uint256);

    function getStake(address _user, uint256 _stakeId)
        external
        view
        returns (Stake.Data memory);

    function getStakesLength(address _user) external view returns (uint256);

    function sync() external;

    function setWeight(uint32 _weight) external;

    function receiveVaultRewards(uint256 value) external;
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

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
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

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
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Function for getting block timestamp.
/// @dev Base contract that is overridden for tests.
abstract contract Timestamp {
    /**
     * @dev Testing time-dependent functionality is difficult and the best way of
     *      doing it is to override time in helper test smart contracts.
     *
     * @return `block.timestamp` in mainnet, custom values in testnets (if overridden).
     */
    function _now256() internal view virtual returns (uint256) {
        // return current block timestamp
        return block.timestamp;
    }

    /**
     * @dev Empty reserved space in storage. The size of the __gap array is calculated so that
     *      the amount of storage used by a contract always adds up to the 50.
     *      See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library VoteEarn {
    /**
     * @dev Maximum period that someone can lock a stake for.
     */
    uint256 internal constant BASE_TIME = 120 minutes;

    function voteEarned(uint256 _amount, uint256 _lockTime)
        internal
        pure
        returns (uint256)
    {
        return (_amount * _lockTime) / BASE_TIME + _amount;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { FactoryControlled } from "./FactoryControlled.sol";
import { ErrorHandler } from "../lib/ErrorHandler.sol";

abstract contract VaultRecipient is Initializable, FactoryControlled {
    using ErrorHandler for bytes4;

    /// @dev Link to deployed DlpVault instance.
    address internal _vault;

    /// @dev Used to calculate vault rewards.
    /// @dev This value is different from "reward per token" used in locked pool.
    /// @dev Note: stakes are different in duration and "weight" reflects that,
    uint256 public vaultRewardsPerWeight;

    /**
     * @dev Fired in `setVault()`.
     *
     * @param by an address which executed the function, always a factory owner
     * @param previousVault previous vault contract address
     * @param newVault new vault address
     */
    event LogSetVault(address indexed by, address previousVault, address newVault);

    /**
     * @dev Executed only by the factory owner to Set the vault.
     *
     * @param vault_ an address of deployed IlluviumVault instance
     */
    function setVault(address vault_) external virtual {
        // we're using selector to simplify input and state validation
        bytes4 fnSelector = this.setVault.selector;
        // verify function is executed by the factory owner
        fnSelector.verifyState(_factory.owner() == msg.sender, 0);
        // verify input is set
        fnSelector.verifyInput(vault_ != address(0), 0);

        // saves current vault to memory
        address previousVault = vault_;
        // update vault address
        _vault = vault_;

        // emit an event
        emit LogSetVault(msg.sender, previousVault, _vault);
    }

    /// @dev Utility function to check if caller is the Vault contract
    function _requireIsVault() internal view virtual {
        // we're using selector to simplify input and state validation
        // internal function simulated selector is `bytes4(keccak256("_requireIsVault()"))`
        bytes4 fnSelector = 0xeeea774b;
        // checks if caller is the same stored vault address
        fnSelector.verifyAccess(msg.sender == _vault);
    }

    /**
     * @dev Empty reserved space in storage. The size of the __gap array is calculated so that
     *      the amount of storage used by a contract always adds up to the 50.
     *      See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[48] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ICorePool} from "./ICorePool.sol";

interface IDLPPool is ICorePool {
    function stakeAsPool(
        address _staker,
        uint256 _value,
        bool isAdditional
    ) external;

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { IFactory } from "../interface/IFactory.sol";
import { ErrorHandler } from "../lib/ErrorHandler.sol";

/**
 * @title FactoryControlled
 *
 * @dev Abstract smart contract responsible to hold IFactory factory address.
 * @dev Stores PoolFactory address on initialization.
 *
 */
abstract contract FactoryControlled is Initializable {
    using ErrorHandler for bytes4;
    /// @dev Link to the pool factory IlluviumPoolFactory instance.
    IFactory internal _factory;

    /// @dev Attachs PoolFactory address to the FactoryControlled contract.
    function __FactoryControlled_init(address factory_) internal initializer {
        // we're using selector to simplify input and state validation
        // internal function simulated selector is `bytes4(keccak256("__FactoryControlled_init(address)"))`
        bytes4 fnSelector = 0xbb6c0dbf;
        fnSelector.verifyNonZeroInput(uint160(factory_), 0);

        _factory = IFactory(factory_);
    }

    /// @dev checks if caller is factory admin (eDAO multisig address).
    function _requireIsFactoryController() internal view virtual {
        // we're using selector to simplify input and state validation
        // internal function simulated selector is `bytes4(keccak256("_requireIsFactoryController()"))`
        bytes4 fnSelector = 0x39e71deb;
        fnSelector.verifyAccess(msg.sender == _factory.owner());
    }

    /**
     * @dev Empty reserved space in storage. The size of the __gap array is calculated so that
     *      the amount of storage used by a contract always adds up to the 50.
     *      See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}