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

// SPDX-License-Identifier: LGPL-3.0
pragma solidity >=0.8.0 <0.9.0;

interface IFeeDistributor {
    event ToggleAllowCheckpointToken(bool toggleFlag);

    event CheckpointToken(uint256 time, uint256 tokens);

    event Claimed(address indexed recipient, uint256 amount, uint256 claimEpoch, uint256 maxEpoch);

    event RecoverBalance(address indexed token, address indexed emergencyReturn, uint256 amount);

    event SetEmergencyReturn(address indexed emergencyReturn);

    /**
     * @notice Update the token checkpoint
     * @dev Calculates the total number of tokens to be distributed in a given week.
     *    During setup for the initial distribution this function is only callable
     *    by the contract owner. Beyond initial distro, it can be enabled for anyone
     *    to call
     */
    function checkpointToken() external;

    /**
     * @notice Get the veLT balance for `_user` at `_timestamp`
     * @param _user Address to query balance for
     * @param _timestamp Epoch time
     * @return uint256 veLT balance
     */
    function veForAt(address _user, uint256 _timestamp) external view returns (uint256);

    /**
     * @notice Get the VeLT voting percentage for `_user` in _gauge  at `_timestamp`
     * @param _user Address to query voting
     * @param _timestamp Epoch time
     * @return value of voting precentage normalized to 1e18
     */
    function vePrecentageForAt(address _user, uint256 _timestamp) external returns (uint256);

    /**
     * @notice Update the veLT total supply checkpoint
     * @dev The checkpoint is also updated by the first claimant each
     *    new epoch week. This function may be called independently
     *    of a claim, to reduce claiming gas costs.
     */
    function checkpointTotalSupply() external;

    /**
     * @notice Claim fees for `_addr`
     *  @dev Each call to claim look at a maximum of 50 user veLT points.
     *    For accounts with many veLT related actions, this function
     *    may need to be called more than once to claim all available
     *    fees. In the `Claimed` event that fires, if `claim_epoch` is
     *    less than `max_epoch`, the account may claim again.
     *    @param _addr Address to claim fees for
     *    @return uint256 Amount of fees claimed in the call
     *
     */
    function claim(address _addr) external returns (uint256);

    /**
     * @notice Make multiple fee claims in a single call
     * @dev Used to claim for many accounts at once, or to make
     *    multiple claims for the same address when that address
     *    has significant veLT history
     * @param _receivers List of addresses to claim for. Claiming terminates at the first `ZERO_ADDRESS`.
     * @return uint256 claim totol fee
     */
    function claimMany(address[] memory _receivers) external returns (uint256);

    /**
     * @notice Receive HOPE into the contract and trigger a token checkpoint
     * @param amount burn amount
     * @return bool success
     */
    function burn(uint256 amount) external returns (bool);

    /**
     * @notice Toggle permission for checkpointing by any account
     */
    function toggleAllowCheckpointToken() external;

    /**
     * @notice Recover ERC20 tokens from this contract
     * @dev Tokens are sent to the emergency return address.
     * @return bool success
     */
    function recoverBalance() external returns (bool);

    /**
     * pause contract
     */
    function pause() external;

    /**
     * unpause contract
     */
    function unpause() external;
}

// SPDX-License-Identifier: LGPL-3.0

pragma solidity 0.8.17;

interface IGaugeController {
    struct Point {
        uint256 bias;
        uint256 slope;
    }

    struct VotedSlope {
        uint256 slope;
        uint256 power;
        uint256 end;
    }

    struct UserPoint {
        uint256 bias;
        uint256 slope;
        uint256 ts;
        uint256 blk;
    }

    event AddType(string name, int128 type_id);

    event NewTypeWeight(int128 indexed type_id, uint256 time, uint256 weight, uint256 total_weight);

    event NewGaugeWeight(address indexed gauge_address, uint256 time, uint256 weight, uint256 total_weight);

    event VoteForGauge(address indexed user, address indexed gauge_address, uint256 time, uint256 weight);

    event NewGauge(address indexed gauge_address, int128 gauge_type, uint256 weight);

    /**
     * @notice Get gauge type for address
     *  @param _addr Gauge address
     * @return Gauge type id
     */
    function gaugeTypes(address _addr) external view returns (int128);

    /**
     * @notice Add gauge `addr` of type `gauge_type` with weight `weight`
     * @param addr Gauge address
     * @param gaugeType Gauge type
     * @param weight Gauge weight
     */
    function addGauge(address addr, int128 gaugeType, uint256 weight) external;

