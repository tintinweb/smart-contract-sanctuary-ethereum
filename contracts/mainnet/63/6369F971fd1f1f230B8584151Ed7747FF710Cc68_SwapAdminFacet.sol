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
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

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
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC20Upgradeable.sol";
import "../../../utils/ContextUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20BurnableUpgradeable is Initializable, ContextUpgradeable, ERC20Upgradeable {
    function __ERC20Burnable_init() internal onlyInitializing {
    }

    function __ERC20Burnable_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
interface IERC20Permit {
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
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
        IERC20 token,
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
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
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
        IERC20Permit token,
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
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import {TransferInfo, AppStorage, Role} from "../libraries/LibConnextStorage.sol";
import {LibDiamond} from "../libraries/LibDiamond.sol";
import {AssetLogic} from "../libraries/AssetLogic.sol";
import {TokenId} from "../libraries/TokenId.sol";
import {Constants} from "../libraries/Constants.sol";

contract BaseConnextFacet {
  AppStorage internal s;

  // ========== Custom Errors ===========

  error BaseConnextFacet__onlyOwner_notOwner();
  error BaseConnextFacet__onlyProposed_notProposedOwner();
  error BaseConnextFacet__onlyOwnerOrRouter_notOwnerOrRouter();
  error BaseConnextFacet__onlyOwnerOrWatcher_notOwnerOrWatcher();
  error BaseConnextFacet__onlyOwnerOrAdmin_notOwnerOrAdmin();
  error BaseConnextFacet__whenNotPaused_paused();
  error BaseConnextFacet__nonReentrant_reentrantCall();
  error BaseConnextFacet__nonXCallReentrant_reentrantCall();
  error BaseConnextFacet__getAdoptedAsset_assetNotFound();
  error BaseConnextFacet__getApprovedCanonicalId_notAllowlisted();

  // ============ Modifiers ============

  /**
   * @dev Prevents a contract from calling itself, directly or indirectly.
   * Calling a `nonReentrant` function from another `nonReentrant`
   * function is not supported. It is possible to prevent this from happening
   * by making the `nonReentrant` function external, and making it call a
   * `private` function that does the actual work.
   */
  modifier nonReentrant() {
    // On the first call to nonReentrant, _notEntered will be true
    if (s._status == Constants.ENTERED) revert BaseConnextFacet__nonReentrant_reentrantCall();

    // Any calls to nonReentrant after this point will fail
    s._status = Constants.ENTERED;

    _;

    // By storing the original value once again, a refund is triggered (see
    // https://eips.ethereum.org/EIPS/eip-2200)
    s._status = Constants.NOT_ENTERED;
  }

  modifier nonXCallReentrant() {
    // On the first call to nonReentrant, _notEntered will be true
    if (s._xcallStatus == Constants.ENTERED) revert BaseConnextFacet__nonXCallReentrant_reentrantCall();

    // Any calls to nonReentrant after this point will fail
    s._xcallStatus = Constants.ENTERED;

    _;

    // By storing the original value once again, a refund is triggered (see
    // https://eips.ethereum.org/EIPS/eip-2200)
    s._xcallStatus = Constants.NOT_ENTERED;
  }

  /**
   * @notice Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    if (LibDiamond.contractOwner() != msg.sender) revert BaseConnextFacet__onlyOwner_notOwner();
    _;
  }

  /**
   * @notice Throws if called by any account other than the proposed owner.
   */
  modifier onlyProposed() {
    if (s._proposed != msg.sender) revert BaseConnextFacet__onlyProposed_notProposedOwner();
    _;
  }

  /**
   * @notice Throws if called by any account other than the owner and router role.
   */
  modifier onlyOwnerOrRouter() {
    if (LibDiamond.contractOwner() != msg.sender && s.roles[msg.sender] != Role.RouterAdmin)
      revert BaseConnextFacet__onlyOwnerOrRouter_notOwnerOrRouter();
    _;
  }

  /**
   * @notice Throws if called by any account other than the owner and watcher role.
   */
  modifier onlyOwnerOrWatcher() {
    if (LibDiamond.contractOwner() != msg.sender && s.roles[msg.sender] != Role.Watcher)
      revert BaseConnextFacet__onlyOwnerOrWatcher_notOwnerOrWatcher();
    _;
  }

  /**
   * @notice Throws if called by any account other than the owner and admin role.
   */
  modifier onlyOwnerOrAdmin() {
    if (LibDiamond.contractOwner() != msg.sender && s.roles[msg.sender] != Role.Admin)
      revert BaseConnextFacet__onlyOwnerOrAdmin_notOwnerOrAdmin();
    _;
  }

  /**
   * @notice Throws if all functionality is paused
   */
  modifier whenNotPaused() {
    if (s._paused) revert BaseConnextFacet__whenNotPaused_paused();
    _;
  }

  // ============ Internal functions ============
  /**
   * @notice Indicates if the router allowlist has been removed
   */
  function _isRouterAllowlistRemoved() internal view returns (bool) {
    return LibDiamond.contractOwner() == address(0) || s._routerAllowlistRemoved;
  }

  /**
   * @notice Returns the adopted assets for given canonical information
   */
  function _getAdoptedAsset(bytes32 _key) internal view returns (address) {
    address adopted = AssetLogic.getConfig(_key).adopted;
    if (adopted == address(0)) {
      revert BaseConnextFacet__getAdoptedAsset_assetNotFound();
    }
    return adopted;
  }

  /**
   * @notice Returns the adopted assets for given canonical information
   */
  function _getRepresentationAsset(bytes32 _key) internal view returns (address) {
    address representation = AssetLogic.getConfig(_key).representation;
    // If this is address(0), then there is no mintable token for this asset on this
    // domain
    return representation;
  }

  /**
   * @notice Calculates a transferId
   */
  function _calculateTransferId(TransferInfo memory _params) internal pure returns (bytes32) {
    return keccak256(abi.encode(_params));
  }

  /**
   * @notice Internal utility function that combines
   *         `_origin` and `_nonce`.
   * @dev Both origin and nonce should be less than 2^32 - 1
   * @param _origin Domain of chain where the transfer originated
   * @param _nonce The unique identifier for the message from origin to destination
   * @return Returns (`_origin` << 32) & `_nonce`
   */
  function _originAndNonce(uint32 _origin, uint32 _nonce) internal pure returns (uint64) {
    return (uint64(_origin) << 32) | _nonce;
  }

  function _getLocalAsset(
    bytes32 _key,
    bytes32 _id,
    uint32 _domain
  ) internal view returns (address) {
    return AssetLogic.getLocalAsset(_key, _id, _domain, s);
  }

  function _getCanonicalTokenId(address _candidate) internal view returns (TokenId memory) {
    return AssetLogic.getCanonicalTokenId(_candidate, s);
  }

  function _getLocalAndAdoptedToken(
    bytes32 _key,
    bytes32 _id,
    uint32 _domain
  ) internal view returns (address, address) {
    address _local = AssetLogic.getLocalAsset(_key, _id, _domain, s);
    address _adopted = _getAdoptedAsset(_key);
    return (_local, _adopted);
  }

  function _isLocalOrigin(address _token) internal view returns (bool) {
    return AssetLogic.isLocalOrigin(_token, s);
  }

  function _getApprovedCanonicalId(address _candidate) internal view returns (TokenId memory, bytes32) {
    TokenId memory _canonical = _getCanonicalTokenId(_candidate);
    bytes32 _key = AssetLogic.calculateCanonicalHash(_canonical.id, _canonical.domain);
    if (!AssetLogic.getConfig(_key).approval) {
      revert BaseConnextFacet__getApprovedCanonicalId_notAllowlisted();
    }
    return (_canonical, _key);
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import {IERC20, Address, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";

import {AmplificationUtils, SwapUtils} from "../libraries/AmplificationUtils.sol";
import {Constants} from "../libraries/Constants.sol";

import {LPToken} from "../helpers/LPToken.sol";

import {BaseConnextFacet} from "./BaseConnextFacet.sol";

/**
 * @title SwapAdminFacet
 * @notice Contract module which exposes only-admin controls for the StableSwapFacet
 * contract.
 *
 * @dev This module is used through inheritance. It will make available the
 * modifier `onlyOwner`, which can be applied to your functions to restrict
 * their use to the owner.
 */
contract SwapAdminFacet is BaseConnextFacet {
  using SafeERC20 for IERC20;
  using SwapUtils for SwapUtils.Swap;
  using AmplificationUtils for SwapUtils.Swap;

  // ========== Custom Errors ===========
  error SwapAdminFacet__initializeSwap_alreadyInitialized();
  error SwapAdminFacet__initializeSwap_invalidPooledTokens();
  error SwapAdminFacet__initializeSwap_decimalsMismatch();
  error SwapAdminFacet__initializeSwap_duplicateTokens();
  error SwapAdminFacet__initializeSwap_zeroTokenAddress();
  error SwapAdminFacet__initializeSwap_tokenDecimalsExceedMax();
  error SwapAdminFacet__initializeSwap_aExceedMax();
  error SwapAdminFacet__initializeSwap_feeExceedMax();
  error SwapAdminFacet__initializeSwap_adminFeeExceedMax();
  error SwapAdminFacet__initializeSwap_failedInitLpTokenClone();
  error SwapAdminFacet__updateLpTokenTarget_invalidNewAddress();
  error SwapAdminFacet__removeSwap_notInitialized();
  error SwapAdminFacet__removeSwap_notDisabledPool();
  error SwapAdminFacet__removeSwap_delayNotElapsed();
  error SwapAdminFacet__disableSwap_notInitialized();
  error SwapAdminFacet__disableSwap_alreadyDisabled();

  // ============ Properties ============

  // ============ Events ============

  /**
   * @notice Emitted when the owner calls `initializeSwap`
   * @param key - Identifier for asset
   * @param swap - The swap that was initialized
   * @param caller - The caller of the function
   */
  event SwapInitialized(bytes32 indexed key, SwapUtils.Swap swap, address caller);

  /**
   * @notice Emitted when the owner calls `removeSwap`
   * @param key - Identifier for asset
   * @param caller - The caller of the function
   */
  event SwapRemoved(bytes32 indexed key, address caller);

  /**
   * @notice Emitted when the owner calls `disableSwap`
   * @param key - Identifier for asset
   * @param caller - The caller of the function
   */
  event SwapDisabled(bytes32 indexed key, address caller);

  /**
   * @notice Emitted when the owner withdraws admin fees
   * @param key - Identifier for asset
   * @param caller - The caller of the function
   */
  event AdminFeesWithdrawn(bytes32 indexed key, address caller);

  /**
   * @notice Emitted when the owner sets admin fees
   * @param key - Identifier for asset
   * @param newAdminFee - The updated fee
   * @param caller - The caller of the function
   */
  event AdminFeesSet(bytes32 indexed key, uint256 newAdminFee, address caller);

  /**
   * @notice Emitted when the owner sets swap fees
   * @param key - Identifier for asset
   * @param newSwapFee - The updated fee
   * @param caller - The caller of the function
   */
  event SwapFeesSet(bytes32 indexed key, uint256 newSwapFee, address caller);

  /**
   * @notice Emitted when the owner starts ramping up or down the A parameter
   * @param key - Identifier for asset
   * @param futureA - The final A value after ramp
   * @param futureTime - The time A should reach the final value
   * @param caller - The caller of the function
   */
  event RampAStarted(bytes32 indexed key, uint256 futureA, uint256 futureTime, address caller);

  /**
   * @notice Emitted when the owner stops ramping up or down the A parameter
   * @param key - Identifier for asset
   * @param caller - The caller of the function
   */
  event RampAStopped(bytes32 indexed key, address caller);

  /**
   * @notice Emitted when the owner update lpTokenTargetAddress
   * @param oldAddress - The old lpTokenTargetAddress
   * @param newAddress - Updated address
   * @param caller - The caller of the function
   */
  event LPTokenTargetUpdated(address oldAddress, address newAddress, address caller);

  // ============ External: Getters ============
  /**
   * @notice Returns the lp target token address
   * @return address
   */
  function lpTokenTargetAddress() public view returns (address) {
    return s.lpTokenTargetAddress;
  }

  /**
   * @notice Return if the pool is disabled
   * @param key Hash of the canonical id + domain
   * @return disabled flag
   */
  function isDisabled(bytes32 key) external view returns (bool) {
    return s.swapStorages[key].disabled;
  }

  /*** StableSwap ADMIN FUNCTIONS ***/
  /**
   * @notice Initializes this Swap contract with the given parameters.
   * This will also clone a LPToken contract that represents users'
   * LP positions. The owner of LPToken will be this contract - which means
   * only this contract is allowed to mint/burn tokens.
   *
   * @dev The swap can only be updated after initialization via `rampA`. This means
   * if this value is incorrectly set, it will take some time to reach the
   * correct value.
   *
   * @param _key the hash of the canonical id and domain for token
   * @param _pooledTokens an array of ERC20s this pool will accept.
   * length of this array should be in 2 ~ 16
   * @param decimals the decimals to use for each pooled token,
   * eg 8 for WBTC. Cannot be larger than POOL_PRECISION_DECIMALS(18)
   * Only fixed decimal tokens are allowed.
   * @param lpTokenName the long-form name of the token to be deployed
   * @param lpTokenSymbol the short symbol for the token to be deployed
   * @param _a the amplification coefficient * n ** (n - 1). See the
   * StableSwap paper for details
   * @param _fee default swap fee to be initialized with
   * @param _adminFee default adminFee to be initialized with
   */
  function initializeSwap(
    bytes32 _key,
    IERC20[] memory _pooledTokens,
    uint8[] memory decimals,
    string memory lpTokenName,
    string memory lpTokenSymbol,
    uint256 _a,
    uint256 _fee,
    uint256 _adminFee
  ) external onlyOwnerOrAdmin {
    if (s.swapStorages[_key].pooledTokens.length != 0) revert SwapAdminFacet__initializeSwap_alreadyInitialized();

    // Check _pooledTokens and precisions parameter
    if (
      _pooledTokens.length < Constants.MINIMUM_POOLED_TOKENS || _pooledTokens.length > Constants.MAXIMUM_POOLED_TOKENS
    ) {
      revert SwapAdminFacet__initializeSwap_invalidPooledTokens();
    }

    uint256 numPooledTokens = _pooledTokens.length;

    if (numPooledTokens != decimals.length) revert SwapAdminFacet__initializeSwap_decimalsMismatch();

    uint256[] memory precisionMultipliers = new uint256[](decimals.length);

    for (uint256 i; i < numPooledTokens; ) {
      if (i != 0) {
        // Check if index is already used. Check if 0th element is a duplicate.
        if (s.tokenIndexes[_key][address(_pooledTokens[i])] != 0 || _pooledTokens[0] == _pooledTokens[i])
          revert SwapAdminFacet__initializeSwap_duplicateTokens();
      }
      if (address(_pooledTokens[i]) == address(0)) revert SwapAdminFacet__initializeSwap_zeroTokenAddress();

      if (decimals[i] > Constants.POOL_PRECISION_DECIMALS)
        revert SwapAdminFacet__initializeSwap_tokenDecimalsExceedMax();

      precisionMultipliers[i] = 10**uint256(Constants.POOL_PRECISION_DECIMALS - decimals[i]);
      // NOTE: safe to cast to uint8 as the numPooledTokens is that type and the loop ceiling
      s.tokenIndexes[_key][address(_pooledTokens[i])] = uint8(i);

      unchecked {
        ++i;
      }
    }

    // Check _a, _fee, _adminFee, _withdrawFee parameters
    if (_a > Constants.MAX_A - 1) revert SwapAdminFacet__initializeSwap_aExceedMax();
    if (_fee > Constants.MAX_SWAP_FEE - 1) revert SwapAdminFacet__initializeSwap_feeExceedMax();
    if (_adminFee > Constants.MAX_ADMIN_FEE - 1) revert SwapAdminFacet__initializeSwap_adminFeeExceedMax();

    // Initialize a LPToken contract
    LPToken lpToken = LPToken(Clones.clone(s.lpTokenTargetAddress));
    if (!lpToken.initialize(lpTokenName, lpTokenSymbol)) revert SwapAdminFacet__initializeSwap_failedInitLpTokenClone();

    // Initialize swapStorage struct
    SwapUtils.Swap memory entry = SwapUtils.Swap({
      key: _key,
      initialA: _a * Constants.A_PRECISION,
      futureA: _a * Constants.A_PRECISION,
      swapFee: _fee,
      adminFee: _adminFee,
      lpToken: lpToken,
      pooledTokens: _pooledTokens,
      tokenPrecisionMultipliers: precisionMultipliers,
      balances: new uint256[](_pooledTokens.length),
      adminFees: new uint256[](_pooledTokens.length),
      initialATime: 0,
      futureATime: 0,
      disabled: false,
      removeTime: 0
    });
    s.swapStorages[_key] = entry;
    emit SwapInitialized(_key, entry, msg.sender);
  }

  /**
   * @notice disable swap for key
   *
   * @param _key the hash of the canonical id and domain for token
   */
  function disableSwap(bytes32 _key) external onlyOwnerOrAdmin {
    uint256 numPooledTokens = s.swapStorages[_key].pooledTokens.length;

    if (numPooledTokens == 0) revert SwapAdminFacet__disableSwap_notInitialized();
    if (s.swapStorages[_key].disabled) revert SwapAdminFacet__disableSwap_alreadyDisabled();

    s.swapStorages[_key].disabled = true;
    s.swapStorages[_key].removeTime = block.timestamp + Constants.REMOVE_DELAY;

    emit SwapDisabled(_key, msg.sender);
  }

  /**
   * @notice remove Swap Struct for key
   *
   * @param _key the hash of the canonical id and domain for token
   */
  function removeSwap(bytes32 _key) external onlyOwnerOrAdmin {
    uint256 numPooledTokens = s.swapStorages[_key].pooledTokens.length;
    if (numPooledTokens == 0) revert SwapAdminFacet__removeSwap_notInitialized();

    if (!s.swapStorages[_key].disabled) revert SwapAdminFacet__removeSwap_notDisabledPool();
    if (s.swapStorages[_key].removeTime > block.timestamp) revert SwapAdminFacet__removeSwap_delayNotElapsed();

    for (uint256 i; i < numPooledTokens; ) {
      IERC20 pooledToken = s.swapStorages[_key].pooledTokens[i];
      if (s.swapStorages[_key].balances[i] > 0) {
        // if there is not removed balance, transfer to admin wallet.
        pooledToken.safeTransfer(msg.sender, s.swapStorages[_key].balances[i]);
      }

      delete s.tokenIndexes[_key][address(pooledToken)];

      unchecked {
        ++i;
      }
    }

    _withdrawAdminFees(_key, msg.sender);

    delete s.swapStorages[_key];

    emit SwapRemoved(_key, msg.sender);
  }

  /**
   * @notice Withdraw all admin fees to the contract owner
   * @param key Hash of the canonical domain and id
   */
  function withdrawSwapAdminFees(bytes32 key) external onlyOwnerOrAdmin nonReentrant {
    _withdrawAdminFees(key, msg.sender);
  }

  /**
   * @notice Withdraws all admin fees for pool at key to provided address and emits event
   * @param _key Hash of the canonical domain and id
   * @param _to Recipient of fees
   */
  function _withdrawAdminFees(bytes32 _key, address _to) internal {
    s.swapStorages[_key].withdrawAdminFees(_to);
    emit AdminFeesWithdrawn(_key, _to);
  }

  /**
   * @notice Update the admin fee. Admin fee takes portion of the swap fee.
   * @param key Hash of the canonical domain and id
   * @param newAdminFee new admin fee to be applied on future transactions
   */
  function setSwapAdminFee(bytes32 key, uint256 newAdminFee) external onlyOwnerOrAdmin {
    s.swapStorages[key].setAdminFee(newAdminFee);
    emit AdminFeesSet(key, newAdminFee, msg.sender);
  }

  /**
   * @notice Update the swap fee to be applied on swaps
   * @param key Hash of the canonical domain and id
   * @param newSwapFee new swap fee to be applied on future transactions
   */
  function setSwapFee(bytes32 key, uint256 newSwapFee) external onlyOwnerOrAdmin {
    s.swapStorages[key].setSwapFee(newSwapFee);
    emit SwapFeesSet(key, newSwapFee, msg.sender);
  }

  /**
   * @notice Start ramping up or down A parameter towards given futureA and futureTime
   * Checks if the change is too rapid, and commits the new A value only when it falls under
   * the limit range.
   * @param key Hash of the canonical domain and id
   * @param futureA the new A to ramp towards
   * @param futureTime timestamp when the new A should be reached
   */
  function rampA(
    bytes32 key,
    uint256 futureA,
    uint256 futureTime
  ) external onlyOwnerOrAdmin {
    s.swapStorages[key].rampA(futureA, futureTime);
    emit RampAStarted(key, futureA, futureTime, msg.sender);
  }

  /**
   * @notice Stop ramping A immediately. Reverts if ramp A is already stopped.
   * @param key Hash of the canonical domain and id
   */
  function stopRampA(bytes32 key) external onlyOwnerOrAdmin {
    s.swapStorages[key].stopRampA();
    emit RampAStopped(key, msg.sender);
  }

  /**
   * @notice Update lpTokenTargetAddress
   * @param newAddress New lpTokenTargetAddress
   */
  function updateLpTokenTarget(address newAddress) external onlyOwnerOrAdmin {
    if (!Address.isContract(newAddress)) revert SwapAdminFacet__updateLpTokenTarget_invalidNewAddress();
    emit LPTokenTargetUpdated(s.lpTokenTargetAddress, newAddress, msg.sender);
    s.lpTokenTargetAddress = newAddress;
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/**
 * @title Liquidity Provider Token
 * @notice This token is an ERC20 detailed token with added capability to be minted by the owner.
 * It is used to represent user's shares when providing liquidity to swap contracts.
 * @dev Only Swap contracts should initialize and own LPToken contracts.
 */
contract LPToken is ERC20Upgradeable, OwnableUpgradeable {
  // ============ Storage ============

  // ============ Initializer ============

  /**
   * @notice Initializes this LPToken contract with the given name and symbol
   * @dev The caller of this function will become the owner. A Swap contract should call this
   * in its initializer function.
   * @param name name of this token
   * @param symbol symbol of this token
   */
  function initialize(string memory name, string memory symbol) external initializer returns (bool) {
    __Context_init_unchained();
    __ERC20_init_unchained(name, symbol);
    __Ownable_init_unchained();
    return true;
  }

  // ============ External functions ============

  /**
   * @notice Mints the given amount of LPToken to the recipient.
   * @dev only owner can call this mint function
   * @param recipient address of account to receive the tokens
   * @param amount amount of tokens to mint
   */
  function mint(address recipient, uint256 amount) external onlyOwner {
    require(amount != 0, "LPToken: cannot mint 0");
    _mint(recipient, amount);
  }

  /**
   * @notice Burns the given amount of LPToken from provided account
   * @dev only owner can call this burn function
   * @param account address of account from which to burn token
   * @param amount amount of tokens to mint
   */
  function burnFrom(address account, uint256 amount) external onlyOwner {
    require(amount != 0, "LPToken: cannot burn 0");
    _burn(account, amount);
  }

  // ============ Internal functions ============

  /**
   * @dev Overrides ERC20._beforeTokenTransfer() which get called on every transfers including
   * minting and burning. This ensures that Swap.updateUserWithdrawFees are called everytime.
   * This assumes the owner is set to a Swap contract's address.
   */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual override(ERC20Upgradeable) {
    super._beforeTokenTransfer(from, to, amount);
    require(to != address(this), "LPToken: cannot send to itself");
  }

  // ============ Upgrade Gap ============
  uint256[50] private __GAP; // gap for upgrade safety
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

interface IDiamondCut {
  enum FacetCutAction {
    Add,
    Replace,
    Remove
  }
  // Add=0, Replace=1, Remove=2

  struct FacetCut {
    address facetAddress;
    FacetCutAction action;
    bytes4[] functionSelectors;
  }

  /// @notice Propose to add/replace/remove any number of functions and optionally execute
  ///         a function with delegatecall
  /// @param _diamondCut Contains the facet addresses and function selectors
  /// @param _init The address of the contract or facet to execute _calldata
  /// @param _calldata A function call, including function selector and arguments
  ///                  _calldata is executed with delegatecall on _init
  function proposeDiamondCut(
    FacetCut[] calldata _diamondCut,
    address _init,
    bytes calldata _calldata
  ) external;

  event DiamondCutProposed(FacetCut[] _diamondCut, address _init, bytes _calldata, uint256 deadline);

  /// @notice Add/replace/remove any number of functions and optionally execute
  ///         a function with delegatecall
  /// @param _diamondCut Contains the facet addresses and function selectors
  /// @param _init The address of the contract or facet to execute _calldata
  /// @param _calldata A function call, including function selector and arguments
  ///                  _calldata is executed with delegatecall on _init
  function diamondCut(
    FacetCut[] calldata _diamondCut,
    address _init,
    bytes calldata _calldata
  ) external;

  event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);

  /// @notice Propose to add/replace/remove any number of functions and optionally execute
  ///         a function with delegatecall
  /// @param _diamondCut Contains the facet addresses and function selectors
  /// @param _init The address of the contract or facet to execute _calldata
  /// @param _calldata A function call, including function selector and arguments
  ///                  _calldata is executed with delegatecall on _init
  function rescindDiamondCut(
    FacetCut[] calldata _diamondCut,
    address _init,
    bytes calldata _calldata
  ) external;

  /**
   * @notice Returns the acceptance time for a given proposal
   * @param _diamondCut Contains the facet addresses and function selectors
   * @param _init The address of the contract or facet to execute _calldata
   * @param _calldata A function call, including function selector and arguments _calldata is
   * executed with delegatecall on _init
   */
  function getAcceptanceTime(
    FacetCut[] calldata _diamondCut,
    address _init,
    bytes calldata _calldata
  ) external returns (uint256);

  event DiamondCutRescinded(FacetCut[] _diamondCut, address _init, bytes _calldata);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IStableSwap {
  /*** EVENTS ***/

  // events replicated from SwapUtils to make the ABI easier for dumb
  // clients
  event TokenSwap(address indexed buyer, uint256 tokensSold, uint256 tokensBought, uint128 soldId, uint128 boughtId);
  event AddLiquidity(
    address indexed provider,
    uint256[] tokenAmounts,
    uint256[] fees,
    uint256 invariant,
    uint256 lpTokenSupply
  );
  event RemoveLiquidity(address indexed provider, uint256[] tokenAmounts, uint256 lpTokenSupply);
  event RemoveLiquidityOne(
    address indexed provider,
    uint256 lpTokenAmount,
    uint256 lpTokenSupply,
    uint256 boughtId,
    uint256 tokensBought
  );
  event RemoveLiquidityImbalance(
    address indexed provider,
    uint256[] tokenAmounts,
    uint256[] fees,
    uint256 invariant,
    uint256 lpTokenSupply
  );
  event NewAdminFee(uint256 newAdminFee);
  event NewSwapFee(uint256 newSwapFee);
  event NewWithdrawFee(uint256 newWithdrawFee);
  event RampA(uint256 oldA, uint256 newA, uint256 initialTime, uint256 futureTime);
  event StopRampA(uint256 currentA, uint256 time);

  function swap(
    uint8 tokenIndexFrom,
    uint8 tokenIndexTo,
    uint256 dx,
    uint256 minDy,
    uint256 deadline
  ) external returns (uint256);

  function swapExact(
    uint256 amountIn,
    address assetIn,
    address assetOut,
    uint256 minAmountOut,
    uint256 deadline
  ) external payable returns (uint256);

  function swapExactOut(
    uint256 amountOut,
    address assetIn,
    address assetOut,
    uint256 maxAmountIn,
    uint256 deadline
  ) external payable returns (uint256);

  function getA() external view returns (uint256);

  function getToken(uint8 index) external view returns (IERC20);

  function getTokenIndex(address tokenAddress) external view returns (uint8);

  function getTokenBalance(uint8 index) external view returns (uint256);

  function getVirtualPrice() external view returns (uint256);

  // min return calculation functions
  function calculateSwap(
    uint8 tokenIndexFrom,
    uint8 tokenIndexTo,
    uint256 dx
  ) external view returns (uint256);

  function calculateSwapOut(
    uint8 tokenIndexFrom,
    uint8 tokenIndexTo,
    uint256 dy
  ) external view returns (uint256);

  function calculateSwapFromAddress(
    address assetIn,
    address assetOut,
    uint256 amountIn
  ) external view returns (uint256);

  function calculateSwapOutFromAddress(
    address assetIn,
    address assetOut,
    uint256 amountOut
  ) external view returns (uint256);

  function calculateTokenAmount(uint256[] calldata amounts, bool deposit) external view returns (uint256);

  function calculateRemoveLiquidity(uint256 amount) external view returns (uint256[] memory);

  function calculateRemoveLiquidityOneToken(uint256 tokenAmount, uint8 tokenIndex)
    external
    view
    returns (uint256 availableTokenAmount);

  // state modifying functions
  function initialize(
    IERC20[] memory pooledTokens,
    uint8[] memory decimals,
    string memory lpTokenName,
    string memory lpTokenSymbol,
    uint256 a,
    uint256 fee,
    uint256 adminFee,
    address lpTokenTargetAddress
  ) external;

  function addLiquidity(
    uint256[] calldata amounts,
    uint256 minToMint,
    uint256 deadline
  ) external returns (uint256);

  function removeLiquidity(
    uint256 amount,
    uint256[] calldata minAmounts,
    uint256 deadline
  ) external returns (uint256[] memory);

  function removeLiquidityOneToken(
    uint256 tokenAmount,
    uint8 tokenIndex,
    uint256 minAmount,
    uint256 deadline
  ) external returns (uint256);

  function removeLiquidityImbalance(
    uint256[] calldata amounts,
    uint256 maxBurnAmount,
    uint256 deadline
  ) external returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import {SwapUtils} from "./SwapUtils.sol";
import {Constants} from "./Constants.sol";

/**
 * @title AmplificationUtils library
 * @notice A library to calculate and ramp the A parameter of a given `SwapUtils.Swap` struct.
 * This library assumes the struct is fully validated.
 */
library AmplificationUtils {
  event RampA(uint256 oldA, uint256 newA, uint256 initialTime, uint256 futureTime);
  event StopRampA(uint256 currentA, uint256 time);

  /**
   * @notice Return A, the amplification coefficient * n ** (n - 1)
   * @dev See the StableSwap paper for details
   * @param self Swap struct to read from
   * @return A parameter
   */
  function getA(SwapUtils.Swap storage self) internal view returns (uint256) {
    return _getAPrecise(self) / Constants.A_PRECISION;
  }

  /**
   * @notice Return A in its raw precision
   * @dev See the StableSwap paper for details
   * @param self Swap struct to read from
   * @return A parameter in its raw precision form
   */
  function getAPrecise(SwapUtils.Swap storage self) internal view returns (uint256) {
    return _getAPrecise(self);
  }

  /**
   * @notice Return A in its raw precision
   * @dev See the StableSwap paper for details
   * @param self Swap struct to read from
   * @return currentA A parameter in its raw precision form
   */
  function _getAPrecise(SwapUtils.Swap storage self) internal view returns (uint256 currentA) {
    uint256 t1 = self.futureATime; // time when ramp is finished
    currentA = self.futureA; // final A value when ramp is finished
    uint256 a0 = self.initialA; // initial A value when ramp is started

    if (a0 != currentA && block.timestamp < t1) {
      uint256 t0 = self.initialATime; // time when ramp is started
      assembly {
        currentA := div(add(mul(a0, sub(t1, timestamp())), mul(currentA, sub(timestamp(), t0))), sub(t1, t0))
      }
    }
  }

  /**
   * @notice Start ramping up or down A parameter towards given futureA_ and futureTime_
   * Checks if the change is too rapid, and commits the new A value only when it falls under
   * the limit range.
   * @param self Swap struct to update
   * @param futureA_ the new A to ramp towards
   * @param futureTime_ timestamp when the new A should be reached
   */
  function rampA(
    SwapUtils.Swap storage self,
    uint256 futureA_,
    uint256 futureTime_
  ) internal {
    require(block.timestamp >= self.initialATime + Constants.MIN_RAMP_DELAY, "Wait 1 day before starting ramp");
    require(futureTime_ >= block.timestamp + Constants.MIN_RAMP_TIME, "Insufficient ramp time");
    require(futureA_ != 0 && futureA_ < Constants.MAX_A, "futureA_ must be > 0 and < MAX_A");

    uint256 initialAPrecise = _getAPrecise(self);
    uint256 futureAPrecise = futureA_ * Constants.A_PRECISION;
    require(initialAPrecise != futureAPrecise, "!valid ramp");

    if (futureAPrecise < initialAPrecise) {
      require(futureAPrecise * Constants.MAX_A_CHANGE >= initialAPrecise, "futureA_ is too small");
    } else {
      require(futureAPrecise <= initialAPrecise * Constants.MAX_A_CHANGE, "futureA_ is too large");
    }

    self.initialA = initialAPrecise;
    self.futureA = futureAPrecise;
    self.initialATime = block.timestamp;
    self.futureATime = futureTime_;

    emit RampA(initialAPrecise, futureAPrecise, block.timestamp, futureTime_);
  }

  /**
   * @notice Stops ramping A immediately. Once this function is called, rampA()
   * cannot be called for another 24 hours
   * @param self Swap struct to update
   */
  function stopRampA(SwapUtils.Swap storage self) internal {
    require(self.futureATime > block.timestamp, "Ramp is already stopped");

    uint256 currentA = _getAPrecise(self);
    self.initialA = currentA;
    self.futureA = currentA;
    self.initialATime = block.timestamp;
    self.futureATime = block.timestamp;

    emit StopRampA(currentA, block.timestamp);
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import {TypeCasts} from "../../../shared/libraries/TypeCasts.sol";

import {IStableSwap} from "../interfaces/IStableSwap.sol";

import {LibConnextStorage, AppStorage, TokenConfig} from "./LibConnextStorage.sol";
import {SwapUtils} from "./SwapUtils.sol";
import {Constants} from "./Constants.sol";
import {TokenId} from "./TokenId.sol";

library AssetLogic {
  // ============ Libraries ============

  using SwapUtils for SwapUtils.Swap;
  using SafeERC20 for IERC20Metadata;

  // ============ Errors ============

  error AssetLogic__handleIncomingAsset_nativeAssetNotSupported();
  error AssetLogic__handleIncomingAsset_feeOnTransferNotSupported();
  error AssetLogic__handleOutgoingAsset_notNative();
  error AssetLogic__getTokenIndexFromStableSwapPool_notExist();
  error AssetLogic__getConfig_notRegistered();
  error AssetLogic__swapAsset_externalStableSwapPoolDoesNotExist();

  // ============ Internal: Handle Transfer ============

  function getConfig(bytes32 _key) internal view returns (TokenConfig storage) {
    AppStorage storage s = LibConnextStorage.connextStorage();
    TokenConfig storage config = s.tokenConfigs[_key];

    // Sanity check: not empty
    // NOTE: adopted decimals will *always* be nonzero (or reflect what is onchain
    // for the asset). The same is not true for the representation assets, which
    // will always have 0 decimals on the canonical domain
    if (config.adoptedDecimals < 1) {
      revert AssetLogic__getConfig_notRegistered();
    }

    return config;
  }

  /**
   * @notice Handles transferring funds from msg.sender to the Connext contract.
   * @dev Does NOT work with fee-on-transfer tokens: will revert.
   *
   * @param _asset - The address of the ERC20 token to transfer.
   * @param _amount - The specified amount to transfer.
   */
  function handleIncomingAsset(address _asset, uint256 _amount) internal {
    // Sanity check: if amount is 0, do nothing.
    if (_amount == 0) {
      return;
    }
    // Sanity check: asset address is not zero.
    if (_asset == address(0)) {
      revert AssetLogic__handleIncomingAsset_nativeAssetNotSupported();
    }

    IERC20Metadata asset = IERC20Metadata(_asset);

    // Record starting amount to validate correct amount is transferred.
    uint256 starting = asset.balanceOf(address(this));

    // Transfer asset to contract.
    asset.safeTransferFrom(msg.sender, address(this), _amount);

    // Ensure correct amount was transferred (i.e. this was not a fee-on-transfer token).
    if (asset.balanceOf(address(this)) - starting != _amount) {
      revert AssetLogic__handleIncomingAsset_feeOnTransferNotSupported();
    }
  }

  /**
   * @notice Handles transferring funds from the Connext contract to a specified address
   * @param _asset - The address of the ERC20 token to transfer.
   * @param _to - The recipient address that will receive the funds.
   * @param _amount - The amount to withdraw from contract.
   */
  function handleOutgoingAsset(
    address _asset,
    address _to,
    uint256 _amount
  ) internal {
    // Sanity check: if amount is 0, do nothing.
    if (_amount == 0) {
      return;
    }
    // Sanity check: asset address is not zero.
    if (_asset == address(0)) revert AssetLogic__handleOutgoingAsset_notNative();

    // Transfer ERC20 asset to target recipient.
    SafeERC20.safeTransfer(IERC20Metadata(_asset), _to, _amount);
  }

  // ============ Internal: StableSwap Pools ============

  /**
   * @notice Return the index of the given token address. Reverts if no matching
   * token is found.
   * @param key the hash of the canonical id and domain
   * @param tokenAddress address of the token
   * @return the index of the given token address
   */
  function getTokenIndexFromStableSwapPool(bytes32 key, address tokenAddress) internal view returns (uint8) {
    AppStorage storage s = LibConnextStorage.connextStorage();
    uint8 index = s.tokenIndexes[key][tokenAddress];
    if (address(s.swapStorages[key].pooledTokens[index]) != tokenAddress)
      revert AssetLogic__getTokenIndexFromStableSwapPool_notExist();
    return index;
  }

  // ============ Internal: Handle Swap ============

  /**
   * @notice Swaps an adopted asset to the local (representation or canonical) asset.
   * @dev Will not swap if the asset passed in is the local asset.
   * @param _key - The hash of canonical id and domain.
   * @param _asset - The address of the adopted asset to swap into the local asset.
   * @param _amount - The amount of the adopted asset to swap.
   * @param _slippage - The maximum amount of slippage user will take on from _amount in BPS.
   * @return uint256 The amount of local asset received from swap.
   */
  function swapToLocalAssetIfNeeded(
    bytes32 _key,
    address _asset,
    address _local,
    uint256 _amount,
    uint256 _slippage
  ) internal returns (uint256) {
    // If there's no amount, no need to swap.
    if (_amount == 0) {
      return 0;
    }

    // Check the case where the adopted asset *is* the local asset. If so, no need to swap.
    if (_local == _asset) {
      return _amount;
    }

    // Get the configs.
    TokenConfig storage config = getConfig(_key);

    // Swap the asset to the proper local asset.
    (uint256 out, ) = _swapAsset(
      _key,
      _asset,
      _local,
      _amount,
      calculateSlippageBoundary(config.adoptedDecimals, config.representationDecimals, _amount, _slippage)
    );
    return out;
  }

  /**
   * @notice Swaps a local bridge asset for the adopted asset using the stored stable swap
   * @dev Will not swap if the asset passed in is the adopted asset
   * @param _key the hash of the canonical id and domain
   * @param _asset - The address of the local asset to swap into the adopted asset
   * @param _amount - The amount of the local asset to swap
   * @param _slippage - The minimum amount of slippage user will take on from _amount in BPS
   * @param _normalizedIn - The amount sent in on xcall to take the slippage from, in 18 decimals
   * by convention
   * @return The amount of adopted asset received from swap
   * @return The address of asset received post-swap
   */
  function swapFromLocalAssetIfNeeded(
    bytes32 _key,
    address _asset,
    uint256 _amount,
    uint256 _slippage,
    uint256 _normalizedIn
  ) internal returns (uint256, address) {
    // Get the token config.
    TokenConfig storage config = getConfig(_key);
    address adopted = config.adopted;

    // If the adopted asset is the local asset, no need to swap.
    if (adopted == _asset) {
      return (_amount, adopted);
    }

    // If there's no amount, no need to swap.
    if (_amount == 0) {
      return (_amount, adopted);
    }

    // Swap the asset to the proper local asset
    return
      _swapAsset(
        _key,
        _asset,
        adopted,
        _amount,
        // NOTE: To get the slippage boundary here, you must take the slippage % off of the
        // normalized amount in (at 18 decimals by convention), then convert that amount
        // to the proper decimals of adopted.
        calculateSlippageBoundary(
          Constants.DEFAULT_NORMALIZED_DECIMALS,
          config.adoptedDecimals,
          _normalizedIn,
          _slippage
        )
      );
  }

  /**
   * @notice Swaps a local bridge asset for the adopted asset using the stored stable swap
   * @dev Will not swap if the asset passed in is the adopted asset
   * @param _key the hash of the canonical id and domain
   * @param _asset - The address of the local asset to swap into the adopted asset
   * @param _amount - The exact amount to receive out of the swap
   * @param _maxIn - The most you will supply to the swap
   * @return The amount of local asset put into  swap
   * @return The address of asset received post-swap
   */
  function swapFromLocalAssetIfNeededForExactOut(
    bytes32 _key,
    address _asset,
    uint256 _amount,
    uint256 _maxIn
  ) internal returns (uint256, address) {
    TokenConfig storage config = getConfig(_key);

    // If the adopted asset is the local asset, no need to swap.
    address adopted = config.adopted;
    if (adopted == _asset) {
      return (_amount, adopted);
    }

    return _swapAssetOut(_key, _asset, adopted, _amount, _maxIn);
  }

  /**
   * @notice Swaps assetIn to assetOut using the stored stable swap or internal swap pool.
   * @dev Will not swap if the asset passed in is the adopted asset
   * @param _key - The hash of canonical id and domain.
   * @param _assetIn - The address of the from asset
   * @param _assetOut - The address of the to asset
   * @param _amount - The amount of the local asset to swap
   * @param _minOut - The minimum amount of `_assetOut` the user will accept
   * @return The amount of asset received
   * @return The address of asset received
   */
  function _swapAsset(
    bytes32 _key,
    address _assetIn,
    address _assetOut,
    uint256 _amount,
    uint256 _minOut
  ) internal returns (uint256, address) {
    AppStorage storage s = LibConnextStorage.connextStorage();

    // Retrieve internal swap pool reference.
    SwapUtils.Swap storage ipool = s.swapStorages[_key];

    if (ipool.exists()) {
      // Swap via the internal pool.
      return (
        ipool.swapInternal(
          getTokenIndexFromStableSwapPool(_key, _assetIn),
          getTokenIndexFromStableSwapPool(_key, _assetOut),
          _amount,
          _minOut
        ),
        _assetOut
      );
    } else {
      // Otherwise, swap via external stableswap pool.
      IStableSwap pool = IStableSwap(getConfig(_key).adoptedToLocalExternalPools);

      IERC20Metadata assetIn = IERC20Metadata(_assetIn);

      assetIn.safeApprove(address(pool), 0);
      assetIn.safeIncreaseAllowance(address(pool), _amount);

      // NOTE: If pool is not registered here, then this call will revert.
      return (
        pool.swapExact(_amount, _assetIn, _assetOut, _minOut, block.timestamp + Constants.DEFAULT_DEADLINE_EXTENSION),
        _assetOut
      );
    }
  }

  /**
   * @notice Swaps assetIn to assetOut using the stored stable swap or internal swap pool.
   * @param _key - The hash of the canonical id and domain.
   * @param _assetIn - The address of the from asset.
   * @param _assetOut - The address of the to asset.
   * @param _amountOut - The amount of the _assetOut to swap.
   * @param _maxIn - The most you will supply to the swap.
   * @return amountIn The amount of assetIn. Will be 0 if the swap was unsuccessful (slippage
   * too high).
   * @return assetOut The address of asset received.
   */
  function _swapAssetOut(
    bytes32 _key,
    address _assetIn,
    address _assetOut,
    uint256 _amountOut,
    uint256 _maxIn
  ) internal returns (uint256, address) {
    AppStorage storage s = LibConnextStorage.connextStorage();

    // Retrieve internal swap pool reference. If it doesn't exist, we'll resort to using an
    // external stableswap below.
    SwapUtils.Swap storage ipool = s.swapStorages[_key];

    // Swap the asset to the proper local asset.
    // NOTE: IFF slippage was too high to perform swap in either case: success = false, amountIn = 0
    if (ipool.exists()) {
      // Swap via the internal pool.
      return (
        ipool.swapInternalOut(
          getTokenIndexFromStableSwapPool(_key, _assetIn),
          getTokenIndexFromStableSwapPool(_key, _assetOut),
          _amountOut,
          _maxIn
        ),
        _assetOut
      );
    } else {
      // Otherwise, swap via external stableswap pool.
      // NOTE: This call will revert if the external stableswap pool doesn't exist.
      IStableSwap pool = IStableSwap(getConfig(_key).adoptedToLocalExternalPools);
      address poolAddress = address(pool);

      // Perform the swap.
      // Edge case with some tokens: Example USDT in ETH Mainnet, after the backUnbacked call
      // there could be a remaining allowance if not the whole amount is pulled by aave.
      // Later, if we try to increase the allowance it will fail. USDT demands if allowance
      // is not 0, it has to be set to 0 first.
      // Example: https://github.com/aave/aave-v3-periphery/blob/ca184e5278bcbc10d28c3dbbc604041d7cfac50b/contracts/adapters/paraswap/ParaSwapRepayAdapter.sol#L138-L140
      IERC20Metadata assetIn = IERC20Metadata(_assetIn);

      assetIn.safeApprove(poolAddress, 0);
      assetIn.safeIncreaseAllowance(poolAddress, _maxIn);

      uint256 out = pool.swapExactOut(
        _amountOut,
        _assetIn,
        _assetOut,
        _maxIn,
        block.timestamp + Constants.DEFAULT_DEADLINE_EXTENSION
      );

      // Reset allowance
      assetIn.safeApprove(poolAddress, 0);
      return (out, _assetOut);
    }
  }

  /**
   * @notice Calculate amount of tokens you receive on a local bridge asset for the adopted asset
   * using the stored stable swap
   * @dev Will not use the stored stable swap if the asset passed in is the local asset
   * @param _key - The hash of the canonical id and domain
   * @param _asset - The address of the local asset to swap into the local asset
   * @param _amount - The amount of the local asset to swap
   * @return The amount of local asset received from swap
   * @return The address of asset received post-swap
   */
  function calculateSwapFromLocalAssetIfNeeded(
    bytes32 _key,
    address _asset,
    uint256 _amount
  ) internal view returns (uint256, address) {
    AppStorage storage s = LibConnextStorage.connextStorage();

    // If the adopted asset is the local asset, no need to swap.
    TokenConfig storage config = getConfig(_key);
    address adopted = config.adopted;
    if (adopted == _asset) {
      return (_amount, adopted);
    }

    SwapUtils.Swap storage ipool = s.swapStorages[_key];

    // Calculate the swap using the appropriate pool.
    if (ipool.exists()) {
      // Calculate with internal swap pool.
      uint8 tokenIndexIn = getTokenIndexFromStableSwapPool(_key, _asset);
      uint8 tokenIndexOut = getTokenIndexFromStableSwapPool(_key, adopted);
      return (ipool.calculateSwap(tokenIndexIn, tokenIndexOut, _amount), adopted);
    } else {
      // Otherwise, try to calculate with external pool.
      IStableSwap pool = IStableSwap(config.adoptedToLocalExternalPools);
      // NOTE: This call will revert if no external pool exists.
      return (pool.calculateSwapFromAddress(_asset, adopted, _amount), adopted);
    }
  }

  /**
   * @notice Calculate amount of tokens you receive of a local bridge asset for the adopted asset
   * using the stored stable swap
   * @dev Will not use the stored stable swap if the asset passed in is the local asset
   * @param _asset - The address of the asset to swap into the local asset
   * @param _amount - The amount of the asset to swap
   * @return The amount of local asset received from swap
   * @return The address of asset received post-swap
   */
  function calculateSwapToLocalAssetIfNeeded(
    bytes32 _key,
    address _asset,
    address _local,
    uint256 _amount
  ) internal view returns (uint256, address) {
    AppStorage storage s = LibConnextStorage.connextStorage();

    // If the asset is the local asset, no swap needed
    if (_asset == _local) {
      return (_amount, _local);
    }

    SwapUtils.Swap storage ipool = s.swapStorages[_key];

    // Calculate the swap using the appropriate pool.
    if (ipool.exists()) {
      // if internal swap pool exists
      uint8 tokenIndexIn = getTokenIndexFromStableSwapPool(_key, _asset);
      uint8 tokenIndexOut = getTokenIndexFromStableSwapPool(_key, _local);
      return (ipool.calculateSwap(tokenIndexIn, tokenIndexOut, _amount), _local);
    } else {
      IStableSwap pool = IStableSwap(getConfig(_key).adoptedToLocalExternalPools);

      return (pool.calculateSwapFromAddress(_asset, _local, _amount), _local);
    }
  }

  // ============ Internal: Token ID Helpers ============

  /**
   * @notice Gets the canonical information for a given candidate.
   * @dev First checks the `address(0)` convention, then checks if the asset given is the
   * adopted asset, then calculates the local address.
   * @return TokenId The canonical token ID information for the given candidate.
   */
  function getCanonicalTokenId(address _candidate, AppStorage storage s) internal view returns (TokenId memory) {
    TokenId memory _canonical;
    // If candidate is address(0), return an empty `_canonical`.
    if (_candidate == address(0)) {
      return _canonical;
    }

    // Check to see if candidate is an adopted asset.
    _canonical = s.adoptedToCanonical[_candidate];
    if (_canonical.domain != 0) {
      // Candidate is an adopted asset, return canonical info.
      return _canonical;
    }

    // Candidate was not adopted; it could be the local address.
    // IFF this domain is the canonical domain, then the local == canonical.
    // Otherwise, it will be the representation asset.
    if (isLocalOrigin(_candidate, s)) {
      // The token originates on this domain, canonical information is the information
      // of the candidate
      _canonical.domain = s.domain;
      _canonical.id = TypeCasts.addressToBytes32(_candidate);
    } else {
      // on a remote domain, return the representation
      _canonical = s.representationToCanonical[_candidate];
    }
    return _canonical;
  }

  /**
   * @notice Determine if token is of local origin (i.e. it is a locally originating contract,
   * and NOT a token deployed by the bridge).
   * @param s AppStorage instance.
   * @return bool true if token is locally originating, false otherwise.
   */
  function isLocalOrigin(address _token, AppStorage storage s) internal view returns (bool) {
    // If the token contract WAS deployed by the bridge, it will be stored in this mapping.
    // If so, the token is NOT of local origin.
    if (s.representationToCanonical[_token].domain != 0) {
      return false;
    }
    // If the contract was NOT deployed by the bridge, but the contract does exist, then it
    // IS of local origin. Returns true if code exists at `_addr`.
    return _token.code.length != 0;
  }

  /**
   * @notice Get the local asset address for a given canonical key, id, and domain.
   * @param _key - The hash of canonical id and domain.
   * @param _id Canonical ID.
   * @param _domain Canonical domain.
   * @param s AppStorage instance.
   * @return address of the the local asset.
   */
  function getLocalAsset(
    bytes32 _key,
    bytes32 _id,
    uint32 _domain,
    AppStorage storage s
  ) internal view returns (address) {
    if (_domain == s.domain) {
      // Token is of local origin
      return TypeCasts.bytes32ToAddress(_id);
    } else {
      // Token is a representation of a token of remote origin
      return getConfig(_key).representation;
    }
  }

  /**
   * @notice Calculates the hash of canonical ID and domain.
   * @dev This hash is used as the key for many asset-related mappings.
   * @param _id Canonical ID.
   * @param _domain Canonical domain.
   * @return bytes32 Canonical hash, used as key for accessing token info from mappings.
   */
  function calculateCanonicalHash(bytes32 _id, uint32 _domain) internal pure returns (bytes32) {
    return keccak256(abi.encode(_id, _domain));
  }

  // ============ Internal: Math ============

  /**
   * @notice This function calculates slippage as a %age of the amount in, and normalizes
   * That to the `_out` decimals.
   *
   * @dev This *ONLY* works for 1:1 assets
   *
   * @param _in The decimals of the asset in / amount in
   * @param _out The decimals of the target asset
   * @param _amountIn The starting amount for the swap
   * @param _slippage The slippage allowed for the swap, in BPS
   * @return uint256 The minimum amount out for the swap
   */
  function calculateSlippageBoundary(
    uint8 _in,
    uint8 _out,
    uint256 _amountIn,
    uint256 _slippage
  ) internal pure returns (uint256) {
    if (_amountIn == 0) {
      return 0;
    }
    // Get the min recieved (in same decimals as _amountIn)
    uint256 min = (_amountIn * (Constants.BPS_FEE_DENOMINATOR - _slippage)) / Constants.BPS_FEE_DENOMINATOR;
    return normalizeDecimals(_in, _out, min);
  }

  /**
   * @notice This function translates the _amount in _in decimals
   * to _out decimals
   *
   * @param _in The decimals of the asset in / amount in
   * @param _out The decimals of the target asset
   * @param _amount The value to normalize to the `_out` decimals
   * @return uint256 Normalized decimals.
   */
  function normalizeDecimals(
    uint8 _in,
    uint8 _out,
    uint256 _amount
  ) internal pure returns (uint256) {
    if (_in == _out) {
      return _amount;
    }
    // Convert this value to the same decimals as _out
    uint256 normalized;
    if (_in < _out) {
      normalized = _amount * (10**(_out - _in));
    } else {
      normalized = _amount / (10**(_in - _out));
    }
    return normalized;
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.17;

library Constants {
  // ============= Initial Values =============

  /**
   * @notice Sets the initial lp fee at 5 bps
   */
  uint256 public constant INITIAL_LIQUIDITY_FEE_NUMERATOR = 9_995;

  /**
   * @notice Sets the initial max routers per transfer
   */
  uint256 public constant INITIAL_MAX_ROUTERS = 5;

  /**
   * @notice Sets the initial max routers per transfer
   */
  uint16 public constant INITIAL_AAVE_REFERRAL_CODE = 0;

  // =============

  // ============= Unchangeable Values =============
  // ============= Facets

  /**
   * @notice Reentrancy modifier for diamond
   */
  uint256 internal constant NOT_ENTERED = 1;

  /**
   * @notice Reentrancy modifier for diamond
   */
  uint256 internal constant ENTERED = 2;

  /**
   * @notice Contains hash of empty bytes
   */
  bytes32 internal constant EMPTY_HASH = keccak256("");

  /**
   * @notice Denominator for BPS values
   */
  uint256 public constant BPS_FEE_DENOMINATOR = 10_000;

  /**
   * @notice Value for delay used on governance
   */
  uint256 public constant GOVERNANCE_DELAY = 7 days;

  /**
   * @notice Required gas amount to be leftover after passing in `gasleft` when
   * executing calldata (see `_executeCalldata` method).
   */
  uint256 public constant EXECUTE_CALLDATA_RESERVE_GAS = 10_000;

  /**
   * @notice Portal referral code
   */
  uint16 public constant AAVE_REFERRAL_CODE = 0;

  // ============= ConnextPriceOracle
  /**
   * @notice Valid period for a price delivered by the price oracle
   */
  uint256 public constant ORACLE_VALID_PERIOD = 1 minutes;

  /**
   * @notice Valid wiggle room for future timestamps (3s) used by `setDirectPrice`
   */
  uint256 public constant FUTURE_TIME_BUFFER = 3;

  /**
   * @notice Defalt decimals values are normalized to
   */
  uint8 public constant DEFAULT_NORMALIZED_DECIMALS = uint8(18);

  /**
   * @notice Bytes of return data copied back when using `excessivelySafeCall`
   */
  uint16 public constant DEFAULT_COPY_BYTES = 256;

  /**
   * @notice Valid deadline extension used when swapping (1hr)
   */
  uint256 public constant DEFAULT_DEADLINE_EXTENSION = 3600;

  // ============= Swaps
  /**
   * @notice the precision all pools tokens will be converted to
   * @dev stored here to keep easily in sync between `SwapUtils` and `SwapUtilsExternal`
   *
   * The minimum in a pool is 2 (nextUSDC, USDC), and the maximum allowed is 16. While
   * we do not have pools supporting this number of token, allowing a larger value leaves
   * the possibility open to pool multiple stable local/adopted pairs, garnering greater
   * capital efficiency. 16 specifically was chosen as a bit of a sweet spot between the
   * default of 32 and what we will realistically host in pools.
   */
  uint256 public constant MINIMUM_POOLED_TOKENS = 2;
  uint256 public constant MAXIMUM_POOLED_TOKENS = 16;

  /**
   * @notice the precision all pools tokens will be converted to
   * @dev stored here to keep easily in sync between `SwapUtils` and `SwapUtilsExternal`
   */
  uint8 public constant POOL_PRECISION_DECIMALS = 18;

  /**
   * @notice the denominator used to calculate admin and LP fees. For example, an
   * LP fee might be something like tradeAmount.mul(fee).div(FEE_DENOMINATOR)
   * @dev stored here to keep easily in sync between `SwapUtils` and `SwapUtilsExternal`
   */
  uint256 public constant FEE_DENOMINATOR = 1e10;

  /**
   * @notice Max swap fee is 1% or 100bps of each swap
   * @dev stored here to keep easily in sync between `SwapUtils` and `SwapUtilsExternal`
   */
  uint256 public constant MAX_SWAP_FEE = 1e8;

  /**
   * @notice Max adminFee is 100% of the swapFee. adminFee does not add additional fee on top of swapFee.
   * Instead it takes a certain % of the swapFee. Therefore it has no impact on the
   * users but only on the earnings of LPs
   * @dev stored here to keep easily in sync between `SwapUtils` and `SwapUtilsExternal`
   */
  uint256 public constant MAX_ADMIN_FEE = 1e10;

  /**
   * @notice constant value used as max loop limit
   * @dev stored here to keep easily in sync between `SwapUtils` and `SwapUtilsExternal`
   */
  uint256 public constant MAX_LOOP_LIMIT = 256;

  // Constant value used as max delay time for removing swap after disabled
  uint256 internal constant REMOVE_DELAY = 7 days;

  /**
   * @notice constant values used in ramping A calculations
   * @dev stored here to keep easily in sync between `SwapUtils` and `SwapUtilsExternal`
   */
  uint256 public constant A_PRECISION = 100;
  uint256 public constant MAX_A = 10**6;
  uint256 public constant MAX_A_CHANGE = 2;
  uint256 public constant MIN_RAMP_TIME = 14 days;
  uint256 public constant MIN_RAMP_DELAY = 1 days;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import {IStableSwap} from "../interfaces/IStableSwap.sol";
import {IConnectorManager} from "../../../messaging/interfaces/IConnectorManager.sol";
import {SwapUtils} from "./SwapUtils.sol";
import {TokenId} from "./TokenId.sol";

/**
 * @notice THIS FILE DEFINES OUR STORAGE LAYOUT AND ID GENERATION SCHEMA. IT CAN ONLY BE MODIFIED FREELY FOR FRESH
 * DEPLOYS. If you are modifiying this file for an upgrade, you must **CAREFULLY** ensure
 * the contract storage layout is not impacted.
 *
 * BE VERY CAREFUL MODIFYING THE VALUES IN THIS FILE!
 */

// ============= Enum =============

/// @notice Enum representing address role
// Returns uint
// None     - 0
// Router   - 1
// Watcher  - 2
// Admin    - 3
enum Role {
  None,
  RouterAdmin,
  Watcher,
  Admin
}

/**
 * @notice Enum representing status of destination transfer
 * @dev Status is only assigned on the destination domain, will always be "none" for the
 * origin domains
 * @return uint - Index of value in enum
 */
enum DestinationTransferStatus {
  None, // 0
  Reconciled, // 1
  Executed, // 2
  Completed // 3 - executed + reconciled
}

/**
 * @notice These are the parameters that will remain constant between the
 * two chains. They are supplied on `xcall` and should be asserted on `execute`
 * @property to - The account that receives funds, in the event of a crosschain call,
 * will receive funds if the call fails.
 *
 * @param originDomain - The originating domain (i.e. where `xcall` is called)
 * @param destinationDomain - The final domain (i.e. where `execute` / `reconcile` are called)\
 * @param canonicalDomain - The canonical domain of the asset you are bridging
 * @param to - The address you are sending funds (and potentially data) to
 * @param delegate - An address who can execute txs on behalf of `to`, in addition to allowing relayers
 * @param receiveLocal - If true, will use the local asset on the destination instead of adopted.
 * @param callData - The data to execute on the receiving chain. If no crosschain call is needed, then leave empty.
 * @param slippage - Slippage user is willing to accept from original amount in expressed in BPS (i.e. if
 * a user takes 1% slippage, this is expressed as 1_000)
 * @param originSender - The msg.sender of the xcall
 * @param bridgedAmt - The amount sent over the bridge (after potential AMM on xcall)
 * @param normalizedIn - The amount sent to `xcall`, normalized to 18 decimals
 * @param nonce - The nonce on the origin domain used to ensure the transferIds are unique
 * @param canonicalId - The unique identifier of the canonical token corresponding to bridge assets
 */
struct TransferInfo {
  uint32 originDomain;
  uint32 destinationDomain;
  uint32 canonicalDomain;
  address to;
  address delegate;
  bool receiveLocal;
  bytes callData;
  uint256 slippage;
  address originSender;
  uint256 bridgedAmt;
  uint256 normalizedIn;
  uint256 nonce;
  bytes32 canonicalId;
}

/**
 * @notice
 * @param params - The TransferInfo. These are consistent across sending and receiving chains.
 * @param routers - The routers who you are sending the funds on behalf of.
 * @param routerSignatures - Signatures belonging to the routers indicating permission to use funds
 * for the signed transfer ID.
 * @param sequencer - The sequencer who assigned the router path to this transfer.
 * @param sequencerSignature - Signature produced by the sequencer for path assignment accountability
 * for the path that was signed.
 */
struct ExecuteArgs {
  TransferInfo params;
  address[] routers;
  bytes[] routerSignatures;
  address sequencer;
  bytes sequencerSignature;
}

/**
 * @notice Contains configs for each router
 * @param approved Whether the router is allowlisted, settable by admin
 * @param portalApproved Whether the router is allowlisted for portals, settable by admin
 * @param routerOwners The address that can update the `recipient`
 * @param proposedRouterOwners Owner candidates
 * @param proposedRouterTimestamp When owner candidate was proposed (there is a delay to acceptance)
 */
struct RouterConfig {
  bool approved;
  bool portalApproved;
  address owner;
  address recipient;
  address proposed;
  uint256 proposedTimestamp;
}

/**
 * @notice Contains configurations for tokens
 * @dev Struct will be stored on the hash of the `canonicalId` and `canonicalDomain`. There are also
 * two separate reverse lookups, that deliver plaintext information based on the passed in address (can
 * either be representation or adopted address passed in).
 *
 * If the decimals are updated in a future token upgrade, the transfers should fail. If that happens, the
 * asset and swaps must be removed, and then they can be readded
 *
 * @param representation Address of minted asset on this domain. If the token is of local origin (meaning it was
 * originally deployed on this chain), this MUST map to address(0).
 * @param representationDecimals Decimals of minted asset on this domain
 * @param adopted Address of adopted asset on this domain
 * @param adoptedDecimals Decimals of adopted asset on this domain
 * @param adoptedToLocalExternalPools Holds the AMMs for swapping in and out of local assets
 * @param approval Allowed assets
 * @param cap Liquidity caps of whitelisted assets. If 0, no cap is enforced.
 * @param custodied Custodied balance by address
 */
struct TokenConfig {
  address representation;
  uint8 representationDecimals;
  address adopted;
  uint8 adoptedDecimals;
  address adoptedToLocalExternalPools;
  bool approval;
  uint256 cap;
  uint256 custodied;
}

struct AppStorage {
  //
  // 0
  bool initialized;
  //
  // Connext
  //
  // 1
  uint256 LIQUIDITY_FEE_NUMERATOR;
  /**
   * @notice The local address that is custodying relayer fees
   */
  // 2
  address relayerFeeVault;
  /**
   * @notice Nonce for the contract, used to keep unique transfer ids.
   * @dev Assigned at first interaction (xcall on origin domain).
   */
  // 3
  uint256 nonce;
  /**
   * @notice The domain this contract exists on.
   * @dev Must match the domain identifier, which is distinct from the "chainId".
   */
  // 4
  uint32 domain;
  /**
   * @notice Mapping of adopted to canonical asset information.
   */
  // 5
  mapping(address => TokenId) adoptedToCanonical;
  /**
   * @notice Mapping of representation to canonical asset information.
   */
  // 6
  mapping(address => TokenId) representationToCanonical;
  /**
   * @notice Mapping of hash(canonicalId, canonicalDomain) to token config on this domain.
   */
  // 7
  mapping(bytes32 => TokenConfig) tokenConfigs;
  /**
   * @notice Mapping to track transfer status on destination domain
   */
  // 8
  mapping(bytes32 => DestinationTransferStatus) transferStatus;
  /**
   * @notice Mapping holding router address that provided fast liquidity.
   */
  // 9
  mapping(bytes32 => address[]) routedTransfers;
  /**
   * @notice Mapping of router to available balance of an asset.
   * @dev Routers should always store liquidity that they can expect to receive via the bridge on
   * this domain (the local asset).
   */
  // 10
  mapping(address => mapping(address => uint256)) routerBalances;
  /**
   * @notice Mapping of approved relayers
   * @dev Send relayer fee if msg.sender is approvedRelayer; otherwise revert.
   */
  // 11
  mapping(address => bool) approvedRelayers;
  /**
   * @notice The max amount of routers a payment can be routed through.
   */
  // 12
  uint256 maxRoutersPerTransfer;
  /**
   * @notice Stores a mapping of transfer id to slippage overrides.
   */
  // 13
  mapping(bytes32 => uint256) slippage;
  /**
   * @notice Stores a mapping of transfer id to receive local overrides.
   */
  // 14
  mapping(bytes32 => bool) receiveLocalOverride;
  /**
   * @notice Stores a mapping of remote routers keyed on domains.
   * @dev Addresses are cast to bytes32.
   * This mapping is required because the Connext now contains the BridgeRouter and must implement
   * the remotes interface.
   */
  // 15
  mapping(uint32 => bytes32) remotes;
  //
  // ProposedOwnable
  //
  // 17
  address _proposed;
  // 18
  uint256 _proposedOwnershipTimestamp;
  // 19
  bool _routerAllowlistRemoved;
  // 20
  uint256 _routerAllowlistTimestamp;
  /**
   * @notice Stores a mapping of address to Roles
   * @dev returns uint representing the enum Role value
   */
  // 21
  mapping(address => Role) roles;
  //
  // RouterFacet
  //
  // 22
  mapping(address => RouterConfig) routerConfigs;
  //
  // ReentrancyGuard
  //
  // 23
  uint256 _status;
  // 24
  uint256 _xcallStatus;
  //
  // StableSwap
  //
  /**
   * @notice Mapping holding the AMM storages for swapping in and out of local assets
   * @dev Swaps for an adopted asset <> local asset (i.e. POS USDC <> nextUSDC on polygon)
   * Struct storing data responsible for automatic market maker functionalities. In order to
   * access this data, this contract uses SwapUtils library. For more details, see SwapUtils.sol.
   */
  // 25
  mapping(bytes32 => SwapUtils.Swap) swapStorages;
  /**
   * @notice Maps token address to an index in the pool. Used to prevent duplicate tokens in the pool.
   * @dev getTokenIndex function also relies on this mapping to retrieve token index.
   */
  // 26
  mapping(bytes32 => mapping(address => uint8)) tokenIndexes;
  /**
   * The address of an existing LPToken contract to use as a target
   * this target must be the address which connext deployed on this chain.
   */
  // 27
  address lpTokenTargetAddress;
  /**
   * @notice Stores whether or not bribing, AMMs, have been paused.
   */
  // 28
  bool _paused;
  //
  // AavePortals
  //
  /**
   * @notice Address of Aave Pool contract.
   */
  // 29
  address aavePool;
  /**
   * @notice Fee percentage numerator for using Portal liquidity.
   * @dev Assumes the same basis points as the liquidity fee.
   */
  // 30
  uint256 aavePortalFeeNumerator;
  /**
   * @notice Mapping to store the transfer liquidity amount provided by Aave Portals.
   */
  // 31
  mapping(bytes32 => uint256) portalDebt;
  /**
   * @notice Mapping to store the transfer liquidity amount provided by Aave Portals.
   */
  // 32
  mapping(bytes32 => uint256) portalFeeDebt;
  /**
   * @notice Mapping of approved sequencers
   * @dev Sequencer address provided must belong to an approved sequencer in order to call `execute`
   * for the fast liquidity route.
   */
  // 33
  mapping(address => bool) approvedSequencers;
  /**
   * @notice Remote connection manager for xapp.
   */
  // 34
  IConnectorManager xAppConnectionManager;
}

library LibConnextStorage {
  function connextStorage() internal pure returns (AppStorage storage ds) {
    assembly {
      ds.slot := 0
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/
import {IDiamondCut} from "../interfaces/IDiamondCut.sol";

// Remember to add the loupe functions from DiamondLoupeFacet to the diamond.
// The loupe functions are required by the EIP2535 Diamonds standard

library LibDiamond {
  bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

  struct FacetAddressAndPosition {
    address facetAddress;
    uint96 functionSelectorPosition; // position in facetFunctionSelectors.functionSelectors array
  }

  struct FacetFunctionSelectors {
    bytes4[] functionSelectors;
    uint256 facetAddressPosition; // position of facetAddress in facetAddresses array
  }

  struct DiamondStorage {
    // maps function selector to the facet address and
    // the position of the selector in the facetFunctionSelectors.selectors array
    mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
    // maps facet addresses to function selectors
    mapping(address => FacetFunctionSelectors) facetFunctionSelectors;
    // facet addresses
    address[] facetAddresses;
    // Used to query if a contract implements an interface.
    // Used to implement ERC-165.
    mapping(bytes4 => bool) supportedInterfaces;
    // owner of the contract
    address contractOwner;
    // hash of proposed facets => acceptance time
    mapping(bytes32 => uint256) acceptanceTimes;
    // acceptance delay for upgrading facets
    uint256 acceptanceDelay;
  }

  function diamondStorage() internal pure returns (DiamondStorage storage ds) {
    bytes32 position = DIAMOND_STORAGE_POSITION;
    assembly {
      ds.slot := position
    }
  }

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  function setContractOwner(address _newOwner) internal {
    DiamondStorage storage ds = diamondStorage();
    emit OwnershipTransferred(ds.contractOwner, _newOwner);
    ds.contractOwner = _newOwner;
  }

  function contractOwner() internal view returns (address contractOwner_) {
    contractOwner_ = diamondStorage().contractOwner;
  }

  function acceptanceDelay() internal view returns (uint256) {
    return diamondStorage().acceptanceDelay;
  }

  function acceptanceTime(bytes32 _key) internal view returns (uint256) {
    return diamondStorage().acceptanceTimes[_key];
  }

  function enforceIsContractOwner() internal view {
    require(msg.sender == diamondStorage().contractOwner, "LibDiamond: !contract owner");
  }

  event DiamondCutProposed(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata, uint256 deadline);

  function proposeDiamondCut(
    IDiamondCut.FacetCut[] memory _diamondCut,
    address _init,
    bytes memory _calldata
  ) internal {
    // NOTE: to save gas, verification that `proposeDiamondCut` and `diamondCut` are not
    // included is performed in `diamondCut`, where there is already a loop over facets.
    // In the case where these cuts are performed, admins must call `rescindDiamondCut`

    DiamondStorage storage ds = diamondStorage();
    uint256 acceptance = block.timestamp + ds.acceptanceDelay;
    ds.acceptanceTimes[keccak256(abi.encode(_diamondCut, _init, _calldata))] = acceptance;
    emit DiamondCutProposed(_diamondCut, _init, _calldata, acceptance);
  }

  event DiamondCutRescinded(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);

  function rescindDiamondCut(
    IDiamondCut.FacetCut[] memory _diamondCut,
    address _init,
    bytes memory _calldata
  ) internal {
    // NOTE: you can always rescind a proposed facet cut as the owner, even if outside of the validity
    // period or befor the delay elpases
    delete diamondStorage().acceptanceTimes[keccak256(abi.encode(_diamondCut, _init, _calldata))];
    emit DiamondCutRescinded(_diamondCut, _init, _calldata);
  }

  event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);

  // Internal function version of diamondCut
  function diamondCut(
    IDiamondCut.FacetCut[] memory _diamondCut,
    address _init,
    bytes memory _calldata
  ) internal {
    DiamondStorage storage ds = diamondStorage();
    bytes32 key = keccak256(abi.encode(_diamondCut, _init, _calldata));
    if (ds.facetAddresses.length != 0) {
      uint256 time = ds.acceptanceTimes[key];
      require(time != 0 && time <= block.timestamp, "LibDiamond: delay not elapsed");
      // Reset the acceptance time to ensure the same set of updates cannot be replayed
      // without going through a proposal window

      // NOTE: the only time this will not be set to 0 is when there are no
      // existing facet addresses (on initialization, or when starting after a bad upgrade,
      // for example).
      // The only relevant case is the initial case, which has no acceptance time. otherwise,
      // there is no way to update the facet selector mapping to call `diamondCut`.
      // Avoiding setting the empty value will save gas on the initial deployment.
      delete ds.acceptanceTimes[key];
    } // Otherwise, this is the first instance of deployment and it can be set automatically
    uint256 len = _diamondCut.length;
    for (uint256 facetIndex; facetIndex < len; ) {
      IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;
      if (action == IDiamondCut.FacetCutAction.Add) {
        addFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
      } else if (action == IDiamondCut.FacetCutAction.Replace) {
        replaceFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
      } else if (action == IDiamondCut.FacetCutAction.Remove) {
        removeFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
      } else {
        revert("LibDiamondCut: Incorrect FacetCutAction");
      }

      unchecked {
        ++facetIndex;
      }
    }
    emit DiamondCut(_diamondCut, _init, _calldata);
    initializeDiamondCut(_init, _calldata);
  }

  function addFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
    require(_functionSelectors.length != 0, "LibDiamondCut: No selectors in facet to cut");
    DiamondStorage storage ds = diamondStorage();
    require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
    uint96 selectorPosition = uint96(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
    // add new facet address if it does not exist
    if (selectorPosition == 0) {
      addFacet(ds, _facetAddress);
    }
    uint256 len = _functionSelectors.length;
    for (uint256 selectorIndex; selectorIndex < len; ) {
      bytes4 selector = _functionSelectors[selectorIndex];
      address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
      require(oldFacetAddress == address(0), "LibDiamondCut: Can't add function that already exists");
      addFunction(ds, selector, selectorPosition, _facetAddress);
      selectorPosition++;

      unchecked {
        ++selectorIndex;
      }
    }
  }

  function replaceFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
    uint256 len = _functionSelectors.length;
    require(len != 0, "LibDiamondCut: No selectors in facet to cut");
    DiamondStorage storage ds = diamondStorage();
    require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
    uint96 selectorPosition = uint96(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
    // add new facet address if it does not exist
    if (selectorPosition == 0) {
      addFacet(ds, _facetAddress);
    }
    for (uint256 selectorIndex; selectorIndex < len; ) {
      bytes4 selector = _functionSelectors[selectorIndex];
      address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
      require(oldFacetAddress != _facetAddress, "LibDiamondCut: Can't replace function with same function");
      removeFunction(ds, oldFacetAddress, selector);
      addFunction(ds, selector, selectorPosition, _facetAddress);
      selectorPosition++;

      unchecked {
        ++selectorIndex;
      }
    }
  }

  function removeFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
    require(_functionSelectors.length != 0, "LibDiamondCut: No selectors in facet to cut");
    DiamondStorage storage ds = diamondStorage();
    // get the propose and cut selectors -- can never remove these
    bytes4 proposeSelector = IDiamondCut.proposeDiamondCut.selector;
    bytes4 cutSelector = IDiamondCut.diamondCut.selector;
    // if function does not exist then do nothing and return
    require(_facetAddress == address(0), "LibDiamondCut: Remove facet address must be address(0)");
    uint256 len = _functionSelectors.length;
    for (uint256 selectorIndex; selectorIndex < len; ) {
      bytes4 selector = _functionSelectors[selectorIndex];
      require(selector != proposeSelector && selector != cutSelector, "LibDiamondCut: Cannot remove cut selectors");
      address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
      removeFunction(ds, oldFacetAddress, selector);

      unchecked {
        ++selectorIndex;
      }
    }
  }

  function addFacet(DiamondStorage storage ds, address _facetAddress) internal {
    enforceHasContractCode(_facetAddress, "LibDiamondCut: New facet has no code");
    ds.facetFunctionSelectors[_facetAddress].facetAddressPosition = ds.facetAddresses.length;
    ds.facetAddresses.push(_facetAddress);
  }

  function addFunction(
    DiamondStorage storage ds,
    bytes4 _selector,
    uint96 _selectorPosition,
    address _facetAddress
  ) internal {
    ds.selectorToFacetAndPosition[_selector].functionSelectorPosition = _selectorPosition;
    ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(_selector);
    ds.selectorToFacetAndPosition[_selector].facetAddress = _facetAddress;
  }

  function removeFunction(
    DiamondStorage storage ds,
    address _facetAddress,
    bytes4 _selector
  ) internal {
    require(_facetAddress != address(0), "LibDiamondCut: Can't remove function that doesn't exist");
    // an immutable function is a function defined directly in a diamond
    require(_facetAddress != address(this), "LibDiamondCut: Can't remove immutable function");
    // replace selector with last selector, then delete last selector
    uint256 selectorPosition = ds.selectorToFacetAndPosition[_selector].functionSelectorPosition;
    uint256 lastSelectorPosition = ds.facetFunctionSelectors[_facetAddress].functionSelectors.length - 1;
    // if not the same then replace _selector with lastSelector
    if (selectorPosition != lastSelectorPosition) {
      bytes4 lastSelector = ds.facetFunctionSelectors[_facetAddress].functionSelectors[lastSelectorPosition];
      ds.facetFunctionSelectors[_facetAddress].functionSelectors[selectorPosition] = lastSelector;
      ds.selectorToFacetAndPosition[lastSelector].functionSelectorPosition = uint96(selectorPosition);
    }
    // delete the last selector
    ds.facetFunctionSelectors[_facetAddress].functionSelectors.pop();
    delete ds.selectorToFacetAndPosition[_selector];

    // if no more selectors for facet address then delete the facet address
    if (lastSelectorPosition == 0) {
      // replace facet address with last facet address and delete last facet address
      uint256 lastFacetAddressPosition = ds.facetAddresses.length - 1;
      uint256 facetAddressPosition = ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
      if (facetAddressPosition != lastFacetAddressPosition) {
        address lastFacetAddress = ds.facetAddresses[lastFacetAddressPosition];
        ds.facetAddresses[facetAddressPosition] = lastFacetAddress;
        ds.facetFunctionSelectors[lastFacetAddress].facetAddressPosition = facetAddressPosition;
      }
      ds.facetAddresses.pop();
      delete ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
    }
  }

  function initializeDiamondCut(address _init, bytes memory _calldata) internal {
    if (_init == address(0)) {
      require(_calldata.length == 0, "LibDiamondCut: _init is address(0) but_calldata is not empty");
    } else {
      require(_calldata.length != 0, "LibDiamondCut: _calldata is empty but _init is not address(0)");
      if (_init != address(this)) {
        enforceHasContractCode(_init, "LibDiamondCut: _init address has no code");
      }
      (bool success, bytes memory error) = _init.delegatecall(_calldata);
      if (!success) {
        if (error.length != 0) {
          // bubble up the error
          revert(string(error));
        } else {
          revert("LibDiamondCut: _init function reverted");
        }
      }
    }
  }

  function enforceHasContractCode(address _contract, string memory _errorMessage) internal view {
    require(_contract.code.length != 0, _errorMessage);
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

/**
 * @title MathUtils library
 * @notice A library to be used in conjunction with SafeMath. Contains functions for calculating
 * differences between two uint256.
 */
library MathUtils {
  /**
   * @notice Compares a and b and returns true if the difference between a and b
   *         is less than 1 or equal to each other.
   * @param a uint256 to compare with
   * @param b uint256 to compare with
   * @return True if the difference between a and b is less than 1 or equal,
   *         otherwise return false
   */
  function within1(uint256 a, uint256 b) internal pure returns (bool) {
    return (difference(a, b) < 1 + 1); // instead of <=1
  }

  /**
   * @notice Calculates absolute difference between a and b
   * @param a uint256 to compare with
   * @param b uint256 to compare with
   * @return Difference between a and b
   */
  function difference(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a > b) {
      return a - b;
    }
    return b - a;
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {LPToken} from "../helpers/LPToken.sol";

import {AmplificationUtils} from "./AmplificationUtils.sol";
import {MathUtils} from "./MathUtils.sol";
import {AssetLogic} from "./AssetLogic.sol";
import {Constants} from "./Constants.sol";

/**
 * @title SwapUtils library
 * @notice A library to be used within Swap.sol. Contains functions responsible for custody and AMM functionalities.
 * @dev Contracts relying on this library must initialize SwapUtils.Swap struct then use this library
 * for SwapUtils.Swap struct. Note that this library contains both functions called by users and admins.
 * Admin functions should be protected within contracts using this library.
 */
library SwapUtils {
  using SafeERC20 for IERC20;
  using MathUtils for uint256;

  /*** EVENTS ***/

  event TokenSwap(
    bytes32 indexed key,
    address indexed buyer,
    uint256 tokensSold,
    uint256 tokensBought,
    uint128 soldId,
    uint128 boughtId
  );
  event AddLiquidity(
    bytes32 indexed key,
    address indexed provider,
    uint256[] tokenAmounts,
    uint256[] fees,
    uint256 invariant,
    uint256 lpTokenSupply
  );
  event RemoveLiquidity(bytes32 indexed key, address indexed provider, uint256[] tokenAmounts, uint256 lpTokenSupply);
  event RemoveLiquidityOne(
    bytes32 indexed key,
    address indexed provider,
    uint256 lpTokenAmount,
    uint256 lpTokenSupply,
    uint256 boughtId,
    uint256 tokensBought
  );
  event RemoveLiquidityImbalance(
    bytes32 indexed key,
    address indexed provider,
    uint256[] tokenAmounts,
    uint256[] fees,
    uint256 invariant,
    uint256 lpTokenSupply
  );
  event NewAdminFee(bytes32 indexed key, uint256 newAdminFee);
  event NewSwapFee(bytes32 indexed key, uint256 newSwapFee);

  struct Swap {
    // variables around the ramp management of A,
    // the amplification coefficient * n ** (n - 1)
    // see Curve stableswap paper for details
    bytes32 key;
    uint256 initialA;
    uint256 futureA;
    uint256 initialATime;
    uint256 futureATime;
    // fee calculation
    uint256 swapFee;
    uint256 adminFee;
    LPToken lpToken;
    // contract references for all tokens being pooled
    IERC20[] pooledTokens;
    // multipliers for each pooled token's precision to get to Constants.POOL_PRECISION_DECIMALS
    // for example, TBTC has 18 decimals, so the multiplier should be 1. WBTC
    // has 8, so the multiplier should be 10 ** 18 / 10 ** 8 => 10 ** 10
    uint256[] tokenPrecisionMultipliers;
    // the pool balance of each token, in the token's precision
    // the contract's actual token balance might differ
    uint256[] balances;
    // the admin fee balance of each token, in the token's precision
    uint256[] adminFees;
    // the flag if this pool disabled by admin. once disabled, only remove liquidity will work.
    bool disabled;
    // once pool disabled, admin can remove pool after passed removeTime. and reinitialize.
    uint256 removeTime;
  }

  // Struct storing variables used in calculations in the
  // calculateWithdrawOneTokenDY function to avoid stack too deep errors
  struct CalculateWithdrawOneTokenDYInfo {
    uint256 d0;
    uint256 d1;
    uint256 newY;
    uint256 feePerToken;
    uint256 preciseA;
  }

  // Struct storing variables used in calculations in the
  // {add,remove}Liquidity functions to avoid stack too deep errors
  struct ManageLiquidityInfo {
    uint256 d0;
    uint256 d1;
    uint256 d2;
    uint256 preciseA;
    LPToken lpToken;
    uint256 totalSupply;
    uint256[] balances;
    uint256[] multipliers;
  }

  /*** VIEW & PURE FUNCTIONS ***/

  function _getAPrecise(Swap storage self) private view returns (uint256) {
    return AmplificationUtils._getAPrecise(self);
  }

  /**
   * @notice Calculate the dy, the amount of selected token that user receives and
   * the fee of withdrawing in one token
   * @param tokenAmount the amount to withdraw in the pool's precision
   * @param tokenIndex which token will be withdrawn
   * @param self Swap struct to read from
   * @return the amount of token user will receive
   */
  function calculateWithdrawOneToken(
    Swap storage self,
    uint256 tokenAmount,
    uint8 tokenIndex
  ) internal view returns (uint256) {
    (uint256 availableTokenAmount, ) = _calculateWithdrawOneToken(
      self,
      tokenAmount,
      tokenIndex,
      self.lpToken.totalSupply()
    );
    return availableTokenAmount;
  }

  function _calculateWithdrawOneToken(
    Swap storage self,
    uint256 tokenAmount,
    uint8 tokenIndex,
    uint256 totalSupply
  ) private view returns (uint256, uint256) {
    uint256 dy;
    uint256 newY;
    uint256 currentY;

    (dy, newY, currentY) = calculateWithdrawOneTokenDY(self, tokenIndex, tokenAmount, totalSupply);

    // dy_0 (without fees)
    // dy, dy_0 - dy

    uint256 dySwapFee = (currentY - newY) / self.tokenPrecisionMultipliers[tokenIndex] - dy;

    return (dy, dySwapFee);
  }

  /**
   * @notice Calculate the dy of withdrawing in one token
   * @param self Swap struct to read from
   * @param tokenIndex which token will be withdrawn
   * @param tokenAmount the amount to withdraw in the pools precision
   * @return the d and the new y after withdrawing one token
   */
  function calculateWithdrawOneTokenDY(
    Swap storage self,
    uint8 tokenIndex,
    uint256 tokenAmount,
    uint256 totalSupply
  )
    internal
    view
    returns (
      uint256,
      uint256,
      uint256
    )
  {
    // Get the current D, then solve the stableswap invariant
    // y_i for D - tokenAmount
    uint256[] memory xp = _xp(self);

    require(tokenIndex < xp.length, "index out of range");

    CalculateWithdrawOneTokenDYInfo memory v = CalculateWithdrawOneTokenDYInfo(0, 0, 0, 0, 0);
    v.preciseA = _getAPrecise(self);
    v.d0 = getD(xp, v.preciseA);
    v.d1 = v.d0 - ((tokenAmount * v.d0) / totalSupply);

    require(tokenAmount <= xp[tokenIndex], "exceeds available");

    v.newY = getYD(v.preciseA, tokenIndex, xp, v.d1);

    uint256[] memory xpReduced = new uint256[](xp.length);

    v.feePerToken = _feePerToken(self.swapFee, xp.length);
    // TODO: Set a length variable (at top) instead of reading xp.length on each loop.
    uint256 len = xp.length;
    for (uint256 i; i < len; ) {
      uint256 xpi = xp[i];
      // if i == tokenIndex, dxExpected = xp[i] * d1 / d0 - newY
      // else dxExpected = xp[i] - (xp[i] * d1 / d0)
      // xpReduced[i] -= dxExpected * fee / Constants.FEE_DENOMINATOR
      xpReduced[i] =
        xpi -
        ((((i == tokenIndex) ? ((xpi * v.d1) / v.d0 - v.newY) : (xpi - (xpi * v.d1) / v.d0)) * v.feePerToken) /
          Constants.FEE_DENOMINATOR);

      unchecked {
        ++i;
      }
    }

    uint256 dy = xpReduced[tokenIndex] - getYD(v.preciseA, tokenIndex, xpReduced, v.d1);
    dy = (dy - 1) / (self.tokenPrecisionMultipliers[tokenIndex]);

    return (dy, v.newY, xp[tokenIndex]);
  }

  /**
   * @notice Calculate the price of a token in the pool with given
   * precision-adjusted balances and a particular D.
   *
   * @dev This is accomplished via solving the invariant iteratively.
   * See the StableSwap paper and Curve.fi implementation for further details.
   *
   * x_1**2 + x1 * (sum' - (A*n**n - 1) * D / (A * n**n)) = D ** (n + 1) / (n ** (2 * n) * prod' * A)
   * x_1**2 + b*x_1 = c
   * x_1 = (x_1**2 + c) / (2*x_1 + b)
   *
   * @param a the amplification coefficient * n ** (n - 1). See the StableSwap paper for details.
   * @param tokenIndex Index of token we are calculating for.
   * @param xp a precision-adjusted set of pool balances. Array should be
   * the same cardinality as the pool.
   * @param d the stableswap invariant
   * @return the price of the token, in the same precision as in xp
   */
  function getYD(
    uint256 a,
    uint8 tokenIndex,
    uint256[] memory xp,
    uint256 d
  ) internal pure returns (uint256) {
    uint256 numTokens = xp.length;
    require(tokenIndex < numTokens, "Token not found");

    uint256 c = d;
    uint256 s;
    uint256 nA = a * numTokens;

    for (uint256 i; i < numTokens; ) {
      if (i != tokenIndex) {
        s += xp[i];
        c = (c * d) / (xp[i] * numTokens);
        // If we were to protect the division loss we would have to keep the denominator separate
        // and divide at the end. However this leads to overflow with large numTokens or/and D.
        // c = c * D * D * D * ... overflow!
      }

      unchecked {
        ++i;
      }
    }
    c = (c * d * Constants.A_PRECISION) / (nA * numTokens);

    uint256 b = s + ((d * Constants.A_PRECISION) / nA);
    uint256 yPrev;
    // Select d as the starting point of the Newton method. Because y < D
    // D is the best option as the starting point in case the pool is very imbalanced.
    uint256 y = d;
    for (uint256 i; i < Constants.MAX_LOOP_LIMIT; ) {
      yPrev = y;
      y = ((y * y) + c) / ((y * 2) + b - d);
      if (y.within1(yPrev)) {
        return y;
      }

      unchecked {
        ++i;
      }
    }
    revert("Approximation did not converge");
  }

  /**
   * @notice Get D, the StableSwap invariant, based on a set of balances and a particular A.
   * @param xp a precision-adjusted set of pool balances. Array should be the same cardinality
   * as the pool.
   * @param a the amplification coefficient * n ** (n - 1) in A_PRECISION.
   * See the StableSwap paper for details
   * @return the invariant, at the precision of the pool
   */
  function getD(uint256[] memory xp, uint256 a) internal pure returns (uint256) {
    uint256 numTokens = xp.length;
    uint256 s;
    for (uint256 i; i < numTokens; ) {
      s += xp[i];

      unchecked {
        ++i;
      }
    }
    if (s == 0) {
      return 0;
    }

    uint256 prevD;
    uint256 d = s;
    uint256 nA = a * numTokens;

    for (uint256 i; i < Constants.MAX_LOOP_LIMIT; ) {
      uint256 dP = d;
      for (uint256 j; j < numTokens; ) {
        dP = (dP * d) / (xp[j] * numTokens);
        // If we were to protect the division loss we would have to keep the denominator separate
        // and divide at the end. However this leads to overflow with large numTokens or/and D.
        // dP = dP * D * D * D * ... overflow!

        unchecked {
          ++j;
        }
      }
      prevD = d;
      d =
        (((nA * s) / Constants.A_PRECISION + dP * numTokens) * d) /
        ((((nA - Constants.A_PRECISION) * d) / Constants.A_PRECISION + (numTokens + 1) * dP));
      if (d.within1(prevD)) {
        return d;
      }

      unchecked {
        ++i;
      }
    }

    // Convergence should occur in 4 loops or less. If this is reached, there may be something wrong
    // with the pool. If this were to occur repeatedly, LPs should withdraw via `removeLiquidity()`
    // function which does not rely on D.
    revert("D does not converge");
  }

  /**
   * @notice Given a set of balances and precision multipliers, return the
   * precision-adjusted balances.
   *
   * @param balances an array of token balances, in their native precisions.
   * These should generally correspond with pooled tokens.
   *
   * @param precisionMultipliers an array of multipliers, corresponding to
   * the amounts in the balances array. When multiplied together they
   * should yield amounts at the pool's precision.
   *
   * @return an array of amounts "scaled" to the pool's precision
   */
  function _xp(uint256[] memory balances, uint256[] memory precisionMultipliers)
    internal
    pure
    returns (uint256[] memory)
  {
    uint256 numTokens = balances.length;
    require(numTokens == precisionMultipliers.length, "mismatch multipliers");
    uint256[] memory xp = new uint256[](numTokens);
    for (uint256 i; i < numTokens; ) {
      xp[i] = balances[i] * precisionMultipliers[i];

      unchecked {
        ++i;
      }
    }
    return xp;
  }

  /**
   * @notice Return the precision-adjusted balances of all tokens in the pool
   * @param self Swap struct to read from
   * @return the pool balances "scaled" to the pool's precision, allowing
   * them to be more easily compared.
   */
  function _xp(Swap storage self) internal view returns (uint256[] memory) {
    return _xp(self.balances, self.tokenPrecisionMultipliers);
  }

  /**
   * @notice Get the virtual price, to help calculate profit
   * @param self Swap struct to read from
   * @return the virtual price, scaled to precision of Constants.POOL_PRECISION_DECIMALS
   */
  function getVirtualPrice(Swap storage self) internal view returns (uint256) {
    uint256 d = getD(_xp(self), _getAPrecise(self));
    LPToken lpToken = self.lpToken;
    uint256 supply = lpToken.totalSupply();
    if (supply != 0) {
      return (d * (10**uint256(Constants.POOL_PRECISION_DECIMALS))) / supply;
    }
    return 0;
  }

  /**
   * @notice Calculate the new balances of the tokens given the indexes of the token
   * that is swapped from (FROM) and the token that is swapped to (TO).
   * This function is used as a helper function to calculate how much TO token
   * the user should receive on swap.
   *
   * @param preciseA precise form of amplification coefficient
   * @param tokenIndexFrom index of FROM token
   * @param tokenIndexTo index of TO token
   * @param x the new total amount of FROM token
   * @param xp balances of the tokens in the pool
   * @return the amount of TO token that should remain in the pool
   */
  function getY(
    uint256 preciseA,
    uint8 tokenIndexFrom,
    uint8 tokenIndexTo,
    uint256 x,
    uint256[] memory xp
  ) internal pure returns (uint256) {
    uint256 numTokens = xp.length;
    require(tokenIndexFrom != tokenIndexTo, "compare token to itself");
    require(tokenIndexFrom < numTokens && tokenIndexTo < numTokens, "token not found");

    uint256 d = getD(xp, preciseA);
    uint256 c = d;
    uint256 s;
    uint256 nA = numTokens * preciseA;

    uint256 _x;
    for (uint256 i; i < numTokens; ) {
      if (i == tokenIndexFrom) {
        _x = x;
      } else if (i != tokenIndexTo) {
        _x = xp[i];
      } else {
        unchecked {
          ++i;
        }
        continue;
      }
      s += _x;
      c = (c * d) / (_x * numTokens);
      // If we were to protect the division loss we would have to keep the denominator separate
      // and divide at the end. However this leads to overflow with large numTokens or/and D.
      // c = c * D * D * D * ... overflow!

      unchecked {
        ++i;
      }
    }
    c = (c * d * Constants.A_PRECISION) / (nA * numTokens);
    uint256 b = s + ((d * Constants.A_PRECISION) / nA);
    uint256 yPrev;
    uint256 y = d;

    // iterative approximation
    for (uint256 i; i < Constants.MAX_LOOP_LIMIT; ) {
      yPrev = y;
      y = ((y * y) + c) / ((y * 2) + b - d);
      if (y.within1(yPrev)) {
        return y;
      }

      unchecked {
        ++i;
      }
    }
    revert("Approximation did not converge");
  }

  /**
   * @notice Externally calculates a swap between two tokens.
   * @param self Swap struct to read from
   * @param tokenIndexFrom the token to sell
   * @param tokenIndexTo the token to buy
   * @param dx the number of tokens to sell. If the token charges a fee on transfers,
   * use the amount that gets transferred after the fee.
   * @return dy the number of tokens the user will get
   */
  function calculateSwap(
    Swap storage self,
    uint8 tokenIndexFrom,
    uint8 tokenIndexTo,
    uint256 dx
  ) internal view returns (uint256 dy) {
    (dy, ) = _calculateSwap(self, tokenIndexFrom, tokenIndexTo, dx, self.balances);
  }

  /**
   * @notice Externally calculates a swap between two tokens.
   * @param self Swap struct to read from
   * @param tokenIndexFrom the token to sell
   * @param tokenIndexTo the token to buy
   * @param dy the number of tokens to buy.
   * @return dx the number of tokens the user have to transfer + fee
   */
  function calculateSwapInv(
    Swap storage self,
    uint8 tokenIndexFrom,
    uint8 tokenIndexTo,
    uint256 dy
  ) internal view returns (uint256 dx) {
    (dx, ) = _calculateSwapInv(self, tokenIndexFrom, tokenIndexTo, dy, self.balances);
  }

  /**
   * @notice Internally calculates a swap between two tokens.
   *
   * @dev The caller is expected to transfer the actual amounts (dx and dy)
   * using the token contracts.
   *
   * @param self Swap struct to read from
   * @param tokenIndexFrom the token to sell
   * @param tokenIndexTo the token to buy
   * @param dx the number of tokens to sell. If the token charges a fee on transfers,
   * use the amount that gets transferred after the fee.
   * @return dy the number of tokens the user will get in the token's precision. ex WBTC -> 8
   * @return dyFee the associated fee in multiplied precision (Constants.POOL_PRECISION_DECIMALS)
   */
  function _calculateSwap(
    Swap storage self,
    uint8 tokenIndexFrom,
    uint8 tokenIndexTo,
    uint256 dx,
    uint256[] memory balances
  ) internal view returns (uint256 dy, uint256 dyFee) {
    uint256[] memory multipliers = self.tokenPrecisionMultipliers;
    uint256[] memory xp = _xp(balances, multipliers);
    require(tokenIndexFrom < xp.length && tokenIndexTo < xp.length, "index out of range");
    uint256 x = dx * multipliers[tokenIndexFrom] + xp[tokenIndexFrom];
    uint256 y = getY(_getAPrecise(self), tokenIndexFrom, tokenIndexTo, x, xp);
    dy = xp[tokenIndexTo] - y - 1;
    dyFee = (dy * self.swapFee) / Constants.FEE_DENOMINATOR;
    dy = (dy - dyFee) / multipliers[tokenIndexTo];
  }

  /**
   * @notice Internally calculates a swap between two tokens.
   *
   * @dev The caller is expected to transfer the actual amounts (dx and dy)
   * using the token contracts.
   *
   * @param self Swap struct to read from
   * @param tokenIndexFrom the token to sell
   * @param tokenIndexTo the token to buy
   * @param dy the number of tokens to buy. If the token charges a fee on transfers,
   * use the amount that gets transferred after the fee.
   * @return dx the number of tokens the user have to deposit in the token's precision. ex WBTC -> 8
   * @return dxFee the associated fee in multiplied precision (Constants.POOL_PRECISION_DECIMALS)
   */
  function _calculateSwapInv(
    Swap storage self,
    uint8 tokenIndexFrom,
    uint8 tokenIndexTo,
    uint256 dy,
    uint256[] memory balances
  ) internal view returns (uint256 dx, uint256 dxFee) {
    require(tokenIndexFrom != tokenIndexTo, "compare token to itself");
    uint256[] memory multipliers = self.tokenPrecisionMultipliers;
    uint256[] memory xp = _xp(balances, multipliers);
    require(tokenIndexFrom < xp.length && tokenIndexTo < xp.length, "index out of range");

    uint256 a = _getAPrecise(self);
    uint256 d0 = getD(xp, a);

    xp[tokenIndexTo] = xp[tokenIndexTo] - (dy * multipliers[tokenIndexTo]);
    uint256 x = getYD(a, tokenIndexFrom, xp, d0);
    dx = (x + 1) - xp[tokenIndexFrom];
    dxFee = (dx * self.swapFee) / Constants.FEE_DENOMINATOR;
    dx = (dx + dxFee) / multipliers[tokenIndexFrom];
  }

  /**
   * @notice A simple method to calculate amount of each underlying
   * tokens that is returned upon burning given amount of
   * LP tokens
   *
   * @param amount the amount of LP tokens that would to be burned on
   * withdrawal
   * @return array of amounts of tokens user will receive
   */
  function calculateRemoveLiquidity(Swap storage self, uint256 amount) internal view returns (uint256[] memory) {
    return _calculateRemoveLiquidity(self.balances, amount, self.lpToken.totalSupply());
  }

  function _calculateRemoveLiquidity(
    uint256[] memory balances,
    uint256 amount,
    uint256 totalSupply
  ) internal pure returns (uint256[] memory) {
    require(amount <= totalSupply, "exceed total supply");

    uint256 numBalances = balances.length;
    uint256[] memory amounts = new uint256[](numBalances);

    for (uint256 i; i < numBalances; ) {
      amounts[i] = (balances[i] * amount) / totalSupply;

      unchecked {
        ++i;
      }
    }
    return amounts;
  }

  /**
   * @notice A simple method to calculate prices from deposits or
   * withdrawals, excluding fees but including slippage. This is
   * helpful as an input into the various "min" parameters on calls
   * to fight front-running
   *
   * @dev This shouldn't be used outside frontends for user estimates.
   *
   * @param self Swap struct to read from
   * @param amounts an array of token amounts to deposit or withdrawal,
   * corresponding to pooledTokens. The amount should be in each
   * pooled token's native precision. If a token charges a fee on transfers,
   * use the amount that gets transferred after the fee.
   * @param deposit whether this is a deposit or a withdrawal
   * @return if deposit was true, total amount of lp token that will be minted and if
   * deposit was false, total amount of lp token that will be burned
   */
  function calculateTokenAmount(
    Swap storage self,
    uint256[] calldata amounts,
    bool deposit
  ) internal view returns (uint256) {
    uint256[] memory balances = self.balances;
    uint256 numBalances = balances.length;
    require(amounts.length == numBalances, "invalid length of amounts");

    uint256 a = _getAPrecise(self);
    uint256[] memory multipliers = self.tokenPrecisionMultipliers;

    uint256 d0 = getD(_xp(balances, multipliers), a);
    for (uint256 i; i < numBalances; ) {
      if (deposit) {
        balances[i] = balances[i] + amounts[i];
      } else {
        balances[i] = balances[i] - amounts[i];
      }

      unchecked {
        ++i;
      }
    }
    uint256 d1 = getD(_xp(balances, multipliers), a);
    uint256 totalSupply = self.lpToken.totalSupply();

    if (deposit) {
      return ((d1 - d0) * totalSupply) / d0;
    } else {
      return ((d0 - d1) * totalSupply) / d0;
    }
  }

  /**
   * @notice return accumulated amount of admin fees of the token with given index
   * @param self Swap struct to read from
   * @param index Index of the pooled token
   * @return admin balance in the token's precision
   */
  function getAdminBalance(Swap storage self, uint256 index) internal view returns (uint256) {
    require(index < self.pooledTokens.length, "index out of range");
    return self.adminFees[index];
  }

  /**
   * @notice internal helper function to calculate fee per token multiplier used in
   * swap fee calculations
   * @param swapFee swap fee for the tokens
   * @param numTokens number of tokens pooled
   */
  function _feePerToken(uint256 swapFee, uint256 numTokens) internal pure returns (uint256) {
    return (swapFee * numTokens) / ((numTokens - 1) * 4);
  }

  /*** STATE MODIFYING FUNCTIONS ***/

  /**
   * @notice swap two tokens in the pool
   * @param self Swap struct to read from and write to
   * @param tokenIndexFrom the token the user wants to sell
   * @param tokenIndexTo the token the user wants to buy
   * @param dx the amount of tokens the user wants to sell
   * @param minDy the min amount the user would like to receive, or revert.
   * @return amount of token user received on swap
   */
  function swap(
    Swap storage self,
    uint8 tokenIndexFrom,
    uint8 tokenIndexTo,
    uint256 dx,
    uint256 minDy
  ) internal returns (uint256) {
    require(!self.disabled, "disabled pool");
    {
      IERC20 tokenFrom = self.pooledTokens[tokenIndexFrom];
      require(dx <= tokenFrom.balanceOf(msg.sender), "swap more than you own");
      // Reverts for fee on transfer
      AssetLogic.handleIncomingAsset(address(tokenFrom), dx);
    }

    uint256 dy;
    uint256 dyFee;
    uint256[] memory balances = self.balances;
    (dy, dyFee) = _calculateSwap(self, tokenIndexFrom, tokenIndexTo, dx, balances);
    require(dy >= minDy, "dy < minDy");

    uint256 dyAdminFee = (dyFee * self.adminFee) /
      Constants.FEE_DENOMINATOR /
      self.tokenPrecisionMultipliers[tokenIndexTo];

    self.balances[tokenIndexFrom] = balances[tokenIndexFrom] + dx;
    self.balances[tokenIndexTo] = balances[tokenIndexTo] - dy - dyAdminFee;
    if (dyAdminFee != 0) {
      self.adminFees[tokenIndexTo] = self.adminFees[tokenIndexTo] + dyAdminFee;
    }

    AssetLogic.handleOutgoingAsset(address(self.pooledTokens[tokenIndexTo]), msg.sender, dy);

    emit TokenSwap(self.key, msg.sender, dx, dy, tokenIndexFrom, tokenIndexTo);

    return dy;
  }

  /**
   * @notice swap two tokens in the pool
   * @param self Swap struct to read from and write to
   * @param tokenIndexFrom the token the user wants to sell
   * @param tokenIndexTo the token the user wants to buy
   * @param dy the amount of tokens the user wants to buy
   * @param maxDx the max amount the user would like to send.
   * @return amount of token user have to transfer on swap
   */
  function swapOut(
    Swap storage self,
    uint8 tokenIndexFrom,
    uint8 tokenIndexTo,
    uint256 dy,
    uint256 maxDx
  ) internal returns (uint256) {
    require(!self.disabled, "disabled pool");
    require(dy <= self.balances[tokenIndexTo], ">pool balance");

    uint256 dx;
    uint256 dxFee;
    uint256[] memory balances = self.balances;
    (dx, dxFee) = _calculateSwapInv(self, tokenIndexFrom, tokenIndexTo, dy, balances);
    require(dx <= maxDx, "dx > maxDx");

    uint256 dxAdminFee = (dxFee * self.adminFee) /
      Constants.FEE_DENOMINATOR /
      self.tokenPrecisionMultipliers[tokenIndexFrom];

    self.balances[tokenIndexFrom] = balances[tokenIndexFrom] + dx - dxAdminFee;
    self.balances[tokenIndexTo] = balances[tokenIndexTo] - dy;
    if (dxAdminFee != 0) {
      self.adminFees[tokenIndexFrom] = self.adminFees[tokenIndexFrom] + dxAdminFee;
    }

    {
      IERC20 tokenFrom = self.pooledTokens[tokenIndexFrom];
      require(dx <= tokenFrom.balanceOf(msg.sender), "more than you own");
      // Reverts for fee on transfer
      AssetLogic.handleIncomingAsset(address(tokenFrom), dx);
    }

    AssetLogic.handleOutgoingAsset(address(self.pooledTokens[tokenIndexTo]), msg.sender, dy);

    emit TokenSwap(self.key, msg.sender, dx, dy, tokenIndexFrom, tokenIndexTo);

    return dx;
  }

  /**
   * @notice swap two tokens in the pool internally
   * @param self Swap struct to read from and write to
   * @param tokenIndexFrom the token the user wants to sell
   * @param tokenIndexTo the token the user wants to buy
   * @param dx the amount of tokens the user wants to sell
   * @param minDy the min amount the user would like to receive, or revert.
   * @return amount of token user received on swap
   */
  function swapInternal(
    Swap storage self,
    uint8 tokenIndexFrom,
    uint8 tokenIndexTo,
    uint256 dx,
    uint256 minDy
  ) internal returns (uint256) {
    require(!self.disabled, "disabled pool");
    require(dx <= self.balances[tokenIndexFrom], "more than pool balance");

    uint256 dy;
    uint256 dyFee;
    uint256[] memory balances = self.balances;
    (dy, dyFee) = _calculateSwap(self, tokenIndexFrom, tokenIndexTo, dx, balances);
    require(dy >= minDy, "dy < minDy");

    uint256 dyAdminFee = (dyFee * self.adminFee) /
      Constants.FEE_DENOMINATOR /
      self.tokenPrecisionMultipliers[tokenIndexTo];

    self.balances[tokenIndexFrom] = balances[tokenIndexFrom] + dx;
    self.balances[tokenIndexTo] = balances[tokenIndexTo] - dy - dyAdminFee;

    if (dyAdminFee != 0) {
      self.adminFees[tokenIndexTo] = self.adminFees[tokenIndexTo] + dyAdminFee;
    }

    emit TokenSwap(self.key, msg.sender, dx, dy, tokenIndexFrom, tokenIndexTo);

    return dy;
  }

  /**
   * @notice Should get exact amount out of AMM for asset put in
   */
  function swapInternalOut(
    Swap storage self,
    uint8 tokenIndexFrom,
    uint8 tokenIndexTo,
    uint256 dy,
    uint256 maxDx
  ) internal returns (uint256) {
    require(!self.disabled, "disabled pool");
    require(dy <= self.balances[tokenIndexTo], "more than pool balance");

    uint256 dx;
    uint256 dxFee;
    uint256[] memory balances = self.balances;
    (dx, dxFee) = _calculateSwapInv(self, tokenIndexFrom, tokenIndexTo, dy, balances);
    require(dx <= maxDx, "dx > maxDx");

    uint256 dxAdminFee = (dxFee * self.adminFee) /
      Constants.FEE_DENOMINATOR /
      self.tokenPrecisionMultipliers[tokenIndexFrom];

    self.balances[tokenIndexFrom] = balances[tokenIndexFrom] + dx - dxAdminFee;
    self.balances[tokenIndexTo] = balances[tokenIndexTo] - dy;

    if (dxAdminFee != 0) {
      self.adminFees[tokenIndexFrom] = self.adminFees[tokenIndexFrom] + dxAdminFee;
    }

    emit TokenSwap(self.key, msg.sender, dx, dy, tokenIndexFrom, tokenIndexTo);

    return dx;
  }

  /**
   * @notice Add liquidity to the pool
   * @param self Swap struct to read from and write to
   * @param amounts the amounts of each token to add, in their native precision
   * @param minToMint the minimum LP tokens adding this amount of liquidity
   * should mint, otherwise revert. Handy for front-running mitigation
   * allowed addresses. If the pool is not in the guarded launch phase, this parameter will be ignored.
   * @return amount of LP token user received
   */
  function addLiquidity(
    Swap storage self,
    uint256[] memory amounts,
    uint256 minToMint
  ) internal returns (uint256) {
    require(!self.disabled, "disabled pool");

    uint256 numTokens = self.pooledTokens.length;
    require(amounts.length == numTokens, "mismatch pooled tokens");

    // current state
    ManageLiquidityInfo memory v = ManageLiquidityInfo(
      0,
      0,
      0,
      _getAPrecise(self),
      self.lpToken,
      0,
      self.balances,
      self.tokenPrecisionMultipliers
    );
    v.totalSupply = v.lpToken.totalSupply();
    if (v.totalSupply != 0) {
      v.d0 = getD(_xp(v.balances, v.multipliers), v.preciseA);
    }

    uint256[] memory newBalances = new uint256[](numTokens);

    for (uint256 i; i < numTokens; ) {
      require(v.totalSupply != 0 || amounts[i] != 0, "!supply all tokens");

      // Transfer tokens first to see if a fee was charged on transfer
      if (amounts[i] != 0) {
        IERC20 token = self.pooledTokens[i];
        // Reverts for fee on transfer
        AssetLogic.handleIncomingAsset(address(token), amounts[i]);
      }

      newBalances[i] = v.balances[i] + amounts[i];

      unchecked {
        ++i;
      }
    }

    // invariant after change
    v.d1 = getD(_xp(newBalances, v.multipliers), v.preciseA);
    require(v.d1 > v.d0, "D should increase");

    // updated to reflect fees and calculate the user's LP tokens
    v.d2 = v.d1;
    uint256[] memory fees = new uint256[](numTokens);

    if (v.totalSupply != 0) {
      uint256 feePerToken = _feePerToken(self.swapFee, numTokens);
      for (uint256 i; i < numTokens; ) {
        uint256 idealBalance = (v.d1 * v.balances[i]) / v.d0;
        fees[i] = (feePerToken * (idealBalance.difference(newBalances[i]))) / Constants.FEE_DENOMINATOR;
        uint256 adminFee = (fees[i] * self.adminFee) / Constants.FEE_DENOMINATOR;
        self.balances[i] = newBalances[i] - adminFee;
        self.adminFees[i] = self.adminFees[i] + adminFee;
        newBalances[i] = newBalances[i] - fees[i];

        unchecked {
          ++i;
        }
      }
      v.d2 = getD(_xp(newBalances, v.multipliers), v.preciseA);
    } else {
      // the initial depositor doesn't pay fees
      self.balances = newBalances;
    }

    uint256 toMint;
    if (v.totalSupply == 0) {
      toMint = v.d1;
    } else {
      toMint = ((v.d2 - v.d0) * v.totalSupply) / v.d0;
    }

    require(toMint >= minToMint, "mint < min");

    // mint the user's LP tokens
    v.lpToken.mint(msg.sender, toMint);

    emit AddLiquidity(self.key, msg.sender, amounts, fees, v.d1, v.totalSupply + toMint);

    return toMint;
  }

  /**
   * @notice Burn LP tokens to remove liquidity from the pool.
   * @dev Liquidity can always be removed, even when the pool is paused.
   * @param self Swap struct to read from and write to
   * @param amount the amount of LP tokens to burn
   * @param minAmounts the minimum amounts of each token in the pool
   * acceptable for this burn. Useful as a front-running mitigation
   * @return amounts of tokens the user received
   */
  function removeLiquidity(
    Swap storage self,
    uint256 amount,
    uint256[] calldata minAmounts
  ) internal returns (uint256[] memory) {
    LPToken lpToken = self.lpToken;
    require(amount <= lpToken.balanceOf(msg.sender), ">LP.balanceOf");
    uint256 numTokens = self.pooledTokens.length;
    require(minAmounts.length == numTokens, "mismatch poolTokens");

    uint256[] memory balances = self.balances;
    uint256 totalSupply = lpToken.totalSupply();

    uint256[] memory amounts = _calculateRemoveLiquidity(balances, amount, totalSupply);

    uint256 numAmounts = amounts.length;
    for (uint256 i; i < numAmounts; ) {
      require(amounts[i] >= minAmounts[i], "amounts[i] < minAmounts[i]");
      self.balances[i] = balances[i] - amounts[i];
      AssetLogic.handleOutgoingAsset(address(self.pooledTokens[i]), msg.sender, amounts[i]);

      unchecked {
        ++i;
      }
    }

    lpToken.burnFrom(msg.sender, amount);

    emit RemoveLiquidity(self.key, msg.sender, amounts, totalSupply - amount);

    return amounts;
  }

  /**
   * @notice Remove liquidity from the pool all in one token.
   * @param self Swap struct to read from and write to
   * @param tokenAmount the amount of the lp tokens to burn
   * @param tokenIndex the index of the token you want to receive
   * @param minAmount the minimum amount to withdraw, otherwise revert
   * @return amount chosen token that user received
   */
  function removeLiquidityOneToken(
    Swap storage self,
    uint256 tokenAmount,
    uint8 tokenIndex,
    uint256 minAmount
  ) internal returns (uint256) {
    LPToken lpToken = self.lpToken;

    require(tokenAmount <= lpToken.balanceOf(msg.sender), ">LP.balanceOf");
    uint256 numTokens = self.pooledTokens.length;
    require(tokenIndex < numTokens, "not found");

    uint256 totalSupply = lpToken.totalSupply();

    (uint256 dy, uint256 dyFee) = _calculateWithdrawOneToken(self, tokenAmount, tokenIndex, totalSupply);

    require(dy >= minAmount, "dy < minAmount");

    uint256 adminFee = (dyFee * self.adminFee) / Constants.FEE_DENOMINATOR;
    self.balances[tokenIndex] = self.balances[tokenIndex] - (dy + adminFee);
    if (adminFee != 0) {
      self.adminFees[tokenIndex] = self.adminFees[tokenIndex] + adminFee;
    }
    lpToken.burnFrom(msg.sender, tokenAmount);
    AssetLogic.handleOutgoingAsset(address(self.pooledTokens[tokenIndex]), msg.sender, dy);

    emit RemoveLiquidityOne(self.key, msg.sender, tokenAmount, totalSupply, tokenIndex, dy);

    return dy;
  }

  /**
   * @notice Remove liquidity from the pool, weighted differently than the
   * pool's current balances.
   *
   * @param self Swap struct to read from and write to
   * @param amounts how much of each token to withdraw
   * @param maxBurnAmount the max LP token provider is willing to pay to
   * remove liquidity. Useful as a front-running mitigation.
   * @return actual amount of LP tokens burned in the withdrawal
   */
  function removeLiquidityImbalance(
    Swap storage self,
    uint256[] memory amounts,
    uint256 maxBurnAmount
  ) internal returns (uint256) {
    ManageLiquidityInfo memory v = ManageLiquidityInfo(
      0,
      0,
      0,
      _getAPrecise(self),
      self.lpToken,
      0,
      self.balances,
      self.tokenPrecisionMultipliers
    );
    v.totalSupply = v.lpToken.totalSupply();

    uint256 numTokens = self.pooledTokens.length;
    uint256 numAmounts = amounts.length;
    require(numAmounts == numTokens, "mismatch pool tokens");

    require(maxBurnAmount <= v.lpToken.balanceOf(msg.sender) && maxBurnAmount != 0, ">LP.balanceOf");

    uint256 feePerToken = _feePerToken(self.swapFee, numTokens);
    uint256[] memory fees = new uint256[](numTokens);
    {
      uint256[] memory balances1 = new uint256[](numTokens);
      v.d0 = getD(_xp(v.balances, v.multipliers), v.preciseA);
      for (uint256 i; i < numTokens; ) {
        require(v.balances[i] >= amounts[i], "withdraw more than available");

        unchecked {
          balances1[i] = v.balances[i] - amounts[i];
          ++i;
        }
      }
      v.d1 = getD(_xp(balances1, v.multipliers), v.preciseA);

      for (uint256 i; i < numTokens; ) {
        {
          uint256 idealBalance = (v.d1 * v.balances[i]) / v.d0;
          uint256 difference = idealBalance.difference(balances1[i]);
          fees[i] = (feePerToken * difference) / Constants.FEE_DENOMINATOR;
        }
        uint256 adminFee = (fees[i] * self.adminFee) / Constants.FEE_DENOMINATOR;
        self.balances[i] = balances1[i] - adminFee;
        self.adminFees[i] = self.adminFees[i] + adminFee;
        balances1[i] = balances1[i] - fees[i];

        unchecked {
          ++i;
        }
      }

      v.d2 = getD(_xp(balances1, v.multipliers), v.preciseA);
    }
    uint256 tokenAmount = ((v.d0 - v.d2) * v.totalSupply) / v.d0;
    require(tokenAmount != 0, "!zero amount");
    tokenAmount = tokenAmount + 1;

    require(tokenAmount <= maxBurnAmount, "tokenAmount > maxBurnAmount");

    v.lpToken.burnFrom(msg.sender, tokenAmount);

    for (uint256 i; i < numTokens; ) {
      AssetLogic.handleOutgoingAsset(address(self.pooledTokens[i]), msg.sender, amounts[i]);

      unchecked {
        ++i;
      }
    }

    emit RemoveLiquidityImbalance(self.key, msg.sender, amounts, fees, v.d1, v.totalSupply - tokenAmount);

    return tokenAmount;
  }

  /**
   * @notice withdraw all admin fees to a given address
   * @param self Swap struct to withdraw fees from
   * @param to Address to send the fees to
   */
  function withdrawAdminFees(Swap storage self, address to) internal {
    uint256 numTokens = self.pooledTokens.length;
    for (uint256 i; i < numTokens; ) {
      IERC20 token = self.pooledTokens[i];
      uint256 balance = self.adminFees[i];
      if (balance != 0) {
        delete self.adminFees[i];
        AssetLogic.handleOutgoingAsset(address(token), to, balance);
      }

      unchecked {
        ++i;
      }
    }
  }

  /**
   * @notice Sets the admin fee
   * @dev adminFee cannot be higher than 100% of the swap fee
   * @param self Swap struct to update
   * @param newAdminFee new admin fee to be applied on future transactions
   */
  function setAdminFee(Swap storage self, uint256 newAdminFee) internal {
    require(newAdminFee < Constants.MAX_ADMIN_FEE + 1, "too high");
    self.adminFee = newAdminFee;

    emit NewAdminFee(self.key, newAdminFee);
  }

  /**
   * @notice update the swap fee
   * @dev fee cannot be higher than 1% of each swap
   * @param self Swap struct to update
   * @param newSwapFee new swap fee to be applied on future transactions
   */
  function setSwapFee(Swap storage self, uint256 newSwapFee) internal {
    require(newSwapFee < Constants.MAX_SWAP_FEE + 1, "too high");
    self.swapFee = newSwapFee;

    emit NewSwapFee(self.key, newSwapFee);
  }

  /**
   * @notice Check if this stableswap pool exists and is valid (i.e. has been
   * initialized and tokens have been added).
   * @return bool true if this stableswap pool is valid, false if not.
   */
  function exists(Swap storage self) internal view returns (bool) {
    return !self.disabled && self.pooledTokens.length != 0;
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.17;

// ============= Structs =============

// Tokens are identified by a TokenId:
// domain - 4 byte chain ID of the chain from which the token originates
// id - 32 byte identifier of the token address on the origin chain, in that chain's address format
struct TokenId {
  uint32 domain;
  bytes32 id;
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.17;

import {IOutbox} from "./IOutbox.sol";

/**
 * @notice Each router extends the `XAppConnectionClient` contract. This contract
 * allows an admin to call `setXAppConnectionManager` to update the underlying
 * pointers to the messaging inboxes (Replicas) and outboxes (Homes).
 *
 * @dev This interface only contains the functions needed for the `XAppConnectionClient`
 * will interface with.
 */
interface IConnectorManager {
  /**
   * @notice Get the local inbox contract from the xAppConnectionManager
   * @return The local inbox contract
   * @dev The local inbox contract is a SpokeConnector with AMBs, and a
   * Home contract with nomad
   */
  function home() external view returns (IOutbox);

  /**
   * @notice Determine whether _potentialReplica is an enrolled Replica from the xAppConnectionManager
   * @return True if _potentialReplica is an enrolled Replica
   */
  function isReplica(address _potentialReplica) external view returns (bool);

  /**
   * @notice Get the local domain from the xAppConnectionManager
   * @return The local domain
   */
  function localDomain() external view returns (uint32);
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.17;

/**
 * @notice Interface for all contracts sending messages originating on their
 * current domain.
 *
 * @dev These are the Home.sol interface methods used by the `Router`
 * and exposed via `home()` on the `XAppConnectionClient`
 */
interface IOutbox {
  /**
   * @notice Emitted when a new message is added to an outbound message merkle root
   * @param leafIndex Index of message's leaf in merkle tree
   * @param destinationAndNonce Destination and destination-specific
   * nonce combined in single field ((destination << 32) & nonce)
   * @param messageHash Hash of message; the leaf inserted to the Merkle tree for the message
   * @param committedRoot the latest notarized root submitted in the last signed Update
   * @param message Raw bytes of message
   */
  event Dispatch(
    bytes32 indexed messageHash,
    uint256 indexed leafIndex,
    uint64 indexed destinationAndNonce,
    bytes32 committedRoot,
    bytes message
  );

  /**
   * @notice Dispatch the message it to the destination domain & recipient
   * @dev Format the message, insert its hash into Merkle tree,
   * enqueue the new Merkle root, and emit `Dispatch` event with message information.
   * @param _destinationDomain Domain of destination chain
   * @param _recipientAddress Address of recipient on destination chain as bytes32
   * @param _messageBody Raw bytes content of message
   * @return bytes32 The leaf added to the tree
   */
  function dispatch(
    uint32 _destinationDomain,
    bytes32 _recipientAddress,
    bytes memory _messageBody
  ) external returns (bytes32, bytes memory);
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.17;

import {TypedMemView} from "./TypedMemView.sol";

library TypeCasts {
  using TypedMemView for bytes;
  using TypedMemView for bytes29;

  // alignment preserving cast
  function addressToBytes32(address _addr) internal pure returns (bytes32) {
    return bytes32(uint256(uint160(_addr)));
  }

  // alignment preserving cast
  function bytes32ToAddress(bytes32 _buf) internal pure returns (address) {
    return address(uint160(uint256(_buf)));
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.17;

library TypedMemView {
  // Why does this exist?
  // the solidity `bytes memory` type has a few weaknesses.
  // 1. You can't index ranges effectively
  // 2. You can't slice without copying
  // 3. The underlying data may represent any type
  // 4. Solidity never deallocates memory, and memory costs grow
  //    superlinearly

  // By using a memory view instead of a `bytes memory` we get the following
  // advantages:
  // 1. Slices are done on the stack, by manipulating the pointer
  // 2. We can index arbitrary ranges and quickly convert them to stack types
  // 3. We can insert type info into the pointer, and typecheck at runtime

  // This makes `TypedMemView` a useful tool for efficient zero-copy
  // algorithms.

  // Why bytes29?
  // We want to avoid confusion between views, digests, and other common
  // types so we chose a large and uncommonly used odd number of bytes
  //
  // Note that while bytes are left-aligned in a word, integers and addresses
  // are right-aligned. This means when working in assembly we have to
  // account for the 3 unused bytes on the righthand side
  //
  // First 5 bytes are a type flag.
  // - ff_ffff_fffe is reserved for unknown type.
  // - ff_ffff_ffff is reserved for invalid types/errors.
  // next 12 are memory address
  // next 12 are len
  // bottom 3 bytes are empty

  // Assumptions:
  // - non-modification of memory.
  // - No Solidity updates
  // - - wrt free mem point
  // - - wrt bytes representation in memory
  // - - wrt memory addressing in general

  // Usage:
  // - create type constants
  // - use `assertType` for runtime type assertions
  // - - unfortunately we can't do this at compile time yet :(
  // - recommended: implement modifiers that perform type checking
  // - - e.g.
  // - - `uint40 constant MY_TYPE = 3;`
  // - - ` modifer onlyMyType(bytes29 myView) { myView.assertType(MY_TYPE); }`
  // - instantiate a typed view from a bytearray using `ref`
  // - use `index` to inspect the contents of the view
  // - use `slice` to create smaller views into the same memory
  // - - `slice` can increase the offset
  // - - `slice can decrease the length`
  // - - must specify the output type of `slice`
  // - - `slice` will return a null view if you try to overrun
  // - - make sure to explicitly check for this with `notNull` or `assertType`
  // - use `equal` for typed comparisons.

  // The null view
  bytes29 public constant NULL = hex"ffffffffffffffffffffffffffffffffffffffffffffffffffffffffff";
  uint256 constant LOW_12_MASK = 0xffffffffffffffffffffffff;
  uint256 constant TWENTY_SEVEN_BYTES = 8 * 27;
  uint256 private constant _27_BYTES_IN_BITS = 8 * 27; // <--- also used this named constant where ever 216 is used.
  uint256 private constant LOW_27_BYTES_MASK = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffff; // (1 << _27_BYTES_IN_BITS) - 1;

  // ========== Custom Errors ===========

  error TypedMemView__assertType_typeAssertionFailed(uint256 actual, uint256 expected);
  error TypedMemView__index_overrun(uint256 loc, uint256 len, uint256 index, uint256 slice);
  error TypedMemView__index_indexMoreThan32Bytes();
  error TypedMemView__unsafeCopyTo_nullPointer();
  error TypedMemView__unsafeCopyTo_invalidPointer();
  error TypedMemView__unsafeCopyTo_identityOOG();
  error TypedMemView__assertValid_validityAssertionFailed();

  /**
   * @notice          Changes the endianness of a uint256.
   * @dev             https://graphics.stanford.edu/~seander/bithacks.html#ReverseParallel
   * @param _b        The unsigned integer to reverse
   * @return          v - The reversed value
   */
  function reverseUint256(uint256 _b) internal pure returns (uint256 v) {
    v = _b;

    // swap bytes
    v =
      ((v >> 8) & 0x00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF) |
      ((v & 0x00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF) << 8);
    // swap 2-byte long pairs
    v =
      ((v >> 16) & 0x0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF) |
      ((v & 0x0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF) << 16);
    // swap 4-byte long pairs
    v =
      ((v >> 32) & 0x00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF) |
      ((v & 0x00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF) << 32);
    // swap 8-byte long pairs
    v =
      ((v >> 64) & 0x0000000000000000FFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF) |
      ((v & 0x0000000000000000FFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF) << 64);
    // swap 16-byte long pairs
    v = (v >> 128) | (v << 128);
  }

  /**
   * @notice      Create a mask with the highest `_len` bits set.
   * @param _len  The length
   * @return      mask - The mask
   */
  function leftMask(uint8 _len) private pure returns (uint256 mask) {
    // ugly. redo without assembly?
    assembly {
      // solhint-disable-previous-line no-inline-assembly
      mask := sar(sub(_len, 1), 0x8000000000000000000000000000000000000000000000000000000000000000)
    }
  }

  /**
   * @notice      Return the null view.
   * @return      bytes29 - The null view
   */
  function nullView() internal pure returns (bytes29) {
    return NULL;
  }

  /**
   * @notice      Check if the view is null.
   * @return      bool - True if the view is null
   */
  function isNull(bytes29 memView) internal pure returns (bool) {
    return memView == NULL;
  }

  /**
   * @notice      Check if the view is not null.
   * @return      bool - True if the view is not null
   */
  function notNull(bytes29 memView) internal pure returns (bool) {
    return !isNull(memView);
  }

  /**
   * @notice          Check if the view is of a invalid type and points to a valid location
   *                  in memory.
   * @dev             We perform this check by examining solidity's unallocated memory
   *                  pointer and ensuring that the view's upper bound is less than that.
   * @param memView   The view
   * @return          ret - True if the view is invalid
   */
  function isNotValid(bytes29 memView) internal pure returns (bool ret) {
    if (typeOf(memView) == 0xffffffffff) {
      return true;
    }
    uint256 _end = end(memView);
    assembly {
      // solhint-disable-previous-line no-inline-assembly
      ret := gt(_end, mload(0x40))
    }
  }

  /**
   * @notice          Require that a typed memory view be valid.
   * @dev             Returns the view for easy chaining.
   * @param memView   The view
   * @return          bytes29 - The validated view
   */
  function assertValid(bytes29 memView) internal pure returns (bytes29) {
    if (isNotValid(memView)) revert TypedMemView__assertValid_validityAssertionFailed();
    return memView;
  }

  /**
   * @notice          Return true if the memview is of the expected type. Otherwise false.
   * @param memView   The view
   * @param _expected The expected type
   * @return          bool - True if the memview is of the expected type
   */
  function isType(bytes29 memView, uint40 _expected) internal pure returns (bool) {
    return typeOf(memView) == _expected;
  }

  /**
   * @notice          Require that a typed memory view has a specific type.
   * @dev             Returns the view for easy chaining.
   * @param memView   The view
   * @param _expected The expected type
   * @return          bytes29 - The view with validated type
   */
  function assertType(bytes29 memView, uint40 _expected) internal pure returns (bytes29) {
    if (!isType(memView, _expected)) {
      revert TypedMemView__assertType_typeAssertionFailed(uint256(typeOf(memView)), uint256(_expected));
    }
    return memView;
  }

  /**
   * @notice          Return an identical view with a different type.
   * @param memView   The view
   * @param _newType  The new type
   * @return          newView - The new view with the specified type
   */
  function castTo(bytes29 memView, uint40 _newType) internal pure returns (bytes29 newView) {
    // then | in the new type
    assembly {
      // solhint-disable-previous-line no-inline-assembly
      // shift off the top 5 bytes
      newView := or(and(memView, LOW_27_BYTES_MASK), shl(_27_BYTES_IN_BITS, _newType))
    }
  }

  /**
   * @notice          Unsafe raw pointer construction. This should generally not be called
   *                  directly. Prefer `ref` wherever possible.
   * @dev             Unsafe raw pointer construction. This should generally not be called
   *                  directly. Prefer `ref` wherever possible.
   * @param _type     The type
   * @param _loc      The memory address
   * @param _len      The length
   * @return          newView - The new view with the specified type, location and length
   */
  function unsafeBuildUnchecked(
    uint256 _type,
    uint256 _loc,
    uint256 _len
  ) private pure returns (bytes29 newView) {
    uint256 _uint96Bits = 96;
    uint256 _emptyBits = 24;

    // Cast params to ensure input is of correct length
    uint96 len_ = uint96(_len);
    uint96 loc_ = uint96(_loc);
    require(len_ == _len && loc_ == _loc, "!truncated");

    assembly {
      // solium-disable-previous-line security/no-inline-assembly
      newView := shl(_uint96Bits, _type) // insert type
      newView := shl(_uint96Bits, or(newView, loc_)) // insert loc
      newView := shl(_emptyBits, or(newView, len_)) // empty bottom 3 bytes
    }
  }

  /**
   * @notice          Instantiate a new memory view. This should generally not be called
   *                  directly. Prefer `ref` wherever possible.
   * @dev             Instantiate a new memory view. This should generally not be called
   *                  directly. Prefer `ref` wherever possible.
   * @param _type     The type
   * @param _loc      The memory address
   * @param _len      The length
   * @return          newView - The new view with the specified type, location and length
   */
  function build(
    uint256 _type,
    uint256 _loc,
    uint256 _len
  ) internal pure returns (bytes29 newView) {
    uint256 _end = _loc + _len;
    assembly {
      // solhint-disable-previous-line no-inline-assembly
      if gt(_end, mload(0x40)) {
        _end := 0
      }
    }
    if (_end == 0) {
      return NULL;
    }
    newView = unsafeBuildUnchecked(_type, _loc, _len);
  }

  /**
   * @notice          Instantiate a memory view from a byte array.
   * @dev             Note that due to Solidity memory representation, it is not possible to
   *                  implement a deref, as the `bytes` type stores its len in memory.
   * @param arr       The byte array
   * @param newType   The type
   * @return          bytes29 - The memory view
   */
  function ref(bytes memory arr, uint40 newType) internal pure returns (bytes29) {
    uint256 _len = arr.length;

    uint256 _loc;
    assembly {
      // solhint-disable-previous-line no-inline-assembly
      _loc := add(arr, 0x20) // our view is of the data, not the struct
    }

    return build(newType, _loc, _len);
  }

  /**
   * @notice          Return the associated type information.
   * @param memView   The memory view
   * @return          _type - The type associated with the view
   */
  function typeOf(bytes29 memView) internal pure returns (uint40 _type) {
    assembly {
      // solhint-disable-previous-line no-inline-assembly
      // 216 == 256 - 40
      _type := shr(_27_BYTES_IN_BITS, memView) // shift out lower 24 bytes
    }
  }

  /**
   * @notice          Return the memory address of the underlying bytes.
   * @param memView   The view
   * @return          _loc - The memory address
   */
  function loc(bytes29 memView) internal pure returns (uint96 _loc) {
    uint256 _mask = LOW_12_MASK; // assembly can't use globals
    assembly {
      // solhint-disable-previous-line no-inline-assembly
      // 120 bits = 12 bytes (the encoded loc) + 3 bytes (empty low space)
      _loc := and(shr(120, memView), _mask)
    }
  }

  /**
   * @notice          The number of memory words this memory view occupies, rounded up.
   * @param memView   The view
   * @return          uint256 - The number of memory words
   */
  function words(bytes29 memView) internal pure returns (uint256) {
    return (uint256(len(memView)) + 31) / 32;
  }

  /**
   * @notice          The in-memory footprint of a fresh copy of the view.
   * @param memView   The view
   * @return          uint256 - The in-memory footprint of a fresh copy of the view.
   */
  function footprint(bytes29 memView) internal pure returns (uint256) {
    return words(memView) * 32;
  }

  /**
   * @notice          The number of bytes of the view.
   * @param memView   The view
   * @return          _len - The length of the view
   */
  function len(bytes29 memView) internal pure returns (uint96 _len) {
    uint256 _mask = LOW_12_MASK; // assembly can't use globals
    assembly {
      // solhint-disable-previous-line no-inline-assembly
      _len := and(shr(24, memView), _mask)
    }
  }

  /**
   * @notice          Returns the endpoint of `memView`.
   * @param memView   The view
   * @return          uint256 - The endpoint of `memView`
   */
  function end(bytes29 memView) internal pure returns (uint256) {
    unchecked {
      return loc(memView) + len(memView);
    }
  }

  /**
   * @notice          Safe slicing without memory modification.
   * @param memView   The view
   * @param _index    The start index
   * @param _len      The length
   * @param newType   The new type
   * @return          bytes29 - The new view
   */
  function slice(
    bytes29 memView,
    uint256 _index,
    uint256 _len,
    uint40 newType
  ) internal pure returns (bytes29) {
    uint256 _loc = loc(memView);

    // Ensure it doesn't overrun the view
    if (_loc + _index + _len > end(memView)) {
      return NULL;
    }

    _loc = _loc + _index;
    return build(newType, _loc, _len);
  }

  /**
   * @notice          Shortcut to `slice`. Gets a view representing the first `_len` bytes.
   * @param memView   The view
   * @param _len      The length
   * @param newType   The new type
   * @return          bytes29 - The new view
   */
  function prefix(
    bytes29 memView,
    uint256 _len,
    uint40 newType
  ) internal pure returns (bytes29) {
    return slice(memView, 0, _len, newType);
  }

  /**
   * @notice          Shortcut to `slice`. Gets a view representing the last `_len` byte.
   * @param memView   The view
   * @param _len      The length
   * @param newType   The new type
   * @return          bytes29 - The new view
   */
  function postfix(
    bytes29 memView,
    uint256 _len,
    uint40 newType
  ) internal pure returns (bytes29) {
    return slice(memView, uint256(len(memView)) - _len, _len, newType);
  }

  /**
   * @notice          Load up to 32 bytes from the view onto the stack.
   * @dev             Returns a bytes32 with only the `_bytes` highest bytes set.
   *                  This can be immediately cast to a smaller fixed-length byte array.
   *                  To automatically cast to an integer, use `indexUint`.
   * @param memView   The view
   * @param _index    The index
   * @param _bytes    The bytes
   * @return          result - The 32 byte result
   */
  function index(
    bytes29 memView,
    uint256 _index,
    uint8 _bytes
  ) internal pure returns (bytes32 result) {
    if (_bytes == 0) {
      return bytes32(0);
    }
    if (_index + _bytes > len(memView)) {
      // "TypedMemView/index - Overran the view. Slice is at {loc} with length {len}. Attempted to index at offset {index} with length {slice},
      revert TypedMemView__index_overrun(loc(memView), len(memView), _index, uint256(_bytes));
    }
    if (_bytes > 32) revert TypedMemView__index_indexMoreThan32Bytes();

    uint8 bitLength;
    unchecked {
      bitLength = _bytes * 8;
    }
    uint256 _loc = loc(memView);
    uint256 _mask = leftMask(bitLength);
    assembly {
      // solhint-disable-previous-line no-inline-assembly
      result := and(mload(add(_loc, _index)), _mask)
    }
  }

  /**
   * @notice          Parse an unsigned integer from the view at `_index`.
   * @dev             Requires that the view have >= `_bytes` bytes following that index.
   * @param memView   The view
   * @param _index    The index
   * @param _bytes    The bytes
   * @return          result - The unsigned integer
   */
  function indexUint(
    bytes29 memView,
    uint256 _index,
    uint8 _bytes
  ) internal pure returns (uint256 result) {
    return uint256(index(memView, _index, _bytes)) >> ((32 - _bytes) * 8);
  }

  /**
   * @notice          Parse an unsigned integer from LE bytes.
   * @param memView   The view
   * @param _index    The index
   * @param _bytes    The bytes
   * @return          result - The unsigned integer
   */
  function indexLEUint(
    bytes29 memView,
    uint256 _index,
    uint8 _bytes
  ) internal pure returns (uint256 result) {
    return reverseUint256(uint256(index(memView, _index, _bytes)));
  }

  /**
   * @notice          Parse an address from the view at `_index`. Requires that the view have >= 20 bytes
   *                  following that index.
   * @param memView   The view
   * @param _index    The index
   * @return          address - The address
   */
  function indexAddress(bytes29 memView, uint256 _index) internal pure returns (address) {
    return address(uint160(indexUint(memView, _index, 20)));
  }

  /**
   * @notice          Return the keccak256 hash of the underlying memory
   * @param memView   The view
   * @return          digest - The keccak256 hash of the underlying memory
   */
  function keccak(bytes29 memView) internal pure returns (bytes32 digest) {
    uint256 _loc = loc(memView);
    uint256 _len = len(memView);
    assembly {
      // solhint-disable-previous-line no-inline-assembly
      digest := keccak256(_loc, _len)
    }
  }

  /**
   * @notice          Return true if the underlying memory is equal. Else false.
   * @param left      The first view
   * @param right     The second view
   * @return          bool - True if the underlying memory is equal
   */
  function untypedEqual(bytes29 left, bytes29 right) internal pure returns (bool) {
    return (loc(left) == loc(right) && len(left) == len(right)) || keccak(left) == keccak(right);
  }

  /**
   * @notice          Return false if the underlying memory is equal. Else true.
   * @param left      The first view
   * @param right     The second view
   * @return          bool - False if the underlying memory is equal
   */
  function untypedNotEqual(bytes29 left, bytes29 right) internal pure returns (bool) {
    return !untypedEqual(left, right);
  }

  /**
   * @notice          Compares type equality.
   * @dev             Shortcuts if the pointers are identical, otherwise compares type and digest.
   * @param left      The first view
   * @param right     The second view
   * @return          bool - True if the types are the same
   */
  function equal(bytes29 left, bytes29 right) internal pure returns (bool) {
    return left == right || (typeOf(left) == typeOf(right) && keccak(left) == keccak(right));
  }

  /**
   * @notice          Compares type inequality.
   * @dev             Shortcuts if the pointers are identical, otherwise compares type and digest.
   * @param left      The first view
   * @param right     The second view
   * @return          bool - True if the types are not the same
   */
  function notEqual(bytes29 left, bytes29 right) internal pure returns (bool) {
    return !equal(left, right);
  }

  /**
   * @notice          Copy the view to a location, return an unsafe memory reference
   * @dev             Super Dangerous direct memory access.
   *
   *                  This reference can be overwritten if anything else modifies memory (!!!).
   *                  As such it MUST be consumed IMMEDIATELY.
   *                  This function is private to prevent unsafe usage by callers.
   * @param memView   The view
   * @param _newLoc   The new location
   * @return          written - the unsafe memory reference
   */
  function unsafeCopyTo(bytes29 memView, uint256 _newLoc) private view returns (bytes29 written) {
    if (isNull(memView)) revert TypedMemView__unsafeCopyTo_nullPointer();
    if (isNotValid(memView)) revert TypedMemView__unsafeCopyTo_invalidPointer();

    uint256 _len = len(memView);
    uint256 _oldLoc = loc(memView);

    uint256 ptr;
    bool res;
    assembly {
      // solhint-disable-previous-line no-inline-assembly
      ptr := mload(0x40)
      // revert if we're writing in occupied memory
      if gt(ptr, _newLoc) {
        revert(0x60, 0x20) // empty revert message
      }

      // use the identity precompile to copy
      // guaranteed not to fail, so pop the success
      res := staticcall(gas(), 4, _oldLoc, _len, _newLoc, _len)
    }
    if (!res) revert TypedMemView__unsafeCopyTo_identityOOG();
    written = unsafeBuildUnchecked(typeOf(memView), _newLoc, _len);
  }

  /**
   * @notice          Copies the referenced memory to a new loc in memory, returning a `bytes` pointing to
   *                  the new memory
   * @dev             Shortcuts if the pointers are identical, otherwise compares type and digest.
   * @param memView   The view
   * @return          ret - The view pointing to the new memory
   */
  function clone(bytes29 memView) internal view returns (bytes memory ret) {
    uint256 ptr;
    uint256 _len = len(memView);
    assembly {
      // solhint-disable-previous-line no-inline-assembly
      ptr := mload(0x40) // load unused memory pointer
      ret := ptr
    }
    unchecked {
      unsafeCopyTo(memView, ptr + 0x20);
    }
    assembly {
      // solhint-disable-previous-line no-inline-assembly
      mstore(0x40, add(add(ptr, _len), 0x20)) // write new unused pointer
      mstore(ptr, _len) // write len of new array (in bytes)
    }
  }

  /**
   * @notice          Join the views in memory, return an unsafe reference to the memory.
   * @dev             Super Dangerous direct memory access.
   *
   *                  This reference can be overwritten if anything else modifies memory (!!!).
   *                  As such it MUST be consumed IMMEDIATELY.
   *                  This function is private to prevent unsafe usage by callers.
   * @param memViews  The views
   * @return          unsafeView - The conjoined view pointing to the new memory
   */
  function unsafeJoin(bytes29[] memory memViews, uint256 _location) private view returns (bytes29 unsafeView) {
    assembly {
      // solhint-disable-previous-line no-inline-assembly
      let ptr := mload(0x40)
      // revert if we're writing in occupied memory
      if gt(ptr, _location) {
        revert(0x60, 0x20) // empty revert message
      }
    }

    uint256 _offset = 0;
    uint256 _len = memViews.length;
    for (uint256 i = 0; i < _len; ) {
      bytes29 memView = memViews[i];
      unchecked {
        unsafeCopyTo(memView, _location + _offset);
        _offset += len(memView);
        ++i;
      }
    }
    unsafeView = unsafeBuildUnchecked(0, _location, _offset);
  }

  /**
   * @notice          Produce the keccak256 digest of the concatenated contents of multiple views.
   * @param memViews  The views
   * @return          bytes32 - The keccak256 digest
   */
  function joinKeccak(bytes29[] memory memViews) internal view returns (bytes32) {
    uint256 ptr;
    assembly {
      // solhint-disable-previous-line no-inline-assembly
      ptr := mload(0x40) // load unused memory pointer
    }
    return keccak(unsafeJoin(memViews, ptr));
  }

  /**
   * @notice          copies all views, joins them into a new bytearray.
   * @param memViews  The views
   * @return          ret - The new byte array
   */
  function join(bytes29[] memory memViews) internal view returns (bytes memory ret) {
    uint256 ptr;
    assembly {
      // solhint-disable-previous-line no-inline-assembly
      ptr := mload(0x40) // load unused memory pointer
    }

    bytes29 _newView;
    unchecked {
      _newView = unsafeJoin(memViews, ptr + 0x20);
    }
    uint256 _written = len(_newView);
    uint256 _footprint = footprint(_newView);

    assembly {
      // solhint-disable-previous-line no-inline-assembly
      // store the legnth
      mstore(ptr, _written)
      // new pointer is old + 0x20 + the footprint of the body
      mstore(0x40, add(add(ptr, _footprint), 0x20))
      ret := ptr
    }
  }
}