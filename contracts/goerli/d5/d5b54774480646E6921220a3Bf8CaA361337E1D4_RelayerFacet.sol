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
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
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
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

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
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[owner][spender];
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
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
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

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

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
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import {Home} from "../../../nomad-core/contracts/Home.sol";

import {AppStorage} from "../libraries/LibConnextStorage.sol";
import {LibDiamond} from "../libraries/LibDiamond.sol";

contract BaseConnextFacet {
  AppStorage internal s;

  // ========== Properties ===========
  uint256 internal constant _NOT_ENTERED = 1;
  uint256 internal constant _ENTERED = 2;

  // Contains hash of empty bytes
  bytes32 internal constant EMPTY = hex"c5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470";

  // ========== Custom Errors ===========

  error BaseConnextFacet__onlyRemoteRouter_notRemoteRouter();
  error BaseConnextFacet__onlyReplica_notReplica();
  error BaseConnextFacet__onlyOwner_notOwner();
  error BaseConnextFacet__onlyProposed_notProposedOwner();
  error BaseConnextFacet__whenNotPaused_paused();
  error BaseConnextFacet__nonReentrant_reentrantCall();

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
    if (s._status == _ENTERED) revert BaseConnextFacet__nonReentrant_reentrantCall();

    // Any calls to nonReentrant after this point will fail
    s._status = _ENTERED;

    _;

    // By storing the original value once again, a refund is triggered (see
    // https://eips.ethereum.org/EIPS/eip-2200)
    s._status = _NOT_ENTERED;
  }

  /**
   * @notice Only accept messages from a remote Router contract
   * @param _origin The domain the message is coming from
   * @param _router The address the message is coming from
   */
  modifier onlyRemoteRouter(uint32 _origin, bytes32 _router) {
    if (!_isRemoteRouter(_origin, _router)) revert BaseConnextFacet__onlyRemoteRouter_notRemoteRouter();
    _;
  }

  /**
   * @notice Only accept messages from an Nomad Replica contract
   */
  modifier onlyReplica() {
    if (!_isReplica(msg.sender)) revert BaseConnextFacet__onlyReplica_notReplica();
    _;
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
   * @notice Throws if all functionality is paused
   */
  modifier whenNotPaused() {
    if (s._paused) revert BaseConnextFacet__whenNotPaused_paused();
    _;
  }

  // ============ Internal functions ============
  /**
   * @notice Indicates if the ownership of the router whitelist has
   * been renounced
   */
  function _isRouterOwnershipRenounced() internal view returns (bool) {
    return LibDiamond.contractOwner() == address(0) || s._routerOwnershipRenounced;
  }

  /**
   * @notice Indicates if the ownership of the asset whitelist has
   * been renounced
   */
  function _isAssetOwnershipRenounced() internal view returns (bool) {
    return LibDiamond.contractOwner() == address(0) || s._assetOwnershipRenounced;
  }

  /**
   * @notice Return true if the given domain / router is the address of a remote xApp Router
   * @param _domain The domain of the potential remote xApp Router
   * @param _router The address of the potential remote xApp Router
   */
  function _isRemoteRouter(uint32 _domain, bytes32 _router) internal view returns (bool) {
    return s.remotes[_domain] == _router && _router != bytes32(0);
  }

  /**
   * @notice Assert that the given domain has a xApp Router registered and return its address
   * @param _domain The domain of the chain for which to get the xApp Router
   * @return _remote The address of the remote xApp Router on _domain
   */
  function _mustHaveRemote(uint32 _domain) internal view returns (bytes32 _remote) {
    _remote = s.remotes[_domain];
    require(_remote != bytes32(0), "!remote");
  }

  /**
   * @notice Get the local Home contract from the xAppConnectionManager
   * @return The local Home contract
   */
  function _home() internal view returns (Home) {
    return s.xAppConnectionManager.home();
  }

  /**
   * @notice Determine whether _potentialReplica is an enrolled Replica from the xAppConnectionManager
   * @return True if _potentialReplica is an enrolled Replica
   */
  function _isReplica(address _potentialReplica) internal view returns (bool) {
    return s.xAppConnectionManager.isReplica(_potentialReplica);
  }

  /**
   * @notice Get the local domain from the xAppConnectionManager
   * @return The local domain
   */
  function _localDomain() internal view virtual returns (uint32) {
    return s.xAppConnectionManager.localDomain();
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";

import {BaseConnextFacet} from "./BaseConnextFacet.sol";
import {RelayerFeeRouter} from "../../relayer-fee/RelayerFeeRouter.sol";

contract RelayerFacet is BaseConnextFacet {
  // ========== Custom Errors ===========
  error RelayerFacet__onlyRelayerFeeRouter_notRelayerFeeRouter();
  error RelayerFacet__setRelayerFeeRouter_invalidRelayerFeeRouter();
  error RelayerFacet__addRelayer_alreadyApproved();
  error RelayerFacet__removeRelayer_notApproved();
  error RelayerFacet__initiateClaim_emptyClaim();
  error RelayerFacet__initiateClaim_notRelayer(bytes32 transferId);

  // ========== Events ===========
  /**
   * @notice Emitted when the relayerFeeRouter variable is updated
   * @param oldRouter - The relayerFeeRouter old value
   * @param newRouter - The relayerFeeRouter new value
   * @param caller - The account that called the function
   */
  event RelayerFeeRouterUpdated(address oldRouter, address newRouter, address caller);

  /**
   * @notice Emitted when a relayer is added or removed from whitelists
   * @param relayer - The relayer address to be added or removed
   * @param caller - The account that called the function
   */
  event RelayerAdded(address relayer, address caller);

  /**
   * @notice Emitted when a relayer is added or removed from whitelists
   * @param relayer - The relayer address to be added or removed
   * @param caller - The account that called the function
   */
  event RelayerRemoved(address relayer, address caller);

  /**
   * @notice Emitted when `initiateClaim` is called on the destination chain
   * @param domain - Domain to claim funds on
   * @param recipient - Address on origin chain to send claimed funds to
   * @param caller - The account that called the function
   * @param transferIds - TransferIds to claim
   */
  event InitiatedClaim(uint32 indexed domain, address indexed recipient, address caller, bytes32[] transferIds);

  /**
   * @notice Emitted when `claim` is called on the origin domain
   * @param recipient - Address on origin chain to send claimed funds to
   * @param total - Total amount claimed
   * @param transferIds - TransferIds to claim
   */
  event Claimed(address indexed recipient, uint256 total, bytes32[] transferIds);

  // ============ Modifiers ============

  /**
   * @notice Restricts the caller to the local relayer fee router
   */
  modifier onlyRelayerFeeRouter() {
    if (msg.sender != address(s.relayerFeeRouter)) revert RelayerFacet__onlyRelayerFeeRouter_notRelayerFeeRouter();
    _;
  }

  // ============ Getters ============

  function transferRelayer(bytes32 _transferId) public view returns (address) {
    return s.transferRelayer[_transferId];
  }

  function approvedRelayers(address _relayer) public view returns (bool) {
    return s.approvedRelayers[_relayer];
  }

  function relayerFeeRouter() external view returns (RelayerFeeRouter) {
    return s.relayerFeeRouter;
  }

  // ============ Admin functions ============

  /**
   * @notice Updates the relayer fee router
   * @param _relayerFeeRouter The address of the new router
   */
  function setRelayerFeeRouter(address _relayerFeeRouter) external onlyOwner {
    address old = address(s.relayerFeeRouter);
    if (old == _relayerFeeRouter || !Address.isContract(_relayerFeeRouter))
      revert RelayerFacet__setRelayerFeeRouter_invalidRelayerFeeRouter();

    s.relayerFeeRouter = RelayerFeeRouter(_relayerFeeRouter);
    emit RelayerFeeRouterUpdated(old, _relayerFeeRouter, msg.sender);
  }

  /**
   * @notice Used to add approved relayer
   * @param _relayer - The relayer address to add
   */
  function addRelayer(address _relayer) external onlyOwner {
    if (s.approvedRelayers[_relayer]) revert RelayerFacet__addRelayer_alreadyApproved();
    s.approvedRelayers[_relayer] = true;

    emit RelayerAdded(_relayer, msg.sender);
  }

  /**
   * @notice Used to remove approved relayer
   * @param _relayer - The relayer address to remove
   */
  function removeRelayer(address _relayer) external onlyOwner {
    if (!s.approvedRelayers[_relayer]) revert RelayerFacet__removeRelayer_notApproved();
    delete s.approvedRelayers[_relayer];

    emit RelayerRemoved(_relayer, msg.sender);
  }

  // ============ External functions ============

  /**
   * @notice Called by relayer when they want to claim owed funds on a given domain.
   *
   * @dev Domain should be the origin domain of all the transfer IDs.
   *
   * @param _recipient - address on origin chain to send claimed funds to
   * @param _domain - domain to claim funds on
   * @param _transferIds - transferIds to claim
   */
  function initiateClaim(
    uint32 _domain,
    address _recipient,
    bytes32[] calldata _transferIds
  ) external whenNotPaused {
    // Make sure the transferIds length is greater than 0.
    // This is to make sure a valid relayer is calling this function.
    uint256 numTransfers = _transferIds.length;
    if (numTransfers == 0) revert RelayerFacet__initiateClaim_emptyClaim();

    // Ensure the relayer can claim all transfers specified.
    for (uint256 i; i < numTransfers; ) {
      if (s.transferRelayer[_transferIds[i]] != msg.sender)
        revert RelayerFacet__initiateClaim_notRelayer(_transferIds[i]);
      unchecked {
        ++i;
      }
    }

    // Send transferIds via nomad.
    s.relayerFeeRouter.send(_domain, _recipient, _transferIds);

    emit InitiatedClaim(_domain, _recipient, msg.sender, _transferIds);
  }

  /**
   * @notice Pays out a relayer for the given fees
   * @dev Called by the RelayerFeeRouter.handle message. The validity of the transferIds is
   * asserted before dispatching the message.
   * @param _recipient - address on origin chain to send claimed funds to
   * @param _transferIds - transferIds to claim
   */
  function claim(address _recipient, bytes32[] calldata _transferIds) external onlyRelayerFeeRouter {
    uint256 numTransfers = _transferIds.length;
    // Tally amounts owed
    uint256 total;
    for (uint256 i; i < numTransfers; ) {
      total += s.relayerFees[_transferIds[i]];
      delete s.relayerFees[_transferIds[i]];
      unchecked {
        ++i;
      }
    }

    Address.sendValue(payable(_recipient), total);

    emit Claimed(_recipient, total, _transferIds);
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import {ERC20BurnableUpgradeable, ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/**
 * @title Liquidity Provider Token
 * @notice This token is an ERC20 detailed token with added capability to be minted by the owner.
 * It is used to represent user's shares when providing liquidity to swap contracts.
 * @dev Only Swap contracts should initialize and own LPToken contracts.
 */
contract LPToken is ERC20BurnableUpgradeable, OwnableUpgradeable {
  // ============ Upgrade Gap ============

  uint256[49] private __GAP; // gap for upgrade safety

  // ============ Storage ============

  /**
   * @notice Used to enforce proper token dilution
   * @dev If this is the first mint of the LP token, this amount of funds are burned.
   * See audit recommendations here:
   * - https://github.com/code-423n4/2022-03-prepo-findings/issues/27
   * - https://github.com/code-423n4/2022-04-jpegd-findings/issues/12
   * and uniswap v2 implementation here:
   * https://github.com/Uniswap/v2-core/blob/8b82b04a0b9e696c0e83f8b2f00e5d7be6888c79/contracts/UniswapV2Pair.sol#L15
   */
  uint256 public constant MINIMUM_LIQUIDITY = 10**3;

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
    if (totalSupply() == 0) {
      // NOTE: using the _mint function directly will error because it is going
      // to the 0 address. fix by using the address(1) here instead
      _mint(address(1), MINIMUM_LIQUIDITY);
    }
    _mint(recipient, amount);
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
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.15;

interface IBridgeToken {
  function initialize() external;

  function name() external returns (string memory);

  function balanceOf(address _account) external view returns (uint256);

  function symbol() external view returns (string memory);

  function decimals() external view returns (uint8);

  function detailsHash() external view returns (bytes32);

  function burn(address _from, uint256 _amnt) external;

  function mint(address _to, uint256 _amnt) external;

  function setDetailsHash(bytes32 _detailsHash) external;

  function setDetails(
    string calldata _name,
    string calldata _symbol,
    uint8 _decimals
  ) external;

  // inherited from ownable
  function transferOwnership(address _newOwner) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {XAppConnectionManager} from "../../../nomad-core/contracts/XAppConnectionManager.sol";

import {RelayerFeeRouter} from "../../relayer-fee/RelayerFeeRouter.sol";
import {PromiseRouter} from "../../promise/PromiseRouter.sol";

import {ConnextMessage} from "../libraries/ConnextMessage.sol";
import {XCallArgs, ExecuteArgs, CallParams} from "../libraries/LibConnextStorage.sol";
import {SwapUtils} from "../libraries/SwapUtils.sol";

import {IStableSwap} from "./IStableSwap.sol";
import {ITokenRegistry} from "./ITokenRegistry.sol";
import {IWrapped} from "./IWrapped.sol";
import {IExecutor} from "./IExecutor.sol";
import {ISponsorVault} from "./ISponsorVault.sol";

import {IDiamondCut} from "./IDiamondCut.sol";

interface IConnextHandler {
  // AssetFacet
  function canonicalToAdopted(bytes32 _canonicalId) external view returns (address);

  function adoptedToCanonical(address _adopted) external view returns (ConnextMessage.TokenId memory);

  function approvedAssets(bytes32 _asset) external view returns (bool);

  function adoptedToLocalPools(bytes32 _adopted) external view returns (IStableSwap);

  function setupAsset(
    ConnextMessage.TokenId calldata _canonical,
    address _adoptedAssetId,
    address _stableSwapPool
  ) external;

  function addStableSwapPool(ConnextMessage.TokenId calldata _canonical, address _stableSwapPool) external;

  function removeAssetId(bytes32 _canonicalId, address _adoptedAssetId) external;

  // BaseConnextFacet
  function isRouterOwnershipRenounced() external view returns (bool);

  function isAssetOwnershipRenounced() external view returns (bool);

  function VERSION() external view returns (uint8);

  // BridgeFacet
  function relayerFees(bytes32 _transferId) external view returns (uint256);

  function routedTransfers(bytes32 _transferId) external view returns (address[] memory);

  function reconciledTransfers(bytes32 _transferId) external view returns (bool);

  function tokenRegistry() external view returns (ITokenRegistry);

  function domain() external view returns (uint256);

  function executor() external view returns (IExecutor);

  function nonce() external view returns (uint256);

  function wrapper() external view returns (IWrapped);

  function sponsorVault() external view returns (ISponsorVault);

  function promiseRouter() external view returns (PromiseRouter);

  function relayerFeeRouer() external view returns (RelayerFeeRouter);

  function setTokenRegistry(address _tokenRegistry) external;

  function setRelayerFeeRouter(address _relayerFeeRouter) external;

  function setPromiseRouter(address payable _promiseRouter) external;

  function setExecutor(address _executor) external;

  function setWrapper(address _wrapper) external;

  function setSponsorVault(address _sponsorVault) external;

  function xcall(XCallArgs calldata _args) external payable returns (bytes32);

  function handle(
    uint32 _origin,
    uint32 _nonce,
    bytes32 _sender,
    bytes memory _message
  ) external;

  function execute(ExecuteArgs calldata _args) external returns (bytes32 transferId);

  function bumpTransfer(bytes32 _transferId) external payable;

  function forceReceiveLocal(
    CallParams calldata _params,
    uint256 _amount,
    uint256 _nonce,
    bytes32 _canonicalId,
    uint32 _canonicalDomain,
    address _originSender
  ) external payable;

  // NomadFacet
  function xAppConnectionManager() external view returns (XAppConnectionManager);

  function remotes(uint32 _domain) external view returns (bytes32);

  function setXAppConnectionManager(address _xAppConnectionManager) external;

  function enrollRemoteRouter(uint32 _domain, bytes32 _router) external;

  // ProposedOwnableFacet
  function routerOwnershipRenounced() external view returns (bool);

  function assetOwnershipRenounced() external view returns (bool);

  function proposedOwnableOwner() external view returns (address);

  function proposed() external view returns (address);

  function proposedTimestamp() external view returns (uint256);

  function routerOwnershipTimestamp() external view returns (uint256);

  function assetOwnershipTimestamp() external view returns (uint256);

  function delay() external view returns (uint256);

  function proposeRouterOwnershipRenunciation() external;

  function renounceRouterOwnership() external;

  function proposeAssetOwnershipRenunciation() external;

  function renounceAssetOwnership() external;

  function renounced() external view returns (bool);

  function proposeNewOwner(address newlyProposed) external;

  function renounceOwnership() external;

  function acceptProposedOwner() external;

  function pause() external;

  function unpause() external;

  // RelayerFacet
  function transferRelayer(bytes32 _transferId) external view returns (address);

  function approvedRelayers(address _relayer) external view returns (bool);

  function relayerFeeRouter() external view returns (RelayerFeeRouter);

  function addRelayer(address _relayer) external;

  function removeRelayer(address _relayer) external;

  function initiateClaim(
    uint32 _domain,
    address _recipient,
    bytes32[] calldata _transferIds
  ) external;

  function claim(address _recipient, bytes32[] calldata _transferIds) external;

  // RoutersFacet
  function LIQUIDITY_FEE_NUMERATOR() external view returns (uint256);

  function LIQUIDITY_FEE_DENOMINATOR() external view returns (uint256);

  function getRouterApproval(address _router) external view returns (bool);

  function getRouterRecipient(address _router) external view returns (address);

  function getRouterOwner(address _router) external view returns (address);

  function getProposedRouterOwner(address _router) external view returns (address);

  function getProposedRouterOwnerTimestamp(address _router) external view returns (uint256);

  function maxRoutersPerTransfer() external view returns (uint256);

  function setLiquidityFeeNumerator(uint256 _numerator) external;

  function routerBalances(address _router, address _asset) external view returns (uint256);

  function setRouterRecipient(address router, address recipient) external;

  function proposeRouterOwner(address router, address proposed) external;

  function acceptProposedRouterOwner(address router) external;

  function setupRouter(
    address router,
    address owner,
    address recipient
  ) external;

  function removeRouter(address router) external;

  function setMaxRoutersPerTransfer(uint256 _newMaxRouters) external;

  function addRouterLiquidityFor(
    uint256 _amount,
    address _local,
    address _router
  ) external payable;

  function addRouterLiquidity(uint256 _amount, address _local) external payable;

  function removeRouterLiquidityFor(
    uint256 _amount,
    address _local,
    address payable _to,
    address _router
  ) external;

  function removeRouterLiquidity(
    uint256 _amount,
    address _local,
    address payable _to
  ) external;

  // PortalFacet
  function getRouterApprovalForPortal(address _router) external view returns (bool);

  function getAavePortalDebt(bytes32 _transferId) external view returns (uint256);

  function getAavePortalFeeDebt(bytes32 _transferId) external view returns (uint256);

  function aavePool() external view returns (address);

  function aavePortalFee() external view returns (uint256);

  function approveRouterForPortal(address _router) external;

  function unapproveRouterForPortal(address _router) external;

  function setAavePool(address _aavePool) external;

  function setAavePortalFee(uint256 _aavePortalFeeNumerator) external;

  function repayAavePortal(
    address _asset,
    uint256 _backingAmount,
    uint256 _feeAmount,
    uint256 _maxIn,
    bytes32 _transferId
  ) external;

  function repayAavePortalFor(
    address _router,
    address _adopted,
    uint256 _backingAmount,
    uint256 _feeAmount,
    bytes32 _transferId
  ) external;

  // StableSwapFacet
  function getSwapStorage(bytes32 canonicalId) external view returns (SwapUtils.Swap memory);

  function getSwapLPToken(bytes32 canonicalId) external view returns (address);

  function getSwapA(bytes32 canonicalId) external view returns (uint256);

  function getSwapAPrecise(bytes32 canonicalId) external view returns (uint256);

  function getSwapToken(bytes32 canonicalId, uint8 index) external view returns (IERC20);

  function getSwapTokenIndex(bytes32 canonicalId, address tokenAddress) external view returns (uint8);

  function getSwapTokenBalance(bytes32 canonicalId, uint8 index) external view returns (uint256);

  function getSwapVirtualPrice(bytes32 canonicalId) external view returns (uint256);

  function calculateSwap(
    bytes32 canonicalId,
    uint8 tokenIndexFrom,
    uint8 tokenIndexTo,
    uint256 dx
  ) external view returns (uint256);

  function calculateSwapTokenAmount(
    bytes32 canonicalId,
    uint256[] calldata amounts,
    bool deposit
  ) external view returns (uint256);

  function calculateRemoveSwapLiquidity(bytes32 canonicalId, uint256 amount) external view returns (uint256[] memory);

  function calculateRemoveSwapLiquidityOneToken(
    bytes32 canonicalId,
    uint256 tokenAmount,
    uint8 tokenIndex
  ) external view returns (uint256);

  function getSwapAdminBalance(bytes32 canonicalId, uint256 index) external view returns (uint256);

  function swap(
    bytes32 canonicalId,
    uint8 tokenIndexFrom,
    uint8 tokenIndexTo,
    uint256 dx,
    uint256 minDy,
    uint256 deadline
  ) external returns (uint256);

  function swapExact(
    bytes32 canonicalId,
    uint256 amountIn,
    address assetIn,
    address assetOut,
    uint256 minAmountOut,
    uint256 deadline
  ) external payable returns (uint256);

  function swapExactOut(
    bytes32 canonicalId,
    uint256 amountOut,
    address assetIn,
    address assetOut,
    uint256 maxAmountIn,
    uint256 deadline
  ) external payable returns (uint256);

  function addSwapLiquidity(
    bytes32 canonicalId,
    uint256[] calldata amounts,
    uint256 minToMint,
    uint256 deadline
  ) external returns (uint256);

  function removeSwapLiquidity(
    bytes32 canonicalId,
    uint256 amount,
    uint256[] calldata minAmounts,
    uint256 deadline
  ) external returns (uint256[] memory);

  function removeSwapLiquidityOneToken(
    bytes32 canonicalId,
    uint256 tokenAmount,
    uint8 tokenIndex,
    uint256 minAmount,
    uint256 deadline
  ) external returns (uint256);

  function removeSwapLiquidityImbalance(
    bytes32 canonicalId,
    uint256[] calldata amounts,
    uint256 maxBurnAmount,
    uint256 deadline
  ) external returns (uint256);

  function initializeSwap(
    bytes32 _canonicalId,
    IERC20[] memory _pooledTokens,
    uint8[] memory decimals,
    string memory lpTokenName,
    string memory lpTokenSymbol,
    uint256 _a,
    uint256 _fee,
    uint256 _adminFee,
    address lpTokenTargetAddress
  ) external;

  function withdrawSwapAdminFees(bytes32 canonicalId) external;

  function setSwapAdminFee(bytes32 canonicalId, uint256 newAdminFee) external;

  function setSwapFee(bytes32 canonicalId, uint256 newSwapFee) external;

  function rampA(
    bytes32 canonicalId,
    uint256 futureA,
    uint256 futureTime
  ) external;

  function stopRampA(bytes32 canonicalId) external;

  // DiamondCutFacet
  function diamondCut(
    IDiamondCut.FacetCut[] calldata _diamondCut,
    address _init,
    bytes calldata _calldata
  ) external;

  function proposeDiamondCut(
    IDiamondCut.FacetCut[] calldata _diamondCut,
    address _init,
    bytes calldata _calldata
  ) external;

  function rescindDiamondCut(
    IDiamondCut.FacetCut[] calldata _diamondCut,
    address _init,
    bytes calldata _calldata
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

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
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

interface IExecutor {
  /**
   * @param _transferId Unique identifier of transaction id that necessitated
   * calldata execution
   * @param _amount The amount to approve or send with the call
   * @param _to The address to execute the calldata on
   * @param _assetId The assetId of the funds to approve to the contract or
   * send along with the call
   * @param _properties The origin properties
   * @param _callData The data to execute
   */
  struct ExecutorArgs {
    bytes32 transferId;
    uint256 amount;
    address to;
    address recovery;
    address assetId;
    bytes properties;
    bytes callData;
  }

  event Executed(
    bytes32 indexed transferId,
    address indexed to,
    address indexed recovery,
    address assetId,
    uint256 amount,
    bytes _properties,
    bytes callData,
    bytes returnData,
    bool success
  );

  function getConnext() external returns (address);

  function originSender() external returns (address);

  function origin() external returns (uint32);

  function amount() external returns (uint256);

  function execute(ExecutorArgs calldata _args) external payable returns (bool success, bytes memory returnData);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

interface ISponsorVault {
  // Should be callable by the Connext contract only. Should:
  // - call `addLiquidityFor` to send the calculated fee to the router
  // - return the amount of liquidity router was reimbursed
  function reimburseLiquidityFees(
    address token,
    uint256 amount,
    address receiver
  ) external returns (uint256);

  // Should be callable by the Connext contract only. Should:
  // - take in an amount of relayer fee specified on origin chain
  // - convert that amount to destination domain gas
  // - send the user the destination domain gas
  function reimburseRelayerFees(
    uint32 originDomain,
    address payable receiver,
    uint256 amount
  ) external;

  // Should allow anyone to send funds to the vault for sponsoring fees
  function deposit(address _token, uint256 _amount) external payable;

  // Should allow the owner of the vault to withdraw funds put in to a given
  // address
  function withdraw(
    address token,
    address receiver,
    uint256 amount
  ) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

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

  function swapExact(
    uint256 amountIn,
    address assetIn,
    address assetOut,
    uint256 minAmountOut
  ) external payable returns (uint256);

  function swapExactOut(
    uint256 amountOut,
    address assetIn,
    address assetOut,
    uint256 maxAmountIn
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

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.15;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ITokenRegistry {
  function isLocalOrigin(address _token) external view returns (bool);

  function ensureLocalToken(uint32 _domain, bytes32 _id) external returns (address _local);

  function mustHaveLocalToken(uint32 _domain, bytes32 _id) external view returns (IERC20);

  function getLocalAddress(uint32 _domain, bytes32 _id) external view returns (address _local);

  function getTokenId(address _token) external view returns (uint32, bytes32);

  function enrollCustom(
    uint32 _domain,
    bytes32 _id,
    address _custom
  ) external;

  function oldReprToCurrentRepr(address _oldRepr) external view returns (address _currentRepr);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

interface IWrapped {
  function deposit() external payable;

  function withdraw(uint256 amount) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";

import {SwapUtils} from "./SwapUtils.sol";

/**
 * @title AmplificationUtils library
 * @notice A library to calculate and ramp the A parameter of a given `SwapUtils.Swap` struct.
 * This library assumes the struct is fully validated.
 */
library AmplificationUtils {
  using SafeMath for uint256;

  event RampA(uint256 oldA, uint256 newA, uint256 initialTime, uint256 futureTime);
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
  function getA(SwapUtils.Swap storage self) internal view returns (uint256) {
    return _getAPrecise(self).div(A_PRECISION);
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
   * @return A parameter in its raw precision form
   */
  function _getAPrecise(SwapUtils.Swap storage self) internal view returns (uint256) {
    uint256 t1 = self.futureATime; // time when ramp is finished
    uint256 a1 = self.futureA; // final A value when ramp is finished

    if (block.timestamp < t1) {
      uint256 t0 = self.initialATime; // time when ramp is started
      uint256 a0 = self.initialA; // initial A value when ramp is started
      if (a1 > a0) {
        // a0 + (a1 - a0) * (block.timestamp - t0) / (t1 - t0)
        return a0.add(a1.sub(a0).mul(block.timestamp.sub(t0)).div(t1.sub(t0)));
      } else {
        // a0 - (a0 - a1) * (block.timestamp - t0) / (t1 - t0)
        return a0.sub(a0.sub(a1).mul(block.timestamp.sub(t0)).div(t1.sub(t0)));
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
  ) internal {
    require(block.timestamp >= self.initialATime.add(1 days), "Wait 1 day before starting ramp");
    require(futureTime_ >= block.timestamp.add(MIN_RAMP_TIME), "Insufficient ramp time");
    require(futureA_ != 0 && futureA_ < MAX_A, "futureA_ must be > 0 and < MAX_A");

    uint256 initialAPrecise = _getAPrecise(self);
    uint256 futureAPrecise = futureA_.mul(A_PRECISION);

    if (futureAPrecise < initialAPrecise) {
      require(futureAPrecise.mul(MAX_A_CHANGE) >= initialAPrecise, "futureA_ is too small");
    } else {
      require(futureAPrecise <= initialAPrecise.mul(MAX_A_CHANGE), "futureA_ is too large");
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
pragma solidity 0.8.15;

import {TypedMemView} from "../../../nomad-core/libs/TypedMemView.sol";

library ConnextMessage {
  // ============ Libraries ============

  using TypedMemView for bytes;
  using TypedMemView for bytes29;

  // ============ Enums ============

  // WARNING: do NOT re-write the numbers / order
  // of message types in an upgrade;
  // will cause in-flight messages to be mis-interpreted
  enum Types {
    Invalid, // 0
    TokenId, // 1
    Message, // 2
    Transfer // 3
  }

  // ============ Structs ============

  // Tokens are identified by a TokenId:
  // domain - 4 byte chain ID of the chain from which the token originates
  // id - 32 byte identifier of the token address on the origin chain, in that chain's address format
  struct TokenId {
    uint32 domain;
    bytes32 id;
  }

  // ============ Constants ============

  uint256 private constant TOKEN_ID_LEN = 36; // 4 bytes domain + 32 bytes id
  uint256 private constant IDENTIFIER_LEN = 1;
  uint256 private constant TRANSFER_LEN = 129;
  // 1 byte identifier + 32 bytes recipient + 32 bytes amount + 32 bytes detailsHash + 32 bytes external hash

  // ============ Modifiers ============

  /**
   * @notice Asserts a message is of type `_t`
   * @param _view The message
   * @param _t The expected type
   */
  modifier typeAssert(bytes29 _view, Types _t) {
    _view.assertType(uint40(_t));
    _;
  }

  // ============ Internal Functions: Validation ============

  /**
   * @notice Checks that Action is valid type
   * @param _action The action
   * @return TRUE if action is valid
   */
  function isValidAction(bytes29 _action) internal pure returns (bool) {
    return isTransfer(_action);
  }

  /**
   * @notice Checks that the message is of the specified type
   * @param _type the type to check for
   * @param _action The message
   * @return True if the message is of the specified type
   */
  function isType(bytes29 _action, Types _type) internal pure returns (bool) {
    return actionType(_action) == uint8(_type) && messageType(_action) == _type;
  }

  /**
   * @notice Checks that the message is of type Transfer
   * @param _action The message
   * @return True if the message is of type Transfer
   */
  function isTransfer(bytes29 _action) internal pure returns (bool) {
    return isType(_action, Types.Transfer);
  }

  /**
   * @notice Checks that view is a valid message length
   * @param _view The bytes string
   * @return TRUE if message is valid
   */
  function isValidMessageLength(bytes29 _view) internal pure returns (bool) {
    uint256 _len = _view.len();
    return _len == TOKEN_ID_LEN + TRANSFER_LEN;
  }

  /**
   * @notice Asserts that the message is of type Message
   * @param _view The message
   * @return The message
   */
  function mustBeMessage(bytes29 _view) internal pure returns (bytes29) {
    return tryAsMessage(_view).assertValid();
  }

  // ============ Internal Functions: Formatting ============

  /**
   * @notice Formats an action message
   * @param _tokenId The token ID
   * @param _action The action
   * @return The formatted message
   */
  function formatMessage(bytes29 _tokenId, bytes29 _action)
    internal
    view
    typeAssert(_tokenId, Types.TokenId)
    returns (bytes memory)
  {
    require(isValidAction(_action), "!action");
    bytes29[] memory _views = new bytes29[](2);
    _views[0] = _tokenId;
    _views[1] = _action;
    return TypedMemView.join(_views);
  }

  /**
   * @notice Formats Transfer
   * @param _to The recipient address as bytes32
   * @param _amnt The transfer amount
   * @param _detailsHash The token details hash
   * @param _transferId Unique identifier for transfer
   * @return
   */
  function formatTransfer(
    bytes32 _to,
    uint256 _amnt,
    bytes32 _detailsHash,
    bytes32 _transferId
  ) internal pure returns (bytes29) {
    return
      abi.encodePacked(Types.Transfer, _to, _amnt, _detailsHash, _transferId).ref(0).castTo(uint40(Types.Transfer));
  }

  /**
   * @notice Serializes a Token ID struct
   * @param _tokenId The token id struct
   * @return The formatted Token ID
   */
  function formatTokenId(TokenId memory _tokenId) internal pure returns (bytes29) {
    return formatTokenId(_tokenId.domain, _tokenId.id);
  }

  /**
   * @notice Creates a serialized Token ID from components
   * @param _domain The domain
   * @param _id The ID
   * @return The formatted Token ID
   */
  function formatTokenId(uint32 _domain, bytes32 _id) internal pure returns (bytes29) {
    return abi.encodePacked(_domain, _id).ref(0).castTo(uint40(Types.TokenId));
  }

  /**
   * @notice Formats the keccak256 hash of the token details
   * Token Details Format:
   *      length of name cast to bytes - 32 bytes
   *      name - x bytes (variable)
   *      length of symbol cast to bytes - 32 bytes
   *      symbol - x bytes (variable)
   *      decimals - 1 byte
   * @param _name The name
   * @param _symbol The symbol
   * @param _decimals The decimals
   * @return The Details message
   */
  function formatDetailsHash(
    string memory _name,
    string memory _symbol,
    uint8 _decimals
  ) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(bytes(_name).length, _name, bytes(_symbol).length, _symbol, _decimals));
  }

  /**
   * @notice Converts to a Message
   * @param _message The message
   * @return The newly typed message
   */
  function tryAsMessage(bytes29 _message) internal pure returns (bytes29) {
    if (isValidMessageLength(_message)) {
      return _message.castTo(uint40(Types.Message));
    }
    return TypedMemView.nullView();
  }

  // ============ Internal Functions: Parsing msg ============

  /**
   * @notice Returns the type of the message
   * @param _view The message
   * @return The type of the message
   */
  function messageType(bytes29 _view) internal pure returns (Types) {
    return Types(uint8(_view.typeOf()));
  }

  /**
   * @notice Retrieves the token ID from a Message
   * @param _message The message
   * @return The ID
   */
  function tokenId(bytes29 _message) internal pure typeAssert(_message, Types.Message) returns (bytes29) {
    return _message.slice(0, TOKEN_ID_LEN, uint40(Types.TokenId));
  }

  /**
   * @notice Retrieves the action data from a Message
   * @param _message The message
   * @return The action
   */
  function action(bytes29 _message) internal pure typeAssert(_message, Types.Message) returns (bytes29) {
    uint256 _actionLen = _message.len() - TOKEN_ID_LEN;
    uint40 _type = uint40(msgType(_message));
    return _message.slice(TOKEN_ID_LEN, _actionLen, _type);
  }

  // ============ Internal Functions: Parsing tokenId ============

  /**
   * @notice Retrieves the domain from a TokenID
   * @param _tokenId The message
   * @return The domain
   */
  function domain(bytes29 _tokenId) internal pure typeAssert(_tokenId, Types.TokenId) returns (uint32) {
    return uint32(_tokenId.indexUint(0, 4));
  }

  /**
   * @notice Retrieves the ID from a TokenID
   * @param _tokenId The message
   * @return The ID
   */
  function id(bytes29 _tokenId) internal pure typeAssert(_tokenId, Types.TokenId) returns (bytes32) {
    // before = 4 bytes domain
    return _tokenId.index(4, 32);
  }

  /**
   * @notice Retrieves the EVM ID
   * @param _tokenId The message
   * @return The EVM ID
   */
  function evmId(bytes29 _tokenId) internal pure typeAssert(_tokenId, Types.TokenId) returns (address) {
    // before = 4 bytes domain + 12 bytes empty to trim for address
    return _tokenId.indexAddress(16);
  }

  // ============ Internal Functions: Parsing action ============

  /**
   * @notice Retrieves the action identifier from message
   * @param _message The action
   * @return The message type
   */
  function msgType(bytes29 _message) internal pure returns (uint8) {
    return uint8(_message.indexUint(TOKEN_ID_LEN, 1));
  }

  /**
   * @notice Retrieves the identifier from action
   * @param _action The action
   * @return The action type
   */
  function actionType(bytes29 _action) internal pure returns (uint8) {
    return uint8(_action.indexUint(0, 1));
  }

  /**
   * @notice Retrieves the recipient from a Transfer
   * @param _transferAction The message
   * @return The recipient address as bytes32
   */
  function recipient(bytes29 _transferAction) internal pure returns (bytes32) {
    // before = 1 byte identifier
    return _transferAction.index(1, 32);
  }

  /**
   * @notice Retrieves the EVM Recipient from a Transfer
   * @param _transferAction The message
   * @return The EVM Recipient
   */
  function evmRecipient(bytes29 _transferAction) internal pure returns (address) {
    // before = 1 byte identifier + 12 bytes empty to trim for address = 13 bytes
    return _transferAction.indexAddress(13);
  }

  /**
   * @notice Retrieves the amount from a Transfer
   * @param _transferAction The message
   * @return The amount
   */
  function amnt(bytes29 _transferAction) internal pure returns (uint256) {
    // before = 1 byte identifier + 32 bytes ID = 33 bytes
    return _transferAction.indexUint(33, 32);
  }

  /**
   * @notice Retrieves the unique identifier from a Transfer
   * @param _transferAction The message
   * @return The amount
   */
  function transferId(bytes29 _transferAction) internal pure returns (bytes32) {
    // before = 1 byte identifier + 32 bytes ID + 32 bytes amount + 32 bytes detailsHash = 97 bytes
    return _transferAction.index(97, 32);
  }

  /**
   * @notice Retrieves the detailsHash from a Transfer
   * @param _transferAction The message
   * @return The detailsHash
   */
  function detailsHash(bytes29 _transferAction) internal pure returns (bytes32) {
    // before = 1 byte identifier + 32 bytes ID + 32 bytes amount = 65 bytes
    return _transferAction.index(65, 32);
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import {XAppConnectionManager} from "../../../nomad-core/contracts/XAppConnectionManager.sol";

import {RelayerFeeRouter} from "../../relayer-fee/RelayerFeeRouter.sol";
import {PromiseRouter} from "../../promise/PromiseRouter.sol";

import {ITokenRegistry} from "../interfaces/ITokenRegistry.sol";
import {IWrapped} from "../interfaces/IWrapped.sol";
import {IExecutor} from "../interfaces/IExecutor.sol";
import {IStableSwap} from "../interfaces/IStableSwap.sol";
import {ISponsorVault} from "../interfaces/ISponsorVault.sol";

import {ConnextMessage} from "./ConnextMessage.sol";
import {SwapUtils} from "./SwapUtils.sol";

// ============= Structs =============

/**
 * @notice These are the call parameters that will remain constant between the
 * two chains. They are supplied on `xcall` and should be asserted on `execute`
 * @property to - The account that receives funds, in the event of a crosschain call,
 * will receive funds if the call fails.
 * @param to - The address you are sending funds (and potentially data) to
 * @param callData - The data to execute on the receiving chain. If no crosschain call is needed, then leave empty.
 * @param originDomain - The originating domain (i.e. where `xcall` is called). Must match nomad domain schema
 * @param destinationDomain - The final domain (i.e. where `execute` / `reconcile` are called). Must match nomad domain schema
 * @param agent - An address who can execute txs on behalf of `to`, in addition to allowing relayers
 * @param recovery - The address to send funds to if your `Executor.execute call` fails
 * @param callback - The address on the origin domain of the callback contract
 * @param callbackFee - The relayer fee to execute the callback
 * @param forceSlow - If true, will take slow liquidity path even if it is not a permissioned call
 * @param receiveLocal - If true, will use the local nomad asset on the destination instead of adopted.
 * @param relayerFee - The amount of relayer fee the tx called xcall with
 * @param slippageTol - Max bps of original due to slippage (i.e. would be 9995 to tolerate .05% slippage)
 */
struct CallParams {
  address to;
  bytes callData;
  uint32 originDomain;
  uint32 destinationDomain;
  address agent;
  address recovery;
  bool forceSlow;
  bool receiveLocal;
  address callback;
  uint256 callbackFee;
  uint256 relayerFee;
  uint256 slippageTol;
}

/**
 * @notice The arguments you supply to the `xcall` function called by user on origin domain
 * @param params - The CallParams. These are consistent across sending and receiving chains
 * @param transactingAssetId - The asset the caller sent with the transfer. Can be the adopted, canonical,
 * or the representational asset
 * @param amount - The amount of transferring asset the tx called xcall with
 */
struct XCallArgs {
  CallParams params;
  address transactingAssetId; // Could be adopted, local, or wrapped
  uint256 amount;
}

/**
 * @notice
 * @param params - The CallParams. These are consistent across sending and receiving chains
 * @param local - The local asset for the transfer, will be swapped to the adopted asset if
 * appropriate
 * @param routers - The routers who you are sending the funds on behalf of
 * @param amount - The amount of liquidity the router provided or the bridge forwarded, depending on
 * if fast liquidity was used
 * @param nonce - The nonce used to generate transfer id
 * @param originSender - The msg.sender of the xcall on origin domain
 */
struct ExecuteArgs {
  CallParams params;
  address local; // local representation of canonical token
  address[] routers;
  bytes[] routerSignatures;
  uint256 amount;
  uint256 nonce;
  address originSender;
}

/**
 * @notice Contains RouterFacet related state
 * @param approvedRouters - Mapping of whitelisted router addresses
 * @param routerRecipients - Mapping of router withdraw recipient addresses.
 * If set, all liquidity is withdrawn only to this address. Must be set by routerOwner
 * (if configured) or the router itself
 * @param routerOwners - Mapping of router owners
 * If set, can update the routerRecipient
 * @param proposedRouterOwners - Mapping of proposed router owners
 * Must wait timeout to set the
 * @param proposedRouterTimestamp - Mapping of proposed router owners timestamps
 * When accepting a proposed owner, must wait for delay to elapse
 */
struct RouterPermissionsManagerInfo {
  mapping(address => bool) approvedRouters;
  mapping(address => bool) approvedForPortalRouters;
  mapping(address => address) routerRecipients;
  mapping(address => address) routerOwners;
  mapping(address => address) proposedRouterOwners;
  mapping(address => uint256) proposedRouterTimestamp;
}

struct AppStorage {
  bool initialized;
  //
  // ConnextHandler
  //
  // 0
  uint256 LIQUIDITY_FEE_NUMERATOR;
  // 1
  uint256 LIQUIDITY_FEE_DENOMINATOR;
  // The local nomad relayer fee router
  // 2
  RelayerFeeRouter relayerFeeRouter;
  // The local nomad promise callback router
  // 3
  PromiseRouter promiseRouter;
  // /**
  // * @notice The address of the wrapper for the native asset on this domain
  // * @dev Needed because the nomad only handles ERC20 assets
  // */
  // 4
  IWrapped wrapper;
  // /**
  // * @notice Nonce for the contract, used to keep unique transfer ids.
  // * @dev Assigned at first interaction (xcall on origin domain);
  // */
  // 5
  uint256 nonce;
  // /**
  // * @notice The external contract that will execute crosschain calldata
  // */
  // 6
  IExecutor executor;
  // /**
  // * @notice The domain this contract exists on
  // * @dev Must match the nomad domain, which is distinct from the "chainId"
  // */
  // 7
  uint32 domain;
  // /**
  // * @notice The local nomad token registry
  // */
  // 8
  ITokenRegistry tokenRegistry;
  // /**
  // * @notice Mapping holding the AMMs for swapping in and out of local assets
  // * @dev Swaps for an adopted asset <> nomad local asset (i.e. POS USDC <> madUSDC on polygon)
  // */
  // 9
  mapping(bytes32 => IStableSwap) adoptedToLocalPools;
  // /**
  // * @notice Mapping of whitelisted assets on same domain as contract
  // * @dev Mapping is keyed on the canonical token identifier matching what is stored in the token
  // * registry
  // */
  // 10
  mapping(bytes32 => bool) approvedAssets;
  // /**
  // * @notice Mapping of canonical to adopted assets on this domain
  // * @dev If the adopted asset is the native asset, the keyed address will
  // * be the wrapped asset address
  // */
  // 11
  mapping(address => ConnextMessage.TokenId) adoptedToCanonical;
  // /**
  // * @notice Mapping of adopted to canonical on this domain
  // * @dev If the adopted asset is the native asset, the stored address will be the
  // * wrapped asset address
  // */
  // 12
  mapping(bytes32 => address) canonicalToAdopted;
  // /**
  // * @notice Mapping to determine if transfer is reconciled
  // */
  // 13
  mapping(bytes32 => bool) reconciledTransfers;
  // /**
  // * @notice Mapping holding router address that provided fast liquidity
  // */
  // 14
  mapping(bytes32 => address[]) routedTransfers;
  // /**
  // * @notice Mapping of router to available balance of an asset
  // * @dev Routers should always store liquidity that they can expect to receive via the bridge on
  // * this domain (the nomad local asset)
  // */
  // 15
  mapping(address => mapping(address => uint256)) routerBalances;
  // /**
  // * @notice Mapping of approved relayers
  // * @dev Send relayer fee if msg.sender is approvedRelayer. otherwise revert()
  // */
  // 16
  mapping(address => bool) approvedRelayers;
  // /**
  // * @notice Stores the relayer fee for a transfer. Updated on origin domain when a user calls xcall or bump
  // * @dev This will track all of the relayer fees assigned to a transfer by id, including any bumps made by the relayer
  // */
  // 17
  mapping(bytes32 => uint256) relayerFees;
  // /**
  // * @notice Stores the relayer of a transfer. Updated on the destination domain when a relayer calls execute
  // * for transfer
  // * @dev When relayer claims, must check that the msg.sender has forwarded transfer
  // */
  // 18
  mapping(bytes32 => address) transferRelayer;
  // /**
  // * @notice The max amount of routers a payment can be routed through
  // */
  // 19
  uint256 maxRoutersPerTransfer;
  // /**
  //  * @notice The Vault used for sponsoring fees
  //  */
  // 20
  ISponsorVault sponsorVault;
  //
  // Router
  //
  // 21
  mapping(uint32 => bytes32) remotes;
  //
  // XAppConnectionClient
  //
  // 22
  XAppConnectionManager xAppConnectionManager;
  //
  // ProposedOwnable
  //
  // 23
  address _proposed;
  // 24
  uint256 _proposedOwnershipTimestamp;
  // 25
  bool _routerOwnershipRenounced;
  // 26
  uint256 _routerOwnershipTimestamp;
  // 27
  bool _assetOwnershipRenounced;
  // 28
  uint256 _assetOwnershipTimestamp;
  //
  // RouterFacet
  //
  // 29
  RouterPermissionsManagerInfo routerPermissionInfo;
  //
  // ReentrancyGuard
  //
  // 30
  uint256 _status;
  //
  // StableSwap
  //
  /**
   * @notice Mapping holding the AMM storages for swapping in and out of local assets
   * @dev Swaps for an adopted asset <> nomad local asset (i.e. POS USDC <> madUSDC on polygon)
   * Struct storing data responsible for automatic market maker functionalities. In order to
   * access this data, this contract uses SwapUtils library. For more details, see SwapUtils.sol
   */
  // 31
  mapping(bytes32 => SwapUtils.Swap) swapStorages;
  /**
   * @notice Maps token address to an index in the pool. Used to prevent duplicate tokens in the pool.
   * @dev getTokenIndex function also relies on this mapping to retrieve token index.
   */
  // 32
  mapping(bytes32 => mapping(address => uint8)) tokenIndexes;
  /**
   * @notice Stores whether or not bribing, AMMs, have been paused
   */
  // 33
  bool _paused;
  //
  // AavePortals
  //
  /**
   * @notice Address of Aave Pool contract
   */
  address aavePool;
  /**
   * @notice Fee percentage numerator for using Portal liquidity
   * @dev Assumes the same basis points as the liquidity fee
   */
  uint256 aavePortalFeeNumerator;
  /**
   * @notice Mapping to store the transfer liquidity amount provided by Aave Portals
   */
  mapping(bytes32 => uint256) portalDebt;
  /**
   * @notice Mapping to store the transfer liquidity amount provided by Aave Portals
   */
  mapping(bytes32 => uint256) portalFeeDebt;
  //
  // BridgeFacet (cont.) TODO: can we move this
  //
  /**
   * @notice Stores whether a transfer has had `receiveLocal` overrides forced
   */
  // 34
  mapping(bytes32 => bool) receiveLocalOverrides;
}

library LibConnextStorage {
  function connextStorage() internal pure returns (AppStorage storage ds) {
    assembly {
      ds.slot := 0
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/
import {IDiamondCut} from "../interfaces/IDiamondCut.sol";

// Remember to add the loupe functions from DiamondLoupeFacet to the diamond.
// The loupe functions are required by the EIP2535 Diamonds standard

library LibDiamond {
  bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

  uint256 private constant _delay = 7 days;

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
    address previousOwner = ds.contractOwner;
    ds.contractOwner = _newOwner;
    emit OwnershipTransferred(previousOwner, _newOwner);
  }

  function contractOwner() internal view returns (address contractOwner_) {
    contractOwner_ = diamondStorage().contractOwner;
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
    uint256 acceptance = block.timestamp + _delay;
    diamondStorage().acceptanceTimes[keccak256(abi.encode(_diamondCut, _init, _calldata))] = acceptance;
    emit DiamondCutProposed(_diamondCut, _init, _calldata, acceptance);
  }

  event DiamondCutRescinded(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);

  function rescindDiamondCut(
    IDiamondCut.FacetCut[] memory _diamondCut,
    address _init,
    bytes memory _calldata
  ) internal {
    diamondStorage().acceptanceTimes[keccak256(abi.encode(_diamondCut, _init, _calldata))] = 0;
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
    if (ds.facetAddresses.length != 0) {
      uint256 time = ds.acceptanceTimes[keccak256(abi.encode(_diamondCut, _init, _calldata))];
      require(time != 0 && time < block.timestamp, "LibDiamond: delay not elapsed");
    } // Otherwise, this is the first instance of deployment and it can be set automatically
    for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {
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
    for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
      bytes4 selector = _functionSelectors[selectorIndex];
      address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
      require(oldFacetAddress == address(0), "LibDiamondCut: Can't add function that already exists");
      addFunction(ds, selector, selectorPosition, _facetAddress);
      selectorPosition++;
    }
  }

  function replaceFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
    require(_functionSelectors.length != 0, "LibDiamondCut: No selectors in facet to cut");
    DiamondStorage storage ds = diamondStorage();
    require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
    uint96 selectorPosition = uint96(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
    // add new facet address if it does not exist
    if (selectorPosition == 0) {
      addFacet(ds, _facetAddress);
    }
    for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
      bytes4 selector = _functionSelectors[selectorIndex];
      address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
      require(oldFacetAddress != _facetAddress, "LibDiamondCut: Can't replace function with same function");
      removeFunction(ds, oldFacetAddress, selector);
      addFunction(ds, selector, selectorPosition, _facetAddress);
      selectorPosition++;
    }
  }

  function removeFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
    require(_functionSelectors.length != 0, "LibDiamondCut: No selectors in facet to cut");
    DiamondStorage storage ds = diamondStorage();
    // if function does not exist then do nothing and return
    require(_facetAddress == address(0), "LibDiamondCut: Remove facet address must be address(0)");
    for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
      bytes4 selector = _functionSelectors[selectorIndex];
      address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
      removeFunction(ds, oldFacetAddress, selector);
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
    uint256 contractSize;
    assembly {
      contractSize := extcodesize(_contract)
    }
    require(contractSize != 0, _errorMessage);
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {LPToken} from "../helpers/LPToken.sol";
import {AmplificationUtils} from "./AmplificationUtils.sol";
import {MathUtils} from "./MathUtils.sol";

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
    // the admin fee balance of each token, in the token's precision
    uint256[] adminFees;
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
  uint8 internal constant POOL_PRECISION_DECIMALS = 18;

  // the denominator used to calculate admin and LP fees. For example, an
  // LP fee might be something like tradeAmount.mul(fee).div(FEE_DENOMINATOR)
  uint256 internal constant FEE_DENOMINATOR = 1e10;

  // Max swap fee is 1% or 100bps of each swap
  uint256 internal constant MAX_SWAP_FEE = 1e8;

  // Max adminFee is 100% of the swapFee
  // adminFee does not add additional fee on top of swapFee
  // Instead it takes a certain % of the swapFee. Therefore it has no impact on the
  // users but only on the earnings of LPs
  uint256 internal constant MAX_ADMIN_FEE = 1e10;

  // Constant value used as max loop limit
  uint256 internal constant MAX_LOOP_LIMIT = 256;

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

    uint256 dySwapFee = currentY.sub(newY).div(self.tokenPrecisionMultipliers[tokenIndex]).sub(dy);

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
    v.d1 = v.d0.sub(tokenAmount.mul(v.d0).div(totalSupply));

    require(tokenAmount <= xp[tokenIndex], "exceeds available");

    v.newY = getYD(v.preciseA, tokenIndex, xp, v.d1);

    uint256[] memory xpReduced = new uint256[](xp.length);

    v.feePerToken = _feePerToken(self.swapFee, xp.length);
    // TODO: Set a length variable (at top) instead of reading xp.length on each loop.
    for (uint256 i; i < xp.length; ) {
      uint256 xpi = xp[i];
      // if i == tokenIndex, dxExpected = xp[i] * d1 / d0 - newY
      // else dxExpected = xp[i] - (xp[i] * d1 / d0)
      // xpReduced[i] -= dxExpected * fee / FEE_DENOMINATOR
      xpReduced[i] = xpi.sub(
        ((i == tokenIndex) ? xpi.mul(v.d1).div(v.d0).sub(v.newY) : xpi.sub(xpi.mul(v.d1).div(v.d0)))
          .mul(v.feePerToken)
          .div(FEE_DENOMINATOR)
      );

      unchecked {
        ++i;
      }
    }

    uint256 dy = xpReduced[tokenIndex].sub(getYD(v.preciseA, tokenIndex, xpReduced, v.d1));
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

    for (uint256 i; i < numTokens; ) {
      if (i != tokenIndex) {
        s = s.add(xp[i]);
        c = c.mul(d).div(xp[i].mul(numTokens));
        // If we were to protect the division loss we would have to keep the denominator separate
        // and divide at the end. However this leads to overflow with large numTokens or/and D.
        // c = c * D * D * D * ... overflow!
      }

      unchecked {
        ++i;
      }
    }
    c = c.mul(d).mul(AmplificationUtils.A_PRECISION).div(nA.mul(numTokens));

    uint256 b = s.add(d.mul(AmplificationUtils.A_PRECISION).div(nA));
    uint256 yPrev;
    uint256 y = d;
    for (uint256 i; i < MAX_LOOP_LIMIT; ) {
      yPrev = y;
      y = y.mul(y).add(c).div(y.mul(2).add(b).sub(d));
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
   * @param a the amplification coefficient * n * (n - 1) in A_PRECISION.
   * See the StableSwap paper for details
   * @return the invariant, at the precision of the pool
   */
  function getD(uint256[] memory xp, uint256 a) internal pure returns (uint256) {
    uint256 numTokens = xp.length;
    uint256 s;
    for (uint256 i; i < numTokens; ) {
      s = s.add(xp[i]);

      unchecked {
        ++i;
      }
    }
    if (s == 0) {
      return 0;
    }

    uint256 prevD;
    uint256 d = s;
    uint256 nA = a.mul(numTokens);

    for (uint256 i; i < MAX_LOOP_LIMIT; ) {
      uint256 dP = d;
      for (uint256 j; j < numTokens; ) {
        dP = dP.mul(d).div(xp[j].mul(numTokens));
        // If we were to protect the division loss we would have to keep the denominator separate
        // and divide at the end. However this leads to overflow with large numTokens or/and D.
        // dP = dP * D * D * D * ... overflow!

        unchecked {
          ++j;
        }
      }
      prevD = d;
      d = nA.mul(s).div(AmplificationUtils.A_PRECISION).add(dP.mul(numTokens)).mul(d).div(
        nA.sub(AmplificationUtils.A_PRECISION).mul(d).div(AmplificationUtils.A_PRECISION).add(numTokens.add(1).mul(dP))
      );
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
      xp[i] = balances[i].mul(precisionMultipliers[i]);

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
   * @return the virtual price, scaled to precision of POOL_PRECISION_DECIMALS
   */
  function getVirtualPrice(Swap storage self) internal view returns (uint256) {
    uint256 d = getD(_xp(self), _getAPrecise(self));
    LPToken lpToken = self.lpToken;
    uint256 supply = lpToken.totalSupply();
    if (supply != 0) {
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
    require(tokenIndexFrom != tokenIndexTo, "compare token to itself");
    require(tokenIndexFrom < numTokens && tokenIndexTo < numTokens, "token not found");

    uint256 d = getD(xp, preciseA);
    uint256 c = d;
    uint256 s;
    uint256 nA = numTokens.mul(preciseA);

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
      s = s.add(_x);
      c = c.mul(d).div(_x.mul(numTokens));
      // If we were to protect the division loss we would have to keep the denominator separate
      // and divide at the end. However this leads to overflow with large numTokens or/and D.
      // c = c * D * D * D * ... overflow!

      unchecked {
        ++i;
      }
    }
    c = c.mul(d).mul(AmplificationUtils.A_PRECISION).div(nA.mul(numTokens));
    uint256 b = s.add(d.mul(AmplificationUtils.A_PRECISION).div(nA));
    uint256 yPrev;
    uint256 y = d;

    // iterative approximation
    for (uint256 i; i < MAX_LOOP_LIMIT; ) {
      yPrev = y;
      y = y.mul(y).add(c).div(y.mul(2).add(b).sub(d));
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
    require(tokenIndexFrom < xp.length && tokenIndexTo < xp.length, "index out of range");
    uint256 x = dx.mul(multipliers[tokenIndexFrom]).add(xp[tokenIndexFrom]);
    uint256 y = getY(_getAPrecise(self), tokenIndexFrom, tokenIndexTo, x, xp);
    dy = xp[tokenIndexTo].sub(y).sub(1);
    dyFee = dy.mul(self.swapFee).div(FEE_DENOMINATOR);
    dy = dy.sub(dyFee).div(multipliers[tokenIndexTo]);
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
   * @return dx the number of tokens the user have to deposit
   * @return dxFee the associated fee
   */
  function _calculateSwapInv(
    Swap storage self,
    uint8 tokenIndexFrom,
    uint8 tokenIndexTo,
    uint256 dy,
    uint256[] memory balances
  ) internal view returns (uint256 dx, uint256 dxFee) {
    uint256[] memory multipliers = self.tokenPrecisionMultipliers;
    uint256[] memory xp = _xp(balances, multipliers);
    require(tokenIndexFrom < xp.length && tokenIndexTo < xp.length, "index out of range");

    uint256 a = _getAPrecise(self);
    uint256 d0 = getD(xp, a);

    xp[tokenIndexTo] = xp[tokenIndexTo].sub(dy.mul(multipliers[tokenIndexTo]));
    uint256 x = getYD(a, tokenIndexFrom, xp, d0);
    dx = x.sub(xp[tokenIndexFrom]).add(1);
    dxFee = dx.mul(self.swapFee).div(FEE_DENOMINATOR);
    dx = dx.add(dxFee).div(multipliers[tokenIndexFrom]);
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
      amounts[i] = balances[i].mul(amount).div(totalSupply);

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
    uint256 a = _getAPrecise(self);
    uint256[] memory balances = self.balances;
    uint256[] memory multipliers = self.tokenPrecisionMultipliers;

    uint256 numBalances = balances.length;
    uint256 d0 = getD(_xp(balances, multipliers), a);
    for (uint256 i; i < numBalances; ) {
      if (deposit) {
        balances[i] = balances[i].add(amounts[i]);
      } else {
        balances[i] = balances[i].sub(amounts[i], "withdraw >available");
      }

      unchecked {
        ++i;
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
  ) internal returns (uint256) {
    {
      IERC20 tokenFrom = self.pooledTokens[tokenIndexFrom];
      require(dx <= tokenFrom.balanceOf(msg.sender), "swap more than you own");
      // Transfer tokens first to see if a fee was charged on transfer
      uint256 beforeBalance = tokenFrom.balanceOf(address(this));
      tokenFrom.safeTransferFrom(msg.sender, address(this), dx);

      // Use the actual transferred amount for AMM math
      dx = tokenFrom.balanceOf(address(this)).sub(beforeBalance);
    }

    uint256 dy;
    uint256 dyFee;
    uint256[] memory balances = self.balances;
    (dy, dyFee) = _calculateSwap(self, tokenIndexFrom, tokenIndexTo, dx, balances);
    require(dy >= minDy, "dy < minDy");

    uint256 dyAdminFee = dyFee.mul(self.adminFee).div(FEE_DENOMINATOR).div(
      self.tokenPrecisionMultipliers[tokenIndexTo]
    );

    self.balances[tokenIndexFrom] = balances[tokenIndexFrom].add(dx);
    self.balances[tokenIndexTo] = balances[tokenIndexTo].sub(dy).sub(dyAdminFee);
    if (dyAdminFee != 0) {
      self.adminFees[tokenIndexTo] = self.adminFees[tokenIndexTo].add(dyAdminFee);
    }

    self.pooledTokens[tokenIndexTo].safeTransfer(msg.sender, dy);

    emit TokenSwap(msg.sender, dx, dy, tokenIndexFrom, tokenIndexTo);

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
    require(dy <= self.balances[tokenIndexTo], ">pool balance");

    uint256 dx;
    uint256 dxFee;
    uint256[] memory balances = self.balances;
    (dx, dxFee) = _calculateSwapInv(self, tokenIndexFrom, tokenIndexTo, dy, balances);
    require(dx <= maxDx, "dx > maxDx");

    uint256 dxAdminFee = dxFee.mul(self.adminFee).div(FEE_DENOMINATOR).div(
      self.tokenPrecisionMultipliers[tokenIndexFrom]
    );

    self.balances[tokenIndexFrom] = balances[tokenIndexFrom].add(dx).sub(dxAdminFee);
    self.balances[tokenIndexTo] = balances[tokenIndexTo].sub(dy);
    if (dxAdminFee != 0) {
      self.adminFees[tokenIndexFrom] = self.adminFees[tokenIndexFrom].add(dxAdminFee);
    }

    {
      IERC20 tokenFrom = self.pooledTokens[tokenIndexFrom];
      require(dx <= tokenFrom.balanceOf(msg.sender), "more than you own");
      // Transfer tokens first to see if a fee was charged on transfer
      uint256 beforeBalance = tokenFrom.balanceOf(address(this));
      tokenFrom.safeTransferFrom(msg.sender, address(this), dx);

      // Use the actual transferred amount for AMM math
      require(dx == tokenFrom.balanceOf(address(this)).sub(beforeBalance), "not support fee token");
    }

    self.pooledTokens[tokenIndexTo].safeTransfer(msg.sender, dy);

    emit TokenSwap(msg.sender, dx, dy, tokenIndexFrom, tokenIndexTo);

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
    IERC20 tokenFrom = self.pooledTokens[tokenIndexFrom];
    require(dx <= tokenFrom.balanceOf(msg.sender), "more than you own");

    uint256 dy;
    uint256 dyFee;
    uint256[] memory balances = self.balances;
    (dy, dyFee) = _calculateSwap(self, tokenIndexFrom, tokenIndexTo, dx, balances);
    require(dy >= minDy, "dy < minDy");

    uint256 dyAdminFee = dyFee.mul(self.adminFee).div(FEE_DENOMINATOR).div(
      self.tokenPrecisionMultipliers[tokenIndexTo]
    );

    self.balances[tokenIndexFrom] = balances[tokenIndexFrom].add(dx);
    self.balances[tokenIndexTo] = balances[tokenIndexTo].sub(dy).sub(dyAdminFee);

    if (dyAdminFee != 0) {
      self.adminFees[tokenIndexTo] = self.adminFees[tokenIndexTo].add(dyAdminFee);
    }

    emit TokenSwap(msg.sender, dx, dy, tokenIndexFrom, tokenIndexTo);

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
    require(dy <= self.balances[tokenIndexTo], "more than pool balance");

    uint256 dx;
    uint256 dxFee;
    uint256[] memory balances = self.balances;
    (dx, dxFee) = _calculateSwapInv(self, tokenIndexFrom, tokenIndexTo, dy, balances);
    require(dx <= maxDx, "dx > maxDx");

    uint256 dxAdminFee = dxFee.mul(self.adminFee).div(FEE_DENOMINATOR).div(
      self.tokenPrecisionMultipliers[tokenIndexFrom]
    );

    self.balances[tokenIndexFrom] = balances[tokenIndexFrom].add(dx).sub(dxAdminFee);
    self.balances[tokenIndexTo] = balances[tokenIndexTo].sub(dy);

    if (dxAdminFee != 0) {
      self.adminFees[tokenIndexFrom] = self.adminFees[tokenIndexFrom].add(dxAdminFee);
    }

    emit TokenSwap(msg.sender, dx, dy, tokenIndexFrom, tokenIndexTo);

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
    IERC20[] memory pooledTokens = self.pooledTokens;
    uint256 numTokens = pooledTokens.length;
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
        uint256 beforeBalance = pooledTokens[i].balanceOf(address(this));
        pooledTokens[i].safeTransferFrom(msg.sender, address(this), amounts[i]);

        // Update the amounts[] with actual transfer amount
        amounts[i] = pooledTokens[i].balanceOf(address(this)).sub(beforeBalance);
      }

      newBalances[i] = v.balances[i].add(amounts[i]);

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
        uint256 idealBalance = v.d1.mul(v.balances[i]).div(v.d0);
        fees[i] = feePerToken.mul(idealBalance.difference(newBalances[i])).div(FEE_DENOMINATOR);
        uint256 adminFee = fees[i].mul(self.adminFee).div(FEE_DENOMINATOR);
        self.balances[i] = newBalances[i].sub(adminFee);
        self.adminFees[i] = self.adminFees[i].add(adminFee);
        newBalances[i] = newBalances[i].sub(fees[i]);

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
      toMint = v.d2.sub(v.d0).mul(v.totalSupply).div(v.d0);
    }

    require(toMint >= minToMint, "mint < min");

    // mint the user's LP tokens
    v.lpToken.mint(msg.sender, toMint);

    emit AddLiquidity(msg.sender, amounts, fees, v.d1, v.totalSupply.add(toMint));

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
    IERC20[] memory pooledTokens = self.pooledTokens;
    require(amount <= lpToken.balanceOf(msg.sender), ">LP.balanceOf");
    uint256 numTokens = pooledTokens.length;
    require(minAmounts.length == numTokens, "mismatch poolTokens");

    uint256[] memory balances = self.balances;
    uint256 totalSupply = lpToken.totalSupply();

    uint256[] memory amounts = _calculateRemoveLiquidity(balances, amount, totalSupply);

    uint256 numAmounts = amounts.length;
    for (uint256 i; i < numAmounts; ) {
      require(amounts[i] >= minAmounts[i], "amounts[i] < minAmounts[i]");
      self.balances[i] = balances[i].sub(amounts[i]);
      pooledTokens[i].safeTransfer(msg.sender, amounts[i]);

      unchecked {
        ++i;
      }
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
  ) internal returns (uint256) {
    LPToken lpToken = self.lpToken;
    IERC20[] memory pooledTokens = self.pooledTokens;

    require(tokenAmount <= lpToken.balanceOf(msg.sender), ">LP.balanceOf");
    uint256 numTokens = pooledTokens.length;
    require(tokenIndex < numTokens, "not found");

    uint256 totalSupply = lpToken.totalSupply();

    (uint256 dy, uint256 dyFee) = _calculateWithdrawOneToken(self, tokenAmount, tokenIndex, totalSupply);

    require(dy >= minAmount, "dy < minAmount");

    uint256 adminFee = dyFee.mul(self.adminFee).div(FEE_DENOMINATOR);
    self.balances[tokenIndex] = self.balances[tokenIndex].sub(dy.add(adminFee));
    if (adminFee != 0) {
      self.adminFees[tokenIndex] = self.adminFees[tokenIndex].add(adminFee);
    }
    lpToken.burnFrom(msg.sender, tokenAmount);
    pooledTokens[tokenIndex].safeTransfer(msg.sender, dy);

    emit RemoveLiquidityOne(msg.sender, tokenAmount, totalSupply, tokenIndex, dy);

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

    IERC20[] memory pooledTokens = self.pooledTokens;

    uint256 numTokens = pooledTokens.length;
    uint256 numAmounts = amounts.length;
    require(numAmounts == numTokens, "mismatch pool tokens");

    require(maxBurnAmount <= v.lpToken.balanceOf(msg.sender) && maxBurnAmount != 0, ">LP.balanceOf");

    uint256 feePerToken = _feePerToken(self.swapFee, numTokens);
    uint256[] memory fees = new uint256[](numTokens);
    {
      uint256[] memory balances1 = new uint256[](numTokens);
      v.d0 = getD(_xp(v.balances, v.multipliers), v.preciseA);
      for (uint256 i; i < numTokens; ) {
        balances1[i] = v.balances[i].sub(amounts[i], "withdraw more than available");

        unchecked {
          ++i;
        }
      }
      v.d1 = getD(_xp(balances1, v.multipliers), v.preciseA);

      for (uint256 i; i < numTokens; ) {
        {
          uint256 idealBalance = v.d1.mul(v.balances[i]).div(v.d0);
          uint256 difference = idealBalance.difference(balances1[i]);
          fees[i] = feePerToken.mul(difference).div(FEE_DENOMINATOR);
        }
        uint256 adminFee = fees[i].mul(self.adminFee).div(FEE_DENOMINATOR);
        self.balances[i] = balances1[i].sub(adminFee);
        self.adminFees[i] = self.adminFees[i].add(adminFee);
        balances1[i] = balances1[i].sub(fees[i]);

        unchecked {
          ++i;
        }
      }

      v.d2 = getD(_xp(balances1, v.multipliers), v.preciseA);
    }
    uint256 tokenAmount = v.d0.sub(v.d2).mul(v.totalSupply).div(v.d0);
    require(tokenAmount != 0, "!zero amount");
    tokenAmount = tokenAmount.add(1);

    require(tokenAmount <= maxBurnAmount, "tokenAmount > maxBurnAmount");

    v.lpToken.burnFrom(msg.sender, tokenAmount);

    for (uint256 i; i < numTokens; ) {
      pooledTokens[i].safeTransfer(msg.sender, amounts[i]);

      unchecked {
        ++i;
      }
    }

    emit RemoveLiquidityImbalance(msg.sender, amounts, fees, v.d1, v.totalSupply.sub(tokenAmount));

    return tokenAmount;
  }

  /**
   * @notice withdraw all admin fees to a given address
   * @param self Swap struct to withdraw fees from
   * @param to Address to send the fees to
   */
  function withdrawAdminFees(Swap storage self, address to) internal {
    IERC20[] memory pooledTokens = self.pooledTokens;
    for (uint256 i; i < pooledTokens.length; ) {
      IERC20 token = pooledTokens[i];
      uint256 balance = self.adminFees[i];
      if (balance != 0) {
        self.adminFees[i] = 0;
        token.safeTransfer(to, balance);
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
    require(newAdminFee <= MAX_ADMIN_FEE, "too high");
    self.adminFee = newAdminFee;

    emit NewAdminFee(newAdminFee);
  }

  /**
   * @notice update the swap fee
   * @dev fee cannot be higher than 1% of each swap
   * @param self Swap struct to update
   * @param newSwapFee new swap fee to be applied on future transactions
   */
  function setSwapFee(Swap storage self, uint256 newSwapFee) internal {
    require(newSwapFee <= MAX_SWAP_FEE, "too high");
    self.swapFee = newSwapFee;

    emit NewSwapFee(newSwapFee);
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.15;

import {Home} from "../../nomad-core/contracts/Home.sol";
import {TypedMemView} from "../../nomad-core/libs/TypedMemView.sol";

import {AddressUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import {IConnextHandler} from "../connext/interfaces/IConnextHandler.sol";
import {IBridgeToken} from "../connext/interfaces/IBridgeToken.sol";

import {Router} from "../shared/Router.sol";
import {XAppConnectionClient} from "../shared/XAppConnectionClient.sol";
import {Version} from "../shared/Version.sol";

import {ICallback} from "./interfaces/ICallback.sol";
import {PromiseMessage} from "./libraries/PromiseMessage.sol";

/**
 * @title PromiseRouter
 */
contract PromiseRouter is Version, Router, ReentrancyGuardUpgradeable {
  // ============ Libraries ============

  using TypedMemView for bytes;
  using TypedMemView for bytes29;
  using PromiseMessage for bytes29;

  // ========== Custom Errors ===========

  error PromiseRouter__onlyConnext_notConnext();
  error PromiseRouter__send_returndataEmpty();
  error PromiseRouter__send_callbackEmpty();
  error PromiseRouter__process_invalidTransferId();
  error PromiseRouter__process_invalidMessage();
  error PromiseRouter__process_notApprovedRelayer();
  error PromiseRouter__process_insufficientCallbackFee();
  error PromiseRouter__process_notContractCallback();
  error PromiseRouter__bumpCallbackFee_valueIsZero();
  error PromiseRouter__bumpCallbackFee_messageUnavailable();
  error PromiseRouter__initCallbackFee_valueIsZero();

  // ============ Public Storage ============

  IConnextHandler public connext;

  /**
   * @notice Mapping of transferId to promise callback messages
   * @dev While handling the message, it will parse transferId from incomming message and store the message in the mapping
   */
  mapping(bytes32 => bytes32) public messageHashes;

  /**
   * @notice Mapping of transferId to callback fee
   * @dev This will track all the callback fees for each transferId.
   * Can add while xcall or bumping callback fee
   */
  mapping(bytes32 => uint256) public callbackFees;

  // ============ Upgrade Gap ============

  // gap for upgrade safety
  uint256[49] private __GAP;

  // ======== Events =========

  /**
   * @notice Emitted when a promise callback has been sent from this domain
   * @param domain The domain where to execute the callback
   * @param remote Remote PromiseRouter address
   * @param transferId The transferId
   * @param callbackAddress The address of the callback
   * @param success The return success from the execution on the destination domain
   * @param data The returnData from the execution on the destination domain
   * @param message The message sent to the destination domain
   */
  event Send(
    uint32 domain,
    bytes32 remote,
    bytes32 transferId,
    address callbackAddress,
    bool success,
    bytes data,
    bytes message
  );

  /**
   * @notice Emitted when a promise callback message has arrived to this domain
   * @param originAndNonce Domain where the transfer originated and the unique identifier
   * for the message from origin to destination, combined in a single field ((origin << 32) & nonce)
   * @param origin Domain where the transfer originated
   * @param transferId The transferId
   * @param callbackAddress The address of the callback
   * @param success The return success from the execution on the destination domain
   * @param data The returnData from the execution on the destination domain
   * @param message The message sent to the destination domain
   */
  event Receive(
    uint64 indexed originAndNonce,
    uint32 indexed origin,
    bytes32 transferId,
    address callbackAddress,
    bool success,
    bytes data,
    bytes message
  );

  /**
   * @notice Emitted when transaction fee for callback added
   * @param transferId The transferId
   * @param addedFee The fee amount that added newly
   * @param totalFee The total fee amount, can be bumped by multiple times
   * @param caller The transaction caller
   */
  event CallbackFeeAdded(bytes32 indexed transferId, uint256 addedFee, uint256 totalFee, address caller);

  /**
   * @notice Emitted when callback function executed
   * @param transferId The transferId
   * @param relayer The address of the relayer which executed the callback
   */
  event CallbackExecuted(bytes32 indexed transferId, address relayer);

  /**
   * @notice Emitted when a new Connext address is set
   * @param connext The new connext address
   */
  event SetConnext(address indexed connext);

  // ============ Modifiers ============

  /**
   * @notice Restricts the caller to the local bridge router
   */
  modifier onlyConnext() {
    if (msg.sender != address(connext)) revert PromiseRouter__onlyConnext_notConnext();
    _;
  }

  // ======== Initializer ========

  function initialize(address _xAppConnectionManager) public initializer {
    __XAppConnectionClient_initialize(_xAppConnectionManager);
  }

  /**
   * @notice Sets the Connext.
   * @dev Connext and relayer fee router store references to each other
   * @param _connext The address of the Connext implementation
   */
  function setConnext(address _connext) external onlyOwner {
    connext = IConnextHandler(_connext);
    emit SetConnext(_connext);
  }

  // ======== External: Send PromiseCallback =========

  /**
   * @notice Sends a request to execute callback in the originated domain
   * @param _domain The domain where to execute callback
   * @param _transferId The transferId
   * @param _callbackAddress A callback address to be called when promise callback is received
   * @param _returnSuccess The returnSuccess from the execution
   * @param _returnData The returnData from the execution
   */
  function send(
    uint32 _domain,
    bytes32 _transferId,
    address _callbackAddress,
    bool _returnSuccess,
    bytes calldata _returnData
  ) external onlyConnext {
    if (_returnData.length == 0) revert PromiseRouter__send_returndataEmpty();
    if (_callbackAddress == address(0)) revert PromiseRouter__send_callbackEmpty();

    // get remote PromiseRouter address; revert if not found
    bytes32 remote = _mustHaveRemote(_domain);

    bytes memory message = PromiseMessage.formatPromiseCallback(
      _transferId,
      _callbackAddress,
      _returnSuccess,
      _returnData
    );

    xAppConnectionManager.home().dispatch(_domain, remote, message);

    // emit Send event
    emit Send(_domain, remote, _transferId, _callbackAddress, _returnSuccess, _returnData, message);
  }

  // ======== External: Handle =========

  /**
   * @notice Handles an incoming message
   * @param _origin The origin domain
   * @param _nonce The unique identifier for the message from origin to destination
   * @param _sender The sender address
   * @param _message The message
   */
  function handle(
    uint32 _origin,
    uint32 _nonce,
    bytes32 _sender,
    bytes memory _message
  ) external override onlyReplica onlyRemoteRouter(_origin, _sender) {
    // parse transferId, callbackAddress, callData from message
    bytes29 _msg = _message.ref(0).mustBePromiseCallback();

    bytes32 transferId = _msg.transferId();
    address callbackAddress = _msg.callbackAddress();
    bool success = _msg.returnSuccess();
    bytes memory data = _msg.returnData();

    // store Promise message
    messageHashes[transferId] = _msg.keccak();

    // emit Receive event
    emit Receive(_originAndNonce(_origin, _nonce), _origin, transferId, callbackAddress, success, data, _message);
  }

  /**
   * @notice Process stored callback function
   * @param transferId The transferId to process
   */
  function process(bytes32 transferId, bytes calldata _message) public nonReentrant {
    // parse out the return data and callback address from message
    bytes32 messageHash = messageHashes[transferId];
    if (messageHash == bytes32(0)) revert PromiseRouter__process_invalidTransferId();

    bytes29 _msg = _message.ref(0).mustBePromiseCallback();
    if (messageHash != _msg.keccak()) revert PromiseRouter__process_invalidMessage();

    // enforce relayer is whitelisted by calling local connext contract
    if (!connext.approvedRelayers(msg.sender)) revert PromiseRouter__process_notApprovedRelayer();

    address callbackAddress = _msg.callbackAddress();

    if (!AddressUpgradeable.isContract(callbackAddress)) revert PromiseRouter__process_notContractCallback();

    uint256 callbackFee = callbackFees[transferId];

    // remove message
    delete messageHashes[transferId];

    // remove callback fees
    callbackFees[transferId] = 0;

    // execute callback
    ICallback(callbackAddress).callback(transferId, _msg.returnSuccess(), _msg.returnData());

    emit CallbackExecuted(transferId, msg.sender);

    // Should transfer the stored relayer fee to the msg.sender
    if (callbackFee != 0) {
      AddressUpgradeable.sendValue(payable(msg.sender), callbackFee);
    }
  }

  /**
   * @notice This function will be called on the origin domain to init the callback fee while xcall
   * @param _transferId - The unique identifier of the crosschain transaction
   */
  function initCallbackFee(bytes32 _transferId) external payable onlyConnext {
    if (msg.value == 0) revert PromiseRouter__initCallbackFee_valueIsZero();

    callbackFees[_transferId] += msg.value;

    emit CallbackFeeAdded(_transferId, msg.value, callbackFees[_transferId], msg.sender);
  }

  /**
   * @notice This function will be called on the origin domain to increase the callback fee
   * @param _transferId - The unique identifier of the crosschain transaction
   */
  function bumpCallbackFee(bytes32 _transferId) external payable {
    if (msg.value == 0) revert PromiseRouter__bumpCallbackFee_valueIsZero();

    // use the presence of the message to evaluate if the fee should be bumped.
    // this is to check that the user is not bumping a transferId that does not exist, or they
    // are not bumping the fees of a transfer that has already been processed.
    // the other options are to (a) track process status in a separate mapping (3 mappings updated)
    // on process) or (b) use the callbackFees mapping and require the callback fees are nonzero
    // on xcall (preventing 0-fee callbacks)
    if (messageHashes[_transferId] == bytes32(0)) revert PromiseRouter__bumpCallbackFee_messageUnavailable();

    callbackFees[_transferId] += msg.value;

    emit CallbackFeeAdded(_transferId, msg.value, callbackFees[_transferId], msg.sender);
  }

  /**
   * @dev explicit override for compiler inheritance
   * @return domain of chain on which the contract is deployed
   */
  function _localDomain() internal view override(XAppConnectionClient) returns (uint32) {
    return XAppConnectionClient._localDomain();
  }

  /**
   * @notice Internal utility function that combines
   * `_origin` and `_nonce`.
   * @dev Both origin and nonce should be less than 2^32 - 1
   * @param _origin Domain of chain where the transfer originated
   * @param _nonce The unique identifier for the message from origin to destination
   * @return uint64 (`_origin` << 32) | `_nonce`
   */
  function _originAndNonce(uint32 _origin, uint32 _nonce) internal pure returns (uint64) {
    return (uint64(_origin) << 32) | _nonce;
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

interface ICallback {
  function callback(
    bytes32 transferId,
    bool success,
    bytes memory data
  ) external;
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.15;

// ============ External Imports ============
import {TypedMemView} from "../../../nomad-core/libs/TypedMemView.sol";

library PromiseMessage {
  // ============ Libraries ============

  using TypedMemView for bytes;
  using TypedMemView for bytes29;

  // ============ Enums ============

  // WARNING: do NOT re-write the numbers / order
  // of message types in an upgrade;
  // will cause in-flight messages to be mis-interpreted
  enum Types {
    Invalid, // 0
    PromiseCallback // 1
  }

  // ============ Constants ============
  uint256 private constant IDENTIFIER_LEN = 1;
  // 1 byte identifier + 32 bytes transferId + 20 bytes callback + 1 byte success + 32 bytes length + x bytes data
  // before: 1 byte identifier + 32 bytes transferId + 20 bytes callback + 1 byte success= 54 bytes
  uint256 private constant LENGTH_RETURNDATA_START = 54;
  uint8 private constant LENGTH_RETURNDATA_LEN = 32;

  // before: 1 byte identifier + 32 bytes transferId + 20 bytes callback +  1 byte success + 32 bytes length = 86 bytes
  uint256 private constant RETURNDATA_START = 86;

  // ============ Modifiers ============

  /**
   * @notice Asserts a message is of type `_t`
   * @param _view The message
   * @param _t The expected type
   */
  modifier typeAssert(bytes29 _view, Types _t) {
    _view.assertType(uint40(_t));
    _;
  }

  // ============ Formatters ============

  /**
   * @notice Formats an promise callback message
   * @param _transferId The address of the relayer
   * @param _callbackAddress The callback address on destination domain
   * @param _returnSuccess The success of the call
   * @param _returnData The return data of the call
   * @return The formatted message
   */
  function formatPromiseCallback(
    bytes32 _transferId,
    address _callbackAddress,
    bool _returnSuccess,
    bytes calldata _returnData
  ) internal pure returns (bytes memory) {
    return
      abi.encodePacked(
        uint8(Types.PromiseCallback),
        _transferId,
        _callbackAddress,
        uint8(_returnSuccess ? 1 : 0),
        _returnData.length,
        _returnData
      );
  }

  // ============ Getters ============

  /**
   * @notice Parse the transferId from the message
   * @param _view The message
   * @return The transferId
   */
  function transferId(bytes29 _view) internal pure typeAssert(_view, Types.PromiseCallback) returns (bytes32) {
    // before = 1 byte identifier
    return _view.index(1, 32);
  }

  /**
   * @notice Parse the callback address from the message
   * @param _view The message
   * @return The callback address
   */
  function callbackAddress(bytes29 _view) internal pure typeAssert(_view, Types.PromiseCallback) returns (address) {
    // before = 1 byte identifier + 32 bytes transferId
    return _view.indexAddress(33);
  }

  /**
   * @notice Parse the result of execution on the destination domain
   * @param _view The message
   * @return The call result
   */
  function returnSuccess(bytes29 _view) internal pure typeAssert(_view, Types.PromiseCallback) returns (bool) {
    // before: 1 byte identifier + 32 bytes transferId + 20 bytes callback = 53 bytes
    return _view.indexUint(53, 1) == 1;
  }

  /**
   * @notice Parse the returnData length from the message
   * @param _view The message
   * @return The returnData length
   */
  function lengthOfReturnData(bytes29 _view) internal pure returns (uint256) {
    return _view.indexUint(LENGTH_RETURNDATA_START, LENGTH_RETURNDATA_LEN);
  }

  /**
   * @notice Parse returnData from the message
   * @param _view The message
   * @return data
   */
  function returnData(bytes29 _view)
    internal
    view
    typeAssert(_view, Types.PromiseCallback)
    returns (bytes memory data)
  {
    uint256 length = lengthOfReturnData(_view);

    data = _view.slice(RETURNDATA_START, length, 0).clone();
  }

  /**
   * @notice Checks that view is a valid message length
   * @param _view The bytes string
   * @return TRUE if message is valid
   */
  function isValidPromiseCallbackLength(bytes29 _view) internal pure returns (bool) {
    uint256 _len = _view.len();
    if (_len <= LENGTH_RETURNDATA_START) {
      return false;
    }
    uint256 _length = lengthOfReturnData(_view);
    // before = 1 byte identifier + 32 bytes transferId + 20 bytes callback address + 1 byte success + 32 bytes length + x bytes data
    // allow zero-length return data
    return _length >= 0 && (RETURNDATA_START + _length) == _len;
  }

  /**
   * @notice Converts to a Promise callback message
   * @param _view The message
   * @return The newly typed message
   */
  function tryAsPromiseCallback(bytes29 _view) internal pure returns (bytes29) {
    if (isValidPromiseCallbackLength(_view)) {
      return _view.castTo(uint40(Types.PromiseCallback));
    }
    return TypedMemView.nullView();
  }

  /**
   * @notice Asserts that the message is of type PromiseCallback
   * @param _view The message
   * @return The message
   */
  function mustBePromiseCallback(bytes29 _view) internal pure returns (bytes29) {
    return tryAsPromiseCallback(_view).assertValid();
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.15;

import {Home} from "../../nomad-core/contracts/Home.sol";
import {TypedMemView} from "../../nomad-core/libs/TypedMemView.sol";

import {IConnextHandler} from "../connext/interfaces/IConnextHandler.sol";

import {Router} from "../shared/Router.sol";
import {XAppConnectionClient} from "../shared/XAppConnectionClient.sol";
import {Version} from "../shared/Version.sol";

import {RelayerFeeMessage} from "./libraries/RelayerFeeMessage.sol";

/**
 * @title RelayerFeeRouter
 */
contract RelayerFeeRouter is Version, Router {
  // ============ Libraries ============

  using TypedMemView for bytes;
  using TypedMemView for bytes29;
  using RelayerFeeMessage for bytes29;

  // ========== Custom Errors ===========

  error RelayerFeeRouter__onlyConnext_notConnext();
  error RelayerFeeRouter__send_claimEmpty();
  error RelayerFeeRouter__send_recipientEmpty();

  // ============ Public Storage ============

  IConnextHandler public connext;

  // ============ Upgrade Gap ============

  // gap for upgrade safety
  uint256[49] private __GAP;

  // ======== Events =========

  /**
   * @notice Emitted when a fees claim has been initialized in this domain
   * @param domain The domain where to claim the fees
   * @param recipient The address of the relayer
   * @param transferIds A group of transaction ids to claim for fee bumps
   * @param remote Remote RelayerFeeRouter address
   * @param message The message sent to the destination domain
   */
  event Send(uint32 domain, address recipient, bytes32[] transferIds, bytes32 remote, bytes message);

  /**
   * @notice Emitted when the a fees claim message has arrived to this domain
   * @param originAndNonce Domain where the transfer originated and the unique identifier
   * for the message from origin to destination, combined in a single field ((origin << 32) & nonce)
   * @param origin Domain where the transfer originated
   * @param recipient The address of the relayer
   * @param transferIds A group of transaction ids to claim for fee bumps
   */
  event Receive(uint64 indexed originAndNonce, uint32 indexed origin, address indexed recipient, bytes32[] transferIds);

  /**
   * @notice Emitted when a new Connext address is set
   * @param connext The new connext address
   */
  event SetConnext(address indexed connext);

  // ============ Modifiers ============

  /**
   * @notice Restricts the caller to the local bridge router
   */
  modifier onlyConnext() {
    if (msg.sender != address(connext)) revert RelayerFeeRouter__onlyConnext_notConnext();
    _;
  }

  // ======== Initializer ========

  function initialize(address _xAppConnectionManager) public initializer {
    __XAppConnectionClient_initialize(_xAppConnectionManager);
  }

  /**
   * @notice Sets the Connext.
   * @dev Connext and relayer fee router store references to each other
   * @param _connext The address of the Connext implementation
   */
  function setConnext(address _connext) external onlyOwner {
    connext = IConnextHandler(_connext);
    emit SetConnext(_connext);
  }

  // ======== External: Send Claim =========

  /**
   * @notice Sends a request to claim the fees in the originated domain
   * @param _domain The domain where to claim the fees
   * @param _recipient The address of the relayer
   * @param _transferIds A group of transfer ids to claim for fee bumps
   */
  function send(
    uint32 _domain,
    address _recipient,
    bytes32[] calldata _transferIds
  ) external onlyConnext {
    if (_transferIds.length == 0) revert RelayerFeeRouter__send_claimEmpty();
    if (_recipient == address(0)) revert RelayerFeeRouter__send_recipientEmpty();

    // get remote RelayerFeeRouter address; revert if not found
    bytes32 remote = _mustHaveRemote(_domain);

    bytes memory message = RelayerFeeMessage.formatClaimFees(_recipient, _transferIds);

    xAppConnectionManager.home().dispatch(_domain, remote, message);

    // emit Send event
    emit Send(_domain, _recipient, _transferIds, remote, message);
  }

  // ======== External: Handle =========

  /**
   * @notice Handles an incoming message
   * @param _origin The origin domain
   * @param _nonce The unique identifier for the message from origin to destination
   * @param _sender The sender address
   * @param _message The message
   */
  function handle(
    uint32 _origin,
    uint32 _nonce,
    bytes32 _sender,
    bytes memory _message
  ) external override onlyReplica onlyRemoteRouter(_origin, _sender) {
    // parse recipient and transferIds from message
    bytes29 _msg = _message.ref(0).mustBeClaimFees();

    address recipient = _msg.recipient();
    bytes32[] memory transferIds = _msg.transferIds();

    connext.claim(recipient, transferIds);

    // emit Receive event
    emit Receive(_originAndNonce(_origin, _nonce), _origin, recipient, transferIds);
  }

  /**
   * @dev explicit override for compiler inheritance
   * @dev explicit override for compiler inheritance
   * @return domain of chain on which the contract is deployed
   */
  function _localDomain() internal view override(XAppConnectionClient) returns (uint32) {
    return XAppConnectionClient._localDomain();
  }

  /**
   * @notice Internal utility function that combines
   * `_origin` and `_nonce`.
   * @dev Both origin and nonce should be less than 2^32 - 1
   * @param _origin Domain of chain where the transfer originated
   * @param _nonce The unique identifier for the message from origin to destination
   * @return uint64 (`_origin` << 32) | `_nonce`
   */
  function _originAndNonce(uint32 _origin, uint32 _nonce) internal pure returns (uint64) {
    return (uint64(_origin) << 32) | _nonce;
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.15;

// ============ External Imports ============
import {TypedMemView} from "../../../nomad-core/libs/TypedMemView.sol";

library RelayerFeeMessage {
  // ============ Libraries ============

  using TypedMemView for bytes;
  using TypedMemView for bytes29;

  // ============ Enums ============

  // WARNING: do NOT re-write the numbers / order
  // of message types in an upgrade;
  // will cause in-flight messages to be mis-interpreted
  enum Types {
    Invalid, // 0
    ClaimFees // 1
  }

  // ============ Constants ============

  // before: 1 byte identifier + 20 bytes recipient + 32 bytes length + 32 bytes 1 transfer id = 85 bytes
  uint256 private constant MIN_CLAIM_LEN = 85;
  // before: 1 byte identifier + 20 bytes recipient = 21 bytes
  uint256 private constant LENGTH_ID_START = 21;
  uint8 private constant LENGTH_ID_LEN = 32;
  // before: 1 byte identifier
  uint256 private constant RECIPIENT_START = 1;
  // before: 1 byte identifier + 20 bytes recipient + 32 bytes length = 53 bytes
  uint256 private constant TRANSFER_IDS_START = 53;
  uint8 private constant TRANSFER_ID_LEN = 32;

  // ============ Modifiers ============

  /**
   * @notice Asserts a message is of type `_t`
   * @param _view The message
   * @param _t The expected type
   */
  modifier typeAssert(bytes29 _view, Types _t) {
    _view.assertType(uint40(_t));
    _;
  }

  // ============ Formatters ============

  /**
   * @notice Formats an claim fees message
   * @param _recipient The address of the relayer
   * @param _transferIds A group of transfers ids to claim for fee bumps
   * @return The formatted message
   */
  function formatClaimFees(address _recipient, bytes32[] calldata _transferIds) internal pure returns (bytes memory) {
    return abi.encodePacked(uint8(Types.ClaimFees), _recipient, _transferIds.length, _transferIds);
  }

  // ============ Getters ============

  /**
   * @notice Parse the recipient address of the fees
   * @param _view The message
   * @return The recipient address
   */
  function recipient(bytes29 _view) internal pure typeAssert(_view, Types.ClaimFees) returns (address) {
    // before = 1 byte identifier
    return _view.indexAddress(1);
  }

  /**
   * @notice Parse The group of transfers ids to claim for fee bumps
   * @param _view The message
   * @return The group of transfers ids to claim for fee bumps
   */
  function transferIds(bytes29 _view) internal pure typeAssert(_view, Types.ClaimFees) returns (bytes32[] memory) {
    uint256 length = _view.indexUint(LENGTH_ID_START, LENGTH_ID_LEN);

    bytes32[] memory ids = new bytes32[](length);
    for (uint256 i; i < length; ) {
      ids[i] = _view.index(TRANSFER_IDS_START + i * TRANSFER_ID_LEN, TRANSFER_ID_LEN);

      unchecked {
        ++i;
      }
    }
    return ids;
  }

  /**
   * @notice Checks that view is a valid message length
   * @param _view The bytes string
   * @return TRUE if message is valid
   */
  function isValidClaimFeesLength(bytes29 _view) internal pure returns (bool) {
    uint256 _len = _view.len();
    // at least 1 transfer id where the excess is multiplier of transfer id length
    return _len >= MIN_CLAIM_LEN && (_len - TRANSFER_IDS_START) % TRANSFER_ID_LEN == 0;
  }

  /**
   * @notice Converts to a ClaimFees
   * @param _view The message
   * @return The newly typed message
   */
  function tryAsClaimFees(bytes29 _view) internal pure returns (bytes29) {
    if (isValidClaimFeesLength(_view)) {
      return _view.castTo(uint40(Types.ClaimFees));
    }
    return TypedMemView.nullView();
  }

  /**
   * @notice Asserts that the message is of type ClaimFees
   * @param _view The message
   * @return The message
   */
  function mustBeClaimFees(bytes29 _view) internal pure returns (bytes29) {
    return tryAsClaimFees(_view).assertValid();
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import {IProposedOwnable} from "./interfaces/IProposedOwnable.sol";

/**
 * @title ProposedOwnable
 * @notice Contract module which provides a basic access control mechanism,
 * where there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed via a two step process:
 * 1. Call `proposeOwner`
 * 2. Wait out the delay period
 * 3. Call `acceptOwner`
 *
 * @dev This module is used through inheritance. It will make available the
 * modifier `onlyOwner`, which can be applied to your functions to restrict
 * their use to the owner.
 *
 * @dev The majority of this code was taken from the openzeppelin Ownable
 * contract
 *
 */
abstract contract ProposedOwnable is IProposedOwnable {
  // ========== Custom Errors ===========

  error ProposedOwnable__onlyOwner_notOwner();
  error ProposedOwnable__onlyProposed_notProposedOwner();
  error ProposedOwnable__proposeNewOwner_invalidProposal();
  error ProposedOwnable__proposeNewOwner_noOwnershipChange();
  error ProposedOwnable__renounceOwnership_noProposal();
  error ProposedOwnable__renounceOwnership_delayNotElapsed();
  error ProposedOwnable__renounceOwnership_invalidProposal();
  error ProposedOwnable__acceptProposedOwner_delayNotElapsed();

  // ============ Properties ============

  address private _owner;

  address private _proposed;
  uint256 private _proposedOwnershipTimestamp;

  uint256 private constant _delay = 7 days;

  // ======== Getters =========

  /**
   * @notice Returns the address of the current owner.
   */
  function owner() public view virtual returns (address) {
    return _owner;
  }

  /**
   * @notice Returns the address of the proposed owner.
   */
  function proposed() public view virtual returns (address) {
    return _proposed;
  }

  /**
   * @notice Returns the address of the proposed owner.
   */
  function proposedTimestamp() public view virtual returns (uint256) {
    return _proposedOwnershipTimestamp;
  }

  /**
   * @notice Returns the delay period before a new owner can be accepted.
   */
  function delay() public view virtual returns (uint256) {
    return _delay;
  }

  /**
   * @notice Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    if (_owner != msg.sender) revert ProposedOwnable__onlyOwner_notOwner();
    _;
  }

  /**
   * @notice Throws if called by any account other than the proposed owner.
   */
  modifier onlyProposed() {
    if (_proposed != msg.sender) revert ProposedOwnable__onlyProposed_notProposedOwner();
    _;
  }

  /**
   * @notice Indicates if the ownership has been renounced() by
   * checking if current owner is address(0)
   */
  function renounced() public view returns (bool) {
    return _owner == address(0);
  }

  // ======== External =========

  /**
   * @notice Sets the timestamp for an owner to be proposed, and sets the
   * newly proposed owner as step 1 in a 2-step process
   */
  function proposeNewOwner(address newlyProposed) public virtual onlyOwner {
    // Contract as source of truth
    if (_proposed == newlyProposed && newlyProposed != address(0))
      revert ProposedOwnable__proposeNewOwner_invalidProposal();

    // Sanity check: reasonable proposal
    if (_owner == newlyProposed) revert ProposedOwnable__proposeNewOwner_noOwnershipChange();

    _setProposed(newlyProposed);
  }

  /**
   * @notice Renounces ownership of the contract after a delay
   */
  function renounceOwnership() public virtual onlyOwner {
    // Ensure there has been a proposal cycle started
    if (_proposedOwnershipTimestamp == 0) revert ProposedOwnable__renounceOwnership_noProposal();

    // Ensure delay has elapsed
    if ((block.timestamp - _proposedOwnershipTimestamp) <= _delay)
      revert ProposedOwnable__renounceOwnership_delayNotElapsed();

    // Require proposed is set to 0
    if (_proposed != address(0)) revert ProposedOwnable__renounceOwnership_invalidProposal();

    // Emit event, set new owner, reset timestamp
    _setOwner(_proposed);
  }

  /**
   * @notice Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function acceptProposedOwner() public virtual onlyProposed {
    // NOTE: no need to check if _owner == _proposed, because the _proposed
    // is 0-d out and this check is implicitly enforced by modifier

    // NOTE: no need to check if _proposedOwnershipTimestamp > 0 because
    // the only time this would happen is if the _proposed was never
    // set (will fail from modifier) or if the owner == _proposed (checked
    // above)

    // Ensure delay has elapsed
    if ((block.timestamp - _proposedOwnershipTimestamp) <= _delay)
      revert ProposedOwnable__acceptProposedOwner_delayNotElapsed();

    // Emit event, set new owner, reset timestamp
    _setOwner(_proposed);
  }

  // ======== Internal =========

  function _setOwner(address newOwner) internal {
    address oldOwner = _owner;
    _owner = newOwner;
    _proposedOwnershipTimestamp = 0;
    _proposed = address(0);
    emit OwnershipTransferred(oldOwner, newOwner);
  }

  function _setProposed(address newlyProposed) private {
    _proposedOwnershipTimestamp = block.timestamp;
    _proposed = newlyProposed;
    emit OwnershipProposed(newlyProposed);
  }
}

abstract contract ProposedOwnableUpgradeable is Initializable, ProposedOwnable {
  /**
   * @dev Initializes the contract setting the deployer as the initial
   */
  function __ProposedOwnable_init() internal onlyInitializing {
    __ProposedOwnable_init_unchained();
  }

  function __ProposedOwnable_init_unchained() internal onlyInitializing {
    _setOwner(msg.sender);
  }

  /**
   * @dev This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   */
  uint256[49] private __GAP;
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.6.11;

// ============ Internal Imports ============
import {XAppConnectionClient} from "./XAppConnectionClient.sol";
// ============ External Imports ============
import {IMessageRecipient} from "../../nomad-core/interfaces/IMessageRecipient.sol";

abstract contract Router is XAppConnectionClient, IMessageRecipient {
  // ============ Mutable Storage ============

  mapping(uint32 => bytes32) public remotes;

  // ============ Upgrade Gap ============

  uint256[49] private __GAP; // gap for upgrade safety

  // ============ Modifiers ============

  /**
   * @notice Only accept messages from a remote Router contract
   * @param _origin The domain the message is coming from
   * @param _router The address the message is coming from
   */
  modifier onlyRemoteRouter(uint32 _origin, bytes32 _router) {
    require(_isRemoteRouter(_origin, _router), "!remote router");
    _;
  }

  // ============ External functions ============

  /**
   * @notice Register the address of a Router contract for the same xApp on a remote chain
   * @param _domain The domain of the remote xApp Router
   * @param _router The address of the remote xApp Router
   */
  function enrollRemoteRouter(uint32 _domain, bytes32 _router) external onlyOwner {
    remotes[_domain] = _router;
  }

  // ============ Virtual functions ============

  function handle(
    uint32 _origin,
    uint32 _nonce,
    bytes32 _sender,
    bytes memory _message
  ) external virtual override;

  // ============ Internal functions ============
  /**
   * @notice Return true if the given domain / router is the address of a remote xApp Router
   * @param _domain The domain of the potential remote xApp Router
   * @param _router The address of the potential remote xApp Router
   */
  function _isRemoteRouter(uint32 _domain, bytes32 _router) internal view returns (bool) {
    return remotes[_domain] == _router;
  }

  /**
   * @notice Assert that the given domain has a xApp Router registered and return its address
   * @param _domain The domain of the chain for which to get the xApp Router
   * @return _remote The address of the remote xApp Router on _domain
   */
  function _mustHaveRemote(uint32 _domain) internal view returns (bytes32 _remote) {
    _remote = remotes[_domain];
    require(_remote != bytes32(0), "!remote");
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.15;

/**
 * @title Version
 * @notice Version getter for contracts
 **/
contract Version {
  uint8 public constant VERSION = 0;
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.6.11;

// ============ External Imports ============
import {Home} from "../../nomad-core/contracts/Home.sol";
import {XAppConnectionManager} from "../../nomad-core/contracts/XAppConnectionManager.sol";

import {ProposedOwnableUpgradeable} from "./ProposedOwnable.sol";

abstract contract XAppConnectionClient is ProposedOwnableUpgradeable {
  // ============ Mutable Storage ============

  XAppConnectionManager public xAppConnectionManager;

  // ============ Upgrade Gap ============

  uint256[49] private __GAP; // gap for upgrade safety

  // ============ Modifiers ============

  /**
   * @notice Only accept messages from an Nomad Replica contract
   */
  modifier onlyReplica() {
    require(_isReplica(msg.sender), "!replica");
    _;
  }

  // ======== Initializer =========

  function __XAppConnectionClient_initialize(address _xAppConnectionManager) internal initializer {
    xAppConnectionManager = XAppConnectionManager(_xAppConnectionManager);
    __ProposedOwnable_init();
  }

  // ============ External functions ============

  /**
   * @notice Modify the contract the xApp uses to validate Replica contracts
   * @param _xAppConnectionManager The address of the xAppConnectionManager contract
   */
  function setXAppConnectionManager(address _xAppConnectionManager) external onlyOwner {
    xAppConnectionManager = XAppConnectionManager(_xAppConnectionManager);
  }

  // ============ Internal functions ============

  /**
   * @notice Get the local Home contract from the xAppConnectionManager
   * @return The local Home contract
   */
  function _home() internal view returns (Home) {
    return xAppConnectionManager.home();
  }

  /**
   * @notice Determine whether _potentialReplica is an enrolled Replica from the xAppConnectionManager
   * @return True if _potentialReplica is an enrolled Replica
   */
  function _isReplica(address _potentialReplica) internal view returns (bool) {
    return xAppConnectionManager.isReplica(_potentialReplica);
  }

  /**
   * @notice Get the local domain from the xAppConnectionManager
   * @return The local domain
   */
  function _localDomain() internal view virtual returns (uint32) {
    return xAppConnectionManager.localDomain();
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

/**
 * @title IProposedOwnable
 * @notice Defines a minimal interface for ownership with a two step proposal and acceptance
 * process
 */
interface IProposedOwnable {
  /**
   * @dev This emits when change in ownership of a contract is proposed.
   */
  event OwnershipProposed(address indexed proposedOwner);

  /**
   * @dev This emits when ownership of a contract changes.
   */
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @notice Get the address of the owner
   * @return owner_ The address of the owner.
   */
  function owner() external view returns (address owner_);

  /**
   * @notice Get the address of the proposed owner
   * @return proposed_ The address of the proposed.
   */
  function proposed() external view returns (address proposed_);

  /**
   * @notice Set the address of the proposed owner of the contract
   * @param newlyProposed The proposed new owner of the contract
   */
  function proposeNewOwner(address newlyProposed) external;

  /**
   * @notice Set the address of the proposed owner of the contract
   */
  function acceptProposedOwner() external;
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.6.11;

// ============ Internal Imports ============
import {Version0} from "./Version0.sol";
import {NomadBase} from "./NomadBase.sol";
import {QueueLib} from "../libs/Queue.sol";
import {MerkleLib} from "../libs/Merkle.sol";
import {Message} from "../libs/Message.sol";
import {MerkleTreeManager} from "./Merkle.sol";
import {QueueManager} from "./Queue.sol";
import {IUpdaterManager} from "../interfaces/IUpdaterManager.sol";
// ============ External Imports ============
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

/**
 * @title Home
 * @author Illusory Systems Inc.
 * @notice Accepts messages to be dispatched to remote chains,
 * constructs a Merkle tree of the messages,
 * and accepts signatures from a bonded Updater
 * which notarize the Merkle tree roots.
 * Accepts submissions of fraudulent signatures
 * by the Updater and slashes the Updater in this case.
 */
contract Home is Version0, QueueManager, MerkleTreeManager, NomadBase {
  // ============ Libraries ============

  using QueueLib for QueueLib.Queue;
  using MerkleLib for MerkleLib.Tree;

  // ============ Constants ============

  // Maximum bytes per message = 2 KiB
  // (somewhat arbitrarily set to begin)
  uint256 public constant MAX_MESSAGE_BODY_BYTES = 2 * 2**10;

  // ============ Public Storage Variables ============

  // domain => next available nonce for the domain
  mapping(uint32 => uint32) public nonces;
  // contract responsible for Updater bonding, slashing and rotation
  IUpdaterManager public updaterManager;

  // ============ Upgrade Gap ============

  // gap for upgrade safety
  uint256[48] private __GAP;

  // ============ Events ============

  /**
   * @notice Emitted when a new message is dispatched via Nomad
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
   * @notice Emitted when proof of an improper update is submitted,
   * which sets the contract to FAILED state
   * @param oldRoot Old root of the improper update
   * @param newRoot New root of the improper update
   * @param signature Signature on `oldRoot` and `newRoot
   */
  event ImproperUpdate(bytes32 oldRoot, bytes32 newRoot, bytes signature);

  /**
   * @notice Emitted when the Updater is slashed
   * (should be paired with ImproperUpdater or DoubleUpdate event)
   * @param updater The address of the updater
   * @param reporter The address of the entity that reported the updater misbehavior
   */
  event UpdaterSlashed(address indexed updater, address indexed reporter);

  /**
   * @notice Emitted when the UpdaterManager contract is changed
   * @param updaterManager The address of the new updaterManager
   */
  event NewUpdaterManager(address updaterManager);

  // ============ Constructor ============

  constructor(uint32 _localDomain) NomadBase(_localDomain) {} // solhint-disable-line no-empty-blocks

  // ============ Initializer ============

  function initialize(IUpdaterManager _updaterManager) public initializer {
    // initialize queue, set Updater Manager, and initialize
    __QueueManager_initialize();
    _setUpdaterManager(_updaterManager);
    __NomadBase_initialize(updaterManager.updater());
  }

  // ============ Modifiers ============

  /**
   * @notice Ensures that function is called by the UpdaterManager contract
   */
  modifier onlyUpdaterManager() {
    require(msg.sender == address(updaterManager), "!updaterManager");
    _;
  }

  // ============ External: Updater & UpdaterManager Configuration  ============

  /**
   * @notice Set a new Updater
   * @param _updater the new Updater
   */
  function setUpdater(address _updater) external onlyUpdaterManager {
    _setUpdater(_updater);
  }

  /**
   * @notice Set a new UpdaterManager contract
   * @dev Home(s) will initially be initialized using a trusted UpdaterManager contract;
   * we will progressively decentralize by swapping the trusted contract with a new implementation
   * that implements Updater bonding & slashing, and rules for Updater selection & rotation
   * @param _updaterManager the new UpdaterManager contract
   */
  function setUpdaterManager(address _updaterManager) external onlyOwner {
    _setUpdaterManager(IUpdaterManager(_updaterManager));
  }

  // ============ External Functions  ============

  /**
   * @notice Dispatch the message it to the destination domain & recipient
   * @dev Format the message, insert its hash into Merkle tree,
   * enqueue the new Merkle root, and emit `Dispatch` event with message information.
   * @param _destinationDomain Domain of destination chain
   * @param _recipientAddress Address of recipient on destination chain as bytes32
   * @param _messageBody Raw bytes content of message
   */
  function dispatch(
    uint32 _destinationDomain,
    bytes32 _recipientAddress,
    bytes memory _messageBody
  ) external notFailed {
    require(_messageBody.length <= MAX_MESSAGE_BODY_BYTES, "msg too long");
    // get the next nonce for the destination domain, then increment it
    uint32 _nonce = nonces[_destinationDomain];
    nonces[_destinationDomain] = _nonce + 1;
    // format the message into packed bytes
    bytes memory _message = Message.formatMessage(
      localDomain,
      bytes32(uint256(uint160(msg.sender))),
      _nonce,
      _destinationDomain,
      _recipientAddress,
      _messageBody
    );
    // insert the hashed message into the Merkle tree
    bytes32 _messageHash = keccak256(_message);
    tree.insert(_messageHash);
    // enqueue the new Merkle root after inserting the message
    queue.enqueue(root());
    // Emit Dispatch event with message information
    // note: leafIndex is count() - 1 since new leaf has already been inserted
    emit Dispatch(_messageHash, count() - 1, _destinationAndNonce(_destinationDomain, _nonce), committedRoot, _message);
  }

  /**
   * @notice Submit a signature from the Updater "notarizing" a root,
   * which updates the Home contract's `committedRoot`,
   * and publishes the signature which will be relayed to Replica contracts
   * @dev emits Update event
   * @dev If _newRoot is not contained in the queue,
   * the Update is a fraudulent Improper Update, so
   * the Updater is slashed & Home is set to FAILED state
   * @param _committedRoot Current updated merkle root which the update is building off of
   * @param _newRoot New merkle root to update the contract state to
   * @param _signature Updater signature on `_committedRoot` and `_newRoot`
   */
  function update(
    bytes32 _committedRoot,
    bytes32 _newRoot,
    bytes memory _signature
  ) external notFailed {
    // check that the update is not fraudulent;
    // if fraud is detected, Updater is slashed & Home is set to FAILED state
    if (improperUpdate(_committedRoot, _newRoot, _signature)) return;
    // clear all of the intermediate roots contained in this update from the queue
    while (true) {
      bytes32 _next = queue.dequeue();
      if (_next == _newRoot) break;
    }
    // update the Home state with the latest signed root & emit event
    committedRoot = _newRoot;
    emit Update(localDomain, _committedRoot, _newRoot, _signature);
  }

  /**
   * @notice Suggest an update for the Updater to sign and submit.
   * @dev If queue is empty, null bytes returned for both
   * (No update is necessary because no messages have been dispatched since the last update)
   * @return _committedRoot Latest root signed by the Updater
   * @return _new Latest enqueued Merkle root
   */
  function suggestUpdate() external view returns (bytes32 _committedRoot, bytes32 _new) {
    if (queue.length() != 0) {
      _committedRoot = committedRoot;
      _new = queue.lastItem();
    }
  }

  // ============ Public Functions  ============

  /**
   * @notice Hash of Home domain concatenated with "NOMAD"
   */
  function homeDomainHash() public view override returns (bytes32) {
    return _homeDomainHash(localDomain);
  }

  /**
   * @notice Check if an Update is an Improper Update;
   * if so, slash the Updater and set the contract to FAILED state.
   *
   * An Improper Update is an update building off of the Home's `committedRoot`
   * for which the `_newRoot` does not currently exist in the Home's queue.
   * This would mean that message(s) that were not truly
   * dispatched on Home were falsely included in the signed root.
   *
   * An Improper Update will only be accepted as valid by the Replica
   * If an Improper Update is attempted on Home,
   * the Updater will be slashed immediately.
   * If an Improper Update is submitted to the Replica,
   * it should be relayed to the Home contract using this function
   * in order to slash the Updater with an Improper Update.
   *
   * An Improper Update submitted to the Replica is only valid
   * while the `_oldRoot` is still equal to the `committedRoot` on Home;
   * if the `committedRoot` on Home has already been updated with a valid Update,
   * then the Updater should be slashed with a Double Update.
   * @dev Reverts (and doesn't slash updater) if signature is invalid or
   * update not current
   * @param _oldRoot Old merkle tree root (should equal home's committedRoot)
   * @param _newRoot New merkle tree root
   * @param _signature Updater signature on `_oldRoot` and `_newRoot`
   * @return TRUE if update was an Improper Update (implying Updater was slashed)
   */
  function improperUpdate(
    bytes32 _oldRoot,
    bytes32 _newRoot,
    bytes memory _signature
  ) public notFailed returns (bool) {
    require(_isUpdaterSignature(_oldRoot, _newRoot, _signature), "!updater sig");
    require(_oldRoot == committedRoot, "not a current update");
    // if the _newRoot is not currently contained in the queue,
    // slash the Updater and set the contract to FAILED state
    if (!queue.contains(_newRoot)) {
      _fail();
      emit ImproperUpdate(_oldRoot, _newRoot, _signature);
      return true;
    }
    // if the _newRoot is contained in the queue,
    // this is not an improper update
    return false;
  }

  // ============ Internal Functions  ============

  /**
   * @notice Set the UpdaterManager
   * @param _updaterManager Address of the UpdaterManager
   */
  function _setUpdaterManager(IUpdaterManager _updaterManager) internal {
    require(Address.isContract(address(_updaterManager)), "!contract updaterManager");
    updaterManager = IUpdaterManager(_updaterManager);
    emit NewUpdaterManager(address(_updaterManager));
  }

  /**
   * @notice Slash the Updater and set contract state to FAILED
   * @dev Called when fraud is proven (Improper Update or Double Update)
   */
  function _fail() internal override {
    // set contract to FAILED
    _setFailed();
    // slash Updater
    updaterManager.slashUpdater(payable(msg.sender));
    emit UpdaterSlashed(updater, msg.sender);
  }

  /**
   * @notice Internal utility function that combines
   * `_destination` and `_nonce`.
   * @dev Both destination and nonce should be less than 2^32 - 1
   * @param _destination Domain of destination chain
   * @param _nonce Current nonce for given destination chain
   * @return Returns (`_destination` << 32) & `_nonce`
   */
  function _destinationAndNonce(uint32 _destination, uint32 _nonce) internal pure returns (uint64) {
    return (uint64(_destination) << 32) | _nonce;
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.6.11;

// ============ Internal Imports ============
import {MerkleLib} from "../libs/Merkle.sol";

/**
 * @title MerkleTreeManager
 * @author Illusory Systems Inc.
 * @notice Contains a Merkle tree instance and
 * exposes view functions for the tree.
 */
contract MerkleTreeManager {
  // ============ Libraries ============

  using MerkleLib for MerkleLib.Tree;
  MerkleLib.Tree public tree;

  // ============ Upgrade Gap ============

  // gap for upgrade safety
  uint256[49] private __GAP;

  // ============ Public Functions ============

  /**
   * @notice Calculates and returns tree's current root
   */
  function root() public view returns (bytes32) {
    return tree.root();
  }

  /**
   * @notice Returns the number of inserted leaves in the tree (current index)
   */
  function count() public view returns (uint256) {
    return tree.count;
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.6.11;

// ============ Internal Imports ============
import {Message} from "../libs/Message.sol";
// ============ External Imports ============
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/**
 * @title NomadBase
 * @author Illusory Systems Inc.
 * @notice Shared utilities between Home and Replica.
 */
abstract contract NomadBase is Initializable, OwnableUpgradeable {
  // ============ Enums ============

  // States:
  //   0 - UnInitialized - before initialize function is called
  //   note: the contract is initialized at deploy time, so it should never be in this state
  //   1 - Active - as long as the contract has not become fraudulent
  //   2 - Failed - after a valid fraud proof has been submitted;
  //   contract will no longer accept updates or new messages
  enum States {
    UnInitialized,
    Active,
    Failed
  }

  // ============ Immutable Variables ============

  // Domain of chain on which the contract is deployed
  uint32 public immutable localDomain;

  // ============ Public Variables ============

  // Address of bonded Updater
  address public updater;
  // Current state of contract
  States public state;
  // The latest root that has been signed by the Updater
  bytes32 public committedRoot;

  // ============ Upgrade Gap ============

  // gap for upgrade safety
  uint256[47] private __GAP;

  // ============ Events ============

  /**
   * @notice Emitted when update is made on Home
   * or unconfirmed update root is submitted on Replica
   * @param homeDomain Domain of home contract
   * @param oldRoot Old merkle root
   * @param newRoot New merkle root
   * @param signature Updater's signature on `oldRoot` and `newRoot`
   */
  event Update(uint32 indexed homeDomain, bytes32 indexed oldRoot, bytes32 indexed newRoot, bytes signature);

  /**
   * @notice Emitted when proof of a double update is submitted,
   * which sets the contract to FAILED state
   * @param oldRoot Old root shared between two conflicting updates
   * @param newRoot Array containing two conflicting new roots
   * @param signature Signature on `oldRoot` and `newRoot`[0]
   * @param signature2 Signature on `oldRoot` and `newRoot`[1]
   */
  event DoubleUpdate(bytes32 oldRoot, bytes32[2] newRoot, bytes signature, bytes signature2);

  /**
   * @notice Emitted when Updater is rotated
   * @param oldUpdater The address of the old updater
   * @param newUpdater The address of the new updater
   */
  event NewUpdater(address oldUpdater, address newUpdater);

  // ============ Modifiers ============

  /**
   * @notice Ensures that contract state != FAILED when the function is called
   */
  modifier notFailed() {
    require(state != States.Failed, "failed state");
    _;
  }

  // ============ Constructor ============

  constructor(uint32 _localDomain) {
    localDomain = _localDomain;
  }

  // ============ Initializer ============

  function __NomadBase_initialize(address _updater) internal initializer {
    __Ownable_init();
    _setUpdater(_updater);
    state = States.Active;
  }

  // ============ External Functions ============

  /**
   * @notice Called by external agent. Checks that signatures on two sets of
   * roots are valid and that the new roots conflict with each other. If both
   * cases hold true, the contract is failed and a `DoubleUpdate` event is
   * emitted.
   * @dev When `fail()` is called on Home, updater is slashed.
   * @param _oldRoot Old root shared between two conflicting updates
   * @param _newRoot Array containing two conflicting new roots
   * @param _signature Signature on `_oldRoot` and `_newRoot`[0]
   * @param _signature2 Signature on `_oldRoot` and `_newRoot`[1]
   */
  function doubleUpdate(
    bytes32 _oldRoot,
    bytes32[2] calldata _newRoot,
    bytes calldata _signature,
    bytes calldata _signature2
  ) external notFailed {
    if (
      NomadBase._isUpdaterSignature(_oldRoot, _newRoot[0], _signature) &&
      NomadBase._isUpdaterSignature(_oldRoot, _newRoot[1], _signature2) &&
      _newRoot[0] != _newRoot[1]
    ) {
      _fail();
      emit DoubleUpdate(_oldRoot, _newRoot, _signature, _signature2);
    }
  }

  // ============ Public Functions ============

  /**
   * @notice Hash of Home domain concatenated with "NOMAD"
   */
  function homeDomainHash() public view virtual returns (bytes32);

  // ============ Internal Functions ============

  /**
   * @notice Hash of Home domain concatenated with "NOMAD"
   * @param _homeDomain the Home domain to hash
   */
  function _homeDomainHash(uint32 _homeDomain) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(_homeDomain, "NOMAD"));
  }

  /**
   * @notice Set contract state to FAILED
   * @dev Called when a valid fraud proof is submitted
   */
  function _setFailed() internal {
    state = States.Failed;
  }

  /**
   * @notice Moves the contract into failed state
   * @dev Called when fraud is proven
   * (Double Update is submitted on Home or Replica,
   * or Improper Update is submitted on Home)
   */
  function _fail() internal virtual;

  /**
   * @notice Set the Updater
   * @param _newUpdater Address of the new Updater
   */
  function _setUpdater(address _newUpdater) internal {
    address _oldUpdater = updater;
    updater = _newUpdater;
    emit NewUpdater(_oldUpdater, _newUpdater);
  }

  /**
   * @notice Checks that signature was signed by Updater
   * @param _oldRoot Old merkle root
   * @param _newRoot New merkle root
   * @param _signature Signature on `_oldRoot` and `_newRoot`
   * @return TRUE iff signature is valid signed by updater
   **/
  function _isUpdaterSignature(
    bytes32 _oldRoot,
    bytes32 _newRoot,
    bytes memory _signature
  ) internal view returns (bool) {
    bytes32 _digest = keccak256(abi.encodePacked(homeDomainHash(), _oldRoot, _newRoot));
    _digest = ECDSA.toEthSignedMessageHash(_digest);
    return (ECDSA.recover(_digest, _signature) == updater);
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.6.11;

// ============ Internal Imports ============
import {QueueLib} from "../libs/Queue.sol";
// ============ External Imports ============
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @title QueueManager
 * @author Illusory Systems Inc.
 * @notice Contains a queue instance and
 * exposes view functions for the queue.
 **/
contract QueueManager is Initializable {
  // ============ Libraries ============

  using QueueLib for QueueLib.Queue;
  QueueLib.Queue internal queue;

  // ============ Upgrade Gap ============

  // gap for upgrade safety
  uint256[49] private __GAP;

  // ============ Initializer ============

  function __QueueManager_initialize() internal initializer {
    queue.initialize();
  }

  // ============ Public Functions ============

  /**
   * @notice Returns number of elements in queue
   */
  function queueLength() external view returns (uint256) {
    return queue.length();
  }

  /**
   * @notice Returns TRUE iff `_item` is in the queue
   */
  function queueContains(bytes32 _item) external view returns (bool) {
    return queue.contains(_item);
  }

  /**
   * @notice Returns last item enqueued to the queue
   */
  function queueEnd() external view returns (bytes32) {
    return queue.lastItem();
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.6.11;

// ============ Internal Imports ============
import {Version0} from "./Version0.sol";
import {NomadBase} from "./NomadBase.sol";
import {MerkleLib} from "../libs/Merkle.sol";
import {Message} from "../libs/Message.sol";
// ============ External Imports ============
// import {TypedMemView} from "@summa-tx/memview-sol/contracts/TypedMemView.sol";
import {TypedMemView} from "../libs/TypedMemView.sol";

/**
 * @title Replica
 * @author Illusory Systems Inc.
 * @notice Track root updates on Home,
 * prove and dispatch messages to end recipients.
 */
contract Replica is Version0, NomadBase {
  // ============ Libraries ============

  using MerkleLib for MerkleLib.Tree;
  using TypedMemView for bytes;
  using TypedMemView for bytes29;
  using Message for bytes29;

  // ============ Enums ============

  // Status of Message:
  //   0 - None - message has not been proven or processed
  //   1 - Proven - message inclusion proof has been validated
  //   2 - Processed - message has been dispatched to recipient
  enum MessageStatus {
    None,
    Proven,
    Processed
  }

  // ============ Immutables ============

  // Minimum gas for message processing
  uint256 public immutable PROCESS_GAS;
  // Reserved gas (to ensure tx completes in case message processing runs out)
  uint256 public immutable RESERVE_GAS;

  // ============ Public Storage ============

  // Domain of home chain
  uint32 public remoteDomain;
  // Number of seconds to wait before root becomes confirmable
  uint256 public optimisticSeconds;
  // re-entrancy guard
  uint8 private entered;
  // Mapping of roots to allowable confirmation times
  mapping(bytes32 => uint256) public confirmAt;
  // Mapping of message leaves to MessageStatus
  mapping(bytes32 => MessageStatus) public messages;

  // ============ Upgrade Gap ============

  // gap for upgrade safety
  uint256[45] private __GAP;

  // ============ Events ============

  /**
   * @notice Emitted when message is processed
   * @param messageHash Hash of message that failed to process
   * @param success TRUE if the call was executed successfully, FALSE if the call reverted
   * @param returnData the return data from the external call
   */
  event Process(bytes32 indexed messageHash, bool indexed success, bytes indexed returnData);

  /**
   * @notice Emitted when the value for optimisticTimeout is set
   * @param timeout The new value for optimistic timeout
   */
  event SetOptimisticTimeout(uint256 timeout);

  /**
   * @notice Emitted when a root's confirmation is modified by governance
   * @param root The root for which confirmAt has been set
   * @param previousConfirmAt The previous value of confirmAt
   * @param newConfirmAt The new value of confirmAt
   */
  event SetConfirmation(bytes32 indexed root, uint256 previousConfirmAt, uint256 newConfirmAt);

  // ============ Constructor ============

  // solhint-disable-next-line no-empty-blocks
  constructor(
    uint32 _localDomain,
    uint256 _processGas,
    uint256 _reserveGas
  ) NomadBase(_localDomain) {
    require(_processGas >= 850_000, "!process gas");
    require(_reserveGas >= 15_000, "!reserve gas");
    PROCESS_GAS = _processGas;
    RESERVE_GAS = _reserveGas;
  }

  // ============ Initializer ============

  function initialize(
    uint32 _remoteDomain,
    address _updater,
    bytes32 _committedRoot,
    uint256 _optimisticSeconds
  ) public initializer {
    __NomadBase_initialize(_updater);
    // set storage variables
    entered = 1;
    remoteDomain = _remoteDomain;
    committedRoot = _committedRoot;
    confirmAt[_committedRoot] = 1;
    optimisticSeconds = _optimisticSeconds;
    emit SetOptimisticTimeout(_optimisticSeconds);
  }

  // ============ External Functions ============

  /**
   * @notice Called by external agent. Submits the signed update's new root,
   * marks root's allowable confirmation time, and emits an `Update` event.
   * @dev Reverts if update doesn't build off latest committedRoot
   * or if signature is invalid.
   * @param _oldRoot Old merkle root
   * @param _newRoot New merkle root
   * @param _signature Updater's signature on `_oldRoot` and `_newRoot`
   */
  function update(
    bytes32 _oldRoot,
    bytes32 _newRoot,
    bytes memory _signature
  ) external notFailed {
    // ensure that update is building off the last submitted root
    require(_oldRoot == committedRoot, "not current update");
    // validate updater signature
    require(_isUpdaterSignature(_oldRoot, _newRoot, _signature), "!updater sig");
    // Hook for future use
    _beforeUpdate();
    // set the new root's confirmation timer
    confirmAt[_newRoot] = block.timestamp + optimisticSeconds;
    // update committedRoot
    committedRoot = _newRoot;
    emit Update(remoteDomain, _oldRoot, _newRoot, _signature);
  }

  /**
   * @notice First attempts to prove the validity of provided formatted
   * `message`. If the message is successfully proven, then tries to process
   * message.
   * @dev Reverts if `prove` call returns false
   * @param _message Formatted message (refer to NomadBase.sol Message library)
   * @param _proof Merkle proof of inclusion for message's leaf
   * @param _index Index of leaf in home's merkle tree
   */
  function proveAndProcess(
    bytes memory _message,
    bytes32[32] calldata _proof,
    uint256 _index
  ) external {
    require(prove(keccak256(_message), _proof, _index), "!prove");
    process(_message);
  }

  /**
   * @notice Given formatted message, attempts to dispatch
   * message payload to end recipient.
   * @dev Recipient must implement a `handle` method (refer to IMessageRecipient.sol)
   * Reverts if formatted message's destination domain is not the Replica's domain,
   * if message has not been proven,
   * or if not enough gas is provided for the dispatch transaction.
   * @param _message Formatted message
   * @return _success TRUE iff dispatch transaction succeeded
   */
  function process(bytes memory _message) public returns (bool _success) {
    bytes29 _m = _message.ref(0);
    // ensure message was meant for this domain
    require(_m.destination() == localDomain, "!destination");
    // ensure message has been proven
    bytes32 _messageHash = _m.keccak();
    require(messages[_messageHash] == MessageStatus.Proven, "!proven");
    // check re-entrancy guard
    require(entered == 1, "!reentrant");
    entered = 0;
    // update message status as processed
    messages[_messageHash] = MessageStatus.Processed;
    // A call running out of gas TYPICALLY errors the whole tx. We want to
    // a) ensure the call has a sufficient amount of gas to make a
    //    meaningful state change.
    // b) ensure that if the subcall runs out of gas, that the tx as a whole
    //    does not revert (i.e. we still mark the message processed)
    // To do this, we require that we have enough gas to process
    // and still return. We then delegate only the minimum processing gas.
    require(gasleft() >= PROCESS_GAS + RESERVE_GAS, "!gas");
    // get the message recipient
    address _recipient = _m.recipientAddress();
    // set up for assembly call
    uint256 _toCopy;
    uint256 _maxCopy = 256;
    uint256 _gas = PROCESS_GAS;
    // allocate memory for returndata
    bytes memory _returnData = new bytes(_maxCopy);
    bytes memory _calldata = abi.encodeWithSignature(
      "handle(uint32,uint32,bytes32,bytes)",
      _m.origin(),
      _m.nonce(),
      _m.sender(),
      _m.body().clone()
    );
    // dispatch message to recipient
    // by assembly calling "handle" function
    // we call via assembly to avoid memcopying a very large returndata
    // returned by a malicious contract
    assembly {
      _success := call(
        _gas, // gas
        _recipient, // recipient
        0, // ether value
        add(_calldata, 0x20), // inloc
        mload(_calldata), // inlen
        0, // outloc
        0 // outlen
      )
      // limit our copy to 256 bytes
      _toCopy := returndatasize()
      if gt(_toCopy, _maxCopy) {
        _toCopy := _maxCopy
      }
      // Store the length of the copied bytes
      mstore(_returnData, _toCopy)
      // copy the bytes from returndata[0:_toCopy]
      returndatacopy(add(_returnData, 0x20), 0, _toCopy)
    }
    // emit process results
    emit Process(_messageHash, _success, _returnData);
    // reset re-entrancy guard
    entered = 1;
  }

  // ============ External Owner Functions ============

  /**
   * @notice Set optimistic timeout period for new roots
   * @dev Only callable by owner (Governance)
   * @param _optimisticSeconds New optimistic timeout period
   */
  function setOptimisticTimeout(uint256 _optimisticSeconds) external onlyOwner {
    optimisticSeconds = _optimisticSeconds;
    emit SetOptimisticTimeout(_optimisticSeconds);
  }

  /**
   * @notice Set Updater role
   * @dev MUST ensure that all roots signed by previous Updater have
   * been relayed before calling. Only callable by owner (Governance)
   * @param _updater New Updater
   */
  function setUpdater(address _updater) external onlyOwner {
    _setUpdater(_updater);
  }

  /**
   * @notice Set confirmAt for a given root
   * @dev To be used if in the case that fraud is proven
   * and roots need to be deleted / added. Only callable by owner (Governance)
   * @param _root The root for which to modify confirm time
   * @param _confirmAt The new confirmation time. Set to 0 to "delete" a root.
   */
  function setConfirmation(bytes32 _root, uint256 _confirmAt) external onlyOwner {
    uint256 _previousConfirmAt = confirmAt[_root];
    confirmAt[_root] = _confirmAt;
    emit SetConfirmation(_root, _previousConfirmAt, _confirmAt);
  }

  // ============ Public Functions ============

  /**
   * @notice Check that the root has been submitted
   * and that the optimistic timeout period has expired,
   * meaning the root can be processed
   * @param _root the Merkle root, submitted in an update, to check
   * @return TRUE iff root has been submitted & timeout has expired
   */
  function acceptableRoot(bytes32 _root) public view returns (bool) {
    uint256 _time = confirmAt[_root];
    if (_time == 0) {
      return false;
    }
    return block.timestamp >= _time;
  }

  /**
   * @notice Attempts to prove the validity of message given its leaf, the
   * merkle proof of inclusion for the leaf, and the index of the leaf.
   * @dev Reverts if message's MessageStatus != None (i.e. if message was
   * already proven or processed)
   * @dev For convenience, we allow proving against any previous root.
   * This means that witnesses never need to be updated for the new root
   * @param _leaf Leaf of message to prove
   * @param _proof Merkle proof of inclusion for leaf
   * @param _index Index of leaf in home's merkle tree
   * @return Returns true if proof was valid and `prove` call succeeded
   **/
  function prove(
    bytes32 _leaf,
    bytes32[32] calldata _proof,
    uint256 _index
  ) public returns (bool) {
    // ensure that message has not been proven or processed
    require(messages[_leaf] == MessageStatus.None, "!MessageStatus.None");
    // calculate the expected root based on the proof
    bytes32 _calculatedRoot = MerkleLib.branchRoot(_leaf, _proof, _index);
    // if the root is valid, change status to Proven
    if (acceptableRoot(_calculatedRoot)) {
      messages[_leaf] = MessageStatus.Proven;
      return true;
    }
    return false;
  }

  /**
   * @notice Hash of Home domain concatenated with "NOMAD"
   */
  function homeDomainHash() public view override returns (bytes32) {
    return _homeDomainHash(remoteDomain);
  }

  // ============ Internal Functions ============

  /**
   * @notice Moves the contract into failed state
   * @dev Called when a Double Update is submitted
   */
  function _fail() internal override {
    _setFailed();
  }

  /// @notice Hook for potential future use
  // solhint-disable-next-line no-empty-blocks
  function _beforeUpdate() internal {}
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.6.11;

/**
 * @title Version0
 * @notice Version getter for contracts
 **/
contract Version0 {
  uint8 public constant VERSION = 0;
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.6.11;

// ============ Internal Imports ============
import {Home} from "./Home.sol";
import {Replica} from "./Replica.sol";
import {TypeCasts} from "../libs/TypeCasts.sol";
// ============ External Imports ============
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title XAppConnectionManager
 * @author Illusory Systems Inc.
 * @notice Manages a registry of local Replica contracts
 * for remote Home domains. Accepts Watcher signatures
 * to un-enroll Replicas attached to fraudulent remote Homes
 */
contract XAppConnectionManager is Ownable {
  // ============ Public Storage ============

  // Home contract
  Home public home;
  // local Replica address => remote Home domain
  mapping(address => uint32) public replicaToDomain;
  // remote Home domain => local Replica address
  mapping(uint32 => address) public domainToReplica;
  // watcher address => replica remote domain => has/doesn't have permission
  mapping(address => mapping(uint32 => bool)) private watcherPermissions;

  // ============ Events ============

  /**
   * @notice Emitted when a new Replica is enrolled / added
   * @param domain the remote domain of the Home contract for the Replica
   * @param replica the address of the Replica
   */
  event ReplicaEnrolled(uint32 indexed domain, address replica);

  /**
   * @notice Emitted when a new Replica is un-enrolled / removed
   * @param domain the remote domain of the Home contract for the Replica
   * @param replica the address of the Replica
   */
  event ReplicaUnenrolled(uint32 indexed domain, address replica);

  /**
   * @notice Emitted when Watcher permissions are changed
   * @param domain the remote domain of the Home contract for the Replica
   * @param watcher the address of the Watcher
   * @param access TRUE if the Watcher was given permissions, FALSE if permissions were removed
   */
  event WatcherPermissionSet(uint32 indexed domain, address watcher, bool access);

  // ============ Modifiers ============

  modifier onlyReplica() {
    require(isReplica(msg.sender), "!replica");
    _;
  }

  // ============ Constructor ============

  // solhint-disable-next-line no-empty-blocks
  constructor() Ownable() {}

  // ============ External Functions ============

  /**
   * @notice Un-Enroll a replica contract
   * in the case that fraud was detected on the Home
   * @dev in the future, if fraud occurs on the Home contract,
   * the Watcher will submit their signature directly to the Home
   * and it can be relayed to all remote chains to un-enroll the Replicas
   * @param _domain the remote domain of the Home contract for the Replica
   * @param _updater the address of the Updater for the Home contract (also stored on Replica)
   * @param _signature signature of watcher on (domain, replica address, updater address)
   */
  function unenrollReplica(
    uint32 _domain,
    bytes32 _updater,
    bytes memory _signature
  ) external {
    // ensure that the replica is currently set
    address _replica = domainToReplica[_domain];
    require(_replica != address(0), "!replica exists");
    // ensure that the signature is on the proper updater
    require(Replica(_replica).updater() == TypeCasts.bytes32ToAddress(_updater), "!current updater");
    // get the watcher address from the signature
    // and ensure that the watcher has permission to un-enroll this replica
    address _watcher = _recoverWatcherFromSig(_domain, TypeCasts.addressToBytes32(_replica), _updater, _signature);
    require(watcherPermissions[_watcher][_domain], "!valid watcher");
    // remove the replica from mappings
    _unenrollReplica(_replica);
  }

  /**
   * @notice Set the address of the local Home contract
   * @param _home the address of the local Home contract
   */
  function setHome(address _home) external onlyOwner {
    home = Home(_home);
  }

  /**
   * @notice Allow Owner to enroll Replica contract
   * @param _replica the address of the Replica
   * @param _domain the remote domain of the Home contract for the Replica
   */
  function ownerEnrollReplica(address _replica, uint32 _domain) external onlyOwner {
    // un-enroll any existing replica
    _unenrollReplica(_replica);
    // add replica and domain to two-way mapping
    replicaToDomain[_replica] = _domain;
    domainToReplica[_domain] = _replica;
    emit ReplicaEnrolled(_domain, _replica);
  }

  /**
   * @notice Allow Owner to un-enroll Replica contract
   * @param _replica the address of the Replica
   */
  function ownerUnenrollReplica(address _replica) external onlyOwner {
    _unenrollReplica(_replica);
  }

  /**
   * @notice Allow Owner to set Watcher permissions for a Replica
   * @param _watcher the address of the Watcher
   * @param _domain the remote domain of the Home contract for the Replica
   * @param _access TRUE to give the Watcher permissions, FALSE to remove permissions
   */
  function setWatcherPermission(
    address _watcher,
    uint32 _domain,
    bool _access
  ) external onlyOwner {
    watcherPermissions[_watcher][_domain] = _access;
    emit WatcherPermissionSet(_domain, _watcher, _access);
  }

  /**
   * @notice Query local domain from Home
   * @return local domain
   */
  function localDomain() external view returns (uint32) {
    return home.localDomain();
  }

  /**
   * @notice Get access permissions for the watcher on the domain
   * @param _watcher the address of the watcher
   * @param _domain the domain to check for watcher permissions
   * @return TRUE iff _watcher has permission to un-enroll replicas on _domain
   */
  function watcherPermission(address _watcher, uint32 _domain) external view returns (bool) {
    return watcherPermissions[_watcher][_domain];
  }

  // ============ Public Functions ============

  /**
   * @notice Check whether _replica is enrolled
   * @param _replica the replica to check for enrollment
   * @return TRUE iff _replica is enrolled
   */
  function isReplica(address _replica) public view returns (bool) {
    return replicaToDomain[_replica] != 0;
  }

  // ============ Internal Functions ============

  /**
   * @notice Remove the replica from the two-way mappings
   * @param _replica replica to un-enroll
   */
  function _unenrollReplica(address _replica) internal {
    uint32 _currentDomain = replicaToDomain[_replica];
    domainToReplica[_currentDomain] = address(0);
    replicaToDomain[_replica] = 0;
    emit ReplicaUnenrolled(_currentDomain, _replica);
  }

  /**
   * @notice Get the Watcher address from the provided signature
   * @return address of watcher that signed
   */
  function _recoverWatcherFromSig(
    uint32 _domain,
    bytes32 _replica,
    bytes32 _updater,
    bytes memory _signature
  ) internal view returns (address) {
    bytes32 _homeDomainHash = Replica(TypeCasts.bytes32ToAddress(_replica)).homeDomainHash();
    bytes32 _digest = keccak256(abi.encodePacked(_homeDomainHash, _domain, _updater));
    _digest = ECDSA.toEthSignedMessageHash(_digest);
    return ECDSA.recover(_digest, _signature);
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.6.11;

interface IMessageRecipient {
  function handle(
    uint32 _origin,
    uint32 _nonce,
    bytes32 _sender,
    bytes memory _message
  ) external;
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.6.11;

interface IUpdaterManager {
  function slashUpdater(address payable _reporter) external;

  function updater() external view returns (address);
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.6.11;

// work based on eth2 deposit contract, which is used under CC0-1.0

/**
 * @title MerkleLib
 * @author Illusory Systems Inc.
 * @notice An incremental merkle tree modeled on the eth2 deposit contract.
 **/
library MerkleLib {
  uint256 internal constant TREE_DEPTH = 32;
  uint256 internal constant MAX_LEAVES = 2**TREE_DEPTH - 1;

  /**
   * @notice Struct representing incremental merkle tree. Contains current
   * branch and the number of inserted leaves in the tree.
   **/
  struct Tree {
    bytes32[TREE_DEPTH] branch;
    uint256 count;
  }

  /**
   * @notice Inserts `_node` into merkle tree
   * @dev Reverts if tree is full
   * @param _node Element to insert into tree
   **/
  function insert(Tree storage _tree, bytes32 _node) internal {
    require(_tree.count < MAX_LEAVES, "merkle tree full");

    _tree.count += 1;
    uint256 size = _tree.count;
    for (uint256 i = 0; i < TREE_DEPTH; i++) {
      if ((size & 1) == 1) {
        _tree.branch[i] = _node;
        return;
      }
      _node = keccak256(abi.encodePacked(_tree.branch[i], _node));
      size /= 2;
    }
    // As the loop should always end prematurely with the `return` statement,
    // this code should be unreachable. We assert `false` just to be safe.
    assert(false);
  }

  /**
   * @notice Calculates and returns`_tree`'s current root given array of zero
   * hashes
   * @param _zeroes Array of zero hashes
   * @return _current Calculated root of `_tree`
   **/
  function rootWithCtx(Tree storage _tree, bytes32[TREE_DEPTH] memory _zeroes)
    internal
    view
    returns (bytes32 _current)
  {
    uint256 _index = _tree.count;

    for (uint256 i = 0; i < TREE_DEPTH; i++) {
      uint256 _ithBit = (_index >> i) & 0x01;
      bytes32 _next = _tree.branch[i];
      if (_ithBit == 1) {
        _current = keccak256(abi.encodePacked(_next, _current));
      } else {
        _current = keccak256(abi.encodePacked(_current, _zeroes[i]));
      }
    }
  }

  /// @notice Calculates and returns`_tree`'s current root
  function root(Tree storage _tree) internal view returns (bytes32) {
    return rootWithCtx(_tree, zeroHashes());
  }

  /// @notice Returns array of TREE_DEPTH zero hashes
  /// @return _zeroes Array of TREE_DEPTH zero hashes
  function zeroHashes() internal pure returns (bytes32[TREE_DEPTH] memory _zeroes) {
    _zeroes[0] = Z_0;
    _zeroes[1] = Z_1;
    _zeroes[2] = Z_2;
    _zeroes[3] = Z_3;
    _zeroes[4] = Z_4;
    _zeroes[5] = Z_5;
    _zeroes[6] = Z_6;
    _zeroes[7] = Z_7;
    _zeroes[8] = Z_8;
    _zeroes[9] = Z_9;
    _zeroes[10] = Z_10;
    _zeroes[11] = Z_11;
    _zeroes[12] = Z_12;
    _zeroes[13] = Z_13;
    _zeroes[14] = Z_14;
    _zeroes[15] = Z_15;
    _zeroes[16] = Z_16;
    _zeroes[17] = Z_17;
    _zeroes[18] = Z_18;
    _zeroes[19] = Z_19;
    _zeroes[20] = Z_20;
    _zeroes[21] = Z_21;
    _zeroes[22] = Z_22;
    _zeroes[23] = Z_23;
    _zeroes[24] = Z_24;
    _zeroes[25] = Z_25;
    _zeroes[26] = Z_26;
    _zeroes[27] = Z_27;
    _zeroes[28] = Z_28;
    _zeroes[29] = Z_29;
    _zeroes[30] = Z_30;
    _zeroes[31] = Z_31;
  }

  /**
   * @notice Calculates and returns the merkle root for the given leaf
   * `_item`, a merkle branch, and the index of `_item` in the tree.
   * @param _item Merkle leaf
   * @param _branch Merkle proof
   * @param _index Index of `_item` in tree
   * @return _current Calculated merkle root
   **/
  function branchRoot(
    bytes32 _item,
    bytes32[TREE_DEPTH] memory _branch,
    uint256 _index
  ) internal pure returns (bytes32 _current) {
    _current = _item;

    for (uint256 i = 0; i < TREE_DEPTH; i++) {
      uint256 _ithBit = (_index >> i) & 0x01;
      bytes32 _next = _branch[i];
      if (_ithBit == 1) {
        _current = keccak256(abi.encodePacked(_next, _current));
      } else {
        _current = keccak256(abi.encodePacked(_current, _next));
      }
    }
  }

  // keccak256 zero hashes
  bytes32 internal constant Z_0 = hex"0000000000000000000000000000000000000000000000000000000000000000";
  bytes32 internal constant Z_1 = hex"ad3228b676f7d3cd4284a5443f17f1962b36e491b30a40b2405849e597ba5fb5";
  bytes32 internal constant Z_2 = hex"b4c11951957c6f8f642c4af61cd6b24640fec6dc7fc607ee8206a99e92410d30";
  bytes32 internal constant Z_3 = hex"21ddb9a356815c3fac1026b6dec5df3124afbadb485c9ba5a3e3398a04b7ba85";
  bytes32 internal constant Z_4 = hex"e58769b32a1beaf1ea27375a44095a0d1fb664ce2dd358e7fcbfb78c26a19344";
  bytes32 internal constant Z_5 = hex"0eb01ebfc9ed27500cd4dfc979272d1f0913cc9f66540d7e8005811109e1cf2d";
  bytes32 internal constant Z_6 = hex"887c22bd8750d34016ac3c66b5ff102dacdd73f6b014e710b51e8022af9a1968";
  bytes32 internal constant Z_7 = hex"ffd70157e48063fc33c97a050f7f640233bf646cc98d9524c6b92bcf3ab56f83";
  bytes32 internal constant Z_8 = hex"9867cc5f7f196b93bae1e27e6320742445d290f2263827498b54fec539f756af";
  bytes32 internal constant Z_9 = hex"cefad4e508c098b9a7e1d8feb19955fb02ba9675585078710969d3440f5054e0";
  bytes32 internal constant Z_10 = hex"f9dc3e7fe016e050eff260334f18a5d4fe391d82092319f5964f2e2eb7c1c3a5";
  bytes32 internal constant Z_11 = hex"f8b13a49e282f609c317a833fb8d976d11517c571d1221a265d25af778ecf892";
  bytes32 internal constant Z_12 = hex"3490c6ceeb450aecdc82e28293031d10c7d73bf85e57bf041a97360aa2c5d99c";
  bytes32 internal constant Z_13 = hex"c1df82d9c4b87413eae2ef048f94b4d3554cea73d92b0f7af96e0271c691e2bb";
  bytes32 internal constant Z_14 = hex"5c67add7c6caf302256adedf7ab114da0acfe870d449a3a489f781d659e8becc";
  bytes32 internal constant Z_15 = hex"da7bce9f4e8618b6bd2f4132ce798cdc7a60e7e1460a7299e3c6342a579626d2";
  bytes32 internal constant Z_16 = hex"2733e50f526ec2fa19a22b31e8ed50f23cd1fdf94c9154ed3a7609a2f1ff981f";
  bytes32 internal constant Z_17 = hex"e1d3b5c807b281e4683cc6d6315cf95b9ade8641defcb32372f1c126e398ef7a";
  bytes32 internal constant Z_18 = hex"5a2dce0a8a7f68bb74560f8f71837c2c2ebbcbf7fffb42ae1896f13f7c7479a0";
  bytes32 internal constant Z_19 = hex"b46a28b6f55540f89444f63de0378e3d121be09e06cc9ded1c20e65876d36aa0";
  bytes32 internal constant Z_20 = hex"c65e9645644786b620e2dd2ad648ddfcbf4a7e5b1a3a4ecfe7f64667a3f0b7e2";
  bytes32 internal constant Z_21 = hex"f4418588ed35a2458cffeb39b93d26f18d2ab13bdce6aee58e7b99359ec2dfd9";
  bytes32 internal constant Z_22 = hex"5a9c16dc00d6ef18b7933a6f8dc65ccb55667138776f7dea101070dc8796e377";
  bytes32 internal constant Z_23 = hex"4df84f40ae0c8229d0d6069e5c8f39a7c299677a09d367fc7b05e3bc380ee652";
  bytes32 internal constant Z_24 = hex"cdc72595f74c7b1043d0e1ffbab734648c838dfb0527d971b602bc216c9619ef";
  bytes32 internal constant Z_25 = hex"0abf5ac974a1ed57f4050aa510dd9c74f508277b39d7973bb2dfccc5eeb0618d";
  bytes32 internal constant Z_26 = hex"b8cd74046ff337f0a7bf2c8e03e10f642c1886798d71806ab1e888d9e5ee87d0";
  bytes32 internal constant Z_27 = hex"838c5655cb21c6cb83313b5a631175dff4963772cce9108188b34ac87c81c41e";
  bytes32 internal constant Z_28 = hex"662ee4dd2dd7b2bc707961b1e646c4047669dcb6584f0d8d770daf5d7e7deb2e";
  bytes32 internal constant Z_29 = hex"388ab20e2573d171a88108e79d820e98f26c0b84aa8b2f4aa4968dbb818ea322";
  bytes32 internal constant Z_30 = hex"93237c50ba75ee485f4c22adf2f741400bdf8d6a9cc7df7ecae576221665d735";
  bytes32 internal constant Z_31 = hex"8448818bb4ae4562849e949e17ac16e0be16688e156b5cf15e098c627c0056a9";
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.6.11;

// import "@summa-tx/memview-sol/contracts/TypedMemView.sol";

import "./TypedMemView.sol";

import {TypeCasts} from "./TypeCasts.sol";

/**
 * @title Message Library
 * @author Illusory Systems Inc.
 * @notice Library for formatted messages used by Home and Replica.
 **/
library Message {
  using TypedMemView for bytes;
  using TypedMemView for bytes29;

  // Number of bytes in formatted message before `body` field
  uint256 internal constant PREFIX_LENGTH = 76;

  /**
   * @notice Returns formatted (packed) message with provided fields
   * @param _originDomain Domain of home chain
   * @param _sender Address of sender as bytes32
   * @param _nonce Destination-specific nonce
   * @param _destinationDomain Domain of destination chain
   * @param _recipient Address of recipient on destination chain as bytes32
   * @param _messageBody Raw bytes of message body
   * @return Formatted message
   **/
  function formatMessage(
    uint32 _originDomain,
    bytes32 _sender,
    uint32 _nonce,
    uint32 _destinationDomain,
    bytes32 _recipient,
    bytes memory _messageBody
  ) internal pure returns (bytes memory) {
    return abi.encodePacked(_originDomain, _sender, _nonce, _destinationDomain, _recipient, _messageBody);
  }

  /**
   * @notice Returns leaf of formatted message with provided fields.
   * @param _origin Domain of home chain
   * @param _sender Address of sender as bytes32
   * @param _nonce Destination-specific nonce number
   * @param _destination Domain of destination chain
   * @param _recipient Address of recipient on destination chain as bytes32
   * @param _body Raw bytes of message body
   * @return Leaf (hash) of formatted message
   **/
  function messageHash(
    uint32 _origin,
    bytes32 _sender,
    uint32 _nonce,
    uint32 _destination,
    bytes32 _recipient,
    bytes memory _body
  ) internal pure returns (bytes32) {
    return keccak256(formatMessage(_origin, _sender, _nonce, _destination, _recipient, _body));
  }

  /// @notice Returns message's origin field
  function origin(bytes29 _message) internal pure returns (uint32) {
    return uint32(_message.indexUint(0, 4));
  }

  /// @notice Returns message's sender field
  function sender(bytes29 _message) internal pure returns (bytes32) {
    return _message.index(4, 32);
  }

  /// @notice Returns message's nonce field
  function nonce(bytes29 _message) internal pure returns (uint32) {
    return uint32(_message.indexUint(36, 4));
  }

  /// @notice Returns message's destination field
  function destination(bytes29 _message) internal pure returns (uint32) {
    return uint32(_message.indexUint(40, 4));
  }

  /// @notice Returns message's recipient field as bytes32
  function recipient(bytes29 _message) internal pure returns (bytes32) {
    return _message.index(44, 32);
  }

  /// @notice Returns message's recipient field as an address
  function recipientAddress(bytes29 _message) internal pure returns (address) {
    return TypeCasts.bytes32ToAddress(recipient(_message));
  }

  /// @notice Returns message's body field as bytes29 (refer to TypedMemView library for details on bytes29 type)
  function body(bytes29 _message) internal pure returns (bytes29) {
    return _message.slice(PREFIX_LENGTH, _message.len() - PREFIX_LENGTH, 0);
  }

  function leaf(bytes29 _message) internal view returns (bytes32) {
    return
      messageHash(
        origin(_message),
        sender(_message),
        nonce(_message),
        destination(_message),
        recipient(_message),
        TypedMemView.clone(body(_message))
      );
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.6.11;

/**
 * @title QueueLib
 * @author Illusory Systems Inc.
 * @notice Library containing queue struct and operations for queue used by
 * Home and Replica.
 **/
library QueueLib {
  /**
   * @notice Queue struct
   * @dev Internally keeps track of the `first` and `last` elements through
   * indices and a mapping of indices to enqueued elements.
   **/
  struct Queue {
    uint128 first;
    uint128 last;
    mapping(uint256 => bytes32) queue;
  }

  /**
   * @notice Initializes the queue
   * @dev Empty state denoted by _q.first > q._last. Queue initialized
   * with _q.first = 1 and _q.last = 0.
   **/
  function initialize(Queue storage _q) internal {
    if (_q.first == 0) {
      _q.first = 1;
    }
  }

  /**
   * @notice Enqueues a single new element
   * @param _item New element to be enqueued
   * @return _last Index of newly enqueued element
   **/
  function enqueue(Queue storage _q, bytes32 _item) internal returns (uint128 _last) {
    _last = _q.last + 1;
    _q.last = _last;
    if (_item != bytes32(0)) {
      // saves gas if we're queueing 0
      _q.queue[_last] = _item;
    }
  }

  /**
   * @notice Dequeues element at front of queue
   * @dev Removes dequeued element from storage
   * @return _item Dequeued element
   **/
  function dequeue(Queue storage _q) internal returns (bytes32 _item) {
    uint128 _last = _q.last;
    uint128 _first = _q.first;
    require(_length(_last, _first) != 0, "Empty");
    _item = _q.queue[_first];
    if (_item != bytes32(0)) {
      // saves gas if we're dequeuing 0
      delete _q.queue[_first];
    }
    _q.first = _first + 1;
  }

  /**
   * @notice Batch enqueues several elements
   * @param _items Array of elements to be enqueued
   * @return _last Index of last enqueued element
   **/
  function enqueue(Queue storage _q, bytes32[] memory _items) internal returns (uint128 _last) {
    _last = _q.last;
    for (uint256 i = 0; i < _items.length; i += 1) {
      _last += 1;
      bytes32 _item = _items[i];
      if (_item != bytes32(0)) {
        _q.queue[_last] = _item;
      }
    }
    _q.last = _last;
  }

  /**
   * @notice Batch dequeues `_number` elements
   * @dev Reverts if `_number` > queue length
   * @param _number Number of elements to dequeue
   * @return Array of dequeued elements
   **/
  function dequeue(Queue storage _q, uint256 _number) internal returns (bytes32[] memory) {
    uint128 _last = _q.last;
    uint128 _first = _q.first;
    // Cannot underflow unless state is corrupted
    require(_length(_last, _first) >= _number, "Insufficient");

    bytes32[] memory _items = new bytes32[](_number);

    for (uint256 i = 0; i < _number; i++) {
      _items[i] = _q.queue[_first];
      delete _q.queue[_first];
      _first++;
    }
    _q.first = _first;
    return _items;
  }

  /**
   * @notice Returns true if `_item` is in the queue and false if otherwise
   * @dev Linearly scans from _q.first to _q.last looking for `_item`
   * @param _item Item being searched for in queue
   * @return True if `_item` currently exists in queue, false if otherwise
   **/
  function contains(Queue storage _q, bytes32 _item) internal view returns (bool) {
    for (uint256 i = _q.first; i <= _q.last; i++) {
      if (_q.queue[i] == _item) {
        return true;
      }
    }
    return false;
  }

  /// @notice Returns last item in queue
  /// @dev Returns bytes32(0) if queue empty
  function lastItem(Queue storage _q) internal view returns (bytes32) {
    return _q.queue[_q.last];
  }

  /// @notice Returns element at front of queue without removing element
  /// @dev Reverts if queue is empty
  function peek(Queue storage _q) internal view returns (bytes32 _item) {
    require(!isEmpty(_q), "Empty");
    _item = _q.queue[_q.first];
  }

  /// @notice Returns true if queue is empty and false if otherwise
  function isEmpty(Queue storage _q) internal view returns (bool) {
    return _q.last < _q.first;
  }

  /// @notice Returns number of elements in queue
  function length(Queue storage _q) internal view returns (uint256) {
    uint128 _last = _q.last;
    uint128 _first = _q.first;
    // Cannot underflow unless state is corrupted
    return _length(_last, _first);
  }

  /// @notice Returns number of elements between `_last` and `_first` (used internally)
  function _length(uint128 _last, uint128 _first) internal pure returns (uint256) {
    return uint256(_last + 1 - _first);
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.6.11;

// import "@summa-tx/memview-sol/contracts/TypedMemView.sol";
import "./TypedMemView.sol";

library TypeCasts {
  using TypedMemView for bytes;
  using TypedMemView for bytes29;

  function coerceBytes32(string memory _s) internal pure returns (bytes32 _b) {
    _b = bytes(_s).ref(0).index(0, uint8(bytes(_s).length));
  }

  // treat it as a null-terminated string of max 32 bytes
  function coerceString(bytes32 _buf) internal pure returns (string memory _newStr) {
    uint8 _slen = 0;
    while (_slen < 32 && _buf[_slen] != 0) {
      _slen++;
    }

    // solhint-disable-next-line no-inline-assembly
    assembly {
      _newStr := mload(0x40)
      mstore(0x40, add(_newStr, 0x40)) // may end up with extra
      mstore(_newStr, _slen)
      mstore(add(_newStr, 0x20), _buf)
    }
  }

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
pragma solidity >=0.8.11;

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
  uint8 constant TWELVE_BYTES = 96;

  /**
   * @notice      Returns the encoded hex character that represents the lower 4 bits of the argument.
   * @param _b    The byte
   * @return      char - The encoded hex character
   */
  function nibbleHex(uint8 _b) internal pure returns (uint8 char) {
    // This can probably be done more efficiently, but it's only in error
    // paths, so we don't really care :)
    uint8 _nibble = _b | 0xf0; // set top 4, keep bottom 4
    if (_nibble == 0xf0) {
      return 0x30;
    } // 0
    if (_nibble == 0xf1) {
      return 0x31;
    } // 1
    if (_nibble == 0xf2) {
      return 0x32;
    } // 2
    if (_nibble == 0xf3) {
      return 0x33;
    } // 3
    if (_nibble == 0xf4) {
      return 0x34;
    } // 4
    if (_nibble == 0xf5) {
      return 0x35;
    } // 5
    if (_nibble == 0xf6) {
      return 0x36;
    } // 6
    if (_nibble == 0xf7) {
      return 0x37;
    } // 7
    if (_nibble == 0xf8) {
      return 0x38;
    } // 8
    if (_nibble == 0xf9) {
      return 0x39;
    } // 9
    if (_nibble == 0xfa) {
      return 0x61;
    } // a
    if (_nibble == 0xfb) {
      return 0x62;
    } // b
    if (_nibble == 0xfc) {
      return 0x63;
    } // c
    if (_nibble == 0xfd) {
      return 0x64;
    } // d
    if (_nibble == 0xfe) {
      return 0x65;
    } // e
    if (_nibble == 0xff) {
      return 0x66;
    } // f
  }

  /**
   * @notice      Returns a uint16 containing the hex-encoded byte.
   * @param _b    The byte
   * @return      encoded - The hex-encoded byte
   */
  function byteHex(uint8 _b) internal pure returns (uint16 encoded) {
    encoded |= nibbleHex(_b >> 4); // top 4 bits
    encoded <<= 8;
    encoded |= nibbleHex(_b); // lower 4 bits
  }

  /**
   * @notice      Encodes the uint256 to hex. `first` contains the encoded top 16 bytes.
   *              `second` contains the encoded lower 16 bytes.
   *
   * @param _b    The 32 bytes as uint256
   * @return      first - The top 16 bytes
   * @return      second - The bottom 16 bytes
   */
  function encodeHex(uint256 _b) internal pure returns (uint256 first, uint256 second) {
    for (uint8 i = 31; i > 15; ) {
      uint8 _byte = uint8(_b >> (i * 8));
      first |= byteHex(_byte);
      if (i != 16) {
        first <<= 16;
      }
      unchecked {
        i -= 1;
      }
    }

    // abusing underflow here =_=
    for (uint8 i = 15; i < 255; ) {
      uint8 _byte = uint8(_b >> (i * 8));
      second |= byteHex(_byte);
      if (i != 0) {
        second <<= 16;
      }
      unchecked {
        i -= 1;
      }
    }
  }

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
   * @notice          Check if the view is of a valid type and points to a valid location
   *                  in memory.
   * @dev             We perform this check by examining solidity's unallocated memory
   *                  pointer and ensuring that the view's upper bound is less than that.
   * @param memView   The view
   * @return          ret - True if the view is valid
   */
  function isValid(bytes29 memView) internal pure returns (bool ret) {
    if (typeOf(memView) == 0xffffffffff) {
      return false;
    }
    uint256 _end = end(memView);
    assembly {
      // solhint-disable-previous-line no-inline-assembly
      ret := not(gt(_end, mload(0x40)))
    }
  }

  /**
   * @notice          Require that a typed memory view be valid.
   * @dev             Returns the view for easy chaining.
   * @param memView   The view
   * @return          bytes29 - The validated view
   */
  function assertValid(bytes29 memView) internal pure returns (bytes29) {
    require(isValid(memView), "Validity assertion failed");
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
      (, uint256 g) = encodeHex(uint256(typeOf(memView)));
      (, uint256 e) = encodeHex(uint256(_expected));
      string memory err = string(
        abi.encodePacked("Type assertion failed. Got 0x", uint80(g), ". Expected 0x", uint80(e))
      );
      revert(err);
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
      newView := or(newView, shr(40, shl(40, memView)))
      newView := or(newView, shl(216, _newType))
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
    assembly {
      // solhint-disable-previous-line no-inline-assembly
      newView := shl(96, or(newView, _type)) // insert type
      newView := shl(96, or(newView, _loc)) // insert loc
      newView := shl(24, or(newView, _len)) // empty bottom 3 bytes
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
      _type := shr(216, memView) // shift out lower 24 bytes
    }
  }

  /**
   * @notice          Optimized type comparison. Checks that the 5-byte type flag is equal.
   * @param left      The first view
   * @param right     The second view
   * @return          bool - True if the 5-byte type flag is equal
   */
  function sameType(bytes29 left, bytes29 right) internal pure returns (bool) {
    return (left ^ right) >> (2 * TWELVE_BYTES) == 0;
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
    return (uint256(len(memView)) + 32) / 32;
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
   * @notice          Construct an error message for an indexing overrun.
   * @param _loc      The memory address
   * @param _len      The length
   * @param _index    The index
   * @param _slice    The slice where the overrun occurred
   * @return          err - The err
   */
  function indexErrOverrun(
    uint256 _loc,
    uint256 _len,
    uint256 _index,
    uint256 _slice
  ) internal pure returns (string memory err) {
    (, uint256 a) = encodeHex(_loc);
    (, uint256 b) = encodeHex(_len);
    (, uint256 c) = encodeHex(_index);
    (, uint256 d) = encodeHex(_slice);
    err = string(
      abi.encodePacked(
        "TypedMemView/index - Overran the view. Slice is at 0x",
        uint48(a),
        " with length 0x",
        uint48(b),
        ". Attempted to index at offset 0x",
        uint48(c),
        " with length 0x",
        uint48(d),
        "."
      )
    );
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
      revert(indexErrOverrun(loc(memView), len(memView), _index, uint256(_bytes)));
    }
    require(_bytes <= 32, "TypedMemView/index - Attempted to index more than 32 bytes");

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
   * @notice          Return the sha2 digest of the underlying memory.
   * @dev             We explicitly deallocate memory afterwards.
   * @param memView   The view
   * @return          digest - The sha2 hash of the underlying memory
   */
  function sha2(bytes29 memView) internal view returns (bytes32 digest) {
    uint256 _loc = loc(memView);
    uint256 _len = len(memView);
    assembly {
      // solhint-disable-previous-line no-inline-assembly
      let ptr := mload(0x40)
      pop(staticcall(gas(), 2, _loc, _len, ptr, 0x20)) // sha2 #1
      digest := mload(ptr)
    }
  }

  /**
   * @notice          Implements bitcoin's hash160 (rmd160(sha2()))
   * @param memView   The pre-image
   * @return          digest - the Digest
   */
  function hash160(bytes29 memView) internal view returns (bytes20 digest) {
    uint256 _loc = loc(memView);
    uint256 _len = len(memView);
    assembly {
      // solhint-disable-previous-line no-inline-assembly
      let ptr := mload(0x40)
      pop(staticcall(gas(), 2, _loc, _len, ptr, 0x20)) // sha2
      pop(staticcall(gas(), 3, ptr, 0x20, ptr, 0x20)) // rmd160
      digest := mload(add(ptr, 0xc)) // return value is 0-prefixed.
    }
  }

  /**
   * @notice          Implements bitcoin's hash256 (double sha2)
   * @param memView   A view of the preimage
   * @return          digest - the Digest
   */
  function hash256(bytes29 memView) internal view returns (bytes32 digest) {
    uint256 _loc = loc(memView);
    uint256 _len = len(memView);
    assembly {
      // solhint-disable-previous-line no-inline-assembly
      let ptr := mload(0x40)
      pop(staticcall(gas(), 2, _loc, _len, ptr, 0x20)) // sha2 #1
      pop(staticcall(gas(), 2, ptr, 0x20, ptr, 0x20)) // sha2 #2
      digest := mload(ptr)
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
    require(notNull(memView), "TypedMemView/copyTo - Null pointer deref");
    require(isValid(memView), "TypedMemView/copyTo - Invalid pointer deref");
    uint256 _len = len(memView);
    uint256 _oldLoc = loc(memView);

    uint256 ptr;
    assembly {
      // solhint-disable-previous-line no-inline-assembly
      ptr := mload(0x40)
      // revert if we're writing in occupied memory
      if gt(ptr, _newLoc) {
        revert(0x60, 0x20) // empty revert message
      }

      // use the identity precompile to copy
      // guaranteed not to fail, so pop the success
      pop(staticcall(gas(), 4, _oldLoc, _len, _newLoc, _len))
    }

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
    for (uint256 i = 0; i < memViews.length; i++) {
      bytes29 memView = memViews[i];
      unchecked {
        unsafeCopyTo(memView, _location + _offset);
        _offset += len(memView);
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
   * @notice          Produce the sha256 digest of the concatenated contents of multiple views.
   * @param memViews  The views
   * @return          bytes32 - The sha256 digest
   */
  function joinSha2(bytes29[] memory memViews) internal view returns (bytes32) {
    uint256 ptr;
    assembly {
      // solhint-disable-previous-line no-inline-assembly
      ptr := mload(0x40) // load unused memory pointer
    }
    return sha2(unsafeJoin(memViews, ptr));
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