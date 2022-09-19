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
// OpenZeppelin Contracts (last updated v4.7.0) (finance/PaymentSplitter.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/utils/SafeERC20Upgradeable.sol";
import "../utils/AddressUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @title PaymentSplitter
 * @dev This contract allows to split Ether payments among a group of accounts. The sender does not need to be aware
 * that the Ether will be split in this way, since it is handled transparently by the contract.
 *
 * The split can be in equal parts or in any other arbitrary proportion. The way this is specified is by assigning each
 * account to a number of shares. Of all the Ether that this contract receives, each account will then be able to claim
 * an amount proportional to the percentage of total shares they were assigned. The distribution of shares is set at the
 * time of contract deployment and can't be updated thereafter.
 *
 * `PaymentSplitter` follows a _pull payment_ model. This means that payments are not automatically forwarded to the
 * accounts but kept in this contract, and the actual transfer is triggered as a separate step by calling the {release}
 * function.
 *
 * NOTE: This contract assumes that ERC20 tokens will behave similarly to native tokens (Ether). Rebasing tokens, and
 * tokens that apply fees during transfers, are likely to not be supported as expected. If in doubt, we encourage you
 * to run tests before sending real value to this contract.
 */
contract PaymentSplitterUpgradeable is Initializable, ContextUpgradeable {
    event PayeeAdded(address account, uint256 shares);
    event PaymentReleased(address to, uint256 amount);
    event ERC20PaymentReleased(IERC20Upgradeable indexed token, address to, uint256 amount);
    event PaymentReceived(address from, uint256 amount);

    uint256 private _totalShares;
    uint256 private _totalReleased;

    mapping(address => uint256) private _shares;
    mapping(address => uint256) private _released;
    address[] private _payees;

    mapping(IERC20Upgradeable => uint256) private _erc20TotalReleased;
    mapping(IERC20Upgradeable => mapping(address => uint256)) private _erc20Released;

    /**
     * @dev Creates an instance of `PaymentSplitter` where each account in `payees` is assigned the number of shares at
     * the matching position in the `shares` array.
     *
     * All addresses in `payees` must be non-zero. Both arrays must have the same non-zero length, and there must be no
     * duplicates in `payees`.
     */
    function __PaymentSplitter_init(address[] memory payees, uint256[] memory shares_) internal onlyInitializing {
        __PaymentSplitter_init_unchained(payees, shares_);
    }

    function __PaymentSplitter_init_unchained(address[] memory payees, uint256[] memory shares_) internal onlyInitializing {
        require(payees.length == shares_.length, "PaymentSplitter: payees and shares length mismatch");
        require(payees.length > 0, "PaymentSplitter: no payees");

        for (uint256 i = 0; i < payees.length; i++) {
            _addPayee(payees[i], shares_[i]);
        }
    }

    /**
     * @dev The Ether received will be logged with {PaymentReceived} events. Note that these events are not fully
     * reliable: it's possible for a contract to receive Ether without triggering this function. This only affects the
     * reliability of the events, and not the actual splitting of Ether.
     *
     * To learn more about this see the Solidity documentation for
     * https://solidity.readthedocs.io/en/latest/contracts.html#fallback-function[fallback
     * functions].
     */
    receive() external payable virtual {
        emit PaymentReceived(_msgSender(), msg.value);
    }

    /**
     * @dev Getter for the total shares held by payees.
     */
    function totalShares() public view returns (uint256) {
        return _totalShares;
    }

    /**
     * @dev Getter for the total amount of Ether already released.
     */
    function totalReleased() public view returns (uint256) {
        return _totalReleased;
    }

    /**
     * @dev Getter for the total amount of `token` already released. `token` should be the address of an IERC20
     * contract.
     */
    function totalReleased(IERC20Upgradeable token) public view returns (uint256) {
        return _erc20TotalReleased[token];
    }

    /**
     * @dev Getter for the amount of shares held by an account.
     */
    function shares(address account) public view returns (uint256) {
        return _shares[account];
    }

    /**
     * @dev Getter for the amount of Ether already released to a payee.
     */
    function released(address account) public view returns (uint256) {
        return _released[account];
    }

    /**
     * @dev Getter for the amount of `token` tokens already released to a payee. `token` should be the address of an
     * IERC20 contract.
     */
    function released(IERC20Upgradeable token, address account) public view returns (uint256) {
        return _erc20Released[token][account];
    }

    /**
     * @dev Getter for the address of the payee number `index`.
     */
    function payee(uint256 index) public view returns (address) {
        return _payees[index];
    }

    /**
     * @dev Getter for the amount of payee's releasable Ether.
     */
    function releasable(address account) public view returns (uint256) {
        uint256 totalReceived = address(this).balance + totalReleased();
        return _pendingPayment(account, totalReceived, released(account));
    }

    /**
     * @dev Getter for the amount of payee's releasable `token` tokens. `token` should be the address of an
     * IERC20 contract.
     */
    function releasable(IERC20Upgradeable token, address account) public view returns (uint256) {
        uint256 totalReceived = token.balanceOf(address(this)) + totalReleased(token);
        return _pendingPayment(account, totalReceived, released(token, account));
    }

    /**
     * @dev Triggers a transfer to `account` of the amount of Ether they are owed, according to their percentage of the
     * total shares and their previous withdrawals.
     */
    function release(address payable account) public virtual {
        require(_shares[account] > 0, "PaymentSplitter: account has no shares");

        uint256 payment = releasable(account);

        require(payment != 0, "PaymentSplitter: account is not due payment");

        _released[account] += payment;
        _totalReleased += payment;

        AddressUpgradeable.sendValue(account, payment);
        emit PaymentReleased(account, payment);
    }

    /**
     * @dev Triggers a transfer to `account` of the amount of `token` tokens they are owed, according to their
     * percentage of the total shares and their previous withdrawals. `token` must be the address of an IERC20
     * contract.
     */
    function release(IERC20Upgradeable token, address account) public virtual {
        require(_shares[account] > 0, "PaymentSplitter: account has no shares");

        uint256 payment = releasable(token, account);

        require(payment != 0, "PaymentSplitter: account is not due payment");

        _erc20Released[token][account] += payment;
        _erc20TotalReleased[token] += payment;

        SafeERC20Upgradeable.safeTransfer(token, account, payment);
        emit ERC20PaymentReleased(token, account, payment);
    }

    /**
     * @dev internal logic for computing the pending payment of an `account` given the token historical balances and
     * already released amounts.
     */
    function _pendingPayment(
        address account,
        uint256 totalReceived,
        uint256 alreadyReleased
    ) private view returns (uint256) {
        return (totalReceived * _shares[account]) / _totalShares - alreadyReleased;
    }

    /**
     * @dev Add a new payee to the contract.
     * @param account The address of the payee to add.
     * @param shares_ The number of shares owned by the payee.
     */
    function _addPayee(address account, uint256 shares_) private {
        require(account != address(0), "PaymentSplitter: account is the zero address");
        require(shares_ > 0, "PaymentSplitter: shares are 0");
        require(_shares[account] == 0, "PaymentSplitter: account already has shares");

        _payees.push(account);
        _shares[account] = shares_;
        _totalShares = _totalShares + shares_;
        emit PayeeAdded(account, shares_);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[43] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981Upgradeable is IERC165Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721Upgradeable.sol";
import "./IERC721ReceiverUpgradeable.sol";
import "./extensions/IERC721MetadataUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../utils/StringsUpgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC721Upgradeable, IERC721MetadataUpgradeable {
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    function __ERC721_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC721_init_unchained(name_, symbol_);
    }

    function __ERC721_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721Upgradeable.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721Upgradeable.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721Upgradeable.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721ReceiverUpgradeable(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721ReceiverUpgradeable.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[44] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/common/ERC2981.sol)

pragma solidity ^0.8.0;

import "../../interfaces/IERC2981Upgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the NFT Royalty Standard, a standardized way to retrieve royalty payment information.
 *
 * Royalty information can be specified globally for all token ids via {_setDefaultRoyalty}, and/or individually for
 * specific token ids via {_setTokenRoyalty}. The latter takes precedence over the first.
 *
 * Royalty is specified as a fraction of sale price. {_feeDenominator} is overridable but defaults to 10000, meaning the
 * fee is specified in basis points by default.
 *
 * IMPORTANT: ERC-2981 only specifies a way to signal royalty information and does not enforce its payment. See
 * https://eips.ethereum.org/EIPS/eip-2981#optional-royalty-payments[Rationale] in the EIP. Marketplaces are expected to
 * voluntarily pay royalties together with sales, but note that this standard is not yet widely supported.
 *
 * _Available since v4.5._
 */
abstract contract ERC2981Upgradeable is Initializable, IERC2981Upgradeable, ERC165Upgradeable {
    function __ERC2981_init() internal onlyInitializing {
    }

    function __ERC2981_init_unchained() internal onlyInitializing {
    }
    struct RoyaltyInfo {
        address receiver;
        uint96 royaltyFraction;
    }

    RoyaltyInfo private _defaultRoyaltyInfo;
    mapping(uint256 => RoyaltyInfo) private _tokenRoyaltyInfo;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165Upgradeable, ERC165Upgradeable) returns (bool) {
        return interfaceId == type(IERC2981Upgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @inheritdoc IERC2981Upgradeable
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) public view virtual override returns (address, uint256) {
        RoyaltyInfo memory royalty = _tokenRoyaltyInfo[_tokenId];

        if (royalty.receiver == address(0)) {
            royalty = _defaultRoyaltyInfo;
        }

        uint256 royaltyAmount = (_salePrice * royalty.royaltyFraction) / _feeDenominator();

        return (royalty.receiver, royaltyAmount);
    }

    /**
     * @dev The denominator with which to interpret the fee set in {_setTokenRoyalty} and {_setDefaultRoyalty} as a
     * fraction of the sale price. Defaults to 10000 so fees are expressed in basis points, but may be customized by an
     * override.
     */
    function _feeDenominator() internal pure virtual returns (uint96) {
        return 10000;
    }

    /**
     * @dev Sets the royalty information that all ids in this contract will default to.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setDefaultRoyalty(address receiver, uint96 feeNumerator) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: invalid receiver");

        _defaultRoyaltyInfo = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Removes default royalty information.
     */
    function _deleteDefaultRoyalty() internal virtual {
        delete _defaultRoyaltyInfo;
    }

    /**
     * @dev Sets the royalty information for a specific token id, overriding the global default.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: Invalid parameters");

        _tokenRoyaltyInfo[tokenId] = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Resets royalty information for the token id back to the global default.
     */
    function _resetTokenRoyalty(uint256 tokenId) internal virtual {
        delete _tokenRoyaltyInfo[tokenId];
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[48] private __gap;
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
interface IERC165Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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
// Copyright (C) 2022 Simplr
pragma solidity 0.8.11;

import "./IAffiliateRegistry.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/**
 * @title Affiliate
 * @dev   Contract that can be inherited to make any contract interact with AffiliateRegistry.
 * @author Chain Labs Team
 */
contract Affiliate {
    IAffiliateRegistry private _affiliateRegistry;
    bytes32 private _projectId;

    event AffiliateShareTransferred(
        address indexed affiliate,
        bytes32 indexed project,
        uint256 value
    );

    function getAffiliateRegistry() public view returns (IAffiliateRegistry) {
        return _affiliateRegistry;
    }

    function getProjectId() public view returns (bytes32) {
        return _projectId;
    }

    function _setAffiliateModule(
        IAffiliateRegistry newRegistry,
        bytes32 projectId
    ) internal {
        require(
            address(newRegistry) != address(0),
            "Affiliate: Registry cannot be null address"
        );
        require(projectId != bytes32(0), "Affiliate: zero project id");
        _affiliateRegistry = newRegistry;
        _projectId = projectId;
    }

    function _setProjectId(bytes32 projectId) internal {
        require(projectId != bytes32(0), "Affiliate: zero project id");
        _projectId = projectId;
    }

    function _transferAffiliateShare(
        bytes memory signature,
        address affiliate,
        uint256 value
    ) internal {
        require(_isAffiliateModuleInitialised(), "Affiliate: not initialised");
        bool isAffiliate;
        uint256 shareValue;
        (isAffiliate, shareValue) = _affiliateRegistry.getAffiliateShareValue(
            signature,
            affiliate,
            _projectId,
            value
        );
        if (isAffiliate) {
            Address.sendValue(payable(affiliate), shareValue);
            emit AffiliateShareTransferred(affiliate, _projectId, shareValue);
        }
    }

    function _isAffiliateModuleInitialised() internal view returns (bool) {
        return
            _projectId != bytes32(0) &&
            address(_affiliateRegistry) != address(0);
    }
}

// SPDX-License-Identifier: MIT
// Copyright (C) 2022 Simplr
pragma solidity 0.8.11;

/**
 * @title Affiliate Registry Interface
 * @dev   Interface with necessary functionalities of Affiliate Registry.
 * @author Chain Labs Team
 */
interface IAffiliateRegistry {
    function setAffiliateShares(uint256 _affiliateShares, bytes32 _projectId)
        external;

    function registerProject(string memory projectName, uint256 affiliateShares)
        external
        returns (bytes32 projectId);

    function getProjectId(string memory _projectName, address _projectOwner)
        external
        view
        returns (bytes32 projectId);

    function getAffiliateShareValue(
        bytes memory signature,
        address affiliate,
        bytes32 projectId,
        uint256 value
    ) external view returns (bool _isAffiliate, uint256 _shareValue);
}

// SPDX-License-Identifier: MIT
// Copyright (C) 2022 Simplr
pragma solidity 0.8.11;

import "./modules/Affiliable.sol";
import "../interface/ICollectionStruct.sol";
import "./ContractMetadata.sol";

/// @title Collection
/// @author Chain Labs
/// @notice Main contract that is made up of building blocks and is ready to be used that extends the affiliate functionality.
/// @dev Inherits all the modules and base collection
contract Collection is ICollectionStruct, Affiliable, ContractMetadata {
    /// @notice setup collection
    /// @dev setup all the modules and base collection
    /// @param _baseCollection struct conatining setup parameters of base collection
    /// @param _presaleable struct conatining setup parameters of presale module
    /// @param _paymentSplitter struct conatining setup parameters of payment splitter module
    /// @param _projectURIProvenance provenance of revealed project URI
    /// @param _royalties struct conatining setup parameters of royalties module
    /// @param _reserveTokens number of tokens to be reserved
    function setup(
        BaseCollectionStruct memory _baseCollection,
        PresaleableStruct memory _presaleable,
        PaymentSplitterStruct memory _paymentSplitter,
        bytes32 _projectURIProvenance,
        RoyaltyInfo memory _royalties,
        uint256 _reserveTokens
    ) external {
        _setup(
            _baseCollection,
            _presaleable,
            _paymentSplitter,
            _projectURIProvenance,
            _royalties,
            _reserveTokens
        );
    }

    /// @notice setup collection with affiliate module
    /// @dev setup all the modules and base collection including affiliate module
    /// @param _baseCollection struct conatining setup parameters of base collection
    /// @param _presaleable struct conatining setup parameters of presale module
    /// @param _paymentSplitter struct conatining setup parameters of payment splitter module
    /// @param _projectURIProvenance provenance of revealed project URI
    /// @param _royalties struct conatining setup parameters of royalties module
    /// @param _reserveTokens number of tokens to be reserved
    /// @param _registry address of Simplr Affiliate registry
    /// @param _projectId project ID of Simplr Collection
    function setupWithAffiliate(
        BaseCollectionStruct memory _baseCollection,
        PresaleableStruct memory _presaleable,
        PaymentSplitterStruct memory _paymentSplitter,
        bytes32 _projectURIProvenance,
        RoyaltyInfo memory _royalties,
        uint256 _reserveTokens,
        IAffiliateRegistry _registry,
        bytes32 _projectId
    ) external {
        _setup(
            _baseCollection,
            _presaleable,
            _paymentSplitter,
            _projectURIProvenance,
            _royalties,
            _reserveTokens
        );
        _setAffiliateModule(_registry, _projectId);
    }

    /// @notice internal method to setup collection
    /// @dev internal method to setup all the modules and base collection
    /// @param _baseCollection struct conatining setup parameters of base collection
    /// @param _presaleable struct conatining setup parameters of presale module
    /// @param _paymentSplitter struct conatining setup parameters of payment splitter module
    /// @param _projectURIProvenance provenance of revealed project URI
    /// @param _royalties struct conatining setup parameters of royalties module
    /// @param _reserveTokens number of tokens to be reserved
    function _setup(
        BaseCollectionStruct memory _baseCollection,
        PresaleableStruct memory _presaleable,
        PaymentSplitterStruct memory _paymentSplitter,
        bytes32 _projectURIProvenance,
        RoyaltyInfo memory _royalties,
        uint256 _reserveTokens
    ) private initializer {
        setupBaseCollection(
            _baseCollection.name,
            _baseCollection.symbol,
            _baseCollection.admin,
            _baseCollection.maximumTokens,
            _baseCollection.maxPurchase,
            _baseCollection.maxHolding,
            _baseCollection.price,
            _baseCollection.publicSaleStartTime,
            _baseCollection.projectURI
        );
        setupPresale(
            _presaleable.presaleReservedTokens,
            _presaleable.presalePrice,
            _presaleable.presaleStartTime,
            _presaleable.presaleMaxHolding,
            _presaleable.presaleWhitelist
        );
        setupPaymentSplitter(
            _paymentSplitter.simplr,
            _paymentSplitter.simplrShares,
            _paymentSplitter.payees,
            _paymentSplitter.shares
        );
        setProvenance(_projectURIProvenance);
        _setReserveTokens(_reserveTokens);
        _setRoyalties(_royalties);
    }
}

// SPDX-License-Identifier: MIT
// Copyright (C) 2022 Simplr
pragma solidity 0.8.11;

/// @title Contract Metadata
/// @author Chain Labs
/// @notice Stores important constant values of contract metadata
/// @dev constants that can help identify the collection type and version
contract ContractMetadata {
    /// @notice Contract Name
    /// @dev State used to identify the collection type
    /// @return CONTRACT_NAME name of contract type as string
    string public constant CONTRACT_NAME = "Collection";

    /// @notice Version
    /// @dev State used to identify the collection version
    /// @return VERSION version of contract as string
    string public constant VERSION = "0.1.0";
}

// SPDX-License-Identifier: MIT
// Copyright (C) 2022 Simplr
pragma solidity 0.8.11;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

/// @title Base Collection
/// @author Chain Labs
/// @notice Base contract for Collection
/// @dev Uses ERC721 as NFT standard
contract BaseCollection is
    OwnableUpgradeable,
    PausableUpgradeable,
    ERC721Upgradeable
{
    //------------------------------------------------------//
    //
    //  Storage
    //
    //------------------------------------------------------//
    /// @notice Maximum tokens that can ever exist
    /// @dev maximum tokens that can be minted
    /// @return maximumTokens maximum number of tokens
    uint256 public maximumTokens;

    /// @notice Maximum tokens that can be bought per transaction in public sale
    /// @dev max mint/buy limit in public sale
    /// @return maxPurchase mint limit per transaction in public sale
    uint256 public maxPurchase;

    /// @notice Maximum tokens an account can buy/mint in public sale
    /// @dev maximum tokens an account can buy/mint in public sale
    /// @return maxHolding maximum tokens an account can hold in public sale
    uint256 public maxHolding;

    /// @notice price per token in public sale
    /// @dev price per token in public sale
    /// @return price price per token in public sale
    uint256 public price;

    /// @notice Next token ID to be minted
    /// @dev counter for tokenID, this accounts for reserved tokens
    /// @return tokensCount next token ID to be minted
    uint256 public tokensCount;

    /// @notice starting token ID to be minted during sale (presale + public sale)
    /// @dev this is adjusted to allow reserving tokens without ever minting them
    /// @return startingTokenIndex first token ID to be minted during sale
    uint256 public startingTokenIndex;

    /// @notice total supply of tokens
    /// @dev it is incremented by 1 everytime a token is minted
    /// @return totalSupply total supply of tokens
    uint256 public totalSupply;

    /// @notice timestamp when public (main) sale starts
    /// @dev public sale starts automatically at this time
    /// @return publicSaleStartTime timestamp when public sale starts
    uint256 public publicSaleStartTime;

    /// @notice Base URI for assets
    /// @dev this state accounts for both placeholer media as well as revealed media
    /// @return projectURI base URI for assets
    string public projectURI;

    /// @notice IPFS CID of JSON file collection metadata
    /// @dev The JSON file is created when the Simplr Collection form is filled and is used by the interface
    /// @return metadata IPFS CID
    string public metadata;

    /// @notice Stores number of tokens minted by an account
    /// @dev mapping of accounts to tokens minted by the account
    /// @return tokensMintedByAccount number of tokens minted
    mapping(address => uint256) public tokensMinted;

    //------------------------------------------------------//
    //
    //  Events
    //
    //------------------------------------------------------//

    event MetadataUpdated(string indexed metadata);

    event PriceUpdated(uint256 newPrice);

    event MaxPurchaseUpdated(uint256 newMaxPurchase);

    event MaxHoldingUpdated(uint256 newMaxHolding);

    event Minted(address indexed receiver, uint256 quantity);

    //------------------------------------------------------//
    //
    //  Setup
    //
    //------------------------------------------------------//

    /// @notice setup states of public sale and collection constants
    /// @dev internal method to setup base collection
    /// @param _name Collection Name
    /// @param _symbol Collection Symbol
    /// @param _admin admin address
    /// @param _maximumTokens maximum number of tokens
    /// @param _maxPurchase maximum number of tokens that can be bought per transaction in public sale
    /// @param _maxHolding maximum number of tokens an account can hold in public sale
    /// @param _price price per NFT token during public sale.
    /// @param _publicSaleStartTime public sale start timestamp
    /// @param _projectURI URI for collection media and assets
    function setupBaseCollection(
        string memory _name,
        string memory _symbol,
        address _admin,
        uint256 _maximumTokens,
        uint16 _maxPurchase,
        uint16 _maxHolding,
        uint256 _price,
        uint256 _publicSaleStartTime,
        string memory _projectURI
    ) internal {
        require(_admin != address(0), "BC:001");
        require(_maximumTokens != 0, "BC:002");
        require(
            _maximumTokens >= _maxHolding && _maxHolding >= _maxPurchase,
            "BC:003"
        );
        __ERC721_init(_name, _symbol);
        _transferOwnership(_admin);
        maximumTokens = _maximumTokens;
        maxPurchase = _maxPurchase;
        maxHolding = _maxHolding;
        price = _price;
        publicSaleStartTime = _publicSaleStartTime;
        projectURI = _projectURI;
    }

    //------------------------------------------------------//
    //
    //  Owner only functions
    //
    //------------------------------------------------------//

    /// @notice updates the collection details (not collection assets)
    /// @dev updates the IPFS CID that points to new collection details
    /// @param _metadata new IPFS CID with updated collection details
    function setMetadata(string memory _metadata) external {
        // can only be invoked before setup or by owner after setup
        require(!isSetupComplete() || msg.sender == owner(), "BC:004");
        require(bytes(_metadata).length != 0, "BC:005");
        metadata = _metadata;
        emit MetadataUpdated(_metadata);
    }

    /// @notice Pause sale of tokens
    /// @dev pause all the open access methods like buy and presale buy
    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    /// @notice unpause sale of tokens
    /// @dev unpause all the open access methods like buy and presale buy
    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    /// @notice Change main sale price
    /// @dev only owner can update the main sale price
    /// @param _newPrice new price
    function setPrice(uint256 _newPrice) external onlyOwner {
        price = _newPrice;
        emit PriceUpdated(_newPrice);
    }

    /// @notice Change number of tokens that be minted in one transaction
    /// @dev only owner can update maximum purchase limit per transaction
    /// @param _newMaxPurchase new maximum purchase limit
    function setMaxPurchase(uint16 _newMaxPurchase) external onlyOwner {
        maxPurchase = _newMaxPurchase;
        emit MaxPurchaseUpdated(_newMaxPurchase);
    }

    /// @notice Change number of tokens that be minted by an account
    /// @dev only owner can update maximum holding limit per account
    /// @param _newMaxHolding new maximum holding limit
    function setMaxHolding(uint16 _newMaxHolding) external onlyOwner {
        maxHolding = _newMaxHolding;
        emit MaxHoldingUpdated(_newMaxHolding);
    }

    //------------------------------------------------------//
    //
    //  Public function
    //
    //------------------------------------------------------//

    /// @notice buy during public sale
    /// @dev method to buy during public sale without affiliate
    /// @param _buyer address of buyer
    /// @param _quantity number of tokens to buy/mint
    function buy(address _buyer, uint256 _quantity) external payable virtual {
        _buy(_buyer, _quantity);
    }

    /// @notice check if public sale is active or not
    /// @dev it compares start time stamp with current time and check if sold or not
    /// @return isSaleActive a boolean, true - sale active, false - sale inactive
    function isSaleActive() public view returns (bool) {
        return
            block.timestamp >= publicSaleStartTime &&
            tokensCount + startingTokenIndex != maximumTokens;
    }

    /// @notice checks if setup is complete
    /// @dev if constants are set, setup is complete
    /// @return boolean checks if setup is complete
    function isSetupComplete() public view virtual returns (bool) {
        return maximumTokens != 0 && publicSaleStartTime != 0;
    }

    //------------------------------------------------------//
    //
    //  Internal function
    //
    //------------------------------------------------------//

    /// @notice internal method to buy during public sale
    /// @dev method to buy during public sale to be used with or without affiliate
    /// @param _buyer address of buyer
    /// @param _quantity number of tokens to buy/mint
    function _buy(address _buyer, uint256 _quantity) internal whenNotPaused {
        require(isSaleActive(), "BC:010");
        uint256 tokensMintedByUser = tokensMinted[_buyer];
        require(msg.value == (price * _quantity), "BC:011");
        require(_quantity <= maxPurchase, "BC:012");
        require(tokensMintedByUser + _quantity <= maxHolding, "BC:013");
        tokensMinted[_buyer] = tokensMintedByUser + _quantity;
        _manufacture(_buyer, _quantity);
    }

    /// @notice mints amount of tokens to an account
    /// @dev it mints tokens to an account doing sanity check of not crossing maximum tokens limit
    /// @param _receiver address of buyer
    /// @param _quantity amount of tokens to be minted
    function _manufacture(address _receiver, uint256 _quantity) internal {
        uint256 currentTokenId = tokensCount + startingTokenIndex;
        require(currentTokenId + _quantity <= maximumTokens, "BC:014");
        uint256 newTokensCount = currentTokenId + _quantity;
        tokensCount += _quantity;
        for (
            currentTokenId;
            currentTokenId < newTokensCount;
            currentTokenId++
        ) {
            _safeMint(_receiver, currentTokenId + 1);
        }
        emit Minted(_receiver, _quantity);
    }

    /// @inheritdoc ERC721Upgradeable
    function _baseURI() internal view virtual override returns (string memory) {
        return projectURI;
    }

    /// @inheritdoc	ERC721Upgradeable
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        if (from == address(0) && to != address(0)) {
            totalSupply++;
        }
    }
}

// SPDX-License-Identifier: MIT
// Copyright (C) 2022 Simplr
pragma solidity 0.8.11;

import "./Royalties.sol";
import "../../../affiliate/Affiliate.sol";

/// @title Affiliable
/// @author Chain Labs
/// @notice Module that adds functionality of affiliate.
/// @dev Uses Simplr Affiliate Infrastructure
contract Affiliable is Royalties, Affiliate {
    //------------------------------------------------------//
    //
    //  Modifiers
    //
    //------------------------------------------------------//

    modifier affiliatePurchase(bytes memory _signature, address _affiliate) {
        _;
        _transferAffiliateShare(_signature, _affiliate, msg.value);
    }

    //------------------------------------------------------//
    //
    //  Public function
    //
    //------------------------------------------------------//

    /// @notice Buy using Affiliate shares
    /// @dev Transfers the affiliate share directly to affiliate address
    /// @param _receiver address of buyer
    /// @param _quantity number of tokens to be bought
    /// @param _signature unique signature of affiliate
    /// @param _affiliate address of affiliate
    function affiliateBuy(
        address _receiver,
        uint256 _quantity,
        bytes memory _signature,
        address _affiliate
    ) external payable virtual affiliatePurchase(_signature, _affiliate) {
        _buy(_receiver, _quantity);
    }

    /// @notice presale buy using Affiliate shares
    /// @dev Transfers the affiliate share directly to affiliate address
    /// @param _proofs merkle proof for whitelist
    /// @param _receiver address of buyer
    /// @param _quantity number of tokens to be bought
    /// @param _signature unique signature of affiliate
    /// @param _affiliate address of affiliate
    function affiliatePresaleBuy(
        bytes32[] calldata _proofs,
        address _receiver,
        uint256 _quantity,
        bytes memory _signature,
        address _affiliate
    ) external payable virtual affiliatePurchase(_signature, _affiliate) {
        _presaleBuy(_proofs, _receiver, _quantity);
    }

    /// @notice is affiliate module active or not
    /// @dev once set, it cannot be updated
    /// @return boolean checks if affiliate module is active or not
    function isAffiliateModuleInitialised() external view returns (bool) {
        return _isAffiliateModuleInitialised();
    }
}

// SPDX-License-Identifier: MIT
// Copyright (C) 2022 Simplr
pragma solidity 0.8.11;

import "@openzeppelin/contracts-upgradeable/finance/PaymentSplitterUpgradeable.sol";
import "../base/BaseCollection.sol";

/// @title Payment Splitable
/// @author Chain Labs
/// @notice Module that adds functionality of payment splitting
/// @dev Core functionality inherited from OpenZeppelin's Payment Splitter
contract PaymentSplitable is BaseCollection, PaymentSplitterUpgradeable {
    //------------------------------------------------------//
    //
    //  Storage
    //
    //------------------------------------------------------//
    /// @notice Shares of Simplr in the sale
    /// @dev percentage (eg. 100% - 10^18) of simplr in the sale
    /// @return SIMPLR_SHARES shares of simplr currently set to 0.0000000000000001%
    uint256 public SIMPLR_SHARES; // share of Simplr

    /// @notice address of Simplr's Fee receiver
    /// @dev Gnosis Safe Simplr Fee Receiver
    /// @return SIMPLR_RECEIVER_ADDRESS address that will receive fee i.e. Simplr Shares
    address public SIMPLR_RECEIVER_ADDRESS;

    //------------------------------------------------------//
    //
    //  Setup
    //
    //------------------------------------------------------//

    /// @notice setup payment splitting details for collection
    /// @dev internal method and only be invoked once during setup
    /// @param _simplr address of simplr beneficicary address
    /// @param _simplrShares percentage share of simplr, eg. 15% = parseUnits(15,16) or toWei(0.15) or 15*10^16
    /// @param _payees array of payee address
    /// @param _shares array of payee shares, index for both arrays should match for a payee
    function setupPaymentSplitter(
        address _simplr,
        uint256 _simplrShares,
        address[] memory _payees,
        uint256[] memory _shares
    ) internal {
        require(_payees.length == _shares.length, "PS:001");
        SIMPLR_RECEIVER_ADDRESS = _simplr;
        SIMPLR_SHARES = _simplrShares;
        _payees[_payees.length - 1] = _simplr;
        _shares[_payees.length - 1] = _simplrShares;
        __PaymentSplitter_init(_payees, _shares);
    }
}

// SPDX-License-Identifier: MIT
// Copyright (C) 2022 Simplr
pragma solidity 0.8.11;

import "./PaymentSplitable.sol";
import "../../interface/ICollectionStruct.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";

/// @title Presaleable
/// @author Chain Labs
/// @notice Module that adds functionality of presale with an optional whitelist presale.
/// @dev Uses merkle proofs for whitelist
contract Presaleable is PaymentSplitable, ICollectionStruct {
    //------------------------------------------------------//
    //
    //  Storage
    //
    //------------------------------------------------------//
    /// @notice merkle root of tree generated from whitelisted addresses
    /// @dev list is stored on IPFS and CID is stored in the state
    /// @return merkleRoot merkle root
    bytes32 public merkleRoot;

    /// @notice CID of file containing list of whitelisted addresses
    /// @dev IPFS CID of JSON file with list of addresses
    /// @return whitelistCid IPFS CID
    string public whitelistCid;

    /// @notice tokens to be sold in presale
    /// @dev maximum tokens to be sold in presale, if not sold, will be rolled over to public sale
    /// @return presaleReservedTokens tokens to be sold in presale
    uint256 public presaleReservedTokens;

    /// @notice maximum tokens an account can buy/mint during presale
    /// @dev maximum tokens an account can buy/mint during presale
    /// @return presaleMaxHolding maximum tokens an account can hold during presale
    uint256 public presaleMaxHolding;

    /// @notice price per token during presale
    /// @dev price per token during presale
    /// @return presalePrice price per token during presale
    uint256 public presalePrice;

    /// @notice timestamp when presale starts
    /// @dev presale starts automatically at this time and ends when public sale starts
    /// @return presaleStartTime timestamp when presale starts
    uint256 public presaleStartTime;

    //------------------------------------------------------//
    //
    //  Events
    //
    //------------------------------------------------------//

    event PublicSaleStartTimeUpdated(uint256 newSaleStartTime);

    event PresaleStartTimeUpdated(uint256 newPresaleStartTime);

    /// @notice logs updated whitelist details
    /// @dev emitted when whitelist updated, logs new merkle root and IPFS CID
    /// @param whitelistRoot updated merkle root generated from new list of whitelisted addresses
    /// @param whitelistCid IPFS CID containing updated list of whitelist addresses
    event WhitelistUpdated(bytes32 indexed whitelistRoot, string whitelistCid);

    event PresalePriceUpdated(uint256 presalePrice);

    event PresaleMaxHoldingUpdated(uint256 presaleMaxHolding);

    event MaximumTokensUpdated(uint256 maximumTokens);

    event PresaleReservedTokensUpdated(uint256 presaleReservedTokens);

    //------------------------------------------------------//
    //
    //  Modifiers
    //
    //------------------------------------------------------//

    modifier presaleAllowed() {
        require(isPresaleAllowed(), "PR:001");
        _;
    }

    //------------------------------------------------------//
    //
    //  Setup
    //
    //------------------------------------------------------//

    /// @notice setup presale details including whitelist
    /// @dev internal method and can only be invoked when Collection is being setup
    /// @param _presaleReservedTokens maximum number of tokens to be sold in presale
    /// @param _presalePrice price per token during presale
    /// @param _presaleStartTime timestamp when presale starts
    /// @param _presaleMaxHolding maximum tokens and account can hold during presale
    /// @param _presaleWhitelist struct containing whitelist details
    function setupPresale(
        uint256 _presaleReservedTokens,
        uint256 _presalePrice,
        uint256 _presaleStartTime,
        uint256 _presaleMaxHolding,
        Whitelist memory _presaleWhitelist
    ) internal {
        if (_presaleStartTime != 0) {
            require(_presaleReservedTokens != 0, "PR:002");
            require(_presaleStartTime > block.timestamp, "PR:003");
            require(_presaleMaxHolding != 0, "PR:004");
            presaleReservedTokens = _presaleReservedTokens;
            presalePrice = _presalePrice;
            presaleStartTime = _presaleStartTime;
            presaleMaxHolding = _presaleMaxHolding;
            if (!(_presaleWhitelist.root == bytes32(0))) {
                _setWhitelist(_presaleWhitelist);
            }
        }
    }

    //------------------------------------------------------//
    //
    //  Owner only functions
    //
    //------------------------------------------------------//

    /// @notice set new sale start time for presale and public sale
    /// @dev single method to set timestamp for public sale and presale
    /// @param _newSaleStartTime new timestamp
    /// @param saleType sale type, true - set for public sale, when saleType is false - set for presale
    function setSaleStartTime(uint256 _newSaleStartTime, bool saleType)
        external
        onlyOwner
    {
        if (saleType) {
            require(
                _newSaleStartTime > block.timestamp &&
                    _newSaleStartTime != publicSaleStartTime &&
                    _newSaleStartTime > presaleStartTime,
                "BC:006"
            );
            publicSaleStartTime = _newSaleStartTime;
            emit PublicSaleStartTimeUpdated(_newSaleStartTime);
        } else {
            require(
                _newSaleStartTime > block.timestamp &&
                    _newSaleStartTime != presaleStartTime &&
                    _newSaleStartTime < publicSaleStartTime,
                "PR:008"
            );
            presaleStartTime = _newSaleStartTime;
            emit PresaleStartTimeUpdated(_newSaleStartTime);
        }
    }

    /// @notice update whitelist
    /// @dev update whitelist merkle root and IPFS CID
    /// @param _whitelist struct containing new whitelist details
    function updateWhitelist(Whitelist memory _whitelist)
        external
        onlyOwner
        presaleAllowed
    {
        _setWhitelist(_whitelist);
    }

    /// @notice sets new price for presale
    /// @dev only owner can change presale price
    /// @param _newPresalePrice new presale price
    function setPresalePrice(uint256 _newPresalePrice) external onlyOwner {
        presalePrice = _newPresalePrice;
        emit PresalePriceUpdated(_newPresalePrice);
    }

    /// @notice Change number of tokens that be minted by an account in presale
    /// @dev only owner can update maximum holding limit per account in presale
    /// @param _newPresaleMaxHolding new maximum holding limit in presale
    function setPresaleMaxHolding(uint256 _newPresaleMaxHolding)
        external
        onlyOwner
    {
        presaleMaxHolding = _newPresaleMaxHolding;
        emit PresaleMaxHoldingUpdated(_newPresaleMaxHolding);
    }

    /// @notice Change maximum tokens
    /// @dev only owner can update maximum tokens
    /// @param _newMaximumTokens new maximum tokens
    function setMaximumTokens(uint256 _newMaximumTokens) external onlyOwner {
        require(
            _newMaximumTokens >= tokensCount + startingTokenIndex &&
                _newMaximumTokens >= presaleReservedTokens + startingTokenIndex,
            "BC:015"
        );
        maximumTokens = _newMaximumTokens;
        emit MaximumTokensUpdated(_newMaximumTokens);
    }

    /// @notice change presale reserved tokens
    /// @dev only owner can change presale reserved tokens
    /// @param _newPresaleReservedTokens new presale reserved tokens
    function setPresaleReservedTokens(uint256 _newPresaleReservedTokens)
        external
        onlyOwner
    {
        require(
            _newPresaleReservedTokens + startingTokenIndex <= maximumTokens &&
                _newPresaleReservedTokens >= tokensCount,
            "PR:015"
        );
        presaleReservedTokens = _newPresaleReservedTokens;
        emit PresaleReservedTokensUpdated(_newPresaleReservedTokens);
    }

    //------------------------------------------------------//
    //
    //  Public function
    //
    //------------------------------------------------------//

    /// @notice buy tokens during presale
    /// @dev checks for whitelist and mints tokens to buyer
    /// @param _proofs array of merkle proofs to validate if user is whitelisted
    /// @param _buyer address of buyer
    /// @param _quantity amount of tokens to be bought
    function presaleBuy(
        bytes32[] calldata _proofs,
        address _buyer,
        uint256 _quantity
    ) external payable virtual {
        _presaleBuy(_proofs, _buyer, _quantity);
    }

    /// @notice get whitelist details
    /// @dev get whitelist merkle root and IPFS CID
    /// @return whitelist struct conatining whitelist details
    function getPresaleWhitelists()
        external
        view
        presaleAllowed
        returns (Whitelist memory whitelist)
    {
        return Whitelist(merkleRoot, whitelistCid);
    }

    /// @notice check if an address is whitelist or not
    /// @dev uses merkle proof to validate if account is whitelisted or not
    /// @param _proofs array of merkle proofs
    /// @param _account address which needs to be validated
    /// @return boolean is address whitelisted or not
    function isWhitelisted(bytes32[] calldata _proofs, address _account)
        public
        view
        returns (bool)
    {
        return _isWhitelisted(_proofs, _account);
    }

    /// @notice check if presale module is active or not
    /// @dev checks if presale module is active or not
    /// @return boolean is presale module active or not
    function isPresaleAllowed() public view returns (bool) {
        return presaleReservedTokens > 0;
    }

    /// @notice check if presale is whitelisted or not
    /// @dev if whitelisted, presale buy will check for whitelist else not
    /// @return boolean is presale whitelisted
    function isPresaleWhitelisted() public view returns (bool) {
        return isPresaleAllowed() && merkleRoot != bytes32(0);
    }

    /// @notice check if presale is live or not
    /// @dev only when presale active, tokens can be bought
    /// @return boolean is presale active or not
    function isPresaleActive() public view returns (bool) {
        return
            block.timestamp > presaleStartTime &&
            tokensCount < presaleReservedTokens &&
            block.timestamp < publicSaleStartTime;
    }

    //------------------------------------------------------//
    //
    //  Internal function
    //
    //------------------------------------------------------//

    /// @notice internal method to buy tokens during presale
    /// @dev invoked by presaleBuy and affiliatePresaleBuy
    /// @param _proofs array of merkle proofs to validate if user is whitelisted
    /// @param _buyer address of buyer
    /// @param _quantity amount of tokens to be bought
    function _presaleBuy(
        bytes32[] calldata _proofs,
        address _buyer,
        uint256 _quantity
    ) internal whenNotPaused presaleAllowed {
        require(isPresaleActive(), "PR:009");
        uint256 tokensMintedByUser = tokensMinted[_buyer];
        require(
            isPresaleWhitelisted() ? _isWhitelisted(_proofs, _buyer) : true,
            "PR:011"
        );
        require(tokensCount + _quantity <= presaleReservedTokens, "PR:013");
        require(msg.value == (presalePrice * _quantity), "PR:010");
        require(_quantity <= maxPurchase, "PR:014");
        require(tokensMintedByUser + _quantity <= presaleMaxHolding, "PR:012");
        tokensMinted[_buyer] = tokensMintedByUser + _quantity;
        _manufacture(_buyer, _quantity);
    }

    /// @notice internal method to check if account if whitelisted or not
    /// @dev internally invoked by presale buy and isWhitelisted
    /// @param _proofs array of merkle proofs to validate if user is whitelisted
    /// @param _account address of buyer
    /// @return boolean is address whitelisted or not
    function _isWhitelisted(bytes32[] calldata _proofs, address _account)
        private
        view
        returns (bool)
    {
        bytes32 leaf = keccak256(abi.encodePacked(_account));
        return MerkleProofUpgradeable.verify(_proofs, merkleRoot, leaf);
    }

    /// @notice internal method to update whitelist details
    /// @dev invoked by updateWhitelist and setup
    /// @param _whitelist struct containing whitelist details
    function _setWhitelist(Whitelist memory _whitelist) private {
        merkleRoot = _whitelist.root;
        whitelistCid = _whitelist.cid;
        emit WhitelistUpdated(_whitelist.root, _whitelist.cid);
    }
}

// SPDX-License-Identifier: MIT
// Copyright (C) 2022 Simplr
pragma solidity 0.8.11;

import "./Revealable.sol";

/// @title Reserveable
/// @author Chain Labs
/// @notice Module that adds functionality of reserving tokens from sale. Reserved tokens cannot be bought.
/// @dev Reserves tokens from token ID 1, mints them on demand
contract Reserveable is Revealable {
    //------------------------------------------------------//
    //
    //  Storage
    //
    //------------------------------------------------------//

    /// @notice total reserved tokends
    /// @dev total reserved tokens, it can be updated by owner until first buy (presale or main sale)
    /// @return reservedTokens the return variables of a contract’s function state variable
    uint256 public reservedTokens;

    /// @notice next token ID that will be minted from reserved tokens
    /// @dev next token ID counter for minting from reserved tokens
    /// @return reserveTokenCounter the return variables of a contract’s function state variable
    uint256 public reserveTokenCounter;

    //------------------------------------------------------//
    //
    //  Events
    //
    //------------------------------------------------------//

    event ReservedTokensUpdated(uint256 reservedTokens);

    event ReservedTokenTransferred(address indexed receiver, uint256 tokenId);

    //------------------------------------------------------//
    //
    //  Owner only functions
    //
    //------------------------------------------------------//

    /// @notice set reserved tokens
    /// @dev only owner can set reserved tokens state
    /// @param _reserveTokens number of tokens to be reserved
    function reserveTokens(uint256 _reserveTokens) external onlyOwner {
        _setReserveTokens(_reserveTokens);
    }

    /// @notice set reserved tokens
    /// @dev internal method to set reserved tokens state
    /// @param _reserveTokens number of tokens to be reserved
    function _setReserveTokens(uint256 _reserveTokens) internal {
        require(tokensCount == 0, "RS:001");
        require(
            _reserveTokens + presaleReservedTokens <= maximumTokens,
            "RS:002"
        );
        reservedTokens = _reserveTokens;
        startingTokenIndex = _reserveTokens;
        emit ReservedTokensUpdated(reservedTokens);
    }

    /// @notice transfer reserve tokens to list of receivers
    /// @dev mints tokens from reserved tokens to the receivers
    /// @param _receivers array of addresses that will receive token in sequential order
    function transferReservedTokens(address[] memory _receivers)
        external
        onlyOwner
    {
        uint256 currentTokenId = reserveTokenCounter;
        require(currentTokenId + _receivers.length <= reservedTokens, "RS:003");
        reserveTokenCounter += _receivers.length;
        currentTokenId++;
        for (uint256 i; i < _receivers.length; i++) {
            _safeMint(_receivers[i], currentTokenId + i);
            emit ReservedTokenTransferred(_receivers[i], currentTokenId + i);
        }
    }
}

// SPDX-License-Identifier: MIT
// Copyright (C) 2022 Simplr
pragma solidity 0.8.11;

import "./Presaleable.sol";

/// @title Revealable
/// @author Chain Labs
/// @notice Module that adds functionality of revealing tokens.
/// @dev Handles revealing and structuring project URI
contract Revealable is Presaleable {
    using StringsUpgradeable for uint256;
    //------------------------------------------------------//
    //
    //  Storage
    //
    //------------------------------------------------------//
    /// @notice checks if collection is revealable or not
    /// @dev state that shows if Revealable module is active or not
    /// @return isRevealable checks if collection is revealable or not
    bool public isRevealable;

    /// @notice checks if collection is revealed or not
    /// @dev state that shows if collection is revealed
    /// @return isRevealed checks if collection is revealed or not
    bool public isRevealed;

    /// @notice provenance of final IPFS CID
    /// @dev keccak256 hash of final IPFS CID
    /// @return projectURIProvenance hash of revealed IPFS CID
    bytes32 public projectURIProvenance;

    //------------------------------------------------------//
    //
    //  Events
    //
    //------------------------------------------------------//

    event ProvenanceUpdated(bytes32 indexed provenance);

    event CollectionRevealed(string projectUri);

    event ProjectURIUpdated(string projectUri);

    //------------------------------------------------------//
    //
    //  Owner only functions
    //
    //------------------------------------------------------//

    /// @notice set provenance of the collection
    /// @dev keccak hash of IPFS CID is done off chain and passed in as parameter
    /// @param _projectURIProvenance keccak256 hash of final IPFS CID
    function setProvenance(bytes32 _projectURIProvenance) internal {
        if (_projectURIProvenance != keccak256(abi.encode(projectURI))) {
            isRevealable = true;
            projectURIProvenance = _projectURIProvenance;
            emit ProvenanceUpdated(_projectURIProvenance);
        } else {
            isRevealed = true;
        }
    }

    /// @notice Reveal and update Project URI
    /// @dev Reveal and update Project URI
    /// @param _projectURI new project URI
    function setProjectURIAndReveal(string memory _projectURI)
        external
        onlyOwner
    {
        require(isRevealable, "Revealable: non revealable");
        isRevealed = true;
        projectURI = _projectURI;
        emit CollectionRevealed(_projectURI);
    }

    /// @notice set new project URI
    /// @dev set new project URI
    /// @param _projectURI new project URI
    function setProjectURI(string memory _projectURI) external onlyOwner {
        projectURI = _projectURI;
        emit ProjectURIUpdated(_projectURI);
    }

    //------------------------------------------------------//
    //
    //  Public function
    //
    //------------------------------------------------------//

    /// @inheritdoc	ERC721Upgradeable
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "R:004");
        string memory baseURI = _baseURI();
        return
            isRevealable
                ? isRevealed
                    ? string(
                        abi.encodePacked(baseURI, tokenId.toString(), ".json")
                    )
                    : baseURI
                : string(
                    abi.encodePacked(baseURI, tokenId.toString(), ".json")
                );
    }
}

