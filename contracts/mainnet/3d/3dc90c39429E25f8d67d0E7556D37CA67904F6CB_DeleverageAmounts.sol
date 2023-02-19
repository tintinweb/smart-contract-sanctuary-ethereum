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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822Proxiable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/ERC1967/ERC1967Proxy.sol)

pragma solidity ^0.8.0;

import "../Proxy.sol";
import "./ERC1967Upgrade.sol";

/**
 * @dev This contract implements an upgradeable proxy. It is upgradeable because calls are delegated to an
 * implementation address that can be changed. This address is stored in storage in the location specified by
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967], so that it doesn't conflict with the storage layout of the
 * implementation behind the proxy.
 */
contract ERC1967Proxy is Proxy, ERC1967Upgrade {
    /**
     * @dev Initializes the upgradeable proxy with an initial implementation specified by `_logic`.
     *
     * If `_data` is nonempty, it's used as data in a delegate call to `_logic`. This will typically be an encoded
     * function call, and allows initializing the storage of the proxy like a Solidity constructor.
     */
    constructor(address _logic, bytes memory _data) payable {
        _upgradeToAndCall(_logic, _data, false);
    }

    /**
     * @dev Returns the current implementation address.
     */
    function _implementation() internal view virtual override returns (address impl) {
        return ERC1967Upgrade._getImplementation();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeacon.sol";
import "../../interfaces/draft-IERC1822.sol";
import "../../utils/Address.sol";
import "../../utils/StorageSlot.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967Upgrade {
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlot.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822Proxiable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlot.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlot.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlot.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(Address.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            Address.isContract(IBeacon(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlot.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(IBeacon(newBeacon).implementation(), data);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/Proxy.sol)

pragma solidity ^0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overridden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overridden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/transparent/ProxyAdmin.sol)

pragma solidity ^0.8.0;

import "./TransparentUpgradeableProxy.sol";
import "../../access/Ownable.sol";

/**
 * @dev This is an auxiliary contract meant to be assigned as the admin of a {TransparentUpgradeableProxy}. For an
 * explanation of why you would want to use this see the documentation for {TransparentUpgradeableProxy}.
 */
contract ProxyAdmin is Ownable {
    /**
     * @dev Returns the current implementation of `proxy`.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function getProxyImplementation(TransparentUpgradeableProxy proxy) public view virtual returns (address) {
        // We need to manually run the static call since the getter cannot be flagged as view
        // bytes4(keccak256("implementation()")) == 0x5c60da1b
        (bool success, bytes memory returndata) = address(proxy).staticcall(hex"5c60da1b");
        require(success);
        return abi.decode(returndata, (address));
    }

    /**
     * @dev Returns the current admin of `proxy`.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function getProxyAdmin(TransparentUpgradeableProxy proxy) public view virtual returns (address) {
        // We need to manually run the static call since the getter cannot be flagged as view
        // bytes4(keccak256("admin()")) == 0xf851a440
        (bool success, bytes memory returndata) = address(proxy).staticcall(hex"f851a440");
        require(success);
        return abi.decode(returndata, (address));
    }

    /**
     * @dev Changes the admin of `proxy` to `newAdmin`.
     *
     * Requirements:
     *
     * - This contract must be the current admin of `proxy`.
     */
    function changeProxyAdmin(TransparentUpgradeableProxy proxy, address newAdmin) public virtual onlyOwner {
        proxy.changeAdmin(newAdmin);
    }

    /**
     * @dev Upgrades `proxy` to `implementation`. See {TransparentUpgradeableProxy-upgradeTo}.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function upgrade(TransparentUpgradeableProxy proxy, address implementation) public virtual onlyOwner {
        proxy.upgradeTo(implementation);
    }

    /**
     * @dev Upgrades `proxy` to `implementation` and calls a function on the new implementation. See
     * {TransparentUpgradeableProxy-upgradeToAndCall}.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function upgradeAndCall(
        TransparentUpgradeableProxy proxy,
        address implementation,
        bytes memory data
    ) public payable virtual onlyOwner {
        proxy.upgradeToAndCall{value: msg.value}(implementation, data);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/transparent/TransparentUpgradeableProxy.sol)

pragma solidity ^0.8.0;

import "../ERC1967/ERC1967Proxy.sol";

/**
 * @dev This contract implements a proxy that is upgradeable by an admin.
 *
 * To avoid https://medium.com/nomic-labs-blog/malicious-backdoors-in-ethereum-proxies-62629adf3357[proxy selector
 * clashing], which can potentially be used in an attack, this contract uses the
 * https://blog.openzeppelin.com/the-transparent-proxy-pattern/[transparent proxy pattern]. This pattern implies two
 * things that go hand in hand:
 *
 * 1. If any account other than the admin calls the proxy, the call will be forwarded to the implementation, even if
 * that call matches one of the admin functions exposed by the proxy itself.
 * 2. If the admin calls the proxy, it can access the admin functions, but its calls will never be forwarded to the
 * implementation. If the admin tries to call a function on the implementation it will fail with an error that says
 * "admin cannot fallback to proxy target".
 *
 * These properties mean that the admin account can only be used for admin actions like upgrading the proxy or changing
 * the admin, so it's best if it's a dedicated account that is not used for anything else. This will avoid headaches due
 * to sudden errors when trying to call a function from the proxy implementation.
 *
 * Our recommendation is for the dedicated account to be an instance of the {ProxyAdmin} contract. If set up this way,
 * you should think of the `ProxyAdmin` instance as the real administrative interface of your proxy.
 */
contract TransparentUpgradeableProxy is ERC1967Proxy {
    /**
     * @dev Initializes an upgradeable proxy managed by `_admin`, backed by the implementation at `_logic`, and
     * optionally initialized with `_data` as explained in {ERC1967Proxy-constructor}.
     */
    constructor(
        address _logic,
        address admin_,
        bytes memory _data
    ) payable ERC1967Proxy(_logic, _data) {
        _changeAdmin(admin_);
    }

    /**
     * @dev Modifier used internally that will delegate the call to the implementation unless the sender is the admin.
     */
    modifier ifAdmin() {
        if (msg.sender == _getAdmin()) {
            _;
        } else {
            _fallback();
        }
    }

    /**
     * @dev Returns the current admin.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-getProxyAdmin}.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
     * https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103`
     */
    function admin() external ifAdmin returns (address admin_) {
        admin_ = _getAdmin();
    }

    /**
     * @dev Returns the current implementation.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-getProxyImplementation}.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
     * https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
     */
    function implementation() external ifAdmin returns (address implementation_) {
        implementation_ = _implementation();
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-changeProxyAdmin}.
     */
    function changeAdmin(address newAdmin) external virtual ifAdmin {
        _changeAdmin(newAdmin);
    }

    /**
     * @dev Upgrade the implementation of the proxy.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-upgrade}.
     */
    function upgradeTo(address newImplementation) external ifAdmin {
        _upgradeToAndCall(newImplementation, bytes(""), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy, and then call a function from the new implementation as specified
     * by `data`, which should be an encoded function call. This is useful to initialize new storage variables in the
     * proxied contract.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-upgradeAndCall}.
     */
    function upgradeToAndCall(address newImplementation, bytes calldata data) external payable ifAdmin {
        _upgradeToAndCall(newImplementation, data, true);
    }

    /**
     * @dev Returns the current admin.
     */
    function _admin() internal view virtual returns (address) {
        return _getAdmin();
    }

    /**
     * @dev Makes sure the admin cannot access the fallback function. See {Proxy-_beforeFallback}.
     */
    function _beforeFallback() internal virtual override {
        require(msg.sender != _getAdmin(), "TransparentUpgradeableProxy: admin cannot fallback to proxy target");
        super._beforeFallback();
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./variables.sol";

contract Events is Variables {
    event updateAuthLog(address auth_);

    event updateRebalancerLog(address auth_, bool isAuth_);

    event updateRatiosLog(
        uint16 maxLimit,
        uint16 minLimit,
        uint16 gap,
        uint128 maxBorrowRate
    );

    event updateFeesLog(
        uint256 revenueFee_,
        uint256 withdrawalFee_,
        uint256 swapFee_,
        uint256 deleverageFee_
    );

    event changeStatusLog(uint256 status_);

    event supplyLog(address token_, uint256 amount_, address to_);

    event withdrawLog(uint256 amount_, address to_);

    event leverageLog(uint256 amt_, uint256 transferAmt_);

    event deleverageLog(uint256 amt_, uint256 transferAmt_);

    event deleverageAndWithdrawLog(
        uint256 deleverageAmt_,
        uint256 transferAmt_,
        uint256 vtokenAmount_,
        address to_
    );

    event importLog(
        address flashTkn_,
        uint256 flashAmt_,
        uint256 route_,
        address to_,
        uint256 stEthAmt_,
        uint256 wethAmt_
    );

    event rebalanceOneLog(
        address flashTkn_,
        uint256 flashAmt_,
        uint256 route_,
        address[] vaults_,
        uint256[] amts_,
        uint256 excessDebt_,
        uint256 paybackDebt_,
        uint256 totalAmountToSwap_,
        uint256 extraWithdraw_,
        uint256 unitAmt_
    );

    event rebalanceTwoLog(
        uint256 withdrawAmt_,
        address flashTkn_,
        uint256 flashAmt_,
        uint256 route_,
        uint256 saveAmt_,
        uint256 unitAmt_
    );

    event collectRevenueLog(
        uint256 amount_,
        uint256 stethAmt_,
        uint256 wethAmt_,
        address to_
    );
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./events.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Helpers is Events {
    using SafeERC20 for IERC20;

    modifier nonReentrant() {
        require(_status != 2, "ReentrancyGuard: reentrant call");
        _status = 2;
        _;
        _status = 1;
    }

    /**
     * @dev Helper function to get current eth borrow rate on aave.
     */
    function getWethBorrowRate()
        internal
        view
        returns (uint256 wethBorrowRate_)
    {
        (, , , , wethBorrowRate_, , , , , ) = aaveProtocolDataProvider
            .getReserveData(wethAddr);
    }

    /**
     * @dev Helper function to get current steth collateral on aave.
     */
    function getStEthCollateralAmount()
        internal
        view
        returns (uint256 stEthAmount_)
    {
        stEthAmount_ = astethToken.balanceOf(address(vaultDsa));
    }

    /**
     * @dev Helper function to get current eth debt on aave.
     */
    function getWethDebtAmount()
        internal
        view
        returns (uint256 wethDebtAmount_)
    {
        wethDebtAmount_ = awethVariableDebtToken.balanceOf(address(vaultDsa));
    }

    struct BalVariables {
        uint256 wethVaultBal;
        uint256 wethDsaBal;
        uint256 stethVaultBal;
        uint256 stethDsaBal;
        uint256 totalBal;
    }

    /**
     * @dev Helper function to get ideal eth/steth amount in vault or vault's dsa.
     */
    function getIdealBalances()
        public
        view
        returns (BalVariables memory balances_)
    {
        balances_.wethVaultBal = wethContract.balanceOf(address(this));
        balances_.wethDsaBal = wethContract.balanceOf(address(vaultDsa));
        balances_.stethVaultBal = stEthContract.balanceOf(address(this));
        balances_.stethDsaBal = stEthContract.balanceOf(address(vaultDsa));
        balances_.totalBal =
            balances_.wethVaultBal +
            balances_.wethDsaBal +
            balances_.stethVaultBal +
            balances_.stethDsaBal;
    }

    /**
     * @dev Helper function to get net assets everywhere (not substracting revenue here).
     */
    function netAssets()
        public
        view
        returns (
            uint256 netCollateral_,
            uint256 netBorrow_,
            BalVariables memory balances_,
            uint256 netSupply_,
            uint256 netBal_
        )
    {
        netCollateral_ = getStEthCollateralAmount();
        netBorrow_ = getWethDebtAmount();
        balances_ = getIdealBalances();
        netSupply_ = netCollateral_ + balances_.totalBal;
        netBal_ = netSupply_ - netBorrow_;
    }

    /**
     * @dev Helper function to get current exchange price and new revenue generated.
     */
    function getCurrentExchangePrice()
        public
        view
        returns (uint256 exchangePrice_, uint256 newRevenue_)
    {
        (, , , , uint256 netBal_) = netAssets();
        netBal_ = netBal_ - revenue;
        uint256 totalSupply_ = totalSupply();
        uint256 exchangePriceWithRevenue_;
        if (totalSupply_ != 0) {
            exchangePriceWithRevenue_ = (netBal_ * 1e18) / totalSupply_;
        } else {
            exchangePriceWithRevenue_ = 1e18;
        }
        // Only calculate revenue if there's a profit
        if (exchangePriceWithRevenue_ > lastRevenueExchangePrice) {
            uint256 newProfit_ = netBal_ -
                ((lastRevenueExchangePrice * totalSupply_) / 1e18);
            newRevenue_ = (newProfit_ * revenueFee) / 10000;
            exchangePrice_ = ((netBal_ - newRevenue_) * 1e18) / totalSupply_;
        } else {
            exchangePrice_ = exchangePriceWithRevenue_;
        }
    }

    /**
     * @dev Helper function to validate the safety of aave position after rebalancing.
     */
    function validateFinalRatio()
        internal
        view
        returns (
            bool maxIsOk_,
            bool maxGapIsOk_,
            bool minIsOk_,
            bool minGapIsOk_,
            bool hfIsOk_
        )
    {
        // Not substracting revenue here as it can also help save position.
        (,,,,,uint hf_) = aaveLendingPool.getUserAccountData(address(vaultDsa));
        (
            uint256 netCollateral_,
            uint256 netBorrow_,
            ,
            uint256 netSupply_,

        ) = netAssets();
        uint256 ratioMax_ = (netBorrow_ * 1e4) / netCollateral_; // Aave position ratio should not go above max limit
        maxIsOk_ = ratios.maxLimit > ratioMax_;
        maxGapIsOk_ = ratioMax_ > ratios.maxLimit - 100;
        uint256 ratioMin_ = (netBorrow_ * 1e4) / netSupply_; // net ratio (position + ideal) should not go above min limit
        minIsOk_ = ratios.minLimit > ratioMin_;
        minGapIsOk_ = ratios.minLimitGap < ratioMin_;
        hfIsOk_ = hf_ > 1015 * 1e15; // HF should be more than 1.015 (this will allow ratio to always stay below 74%)
    }

}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IInstaIndex {
    function build(
        address owner_,
        uint256 accountVersion_,
        address origin_
    ) external returns (address account_);
}

interface IDSA {
    function cast(
        string[] calldata _targetNames,
        bytes[] calldata _datas,
        address _origin
    ) external payable returns (bytes32);
}

interface IAaveProtocolDataProvider {
    function getReserveData(address asset)
        external
        view
        returns (
            uint256 availableLiquidity,
            uint256 totalStableDebt,
            uint256 totalVariableDebt,
            uint256 liquidityRate,
            uint256 variableBorrowRate,
            uint256 stableBorrowRate,
            uint256 averageStableBorrowRate,
            uint256 liquidityIndex,
            uint256 variableBorrowIndex,
            uint40 lastUpdateTimestamp
        );
}

interface AavePoolProviderInterface {
    function getLendingPool() external view returns (address);
}

interface TokenInterface {
    function approve(address, uint256) external;

    function transfer(address, uint256) external;

    function transferFrom(
        address,
        address,
        uint256
    ) external;

    function deposit() external payable;

    function withdraw(uint256) external;

    function balanceOf(address) external view returns (uint256);

    function decimals() external view returns (uint256);

    function totalSupply() external view returns (uint256);
}

interface IAaveLendingPool {
    function getUserAccountData(address) external view returns (uint256, uint256, uint256, uint256, uint256, uint256);
}

interface IInstaList {
    function accountID(address) external view returns (uint64);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title InstaLite.
 * @dev InstaLite Vault 1.
 */

import "./helpers.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract AdminModule is Helpers {
    using SafeERC20 for IERC20;

    /**
     * @dev Only auth gaurd.
     */
    modifier onlyAuth() {
        require(auth == msg.sender, "only auth");
        _;
    }

    /**
     * @dev Only rebalancer gaurd.
     */
    modifier onlyRebalancer() {
        require(
            isRebalancer[msg.sender] || auth == msg.sender,
            "only rebalancer"
        );
        _;
    }

    /**
     * @dev Update auth.
     * @param auth_ address of new auth.
     */
    function updateAuth(address auth_) external onlyAuth {
        auth = auth_;
        emit updateAuthLog(auth_);
    }

    /**
     * @dev Update rebalancer.
     * @param rebalancer_ address of rebalancer.
     * @param isRebalancer_ true for setting the rebalancer, false for removing.
     */
    function updateRebalancer(address rebalancer_, bool isRebalancer_)
        external
        onlyAuth
    {
        isRebalancer[rebalancer_] = isRebalancer_;
        emit updateRebalancerLog(rebalancer_, isRebalancer_);
    }

    /**
     * @dev Update all fees.
     * @param revenueFee_ new revenue fee.
     * @param withdrawalFee_ new withdrawal fee.
     * @param swapFee_ new swap fee or leverage fee.
     * @param deleverageFee_ new deleverage fee.
     */
    function updateFees(
        uint256 revenueFee_,
        uint256 withdrawalFee_,
        uint256 swapFee_,
        uint256 deleverageFee_
    ) external onlyAuth {
        require(revenueFee_ < 10000, "fees-not-valid");
        require(withdrawalFee_ < 10000, "fees-not-valid");
        require(swapFee_ < 10000, "fees-not-valid");
        require(deleverageFee_ < 10000, "fees-not-valid");
        revenueFee = revenueFee_;
        withdrawalFee = withdrawalFee_;
        swapFee = swapFee_;
        deleverageFee = deleverageFee_;
        emit updateFeesLog(
            revenueFee_,
            withdrawalFee_,
            swapFee_,
            deleverageFee_
        );
    }

    /**
     * @dev Update ratios.
     * @param ratios_ new ratios.
     */
    function updateRatios(uint16[] memory ratios_) external onlyAuth {
        ratios = Ratios(
            ratios_[0],
            ratios_[1],
            ratios_[2],
            uint128(ratios_[3]) * 1e23
        );
        emit updateRatiosLog(
            ratios_[0],
            ratios_[1],
            ratios_[2],
            uint128(ratios_[3]) * 1e23
        );
    }

    /**
     * @dev Change status.
     * @param status_ new status, function to pause all functionality of the contract, status = 2 -> pause, status = 1 -> resume.
     */
    function changeStatus(uint256 status_) external onlyAuth {
        _status = status_;
        emit changeStatusLog(status_);
    }

    /**
     * @dev Admin function to supply any token as collateral to save aave position from liquidation in case of adverse market conditions.
     * @param token_ token to supply
     * @param amount_ amount to supply
     */
    // function supplyToken(address token_, uint256 amount_) external onlyAuth {
    //     IERC20(token_).safeTransferFrom(msg.sender, address(vaultDsa), amount_);
    //     string[] memory targets_ = new string[](1);
    //     bytes[] memory calldata_ = new bytes[](1);
    //     targets_[0] = "AAVE-V2-A";
    //     calldata_[0] = abi.encodeWithSignature(
    //         "deposit(address,uint256,uint256,uint256)",
    //         token_,
    //         amount_,
    //         0,
    //         0
    //     );
    //     vaultDsa.cast(targets_, calldata_, address(this));
    // }

    /**
     * @dev Admin function to withdraw token from aave
     * @param token_ token to withdraw
     * @param amount_ amount to withdraw
     */
    // function withdrawToken(address token_, uint256 amount_) external onlyAuth {
    //     string[] memory targets_ = new string[](2);
    //     bytes[] memory calldata_ = new bytes[](2);
    //     targets_[0] = "AAVE-V2-A";
    //     calldata_[0] = abi.encodeWithSignature(
    //         "withdraw(address,uint256,uint256,uint256)",
    //         token_,
    //         amount_,
    //         0,
    //         0
    //     );
    //     targets_[1] = "BASIC-A";
    //     calldata_[1] = abi.encodeWithSignature(
    //         "withdraw(address,uint256,address,uint256,uint256)",
    //         token_,
    //         amount_,
    //         auth,
    //         0,
    //         0
    //     );
    //     vaultDsa.cast(targets_, calldata_, address(this));
    // }

    /**
     * @dev Admin Spell function
     * @param to_ target address
     * @param calldata_ function calldata
     * @param value_ function msg.value
     * @param operation_ .call or .delegate. (0 => .call, 1 => .delegateCall)
     */
    function spell(
        address to_,
        bytes memory calldata_,
        uint256 value_,
        uint256 operation_
    ) external payable onlyAuth {
        if (operation_ == 0) {
            // .call
            Address.functionCallWithValue(
                to_,
                calldata_,
                value_,
                "spell: .call failed"
            );
        } else if (operation_ == 1) {
            // .delegateCall
            Address.functionDelegateCall(
                to_,
                calldata_,
                "spell: .delegateCall failed"
            );
        } else {
            revert("no operation");
        }
    }

    /**
     * @dev Admin function to add auth on DSA
     * @param auth_ new auth address for DSA
     */
    function addDSAAuth(address auth_) external onlyAuth {
        string[] memory targets_ = new string[](1);
        bytes[] memory calldata_ = new bytes[](1);
        targets_[0] = "AUTHORITY-A";
        calldata_[0] = abi.encodeWithSignature("add(address)", auth_);
        vaultDsa.cast(targets_, calldata_, address(this));
    }
}

contract CoreHelpers is AdminModule {
    using SafeERC20 for IERC20;

    /**
     * @dev Update storage.
     * @notice Internal function to update storage.
     */
    function updateStorage(uint256 exchangePrice_, uint256 newRevenue_)
        internal
    {
        if (exchangePrice_ > lastRevenueExchangePrice) {
            lastRevenueExchangePrice = exchangePrice_;
            revenue = revenue + newRevenue_;
        }
    }

    /**
     * @dev internal function which handles supplies.
     */
    function supplyInternal(
        address token_,
        uint256 amount_,
        address to_,
        bool isEth_
    ) internal returns (uint256 vtokenAmount_) {
        require(amount_ != 0, "amount cannot be zero");
        (
            uint256 exchangePrice_,
            uint256 newRevenue_
        ) = getCurrentExchangePrice();
        updateStorage(exchangePrice_, newRevenue_);
        if (isEth_) {
            wethCoreContract.deposit{value: amount_}();
        } else {
            require(token_ == stEthAddr || token_ == wethAddr, "wrong-token");
            IERC20(token_).safeTransferFrom(msg.sender, address(this), amount_);
        }
        vtokenAmount_ = (amount_ * 1e18) / exchangePrice_;
        _mint(to_, vtokenAmount_);
    }

    /**
     * @dev Withdraw helper.
     */
    function withdrawHelper(uint256 amount_, uint256 limit_)
        internal
        pure
        returns (uint256, uint256)
    {
        uint256 transferAmt_;
        if (limit_ > amount_) {
            transferAmt_ = amount_;
            amount_ = 0;
        } else {
            transferAmt_ = limit_;
            amount_ = amount_ - limit_;
        }
        return (amount_, transferAmt_);
    }

    /**
     * @dev Withdraw final.
     */
    function withdrawFinal(uint256 amount_, bool afterDeleverage_)
        public
        view
        returns (uint256[] memory transferAmts_)
    {
        require(amount_ > 0, "amount-invalid");

        (
            uint256 netCollateral_,
            uint256 netBorrow_,
            BalVariables memory balances_,
            ,

        ) = netAssets();

        uint256 margin_ = afterDeleverage_ ? 5 : 10; // 0.05% margin or  0.1% margin
        uint256 colCoveringDebt_ = ((netBorrow_ * 10000) /
            (ratios.maxLimit - margin_));
        uint256 netColLimit_ = netCollateral_ > colCoveringDebt_
            ? netCollateral_ - colCoveringDebt_
            : 0;

        require(
            amount_ < (balances_.totalBal + netColLimit_),
            "excess-withdrawal"
        );

        transferAmts_ = new uint256[](5);
        if (balances_.wethVaultBal > 10) {
            (amount_, transferAmts_[0]) = withdrawHelper(
                amount_,
                balances_.wethVaultBal
            );
        }
        if (balances_.wethDsaBal > 10 && amount_ > 0) {
            (amount_, transferAmts_[1]) = withdrawHelper(
                amount_,
                balances_.wethDsaBal
            );
        }
        if (balances_.stethVaultBal > 10 && amount_ > 0) {
            (amount_, transferAmts_[2]) = withdrawHelper(
                amount_,
                balances_.stethVaultBal
            );
        }
        if (balances_.stethDsaBal > 10 && amount_ > 0) {
            (amount_, transferAmts_[3]) = withdrawHelper(
                amount_,
                balances_.stethDsaBal
            );
        }
        if (netColLimit_ > 10 && amount_ > 0) {
            (amount_, transferAmts_[4]) = withdrawHelper(amount_, netColLimit_);
        }
    }

    /**
     * @dev Function to handle withdraw related transfers.
     */
    function withdrawTransfers(uint256 amount_, uint256[] memory transferAmts_)
        internal
        returns (uint256 wethAmt_, uint256 stEthAmt_)
    {
        wethAmt_ = transferAmts_[0] + transferAmts_[1];
        stEthAmt_ = transferAmts_[2] + transferAmts_[3] + transferAmts_[4];
        uint256 totalTransferAmount_ = wethAmt_ + stEthAmt_;
        require(amount_ == totalTransferAmount_, "transfers-not-valid");
        // batching up spells and withdrawing all the required asset from DSA to vault at once
        uint256 i;
        uint256 j;
        if (transferAmts_[4] > 0) j += 1;
        if (transferAmts_[1] > 0) j += 1;
        if (transferAmts_[3] > 0 || transferAmts_[4] > 0) j += 1;
        if (j == 0) return (wethAmt_, stEthAmt_);
        string[] memory targets_ = new string[](j);
        bytes[] memory calldata_ = new bytes[](j);
        if (transferAmts_[4] > 0) {
            targets_[i] = "AAVE-V2-A";
            calldata_[i] = abi.encodeWithSignature(
                "withdraw(address,uint256,uint256,uint256)",
                stEthAddr,
                transferAmts_[4],
                0,
                0
            );
            i++;
        }
        if (transferAmts_[1] > 0) {
            targets_[i] = "BASIC-A";
            calldata_[i] = abi.encodeWithSignature(
                "withdraw(address,uint256,address,uint256,uint256)",
                wethAddr,
                transferAmts_[1],
                address(this),
                0,
                0
            );
            i++;
        }
        if (transferAmts_[3] > 0 || transferAmts_[4] > 0) {
            targets_[i] = "BASIC-A";
            calldata_[i] = abi.encodeWithSignature(
                "withdraw(address,uint256,address,uint256,uint256)",
                stEthAddr,
                transferAmts_[3] + transferAmts_[4],
                address(this),
                0,
                0
            );
            i++;
        }
        if (j > 0) vaultDsa.cast(targets_, calldata_, address(this));
    }

    /**
     * @dev Internal functions to handle withdrawals.
     */
    function withdrawInternal(
        uint256 amount_,
        address to_,
        bool afterDeleverage_
    ) internal returns (uint256 vtokenAmount_) {
        require(amount_ != 0, "amount cannot be zero");

        (
            uint256 exchangePrice_,
            uint256 newRevenue_
        ) = getCurrentExchangePrice();
        updateStorage(exchangePrice_, newRevenue_);

        if (amount_ == type(uint256).max) {
            vtokenAmount_ = balanceOf(msg.sender); // vToken amount would be the net asset(steth inital deposited)
            amount_ = (vtokenAmount_ * exchangePrice_) / 1e18;
        } else {
            vtokenAmount_ = (amount_ * 1e18) / exchangePrice_;
        }

        _burn(msg.sender, vtokenAmount_);
        uint256 fee_ = (amount_ * withdrawalFee) / 10000;
        uint256 amountAfterFee_ = amount_ - fee_;

        uint256[] memory transferAmts_ = withdrawFinal(
            amountAfterFee_,
            afterDeleverage_
        );

        (uint256 wethAmt_, uint256 stEthAmt_) = withdrawTransfers(
            amountAfterFee_,
            transferAmts_
        );
        (bool maxIsOk_, , , , bool hfIsOk_) = validateFinalRatio();

        require(maxIsOk_ && hfIsOk_, "Aave-position-risky");

        if (wethAmt_ > 0) {
            // withdraw weth and sending ETH to user
            wethCoreContract.withdraw(wethAmt_);
            Address.sendValue(payable(to_), wethAmt_);
        }
        if (stEthAmt_ > 0) stEthContract.safeTransfer(to_, stEthAmt_);

        if (afterDeleverage_) {
            (, , , bool minGapIsOk_, ) = validateFinalRatio();
            require(minGapIsOk_, "Aave-position-risky");
        }
    }

    /**
     * @dev Internal functions for deleverge logics.
     */
    function deleverageInternal(uint256 amt_)
        internal
        returns (uint256 transferAmt_)
    {
        require(amt_ > 0, "not-valid-amount");
        wethContract.safeTransferFrom(msg.sender, address(vaultDsa), amt_);

        bool isDsa_ = instaList.accountID(msg.sender) > 0;

        uint256 i;
        uint256 j = isDsa_ ? 2 : 3;
        string[] memory targets_ = new string[](j);
        bytes[] memory calldata_ = new bytes[](j);
        targets_[0] = "AAVE-V2-A";
        calldata_[0] = abi.encodeWithSignature(
            "payback(address,uint256,uint256,uint256,uint256)",
            wethAddr,
            amt_,
            2,
            0,
            0
        );
        if (!isDsa_) {
            transferAmt_ = amt_ + ((amt_ * deleverageFee) / 10000);
            targets_[1] = "AAVE-V2-A";
            calldata_[1] = abi.encodeWithSignature(
                "withdraw(address,uint256,uint256,uint256)",
                stEthAddr,
                transferAmt_,
                0,
                0
            );
            i = 2;
        } else {
            transferAmt_ = amt_;
            i = 1;
        }
        targets_[i] = "BASIC-A";
        calldata_[i] = abi.encodeWithSignature(
            "withdraw(address,uint256,address,uint256,uint256)",
            isDsa_ ? address(astethToken) : stEthAddr,
            transferAmt_,
            msg.sender,
            0,
            0
        );
        vaultDsa.cast(targets_, calldata_, address(this));
    }
}

contract InstaVaultImplementation is CoreHelpers {
    using SafeERC20 for IERC20;

    /**
     * @dev Supply Eth.
     * @param to_ address to send vTokens to.
     * @return vtokenAmount_ amount of vTokens sent to the `to_` address passed
     */
    function supplyEth(address to_)
        external
        payable
        nonReentrant
        returns (uint256 vtokenAmount_)
    {
        uint256 amount_ = msg.value;
        vtokenAmount_ = supplyInternal(ethAddr, amount_, to_, true);
        emit supplyLog(ethAddr, amount_, to_);
    }

    /**
     * @dev User function to supply (WETH or STETH).
     * @param token_ address of token, steth or weth.
     * @param amount_ amount to supply.
     * @param to_ address to send vTokens to.
     * @return vtokenAmount_ amount of vTokens sent to the `to_` address passed
     */
    function supply(
        address token_,
        uint256 amount_,
        address to_
    ) external nonReentrant returns (uint256 vtokenAmount_) {
        vtokenAmount_ = supplyInternal(token_, amount_, to_, false);
        emit supplyLog(token_, amount_, to_);
    }

    /**
     * @dev User function to withdraw (to get ETH or STETH).
     * @param amount_ amount to withdraw.
     * @param to_ address to send tokens to.
     * @return vtokenAmount_ amount of vTokens burnt from caller
     */
    function withdraw(uint256 amount_, address to_)
        external
        nonReentrant
        returns (uint256 vtokenAmount_)
    {
        vtokenAmount_ = withdrawInternal(amount_, to_, false);
        emit withdrawLog(amount_, to_);
    }

    /**
     * @dev If ratio is below then this function will allow anyone to swap from steth -> weth.
     */
    function leverage(uint256 amt_) external nonReentrant {
        require(amt_ > 0, "not-valid-amount");
        uint256 fee_ = (amt_ * swapFee) / 10000;
        uint256 transferAmt_ = amt_ - fee_;
        revenue += fee_;

        stEthContract.safeTransferFrom(msg.sender, address(this), amt_);

        uint256 wethVaultBal_ = wethContract.balanceOf(address(this));
        uint256 stethVaultBal_ = stEthContract.balanceOf(address(this));

        if (wethVaultBal_ >= transferAmt_) {
            wethContract.safeTransfer(msg.sender, transferAmt_);
        } else {
            uint256 remainingTransferAmt_ = transferAmt_;
            if (wethVaultBal_ > 1e14) {
                remainingTransferAmt_ -= wethVaultBal_;
                wethContract.safeTransfer(msg.sender, wethVaultBal_);
            }
            uint256 i;
            uint256 j = 2;
            if (stethVaultBal_ > 1e14) {
                stEthContract.safeTransfer(address(vaultDsa), stethVaultBal_);
                j = 3;
            }
            string[] memory targets_ = new string[](j);
            bytes[] memory calldata_ = new bytes[](j);
            if (stethVaultBal_ > 1e14) {
                targets_[i] = "AAVE-V2-A";
                calldata_[i] = abi.encodeWithSignature(
                    "deposit(address,uint256,uint256,uint256)",
                    stEthAddr,
                    stethVaultBal_,
                    0,
                    0
                );
                i++;
            }
            targets_[i] = "AAVE-V2-A";
            calldata_[i] = abi.encodeWithSignature(
                "borrow(address,uint256,uint256,uint256,uint256)",
                wethAddr,
                remainingTransferAmt_,
                2,
                0,
                0
            );
            targets_[i + 1] = "BASIC-A";
            calldata_[i + 1] = abi.encodeWithSignature(
                "withdraw(address,uint256,address,uint256,uint256)",
                wethAddr,
                remainingTransferAmt_,
                msg.sender,
                0,
                0
            );
            vaultDsa.cast(targets_, calldata_, address(this));
            (bool maxIsOk_, , bool minIsOk_, , ) = validateFinalRatio();
            require(minIsOk_ && maxIsOk_, "excess-leverage");
        }

        emit leverageLog(amt_, transferAmt_);
    }

    /**
     * @dev If ratio is above then this function will allow anyone to payback WETH and withdraw astETH to msg.sender at 1:1 ratio.
     */
    function deleverage(uint256 amt_) external nonReentrant {
        uint256 transferAmt_ = deleverageInternal(amt_);
        (, , , bool minGapIsOk_, ) = validateFinalRatio();
        require(minGapIsOk_, "excess-deleverage");

        emit deleverageLog(amt_, transferAmt_);
    }

    /**
     * @dev Function to allow max withdrawals.
     */
    function deleverageAndWithdraw(
        uint256 deleverageAmt_,
        uint256 withdrawAmount_,
        address to_
    ) external nonReentrant {
        uint256 transferAmt_ = deleverageInternal(deleverageAmt_); //transffered aSteth if DSA.
        uint256 vtokenAmt_ = withdrawInternal(withdrawAmount_, to_, true);

        emit deleverageAndWithdrawLog(
            deleverageAmt_,
            transferAmt_,
            vtokenAmt_,
            to_
        );
    }

    struct ImportPositionVariables {
        uint256 ratioLimit;
        uint256 importNetAmt;
        uint256 initialDsaAsteth;
        uint256 initialDsaWethDebt;
        uint256 finalDsaAsteth;
        uint256 finalDsaWethDebt;
        uint256 dsaDif;
        bytes encodedFlashData;
        string[] flashTarget;
        bytes[] flashCalldata;
        bool[] checks;
    }

    /**
     * @dev Function to import user's position from his/her DSA to vault.
     */
    function importPosition(
        address flashTkn_,
        uint256 flashAmt_,
        uint256 route_,
        address to_,
        uint256 stEthAmt_,
        uint256 wethAmt_
    ) external nonReentrant {
        ImportPositionVariables memory v_;

        stEthAmt_ = stEthAmt_ == type(uint256).max
            ? astethToken.balanceOf(msg.sender)
            : stEthAmt_;
        wethAmt_ = wethAmt_ == type(uint256).max
            ? awethVariableDebtToken.balanceOf(msg.sender)
            : wethAmt_;

        v_.importNetAmt = stEthAmt_ - wethAmt_;
        v_.ratioLimit = (wethAmt_ * 1e4) / stEthAmt_;
        require(v_.ratioLimit <= ratios.maxLimit, "risky-import");

        (
            uint256 exchangePrice_,
            uint256 newRevenue_
        ) = getCurrentExchangePrice();
        updateStorage(exchangePrice_, newRevenue_);

        v_.initialDsaAsteth = astethToken.balanceOf(address(vaultDsa));
        v_.initialDsaWethDebt = awethVariableDebtToken.balanceOf(
            address(vaultDsa)
        );

        uint256 j = flashAmt_ > 0 ? 6 : 3;
        uint256 i;
        string[] memory targets_ = new string[](j);
        bytes[] memory calldata_ = new bytes[](j);
        if (flashAmt_ > 0) {
            require(flashTkn_ != address(0), "wrong-flash-token");
            targets_[0] = "AAVE-V2-A";
            calldata_[0] = abi.encodeWithSignature(
                "deposit(address,uint256,uint256,uint256)",
                flashTkn_,
                flashAmt_,
                0,
                0
            );
            i++;
        }
        targets_[i] = "AAVE-V2-A";
        calldata_[i] = abi.encodeWithSignature(
            "borrow(address,uint256,uint256,uint256)",
            wethAddr,
            wethAmt_,
            0,
            0
        );
        targets_[i + 1] = "AAVE-V2-A";
        calldata_[i + 1] = abi.encodeWithSignature(
            "paybackOnBehalfOf(address,uint256,uint256,address,uint256,uint256)",
            wethAddr,
            wethAmt_,
            2,
            msg.sender,
            0,
            0
        );
        targets_[i + 2] = "BASIC-A";
        calldata_[i + 2] = abi.encodeWithSignature(
            "depositFrom(address,uint256,address,uint256,uint256)",
            astethToken,
            stEthAmt_,
            msg.sender,
            0,
            0
        );
        if (flashAmt_ > 0) {
            targets_[i + 3] = "AAVE-V2-A";
            calldata_[i + 3] = abi.encodeWithSignature(
                "withdraw(address,uint256,uint256,uint256)",
                flashTkn_,
                flashAmt_,
                0,
                0
            );
            targets_[i + 4] = "INSTAPOOL-C";
            calldata_[i + 4] = abi.encodeWithSignature(
                "flashPayback(address,uint256,uint256,uint256)",
                flashTkn_,
                flashAmt_,
                0,
                0
            );
        }
        if (flashAmt_ > 0) {
            v_.encodedFlashData = abi.encode(targets_, calldata_);

            v_.flashTarget = new string[](1);
            v_.flashCalldata = new bytes[](1);
            v_.flashTarget[0] = "INSTAPOOL-C";
            v_.flashCalldata[0] = abi.encodeWithSignature(
                "flashBorrowAndCast(address,uint256,uint256,bytes,bytes)",
                flashTkn_,
                flashAmt_,
                route_,
                v_.encodedFlashData,
                "0x"
            );

            vaultDsa.cast(v_.flashTarget, v_.flashCalldata, address(this));
        } else {
            vaultDsa.cast(targets_, calldata_, address(this));
        }

        v_.finalDsaAsteth = astethToken.balanceOf(address(vaultDsa));
        v_.finalDsaWethDebt = awethVariableDebtToken.balanceOf(
            address(vaultDsa)
        );

        // final net balance - initial net balance
        v_.dsaDif =
            (v_.finalDsaAsteth - v_.finalDsaWethDebt) -
            (v_.initialDsaAsteth - v_.initialDsaWethDebt);
        require(v_.importNetAmt < v_.dsaDif + 1e9, "import-check-fail"); // Adding 1e9 for decimal problem that might occur due to Aave's calculation

        v_.checks = new bool[](2);

        (v_.checks[0], , , , v_.checks[1]) = validateFinalRatio();
        require(v_.checks[0] && v_.checks[1], "Import: position-is-risky");

        uint256 vtokenAmount_ = (v_.importNetAmt * 1e18) / exchangePrice_;
        _mint(to_, vtokenAmount_);

        emit importLog(flashTkn_, flashAmt_, route_, to_, stEthAmt_, wethAmt_);
    }

    /**
     * @dev Rebalancer function to leverage and rebalance the position.
     */
    function rebalanceOne(
        address flashTkn_,
        uint256 flashAmt_,
        uint256 route_,
        address[] memory vaults_, // leverage using other vaults
        uint256[] memory amts_,
        uint256 excessDebt_,
        uint256 paybackDebt_,
        uint256 totalAmountToSwap_,
        uint256 extraWithdraw_,
        uint256 unitAmt_,
        bytes memory oneInchData_
    ) external nonReentrant onlyRebalancer {
        Address.functionDelegateCall(rebalancerModuleAddr, msg.data);
    }

    /**
     * @dev Rebalancer function for saving. To be run in times of making position less risky or to fill up the withdraw amount for users to exit
     */
    function rebalanceTwo(
        uint256 withdrawAmt_,
        address flashTkn_,
        uint256 flashAmt_,
        uint256 route_,
        uint256 totalAmountToSwap_,
        uint256 unitAmt_,
        bytes memory oneInchData_
    ) external nonReentrant onlyRebalancer {
        Address.functionDelegateCall(rebalancerModuleAddr, msg.data);
    }

    /**
     * @dev Function to collect revenue.
     * @param amount_ amount to claim
     * @param to_ address to send the claimed revenue to
     */
    function collectRevenue(uint256 amount_, address to_) external onlyAuth {
        require(amount_ != 0, "amount-cannot-be-zero");
        if (amount_ == type(uint256).max) amount_ = revenue;
        require(amount_ <= revenue, "not-enough-revenue");
        revenue -= amount_;

        uint256 stethAmt_;
        uint256 wethAmt_;
        uint256 wethVaultBal_ = wethContract.balanceOf(address(this));
        uint256 stethVaultBal_ = stEthContract.balanceOf(address(this));
        if (wethVaultBal_ > 10)
            (amount_, wethAmt_) = withdrawHelper(amount_, wethVaultBal_);
        if (amount_ > 0 && stethVaultBal_ > 10)
            (amount_, stethAmt_) = withdrawHelper(amount_, stethVaultBal_);
        require(amount_ == 0, "not-enough-amount-inside-vault");
        if (wethAmt_ > 0) wethContract.safeTransfer(to_, wethAmt_);
        if (stethAmt_ > 0) stEthContract.safeTransfer(to_, stethAmt_);

        emit collectRevenueLog(stethAmt_ + wethAmt_, stethAmt_, wethAmt_, to_);
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public pure override returns (string memory) {
        return "Instadapp ETH";
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public pure override returns (string memory) {
        return "iETH";
    }

    /* 
     Deprecated
    */
    // function initialize(
    //     string memory name_,
    //     string memory symbol_,
    //     address auth_,
    //     address rebalancer_,
    //     uint256 revenueFee_,
    //     uint16[] memory ratios_
    // ) public initializer {
    //     address vaultDsaAddr_ = instaIndex.build(address(this), 2, address(this));
    //     vaultDsa = IDSA(vaultDsaAddr_);
    //     __ERC20_init(name_, symbol_);
    //     auth = auth_;
    //     isRebalancer[rebalancer_] = true;
    //     revenueFee = revenueFee_;
    //     lastRevenueExchangePrice = 1e18;
    //     // sending borrow rate in 4 decimals eg:- 300 meaning 3% and converting into 27 decimals eg:- 3 * 1e25
    //     ratios = Ratios(ratios_[0], ratios_[1], ratios_[2], uint128(ratios_[3]) * 1e23);
    // }

    receive() external payable {}
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./helpers.sol";

contract IEthRebalancerModule is Helpers {
    using SafeERC20 for IERC20;

    struct RebalanceOneVariables {
        uint256 stethBal;
        string[] targets;
        bytes[] calldatas;
        bool[] checks;
        uint256 length;
        bool isOk;
        bytes encodedFlashData;
        string[] flashTarget;
        bytes[] flashCalldata;
    }

    /**
     * @dev Rebalancer function to leverage and rebalance the position.
     */
    function rebalanceOne(
        address flashTkn_,
        uint256 flashAmt_,
        uint256 route_,
        address[] memory vaults_, // leverage using other vaults
        uint256[] memory amts_,
        uint256 excessDebt_,
        uint256 paybackDebt_,
        uint256 totalAmountToSwap_,
        uint256 extraWithdraw_,
        uint256 unitAmt_,
        bytes memory oneInchData_
    ) external {
        if (excessDebt_ < 1e14) excessDebt_ = 0;
        if (paybackDebt_ < 1e14) paybackDebt_ = 0;
        if (totalAmountToSwap_ < 1e14) totalAmountToSwap_ = 0;
        if (extraWithdraw_ < 1e14) extraWithdraw_ = 0;

        RebalanceOneVariables memory v_;

        v_.length = amts_.length;
        require(vaults_.length == v_.length, "unequal-length");

        require(
            !(excessDebt_ > 0 && paybackDebt_ > 0),
            "cannot-borrow-and-payback-at-once"
        );
        require(
            !(totalAmountToSwap_ > 0 && paybackDebt_ > 0),
            "cannot-swap-and-payback-at-once"
        );
        require(
            !((totalAmountToSwap_ > 0 || v_.length > 0) && excessDebt_ == 0),
            "cannot-swap-and-when-zero-excess-debt"
        );

        BalVariables memory balances_ = getIdealBalances();
        v_.stethBal = balances_.stethDsaBal;
        if (balances_.wethVaultBal > 1e14)
            wethContract.safeTransfer(
                address(vaultDsa),
                balances_.wethVaultBal
            );
        if (balances_.stethVaultBal > 1e14) {
            stEthContract.safeTransfer(
                address(vaultDsa),
                balances_.stethVaultBal
            );
            v_.stethBal += balances_.stethVaultBal;
        }
        if (v_.stethBal < 1e14) v_.stethBal = 0;

        uint256 i;
        uint256 j;
        if (excessDebt_ > 0) j += 4;
        if (v_.length > 0) j += v_.length;
        if (totalAmountToSwap_ > 0) j += 1;
        if (excessDebt_ > 0 && (totalAmountToSwap_ > 0 || v_.stethBal > 0))
            j += 1;
        if (paybackDebt_ > 0) j += 1;
        if (v_.stethBal > 0 && excessDebt_ == 0) j += 1;
        if (extraWithdraw_ > 0) j += 2;
        v_.targets = new string[](j);
        v_.calldatas = new bytes[](j);
        if (excessDebt_ > 0) {
            v_.targets[0] = "AAVE-V2-A";
            v_.calldatas[0] = abi.encodeWithSignature(
                "deposit(address,uint256,uint256,uint256)",
                flashTkn_,
                flashAmt_,
                0,
                0
            );
            v_.targets[1] = "AAVE-V2-A";
            v_.calldatas[1] = abi.encodeWithSignature(
                "borrow(address,uint256,uint256,uint256,uint256)",
                wethAddr,
                excessDebt_,
                2,
                0,
                0
            );
            i = 2;
            // Doing swaps from different vaults using deleverage to reduce other vaults riskiness if needed.
            // It takes WETH from vault and gives astETH at 1:1
            for (uint256 k = 0; k < v_.length; k++) {
                v_.targets[i] = "LITE-A"; // Instadapp Lite vaults connector
                v_.calldatas[i] = abi.encodeWithSignature(
                    "deleverage(address,uint256,uint256,uint256)",
                    vaults_[k],
                    amts_[k],
                    0,
                    0
                );
                i++;
            }
            if (totalAmountToSwap_ > 0) {
                require(unitAmt_ > (1e18 - 10), "invalid-unit-amt");
                v_.targets[i] = "1INCH-A";
                v_.calldatas[i] = abi.encodeWithSignature(
                    "sell(address,address,uint256,uint256,bytes,uint256)",
                    stEthAddr,
                    wethAddr,
                    totalAmountToSwap_,
                    unitAmt_,
                    oneInchData_,
                    0
                );
                i++;
            }
            if (totalAmountToSwap_ > 0 || v_.stethBal > 0) {
                v_.targets[i] = "AAVE-V2-A";
                v_.calldatas[i] = abi.encodeWithSignature(
                    "deposit(address,uint256,uint256,uint256)",
                    stEthAddr,
                    type(uint256).max,
                    0,
                    0
                );
                i++;
            }
            v_.targets[i] = "AAVE-V2-A";
            v_.calldatas[i] = abi.encodeWithSignature(
                "withdraw(address,uint256,uint256,uint256)",
                flashTkn_,
                flashAmt_,
                0,
                0
            );
            v_.targets[i + 1] = "INSTAPOOL-C";
            v_.calldatas[i + 1] = abi.encodeWithSignature(
                "flashPayback(address,uint256,uint256,uint256)",
                flashTkn_,
                flashAmt_,
                0,
                0
            );
            i += 2;
        }
        if (paybackDebt_ > 0) {
            v_.targets[i] = "AAVE-V2-A";
            v_.calldatas[i] = abi.encodeWithSignature(
                "payback(address,uint256,uint256,uint256,uint256)",
                wethAddr,
                paybackDebt_,
                2,
                0,
                0
            );
            i++;
        }
        if (v_.stethBal > 0 && excessDebt_ == 0) {
            v_.targets[i] = "AAVE-V2-A";
            v_.calldatas[i] = abi.encodeWithSignature(
                "deposit(address,uint256,uint256,uint256)",
                stEthAddr,
                type(uint256).max,
                0,
                0
            );
            i++;
        }
        if (extraWithdraw_ > 0) {
            v_.targets[i] = "AAVE-V2-A";
            v_.calldatas[i] = abi.encodeWithSignature(
                "withdraw(address,uint256,uint256,uint256)",
                stEthAddr,
                extraWithdraw_,
                0,
                0
            );
            v_.targets[i + 1] = "BASIC-A";
            v_.calldatas[i + 1] = abi.encodeWithSignature(
                "withdraw(address,uint256,address,uint256,uint256)",
                stEthAddr,
                extraWithdraw_,
                address(this),
                0,
                0
            );
        }

        if (excessDebt_ > 0) {
            v_.encodedFlashData = abi.encode(v_.targets, v_.calldatas);

            v_.flashTarget = new string[](1);
            v_.flashCalldata = new bytes[](1);
            v_.flashTarget[0] = "INSTAPOOL-C";
            v_.flashCalldata[0] = abi.encodeWithSignature(
                "flashBorrowAndCast(address,uint256,uint256,bytes,bytes)",
                flashTkn_,
                flashAmt_,
                route_,
                v_.encodedFlashData,
                "0x"
            );

            vaultDsa.cast(v_.flashTarget, v_.flashCalldata, address(this));
            require(
                getWethBorrowRate() < ratios.maxBorrowRate,
                "high-borrow-rate"
            );
        } else {
            if (j > 0) vaultDsa.cast(v_.targets, v_.calldatas, address(this));
        }

        v_.checks = new bool[](4);
        (
            v_.checks[0],
            ,
            v_.checks[1],
            v_.checks[2],
            v_.checks[3]
        ) = validateFinalRatio();
        if (excessDebt_ > 0)
            require(v_.checks[1], "position-risky-after-leverage");
        if (extraWithdraw_ > 0) require(v_.checks[0], "position-risky");
        if (excessDebt_ > 0 && extraWithdraw_ > 0)
            require(v_.checks[3], "position-hf-risky");

        emit rebalanceOneLog(
            flashTkn_,
            flashAmt_,
            route_,
            vaults_,
            amts_,
            excessDebt_,
            paybackDebt_,
            totalAmountToSwap_,
            extraWithdraw_,
            unitAmt_
        );
    }

    struct RebalanceTwoVariables {
        bool hfIsOk;
        BalVariables balances;
        uint256 wethBal;
        string[] targets;
        bytes[] calldatas;
        bytes encodedFlashData;
        string[] flashTarget;
        bytes[] flashCalldata;
        bool maxIsOk;
        bool minGapIsOk;
    }

    /**
     * @dev Rebalancer function for saving. To be run in times of making position less risky or to fill up the withdraw amount for users to exit
     */
    function rebalanceTwo(
        uint256 withdrawAmt_,
        address flashTkn_,
        uint256 flashAmt_,
        uint256 route_,
        uint256 totalAmountToSwap_,
        uint256 unitAmt_,
        bytes memory oneInchData_
    ) external {
        RebalanceTwoVariables memory v_;
        (, , , , v_.hfIsOk) = validateFinalRatio();
        if (v_.hfIsOk) {
            require(unitAmt_ > (1e18 - (2 * 1e16)), "excess-slippage"); // Here's it's 2% slippage.
        } else {
            // Here's it's 5% slippage. Only when HF is not okay. Meaning stETH got too unstable from it's original price.
            require(unitAmt_ > (1e18 - (5 * 1e16)), "excess-slippage");
        }
        v_.balances = getIdealBalances();
        v_.wethBal = v_.balances.wethDsaBal;
        if (v_.balances.wethVaultBal > 0) {
            wethContract.safeTransfer(
                address(vaultDsa),
                v_.balances.wethVaultBal
            );
            v_.wethBal += v_.balances.wethVaultBal;
        }
        if (v_.balances.stethVaultBal > 0) {
            stEthContract.safeTransfer(
                address(vaultDsa),
                v_.balances.stethVaultBal
            );
        }
        if (v_.wethBal < 1e14) v_.wethBal = 0;

        uint256 i;
        uint256 j;
        if (flashAmt_ > 0) j += 3;
        if (withdrawAmt_ > 0) j += 1;
        if (totalAmountToSwap_ > 0) j += 1;
        if (totalAmountToSwap_ > 0 || v_.wethBal > 0) j += 1;
        v_.targets = new string[](j);
        v_.calldatas = new bytes[](j);
        if (flashAmt_ > 0) {
            v_.targets[0] = "AAVE-V2-A";
            v_.calldatas[0] = abi.encodeWithSignature(
                "deposit(address,uint256,uint256,uint256)",
                flashTkn_,
                flashAmt_,
                0,
                0
            );
            i++;
        }
        if (withdrawAmt_ > 0) {
            v_.targets[i] = "AAVE-V2-A";
            v_.calldatas[i] = abi.encodeWithSignature(
                "withdraw(address,uint256,uint256,uint256)",
                stEthAddr,
                withdrawAmt_,
                0,
                0
            );
            i++;
        }
        if (totalAmountToSwap_ > 0) {
            v_.targets[i] = "1INCH-A";
            v_.calldatas[i] = abi.encodeWithSignature(
                "sell(address,address,uint256,uint256,bytes,uint256)",
                wethAddr,
                stEthAddr,
                totalAmountToSwap_,
                unitAmt_,
                oneInchData_,
                0
            );
            i++;
        }
        if (totalAmountToSwap_ > 0 || v_.wethBal > 0) {
            v_.targets[i] = "AAVE-V2-A";
            v_.calldatas[i] = abi.encodeWithSignature(
                "payback(address,uint256,uint256,uint256,uint256)",
                wethAddr,
                type(uint256).max,
                2,
                0,
                0
            );
            i++;
        }
        if (flashAmt_ > 0) {
            v_.targets[i] = "AAVE-V2-A";
            v_.calldatas[i] = abi.encodeWithSignature(
                "withdraw(address,uint256,uint256,uint256)",
                flashTkn_,
                flashAmt_,
                0,
                0
            );
            v_.targets[i + 1] = "INSTAPOOL-C";
            v_.calldatas[i + 1] = abi.encodeWithSignature(
                "flashPayback(address,uint256,uint256,uint256)",
                flashTkn_,
                flashAmt_,
                0,
                0
            );
        }

        if (flashAmt_ > 0) {
            v_.encodedFlashData = abi.encode(v_.targets, v_.calldatas);

            v_.flashTarget = new string[](1);
            v_.flashCalldata = new bytes[](1);
            v_.flashTarget[0] = "INSTAPOOL-C";
            v_.flashCalldata[0] = abi.encodeWithSignature(
                "flashBorrowAndCast(address,uint256,uint256,bytes,bytes)",
                flashTkn_,
                flashAmt_,
                route_,
                v_.encodedFlashData,
                "0x"
            );

            vaultDsa.cast(v_.flashTarget, v_.flashCalldata, address(this));
        } else {
            vaultDsa.cast(v_.targets, v_.calldatas, address(this));
        }

        (v_.maxIsOk, , , v_.minGapIsOk, ) = validateFinalRatio();
        require(v_.minGapIsOk, "position-over-saved");
        require(v_.maxIsOk, "position-under-saved");

        emit rebalanceTwoLog(
            withdrawAmt_,
            flashTkn_,
            flashAmt_,
            route_,
            totalAmountToSwap_,
            unitAmt_
        );
    }

    receive() external payable {}
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

contract ConstantVariables is ERC20Upgradeable {
    using SafeERC20 for IERC20;

    address internal constant ethAddr =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    IInstaIndex internal constant instaIndex =
        IInstaIndex(0x2971AdFa57b20E5a416aE5a708A8655A9c74f723);
    address internal constant wethAddr =
        0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address internal constant stEthAddr =
        0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;
    IAaveProtocolDataProvider internal constant aaveProtocolDataProvider =
        IAaveProtocolDataProvider(0x057835Ad21a177dbdd3090bB1CAE03EaCF78Fc6d);
    IERC20 internal constant awethVariableDebtToken =
        IERC20(0xF63B34710400CAd3e044cFfDcAb00a0f32E33eCf);
    IERC20 internal constant astethToken =
        IERC20(0x1982b2F5814301d4e9a8b0201555376e62F82428);
    TokenInterface internal constant wethCoreContract =
        TokenInterface(wethAddr); // contains deposit & withdraw for weth
    IAaveLendingPool internal constant aaveLendingPool =
        IAaveLendingPool(0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9);
    IERC20 internal constant wethContract = IERC20(wethAddr);
    IERC20 internal constant stEthContract = IERC20(stEthAddr);
    IInstaList internal constant instaList =
        IInstaList(0x4c8a1BEb8a87765788946D6B19C6C6355194AbEb);
    address internal constant rebalancerModuleAddr =
        0xcfCdB64a551478E07Bd07d17CF1525f740173a35;
}

contract Variables is ConstantVariables {
    uint256 internal _status = 1;

    address public auth;

    // only authorized addresses can rebalance
    mapping(address => bool) public isRebalancer;

    IDSA public vaultDsa;

    struct Ratios {
        uint16 maxLimit; // Above this withdrawals are not allowed
        uint16 minLimit; // After leverage the ratio should be below minLimit & above minLimitGap
        uint16 minLimitGap;
        // send borrow rate in 4 decimals from UI. In the smart contract it'll convert to 27 decimals which where is 100%
        uint128 maxBorrowRate; // maximum borrow rate above this leveraging should not happen
    }

    Ratios public ratios;

    // last revenue exchange price (helps in calculating revenue)
    // Exchange price when revenue got updated last. It'll only increase overtime.
    uint256 public lastRevenueExchangePrice;

    uint256 public revenueFee; // 1000 = 10% (10% of user's profit)

    uint256 public revenue;

    uint256 public withdrawalFee; // 10000 = 100%

    uint256 public swapFee;

    uint256 public deleverageFee;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./variables.sol";

contract Helpers is Variables {
    /**
     * @dev reentrancy gaurd.
     */
    modifier nonReentrant() {
        require(_status != 2, "ReentrancyGuard: reentrant call");
        _status = 2;
        _;
        _status = 1;
    }

    /**
     * @dev Helper function to get current eth borrow rate on aave.
     */
    function getWethBorrowRate()
        internal
        view
        returns (uint256 wethBorrowRate_)
    {
        (, , , , wethBorrowRate_, , , , , ) = aaveProtocolDataProvider
            .getReserveData(address(wethContract));
    }

    /**
     * @dev Helper function to get current token collateral on aave.
     */
    function getTokenCollateralAmount()
        internal
        view
        returns (uint256 tokenAmount_)
    {
        tokenAmount_ = _atoken.balanceOf(address(_vaultDsa));
    }

    /**
     * @dev Helper function to get current steth collateral on aave.
     */
    function getStethCollateralAmount()
        internal
        view
        returns (uint256 stEthAmount_)
    {
        stEthAmount_ = astethToken.balanceOf(address(_vaultDsa));
    }

    /**
     * @dev Helper function to get current eth debt on aave.
     */
    function getWethDebtAmount()
        internal
        view
        returns (uint256 wethDebtAmount_)
    {
        wethDebtAmount_ = awethVariableDebtToken.balanceOf(address(_vaultDsa));
    }

    /**
     * @dev Helper function to token balances of everywhere.
     */
    function getVaultBalances()
        public
        view
        returns (
            uint256 tokenCollateralAmt_,
            uint256 stethCollateralAmt_,
            uint256 wethDebtAmt_,
            uint256 tokenVaultBal_,
            uint256 tokenDSABal_,
            uint256 netTokenBal_
        )
    {
        tokenCollateralAmt_ = getTokenCollateralAmount();
        stethCollateralAmt_ = getStethCollateralAmount();
        wethDebtAmt_ = getWethDebtAmount();
        tokenVaultBal_ = _token.balanceOf(address(this));
        tokenDSABal_ = _token.balanceOf(address(_vaultDsa));
        netTokenBal_ = tokenCollateralAmt_ + tokenVaultBal_ + tokenDSABal_;
    }

    // returns net eth. net stETH + ETH - net ETH debt.
    function getNewProfits() public view returns (uint256 profits_) {
        uint256 stEthCol_ = getStethCollateralAmount();
        uint256 stEthDsaBal_ = stethContract.balanceOf(address(_vaultDsa));
        uint256 wethDsaBal_ = wethContract.balanceOf(address(_vaultDsa));
        uint256 positiveEth_ = stEthCol_ + stEthDsaBal_ + wethDsaBal_;
        uint256 negativeEth_ = getWethDebtAmount() + _revenueEth;
        profits_ = negativeEth_ < positiveEth_
            ? positiveEth_ - negativeEth_
            : 0;
    }

    /**
     * @dev Helper function to get current exchange price and new revenue generated.
     */
    function getCurrentExchangePrice()
        public
        view
        returns (uint256 exchangePrice_, uint256 newTokenRevenue_)
    {
        // net token balance is total balance. stETH collateral & ETH debt cancels out each other.
        (, , , , , uint256 netTokenBalance_) = getVaultBalances();
        netTokenBalance_ -= _revenue;
        uint256 totalSupply_ = totalSupply();
        uint256 exchangePriceWithRevenue_;
        if (totalSupply_ != 0) {
            exchangePriceWithRevenue_ =
                (netTokenBalance_ * 1e18) /
                totalSupply_;
        } else {
            exchangePriceWithRevenue_ = 1e18;
        }
        // Only calculate revenue if there's a profit
        if (exchangePriceWithRevenue_ > _lastRevenueExchangePrice) {
            uint256 newProfit_ = netTokenBalance_ -
                ((_lastRevenueExchangePrice * totalSupply_) / 1e18);
            newTokenRevenue_ = (newProfit_ * _revenueFee) / 10000;
            exchangePrice_ =
                ((netTokenBalance_ - newTokenRevenue_) * 1e18) /
                totalSupply_;
        } else {
            exchangePrice_ = exchangePriceWithRevenue_;
        }
    }

    struct ValidateFinalPosition {
        uint256 tokenPriceInBaseCurrency;
        uint256 ethPriceInBaseCurrency;
        uint256 excessDebtInBaseCurrency;
        uint256 netTokenColInBaseCurrency;
        uint256 netTokenSupplyInBaseCurrency;
        uint256 ratioMax;
        uint256 ratioMin;
    }

    /**
     * @dev Helper function to validate the safety of aave position after rebalancing.
     */
    function validateFinalPosition()
        internal
        view
        returns (
            bool criticalIsOk_,
            bool criticalGapIsOk_,
            bool minIsOk_,
            bool minGapIsOk_,
            bool withdrawIsOk_
        )
    {
        (
            uint256 tokenColAmt_,
            uint256 stethColAmt_,
            uint256 wethDebt_,
            ,
            ,
            uint256 netTokenBal_
        ) = getVaultBalances();

        uint256 ethCoveringDebt_ = (stethColAmt_ * _ratios.stEthLimit) / 10000;

        uint256 excessDebt_ = ethCoveringDebt_ < wethDebt_
            ? wethDebt_ - ethCoveringDebt_
            : 0;

        if (excessDebt_ > 0) {
            IAavePriceOracle aaveOracle_ = IAavePriceOracle(
                aaveAddressProvider.getPriceOracle()
            );

            ValidateFinalPosition memory validateFinalPosition_;
            validateFinalPosition_.tokenPriceInBaseCurrency = aaveOracle_
                .getAssetPrice(address(_token));
            validateFinalPosition_.ethPriceInBaseCurrency = aaveOracle_
                .getAssetPrice(address(wethContract));

            validateFinalPosition_.excessDebtInBaseCurrency =
                (excessDebt_ * validateFinalPosition_.ethPriceInBaseCurrency) /
                1e18;

            validateFinalPosition_.netTokenColInBaseCurrency =
                (tokenColAmt_ *
                    validateFinalPosition_.tokenPriceInBaseCurrency) /
                (10**_tokenDecimals);
            validateFinalPosition_.netTokenSupplyInBaseCurrency =
                (netTokenBal_ *
                    validateFinalPosition_.tokenPriceInBaseCurrency) /
                (10**_tokenDecimals);

            validateFinalPosition_.ratioMax =
                (validateFinalPosition_.excessDebtInBaseCurrency * 10000) /
                validateFinalPosition_.netTokenColInBaseCurrency;
            validateFinalPosition_.ratioMin =
                (validateFinalPosition_.excessDebtInBaseCurrency * 10000) /
                validateFinalPosition_.netTokenSupplyInBaseCurrency;

            criticalIsOk_ = validateFinalPosition_.ratioMax < _ratios.maxLimit;
            criticalGapIsOk_ =
                validateFinalPosition_.ratioMax > _ratios.maxLimitGap;
            minIsOk_ = validateFinalPosition_.ratioMin < _ratios.minLimit;
            minGapIsOk_ = validateFinalPosition_.ratioMin > _ratios.minLimitGap;
            withdrawIsOk_ =
                validateFinalPosition_.ratioMax < (_ratios.maxLimit - 100);
        } else {
            criticalIsOk_ = true;
            minIsOk_ = true;
        }
    }

    /**
     * @dev Helper function to validate if the leverage amount is divided correctly amount other-vault-swaps and 1inch-swap .
     */
    function validateLeverageAmt(
        address[] memory vaults_,
        uint256[] memory amts_,
        uint256 leverageAmt_,
        uint256 swapAmt_
    ) internal pure returns (bool isOk_) {
        if (leverageAmt_ == 0 && swapAmt_ == 0) {
            isOk_ = true;
            return isOk_;
        }
        uint256 l_ = vaults_.length;
        isOk_ = l_ == amts_.length;
        if (isOk_) {
            uint256 totalAmt_ = swapAmt_;
            for (uint256 i = 0; i < l_; i++) {
                totalAmt_ = totalAmt_ + amts_[i];
            }
            isOk_ = totalAmt_ <= leverageAmt_; // total amount should not be more than leverage amount
            isOk_ = isOk_ && ((leverageAmt_ * 9999) / 10000) < totalAmt_; // total amount should be more than (0.9999 * leverage amount). 0.01% slippage gap.
        }
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IInstaIndex {
    function build(
        address owner_,
        uint256 accountVersion_,
        address origin_
    ) external returns (address account_);
}

interface IDSA {
    function cast(
        string[] calldata _targetNames,
        bytes[] calldata _datas,
        address _origin
    ) external payable returns (bytes32);
}

interface IAaveProtocolDataProvider {
    function getReserveData(address asset)
        external
        view
        returns (
            uint256 availableLiquidity,
            uint256 totalStableDebt,
            uint256 totalVariableDebt,
            uint256 liquidityRate,
            uint256 variableBorrowRate,
            uint256 stableBorrowRate,
            uint256 averageStableBorrowRate,
            uint256 liquidityIndex,
            uint256 variableBorrowIndex,
            uint40 lastUpdateTimestamp
        );
}

interface IAaveAddressProvider {
    function getPriceOracle() external view returns (address);
}

interface IAavePriceOracle {
    function getAssetPrice(address _asset) external view returns (uint256);
}

interface TokenInterface {
    function approve(address, uint256) external;

    function transfer(address, uint256) external;

    function transferFrom(
        address,
        address,
        uint256
    ) external;

    function deposit() external payable;

    function withdraw(uint256) external;

    function balanceOf(address) external view returns (uint256);

    function decimals() external view returns (uint256);

    function totalSupply() external view returns (uint256);
}

interface IInstaList {
    function accountID(address) external view returns (uint64);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./interfaces.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

contract ConstantVariables is ERC20Upgradeable {
    IInstaIndex internal constant instaIndex =
        IInstaIndex(0x2971AdFa57b20E5a416aE5a708A8655A9c74f723);
    IERC20 internal constant wethContract =
        IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IERC20 internal constant stethContract =
        IERC20(0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84);
    IAaveProtocolDataProvider internal constant aaveProtocolDataProvider =
        IAaveProtocolDataProvider(0x057835Ad21a177dbdd3090bB1CAE03EaCF78Fc6d);
    IAaveAddressProvider internal constant aaveAddressProvider =
        IAaveAddressProvider(0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5);
    IERC20 internal constant awethVariableDebtToken =
        IERC20(0xF63B34710400CAd3e044cFfDcAb00a0f32E33eCf);
    IERC20 internal constant astethToken =
        IERC20(0x1982b2F5814301d4e9a8b0201555376e62F82428);
    IInstaList internal constant instaList =
        IInstaList(0x4c8a1BEb8a87765788946D6B19C6C6355194AbEb);
}

contract Variables is ConstantVariables {
    uint256 internal _status = 1;

    // only authorized addresses can rebalance
    mapping(address => bool) internal _isRebalancer;

    IERC20 internal _token;

    uint8 internal _tokenDecimals;

    uint256 internal _tokenMinLimit;

    IERC20 internal _atoken;

    IDSA internal _vaultDsa;

    struct Ratios {
        uint16 maxLimit; // Above this withdrawals are not allowed
        uint16 maxLimitGap;
        uint16 minLimit; // After leverage the ratio should be below minLimit & above minLimitGap
        uint16 minLimitGap;
        uint16 stEthLimit; // if 7500. Meaning stETH collateral covers 75% of the ETH debt. Excess ETH will be covered by token limit.
        // send borrow rate in 4 decimals from UI. In the smart contract it'll convert to 27 decimals which where is 100%
        uint128 maxBorrowRate; // maximum borrow rate above this leveraging should not happen
    }

    Ratios internal _ratios;

    // last revenue exchange price (helps in calculating revenue)
    // Exchange price when revenue got updated last. It'll only increase overtime.
    uint256 internal _lastRevenueExchangePrice;

    uint256 internal _revenueFee; // 1000 = 10% (10% of user's profit)

    uint256 internal _revenue;

    uint256 internal _revenueEth;

    uint256 internal _withdrawalFee; // 10000 = 100%

    uint256 internal _idealExcessAmt; // 10 means 0.1% of total stEth/Eth supply (collateral + ideal balance)

    uint256 internal _swapFee; // 5 means 0.05%. This is the fee on leverage function which allows swap of stETH -> ETH

    uint256 internal _saveSlippage; // 1e16 means 1%

    uint256 internal _deleverageFee; // 1 means 0.01%
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "../common/helpers.sol";

contract Events is Helpers {
    event supplyLog(
        uint256 amount_,
        address indexed caller_,
        address indexed to_
    );

    event withdrawLog(
        uint256 amount_,
        address indexed caller_,
        address indexed to_
    );

    event leverageLog(uint256 amt_, uint256 transferAmt_);

    event deleverageLog(uint256 amt_, uint256 transferAmt_);

    event deleverageAndWithdrawLog(
        uint256 deleverageAmt_,
        uint256 transferAmt_,
        uint256 vtokenAmount_,
        address to_
    );
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./events.sol";

contract CoreHelpers is Events {
    using SafeERC20 for IERC20;

    /**
     * @dev Update storage.
     * @notice Internal function to update storage.
     */
    function updateStorage(uint256 exchangePrice_, uint256 newRevenue_)
        internal
    {
        if (exchangePrice_ > _lastRevenueExchangePrice) {
            _lastRevenueExchangePrice = exchangePrice_;
            _revenue += newRevenue_;
        }
    }

    /**
     * @dev Withdraw helper.
     */
    function withdrawHelper(uint256 amount_, uint256 limit_)
        internal
        pure
        returns (uint256, uint256)
    {
        uint256 transferAmt_;
        if (limit_ > amount_) {
            transferAmt_ = amount_;
            amount_ = 0;
        } else {
            transferAmt_ = limit_;
            amount_ = amount_ - limit_;
        }
        return (amount_, transferAmt_);
    }

    /**
     * @dev Withdraw final.
     */
    function withdrawFinal(uint256 amount_)
        internal
        view
        returns (uint256[] memory transferAmts_)
    {
        require(amount_ > 0, "amount-invalid");
        (
            uint256 tokenCollateralAmt_,
            ,
            ,
            uint256 tokenVaultBal_,
            uint256 tokenDSABal_,
            uint256 netTokenBal_
        ) = getVaultBalances();
        require(amount_ <= netTokenBal_, "excess-withdrawal");

        transferAmts_ = new uint256[](3);
        if (tokenVaultBal_ > 10) {
            (amount_, transferAmts_[0]) = withdrawHelper(
                amount_,
                tokenVaultBal_
            );
        }
        if (tokenDSABal_ > 10 && amount_ > 0) {
            (amount_, transferAmts_[1]) = withdrawHelper(amount_, tokenDSABal_);
        }
        if (tokenCollateralAmt_ > 10 && amount_ > 0) {
            (amount_, transferAmts_[2]) = withdrawHelper(
                amount_,
                tokenCollateralAmt_
            );
        }
    }

    /**
     * @dev Withdraw related transfers.
     */
    function withdrawTransfers(uint256 amount_, uint256[] memory transferAmts_)
        internal
    {
        if (transferAmts_[0] == amount_) return;
        uint256 totalTransferAmount_ = transferAmts_[0] +
            transferAmts_[1] +
            transferAmts_[2];
        require(amount_ == totalTransferAmount_, "transfers-not-valid");
        // batching up spells and withdrawing all the required asset from DSA to vault at once
        uint256 i;
        uint256 j;
        uint256 withdrawAmtDSA = transferAmts_[1] + transferAmts_[2];
        if (transferAmts_[2] > 0) j++;
        if (withdrawAmtDSA > 0) j++;
        string[] memory targets_ = new string[](j);
        bytes[] memory calldata_ = new bytes[](j);
        if (transferAmts_[2] > 0) {
            targets_[i] = "AAVE-V2-A";
            calldata_[i] = abi.encodeWithSignature(
                "withdraw(address,uint256,uint256,uint256)",
                address(_token),
                transferAmts_[2],
                0,
                0
            );
            i++;
        }
        if (withdrawAmtDSA > 0) {
            targets_[i] = "BASIC-A";
            calldata_[i] = abi.encodeWithSignature(
                "withdraw(address,uint256,address,uint256,uint256)",
                address(_token),
                withdrawAmtDSA,
                address(this),
                0,
                0
            );
        }
        _vaultDsa.cast(targets_, calldata_, address(this));
    }

    /**
     * @dev Internal function to handle withdrawals.
     */
    function withdrawInternal(
        uint256 amount_,
        address to_,
        bool afterDeleverage_
    ) internal returns (uint256 vtokenAmount_) {
        require(amount_ != 0, "amount cannot be zero");

        (
            uint256 exchangePrice_,
            uint256 newRevenue_
        ) = getCurrentExchangePrice();
        updateStorage(exchangePrice_, newRevenue_);

        if (amount_ == type(uint256).max) {
            vtokenAmount_ = balanceOf(msg.sender);
            amount_ = (vtokenAmount_ * exchangePrice_) / 1e18;
        } else {
            vtokenAmount_ = (amount_ * 1e18) / exchangePrice_;
        }

        _burn(msg.sender, vtokenAmount_);
        uint256 fee_ = (amount_ * _withdrawalFee) / 10000;
        uint256 amountAfterFee_ = amount_ - fee_;
        uint256[] memory transferAmts_ = withdrawFinal(amountAfterFee_);
        withdrawTransfers(amountAfterFee_, transferAmts_);

        (, , , , bool isOk_) = validateFinalPosition();
        require(isOk_, "position-risky");

        _token.safeTransfer(to_, amountAfterFee_);

        if (afterDeleverage_) {
            (, , , bool minGapIsOk_, ) = validateFinalPosition();
            require(minGapIsOk_, "excess-deleverage");
        }
    }

    /**
     * @dev Internal function for deleverage logics.
     */
    function deleverageInternal(uint256 amt_)
        internal
        returns (uint256 transferAmt_)
    {
        require(amt_ > 0, "not-valid-amount");
        wethContract.safeTransferFrom(msg.sender, address(_vaultDsa), amt_);

        bool isDsa_ = instaList.accountID(msg.sender) > 0;

        uint256 i;
        uint256 j = isDsa_ ? 2 : 3;
        string[] memory targets_ = new string[](j);
        bytes[] memory calldata_ = new bytes[](j);
        targets_[0] = "AAVE-V2-A";
        calldata_[0] = abi.encodeWithSignature(
            "payback(address,uint256,uint256,uint256,uint256)",
            address(wethContract),
            amt_,
            2,
            0,
            0
        );
        if (!isDsa_) {
            transferAmt_ = amt_ + ((amt_ * _deleverageFee) / 10000);
            targets_[1] = "AAVE-V2-A";
            calldata_[1] = abi.encodeWithSignature(
                "withdraw(address,uint256,uint256,uint256)",
                address(stethContract),
                transferAmt_,
                0,
                0
            );
            i = 2;
        } else {
            transferAmt_ = amt_;
            i = 1;
        }
        targets_[i] = "BASIC-A";
        calldata_[i] = abi.encodeWithSignature(
            "withdraw(address,uint256,address,uint256,uint256)",
            isDsa_ ? address(astethToken) : address(stethContract),
            transferAmt_,
            msg.sender,
            0,
            0
        );
        _vaultDsa.cast(targets_, calldata_, address(this));
    }
}

contract UserModule is CoreHelpers {
    using SafeERC20 for IERC20;

    /**
     * @dev User function to supply.
     * @param token_ address of token.
     * @param amount_ amount to supply.
     * @param to_ address to send vTokens to.
     * @return vtokenAmount_ amount of vTokens sent to the `to_` address passed
     */
    function supply(
        address token_,
        uint256 amount_,
        address to_
    ) external nonReentrant returns (uint256 vtokenAmount_) {
        require(token_ == address(_token), "wrong token");
        require(amount_ != 0, "amount cannot be zero");
        (
            uint256 exchangePrice_,
            uint256 newRevenue_
        ) = getCurrentExchangePrice();
        updateStorage(exchangePrice_, newRevenue_);
        _token.safeTransferFrom(msg.sender, address(this), amount_);
        vtokenAmount_ = (amount_ * 1e18) / exchangePrice_;
        _mint(to_, vtokenAmount_);
        emit supplyLog(amount_, msg.sender, to_);
    }

    /**
     * @dev User function to withdraw.
     * @param amount_ amount to withdraw.
     * @param to_ address to send tokens to.
     * @return vtokenAmount_ amount of vTokens burnt from caller
     */
    function withdraw(uint256 amount_, address to_)
        external
        nonReentrant
        returns (uint256 vtokenAmount_)
    {
        vtokenAmount_ = withdrawInternal(amount_, to_, false);
        emit withdrawLog(amount_, msg.sender, to_);
    }

    /**
     * @dev If ratio is below then this function will allow anyone to swap from steth -> weth.
     */
    function leverage(uint256 amt_) external nonReentrant {
        require(amt_ > 0, "not-valid-amount");
        stethContract.safeTransferFrom(msg.sender, address(_vaultDsa), amt_);
        uint256 fee_ = (amt_ * _swapFee) / 10000;
        uint256 transferAmt_ = amt_ - fee_;
        _revenueEth += fee_;

        uint256 tokenBal_ = _token.balanceOf(address(this));
        if (tokenBal_ > _tokenMinLimit)
            _token.safeTransfer(address(_vaultDsa), tokenBal_);
        tokenBal_ = _token.balanceOf(address(_vaultDsa));
        uint256 i;
        uint256 j = tokenBal_ > _tokenMinLimit ? 4 : 3;
        string[] memory targets_ = new string[](j);
        bytes[] memory calldata_ = new bytes[](j);
        if (tokenBal_ > _tokenMinLimit) {
            targets_[i] = "AAVE-V2-A";
            calldata_[i] = abi.encodeWithSignature(
                "deposit(address,uint256,uint256,uint256)",
                address(_token),
                tokenBal_,
                0,
                0
            );
            i++;
        }
        targets_[i] = "AAVE-V2-A";
        calldata_[i] = abi.encodeWithSignature(
            "deposit(address,uint256,uint256,uint256)",
            address(stethContract),
            amt_,
            0,
            0
        );
        targets_[i + 1] = "AAVE-V2-A";
        calldata_[i + 1] = abi.encodeWithSignature(
            "borrow(address,uint256,uint256,uint256,uint256)",
            address(wethContract),
            amt_,
            2,
            0,
            0
        );
        targets_[i + 2] = "BASIC-A";
        calldata_[i + 2] = abi.encodeWithSignature(
            "withdraw(address,uint256,address,uint256,uint256)",
            address(wethContract),
            transferAmt_,
            msg.sender,
            0,
            0
        );
        _vaultDsa.cast(targets_, calldata_, address(this));
        (, , bool minIsOk_, , ) = validateFinalPosition();
        require(minIsOk_, "excess-leverage");

        emit leverageLog(amt_, transferAmt_);
    }

    /**
     * @dev If ratio is above then this function will allow anyone to payback WETH and withdraw astETH to msg.sender at 1:1 ratio.
     */
    function deleverage(uint256 amt_) external nonReentrant {
        uint256 transferAmt_ = deleverageInternal(amt_);
        (, , , bool minGapIsOk_, ) = validateFinalPosition();
        require(minGapIsOk_, "excess-deleverage");
        emit deleverageLog(amt_, transferAmt_);
    }

    /**
     * @dev Function to allow users to max withdraw
     */
    function deleverageAndWithdraw(
        uint256 deleverageAmt_,
        uint256 withdrawAmount_,
        address to_
    ) external nonReentrant {
        uint256 transferAmt_ = deleverageInternal(deleverageAmt_);
        uint256 vtokenAmt_ = withdrawInternal(withdrawAmount_, to_, true);

        emit deleverageAndWithdrawLog(
            deleverageAmt_,
            transferAmt_,
            vtokenAmt_,
            to_
        );
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "../common/helpers.sol";

contract Events is Helpers {
    event collectProfitLog(
        bool isWeth,
        uint256 withdrawAmt_,
        uint256 amt_,
        uint256 unitAmt_
    );

    event rebalanceOneLog(
        address flashTkn_,
        uint256 flashAmt_,
        uint256 route_,
        address[] vaults_,
        uint256[] amts_,
        uint256 leverageAmt_,
        uint256 swapAmt_,
        uint256 tokenSupplyAmt_,
        uint256 tokenWithdrawAmt_,
        uint256 unitAmt_
    );

    event rebalanceTwoLog(
        address flashTkn_,
        uint256 flashAmt_,
        uint256 route_,
        uint256 saveAmt_,
        uint256 unitAmt_
    );
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./events.sol";
import "../../../../infiniteProxy/IProxy.sol";

contract RebalancerModule is Events {
    using SafeERC20 for IERC20;

    /**
     * @dev Only rebalancer gaurd.
     */
    modifier onlyRebalancer() {
        require(
            _isRebalancer[msg.sender] ||
                IProxy(address(this)).getAdmin() == msg.sender,
            "only rebalancer"
        );
        _;
    }

    /**
     * @dev low gas function just to collect profit.
     * @notice Collected the profit & leave it in the DSA itself to optimize further on gas.
     */
    function collectProfit(
        bool isWeth, // either weth or steth
        uint256 withdrawAmt_,
        uint256 amt_,
        uint256 unitAmt_,
        bytes memory oneInchData_
    ) external nonReentrant onlyRebalancer {
        uint256 profits_ = getNewProfits();
        require(amt_ <= profits_, "amount-exceeds-profit");
        uint256 length_ = 1;
        if (withdrawAmt_ > 0) length_++;
        string[] memory targets_ = new string[](length_);
        bytes[] memory calldata_ = new bytes[](length_);
        address sellToken_ = isWeth
            ? address(wethContract)
            : address(stethContract);
        uint256 maxAmt_ = (getStethCollateralAmount() * _idealExcessAmt) /
            10000;
        if (withdrawAmt_ > 0) {
            if (isWeth) {
                targets_[0] = "AAVE-V2-A";
                calldata_[0] = abi.encodeWithSignature(
                    "borrow(address,uint256,uint256,uint256,uint256)",
                    address(wethContract),
                    withdrawAmt_,
                    2,
                    0,
                    0
                );
            } else {
                targets_[0] = "AAVE-V2-A";
                calldata_[0] = abi.encodeWithSignature(
                    "withdraw(address,uint256,uint256,uint256)",
                    address(stethContract),
                    withdrawAmt_,
                    0,
                    0
                );
            }
        }
        targets_[length_ - 1] = "1INCH-A";
        calldata_[length_ - 1] = abi.encodeWithSignature(
            "sell(address,address,uint256,uint256,bytes,uint256)",
            _token,
            sellToken_,
            amt_,
            unitAmt_,
            oneInchData_,
            0
        );
        _vaultDsa.cast(targets_, calldata_, address(this));
        if (withdrawAmt_ > 0)
            require(
                IERC20(sellToken_).balanceOf(address(_vaultDsa)) <= maxAmt_,
                "withdrawal-exceeds-max-limit"
            );

        emit collectProfitLog(isWeth, withdrawAmt_, amt_, unitAmt_);
    }

    struct RebalanceOneVariables {
        bool isOk;
        uint256 i;
        uint256 j;
        uint256 length;
        string[] targets;
        bytes[] calldatas;
        bool criticalIsOk;
        bool minIsOk;
    }

    /**
     * @dev Rebalancer function to leverage and rebalance the position.
     */
    function rebalanceOne(
        address flashTkn_,
        uint256 flashAmt_,
        uint256 route_,
        address[] memory vaults_, // leverage using other vaults
        uint256[] memory amts_,
        uint256 leverageAmt_,
        uint256 swapAmt_, // 1inch's swap amount
        uint256 tokenSupplyAmt_,
        uint256 tokenWithdrawAmt_,
        uint256 unitAmt_,
        bytes memory oneInchData_
    ) external nonReentrant onlyRebalancer {
        if (leverageAmt_ < 1e14) leverageAmt_ = 0;
        if (tokenWithdrawAmt_ < _tokenMinLimit) tokenWithdrawAmt_ = 0;
        if (tokenSupplyAmt_ >= _tokenMinLimit)
            _token.safeTransfer(address(_vaultDsa), tokenSupplyAmt_);

        RebalanceOneVariables memory v_;
        v_.isOk = validateLeverageAmt(vaults_, amts_, leverageAmt_, swapAmt_);
        require(v_.isOk, "swap-amounts-are-not-proper");

        v_.length = amts_.length;
        uint256 tokenDsaBal_ = _token.balanceOf(address(_vaultDsa));
        if (tokenDsaBal_ >= _tokenMinLimit) v_.j += 1;
        if (leverageAmt_ > 0) v_.j += 1;
        if (flashAmt_ > 0) v_.j += 3;
        if (swapAmt_ > 0) v_.j += 2; // only deposit stEth in Aave if swap amt > 0.
        if (v_.length > 0) v_.j += v_.length;
        if (tokenWithdrawAmt_ > 0) v_.j += 2;

        v_.targets = new string[](v_.j);
        v_.calldatas = new bytes[](v_.j);
        if (tokenDsaBal_ >= _tokenMinLimit) {
            v_.targets[v_.i] = "AAVE-V2-A";
            v_.calldatas[v_.i] = abi.encodeWithSignature(
                "deposit(address,uint256,uint256,uint256)",
                address(_token),
                type(uint256).max,
                0,
                0
            );
            v_.i++;
        }

        if (leverageAmt_ > 0) {
            if (flashAmt_ > 0) {
                v_.targets[v_.i] = "AAVE-V2-A";
                v_.calldatas[v_.i] = abi.encodeWithSignature(
                    "deposit(address,uint256,uint256,uint256)",
                    flashTkn_,
                    flashAmt_,
                    0,
                    0
                );
                v_.i++;
            }
            v_.targets[v_.i] = "AAVE-V2-A";
            v_.calldatas[v_.i] = abi.encodeWithSignature(
                "borrow(address,uint256,uint256,uint256,uint256)",
                address(wethContract),
                leverageAmt_,
                2,
                0,
                0
            );
            v_.i++;
            // Doing swaps from different vaults using deleverage to reduce other vaults riskiness if needed.
            // It takes WETH from vault and gives astETH at 1:1
            for (uint256 k = 0; k < v_.length; k++) {
                v_.targets[v_.i] = "LITE-A"; // Instadapp Lite vaults connector
                v_.calldatas[v_.i] = abi.encodeWithSignature(
                    "deleverage(address,uint256,uint256,uint256)",
                    vaults_[k],
                    amts_[k],
                    0,
                    0
                );
                v_.i++;
            }
            if (swapAmt_ > 0) {
                require(unitAmt_ > (1e18 - 10), "invalid-unit-amt");
                v_.targets[v_.i] = "1INCH-A";
                v_.calldatas[v_.i] = abi.encodeWithSignature(
                    "sell(address,address,uint256,uint256,bytes,uint256)",
                    address(stethContract),
                    address(wethContract),
                    swapAmt_,
                    unitAmt_,
                    oneInchData_,
                    0
                );
                v_.targets[v_.i + 1] = "AAVE-V2-A";
                v_.calldatas[v_.i + 1] = abi.encodeWithSignature(
                    "deposit(address,uint256,uint256,uint256)",
                    address(stethContract),
                    type(uint256).max,
                    0,
                    0
                );
                v_.i += 2;
            }
            if (flashAmt_ > 0) {
                v_.targets[v_.i] = "AAVE-V2-A";
                v_.calldatas[v_.i] = abi.encodeWithSignature(
                    "withdraw(address,uint256,uint256,uint256)",
                    flashTkn_,
                    flashAmt_,
                    0,
                    0
                );
                v_.targets[v_.i + 1] = "INSTAPOOL-C";
                v_.calldatas[v_.i + 1] = abi.encodeWithSignature(
                    "flashPayback(address,uint256,uint256,uint256)",
                    flashTkn_,
                    flashAmt_,
                    0,
                    0
                );
                v_.i += 2;
            }
        }
        if (tokenWithdrawAmt_ > 0) {
            v_.targets[v_.i] = "AAVE-V2-A";
            v_.calldatas[v_.i] = abi.encodeWithSignature(
                "withdraw(address,uint256,uint256,uint256)",
                _token,
                tokenWithdrawAmt_,
                0,
                0
            );
            v_.targets[v_.i + 1] = "BASIC-A";
            v_.calldatas[v_.i + 1] = abi.encodeWithSignature(
                "withdraw(address,uint256,address,uint256,uint256)",
                _token,
                tokenWithdrawAmt_,
                address(this),
                0,
                0
            );
            v_.i += 2;
        }

        if (flashAmt_ > 0) {
            bytes memory encodedFlashData_ = abi.encode(
                v_.targets,
                v_.calldatas
            );

            string[] memory flashTarget_ = new string[](1);
            bytes[] memory flashCalldata_ = new bytes[](1);
            flashTarget_[0] = "INSTAPOOL-C";
            flashCalldata_[0] = abi.encodeWithSignature(
                "flashBorrowAndCast(address,uint256,uint256,bytes,bytes)",
                flashTkn_,
                flashAmt_,
                route_,
                encodedFlashData_,
                "0x"
            );
            _vaultDsa.cast(flashTarget_, flashCalldata_, address(this));
        } else {
            if (v_.j > 0)
                _vaultDsa.cast(v_.targets, v_.calldatas, address(this));
        }
        if (leverageAmt_ > 0)
            require(
                getWethBorrowRate() < _ratios.maxBorrowRate,
                "high-borrow-rate"
            );

        (v_.criticalIsOk, , v_.minIsOk, , ) = validateFinalPosition();
        // this will allow auth to take position to max safe limit. Only have to execute when there's a need to make other vaults safer.
        if (IProxy(address(this)).getAdmin() == msg.sender) {
            if (leverageAmt_ > 0)
                require(v_.criticalIsOk, "aave position risky");
        } else {
            if (leverageAmt_ > 0)
                require(v_.minIsOk, "position risky after leverage");
            if (tokenWithdrawAmt_ > 0)
                require(v_.criticalIsOk, "aave position risky");
        }

        emit rebalanceOneLog(
            flashTkn_,
            flashAmt_,
            route_,
            vaults_,
            amts_,
            leverageAmt_,
            swapAmt_,
            tokenSupplyAmt_,
            tokenWithdrawAmt_,
            unitAmt_
        );
    }

    /**
     * @dev Rebalancer function for saving. To be run in times of making position less risky or to fill up the withdraw amount for users to exit
     */
    function rebalanceTwo(
        address flashTkn_,
        uint256 flashAmt_,
        uint256 route_,
        uint256 saveAmt_,
        uint256 tokenSupplyAmt_,
        uint256 unitAmt_,
        bytes memory oneInchData_
    ) external nonReentrant onlyRebalancer {
        require(unitAmt_ > (1e18 - _saveSlippage), "excess-slippage"); // TODO: set variable to update slippage? Here's it's 0.1% slippage.
        uint256 i;
        uint256 j;

        if (tokenSupplyAmt_ >= _tokenMinLimit)
            _token.safeTransfer(address(_vaultDsa), tokenSupplyAmt_);
        uint256 tokenDsaBal_ = _token.balanceOf(address(_vaultDsa));
        if (tokenDsaBal_ >= _tokenMinLimit) j += 1;
        if (saveAmt_ > 0) j += 3;
        if (flashAmt_ > 0) j += 3;
        string[] memory targets_ = new string[](j);
        bytes[] memory calldata_ = new bytes[](j);

        if (tokenDsaBal_ >= _tokenMinLimit) {
            targets_[i] = "AAVE-V2-A";
            calldata_[i] = abi.encodeWithSignature(
                "deposit(address,uint256,uint256,uint256)",
                address(_token),
                type(uint256).max,
                0,
                0
            );
            i++;
        }

        if (saveAmt_ > 0) {
            if (flashAmt_ > 0) {
                targets_[i] = "AAVE-V2-A";
                calldata_[i] = abi.encodeWithSignature(
                    "deposit(address,uint256,uint256,uint256)",
                    flashTkn_,
                    flashAmt_,
                    0,
                    0
                );
                i++;
            }
            targets_[i] = "AAVE-V2-A";
            calldata_[i] = abi.encodeWithSignature(
                "withdraw(address,uint256,uint256,uint256)",
                address(stethContract),
                saveAmt_,
                0,
                0
            );
            targets_[i + 1] = "1INCH-A";
            calldata_[i + 1] = abi.encodeWithSignature(
                "sell(address,address,uint256,uint256,bytes,uint256)",
                address(wethContract),
                address(stethContract),
                saveAmt_,
                unitAmt_,
                oneInchData_,
                1 // setId 1
            );
            targets_[i + 2] = "AAVE-V2-A";
            calldata_[i + 2] = abi.encodeWithSignature(
                "payback(address,uint256,uint256,uint256,uint256)",
                address(wethContract),
                0,
                2,
                1, // getId 1 to get the payback amount
                0
            );
            if (flashAmt_ > 0) {
                targets_[i + 3] = "AAVE-V2-A";
                calldata_[i + 3] = abi.encodeWithSignature(
                    "withdraw(address,uint256,uint256,uint256)",
                    flashTkn_,
                    flashAmt_,
                    0,
                    0
                );
                targets_[i + 4] = "INSTAPOOL-C";
                calldata_[i + 4] = abi.encodeWithSignature(
                    "flashPayback(address,uint256,uint256,uint256)",
                    flashTkn_,
                    flashAmt_,
                    0,
                    0
                );
            }
        }

        if (flashAmt_ > 0) {
            bytes memory encodedFlashData_ = abi.encode(targets_, calldata_);

            string[] memory flashTarget_ = new string[](1);
            bytes[] memory flashCalldata_ = new bytes[](1);
            flashTarget_[0] = "INSTAPOOL-C";
            flashCalldata_[0] = abi.encodeWithSignature(
                "flashBorrowAndCast(address,uint256,uint256,bytes,bytes)",
                flashTkn_,
                flashAmt_,
                route_,
                encodedFlashData_,
                "0x"
            );
            _vaultDsa.cast(flashTarget_, flashCalldata_, address(this));
        } else {
            if (j > 0) _vaultDsa.cast(targets_, calldata_, address(this));
        }

        (, bool isOk_, , , ) = validateFinalPosition();
        require(isOk_, "position-risky");

        emit rebalanceTwoLog(flashTkn_, flashAmt_, route_, saveAmt_, unitAmt_);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "../common/helpers.sol";

contract Events is Helpers {
    event updateRebalancerLog(address auth_, bool isAuth_);

    event changeStatusLog(uint256 status_);

    event updateRatiosLog(
        uint16 maxLimit,
        uint16 maxLimitGap,
        uint16 minLimit,
        uint16 minLimitGap,
        uint16 stEthLimit,
        uint128 maxBorrowRate
    );

    event updateFeesLog(
        uint256 revenueFee_,
        uint256 withdrawalFee_,
        uint256 swapFee_,
        uint256 deleverageFee_
    );

    event collectRevenueLog(
        uint256 amount_,
        address to_
    );

    event collectRevenueEthLog(
        uint256 amount_,
        uint256 stethAmt_,
        uint256 wethAmt_,
        address to_
    );
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./events.sol";
import "../../../../infiniteProxy/IProxy.sol";

contract AdminModule is Events {
    using SafeERC20 for IERC20;

    /**
     * @dev Only auth gaurd.
     */
    modifier onlyAuth() {
        require(IProxy(address(this)).getAdmin() == msg.sender, "only auth");
        _;
    }

    /**
     * @dev Update rebalancer.
     * @param rebalancer_ address of rebalancer.
     * @param isRebalancer_ true for setting the rebalancer, false for removing.
     */
    function updateRebalancer(address rebalancer_, bool isRebalancer_)
        external
        onlyAuth
    {
        _isRebalancer[rebalancer_] = isRebalancer_;
        emit updateRebalancerLog(rebalancer_, isRebalancer_);
    }

    /**
     * @dev Update all fees.
     * @param revenueFee_ new revenue fee.
     * @param withdrawalFee_ new withdrawal fee.
     * @param swapFee_ new swap fee or leverage fee.
     * @param deleverageFee_ new deleverage fee.
     */
    function updateFees(
        uint256 revenueFee_,
        uint256 withdrawalFee_,
        uint256 swapFee_,
        uint256 deleverageFee_
    ) external onlyAuth {
        require(revenueFee_ / 10000 == 0, "fees-not-valid");
        require(withdrawalFee_ / 10000 == 0, "fees-not-valid");
        require(swapFee_ / 10000 == 0, "fees-not-valid");
        require(deleverageFee_ / 10000 == 0, "fees-not-valid");
        _revenueFee = revenueFee_;
        _withdrawalFee = withdrawalFee_;
        _swapFee = swapFee_;
        _deleverageFee = deleverageFee_;
        emit updateFeesLog(
            revenueFee_,
            withdrawalFee_,
            swapFee_,
            deleverageFee_
        );
    }

    /**
     * @dev Update ratios.
     * @param ratios_ new ratios.
     */
    function updateRatios(uint16[] memory ratios_) external onlyAuth {
        _ratios = Ratios(
            ratios_[0],
            ratios_[1],
            ratios_[2],
            ratios_[3],
            ratios_[4],
            uint128(ratios_[5]) * 1e23
        );
        emit updateRatiosLog(
            ratios_[0],
            ratios_[1],
            ratios_[2],
            ratios_[3],
            ratios_[4],
            uint128(ratios_[5]) * 1e23
        );
    }

    /**
     * @dev Change status.
     * @param status_ new status, function to pause all functionality of the contract, status = 2 -> pause, status = 1 -> resume.
     */
    function changeStatus(uint256 status_) external onlyAuth {
        _status = status_;
        emit changeStatusLog(status_);
    }

    /**
     * @dev Function to collect token revenue.
     * @param amount_ amount to claim
     * @param to_ address to send the claimed revenue to
     */
    function collectRevenue(uint256 amount_, address to_) external onlyAuth {
        require(amount_ != 0, "amount-cannot-be-zero");
        if (amount_ == type(uint256).max) amount_ = _revenue;
        require(amount_ <= _revenue, "not-enough-revenue");
        _revenue -= amount_;
        uint256 tokenVaultBal_ = _token.balanceOf(address(this));
        require(tokenVaultBal_ >= amount_, "not-enough-amount-inside-vault");
        _token.safeTransfer(to_, amount_);
        emit collectRevenueLog(amount_, to_);
    }

    /**
     * @dev Function to collect eth revenue.
     * @param amount_ amount to claim
     * @param to_ address to send the claimed revenue to
     */
    function collectRevenueEth(uint256 amount_, address to_) external onlyAuth {
        require(amount_ != 0, "amount-cannot-be-zero");
        if (amount_ == type(uint256).max) amount_ = _revenueEth;
        require(amount_ <= _revenueEth, "not-enough-revenue");
        _revenueEth -= amount_;
        string[] memory targets_ = new string[](2);
        bytes[] memory calldata_ = new bytes[](2);
        targets_[0] = "AAVE-V2-A";
        calldata_[0] = abi.encodeWithSignature(
            "withdraw(address,uint256,uint256,uint256)",
            address(stethContract),
            amount_,
            0,
            0
        );
        targets_[1] = "BASIC-A";
        calldata_[1] = abi.encodeWithSignature(
            "withdraw(address,uint256,address,uint256,uint256)",
            address(stethContract),
            amount_,
            to_,
            0,
            0
        );
        _vaultDsa.cast(targets_, calldata_, address(this));
        (bool isOk_, , , , ) = validateFinalPosition();
        require(isOk_, "position-risky");
        emit collectRevenueEthLog(amount_, amount_, 0, to_);
    }

    /**
     * @dev function to initialize variables
     */
    function initialize(
        string memory name_,
        string memory symbol_,
        address rebalancer_,
        address token_,
        address atoken_,
        uint256 revenueFee_,
        uint256 withdrawalFee_,
        uint256 idealExcessAmt_,
        uint16[] memory ratios_,
        uint256 swapFee_,
        uint256 saveSlippage_,
        uint256 deleverageFee_
    ) external initializer onlyAuth {
        address vaultDsaAddr_ = instaIndex.build(
            address(this),
            2,
            address(this)
        );
        _vaultDsa = IDSA(vaultDsaAddr_);
        __ERC20_init(name_, symbol_);
        _isRebalancer[rebalancer_] = true;
        _token = IERC20(token_);
        _tokenDecimals = uint8(TokenInterface(token_).decimals());
        _atoken = IERC20(atoken_);
        _revenueFee = revenueFee_;
        _lastRevenueExchangePrice = 1e18;
        _withdrawalFee = withdrawalFee_;
        _idealExcessAmt = idealExcessAmt_;
        // sending borrow rate in 4 decimals eg:- 300 meaning 3% and converting into 27 decimals eg:- 3 * 1e25
        _ratios = Ratios(
            ratios_[0],
            ratios_[1],
            ratios_[2],
            ratios_[3],
            ratios_[4],
            uint128(ratios_[5]) * 1e23
        );
        _tokenMinLimit = _tokenDecimals > 17 ? 1e14 : _tokenDecimals > 11
            ? 1e11
            : _tokenDecimals > 5
            ? 1e4
            : 1;
        _swapFee = swapFee_;
        _saveSlippage = saveSlippage_;
        _deleverageFee = deleverageFee_;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "../common/helpers.sol";

contract ReadModule is Helpers {

    function isRebalancer(address accountAddr_) public view returns (bool) {
        return _isRebalancer[accountAddr_];
    }

    function token() public view returns (address) {
        return address(_token);
    }

    /**
     * @dev function to read decimals of itokens
     */
    function decimals() public view override returns (uint8) {
        return _tokenDecimals;
    }

    function tokenMinLimit() public view returns (uint256) {
        return _tokenMinLimit;
    }

    function atoken() public view returns (address) {
        return address(_atoken);
    }

    function vaultDsa() public view returns (address) {
        return address(_vaultDsa);
    }

    function ratios() public view returns (Ratios memory) {
        return _ratios;
    }

    function lastRevenueExchangePrice() public view returns (uint256) {
        return _lastRevenueExchangePrice;
    }

    function revenueFee() public view returns (uint256) {
        return _revenueFee;
    }

    function revenue() public view returns (uint256) {
        return _revenue;
    }

    function revenueEth() public view returns (uint256) {
        return _revenueEth;
    }

    function withdrawalFee() public view returns (uint256) {
        return _withdrawalFee;
    }

    function idealExcessAmt() public view returns (uint256) {
        return _idealExcessAmt;
    }

    function swapFee() public view returns (uint256) {
        return _swapFee;
    }
    
    function saveSlippage() public view returns (uint256) {
        return _saveSlippage;
    }

    function deleverageFee() public view returns (uint256) {
        return _deleverageFee;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "../common/variables.sol";
import "../../../../infiniteProxy/IProxy.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract SecurityModule is Variables {
    /**
     * @dev Only auth gaurd.
     */
    modifier onlyAuth() {
        require(IProxy(address(this)).getAdmin() == msg.sender, "only auth");
        _;
    }

    /**
     * @dev Admin Spell function
     * @param to_ target address
     * @param calldata_ function calldata
     * @param value_ function msg.value
     * @param operation_ .call or .delegate. (0 => .call, 1 => .delegateCall)
     */
    function spell(address to_, bytes memory calldata_, uint256 value_, uint256 operation_) external payable onlyAuth {
        if (operation_ == 0) {
            // .call
            Address.functionCallWithValue(to_, calldata_, value_, "spell: .call failed");
        } else if (operation_ == 1) {
            // .delegateCall
            Address.functionDelegateCall(to_, calldata_, "spell: .delegateCall failed");
        } else {
            revert("no operation");
        }
    }

    /**
     * @dev Admin function to add auth on DSA
     * @param auth_ new auth address for DSA
     */
    function addDSAAuth(address auth_) external onlyAuth {
        string[] memory targets_ = new string[](1);
        bytes[] memory calldata_ = new bytes[](1);
        targets_[0] = "AUTHORITY-A";
        calldata_[0] = abi.encodeWithSignature(
            "add(address)",
            auth_
        );
        _vaultDsa.cast(targets_, calldata_, address(this));
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "../common/variables.sol";
import "hardhat/console.sol";

contract ValidatePositionTestModule is Variables {
    /**
     * @dev reentrancy gaurd.
     */
    modifier nonReentrant() {
        require(_status != 2, "ReentrancyGuard: reentrant call");
        _status = 2;
        _;
        _status = 1;
    }

    /**
     * @dev Helper function to get current eth borrow rate on aave.
     */
    function getWethBorrowRate()
        internal
        view
        returns (uint256 wethBorrowRate_)
    {
        (, , , , wethBorrowRate_, , , , , ) = aaveProtocolDataProvider
            .getReserveData(address(wethContract));
    }

    /**
     * @dev Helper function to get current token collateral on aave.
     */
    function getTokenCollateralAmount()
        internal
        view
        returns (uint256 tokenAmount_)
    {
        tokenAmount_ = _atoken.balanceOf(address(_vaultDsa));
    }

    /**
     * @dev Helper function to get current steth collateral on aave.
     */
    function getStethCollateralAmount()
        internal
        view
        returns (uint256 stEthAmount_)
    {
        stEthAmount_ = astethToken.balanceOf(address(_vaultDsa));
    }

    /**
     * @dev Helper function to get current eth debt on aave.
     */
    function getWethDebtAmount()
        internal
        view
        returns (uint256 wethDebtAmount_)
    {
        wethDebtAmount_ = awethVariableDebtToken.balanceOf(address(_vaultDsa));
    }

    /**
     * @dev Helper function to token balances of everywhere.
     */
    function getVaultBalances()
        public
        view
        returns (
            uint256 tokenCollateralAmt_,
            uint256 stethCollateralAmt_,
            uint256 wethDebtAmt_,
            uint256 tokenVaultBal_,
            uint256 tokenDSABal_,
            uint256 netTokenBal_
        )
    {
        tokenCollateralAmt_ = getTokenCollateralAmount();
        stethCollateralAmt_ = getStethCollateralAmount();
        wethDebtAmt_ = getWethDebtAmount();
        tokenVaultBal_ = _token.balanceOf(address(this));
        tokenDSABal_ = _token.balanceOf(address(_vaultDsa));
        netTokenBal_ = tokenCollateralAmt_ + tokenVaultBal_ + tokenDSABal_;
    }

    struct ValidateFinalPosition {
        uint256 tokenPriceInBaseCurrency_;
        uint256 ethPriceInBaseCurrency_;
        uint256 excessDebtInBaseCurrency_;
        uint256 netTokenColInBaseCurrency_;
        uint256 netTokenSupplyInBaseCurrency_;
        uint256 ratioMax_;
        uint256 ratioMin_;
    }

    /**
     * @dev Helper function to validate the safety of aave position after rebalancing.
     */
    function validateFinalPosition()
        public
        view
        returns (
            bool criticalIsOk_,
            bool criticalGapIsOk_,
            bool minIsOk_,
            bool minGapIsOk_
        )
    {
        (
            uint256 tokenColAmt_,
            uint256 stethColAmt_,
            uint256 wethDebt_,
            ,
            ,
            uint256 netTokenBal_
        ) = getVaultBalances();

        uint256 ethCoveringDebt_ = (stethColAmt_ * _ratios.stEthLimit) / 10000;

        uint256 excessDebt_ = ethCoveringDebt_ < wethDebt_
            ? wethDebt_ - ethCoveringDebt_
            : 0;

        if (excessDebt_ > 0) {
            // TODO: add a fallback oracle fetching price from chainlink in case Aave changes oracle in future or in Aave v3?
            IAavePriceOracle aaveOracle_ = IAavePriceOracle(
                aaveAddressProvider.getPriceOracle()
            );

            ValidateFinalPosition memory validateFinalPosition_;
            validateFinalPosition_.tokenPriceInBaseCurrency_ = aaveOracle_.getAssetPrice(
                address(_token)
            );
            console.log("Token Price In BaseCurrency", validateFinalPosition_.tokenPriceInBaseCurrency_);
            validateFinalPosition_.ethPriceInBaseCurrency_ = aaveOracle_.getAssetPrice(
                address(wethContract)
            );
            console.log("ETH Price In BaseCurrency", validateFinalPosition_.ethPriceInBaseCurrency_);

            validateFinalPosition_.excessDebtInBaseCurrency_ = (excessDebt_ *
                validateFinalPosition_.ethPriceInBaseCurrency_) / 1e18;

            validateFinalPosition_.netTokenColInBaseCurrency_ = 
                (
                    tokenColAmt_ * validateFinalPosition_.tokenPriceInBaseCurrency_
                ) / (10**_tokenDecimals);

            validateFinalPosition_.netTokenSupplyInBaseCurrency_ = 
                (
                    netTokenBal_ * validateFinalPosition_.tokenPriceInBaseCurrency_
                ) / (10**_tokenDecimals);

            validateFinalPosition_.ratioMax_ = 
                (validateFinalPosition_.excessDebtInBaseCurrency_ * 10000) /
                    validateFinalPosition_.netTokenColInBaseCurrency_;

            validateFinalPosition_.ratioMin_ = 
                (validateFinalPosition_.excessDebtInBaseCurrency_ * 10000) /
                validateFinalPosition_.netTokenSupplyInBaseCurrency_;

            criticalIsOk_ = validateFinalPosition_.ratioMax_ < _ratios.maxLimit;
            criticalGapIsOk_ = validateFinalPosition_.ratioMax_ > _ratios.maxLimitGap;
            minIsOk_ = validateFinalPosition_.ratioMin_ < _ratios.minLimit;
            minGapIsOk_ = validateFinalPosition_.ratioMin_ > _ratios.minLimitGap;
            console.log("Ratio Max", validateFinalPosition_.ratioMax_);
            console.log("Ratio Min", validateFinalPosition_.ratioMin_);
        } else {
            criticalIsOk_ = true;
            minIsOk_ = true;
        }
    }


    /**
     * @dev Helper function to validate the safety of aave position after rebalancing.
     */
    function validateFinalPositionOld()
        public
        view
        returns (
            bool criticalIsOk_,
            bool criticalGapIsOk_,
            bool minIsOk_,
            bool minGapIsOk_
        )
    {
        (
            uint256 tokenColAmt_,
            uint256 stethColAmt_,
            uint256 wethDebt_,
            ,
            ,
            uint256 netTokenBal_
        ) = getVaultBalances();

        uint256 ethCoveringDebt_ = (stethColAmt_ * _ratios.stEthLimit) / 10000;

        uint256 excessDebt_ = ethCoveringDebt_ < wethDebt_
            ? wethDebt_ - ethCoveringDebt_
            : 0;

        if (excessDebt_ > 0) {
            // TODO: add a fallback oracle fetching price from chainlink in case Aave changes oracle in future or in Aave v3?
            uint256 tokenPriceInEth_ = IAavePriceOracle(
                aaveAddressProvider.getPriceOracle()
            ).getAssetPrice(address(_token));
            console.log("Token Price In ETH", tokenPriceInEth_);



            uint256 netTokenColInEth_ = (tokenColAmt_ * tokenPriceInEth_) /
                (10**_tokenDecimals);
            uint256 netTokenSupplyInEth_ = (netTokenBal_ * tokenPriceInEth_) /
                (10**_tokenDecimals);

            uint256 ratioMax_ = (excessDebt_ * 10000) / netTokenColInEth_;
            uint256 ratioMin_ = (excessDebt_ * 10000) / netTokenSupplyInEth_;

            criticalIsOk_ = ratioMax_ < _ratios.maxLimit;
            criticalGapIsOk_ = ratioMax_ > _ratios.maxLimitGap;
            minIsOk_ = ratioMin_ < _ratios.minLimit;
            minGapIsOk_ = ratioMin_ > _ratios.minLimitGap;
            console.log("Ratio Max", ratioMax_);
            console.log("Ratio Min", ratioMin_);
        } else {
            criticalIsOk_ = true;
            minIsOk_ = true;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../infiniteProxy/proxy.sol";

contract InstaVault is Proxy {
    constructor(address admin_, address dummyImplementation_)
        Proxy(admin_, dummyImplementation_)
    {}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract InstaVault is TransparentUpgradeableProxy {
    constructor(address _logic, address admin_, bytes memory _data) public TransparentUpgradeableProxy(_logic, admin_, _data) {}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

/**
 * @dev This is an auxiliary contract meant to be assigned as the admin of a {TransparentUpgradeableProxy}. For an
 * explanation of why you would want to use this see the documentation for {TransparentUpgradeableProxy}.
 */
contract InstaAdmin is ProxyAdmin {
    constructor(address _owner) {
        transferOwnership(_owner);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract UserModule {
    /**
     * @dev User function to supply.
     * @param token_ address of token.
     * @param amount_ amount to supply.
     * @param to_ address to send vTokens to.
     * @return vtokenAmount_ amount of vTokens sent to the `to_` address passed
     */
    function supply(
        address token_,
        uint256 amount_,
        address to_
    ) external returns (uint256 vtokenAmount_) {}

    /**
     * @dev User function to withdraw.
     * @param amount_ amount to withdraw.
     * @param to_ address to send tokens to.
     * @return vtokenAmount_ amount of vTokens burnt from caller
     */
    function withdraw(uint256 amount_, address to_)
        external
        returns (uint256 vtokenAmount_)
    {}

    /**
     * @dev If ratio is below then this function will allow anyone to swap from steth -> weth.
     * @param amt_ amount of stEth to swap for weth.
     */
    function leverage(uint256 amt_) external {}

    /**
     * @dev If ratio is above then this function will allow anyone to payback WETH and withdraw astETH to msg.sender at 1:1 ratio.
     * @param amt_ amount of weth to swap for steth.
     */
    function deleverage(uint256 amt_) external {}

    /**
     * @dev Function to allow users to max withdraw
     */
    function deleverageAndWithdraw(
        uint256 deleverageAmt_,
        uint256 withdrawAmount_,
        address to_
    ) external {}

    event supplyLog(
        uint256 amount_,
        address indexed caller_,
        address indexed to_
    );

    event withdrawLog(
        uint256 amount_,
        address indexed caller_,
        address indexed to_
    );

    event leverageLog(uint256 amt_, uint256 transferAmt_);

    event deleverageLog(uint256 amt_, uint256 transferAmt_);

    event deleverageAndWithdrawLog(
        uint256 deleverageAmt_,
        uint256 transferAmt_,
        uint256 vtokenAmount_,
        address to_
    );
}

contract RebalancerModule {
    /**
     * @dev low gas function just to collect profit.
     * @notice Collected the profit & leave it in the DSA itself to optimize further on gas.
     * @param isWeth what token to swap. WETH or stETH.
     * @param withdrawAmt_ need to borrow any weth amount or withdraw steth for swaps from Aave position.
     * @param amt_ amount to swap into base vault token.
     * @param unitAmt_ unit amount for swap.
     * @param oneInchData_ 1inch's data for the swaps.
     */
    function collectProfit(
        bool isWeth, // either weth or steth
        uint256 withdrawAmt_,
        uint256 amt_,
        uint256 unitAmt_,
        bytes memory oneInchData_
    ) external {}

    /**
     * @dev Rebalancer function to leverage and rebalance the position.
     */
    function rebalanceOne(
        address flashTkn_,
        uint256 flashAmt_,
        uint256 route_,
        address[] memory vaults_, // leverage using other vaults
        uint256[] memory amts_,
        uint256 leverageAmt_,
        uint256 swapAmt_, // 1inch's swap amount
        uint256 tokenSupplyAmt_,
        uint256 tokenWithdrawAmt_,
        uint256 unitAmt_,
        bytes memory oneInchData_
    ) external {}

    /**
     * @dev Rebalancer function for saving. To be run in times of making position less risky or to fill up the withdraw amount for users to exit
     */
    function rebalanceTwo(
        address flashTkn_,
        uint256 flashAmt_,
        uint256 route_,
        uint256 saveAmt_,
        uint256 tokenSupplyAmt_,
        uint256 unitAmt_,
        bytes memory oneInchData_
    ) external {}

    event collectProfitLog(
        bool isWeth,
        uint256 withdrawAmt_,
        uint256 amt_,
        uint256 unitAmt_
    );

    event rebalanceOneLog(
        address flashTkn_,
        uint256 flashAmt_,
        uint256 route_,
        address[] vaults_,
        uint256[] amts_,
        uint256 leverageAmt_,
        uint256 swapAmt_,
        uint256 tokenSupplyAmt_,
        uint256 tokenWithdrawAmt_,
        uint256 unitAmt_
    );

    event rebalanceTwoLog(
        address flashTkn_,
        uint256 flashAmt_,
        uint256 route_,
        uint256 saveAmt_,
        uint256 unitAmt_
    );
}

contract AdminModule {
    /**
     * @dev Update rebalancer.
     * @param rebalancer_ address of rebalancer.
     * @param isRebalancer_ true for setting the rebalancer, false for removing.
     */
    function updateRebalancer(address rebalancer_, bool isRebalancer_)
        external
    {}

    /**
     * @dev Update all fees.
     * @param revenueFee_ new revenue fee.
     * @param withdrawalFee_ new withdrawal fee.
     * @param swapFee_ new swap fee or leverage fee.
     * @param deleverageFee_ new deleverage fee.
     */
    function updateFees(
        uint256 revenueFee_,
        uint256 withdrawalFee_,
        uint256 swapFee_,
        uint256 deleverageFee_
    ) external {}

    /**
     * @dev Update ratios.
     * @param ratios_ new ratios.
     */
    function updateRatios(uint16[] memory ratios_) external {}

    /**
     * @dev Change status.
     * @param status_ new status, function to pause all functionality of the contract, status = 2 -> pause, status = 1 -> resume.
     */
    function changeStatus(uint256 status_) external {}

    /**
     * @dev Function to collect token revenue.
     * @param amount_ amount to claim
     * @param to_ address to send the claimed revenue to
     */
    function collectRevenue(uint256 amount_, address to_) external {}

    /**
     * @dev Function to collect eth revenue.
     * @param amount_ amount to claim
     * @param to_ address to send the claimed revenue to
     */
    function collectRevenueEth(uint256 amount_, address to_) external {}

    /**
     * @dev function to initialize variables
     */
    function initialize(
        string memory name_,
        string memory symbol_,
        address rebalancer_,
        address token_,
        address atoken_,
        uint256 revenueFee_,
        uint256 withdrawalFee_,
        uint256 idealExcessAmt_,
        uint16[] memory ratios_,
        uint256 swapFee_,
        uint256 saveSlippage_,
        uint256 deleverageFee_
    ) external {}

    event updateRebalancerLog(address auth_, bool isAuth_);

    event changeStatusLog(uint256 status_);

    event updateRatiosLog(
        uint16 maxLimit,
        uint16 maxLimitGap,
        uint16 minLimit,
        uint16 minLimitGap,
        uint16 stEthLimit,
        uint128 maxBorrowRate
    );

    event updateFeesLog(
        uint256 revenueFee_,
        uint256 withdrawalFee_,
        uint256 swapFee_,
        uint256 deleverageFee_
    );

    event collectRevenueLog(uint256 amount_, address to_);

    event collectRevenueEthLog(
        uint256 amount_,
        uint256 stethAmt_,
        uint256 wethAmt_,
        address to_
    );
}

contract ReadModule {
    function isRebalancer(address accountAddr_) public view returns (bool) {}

    /**
     * @dev Base token of the vault
     */
    function token() public view returns (address) {}

    /**
     * @dev Minimum token limit used inside the functions
     */
    function tokenMinLimit() public view returns (uint256) {}

    /**
     * @dev atoken of the base token of the vault
     */
    function atoken() public view returns (address) {}

    /**
     * @dev DSA for this particular vault
     */
    function vaultDsa() public view returns (address) {}

    struct Ratios {
        uint16 maxLimit; // Above this withdrawals are not allowed
        uint16 maxLimitGap;
        uint16 minLimit; // After leverage the ratio should be below minLimit & above minLimitGap
        uint16 minLimitGap;
        uint16 stEthLimit; // if 7500. Meaning stETH collateral covers 75% of the ETH debt. Excess ETH will be covered by token limit.
        // send borrow rate in 4 decimals from UI. In the smart contract it'll convert to 27 decimals which where is 100%
        uint128 maxBorrowRate; // maximum borrow rate above this leveraging should not happen
    }

    /**
     * @dev Ratios to set particular limits on leveraging, saving and risks of the vault.
     */
    function ratios() public view returns (Ratios memory) {}

    /**
     * @dev last stored revenue exchange price
     */
    function lastRevenueExchangePrice() public view returns (uint256) {}

    /**
     * @dev cut to take from the profits
     */
    function revenueFee() public view returns (uint256) {}

    /**
     * @dev base token revenue stored in the vault
     */
    function revenue() public view returns (uint256) {}

    /**
     * @dev ETH revenue stored in the vault
     */
    function revenueEth() public view returns (uint256) {}

    /**
     * @dev Withdrawl Fee of the vault
     */
    function withdrawalFee() public view returns (uint256) {}

    /**
     * @dev extra eth/stETH amount to leave in the vault for easier swaps.
     */
    function idealExcessAmt() public view returns (uint256) {}

    /**
     * @dev Fees of leverage swaps.
     */
    function swapFee() public view returns (uint256) {}

    /**
     * @dev Max allowed slippage at the time of saving the vault
     */
    function saveSlippage() public view returns (uint256) {}

    /**
     * @dev Fees of deleverage swaps.
     */
    function deleverageFee() public view returns (uint256) {}
}

contract SecurityModule {
    /**
     * @dev Admin Spell function
     * @param to_ target address
     * @param calldata_ function calldata
     * @param value_ function msg.value
     * @param operation_ .call or .delegate. (0 => .call, 1 => .delegateCall)
     */
    function spell(
        address to_,
        bytes memory calldata_,
        uint256 value_,
        uint256 operation_
    ) external payable {}

    /**
     * @dev Admin function to add auth on DSA
     * @param auth_ new auth address for DSA
     */
    function addDSAAuth(address auth_) external {}
}

contract HelperReadFunctions {
    /**
     * @dev Helper function to token balances of everywhere.
     */
    function getVaultBalances()
        public
        view
        returns (
            uint256 tokenCollateralAmt_,
            uint256 stethCollateralAmt_,
            uint256 wethDebtAmt_,
            uint256 tokenVaultBal_,
            uint256 tokenDSABal_,
            uint256 netTokenBal_
        )
    {}

    // returns net eth. net stETH + ETH - net ETH debt.
    function getNewProfits() public view returns (uint256 profits_) {}

    /**
     * @dev Helper function to get current exchange price and new revenue generated.
     */
    function getCurrentExchangePrice()
        public
        view
        returns (uint256 exchangePrice_, uint256 newTokenRevenue_)
    {}
}

contract ERC20Functions {
    function decimals() public view returns (uint8) {}

    function totalSupply() external view returns (uint256) {}

    function balanceOf(address account) external view returns (uint256) {}

    function transfer(address to, uint256 amount) external returns (bool) {}

    function allowance(address owner, address spender)
        external
        view
        returns (uint256)
    {}

    function approve(address spender, uint256 amount) external returns (bool) {}

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool) {}

    function name() external view returns (string memory) {}

    function symbol() external view returns (string memory) {}

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract VaultDummyImplementation is
    UserModule,
    RebalancerModule,
    AdminModule,
    ReadModule,
    SecurityModule,
    HelperReadFunctions,
    ERC20Functions
{
    receive() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Events {
    event setAdminLog(address oldAdmin_, address newAdmin_);

    event setDummyImplementationLog(
        address oldDummyImplementation_,
        address newDummyImplementation_
    );

    event setImplementationLog(address implementation_, bytes4[] sigs_);

    event removeImplementationLog(address implementation_);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IProxy {
    function getAdmin() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./events.sol";

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`.
 */
contract Internals is Events {
    struct AddressSlot {
        address value;
    }

    struct SigsSlot {
        bytes4[] value;
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT =
        0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Storage slot with the address of the current dummy-implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _DUMMY_IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Returns the storage slot which stores the sigs array set for the implementation.
     */
    function _getImplSigsSlot(address implementation_)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode("eip1967.proxy.implementation", implementation_)
            );
    }

    /**
     * @dev Returns the storage slot which stores the implementation address for the function sig.
     */
    function _getSigsImplSlot(bytes4 sig_) internal pure returns (bytes32) {
        return keccak256(abi.encode("eip1967.proxy.implementation", sig_));
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot_)
        internal
        pure
        returns (AddressSlot storage _r)
    {
        assembly {
            _r.slot := slot_
        }
    }

    /**
     * @dev Returns an `SigsSlot` with member `value` located at `slot`.
     */
    function getSigsSlot(bytes32 slot_)
        internal
        pure
        returns (SigsSlot storage _r)
    {
        assembly {
            _r.slot := slot_
        }
    }

    /**
     * @dev Sets new implementation and adds mapping from implementation to sigs and sig to implementation.
     */
    function _setImplementationSigs(
        address implementation_,
        bytes4[] memory sigs_
    ) internal {
        require(sigs_.length != 0, "no-sigs");
        bytes32 slot_ = _getImplSigsSlot(implementation_);
        bytes4[] memory sigsCheck_ = getSigsSlot(slot_).value;
        require(sigsCheck_.length == 0, "implementation-already-exist");
        for (uint256 i = 0; i < sigs_.length; i++) {
            bytes32 sigSlot_ = _getSigsImplSlot(sigs_[i]);
            require(
                getAddressSlot(sigSlot_).value == address(0),
                "sig-already-exist"
            );
            getAddressSlot(sigSlot_).value = implementation_;
        }
        getSigsSlot(slot_).value = sigs_;
        emit setImplementationLog(implementation_, sigs_);
    }

    /**
     * @dev Removes implementation and the mappings corresponding to it.
     */
    function _removeImplementationSigs(address implementation_) internal {
        bytes32 slot_ = _getImplSigsSlot(implementation_);
        bytes4[] memory sigs_ = getSigsSlot(slot_).value;
        require(sigs_.length != 0, "implementation-not-exist");
        for (uint256 i = 0; i < sigs_.length; i++) {
            bytes32 sigSlot_ = _getSigsImplSlot(sigs_[i]);
            delete getAddressSlot(sigSlot_).value;
        }
        delete getSigsSlot(slot_).value;
        emit removeImplementationLog(implementation_);
    }

    /**
     * @dev Returns bytes4[] sigs from implementation address. If implemenatation is not registered then returns empty array.
     */
    function _getImplementationSigs(address implementation_)
        internal
        view
        returns (bytes4[] memory)
    {
        bytes32 slot_ = _getImplSigsSlot(implementation_);
        return getSigsSlot(slot_).value;
    }

    /**
     * @dev Returns implementation address from bytes4 sig. If sig is not registered then returns address(0).
     */
    function _getSigImplementation(bytes4 sig_)
        internal
        view
        returns (address implementation_)
    {
        bytes32 slot_ = _getSigsImplSlot(sig_);
        return getAddressSlot(slot_).value;
    }

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Returns the current dummy-implementation.
     */
    function _getDummyImplementation() internal view returns (address) {
        return getAddressSlot(_DUMMY_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin_) internal {
        address oldAdmin_ = _getAdmin();
        require(
            newAdmin_ != address(0),
            "ERC1967: new admin is the zero address"
        );
        getAddressSlot(_ADMIN_SLOT).value = newAdmin_;
        emit setAdminLog(oldAdmin_, newAdmin_);
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setDummyImplementation(address newDummyImplementation_) internal {
        address oldDummyImplementation_ = _getDummyImplementation();
        getAddressSlot(_DUMMY_IMPLEMENTATION_SLOT)
            .value = newDummyImplementation_;
        emit setDummyImplementationLog(
            oldDummyImplementation_,
            newDummyImplementation_
        );
    }

    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _delegate(address implementation_) internal {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(
                gas(),
                implementation_,
                0,
                calldatasize(),
                0,
                0
            )

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev Delegates the current call to the address returned by Implementations registry.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _fallback(bytes4 sig_) internal {
        address implementation_ = _getSigImplementation(sig_);
        require(
            implementation_ != address(0),
            "Liquidity: Not able to find implementation_"
        );
        _delegate(implementation_);
    }
}

contract AdminStuff is Internals {
    /**
     * @dev Only admin gaurd.
     */
    modifier onlyAdmin() {
        require(msg.sender == _getAdmin(), "not-the-admin");
        _;
    }

    /**
     * @dev Sets new admin.
     */
    function setAdmin(address newAdmin_) external onlyAdmin {
        _setAdmin(newAdmin_);
    }

    /**
     * @dev Sets new dummy-implementation.
     */
    function setDummyImplementation(address newDummyImplementation_)
        external
        onlyAdmin
    {
        _setDummyImplementation(newDummyImplementation_);
    }

    /**
     * @dev Adds new implementation address.
     */
    function addImplementation(address implementation_, bytes4[] calldata sigs_)
        external
        onlyAdmin
    {
        _setImplementationSigs(implementation_, sigs_);
    }

    /**
     * @dev Removes an existing implementation address.
     */
    function removeImplementation(address implementation_) external onlyAdmin {
        _removeImplementationSigs(implementation_);
    }

    constructor(address admin_, address dummyImplementation_) {
        _setAdmin(admin_);
        _setDummyImplementation(dummyImplementation_);
    }
}

abstract contract Proxy is AdminStuff {
    constructor(address admin_, address dummyImplementation_)
        AdminStuff(admin_, dummyImplementation_)
    {}

    /**
     * @dev Returns admin's address.
     */
    function getAdmin() external view returns (address) {
        return _getAdmin();
    }

    /**
     * @dev Returns dummy-implementations's address.
     */
    function getDummyImplementation() external view returns (address) {
        return _getDummyImplementation();
    }

    /**
     * @dev Returns bytes4[] sigs from implementation address If not registered then returns empty array.
     */
    function getImplementationSigs(address impl_)
        external
        view
        returns (bytes4[] memory)
    {
        return _getImplementationSigs(impl_);
    }

    /**
     * @dev Returns implementation address from bytes4 sig. If sig is not registered then returns address(0).
     */
    function getSigsImplementation(bytes4 sig_)
        external
        view
        returns (address)
    {
        return _getSigImplementation(sig_);
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by Implementations registry.
     */
    fallback() external payable {
        _fallback(msg.sig);
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by Implementations registry.
     */
    receive() external payable {
        if (msg.sig != 0x00000000) {
            _fallback(msg.sig);
        }
    }
}

pragma solidity ^0.8.0;
import "./variables.sol";

contract Events is Variables {
    event updateAuthLog(address auth_);

    event updateVaultLog(address vaultAddr_, bool isVault_);

    event updatePremiumLog(uint256 premium_);

    event updatePremiumEthLog(uint256 premiumEth_);

    event withdrawPremiumLog(
        address[] tokens_,
        uint256[] amounts_,
        address to_
    );
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IFla {
    function flashLoan(
        address[] memory tokens_,
        uint256[] memory amts_,
        uint256 route,
        bytes calldata data_,
        bytes calldata instaData_
    ) external;
}

interface IVault {
    function getCurrentExchangePrice()
        external
        view
        returns (uint256 exchangePrice_, uint256 newRevenue_);

    function deleverageAndWithdraw(
        uint256 deleverageAmt_,
        uint256 withdrawAmount_,
        address to_
    ) external;

    function token() external view returns (address);

    function decimals() external view returns (uint8);

    function withdrawalFee() external view returns (uint256);
}

interface IAavePriceOracle {
    function getAssetPrice(address _asset) external view returns (uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./events.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract AdminModule is Events {
    using SafeERC20 for IERC20;

    /**
     * @dev Reentrancy gaurd.
     */
    modifier nonReentrant() {
        require(status != 2, "ReentrancyGuard: reentrant call");
        status = 2;
        _;
        status = 1;
    }

    /**
     * @dev Only auth gaurd.
     */
    modifier onlyAuth() {
        require(auth == msg.sender, "only auth");
        _;
    }

    /**
     * @dev Update auth.
     * @param auth_ address of new auth.
     */
    function updateAuth(address auth_) external onlyAuth {
        auth = auth_;
        emit updateAuthLog(auth_);
    }

    /**
     * @dev Update if vault or not.
     * @param vaultAddr_ address of vault.
     * @param isVault_ true for adding the vault, false for removing.
     */
    function updateVault(address vaultAddr_, bool isVault_) external onlyAuth {
        isVault[vaultAddr_] = isVault_;
        emit updateVaultLog(vaultAddr_, isVault_);
    }

    /**
     * @dev Update premium.
     * @param premium_ new premium.
     */
    function updatePremium(uint256 premium_) external onlyAuth {
        premium = premium_;
        emit updatePremiumLog(premium_);
    }

    /**
     * @dev Update premium.
     * @param premiumEth_ new premium.
     */
    function updatePremiumEth(uint256 premiumEth_) external onlyAuth {
        premiumEth = premiumEth_;
        emit updatePremiumEthLog(premiumEth_);
    }

    /**
     * @dev Function to withdraw premium collected.
     * @param tokens_ list of token addresses.
     * @param amounts_ list of corresponding amounts.
     * @param to_ address to transfer the funds to.
     */
    function withdrawPremium(
        address[] memory tokens_,
        uint256[] memory amounts_,
        address to_
    ) external onlyAuth {
        uint256 length_ = tokens_.length;
        require(amounts_.length == length_, "lengths not same");
        for (uint256 i = 0; i < length_; i++) {
            if (amounts_[i] == type(uint256).max)
                amounts_[i] = IERC20(tokens_[i]).balanceOf(address(this));
            IERC20(tokens_[i]).safeTransfer(to_, amounts_[i]);
        }
        emit withdrawPremiumLog(tokens_, amounts_, to_);
    }
}

contract InstaVaultWrapperImplementation is AdminModule {
    using SafeERC20 for IERC20;

    function deleverageAndWithdraw(
        address vaultAddr_,
        uint256 deleverageAmt_,
        uint256 withdrawAmount_,
        address to_,
        uint256 unitAmt_,
        bytes memory swapData_,
        uint256 route_,
        bytes memory instaData_
    ) external nonReentrant {
        require(unitAmt_ != 0, "unitAmt_ cannot be zero");
        require(isVault[vaultAddr_], "invalid vault");
        (uint256 exchangePrice_, ) = IVault(vaultAddr_)
            .getCurrentExchangePrice();
        uint256 itokenAmt_;
        if (withdrawAmount_ == type(uint256).max) {
            itokenAmt_ = IERC20(vaultAddr_).balanceOf(msg.sender);
            withdrawAmount_ = (itokenAmt_ * exchangePrice_) / 1e18;
        } else {
            itokenAmt_ = (withdrawAmount_ * 1e18) / exchangePrice_;
        }
        IERC20(vaultAddr_).safeTransferFrom(
            msg.sender,
            address(this),
            itokenAmt_
        );
        address[] memory wethList_ = new address[](1);
        wethList_[0] = address(wethContract);
        uint256[] memory wethAmtList_ = new uint256[](1);
        wethAmtList_[0] = deleverageAmt_;
        bytes memory data_ = abi.encode(
            vaultAddr_,
            withdrawAmount_,
            to_,
            unitAmt_,
            swapData_
        );
        fla.flashLoan(wethList_, wethAmtList_, route_, data_, instaData_);
    }

    struct InstaVars {
        address vaultAddr;
        uint256 withdrawAmt;
        uint256 withdrawAmtAfterFee;
        address to;
        uint256 unitAmt;
        bytes swapData;
        uint256 withdrawalFee;
        uint256 iniWethBal;
        uint256 iniStethBal;
        uint256 finWethBal;
        uint256 finStethBal;
        uint256 iniEthBal;
        uint256 finEthBal;
        uint256 ethReceived;
        uint256 stethReceived;
        uint256 iniTokenBal;
        uint256 finTokenBal;
        bool success;
        uint256 wethCut;
        uint256 wethAmtReceivedAfterSwap;
        address tokenAddr;
        uint256 tokenDecimals;
        uint256 tokenPriceInBaseCurrency;
        uint256 ethPriceInBaseCurrency;
        uint256 tokenPriceInEth;
        uint256 tokenCut;
    }

    function executeOperation(
        address[] memory tokens_,
        uint256[] memory amounts_,
        uint256[] memory premiums_,
        address initiator_,
        bytes memory params_
    ) external returns (bool) {
        require(msg.sender == address(fla), "illegal-caller");
        require(initiator_ == address(this), "illegal-initiator");
        require(
            tokens_.length == 1 && tokens_[0] == address(wethContract),
            "invalid-params"
        );

        InstaVars memory v_;
        (v_.vaultAddr, v_.withdrawAmt, v_.to, v_.unitAmt, v_.swapData) = abi
            .decode(params_, (address, uint256, address, uint256, bytes));
        IVault vault_ = IVault(v_.vaultAddr);
        v_.withdrawalFee = vault_.withdrawalFee();
        v_.withdrawAmtAfterFee =
            v_.withdrawAmt -
            ((v_.withdrawAmt * v_.withdrawalFee) / 1e4);
        wethContract.safeApprove(v_.vaultAddr, amounts_[0]);
        if (v_.vaultAddr == ethVaultAddr) {
            v_.iniEthBal = address(this).balance;
            v_.iniStethBal = stethContract.balanceOf(address(this));
            vault_.deleverageAndWithdraw(
                amounts_[0],
                v_.withdrawAmt,
                address(this)
            );
            v_.finEthBal = address(this).balance;
            v_.finStethBal = stethContract.balanceOf(address(this));
            v_.ethReceived = v_.finEthBal - v_.iniEthBal;
            v_.stethReceived = v_.finStethBal - amounts_[0] - v_.iniStethBal;
            require(
                v_.ethReceived + v_.stethReceived + 1e9 >=
                    v_.withdrawAmtAfterFee, // Adding small margin for any potential decimal error
                "something-went-wrong"
            );

            v_.iniWethBal = wethContract.balanceOf(address(this));
            stethContract.safeApprove(oneInchAddr, amounts_[0]);
            Address.functionCall(oneInchAddr, v_.swapData, "1Inch-swap-failed");
            v_.finWethBal = wethContract.balanceOf(address(this));
            v_.wethAmtReceivedAfterSwap = v_.finWethBal - v_.iniWethBal;
            require(
                v_.wethAmtReceivedAfterSwap != 0,
                "wethAmtReceivedAfterSwap cannot be zero"
            );
            require(
                v_.wethAmtReceivedAfterSwap >=
                    (amounts_[0] * v_.unitAmt) / 1e18,
                "Too-much-slippage"
            );

            v_.wethCut =
                amounts_[0] +
                premiums_[0] -
                v_.wethAmtReceivedAfterSwap;
            v_.wethCut = v_.wethCut + ((v_.wethCut * premiumEth) / 10000);
            if (v_.wethCut < v_.ethReceived) {
                Address.sendValue(payable(v_.to), v_.ethReceived - v_.wethCut);
                stethContract.safeTransfer(v_.to, v_.stethReceived);
            } else {
                v_.wethCut -= v_.ethReceived;
                stethContract.safeTransfer(
                    v_.to,
                    v_.stethReceived - v_.wethCut
                );
            }
        } else {
            v_.tokenAddr = vault_.token();
            v_.tokenDecimals = vault_.decimals();
            v_.tokenPriceInBaseCurrency = aaveOracle.getAssetPrice(
                v_.tokenAddr
            );
            v_.ethPriceInBaseCurrency = aaveOracle.getAssetPrice(
                address(wethContract)
            );
            v_.tokenPriceInEth =
                (v_.tokenPriceInBaseCurrency * 1e18) /
                v_.ethPriceInBaseCurrency;

            v_.iniTokenBal = IERC20(v_.tokenAddr).balanceOf(address(this));
            v_.iniStethBal = stethContract.balanceOf(address(this));
            vault_.deleverageAndWithdraw(
                amounts_[0],
                v_.withdrawAmt,
                address(this)
            );
            v_.finTokenBal = IERC20(v_.tokenAddr).balanceOf(address(this));
            v_.finStethBal = stethContract.balanceOf(address(this));
            require(
                v_.finTokenBal - v_.iniTokenBal >=
                    ((v_.withdrawAmtAfterFee * 99999999) / 100000000), // Adding small margin for any potential decimal error
                "something-went-wrong"
            );
            require(
                v_.finStethBal - v_.iniStethBal + 1e9 >= amounts_[0], // Adding small margin for any potential decimal error
                "something-went-wrong"
            );

            v_.iniWethBal = wethContract.balanceOf(address(this));
            stethContract.safeApprove(oneInchAddr, amounts_[0]);
            Address.functionCall(oneInchAddr, v_.swapData, "1Inch-swap-failed");
            v_.finWethBal = wethContract.balanceOf(address(this));
            v_.wethAmtReceivedAfterSwap = v_.finWethBal - v_.iniWethBal;
            require(
                v_.wethAmtReceivedAfterSwap != 0,
                "wethAmtReceivedAfterSwap cannot be zero"
            );
            require(
                v_.wethAmtReceivedAfterSwap >=
                    (amounts_[0] * v_.unitAmt) / 1e18,
                "Too-much-slippage"
            );
            v_.wethCut =
                amounts_[0] +
                premiums_[0] -
                v_.wethAmtReceivedAfterSwap;
            v_.wethCut = v_.wethCut + ((v_.wethCut * premium) / 10000);
            v_.tokenCut =
                (v_.wethCut * (10**v_.tokenDecimals)) /
                (v_.tokenPriceInEth);
            IERC20(v_.tokenAddr).safeTransfer(
                v_.to,
                v_.withdrawAmtAfterFee - v_.tokenCut
            );
        }
        wethContract.safeTransfer(address(fla), amounts_[0] + premiums_[0]);
        return true;
    }

    // function initialize(address auth_, uint256 premium_) external {
    //     require(status == 0, "only once");
    //     auth = auth_;
    //     premium = premium_;
    //     status = 1;
    // }

    receive() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract InstaDeleverageAndWithdrawWrapper is TransparentUpgradeableProxy {
    constructor(address _logic, address admin_, bytes memory _data) public TransparentUpgradeableProxy(_logic, admin_, _data) {}
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ConstantVariables {
    IFla internal constant fla =
        IFla(0x619Ad2D02dBeE6ebA3CDbDA3F98430410e892882);
    address internal constant oneInchAddr =
        0x1111111254fb6c44bAC0beD2854e76F90643097d;
    IERC20 internal constant wethContract =
        IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IERC20 internal constant stethContract =
        IERC20(0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84);
    address internal constant ethVaultAddr =
        0xc383a3833A87009fD9597F8184979AF5eDFad019;
    IAavePriceOracle internal constant aaveOracle =
        IAavePriceOracle(0xA50ba011c48153De246E5192C8f9258A2ba79Ca9);
}

contract Variables is ConstantVariables {
    uint256 internal status;

    address public auth;

    mapping(address => bool) public isVault;

    uint256 public premium; // premium for token vaults (in BPS)

    uint256 public premiumEth; // premium for eth vault (in BPS)
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IVault {
    function supply(
        address token_,
        uint256 amount_,
        address to_
    ) external returns (uint256 vtokenAmount_);
}

contract IEthSupplyWrapper {
    using SafeERC20 for IERC20;

    IVault internal constant ethVault =
        IVault(0xc383a3833A87009fD9597F8184979AF5eDFad019);
    address internal constant oneInchAddr =
        0x1111111254fb6c44bAC0beD2854e76F90643097d;
    IERC20 internal constant stethContract =
        IERC20(0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84);

    function supplyEth(address to_, bytes memory swapData_)
        external
        payable
        returns (uint256 vtokenAmount_)
    {
        require(msg.value > 0, "supply amount cannot be zero");
        uint256 iniStethBal_ = stethContract.balanceOf(address(this));
        Address.functionCallWithValue(oneInchAddr, swapData_, msg.value);
        uint256 finStethBal_ = stethContract.balanceOf(address(this));
        uint256 stethAmtReceived = finStethBal_ - iniStethBal_;
        require(stethAmtReceived > msg.value, "Too-much-slippage");
        vtokenAmount_ = ethVault.supply(
            address(stethContract),
            stethAmtReceived,
            to_
        );
    }

    constructor() {
        stethContract.safeApprove(address(ethVault), type(uint256).max);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

interface ITokenInterface {
    function getCurrentExchangePrice()
        external
        view
        returns (uint256 exchangePrice_, uint256 newRevenue_);
}

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function latestAnswer() external view returns (int256 answer);
}

contract IDAIPriceResolver {
    string public constant name = "iDAI-price-v1.0";
    ITokenInterface public constant iToken =
        ITokenInterface(0x40a9d39aa50871Df092538c5999b107f34409061);
    AggregatorV3Interface public constant chainLinkOracleEth =
        AggregatorV3Interface(0x773616E4d11A78F511299002da57A0a94577F1f4); // DAI/ETH
    AggregatorV3Interface public constant chainLinkOracleUsd =
        AggregatorV3Interface(0xAed0c38402a5d19df6E4c03F4E2DceD6e29c1ee9); // DAI/USD

    function getPriceInEth() public view returns (uint256) {
        (uint256 exchangeRate, ) = iToken.getCurrentExchangePrice();
        int256 tokenPriceInEth = chainLinkOracleEth.latestAnswer();
        uint8 decimals = chainLinkOracleEth.decimals();
        return (exchangeRate * uint256(tokenPriceInEth)) / (10**decimals);
    }

    function getPriceInUsd() public view returns (uint256 priceInUsd) {
        (uint256 exchangeRate, ) = iToken.getCurrentExchangePrice();
        int256 tokenPriceInUsd = chainLinkOracleUsd.latestAnswer();
        uint8 decimals = chainLinkOracleUsd.decimals();
        return (exchangeRate * uint256(tokenPriceInUsd)) / (10**decimals);
    }

    function getExchangeRate() public view returns (uint256 exchangeRate) {
        (exchangeRate, ) = iToken.getCurrentExchangePrice();
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

interface IETHInterface {
    function getCurrentExchangePrice()
            external
            view
            returns (uint256 exchangePrice_, uint256 newRevenue_);
}

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

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

contract IETHPriceResolver {
    string public constant name = "iETH-price-v1.0";

    IETHInterface public constant iToken = IETHInterface(0xc383a3833A87009fD9597F8184979AF5eDFad019); // iETH
    AggregatorV3Interface public constant chainLinkOracle = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419); // ETH/USD

    function getPriceInUsd() public view returns (uint256 priceInUsd) {
        (uint256 exchangeRate, ) =  iToken.getCurrentExchangePrice();
        ( , int256 oraclePrice, , , ) = chainLinkOracle.latestRoundData();
        uint8 decimals = chainLinkOracle.decimals();

        return (exchangeRate * uint256(oraclePrice)) / (10 ** decimals);
    }

    function getPriceInEth() public view returns (uint256 priceInEth) {
        (uint256 exchangeRate, ) =  iToken.getCurrentExchangePrice();
        return (exchangeRate);
    }

    function getExchangeRate() public view returns (uint256 exchangeRate) {
        (exchangeRate, ) =  iToken.getCurrentExchangePrice();
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

interface ITokenInterface {
    function getCurrentExchangePrice()
        external
        view
        returns (uint256 exchangePrice_, uint256 newRevenue_);
}

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function latestAnswer() external view returns (int256 answer);
}

contract IUSDCPriceResolver {
    string public constant name = "iUSDC-price-v1.0";
    ITokenInterface public constant iToken =
        ITokenInterface(0xc8871267e07408b89aA5aEcc58AdCA5E574557F8);
    AggregatorV3Interface public constant chainLinkOracleEth =
        AggregatorV3Interface(0x986b5E1e1755e3C2440e960477f25201B0a8bbD4); // USDC/ETH
    AggregatorV3Interface public constant chainLinkOracleUsd =
        AggregatorV3Interface(0x8fFfFfd4AfB6115b954Bd326cbe7B4BA576818f6); // USDC/USD

    function getPriceInEth() public view returns (uint256) {
        (uint256 exchangeRate, ) = iToken.getCurrentExchangePrice();
        int256 tokenPriceInEth = chainLinkOracleEth.latestAnswer();
        uint8 decimals = chainLinkOracleEth.decimals();
        return (exchangeRate * uint256(tokenPriceInEth)) / (10**decimals);
    }

    function getPriceInUsd() public view returns (uint256 priceInUsd) {
        (uint256 exchangeRate, ) = iToken.getCurrentExchangePrice();
        int256 tokenPriceInUsd = chainLinkOracleUsd.latestAnswer();
        uint8 decimals = chainLinkOracleUsd.decimals();
        return (exchangeRate * uint256(tokenPriceInUsd)) / (10**decimals);
    }

    function getExchangeRate() public view returns (uint256 exchangeRate) {
        (exchangeRate, ) = iToken.getCurrentExchangePrice();
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

interface ITokenInterface {
    function getCurrentExchangePrice()
        external
        view
        returns (uint256 exchangePrice_, uint256 newRevenue_);
}

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function latestAnswer() external view returns (int256 answer);
}

contract IWBTCPriceResolver {
    string public constant name = "iWBTC-price-v1.0";
    ITokenInterface public constant iToken =
        ITokenInterface(0xEC363faa5c4dd0e51f3D9B5d0101263760E7cdeB);
    AggregatorV3Interface public constant chainLinkOracleWbtcinBtc =
        AggregatorV3Interface(0xfdFD9C85aD200c506Cf9e21F1FD8dd01932FBB23); // WBTC/BTC
    AggregatorV3Interface public constant chainLinkOracleEth =
        AggregatorV3Interface(0xdeb288F737066589598e9214E782fa5A8eD689e8); // BTC/ETH
    AggregatorV3Interface public constant chainLinkOracleUsd =
        AggregatorV3Interface(0xF4030086522a5bEEa4988F8cA5B36dbC97BeE88c); // BTC/USD

    function getPriceInEth() public view returns (uint256) {
        (uint256 exchangeRate, ) = iToken.getCurrentExchangePrice();
        int256 tokenPriceInEth = chainLinkOracleEth.latestAnswer();
        uint8 tokenOracleDecimals = chainLinkOracleEth.decimals();
        int256 wbtcPriceInBtc = chainLinkOracleWbtcinBtc.latestAnswer();
        uint8 wbtcOracleDecimals = chainLinkOracleWbtcinBtc.decimals();
        return
            (exchangeRate *
                uint256(tokenPriceInEth) *
                uint256(wbtcPriceInBtc)) /
            ((10**tokenOracleDecimals) * (10**wbtcOracleDecimals));
    }

    function getPriceInUsd() public view returns (uint256 priceInUsd) {
        (uint256 exchangeRate, ) = iToken.getCurrentExchangePrice();
        int256 tokenPriceInUsd = chainLinkOracleUsd.latestAnswer();
        uint8 tokenOracleDecimals = chainLinkOracleUsd.decimals();
        int256 wbtcPriceInBtc = chainLinkOracleWbtcinBtc.latestAnswer();
        uint8 wbtcOracleDecimals = chainLinkOracleWbtcinBtc.decimals();
        return
            (exchangeRate *
                uint256(tokenPriceInUsd) *
                uint256(wbtcPriceInBtc)) /
            ((10**tokenOracleDecimals) * (10**wbtcOracleDecimals));
    }

    function getExchangeRate() public view returns (uint256 exchangeRate) {
        (exchangeRate, ) = iToken.getCurrentExchangePrice();
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface VaultInterface {
    function balanceOf(address account) external view returns (uint256);

    function getCurrentExchangePrice()
        external
        view
        returns (uint256 exchangePrice_, uint256 newRevenue_);

    struct BalVariables {
        uint256 wethVaultBal;
        uint256 wethDsaBal;
        uint256 stethVaultBal;
        uint256 stethDsaBal;
        uint256 totalBal;
    }

    function netAssets()
        external
        view
        returns (
            uint256 netCollateral_,
            uint256 netBorrow_,
            BalVariables memory balances_,
            uint256 netSupply_,
            uint256 netBal_
        );

    struct Ratios {
        uint16 maxLimit; // Above this withdrawals are not allowed
        uint16 minLimit; // After leverage the ratio should be below minLimit & above minLimitGap
        uint16 minLimitGap;
        // send borrow rate in 4 decimals from UI. In the smart contract it'll convert to 27 decimals which where is 100%
        uint128 maxBorrowRate; // maximum borrow rate above this leveraging should not happen
    }

    // maximum borrow rate. If above this limit then leverage won't happen
    function ratios() external view returns (Ratios memory);

    function vaultDsa() external view returns (address);

    function lastRevenueExchangePrice() external view returns (uint256);

    function revenueFee() external view returns (uint256);

    function revenue() external view returns (uint256);

    function totalSupply() external view returns (uint256);
}

interface IAaveAddressProvider {
    function getPriceOracle() external view returns (address);

    function getLendingPool() external view returns (address);
}

interface IAavePriceOracle {
    function getAssetPrice(address _asset) external view returns (uint256);
}

interface IAaveLendingPool {
    function getUserAccountData(address) external view returns (uint256, uint256, uint256, uint256, uint256, uint256);
}

interface Vault2Interface {
    function token() external view returns (address);

    function decimals() external view returns (uint8);

    function tokenMinLimit() external view returns (uint256);

    function atoken() external view returns (address);

    function vaultDsa() external view returns (address);

    struct Ratios {
        uint16 maxLimit; // Above this withdrawals are not allowed
        uint16 maxLimitGap;
        uint16 minLimit; // After leverage the ratio should be below minLimit & above minLimitGap
        uint16 minLimitGap;
        uint16 stEthLimit; // if 7500. Meaning stETH collateral covers 75% of the ETH debt. Excess ETH will be covered by token limit.
        // send borrow rate in 4 decimals from UI. In the smart contract it'll convert to 27 decimals which where is 100%
        uint128 maxBorrowRate; // maximum borrow rate above this leveraging should not happen
    }

    function ratios() external view returns (Ratios memory);

    function getCurrentExchangePrice()
        external
        view
        returns (uint256 exchangePrice_, uint256 newRevenue_);

    function lastRevenueExchangePrice() external view returns (uint256);

    function revenueFee() external view returns (uint256);

    function revenue() external view returns (uint256);

    function revenueEth() external view returns (uint256);

    function withdrawalFee() external view returns (uint256);

    function idealExcessAmt() external view returns (uint256);

    function swapFee() external view returns (uint256);

    function deleverageFee() external view returns (uint256);

    function saveSlippage() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function getVaultBalances()
        external
        view
        returns (
            uint256 tokenCollateralAmt_,
            uint256 stethCollateralAmt_,
            uint256 wethDebtAmt_,
            uint256 tokenVaultBal_,
            uint256 tokenDSABal_,
            uint256 netTokenBal_
        );

    function getNewProfits() external view returns (uint256 profits_);

    function balanceOf(address account) external view returns (uint256);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./variables.sol";

contract DeleverageAmounts is Variables {
    function getMaxDeleverageAmt(address vaultAddr_)
        public
        view
        returns (uint256 amount_)
    {
        if (vaultAddr_ == address(vault)) {
            VaultInterface.Ratios memory ratio_ = vault.ratios();
            (, uint netBorrow_, , uint netSupply_,) = vault.netAssets();
            // 1e4 + 10
            uint minLimitGap_ = ratio_.minLimitGap + 10; // 0.1% margin
            amount_ = ((netBorrow_ * 1e4) - (minLimitGap_ * netSupply_)) / (1e4 - minLimitGap_);
        } else {
            Vault2Interface vault_ = Vault2Interface(vaultAddr_);
            address tokenAddr_ = vault_.token();
            uint256 tokenDecimals_ = vault_.decimals();
            (
                ,
                uint256 stethCollateral_,
                uint256 wethDebt_,
                ,
                ,
                uint256 netTokenBal_
            ) = vault_.getVaultBalances();
            Vault2Interface.Ratios memory ratios_ = vault_.ratios();
            uint256 ethCoveringDebt_ = (stethCollateral_ * ratios_.stEthLimit) /
                10000;
            uint256 excessDebt_ = ethCoveringDebt_ < wethDebt_
                ? wethDebt_ - ethCoveringDebt_
                : 0;
            uint256 tokenPriceInEth_ = IAavePriceOracle(
                aaveAddressProvider.getPriceOracle()
            ).getAssetPrice(tokenAddr_);
            uint256 netTokenSupplyInEth_ = (netTokenBal_ * tokenPriceInEth_) /
                (10**tokenDecimals_);
            uint256 currentRatioMin_ = netTokenSupplyInEth_ == 0
                ? 0
                : (excessDebt_ * 10000) / netTokenSupplyInEth_;
            if (currentRatioMin_ > ratios_.minLimit) {
                // keeping 0.1% margin for final ratio
                amount_ =
                    ((currentRatioMin_ - (ratios_.minLimitGap + 10)) *
                        netTokenSupplyInEth_) /
                    (10000 - ratios_.stEthLimit);
            }
        }
    }

    function getMaxDeleverageAmts(address[] memory vaults_)
        public
        view
        returns (uint256[] memory amounts_)
    {
        amounts_ = new uint256[](vaults_.length);
        for (uint256 i = 0; i < vaults_.length; i++) {
            amounts_[i] = getMaxDeleverageAmt(vaults_[i]);
        }
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./interfaces.sol";

contract Variables {
    VaultInterface public constant vault =
        VaultInterface(0xc383a3833A87009fD9597F8184979AF5eDFad019);
    IAaveAddressProvider internal constant aaveAddressProvider =
        IAaveAddressProvider(0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5);
    address public constant wethAddr =
        0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant stEthAddr =
        0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./interfaces.sol";

contract Helpers {
    VaultInterface public constant vault =
        VaultInterface(0xc383a3833A87009fD9597F8184979AF5eDFad019);
    IAaveAddressProvider internal constant aaveAddressProvider =
        IAaveAddressProvider(0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5);
    address internal constant wethAddr =
        0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address internal constant stEthAddr =
        0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;

    function getMaxDeleverageAmt(address vaultAddr_)
        internal
        view
        returns (uint256 amount_)
    {
        Vault2Interface vault_ = Vault2Interface(vaultAddr_);
        address tokenAddr_ = vault_.token();
        uint256 tokenDecimals_ = vault_.decimals();
        (
            ,
            uint256 stethCollateral_,
            uint256 wethDebt_,
            ,
            ,
            uint256 netTokenBal_
        ) = vault_.getVaultBalances();
        Vault2Interface.Ratios memory ratios_ = vault_.ratios();
        uint256 ethCoveringDebt_ = (stethCollateral_ * ratios_.stEthLimit) /
            10000;
        uint256 excessDebt_ = ethCoveringDebt_ < wethDebt_
            ? wethDebt_ - ethCoveringDebt_
            : 0;
        uint256 tokenPriceInEth_ = IAavePriceOracle(
            aaveAddressProvider.getPriceOracle()
        ).getAssetPrice(tokenAddr_);
        uint256 netTokenSupplyInEth_ = (netTokenBal_ * tokenPriceInEth_) /
            (10**tokenDecimals_);
        uint256 currentRatioMin_ = netTokenSupplyInEth_ == 0
            ? 0
            : (excessDebt_ * 10000) / netTokenSupplyInEth_;
        if (currentRatioMin_ > ratios_.minLimit) {
            // keeping 0.1% margin for final ratio
            amount_ =
                ((currentRatioMin_ - (ratios_.minLimitGap + 10)) *
                    netTokenSupplyInEth_) /
                (10000 - ratios_.stEthLimit);
        }
    }

    function getMaxDeleverageAmts(address[] memory vaults_)
        internal
        view
        returns (uint256[] memory amounts_)
    {
        amounts_ = new uint256[](vaults_.length);
        for (uint256 i = 0; i < vaults_.length; i++) {
            amounts_[i] = getMaxDeleverageAmt(vaults_[i]);
        }
    }

// // /// /  NO USE OF BELOW FUNCTIONS IN NEW VAULT  // // / // / //

    function bubbleSort(address[] memory vaults_, uint256[] memory amounts_)
        internal
        pure
        returns (address[] memory, uint256[] memory)
    {
        for (uint256 i = 0; i < amounts_.length - 1; i++) {
            for (uint256 j = 0; j < amounts_.length - i - 1; j++) {
                if (amounts_[j] < amounts_[j + 1]) {
                    (
                        vaults_[j],
                        vaults_[j + 1],
                        amounts_[j],
                        amounts_[j + 1]
                    ) = (
                        vaults_[j + 1],
                        vaults_[j],
                        amounts_[j + 1],
                        amounts_[j]
                    );
                }
            }
        }
        return (vaults_, amounts_);
    }

    function getTrimmedArrays(
        address[] memory vaults_,
        uint256[] memory amounts_,
        uint256 length_
    )
        internal
        pure
        returns (address[] memory finalVaults_, uint256[] memory finalAmts_)
    {
        finalVaults_ = new address[](length_);
        finalAmts_ = new uint256[](length_);
        for (uint256 i = 0; i < length_; i++) {
            finalVaults_[i] = vaults_[i];
            finalAmts_[i] = amounts_[i];
        }
    }

    function getVaultsToUse(
        address[] memory vaultsToCheck_,
        uint256[] memory deleverageAmts_,
        uint256 totalSwapAmt_
    )
        internal
        pure
        returns (
            address[] memory vaults_,
            uint256[] memory amounts_,
            uint256 swapAmt_
        )
    {
        (vaults_, amounts_) = bubbleSort(vaultsToCheck_, deleverageAmts_);
        swapAmt_ = totalSwapAmt_;
        uint256 i;
        while (swapAmt_ > 0 && i < vaults_.length && amounts_[i] > 0) {
            if (amounts_[i] > swapAmt_) amounts_[i] = swapAmt_;
            swapAmt_ -= amounts_[i];
            i++;
        }
        if (i != vaults_.length)
            (vaults_, amounts_) = getTrimmedArrays(vaults_, amounts_, i);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface VaultInterface {
    function balanceOf(address account) external view returns (uint256);

    function getCurrentExchangePrice()
        external
        view
        returns (uint256 exchangePrice_, uint256 newRevenue_);

    struct BalVariables {
        uint256 wethVaultBal;
        uint256 wethDsaBal;
        uint256 stethVaultBal;
        uint256 stethDsaBal;
        uint256 totalBal;
    }

    function netAssets()
        external
        view
        returns (
            uint256 netCollateral_,
            uint256 netBorrow_,
            BalVariables memory balances_,
            uint256 netSupply_,
            uint256 netBal_
        );

    struct Ratios {
        uint16 maxLimit; // Above this withdrawals are not allowed
        uint16 minLimit; // After leverage the ratio should be below minLimit & above minLimitGap
        uint16 minLimitGap;
        // send borrow rate in 4 decimals from UI. In the smart contract it'll convert to 27 decimals which where is 100%
        uint128 maxBorrowRate; // maximum borrow rate above this leveraging should not happen
    }

    // maximum borrow rate. If above this limit then leverage won't happen
    function ratios() external view returns (Ratios memory);

    function vaultDsa() external view returns (address);

    function lastRevenueExchangePrice() external view returns (uint256);

    function revenueFee() external view returns (uint256);

    function revenue() external view returns (uint256);

    function totalSupply() external view returns (uint256);
}

interface IAaveAddressProvider {
    function getPriceOracle() external view returns (address);

    function getLendingPool() external view returns (address);
}

interface IAavePriceOracle {
    function getAssetPrice(address _asset) external view returns (uint256);
}

interface IAaveLendingPool {
    function getUserAccountData(address) external view returns (uint256, uint256, uint256, uint256, uint256, uint256);
}

interface Vault2Interface {
    function token() external view returns (address);

    function decimals() external view returns (uint8);

    function tokenMinLimit() external view returns (uint256);

    function atoken() external view returns (address);

    function vaultDsa() external view returns (address);

    struct Ratios {
        uint16 maxLimit; // Above this withdrawals are not allowed
        uint16 maxLimitGap;
        uint16 minLimit; // After leverage the ratio should be below minLimit & above minLimitGap
        uint16 minLimitGap;
        uint16 stEthLimit; // if 7500. Meaning stETH collateral covers 75% of the ETH debt. Excess ETH will be covered by token limit.
        // send borrow rate in 4 decimals from UI. In the smart contract it'll convert to 27 decimals which where is 100%
        uint128 maxBorrowRate; // maximum borrow rate above this leveraging should not happen
    }

    function ratios() external view returns (Ratios memory);

    function getCurrentExchangePrice()
        external
        view
        returns (uint256 exchangePrice_, uint256 newRevenue_);

    function lastRevenueExchangePrice() external view returns (uint256);

    function revenueFee() external view returns (uint256);

    function revenue() external view returns (uint256);

    function revenueEth() external view returns (uint256);

    function withdrawalFee() external view returns (uint256);

    function idealExcessAmt() external view returns (uint256);

    function swapFee() external view returns (uint256);

    function deleverageFee() external view returns (uint256);

    function saveSlippage() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function getVaultBalances()
        external
        view
        returns (
            uint256 tokenCollateralAmt_,
            uint256 stethCollateralAmt_,
            uint256 wethDebtAmt_,
            uint256 tokenVaultBal_,
            uint256 tokenDSABal_,
            uint256 netTokenBal_
        );

    function getNewProfits() external view returns (uint256 profits_);

    function balanceOf(address account) external view returns (uint256);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./helpers.sol";

contract InstaVaultResolver is Helpers {
    struct VaultInfo {
        address vaultAddr;
        address vaultDsa;
        uint256 revenue;
        uint256 revenueFee;
        VaultInterface.Ratios ratios;
        uint256 lastRevenueExchangePrice;
        uint256 exchangePrice;
        uint256 totalSupply;
        uint256 netCollateral;
        uint256 netBorrow;
        VaultInterface.BalVariables balances;
        uint256 netSupply;
        uint256 netBal;
    }

    function getVaultInfo() public view returns (VaultInfo memory vaultInfo_) {
        vaultInfo_.vaultAddr = address(vault);
        vaultInfo_.vaultDsa = vault.vaultDsa();
        vaultInfo_.revenue = vault.revenue();
        vaultInfo_.revenueFee = vault.revenueFee();
        vaultInfo_.ratios = vault.ratios();
        vaultInfo_.lastRevenueExchangePrice = vault.lastRevenueExchangePrice();
        (vaultInfo_.exchangePrice, ) = vault.getCurrentExchangePrice();
        vaultInfo_.totalSupply = vault.totalSupply();
        (
            vaultInfo_.netCollateral,
            vaultInfo_.netBorrow,
            vaultInfo_.balances,
            vaultInfo_.netSupply,
            vaultInfo_.netBal
        ) = vault.netAssets();
    }

    function getUserInfo(address user_)
        public
        view
        returns (
            VaultInfo memory vaultInfo_,
            uint256 vtokenBal_,
            uint256 amount_
        )
    {
        vaultInfo_ = getVaultInfo();
        vtokenBal_ = vault.balanceOf(user_);
        amount_ = (vtokenBal_ * vaultInfo_.exchangePrice) / 1e18;
    }

    struct RebalanceVariables {
        uint256 netCollateral;
        uint256 netBorrow;
        VaultInterface.BalVariables balances;
        uint256 netSupply;
        uint256 netBal;
        uint256 netBalUsed;
        uint256 netStEth;
        int256 netWeth;
        uint256 ratio;
        uint256 targetRatio;
        uint256 targetRatioDif;
        uint256[] deleverageAmts;
        uint256 hf;
        bool hfIsOk;
    }

    // This function gives data around leverage position
    function rebalanceOneData(address[] memory vaultsToCheck_)
        public
        view
        returns (
            uint256 finalCol_,
            uint256 finalDebt_,
            address flashTkn_,
            uint256 flashAmt_,
            uint256 route_,
            address[] memory vaults_,
            uint256[] memory amts_,
            uint256 excessDebt_,
            uint256 paybackDebt_,
            uint256 totalAmountToSwap_,
            uint256 extraWithdraw_,
            bool isRisky_
        )
    {
        RebalanceVariables memory v_;
        (v_.netCollateral, v_.netBorrow, v_.balances, , v_.netBal) = vault
            .netAssets();
        if (v_.balances.wethVaultBal <= 1e14) v_.balances.wethVaultBal = 0;
        if (v_.balances.stethVaultBal <= 1e14) v_.balances.stethVaultBal = 0;
        VaultInterface.Ratios memory ratios_ = vault.ratios();
        v_.netStEth =
            v_.netCollateral +
            v_.balances.stethVaultBal +
            v_.balances.stethDsaBal;
        v_.netWeth =
            int256(v_.balances.wethVaultBal + v_.balances.wethDsaBal) -
            int256(v_.netBorrow);
        v_.ratio = v_.netWeth < 0
            ? (uint256(-v_.netWeth) * 1e4) / v_.netStEth
            : 0;
            // 1% = 100
        v_.targetRatioDif = 10000 - (ratios_.minLimit - 10); // taking 0.1% more dif for margin
        if (v_.ratio < ratios_.minLimitGap) {
            // leverage till minLimit <> minLimitGap
            // final difference between collateral & debt in percent
            finalCol_ = (v_.netBal * 1e4) / v_.targetRatioDif;
            finalDebt_ = finalCol_ - v_.netBal;
            excessDebt_ = finalDebt_ - v_.netBorrow;
            flashTkn_ = wethAddr;
            flashAmt_ = (v_.netCollateral / 10) + ((excessDebt_ * 10) / 8); // 10% of current collateral + excessDebt / 0.8
            route_ = 5;
            totalAmountToSwap_ =
                excessDebt_ +
                v_.balances.wethVaultBal +
                v_.balances.wethDsaBal;
            v_.deleverageAmts = getMaxDeleverageAmts(vaultsToCheck_);
            (vaults_, amts_, totalAmountToSwap_) = getVaultsToUse(
                vaultsToCheck_,
                v_.deleverageAmts,
                totalAmountToSwap_
            );
            (, , , , , v_.hf) = IAaveLendingPool(
                aaveAddressProvider.getLendingPool()
            ).getUserAccountData(vault.vaultDsa());
            v_.hfIsOk = v_.hf > 1015 * 1e15;
            // only withdraw from aave position if position is safe
            if (v_.hfIsOk) {
                // keeping as non collateral for easier withdrawals
                extraWithdraw_ =
                    finalCol_ -
                    ((finalDebt_ * 1e4) / (ratios_.maxLimit - 10));
            }
        } else {
            finalCol_ = v_.netStEth;
            finalDebt_ = uint256(-v_.netWeth);
            paybackDebt_ = v_.balances.wethVaultBal + v_.balances.wethDsaBal;
            (, , , , , v_.hf) = IAaveLendingPool(
                aaveAddressProvider.getLendingPool()
            ).getUserAccountData(vault.vaultDsa());
            v_.hfIsOk = v_.hf > 1015 * 1e15;
            // only withdraw from aave position if position is safe
            if (v_.ratio < (ratios_.maxLimit - 10) && v_.hfIsOk) {
                extraWithdraw_ =
                    finalCol_ -
                    ((finalDebt_ * 1e4) / (ratios_.maxLimit - 10));
            }
        }
        if (v_.ratio > ratios_.maxLimit) {
            isRisky_ = true;
        }

        if (excessDebt_ < 1e14) excessDebt_ = 0;
        if (paybackDebt_ < 1e14) paybackDebt_ = 0;
        if (totalAmountToSwap_ < 1e14) totalAmountToSwap_ = 0;
        if (extraWithdraw_ < 1e14) extraWithdraw_ = 0;
    }

    function rebalanceTwoData()
        public
        view
        returns (
            uint256 finalCol_,
            uint256 finalDebt_,
            uint256 withdrawAmt_, // always returned zero as of now
            address flashTkn_,
            uint256 flashAmt_,
            uint256 route_,
            uint256 saveAmt_,
            bool hfIsOk_
        )
    {
        RebalanceVariables memory v_;
        (, , , , , v_.hf) = IAaveLendingPool(
            aaveAddressProvider.getLendingPool()
        ).getUserAccountData(vault.vaultDsa());
        hfIsOk_ = v_.hf > 1015 * 1e15;
        (v_.netCollateral, v_.netBorrow, v_.balances, v_.netSupply,) = vault
            .netAssets();
        VaultInterface.Ratios memory ratios_ = vault.ratios();
        if (hfIsOk_) {
            v_.ratio = (v_.netBorrow * 1e4) / v_.netCollateral;
            v_.targetRatioDif = 10000 - (ratios_.maxLimit - 100); // taking 1% more dif for margin
            if (v_.ratio > ratios_.maxLimit) {
                v_.netBalUsed =
                    v_.netCollateral +
                    v_.balances.wethDsaBal -
                    v_.netBorrow;
                finalCol_ = (v_.netBalUsed * 1e4) / v_.targetRatioDif;
                finalDebt_ = finalCol_ - v_.netBalUsed;
                saveAmt_ = v_.netBorrow - finalDebt_ - v_.balances.wethDsaBal;
            }
        } else {
            v_.ratio = (v_.netBorrow * 1e4) / v_.netSupply;
            v_.targetRatio = (ratios_.minLimitGap + 10); // taking 0.1% more dif for margin
            v_.targetRatioDif = 10000 - v_.targetRatio;
            if (v_.ratio > ratios_.minLimit) {
                saveAmt_ =
                    ((1e4 * (v_.netBorrow - v_.balances.wethDsaBal)) -
                        (v_.targetRatio *
                            (v_.netSupply - v_.balances.wethDsaBal))) /
                    v_.targetRatioDif;
                finalCol_ = v_.netCollateral - saveAmt_;
                finalDebt_ = v_.netBorrow - saveAmt_ - v_.balances.wethDsaBal;
            }
        }
        flashTkn_ = wethAddr;
        flashAmt_ = (v_.netCollateral / 10) + ((saveAmt_ * 10) / 8); // 10% of current collateral + saveAmt_ / 0.8
        route_ = 5;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./interfaces.sol";

contract Helpers {
    IAaveAddressProvider internal constant aaveAddressProvider =
        IAaveAddressProvider(0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5);
    address internal constant wethAddr =
        0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address internal constant stEthAddr =
        0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;

    function checkIfBorrowAllowed(address vaultDsaAddr_, uint256 wethBorrowAmt_) internal view returns (bool) {
        (,, uint256 availableBorrowsETH,,,) = IAaveLendingPool(aaveAddressProvider.getLendingPool()).getUserAccountData(vaultDsaAddr_);
        return wethBorrowAmt_ < availableBorrowsETH;
    }

    function getMaxDeleverageAmt(address vaultAddr_)
        internal
        view
        returns (uint256 amount_)
    {
        VaultInterface vault_ = VaultInterface(vaultAddr_);
        address tokenAddr_ = vault_.token();
        uint256 tokenDecimals_ = vault_.decimals();
        (
            ,
            uint256 stethCollateral_,
            uint256 wethDebt_,
            ,
            ,
            uint256 netTokenBal_
        ) = vault_.getVaultBalances();
        VaultInterface.Ratios memory ratios_ = vault_.ratios();
        uint256 ethCoveringDebt_ = (stethCollateral_ * ratios_.stEthLimit) /
            10000;
        uint256 excessDebt_ = ethCoveringDebt_ < wethDebt_
            ? wethDebt_ - ethCoveringDebt_
            : 0;
        uint256 tokenPriceInEth_ = IAavePriceOracle(
            aaveAddressProvider.getPriceOracle()
        ).getAssetPrice(tokenAddr_);
        uint256 netTokenSupplyInEth_ = (netTokenBal_ * tokenPriceInEth_) /
            (10**tokenDecimals_);
        uint256 currentRatioMin_ = netTokenSupplyInEth_ == 0
            ? 0
            : (excessDebt_ * 10000) / netTokenSupplyInEth_;
        if (currentRatioMin_ > ratios_.minLimit) {
            // keeping 0.1% margin for final ratio
            amount_ =
                ((currentRatioMin_ - (ratios_.minLimitGap + 10)) *
                    netTokenSupplyInEth_) /
                (10000 - ratios_.stEthLimit);
        }
    }

    function getMaxDeleverageAmts(address[] memory vaults_)
        internal
        view
        returns (uint256[] memory amounts_)
    {
        amounts_ = new uint256[](vaults_.length);
        for (uint256 i = 0; i < vaults_.length; i++) {
            amounts_[i] = getMaxDeleverageAmt(vaults_[i]);
        }
    }

    function bubbleSort(address[] memory vaults_, uint256[] memory amounts_)
        internal
        pure
        returns (address[] memory, uint256[] memory)
    {
        for (uint256 i = 0; i < amounts_.length - 1; i++) {
            for (uint256 j = 0; j < amounts_.length - i - 1; j++) {
                if (amounts_[j] < amounts_[j + 1]) {
                    (
                        vaults_[j],
                        vaults_[j + 1],
                        amounts_[j],
                        amounts_[j + 1]
                    ) = (
                        vaults_[j + 1],
                        vaults_[j],
                        amounts_[j + 1],
                        amounts_[j]
                    );
                }
            }
        }
        return (vaults_, amounts_);
    }

    function getTrimmedArrays(
        address[] memory vaults_,
        uint256[] memory amounts_,
        uint256 length_
    )
        internal
        pure
        returns (address[] memory finalVaults_, uint256[] memory finalAmts_)
    {
        finalVaults_ = new address[](length_);
        finalAmts_ = new uint256[](length_);
        for (uint256 i = 0; i < length_; i++) {
            finalVaults_[i] = vaults_[i];
            finalAmts_[i] = amounts_[i];
        }
    }

    function getVaultsToUse(
        address[] memory vaultsToCheck_,
        uint256[] memory deleverageAmts_,
        uint256 leverageAmt_
    )
        internal
        pure
        returns (
            address[] memory vaults_,
            uint256[] memory amounts_,
            uint256 swapAmt_
        )
    {
        (vaults_, amounts_) = bubbleSort(vaultsToCheck_, deleverageAmts_);
        swapAmt_ = leverageAmt_;
        uint256 i;
        while (swapAmt_ > 0 && i < vaults_.length && amounts_[i] > 0) {
            if (amounts_[i] > swapAmt_) amounts_[i] = swapAmt_;
            swapAmt_ -= amounts_[i];
            i++;
        }
        if (i != vaults_.length)
            (vaults_, amounts_) = getTrimmedArrays(vaults_, amounts_, i);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IAaveAddressProvider {
    function getPriceOracle() external view returns (address);

    function getLendingPool() external view returns (address);
}

interface IAavePriceOracle {
    function getAssetPrice(address _asset) external view returns (uint256);
}

interface IAaveLendingPool {
    function getUserAccountData(address user)
        external
        view
        returns (
            uint256 totalCollateralETH,
            uint256 totalDebtETH,
            uint256 availableBorrowsETH,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor
        );
}

interface VaultInterface {
    function token() external view returns (address);

    function decimals() external view returns (uint8);

    function tokenMinLimit() external view returns (uint256);

    function atoken() external view returns (address);

    function vaultDsa() external view returns (address);

    struct Ratios {
        uint16 maxLimit; // Above this withdrawals are not allowed
        uint16 maxLimitGap;
        uint16 minLimit; // After leverage the ratio should be below minLimit & above minLimitGap
        uint16 minLimitGap;
        uint16 stEthLimit; // if 7500. Meaning stETH collateral covers 75% of the ETH debt. Excess ETH will be covered by token limit.
        // send borrow rate in 4 decimals from UI. In the smart contract it'll convert to 27 decimals which where is 100%
        uint128 maxBorrowRate; // maximum borrow rate above this leveraging should not happen
    }

    function ratios() external view returns (Ratios memory);

    function getCurrentExchangePrice()
        external
        view
        returns (uint256 exchangePrice_, uint256 newRevenue_);

    function lastRevenueExchangePrice() external view returns (uint256);

    function revenueFee() external view returns (uint256);

    function revenue() external view returns (uint256);

    function revenueEth() external view returns (uint256);

    function withdrawalFee() external view returns (uint256);

    function idealExcessAmt() external view returns (uint256);

    function swapFee() external view returns (uint256);

    function deleverageFee() external view returns (uint256);

    function saveSlippage() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function getVaultBalances()
        external
        view
        returns (
            uint256 tokenCollateralAmt_,
            uint256 stethCollateralAmt_,
            uint256 wethDebtAmt_,
            uint256 tokenVaultBal_,
            uint256 tokenDSABal_,
            uint256 netTokenBal_
        );

    function getNewProfits() external view returns (uint256 profits_);

    function balanceOf(address account) external view returns (uint256);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./helpers.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract InstaVaultResolver is Helpers {
    struct VaultInfo {
        address token;
        uint8 decimals;
        uint256 tokenMinLimit;
        address atoken;
        address vaultDsa;
        VaultInterface.Ratios ratios;
        uint256 exchangePrice;
        uint256 lastRevenueExchangePrice;
        uint256 revenueFee;
        uint256 revenue;
        uint256 revenueEth;
        uint256 withdrawalFee;
        uint256 idealExcessAmt;
        uint256 swapFee;
        uint256 deleverageFee;
        uint256 saveSlippage;
        uint256 vTokenTotalSupply;
        uint256 tokenCollateralAmt;
        uint256 tokenVaultBal;
        uint256 tokenDSABal;
        uint256 netTokenBal;
        uint256 stethCollateralAmt;
        uint256 stethVaultBal;
        uint256 stethDSABal;
        uint256 wethDebtAmt;
        uint256 wethVaultBal;
        uint256 wethDSABal;
        uint256 tokenPriceInEth;
        uint256 currentRatioMax;
        uint256 currentRatioMin;
        uint256 availableWithdraw;
    }

    function getVaultInfo(address vaultAddr_)
        public
        view
        returns (VaultInfo memory vaultInfo_)
    {
        VaultInterface vault = VaultInterface(vaultAddr_);
        vaultInfo_.token = vault.token();
        vaultInfo_.decimals = vault.decimals();
        vaultInfo_.tokenMinLimit = vault.tokenMinLimit();
        vaultInfo_.atoken = vault.atoken();
        vaultInfo_.vaultDsa = vault.vaultDsa();
        vaultInfo_.ratios = vault.ratios();
        (vaultInfo_.exchangePrice, ) = vault.getCurrentExchangePrice();
        vaultInfo_.lastRevenueExchangePrice = vault.lastRevenueExchangePrice();
        vaultInfo_.revenueFee = vault.revenueFee();
        vaultInfo_.revenue = vault.revenue();
        vaultInfo_.revenueEth = vault.revenueEth();
        vaultInfo_.withdrawalFee = vault.withdrawalFee();
        vaultInfo_.idealExcessAmt = vault.idealExcessAmt();
        vaultInfo_.swapFee = vault.swapFee();
        vaultInfo_.deleverageFee = vault.deleverageFee();
        vaultInfo_.saveSlippage = vault.saveSlippage();
        vaultInfo_.vTokenTotalSupply = vault.totalSupply();
        (
            vaultInfo_.tokenCollateralAmt,
            vaultInfo_.stethCollateralAmt,
            vaultInfo_.wethDebtAmt,
            vaultInfo_.tokenVaultBal,
            vaultInfo_.tokenDSABal,
            vaultInfo_.netTokenBal
        ) = vault.getVaultBalances();
        vaultInfo_.stethVaultBal = IERC20(stEthAddr).balanceOf(vaultAddr_);
        vaultInfo_.stethDSABal = IERC20(stEthAddr).balanceOf(
            vaultInfo_.vaultDsa
        );
        vaultInfo_.wethVaultBal = IERC20(wethAddr).balanceOf(vaultAddr_);
        vaultInfo_.wethDSABal = IERC20(wethAddr).balanceOf(vaultInfo_.vaultDsa);

        vaultInfo_.tokenPriceInEth = IAavePriceOracle(
            aaveAddressProvider.getPriceOracle()
        ).getAssetPrice(vaultInfo_.token);
        uint256 netTokenColInEth_ = (vaultInfo_.tokenCollateralAmt *
            vaultInfo_.tokenPriceInEth) / (10**vaultInfo_.decimals);
        uint256 netTokenSupplyInEth_ = (vaultInfo_.netTokenBal *
            vaultInfo_.tokenPriceInEth) / (10**vaultInfo_.decimals);
        uint256 ethCoveringDebt_ = (vaultInfo_.stethCollateralAmt *
            vaultInfo_.ratios.stEthLimit) / 10000;
        uint256 excessDebt_ = ethCoveringDebt_ < vaultInfo_.wethDebtAmt
            ? vaultInfo_.wethDebtAmt - ethCoveringDebt_
            : 0;
        vaultInfo_.currentRatioMax = netTokenColInEth_ == 0
            ? 0
            : (excessDebt_ * 10000) / netTokenColInEth_;
        vaultInfo_.currentRatioMin = netTokenSupplyInEth_ == 0
            ? 0
            : (excessDebt_ * 10000) / netTokenSupplyInEth_;
        vaultInfo_.availableWithdraw =
            vaultInfo_.tokenVaultBal +
            vaultInfo_.tokenDSABal;
        uint256 maxLimitThreshold = vaultInfo_.ratios.maxLimit - 100; // keeping 1% margin
        if (vaultInfo_.currentRatioMax < maxLimitThreshold) {
            vaultInfo_.availableWithdraw += (((maxLimitThreshold -
                vaultInfo_.currentRatioMax) * vaultInfo_.tokenCollateralAmt) /
                maxLimitThreshold);
        }
    }

    struct UserInfo {
        address vaultAddr;
        VaultInfo vaultInfo;
        uint256 tokenBal;
        uint256 vtokenBal;
        uint256 withdrawAmount;
    }

    function getUserInfo(address[] memory vaults_, address user_)
        public
        view
        returns (UserInfo[] memory userInfos_)
    {
        userInfos_ = new UserInfo[](vaults_.length);
        for (uint256 i = 0; i < vaults_.length; i++) {
            VaultInterface vault = VaultInterface(vaults_[i]);
            userInfos_[i].vaultAddr = vaults_[i];
            userInfos_[i].vaultInfo = getVaultInfo(vaults_[i]);
            userInfos_[i].tokenBal = IERC20(userInfos_[i].vaultInfo.token)
                .balanceOf(user_);
            userInfos_[i].vtokenBal = vault.balanceOf(user_);
            userInfos_[i].withdrawAmount =
                (userInfos_[i].vtokenBal *
                    userInfos_[i].vaultInfo.exchangePrice) /
                1e18;
        }
    }

    function collectProfitData(address vaultAddr_)
        public
        view
        returns (bool isEth_, uint256 withdrawAmt_, uint256 amt_)
    {
        VaultInterface vault = VaultInterface(vaultAddr_);
        address vaultDsaAddr_ = vault.vaultDsa();
        uint256 profits_ = (vault.getNewProfits() * 99) / 100; // keeping 1% margin
        uint256 vaultDsaWethBal_ = IERC20(wethAddr).balanceOf(vaultDsaAddr_);
        uint256 vaultDsaStethBal_ = IERC20(stEthAddr).balanceOf(vaultDsaAddr_);

        if (profits_ > vaultDsaWethBal_ && profits_ > vaultDsaStethBal_) {
            (, uint256 stethCollateralAmt_, , , , ) = vault.getVaultBalances();
            uint256 maxAmt_ = (stethCollateralAmt_ * vault.idealExcessAmt()) /
                10000;
            maxAmt_ = (maxAmt_ * 99) / 100; // keeping 1% margin
            uint256 wethBorrowAmt_ = maxAmt_ + profits_ - vaultDsaWethBal_;
            uint256 stethWithdrawAmt_ = maxAmt_ + profits_ - vaultDsaStethBal_;
            if (checkIfBorrowAllowed(vaultDsaAddr_, wethBorrowAmt_)) {
                withdrawAmt_ = wethBorrowAmt_;
                isEth_ = true;
            } else {
                withdrawAmt_ = stethWithdrawAmt_;
            }
        } else if (profits_ <= vaultDsaWethBal_) isEth_ = true;
        amt_ = profits_;
    }

    struct RebalanceOneVariables {
        address tokenAddr;
        uint256 tokenDecimals;
        uint256 tokenMinLimit;
        uint256 tokenVaultBal;
        uint256 netTokenBal;
        VaultInterface.Ratios ratios;
        uint256 stethCollateral;
        uint256 wethDebt;
        uint256 ethCoveringDebt;
        uint256 excessDebt;
        uint256 tokenPriceInEth;
        uint256 netTokenSupplyInEth;
        uint256 currentRatioMin;
        uint256[] deleverageAmts;
    }

    function rebalanceOneData(
        address vaultAddr_,
        address[] memory vaultsToCheck_
    )
        public
        view
        returns (
            address flashTkn_, // currently its always weth addr
            uint256 flashAmt_,
            uint256 route_,
            address[] memory vaults_,
            uint256[] memory amts_,
            uint256 leverageAmt_,
            uint256 swapAmt_,
            uint256 tokenSupplyAmt_,
            uint256 tokenWithdrawAmt_ // currently always returned zero
        )
    {
        RebalanceOneVariables memory v_;
        VaultInterface vault_ = VaultInterface(vaultAddr_);
        v_.tokenAddr = vault_.token();
        v_.tokenDecimals = vault_.decimals();
        v_.tokenMinLimit = vault_.tokenMinLimit();
        (
            ,
            v_.stethCollateral,
            v_.wethDebt,
            v_.tokenVaultBal,
            ,
            v_.netTokenBal
        ) = vault_.getVaultBalances();
        if (v_.tokenVaultBal > v_.tokenMinLimit)
            tokenSupplyAmt_ = v_.tokenVaultBal;
        v_.ratios = vault_.ratios();
        v_.ethCoveringDebt =
            (v_.stethCollateral * v_.ratios.stEthLimit) /
            10000;
        v_.excessDebt = v_.ethCoveringDebt < v_.wethDebt
            ? v_.wethDebt - v_.ethCoveringDebt
            : 0;
        v_.tokenPriceInEth = IAavePriceOracle(
            aaveAddressProvider.getPriceOracle()
        ).getAssetPrice(v_.tokenAddr);
        v_.netTokenSupplyInEth =
            (v_.netTokenBal * v_.tokenPriceInEth) /
            (10**v_.tokenDecimals);
        v_.currentRatioMin = v_.netTokenSupplyInEth == 0
            ? 0
            : (v_.excessDebt * 10000) / v_.netTokenSupplyInEth;
        if (v_.currentRatioMin < v_.ratios.minLimitGap) {
            // keeping 0.1% margin for final ratio
            leverageAmt_ =
                (((v_.ratios.minLimit - 10) - v_.currentRatioMin) *
                    v_.netTokenSupplyInEth) /
                (10000 - v_.ratios.stEthLimit);
            flashTkn_ = wethAddr;
            // TODO: dont take flashloan if not needed
            flashAmt_ =
                (v_.netTokenSupplyInEth / 10) +
                ((leverageAmt_ * 10) / 8); // 10% of current collateral(in eth) + leverageAmt_ / 0.8
            route_ = 5;
            v_.deleverageAmts = getMaxDeleverageAmts(vaultsToCheck_);
            (vaults_, amts_, swapAmt_) = getVaultsToUse(
                vaultsToCheck_,
                v_.deleverageAmts,
                leverageAmt_
            );
        }
    }

    struct RebalanceTwoVariables {
        address tokenAddr;
        uint256 tokenDecimals;
        uint256 tokenMinLimit;
        uint256 stethCollateral;
        uint256 wethDebt;
        uint256 tokenVaultBal;
        uint256 netTokenBal;
        VaultInterface.Ratios ratios;
        uint256 ethCoveringDebt;
        uint256 excessDebt;
        uint256 tokenPriceInEth;
        uint256 netTokenCollateralInEth;
        uint256 currentRatioMax;
    }

    function rebalanceTwoData(address vaultAddr_)
        public
        view
        returns (
            address flashTkn_,
            uint256 flashAmt_,
            uint256 route_,
            uint256 saveAmt_,
            uint256 tokenSupplyAmt_
        )
    {
        VaultInterface vault_ = VaultInterface(vaultAddr_);
        RebalanceTwoVariables memory v_;
        v_.tokenAddr = vault_.token();
        v_.tokenDecimals = vault_.decimals();
        v_.tokenMinLimit = vault_.tokenMinLimit();
        (
            ,
            v_.stethCollateral,
            v_.wethDebt,
            v_.tokenVaultBal,
            ,
            v_.netTokenBal
        ) = vault_.getVaultBalances();
        if (v_.tokenVaultBal > v_.tokenMinLimit)
            tokenSupplyAmt_ = v_.tokenVaultBal;
        VaultInterface.Ratios memory ratios_ = vault_.ratios();
        v_.ethCoveringDebt = (v_.stethCollateral * ratios_.stEthLimit) / 10000;
        v_.excessDebt = v_.ethCoveringDebt < v_.wethDebt
            ? v_.wethDebt - v_.ethCoveringDebt
            : 0;
        v_.tokenPriceInEth = IAavePriceOracle(
            aaveAddressProvider.getPriceOracle()
        ).getAssetPrice(v_.tokenAddr);
        v_.netTokenCollateralInEth =
            (v_.netTokenBal * v_.tokenPriceInEth) /
            (10**v_.tokenDecimals);
        v_.currentRatioMax = v_.netTokenCollateralInEth == 0
            ? 0
            : (v_.excessDebt * 10000) / v_.netTokenCollateralInEth;
        if (v_.currentRatioMax > ratios_.maxLimit) {
            saveAmt_ =
                ((v_.currentRatioMax - (ratios_.maxLimitGap + 10)) *
                    v_.netTokenCollateralInEth) /
                (10000 - ratios_.stEthLimit);
            flashTkn_ = wethAddr;
            // TODO: dont take flashloan if not needed
            flashAmt_ =
                (v_.netTokenCollateralInEth / 10) +
                ((saveAmt_ * 10) / 8); // 10% of current collateral(in eth) + (leverageAmt_ / 0.8)
            route_ = 5;
        }
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./interface.sol";

contract Helpers {
    IAaveAddressProvider internal constant AAVE_ADDR_PROVIDER =
        IAaveAddressProvider(0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5);
    IAaveDataprovider internal constant AAVE_DATA =
        IAaveDataprovider(0x057835Ad21a177dbdd3090bB1CAE03EaCF78Fc6d);
    InstaDeleverageAndWithdrawWrapper
        internal constant deleverageAndWithdrawWrapper =
        InstaDeleverageAndWithdrawWrapper(
            0xA6978cBA39f86491Ae5dcA53f4cdeFCB100E3E3d
        );
    IChainlink internal constant stethInEth =
        IChainlink(0x86392dC19c0b719886221c78AB11eb8Cf5c52812);
    IChainlink internal constant ethInUsd =
        IChainlink(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);

    address internal constant ETH_ADDR =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address internal constant WETH_ADDR =
        0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address internal constant STETH_ADDR =
        0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;
    address internal constant ETH_VAULT_ADDR =
        0xc383a3833A87009fD9597F8184979AF5eDFad019;

    struct BalVariables {
        uint256 wethVaultBal;
        uint256 wethDsaBal;
        uint256 stethVaultBal;
        uint256 stethDsaBal;
        uint256 totalBal;
    }

    struct HelperStruct {
        uint256 stethCollateralAmt;
        uint256 tokenVaultBal;
        uint256 tokenDSABal;
        uint256 netTokenBal;
        uint256 tokenCollateralAmt;
    }

    /**
     * @dev Helper function
     * @notice Helper function for calculating amounts
     */
    function getAmounts(
        address vaultAddr_,
        uint256 decimals_,
        uint256 tokenPriceInBaseCurrency_,
        uint256 ethPriceInBaseCurrency_,
        uint256 stEthLimit_,
        uint256 maxLimitThreshold_
    )
        internal
        view
        returns (
            uint256 stethCollateralAmt,
            uint256 wethDebtAmt,
            uint256 availableWithdraw
        )
    {
        VaultInterfaceToken tokenVault_ = VaultInterfaceToken(vaultAddr_);
        HelperStruct memory helper_;

        (
            helper_.tokenCollateralAmt,
            stethCollateralAmt,
            wethDebtAmt,
            helper_.tokenVaultBal,
            helper_.tokenDSABal,
            helper_.netTokenBal
        ) = tokenVault_.getVaultBalances();

        uint256 tokenPriceInEth = (tokenPriceInBaseCurrency_ * 1e18) /
            ethPriceInBaseCurrency_;
        uint256 tokenColInEth_ = (helper_.tokenCollateralAmt *
            tokenPriceInEth) / (10**decimals_);
        uint256 ethCoveringDebt_ = (stethCollateralAmt * stEthLimit_) / 10000;
        uint256 excessDebt_ = (ethCoveringDebt_ < wethDebtAmt)
            ? wethDebtAmt - ethCoveringDebt_
            : 0;
        uint256 currentRatioMax = tokenColInEth_ == 0
            ? 0
            : (excessDebt_ * 10000) / tokenColInEth_;
        if (currentRatioMax < maxLimitThreshold_) {
            availableWithdraw =
                helper_.tokenVaultBal +
                helper_.tokenDSABal +
                (((maxLimitThreshold_ - currentRatioMax) *
                    helper_.tokenCollateralAmt) / maxLimitThreshold_);
        }
    }

    struct CurrentRatioVars {
        uint256 netCollateral;
        uint256 netBorrow;
        uint256 netSupply;
        address tokenAddr;
        uint256 tokenDecimals;
        uint256 tokenColAmt;
        uint256 stethColAmt;
        uint256 wethDebt;
        uint256 netTokenBal;
        uint256 ethCoveringDebt;
        uint256 excessDebt;
        uint256 tokenPriceInBaseCurrency;
        uint256 ethPriceInBaseCurrency;
        uint256 excessDebtInBaseCurrency;
        uint256 netTokenColInBaseCurrency;
        uint256 netTokenSupplyInBaseCurrency;
    }

    function getCurrentRatios(address vaultAddr_)
        public
        view
        returns (uint256 currentRatioMax_, uint256 currentRatioMin_)
    {
        CurrentRatioVars memory v_;
        if (vaultAddr_ == ETH_VAULT_ADDR) {
            (
                v_.netCollateral,
                v_.netBorrow,
                ,
                v_.netSupply,

            ) = VaultInterfaceETH(vaultAddr_).netAssets();
            currentRatioMax_ = (v_.netBorrow * 1e4) / v_.netCollateral;
            currentRatioMin_ = (v_.netBorrow * 1e4) / v_.netSupply;
        } else {
            VaultInterfaceToken vault_ = VaultInterfaceToken(vaultAddr_);
            v_.tokenAddr = vault_.token();
            v_.tokenDecimals = VaultInterfaceCommon(vaultAddr_).decimals();
            (
                v_.tokenColAmt,
                v_.stethColAmt,
                v_.wethDebt,
                ,
                ,
                v_.netTokenBal
            ) = vault_.getVaultBalances();
            VaultInterfaceToken.Ratios memory ratios_ = vault_.ratios();
            v_.ethCoveringDebt = (v_.stethColAmt * ratios_.stEthLimit) / 10000;
            v_.excessDebt = v_.ethCoveringDebt < v_.wethDebt
                ? v_.wethDebt - v_.ethCoveringDebt
                : 0;
            IAavePriceOracle aaveOracle_ = IAavePriceOracle(
                AAVE_ADDR_PROVIDER.getPriceOracle()
            );
            v_.tokenPriceInBaseCurrency = aaveOracle_.getAssetPrice(
                v_.tokenAddr
            );
            v_.ethPriceInBaseCurrency = aaveOracle_.getAssetPrice(WETH_ADDR);
            v_.excessDebtInBaseCurrency =
                (v_.excessDebt * v_.ethPriceInBaseCurrency) /
                1e18;

            v_.netTokenColInBaseCurrency =
                (v_.tokenColAmt * v_.tokenPriceInBaseCurrency) /
                (10**v_.tokenDecimals);
            v_.netTokenSupplyInBaseCurrency =
                (v_.netTokenBal * v_.tokenPriceInBaseCurrency) /
                (10**v_.tokenDecimals);

            currentRatioMax_ =
                (v_.excessDebtInBaseCurrency * 10000) /
                v_.netTokenColInBaseCurrency;
            currentRatioMin_ =
                (v_.excessDebtInBaseCurrency * 10000) /
                v_.netTokenSupplyInBaseCurrency;
        }
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IAaveAddressProvider {
    function getPriceOracle() external view returns (address);
}

interface IAavePriceOracle {
    function getAssetPrice(address _asset) external view returns (uint256);
}

interface IAaveDataprovider {
    function getReserveData(address asset)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint40
        );
}

interface TokenInterface {
    function approve(address, uint256) external;

    function transfer(address, uint256) external;

    function transferFrom(
        address,
        address,
        uint256
    ) external;

    function deposit() external payable;

    function withdraw(uint256) external;

    function balanceOf(address) external view returns (uint256);

    function decimals() external view returns (uint256);

    function totalSupply() external view returns (uint256);
}

interface VaultInterfaceETH {
    struct BalVariables {
        uint256 wethVaultBal;
        uint256 wethDsaBal;
        uint256 stethVaultBal;
        uint256 stethDsaBal;
        uint256 totalBal;
    }

    function netAssets()
        external
        view
        returns (
            uint256 netCollateral_,
            uint256 netBorrow_,
            BalVariables memory balances_,
            uint256 netSupply_,
            uint256 netBal_
        );

    struct Ratios {
        uint16 maxLimit;
        uint16 minLimit;
        uint16 minLimitGap;
        uint128 maxBorrowRate;
    }

    function ratios() external view returns (Ratios memory);
}

interface VaultInterfaceToken {
    struct Ratios {
        uint16 maxLimit;
        uint16 maxLimitGap;
        uint16 minLimit;
        uint16 minLimitGap;
        uint16 stEthLimit;
        uint128 maxBorrowRate;
    }

    function ratios() external view returns (Ratios memory);

    function token() external view returns (address);

    function idealExcessAmt() external view returns (uint256);

    function getVaultBalances()
        external
        view
        returns (
            uint256 tokenCollateralAmt_,
            uint256 stethCollateralAmt_,
            uint256 wethDebtAmt_,
            uint256 tokenVaultBal_,
            uint256 tokenDSABal_,
            uint256 netTokenBal_
        );
}

interface VaultInterfaceCommon {
    function decimals() external view returns (uint8);

    function balanceOf(address account) external view returns (uint256);

    function getCurrentExchangePrice()
        external
        view
        returns (uint256 exchangePrice_, uint256 newRevenue_);

    function vaultDsa() external view returns (address);

    function totalSupply() external view returns (uint256);

    function revenueFee() external view returns (uint256);

    function withdrawalFee() external view returns (uint256);

    function swapFee() external view returns (uint256);

    function deleverageFee() external view returns (uint256);
}

interface InstaDeleverageAndWithdrawWrapper {
    function premium() external view returns (uint256);

    function premiumEth() external view returns (uint256);
}

interface IPriceResolver {
    function getPriceInUsd() external view returns (uint256 priceInUSD);

    function getPriceInEth() external view returns (uint256 priceInETH);
}

interface IChainlink {
    function latestAnswer() external view returns (int256 answer);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./interface.sol";
import "./helpers.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract InstaVaultUIResolver is Helpers {
    struct CommonVaultInfo {
        address token;
        uint8 decimals;
        uint256 userBalance;
        uint256 userBalanceStETH;
        uint256 aaveTokenSupplyRate;
        uint256 aaveWETHBorrowRate_;
        uint256 totalStEthBal;
        uint256 wethDebtAmt;
        uint256 userSupplyAmount;
        uint256 vaultTVLInAsset;
        uint256 availableWithdraw;
        uint256 withdrawalFee;
        uint256 revenueFee;
        VaultInterfaceToken.Ratios ratios;
    }

    /**
     * @dev Get all the info
     * @notice Get info of all the vaults and the user
     */
    function getInfoCommon(address user_, address[] memory vaults_)
        public
        view
        returns (CommonVaultInfo[] memory commonInfo_)
    {
        uint256 len_ = vaults_.length;
        commonInfo_ = new CommonVaultInfo[](vaults_.length);

        for (uint256 i = 0; i < len_; i++) {
            VaultInterfaceCommon vault_ = VaultInterfaceCommon(vaults_[i]);
            IAavePriceOracle aaveOracle_ = IAavePriceOracle(
                AAVE_ADDR_PROVIDER.getPriceOracle()
            );
            uint256 ethPriceInBaseCurrency_ = aaveOracle_.getAssetPrice(
                WETH_ADDR
            );

            if (vaults_[i] == ETH_VAULT_ADDR) {
                HelperStruct memory helper_;
                VaultInterfaceETH ethVault_ = VaultInterfaceETH(vaults_[i]);
                VaultInterfaceETH.Ratios memory ratios_ = ethVault_.ratios();

                commonInfo_[i].token = ETH_ADDR;
                commonInfo_[i].decimals = 18;
                commonInfo_[i].userBalance = user_.balance;
                commonInfo_[i].userBalanceStETH = TokenInterface(STETH_ADDR)
                    .balanceOf(user_);
                commonInfo_[i].aaveTokenSupplyRate = 0;

                VaultInterfaceETH.BalVariables memory balances_;
                (
                    helper_.stethCollateralAmt,
                    commonInfo_[i].wethDebtAmt,
                    balances_,
                    ,

                ) = ethVault_.netAssets();

                commonInfo_[i].totalStEthBal =
                    helper_.stethCollateralAmt +
                    balances_.stethDsaBal +
                    balances_.stethVaultBal;
                uint256 currentRatioMax_ = (commonInfo_[i].wethDebtAmt * 1e4) /
                    helper_.stethCollateralAmt;
                uint256 maxLimitThreshold = ratios_.maxLimit - 20; // taking 0.2% margin
                if (currentRatioMax_ < maxLimitThreshold) {
                    commonInfo_[i].availableWithdraw =
                        balances_.totalBal +
                        helper_.stethCollateralAmt -
                        ((1e4 * commonInfo_[i].wethDebtAmt) /
                            maxLimitThreshold);
                }
                commonInfo_[i].ratios.maxLimit = ratios_.maxLimit;
                commonInfo_[i].ratios.minLimit = ratios_.minLimit;
                commonInfo_[i].ratios.minLimitGap = ratios_.minLimitGap;
                commonInfo_[i].ratios.maxBorrowRate = ratios_.maxBorrowRate;
            } else {
                VaultInterfaceToken tokenVault_ = VaultInterfaceToken(
                    vaults_[i]
                );
                commonInfo_[i].ratios = tokenVault_.ratios();

                commonInfo_[i].token = tokenVault_.token();
                commonInfo_[i].decimals = vault_.decimals();
                commonInfo_[i].userBalance = TokenInterface(
                    commonInfo_[i].token
                ).balanceOf(user_);
                commonInfo_[i].userBalanceStETH = 0;
                (
                    ,
                    ,
                    ,
                    commonInfo_[i].aaveTokenSupplyRate,
                    ,
                    ,
                    ,
                    ,
                    ,

                ) = AAVE_DATA.getReserveData(commonInfo_[i].token);

                uint256 maxLimitThreshold = (commonInfo_[i].ratios.maxLimit -
                    100) - 10; // taking 0.1% margin from withdrawLimit
                uint256 stethCollateralAmt_;

                (
                    stethCollateralAmt_,
                    commonInfo_[i].wethDebtAmt,
                    commonInfo_[i].availableWithdraw
                ) = getAmounts(
                    vaults_[i],
                    commonInfo_[i].decimals,
                    aaveOracle_.getAssetPrice(commonInfo_[i].token),
                    ethPriceInBaseCurrency_,
                    commonInfo_[i].ratios.stEthLimit,
                    maxLimitThreshold
                );

                commonInfo_[i].totalStEthBal =
                    stethCollateralAmt_ +
                    IERC20(STETH_ADDR).balanceOf(vault_.vaultDsa()) +
                    IERC20(STETH_ADDR).balanceOf(vaults_[i]);
            }

            (uint256 exchangePrice, ) = vault_.getCurrentExchangePrice();
            commonInfo_[i].userSupplyAmount =
                (vault_.balanceOf(user_) * exchangePrice) /
                1e18;

            (, , , , commonInfo_[i].aaveWETHBorrowRate_, , , , , ) = AAVE_DATA
                .getReserveData(WETH_ADDR);

            commonInfo_[i].vaultTVLInAsset =
                (vault_.totalSupply() * exchangePrice) /
                1e18;
            commonInfo_[i].withdrawalFee = vault_.withdrawalFee();
            commonInfo_[i].revenueFee = vault_.revenueFee();
        }
    }

    struct DeleverageAndWithdrawVars {
        uint256 netCollateral;
        uint256 netBorrow;
        VaultInterfaceETH.BalVariables balances;
        uint256 netSupply;
        uint256 availableWithdraw;
        uint256 maxLimitThreshold;
        uint256 withdrawLimitThreshold;
        address tokenAddr;
        uint256 tokenCollateralAmt;
        uint256 tokenVaultBal;
        uint256 tokenDSABal;
        uint256 netTokenBal;
        uint256 idealTokenBal;
        uint256 tokenPriceInBaseCurrency;
        uint256 ethPriceInBaseCurrency;
        uint256 tokenColInEth;
        uint256 tokenSupplyInEth;
        uint256 withdrawAmtInEth;
        uint256 idealTokenBalInEth;
    }

    struct DeleverageAndWithdrawReturnVars {
        address tokenAddr;
        uint256 tokenDecimals;
        uint256 premium;
        uint256 premiumEth;
        uint256 tokenPriceInEth;
        uint256 exchangePrice;
        uint256 itokenAmt; // ##
        uint256 withdrawalFee;
        VaultInterfaceToken.Ratios ratios; // 6700
        uint256 currentRatioMin;
        uint256 currentRatioMax; //7179
        uint256 deleverageAmtMax;
        uint256 deleverageAmtMin; // ##
        uint256 deleverageAmtTillMinLimit;
        uint256 deleverageAmtTillMaxLimit;
    }

    function getDeleverageAndWithdrawData(
        address vaultAddr_,
        uint256 withdrawAmt_
    ) public view returns (DeleverageAndWithdrawReturnVars memory r_) {
        DeleverageAndWithdrawVars memory v_;
        r_.premium = deleverageAndWithdrawWrapper.premium();
        r_.premiumEth = deleverageAndWithdrawWrapper.premiumEth();
        r_.withdrawalFee = VaultInterfaceCommon(vaultAddr_).withdrawalFee();
        (r_.exchangePrice, ) = VaultInterfaceCommon(vaultAddr_)
            .getCurrentExchangePrice();
        r_.itokenAmt = (withdrawAmt_ * 1e18) / r_.exchangePrice;
        withdrawAmt_ = withdrawAmt_ - (withdrawAmt_ * r_.withdrawalFee) / 1e4;
        (r_.currentRatioMax, r_.currentRatioMin) = getCurrentRatios(vaultAddr_);
        r_.tokenDecimals = VaultInterfaceCommon(vaultAddr_).decimals();
        if (vaultAddr_ == ETH_VAULT_ADDR) {
            r_.tokenAddr = ETH_ADDR;
            r_.tokenPriceInEth = 1e18;
            VaultInterfaceETH.Ratios memory ratios_ = VaultInterfaceETH(
                vaultAddr_
            ).ratios();
            r_.ratios.maxLimit = ratios_.maxLimit;
            r_.ratios.minLimit = ratios_.minLimit;
            r_.ratios.minLimitGap = ratios_.minLimitGap;
            r_.ratios.maxBorrowRate = ratios_.maxBorrowRate;
            (
                v_.netCollateral,
                v_.netBorrow,
                v_.balances,
                v_.netSupply,

            ) = VaultInterfaceETH(vaultAddr_).netAssets();

            v_.maxLimitThreshold = ratios_.maxLimit - 20; // taking 0.2% margin
            if (r_.currentRatioMax < v_.maxLimitThreshold) {
                v_.availableWithdraw =
                    v_.balances.totalBal +
                    v_.netCollateral -
                    ((1e4 * v_.netBorrow) / v_.maxLimitThreshold);
            }

            // using this deleverageAmt_ the max ratio will remain the same
            if (withdrawAmt_ > v_.balances.totalBal) {
                r_.deleverageAmtMax =
                    (v_.netBorrow * (withdrawAmt_ - v_.balances.totalBal)) /
                    (v_.netCollateral - v_.netBorrow);
            } else r_.deleverageAmtMax = 0;

            // ####################
            // using this deleverageAmt_ the min ratio will remain the same
            r_.deleverageAmtMin =
                (v_.netBorrow * withdrawAmt_) /
                (v_.netSupply - v_.netBorrow);

            // using this deleverageAmt_ the max ratio will be taken to withdrawLimit (unless ideal balance is sufficient)
            if (v_.availableWithdraw <= withdrawAmt_) {
                uint256 withdrawLimit_ = ratios_.maxLimit - 20; // taking 0.2% margin from maxLimit
                r_.deleverageAmtTillMaxLimit =
                    ((v_.netBorrow * 1e4) -
                        (withdrawLimit_ * (v_.netSupply - withdrawAmt_))) /
                    (1e4 - withdrawLimit_);
            } else r_.deleverageAmtTillMaxLimit = 0;

            // using this deleverageAmt_ the min ratio will be taken to minLimit
            if (v_.availableWithdraw <= withdrawAmt_) {
                r_.deleverageAmtTillMinLimit =
                    ((v_.netBorrow * 1e4) -
                        (ratios_.minLimit * (v_.netSupply - withdrawAmt_))) /
                    (1e4 - ratios_.minLimit);
            } else r_.deleverageAmtTillMinLimit = 0;
        } else {
            r_.tokenAddr = VaultInterfaceToken(vaultAddr_).token();
            r_.ratios = VaultInterfaceToken(vaultAddr_).ratios();
            (
                v_.tokenCollateralAmt,
                ,
                ,
                v_.tokenVaultBal,
                v_.tokenDSABal,
                v_.netTokenBal
            ) = VaultInterfaceToken(vaultAddr_).getVaultBalances();
            v_.idealTokenBal = v_.tokenVaultBal + v_.tokenDSABal;

            IAavePriceOracle aaveOracle_ = IAavePriceOracle(
                AAVE_ADDR_PROVIDER.getPriceOracle()
            );
            v_.tokenPriceInBaseCurrency = aaveOracle_.getAssetPrice(
                r_.tokenAddr
            );
            v_.ethPriceInBaseCurrency = aaveOracle_.getAssetPrice(WETH_ADDR);
            r_.tokenPriceInEth =
                (v_.tokenPriceInBaseCurrency * 1e18) /
                v_.ethPriceInBaseCurrency;
            v_.tokenColInEth =
                (v_.tokenCollateralAmt * r_.tokenPriceInEth) /
                (10**r_.tokenDecimals);
            v_.tokenSupplyInEth =
                (v_.netTokenBal * r_.tokenPriceInEth) /
                (10**r_.tokenDecimals);
            v_.withdrawAmtInEth =
                (withdrawAmt_ * r_.tokenPriceInEth) /
                (10**r_.tokenDecimals);
            v_.idealTokenBalInEth =
                (v_.idealTokenBal * r_.tokenPriceInEth) /
                (10**r_.tokenDecimals);

            // using this deleverageAmt_ the max ratio will remain the same
            if (v_.withdrawAmtInEth > v_.idealTokenBalInEth) {
                r_.deleverageAmtMax =
                    (r_.currentRatioMax *
                        (v_.withdrawAmtInEth - v_.idealTokenBalInEth)) /
                    (10000 - r_.ratios.stEthLimit);
            } else r_.deleverageAmtMax = 0;

            // using this deleverageAmt_ the min ratio will remain the same
            r_.deleverageAmtMin =
                (r_.currentRatioMin * v_.withdrawAmtInEth) /
                (10000 - r_.ratios.stEthLimit);

            uint256 withdrawLimit_ = r_.ratios.maxLimit - 100;
            v_.withdrawLimitThreshold = withdrawLimit_ - 10; // keeping 0.1% margin
            if (r_.currentRatioMax < v_.withdrawLimitThreshold) {
                v_.availableWithdraw =
                    v_.tokenVaultBal +
                    v_.tokenDSABal +
                    (((v_.withdrawLimitThreshold - r_.currentRatioMax) *
                        v_.tokenCollateralAmt) / v_.withdrawLimitThreshold);
            }

            // using this deleverageAmt_ the max ratio will be taken to withdrawLimit (unless ideal balance is sufficient)
            if (v_.availableWithdraw <= withdrawAmt_) {
                r_.deleverageAmtTillMaxLimit =
                    ((r_.currentRatioMax * v_.tokenColInEth) -
                        (v_.withdrawLimitThreshold *
                            (v_.tokenSupplyInEth - v_.withdrawAmtInEth))) /
                    (10000 - r_.ratios.stEthLimit);
            } else r_.deleverageAmtTillMaxLimit = 0;

            // using this deleverageAmt_ the min ratio will be taken to minLimit
            if (v_.availableWithdraw <= withdrawAmt_) {
                r_.deleverageAmtTillMinLimit =
                    ((r_.currentRatioMin * v_.tokenSupplyInEth) -
                        (r_.ratios.minLimit *
                            (v_.tokenSupplyInEth - v_.withdrawAmtInEth))) /
                    (10000 - r_.ratios.stEthLimit);
            } else r_.deleverageAmtTillMinLimit = 0;
        }
    }

    struct ITokenInfoReturnVars {
        address tokenAddr;
        uint256 tokenDecimals;
        uint256 mintFee;
        uint256 redeemFee;
        uint256 streamingFee;
        uint256 swapFee;
        uint256 deleverageFee;
        uint256 totalSupply;
        uint256 itokenPriceInEth;
        uint256 itokenPriceInUsd;
        uint256 itokenPriceInUnderlyingToken;
        uint256 stethPriceInEth;
        uint256 stethPriceInUsd;
        uint256 ethPriceInUsd;
        uint256 volume;
    }

    function getITokenInfo(address itokenAddr_, address priceResolverAddr_)
        public
        view
        returns (ITokenInfoReturnVars memory r_)
    {
        VaultInterfaceCommon vault_ = VaultInterfaceCommon(itokenAddr_);
        if (itokenAddr_ == ETH_VAULT_ADDR) r_.tokenAddr = ETH_ADDR;
        else r_.tokenAddr = VaultInterfaceToken(itokenAddr_).token();
        r_.tokenDecimals = vault_.decimals();
        r_.mintFee = 0;
        r_.redeemFee = vault_.withdrawalFee();
        r_.streamingFee = 0;
        r_.swapFee = vault_.swapFee();
        r_.deleverageFee = vault_.deleverageFee();
        r_.totalSupply = vault_.totalSupply();
        (r_.itokenPriceInUnderlyingToken, ) = vault_.getCurrentExchangePrice();
        r_.itokenPriceInEth = IPriceResolver(priceResolverAddr_)
            .getPriceInEth();
        r_.itokenPriceInUsd = IPriceResolver(priceResolverAddr_)
            .getPriceInUsd();
        r_.stethPriceInEth = uint256(stethInEth.latestAnswer());
        r_.ethPriceInUsd = uint256(ethInUsd.latestAnswer());
        r_.stethPriceInUsd = (r_.stethPriceInEth * r_.ethPriceInUsd) / 1e18;
        r_.volume = 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int256)", p0));
	}

	function logUint(uint256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint256 p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256)", p0, p1));
	}

	function log(uint256 p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string)", p0, p1));
	}

	function log(uint256 p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool)", p0, p1));
	}

	function log(uint256 p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address)", p0, p1));
	}

	function log(string memory p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint256 p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}