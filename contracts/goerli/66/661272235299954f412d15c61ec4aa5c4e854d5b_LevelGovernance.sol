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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
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

pragma solidity >=0.8.0;

interface IGovernancePowerDelegationToken {
    enum DelegationType {
        VOTING_POWER,
        PROPOSITION_POWER
    }

    /**
     * @dev emitted when a user delegates to another
     * @param delegator the delegator
     * @param delegatee the delegatee
     * @param delegationType the type of delegation (VOTING_POWER, PROPOSITION_POWER)
     **/
    event DelegateChanged(address indexed delegator, address indexed delegatee, DelegationType delegationType);

    /**
     * @dev emitted when an action changes the delegated power of a user
     * @param user the user which delegated power has changed
     * @param amount the amount of delegated power for the user
     * @param delegationType the type of delegation (VOTING_POWER, PROPOSITION_POWER)
     **/
    event DelegatedPowerChanged(address indexed user, uint256 amount, DelegationType delegationType);

    /**
     * @dev delegates the specific power to a delegatee
     * @param delegatee the user which delegated power has changed
     * @param delegationType the type of delegation (VOTING_POWER, PROPOSITION_POWER)
     **/
    function delegateByType(address delegatee, DelegationType delegationType) external;

    /**
     * @dev delegates all the powers to a specific user
     * @param delegatee the user to which the power will be delegated
     **/
    function delegate(address delegatee) external;

    /**
     * @dev returns the delegatee of an user
     * @param delegator the address of the delegator
     **/
    function getDelegateeByType(address delegator, DelegationType delegationType)
        external
        view
        returns (address);

    /**
     * @dev returns the current delegated power of a user. The current power is the
     * power delegated at the time of the last snapshot
     * @param user the user
     **/
    function getPowerCurrent(address user, DelegationType delegationType) external view returns (uint256);

    /**
     * @dev returns the delegated power of a user at a certain block
     * @param user the user
     **/
    function getPowerAtBlock(
        address user,
        uint256 blockNumber,
        DelegationType delegationType
    ) external view returns (uint256);

    /**
     * @dev returns the total supply at a certain block number
     **/
    function totalSupplyAt(uint256 blockNumber) external view returns (uint256);
}

pragma solidity >=0.8.0;