    /**
     * @notice Checkpoint to fill data common for all gauges
     */
    function checkpoint() external;

    /**
     * @notice Checkpoint to fill data for both a specific gauge and common for all gauge
     * @param addr Gauge address
     */
    function checkpointGauge(address addr) external;

    /**
     * @notice Get Gauge relative weight (not more than 1.0) normalized to 1e18(e.g. 1.0 == 1e18). Inflation which will be received by
     * it is inflation_rate * relative_weight / 1e18
     * @param gaugeAddress Gauge address
     * @param time Relative weight at the specified timestamp in the past or present
     * @return Value of relative weight normalized to 1e18
     */
    function gaugeRelativeWeight(address gaugeAddress, uint256 time) external view returns (uint256);

    /**
     *  @notice Get gauge weight normalized to 1e18 and also fill all the unfilled values for type and gauge records
     * @dev Any address can call, however nothing is recorded if the values are filled already
     * @param gaugeAddress Gauge address
     * @param time Relative weight at the specified timestamp in the past or present
     * @return Value of relative weight normalized to 1e18
     */
    function gaugeRelativeWeightWrite(address gaugeAddress, uint256 time) external returns (uint256);

    /**
     * @notice Add gauge type with name `_name` and weight `weight`
     * @dev only owner call
     * @param _name Name of gauge type
     * @param weight Weight of gauge type
     */
    function addType(string memory _name, uint256 weight) external;

    /**
     * @notice Change gauge type `type_id` weight to `weight`
     * @dev only owner call
     * @param type_id Gauge type id
     * @param weight New Gauge weight
     */
    function changeTypeWeight(int128 type_id, uint256 weight) external;

    /**
     * @notice Change weight of gauge `addr` to `weight`
     * @param gaugeAddress `Gauge` contract address
     * @param weight New Gauge weight
     */
    function changeGaugeWeight(address gaugeAddress, uint256 weight) external;

    /**
     * @notice Allocate voting power for changing pool weights
     * @param gaugeAddress Gauge which `msg.sender` votes for
     * @param userWeight Weight for a gauge in bps (units of 0.01%). Minimal is 0.01%. Ignored if 0.
     *        example: 10%=1000,3%=300,0.01%=1,100%=10000
     */
    function voteForGaugeWeights(address gaugeAddress, uint256 userWeight) external;

    /**
     * @notice Get current gauge weight
     * @param addr Gauge address
     * @return Gauge weight
     */

    function getGaugeWeight(address addr) external view returns (uint256);

    /**
     * @notice Get current type weight
     * @param type_id Type id
     * @return Type weight
     */
    function getTypeWeight(int128 type_id) external view returns (uint256);

    /**
     * @notice Get current total (type-weighted) weight
     * @return Total weight
     */
    function getTotalWeight() external view returns (uint256);

    /**
     * @notice Get sum of gauge weights per type
     * @param type_id Type id
     * @return Sum of gauge weights
     */
    function getWeightsSumPreType(int128 type_id) external view returns (uint256);

    function votingEscrow() external view returns (address);
}

// SPDX-License-Identifier: LGPL-3.0
pragma solidity >=0.8.0 <0.9.0;

interface IGaugeFeeDistributor {
    event ToggleAllowCheckpointToken(bool toggleFlag);

    event CheckpointToken(uint256 time, uint256 tokens);

    event Claimed(address indexed gauge, address indexed recipient, uint256 amount, uint256 claimEpoch, uint256 maxEpoch);

    event RecoverBalance(address indexed token, address indexed emergencyReturn, uint256 amount);

    event SetEmergencyReturn(address indexed emergencyReturn);

    /**
     * @notice Update the token checkpoint
     * @dev Calculates the total number of tokens to be distributed in a given week.
     *    During setup for the initial distribution this function is only callable
     *    by the contract owner. Beyond initial distro, it can be enabled for anyone
     *    to call
     */
    function checkpointToken() external;

    /**
     * @notice Get the VeLT voting percentage for `_user` in _gauge  at `_timestamp`
     * @param _gauge Address to query voting gauge
     * @param _user Address to query voting
     * @param _timestamp Epoch time
     * @return value of voting precentage normalized to 1e18
     */
    function vePrecentageForAt(address _gauge, address _user, uint256 _timestamp) external returns (uint256);

    /**
     * @notice Get the veLT balance for `_user` at `_timestamp`
     * @param _gauge Address to query voting gauge
     * @param _user Address to query balance for
     * @param _timestamp Epoch time
     * @return uint256 veLT balance
     */
    function veForAt(address _gauge, address _user, uint256 _timestamp) external view returns (uint256);

