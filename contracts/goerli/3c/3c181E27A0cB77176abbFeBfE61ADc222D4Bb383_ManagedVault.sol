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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library CountersUpgradeable {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title Teragon Managed Vault Interface
 * @author Teragon
 * @dev IManagedVault contains all errors, events, and public & external function interfaces for ManagedVault.
 * @custom:version 0.2
 * @custom:logo                                                =
 *                                                          ==== ===
 *                                                       ======= =======
 *                                   == ==           =========== =======
 *                                ===== ======    ============== =======
 *                             ======== =========   ============ =======
 *                         ============ ============   ========= =======
 *                      ===============   =============  ======= =======
 *                   =============== ======= ==========  ======= =======
 *               =============== ============== =======  ======= =======
 *              ============= ====================  ===  ======= =======
 *              ========= ============================   ======= =======
 *              ====== ==============     ============  ======== =======
 *              == ==============   ===  ===  ====  ============ =======
 *               ============== =======  ======  ==============   ======
 *                  =========== =======  ======= ===========  ====== ===
 *                      ======= =======  ======= =======  =============
 *                         ==== =======  ======= ====  ==============
 *                              =======  =======    ==============
 *                              =======  =======  ==============
 *                              =======  ===========  =====  ===
 *                              =======  ==============  =======
 *                              ===  =====  ====================
 *                                ============ =================
 *                                ===============  =============
 *                                    =============== ==========
 *                                       ===============  ======
 *                                           ==============  ===
 *                                              ==============
 *                                                  ========
 *                                                     ==
 */
interface IManagedVault {

    /* ------------------------------- */
    /*              Enums              */
    /* ------------------------------- */

    /**
     * @notice Only used in RedemptionEpoch structs. When a redemption epoch is created its status is 0 (Pending).
     *         When the owner liquidates the required amount of redemption tokens, they call the settleRedemptionEpoch
     *         function. If the call succeedes, the state is set as 1 (Settled) and the investors are able to withdraw
     *         their portions of the settlement.
     */
    enum RedemptionEpochState { Pending, Settled }

    /* --------------------------------- */
    /*              Structs              */
    /* --------------------------------- */

    /**
     * @notice Redemptions are settled in epochs. Investors can request to redeem at anytime. When the owner calls the
     *         rollRedemptionEpoch, one of the structs below is pushed to the redemptionEpochs array.
     *
     * @param state                  Initially 0 (Pending). When the ownersettles the epoch, set to 1 (Settled).
     * @param redemptionToken        The token this redemption epoch is paid in.
     * @param redemptionTokenPrice   The price of the redemption token at the time of settlement.
     * @param netVaultPriceAfterFees The price of the vault token after fees at the time of settlement.
     * @param vaultTokenTotalAmount  The total amount of tokens registered for redemption in this epoch.
     */
    struct RedemptionEpoch {
        RedemptionEpochState state;
        IERC20 redemptionToken;
        uint256 redemptionTokenPrice;
        uint256 netVaultPriceAfterFees;
        uint256 vaultTokenTotalAmount;
    }

    /* -------------------------------- */
    /*              Events              */
    /* -------------------------------- */

    /* ------------ Events for External Functions ------------ */

    /**
     * @notice Emitted when a user deposits the native cryptocurrency (Ether for the Ethereum network)
     *         into the contract.
     *
     * @param depositor The address of the user who deposited the native cryptocurrency.
     * @param amount The amount of native cryptocurrency deposited.
     */
    event DepositNative(address indexed depositor, uint256 indexed amount);

    /**
     * @notice Emitted when a user deposits a deposit token into the contract.
     */
    event DepositToken(IERC20 indexed tokenAddress, address indexed depositor, uint256 indexed amount);

    event Redeem(uint256 indexed redemptionEpochId, address indexed account, uint256 indexed amount);

    event Withdraw(uint256 indexed redemptionEpochId, address indexed account, uint256 indexed amount);

    /* ------------ Events for External Owner Functions for Management ------------ */

    /**
     * @notice Emitted when the manager sets the vault price for a given block number.
     */
    event SetVaultPrice(uint256 indexed blockNumber, uint256 indexed price);

    /**
     * @notice Emitted when the manager mints pending deposits.
     * @dev Used to display account based PNL on frontends
     */
    event DepositMinted(
        address indexed depositor,
        uint256 amount,
        uint256 indexed blockTimeStamp,
        uint256 indexed vaultPrice
    );

    /**
     * @notice Emitted when the manager sets the price of the native currency.
     * (Ether for the Ethereum network) for the deposits.
     */
    event SetNativePrice(uint256 indexed blockNumber, uint256 indexed price);

    /**
     * @notice Emitted when the manager sets the price of a deposit token.
     */
    event SetTokenPrice(uint256 indexed blockNumber, IERC20 indexed tokenAddress, uint256 indexed price);

    event RollRedemptionEpoch(
        uint256 indexed redemptionEpochId,
        IERC20 indexed redemptionToken,
        uint256 redemptionTokenPrice,
        uint256 netVaultPriceAfterFees,
        uint256 vaultTokenTotalAmount
    );

    event SettleRedemptionEpoch(
        uint256 indexed redemptionEpochId,
        IERC20 indexed redemptionToken,
        uint256 totalRedemptionTokenAmount
    );

    event AccruePerformanceFee(uint256 indexed performanceFeePeriodCount, uint256 accuredPerformanceFee);

    event MintPerformanceFee(address indexed to, uint256 amount);

    event MintManagementFee(address indexed to, uint256 amount);

    /* ------------ Events for External Owner Functions for Deposit Settings ------------ */

    /**
     * @notice Emitted when the native currency's (Ether for the Ethereum network) deposit state is changed.
     */
    event SetNativeDepositState(bool state);

    /**
     * @notice Emitted when a token is set or unset as an enabled deposit token.
     */
    event SetTokenDepositState(IERC20 tokenAddress, bool state);

    /**
     * @notice Emitted when the manager sets the minimum of amount native currency that is allowed for deposits. 
     */
    event SetNativeMinimumDepositAmount(uint256 indexed amount);

    /**
     * @notice Emitted when the manager sets minimum deposit amount for a deposit token. 
     */
    event SetTokenMinimumDepositAmount(IERC20 indexed tokenAddress, uint256 indexed amount);

    /* ------------ Events for External Owner Functions for Redemption Settings ------------ */

    event SetNextRedemptionToken(IERC20 indexed tokenAddress);

    event SetRedemptionFeeBPS(uint256 bps);

    /* ------------ Events for External Owner Functions for Management Fee Settings ------------ */
    
    event SetManagementFeeBPS(uint256 bps);

    /* ------------ Events for External Owner Functions for Performance Fee Settings ------------ */
    
    event SetPerformanceFeeBPS(uint256 bps);

    event SetPerformanceFeePeriodSeconds(uint256 duration);

    event SetPerformanceFeeAccrueWindowSeconds(uint256 durations);

    /* ------------ Events for External Owner Functions for Administration ------------ */

    /**
     * @notice Emitted when the pause is triggered.
     */
    event Paused();

    /**
     * @notice Emitted when the pause is lifted.
     */
    event Unpaused();

    /**
     * @notice Emitted when the owner invokes an arbitrary function of any contract.
     */
    event Invoked(address indexed target, uint indexed value, bytes data, bytes returnValue);

    /* -------------------------------- */
    /*              Errors              */
    /* -------------------------------- */

    /**
     * @notice The owner must precisly calculate asset prices at a specific block in the past.
     *
     * @param blockNumber The given block number that is equal or larger than the current block.
     */
    error BlockNumberInTheFuture(uint256 blockNumber);

    /**
     * @notice Thrown when a token address is not supplied as expected. In setPrices, the token address array must be
     *         exactly the same as the response of the tokenAdresses() function.
     *
     * @param givenTokenAddress    The given token address.
     * @param expectedTokenAddress The expected token address.
     */
    error InvalidTokenAddress(IERC20 givenTokenAddress, IERC20 expectedTokenAddress);

    /**
     * @notice Thrown when the deposit is not allowed for the native currency or a token
     */
    error DepositNotAllowed();

    /**
     * @notice Thrown when the deposit amount is less than the minimum amount
     *
     * @param amount        The amount to be deposited
     * @param minimumAmount The minimum amount for such deposits
     */
    error AmountTooLittle(uint256 amount, uint256 minimumAmount);

    /**
     * @notice Thrown when a required transfer is failed
     */
    error TransferFailed();

    /**
     * @notice Thrown when given redemptionFeeBPS is higher than the maximum
     */
    error InvalidRedemptionFeeBPS();

    /**
     * @notice Thrown when given managementFeeBPS is higher than the maximum
     */
    error InvalidManagementFeeBPS();

    /**
     * @notice Thrown when given performanceFeeBPS is higher than the maximum
     */
    error InvalidPerformanceFeeBPS();

    /**
     * @notice Thrown when accrual period hasn't started yet
     *
     * @param performanceFeePeriodCount  The performance fee period for which accrual was attempted
     * @param accrueWindowFirstTimestamp The first allowed timestamp of the accrual period
     * @param currentTimestamp           Current timestamp
     */
    error EarlyPerformanceFeeAccrue(
        uint256 performanceFeePeriodCount,
        uint256 accrueWindowFirstTimestamp,
        uint256 currentTimestamp
    );

    /**
     * @notice Thrown when accrual period has passed
     *
     * @param performanceFeePeriodCount The performance fee period for which accrual was attempted
     * @param accrueWindowLastTimestamp The last allowed timestamp of the accrual period
     * @param currentTimestamp Current timestamp
     */
    error LatePerformanceFeeAccrue(uint256 performanceFeePeriodCount, uint256 accrueWindowLastTimestamp, uint256 currentTimestamp);

    /* -------------------------------------------- */
    /*              External Functions              */
    /* -------------------------------------------- */

    /**
     * @notice Deposits the native currency (eg. ETH for the Ethereum network) into the managed vault.
     *         msg.value must be equal to or greater than nativeMinimumDepositAmount.
     *         Requires that nativeDepositState is true.
     *         Requires that the contract is not paused.
     *         Emits a {DepositNative} event.
     */
    function depositNative() payable external;

    /** 
     * @notice Deposits ERC-20 tokens into the managed vault.
     *         Amount must be equal to or greater than minimumDepositTokenAmount.
     *         Requires that the token address is whitelisted.
     *         Requires that the contract is not paused.
     *         Emits a {DepositToken} event.
     *
     * @param tokenAddress The address of the token.
     * @param amount       The amount of the token.
     */
    function depositToken(IERC20 tokenAddress, uint256 amount) external;

    /**
     * @notice Updates the user's amount of vault tokens pending redemption in the current redemption epoch. 
     *         Previously settled redemption epoch proceeds can be withdrawn via {withdraw}.
     *         Can be called more than once during the same redemption epoch to override the redemption amount.
     *         Modifies redemption states only for the current epoch, previous epoch states cannot be modified.
     *         Requires that the contract is not paused.
     *
     * @param amount The amount of vault tokens.
     */
    function redeem(uint256 amount) external;

    /**
     * @notice Withdraws specified epoch's settlement proceeds (in the form of the token that is set as the redemption
     *         token, eg. "USDC") and burns the redeemed vault tokens. Can be executed for any past epoch at any point
     *         in time in which a user redemption was initialized and settled.
     *         Requires that the contract is not paused.
     *
     * @param account           The address where withdrawn tokens will be transferred.
     * @param redemptionEpochId The epoch of the redemption to withdraw.
     */
    function withdraw(address account, uint256 redemptionEpochId) external;

    /* ----------------------------------------------------------------- */
    /*              External Owner Functions for Management              */
    /* ----------------------------------------------------------------- */

    /**
     * @notice Sets the vault's token price, native price, and all token prices for a given blockNumber.
     *         Afterwards, the pending deposits up until the blockNumber can be minted.
     *         The native price must be set regardless of its deposit status. The token prices should be set in the
     *         right order. Emits {SetVaultPrice}, {SetNativePrice}, and {SetTokenPrice} events when these values are
     *         updated.
     *         Requires the caller to be the owner.
     *
     * @param blockNumber           The block number of the new prices. Must be lower than block.number.
     * @param vaultPriceAtTheBlock  New price of the vault token.
     * @param nativePriceAtTheBlock New price of the native currency (eg. ETH price for the Ethereum network).
     * @param tokenAddresses        Array of token addresses to set prices for in the order of {tokenAdresses} function.
     * @param tokenPricesAtTheBlock Array of token prices in the order of tokenAdresses.
     */
    function setPrices(
        uint256 blockNumber,
        uint256 vaultPriceAtTheBlock,
        uint256 nativePriceAtTheBlock,
        IERC20[] calldata tokenAddresses,
        uint256[] calldata tokenPricesAtTheBlock
    ) external;

    /**
     * @notice Mints tokens for new deposits since the last mint until (including) the setPriceBlockNumber.
     *         Removes the pending deposits, and adds vault token balances to depositors.
     *         Requires the caller to be the owner.
     *
     * @param maxMints Maximum number of individual deposits that will be minted. Could higher as long as
     *                 the transaction does not exceed the network's block gas limit.
     *
     * @return mintCount The number of mint operations performed.
     */
    function mint(uint256 maxMints) external returns (uint256 mintCount);

    /**
     * @notice Ends the current epoch and starts a new one. Since a new epoch is initiated, redeem() calls ensuing this
     *         function's execution will be applied for the new redemption epoch. This effectively means that redemption
     *         amounts for the previous epoch are now locked-in, new redeems cannot be added, existing ones can no
     *         longer be modified.
     *         Requires the caller to be the owner.
     */
    function rollRedemptionEpoch() external;

    /**
     * @notice Calculates and transfers the tokens required to fulfill redemptions for the last redemption epoch.
     *         Afterward, redeemed amounts for that epoch are enabled for withdrawal. Before executing this function
     *         the vault owner must verify that the vault owner account is in possession of the amount of required 
     *         redemptionTokens and that the vault contract has the necessary token allowance from the owner.
     *         Otherwise, the call will revert with {TransferFailed}.
     *         Requires the previous epoch to be in "Settled" state, except for the first epoch.
     *         Requires the epoch to be in "Pending" state.
     *         Requires the caller to be the owner.
     *
     * @param redemptionEpochId Redemption epoch id. Must be less than {redemptionEpochsCount}.
    */
    function settleRedemptionEpoch(uint256 redemptionEpochId) external;

    /**
     * @notice Calculates the performance fee earned by the vault and updates the accrued fee amount in vault tokens.
     *         Requires the caller to be the owner.
     *
     * @param performanceFeePeriodCount Elapsed number of performance fee periods.
    */
    function accruePerformanceFee(uint256 performanceFeePeriodCount) external;

    /**
     * @notice Mints the specified amount of performance fee earned by the vault in the form of new vault tokens.
     *         Requires the caller to be the owner.
     *
     * @param to     The address to send the newly minted tokens.
     * @param amount The amount of tokens to mint (cannot exceed performanceFeeAccruedVaultTokenAmount).
    */
    function mintPerformanceFee(address to, uint256 amount) external;

    /**
     * @notice Mints the specified amount of management fee earned by the vault in the form of new vault tokens.
     *         Requires the caller to be the owner.
     *
     * @param to     The address to send the newly minted tokens.
     * @param amount The amount of tokens to mint (cannot exceed managementFeeAccruedVaultTokenAmount).
    */
    function mintManagementFee(address to, uint256 amount) external;

    /* ----------------------------------------------------------------------- */
    /*              External Owner Functions for Deposit Settings              */
    /* ----------------------------------------------------------------------- */

    /**
     * @notice Sets the native currency (eg. ETH for the Ethereum network) whitelist state. {depositNative} function
     *         won't work unless this function is set to true. Emits a {SetNativeDepositState} event if whitelist state
     *         changes for native cryptocurrency.
     *         Requires the caller to be the owner.
     *
     * @param state The new state of the whitelist.
     */
    function setNativeDepositState(bool state) external;

    /**
     * @notice Sets token whitelist states. Only whitelisted tokens are accepted for deposits. If the state is true,
     *         the token is allowed for deposits, thus can be set as nextRedemptionToken. Otherwise, depositToken
     *         for that token reverts. Emits a {SetTokenDepositState} event if whitelist state changes for the token.
     *         Requires the caller to be the owner.
     *
     * @param tokenAddress Address of the token.
     * @param state        The new state of the whitelist.
     */
    function setTokenDepositState(IERC20 tokenAddress, bool state) external;

    /**
     * @notice Sets the minimum amount of native currency that can be deposited. Can protect against dust attacks. Emits
     *         a {SetNativeMinimumDepositAmount} event.
     *         Requires the caller to be the owner.
     *
     * @param amount The minimum amount of native cryptocurrency that can be deposited.
     */
    function setNativeMinimumDepositAmount(uint256 amount) external;

    /**
     * @notice Sets the minimum amount of a deposit token that can be deposited. Can protect against dust attacks. Emits
     *         a {SetTokenMinimumDepositAmount} event.
     *         Requires the caller to be the owner.
     *
     * @param tokenAddress The address of the deposit token.
     * @param amount       The minimum amount of the deposit token that can be deposited.
     */
    function setTokenMinimumDepositAmount(IERC20 tokenAddress, uint256 amount) external;

    /* -------------------------------------------------------------------------- */
    /*              External Owner Functions for Redemption Settings              */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Sets {nextRedemptionToken} i.e. the token that will be used to settle redemptions in the next redemption
     *         epochs that will be created by {rollRedemptionEpoch}. The token must be among {tokenDepositStates}.
     *         Emits a {SetTokenMinimumDepositAmount} event.
     *         Requires the caller to be the owner.
     *
     * @param tokenAddress The address of the redemption token.
     */
    function setNextRedemptionToken(IERC20 tokenAddress) external;

    /**
     * @notice Sets {redemptionFeeBPS} i.e. the fee that is taken on redemptions in basis points. Maximum value is 1000
     *         (10%).
     *         Requires the caller to be the owner.
     *
     * @param bps The fee amount in basis points, 100 means 1%.
     */
    function setRedemptionFeeBPS(uint256 bps) external;

    /* ------------------------------------------------------------------------------ */
    /*              External Owner Functions for Management Fee Settings              */
    /* ------------------------------------------------------------------------------ */

    /**
     * @notice Sets {managementFeeBPS} i.e. the annual fee taken from the vault in basis points. Maximum value is 1000
     *         (10%).
     *         Requires the caller to be the owner.
     *
     * @param bps The fee amount in basis points, 100 means 1%.
     */
    function setManagementFeeBPS(uint256 bps) external;
       
    /* ------------------------------------------------------------------------------- */
    /*              External Owner Functions for Performance Fee Settings              */
    /* ------------------------------------------------------------------------------- */

    /**
     * @notice Sets {performanceFeeBPS} i.e. the fee that is taken from the positive performance of the vault in basis
     *         points. Maximum value is 5000 (50%).
     *         Requires the caller to be the owner.
     *
     * @param bps The fee amount in basis points, 100 means 1%.
     */
    function setPerformanceFeeBPS(uint256 bps) external;
    
    /**
     * @notice Sets {performanceFeePeriodSeconds} the performance fee period length in seconds.
     *         Requires the caller to be the owner.
     *
     * @param duration The period length in seconds for calculating the performance fee windows in which the owner is allowed
     *        to accrue the performance fee.
     */
    function setPerformanceFeePeriodSeconds(uint256 duration) external;
    
    /**
     * @notice Sets {performanceFeeAccrueWindowSeconds} performance fee accrual window in seconds. This duration does
     *         not extend the length between the beginning of periods, which is only determined by
     *         {performanceFeePeriodSeconds}.
     *         Requires the caller to be the owner.
     *
     * @param duration The length of the window in which the owner is allowed to accrue the performance fee. 
     */
    function setPerformanceFeeAccrueWindowSeconds(uint256 duration) external;  

    /* --------------------------------------------------------------------- */
    /*              External Owner Functions for Administration              */
    /* --------------------------------------------------------------------- */

    /**
     * @notice Triggers stopped state. Emits {Paused}.
     *         Requires the contract not to be already paused.
     *         Requires the caller to be the owner.
     */
    function pause() external;

    /**
     * @notice Returns to normal state. Emits {Unpaused}.
     *         Requires the contract to be paused.
     *         Requires the caller to be the owner.
     */
    function unpause() external;
        
    /**
     * @notice Low level function that allows a module to make an arbitrary function call to any contract. Emits an
     *         {Invoked} event.
     *         Requires the target to be a contract address.
     *         Requires the caller to be the owner.
     *
     * @param target Address of the smart contract to call.
     * @param value  Quantity of Ether to provide the call (typically 0).
     * @param data   Encoded function selector and arguments.
     *
     * @return returnValue Bytes encoded return value.
     */
    function invoke(
        address target,
        bytes calldata data,
        uint256 value
    ) external returns (bytes memory returnValue);

    /* ------------------------------------------------- */
    /*              External View Functions              */
    /* ------------------------------------------------- */

    /**
     * @notice Returns the token addresses enabled for deposits.
     *
     * @return tokenAddresses Array of token addresses that is enabled for deposits.
     */
    function tokenAdresses() external view returns (address[] memory tokenAddresses);

    /**
     * @notice Returns the number of pending mints and the total number of vault tokens to be minted. Only includes
     *         deposits at or before setPriceBlockNumber. The response of this function could be used to simulate the
     *         response of the mint function.
     *
     * @param maxMints The maximum number of mints to be simulated.
     *
     * @return count  The number of pending mints.
     * @return amount The number of vault tokens to be minted.
     */
    function pendingMintsCountAndAmount(uint maxMints) external view returns (uint count, uint amount);

    /**
     * @notice Returns the remaining number of native currency (eg. ETH for the Ethereum network) deposits amount for a
     *         given depositor.
     *
     * @param depositor The address of the depositor.
     *
     * @return totalAmount Remaining native currency deposited by depositor.
     */
    function pendingNativeDepositAmount(address depositor) external view returns (uint totalAmount);

    /**
     * @notice Returns the remaining number of deposit amount for a given token address and depositor.
     * 
     * @param depositor    The address of the depositor.
     * @param tokenAddress The address of the deposit token.
     *
     * @return totalAmount Remaining deposit amount for the given token address and depositor.
     */
    function pendingTokenDepositAmount(address depositor, IERC20 tokenAddress) external view returns (uint totalAmount);

    /**
     * @notice Returns the total remaining deposit amount for the native currency (eg. ETH for the Ethereum network) up
     *         to a block number.
     *
     * @param maxBlockNumber The maximum block number to make the calculations for.
     *
     * @return totalAmount   Remaining native currency deposited up to the given block number.
     */
    function totalPendingNativeDepositAmount(uint maxBlockNumber) external view returns (uint totalAmount);

    /**
     * @notice Returns the total remaining deposit amount for the given token address up to (including) a block number.
     *
     * @param maxBlockNumber The maximum block number to make the calculations for.
     * @param tokenAddress   The address of the deposit token.
     *
     * @return totalAmount Remaining deposit amount for the given token address up to (including) the given block number.
     */
    function totalPendingTokenDepositAmount(
        uint maxBlockNumber,
        IERC20 tokenAddress
    ) external view returns (uint totalAmount);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

/**
 * @title PendingDeposit
 * @author Teragon
 * 
 * Adopted from https://github.com/edag94/solidity-queue
 */


library PendingDeposit { 
    struct Item {
        uint256 blockNumber;
        address depositor;
        uint256 amount;
    }

    struct Queue {
        mapping (uint256 => Item) _pendingDeposits;
        uint256 _first;
        uint256 _last;
    }

    modifier isNotEmpty(Queue storage queue) {
        require(!isEmpty(queue), "Queue is empty.");
        _;
    }

    /**
     * @dev Gets the number of elements in the queue. O(1)
     * @param queue Queue struct from contract.
     */
    function length(Queue storage queue) internal view returns (uint256) {
        if (queue._last <= queue._first) {
            return 0;
        }
        return queue._last - queue._first;
    }

    /**
     * @dev Returns if queue is empty. O(1)
     * @param queue Queue struct from contract.
     */
    function isEmpty(Queue storage queue) internal view returns (bool) {
        return length(queue) == 0;
    }

    /**
     * @dev Adds an element to the back of the queue. O(1)
     * @param queue Queue struct from contract.
     * @param pendingDeposit The added element's pendingDeposit.
     */
    function enqueue(Queue storage queue, Item memory pendingDeposit) internal {
        queue._pendingDeposits[queue._last++] = pendingDeposit;
    }

    /**
     * @dev Removes an element from the front of the queue and returns it. O(1)
     * @param queue Queue struct from contract.
     */
    function dequeue(Queue storage queue) internal isNotEmpty(queue) returns (Item memory pendingDeposit) {
        pendingDeposit = queue._pendingDeposits[queue._first];
        delete queue._pendingDeposits[queue._first++];
    }

    /**
     * @dev Returns the pendingDeposit from the front of the queue, without removing it. O(1)
     * @param queue Queue struct from contract.
     */
    function peek(Queue storage queue) internal view isNotEmpty(queue) returns (Item memory pendingDeposit) {
        return queue._pendingDeposits[queue._first];
    }

    /**
     * @dev Returns the pendingDeposit from the back of the queue. O(1)
     * @param queue Queue struct from contract.
     */
    function peekLast(Queue storage queue) internal view isNotEmpty(queue) returns (Item memory pendingDeposit) {
        return queue._pendingDeposits[queue._last - 1];
    }

    function peekIndex(Queue storage queue, uint256 index) internal view isNotEmpty(queue) returns (Item memory pendingDeposit) {
        require(queue._first + index < queue._last, "Index out of bound");
        return queue._pendingDeposits[queue._first + index];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";

import "./interfaces/IManagedVault.sol";
import "./libraries/PendingDeposit.sol";

/**
 * @title Teragon Managed Vault
 * @author Teragon Labs Ltd
 * @custom:version 0.2
 * @custom:logo                                                =
 *                                                          ==== ===
 *                                                       ======= =======
 *                                   == ==           =========== =======
 *                                ===== ======    ============== =======
 *                             ======== =========   ============ =======
 *                         ============ ============   ========= =======
 *                      ===============   =============  ======= =======
 *                   =============== ======= ==========  ======= =======
 *               =============== ============== =======  ======= =======
 *              ============= ====================  ===  ======= =======
 *              ========= ============================   ======= =======
 *              ====== ==============     ============  ======== =======
 *              == ==============   ===  ===  ====  ============ =======
 *               ============== =======  ======  ==============   ======
 *                  =========== =======  ======= ===========  ====== ===
 *                      ======= =======  ======= =======  =============
 *                         ==== =======  ======= ====  ==============
 *                              =======  =======    ==============
 *                              =======  =======  ==============
 *                              =======  ===========  =====  ===
 *                              =======  ==============  =======
 *                              ===  =====  ====================
 *                                ============ =================
 *                                ===============  =============
 *                                    =============== ==========
 *                                       ===============  ======
 *                                           ==============  ===
 *                                              ==============
 *                                                  ========
 *                                                     ==
 */
contract ManagedVault is Initializable, OwnableUpgradeable, ERC20Upgradeable, IManagedVault {

    /* ----------------------------------- */
    /*              Libraries              */
    /* ----------------------------------- */

    using AddressUpgradeable for address;
    using EnumerableSet for EnumerableSet.AddressSet;
    using PendingDeposit for PendingDeposit.Queue;
    using CountersUpgradeable for CountersUpgradeable.Counter;

    /* ----------------------------------- */
    /*              Constants              */
    /* ----------------------------------- */

    /**
     * @dev One mean calendar year has 8765.82 hours. This constant is equivalent to 8765.82 x 60 x 60.
     */
    uint256 constant SECONDS_IN_A_YEAR = 8765.82 hours;

    /**
     * @dev 100% in basis points
     */
    uint256 constant ONE_HUNDRED_PERCENT_BPS = 10000;

    /**
     * @dev 10% in basis points
     */
    uint256 constant MAX_REDEMPTION_FEE_BPS = 1000;

    /**
     * @dev 10% in basis points
     */
    uint256 constant MAX_MANAGEMENT_FEE_BPS = 1000;

    /**
     * @dev 50% in basis points
     */
    uint256 constant MAX_PERFORMANCE_FEE_BPS = 5000;

    /* ----------------------------------------- */
    /*              State Variables              */
    /* ----------------------------------------- */

    /**
     * @dev Pending deposits for the network's native currency (eg. ETH for the Ethereum network).
     */
    PendingDeposit.Queue pendingNativeDeposits;

    /**
     * @notice A mapping from deposit token address to pending token deposits for whitelisted tokens.
     */
    mapping(IERC20 => PendingDeposit.Queue) public pendingTokenDeposits;

    /**
     * @notice The price of 1e18 of this contract's token in USD with a given precision such as 1e6. The given precision
     *         must be the same for all prices. For instance, if a precision value of 6 is used for a vault, $100 vault
     *         price should be set as: 1e2 * 1e6 * 1e18 = 1e26.
     */
    uint256 public vaultPrice;

    /**
     * @notice The block number the prices are set for in the last setPrices call.
     */
    uint256 public setPriceBlockNumber;

    /* ------------ Native Currency Settings & Variables ------------ */

    /**
     * @notice Whether the native currency deposits are allowed or not.
     */
    bool public nativeDepositState;

    /**
     * @notice The price of the native currency.
     */
    uint256 public nativePrice;

    /**
     * @notice The minimum deposit amount for native currency deposits.
     */
    uint256 public nativeMinimumDepositAmount;

    /* ------------ Token Settings & Variables ------------ */

    /**
     * @dev A set of token addresses for enabled tokenDepositStates. {tokenAdresses} could be used for reading them.
     */
    EnumerableSet.AddressSet private tokenDepositStates;

    /**
     * @notice Prices of deposit tokens.
     */
    mapping(IERC20 => uint256) public tokenPrices;

    /**
     * @notice Minimum deposit amounts for deposit tokens.
     */
    mapping(IERC20 => uint256) public tokenMinimumDepositAmounts;

    /* ----------------------------------------------------------- */
    /*              State Variables for Versions 0.2+              */
    /* ----------------------------------------------------------- */

    /**
     * @notice Whether the contract is paused or not. Replicating OpenZeppelin's Pausable functionality as we cannot add
     *         another class dependency due to upgradeable storage patterns.
     */
    bool public paused;

    /**
     * @notice Locked vault token amounts that can be only locked and unlocked by the contract. Used for locking
     *         redeemed tokens.
     */
    mapping(address => uint256) public locks;

    /* ------------ Redemption settings ------------ */
    
    /**
     * @notice The redemption fee amount in basis points, 100 means 1%.
     */
    uint256 public redemptionFeeBPS;
    
    /**
     * @notice The token that will be used for settling the next redemption epoch. Must be among the deposit tokens.
     */
    IERC20 public nextRedemptionToken;

    /* ------------ Redemption variables ------------ */
    
    /**
     * @notice Total vault tokens redeemed since the last rolled redemption epoch. This amount will be settled in the
     *         next redemption epoch by the manager.
     */
    uint256 public nextRedemptionEpochVaultTokenTotalAmount;
    
    /**
     * @notice The total vault token amount settled by the manager, awaiting withdrawal from redeemers. 
     *         Non-withdrawn amounts are rolled over to pursuing epochs until withdrawn.
     */
    uint256 public withdrawableVaultTokenTotalAmount;
    
    /**
     * @notice Rolled redemption epochs that are either pending to be settled by the manager or already settled.
     *         New redemptions are going to be included in the next redemptionEpoch and until that time they can be
     *         updated or cancelled.
     */
    RedemptionEpoch[] public redemptionEpochs;
    
    /**
     * @notice Redemptions for a given redemptionEpochId and account. Could be read as:
     *         mapping(uint256 redemptionEpochId => mapping(address account => uint256 redemptionAmount))
     */
    mapping(uint256 => mapping(address => uint256)) public redemptions;

    /* ------------ Management fee settings ------------ */
    
    /**
     * @notice The annual management fee amount in basis points, 100 means 1%.
     */
    uint256 public managementFeeBPS;

    /* ------------ Management fee variables ------------ */
    
    /**
     * @notice The last timestamp where management fee accrued.
     *         
     */
    uint256 public managementFeeLastUpdatedTimestamp;
    
    /**
     * @notice The number of vault tokens accrued as vault management fee.
     */
    uint256 public managementFeeAccruedVaultTokenAmount;

    // 
    /* ------------ Performance fee settings ------------ */
    
    /**
     * @notice The performance fee amount in basis points, 100 means 1%.
     */
    uint256 public performanceFeeBPS;
    
    /**
     * @notice The period length in seconds for calculating the performance fee windows that the owner can accrue the
     *         performance fee.
     */
    uint256 public performanceFeePeriodSeconds;
    
    /**
     * @notice The length of the window where the owner can accrue the performance fee. 
     */
    uint256 public performanceFeeAccrueWindowSeconds;

    // 
    /* ------------ Performance fee variables ------------ */
    
    /**
     * @notice The number of vault tokens accrued as vault performance fee.
     */
    uint256 public performanceFeeAccruedVaultTokenAmount;
    
    /**
     * @notice The anchor timestamp for calculating the windows in which the owner can accrue the performance fee.
     *         Set to the contract deployment timestamp for new deployments.
     */
    uint256 public performanceFeeInitiationTimestamp;
    
    /**
     * @notice Aggregate enterance to the vault by investors. Kept for calculating the performance of the vault. Its
     *         unit is a virtual USD amount with the precision used for the prices. $1 would mean 1e24 if 6 price
     *         precision is used for prices and 1e18 precision is used for amounts.
     */
    uint256 public performanceFeeEntrance;
    
    /**
     * @notice Aggregate exit from the vault by investors. Reduced proportionally when the investors exit the vault at a
     *         loss. Kept for calculating the performance of the vault. Its unit is a virtual USD amount with the
     *         precision used for the prices. $1 would mean 1e24 if 6 price precision is used for prices and 1e18
     *         precision is used for amounts.
     */
    uint256 public performanceFeeExit;

    /* -------------------------------------------- */
    /*              Function Modifiers              */
    /* -------------------------------------------- */

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *      Requires that the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!paused, "Pausable: paused");
        _;
    }

    /* ----------------------------------------------- */
    /*              Initializer Functions              */
    /* ----------------------------------------------- */

    /**
     * @dev The implementation of {initialize1} so that {initialize} can run this for new contracts.
     */
    function __ManagedVault_init_1(address owner_, string memory name_, string memory symbol_) internal reinitializer(1) {
        __ERC20_init(name_, symbol_);
        __Ownable_init();
        _transferOwnership(owner_);
    }

    /**
     * @dev The implementation of {initialize2} so that {initialize} can run this for new contracts.
     */
    function __ManagedVault_init_2() internal reinitializer(2) {
        require(owner() != address(0), "Parent initializer is not run");
        performanceFeeEntrance = grossAssetValue();
        managementFeeLastUpdatedTimestamp = block.timestamp;
        performanceFeeInitiationTimestamp = block.timestamp;
    }

    /**
     * @dev The original initializer. Emits an {Initialized(1)} event.
     */
    function initialize1(address owner_, string memory name_, string memory symbol_) external {
        __ManagedVault_init_1(owner_, name_, symbol_);
    }

    /**
     * @dev The initializer for v0.2. For new deployments, _ManagedVault_init_1() must be called first; this initializer function
     *      confirms that by checking whether the owner is initialized. Emits an {Initialized(2)} event. For upgrades from
     *      previous versions, this function should be called as the first step in the post-upgrade init multicall.
     */
    function initialize2() external {
        __ManagedVault_init_2();
    }

    /**
     * @dev The initialize function that calls all the required initializers for new deployments.
     */
    function initialize(address owner_, string memory name_, string memory symbol_) external {
        __ManagedVault_init_1(owner_, name_, symbol_);
        __ManagedVault_init_2();
    }

    /* -------------------------------------------- */
    /*              External Functions              */
    /* -------------------------------------------- */

    /**
     * @inheritdoc IManagedVault
     */
    function depositNative() payable whenNotPaused external {
        address depositor = msg.sender;
        uint256 amount = msg.value;

        if (!nativeDepositState) {
            revert DepositNotAllowed();
        }

        if (amount < nativeMinimumDepositAmount) {
            revert AmountTooLittle({
                amount: amount,
                minimumAmount: nativeMinimumDepositAmount
            });
        }

        (bool success, ) = payable(owner()).call{value:msg.value}("");
        if (!success) {
            revert TransferFailed();
        }

        PendingDeposit.Item memory pendingDeposit = PendingDeposit.Item({
            blockNumber: block.number,
            depositor: depositor,
            amount: amount
        });

        pendingNativeDeposits.enqueue(pendingDeposit);
        emit DepositNative(depositor, amount);
    }

    /**
     * @inheritdoc IManagedVault
     */
    function depositToken(IERC20 tokenAddress, uint256 amount) whenNotPaused external {
        address depositor = msg.sender;

        if (!tokenDepositStates.contains(address(tokenAddress))) {
            revert DepositNotAllowed();
        }

        if (amount < tokenMinimumDepositAmounts[tokenAddress]) {
            revert AmountTooLittle({
                amount: amount,
                minimumAmount: tokenMinimumDepositAmounts[tokenAddress]
            });
        }

        bool success = tokenAddress.transferFrom(depositor, owner(), amount);
        if (!success) {
            revert TransferFailed();
        }

        PendingDeposit.Item memory pendingDeposit = PendingDeposit.Item({
            blockNumber: block.number,
            depositor: depositor,
            amount: amount
        });

        pendingTokenDeposits[tokenAddress].enqueue(pendingDeposit);
        emit DepositToken(tokenAddress, depositor, amount);
    }

    /**
     * @inheritdoc IManagedVault
     *
     * @dev _lock and _unlock functions have the necessary require statements for the amounts.
     */
    function redeem(uint256 amount) whenNotPaused external {
        uint256 oldAmount = redemptions[redemptionEpochs.length][msg.sender];
        require(oldAmount != amount);

        if (oldAmount < amount) {
            _lock(msg.sender, amount - oldAmount);
        } else if (amount < oldAmount) {
            _unlock(msg.sender, oldAmount - amount);
        }

        unchecked {
            nextRedemptionEpochVaultTokenTotalAmount += (amount - oldAmount);
        }
        redemptions[redemptionEpochs.length][msg.sender] = amount;
        emit Redeem(redemptionEpochs.length, msg.sender, amount);
    }

    /**
     * @inheritdoc IManagedVault
     */
    function withdraw(address account, uint256 redemptionEpochId) whenNotPaused external {
        require(redemptionEpochId < redemptionEpochs.length, "Invalid epoch");
        RedemptionEpoch storage redemptionEpoch = redemptionEpochs[redemptionEpochId];
        require(redemptionEpoch.state == RedemptionEpochState.Settled, "Settlement for the given epoch has not been completed yet.");
        uint256 amount = redemptions[redemptionEpochId][account];
        require(0 < amount);

        withdrawableVaultTokenTotalAmount -= amount;
        redemptions[redemptionEpochId][account] = 0;
        _unlock(account, amount);
        _burn(account, amount);

        bool success = redemptionEpoch.redemptionToken.transfer(account, amount * redemptionEpoch.netVaultPriceAfterFees / redemptionEpoch.redemptionTokenPrice);
        if (!success) {
            revert TransferFailed();
        }
        emit Withdraw(redemptionEpochId, account, amount);
    }

    /* ----------------------------------------------------------------- */
    /*              External Owner Functions for Management              */
    /* ----------------------------------------------------------------- */

    /**
     * @inheritdoc IManagedVault
     */
    function setPrices(uint256 blockNumber, uint256 vaultPriceAtTheBlock, uint256 nativePriceAtTheBlock, IERC20[] calldata tokenAddresses, uint256[] calldata tokenPricesAtTheBlock) external onlyOwner {
        // Set the block number
        if (blockNumber >= block.number) {
            revert BlockNumberInTheFuture({blockNumber: blockNumber});
        }
        setPriceBlockNumber = blockNumber;

        // Set the vault token price
        if (vaultPrice != vaultPriceAtTheBlock) {
            vaultPrice = vaultPriceAtTheBlock;
            emit SetVaultPrice(blockNumber, vaultPrice);
        }
        // Updates accrued management fees and adjusts vaultPrice to account for the dilution
        _accrueManagementFee();

        // Set the native currency price
        if (nativePrice != nativePriceAtTheBlock) {
            nativePrice = nativePriceAtTheBlock;
            emit SetNativePrice(blockNumber, nativePrice);
        }

        // Set the token prices
        uint256 tokensCount = tokenDepositStates.length();
        for (uint256 tokenIndex = 0; tokenIndex < tokensCount;) {
            IERC20 depositTokenAddress = IERC20(tokenDepositStates.at(tokenIndex));
            // Check if the token addresses are in the exact order step by step
            if(depositTokenAddress != tokenAddresses[tokenIndex]) {
                revert InvalidTokenAddress({
                    givenTokenAddress: tokenAddresses[tokenIndex],
                    expectedTokenAddress: depositTokenAddress
                });
            }

            if (tokenPrices[depositTokenAddress] != tokenPricesAtTheBlock[tokenIndex]) {
                tokenPrices[depositTokenAddress] = tokenPricesAtTheBlock[tokenIndex];
                emit SetTokenPrice(blockNumber, depositTokenAddress, tokenPrices[depositTokenAddress]);
            }

            unchecked { tokenIndex++; }
        }
    }

    /**
     * @inheritdoc IManagedVault
     */
    function mint(uint256 maxMints) external onlyOwner returns (uint256 mintCount) {
        // Put storage variables on stack to avoid SLOAD operations in loops
        uint256 stackSetPriceBlockNumber = setPriceBlockNumber;
        uint256 stackVaultPrice = netVaultPrice();
        uint256 blockTimeStamp = block.timestamp;

        // Minting for the native currency (eg. ETH for the Ethereum Network)
        uint256 stackNativePrice = nativePrice;
        uint256 remainingPendingNativeDeposits = pendingNativeDeposits.length();
        if (nativeDepositState) {
            while (0 < remainingPendingNativeDeposits && mintCount < maxMints) {
                PendingDeposit.Item memory nextPendingDeposit = pendingNativeDeposits.peek();
                if (nextPendingDeposit.blockNumber > stackSetPriceBlockNumber) {
                    break;
                }

                pendingNativeDeposits.dequeue();
                unchecked { remainingPendingNativeDeposits--; }

                uint256 vaultTokenAmount = nextPendingDeposit.amount * stackNativePrice / stackVaultPrice;
                _mint(nextPendingDeposit.depositor, vaultTokenAmount);
                unchecked { mintCount++; }
                emit DepositMinted(nextPendingDeposit.depositor, vaultTokenAmount, blockTimeStamp, vaultPrice);
                
                // Performance fee logic
                performanceFeeEntrance += vaultTokenAmount * stackVaultPrice;
            }
        }

        // Minting for ERC20 tokens (eg. USDC, USDT)
        uint256 tokensCount = tokenDepositStates.length();
        for (uint256 tokenIndex = 0; tokenIndex < tokensCount;) {
            IERC20 depositTokenAddress = IERC20(tokenDepositStates.at(tokenIndex));
            uint256 stackTokenPrice = tokenPrices[depositTokenAddress];
            uint256 remainingPendingTokenDeposits = pendingTokenDeposits[depositTokenAddress].length();
            while (0 < remainingPendingTokenDeposits && mintCount < maxMints) {
                PendingDeposit.Item memory nextPendingDeposit = pendingTokenDeposits[depositTokenAddress].peek();
                if (nextPendingDeposit.blockNumber > stackSetPriceBlockNumber) {
                    break;
                }

                pendingTokenDeposits[depositTokenAddress].dequeue();
                unchecked { remainingPendingTokenDeposits--; }

                uint256 vaultTokenAmount = nextPendingDeposit.amount * stackTokenPrice / stackVaultPrice;
                _mint(nextPendingDeposit.depositor, vaultTokenAmount);
                unchecked { mintCount++; }
                emit DepositMinted(nextPendingDeposit.depositor, vaultTokenAmount, blockTimeStamp, vaultPrice);

                // Performance fee logic
                performanceFeeEntrance += vaultTokenAmount * stackVaultPrice;
            }

            unchecked { tokenIndex++; }
        }
    }

    /**
     * @inheritdoc IManagedVault
     */
    function rollRedemptionEpoch() external onlyOwner {
        uint256 redemptionEpochId = redemptionEpochs.length;
        IERC20 redemptionToken = nextRedemptionToken;
        uint256 redemptionTokenPrice = tokenPrices[nextRedemptionToken];
        uint256 netVaultPriceAfterFees = netVaultPrice() * (ONE_HUNDRED_PERCENT_BPS - redemptionFeeBPS) / ONE_HUNDRED_PERCENT_BPS;
        uint256 vaultTokenTotalAmount = nextRedemptionEpochVaultTokenTotalAmount;

        redemptionEpochs.push(
            RedemptionEpoch(
                RedemptionEpochState.Pending,
                redemptionToken,
                redemptionTokenPrice,
                netVaultPriceAfterFees,
                vaultTokenTotalAmount
            )
        );
        nextRedemptionEpochVaultTokenTotalAmount = 0;

        emit RollRedemptionEpoch(redemptionEpochId, redemptionToken, redemptionTokenPrice, netVaultPriceAfterFees, vaultTokenTotalAmount);
    }

    /**
     * @inheritdoc IManagedVault
     */
    function settleRedemptionEpoch(uint256 redemptionEpochId) external onlyOwner {
        RedemptionEpoch storage redemptionEpoch = redemptionEpochs[redemptionEpochId];
        require(redemptionEpoch.state == RedemptionEpochState.Pending);
        if (0 < redemptionEpochId) {
            require(redemptionEpochs[redemptionEpochId - 1].state == RedemptionEpochState.Settled, "previous epoch must be settled");
        }
        
        uint256 totalRedemptionTokenAmount = redemptionEpoch.vaultTokenTotalAmount * redemptionEpoch.netVaultPriceAfterFees / redemptionEpoch.redemptionTokenPrice;
        bool success = redemptionEpoch.redemptionToken.transferFrom(owner(), address(this), totalRedemptionTokenAmount);
        if (!success) {
            revert TransferFailed();
        }

        // Performance fee logic
        performanceFeeExit += redemptionEpoch.vaultTokenTotalAmount  * netVaultPrice();
        if (_performanceFeePnL() < 0) {
            // Only non-negative int256s could be converted to uint256 and there won't be any exceptions below.
            // performanceFeeExit, redemptionEpoch.vaultTokenTotalAmount, and totalSupply() are non-negative and _performanceFeePnL() is negative.
            // Therefore, performanceFeeExit - _performanceFeePnL() * redemptionEpoch.vaultTokenTotalAmount / totalSupply() is positive (or throws a division to zero exception).
            performanceFeeExit = uint256(int256(performanceFeeExit) - _performanceFeePnL() * int256(redemptionEpoch.vaultTokenTotalAmount) / int256(totalSupply()));
        }
        withdrawableVaultTokenTotalAmount += redemptionEpoch.vaultTokenTotalAmount;

        redemptionEpoch.state = RedemptionEpochState.Settled;
        emit SettleRedemptionEpoch(redemptionEpochId, redemptionEpoch.redemptionToken, totalRedemptionTokenAmount);
    }

    /**
     * @inheritdoc IManagedVault
     */
    function accruePerformanceFee(uint256 performanceFeePeriodCount) external onlyOwner {
        uint256 accrueWindowFirstTimestamp = performanceFeeInitiationTimestamp + (performanceFeePeriodCount + 1) * performanceFeePeriodSeconds;
        uint256 accrueWindowLastTimestamp = accrueWindowFirstTimestamp + performanceFeeAccrueWindowSeconds;
        if(block.timestamp < accrueWindowFirstTimestamp) revert EarlyPerformanceFeeAccrue(performanceFeePeriodCount, accrueWindowFirstTimestamp, block.timestamp);
        if(accrueWindowLastTimestamp < block.timestamp) revert LatePerformanceFeeAccrue(performanceFeePeriodCount, accrueWindowLastTimestamp, block.timestamp);

        uint256 accruedPerformanceFee = _accruablePerformanceFee() / netVaultPrice();
        uint256 actualGAV = grossAssetValue();
        performanceFeeAccruedVaultTokenAmount += accruedPerformanceFee;
        
        if (totalSupply() > 0) {
            vaultPrice = actualGAV / totalSupply();
        }

        if (_performanceFeePnL() < 0) {
            // Only non-negative int256s could be converted to uint256 and there won't be any exceptions below.
            // grossAssetValue() is non-negative and _performanceFeePnL() is negative.
            // Therefore, grossAssetValue() - _performanceFeePnL() is positive.
            performanceFeeEntrance = uint256(int256(grossAssetValue()) - _performanceFeePnL());
        } else {
            performanceFeeEntrance = grossAssetValue();
        }
        performanceFeeExit = 0;

        emit AccruePerformanceFee(performanceFeePeriodCount, accruedPerformanceFee);
    }

    /**
     * @inheritdoc IManagedVault
     */
    function mintPerformanceFee(address to, uint256 amount) external onlyOwner {
        require(amount <= performanceFeeAccruedVaultTokenAmount, "amount exceeds performanceFeeAccruedVaultTokenAmount");
        performanceFeeAccruedVaultTokenAmount -= amount;
        _mint(to, amount);
        emit MintPerformanceFee(to, amount);
    }

    /**
     * @inheritdoc IManagedVault
     */
    function mintManagementFee(address to, uint256 amount) external onlyOwner {
        require(amount <= managementFeeAccruedVaultTokenAmount, "amount exceeds managementFeeAccruedVaultTokenAmount");
        managementFeeAccruedVaultTokenAmount -= amount;
        _mint(to, amount);
        emit MintManagementFee(to, amount);
    }

    /* ----------------------------------------------------------------------- */
    /*              External Owner Functions for Deposit Settings              */
    /* ----------------------------------------------------------------------- */

    /**
     * @inheritdoc IManagedVault
     */
    function setNativeDepositState(bool state) external onlyOwner {
        require(nativeDepositState != state);

        nativeDepositState = state;

        emit SetNativeDepositState(state);
    }

    /**
     * @inheritdoc IManagedVault
     */
    function setTokenDepositState(IERC20 tokenAddress, bool state) external onlyOwner {
        if (tokenAddress == nextRedemptionToken) {
            require(state);
        }

        bool isUpdated;
        if (state) {
            isUpdated = tokenDepositStates.add(address(tokenAddress));
        } else {
            isUpdated = tokenDepositStates.remove(address(tokenAddress));
        }

        if (isUpdated) {
            emit SetTokenDepositState(tokenAddress, state);
        }
    }

    /**
     * @inheritdoc IManagedVault
     */
    function setNativeMinimumDepositAmount(uint256 amount) external onlyOwner {
        require(nativeMinimumDepositAmount != amount);

        nativeMinimumDepositAmount = amount;

        emit SetNativeMinimumDepositAmount(amount);
    }

    /**
     * @inheritdoc IManagedVault
     */
    function setTokenMinimumDepositAmount(IERC20 tokenAddress, uint256 amount) external onlyOwner {
        require(tokenMinimumDepositAmounts[tokenAddress] != amount);

        tokenMinimumDepositAmounts[tokenAddress] = amount;

        emit SetTokenMinimumDepositAmount(tokenAddress, amount);
    }

    /* -------------------------------------------------------------------------- */
    /*              External Owner Functions for Redemption Settings              */
    /* -------------------------------------------------------------------------- */

    /**
     * @inheritdoc IManagedVault
     */
    function setNextRedemptionToken(IERC20 tokenAddress) external onlyOwner {
        require(nextRedemptionToken != tokenAddress);
        require(tokenDepositStates.contains(address(tokenAddress)));

        nextRedemptionToken = tokenAddress;

        emit SetNextRedemptionToken(tokenAddress);
    }

    /**
     * @inheritdoc IManagedVault
     */
    function setRedemptionFeeBPS(uint256 bps) external onlyOwner {
        if (MAX_REDEMPTION_FEE_BPS < bps) revert InvalidRedemptionFeeBPS();
        require(redemptionFeeBPS != bps);

        redemptionFeeBPS = bps;

        emit SetRedemptionFeeBPS(bps);
    }

    /* ------------------------------------------------------------------------------ */
    /*              External Owner Functions for Management Fee Settings              */
    /* ------------------------------------------------------------------------------ */

    /**
     * @inheritdoc IManagedVault
     */
    function setManagementFeeBPS(uint256 bps) external onlyOwner {
        require(managementFeeBPS != bps);
        if (MAX_MANAGEMENT_FEE_BPS < bps) revert InvalidManagementFeeBPS();
        
        managementFeeBPS = bps;

        emit SetManagementFeeBPS(bps);
    }

    /* ------------------------------------------------------------------------------- */
    /*              External Owner Functions for Performance Fee Settings              */
    /* ------------------------------------------------------------------------------- */

    /**
     * @inheritdoc IManagedVault
     */
    function setPerformanceFeeBPS(uint256 bps) external onlyOwner {
        require(performanceFeeBPS != bps);
        if (MAX_PERFORMANCE_FEE_BPS < bps) revert InvalidPerformanceFeeBPS();
        
        performanceFeeBPS = bps;

        emit SetPerformanceFeeBPS(bps);
    }

    /**
     * @inheritdoc IManagedVault
     */
    function setPerformanceFeePeriodSeconds(uint256 duration) external onlyOwner {
        require(performanceFeePeriodSeconds != duration);

        performanceFeePeriodSeconds = duration;

        emit SetPerformanceFeePeriodSeconds(duration);
    }

    /**
     * @inheritdoc IManagedVault
     */
    function setPerformanceFeeAccrueWindowSeconds(uint256 duration) external onlyOwner {
        require(performanceFeeAccrueWindowSeconds != duration);

        performanceFeeAccrueWindowSeconds = duration;

        emit SetPerformanceFeeAccrueWindowSeconds(duration);
    }

    /* --------------------------------------------------------------------- */
    /*              External Owner Functions for Administration              */
    /* --------------------------------------------------------------------- */

    /**
     * @inheritdoc IManagedVault
     */
    function pause() external onlyOwner {
        require(paused == false);
        paused = true;
        emit Paused();
    }

    /**
     * @inheritdoc IManagedVault
     */
    function unpause() external onlyOwner {
        require(paused == true);
        paused = false;
        emit Unpaused();
    }

    /**
     * @inheritdoc IManagedVault
     */
    function invoke(address target, bytes calldata data, uint256 value) external onlyOwner returns (bytes memory returnValue) {
        returnValue = target.functionCallWithValue(data, value);
        emit Invoked(target, value, data, returnValue);
    }

    /* ------------------------------------------------- */
    /*              External View Functions              */
    /* ------------------------------------------------- */

    /**
     * @inheritdoc IManagedVault
     */
    function tokenAdresses() external view returns (address[] memory tokenAddresses) {
        return tokenDepositStates.values();
    }

    /**
     * @inheritdoc IManagedVault
     */
    function pendingMintsCountAndAmount(uint256 maxMints) external view returns (uint256 count, uint256 amount) {
        if(maxMints == 0) {
            return(count, amount);
        }

        if (nativeDepositState) {
            for (uint256 i = 0; i < pendingNativeDeposits.length(); i++) {
                if (count == maxMints) {
                    return(count, amount);
                }

                PendingDeposit.Item memory pendingDeposit = pendingNativeDeposits.peekIndex(i);
                if (pendingDeposit.blockNumber > setPriceBlockNumber) {
                    break;
                }
                count++;
                amount += pendingDeposit.amount * nativePrice / vaultPrice;
            }
        }

        for (uint256 i = 0; i < tokenDepositStates.length(); i++) {
            IERC20 depositTokenAddress = IERC20(tokenDepositStates.at(i));
            uint256 tokenPrice = tokenPrices[depositTokenAddress];

            for (uint256 j = 0; j < pendingTokenDeposits[depositTokenAddress].length(); j++) {
                if (count == maxMints) {
                    return(count, amount);
                }

                PendingDeposit.Item memory pendingDeposit = pendingTokenDeposits[depositTokenAddress].peekIndex(j);
                if (pendingDeposit.blockNumber > setPriceBlockNumber) {
                    break;
                }
                count++;
                amount += pendingDeposit.amount * tokenPrice / vaultPrice;
            }
        }
    }

    /**
     * @inheritdoc IManagedVault
     */
    function pendingNativeDepositAmount(address depositor) external view returns (uint256 totalAmount) {
        for (uint256 i = 0; i < pendingNativeDeposits.length(); i++) {
            PendingDeposit.Item memory pendingDeposit = pendingNativeDeposits.peekIndex(i);
            if (pendingDeposit.depositor == depositor) {
                totalAmount += pendingDeposit.amount;
            }
        }
    }

    /**
     * @inheritdoc IManagedVault
     */
    function pendingTokenDepositAmount(address depositor, IERC20 tokenAddress) external view returns (uint256 totalAmount) {
        for (uint256 i = 0; i < pendingTokenDeposits[tokenAddress].length(); i++) {
            PendingDeposit.Item memory pendingDeposit = pendingTokenDeposits[tokenAddress].peekIndex(i);
            if (pendingDeposit.depositor == depositor) {
                totalAmount += pendingDeposit.amount;
            }
        }
    }

    /**
     * @inheritdoc IManagedVault
     */
    function totalPendingNativeDepositAmount(uint256 maxBlockNumber) external view returns (uint256 totalAmount) {
        for (uint256 i = 0; i < pendingNativeDeposits.length(); i++) {
            PendingDeposit.Item memory pendingDeposit = pendingNativeDeposits.peekIndex(i);
            if (pendingDeposit.blockNumber > maxBlockNumber) {
                break;
            }
            totalAmount += pendingDeposit.amount;
        }
    }

    /**
     * @inheritdoc IManagedVault
     */
    function totalPendingTokenDepositAmount(uint256 maxBlockNumber, IERC20 tokenAddress) external view returns (uint256 totalAmount) {
        for (uint256 i = 0; i < pendingTokenDeposits[tokenAddress].length(); i++) {
            PendingDeposit.Item memory pendingDeposit = pendingTokenDeposits[tokenAddress].peekIndex(i);
            if (pendingDeposit.blockNumber > maxBlockNumber) {
                break;
            }
            totalAmount += pendingDeposit.amount;
        }
    }

    /* ----------------------------------------------- */
    /*              Public View Functions              */
    /* ----------------------------------------------- */

    /**
     * @notice Returns the amount of free vault tokens owned by `account`. The definition of free here is unlocked or
     *         unlockable. If the account `redeem`s tokens, they are locked and these tokens can be unlocked until
     *         {rollRedemptionEpoch} is executed. After {rollRedemptionEpoch}, these tokens can no longer be unlocked
     *         so, they are deducted from balanceOf and can only be burned for withdrawal.
     *
     * @param account The account to query. Not including the accrued fees for the owner.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return super.balanceOf(account) - locks[account] + redemptions[redemptionEpochs.length][account];
    }

    /**
     * @notice Returns the amount of free vault tokens in circulation. The definition of free here is unlocked or
     *         unlockable. The redeemed tokens in previous redemptionEpochs cannot be unlocked. Therefore, they're not
     *         included in either {balanceOf} or {totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return super.totalSupply() + performanceFeeAccruedVaultTokenAmount + managementFeeAccruedVaultTokenAmount - withdrawableVaultTokenTotalAmount;
    }

    /**
     * @notice Returns the gross asset value (not accounting for earned fees). Used in PNL and fee
     *         calculations.
     */
    function grossAssetValue() public view returns (uint256) {
        return vaultPrice * totalSupply();
    }

    /**
     * @notice Returns elapsed number of redemption epochs. The current epoch's number is set to this number when
     *         {rollRedemptionEpoch} is called.
     */
    function redemptionEpochsCount() public view returns (uint256) {
        return redemptionEpochs.length;
    }

    /**
     * @notice Returns the net vault price (accounting for earned fees). Mints and withdraws are executed at this
     *         price.
     */
    function netVaultPrice() public view returns (uint256) {
        if (0 < _performanceFeePnL()) {
            return vaultPrice - (_accruablePerformanceFee() / totalSupply());
        } else {
            return vaultPrice;
        }
    }

    /* -------------------------------------------- */
    /*              Internal Functions              */
    /* -------------------------------------------- */

    /**
     * @dev Locks the given amount of vault tokens for an account. Locked tokens are not transferrable.
     *
     * @param account The address of the account.
     * @param amount  The amount of tokens to be locked.
     */
    function _lock(address account, uint256 amount) internal {
        require(locks[account] + amount <= balanceOf(account), "insufficient balance");
        locks[account] += amount;
    }

    /**
     * @dev Unlocks the given amount of vault tokens for an account.
     *
     * @param account The address of the account.
     * @param amount  The amount of tokens to be unlocked.
     */
    function _unlock(address account, uint256 amount) internal {
        require(amount <= locks[account]);
        locks[account] -= amount;
    }

    /**
     * @dev Hook to check if vault token transfer amount exceeds free tokens.
     *
     * @param from   The sender address.
     * @param to     The destination address.
     * @param amount The amount of tokens to transfer.
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal whenNotPaused override {
        if (from != address(0)) {
            require(amount <= super.balanceOf(from) - locks[from], "Cannot transfer locked tokens");
        }
    }

    /**
     * @dev Calculates and updates accrued management fees based on grossAssetValue(). Executed during the mint()
     *      function call. It is crucial for contracts to run the required initializers for this function so that
     *      managementFeeLastUpdatedTimestamp is set properly.
     */
    function _accrueManagementFee() internal {
        uint256 numerator = totalSupply() * (block.timestamp - managementFeeLastUpdatedTimestamp) * managementFeeBPS;
        uint256 denominator = SECONDS_IN_A_YEAR * ONE_HUNDRED_PERCENT_BPS;
        uint256 newManagementFeeVaultTokenAmount = numerator / denominator;

        if (0 < newManagementFeeVaultTokenAmount) {
            uint256 actualGAV = grossAssetValue();
            managementFeeAccruedVaultTokenAmount += newManagementFeeVaultTokenAmount;
            vaultPrice = actualGAV / totalSupply();
        }
        managementFeeLastUpdatedTimestamp = block.timestamp;
    }

    /* ------------------------------------------------- */
    /*              Internal View Functions              */
    /* ------------------------------------------------- */

    /**
     * @dev Returns the total PNL of the vault. Used in performance fee calculations.
     */
    function _performanceFeePnL() internal view returns (int256) {
        return int256(grossAssetValue()) - int256(performanceFeeEntrance) + int256(performanceFeeExit);
    }

    /**
     * @dev Returns the amount of vault tokens accrued as performance fee since the last fee update.
     */
    function _accruablePerformanceFee() internal view returns (uint256) {
        if (0 < _performanceFeePnL()) {
            return uint256(_performanceFeePnL()) * performanceFeeBPS / ONE_HUNDRED_PERCENT_BPS;
        } else {
            return 0;
        }
    }
}