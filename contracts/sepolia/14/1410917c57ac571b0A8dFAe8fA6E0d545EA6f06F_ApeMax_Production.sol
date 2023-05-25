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

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

import "./Libraries/Constants.sol";
import "./Libraries/Data_Structures.sol";
import "./Libraries/Helper_Functions.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/*
    Production version of ApeMax Token
*/

contract ApeMax_Production is ERC20Upgradeable, OwnableUpgradeable {

    // ------- Events -------
    event _claim_apemax(address recipient_address, uint128 amount_minted, uint32 timestamp);
    event _mint_apemax(address indexed recipient_address, uint128 amount_minted, uint128 amount_paid, uint32 timestamp, uint8 currency_index);
    event _stake_tokens(address indexed staker_address, address indexed stake_address, uint64 indexed contract_index, uint128 amount_staked, uint32 timestamp);
    event _unstake_tokens(address indexed staker_address, address indexed stake_address, uint64 indexed contract_index, uint128 amount_staked, uint32 timestamp);
    event _claim_staking_rewards(address indexed staker_address, address indexed stake_address, uint64 indexed contract_index, uint128 amount_claimed, uint32 timestamp);
    event _create_staking_contract(address indexed contract_address, uint64 indexed contract_index, address indexed owner_address, uint32 timestamp);
    event _claim_creator_rewards(address indexed contract_address, uint64 indexed contract_index, address indexed owner_address, uint128 amount_claimed, uint32 timestamp);
    event _update_royalties(address indexed contract_address, uint64 indexed contract_index, address indexed owner_address, uint16 royalties, uint32 timestamp);
    event _distribute_rewards(address indexed contract_address, uint64 indexed contract_index, uint128 reward_amount, uint160 reward_units, uint32 timestamp);

    // ------- Global Vars -------
    Data_Structures.Global internal Global;
    mapping(uint64 => Data_Structures.Contract) internal Contracts;
    mapping(address => Data_Structures.Stake) internal Stakes;

    // For convenience
    mapping(address => uint64) internal Address_To_Contract;
    mapping(address => bool) internal Whitelisted_For_Transfer;

    // Contract State / Rules
    bool transfers_allowed;

    // ------- Init -------
    function initialize() public initializer {

        // Describe the token
        __ERC20_init("ApeMax", "APEMAX");
        __Ownable_init();

        // Mint to founders wallets
        _mint(Constants.founder_0, Constants.founder_reward);
        _mint(Constants.founder_1, Constants.founder_reward);
        _mint(Constants.founder_2, Constants.founder_reward);
        _mint(Constants.founder_3, Constants.founder_reward);

        // Mint to the company wallet
        _mint(Constants.company_wallet, Constants.company_reward);

        // Mint to the contract
        _mint(address(this), Constants.maximum_subsidy);

        // Init global vars
        Global.random_seed = uint256(keccak256(abi.encodePacked(
            block.timestamp,
            block.difficulty
        )));

        Global.init_time = uint32(block.timestamp);

    }

    // ------- Presale -------
    function claim_apemax(
        address recipient,
        uint128 quantity
        )
        public
    {

        // Security check
        require(
            msg.sender == Constants.company_wallet ||
            msg.sender == Constants.pricing_authority,
            "This function is only available to ApeMax admins"
        );

        // Sanity checks
        require(
            Global.total_minted + quantity < Constants.max_presale_quantity,
            "Exceeds maximum total supply"
        );

        // Distribute rewards accordingly
        distribute_rewards(
            0
        );

        // Update quantities
        Global.total_minted += quantity;
        _mint(recipient, quantity);

        // Emit event
        emit _claim_apemax(recipient, quantity, uint32(block.timestamp));
    }

    /*
    function mint_apemax(
        address recipient,

        uint128 amount_payable,
        uint128 quantity,
        uint32 timestamp,
        
        uint8 currency_index, // 0 = eth, 1 = usdt, 2 = usdc, 3 = credit card in eth

        uint8 v, bytes32 r, bytes32 s // <-- signature
        
        )
        public payable
    {

        // Check signature and other params
        Helper_Functions.verify_minting_authorization(
            Global.total_minted,
            block.timestamp,
            amount_payable,
            quantity,
            timestamp,
            currency_index,
            v, r, s
        );
        

        // Price checks        
        if (currency_index == 1) {

            IERC20Upgradeable usdt = IERC20Upgradeable(Constants.usdt_address);

            uint256 sender_balance = usdt.balanceOf(msg.sender);
            uint256 allowance = usdt.allowance(msg.sender, address(this));

            require(sender_balance >= amount_payable, "Insufficient USDT balance");
            require(allowance >= amount_payable, "Insufficient USDT allowance");

            usdt.transferFrom(msg.sender, address(this), amount_payable);

            // require(usdt.transferFrom(msg.sender, address(this), amount_payable), "USDT token transfer failed");
        }
        else if (currency_index == 2) {
            IERC20Upgradeable usdc = IERC20Upgradeable(Constants.usdc_address);
            require(usdc.transferFrom(msg.sender, address(this), amount_payable), "USDC token transfer failed");
        }
        else {
            // Added 1% tolerance
            uint128 one_percent_less = amount_payable - amount_payable / 100;
            require(msg.value >= one_percent_less, "Incorrect ETH amount sent");
        }

        

        // Distribute rewards accordingly
        distribute_rewards(
            0
        );

        // Update quantities
        Global.total_minted += quantity;
        _mint(recipient, quantity);

        // Emit event
        emit _mint_apemax(recipient, quantity, amount_payable, uint32(block.timestamp), currency_index);

    }
    */

    // ------- Transfers -------
    function transfer(
        address recipient,
        uint256 amount
        )
        public override
        can_transfer(msg.sender, recipient)
        has_sufficient_balance(msg.sender, amount)
        returns (bool)
    {

        // Calculate tax that is owed
        uint128 tax_rate = Helper_Functions.calculate_tax(Global.total_staked);
        uint128 tax_amount = uint128(amount) * tax_rate / 10000;
        
        // Transfer to this contract and to recipient accordingly
        _transfer(msg.sender, address(this), tax_amount);

        // Distribute rewards accordingly
        distribute_rewards(
            tax_amount
        );

        // Execute normal transfer logic on difference
        return super.transfer(recipient, amount-tax_amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
        )
        public override
        can_transfer(sender, recipient)
        has_sufficient_balance(msg.sender, amount)
        has_sufficient_allowance(msg.sender, amount)
        returns (bool)
    {

        // Calculate tax that is owed
        uint128 tax_rate = Helper_Functions.calculate_tax(Global.total_staked);
        uint128 tax_amount = uint128(amount) * tax_rate / 10000;
        
        // Transfer to this contract and to recipient accordingly
        _transfer(sender, address(this), tax_amount);

        // Distribute rewards accordingly
        distribute_rewards(
            tax_amount
        );

        // Execute normal transfer from logic on difference
        return super.transferFrom(sender, recipient, amount-tax_amount);
    }
    


    // ------- Staking -------
    function stake_tokens(
        uint128 amount_staked,
        uint64 contract_index,
        address stake_address
        )
        public
        has_sufficient_balance(msg.sender,amount_staked)
        contract_exists(contract_index)
        stake_address_unused(stake_address)
    {

        _transfer(msg.sender, address(this), amount_staked);

        Data_Structures.Contract storage Contract = Contracts[contract_index];

        // Calculate fees
        Data_Structures.Split memory Split = Helper_Functions.calculate_inbound_fees(
            amount_staked,
            Contract.royalties,
            Global.total_staked
        );

        // Add fees to creator and minsterial 
        Contract.unclaimed_creator_rewards += Split.creator;
        Global.unclaimed_ministerial_rewards += Split.ministerial;

        // Distribute rewards accordingly
        distribute_rewards(
            Split.tax
        );

        // Get actual amount being staked
        uint128 amount_sub_fees = amount_staked - Split.total;

        // Setup a new stake
        Data_Structures.Stake memory Stake;
        Stake.amount_staked = amount_sub_fees;
        Stake.amount_staked_raw = amount_staked;
        Stake.staker_address = msg.sender;
        Stake.init_time = uint32(block.timestamp);

        
        if (Contract.total_staked != 0) {

            // Calculate delay nerf
            Stake.delay_nerf = Helper_Functions.delay_function(
                Contract.total_staked,
                Global.total_staked,
                Global.contract_count
            );
        
            // Handle finders fees
            Contract.total_multiple += uint160(amount_sub_fees) * uint160(Constants.decimals) / uint160(Contract.total_staked);
            Stake.multiple = Contract.total_multiple;
        }

        // Update the rest of the stuff
        Stake.historic_reward_units = Contract.reward_units;

        Stake.contract_index = contract_index;

        // Index Stake in Stakes struct on account --> stake address --> Stake...
        Stakes[stake_address] = Stake;

        // Update Contract
        Contract.total_staked += amount_sub_fees;

        // Update Global
        Global.total_staked += amount_sub_fees;

        // Emit event
        emit _stake_tokens(msg.sender, stake_address, contract_index, amount_sub_fees, uint32(block.timestamp));

    }

    function unstake_tokens(
        address stake_address,
        uint64 contract_index
        )
        public
        contract_exists(contract_index)
        stake_address_exists(stake_address)
    {

        // Distribute rewards accordingly
        distribute_rewards(
            0
        );

        // Claim any outstanding rewards
        claim_staking_rewards(
            stake_address,
            contract_index
        );

        Data_Structures.Stake storage Stake = Stakes[stake_address];
        Data_Structures.Contract storage Contract = Contracts[contract_index];

        // Decrement everything
        // Update Contract
        Contract.total_staked -= Stake.amount_staked;

        // Return the user his stake amount
        _transfer(address(this), msg.sender, Stake.amount_staked);

        // Update Global
        Global.total_staked -= Stake.amount_staked;

        // Emit event
        emit _unstake_tokens(msg.sender, stake_address, contract_index, Stake.amount_staked, uint32(block.timestamp));

        // Delete stake
        Stake.amount_staked = 0;

    }


    function claim_staking_rewards(
        address stake_address,
        uint64 contract_index
        )
        public
        contract_exists(contract_index)
        stake_address_exists(stake_address)
    {

        // Create storage / pointer references to make code cleaners
        Data_Structures.Stake storage Stake = Stakes[stake_address];
        Data_Structures.Contract storage Contract = Contracts[contract_index];

        // Exit early if no claim so state is not affected
        uint32 time_elapsed = uint32(block.timestamp) - Stake.init_time;
        if (time_elapsed < Stake.delay_nerf) {
            return;
        }

        // Get finders fees owed
        uint160 relevant_multiple = Contract.total_multiple - Stake.multiple;
        uint256 finders_fees =
            relevant_multiple *
            Stake.amount_staked_raw *
            Constants.finders_fee / 10000
            / Constants.decimals;

        // Update multiple to current
        Stake.multiple = Contract.total_multiple;

        // Get relevant portions for computation
        uint160 relevant_units =
            Contract.reward_units -
            Stake.historic_reward_units;
        
        // Update back to latest historic values
        Stake.historic_reward_units = Contract.reward_units;
 
        // Compute rewards
        uint256 rewards = 
            Stake.amount_staked *
            relevant_units /
            Constants.decimals;

        // Add in finders fees
        rewards += finders_fees;
     

        // Nerf rewards for delay only for the first claim
        if (Stake.has_been_delay_nerfed == false) {

            uint256 nerfed_rewards =
                rewards *
                (time_elapsed - Stake.delay_nerf) /
                time_elapsed;
            
            Global.unclaimed_ministerial_rewards += uint128(rewards - nerfed_rewards);

            rewards = nerfed_rewards;

            Stake.has_been_delay_nerfed = true;
        }

        // Send rewards
        _transfer(address(this), msg.sender, rewards);

        // Emit event
        emit _claim_staking_rewards(msg.sender, stake_address, contract_index, uint128(rewards), uint32(block.timestamp));

    }

    // ------- For Creators -------
    function create_staking_contract(
        address contract_address,
        address owner_address,
        uint16 royalties
        )
        public
        contract_unused(contract_address)
        onlyOwner // <-- will be updated after the presale
    {   

        // Init a new contract
        Data_Structures.Contract memory Contract;

        // Correct royalties to range and set
        Contract.royalties = Helper_Functions.fix_royalties(royalties);

        // Set contract address
        Contract.contract_address = contract_address;

        // Set owner address
        Contract.owner_address = owner_address;

        // Index contract in struct
        Contracts[Global.contract_count] = Contract;

        // For convenience
        Address_To_Contract[contract_address] = Global.contract_count;

        // Emit event
        emit _create_staking_contract(contract_address, Global.contract_count, owner_address, uint32(block.timestamp));
        
        // Increment total count of contracts
        Global.contract_count++;
    }

    function update_contract_owner(
        uint64 contract_index,
        address owner_address
        )
        public
        contract_exists(contract_index)
        only_address_owner(Contracts[contract_index].contract_address, Contracts[contract_index].owner_address)
    {
        Data_Structures.Contract storage Contract = Contracts[contract_index];
        Contract.owner_address = owner_address;
    }

    function claim_creator_rewards(
        uint64 contract_index
        )
        public
        contract_exists(contract_index)
        only_address_owner(Contracts[contract_index].contract_address, Contracts[contract_index].owner_address)
    {
        Data_Structures.Contract storage Contract = Contracts[contract_index];

        _transfer(address(this), msg.sender, Contract.unclaimed_creator_rewards);
        
        // Emit event
        emit _claim_creator_rewards(Contract.contract_address, contract_index, Contract.owner_address, Contract.unclaimed_creator_rewards, uint32(block.timestamp));

        Contract.unclaimed_creator_rewards = 0;
    }

    function update_royalties(
        uint64 contract_index,
        uint16 royalties
        )
        public
        contract_exists(contract_index)
        only_address_owner(Contracts[contract_index].contract_address, Contracts[contract_index].owner_address)
    {
        // Distribute rewards accordingly
        distribute_rewards(
            0
        );

        Data_Structures.Contract storage Contract = Contracts[contract_index];

        Contract.royalties = royalties;

        // Emit event
        emit _update_royalties(Contract.contract_address, contract_index, Contract.owner_address, royalties, uint32(block.timestamp));

    }

    // ------- Ministerial -------
    function withdraw_currency(uint8 currency_index) public onlyOwner {

        if (currency_index == 0) {
            require(address(this).balance > 0, "Insufficient balance");
            payable(owner()).transfer(address(this).balance);
        }
        else if (currency_index == 1) {
            IERC20Upgradeable usdt = IERC20Upgradeable(Constants.usdt_address);
            uint256 usdt_balance = usdt.balanceOf(address(this));
            usdt.transfer(owner(), usdt_balance);
        }
        else if (currency_index == 2) {
            IERC20Upgradeable usdc = IERC20Upgradeable(Constants.usdc_address);
            uint256 usdc_balance = usdc.balanceOf(address(this));
            usdc.transfer(owner(), usdc_balance);
        }
        
    }

    function claim_ministerial_rewards()
        public
        onlyOwner
    {
        _transfer(address(this), owner(), Global.unclaimed_ministerial_rewards);
        Global.unclaimed_ministerial_rewards = 0;
    }

    function enable_transfers(bool _transfers_allowed) public {
        transfers_allowed = _transfers_allowed;
    }

    function whitelist_address_for_transfer(address whitelisted_address, bool status) public {
        Whitelisted_For_Transfer[whitelisted_address] = status;
    }

    function batch_create_staking_contract(
        address[] memory contract_addresses,
        address[] memory owner_addresses,
        uint16[] memory royalties
        )
        public
        onlyOwner
    {
        for (uint256 index = 0; index < contract_addresses.length; index++) {
            create_staking_contract(
                contract_addresses[index],
                owner_addresses[index],
                royalties[index]
            );
        }
    }


    // ------- Internal Helpers -------
    function distribute_rewards(
        uint128 extra_reward
        )
        internal
    {
        // Get subsidy rewards
        uint128 subsidy_amount = Helper_Functions.calculate_subsidy_for_range(
            Global.last_subsidy_update_time,
            uint32(block.timestamp),
            Global.init_time
        );

        // Update last time we calculated subsidy
        Global.last_subsidy_update_time = uint32(block.timestamp);

        // Nerf the subsidy by the mint ratio
        // Add 25% cap within the mint nerf compared to amount stake
        uint256 mint_nerf_ratio = Global.total_minted > 4 * Global.total_staked ? uint256(4 * Global.total_staked) : uint256(Global.total_minted);
        uint128 claimed_subsidy_amount = uint128(uint256(subsidy_amount) * mint_nerf_ratio / uint256(Constants.max_presale_quantity));

        Global.nerfed_subsidy += subsidy_amount - claimed_subsidy_amount;

        uint128 current_weight = 0;
        uint64 contract_index = 0;
        bool found_index = false;

        for (uint8 i = 0; i < 3; i++) {
            
            // Get a random source
            Global.random_seed = uint256(keccak256(abi.encodePacked(
                Global.random_seed,
                Global.total_staked,
                extra_reward,
                block.difficulty
            )));

            // Convert to index, allowing 2 extra indexes which are going to default to total_staked = 0
            uint64 index = uint64(Global.random_seed % uint256(Global.contract_count+2));

            if (index >= Global.contract_count) {
                continue;
            }

            found_index = true;
 
            // Use greater equal so that if total staked is 0 for all chosen (somehow?) then it still will select something and not always index 0
            if (Contracts[index].total_staked >= current_weight) {
                current_weight = Contracts[index].total_staked;
                contract_index = index;
            }

        }

        if (found_index == false) {
            contract_index = uint64(Global.random_seed % uint256(Global.contract_count));
        }


        // Update based on the choice
        Data_Structures.Contract storage Contract = Contracts[contract_index];

        uint128 total_reward = claimed_subsidy_amount + extra_reward;

        if (Contract.total_staked != 0) {

            uint128 staker_rewards =
                (10000 - Contract.royalties) *
                total_reward /
                10000;

            Contract.reward_units +=
                uint160(Constants.decimals) *
                uint160(staker_rewards) / 
                uint160(Contract.total_staked);

            Contract.unclaimed_creator_rewards +=
                total_reward -
                staker_rewards;

        }
        else {
            // If there is nothing staked, everything goes to the owner
            Contract.unclaimed_creator_rewards += total_reward;
        }

        // Emit event
        emit _distribute_rewards(Contract.contract_address, contract_index, total_reward, Contract.reward_units, uint32(block.timestamp));
        
    }

    // ------- Internal Modifiers -------
    modifier only_address_owner(address contract_address, address owner_address) {

        // Check if the sender is the owner of ApeMax contract
        // or if this is an EOA, we will also allow the msg.sender == contract_address
        // or if is type ownable then we also check

        require(
            msg.sender == owner() ||
            msg.sender == contract_address ||
            msg.sender == owner_address,
            "Unauthorized Access"
        );

        _;
    }

    modifier contract_exists(uint64 contract_index) {
        require(
            Contracts[contract_index].contract_address != address(0),
            "No staking contract found at index"
        );
        _;
    }

    modifier contract_unused(address contract_address) {
        require(
            contract_address != address(0),
            "Invalid address"
        );

        require(
            Address_To_Contract[contract_address] == 0 &&
            Contracts[0].contract_address != contract_address,
            "Address already indexed for staking"
        );
        _;
    }

    modifier stake_address_exists(address stake_address) {
        require(
            Stakes[stake_address].staker_address == msg.sender,
            "Stake does not belong to sender"
        );

        require(
            Stakes[stake_address].amount_staked != 0 &&
            Stakes[stake_address].staker_address != address(0),
            "Staking address doesnt exist"
        );
        _;
    }

    modifier stake_address_unused(address stake_address) {
        require(
            stake_address != address(0),
            "Invalid staking address"
        );

        require(
            Stakes[stake_address].amount_staked == 0 &&
            Stakes[stake_address].staker_address == address(0),
            "Staking address already in use"
        );
        _;
    }

    modifier has_sufficient_balance(address sender, uint256 amount_required) {
        require(
            balanceOf(sender) >= amount_required,
            "Insufficient balance"
        );
        _;
    }

    modifier has_sufficient_allowance(address sender, uint256 amount_required) {
        require(
            allowance(sender, address(this)) >= amount_required,
            "Insufficient allowance"
        );
        _;
    }

    modifier can_transfer(address sender, address recipient) {
        require(
            transfers_allowed ||
            recipient == address(this) ||
            Whitelisted_For_Transfer[sender] == true,
            "Transfers are not authorized during the presale"
        );
        _;
    }    
    
    // ------- Readonly -------
    function get_contract(
        uint64 contract_index
        )
        public view
        returns (Data_Structures.Contract memory)
    {
        return Contracts[contract_index];
    }

    function get_stake(
        address stake_address
        )
        public view
        returns (Data_Structures.Stake memory)
    {
        return Stakes[stake_address];
    }

    function get_global()
        public view
        returns (Data_Structures.Global memory)
    {
        return Global;
    }   

}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

library Constants {

    // ------- Addresses -------

    // USDT address
    address internal constant usdt_address = 0xdAC17F958D2ee523a2206206994597C13D831ec7; // USDT

    // USDC address
    address internal constant usdc_address = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48; // USDC

    // Founder Wallets
    address internal constant founder_0 = 0x1FBBdc4b9c8CB458deb9305b0884c64D5DD7DBee; // S
    address internal constant founder_1 = 0xb96ddd73895FF973c85A0dcd882627c994d179C4; // P
    address internal constant founder_2 = 0x3e34a7014751dff1B5fE1aa340c35E8aa00C555E; // A
    address internal constant founder_3 = 0x7D3e5A497a03d294F17650c298F53Fb916421522; // F

    // Company
    address internal constant company_wallet = 0xfe7474462F0d520B3A41bBE3813dd9aE6B5190B8; // Owner

    // Price signing
    address internal constant pricing_authority = 0x83258645a1E202ED1EAA70cAA015DCfaD8557b3b; // Signer

    // ------- Values -------

    // Standard amount of decimals we usually use
    uint128 internal constant decimals = 10 ** 18; // Same as Ethereum

    // Token supply
    uint128 internal constant founder_reward = 50 * 10**9 * decimals; // 4x 50 Billion
    uint128 internal constant company_reward = 200 * 10**9 * decimals; // 200 Billion
    uint128 internal constant max_presale_quantity = 200 * 10**9 * decimals; // 200 Billion
    uint128 internal constant maximum_subsidy = 400 * 10**9 * decimals; // 400 Billion

    // Fees and taxes these are in x100 for some precision
    uint128 internal constant ministerial_fee = 100;
    uint128 internal constant finders_fee = 100;
    uint128 internal constant minimum_tax_rate = 50;
    uint128 internal constant maximum_tax_rate = 500;
    uint128 internal constant tax_rate_range = maximum_tax_rate - minimum_tax_rate;
    uint16 internal constant maximum_royalties = 2500;
    
    // Values for subsidy
    uint128 internal constant subsidy_duration = 946080000; // 30 years
    uint128 internal constant max_subsidy_rate = 3 * maximum_subsidy / subsidy_duration;


}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

library Data_Structures {

    struct Split {
        uint128 staker;
        uint128 tax;
        uint128 ministerial;
        uint128 creator;
        uint128 total;
    }

    struct Stake {

        // Used in calculating the finders fees owed to a user
        uint160 multiple;

        // The historic level of the reward units at the last claim...
        uint160 historic_reward_units;

        // Amount user has comitted to this stake
        uint128 amount_staked;

        // Amount user sent to stake, needed for fees calculation
        uint128 amount_staked_raw;

        // Address of the staker
        address staker_address;

        // The address of the contract corresponding to this stake
        uint64 contract_index;

        // The amount of time you need to wait for your first claim. Basically the waiting list time
        uint32 delay_nerf;

        // Stake init time
        uint32 init_time;

        // If the stake has been nerfed with regards to thr waitlist
        bool has_been_delay_nerfed;
        
    }


    struct Contract {

        // The total amount of units so we can know how much a token staked is worth
        // calculated as incoming rewards * 1-royalty / total staked
        uint160 reward_units;

        // Used in calculating staker finder fees
        uint160 total_multiple;

        // The total amount of staked comitted to this contract
        uint128 total_staked;

        // Rewards allocated for the creator of this stake, still unclaimed
        uint128 unclaimed_creator_rewards;

        // The contract address of this stake
        address contract_address;
        
        // The assigned address of the creator
        address owner_address;

        // The rate of the royalties configured by the creator
        uint16 royalties;
        
    }

    struct Global {

        // Used as a source of randomness
        uint256 random_seed;

        // The total amount staked globally
        uint128 total_staked;

        // The total amount of ApeMax minted
        uint128 total_minted;

        // Unclaimed amount of ministerial rewards
        uint128 unclaimed_ministerial_rewards;

        // Extra subsidy lost to mint nerf. In case we want to do something with it later
        uint128 nerfed_subsidy;

        // The number of contracts
        uint64 contract_count;

        // The time at which this is initialized
        uint32 init_time;

        // The last time we has to issue a tax, used for subsidy range calulcation
        uint32 last_subsidy_update_time;

        // The last time a token was minted
        uint32 last_minted_time;

    }

}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

import "./Data_Structures.sol";
import "./Constants.sol";

library Helper_Functions {

    // ------- Basic -------

    /*
        Adjust a value so it stays within a range
    */
    function fix_for_range(
        uint128 variable,
        uint128 min,
        uint128 max
        )
        public pure
        returns(uint128)

    {

        variable = variable < min ? min : variable;
        variable = variable > max ? max : variable;
        return variable;

    }

    /* 
        Adjust time to reference contract creation time and maximum time
        For cases where there is no maximum it can be used simply by passing max_time = current_time
    */
    function normalize_time(
        uint32 current_time,
        uint32 init_time,
        uint32 max_time
        )
        public pure
        returns (uint32)
    {   
        current_time = current_time < init_time ? init_time : current_time;
        uint32 relative_time = current_time - init_time;
        relative_time = relative_time > max_time ? max_time : relative_time;
        return relative_time;
    }

    // ------- Subsidy -------
    /*
        Calculates the integral of the subsidy, basically:
        ∫ C(t) dt = (A * t) + ((A * t^3) / (3 T^2)) - ((A * t^2)/T)
    */
    function subsidy_integral(
        uint32 time,
        uint32 init_time
        )
        public pure
        returns(uint256)
    {
        // Cast up then down
        uint256 normalized_time = uint256(normalize_time(time, init_time, uint32(Constants.subsidy_duration)));
        uint256 max_subsidy_rate = uint256(Constants.max_subsidy_rate);
        uint256 subsidy_duration = uint256(Constants.subsidy_duration);

        uint256 integral =
            (max_subsidy_rate * normalized_time) +
            ((max_subsidy_rate * normalized_time ** 3) / (3 * subsidy_duration ** 2)) -
            ((max_subsidy_rate * normalized_time ** 2) / subsidy_duration);
        
        return integral;
    }

    /*
        Returns the total subsidy to be distributed in a range of time
    */
    function calculate_subsidy_for_range(
        uint32 start_time,
        uint32 end_time,
        uint32 init_time // Time the contract was initialized
        )
        public pure
        returns(uint128)
    {
        uint256 integral_range =  
            subsidy_integral(end_time, init_time) -
            subsidy_integral(start_time, init_time);

        return uint128(integral_range);
    }

    // ------- Fees -------
    /*
        Returns percentage tax at current time
        Tax ranges from 1% to 5%
        In 100x denomination
    */
    function calculate_tax(
        uint128 total_staked
        )
        public pure
        returns(uint128)
    {

        if (total_staked >= Constants.maximum_subsidy) {
            return Constants.maximum_tax_rate;
        }

        return
            Constants.minimum_tax_rate +
            Constants.tax_rate_range *
            total_staked /
            Constants.maximum_subsidy;

    }

    /*
        Calculates fees to be shared amongst all parties when a new stake comes in
    */
    function calculate_inbound_fees(
        uint128 amount_staked,
        uint16 royalties,
        uint128 total_staked
        )
        public pure
        returns(Data_Structures.Split memory)
    {
        Data_Structures.Split memory inbound_fees;
        
        inbound_fees.staker = Constants.finders_fee * amount_staked / 10000;
        inbound_fees.ministerial = Constants.ministerial_fee * amount_staked / 10000;
        inbound_fees.tax = amount_staked * calculate_tax(total_staked) / 10000;
        inbound_fees.creator = amount_staked * royalties / 1000000;
        
        inbound_fees.total =
            inbound_fees.staker +
            inbound_fees.ministerial + 
            inbound_fees.tax +
            inbound_fees.creator;

        return inbound_fees;
    }

    /*
        Fixes the royalties values if needed
    */
    function fix_royalties(
        uint16 royalties
        )
        public pure
        returns (uint16)
    {
        return royalties > Constants.maximum_royalties ? Constants.maximum_royalties : royalties;
    }

    // ------- Delay -------
    /*
        Determins the amount of delay received
        It is here with the share since the calculation are inherently linked
        More share = more delay...

        switched to -->
        f(a, t, n) = (315,360,000 * (a/t)^3) * (n/10000)
    */
    function delay_function(
        uint128 amount_staked,
        uint128 total_staked,
        uint64 number_of_staking_contracts
        )
        public pure
        returns(uint32)
    {
        uint256 decimals = 10**18;
        uint256 a = uint256(amount_staked);
        uint256 t = uint256(total_staked);
        uint256 n = uint256(number_of_staking_contracts);

        uint256 delay =
            315360000 *
            (decimals * a / t)**3 *
            n /
            10000 /
            (decimals**3);
        
        if (delay > uint256(type(uint32).max)) {
            return type(uint32).max;
        }

        return uint32(delay);


    }

    // ------- Presale -------
    function verify_minting_authorization(
        uint128 total_minted,
        uint256 block_time,
        uint128 amount_payable,
        uint128 quantity,
        uint32 timestamp,
        uint8 currency_index,
        uint8 v, bytes32 r, bytes32 s
        )
        public pure
    {
        // Sanity checks
        require(total_minted + quantity < Constants.max_presale_quantity, "Exceeds maximum total supply");
        require(timestamp + 60 * 60 * 24 > block_time, "Pricing has expired");

        // Verify signature
        require(ecrecover(keccak256(
          abi.encodePacked(
            "\x19Ethereum Signed Message:\n32",
            keccak256(abi.encodePacked(amount_payable, quantity, timestamp, currency_index))
        )), v, r, s) == Constants.pricing_authority, "Invalid signature");
    }

}