interface ITransferHook {
    function onTransfer(
        address from,
        address to,
        uint256 amount
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import {ERC20Upgradeable} from "openzeppelin-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {IGovernancePowerDelegationToken} from "../interfaces/IGovernancePowerDelegationToken.sol";

/**
 * @notice implementation of the LEVEL token contract
 * @author Level
 */
abstract contract GovernancePowerDelegationERC20 is ERC20Upgradeable, IGovernancePowerDelegationToken {
    /// @notice The EIP-712 typehash for the delegation struct used by the contract
    bytes32 public constant DELEGATE_BY_TYPE_TYPEHASH =
        keccak256("DelegateByType(address delegatee,uint256 type,uint256 nonce,uint256 expiry)");

    bytes32 public constant DELEGATE_TYPEHASH = keccak256("Delegate(address delegatee,uint256 nonce,uint256 expiry)");

    /// @dev snapshot of a value on a specific block, used for votes
    struct Snapshot {
        uint128 blockNumber;
        uint128 value;
    }

    /**
     * @dev delegates one specific power to a delegatee
     * @param delegatee the user which delegated power has changed
     * @param delegationType the type of delegation (VOTING_POWER, PROPOSITION_POWER)
     **/
    function delegateByType(address delegatee, DelegationType delegationType) external override {
        _delegateByType(msg.sender, delegatee, delegationType);
    }

    /**
     * @dev delegates all the powers to a specific user
     * @param delegatee the user to which the power will be delegated
     **/
    function delegate(address delegatee) external override {
        _delegateByType(msg.sender, delegatee, DelegationType.VOTING_POWER);
        _delegateByType(msg.sender, delegatee, DelegationType.PROPOSITION_POWER);
    }

    /**
     * @dev returns the delegatee of an user
     * @param delegator the address of the delegator
     **/
    function getDelegateeByType(address delegator, DelegationType delegationType)
        external
        view
        override
        returns (address)
    {
        (, , mapping(address => address) storage delegates) = _getDelegationDataByType(delegationType);

        return _getDelegatee(delegator, delegates);
    }

    /**
     * @dev returns the current delegated power of a user. The current power is the
     * power delegated at the time of the last snapshot
     * @param user the user
     **/
    function getPowerCurrent(address user, DelegationType delegationType) external view override returns (uint256) {
        (
            mapping(address => mapping(uint256 => Snapshot)) storage snapshots,
            mapping(address => uint256) storage snapshotsCounts,

        ) = _getDelegationDataByType(delegationType);

        return _searchByBlockNumber(snapshots, snapshotsCounts, user, block.number);
    }

    /**
     * @dev returns the delegated power of a user at a certain block
     * @param user the user
     **/
    function getPowerAtBlock(
        address user,
        uint256 blockNumber,
        DelegationType delegationType
    ) external view override returns (uint256) {
        (
            mapping(address => mapping(uint256 => Snapshot)) storage snapshots,
            mapping(address => uint256) storage snapshotsCounts,

        ) = _getDelegationDataByType(delegationType);

        return _searchByBlockNumber(snapshots, snapshotsCounts, user, blockNumber);
    }

    /**
     * @dev returns the total supply at a certain block number
     * used by the voting strategy contracts to calculate the total votes needed for threshold/quorum
     * In this initial implementation with no LEVEL minting, simply returns the current supply
     * A snapshots mapping will need to be added in case a mint function is added to the LEVEL token in the future
     **/
    function totalSupplyAt(uint256 /* blockNumber */) external view override returns (uint256) {
        return super.totalSupply();
    }

    /**
     * @dev delegates the specific power to a delegatee
     * @param delegatee the user which delegated power has changed
     * @param delegationType the type of delegation (VOTING_POWER, PROPOSITION_POWER)
     **/
    function _delegateByType(
        address delegator,
        address delegatee,
        DelegationType delegationType
    ) internal {
        require(delegatee != address(0), "INVALID_DELEGATEE");

        (, , mapping(address => address) storage delegates) = _getDelegationDataByType(delegationType);

        uint256 delegatorBalance = balanceOf(delegator);

        address previousDelegatee = _getDelegatee(delegator, delegates);

        delegates[delegator] = delegatee;

        _moveDelegatesByType(previousDelegatee, delegatee, delegatorBalance, delegationType);
        emit DelegateChanged(delegator, delegatee, delegationType);
    }

    /**
     * @dev moves delegated power from one user to another
     * @param from the user from which delegated power is moved
     * @param to the user that will receive the delegated power
     * @param amount the amount of delegated power to be moved
     * @param delegationType the type of delegation (VOTING_POWER, PROPOSITION_POWER)
     **/
    function _moveDelegatesByType(
        address from,
        address to,
        uint256 amount,
        DelegationType delegationType
    ) internal {
        if (from == to) {
            return;
        }

        (
            mapping(address => mapping(uint256 => Snapshot)) storage snapshots,
            mapping(address => uint256) storage snapshotsCounts,

        ) = _getDelegationDataByType(delegationType);

        if (from != address(0)) {
            uint256 previous = 0;
            uint256 fromSnapshotsCount = snapshotsCounts[from];

            if (fromSnapshotsCount != 0) {
                previous = snapshots[from][fromSnapshotsCount - 1].value;
            } else {
                previous = balanceOf(from);
            }

            _writeSnapshot(snapshots, snapshotsCounts, from, uint128(previous), uint128(previous - amount));

            emit DelegatedPowerChanged(from, previous - amount, delegationType);
        }
        if (to != address(0)) {
            uint256 previous = 0;
            uint256 toSnapshotsCount = snapshotsCounts[to];
            if (toSnapshotsCount != 0) {
                previous = snapshots[to][toSnapshotsCount - 1].value;
            } else {
                previous = balanceOf(to);
            }

            _writeSnapshot(snapshots, snapshotsCounts, to, uint128(previous), uint128(previous + amount));

            emit DelegatedPowerChanged(to, previous + amount, delegationType);
        }
    }

    /**
     * @dev searches a snapshot by block number. Uses binary search.
     * @param snapshots the snapshots mapping
     * @param snapshotsCounts the number of snapshots
     * @param user the user for which the snapshot is being searched
     * @param blockNumber the block number being searched
     **/
    function _searchByBlockNumber(
        mapping(address => mapping(uint256 => Snapshot)) storage snapshots,
        mapping(address => uint256) storage snapshotsCounts,
        address user,
        uint256 blockNumber
    ) internal view returns (uint256) {
        require(blockNumber <= block.number, "INVALID_BLOCK_NUMBER");

        uint256 snapshotsCount = snapshotsCounts[user];

        if (snapshotsCount == 0) {
            return balanceOf(user);
        }

        // First check most recent balance
        if (snapshots[user][snapshotsCount - 1].blockNumber <= blockNumber) {
            return snapshots[user][snapshotsCount - 1].value;
        }

        // Next check implicit zero balance
        if (snapshots[user][0].blockNumber > blockNumber) {
            return 0;
        }

        uint256 lower = 0;
        uint256 upper = snapshotsCount - 1;
        while (upper > lower) {
            uint256 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            Snapshot memory snapshot = snapshots[user][center];
            if (snapshot.blockNumber == blockNumber) {
                return snapshot.value;
            } else if (snapshot.blockNumber < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return snapshots[user][lower].value;
    }

    /**
     * @dev returns the delegation data (snapshot, snapshotsCount, list of delegates) by delegation type
     * NOTE: Ideal implementation would have mapped this in a struct by delegation type. Unfortunately,
     * the LEVEL token and StakeToken already include a mapping for the snapshots, so we require contracts
     * who inherit from this to provide access to the delegation data by overriding this method.
     * @param delegationType the type of delegation
     **/
    function _getDelegationDataByType(DelegationType delegationType)
        internal
        view
        virtual
        returns (
            mapping(address => mapping(uint256 => Snapshot)) storage, //snapshots
            mapping(address => uint256) storage, //snapshots count
            mapping(address => address) storage //delegatees list
        );

    /**
     * @dev Writes a snapshot for an owner of tokens
     * @param owner The owner of the tokens
     * param oldValue The value before the operation that is gonna be executed after the snapshot
     * @param newValue The value after the operation
     */
    function _writeSnapshot(
        mapping(address => mapping(uint256 => Snapshot)) storage snapshots,
        mapping(address => uint256) storage snapshotsCounts,
        address owner,
        uint128 /* oldValue */,
        uint128 newValue
    ) internal {
        uint128 currentBlock = uint128(block.number);

        uint256 ownerSnapshotsCount = snapshotsCounts[owner];
        mapping(uint256 => Snapshot) storage snapshotsOwner = snapshots[owner];

        // Doing multiple operations in the same block
        if (ownerSnapshotsCount != 0 && snapshotsOwner[ownerSnapshotsCount - 1].blockNumber == currentBlock) {
            snapshotsOwner[ownerSnapshotsCount - 1].value = newValue;
        } else {
            snapshotsOwner[ownerSnapshotsCount] = Snapshot(currentBlock, newValue);
            snapshotsCounts[owner] = ownerSnapshotsCount + 1;
        }
    }

    /**
     * @dev returns the user delegatee. If a user never performed any delegation,
     * his delegated address will be 0x0. In that case we simply return the user itself
     * @param delegator the address of the user for which return the delegatee
     * @param delegates the array of delegates for a particular type of delegation
     **/
    function _getDelegatee(address delegator, mapping(address => address) storage delegates)
        internal
        view
        returns (address)
    {
        address previousDelegatee = delegates[delegator];

        if (previousDelegatee == address(0)) {
            return delegator;
        }

        return previousDelegatee;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import {Initializable} from "openzeppelin-upgradeable/proxy/utils/Initializable.sol";
import {GovernancePowerDelegationERC20} from "../lib/GovernancePowerDelegationERC20.sol";
import {ITransferHook} from "../interfaces/ITransferHook.sol";

/**
 * @notice implementation of the LevelGovernance token contract
 * @author Level
 * Inspired from AAVE v2
 */
contract LevelGovernance is Initializable, GovernancePowerDelegationERC20 {
    uint256 public constant MAX_SUPPLY = 30_000_000 ether;

    /// @dev owner => next valid nonce to submit with permit()
    mapping(address => uint256) public _nonces;

    mapping(address => mapping(uint256 => Snapshot)) public _votingSnapshots;

    mapping(address => uint256) public _votingSnapshotsCounts;

    /// @dev reference to the Level governance contract to call (if initialized) on _beforeTokenTransfer
    /// !!! IMPORTANT The Level governance is considered a trustable contract, being its responsibility
    /// to control all potential reentrancies by calling back the LevelToken
    ITransferHook public _levelGovernance;

    bytes32 public DOMAIN_SEPARATOR;
    bytes public constant EIP712_REVISION = bytes("1");
    bytes32 internal constant EIP712_DOMAIN =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    bytes32 public constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    mapping(address => address) internal _votingDelegates;

    mapping(address => mapping(uint256 => Snapshot)) internal _propositionPowerSnapshots;
    mapping(address => uint256) internal _propositionPowerSnapshotsCounts;

    mapping(address => address) internal _propositionPowerDelegates;

    function initialize() external initializer {
        __ERC20_init("Level Governance Token", "LGO");
        _mint(_msgSender(), MAX_SUPPLY);
    }

    /**
     * @dev implements the permit function as for https://github.com/ethereum/EIPs/blob/8a34d644aacf0f9f8f00815307fd7dd5da07655f/EIPS/eip-2612.md
     * @param owner the owner of the funds
     * @param spender the spender
     * @param value the amount
     * @param deadline the deadline timestamp, type(uint256).max for no deadline
     * @param v signature param
     * @param s signature param
     * @param r signature param
     */

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(owner != address(0), "INVALID_OWNER");
        //solium-disable-next-line
        require(block.timestamp <= deadline, "INVALID_EXPIRATION");
        uint256 currentValidNonce = _nonces[owner];
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, currentValidNonce, deadline))
            )
        );

        require(owner == ecrecover(digest, v, r, s), "INVALID_SIGNATURE");
        _nonces[owner] = currentValidNonce + 1;
        _approve(owner, spender, value);
    }

    /**
     * @dev Writes a snapshot before any operation involving transfer of value: _transfer, _mint and _burn
     * - On _transfer, it writes snapshots for both "from" and "to"
     * - On _mint, only for _to
     * - On _burn, only for _from
     * @param from the from address
     * @param to the to address
     * @param amount the amount to transfer
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        address votingFromDelegatee = _getDelegatee(from, _votingDelegates);
        address votingToDelegatee = _getDelegatee(to, _votingDelegates);

        _moveDelegatesByType(votingFromDelegatee, votingToDelegatee, amount, DelegationType.VOTING_POWER);

        address propPowerFromDelegatee = _getDelegatee(from, _propositionPowerDelegates);
        address propPowerToDelegatee = _getDelegatee(to, _propositionPowerDelegates);

        _moveDelegatesByType(propPowerFromDelegatee, propPowerToDelegatee, amount, DelegationType.PROPOSITION_POWER);

        // caching the level governance address to avoid multiple state loads
        ITransferHook levelGovernance = _levelGovernance;
        if (levelGovernance != ITransferHook(address(0))) {
            levelGovernance.onTransfer(from, to, amount);
        }
    }

    function _getDelegationDataByType(DelegationType delegationType)
        internal
        view
        override
        returns (
            mapping(address => mapping(uint256 => Snapshot)) storage, //snapshots
            mapping(address => uint256) storage, //snapshots count
            mapping(address => address) storage //delegatees list
        )
    {
        if (delegationType == DelegationType.VOTING_POWER) {
            return (_votingSnapshots, _votingSnapshotsCounts, _votingDelegates);
        } else {
            return (_propositionPowerSnapshots, _propositionPowerSnapshotsCounts, _propositionPowerDelegates);
        }
    }

    /**
     * @dev Delegates power from signatory to `delegatee`
     * @param delegatee The address to delegate votes to
     * @param delegationType the type of delegation (VOTING_POWER, PROPOSITION_POWER)
     * @param nonce The contract state required to match the signature
     * @param expiry The time at which to expire the signature
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function delegateByTypeBySig(
        address delegatee,
        DelegationType delegationType,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        bytes32 structHash = keccak256(
            abi.encode(DELEGATE_BY_TYPE_TYPEHASH, delegatee, uint256(delegationType), nonce, expiry)
        );
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "INVALID_SIGNATURE");
        require(nonce == _nonces[signatory]++, "INVALID_NONCE");
        require(block.timestamp <= expiry, "INVALID_EXPIRATION");
        _delegateByType(signatory, delegatee, delegationType);
    }

    /**
     * @dev Delegates power from signatory to `delegatee`
     * @param delegatee The address to delegate votes to
     * @param nonce The contract state required to match the signature
     * @param expiry The time at which to expire the signature
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function delegateBySig(
        address delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        bytes32 structHash = keccak256(abi.encode(DELEGATE_TYPEHASH, delegatee, nonce, expiry));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "INVALID_SIGNATURE");
        require(nonce == _nonces[signatory]++, "INVALID_NONCE");
        require(block.timestamp <= expiry, "INVALID_EXPIRATION");
        _delegateByType(signatory, delegatee, DelegationType.VOTING_POWER);
        _delegateByType(signatory, delegatee, DelegationType.PROPOSITION_POWER);
    }
}