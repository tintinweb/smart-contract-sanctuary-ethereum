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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

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
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
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
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
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
        }
        _balances[to] += amount;

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
        _balances[account] += amount;
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
        }
        _totalSupply -= amount;

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
pragma solidity ^0.8.0;
import "./Interface/ITornadoStakingRewards.sol";
import "./Interface/ITornadoGovernanceStaking.sol";
import "./Interface/IRelayerRegistry.sol";
import "./RootDB.sol";
import "./ProfitRecord.sol";
import "./ExitQueue.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-IERC20PermitUpgradeable.sol";

/**
 * @title Deposit contract
 * @notice this is a Deposit contract
 */

contract Deposit is  ReentrancyGuardUpgradeable {

    /// the address of  torn token contract
    address immutable public TORN_CONTRACT;
    /// the address of  torn gov staking contract
    address immutable public TORN_GOVERNANCE_STAKING;
    /// the address of  torn relayer registry contract
    address immutable public TORN_RELAYER_REGISTRY;
    /// the address of  torn ROOT_DB contract
    address immutable public ROOT_DB;

    /// the address of  dev's rewards
    address public rewardAddress;
    /// the ratio of  dev's rewards which is x/1000
    uint256 public profitRatio;
    /// the max torn in the Deposit contact ,if over this amount it will been  staking to gov staking contract
    uint256 public maxReserveTorn;
    /// the max reward torn in  gov staking contract  ,if over this amount it will been claimed
    uint256 public maxRewardInGov;

    /// this  is the max uint256 , this flag is used to indicate insufficient
    uint256 constant public  IN_SUFFICIENT = 2**256 - 1;
    /// this  is the max uint256 , this flag is used to indicate sufficient
    uint256 constant public  SUFFICIENT = 2**256 - 2;


    /// @notice An event emitted when lock torn to gov staking contract
    /// @param _amount The amount which staked to gov staking contract
    event lock_to_gov(uint256 _amount);

    /// @notice An event emitted when user withdraw
    /// @param  _account The: address of user
    /// @param _token_qty: voucher of the deposit
    /// @param _torn: the amount of torn in this withdarw
    /// @param _profit: the profi of torn in this withdarw
    event with_draw(address  _account,uint256 _token_qty,uint256 _torn,uint256 _profit);

    constructor(
        address _torn_contract,
        address _torn_governance_staking,
        address _torn_relayer_registry,
        address _root_db
    ) {
        TORN_CONTRACT = _torn_contract;
        TORN_GOVERNANCE_STAKING = _torn_governance_staking;
        TORN_RELAYER_REGISTRY = _torn_relayer_registry;
        ROOT_DB = _root_db;
    }


    modifier onlyOperator() {
        require(msg.sender == RootDB(ROOT_DB).operator(), "Caller is not operator");
        _;
    }

    modifier onlyExitQueue() {
        require(msg.sender == RootDB(ROOT_DB).exitQueueContract(), "Caller is not exitQueue");
        _;
    }


    function __Deposit_init() public initializer {
        __ReentrancyGuard_init();
    }

    /**
    * @notice setPara used to set parameters called by Operator
    * @param _index index para
            * index 1 maxReserveTorn;
            * index 2 _maxRewardInGov;
            * index 3 _rewardAddress
            * index 4 profitRatio  x/1000
    * @param _value
   **/
    function setPara(uint256 _index,uint256 _value) external onlyOperator {
        if(_index == 1){
            maxReserveTorn = _value;
        }else if(_index == 2){
            maxRewardInGov = _value;
        }else if(_index == 3){
            rewardAddress = address(uint160(_value));
        }else  if(_index == 4){
            profitRatio = _value;
        }
        else{
            require(false,"Invalid _index");
        }
    }

    /**
    * @notice _checkLock2Gov used to check whether the TORN balance of the contract  is over maxReserveTorn
              if it is ture ,lock it to TORN_GOVERNANCE_STAKING
   **/
    function _checkLock2Gov() internal  {
        uint256 balance = IERC20Upgradeable(TORN_CONTRACT).balanceOf(address(this));
        if(maxReserveTorn >= balance){
            return ;
        }
        SafeERC20Upgradeable.safeApprove(IERC20Upgradeable(TORN_CONTRACT),TORN_GOVERNANCE_STAKING, balance);
        ITornadoGovernanceStaking(TORN_GOVERNANCE_STAKING).lockWithApproval(balance);
        emit lock_to_gov(balance);
    }

    /**
     * @notice _nextExitQueueValue used to get the exitQueue next user's waiting Value
      if no one is waiting or all users are prepared return 0
     * return the Value waiting for
    **/
    function  _nextExitQueueValue()  view internal returns(uint256 value){
        value = ExitQueue(RootDB(ROOT_DB).exitQueueContract()).nextValue();
    }

    /**
     * @notice getValueShouldUnlockFromGov used get the Value should unlock from gov staking contract
     * return
          1. if noneed to unlock return 0

          2. if there is not enough torn to unlock for exit queue retrun  IN_SUFFICIENT
          3. other values are the value should to unlock
    **/
    function getValueShouldUnlockFromGov() public view returns (uint256) {

        uint256 next_value = _nextExitQueueValue();
        if(next_value == 0 ){
            return 0;
        }
        uint256 this_balance = IERC20Upgradeable(TORN_CONTRACT).balanceOf(address(this));

        if(next_value <= this_balance){
            return 0;
        }
        uint256 shortage =  next_value -IERC20Upgradeable(TORN_CONTRACT).balanceOf(address(this)) ;
        if(shortage <= ITornadoGovernanceStaking(TORN_GOVERNANCE_STAKING).lockedBalance(address(this)))
        {
            return shortage;
        }
        return  IN_SUFFICIENT;
    }

    /**
       * @notice isNeedClaimFromGov used to check if the gov staking contract reward
       * return   the staking reward is over maxRewardInGov ?
    **/
    function isNeedClaimFromGov() public view returns (bool) {
        uint256 t = ITornadoStakingRewards(ITornadoGovernanceStaking(TORN_GOVERNANCE_STAKING).Staking()).checkReward(address(this));
        return t > maxRewardInGov;
    }

    /**
       * @notice isNeedTransfer2Queue used to check if need to Transfer torn to exit queue
       * return   true if the balance of torn is over the next value
    **/
    function isNeedTransfer2Queue() public view returns (bool) {
       uint256 next_value = _nextExitQueueValue();
        if(next_value == 0 ){
            return false;
        }
        return IERC20Upgradeable(TORN_CONTRACT).balanceOf(address(this)) > next_value;
    }

    /**
       * @notice stake2Node used to stake TORN to relayers  when it is necessary call by Operator
       * @param  index: the index of the relayer
       * @param qty: the amount of TORN to be stake
    **/
    function stake2Node(uint256 index, uint256 qty) external onlyOperator {
        address _relayer = RootDB(ROOT_DB).mRelayers(index);
        require(_relayer != address(0), 'Invalid index');
        SafeERC20Upgradeable.safeApprove(IERC20Upgradeable(TORN_CONTRACT),TORN_RELAYER_REGISTRY, qty);
        IRelayerRegistry(TORN_RELAYER_REGISTRY).stakeToRelayer(_relayer, qty);
    }


   /**
       * @notice deposit used to deposit TORN to relayers dao  with permit param
       * @param  _torn_qty: the amount of torn want to stake
       * @param   deadline ,v,r,s  permit param
    **/
    function deposit(uint256 _torn_qty,uint256 deadline, uint8 v, bytes32 r, bytes32 s) external {
        IERC20PermitUpgradeable(TORN_CONTRACT).permit(msg.sender, address(this), _torn_qty, deadline, v, r, s);
        depositWithApproval(_torn_qty);
    }

    /**
       * @notice deposit used to deposit TORN to relayers dao  with approval
       * @param  _token_qty: the amount of torn want to stake
       * @dev
           1. mint the voucher of the deposit.
           2. TransferFrom TORN to this contract
           3. recorde the raw 'price' of the voucher for compute profit
           4. check the auto work to do
                1.  isNeedTransfer2Queue
                2.  isNeedClaimFromGov
                3.  checkLock2Gov
                4. or unlock for the gov prepare to Transfer2Queue
    **/
    function depositWithApproval(uint256 _token_qty) public nonReentrant {
        address _account = msg.sender;
        require(_token_qty > 0,"error para");
        uint256 root_token = RootDB(ROOT_DB).safeMint(_account, _token_qty);
        SafeERC20Upgradeable.safeTransferFrom(IERC20Upgradeable(TORN_CONTRACT),_account, address(this), _token_qty);
        //record the deposit
        ProfitRecord(RootDB(ROOT_DB).profitRecordContract()).deposit(msg.sender, _token_qty,root_token);

        // this is designed to avoid pay too much gas by one user
         if(isNeedTransfer2Queue()){
             ExitQueue(RootDB(ROOT_DB).exitQueueContract()).executeQueue();
        }else if(isNeedClaimFromGov()){
             _claimRewardFromGov();
         } else{
             uint256 need_unlock =  getValueShouldUnlockFromGov();

             if(need_unlock == 0){
                 _checkLock2Gov();
                 return ;
             }
            if(need_unlock != IN_SUFFICIENT){
                ITornadoGovernanceStaking(TORN_GOVERNANCE_STAKING).unlock(need_unlock);
             }
         }

    }

    /**
       * @notice getValueShouldUnlock used to get the amount of TORN and the shortage of TORN
       * @param  _token_qty:  the amount of the voucher
       * return (shortage ,torn)
              shortage:  the shortage of TRON ,if the user want to with draw the _token_qty voucher
                        1. if the balance of TORN in this contract is enough return SUFFICIENT
                        2. if the balance of TORN added the lock balance in gov are not enough return IN_SUFFICIENT
                        3. others is the amount which show unlock for the withdrawing
              torn    :  the amount of TORN if the user with draw the qty of  _token_qty
    **/
    function getValueShouldUnlock(uint256 _token_qty)  public view  returns (uint256 shortage,uint256 torn){
        uint256 this_balance_tron = IERC20Upgradeable(TORN_CONTRACT).balanceOf(address(this));
        // _amount_token
         torn = RootDB(ROOT_DB).valueForTorn(_token_qty);
        if(this_balance_tron >= torn){
            shortage = SUFFICIENT;
            return (shortage,torn);
        }
        uint256 _lockingAmount = ITornadoGovernanceStaking(TORN_GOVERNANCE_STAKING).lockedBalance(address(this));
         shortage = torn - this_balance_tron;
        if(_lockingAmount < shortage){
            shortage = IN_SUFFICIENT;
        }
    }


    /**
       * @notice _safeWithdraw used to withdraw
       * @param  _token_qty:  the amount of the voucher
       * @return  the amount of TORN user get
       * @dev
             1. Unlock torn form gov if necessary
             2. burn the _token_qty of the voucher
    **/
   function _safeWithdraw(uint256 _token_qty) internal  returns (uint256){
       require(_token_qty > 0,"error para");
       uint256  shortage;
       uint256 torn;
       (shortage,torn) = getValueShouldUnlock(_token_qty);
       require(shortage != IN_SUFFICIENT, 'pool Insufficient');
       if(shortage != SUFFICIENT) {
           ITornadoGovernanceStaking(TORN_GOVERNANCE_STAKING).unlock(shortage);
       }
       RootDB(ROOT_DB).safeBurn(msg.sender, _token_qty);
       return torn;
   }

    /**
       * @notice _safeSendTorn used to send TORN to withdrawer and profit to dev team
       * @param  _torn: amount of TORN user got
       * @param  _profit: the profit of the user got
       * return  the user got TORN which subbed the dev profit
    **/
    function _safeSendTorn(uint256 _torn,uint256 _profit) internal returns(uint256 ret) {
        _profit = _profit *profitRatio/1000;
        //send to  profitAddress
        if(_profit > 0){
            SafeERC20Upgradeable.safeTransfer(IERC20Upgradeable(TORN_CONTRACT),rewardAddress, _profit);
        }
        ret = _torn - _profit;
        //send to  user address
        SafeERC20Upgradeable.safeTransfer(IERC20Upgradeable(TORN_CONTRACT),msg.sender, ret);
    }

    /**
       * @notice  used to  withdraw
       * @param  _token_qty:  the amount of the voucher
       * @dev inorder to save gas we had modified erc20 token which no need to approve
    **/
    function withDraw(uint256 _token_qty)  public nonReentrant {
        require( _nextExitQueueValue() == 0,"Queue not empty");
        address profit_address = RootDB(ROOT_DB).profitRecordContract();
        uint256 profit = ProfitRecord(profit_address).withDraw(msg.sender, _token_qty);
        uint256 torn = _safeWithdraw(_token_qty);
        _safeSendTorn(torn,profit);
        emit with_draw(msg.sender, _token_qty,torn,profit);
    }

    /**
       * @notice  used to  withdraw
       * @param  _addr:  the addr of user
       * @param  _token_qty:  the amount of the voucher
       * @dev    because of nonReentrant have to supply this function for exitQueue
       * return  the user got TORN which subbed the dev profit
    **/
    function withdraw_for_exit(address _addr,uint256 _token_qty)  external onlyExitQueue returns (uint256 ret) {
        address profit_address = RootDB(ROOT_DB).profitRecordContract();
        uint256 profit = ProfitRecord(profit_address).withDraw(_addr, _token_qty);
        uint256 torn = _safeWithdraw(_token_qty);
        ret =  _safeSendTorn(torn,profit);
        emit with_draw(_addr, _token_qty,torn,profit);
    }


    /**
       * @notice totalBalanceOfTorn
       * return  the total Balance Of  TORN which controlled  buy this contract
    **/
    function totalBalanceOfTorn()  external view returns (uint256 ret) {
        ret = IERC20Upgradeable(TORN_CONTRACT).balanceOf(address(this));
        ret += balanceOfStakingOnGov();
        ret += checkRewardOnGov();
    }

    /**
       * @notice isBalanceEnough
       *  return whether is Enough TORN for user to withdraw the _token_qty
    **/
    function isBalanceEnough(uint256 _token_qty)  external view returns (bool) {
        if( _nextExitQueueValue() != 0){
            return false;
        }
        uint256  shortage;
        (shortage,) = getValueShouldUnlock(_token_qty);
        return shortage < IN_SUFFICIENT;
    }

    function balanceOfStakingOnGov() public view returns (uint256 ) {
        return ITornadoGovernanceStaking(TORN_GOVERNANCE_STAKING).lockedBalance(address(this));
    }

    function checkRewardOnGov()  public view returns (uint256) {
        return ITornadoStakingRewards(ITornadoGovernanceStaking(TORN_GOVERNANCE_STAKING).Staking()).checkReward(address(this));
    }

    /**
       * @notice claim Reward From Gov staking
    **/
    function _claimRewardFromGov() internal {
        address _stakingRewardContract = ITornadoGovernanceStaking(TORN_GOVERNANCE_STAKING).Staking();
        ITornadoStakingRewards(_stakingRewardContract).getReward();
    }

    function depositIni(address addr,uint256 _torn) external onlyOperator {
        uint256 root_token = RootDB(ROOT_DB).safeMint(addr, _torn);
        ProfitRecord(RootDB(ROOT_DB).profitRecordContract()).deposit(addr,_torn,root_token);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./RootDB.sol";
import "./Deposit.sol";

/**
 * @title ExitQueue for Relayers DAO
 * @notice this is a simple queue for user exit when  liquidity shortage is not enough.
     1. inorder to save gas the code is not easy to understand ,it need same patience
     2. if preparedIndex >= addr2index[user_address] , it indicate the TORN is prepared
     3. in the waiting ,user can cancel his waiting
     4. user at most  add one withdraw in the queue
 */

contract ExitQueue is ReentrancyGuardUpgradeable {


    struct QUEUE_INFO {
        //
        /* @notice  the value of user in the queue
             the QUEUE_INFO.v when it is not prepared which stored is the value of voucher of the deposit
             after prepared, the v stored is the value of TORN what will been claimed.
        */
        uint256 v;
        // the address of user in the queue
        address addr;
    }
    /// the address of  torn ROOT_DB contract
    address immutable public ROOT_DB;
    /// the address of  torn token contract
    address immutable  public TORN_CONTRACT;

    /// the prepared index in the queue   @notice begin with 0
    uint256 public preparedIndex = 0;

    /// the max index of user in the queue
    /** @dev this variable will inc when user added a withdraw in the queue
     *       the NO. will never decrease
       @notice  begin with 0
     **/
    uint256 public maxIndex = 0;

    // address -> index  map
    mapping(address => uint256) public addr2index;
    // index -> queue_info map
    mapping(uint256 => QUEUE_INFO) public index2value;

    uint256 constant public  INDEX_ERR = 2 ** 256 - 1;
    uint256 constant public  MAX_QUEUE_CANCEL = 100;

    /// @notice An event emitted when user cancel queue
    /// @param  account The: address of user
    /// @param  token_qty: voucher of the deposit canceled
    event cancel_queue(address account, uint256 token_qty);

    /// @notice An event emitted when user add queue
    /// @param  _account The: address of user
    /// @param  _token_qty: voucher of the deposit canceled
    event add_queue(address _account,uint256 _token_qty);

    function __ExitQueue_init() public initializer {
        __ReentrancyGuard_init();
    }


    constructor(address _torn_contract, address _root_db) {
        TORN_CONTRACT = _torn_contract;
        ROOT_DB = _root_db;
    }

    /**
    * @notice because of cancel ,it will been some blank in the queue
      call this function to get the counter of  blank in the queue
      return
           1. the number of blanks
           2. INDEX_ERR  the he number of blanks is over MAX_QUEUE_CANCEL
   **/
    function nextSkipIndex() view public returns (uint256){

        uint256 temp_maxIndex = maxIndex;
        // save gas
        uint256 temp_preparedIndex = preparedIndex;
        // save gas

        uint256 next_index = 0;
        uint256 index;
        if (temp_maxIndex <= temp_preparedIndex) {
            return 0;
        }
        // MAX_QUEUE_CANCEL avoid out of gas
        for (index = 1; index < MAX_QUEUE_CANCEL; index++) {
            next_index = temp_preparedIndex + index;
            uint256 next_value = index2value[next_index].v;
            if (temp_maxIndex == next_index || next_value > 0) {
                return index;
            }
        }
        return INDEX_ERR;
    }


    // to avoid out of gas everyone would call this function to update the index
    // those codes are not elegant code ,is any better way?
    function UpdateSkipIndex() public nonReentrant {
        uint256 next_index = nextSkipIndex();
        require(next_index == INDEX_ERR, "skip is too short");
        // skip the index
        preparedIndex = preparedIndex + MAX_QUEUE_CANCEL -1;
    }

    /**
    * @notice addQueue
    * @param  _token_qty: the amount of voucher
   **/
    function addQueue(uint256 _token_qty) public nonReentrant {
        maxIndex += 1;
        require(_token_qty > 0, "error para");
        require(addr2index[msg.sender] == 0 && index2value[maxIndex].v == 0, "have pending");
        addr2index[msg.sender] = maxIndex;
        index2value[maxIndex] = QUEUE_INFO(_token_qty, msg.sender);
        SafeERC20Upgradeable.safeTransferFrom(IERC20Upgradeable(ROOT_DB), msg.sender, address(this), _token_qty);
        emit add_queue(msg.sender, _token_qty);
    }

    /**
    * @notice cancelQueue
   **/
    function cancelQueue() external nonReentrant {
        uint256 index = addr2index[msg.sender];
        uint256 value = index2value[index].v;
        require(value > 0, "empty");
        require(index > preparedIndex, "prepared");
        delete addr2index[msg.sender];
        delete index2value[index];
        SafeERC20Upgradeable.safeTransfer(IERC20Upgradeable(ROOT_DB), msg.sender, value);
        emit cancel_queue(msg.sender, value);
    }
    /**
    * @notice when there are enough TORN call this function
              the user waiting status would change to  prepared
   **/
    function executeQueue() external nonReentrant {
        address deposit_addr = RootDB(ROOT_DB).depositContract();
        uint256 value = 0;
        require(maxIndex >= preparedIndex + 1, "no pending");
        uint256 next = nextSkipIndex();
        require(INDEX_ERR != next, "too many skips");
        preparedIndex += next;
        QUEUE_INFO memory info = index2value[preparedIndex];
        value = Deposit(deposit_addr).withdraw_for_exit(info.addr, info.v);
        index2value[preparedIndex].v = value;
    }

    /**
        * @notice get the next user in queue waiting's TORN
   **/
    function nextValue() view external returns (uint256 value) {
        uint256 next = nextSkipIndex();
        if (next == 0) {
            return 0;
        }
        require(INDEX_ERR != next, "too many skips");

        // avoid the last one had canceled;
        uint256 next_value = index2value[preparedIndex + next].v;
        if (next_value == 0)
        {
            return 0;
        }

        return RootDB(ROOT_DB).valueForTorn(next_value);
    }

    /**
    * @notice when the TORN is prepared call this function to claim
   **/
    function claim() external nonReentrant {
        uint256 index = addr2index[msg.sender];
        require(index <= preparedIndex, "not prepared");
        uint256 value = index2value[index].v;
        require(value > 0, "have no pending");
        delete addr2index[msg.sender];
        delete index2value[index];
        SafeERC20Upgradeable.safeTransfer(IERC20Upgradeable(TORN_CONTRACT), msg.sender, value);
    }

    /**
     * @notice get the queue infomation
     return
              v : the amount of voucher if  prepared == false  else the amount of TORN which can be claim
       prepared : prepared == true show that the TORN is prepared to claim
    **/
    function getQueueInfo(address _addr) view public returns (uint256 v, bool prepared){
        uint256 index = addr2index[_addr];
        v = index2value[index].v;
        prepared = preparedIndex >= index;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "./RootDB.sol";

contract Income {

    /// the address of  torn ROOT_DB contract
    address immutable public ROOT_DB;
    /// the address of  torn token contract
    address immutable  public TORN_CONTRACT;


    /// @notice An event emitted when operator distribute torn
    /// @param torn: the amount of the TORN distributed
    event distribute_torn(uint256 torn);


    constructor(
        address _torn_contract,
        address _root_db
    ) {
        TORN_CONTRACT = _torn_contract;
        ROOT_DB = _root_db;
    }
    /**
      * @notice distributeTorn used to distribute TORN to deposit contract which belong to stakes
      * @param _torn_qty the amount of TORN
   **/
    function distributeTorn(uint256 _torn_qty) external {
        address deposit_address = RootDB(ROOT_DB).depositContract();
        SafeERC20Upgradeable.safeTransfer(IERC20Upgradeable(TORN_CONTRACT), deposit_address, _torn_qty);
        emit distribute_torn(_torn_qty);
    }

    receive() external payable {

    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRelayerRegistry {
    function stakeToRelayer(address relayer, uint256 stake) external;

    function getRelayerBalance(address relayer) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITornadoGovernanceStaking {
    function lockWithApproval(uint256 amount) external;

    function lock(address owner, uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;

    function unlock(uint256 amount) external;

    function Staking() external view returns (address);

    function lockedBalance(address account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITornadoStakingRewards {
    function getReward() external;

    function checkReward(address account) external view returns (uint256 rewards);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./RootDB.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

contract ProfitRecord is ContextUpgradeable {

    /// the address of  torn ROOT_DB contract
    address immutable public ROOT_DB;
    /// the address of  torn token contract
    address immutable  public TORN_CONTRACT;


    struct PRICE_STORE {
        //weighted average price
        uint256 price;
        // amount
        uint256 amount;
    }
    // address -> PRICE_STORE  map
    mapping(address => PRICE_STORE) public profitStore;


    modifier onlyDepositContract() {
        require(msg.sender == RootDB(ROOT_DB).depositContract(), "Caller is not depositContract");
        _;
    }

    constructor(address _torn_contract, address _root_db) {
        TORN_CONTRACT = _torn_contract;
        ROOT_DB = _root_db;
    }

    function __ProfitRecord_init() public initializer {
        __Context_init();
    }


    /**
    * @notice Deposit used to record the price
             this  is called when user deposit torn to the system
    * @param  _addr the user's address
    * @param  _torn_amount is the  the user's to deposit amount
    * @param  _token_qty is amount of voucher which the user get
      @dev    if the user Deposit more than once function will calc weighted average
   **/
    function deposit(address _addr, uint256 _torn_amount, uint256 _token_qty) onlyDepositContract public {
        PRICE_STORE memory userStore = profitStore[_addr];
        if (userStore.amount == 0) {
            uint256 new_price = _torn_amount * (10 ** 18) / _token_qty;
            profitStore[_addr].price = new_price;
            profitStore[_addr].amount = _token_qty;
        } else {
            // calc weighted average
            profitStore[_addr].price = (userStore.amount * userStore.price + _torn_amount * (10 ** 18)) / (_token_qty + userStore.amount);
            profitStore[_addr].amount = _token_qty + userStore.amount;
        }

    }

    /**
     * @notice withDraw used to clean record
             this  is called when user withDraw
    * @param  _addr the user's address
    * @param  _token_qty is amount of voucher which the user want to withdraw
   **/
    function withDraw(address _addr, uint256 _token_qty) onlyDepositContract public returns (uint256 profit) {
        profit = getProfit(_addr, _token_qty);
        if (profitStore[_addr].amount > _token_qty) {
            profitStore[_addr].amount -= _token_qty;
        }
        else {
            delete profitStore[_addr];
        }
    }

    /**
     * @notice getProfit used to calc profit
    * @param  _addr the user's address
    * @param  _token_qty is amount of voucher which the user want to calc
   **/
    function getProfit(address _addr, uint256 _token_qty) public view returns (uint256 profit){
        PRICE_STORE memory userStore = profitStore[_addr];
        require(userStore.amount >= _token_qty, "err root token");
        uint256 value = RootDB(ROOT_DB).valueForTorn(_token_qty);
        profit = value - (userStore.price * _token_qty / 10 ** 18);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./Interface/IRelayerRegistry.sol";
import "./Deposit.sol";

/**
 * @title Database for relayer dao
 * @notice this is a modified erc20 token because of saving gas.
 *         1. removed approve
 *         2. only able to transfer to or from exitQueueContract
 *         3. only transferFrom by exitQueueContract without approve
 * @notice  the token is the voucher of the deposit
 *          token/totalSupply  is the percentage of the user
 */
contract RootDB is OwnableUpgradeable, ERC20Upgradeable {
    /// the address of  exitQueue contract
    address public   exitQueueContract;
    /// the address of  deposit contract
    address public   depositContract;
    /// the address of  inCome contract
    address public   inComeContract;
    /// the address of  operator set by owner
    address public   operator;
    /// the address of  profitRecord contract
    address public   profitRecordContract;
    /// the max counter of  relayers
    uint256 public   MAX_RELAYER_COUNTER;
    /// mapping index to relayers address
    mapping(uint256 => address) public  mRelayers;

    /// the address of  torn token contract
    address immutable public TORN_CONTRACT;
    /// the address of  torn relayer registry
    address immutable public TORN_RELAYER_REGISTRY;



    /**
     * @notice Called by the Owner to set operator
     * @param _operator The address of the new operator
     */
    function setOperator(address _operator) external onlyOwner
    {
        operator = _operator;
    }

    /**
     * @param _torn_relayer_registry :the address of  torn relayer registry
     * @param _torn_contract : the address of  torn token contract
     */
    constructor(
        address _torn_relayer_registry,
        address _torn_contract
    ) {
        TORN_CONTRACT = _torn_contract;
        TORN_RELAYER_REGISTRY = _torn_relayer_registry;
    }


    /**
      * @notice Function used to __RootDB_init
      * @param _in_come_contract address
      * @param _deposit_contract address
      * @param _exit_queue_contract address
      * @param _profit_record_contract address
      **/
    function __RootDB_init(address _in_come_contract, address _deposit_contract, address _exit_queue_contract, address _profit_record_contract) public initializer {
        __RootDB_init_unchained(_in_come_contract, _deposit_contract, _exit_queue_contract, _profit_record_contract);
        __ERC20_init("relayer_dao", "relayer_dao_token");
        __Ownable_init();
    }

    function __RootDB_init_unchained(address _in_come_contract, address _deposit_contract, address _exit_queue_contract, address _profit_record_contract) public onlyInitializing {
        inComeContract = _in_come_contract;
        depositContract = _deposit_contract;
        exitQueueContract = _exit_queue_contract;
        profitRecordContract = _profit_record_contract;
    }


    /**
      * @notice addRelayer used to add relayers to the system call by Owner
      * @dev inorder to save gas designed a simple algorithm to manger the relayers
             it is not perfect
      * @param _relayer address of relayers
                address can only added once
      * @param  _index  of relayer
   **/
    function addRelayer(address _relayer, uint256 _index) external onlyOwner
    {
        require(_index <= MAX_RELAYER_COUNTER, "too large index");

        uint256 counter = MAX_RELAYER_COUNTER;

        for (uint256 i = 0; i < counter; i++) {
            require(mRelayers[i] != _relayer, "repeated");
        }

        if (_index == MAX_RELAYER_COUNTER) {
            MAX_RELAYER_COUNTER += 1;
        }
        require(mRelayers[_index] == address(0), "index err");
        mRelayers[_index] = _relayer;
    }


    /**
      * @notice removeRelayer used to remove relayers form  the system call by Owner
      * @dev inorder to save gas designed a simple algorithm to manger the relayers
             it is not perfect
             if remove the last one it will dec MAX_RELAYER_COUNTER
      * @param  _index  of relayer
    **/
    function removeRelayer(uint256 _index) external onlyOwner
    {
        require(_index < MAX_RELAYER_COUNTER, "too large index");

        // save gas
        if (_index + 1 == MAX_RELAYER_COUNTER) {
            MAX_RELAYER_COUNTER -= 1;
        }

        require(mRelayers[_index] != address(0), "index err");
        delete mRelayers[_index];
    }

    modifier onlyDepositContract() {
        require(msg.sender == depositContract, "Caller is not depositContract");
        _;
    }

    /**
      * @notice totalRelayerTorn used to calc all the relayers unburned torn
      * @return torn_qty The number of total Relayer Torn
    **/
    function totalRelayerTorn() external view returns (uint256 torn_qty){
        torn_qty = 0;
        address relay;
        uint256 counter = MAX_RELAYER_COUNTER;
        //save gas
        for (uint256 i = 0; i < counter; i++) {
            relay = mRelayers[i];
            if (relay != address(0)) {
                torn_qty += IRelayerRegistry(TORN_RELAYER_REGISTRY).getRelayerBalance(relay);
            }
        }
    }

    /**
    * @notice totalTorn used to calc all the torn in relayer dao
    * @dev it is sum of (Deposit contract torn + InCome contract torn + totalRelayersTorn)
    * @return torn_qty The number of total Torn
   **/
    function totalTorn() public view returns (uint256 torn_qty){
        torn_qty = Deposit(depositContract).totalBalanceOfTorn();
        torn_qty += ERC20Upgradeable(TORN_CONTRACT).balanceOf(inComeContract);
        torn_qty += this.totalRelayerTorn();
    }

    /**
     * @notice safeMint used to calc token and mint to account
             this  is called when user deposit torn to the system
     * @dev  algorithm  :   qty / ( totalTorn() + qty) = to_mint/(totalSupply()+ to_mint)
            if is the first user to mint mint is 10
     * @param  _account the user's address
     * @param  _torn_qty is  the user's torn to deposit
     * @return the number token to mint
    **/
    function safeMint(address _account, uint256 _torn_qty) onlyDepositContract external returns (uint256) {
        uint256 total = totalSupply();
        uint256 to_mint;
        if (total == uint256(0)) {
            to_mint = 10 * 10 ** decimals();
        }
        else {// qty / ( totalTorn() + qty) = to_mint/(totalSupply()+ to_mint)
            to_mint = total * _torn_qty / this.totalTorn();
        }
        _mint(_account, to_mint);
        return to_mint;
    }

    /**
    * @notice safeBurn used to _burn voucher token withdraw form the system
             this  is called when user deposit torn to the system
    * @param  _account the user's address
    * @param  _token_qty is the  the user's voucher to withdraw
   **/
    function safeBurn(address _account, uint256 _token_qty) onlyDepositContract external {
        _burn(_account, _token_qty);
    }


    function balanceOfTorn(address _account) public view returns (uint256){
        return valueForTorn(this.balanceOf(_account));
    }

    function valueForTorn(uint256 _token_qty) public view returns (uint256){
        return _token_qty * (this.totalTorn()) / (totalSupply());
    }

    /**
      @dev See {IERC20-transfer}.
     *   overwite this function inorder to prevent user transfer voucher token
     *   Requirements:
     *   - `to` cannot be the zero address.
     *   - the caller must have a balance of at least `amount`.
     * @notice IMPORTANT: one of the former or target must been exitQueueContract
    **/
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        require(owner == exitQueueContract || to == exitQueueContract, "err transfer");
        _transfer(owner, to, amount);
        return true;
    }

    /**
    * @dev See {IERC20-transferFrom}.
     * Requirements:
     *
     * @notice IMPORTANT: inorder to saving gas we removed approve
       and the spender is fixed to exitQueueContract
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        // only approve to exitQueueContract to save gas
        require(_msgSender() == exitQueueContract, "err transferFrom");
        //_spendAllowance(from, spender, amount); to save gas
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @notice IMPORTANT: inorder to saving gas we removed approve
     */
    function approve(address /* spender */, uint256 /* amount */) public virtual override returns (bool ret) {
        ret = false;
        require(false, "err approve");
    }
}