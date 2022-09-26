//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {ContextUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import {SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import {IXpcLocker} from "./IXpcLocker.sol";
import {IERC20Mintable} from "../token/IERC20Mintable.sol";

/**
 * @title Locker Smart Contract
 *
 * @notice Locker Smart Contract which allows to lock XPC ERC20 tokens and mint the
 * same amount of XPCL tokens for specified period of time after which the users
 * will be able to make linear unlock until the end of vesting period is over
 *
 * This can be used for:
 *  - Token developers to prove they have locked tokens
 *  - Presale projects or investors to lock a portion of tokens for a vesting period
 *  - Farming platforms to lock a percentage of the farmed rewards for a period of time
 *  - To lock tokens until a specific unlock date.
 *  - To send tokens to someone under a time lock.
 */
contract XpcLocker is IXpcLocker, ContextUpgradeable {
    using SafeERC20Upgradeable for IERC20Mintable;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    IERC20Upgradeable private _checkToken;
    IERC20Mintable private _lockToken;

    // Start time of the locking period (expressed in UNIX time as seconds)
    uint256 private _start;

    // End of the locking period (expressed in UNIX time as seconds)
    uint256 private _lockEnd;

    // Cliff date (expressed in UNIX time as seconds)
    uint256 private _cliff;

    // Total duration of vesting (after cliff date) expressed in seconds
    uint256 private _unlockDuration;

    // Total amount of XPC tokens locked
    uint256 private _totalLocked;

    // Total amount of XPC tokens released
    uint256 private _totalReleased;

    // Address -> amount of locked XPC tokens
    mapping(address => uint256) private _usersLocked;

    // Address -> amount of already released XPC tokens
    mapping(address => uint256) private _usersReleased;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Creates a locker contract that locks XPC tokens for lock period and then
     * after cliff date unlocks it in linear manner
     *
     * @param checkToken address of the XPC token
     * @param lockToken address of the XPCL token
     * @param startTime the time (as Unix time) at which point lock period starts
     * @param lockDuration duration in seconds of the locking period in which the tokens can be locked
     * @param cliffDuration duration if seconds of the cliff period (after lock period ends)
     * @param duration duration if seconds of the total unlocking period
     */
    function initialize(
        address checkToken,
        address lockToken,
        uint256 startTime,
        uint256 lockDuration,
        uint256 cliffDuration,
        uint256 duration
    ) public initializer {
        __Context_init();
        _checkToken = IERC20Upgradeable(checkToken);
        _lockToken = IERC20Mintable(lockToken);

        // It is safe to check for timestamp here because lock and vesting periods are long enough
        // solhint-disable-next-line not-rely-on-time
        if (block.timestamp > (startTime + lockDuration)) revert IncorrectVestingConfig();

        _start = startTime;
        _lockEnd = startTime + lockDuration;
        _cliff = startTime + lockDuration + cliffDuration;
        _unlockDuration = duration;
    }

    /**
     * @notice Locks the `amount` of XPC token inside of the smart contract
     * It will mint the same amount of XPCL tokens to the user address
     * @param amount amount of the tokens locked
     *
     * @dev XPC has 6 DECIMALS so the amount should be specified accordingly
     * User should first provide the approve to the smart contract to spend `amount`
     * of user tokens (should be done separately from UI)
     */
    function lock(uint256 amount) external override {
        address sender = _msgSender();

        // It is safe to check for timestamp here because lock and vesting periods are long enough
        // solhint-disable-next-line not-rely-on-time
        if (block.timestamp > _lockEnd) revert LockAlreadyEnded(_lockEnd);

        _totalLocked += amount;
        _usersLocked[sender] += amount;
        emit Lock(sender, amount);

        _checkToken.safeTransferFrom(sender, address(this), amount);
        _lockToken.mint(sender, amount);
    }

    /**
     * @notice Releases the `amount` of XPC token from the smart contract
     * @param amount amount of the tokens to be released
     *
     * @dev XPC has 6 DECIMALS so the amount should be specified accordingly.
     */
    function release(uint256 amount) external override {
        address sender = _msgSender();

        // it is safe enough as cliff period is long enough
        // solhint-disable-next-line not-rely-on-time
        if (block.timestamp < _cliff) revert UnlockNotStarted(_cliff);

        uint256 unlockAmount = _unlocked(sender);
        if (amount > unlockAmount) revert LockedBalanceNotEnough(unlockAmount);

        _totalLocked -= amount;
        _usersLocked[sender] -= amount;
        _usersReleased[sender] += amount;
        emit Release(sender, amount);

        // We need to burn the same amount of XPCL tokens
        _lockToken.burn(sender, amount);

        // Send XPC token to the user wallet
        _checkToken.safeTransfer(sender, amount);
    }

    /**
     * @notice Transfers ownership of lock to a new account
     * @param newOwner new owner of the lock
     *
     * @dev transfers ownership of the lock to the new account
     */
    function transferOwnership(address newOwner) external override {
        address sender = _msgSender();

        uint256 locked = _usersLocked[sender];
        delete _usersLocked[sender];

        uint256 released = _usersReleased[sender];
        delete _usersReleased[sender];

        emit TransferOwnership(sender, newOwner);
        _usersLocked[newOwner] = locked;
        _usersReleased[newOwner] = released;

        _lockToken.burn(sender, locked);
        _lockToken.mint(newOwner, locked);
    }

    /**
     * @notice Returns amount of locked XPC tokens
     * @param account address of the locker
     * @return Amount of locked tokens
     */
    function lockedOf(address account) external view override returns (uint256) {
        return _usersLocked[account];
    }

    /**
     * @return the whole amount of the token locked in smart contract.
     */
    function totalLocked() external view override returns (uint256) {
        return _totalLocked;
    }

    /**
     * @notice Returns amount of unlocked XPC tokens
     * @param account address of the locker
     * @return Amount of unlocked tokens
     */
    function unlockedOf(address account) external view override returns (uint256) {
        return _unlocked(account);
    }

    /**
     * @return the whole amount of the token released from smart contract.
     */
    function totalReleased() external view override returns (uint256) {
        return _totalReleased;
    }

    /**
     * @notice Returns amount of released XPC tokens
     * @param account address of the locker
     * @return Amount of released tokens
     */
    function releasedOf(address account) external view override returns (uint256) {
        return _usersReleased[account];
    }

    /**
     * @return the whole amount of the token locked in smart contract.
     */
    function totalUnlocked() external view override returns (uint256) {
        return _unlocked(_totalLocked, _totalReleased);
    }

    /**
     * @return the cliff time of the token vesting.
     */
    function cliff() external view override returns (uint256) {
        return _cliff;
    }

    /**
     * @return the start time of the token vesting.
     */
    function start() external view override returns (uint256) {
        return _start;
    }

    /**
     * @return the end time of the locking period.
     */
    function lockEnd() external view override returns (uint256) {
        return _lockEnd;
    }

    /**
     * @return the whole duration of the token vesting.
     */
    function unlockDuration() external view override returns (uint256) {
        return _unlockDuration;
    }

    /**
     * @notice Returns amount of unlocked XPC tokens
     * @param account address of the locker
     * @return Amount of unlocked tokens
     */
    function _unlocked(address account) private view returns (uint256) {
        return _unlocked(_usersLocked[account], _usersReleased[account]);
    }

    function _unlocked(uint256 locked, uint256 released) private view returns (uint256) {
        // It is safe to check for timestamp here because cliff period is long enough
        // solhint-disable-next-line not-rely-on-time
        if (block.timestamp < _cliff) {
            return 0;
        } else {
            // total amount of tokens user locked during locking period
            uint256 totalAmount = locked + released;

            // If vesting period is over then use vesting end date otherwise the current date
            // It is safe to check for timestamp here because lock and vesting periods are long enough
            // solhint-disable-next-line not-rely-on-time
            uint256 unlockTime = block.timestamp > (_cliff + _unlockDuration)
                ? _cliff + _unlockDuration
                : block.timestamp;

            // total vested amount of tokens for user at the time of checking
            uint256 vestedAmount = (totalAmount * (unlockTime - _cliff)) / _unlockDuration;

            // amount of tokens user can release
            return vestedAmount - released;
        }
    }
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

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
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {ILockableFund} from "./ILockableFund.sol";

/**
 * @title Locker Interface
 * @notice Interface for the Locker smart contract which allow private investors to
 * lock XPC tokens and mint the same amount of XPCL tokens for 1 month after
 * which the users will be able to make linear unlock
 *
 * @dev Locker Interface
 */
interface IXpcLocker is ILockableFund {
    /**
     * @notice Lock event
     * @dev Emitted when `depositor` locks `amount` of XPC token.
     * @param account address of the locker
     * @param amount amount of XPC tokens locked by `locker`
     */
    event Lock(address indexed account, uint256 amount);

    /**
     * @notice Release event
     * @dev Emitted when `account` releases `amount` of XPC token.
     * @param account address of the locker
     * @param amount amount of XPC tokens release by `locker`
     */
    event Release(address indexed account, uint256 amount);

    /**
     * @notice Transfer ownership event
     * @dev Emitted when `account` transferred ownership to `newOwner` of lock.
     * @param account address of the locker
     * @param newOwner address of the locker
     */
    event TransferOwnership(address indexed account, address indexed newOwner);

    /// Passed incorrect vesting schedule configuration
    error IncorrectVestingConfig();

    /// Lock period already ended
    /// It cannot be called after `time`.
    error LockAlreadyEnded(uint256 time);

    /// Unlock period is not started (after cliff)
    /// It cannot be called before `time`.
    error UnlockNotStarted(uint256 time);

    /// Unlocked balance is not enough for unlocking
    /// It cannot be more than `amount` at the moment
    error LockedBalanceNotEnough(uint256 amount);

    /**
     * @notice Locks the `amount` of XPC token inside of the smart contract
     * It will mint the same amount of XPCL tokens to the user address
     * @param amount amount of the tokens locked
     *
     * @dev XPC has 6 DECIMALS so the amount should be specified accordingly
     * User should first provide the approve to the smart contract to spend `amount`
     * of user tokens (should be done separately from UI)
     */
    function lock(uint256 amount) external;

    /**
     * @notice Releases the `amount` of XPC token from the smart contract
     * @param amount amount of the tokens to be released
     *
     * @dev XPC has 6 DECIMALS so the amount should be specified accordingly
     */
    function release(uint256 amount) external;

    /**
     * @notice Transfers ownership of lock to a new account
     * @param newOwner new owner of the lock
     *
     * @dev transfers ownership of the lock to the new account
     */
    function transferOwnership(address newOwner) external;

    /**
     * @notice Returns the cliff time of the token vesting.
     * @return the cliff time of the token vesting.
     */
    function cliff() external view returns (uint256);

    /**
     * @notice Returns the start time of the token vesting.
     * @return the start time of the token vesting.
     */
    function start() external view returns (uint256);

    /**
     * @notice Returns the end time of the locking period.
     * @return the end time of the locking period.
     */
    function lockEnd() external view returns (uint256);

    /**
     * @notice Returns the whole duration of the token vesting.
     * @return the whole duration of the token vesting.
     */
    function unlockDuration() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Interface for the mint and burn operations of the ERC20 tokens
 */
interface IERC20Mintable {
    /**
     * @dev mint `amount` of tokens to `account` address
     */
    function mint(address account, uint256 amount) external;

    /**
     * @dev burn `amount` of tokens from `account` address
     */
    function burn(address account, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

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
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
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
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Lockable Fund Interface
 * @notice Interface for the lockable fund
 *
 * @dev Lockable Fund interface
 */
interface ILockableFund {
    /**
     * @notice Returns amount of locked XPC tokens
     * @param account address of the locker
     * @return Amount of locked tokens
     */
    function lockedOf(address account) external view returns (uint256);

    /**
     * @notice Returns amount of totally locked XPC tokens
     * @return Amount of locked tokens
     */
    function totalLocked() external view returns (uint256);

    /**
     * @notice Returns amount of unlocked XPC tokens
     * @param account address of the locker
     * @return Amount of unlocked tokens
     */
    function unlockedOf(address account) external view returns (uint256);

    /**
     * @notice Returns amount of totally unlocked XPC tokens
     * @return Amount of unlocked tokens
     */
    function totalUnlocked() external view returns (uint256);

    /**
     * @notice Returns amount of XPC tokens available for unlock by `account`
     * @param account address of the locker
     * @return Amount of tokens available for unlock by `account`
     */
    function releasedOf(address account) external view returns (uint256);

    /**
     * @notice Returns amount of XPC tokens available for unlock
     * @return Amount of tokens available for unlock
     */
    function totalReleased() external view returns (uint256);
}