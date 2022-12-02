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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

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
contract ERC20 is Context, IERC20, IERC20Metadata {
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
    constructor(string memory name_, string memory symbol_) {
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
library SafeMath {
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

pragma solidity >=0.6.12;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./SwapUtils.sol";

/**
 * @title AmplificationUtils library
 * @notice A library to calculate and ramp the A parameter of a given `SwapUtils.Swap` struct.
 * This library assumes the struct is fully validated.
 */
library AmplificationUtils {
    using SafeMath for uint256;

    event RampA(
        uint256 oldA,
        uint256 newA,
        uint256 initialTime,
        uint256 futureTime
    );
    event StopRampA(uint256 currentA, uint256 time);

    // Constant values used in ramping A calculations
    uint256 public constant A_PRECISION = 100;
    uint256 public constant MAX_A = 10**6;
    uint256 private constant MAX_A_CHANGE = 2;
    uint256 private constant MIN_RAMP_TIME = 14 days;

    /**
     * @notice Return A, the amplification coefficient * n * (n - 1)
     * @dev See the StableSwap paper for details
     * @param self Swap struct to read from
     * @return A parameter
     */
    function getA(SwapUtils.Swap storage self) external view returns (uint256) {
        return _getAPrecise(self).div(A_PRECISION);
    }

    /**
     * @notice Return A in its raw precision
     * @dev See the StableSwap paper for details
     * @param self Swap struct to read from
     * @return A parameter in its raw precision form
     */
    function getAPrecise(SwapUtils.Swap storage self)
        external
        view
        returns (uint256)
    {
        return _getAPrecise(self);
    }

    /**
     * @notice Return A in its raw precision
     * @dev See the StableSwap paper for details
     * @param self Swap struct to read from
     * @return A parameter in its raw precision form
     */
    function _getAPrecise(SwapUtils.Swap storage self)
        internal
        view
        returns (uint256)
    {
        uint256 t1 = self.futureATime; // time when ramp is finished
        uint256 a1 = self.futureA; // final A value when ramp is finished

        if (block.timestamp < t1) {
            uint256 t0 = self.initialATime; // time when ramp is started
            uint256 a0 = self.initialA; // initial A value when ramp is started
            if (a1 > a0) {
                // a0 + (a1 - a0) * (block.timestamp - t0) / (t1 - t0)
                return
                    a0.add(
                        a1.sub(a0).mul(block.timestamp.sub(t0)).div(t1.sub(t0))
                    );
            } else {
                // a0 - (a0 - a1) * (block.timestamp - t0) / (t1 - t0)
                return
                    a0.sub(
                        a0.sub(a1).mul(block.timestamp.sub(t0)).div(t1.sub(t0))
                    );
            }
        } else {
            return a1;
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
    ) external {
        require(
            block.timestamp >= self.initialATime.add(1 days),
            "Wait 1 day before starting ramp"
        );
        require(
            futureTime_ >= block.timestamp.add(MIN_RAMP_TIME),
            "Insufficient ramp time"
        );
        require(
            futureA_ > 0 && futureA_ < MAX_A,
            "futureA_ must be > 0 and < MAX_A"
        );

        uint256 initialAPrecise = _getAPrecise(self);
        uint256 futureAPrecise = futureA_.mul(A_PRECISION);

        if (futureAPrecise < initialAPrecise) {
            require(
                futureAPrecise.mul(MAX_A_CHANGE) >= initialAPrecise,
                "futureA_ is too small"
            );
        } else {
            require(
                futureAPrecise <= initialAPrecise.mul(MAX_A_CHANGE),
                "futureA_ is too large"
            );
        }

        self.initialA = initialAPrecise;
        self.futureA = futureAPrecise;
        self.initialATime = block.timestamp;
        self.futureATime = futureTime_;

        emit RampA(
            initialAPrecise,
            futureAPrecise,
            block.timestamp,
            futureTime_
        );
    }

    /**
     * @notice Stops ramping A immediately. Once this function is called, rampA()
     * cannot be called for another 24 hours
     * @param self Swap struct to update
     */
    function stopRampA(SwapUtils.Swap storage self) external {
        require(self.futureATime > block.timestamp, "Ramp is already stopped");

        uint256 currentA = _getAPrecise(self);
        self.initialA = currentA;
        self.futureA = currentA;
        self.initialATime = block.timestamp;
        self.futureATime = block.timestamp;

        emit StopRampA(currentA, block.timestamp);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;

interface IAllowlist {
    function getPoolAccountLimit(address poolAddress)
        external
        view
        returns (uint256);

    function getPoolCap(address poolAddress) external view returns (uint256);

    function verifyAddress(address account, bytes32[] calldata merkleProof)
        external
        returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./IAllowlist.sol";

interface ISwap {
    // pool data view functions
    function getA() external view returns (uint256);

    function getAPrecise() external view returns (uint256);

    function getAllowlist() external view returns (IAllowlist);

    function getToken(uint8 index) external view returns (IERC20);

    function getTokenIndex(address tokenAddress) external view returns (uint8);

    function getTokenBalance(uint8 index) external view returns (uint256);

    function getVirtualPrice() external view returns (uint256);

    function owner() external view returns (address);

    function isGuarded() external view returns (bool);

    function paused() external view returns (bool);

    function swapStorage()
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            address
        );

    // min return calculation functions
    function calculateSwap(
        uint8 tokenIndexFrom,
        uint8 tokenIndexTo,
        uint256 dx
    ) external view returns (uint256);

    function calculateTokenAmount(uint256[] calldata amounts, bool deposit)
        external
        view
        returns (uint256);

    function calculateRemoveLiquidity(uint256 amount)
        external
        view
        returns (uint256[] memory);

    function calculateRemoveLiquidityOneToken(
        uint256 tokenAmount,
        uint8 tokenIndex
    ) external view returns (uint256 availableTokenAmount);

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

    function swap(
        uint8 tokenIndexFrom,
        uint8 tokenIndexTo,
        uint256 dx,
        uint256 minDy,
        uint256 deadline
    ) external returns (uint256);

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "./interfaces/ISwap.sol";

/**
 * @title Liquidity Provider Token
 * @notice This token is an ERC20 detailed token with added capability to be minted by the owner.
 * It is used to represent user's shares when providing liquidity to swap contracts.
 * @dev Only Swap contracts should initialize and own LPToken contracts.
 */
contract LPToken is ERC20BurnableUpgradeable, OwnableUpgradeable {
    using SafeMathUpgradeable for uint256;

    /**
     * @notice Initializes this LPToken contract with the given name and symbol
     * @dev The caller of this function will become the owner. A Swap contract should call this
     * in its initializer function.
     * @param name name of this token
     * @param symbol symbol of this token
     */
    function initialize(string memory name, string memory symbol)
        external
        initializer
        returns (bool)
    {
        __Context_init_unchained();
        __ERC20_init_unchained(name, symbol);
        __Ownable_init_unchained();
        return true;
    }

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
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

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
        return (difference(a, b) <= 1);
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

/**
 * @title OwnerPausable
 * @notice An ownable contract allows the owner to pause and unpause the
 * contract without a delay.
 * @dev Only methods using the provided modifiers will be paused.
 */
abstract contract OwnerPausableUpgradeable is
    OwnableUpgradeable,
    PausableUpgradeable
{
    function __OwnerPausable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
        __Pausable_init_unchained();
    }

    /**
     * @notice Pause the contract. Revert if already paused.
     */
    function pause() external onlyOwner {
        PausableUpgradeable._pause();
    }

    /**
     * @notice Unpause the contract. Revert if already unpaused.
     */
    function unpause() external onlyOwner {
        PausableUpgradeable._unpause();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./OwnerPausableUpgradeable.sol";
import "./SwapUtils.sol";
import "./AmplificationUtils.sol";

/**
 * @title Swap - A StableSwap implementation in solidity.
 * @notice This contract is responsible for custody of closely pegged assets (eg. group of stablecoins)
 * and automatic market making system. Users become an LP (Liquidity Provider) by depositing their tokens
 * in desired ratios for an exchange of the pool token that represents their share of the pool.
 * Users can burn pool tokens and withdraw their share of token(s).
 *
 * Each time a swap between the pooled tokens happens, a set fee incurs which effectively gets
 * distributed to the LPs.
 *
 * In case of emergencies, admin can pause additional deposits, swaps, or single-asset withdraws - which
 * stops the ratio of the tokens in the pool from changing.
 * Users can always withdraw their tokens via multi-asset withdraws.
 *
 * @dev Most of the logic is stored as a library `SwapUtils` for the sake of reducing contract's
 * deployment size.
 */
contract Swap is OwnerPausableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using SwapUtils for SwapUtils.Swap;
    using AmplificationUtils for SwapUtils.Swap;

    // Struct storing data responsible for automatic market maker functionalities. In order to
    // access this data, this contract uses SwapUtils library. For more details, see SwapUtils.sol
    SwapUtils.Swap public swapStorage;

    // Maps token address to an index in the pool. Used to prevent duplicate tokens in the pool.
    // getTokenIndex function also relies on this mapping to retrieve token index.
    mapping(address => uint8) private tokenIndexes;

    /*** EVENTS ***/

    // events replicated from SwapUtils to make the ABI easier for dumb
    // clients
    event TokenSwap(
        address indexed buyer,
        uint256 tokensSold,
        uint256 tokensBought,
        uint128 soldId,
        uint128 boughtId
    );
    event AddLiquidity(
        address indexed provider,
        uint256[] tokenAmounts,
        uint256[] fees,
        uint256 invariant,
        uint256 lpTokenSupply
    );
    event RemoveLiquidity(
        address indexed provider,
        uint256[] tokenAmounts,
        uint256 lpTokenSupply
    );
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
    event RampA(
        uint256 oldA,
        uint256 newA,
        uint256 initialTime,
        uint256 futureTime
    );
    event StopRampA(uint256 currentA, uint256 time);

    /**
     * @notice Initializes this Swap contract with the given parameters.
     * This will also clone a LPToken contract that represents users'
     * LP positions. The owner of LPToken will be this contract - which means
     * only this contract is allowed to mint/burn tokens.
     *
     * @param _pooledTokens an array of ERC20s this pool will accept
     * @param decimals the decimals to use for each pooled token,
     * eg 8 for WBTC. Cannot be larger than POOL_PRECISION_DECIMALS
     * @param lpTokenName the long-form name of the token to be deployed
     * @param lpTokenSymbol the short symbol for the token to be deployed
     * @param _a the amplification coefficient * n * (n - 1). See the
     * StableSwap paper for details
     * @param _fee default swap fee to be initialized with
     * @param _adminFee default adminFee to be initialized with
     * @param lpTokenTargetAddress the address of an existing LPToken contract to use as a target
     */
    function initialize(
        IERC20[] memory _pooledTokens,
        uint8[] memory decimals,
        string memory lpTokenName,
        string memory lpTokenSymbol,
        uint256 _a,
        uint256 _fee,
        uint256 _adminFee,
        address lpTokenTargetAddress
    ) public payable virtual initializer {
        __OwnerPausable_init();
        __ReentrancyGuard_init();
        // Check _pooledTokens and precisions parameter
        require(_pooledTokens.length > 1, "_pooledTokens.length <= 1");
        require(_pooledTokens.length <= 32, "_pooledTokens.length > 32");
        require(
            _pooledTokens.length == decimals.length,
            "_pooledTokens decimals mismatch"
        );

        uint256[] memory precisionMultipliers = new uint256[](decimals.length);

        for (uint8 i = 0; i < _pooledTokens.length; i++) {
            if (i > 0) {
                // Check if index is already used. Check if 0th element is a duplicate.
                require(
                    tokenIndexes[address(_pooledTokens[i])] == 0 &&
                        _pooledTokens[0] != _pooledTokens[i],
                    "Duplicate tokens"
                );
            }
            require(
                address(_pooledTokens[i]) != address(0),
                "The 0 address isn't an ERC-20"
            );
            require(
                decimals[i] <= SwapUtils.POOL_PRECISION_DECIMALS,
                "Token decimals exceeds max"
            );
            precisionMultipliers[i] =
                10 **
                    uint256(SwapUtils.POOL_PRECISION_DECIMALS).sub(
                        uint256(decimals[i])
                    );
            tokenIndexes[address(_pooledTokens[i])] = i;
        }

        // Check _a, _fee, _adminFee, _withdrawFee parameters
        require(_a < AmplificationUtils.MAX_A, "_a exceeds maximum");
        require(_fee < SwapUtils.MAX_SWAP_FEE, "_fee exceeds maximum");
        require(
            _adminFee < SwapUtils.MAX_ADMIN_FEE,
            "_adminFee exceeds maximum"
        );

        // Clone and initialize a LPToken contract
        LPToken lpToken = LPToken(Clones.clone(lpTokenTargetAddress));
        require(
            lpToken.initialize(lpTokenName, lpTokenSymbol),
            "could not init lpToken clone"
        );

        // Initialize swapStorage struct
        swapStorage.lpToken = lpToken;
        swapStorage.pooledTokens = _pooledTokens;
        swapStorage.tokenPrecisionMultipliers = precisionMultipliers;
        swapStorage.balances = new uint256[](_pooledTokens.length);
        swapStorage.initialA = _a.mul(AmplificationUtils.A_PRECISION);
        swapStorage.futureA = _a.mul(AmplificationUtils.A_PRECISION);
        // swapStorage.initialATime = 0;
        // swapStorage.futureATime = 0;
        swapStorage.swapFee = _fee;
        swapStorage.adminFee = _adminFee;
    }

    /*** MODIFIERS ***/

    /**
     * @notice Modifier to check deadline against current timestamp
     * @param deadline latest timestamp to accept this transaction
     */
    modifier deadlineCheck(uint256 deadline) {
        require(block.timestamp <= deadline, "Deadline not met");
        _;
    }

    /*** VIEW FUNCTIONS ***/

    /**
     * @notice Return A, the amplification coefficient * n * (n - 1)
     * @dev See the StableSwap paper for details
     * @return A parameter
     */
    function getA() external view virtual returns (uint256) {
        return swapStorage.getA();
    }

    /**
     * @notice Return A in its raw precision form
     * @dev See the StableSwap paper for details
     * @return A parameter in its raw precision form
     */
    function getAPrecise() external view virtual returns (uint256) {
        return swapStorage.getAPrecise();
    }

    /**
     * @notice Return address of the pooled token at given index. Reverts if tokenIndex is out of range.
     * @param index the index of the token
     * @return address of the token at given index
     */
    function getToken(uint8 index) public view virtual returns (IERC20) {
        require(index < swapStorage.pooledTokens.length, "Out of range");
        return swapStorage.pooledTokens[index];
    }

    /**
     * @notice Return the index of the given token address. Reverts if no matching
     * token is found.
     * @param tokenAddress address of the token
     * @return the index of the given token address
     */
    function getTokenIndex(address tokenAddress)
        public
        view
        virtual
        returns (uint8)
    {
        uint8 index = tokenIndexes[tokenAddress];
        require(
            address(getToken(index)) == tokenAddress,
            "Token does not exist"
        );
        return index;
    }

    /**
     * @notice Return current balance of the pooled token at given index
     * @param index the index of the token
     * @return current balance of the pooled token at given index with token's native precision
     */
    function getTokenBalance(uint8 index)
        external
        view
        virtual
        returns (uint256)
    {
        require(index < swapStorage.pooledTokens.length, "Index out of range");
        return swapStorage.balances[index];
    }

    /**
     * @notice Get the virtual price, to help calculate profit
     * @return the virtual price, scaled to the POOL_PRECISION_DECIMALS
     */
    function getVirtualPrice() external view virtual returns (uint256) {
        return swapStorage.getVirtualPrice();
    }

    /**
     * @notice Calculate amount of tokens you receive on swap
     * @param tokenIndexFrom the token the user wants to sell
     * @param tokenIndexTo the token the user wants to buy
     * @param dx the amount of tokens the user wants to sell. If the token charges
     * a fee on transfers, use the amount that gets transferred after the fee.
     * @return amount of tokens the user will receive
     */
    function calculateSwap(
        uint8 tokenIndexFrom,
        uint8 tokenIndexTo,
        uint256 dx
    ) external view virtual returns (uint256) {
        return swapStorage.calculateSwap(tokenIndexFrom, tokenIndexTo, dx);
    }

    /**
     * @notice A simple method to calculate prices from deposits or
     * withdrawals, excluding fees but including slippage. This is
     * helpful as an input into the various "min" parameters on calls
     * to fight front-running
     *
     * @dev This shouldn't be used outside frontends for user estimates.
     *
     * @param amounts an array of token amounts to deposit or withdrawal,
     * corresponding to pooledTokens. The amount should be in each
     * pooled token's native precision. If a token charges a fee on transfers,
     * use the amount that gets transferred after the fee.
     * @param deposit whether this is a deposit or a withdrawal
     * @return token amount the user will receive
     */
    function calculateTokenAmount(uint256[] calldata amounts, bool deposit)
        external
        view
        virtual
        returns (uint256)
    {
        return swapStorage.calculateTokenAmount(amounts, deposit);
    }

    /**
     * @notice A simple method to calculate amount of each underlying
     * tokens that is returned upon burning given amount of LP tokens
     * @param amount the amount of LP tokens that would be burned on withdrawal
     * @return array of token balances that the user will receive
     */
    function calculateRemoveLiquidity(uint256 amount)
        external
        view
        virtual
        returns (uint256[] memory)
    {
        return swapStorage.calculateRemoveLiquidity(amount);
    }

    /**
     * @notice Calculate the amount of underlying token available to withdraw
     * when withdrawing via only single token
     * @param tokenAmount the amount of LP token to burn
     * @param tokenIndex index of which token will be withdrawn
     * @return availableTokenAmount calculated amount of underlying token
     * available to withdraw
     */
    function calculateRemoveLiquidityOneToken(
        uint256 tokenAmount,
        uint8 tokenIndex
    ) external view virtual returns (uint256 availableTokenAmount) {
        return swapStorage.calculateWithdrawOneToken(tokenAmount, tokenIndex);
    }

    /**
     * @notice This function reads the accumulated amount of admin fees of the token with given index
     * @param index Index of the pooled token
     * @return admin's token balance in the token's precision
     */
    function getAdminBalance(uint256 index)
        external
        view
        virtual
        returns (uint256)
    {
        return swapStorage.getAdminBalance(index);
    }

    /*** STATE MODIFYING FUNCTIONS ***/

    /**
     * @notice Swap two tokens using this pool
     * @param tokenIndexFrom the token the user wants to swap from
     * @param tokenIndexTo the token the user wants to swap to
     * @param dx the amount of tokens the user wants to swap from
     * @param minDy the min amount the user would like to receive, or revert.
     * @param deadline latest timestamp to accept this transaction
     */
    function swap(
        uint8 tokenIndexFrom,
        uint8 tokenIndexTo,
        uint256 dx,
        uint256 minDy,
        uint256 deadline
    )
        external
        payable
        virtual
        nonReentrant
        whenNotPaused
        deadlineCheck(deadline)
        returns (uint256)
    {
        return swapStorage.swap(tokenIndexFrom, tokenIndexTo, dx, minDy);
    }

    /**
     * @notice Add liquidity to the pool with the given amounts of tokens
     * @param amounts the amounts of each token to add, in their native precision
     * @param minToMint the minimum LP tokens adding this amount of liquidity
     * should mint, otherwise revert. Handy for front-running mitigation
     * @param deadline latest timestamp to accept this transaction
     * @return amount of LP token user minted and received
     */
    function addLiquidity(
        uint256[] calldata amounts,
        uint256 minToMint,
        uint256 deadline
    )
        external
        payable
        virtual
        nonReentrant
        whenNotPaused
        deadlineCheck(deadline)
        returns (uint256)
    {
        return swapStorage.addLiquidity(amounts, minToMint);
    }

    /**
     * @notice Burn LP tokens to remove liquidity from the pool. Withdraw fee that decays linearly
     * over period of 4 weeks since last deposit will apply.
     * @dev Liquidity can always be removed, even when the pool is paused.
     * @param amount the amount of LP tokens to burn
     * @param minAmounts the minimum amounts of each token in the pool
     *        acceptable for this burn. Useful as a front-running mitigation
     * @param deadline latest timestamp to accept this transaction
     * @return amounts of tokens user received
     */
    function removeLiquidity(
        uint256 amount,
        uint256[] calldata minAmounts,
        uint256 deadline
    )
        external
        payable
        virtual
        nonReentrant
        deadlineCheck(deadline)
        returns (uint256[] memory)
    {
        return swapStorage.removeLiquidity(amount, minAmounts);
    }

    /**
     * @notice Remove liquidity from the pool all in one token. Withdraw fee that decays linearly
     * over period of 4 weeks since last deposit will apply.
     * @param tokenAmount the amount of the token you want to receive
     * @param tokenIndex the index of the token you want to receive
     * @param minAmount the minimum amount to withdraw, otherwise revert
     * @param deadline latest timestamp to accept this transaction
     * @return amount of chosen token user received
     */
    function removeLiquidityOneToken(
        uint256 tokenAmount,
        uint8 tokenIndex,
        uint256 minAmount,
        uint256 deadline
    )
        external
        payable
        virtual
        nonReentrant
        whenNotPaused
        deadlineCheck(deadline)
        returns (uint256)
    {
        return
            swapStorage.removeLiquidityOneToken(
                tokenAmount,
                tokenIndex,
                minAmount
            );
    }

    /**
     * @notice Remove liquidity from the pool, weighted differently than the
     * pool's current balances. Withdraw fee that decays linearly
     * over period of 4 weeks since last deposit will apply.
     * @param amounts how much of each token to withdraw
     * @param maxBurnAmount the max LP token provider is willing to pay to
     * remove liquidity. Useful as a front-running mitigation.
     * @param deadline latest timestamp to accept this transaction
     * @return amount of LP tokens burned
     */
    function removeLiquidityImbalance(
        uint256[] calldata amounts,
        uint256 maxBurnAmount,
        uint256 deadline
    )
        external
        payable
        virtual
        nonReentrant
        whenNotPaused
        deadlineCheck(deadline)
        returns (uint256)
    {
        return swapStorage.removeLiquidityImbalance(amounts, maxBurnAmount);
    }

    /*** ADMIN FUNCTIONS ***/

    /**
     * @notice Withdraw all admin fees to the contract owner
     */
    function withdrawAdminFees() external payable virtual onlyOwner {
        swapStorage.withdrawAdminFees(owner());
    }

    /**
     * @notice Update the admin fee. Admin fee takes portion of the swap fee.
     * @param newAdminFee new admin fee to be applied on future transactions
     */
    function setAdminFee(uint256 newAdminFee) external payable onlyOwner {
        swapStorage.setAdminFee(newAdminFee);
    }

    /**
     * @notice Update the swap fee to be applied on swaps
     * @param newSwapFee new swap fee to be applied on future transactions
     */
    function setSwapFee(uint256 newSwapFee) external payable onlyOwner {
        swapStorage.setSwapFee(newSwapFee);
    }

    /**
     * @notice Start ramping up or down A parameter towards given futureA and futureTime
     * Checks if the change is too rapid, and commits the new A value only when it falls under
     * the limit range.
     * @param futureA the new A to ramp towards
     * @param futureTime timestamp when the new A should be reached
     */
    function rampA(uint256 futureA, uint256 futureTime)
        external
        payable
        onlyOwner
    {
        swapStorage.rampA(futureA, futureTime);
    }

    /**
     * @notice Stop ramping A immediately. Reverts if ramp A is already stopped.
     */
    function stopRampA() external payable onlyOwner {
        swapStorage.stopRampA();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./AmplificationUtils.sol";
import "./LPToken.sol";
import "./MathUtils.sol";

/**
 * @title SwapUtils library
 * @notice A library to be used within Swap.sol. Contains functions responsible for custody and AMM functionalities.
 * @dev Contracts relying on this library must initialize SwapUtils.Swap struct then use this library
 * for SwapUtils.Swap struct. Note that this library contains both functions called by users and admins.
 * Admin functions should be protected within contracts using this library.
 */
library SwapUtils {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using MathUtils for uint256;

    /*** EVENTS ***/

    event TokenSwap(
        address indexed buyer,
        uint256 tokensSold,
        uint256 tokensBought,
        uint128 soldId,
        uint128 boughtId
    );
    event AddLiquidity(
        address indexed provider,
        uint256[] tokenAmounts,
        uint256[] fees,
        uint256 invariant,
        uint256 lpTokenSupply
    );
    event RemoveLiquidity(
        address indexed provider,
        uint256[] tokenAmounts,
        uint256 lpTokenSupply
    );
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

    struct Swap {
        // variables around the ramp management of A,
        // the amplification coefficient * n * (n - 1)
        // see https://www.curve.fi/stableswap-paper.pdf for details
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
        // multipliers for each pooled token's precision to get to POOL_PRECISION_DECIMALS
        // for example, TBTC has 18 decimals, so the multiplier should be 1. WBTC
        // has 8, so the multiplier should be 10 ** 18 / 10 ** 8 => 10 ** 10
        uint256[] tokenPrecisionMultipliers;
        // the pool balance of each token, in the token's precision
        // the contract's actual token balance might differ
        uint256[] balances;
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

    // the precision all pools tokens will be converted to
    uint8 public constant POOL_PRECISION_DECIMALS = 18;

    // the denominator used to calculate admin and LP fees. For example, an
    // LP fee might be something like tradeAmount.mul(fee).div(FEE_DENOMINATOR)
    uint256 private constant FEE_DENOMINATOR = 10**10;

    // Max swap fee is 1% or 100bps of each swap
    uint256 public constant MAX_SWAP_FEE = 10**8;

    // Max adminFee is 100% of the swapFee
    // adminFee does not add additional fee on top of swapFee
    // Instead it takes a certain % of the swapFee. Therefore it has no impact on the
    // users but only on the earnings of LPs
    uint256 public constant MAX_ADMIN_FEE = 10**10;

    // Constant value used as max loop limit
    uint256 private constant MAX_LOOP_LIMIT = 256;

    /*** VIEW & PURE FUNCTIONS ***/

    function _getAPrecise(Swap storage self) internal view returns (uint256) {
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
    ) external view returns (uint256) {
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
    ) internal view returns (uint256, uint256) {
        uint256 dy;
        uint256 newY;
        uint256 currentY;

        (dy, newY, currentY) = calculateWithdrawOneTokenDY(
            self,
            tokenIndex,
            tokenAmount,
            totalSupply
        );

        // dy_0 (without fees)
        // dy, dy_0 - dy

        uint256 dySwapFee = currentY
            .sub(newY)
            .div(self.tokenPrecisionMultipliers[tokenIndex])
            .sub(dy);

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

        require(tokenIndex < xp.length, "Token index out of range");

        CalculateWithdrawOneTokenDYInfo
            memory v = CalculateWithdrawOneTokenDYInfo(0, 0, 0, 0, 0);
        v.preciseA = _getAPrecise(self);
        v.d0 = getD(xp, v.preciseA);
        v.d1 = v.d0.sub(tokenAmount.mul(v.d0).div(totalSupply));

        require(tokenAmount <= xp[tokenIndex], "Withdraw exceeds available");

        v.newY = getYD(v.preciseA, tokenIndex, xp, v.d1);

        uint256[] memory xpReduced = new uint256[](xp.length);

        v.feePerToken = _feePerToken(self.swapFee, xp.length);
        for (uint256 i = 0; i < xp.length; i++) {
            uint256 xpi = xp[i];
            // if i == tokenIndex, dxExpected = xp[i] * d1 / d0 - newY
            // else dxExpected = xp[i] - (xp[i] * d1 / d0)
            // xpReduced[i] -= dxExpected * fee / FEE_DENOMINATOR
            xpReduced[i] = xpi.sub(
                (
                    (i == tokenIndex)
                        ? xpi.mul(v.d1).div(v.d0).sub(v.newY)
                        : xpi.sub(xpi.mul(v.d1).div(v.d0))
                ).mul(v.feePerToken).div(FEE_DENOMINATOR)
            );
        }

        uint256 dy = xpReduced[tokenIndex].sub(
            getYD(v.preciseA, tokenIndex, xpReduced, v.d1)
        );
        dy = dy.sub(1).div(self.tokenPrecisionMultipliers[tokenIndex]);

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
     * @param a the amplification coefficient * n * (n - 1). See the StableSwap paper for details.
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
        uint256 nA = a.mul(numTokens);

        for (uint256 i = 0; i < numTokens; i++) {
            if (i != tokenIndex) {
                s = s.add(xp[i]);
                c = c.mul(d).div(xp[i].mul(numTokens));
                // If we were to protect the division loss we would have to keep the denominator separate
                // and divide at the end. However this leads to overflow with large numTokens or/and D.
                // c = c * D * D * D * ... overflow!
            }
        }
        c = c.mul(d).mul(AmplificationUtils.A_PRECISION).div(nA.mul(numTokens));

        uint256 b = s.add(d.mul(AmplificationUtils.A_PRECISION).div(nA));
        uint256 yPrev;
        uint256 y = d;
        for (uint256 i = 0; i < MAX_LOOP_LIMIT; i++) {
            yPrev = y;
            y = y.mul(y).add(c).div(y.mul(2).add(b).sub(d));
            if (y.within1(yPrev)) {
                return y;
            }
        }
        revert("Approximation did not converge");
    }

    /**
     * @notice Get D, the StableSwap invariant, based on a set of balances and a particular A.
     * @param xp a precision-adjusted set of pool balances. Array should be the same cardinality
     * as the pool.
     * @param a the amplification coefficient * n * (n - 1) in A_PRECISION.
     * See the StableSwap paper for details
     * @return the invariant, at the precision of the pool
     */
    function getD(uint256[] memory xp, uint256 a)
        internal
        pure
        returns (uint256)
    {
        uint256 numTokens = xp.length;
        uint256 s;
        for (uint256 i = 0; i < numTokens; i++) {
            s = s.add(xp[i]);
        }
        if (s == 0) {
            return 0;
        }

        uint256 prevD;
        uint256 d = s;
        uint256 nA = a.mul(numTokens);

        for (uint256 i = 0; i < MAX_LOOP_LIMIT; i++) {
            uint256 dP = d;
            for (uint256 j = 0; j < numTokens; j++) {
                dP = dP.mul(d).div(xp[j].mul(numTokens));
                // If we were to protect the division loss we would have to keep the denominator separate
                // and divide at the end. However this leads to overflow with large numTokens or/and D.
                // dP = dP * D * D * D * ... overflow!
            }
            prevD = d;
            d = nA
                .mul(s)
                .div(AmplificationUtils.A_PRECISION)
                .add(dP.mul(numTokens))
                .mul(d)
                .div(
                    nA
                        .sub(AmplificationUtils.A_PRECISION)
                        .mul(d)
                        .div(AmplificationUtils.A_PRECISION)
                        .add(numTokens.add(1).mul(dP))
                );
            if (d.within1(prevD)) {
                return d;
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
    function _xp(
        uint256[] memory balances,
        uint256[] memory precisionMultipliers
    ) internal pure returns (uint256[] memory) {
        uint256 numTokens = balances.length;
        require(
            numTokens == precisionMultipliers.length,
            "Balances must match multipliers"
        );
        uint256[] memory xp = new uint256[](numTokens);
        for (uint256 i = 0; i < numTokens; i++) {
            xp[i] = balances[i].mul(precisionMultipliers[i]);
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
     * @return the virtual price, scaled to precision of POOL_PRECISION_DECIMALS
     */
    function getVirtualPrice(Swap storage self)
        external
        view
        returns (uint256)
    {
        uint256 d = getD(_xp(self), _getAPrecise(self));
        LPToken lpToken = self.lpToken;
        uint256 supply = lpToken.totalSupply();
        if (supply > 0) {
            return d.mul(10**uint256(POOL_PRECISION_DECIMALS)).div(supply);
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
        require(
            tokenIndexFrom != tokenIndexTo,
            "Can't compare token to itself"
        );
        require(
            tokenIndexFrom < numTokens && tokenIndexTo < numTokens,
            "Tokens must be in pool"
        );

        uint256 d = getD(xp, preciseA);
        uint256 c = d;
        uint256 s;
        uint256 nA = numTokens.mul(preciseA);

        uint256 _x;
        for (uint256 i = 0; i < numTokens; i++) {
            if (i == tokenIndexFrom) {
                _x = x;
            } else if (i != tokenIndexTo) {
                _x = xp[i];
            } else {
                continue;
            }
            s = s.add(_x);
            c = c.mul(d).div(_x.mul(numTokens));
            // If we were to protect the division loss we would have to keep the denominator separate
            // and divide at the end. However this leads to overflow with large numTokens or/and D.
            // c = c * D * D * D * ... overflow!
        }
        c = c.mul(d).mul(AmplificationUtils.A_PRECISION).div(nA.mul(numTokens));
        uint256 b = s.add(d.mul(AmplificationUtils.A_PRECISION).div(nA));
        uint256 yPrev;
        uint256 y = d;

        // iterative approximation
        for (uint256 i = 0; i < MAX_LOOP_LIMIT; i++) {
            yPrev = y;
            y = y.mul(y).add(c).div(y.mul(2).add(b).sub(d));
            if (y.within1(yPrev)) {
                return y;
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
    ) external view returns (uint256 dy) {
        (dy, ) = _calculateSwap(
            self,
            tokenIndexFrom,
            tokenIndexTo,
            dx,
            self.balances
        );
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
     * @return dy the number of tokens the user will get
     * @return dyFee the associated fee
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
        require(
            tokenIndexFrom < xp.length && tokenIndexTo < xp.length,
            "Token index out of range"
        );
        uint256 x = dx.mul(multipliers[tokenIndexFrom]).add(xp[tokenIndexFrom]);
        uint256 y = getY(
            _getAPrecise(self),
            tokenIndexFrom,
            tokenIndexTo,
            x,
            xp
        );
        dy = xp[tokenIndexTo].sub(y).sub(1);
        dyFee = dy.mul(self.swapFee).div(FEE_DENOMINATOR);
        dy = dy.sub(dyFee).div(multipliers[tokenIndexTo]);
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
    function calculateRemoveLiquidity(Swap storage self, uint256 amount)
        external
        view
        returns (uint256[] memory)
    {
        return
            _calculateRemoveLiquidity(
                self.balances,
                amount,
                self.lpToken.totalSupply()
            );
    }

    function _calculateRemoveLiquidity(
        uint256[] memory balances,
        uint256 amount,
        uint256 totalSupply
    ) internal pure returns (uint256[] memory) {
        require(amount <= totalSupply, "Cannot exceed total supply");

        uint256[] memory amounts = new uint256[](balances.length);

        for (uint256 i = 0; i < balances.length; i++) {
            amounts[i] = balances[i].mul(amount).div(totalSupply);
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
    ) external view returns (uint256) {
        uint256 a = _getAPrecise(self);
        uint256[] memory balances = self.balances;
        uint256[] memory multipliers = self.tokenPrecisionMultipliers;

        uint256 d0 = getD(_xp(balances, multipliers), a);
        for (uint256 i = 0; i < balances.length; i++) {
            if (deposit) {
                balances[i] = balances[i].add(amounts[i]);
            } else {
                balances[i] = balances[i].sub(
                    amounts[i],
                    "Cannot withdraw more than available"
                );
            }
        }
        uint256 d1 = getD(_xp(balances, multipliers), a);
        uint256 totalSupply = self.lpToken.totalSupply();

        if (deposit) {
            return d1.sub(d0).mul(totalSupply).div(d0);
        } else {
            return d0.sub(d1).mul(totalSupply).div(d0);
        }
    }

    /**
     * @notice return accumulated amount of admin fees of the token with given index
     * @param self Swap struct to read from
     * @param index Index of the pooled token
     * @return admin balance in the token's precision
     */
    function getAdminBalance(Swap storage self, uint256 index)
        external
        view
        returns (uint256)
    {
        require(index < self.pooledTokens.length, "Token index out of range");
        return
            self.pooledTokens[index].balanceOf(address(this)).sub(
                self.balances[index]
            );
    }

    /**
     * @notice internal helper function to calculate fee per token multiplier used in
     * swap fee calculations
     * @param swapFee swap fee for the tokens
     * @param numTokens number of tokens pooled
     */
    function _feePerToken(uint256 swapFee, uint256 numTokens)
        internal
        pure
        returns (uint256)
    {
        return swapFee.mul(numTokens).div(numTokens.sub(1).mul(4));
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
    ) external returns (uint256) {
        {
            IERC20 tokenFrom = self.pooledTokens[tokenIndexFrom];
            require(
                dx <= tokenFrom.balanceOf(msg.sender),
                "Cannot swap more than you own"
            );
            // Transfer tokens first to see if a fee was charged on transfer
            uint256 beforeBalance = tokenFrom.balanceOf(address(this));
            tokenFrom.safeTransferFrom(msg.sender, address(this), dx);

            // Use the actual transferred amount for AMM math
            dx = tokenFrom.balanceOf(address(this)).sub(beforeBalance);
        }

        uint256 dy;
        uint256 dyFee;
        uint256[] memory balances = self.balances;
        (dy, dyFee) = _calculateSwap(
            self,
            tokenIndexFrom,
            tokenIndexTo,
            dx,
            balances
        );
        require(dy >= minDy, "Swap didn't result in min tokens");

        uint256 dyAdminFee = dyFee.mul(self.adminFee).div(FEE_DENOMINATOR).div(
            self.tokenPrecisionMultipliers[tokenIndexTo]
        );

        self.balances[tokenIndexFrom] = balances[tokenIndexFrom].add(dx);
        self.balances[tokenIndexTo] = balances[tokenIndexTo].sub(dy).sub(
            dyAdminFee
        );

        self.pooledTokens[tokenIndexTo].safeTransfer(msg.sender, dy);

        emit TokenSwap(msg.sender, dx, dy, tokenIndexFrom, tokenIndexTo);

        return dy;
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
    ) external returns (uint256) {
        IERC20[] memory pooledTokens = self.pooledTokens;
        require(
            amounts.length == pooledTokens.length,
            "Amounts must match pooled tokens"
        );

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

        uint256[] memory newBalances = new uint256[](pooledTokens.length);

        for (uint256 i = 0; i < pooledTokens.length; i++) {
            require(
                v.totalSupply != 0 || amounts[i] > 0,
                "Must supply all tokens in pool"
            );

            // Transfer tokens first to see if a fee was charged on transfer
            if (amounts[i] != 0) {
                uint256 beforeBalance = pooledTokens[i].balanceOf(
                    address(this)
                );
                pooledTokens[i].safeTransferFrom(
                    msg.sender,
                    address(this),
                    amounts[i]
                );

                // Update the amounts[] with actual transfer amount
                amounts[i] = pooledTokens[i].balanceOf(address(this)).sub(
                    beforeBalance
                );
            }

            newBalances[i] = v.balances[i].add(amounts[i]);
        }

        // invariant after change
        v.d1 = getD(_xp(newBalances, v.multipliers), v.preciseA);
        require(v.d1 > v.d0, "D should increase");

        // updated to reflect fees and calculate the user's LP tokens
        v.d2 = v.d1;
        uint256[] memory fees = new uint256[](pooledTokens.length);

        if (v.totalSupply != 0) {
            uint256 feePerToken = _feePerToken(
                self.swapFee,
                pooledTokens.length
            );
            for (uint256 i = 0; i < pooledTokens.length; i++) {
                uint256 idealBalance = v.d1.mul(v.balances[i]).div(v.d0);
                fees[i] = feePerToken
                    .mul(idealBalance.difference(newBalances[i]))
                    .div(FEE_DENOMINATOR);
                self.balances[i] = newBalances[i].sub(
                    fees[i].mul(self.adminFee).div(FEE_DENOMINATOR)
                );
                newBalances[i] = newBalances[i].sub(fees[i]);
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
            toMint = v.d2.sub(v.d0).mul(v.totalSupply).div(v.d0);
        }

        require(toMint >= minToMint, "Couldn't mint min requested");

        // mint the user's LP tokens
        v.lpToken.mint(msg.sender, toMint);

        emit AddLiquidity(
            msg.sender,
            amounts,
            fees,
            v.d1,
            v.totalSupply.add(toMint)
        );

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
    ) external returns (uint256[] memory) {
        LPToken lpToken = self.lpToken;
        IERC20[] memory pooledTokens = self.pooledTokens;
        require(amount <= lpToken.balanceOf(msg.sender), ">LP.balanceOf");
        require(
            minAmounts.length == pooledTokens.length,
            "minAmounts must match poolTokens"
        );

        uint256[] memory balances = self.balances;
        uint256 totalSupply = lpToken.totalSupply();

        uint256[] memory amounts = _calculateRemoveLiquidity(
            balances,
            amount,
            totalSupply
        );

        for (uint256 i = 0; i < amounts.length; i++) {
            require(amounts[i] >= minAmounts[i], "amounts[i] < minAmounts[i]");
            self.balances[i] = balances[i].sub(amounts[i]);
            pooledTokens[i].safeTransfer(msg.sender, amounts[i]);
        }

        lpToken.burnFrom(msg.sender, amount);

        emit RemoveLiquidity(msg.sender, amounts, totalSupply.sub(amount));

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
    ) external returns (uint256) {
        LPToken lpToken = self.lpToken;
        IERC20[] memory pooledTokens = self.pooledTokens;

        require(tokenAmount <= lpToken.balanceOf(msg.sender), ">LP.balanceOf");
        require(tokenIndex < pooledTokens.length, "Token not found");

        uint256 totalSupply = lpToken.totalSupply();

        (uint256 dy, uint256 dyFee) = _calculateWithdrawOneToken(
            self,
            tokenAmount,
            tokenIndex,
            totalSupply
        );

        require(dy >= minAmount, "dy < minAmount");

        self.balances[tokenIndex] = self.balances[tokenIndex].sub(
            dy.add(dyFee.mul(self.adminFee).div(FEE_DENOMINATOR))
        );
        lpToken.burnFrom(msg.sender, tokenAmount);
        pooledTokens[tokenIndex].safeTransfer(msg.sender, dy);

        emit RemoveLiquidityOne(
            msg.sender,
            tokenAmount,
            totalSupply,
            tokenIndex,
            dy
        );

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
    ) public returns (uint256) {
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

        IERC20[] memory pooledTokens = self.pooledTokens;

        require(
            amounts.length == pooledTokens.length,
            "Amounts should match pool tokens"
        );

        require(
            maxBurnAmount <= v.lpToken.balanceOf(msg.sender) &&
                maxBurnAmount != 0,
            ">LP.balanceOf"
        );

        uint256 feePerToken = _feePerToken(self.swapFee, pooledTokens.length);
        uint256[] memory fees = new uint256[](pooledTokens.length);
        {
            uint256[] memory balances1 = new uint256[](pooledTokens.length);
            v.d0 = getD(_xp(v.balances, v.multipliers), v.preciseA);
            for (uint256 i = 0; i < pooledTokens.length; i++) {
                balances1[i] = v.balances[i].sub(
                    amounts[i],
                    "Cannot withdraw more than available"
                );
            }
            v.d1 = getD(_xp(balances1, v.multipliers), v.preciseA);

            for (uint256 i = 0; i < pooledTokens.length; i++) {
                uint256 idealBalance = v.d1.mul(v.balances[i]).div(v.d0);
                uint256 difference = idealBalance.difference(balances1[i]);
                fees[i] = feePerToken.mul(difference).div(FEE_DENOMINATOR);
                self.balances[i] = balances1[i].sub(
                    fees[i].mul(self.adminFee).div(FEE_DENOMINATOR)
                );
                balances1[i] = balances1[i].sub(fees[i]);
            }

            v.d2 = getD(_xp(balances1, v.multipliers), v.preciseA);
        }
        uint256 tokenAmount = v.d0.sub(v.d2).mul(v.totalSupply).div(v.d0);
        require(tokenAmount != 0, "Burnt amount cannot be zero");
        tokenAmount = tokenAmount.add(1);

        require(tokenAmount <= maxBurnAmount, "tokenAmount > maxBurnAmount");

        v.lpToken.burnFrom(msg.sender, tokenAmount);

        for (uint256 i = 0; i < pooledTokens.length; i++) {
            pooledTokens[i].safeTransfer(msg.sender, amounts[i]);
        }

        emit RemoveLiquidityImbalance(
            msg.sender,
            amounts,
            fees,
            v.d1,
            v.totalSupply.sub(tokenAmount)
        );

        return tokenAmount;
    }

    /**
     * @notice withdraw all admin fees to a given address
     * @param self Swap struct to withdraw fees from
     * @param to Address to send the fees to
     */
    function withdrawAdminFees(Swap storage self, address to) external {
        IERC20[] memory pooledTokens = self.pooledTokens;
        for (uint256 i = 0; i < pooledTokens.length; i++) {
            IERC20 token = pooledTokens[i];
            uint256 balance = token.balanceOf(address(this)).sub(
                self.balances[i]
            );
            if (balance != 0) {
                token.safeTransfer(to, balance);
            }
        }
    }

    /**
     * @notice Sets the admin fee
     * @dev adminFee cannot be higher than 100% of the swap fee
     * @param self Swap struct to update
     * @param newAdminFee new admin fee to be applied on future transactions
     */
    function setAdminFee(Swap storage self, uint256 newAdminFee) external {
        require(newAdminFee <= MAX_ADMIN_FEE, "Fee is too high");
        self.adminFee = newAdminFee;

        emit NewAdminFee(newAdminFee);
    }

    /**
     * @notice update the swap fee
     * @dev fee cannot be higher than 1% of each swap
     * @param self Swap struct to update
     * @param newSwapFee new swap fee to be applied on future transactions
     */
    function setSwapFee(Swap storage self, uint256 newSwapFee) external {
        require(newSwapFee <= MAX_SWAP_FEE, "Fee is too high");
        self.swapFee = newSwapFee;

        emit NewSwapFee(newSwapFee);
    }
}