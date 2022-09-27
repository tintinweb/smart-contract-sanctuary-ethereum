// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
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
// OpenZeppelin Contracts (last updated v4.7.0) (security/PullPayment.sol)

pragma solidity ^0.8.0;

import "../utils/escrow/EscrowUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Simple implementation of a
 * https://consensys.github.io/smart-contract-best-practices/recommendations/#favor-pull-over-push-for-external-calls[pull-payment]
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 */
library MerkleProofUpgradeable {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Calldata version of {verify}
     *
     * _Available since v4.7._
     */
    function verifyCalldata(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProofCalldata(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Calldata version of {processProof}
     *
     * _Available since v4.7._
     */
    function processProofCalldata(bytes32[] calldata proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Returns true if the `leaves` can be proved to be a part of a Merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
     *
     * _Available since v4.7._
     */
    function multiProofVerify(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProof(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Calldata version of {multiProofVerify}
     *
     * _Available since v4.7._
     */
    function multiProofVerifyCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProofCalldata(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Returns the root of a tree reconstructed from `leaves` and the sibling nodes in `proof`,
     * consuming from one or the other at each step according to the instructions given by
     * `proofFlags`.
     *
     * _Available since v4.7._
     */
    function processMultiProof(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    /**
     * @dev Calldata version of {processMultiProof}
     *
     * _Available since v4.7._
     */
    function processMultiProofCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
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
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/Clones.sol)

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
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
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
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
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
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
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
pragma solidity 0.8.16;
// pragma abicoder v2;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PullPaymentUpgradeable.sol";
import "./Sale.sol";

/**
Allow qualified users to participate in a sale according to sale rules.

Management
- the address that deploys the sale is the sale owner
- owners may change some sale parameters (e.g. start and end times)
- sale proceeds are sent to the sale recipient

Qualification
- public sale: anyone can participate
- private sale: only users who can prove membership in a merkle tree can participate

Sale Rules
- timing: purchases can only be made
  - after the sale opens
  - after the per-account random queue time has elapsed
  - before the sale ends
- purchase quantity: quantity is limited by
  - per-address limit
  - total sale limit
- payment method: participants can pay using either
  - the native token on the network (e.g. ETH)
  - a single ERC-20 token (e.g. USDC)
- number of purchases: there is no limit to the number of compliant purchases a user may make

Token Distribution
- this contract does not distribute any purchased tokens

Metrics
- purchase count: number of purchases made in this sale
- user count: number of unique addresses that participated in this sale
- total bought: value of purchases denominated in a base currency (e.g. USD) as an integer (to get the float value, divide by oracle decimals)
- bought per user: value of a user's purchases denominated in a base currency (e.g. USD)

total bought and bought per user metrics are inclusive of any fee charged (if a fee is charged, the sale recipient will receive less than the total spend)
*/

// Sale can only be updated post-initialization by the contract owner!
struct Config {
  // the address that will receive sale proceeds (tokens and native) minus any fees sent to the fee recipient
  address payable recipient;
  // the merkle root used for proving access
  bytes32 merkleRoot;
  // max that can be spent in the sale in the base currency
  uint256 saleMaximum;
  // max that can be spent per user in the base currency
  uint256 userMaximum;
  // minimum that can be bought in a specific purchase
  uint256 purchaseMinimum;
  // the time at which the sale starts (users will have an additional random delay if maxQueueTime is set)
  uint startTime;
  // the time at which the sale will end, regardless of tokens raised
  uint endTime;
  // what is the maximum length of time a user could wait in the queue after the sale starts?
  uint256 maxQueueTime;
  // a link to off-chain information about this sale
  string URI;
}

// Metrics are only updated by the buyWithToken() and buyWithNative() functions
struct Metrics {
  // number of purchases
  uint256 purchaseCount;
  // number of buyers
  uint256 buyerCount;
  // amount bought denominated in a base currency
  uint256 purchaseTotal;
  // amount bought for each user denominated in a base currency
  mapping(address => uint256) buyerTotal;
}

struct PaymentTokenInfo {
  AggregatorV3Interface oracle;
  uint8 decimals;
}

contract FlatPriceSale is Sale, PullPaymentUpgradeable {
  using SafeERC20Upgradeable for IERC20Upgradeable;

  event ImplementationConstructor(address payable indexed feeRecipient, uint256 feeBips);
  event Update(Config config);
  event Initialize(Config config, string baseCurrency, AggregatorV3Interface nativeOracle, bool nativePaymentsEnabled);
  event SetPaymentTokenInfo(IERC20Upgradeable token, PaymentTokenInfo paymentTokenInfo);
  event SweepToken(address indexed token, uint256 amount);
  event SweepNative(uint256 amount);

  // All chainlink oracles used must have 8 decimals!
  uint256 constant public BASE_CURRENCY_DECIMALS = 8;
  // All supported chains must use 18 decimals (e.g. 1e18 wei / eth)
  uint256 constant internal NATIVE_TOKEN_DECIMALS = 18;

  // flag for additional merkle root data
  uint8 constant internal PER_USER_PURCHASE_LIMIT = 1;
  uint8 constant internal PER_USER_END_TIME = 2;

  /**
  Variables set by implementation contract constructor (immutable)
  */

  // a fee may be charged by the sale manager
  uint256 immutable feeBips;

  // the recipient of the fee
  address payable immutable feeRecipient;

  /**
  Variables set during initialization of clone contracts ("immutable" on each instance)
  */

  // the base currency being used, e.g. 'USD'
  string public baseCurrency;

  string public constant VERSION = "2.0";

  // <native token>/<base currency> price, e.g. ETH/USD price
  AggregatorV3Interface public nativeTokenPriceOracle;

  // whether native payments are enabled (set during intialization)
  bool nativePaymentsEnabled;

  // <ERC20 token>/<base currency> price oracles, eg USDC address => ETH/USDC price
  mapping(IERC20Upgradeable => PaymentTokenInfo) public paymentTokens;

  // owner can update these
  Config public config;

  // derived from payments
  Metrics public metrics;

  // reasonably random value: xor of merkle root and blockhash for transaction setting merkle root
  uint160 internal randomValue;

  // All clones will share the information in the implementation constructor
  constructor(
    uint256 _feeBips,
    address payable _feeRecipient
  ) {
    if (_feeBips > 0) {
      require(_feeRecipient != address(0), "feeRecipient == 0");
    }
    feeRecipient = _feeRecipient;
    feeBips = _feeBips;

    emit ImplementationConstructor(feeRecipient, feeBips);
  }

  /**
  Replacement for constructor for clones of the implementation contract
  Important: anyone can call the initialize function!
  */
  function initialize(
    address _owner,
    Config calldata _config,
    string calldata _baseCurrency,
    bool _nativePaymentsEnabled,
    AggregatorV3Interface _nativeTokenPriceOracle,
    IERC20Upgradeable[] calldata tokens,
    AggregatorV3Interface[] calldata oracles,
    uint8[] calldata decimals
  ) public initializer validUpdate(_config) {
    // initialize the PullPayment escrow contract
    __PullPayment_init();

    // validate the new sale
    require(tokens.length == oracles.length, "token and oracle lengths !=");
    require(tokens.length == decimals.length, "token and decimals lengths !=");
    require(address(_nativeTokenPriceOracle) != address(0), "native oracle == 0");
    require(_nativeTokenPriceOracle.decimals() == BASE_CURRENCY_DECIMALS, "native oracle decimals != 8");

    // save the new sale
    config = _config;

    // save payment config
    baseCurrency = _baseCurrency;
    nativeTokenPriceOracle = _nativeTokenPriceOracle;
    nativePaymentsEnabled = _nativePaymentsEnabled;
    emit Initialize(config, baseCurrency, nativeTokenPriceOracle, _nativePaymentsEnabled);

    for (uint i = 0; i < tokens.length; i++) {
      // double check that tokens and oracles are real addresses
      require(address(tokens[i]) != address(0), "payment token == 0");
      require(address(oracles[i]) != address(0), "token oracle == 0");
      // Double check that oracles use the expected 8 decimals
      require(oracles[i].decimals() == BASE_CURRENCY_DECIMALS, "token oracle decimals != 8");
      // save the payment token info
      paymentTokens[tokens[i]] = PaymentTokenInfo({
        oracle: oracles[i],
        decimals: decimals[i]
      });
  
      emit SetPaymentTokenInfo(tokens[i], paymentTokens[tokens[i]]);
    }

    // Set the random value for the fair queue time
    randomValue = generatePseudorandomValue(config.merkleRoot);

    // transfer ownership to the user initializing the sale
    _transferOwnership(_owner);
  }

  /**
  Check that the user can currently participate in the sale based on the merkle root

  Merkle root options:
  - bytes32(0): this is a public sale, any address can participate
  - otherwise: this is a private sale, users must submit a merkle proof that their address is included in the merkle root
  */
  modifier canAccessSale(bytes calldata data, bytes32[] calldata proof) {
    // make sure the buyer is an EOA
    // TODO: Review this check for meta-transactions
    require((_msgSender() == tx.origin), "Must buy with an EOA");

    // If the merkle root is non-zero this is a private sale and requires a valid proof
    if (config.merkleRoot == bytes32(0)) {
      // this is a public sale
      // IMPORTANT: data is only validated if the merkle root is checked! Public sales do not check any merkle roots!
      require(data.length == 0, "data not permitted on public sale");
    } else {
      // this is a private sale
      require(
        this.isValidMerkleProof(
          config.merkleRoot,
          _msgSender(),
          data,
          proof
        ) == true,
        "bad merkle proof for sale"
      );
    }

    // Require the sale to be open
    require(block.timestamp > config.startTime, "sale has not started yet");
    require(block.timestamp < config.endTime, "sale has ended");
    require(metrics.purchaseTotal < config.saleMaximum, "sale buy limit reached");

    // Reduce congestion by randomly assigning each user a delay time in a virtual queue based on comparing their address and a random value
    // if config.maxQueueTime == 0 the delay is 0
    require(block.timestamp - config.startTime > getFairQueueTime(_msgSender()), "not your turn yet");
    _;
  }

  /**
  Check that the new sale is a valid update
  - If the config already exists, it must not be over (cannot edit sale after it concludes)
  - Sale start, end, and max queue times must be consistent and not too far in the future
   */
  modifier validUpdate(Config calldata newConfig) {
    // get the existing config
    Config memory oldConfig = config;

    /**
     - @notice - Block updates after sale is over 
     - @dev - Since validUpdate is called by initialize(), we can have a new
     - sale here, identifiable by default randomValue of 0
     */
    if (randomValue != 0) {
      // this is an existing sale: cannot update after it has ended
      require(block.timestamp < oldConfig.endTime, "sale is over: cannot upate");
      if (block.timestamp > oldConfig.startTime) {
        // the sale has already started, some things should not be edited
        require(oldConfig.saleMaximum == newConfig.saleMaximum, "editing saleMaximum after sale start");
      }
    }

    // the total sale limit must be at least as large as the per-user limit

    // all required values must be present and reasonable
    // check if the caller accidentally entered a value in milliseconds instead of seconds
    require(newConfig.startTime <= 4102444800, "start > 4102444800 (Jan 1 2100)");
    require(newConfig.endTime <= 4102444800, "end > 4102444800 (Jan 1 2100)");
    require(newConfig.maxQueueTime <= 604800, "max queue time > 604800 (1 week)");
    require(newConfig.recipient != address(0), "recipient == address(0)");

    // sale, user, and purchase limits must be compatible
    require(newConfig.saleMaximum > 0, "saleMaximum == 0");
    require(newConfig.userMaximum > 0, "userMaximum == 0");
    require(newConfig.userMaximum <= newConfig.saleMaximum, "userMaximum > saleMaximum");
    require(newConfig.purchaseMinimum <= newConfig.userMaximum, "purchaseMinimum > userMaximum");

    // new sale times must be internally consistent
    require(newConfig.startTime + newConfig.maxQueueTime < newConfig.endTime, "sale must be open for at least maxQueueTime");

    _;
  }

  modifier validPaymentToken(IERC20Upgradeable token) {
    // check that this token is configured as a payment method
    PaymentTokenInfo memory info = paymentTokens[token];
    require(address(info.oracle) != address(0), "invalid payment token");

    _;
  }

  modifier areNativePaymentsEnabled() {
    require(nativePaymentsEnabled, "native payments disabled");

    _;
  }

  // Get info on a payment token
  function getPaymentToken(IERC20Upgradeable token) external view returns (PaymentTokenInfo memory) {
    return paymentTokens[token];
  }

  // Get a positive token price from a chainlink oracle
  function getOraclePrice(AggregatorV3Interface oracle) public view returns (uint) {
    (
        uint80 roundID,
        int _price,
        uint startedAt,
        uint timeStamp,
        uint80 answeredInRound
    ) = oracle.latestRoundData();

    require(_price > 0, "negative price");
    require(answeredInRound > 0, "answer == 0");
    require(timeStamp > 0, "round not complete");
    require(answeredInRound >= roundID, "stale price");

    return uint(_price);
  }

  /**
    Generate a pseudorandom value
    This is not a truly random value:
    - miners can alter the block hash
    - owners can repeatedly call setMerkleRoot()
    - owners can choose when to submit the transaction
  */
  function generatePseudorandomValue(bytes32 merkleRoot) public view returns(uint160) {
    return uint160(uint256(blockhash(block.number - 1))) ^ uint160(uint256(merkleRoot));
  }

  /**
    Get the delay in seconds that a specific buyer must wait after the sale begins in order to buy tokens in the sale

    Buyers cannot exploit the fair queue when:
    - The sale is private (merkle root != bytes32(0))
    - Each eligible buyer gets exactly one address in the merkle root

    Although miners and sellers can minimize the delay for an arbitrary address, these are not significant threats:
    - the economic opportunity to miners is zero or relatively small (only specific addresses can participate in private sales, and a better queue postion does not imply high returns)
    - sellers can repeatedly set merkle roots to achieve a favorable queue time for any address, but sellers already control the tokens being sold!
  */
  function getFairQueueTime(address buyer) public view returns(uint) {
    if (config.maxQueueTime == 0) {
      // there is no delay: all addresses may participate immediately
      return 0;
    }

    // calculate a distance between the random value and the user's address using the XOR distance metric (c.f. Kademlia)
    uint160 distance = uint160(buyer) ^ randomValue;

    // calculate a speed at which the queue is exhausted such that all users complete the queue by sale.maxQueueTime
    uint160 distancePerSecond = type(uint160).max / uint160(config.maxQueueTime);
    // return the delay (seconds)
    return distance / distancePerSecond;
  }

  /**
  Convert a token quantity (e.g. USDC or ETH) to a base currency (e.g. USD) with the same number of decimals as the price oracle (e.g. 8)

  Example: given 2 NCT tokens, each worth $1.23, tokensToBaseCurrency should return 246000000 ($2.46)

  Function arguments
  - tokenQuantity: 2000000000000000000
  - tokenDecimals: 18

  NCT/USD chainlink oracle (important! the oracle must be <token>/<base currency> not <currency>/<base token>, e.g. ETH/USD, ~$2000 not USD/ETH, ~0.0005)
  - baseCurrencyPerToken: 123000000
  - baseCurrencyDecimals: 8

  Calculation: 2000000000000000000 * 123000000 / 1000000000000000000

  Returns: 246000000
  */
  // function tokensToBaseCurrency(SafeERC20Upgradeable token, uint256 quantity) public view validPaymentToken(token) returns (uint256) {
  //   PaymentTokenInfo info = paymentTokens[token];
  //   return quantity * getOraclePrice(info.oracle) / (10 ** info.decimals);
  // }
  function tokensToBaseCurrency(uint256 tokenQuantity, uint256 tokenDecimals, AggregatorV3Interface oracle) public view returns (uint256 value) {
    return tokenQuantity * getOraclePrice(oracle) / (10 ** tokenDecimals);
  }

  function total() external override view returns(uint256) {
    return  metrics.purchaseTotal;
  }

  // return the amount bought by this user in base currency
  function buyerTotal(address user) external override view returns(uint256) {
    return  metrics.buyerTotal[user];
  }

  /**
  Records a purchase
  Follow the Checks -> Effects -> Interactions pattern
  * Checks: CALLER MUST ENSURE BUYER IS PERMITTED TO PARTICIPATE IN THIS SALE: THIS METHOD DOES NOT CHECK WHETHER THE BUYER SHOULD BE ABLE TO ACCESS THE SALE!
  * Effects: record the payment
  * Interactions: none!
  */
  function _execute(uint256 baseCurrencyQuantity, bytes calldata data) internal {
    // Checks
    uint256 userLimit = config.userMaximum;

    if (data.length > 0) {
      require(uint8(bytes1(data[0:1])) == PER_USER_PURCHASE_LIMIT, "unknown data");
      require(data.length == 33, "data length != 33 bytes");
      userLimit = uint256(bytes32(data[1:33]));
    }

    require(
      baseCurrencyQuantity + metrics.buyerTotal[_msgSender()] <= userLimit,
      "purchase exceeds your limit"
    );

    require(
      baseCurrencyQuantity + metrics.purchaseTotal <= config.saleMaximum,
      "purchase exceeds sale limit"
    );

    require(
      baseCurrencyQuantity >= config.purchaseMinimum,
      "purchase under minimum"
    );

    // Effects
    metrics.purchaseCount += 1;
    if (metrics.buyerTotal[_msgSender()] == 0) {
      // if no prior purchases, this is a new buyer
      metrics.buyerCount += 1;
    }
    metrics.purchaseTotal += baseCurrencyQuantity;
    metrics.buyerTotal[_msgSender()] += baseCurrencyQuantity;
  }

  /**
  Settle payment made with payment token
  Important: this function has no checks! Only call if the purchase is valid!
  */
  function _settlePaymentToken(uint256 baseCurrencyValue, IERC20Upgradeable token, uint256 quantity) internal {
    uint256 fee = 0;
    if (feeBips > 0) {
      fee = (quantity * feeBips) / 10000;
      token.safeTransferFrom(_msgSender(), feeRecipient, fee);
    }
    token.safeTransferFrom(_msgSender(), address(this), quantity - fee);
    emit Buy(_msgSender(), address(token), baseCurrencyValue, quantity, fee);
  }

  /**
  Settle payment made with native token
  Important: this function has no checks! Only call if the purchase is valid!
  */
  function _settleNativeToken(uint256 baseCurrencyValue, uint256 nativeTokenQuantity) internal {
    uint256 nativeFee = 0;
    if (feeBips > 0) {
      nativeFee = (nativeTokenQuantity * feeBips) / 10000;
      _asyncTransfer(feeRecipient, nativeFee);
    }
    _asyncTransfer(config.recipient, nativeFee);
    // This contract will hold the native token until claimed by the owner
    emit Buy(_msgSender(), address(0), baseCurrencyValue, nativeTokenQuantity, nativeFee);
  }

  /**
  Pay with the payment token (e.g. USDC)
  */
  function buyWithToken(
    IERC20Upgradeable token,
    uint256 quantity,
    bytes calldata data,
    bytes32[] calldata proof
  ) external override canAccessSale(data, proof) validPaymentToken(token) nonReentrant {
    // convert to base currency from native tokens
    PaymentTokenInfo memory tokenInfo = paymentTokens[token];
    uint256 baseCurrencyValue = tokensToBaseCurrency(quantity, tokenInfo.decimals, tokenInfo.oracle);
    // Checks and Effects
    _execute(baseCurrencyValue, data);
    // Interactions
    _settlePaymentToken(baseCurrencyValue, token, quantity);
  }

  /**
  Pay with the native token (e.g. ETH)
   */
  function buyWithNative(
    bytes calldata data,
    bytes32[] calldata proof
  ) external override payable canAccessSale(data, proof) areNativePaymentsEnabled nonReentrant {
    // convert to base currency from native tokens
    uint256 baseCurrencyValue = tokensToBaseCurrency(msg.value, NATIVE_TOKEN_DECIMALS, nativeTokenPriceOracle);
    // Checks and Effects
    _execute(baseCurrencyValue, data);
    // Interactions
    _settleNativeToken(baseCurrencyValue, msg.value);
  }

  /**
  External management functions (only the owner may update the sale)
  */
  function update(Config calldata _config) external validUpdate(_config) onlyOwner {
    config = _config;
    // updates always reset the random value
    randomValue = generatePseudorandomValue(config.merkleRoot);
    emit Update(config);
  }

  /**
  Public management functions
  */
  // Sweep an ERC20 token to the recipient (public function)
  function sweepToken(IERC20Upgradeable token) external {
    uint256 amount = token.balanceOf(address(this));
    token.safeTransfer(config.recipient, amount);
    emit SweepToken(address(token), amount);
  }

  // sweep native token to the recipient (public function)
  function sweepNative() external {
    uint256 amount = address(this).balance;
    (bool success, ) = config.recipient.call{value: amount}("");
    require(success, "Transfer failed.");
    emit SweepNative(amount);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.16;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "./FlatPriceSale.sol";

contract FlatPriceSaleFactory {
  address immutable public implementation;
  string public constant VERSION = '2.0';

  event NewSale(address indexed implementation, FlatPriceSale indexed clone, Config config, string baseCurrency, AggregatorV3Interface nativeOracle, bool nativePaymentsEnabled);

  constructor(address _implementation) {
    implementation = _implementation;
  }

  function newSale(
    address _owner,
    Config calldata _config,
    string calldata _baseCurrency,
    bool _nativePaymentsEnabled,
    AggregatorV3Interface _nativeTokenPriceOracle,
    IERC20Upgradeable[] calldata tokens,
    AggregatorV3Interface[] calldata oracles,
    uint8[] calldata decimals
  ) external returns (FlatPriceSale sale) {
    sale = FlatPriceSale(Clones.clone(address(implementation)));

    emit NewSale(implementation, sale, _config, _baseCurrency, _nativeTokenPriceOracle, _nativePaymentsEnabled);

    sale.initialize(
      _owner,
      _config,
      _baseCurrency,
      _nativePaymentsEnabled,
      _nativeTokenPriceOracle,
      tokens,
      oracles,
      decimals
    );

  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";

// Upgradeable contracts are required to use clone() in SaleFactory
abstract contract Sale is ReentrancyGuardUpgradeable, OwnableUpgradeable {
  using SafeERC20Upgradeable for IERC20Upgradeable;
  event Buy(address indexed buyer, address indexed token, uint256 baseCurrencyValue, uint256 tokenValue, uint256 tokenFee);

  /**
  Important: the constructor is only called once on the implementation contract (which is never initialized)
  Clones using this implementation cannot use this constructor method.
  Thus every clone must use the same fields stored in the constructor (feeBips, feeRecipient)
  */

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
      _disableInitializers();
  }

  // is this user permitted to access a sale?
  function isValidMerkleProof(
      bytes32 root,
      address account,
      bytes calldata data,
      bytes32[] calldata proof
  ) public pure returns (bool) {
    // check if the account is in the merkle tree
    bytes32 leaf = keccak256(abi.encodePacked(account, data));
    if (MerkleProofUpgradeable.verify(proof, root, leaf)) {
      return true;
    }
    return false;
  }

  function buyWithToken(
    IERC20Upgradeable token,
    uint256 quantity,
    bytes calldata data,
    bytes32[] calldata proof
  ) external virtual {}

  function buyWithNative(
    bytes calldata data,
    bytes32[] calldata proof
  ) external virtual payable {}


  function isOpen() public virtual view returns(bool) {}

  function isOver() public virtual view returns(bool) {}

  function buyerTotal(address user) external virtual view returns(uint256) {}

  function total() external virtual view returns(uint256) {}
}