// SPDX-License-Identifier: MIT
// Copyright (C) 2022 Simplr
pragma solidity ^0.8.11;

import "./Reservable.sol";
import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";

/// @title Royalties
/// @author Chain Labs
/// @notice Module that adds functionality of royalties as required by EIP-2981.
/// @dev Core functionality inherited from OpenZeppelin's ERC2981
contract Royalties is Reserveable, ERC2981Upgradeable {
    /// @notice event that logs updated royalties info
    /// @dev emits updated royalty receiver and royalty share fraction
    /// @param receiver address that should receive royalty
    /// @param royaltyFraction fraction that should be sent to receiver
    event DefaultRoyaltyUpdated(address receiver, uint96 royaltyFraction);

    //------------------------------------------------------//
    //
    //  Setup
    //
    //------------------------------------------------------//

    /// @notice set royalties, only one address can receive the royalties, considers 10000 = 100%
    /// @dev only owner can set royalties
    /// @param _royalties a struct with royalties receiver and royalties share
    function setRoyalties(RoyaltyInfo memory _royalties) public onlyOwner {
        _setRoyalties(_royalties);
    }

    //------------------------------------------------------//
    //
    //  Public function
    //
    //------------------------------------------------------//

    /// @inheritdoc	ERC721Upgradeable
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Upgradeable, ERC2981Upgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    //------------------------------------------------------//
    //
    //  Internal function
    //
    //------------------------------------------------------//

    /// @notice set default royalties, considers 10000 = 100%
    /// @dev internl method to set royalties
    /// @param _royalties a struct with royalties receiver and royalties share
    function _setRoyalties(RoyaltyInfo memory _royalties) internal {
        _setDefaultRoyalty(_royalties.receiver, _royalties.royaltyFraction);
        emit DefaultRoyaltyUpdated(
            _royalties.receiver,
            _royalties.royaltyFraction
        );
    }
}

// SPDX-License-Identifier: MIT
// Copyright (C) 2022 Simplr
pragma solidity 0.8.11;

/**
 * @title Collection Struct Interface
 * @dev   interface to for all the struct required for setup parameters.
 * @author Chain Labs Team
 */
/// @title Collection Struct Interface
/// @author Chain Labs
/// @notice interface for all the struct required for setup parameters.
interface ICollectionStruct {
    struct BaseCollectionStruct {
        string name;
        string symbol;
        address admin;
        uint256 maximumTokens;
        uint16 maxPurchase;
        uint16 maxHolding;
        uint256 price;
        uint256 publicSaleStartTime;
        string projectURI;
    }

    struct Whitelist {
        bytes32 root;
        string cid;
    }

    struct PresaleableStruct {
        uint256 presaleReservedTokens;
        uint256 presalePrice;
        uint256 presaleStartTime;
        uint256 presaleMaxHolding;
        Whitelist presaleWhitelist;
    }

    struct PaymentSplitterStruct {
        address simplr;
        uint256 simplrShares;
        address[] payees;
        uint256[] shares;
    }
}