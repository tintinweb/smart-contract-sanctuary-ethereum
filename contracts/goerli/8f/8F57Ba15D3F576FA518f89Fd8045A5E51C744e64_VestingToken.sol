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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
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
    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
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

// SPDX-License-Identifier: None
// Unvest Contracts (last updated v2.0.0) (interfaces/IFeeManager.sol)
pragma solidity 0.8.17;

/**
 * @title IFeeManager
 * @dev Interface that describes the struct and accessor function for the data related to the collection of fees.
 */
interface IFeeManager {
    /**
     * @dev `feeCollector` is the address that will collect the fees of every transaction of `VestingToken`s
     * @dev `feePercentage` is the percentage of every transaction that will be collected.
     */
    struct FeeData {
        address feeCollector;
        uint64 feePercentage;
    }

    /**
     * @notice Exposes the `FeeData` for `VestingToken`s to consume.
     */
    function feeData() external view returns (FeeData memory);
}

// SPDX-License-Identifier: None
// Unvest Contracts (last updated v2.0.0) (interfaces/IVestingToken.sol)
pragma solidity 0.8.17;

/**
 * @title IVestingToken
 * @dev Interface that describes the Milestone struct and initialize function so the `VestingTokenFactory` knows how to
 * initialize the `VestingToken`.
 */
interface IVestingToken {
    /**
     * @dev Ramps describes how the periods between release tokens.
     *     - Cliff releases nothing until the end of the period.
     *     - Linear releases tokens every second according to a linear slope.
     *
     * (0) Cliff             (1) Linear
     *  |                     |
     *  |        _____        |        _____
     *  |       |             |       /
     *  |       |             |      /
     *  |_______|_____        |_____/_______
     *      T0   T1               T0   T1
     */
    enum Ramp {
        Cliff,
        Linear
    }

    /**
     * @dev `timestamp` represents a moment in time when this Milestone is considered expired.
     * @dev `ramp` defines the behaviour of the release of tokens in period between the previous Milestone and the
     * current one.
     * @dev `percentage` is the percentage of tokens that should be released once this Milestone has expired.
     */
    struct Milestone {
        uint64 timestamp;
        Ramp ramp;
        uint64 percentage;
    }

    /**
     * @notice Initializes the contract by setting up the ERC20 variables, the `underlyingToken`, and the
     * `milestonesArray` information.
     *
     * @param name                   The token collection name.
     * @param symbol                 The token collection symbol.
     * @param underlyingTokenAddress The ERC20 token that will be held by this contract.
     * @param milestonesArray        Array of all Milestones for this Contract's lifetime.
     */
    function initialize(
        string memory name,
        string memory symbol,
        address underlyingTokenAddress,
        Milestone[] calldata milestonesArray
    ) external;
}

// SPDX-License-Identifier: None
// Unvest Contracts (last updated v2.0.0) (VestingToken.sol)
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "./interfaces/IFeeManager.sol";
import "./interfaces/IVestingToken.sol";

error AddressIsNotAContract();
error MaxAllowedMilestonesHit();
error ClaimableAmountOfImportIsGreaterThanExpected();
error EqualPercentagesOnlyAllowedBeforeLinear();
error InputArraysMustHaveSameLength();
error LastPercentageMustBe100();
error MilestonePercentagesNotSorted();
error MilestoneTimestampsNotSorted();
error MoreThanTwoEqualPercentages();
error OnlyLastPercentageCanBe100();
error UnlockedIsGreaterThanExpected();
error UnsuccessfulFetchOfTokenBalance();

/**
 * @title VestingToken
 * @notice VestingToken locks ERC20 and contains the logic for tokens to be partially unlocked based on
 * milestones.
 */