    /**
     * @notice Get the HOPE balance for _gauge  at `_weekCursor`
     * @param _gauge Address to query voting gauge
     * @param _weekCursor week cursor
     */
    function gaugeBalancePreWeek(address _gauge, uint256 _weekCursor) external view returns (uint256);

    /**
     * @notice Claim fees for `_addr`
     * @dev Each call to claim look at a maximum of 50 user veLT points.
     *    For accounts with many veLT related actions, this function
     *    may need to be called more than once to claim all available
     *    fees. In the `Claimed` event that fires, if `claim_epoch` is
     *    less than `max_epoch`, the account may claim again.
     * @param gauge Address to claim fee of gauge
     * @param _addr Address to claim fees for
     * @return uint256 Amount of fees claimed in the call
     *
     */
    function claim(address gauge, address _addr) external returns (uint256);

    /**
     * @notice Make multiple fee claims in a single call
     * @dev Used to claim for many accounts at once, or to make
     *    multiple claims for the same address when that address
     *    has significant veLT history
     * @param gauge Address to claim fee of gauge
     * @param _receivers List of addresses to claim for. Claiming terminates at the first `ZERO_ADDRESS`.
     * @return uint256 claim totol fee
     */
    function claimMany(address gauge, address[] memory _receivers) external returns (uint256);

    /**
     * @notice Make multiple fee claims in a single call
     * @dev Used to claim for many accounts at once, or to make
         multiple claims for the same address when that address
         has significant veLT history
       @param  gaugeList  List of gauges to claim
     * @param receiver address to claim for.
     * @return uint256 claim total fee
     */
    function claimManyGauge(address[] memory gaugeList, address receiver) external returns (uint256);

    /**
     * @notice Receive HOPE into the contract and trigger a token checkpoint
     * @param amount burn amount
     * @return bool success
     */
    function burn(uint256 amount) external returns (bool);

    /**
     * @notice Toggle permission for checkpointing by any account
     */
    function toggleAllowCheckpointToken() external;

    /**
     * @notice Recover ERC20 tokens from this contract
     * @dev Tokens are sent to the emergency return address.
     * @return bool success
     */
    function recoverBalance() external returns (bool);

    /**
     * pause contract
     */
    function pause() external;

    /**
     * unpause contract
     */
    function unpause() external;
}

// SPDX-License-Identifier: LGPL-3.0
pragma solidity 0.8.17;

interface IMinter {
    function token() external view returns (address);

    function controller() external view returns (address);

    function minted(address user, address gauge) external view returns (uint256);

    function mint(address gaugeAddress) external;
}

// SPDX-License-Identifier: LGPL-3.0
pragma solidity 0.8.17;

interface IVotingEscrow {
    struct Point {
        int256 bias;
        int256 slope;
        uint256 ts;
        uint256 blk;
    }

    struct LockedBalance {
        int256 amount;
        uint256 end;
    }

    event Deposit(
        address indexed provider,
        address indexed beneficiary,
        uint256 value,
        uint256 afterAmount,
        uint256 indexed locktime,
        uint256 _type,
        uint256 ts
    );
    event Withdraw(address indexed provider, uint256 value, uint256 ts);

    event Supply(uint256 prevSupply, uint256 supply);

    event SetSmartWalletChecker(address sender, address indexed newChecker, address oldChecker);

    event SetPermit2Address(address oldAddress, address newAddress);

    /***
     * @dev Get the most recently recorded rate of voting power decrease for `_addr`
     * @param _addr Address of the user wallet
     * @return Value of the slope
     */
    function getLastUserSlope(address _addr) external view returns (int256);

    /***
     * @dev Get the timestamp for checkpoint `_idx` for `_addr`
     * @param _addr User wallet address
     * @param _idx User epoch number
     * @return Epoch time of the checkpoint
     */
    function userPointHistoryTs(address _addr, uint256 _idx) external view returns (uint256);

    /***
     * @dev Get timestamp when `_addr`'s lock finishes
     * @param _addr User wallet
     * @return Epoch time of the lock end
     */
    function lockedEnd(address _addr) external view returns (uint256);

    function createLock(uint256 _value, uint256 _unlockTime, uint256 nonce, uint256 deadline, bytes memory signature) external;

    function createLockFor(
        address _beneficiary,
        uint256 _value,
        uint256 _unlockTime,
        uint256 nonce,
        uint256 deadline,
        bytes memory signature
    ) external;

    function increaseAmount(uint256 _value, uint256 nonce, uint256 deadline, bytes memory signature) external;

    function increaseAmountFor(address _beneficiary, uint256 _value, uint256 nonce, uint256 deadline, bytes memory signature) external;

    function increaseUnlockTime(uint256 _unlockTime) external;

    function checkpointSupply() external;

    function withdraw() external;

    function epoch() external view returns (uint256);

    function getUserPointHistory(address _userAddress, uint256 _index) external view returns (Point memory);

    function supplyPointHistory(uint256 _index) external view returns (int256 bias, int256 slope, uint256 ts, uint256 blk);

    /***
     * @notice Get the current voting power for `msg.sender`
     * @dev Adheres to the ERC20 `balanceOf` interface for Aragon compatibility
     * @param _addr User wallet address
     * @param _t Epoch time to return voting power at
     * @return User voting power
     * @dev return the present voting power if _t is 0
     */
    function balanceOfAtTime(address _addr, uint256 _t) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function totalSupplyAtTime(uint256 _t) external view returns (uint256);

    function userPointEpoch(address _user) external view returns (uint256);
}

// SPDX-License-Identifier: LGPL-3.0
pragma solidity 0.8.17;

import "./XLT.sol";
import "./interfaces/IMinter.sol";
import "./interfaces/IVotingEscrow.sol";
import "./interfaces/IGaugeController.sol";
import "./interfaces/IFeeDistributor.sol";
import "./interfaces/IGaugeFeeDistributor.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { TransferHelper } from "light-lib/contracts/TransferHelper.sol";

interface IXlt {
    function mint(address account, uint256 amount) external;
    function burn(address account, uint256 amount) external;
}

interface ILightTeamVault {
    function claimTo(address to) external;
}

interface IExtendVotingEscrow is IVotingEscrow {
    function locked(address user) external returns (LockedBalance memory);
}

interface ILightGauge {
    function minter() external returns (address);
    function ltToken() external returns (address);
    function controller() external returns (address);
    function votingEscrow() external returns (address);
    function claimableTokens(address addr) external returns (uint256);
}