contract VestingToken is ERC20Upgradeable, ReentrancyGuardUpgradeable, IVestingToken {
    using SafeERC20Upgradeable for ERC20Upgradeable;
    using AddressUpgradeable for address;

    /**
     * @dev `claimedAmountAfterTransfer` is used to calculate the `_claimableAmount` of an account. It's value is
     * updated on every `transfer`, `transferFrom`, and `claim` calls.
     * @dev While `claimedAmountAfterTransfer` contains a fraction of the `claimedAmountAfterTransfer`s of every token
     * transfer the owner of account receives, `claimedBalance` works as a counter for tokens claimed by this account.
     */
    struct Metadata {
        uint256 claimedAmountAfterTransfer;
        uint256 claimedBalance;
    }

    /**
     * @param claimer Address that will receive the `amount` of `underlyingToken`.
     * @param amount  Amount of tokens that will be sent to the `claimer`.
     */
    event Claim(address indexed claimer, uint256 amount);

    /**
     * @param milestoneIndex Index of the Milestone reached.
     * @param percentage     Claimable percentage of tokens.
     */
    event MilestoneReached(uint256 indexed milestoneIndex, uint64 percentage);

    /**
     * @dev Percentages and fees are calculated using 18 decimals where 1 ether is 100%.
     */
    uint256 internal constant ONE = 1 ether;

    /**
     * @notice The ERC20 token that this contract will be vesting.
     */
    ERC20Upgradeable public underlyingToken;

    /**
     * @notice The manager that deployed this contract which controls the values for `fee` and `feeCollector`.
     */
    IFeeManager public manager;

    /**
     * @dev The `decimals` value that is fetched from `underlyingToken`.
     */
    uint8 internal _decimals;

    /**
     * @dev The initial supply used for calculating the `claimableSupply`, `claimedSupply`, and `lockedSupply`.
     */
    uint256 internal _startingSupply;

    /**
     * @dev The imported claimed supply is necessary for an accurate `claimableSupply` but leads to an improper
     * offset in `claimedSupply`, so we keep track of this to account for it.
     */
    uint256 internal _importedClaimedSupply;

    /**
     * @notice An array of Milestones describing the times and behaviour of the rules to release the vested tokens.
     */
    Milestone[] internal _milestones;

    /**
     * @notice Keep track of the last reached Milestone to minimize the iterations over the milestones and save gas.
     */
    uint256 internal _lastReachedMilestone;

    /**
     * @dev Maps a an address to the metadata needed to calculate `claimableBalance` and `lockedBalanceOf`.
     */
    mapping(address => Metadata) internal _metadata;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Initializes the contract by setting up the ERC20 variables, the `underlyingToken`, and the
     * `milestonesArray` information.
     *
     * @dev The Ramp of the first Milestone in the `milestonesArray` will always act as a Cliff since it doesn't have
     * a previous milestone.
     *
     * Requirements:
     *
     * - `underlyingTokenAddress` cannot be the zero address.
     * - `timestamps` must be given in ascending order.
     * - `percentages` must be given in ascending order and the last one must always be 1 eth, where 1 eth equals to
     * 100%.
     * - 2 `percentages` may have the same value as long as they are followed by a `Ramp.Linear` Milestone.
     *
     * @param name                   This ERC20 token name.
     * @param symbol                 This ERC20 token symbol.
     * @param underlyingTokenAddress The ERC20 token that will be held by this contract.
     * @param milestonesArray        Array of all `Milestone`s for this contract's lifetime.
     */
    function initialize(
        string memory name,
        string memory symbol,
        address underlyingTokenAddress,
        Milestone[] calldata milestonesArray
    ) external override initializer {
        __ERC20_init(name, symbol);
        __ReentrancyGuard_init();

        manager = IFeeManager(_msgSender());

        if (!underlyingTokenAddress.isContract()) revert AddressIsNotAContract();
        if (milestonesArray.length > 826) revert MaxAllowedMilestonesHit();

        Milestone calldata current = milestonesArray[0];
        bool twoInARow;

        for (uint256 i = 0; i < milestonesArray.length; i++) {
            if (i > 0) {
                Milestone calldata previous = current;
                current = milestonesArray[i];

                _sortRule(current, previous);
                _twoInARowRule(current, previous, twoInARow);

                twoInARow = previous.percentage == current.percentage;
            }

            _hundredPercentRule(current, i == milestonesArray.length - 1);
            _milestones.push(current);
        }

        underlyingToken = ERC20Upgradeable(underlyingTokenAddress);
        _decimals = _tryFetchDecimals();
    }

    /**
     * @dev Returns the number of decimals used to get its user representation. For example, if `decimals` equals `2`,
     * a balance of `505` tokens should be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between Ether and Wei. Since we can't predict
     * the decimals the `underlyingToken` will have, we need to provide our own implementation which is setup at
     * initialization.
     *
     * NOTE: This information is only used for _display_ purposes: it in no way affects any of the arithmetic of the
     * contract.
     */
    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    /**
     * @notice Vests an `amount` of `underlyingToken` and mints LVTs for a `recipient`.
     *
     * Requirements:
     *
     * - `msg.sender` must have approved this contract an amount of `underlyingToken` greater or equal than `amount`.
     *
     * @param recipient The address that will receive the newly minted LVT.
     * @param amount    The amount of `underlyingToken` to be vested.
     */
    function addRecipient(address recipient, uint256 amount) external nonReentrant {
        uint256 currentBalance = _getBalanceOfThis();

        underlyingToken.safeTransferFrom(_msgSender(), address(this), amount);
        uint256 transferredAmount = _getBalanceOfThis() - currentBalance;

        _startingSupply += transferredAmount;
        _mint(recipient, transferredAmount);
    }

    /**
     * @notice Vests multiple `amounts` of `underlyingToken` and mints LVTs for multiple `recipients`.
     *
     * Requirements:
     *
     * - `recipients` and `amounts` must have the same length.
     * - `msg.sender` must have approved this contract an amount of `underlyingToken` greater or equal than the sum of
     * all of the `amounts`.
     *
     * @param recipients Array of addresses that will receive the newly minted LVTs.
     * @param amounts    Array of amounts of `underlyingToken` to be vested.
     */
    function addRecipients(address[] calldata recipients, uint256[] calldata amounts) external nonReentrant {
        if (recipients.length != amounts.length) revert InputArraysMustHaveSameLength();
        uint256 currentBalance = _getBalanceOfThis();

        uint256 totalAmount;
        for (uint256 i = 0; i < recipients.length; i++) {
            totalAmount += amounts[i];
        }
        underlyingToken.safeTransferFrom(_msgSender(), address(this), totalAmount);
        uint256 transferredAmount = _getBalanceOfThis() - currentBalance;

        _startingSupply += transferredAmount;
        for (uint256 i = 0; i < recipients.length; i++) {
            address recipient = recipients[i];
            uint256 amount = transferredAmount == totalAmount
                ? amounts[i]
                : (amounts[i] * transferredAmount) / totalAmount;
            _mint(recipient, amount);
        }
    }

    /**
     * @notice Behaves as `addRecipient` but provides the ability to set the initial state of the recipient's metadata.
     * @notice This functionality is included in order to allow users to restart an allocation on a different chain and
     * keeping the inner state as close as possible to the original.
     *
     * @dev The `Metadata.claimedAmountAfterTransfer` for the recipient is inferred from the parameters.
     * @dev The `Metadata.claimedBalance` is lost in the transfer, the closest value will be
     * `claimedAmountAfterTransfer`.
     * @dev In the rare case where the contract and it's users are migrated after the last milestone has been reached,
     * the `claimedAmountAfterTransfer` can't be inferred and the `claimedSupply` value for the whole contract is lost
     * in the transfer.
     * @dev The decision to do this is to minimize the altering of metadata to the amount that is being transferred and
     * protect an attack that would render the contract unusable.
     *
     * Requirements:
     *
     * - `unlocked` must be less than or equal to this contracts `unlockedPercentage`.
     * - `claimableAmountOfImport` must be less than or equal than the amount that would be claimable given the values
     *  of `amount` and `percentage`.
     * - `msg.sender` must have approved this contract an amount of `underlyingToken` greater or equal than `amount`.
     *
     * @param recipient               The address that will receive the newly minted LVT.
     * @param amount                  The amount of `underlyingToken` to be vested.
     * @param claimableAmountOfImport The amount of `underlyingToken` from this transaction that should be considered
     *                                claimable.
     * @param unlocked                The unlocked percentage value at the time of the export of this transaction.
     */
    function importRecipient(
        address recipient,
        uint256 amount,
        uint256 claimableAmountOfImport,
        uint256 unlocked
    ) external nonReentrant {
        if (unlocked > unlockedPercentage()) revert UnlockedIsGreaterThanExpected();
        uint256 currentBalance = _getBalanceOfThis();

        underlyingToken.safeTransferFrom(_msgSender(), address(this), amount);
        uint256 transferredAmount = _getBalanceOfThis() - currentBalance;

        uint256 claimedAmount = _claimedAmount(transferredAmount, claimableAmountOfImport, unlocked);

        _metadata[recipient].claimedAmountAfterTransfer += claimedAmount;

        _importedClaimedSupply += claimedAmount;
        _startingSupply += transferredAmount + claimedAmount;
        _mint(recipient, transferredAmount);
    }

    /**
     * @notice Behaves as `addRecipients` but provides the ability to set the initial state of the recipient's
     * metadata.
     * @notice This functionality is included in order to allow users to restart an allocation on a different chain and
     * keeping the inner state as close as possible to the original.
     *
     * @dev The `Metadata.claimedAmountAfterTransfer` for each recipient is inferred from the parameters.
     * @dev The `Metadata.claimedBalance` is lost in the transfer, the closest value will be
     * `claimedAmountAfterTransfer`.
     * @dev In the rare case where the contract and it's users are migrated after the last milestone has been reached,
     * the `claimedAmountAfterTransfer` can't be inferred and the `claimedSupply` value for the whole contract is lost
     * in the transfer.
     * @dev The decision to do this to minimize the altering of metadata to the amount that is being transferred and
     * protect an attack that would render the contract unusable.
     *
     * @dev The Metadata for the recipient is inferred from the parameters. The decision to do this to minimize the
     * altering of metadata to the amount that is being transferred.
     *
     * Requirements:
     *
     * - `recipients`, `amounts`, and `claimableAmountsOfImport` must have the same length.
     * - `unlocked` must be less than or equal to this contracts `unlockedPercentage`.
     * - each value in `claimableAmountsOfImport` must be less than or equal than the amount that would be claimable
     *   given the values in `amounts` and `percentages`.
     * - `msg.sender` must have approved this contract an amount of `underlyingToken` greater or equal than the sum of
     *   all of the `amounts`.
     *
     * @param recipients               Array of addresses that will receive the newly minted LVTs.
     * @param amounts                  Array of amounts of `underlyingToken` to be vested.
     * @param claimableAmountsOfImport Array of amounts of `underlyingToken` from this transaction that should be
     *                                 considered claimable.
     * @param unlocked                 The unlocked percentage value at the time of the export of this transaction.
     */
    function importRecipients(
        address[] calldata recipients,
        uint256[] calldata amounts,
        uint256[] calldata claimableAmountsOfImport,
        uint256 unlocked
    ) external nonReentrant {
        if (unlocked > unlockedPercentage()) revert UnlockedIsGreaterThanExpected();
        if (recipients.length != amounts.length || claimableAmountsOfImport.length != amounts.length)
            revert InputArraysMustHaveSameLength();
        uint256 currentBalance = _getBalanceOfThis();
        uint256 totalAmount;
        for (uint256 i = 0; i < recipients.length; i++) {
            totalAmount += amounts[i];
        }

        underlyingToken.safeTransferFrom(_msgSender(), address(this), totalAmount);
        uint256 transferredAmount = _getBalanceOfThis() - currentBalance;

        uint256 totalClaimed;

        for (uint256 i = 0; i < recipients.length; i++) {
            address recipient = recipients[i];
            uint256 amount = transferredAmount == totalAmount
                ? amounts[i]
                : (amounts[i] * transferredAmount) / totalAmount;

            uint256 claimableAmountOfImport = claimableAmountsOfImport[i];

            uint256 claimedAmount = _claimedAmount(amount, claimableAmountOfImport, unlocked);
            _mint(recipient, amount);

            _metadata[recipient].claimedAmountAfterTransfer += claimedAmount;

            totalClaimed += claimedAmount;
        }

        _importedClaimedSupply += totalClaimed;
        _startingSupply += transferredAmount + totalClaimed;
    }

    /**
     * @param recipient The address that will be exported.
     *
     * @return The arguments to use in a call `importRecipient` on a different contract to migrate the `recipient`'s
     * metadata.
     */
    function exportRecipient(address recipient) external view returns (address, uint256, uint256, uint256) {
        return (recipient, balanceOf(recipient), claimableBalanceOf(recipient), unlockedPercentage());
    }

    /**
     * @param recipients Array of addresses that will be exported.
     *
     * @return The arguments to use in a call `importRecipients` on a different contract to migrate the `recipients`'
     * metadata.
     */
    function exportRecipients(
        address[] calldata recipients
    ) external view returns (address[] calldata, uint256[] memory, uint256[] memory, uint256) {
        uint256[] memory balances = new uint256[](recipients.length);
        uint256[] memory claimableBalances = new uint256[](recipients.length);

        for (uint256 i = 0; i < recipients.length; i++) {
            address recipient = recipients[i];
            balances[i] = balanceOf(recipient);
            claimableBalances[i] = claimableBalanceOf(recipient);
        }

        return (recipients, balances, claimableBalances, unlockedPercentage());
    }

    /**
     * @notice This function will check and update the `_lastReachedMilestone` so the gas usage will be minimal in
     * calls to `unlockedPercentage`.
     *
     * @dev This function is called by claim with a value of `startIndex` equal to the previous value of
     * `_lastReachedMilestone`, but can be called externally with a more accurate value in case multiple Milestones
     * have been reached without anyone claiming.
     *
     * @param startIndex Index of the Milestone we want the loop to start checking.
     */
    function updateLastReachedMilestone(uint256 startIndex) public {
        Milestone storage previous = _milestones[startIndex];
        if (previous.timestamp > block.timestamp) return;

        for (uint256 i = startIndex; i < _milestones.length; i++) {
            Milestone storage current = _milestones[i];
            if (current.timestamp <= block.timestamp) {
                previous = current;
                continue;
            }

            if (i > _lastReachedMilestone + 1) {
                _lastReachedMilestone = i - 1;
                emit MilestoneReached(_lastReachedMilestone, previous.percentage);
            }
            return;
        }

        if (_lastReachedMilestone < _milestones.length - 1) {
            _lastReachedMilestone = _milestones.length - 1;
            emit MilestoneReached(_lastReachedMilestone, uint64(ONE));
        }
    }

    /**
     * @return The percentage of `underlyingToken` that users could claim.
     */
    function unlockedPercentage() public view returns (uint256) {
        Milestone storage previous = _milestones[_lastReachedMilestone];
        // If the first Milestone is still pending, the contract hasn't started unlocking tokens
        if (previous.timestamp > block.timestamp) return 0;

        uint256 percentage = previous.percentage;

        for (uint256 i = _lastReachedMilestone + 1; i < _milestones.length; i++) {
            Milestone storage current = _milestones[i];
            // If `current` Milestone has expired, `percentage` is at least `current` Milestone's percentage
            if (current.timestamp <= block.timestamp) {
                percentage = current.percentage;
                previous = current;
                continue;
            }
            // If `current` Milestone has a `Linear` ramp, `percentage` is between `previous` and `current`
            // Milestone's percentage
            if (current.ramp == Ramp.Linear) {
                percentage +=
                    ((block.timestamp - previous.timestamp) * (current.percentage - previous.percentage)) /
                    (current.timestamp - previous.timestamp);
            }
            // `percentage` won't change after this
            break;
        }
        return percentage;
    }

    /**
     * @return The amount of `underlyingToken` that were held in this contract and have been claimed.
     */
    function claimedSupply() public view returns (uint256) {
        return _startingSupply - totalSupply() - _importedClaimedSupply;
    }

    /**
     * @return The amount of `underlyingToken` being held in this contract and that can be claimed.
     */
    function claimableSupply() public view returns (uint256) {
        return _claimableAmount(_startingSupply, _startingSupply - totalSupply());
    }

    /**
     * @return The amount of `underlyingToken` being held in this contract that can't be claimed yet.
     */
    function lockedSupply() public view returns (uint256) {
        return totalSupply() - claimableSupply();
    }

    /**
     * @param account The address whose tokens are being queried.
     *
     * @return The amount of `underlyingToken` that were held in this contract and this `account` already claimed.
     */
    function claimedBalanceOf(address account) public view returns (uint256) {
        return _metadata[account].claimedBalance;
    }

    /**
     * @param account The address whose tokens are being queried.
     *
     * @return The amount of `underlyingToken` that this `account` owns and can claim.
     */

    function claimableBalanceOf(address account) public view returns (uint256) {
        uint256 claimedAmountAfterTransfer = _metadata[account].claimedAmountAfterTransfer;
        return _claimableAmount(claimedAmountAfterTransfer + balanceOf(account), claimedAmountAfterTransfer);
    }

    /**
     * @param account The address whose tokens are being queried.
     *
     * @return The amount of `underlyingToken` that this `account` owns but can't claim yet.
     */
    function lockedBalanceOf(address account) public view returns (uint256) {
        return balanceOf(account) - claimableBalanceOf(account);
    }

    /**
     * @notice This function transfers the claimable amount of `underlyingToken` and transfers it to `msg.sender`.
     *
     * @custom:emits `Claim(account, claimableAmount)`
     */
    function claim() public {
        address account = _msgSender();
        Metadata storage accountMetadata = _metadata[account];

        updateLastReachedMilestone(_lastReachedMilestone);

        uint256 claimableAmount = _claimableAmount(
            accountMetadata.claimedAmountAfterTransfer + balanceOf(account),
            accountMetadata.claimedAmountAfterTransfer
        );

        if (claimableAmount > 0) {
            _burn(account, claimableAmount);

            accountMetadata.claimedAmountAfterTransfer += claimableAmount;
            accountMetadata.claimedBalance += claimableAmount;

            emit Claim(account, claimableAmount);
            underlyingToken.safeTransfer(account, claimableAmount);
        }
    }

    /**
     * @notice Calculates and transfers the fee before executing a normal ERC20 transfer.
     *
     * @dev This method also updates the metadata in `msg.sender`, `to`, and `feeCollector`.
     *
     * @param to     Address of recipient.
     * @param amount Amount of tokens.
     */
    function transfer(address to, uint256 amount) public override returns (bool) {
        _updateMetadataAndTransfer(_msgSender(), to, amount, true);
        return true;
    }

    /**
     * @notice Calculates and transfers the fee before executing a normal ERC20 transferFrom.
     *
     * @dev This method also updates the metadata in `from`, `to`, and `feeCollector`.
     *
     * @param from   Address of sender.
     * @param to     Address of recipient.
     * @param amount Amount of tokens.
     */
    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        _updateMetadataAndTransfer(from, to, amount, false);
        return true;
    }

    /**
     * @notice Exposes the whole array of `_milestones`.
     */
    function milestones() external view returns (Milestone[] memory) {
        return _milestones;
    }

    /**
     * @dev This function updates the metadata on the `sender`, the `receiver`, and the `feeCollector` if there's any
     * fee involved. The changes on the metadata are on the value `claimedAmountAfterTransfer` which is used to
     * calculate `_claimableAmount`.
     *
     * @dev The math behind these changes can be explained by the following logic:
     *
     *     1) claimableAmount = (unlockedPercentage * startingAmount) / ONE - claimedAmount
     *
     * When there's a transfer of an amount, we transfer both locked and unlocked tokens so the
     * `claimableAmountAfterTransfer` will look like:
     *
     *     2) claimableAmountAfterTransfer = claimableAmount ± claimableAmountOfTransfer
     *
     * Notice the ± symbol is because the `sender`'s `claimableAmount` is reduced while the `receiver`'s
     * `claimableAmount` is increased.
     *
     *     3) claimableAmountOfTransfer = claimableAmountOfSender * amountOfTransfer / balanceOfSender
     *
     * We can expand 3) into:
     *
     *     4) claimableAmountOfTransfer =
     *            (unlockedPercentage * ((startingAmountOfSender * amountOfTransfer) / balanceOfSender)) / ONE) -
     *            ((claimedAmountOfSender * amountOfTransfer) / balanceOfSender)
     *
     * Notice how the structure of the equation is the same as 1) and 2 new variables can be created to calculate
     * `claimableAmountOfTransfer`
     *
     *     a) startingAmountOfTransfer = (startingAmountOfSender * amountOfTransfer) / balanceOfSender
     *     b) claimedAmountOfTransfer = (claimedAmountOfSender * amountOfTransfer) / balanceOfSender
     *
     * Replacing `claimableAmountOfTransfer` in equation 2) and expanding it, we get:
     *
     *     5) claimableAmountAfterTransfer =
     *            ((unlockedPercentage * startingAmount) / ONE - claimedAmount) ±
     *            ((unlockedPercentage * startingAmountOfTransfer) / ONE - claimedAmountOfTransfer)
     *
     * We can group similar variables like this:
     *
     *     6) claimableAmountAfterTransfer =
     *            (unlockedPercentage * (startingAmount - startingAmountOfTransfer)) / ONE -
     *            (claimedAmount - claimedAmountOfTransfer)
     *
     * This shows that the new values to calculate `claimableAmountAfterTransfer` if we want to continue using the
     * equation 1) are:
     *
     *     c) startingAmountAfterTransfer =
     *            startingAmount ±
     *            (startingAmountOfSender * amountOfTransfer) / balanceOfSender
     *     d) claimedAmountAfterTransfer =
     *            claimedAmount ±
     *            (claimedAmountOfSender * amountOfTransfer) / balanceOfSender
     *
     * Since these values depend linearly on the value of `amountOfTransfer`, and the fee is a fraction of the amount,
     * we can just factor in the `feePercentage` to get the values for the transfer to the `feeCollector`.
     *
     *     e) startingAmountOfFee = (startingAmountOfTransfer * feePercentage) / ONE;
     *     f) claimedAmountOfFee = (claimedAmountOfTransfer * feePercentage) / ONE;
     *
     * If we look at equation 1) and set `unlockedPercentage` to ONE, then `claimableAmount` must equal to the
     * `balance`. Therefore the relation between `startingAmount`, `claimedAmount`, and `balance` should be:
     *
     *     g) startingAmount = claimedAmount + balance
     *
     * Since we want to minimize independent rounding in all of the `startingAmount`s, and `claimedAmount`s we will
     * calculate the `claimedAmount` using multiplication and division as shown in b) and f), and the `startingAmount`
     * can be derived using a simple subtraction.
     * With this we ensure that if there's a rounding down in the divisions, we won't be leaving any token locked.
     *
     * @param from       Address of sender.
     * @param to         Address of recipient.
     * @param amount     Amount of tokens.
     * @param isTransfer If a fee is charged, this will let the function know whether to use `transfer` or
     *                   `transferFrom` to collect the fee.
     */
    function _updateMetadataAndTransfer(address from, address to, uint256 amount, bool isTransfer) internal {
        Metadata storage accountMetadata = _metadata[from];

        // Calculate `claimedAmountOfTransfer` as described on equation b)
        // uint256 can handle 78 digits well. Normally token transactions have 18 decimals that gives us 43 digits of
        // wiggle room in the multiplication `(accountMetadata.claimedAmountAfterTransfer * amount)` without
        // overflowing.
        uint256 claimedAmountOfTransfer = (accountMetadata.claimedAmountAfterTransfer * amount) / balanceOf(from);

        // Modify `claimedAmountAfterTransfer` of the sender following equation d)
        // Notice in this case we are reducing the value
        accountMetadata.claimedAmountAfterTransfer -= claimedAmountOfTransfer;

        if (to != from) {
            IFeeManager.FeeData memory feeData = manager.feeData();
            uint256 feePercentage = feeData.feePercentage;

            if (feePercentage != 0) {
                address feeCollector = feeData.feeCollector;

                // The values of `fee` and `claimedAmountOfFee` are calculated using the `feePercentage` shown in
                // equation f)
                uint256 fee = (amount * feePercentage) / ONE;
                uint256 claimedAmountOfFee = (claimedAmountOfTransfer * feePercentage) / ONE;

                // The values for the receiver need to be updated accordingly
                amount -= fee;
                claimedAmountOfTransfer -= claimedAmountOfFee;

                // Modify `claimedAmountAfterTransfer` of the feeCollector following equation d)
                // Notice in this case we are increasing the value
                _metadata[feeCollector].claimedAmountAfterTransfer += claimedAmountOfFee;

                if (isTransfer) {
                    super.transfer(feeCollector, fee);
                } else {
                    super.transferFrom(from, feeCollector, fee);
                }
            }
        }

        // Modify `claimedAmountAfterTransfer` of the receiver following equation d)
        // Notice in this case we are increasing the value
        // The next line triggers the linter because it's not aware that super.transfer does not call an external
        // contract, nor does trigger a fallback function.
        // solhint-disable-next-line reentrancy
        _metadata[to].claimedAmountAfterTransfer += claimedAmountOfTransfer;

        if (isTransfer) {
            super.transfer(to, amount);
        } else {
            super.transferFrom(from, to, amount);
        }
    }

    /**
     * @dev Checks that 2 Milestones have percentages and timestamps sorted in ascending order.
     * @dev Percentages may be repeated and that scenario will be checked in the `_twoInARowRule`.
     *
     * @param current  Milestone with index `i` in the for loop.
     * @param previous Milestone with index `i - 1` in the for loop.
     */
    function _sortRule(Milestone calldata current, Milestone calldata previous) internal pure {
        if (previous.timestamp >= current.timestamp) revert MilestoneTimestampsNotSorted();
        if (previous.percentage > current.percentage) revert MilestonePercentagesNotSorted();
    }

    /**
     * @dev No more than 2 consecutive Milestones can have the same percentage.
     * @dev 2 Milestones may have the same percentage as long as they are followed by a Milestone with a `Ramp.Linear`.
     *
     * @param current   Milestone with index `i` in the for loop.
     * @param previous  Milestone with index `i - 1` in the for loop.
     * @param twoInARow Boolean declaring if the Milestones with index `i - 2` and `i - 1` already had the same
     *                  percentage.
     */
    function _twoInARowRule(Milestone calldata current, Milestone calldata previous, bool twoInARow) internal pure {
        if (twoInARow) {
            if (previous.percentage == current.percentage) revert MoreThanTwoEqualPercentages();
            if (current.ramp != Ramp.Linear) revert EqualPercentagesOnlyAllowedBeforeLinear();
        }
    }

    /**
     * @dev The last Milestone must have 100%.
     * @dev Only the last Milestone can have 100%.
     *
     * @param current         Milestone with index `i` in the for loop.
     * @param isLastMilestone Boolean declaring if the Milestone is the last in the for loop.
     */
    function _hundredPercentRule(Milestone calldata current, bool isLastMilestone) internal pure {
        if (isLastMilestone) {
            if (current.percentage != ONE) revert LastPercentageMustBe100();
        } else {
            if (current.percentage == ONE) revert OnlyLastPercentageCanBe100();
        }
    }

    /**
     * @dev Perform a staticcall to attempt to fetch `underlyingToken`'s decimals. In case of an error, we default to
     * 18.
     */
    function _tryFetchDecimals() internal view returns (uint8) {
        (bool success, bytes memory encodedDecimals) = address(underlyingToken).staticcall(
            abi.encodeWithSelector(ERC20Upgradeable.decimals.selector)
        );

        if (success && encodedDecimals.length >= 32) {
            uint256 returnedDecimals = abi.decode(encodedDecimals, (uint256));
            if (returnedDecimals <= type(uint8).max) {
                return uint8(returnedDecimals);
            }
        }
        return 18;
    }

    /**
     * @dev Perform a staticcall to attempt to fetch `underlyingToken`'s balance of this contract.
     * In case of an error, reverts with custom `UnsuccessfulFetchOfTokenBalance` error.
     */
    function _getBalanceOfThis() internal view returns (uint256) {
        (bool success, bytes memory encodedBalance) = address(underlyingToken).staticcall(
            abi.encodeWithSelector(ERC20Upgradeable.balanceOf.selector, address(this))
        );

        if (success && encodedBalance.length >= 32) {
            return abi.decode(encodedBalance, (uint256));
        }
        revert UnsuccessfulFetchOfTokenBalance();
    }

    /**
     * @notice This method is used to infer the value of claimed amounts.
     *
     * @dev If the unlocked percentage has already reached 100%, there's no way to infer the claimed amount.
     *
     * @param amount                  Amount of `underlyingToken` in the transaction.
     * @param claimableAmountOfImport Amount of `underlyingToken` from this transaction that should be considered
     *                                claimable.
     * @param unlocked                The unlocked percentage value at the time of the export of this transaction.
     *
     * @return Amount of `underlyingToken` that has been claimed based on the arguments given.
     */
    function _claimedAmount(
        uint256 amount,
        uint256 claimableAmountOfImport,
        uint256 unlocked
    ) internal pure returns (uint256) {
        if (unlocked == ONE) return 0;

        uint256 a = unlocked * amount;
        uint256 b = ONE * claimableAmountOfImport;
        // If `a - b` underflows, we display a better error message.
        if (b > a) revert ClaimableAmountOfImportIsGreaterThanExpected();
        return (a - b) / (ONE - unlocked);
    }

    /**
     * @param startingAmount Amount of `underlyingToken` originally held.
     * @param claimedAmount  Amount of `underlyingToken` already claimed.
     *
     * @return Amount of `underlyingToken` that can be claimed based on the milestones reached and initial amounts
     * given.
     */
    function _claimableAmount(uint256 startingAmount, uint256 claimedAmount) internal view returns (uint256) {
        return (unlockedPercentage() * startingAmount) / ONE - claimedAmount;
    }
}