contract LightTeamVaultManager is OwnableUpgradeable {

    event SetCanWithdrawByAnyone(bool indexed value);
    event WithdrawLTRewards(address indexed to, uint256 amount);
    event WithdrawLT(address indexed operator, address indexed to, uint256 amount);
    event WithdrawStHOPE(address indexed to, uint256 amount);

    address public lightTeamVault;
    address public feeDistributor;
    address public gaugeFeeDistributor;
    address public stHopeGauge; // this is both a Gauge and a token 
    address public votingEscrow;

    address public xlt;
    address public token; // LT

    uint256 public mintableXlt; // amount of XLT can be minted by Manager
    uint256 public stHopeTotalClaimed;  // total claimed amount of stHOPE rewards 
    uint256 public stHopeWithdrew;   // the stHOPE had withrew
    uint256 public ltTotalClaimed;  // total claimed amount of LT rewards
    uint256 public ltRewardsWithdrew; // the LT amount had withrew , only for the partial of rewards
    uint256 public ltWithdrew; // the LT amount had withrew , only for the partial of unlocded
    uint256 public lastEndtime; // save the last endtime of lock
    uint256 constant public WEEK = 7 * 86400;
    uint256 constant public LOCK_TIME = 208 * WEEK; // 208 weeks

    // if true, withdrawLT(to,amount) can by called by anyone
    // equivalent amount of XLT will be burn from "to"
    bool public canWithdrawByAnyone; 

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    receive() external payable {}

    function initialize(
        address _owner, // muitiSig
        address _lightTeamVault, 
        address _feeDistributor,
        address _gaugeFeeDistributor,
        address _stHopeGauge
    ) public initializer {
        require(_owner != address(0), "LightTeamVaultManager: invalid owner address");
        require(_lightTeamVault != address(0), "LightTeamVaultManager: invalid lightTeamVault address");
        require(_feeDistributor != address(0), "LightTeamVaultManager: invalid feeDistributor address");
        require(_gaugeFeeDistributor != address(0), "LightTeamVaultManager: invalid gaugeFeeDistributor address");
        require(_stHopeGauge != address(0), "LightTeamVaultManager: invalid stHopeGauge address");

        _transferOwnership(_owner);
        votingEscrow = ILightGauge(_stHopeGauge).votingEscrow();
        token = ILightGauge(_stHopeGauge).ltToken();
        stHopeGauge = _stHopeGauge;
    
        lightTeamVault = _lightTeamVault;
        feeDistributor = _feeDistributor;
        gaugeFeeDistributor = _gaugeFeeDistributor;
        
        IERC20 _xlt = new XLT(address(this));
        xlt = address(_xlt);
    }

    /***
     * @dev if set true, withdrawLT(to,amount) can by called by anyone
     */
    function setCanWithdrawByAnyone(bool _canWithdrawByAnyone) external onlyOwner {
        require(canWithdrawByAnyone != _canWithdrawByAnyone, "LightTeamVaultManager: wrong value to set");
        canWithdrawByAnyone = _canWithdrawByAnyone;

        emit SetCanWithdrawByAnyone(_canWithdrawByAnyone);
    }
    
    /***
     * @dev Claim unlocked LT token from LightTeamVault, then lock them to VoteEscrow for 4 years ,
     *      and record mintable XLT amount, it can only be called by owner every 24h 
     * @return amount amount of locked
     */
    function claimUnlockedLTAndLockForVeLT() external onlyOwner returns (uint256) {
        uint256 balanceBefore = IERC20(token).balanceOf(address(this));
        ILightTeamVault(lightTeamVault).claimTo(address(this));
        uint256 claimAmount = IERC20(token).balanceOf(address(this)) - balanceBefore;
        require(claimAmount > 0, "LightTeamVaultManager: insufficient balance to lock");
        mintableXlt += claimAmount; 

        // lock LT to VoteEscrow,  must add Manager to whitelist of VoteEscrow first
        IExtendVotingEscrow _votingEscrow = IExtendVotingEscrow(votingEscrow);
        // approve for votingEscrow
        IERC20(token).approve(votingEscrow, claimAmount);

        uint256 endTime = block.timestamp + LOCK_TIME;
        if (_votingEscrow.locked(address(this)).amount == 0) {
            _votingEscrow.createLock(claimAmount, endTime, 0, 0, bytes(""));
        } else {
            _votingEscrow.increaseAmount(claimAmount, 0, 0, bytes(""));
            if ((endTime / WEEK) * WEEK > lastEndtime)
                _votingEscrow.increaseUnlockTime(endTime);
        }

        lastEndtime = (endTime / WEEK) * WEEK;
        
        return claimAmount;
    }

    /***
     * @dev Claim unlocked LT token from LightTeamVault to Manager,
     *      and record mintable XLT amount, it can only be called by owner every 24h  
     * @return amount amount of claimed
     */
    function claimUnlockedLT() external onlyOwner returns (uint256) {
        uint256 balanceBefore = IERC20(token).balanceOf(address(this));
        ILightTeamVault(lightTeamVault).claimTo(address(this));
        uint256 claimAmount = IERC20(token).balanceOf(address(this)) - balanceBefore;
        require(claimAmount > 0, "LightTeamVaultManager: insufficient balance to lock");
        mintableXlt += claimAmount; 

        return claimAmount;
    }

    /***
     * @dev Mint amount XLT to "to"
     * @param to Address of the receiver 
     * @param amount amount of XLT 
     */
    function mintXLT(address to, uint amount) external onlyOwner {
        require(mintableXlt >= amount, "LightTeamVaultManager: insufficient mintable amount");
        mintableXlt -= amount;
        IXlt(xlt).mint(to, amount);
    }

    /***
     * @dev Burn amount XLT from "from"
     * @param from Address of the holder 
     * @param amount amount of XLT 
     */
    function burnXLT(address from, uint amount) external onlyOwner {
        require(IERC20(xlt).balanceOf(from) >= amount, "LightTeamVaultManager: insufficient XLT to burn");
        IXlt(xlt).burn(from, amount);
    }

    /***
     * @dev When locked LT expired, withdraw it form VoteEscrow to Manager. can be called by anyone
     */
    function withdrawLTWhenExpired() external {
        IVotingEscrow(votingEscrow).withdraw();
    }

    /***
     * @dev after claimUnlockedLT or withdrawLTWhenExpired, lock LT to votingEscrow
     * @param amount amount of LT to lock 
     * @param unlockTime end time to unlock , if the lock existed, unlockTime must be 0
     */
    function lockLT(uint amount, uint unlockTime) external onlyOwner {
        // lock LT to VoteEscrow,  must add Manager to whitelist of VoteEscrow first
        IExtendVotingEscrow _votingEscrow = IExtendVotingEscrow(votingEscrow);
        // approve for votingEscrow
        IERC20(token).approve(votingEscrow, amount);

        if (_votingEscrow.locked(address(this)).amount == 0) {
            _votingEscrow.createLock(amount, unlockTime, 0, 0, bytes(""));
        } else {
            require(unlockTime == 0, "LightTeamVaultManager: the lock existed, the unlockTime should be zero");
            _votingEscrow.increaseAmount(amount, 0, 0, bytes(""));
        }
    }

    /***
     * @dev Extend the unlock time
     * @param unlockTime  
     */
    function increaseUnlockTime(uint unlockTime) external onlyOwner {
        IVotingEscrow(votingEscrow).increaseUnlockTime(unlockTime);
    }

    /***
     * @dev  Allocate voting power for changing multiple pool weights
     * @param gaugeAddress array of gaugeAddress
     * @param userWeights array of userWeight
     */
    function voteForGaugesWeights(
        address[] calldata gaugeAddresses, 
        uint256[] calldata userWeights
    ) external onlyOwner {
        require(gaugeAddresses.length < 128, "LightTeamVaultManager: length must less than 128");
        require(gaugeAddresses.length == userWeights.length, "LightTeamVaultManager: unmatched length");
        
        address _gaugeController = ILightGauge(stHopeGauge).controller();
        IGaugeController gaugeController = IGaugeController(_gaugeController);
        for (uint i; i < gaugeAddresses.length; ++i) {
            gaugeController.voteForGaugeWeights(gaugeAddresses[i], userWeights[i]);
        }
    }

    /***
     * @dev  Claim the stHOPE from multi Gauges to Manager, it is the benefit from voting
     * @param Gauge address of gaugeAddress
     * @return Amount amount of stHOPE claimed in the call
     */
    function claimFromGauges(address[] calldata gaugeAddresses) external {
        require(gaugeAddresses.length < 32, "LightTeamVaultManager: length must less than 32");
        for (uint i; i < gaugeAddresses.length; ++i) {
            require(gaugeAddresses[i] != address(0), "LightTeamVaultManager: wrong gauge address");
            uint256 fee = IGaugeFeeDistributor(gaugeFeeDistributor).claim(gaugeAddresses[i], address(this));
            stHopeTotalClaimed += fee;
        }  
    }

    /***
     * @dev  Claim the stHOPE from feeDistributor to Manager
     * @return Amount amount of stHOPE claimed in the call
     */
    function claimFromFeeDistributor() external returns (uint256) {
        uint256 fee = IFeeDistributor(feeDistributor).claim(address(this));
        stHopeTotalClaimed += fee;
        return fee;
    }

    /***
     * @dev  Claim the LT to Manager, it is the benefit from hoding veLT
     * @return Amount of LT claimed in the call
     */
    function claimLT() external returns (uint256) {
        uint256 claimableTokens = ILightGauge(stHopeGauge).claimableTokens(address(this));
        require(claimableTokens > 0, "LightTeamVaultManager: insufficient rewards to claim");

        address _minter = ILightGauge(stHopeGauge).minter();
        uint256 balanceBefore = IERC20(token).balanceOf(address(this));
        IMinter(_minter).mint(stHopeGauge);
        uint256 claimAmount = IERC20(token).balanceOf(address(this)) - balanceBefore;
        ltTotalClaimed += claimAmount;
        return claimAmount;
    }

    /***
     * @dev  withdraw LT that comes from rewarding, if "to" is address(0), it will be withdraw to msg.sender
     * @param to the address withrwaw to
     * @param amount the amount to withrwaw
     */
    function withdrawLTRewards(address to, uint amount) external onlyOwner {
        if (to == address(0)) to = msg.sender;
        require(amount <= ltTotalClaimed - ltRewardsWithdrew, "LightTeamVaultManager: insufficient rewards to Withraw");
        ltRewardsWithdrew += amount;
        TransferHelper.doTransferOut(token, to, amount);

        emit WithdrawLTRewards(to, amount);
    }

    /***
     * @dev  withdraw LT that unlocked, if "to" is address(0), it will be withdraw to msg.sender
     * @param to the address withrwaw to
     * @param amount the amount to withrwaw
     */
    function withdrawLT(address to, uint amount) external {
        require(msg.sender == owner() || canWithdrawByAnyone, "LightTeamVaultManager: caller is not the owner");
        if (to == address(0)) to = msg.sender;
        if (msg.sender != owner())
            require(msg.sender == to, "LightTeamVaultManager: invalid call");
    
        require(IERC20(xlt).balanceOf(to) >= amount, "LightTeamVaultManager: insufficient XLT to burn");
        IXlt(xlt).burn(to, amount);
        ltWithdrew += amount;
        TransferHelper.doTransferOut(token, to, amount);

        emit WithdrawLT(msg.sender, to, amount);
    }

    /***
     * @dev  withdraw stHLPE that comes from rewarding, if "to" is address(0), it will be withdraw to msg.sender
     * @param to the address withrwaw to
     * @param amount the amount to withrwaw 
     */
    function withdrawStHOPE(address to, uint amount) external onlyOwner {
        if (to == address(0)) to = msg.sender;
        require(amount <= stHopeTotalClaimed - stHopeWithdrew, "LightTeamVaultManager: insufficient rewards to Withraw");
        stHopeWithdrew += amount;
        TransferHelper.doTransferOut(stHopeGauge, to, amount);

        emit WithdrawStHOPE(to, amount);
    }
}

// SPDX-License-Identifier: LGPL-3.0
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract XLT is ERC20("XLT", "XLT"), Ownable {

    constructor(address manager) {
        _transferOwnership(manager);
    }

    function mint(address account, uint256 amount) external onlyOwner {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) external onlyOwner {
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity 0.8.17;

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: LGPL-3.0

pragma solidity 0.8.17;

interface IPermit2 {
    /// @notice The token and amount details for a transfer signed in the permit transfer signature
    struct TokenPermissions {
        // ERC20 token address
        address token;
        // the maximum amount that can be spent
        uint256 amount;
    }

    /// @notice The signed permit message for a single token transfer
    struct PermitTransferFrom {
        TokenPermissions permitted;
        // a unique value for every token owner's signature to prevent signature replays
        uint256 nonce;
        // deadline on the permit signature
        uint256 deadline;
    }

    /// @notice Specifies the recipient address and amount for batched transfers.
    /// @dev Recipients and amounts correspond to the index of the signed token permissions array.
    /// @dev Reverts if the requested amount is greater than the permitted signed amount.
    struct SignatureTransferDetails {
        // recipient address
        address to;
        // spender requested amount
        uint256 requestedAmount;
    }

    /// @notice Used to reconstruct the signed permit message for multiple token transfers
    /// @dev Do not need to pass in spender address as it is required that it is msg.sender
    /// @dev Note that a user still signs over a spender address
    struct PermitBatchTransferFrom {
        // the tokens and corresponding amounts permitted for a transfer
        TokenPermissions[] permitted;
        // a unique value for every token owner's signature to prevent signature replays
        uint256 nonce;
        // deadline on the permit signature
        uint256 deadline;
    }

    /// @notice A map from token owner address and a caller specified word index to a bitmap. Used to set bits in the bitmap to prevent against signature replay protection
    /// @dev Uses unordered nonces so that permit messages do not need to be spent in a certain order
    /// @dev The mapping is indexed first by the token owner, then by an index specified in the nonce
    /// @dev It returns a uint256 bitmap
    /// @dev The index, or wordPosition is capped at type(uint248).max
    function nonceBitmap(address, uint256) external view returns (uint256);

    /// @notice Transfers a token using a signed permit message
    /// @dev Reverts if the requested amount is greater than the permitted signed amount
    /// @param permit The permit data signed over by the owner
    /// @param owner The owner of the tokens to transfer
    /// @param transferDetails The spender's requested transfer details for the permitted token
    /// @param signature The signature to verify
    function permitTransferFrom(
        PermitTransferFrom memory permit,
        SignatureTransferDetails calldata transferDetails,
        address owner,
        bytes calldata signature
    ) external;

    /// @notice Transfers a token using a signed permit message
    /// @notice Includes extra data provided by the caller to verify signature over
    /// @dev The witness type string must follow EIP712 ordering of nested structs and must include the TokenPermissions type definition
    /// @dev Reverts if the requested amount is greater than the permitted signed amount
    /// @param permit The permit data signed over by the owner
    /// @param owner The owner of the tokens to transfer
    /// @param transferDetails The spender's requested transfer details for the permitted token
    /// @param witness Extra data to include when checking the user signature
    /// @param witnessTypeString The EIP-712 type definition for remaining string stub of the typehash
    /// @param signature The signature to verify
    function permitWitnessTransferFrom(
        PermitTransferFrom memory permit,
        SignatureTransferDetails calldata transferDetails,
        address owner,
        bytes32 witness,
        string calldata witnessTypeString,
        bytes calldata signature
    ) external;

    /// @notice Transfers multiple tokens using a signed permit message
    /// @param permit The permit data signed over by the owner
    /// @param owner The owner of the tokens to transfer
    /// @param transferDetails Specifies the recipient and requested amount for the token transfer
    /// @param signature The signature to verify
    function permitTransferFrom(
        PermitBatchTransferFrom memory permit,
        SignatureTransferDetails[] calldata transferDetails,
        address owner,
        bytes calldata signature
    ) external;

    /// @notice Transfers multiple tokens using a signed permit message
    /// @dev The witness type string must follow EIP712 ordering of nested structs and must include the TokenPermissions type definition
    /// @notice Includes extra data provided by the caller to verify signature over
    /// @param permit The permit data signed over by the owner
    /// @param owner The owner of the tokens to transfer
    /// @param transferDetails Specifies the recipient and requested amount for the token transfer
    /// @param witness Extra data to include when checking the user signature
    /// @param witnessTypeString The EIP-712 type definition for remaining string stub of the typehash
    /// @param signature The signature to verify
    function permitWitnessTransferFrom(
        PermitBatchTransferFrom memory permit,
        SignatureTransferDetails[] calldata transferDetails,
        address owner,
        bytes32 witness,
        string calldata witnessTypeString,
        bytes calldata signature
    ) external;

    /// @notice Invalidates the bits specified in mask for the bitmap at the word position
    /// @dev The wordPos is maxed at type(uint248).max
    /// @param wordPos A number to index the nonceBitmap at
    /// @param mask A bitmap masked against msg.sender's current bitmap at the word position
    function invalidateUnorderedNonces(uint256 wordPos, uint256 mask) external;
}

// SPDX-License-Identifier: LGPL-3.0

pragma solidity 0.8.17;

import "./IERC20.sol";
import "./IPermit2.sol";

library TransferHelper {
    
    /**
     * @dev Similar to EIP20 transfer, except it handles a False result from `transferFrom` and reverts in that case.
     *      This will revert due to insufficient balance or insufficient allowance.
     *      This function returns the actual amount received,
     *      which may be less than `amount` if there is a fee attached to the transfer.
     *
     *      Note: This wrapper safely handles non-standard ERC-20 tokens that do not return a value.
     */
    function doTransferFrom(address tokenAddress, address from, address to, uint256 amount) internal {
        IERC20 token = IERC20(tokenAddress);
        safeTransferFrom(token, from, to, amount);
    }

    /**
     * @dev transfer with permit2
     */
    function doTransferIn(
        address permit2Address,
        address tokenAddress,
        uint256 _value,
        address from,
        uint256 nonce,
        uint256 deadline,
        bytes memory signature
    ) internal returns (uint256) {
        IPermit2.PermitTransferFrom memory permit = IPermit2.PermitTransferFrom({
            permitted: IPermit2.TokenPermissions({token: tokenAddress, amount: _value}),
            nonce: nonce,
            deadline: deadline
        });
        IPermit2.SignatureTransferDetails memory transferDetails = IPermit2.SignatureTransferDetails({
            to: address(this),
            requestedAmount: _value
        });
        // Read from storage once
        IERC20 token = IERC20(permit.permitted.token);
        uint256 balanceBefore = token.balanceOf(transferDetails.to);
        if (nonce == 0 && deadline == 0 && signature.length == 0) {
            safeTransferFrom(token, from, transferDetails.to, transferDetails.requestedAmount);
        } else {
            IPermit2(permit2Address).permitTransferFrom(permit, transferDetails, from, signature);
        }
        // Calculate the amount that was *actually* transferred
        uint256 balanceAfter = IERC20(permit.permitted.token).balanceOf(address(this));
        uint256 spendAmount = balanceAfter - balanceBefore;
        assert(spendAmount == transferDetails.requestedAmount);
        
        return spendAmount;
    }

    /**
     * @dev Similar to EIP20 transfer, except it handles a False success from `transfer` and returns an explanatory
     *      error code rather than reverting. If caller has not called checked protocol's balance, this may revert due to
     *      insufficient cash held in this contract. If caller has checked protocol's balance prior to this call, and verified
     *      it is >= amount, this should not revert in normal conditions.
     *
     *      Note: This wrapper safely handles non-standard ERC-20 tokens that do not return a value.
     */
    function doTransferOut(address tokenAddress, address to, uint256 amount) internal {
        IERC20 token = IERC20(tokenAddress);
        safeTransfer(token, to, amount);
    }

    function doApprove(address tokenAddress, address to, uint256 amount) internal {
        IERC20 token = IERC20(tokenAddress);
        safeApprove(token, to, amount);
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), from) // Append the "from" argument.
            mstore(add(freeMemoryPointer, 36), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
            )
        }

        require(success, "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "TRANSFER_FAILED");
    }

    function safeApprove(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "APPROVE_FAILED");
    }
}