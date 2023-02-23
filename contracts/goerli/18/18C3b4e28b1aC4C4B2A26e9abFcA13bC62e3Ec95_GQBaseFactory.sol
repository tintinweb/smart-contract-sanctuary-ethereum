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
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
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
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
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
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
abstract contract ReentrancyGuard {
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

    constructor() {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import './interfaces/IGQBaseFactory.sol';

import './libraries/PoolTypes.sol';

import './GQStakeFactory.sol';
import './GQGalacticReserveFactory.sol';
import './GQGalacticAllianceFactory.sol';

contract GQBaseFactory is 
    Initializable,
    OwnableUpgradeable, 
    IGQBaseFactory 
{

    // GQStakeFactory
    GQStakeFactory public stakeFactory;

    // GQGalacticReserveFactory
    GQGalacticReserveFactory public galacticReserveFactory;

    // GQGalacticAllianceFactory
    GQGalacticAllianceFactory public galacticAllianceFactory;

    // ============== VARIABLES ==============
    /// @notice Variable for knowing if contract has been initialized
    bool public initialized;

    // ============== MODIFIERS ==============
    /// @notice Will return true only when contract is initialized
    modifier isInitialized() {
        require(initialized, "Error: contract not initialized");
        _;
    }

    // ============== INITIALIZE ==============
    function initialize(
        address stakeFactoryAddress, 
        address galacticReserveFactoryAddress, 
        address galacticAllianceFactoryAddress
    ) external initializer {
        __Ownable_init();

        stakeFactory = GQStakeFactory(stakeFactoryAddress);
        galacticReserveFactory = GQGalacticReserveFactory(galacticReserveFactoryAddress);
        galacticAllianceFactory = GQGalacticAllianceFactory(galacticAllianceFactoryAddress);

        initialized = true;
    }

    /// @inheritdoc IGQBaseFactory
    function createStakePool(
        address stakedToken,
        address rewardToken,
        uint256 rewardPerBlock,
        uint256 startBlock,
        uint256 endBlock,
        uint256 poolLimitPerUser,
        uint256 minimumDeposit
    ) external onlyOwner isInitialized override returns (address poolAddress) {
        poolAddress = stakeFactory.createPool(
            stakedToken,
            rewardToken,
            rewardPerBlock,
            startBlock,
            endBlock,
            poolLimitPerUser,
            minimumDeposit
        );

        emit StakePoolCreated(address(this), poolAddress, stakedToken, rewardToken, rewardPerBlock, startBlock, endBlock, poolLimitPerUser, minimumDeposit);
    }

    /// @inheritdoc IGQBaseFactory
    function createGalacticReservePool(
        address stakedToken,
        address rewardToken,
        uint256 startBlock,
        uint256 endBlock,
        uint256 lockUpDuration,
        uint256 withdrawFee,
        address feeAddress
    ) external onlyOwner isInitialized override returns (address poolAddress) {
        poolAddress = galacticReserveFactory.createPool(
            stakedToken,
            rewardToken,
            startBlock,
            endBlock,
            lockUpDuration,
            withdrawFee,
            feeAddress
        ); 

        emit GalacticReservePoolCreated(address(this), poolAddress, stakedToken, rewardToken, startBlock, endBlock, lockUpDuration, withdrawFee, feeAddress);
    }

    /// @inheritdoc IGQBaseFactory
    function createGalacticAlliancePool(
        address stakedToken,
        address rewardToken1,
        address rewardToken2,
        uint256 startBlock,
        uint256 endBlock,
        uint256 lockUpDuration,
        uint256 withdrawFee,
        address feeAddress
    ) external onlyOwner isInitialized override returns (address poolAddress) {
        poolAddress = galacticAllianceFactory.createPool(
            stakedToken,
            rewardToken1,
            rewardToken2,
            startBlock,
            endBlock,
            lockUpDuration,
            withdrawFee,
            feeAddress
        );

        emit GalacticAlliancePoolCreated(address(this), poolAddress, stakedToken, rewardToken1, rewardToken2, startBlock, endBlock, lockUpDuration, withdrawFee, feeAddress);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/*import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";*/

// TO-REVIEW Eliminada funcionalidad Upgradeable del Proxy
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract GQGalacticAlliance is
    /*Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable*/
    Ownable, 
    ReentrancyGuard
{
    /*using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;*/
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint8 constant TOKEN1 = 1;
    uint8 constant TOKEN2 = 2;

    // Is contract initialized
    bool public isInitialized;

    // The block number when REWARD distribution ends.
    uint256 public endBlock;

    // The block number when REWARD distribution starts.
    uint256 public startBlock;

    // The block number of the last pool update
    uint256 public lastUpdateBlock;

    // Lockup duration for deposit
    uint256 public lockUpDuration;

    // Withdraw fee in BP
    uint256 public withdrawFee;

    // Withdraw fee destiny address
    address public feeAddress;

    // The staked token
    /*IERC20Upgradeable public stakedToken;*/
    IERC20 public stakedToken;

    // PUI
    // The factory address 
    address public factory;

    // Accrued token per share
    mapping(uint8 => uint256) public mapOfAccTokenPerShare;

    // REWARD tokens created per block.
    mapping(uint8 => uint256) public mapOfRewardPerBlock;

    // The precision factor for reward tokens
    mapping(uint8 => uint256) public mapOfPrecisionFactor;

    // decimals places of the reward token
    mapping(uint8 => uint8) public mapOfRewardTokenDecimals;

    // The reward token
    mapping(uint8 => address) public mapOfRewardTokens;

    // Info of each user that stakes tokens (stakedToken)
    mapping(address => UserInfo) public userInfo;

    struct UserInfo {
        uint256 amount; // Staked tokens the user has provided
        uint256 rewardDebt1; // Reward debt1
        uint256 rewardDebt2; // Reward debt2
        uint256 firstDeposit; // First deposit before withdraw
    }

    event AdminTokenRecovery(address tokenRecovered, uint256 amount);
    event Deposit(address indexed user, uint256 amount);
    event Claim(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);
    event NewStartAndEndBlocks(uint256 startBlock, uint256 endBlock);
    event NewEndBlock(uint256 endBlock);
    event NewRewardPerBlock(uint256 rewardPerBlock);
    event RewardsStop(uint256 blockNumber);
    event Withdraw(address indexed user, uint256 amount);
    event NewLockUpDuration(uint256 lockUpDuration);

    // PUI
    //constructor() initializer {}

    /* TO-REVIEW AÑADIDO PUI
     * @notice Constructor of the contract
     * @param _factory: Factory address
     * @param _stakedToken: Staked token address
     * @param _rewardToken1: Reward token1 address
     * @param _rewardToken2: Reward token2 address
     * @param _startBlock: Start block
     * @param _endBlock: End block
     * @param _lockUpDuration: Duration for the deposit
     * @param _withdrawFee: Fee for early withdraw
     * @param _feeAddress: Address where fees for early withdraw will be send
     */
    constructor (
        address _factory,
        address _stakedToken,
        address _rewardToken1,
        address _rewardToken2,
        uint256 _startBlock,
        uint256 _endBlock,
        uint256 _lockUpDuration,
        uint256 _withdrawFee,
        address _feeAddress
    ) {
        //__Ownable_init();

        factory = _factory;
        //stakedToken = IERC20Upgradeable(_stakedToken);
        stakedToken = IERC20(_stakedToken);
        mapOfRewardTokens[TOKEN1] = _rewardToken1;
        mapOfRewardTokens[TOKEN2] = _rewardToken2;
        startBlock = _startBlock;
        endBlock = _endBlock;
        lockUpDuration = _lockUpDuration;
        withdrawFee = _withdrawFee;
        feeAddress = _feeAddress;

        /*mapOfRewardTokenDecimals[TOKEN1] = IERC20MetadataUpgradeable(
            mapOfRewardTokens[TOKEN1]
        ).decimals();
        mapOfRewardTokenDecimals[TOKEN2] = IERC20MetadataUpgradeable(
            mapOfRewardTokens[TOKEN2]
        ).decimals();*/
        mapOfRewardTokenDecimals[TOKEN1] = IERC20Metadata(
            mapOfRewardTokens[TOKEN1]
        ).decimals();
        mapOfRewardTokenDecimals[TOKEN2] = IERC20Metadata(
            mapOfRewardTokens[TOKEN2]
        ).decimals();
        require(
            mapOfRewardTokenDecimals[TOKEN1] < 30 &&
                mapOfRewardTokenDecimals[TOKEN2] < 30,
            "Must be inferior to 30"
        );

        mapOfPrecisionFactor[TOKEN1] = uint256(
            10**(uint256(30).sub(uint256(mapOfRewardTokenDecimals[TOKEN1])))
        );
        mapOfPrecisionFactor[TOKEN2] = uint256(
            10**(uint256(30).sub(uint256(mapOfRewardTokenDecimals[TOKEN2])))
        );

        // Set the lastRewardBlock as the startBlock
        lastUpdateBlock = startBlock;

        isInitialized = true;
    }

    /*
     * @notice Constructor of the contract
     * @param _stakedToken: staked token address
     * @param _rewardToken1: reward token1 address
     * @param _rewardToken2: reward token2 address
     * @param _rewardPerBlock: reward per block (in rewardToken)
     * @param _startBlock: start block
     * @param _endBlock: end block
     * @param _lockUpDuration: duration for the deposit
     * @param _withdrawFee: fee for early withdraw
     * @param _feeAddress: address where fees for early withdraw will be send
     */
    /*function initialize(
        IERC20Upgradeable _stakedToken,
        address _rewardToken1,
        address _rewardToken2,
        uint256 _startBlock,
        uint256 _endBlock,
        uint256 _lockUpDuration,
        uint256 _withdrawFee,
        address _feeAddress
    ) public initializer {
        __Ownable_init();
        stakedToken = _stakedToken;
        mapOfRewardTokens[TOKEN1] = _rewardToken1;
        mapOfRewardTokens[TOKEN2] = _rewardToken2;
        startBlock = _startBlock;
        endBlock = _endBlock;
        lockUpDuration = _lockUpDuration;
        withdrawFee = _withdrawFee;
        feeAddress = _feeAddress;

        mapOfRewardTokenDecimals[TOKEN1] = IERC20MetadataUpgradeable(
            mapOfRewardTokens[TOKEN1]
        ).decimals();
        mapOfRewardTokenDecimals[TOKEN2] = IERC20MetadataUpgradeable(
            mapOfRewardTokens[TOKEN2]
        ).decimals();
        require(
            mapOfRewardTokenDecimals[TOKEN1] < 30 &&
                mapOfRewardTokenDecimals[TOKEN2] < 30,
            "Must be inferior to 30"
        );

        mapOfPrecisionFactor[TOKEN1] = uint256(
            10**(uint256(30).sub(uint256(mapOfRewardTokenDecimals[TOKEN1])))
        );
        mapOfPrecisionFactor[TOKEN2] = uint256(
            10**(uint256(30).sub(uint256(mapOfRewardTokenDecimals[TOKEN2])))
        );

        // Set the lastRewardBlock as the startBlock
        lastUpdateBlock = startBlock;

        isInitialized = true;
    }*/

    /*
     * @notice Deposit staked tokens and collect reward tokens (if any)
     * @param _amount: amount to deposit (in stakedToken)
     */
    function deposit(uint256 _amount) external nonReentrant {
        UserInfo storage user = userInfo[msg.sender];

        _updatePool();

        if (user.amount > 0) {
            uint256 pendingToken1 = user
                .amount
                .mul(mapOfAccTokenPerShare[TOKEN1])
                .div(mapOfPrecisionFactor[TOKEN1])
                .sub(user.rewardDebt1);
            if (pendingToken1 > 0) {
                _safeTokenTransfer(
                    mapOfRewardTokens[TOKEN1],
                    msg.sender,
                    pendingToken1
                );
            }
            uint256 pendingToken2 = user
                .amount
                .mul(mapOfAccTokenPerShare[TOKEN2])
                .div(mapOfPrecisionFactor[TOKEN2])
                .sub(user.rewardDebt2);

            if (pendingToken2 > 0) {
                _safeTokenTransfer(
                    mapOfRewardTokens[TOKEN2],
                    msg.sender,
                    pendingToken2
                );
            }
        }

        if (_amount > 0) {
            user.amount = user.amount.add(_amount);
            stakedToken.safeTransferFrom(
                address(msg.sender),
                address(this),
                _amount
            );
            user.firstDeposit = user.firstDeposit == 0
                ? block.timestamp
                : user.firstDeposit;
        }

        user.rewardDebt1 = user
            .amount
            .mul(mapOfAccTokenPerShare[TOKEN1])
            .div(mapOfPrecisionFactor[TOKEN1]);

        user.rewardDebt2 = user
            .amount
            .mul(mapOfAccTokenPerShare[TOKEN2])
            .div(mapOfPrecisionFactor[TOKEN2]);

        emit Deposit(msg.sender, _amount);
    }

    /*
     * @notice Withdraw staked tokens and collect reward tokens
     * @param _amount: amount to withdraw (in rewardToken)
     */
    function withdraw(uint256 _amount) external nonReentrant {
        require(_amount > 0, "Error: Invalid amount");
        UserInfo storage user = userInfo[msg.sender];
        require(user.amount >= _amount, "Amount to withdraw too high");
        _updatePool();

        uint256 pendingToken1 = user
            .amount
            .mul(mapOfAccTokenPerShare[TOKEN1])
            .div(mapOfPrecisionFactor[TOKEN1])
            .sub(user.rewardDebt1);
        uint256 pendingToken2 = user
            .amount
            .mul(mapOfAccTokenPerShare[TOKEN2])
            .div(mapOfPrecisionFactor[TOKEN2])
            .sub(user.rewardDebt2);

        user.amount = user.amount.sub(_amount);
        uint256 _amountToSend = _amount;
        if (block.timestamp < (user.firstDeposit + lockUpDuration)) {
            uint256 _feeAmountToSend = _amountToSend.mul(withdrawFee).div(
                10000
            );
            stakedToken.safeTransfer(address(feeAddress), _feeAmountToSend);
            _amountToSend = _amountToSend - _feeAmountToSend;
        }
        stakedToken.safeTransfer(address(msg.sender), _amountToSend);
        user.firstDeposit = user.firstDeposit == 0
            ? block.timestamp
            : user.firstDeposit;

        if (pendingToken1 > 0) {
            _safeTokenTransfer(
                mapOfRewardTokens[TOKEN1],
                msg.sender,
                pendingToken1
            );
        }
        if (pendingToken2 > 0) {
            _safeTokenTransfer(
                mapOfRewardTokens[TOKEN2],
                msg.sender,
                pendingToken2
            );
        }

        user.rewardDebt1 = user
            .amount
            .mul(mapOfAccTokenPerShare[TOKEN1])
            .div(mapOfPrecisionFactor[TOKEN1]);
        user.rewardDebt2 = user
            .amount
            .mul(mapOfAccTokenPerShare[TOKEN2])
            .div(mapOfPrecisionFactor[TOKEN2]);

        emit Withdraw(msg.sender, _amount);
    }

    /*
     * @notice Claim reward tokens
     */
    function claim() external nonReentrant {
        UserInfo storage user = userInfo[msg.sender];

        _updatePool();

        if (user.amount > 0) {
            uint256 pendingToken1 = user
                .amount
                .mul(mapOfAccTokenPerShare[TOKEN1])
                .div(mapOfPrecisionFactor[TOKEN1])
                .sub(user.rewardDebt1);

            if (pendingToken1 > 0) {
                _safeTokenTransfer(
                    mapOfRewardTokens[TOKEN1],
                    msg.sender,
                    pendingToken1
                );
                emit Claim(msg.sender, pendingToken1);
            }
            uint256 pendingToken2 = user
                .amount
                .mul(mapOfAccTokenPerShare[TOKEN2])
                .div(mapOfPrecisionFactor[TOKEN2])
                .sub(user.rewardDebt2);

            if (pendingToken2 > 0) {
                _safeTokenTransfer(
                    mapOfRewardTokens[TOKEN2],
                    msg.sender,
                    pendingToken2
                );
                emit Claim(msg.sender, pendingToken2);
            }
        }

        user.rewardDebt1 = user
            .amount
            .mul(mapOfAccTokenPerShare[TOKEN1])
            .div(mapOfPrecisionFactor[TOKEN1]);

        user.rewardDebt2 = user
            .amount
            .mul(mapOfAccTokenPerShare[TOKEN2])
            .div(mapOfPrecisionFactor[TOKEN2]);
    }

    /*
     * @notice Withdraw staked tokens without caring about rewards
     * @dev Needs to be for emergency.
     */
    function emergencyWithdraw() external nonReentrant {
        UserInfo storage user = userInfo[msg.sender];
        uint256 _amountToTransfer = user.amount;
        user.amount = 0;
        user.rewardDebt1 = 0;
        user.rewardDebt2 = 0;

        // Avoid users send an amount with 0 tokens
        if (_amountToTransfer > 0) {
            if (block.timestamp < (user.firstDeposit + lockUpDuration)) {
                uint256 _feeAmountToSend = _amountToTransfer
                    .mul(withdrawFee)
                    .div(10000);
                stakedToken.safeTransfer(address(feeAddress), _feeAmountToSend);
                _amountToTransfer = _amountToTransfer - _feeAmountToSend;
            }
            stakedToken.safeTransfer(address(msg.sender), _amountToTransfer);
        }

        emit EmergencyWithdraw(msg.sender, _amountToTransfer);
    }

    /**
     * @notice It allows the admin to recover wrong tokens sent to the contract
     * @param _tokenAddress: the address of the token to withdraw
     * @param _tokenAmount: the number of tokens to withdraw
     * @dev This function is only callable by admin.
     */
    function recoverWrongTokens(address _tokenAddress, uint256 _tokenAmount)
        external
        onlyOwner
    {
        require(
            _tokenAddress != address(stakedToken),
            "Cannot be staked token"
        );
        require(
            _tokenAddress != mapOfRewardTokens[TOKEN1] &&
                _tokenAddress != mapOfRewardTokens[TOKEN2],
            "Cannot be reward token"
        );

        /*IERC20Upgradeable(_tokenAddress).safeTransfer(
            address(msg.sender),
            _tokenAmount
        );*/
        IERC20(_tokenAddress).safeTransfer(
            address(msg.sender),
            _tokenAmount
        );

        emit AdminTokenRecovery(_tokenAddress, _tokenAmount);
    }

    /*
     * @notice Stop rewards
     * @dev Only callable by owner
     */
    function stopReward() external onlyOwner {
        endBlock = block.number;
    }

    /*
     * @notice Update reward per block
     * @dev Only callable by owner.
     * @param _rewardPerBlock: the reward per block
     */
    function updateRewardPerBlock(uint8 _rewardTokenId, uint256 _rewardPerBlock)
        external
        onlyOwner
    {
        require(block.number < startBlock, "Pool has started");
        mapOfRewardPerBlock[_rewardTokenId] = _rewardPerBlock;
        emit NewRewardPerBlock(_rewardPerBlock);
    }

    /**
     * @notice It allows the admin to update start and end blocks
     * @dev This function is only callable by owner.
     * @param _startBlock: the new start block
     * @param _bonusEndBlock: the new end block
     */
    function updateStartAndEndBlocks(
        uint256 _startBlock,
        uint256 _bonusEndBlock
    ) external onlyOwner {
        require(block.number < startBlock, "Pool has started");
        require(
            _startBlock < _bonusEndBlock,
            "New startBlock must be lower than new endBlock"
        );
        require(
            block.number < _startBlock,
            "New startBlock must be higher than current block"
        );

        startBlock = _startBlock;
        endBlock = _bonusEndBlock;

        // Set the lastRewardBlock as the startBlock
        lastUpdateBlock = startBlock;

        emit NewStartAndEndBlocks(_startBlock, _bonusEndBlock);
    }

    /*
     * @notice Sets the lock up duration
     * @param _lockUpDuration: The lock up duration in seconds (block timestamp)
     * @dev This function is only callable by owner.
     */
    function setLockUpDuration(uint256 _lockUpDuration) external onlyOwner {
        lockUpDuration = _lockUpDuration;
        emit NewLockUpDuration(lockUpDuration);
    }

    /*
     * @notice Sets start block of the pool given a block amount
     * @param _blocks: block amount
     * @dev This function is only callable by owner.
     */
    function poolStartIn(uint256 _blocks) external onlyOwner {
        poolSetStart(block.number.add(_blocks));
    }

    /*
     * @notice Set the duration and start block of the pool
     * @param _startBlock: start block
     * @param _durationBlocks: duration block amount
     * @dev This function is only callable by owner.
     */
    function poolSetStartAndDuration(
        uint256 _startBlock,
        uint256 _durationBlocks
    ) external onlyOwner {
        poolSetStart(_startBlock);
        poolSetDuration(_durationBlocks);
    }

    /*
     * @notice Withdraws the remaining funds
     * @param _to The address where the funds will be sent
     */
    function withdrawRemains(uint8 _rewardTokenId, address _to)
        external
        onlyOwner
    {
        require(block.number > endBlock, "Error: Pool not finished yet");
        /*uint256 tokenBal = IERC20Upgradeable(mapOfRewardTokens[_rewardTokenId])
            .balanceOf(address(this));*/
        uint256 tokenBal = IERC20(mapOfRewardTokens[_rewardTokenId])
            .balanceOf(address(this));            
        require(tokenBal > 0, "Error: No remaining funds");
        /*IERC20Upgradeable(mapOfRewardTokens[_rewardTokenId]).safeTransfer(
            _to,
            tokenBal
        );*/
        IERC20(mapOfRewardTokens[_rewardTokenId]).safeTransfer(
            _to,
            tokenBal
        );        
    }

    /*
     * @notice Deposits the reward token1 funds
     * @param _to The address where the funds will be sent
     */
    function depositRewardTokenFunds(uint8 _rewardTokenId, uint256 _amount)
        external
        onlyOwner
    {
        /*IERC20Upgradeable(mapOfRewardTokens[_rewardTokenId]).safeTransfer(
            address(this),
            _amount
        );*/
        IERC20(mapOfRewardTokens[_rewardTokenId]).safeTransfer(
            address(this),
            _amount
        );        
    }

    /*
     * @notice Gets the reward per block for UI
     * @return reward per block
     */
    function rewarPerBlockUI(uint8 _rewardTokenId)
        external
        view
        returns (uint256)
    {
        return
            mapOfRewardPerBlock[_rewardTokenId].div(
                10**uint256(mapOfRewardTokenDecimals[_rewardTokenId])
            );
    }

    /*
     * @notice View function to see pending reward on frontend.
     * @param _user: user address
     * @return Pending reward for a given user
     */
    function pendingReward(uint8 _rewardTokenId, address _user)
        external
        view
        returns (uint256)
    {
        UserInfo storage user = userInfo[_user];
        uint256 rewardDebt = _rewardTokenId == TOKEN1
            ? user.rewardDebt1
            : user.rewardDebt2;
        uint256 stakedTokenSupply = stakedToken.balanceOf(address(this));
        if (block.number > lastUpdateBlock && stakedTokenSupply != 0) {
            uint256 multiplier = _getMultiplier(lastUpdateBlock, block.number);
            uint256 tokenReward = multiplier.mul(
                mapOfRewardPerBlock[_rewardTokenId]
            );
            uint256 adjustedPerShare = mapOfAccTokenPerShare[_rewardTokenId]
                .add(
                    tokenReward.mul(mapOfPrecisionFactor[_rewardTokenId]).div(
                        stakedTokenSupply
                    )
                );
            return
                user
                    .amount
                    .mul(adjustedPerShare)
                    .div(mapOfPrecisionFactor[_rewardTokenId])
                    .sub(rewardDebt);
        } else {
            return
                user
                    .amount
                    .mul(mapOfAccTokenPerShare[_rewardTokenId])
                    .div(mapOfPrecisionFactor[_rewardTokenId])
                    .sub(rewardDebt);
        }
    }

    /*
     * @notice Sets start block of the pool
     * @param _startBlock: start block
     * @dev This function is only callable by owner.
     */
    function poolSetStart(uint256 _startBlock) public onlyOwner {
        require(block.number < startBlock, "Pool has started");
        uint256 rewardDurationValue = rewardDuration();
        startBlock = _startBlock;
        endBlock = startBlock.add(rewardDurationValue);
        lastUpdateBlock = startBlock;
        emit NewStartAndEndBlocks(startBlock, endBlock);
    }

    /*
     * @notice Set the duration of the pool
     * @param _durationBlocks: duration block amount
     * @dev This function is only callable by owner.
     */
    function poolSetDuration(uint256 _durationBlocks) public onlyOwner {
        require(block.number < startBlock, "Pool has started");
        endBlock = startBlock.add(_durationBlocks);
        poolCalcRewardPerBlock(TOKEN1);
        poolCalcRewardPerBlock(TOKEN2);
        emit NewEndBlock(endBlock);
    }

    /*
     * @notice Calculates the rewardPerBlock of the pool
     * @dev This function is only callable by owner.
     */
    function poolCalcRewardPerBlock(uint8 _rewardTokenId) public onlyOwner {
        //uint256 rewardBal = IERC20Upgradeable(mapOfRewardTokens[_rewardTokenId]).balanceOf(address(this));
        uint256 rewardBal = IERC20(mapOfRewardTokens[_rewardTokenId]).balanceOf(address(this));
        mapOfRewardPerBlock[_rewardTokenId] = rewardBal.div(rewardDuration());
    }

    /*
     * @notice Gets the reward duration
     * @return reward duration
     */
    function rewardDuration() public view returns (uint256) {
        return endBlock.sub(startBlock);
    }

    /*
     * @notice SendPending tokens to claimer
     * @param pending: amount to claim
     */
    function _safeTokenTransfer(
        address _rewardToken,
        address _to,
        uint256 _amount
    ) internal {
        //uint256 rewardTokenBalance = IERC20Upgradeable(_rewardToken).balanceOf(address(this));
        uint256 rewardTokenBalance = IERC20(_rewardToken).balanceOf(address(this));
        if (_amount > rewardTokenBalance) {
            //IERC20Upgradeable(_rewardToken).safeTransfer(_to, rewardTokenBalance);
            IERC20(_rewardToken).safeTransfer(_to, rewardTokenBalance);
        } else {
            //IERC20Upgradeable(_rewardToken).safeTransfer(_to, _amount);
            IERC20(_rewardToken).safeTransfer(_to, _amount);
        }
    }

    /*
     * @notice Update reward variables of the given pool to be up-to-date.
     */
    function _updatePool() internal {
        if (block.number <= lastUpdateBlock) {
            return;
        }

        uint256 stakedTokenSupply = stakedToken.balanceOf(address(this));

        if (stakedTokenSupply == 0) {
            lastUpdateBlock = block.number;
            return;
        }

        uint256 multiplier = _getMultiplier(lastUpdateBlock, block.number);
        uint256 tokenReward1 = multiplier.mul(mapOfRewardPerBlock[TOKEN1]);
        uint256 tokenReward2 = multiplier.mul(mapOfRewardPerBlock[TOKEN2]);
        mapOfAccTokenPerShare[TOKEN1] = mapOfAccTokenPerShare[TOKEN1].add(
            tokenReward1.mul(mapOfPrecisionFactor[TOKEN1]).div(stakedTokenSupply)
        );
        mapOfAccTokenPerShare[TOKEN2] = mapOfAccTokenPerShare[TOKEN2].add(
            tokenReward2.mul(mapOfPrecisionFactor[TOKEN2]).div(stakedTokenSupply)
        );
        lastUpdateBlock = block.number;
    }

    /*
     * @notice Return reward multiplier over the given _from to _to block.
     * @param _from: block to start
     * @param _to: block to finish
     * @return multiplier
     */
    function _getMultiplier(uint256 _from, uint256 _to)
        internal
        view
        returns (uint256)
    {
        if (_to <= endBlock) {
            return _to.sub(_from);
        } else if (_from >= endBlock) {
            return 0;
        } else {
            return endBlock.sub(_from);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";

import './interfaces/IGQGalacticAllianceFactory.sol';

import './GQGalacticAlliance.sol';

contract GQGalacticAllianceFactory is 
    Initializable,
    OwnableUpgradeable, 
    IGQGalacticAllianceFactory 
{
    
    using CountersUpgradeable for CountersUpgradeable.Counter;

    ///@notice Info of the GQ GalacticAlliance Pools
    mapping(uint256 => mapping(address => PoolTypes.GQGalacticAllianceType)) public pools;

    ///@notice Counter to get the identifier for the pools
    CountersUpgradeable.Counter private _poolIdCounter;

    // ============== VARIABLES ==============
    /// @notice Variable for knowing if contract has been initialized
    bool public initialized;

    // ============== MODIFIERS ==============
    /// @notice Will return true only when contract is initialized
    modifier isInitialized() {
        require(initialized, "Error: contract not initialized");
        _;
    }

    // ============== INITIALIZE ==============
    function initialize() external initializer {
        __Ownable_init();

        initialized = true;
    }

    /// @inheritdoc IGQGalacticAllianceFactory
    function createPool(
        address stakedToken,
        address rewardToken1,
        address rewardToken2,
        uint256 startBlock,
        uint256 endBlock,
        uint256 lockUpDuration,
        uint256 withdrawFee,
        address feeAddress
    ) external onlyOwner isInitialized override returns (address poolAddress) {
        // Check that the tokens are not the address(0)
        require(stakedToken != address(0), "Staked token can't be the address 0.");
        require(rewardToken1 != address(0), "Reward token1 can't be the address 0.");
        require(rewardToken2 != address(0), "Reward token2 can't be the address 0.");

        address factory = address(this);

        poolAddress = address(new GQGalacticAlliance{salt: keccak256(abi.encode(stakedToken, rewardToken1, rewardToken2))}(
            factory,
            stakedToken,
            rewardToken1,
            rewardToken2,
            startBlock,
            endBlock,
            lockUpDuration,
            withdrawFee,
            feeAddress
        ));

        uint256 poolId = _poolIdCounter.current();
        pools[poolId][poolAddress] = PoolTypes.GQGalacticAllianceType(
            factory,
            stakedToken,
            rewardToken1,
            rewardToken2,
            startBlock,
            endBlock,
            lockUpDuration,
            withdrawFee,
            feeAddress
        );
        _poolIdCounter.increment();

        emit GalacticAlliancePoolCreated(factory, poolAddress, stakedToken, rewardToken1, rewardToken2, startBlock, endBlock, lockUpDuration, withdrawFee, feeAddress);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract GQGalacticReserve is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Accrued token per share
    uint256 public accTokenPerShare;

    // The block number when REWARD distribution ends.
    uint256 public endBlock;

    // The block number when REWARD distribution starts.
    uint256 public startBlock;

    // The block number of the last pool update
    uint256 public lastUpdateBlock;

    // REWARD tokens created per block.
    uint256 public rewardPerBlock;

    // Lockup duration for deposit
    uint256 public lockUpDuration;

    // Withdraw fee in BP
    uint256 public withdrawFee;

    // The precision factor
    uint256 public PRECISION_FACTOR;

    // decimals places of the reward token
    uint8 public rewardTokenDecimals;

    // Withdraw fee destiny address
    address public feeAddress;

    // The reward token
    IERC20 public rewardToken;

    // The staked token
    IERC20 public stakedToken;

    // PUI
    // The factory address 
    address public factory;

    // Info of each user that stakes tokens (stakedToken)
    mapping(address => UserInfo) public userInfo;

    struct UserInfo {
        uint256 amount; // Staked tokens the user has provided
        uint256 rewardDebt; // Reward debt
        uint256 firstDeposit; // First deposit before withdraw
    }

    event AdminTokenRecovery(address tokenRecovered, uint256 amount);
    event Deposit(address indexed user, uint256 amount);
    event Claim(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);
    event NewStartAndEndBlocks(uint256 startBlock, uint256 endBlock);
    event NewEndBlock(uint256 endBlock);
    event NewRewardPerBlock(uint256 rewardPerBlock);
    event RewardsStop(uint256 blockNumber);
    event Withdraw(address indexed user, uint256 amount);
    event NewLockUpDuration(uint256 lockUpDuration);

    /*
     * @notice Constructor of the contract
     * @param _factory: Factory address     
     * @param _stakedToken: Staked token address
     * @param _rewardToken: Reward token address
     * @param _startBlock: Start block
     * @param _endBlock: End block
     * @param _lockUpDuration: Duration for the deposit
     * @param _withdrawFee: Fee for early withdraw
     * @param _feeAddress: Address where fees for early withdraw will be send
     */
     // MODIFIED PUI
    constructor(
        address _factory,
        address _stakedToken,
        address _rewardToken,
        uint256 _startBlock,
        uint256 _endBlock,
        uint256 _lockUpDuration,
        uint256 _withdrawFee,
        address _feeAddress
    ) {
        factory = _factory;
        stakedToken = IERC20(_stakedToken);
        rewardToken = IERC20(_rewardToken);
        startBlock = _startBlock;
        endBlock = _endBlock;
        lockUpDuration = _lockUpDuration;
        withdrawFee = _withdrawFee;
        feeAddress = _feeAddress;

        rewardTokenDecimals = IERC20Metadata(address(rewardToken)).decimals();
        uint256 decimalsRewardToken = uint256(rewardTokenDecimals);
        require(decimalsRewardToken < 30, "Must be inferior to 30");

        PRECISION_FACTOR = uint256(10**(uint256(30).sub(decimalsRewardToken)));

        // Set the lastRewardBlock as the startBlock
        lastUpdateBlock = startBlock;
    }

    /*
     * @notice Deposit staked tokens and collect reward tokens (if any)
     * @param _amount: amount to deposit (in stakedToken)
     */
    function deposit(uint256 _amount) external nonReentrant {
        UserInfo storage user = userInfo[msg.sender];

        _updatePool();

        if (user.amount > 0) {
            uint256 pending = user
                .amount
                .mul(accTokenPerShare)
                .div(PRECISION_FACTOR)
                .sub(user.rewardDebt);
            if (pending > 0) {
                _safeTokenTransfer(msg.sender, pending);
            }
        }

        if (_amount > 0) {
            user.amount = user.amount.add(_amount);
            stakedToken.safeTransferFrom(
                address(msg.sender),
                address(this),
                _amount
            );
            user.firstDeposit = user.firstDeposit == 0
                ? block.timestamp
                : user.firstDeposit;
        }

        user.rewardDebt = user.amount.mul(accTokenPerShare).div(
            PRECISION_FACTOR
        );

        emit Deposit(msg.sender, _amount);
    }

    /*
     * @notice Withdraw staked tokens and collect reward tokens
     * @param _amount: amount to withdraw (in rewardToken)
     */
    function withdraw(uint256 _amount) external nonReentrant {
        require(_amount > 0, "Error: Invalid amount");
        UserInfo storage user = userInfo[msg.sender];
        require(user.amount >= _amount, "Amount to withdraw too high");
        _updatePool();

        uint256 pending = user
            .amount
            .mul(accTokenPerShare)
            .div(PRECISION_FACTOR)
            .sub(user.rewardDebt);

        user.amount = user.amount.sub(_amount);
        uint256 _amountToSend = _amount;
        if (block.timestamp < (user.firstDeposit + lockUpDuration)) {
            uint256 _feeAmountToSend = _amountToSend.mul(withdrawFee).div(
                10000
            );
            stakedToken.safeTransfer(address(feeAddress), _feeAmountToSend);
            _amountToSend = _amountToSend - _feeAmountToSend;
        }
        stakedToken.safeTransfer(address(msg.sender), _amountToSend);
        user.firstDeposit = user.firstDeposit == 0
            ? block.timestamp
            : user.firstDeposit;

        if (pending > 0) {
            _safeTokenTransfer(msg.sender, pending);
        }

        user.rewardDebt = user.amount.mul(accTokenPerShare).div(
            PRECISION_FACTOR
        );

        emit Withdraw(msg.sender, _amount);
    }

    /*
     * @notice Claim reward tokens
     */
    function claim() external nonReentrant {
        UserInfo storage user = userInfo[msg.sender];

        _updatePool();

        if (user.amount > 0) {
            uint256 pending = user
                .amount
                .mul(accTokenPerShare)
                .div(PRECISION_FACTOR)
                .sub(user.rewardDebt);

            if (pending > 0) {
                _safeTokenTransfer(msg.sender, pending);
                emit Claim(msg.sender, pending);
            }
        }

        user.rewardDebt = user.amount.mul(accTokenPerShare).div(
            PRECISION_FACTOR
        );
    }

    /*
     * @notice Withdraw staked tokens without caring about rewards
     * @dev Needs to be for emergency.
     */
    function emergencyWithdraw() external nonReentrant {
        UserInfo storage user = userInfo[msg.sender];
        uint256 _amountToTransfer = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;

        // Avoid users send an amount with 0 tokens
        if (_amountToTransfer > 0) {
            if (block.timestamp < (user.firstDeposit + lockUpDuration)) {
                uint256 _feeAmountToSend = _amountToTransfer
                    .mul(withdrawFee)
                    .div(10000);
                stakedToken.safeTransfer(address(feeAddress), _feeAmountToSend);
                _amountToTransfer = _amountToTransfer - _feeAmountToSend;
            }
            stakedToken.safeTransfer(address(msg.sender), _amountToTransfer);
        }

        emit EmergencyWithdraw(msg.sender, _amountToTransfer);
    }

    /**
     * @notice It allows the admin to recover wrong tokens sent to the contract
     * @param _tokenAddress: the address of the token to withdraw
     * @param _tokenAmount: the number of tokens to withdraw
     * @dev This function is only callable by admin.
     */
    function recoverWrongTokens(address _tokenAddress, uint256 _tokenAmount)
        external
        onlyOwner
    {
        require(
            _tokenAddress != address(stakedToken),
            "Cannot be staked token"
        );
        require(
            _tokenAddress != address(rewardToken),
            "Cannot be reward token"
        );

        IERC20(_tokenAddress).safeTransfer(address(msg.sender), _tokenAmount);

        emit AdminTokenRecovery(_tokenAddress, _tokenAmount);
    }

    /*
     * @notice Stop rewards
     * @dev Only callable by owner
     */
    function stopReward() external onlyOwner {
        endBlock = block.number;
    }

    /*
     * @notice Update reward per block
     * @dev Only callable by owner.
     * @param _rewardPerBlock: the reward per block
     */
    function updateRewardPerBlock(uint256 _rewardPerBlock) external onlyOwner {
        require(block.number < startBlock, "Pool has started");
        rewardPerBlock = _rewardPerBlock;
        emit NewRewardPerBlock(_rewardPerBlock);
    }

    /**
     * @notice It allows the admin to update start and end blocks
     * @dev This function is only callable by owner.
     * @param _startBlock: the new start block
     * @param _bonusEndBlock: the new end block
     */
    function updateStartAndEndBlocks(
        uint256 _startBlock,
        uint256 _bonusEndBlock
    ) external onlyOwner {
        require(block.number < startBlock, "Pool has started");
        require(
            _startBlock < _bonusEndBlock,
            "New startBlock must be lower than new endBlock"
        );
        require(
            block.number < _startBlock,
            "New startBlock must be higher than current block"
        );

        startBlock = _startBlock;
        endBlock = _bonusEndBlock;

        // Set the lastRewardBlock as the startBlock
        lastUpdateBlock = startBlock;

        emit NewStartAndEndBlocks(_startBlock, _bonusEndBlock);
    }

    /*
     * @notice Sets the lock up duration
     * @param _lockUpDuration: The lock up duration in seconds (block timestamp)
     * @dev This function is only callable by owner.
     */
    function setLockUpDuration(uint256 _lockUpDuration) external onlyOwner {
        lockUpDuration = _lockUpDuration;
        emit NewLockUpDuration(lockUpDuration);
    }

    /*
     * @notice Sets start block of the pool given a block amount
     * @param _blocks: block amount
     * @dev This function is only callable by owner.
     */
    function poolStartIn(uint256 _blocks) external onlyOwner {
        poolSetStart(block.number.add(_blocks));
    }

    /*
     * @notice Set the duration and start block of the pool
     * @param _startBlock: start block
     * @param _durationBlocks: duration block amount
     * @dev This function is only callable by owner.
     */
    function poolSetStartAndDuration(
        uint256 _startBlock,
        uint256 _durationBlocks
    ) external onlyOwner {
        poolSetStart(_startBlock);
        poolSetDuration(_durationBlocks);
    }

    /*
     * @notice Withdraws the remaining funds
     * @param _to The address where the funds will be sent
     */
    function withdrawRemains(address _to) external onlyOwner {
        require(block.number > endBlock, "Error: Pool not finished yet");
        uint256 tokenBal = rewardToken.balanceOf(address(this));
        require(tokenBal > 0, "Error: No remaining funds");
        IERC20(rewardToken).safeTransfer(_to, tokenBal);
    }

    /*
     * @notice Withdraws the remaining funds
     * @param _to The address where the funds will be sent
     */
    function depositRewardFunds(uint256 _amount) external onlyOwner {
        IERC20(rewardToken).safeTransfer(address(this), _amount);
    }

    /*
     * @notice Gets the reward per block for UI
     * @return reward per block
     */
    function rewardPerBlockUI() external view returns (uint256) {
        return rewardPerBlock.div(10**uint256(rewardTokenDecimals));
    }

    /*
     * @notice View function to see pending reward on frontend.
     * @param _user: user address
     * @return Pending reward for a given user
     */
    function pendingReward(address _user) external view returns (uint256) {
        UserInfo storage user = userInfo[_user];
        uint256 stakedTokenSupply = stakedToken.balanceOf(address(this));
        if (block.number > lastUpdateBlock && stakedTokenSupply != 0) {
            uint256 multiplier = _getMultiplier(lastUpdateBlock, block.number);
            uint256 tokenReward = multiplier.mul(rewardPerBlock);
            uint256 adjustedTokenPerShare = accTokenPerShare.add(
                tokenReward.mul(PRECISION_FACTOR).div(stakedTokenSupply)
            );
            return
                user
                    .amount
                    .mul(adjustedTokenPerShare)
                    .div(PRECISION_FACTOR)
                    .sub(user.rewardDebt);
        } else {
            return
                user.amount.mul(accTokenPerShare).div(PRECISION_FACTOR).sub(
                    user.rewardDebt
                );
        }
    }

    /*
     * @notice Sets start block of the pool
     * @param _startBlock: start block
     * @dev This function is only callable by owner.
     */
    function poolSetStart(uint256 _startBlock) public onlyOwner {
        require(block.number < startBlock, "Pool has started");
        uint256 rewardDurationValue = rewardDuration();
        startBlock = _startBlock;
        endBlock = startBlock.add(rewardDurationValue);
        lastUpdateBlock = startBlock;
        emit NewStartAndEndBlocks(startBlock, endBlock);
    }

    /*
     * @notice Set the duration of the pool
     * @param _durationBlocks: duration block amount
     * @dev This function is only callable by owner.
     */
    function poolSetDuration(uint256 _durationBlocks) public onlyOwner {
        require(block.number < startBlock, "Pool has started");
        endBlock = startBlock.add(_durationBlocks);
        poolCalcRewardPerBlock();
        emit NewEndBlock(endBlock);
    }

    /*
     * @notice Calculates the rewardPerBlock of the pool
     * @dev This function is only callable by owner.
     */
    function poolCalcRewardPerBlock() public onlyOwner {
        uint256 rewardBal = rewardToken.balanceOf(address(this));
        rewardPerBlock = rewardBal.div(rewardDuration());
    }

    /*
     * @notice Gets the reward duration
     * @return reward duration
     */
    function rewardDuration() public view returns (uint256) {
        return endBlock.sub(startBlock);
    }

    /*
     * @notice SendPending tokens to claimer
     * @param pending: amount to claim
     */
    function _safeTokenTransfer(address _to, uint256 _amount) internal {
        uint256 rewardTokenBalance = rewardToken.balanceOf(address(this));
        if (_amount > rewardTokenBalance) {
            rewardToken.safeTransfer(_to, rewardTokenBalance);
        } else {
            rewardToken.safeTransfer(_to, _amount);
        }
    }

    /*
     * @notice Update reward variables of the given pool to be up-to-date.
     */
    function _updatePool() internal {
        if (block.number <= lastUpdateBlock) {
            return;
        }

        uint256 stakedTokenSupply = stakedToken.balanceOf(address(this));

        if (stakedTokenSupply == 0) {
            lastUpdateBlock = block.number;
            return;
        }

        uint256 multiplier = _getMultiplier(lastUpdateBlock, block.number);
        uint256 tokenReward = multiplier.mul(rewardPerBlock);
        accTokenPerShare = accTokenPerShare.add(
            tokenReward.mul(PRECISION_FACTOR).div(stakedTokenSupply)
        );
        lastUpdateBlock = block.number;
    }

    /*
     * @notice Return reward multiplier over the given _from to _to block.
     * @param _from: block to start
     * @param _to: block to finish
     * @return multiplier
     */
    function _getMultiplier(uint256 _from, uint256 _to)
        internal
        view
        returns (uint256)
    {
        if (_to <= endBlock) {
            return _to.sub(_from);
        } else if (_from >= endBlock) {
            return 0;
        } else {
            return endBlock.sub(_from);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";

import './interfaces/IGQGalacticReserveFactory.sol';

import './GQGalacticReserve.sol';

contract GQGalacticReserveFactory is 
    Initializable,
    OwnableUpgradeable, 
    IGQGalacticReserveFactory 
{
    
    using CountersUpgradeable for CountersUpgradeable.Counter;

    ///@notice Info of the GQ GalacticReserve Pools
    mapping(uint256 => mapping(address => PoolTypes.GQGalacticReserveType)) public pools;

    ///@notice Counter to get the identifier for the pools
    CountersUpgradeable.Counter private _poolIdCounter;

    // ============== VARIABLES ==============
    /// @notice Variable for knowing if contract has been initialized
    bool public initialized;

    // ============== MODIFIERS ==============
    /// @notice Will return true only when contract is initialized
    modifier isInitialized() {
        require(initialized, "Error: contract not initialized");
        _;
    }

    // ============== INITIALIZE ==============
    function initialize() external initializer {
        __Ownable_init();

        initialized = true;
    }

    /// @inheritdoc IGQGalacticReserveFactory
    function createPool(
        address stakedToken,
        address rewardToken,
        uint256 startBlock,
        uint256 endBlock,
        uint256 lockUpDuration,
        uint256 withdrawFee,
        address feeAddress
    ) external onlyOwner isInitialized override returns (address poolAddress) {
        // Check that the tokens are not the address(0)
        require(stakedToken != address(0), "Staked token can't be the address 0.");
        require(rewardToken != address(0), "Reward token can't be the address 0.");

        address factory = address(this);

        poolAddress = address(new GQGalacticReserve{salt: keccak256(abi.encode(stakedToken, rewardToken))}(
            factory,
            stakedToken,
            rewardToken,
            startBlock,
            endBlock,
            lockUpDuration,
            withdrawFee,
            feeAddress
        )); 

        uint256 poolId = _poolIdCounter.current();
        pools[poolId][poolAddress] = PoolTypes.GQGalacticReserveType(
            factory,
            stakedToken,
            rewardToken,
            startBlock,
            endBlock,
            lockUpDuration,
            withdrawFee,
            feeAddress
        );
        _poolIdCounter.increment();

        emit GalacticReservePoolCreated(factory, poolAddress, stakedToken, rewardToken, startBlock, endBlock, lockUpDuration, withdrawFee, feeAddress);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract GQStake is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Whether a limit is set for users
    bool public hasUserLimit;

    // Whether a limit is set for users
    bool public hasDepositMin;

    // Minimum token deposit
    uint256 public minimumDeposit;

    // Whether it is initialized
    bool public isInitialized;

    // Accrued token per share
    uint256 public accTokenPerShare;

    // The block number when REWARD distribution ends.
    uint256 public endBlock;

    // The block number when REWARD distribution starts.
    uint256 public startBlock;

    // The block number of the last pool update
    uint256 public lastUpdateBlock;

    // The pool limit (0 if none)
    uint256 public poolLimitPerUser;

    // REWARD tokens created per block.
    uint256 public rewardPerBlock;

    // max amount allowed to be transferred, 0 = no limit
    uint256 public rewardMaxTxAmount = 0;

    // decimals places of the reward token
    uint8 public rewardTokenDecimals;

    // Total staked by users
    uint256 public totalStaked;

    // The precision factor
    uint256 public PRECISION_FACTOR;

    // The precision factor
    uint256 public PRECISION_FACTOR_STAKED;

    // The reward token
    IERC20 public rewardToken;

    // The staked token
    IERC20 public stakedToken;

    // PUI
    // The factory address 
    address public factory;

    // Info of each user that stakes tokens (stakedToken)
    mapping(address => UserInfo) public userInfo;

    struct UserInfo {
        uint256 amount; // How many staked tokens the user has provided
        uint256 rewardDebt; // Reward debt
    }

    event AdminTokenRecovery(address tokenRecovered, uint256 amount);
    event Deposit(address indexed user, uint256 amount);
    event Claim(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);
    event NewStartAndEndBlocks(uint256 startBlock, uint256 endBlock);
    event NewRewardPerBlock(uint256 rewardPerBlock);
    event NewPoolLimit(uint256 poolLimitPerUser);
    event RewardsStop(uint256 blockNumber);
    event Withdraw(address indexed user, uint256 amount);

    /* TO-REVIEW AÑADIDO PUI
     * @notice Initialize the contract
     * @param _factory: Factory address     
     * @param _stakedToken: Staked token address
     * @param _rewardToken: Reward token address
     * @param _rewardPerBlock: Reward per block (in rewardToken)
     * @param _startBlock: Start block
     * @param _endBlock: End block
     * @param _poolLimitPerUser: Pool limit per user in stakedToken (if any, else 0)
     * @param _minimumDeposit: Minimum deposit allow on the pool  
     */
    constructor(
        address _factory,        
        address _stakedToken,
        address _rewardToken,
        uint256 _rewardPerBlock,
        uint256 _startBlock,
        uint256 _endBlock,
        uint256 _poolLimitPerUser,
        uint256 _minimumDeposit
    ) {
        require(!isInitialized, "Already initialized");
        isInitialized = true;

        factory = _factory;
        stakedToken = IERC20(_stakedToken);
        rewardToken = IERC20(_rewardToken);
        rewardPerBlock = _rewardPerBlock;
        startBlock = _startBlock;
        endBlock = _endBlock;

        if (poolLimitPerUser > 0) {
            hasUserLimit = true;
            poolLimitPerUser = _poolLimitPerUser; 
        }

        if (minimumDeposit > 0) {
            hasDepositMin = true;
            minimumDeposit = _minimumDeposit; 
        }

        rewardTokenDecimals = IERC20Metadata(address(rewardToken)).decimals();
        uint256 decimalsRewardToken = uint256(rewardTokenDecimals);
        require(decimalsRewardToken < 30, "Must be inferior to 30");

        PRECISION_FACTOR = uint256(10**(uint256(30).sub(decimalsRewardToken)));

        // Set the lastRewardBlock as the startBlock
        lastUpdateBlock = startBlock;
    }

    /*
     * @notice Initialize the contract
     * @param _stakedToken: staked token address
     * @param _rewardToken: reward token address
     * @param _rewardPerBlock: reward per block (in rewardToken)
     * @param _startBlock: start block
     * @param _endBlock: end block
     * @param _poolLimitPerUser: pool limit per user in stakedToken (if any, else 0)
     * @param _admin: admin address with ownership
     */
    function initialize(
        IERC20 _stakedToken,
        IERC20 _rewardToken,
        uint256 _rewardPerBlock,
        uint256 _startBlock,
        uint256 _endBlock,
        uint256 _poolLimitPerUser,
        uint256 _minimumDeposit
    ) external {
        require(!isInitialized, "Already initialized");
        isInitialized = true;

        stakedToken = _stakedToken;
        rewardToken = _rewardToken;
        rewardPerBlock = _rewardPerBlock;
        startBlock = _startBlock;
        endBlock = _endBlock;

        if (_poolLimitPerUser > 0) {
            hasUserLimit = true;
            poolLimitPerUser = _poolLimitPerUser;
        }

        if (_minimumDeposit > 0) {
            hasDepositMin = true;
            minimumDeposit = _minimumDeposit;
        }

        rewardTokenDecimals = IERC20Metadata(address(rewardToken)).decimals();
        uint256 decimalsRewardToken = uint256(rewardTokenDecimals);
        require(decimalsRewardToken < 30, "Must be inferior to 30");

        PRECISION_FACTOR = uint256(10**(uint256(30).sub(decimalsRewardToken)));

        // Set the lastRewardBlock as the startBlock
        lastUpdateBlock = startBlock;
    }

    /*
     * @notice Deposit staked tokens and collect reward tokens (if any)
     * @param _amount: amount to withdraw (in rewardToken)
     */
    function deposit(uint256 _amount) external nonReentrant {
        UserInfo storage user = userInfo[msg.sender];

        if (hasUserLimit) {
            require(
                _amount.add(user.amount) <= poolLimitPerUser,
                "User amount above limit"
            );
        }

        if (hasDepositMin) {
            require(
                _amount >= minimumDeposit,
                "Deposit amount not reach the minimum"
            );
        }

        _updatePool();

        if (user.amount > 0) {
            uint256 pending = user
                .amount
                .mul(accTokenPerShare)
                .div(PRECISION_FACTOR)
                .sub(user.rewardDebt);
            if (pending > 0) {
                sendPending(pending);
            }
        }

        if (_amount > 0) {
            user.amount = user.amount.add(_amount);
            stakedToken.safeTransferFrom(
                address(msg.sender),
                address(this),
                _amount
            );
            totalStaked = totalStaked.add(_amount);
        }

        user.rewardDebt = user.amount.mul(accTokenPerShare).div(
            PRECISION_FACTOR
        );

        emit Deposit(msg.sender, _amount);
    }

    /*
     * @notice Withdraw staked tokens and collect reward tokens
     * @param _amount: amount to withdraw (in rewardToken)
     */
    function withdraw(uint256 _amount) external nonReentrant {
        UserInfo storage user = userInfo[msg.sender];
        require(user.amount >= _amount, "Amount to withdraw too high");

        _updatePool();

        uint256 pending = user
            .amount
            .mul(accTokenPerShare)
            .div(PRECISION_FACTOR)
            .sub(user.rewardDebt);

        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            stakedToken.safeTransfer(address(msg.sender), _amount);
            totalStaked = totalStaked.sub(_amount);
        }

        if (pending > 0) {
            sendPending(pending);
        }

        user.rewardDebt = user.amount.mul(accTokenPerShare).div(
            PRECISION_FACTOR
        );

        emit Withdraw(msg.sender, _amount);
    }

    /*
     * @notice Claim reward tokens
     */
    function claim() external nonReentrant {
        UserInfo storage user = userInfo[msg.sender];

        _updatePool();

        if (user.amount > 0) {
            uint256 pending = user
                .amount
                .mul(accTokenPerShare)
                .div(PRECISION_FACTOR)
                .sub(user.rewardDebt);

            if (pending > 0) {
                sendPending(pending);
                emit Claim(msg.sender, pending);
            }
        }

        user.rewardDebt = user.amount.mul(accTokenPerShare).div(
            PRECISION_FACTOR
        );
    }

    /*
     * @notice SendPending tokens to claimer
     * @param pending: amount to claim
     */
    function sendPending(uint256 pending) internal {
        if (rewardMaxTxAmount == 0) {
            rewardToken.safeTransfer(address(msg.sender), pending);
        } else {
            while (pending > 0) {
                uint256 amount = pending > rewardMaxTxAmount
                    ? rewardMaxTxAmount
                    : pending;
                pending = pending.sub(amount);
                rewardToken.safeTransfer(address(msg.sender), amount);
            }
        }
    }

    /*
     * @notice Withdraw staked tokens without caring about rewards
     * @dev Needs to be for emergency.
     */
    function emergencyWithdraw() external nonReentrant {
        UserInfo storage user = userInfo[msg.sender];
        uint256 amountToTransfer = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;

        if (amountToTransfer > 0) {
            stakedToken.safeTransfer(address(msg.sender), amountToTransfer);
            totalStaked = totalStaked.sub(amountToTransfer);
        }

        emit EmergencyWithdraw(msg.sender, user.amount);
    }

    /**
     * @notice It allows the admin to recover wrong tokens sent to the contract
     * @param _tokenAddress: the address of the token to withdraw
     * @param _tokenAmount: the number of tokens to withdraw
     * @dev This function is only callable by admin.
     */
    function recoverWrongTokens(address _tokenAddress, uint256 _tokenAmount)
        external
        onlyOwner
    {
        require(
            _tokenAddress != address(stakedToken),
            "Cannot be staked token"
        );
        require(
            _tokenAddress != address(rewardToken),
            "Cannot be reward token"
        );

        IERC20(_tokenAddress).safeTransfer(address(msg.sender), _tokenAmount);

        emit AdminTokenRecovery(_tokenAddress, _tokenAmount);
    }

    /*
     * @notice Stop rewards
     * @dev Only callable by owner
     */
    function stopReward() external onlyOwner {
        endBlock = block.number;
    }

    /*
     * @notice Update pool limit per user
     * @dev Only callable by owner.
     * @param _hasUserLimit: whether the limit remains forced
     * @param _poolLimitPerUser: new pool limit per user
     */
    function updatePoolLimitPerUser(
        bool _hasUserLimit,
        uint256 _poolLimitPerUser
    ) external onlyOwner {
        require(hasUserLimit, "Must be set");
        if (_hasUserLimit) {
            require(
                _poolLimitPerUser > poolLimitPerUser,
                "New limit must be higher"
            );
            poolLimitPerUser = _poolLimitPerUser;
        } else {
            hasUserLimit = _hasUserLimit;
            poolLimitPerUser = 0;
        }
        emit NewPoolLimit(poolLimitPerUser);
    }

    /*
     * @notice Update reward per block
     * @dev Only callable by owner.
     * @param _rewardPerBlock: the reward per block
     */
    function updateRewardPerBlock(uint256 _rewardPerBlock) external onlyOwner {
        require(block.number < startBlock, "Pool has started");
        rewardPerBlock = _rewardPerBlock;
        emit NewRewardPerBlock(_rewardPerBlock);
    }

    /**
     * @notice It allows the admin to update start and end blocks
     * @dev This function is only callable by owner.
     * @param _startBlock: the new start block
     * @param _bonusEndBlock: the new end block
     */
    function updateStartAndEndBlocks(
        uint256 _startBlock,
        uint256 _bonusEndBlock
    ) external onlyOwner {
        require(block.number < startBlock, "Pool has started");
        require(
            _startBlock < _bonusEndBlock,
            "New startBlock must be lower than new endBlock"
        );
        require(
            block.number < _startBlock,
            "New startBlock must be higher than current block"
        );

        startBlock = _startBlock;
        endBlock = _bonusEndBlock;

        // Set the lastRewardBlock as the startBlock
        lastUpdateBlock = startBlock;

        emit NewStartAndEndBlocks(_startBlock, _bonusEndBlock);
    }

    /*
     * @notice View function to see pending reward on frontend.
     * @param _user: user address
     * @return Pending reward for a given user
     */
    function pendingReward(address _user) external view returns (uint256) {
        UserInfo storage user = userInfo[_user];
        uint256 stakedTokenSupply = totalStaked;
        if (block.number > lastUpdateBlock && stakedTokenSupply != 0) {
            uint256 multiplier = _getMultiplier(lastUpdateBlock, block.number);
            uint256 tokenReward = multiplier.mul(rewardPerBlock);
            uint256 adjustedTokenPerShare = accTokenPerShare.add(
                tokenReward.mul(PRECISION_FACTOR).div(stakedTokenSupply)
            );
            return
                user
                    .amount
                    .mul(adjustedTokenPerShare)
                    .div(PRECISION_FACTOR)
                    .sub(user.rewardDebt);
        } else {
            return
                user.amount.mul(accTokenPerShare).div(PRECISION_FACTOR).sub(
                    user.rewardDebt
                );
        }
    }

    /*
     * @notice Update reward variables of the given pool to be up-to-date.
     */
    function _updatePool() internal {
        if (block.number <= lastUpdateBlock) {
            return;
        }

        uint256 stakedTokenSupply = totalStaked;
        if (stakedTokenSupply == 0) {
            lastUpdateBlock = block.number;
            return;
        }

        uint256 multiplier = _getMultiplier(lastUpdateBlock, block.number);
        uint256 tokenReward = multiplier.mul(rewardPerBlock);
        accTokenPerShare = accTokenPerShare.add(
            tokenReward.mul(PRECISION_FACTOR).div(stakedTokenSupply)
        );
        lastUpdateBlock = block.number;
    }

    /*
     * @notice Return reward multiplier over the given _from to _to block.
     * @param _from: block to start
     * @param _to: block to finish
     * @return multiplier
     */
    function _getMultiplier(uint256 _from, uint256 _to)
        internal
        view
        returns (uint256)
    {
        if (_to <= endBlock) {
            return _to.sub(_from);
        } else if (_from >= endBlock) {
            return 0;
        } else {
            return endBlock.sub(_from);
        }
    }

    /*
     * @notice Sets the minimum amount to deposit
     * @param _minimumDeposit: Minimum amount to deposit
     * @dev This function is only callable by owner.
     */
    function setMinimumDeposit(uint256 _minimumDeposit) public onlyOwner {
        minimumDeposit = _minimumDeposit;
    }

    /*
     * @notice Sets start block of the pool given a block amount
     * @param _blocks: block amount
     * @dev This function is only callable by owner.
     */
    function poolStartIn(uint256 _blocks) public onlyOwner {
        poolSetStart(block.number.add(_blocks));
    }

    /*
     * @notice Sets start block of the pool
     * @param _startBlock: start block
     * @dev This function is only callable by owner.
     */
    function poolSetStart(uint256 _startBlock) public onlyOwner {
        require(block.number < startBlock, "Pool has started");
        uint256 rewardDurationValue = rewardDuration();
        startBlock = _startBlock;
        endBlock = startBlock.add(rewardDurationValue);
        lastUpdateBlock = startBlock;
    }

    /*
     * @notice Set the duration of the pool
     * @param _durationBlocks: duration block amount
     * @dev This function is only callable by owner.
     */
    function poolSetDuration(uint256 _durationBlocks) public onlyOwner {
        require(block.number < startBlock, "Pool has started");
        endBlock = startBlock.add(_durationBlocks);
        poolCalcRewardPerBlock();
    }

    /*
     * @notice Set the duration and start block of the pool
     * @param _startBlock: start block
     * @param _durationBlocks: duration block amount
     * @dev This function is only callable by owner.
     */
    function poolSetStartAndDuration(
        uint256 _startBlock,
        uint256 _durationBlocks
    ) public onlyOwner {
        poolSetStart(_startBlock);
        poolSetDuration(_durationBlocks);
    }

    /*
     * @notice Calculates the rewardPerBlock of the pool
     * @dev This function is only callable by owner.
     */
    function poolCalcRewardPerBlock() public onlyOwner {
        uint256 rewardBal = rewardToken.balanceOf(address(this)).sub(
            totalStaked
        );
        rewardPerBlock = rewardBal.div(rewardDuration());
    }

    /*
     * @notice Sets the max reward amount for a TX
     * @param _maxTxAmount: max TX amount
     * @dev This function is only callable by owner.
     */
    function poolSetRewardMaxTxAmount(uint256 _maxTxAmount) public onlyOwner {
        rewardMaxTxAmount = _maxTxAmount;
    }

    /*
     * @notice Gets the reward duration
     * @return reward duration
     */
    function rewardDuration() public view returns (uint256) {
        return endBlock.sub(startBlock);
    }

    /*
     * @notice Gets the reward per block for UI
     * @return reward per block
     */
    function rewardPerBlockUI() public view returns (uint256) {
        return rewardPerBlock.div(10**uint256(rewardTokenDecimals));
    }

    /*
     * @notice Withdraws the remaining funds
     * @param _to The address where the funds will be sent
     */
    function withdrawRemains(address _to) public onlyOwner {
        require(block.number > endBlock, "Error: Pool not finished yet");
        require(totalStaked == 0, "Error: Someone has staked tokens");
        uint256 tokenBal = rewardToken.balanceOf(address(this));
        require(tokenBal > 0, "Error: No remaining funds");
        IERC20(rewardToken).safeTransfer(_to, tokenBal);
    }

    /*
     * @notice Deposit funds for reward
     * @param _to The address where the funds will be sent
     */
    function depositRewardFunds(uint256 _amount) public onlyOwner {
        IERC20(rewardToken).safeTransfer(address(this), _amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";

import './interfaces/IGQStakeFactory.sol';

import './GQStake.sol';

contract GQStakeFactory is     
    Initializable,
    OwnableUpgradeable, 
    IGQStakeFactory 
{
    
    using CountersUpgradeable for CountersUpgradeable.Counter;

    ///@notice Info of the GQ Stake Pools
    mapping(uint256 => mapping(address => PoolTypes.GQStakeType)) public pools;

    ///@notice Counter to get the identifier for the pools
    CountersUpgradeable.Counter private _poolIdCounter;

    // ============== VARIABLES ==============
    /// @notice Variable for knowing if contract has been initialized
    bool public initialized;

    // ============== MODIFIERS ==============
    /// @notice Will return true only when contract is initialized
    modifier isInitialized() {
        require(initialized, "Error: contract not initialized");
        _;
    }

    // ============== INITIALIZE ==============
    function initialize() external initializer {
        __Ownable_init();

        initialized = true;
    }

    /// @inheritdoc IGQStakeFactory
    function createPool(
        address stakedToken,
        address rewardToken,
        uint256 rewardPerBlock,
        uint256 startBlock,
        uint256 endBlock,
        uint256 poolLimitPerUser,
        uint256 minimumDeposit
    ) external onlyOwner isInitialized override returns (address poolAddress) {
        // Check that the tokens are not the address(0)
        require(stakedToken != address(0), "Staked token can't be the address 0.");
        require(rewardToken != address(0), "Reward token can't be the address 0.");

        address factory = address(this);

        poolAddress = address(new GQStake{salt: keccak256(abi.encode(stakedToken, rewardToken))}(
            factory,
            stakedToken,
            rewardToken,
            rewardPerBlock,
            startBlock,
            endBlock,
            poolLimitPerUser,
            minimumDeposit
        ));

        uint256 poolId = _poolIdCounter.current();
        pools[poolId][poolAddress] = PoolTypes.GQStakeType(
            factory,
            stakedToken,
            rewardToken,
            rewardPerBlock,
            startBlock,
            endBlock,
            poolLimitPerUser,
            minimumDeposit
        );
        _poolIdCounter.increment();

        emit StakePoolCreated(factory, poolAddress, stakedToken, rewardToken, rewardPerBlock, startBlock, endBlock, poolLimitPerUser, minimumDeposit);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @title The interface for the Outer Ring pools
/// @notice This factory facilitates creation of the different pools available in Outer Ring
interface IGQBaseFactory {

    /// @notice Event emitted when a stake pool is created
    /// @param factory: The address of the factory that deployed the pool
    /// @param pool: The address of the created pool
    /// @param stakedToken: Staked token address
    /// @param rewardToken: Reward token address
    /// @param rewardPerBlock: Reward per block (in rewardToken)
    /// @param startBlock: Start block
    /// @param endBlock: End block
    /// @param poolLimitPerUser: Pool limit per user in stakedToken (if any, else 0)
    /// @param minimumDeposit: Minimum deposit allow on the pool
    event StakePoolCreated (
        address factory,
        address indexed pool,
        address indexed stakedToken,
        address rewardToken,
        uint256 rewardPerBlock,
        uint256 startBlock,
        uint256 endBlock,
        uint256 poolLimitPerUser,
        uint256 minimumDeposit
    );

    /// @notice Event emitted when a galactic reserve pool is created
    /// @param factory: The address of the factory that deployed the pool    
    /// @param pool: The address of the created pool    
    /// @param stakedToken: Staked token address
    /// @param rewardToken: Reward token address
    /// @param startBlock: Start block
    /// @param endBlock: End block
    /// @param lockUpDuration: Duration for the deposit
    /// @param withdrawFee: Fee for early withdraw
    /// @param feeAddress: Address where fees for early withdraw will be send
    event GalacticReservePoolCreated (
        address factory,        
        address indexed pool,        
        address indexed stakedToken,
        address rewardToken,
        uint256 startBlock,
        uint256 endBlock,
        uint256 lockUpDuration,
        uint256 withdrawFee,
        address feeAddress
    );

    /// @notice Event emitted when a galactic reserve pool is created
    /// @param factory: The address of the factory that deployed the pool    
    /// @param pool: The address of the created pool    
    /// @param stakedToken: Staked token address
    /// @param rewardToken1: Reward token1 address
    /// @param rewardToken2: Reward token2 address
    /// @param startBlock: Start block
    /// @param endBlock: End block
    /// @param lockUpDuration: Duration for the deposit
    /// @param withdrawFee: Fee for early withdraw
    /// @param feeAddress: Address where fees for early withdraw will be send
    event GalacticAlliancePoolCreated (
        address factory,        
        address indexed pool,        
        address indexed stakedToken,
        address rewardToken1,
        address rewardToken2,
        uint256 startBlock,
        uint256 endBlock,
        uint256 lockUpDuration,
        uint256 withdrawFee,
        address feeAddress
    );

    /// @notice Function that creates a stake pool for the given two tokens and fee
    /// @param stakedToken: Staked token address
    /// @param rewardToken: Reward token address
    /// @param rewardPerBlock: Reward per block (in rewardToken)
    /// @param startBlock: Start block
    /// @param endBlock: End block
    /// @param poolLimitPerUser: Pool limit per user in stakedToken (if any, else 0)
    /// @param minimumDeposit: Minimum deposit allow on the pool    
    /// @dev The call will revert if the token arguments are invalid.    
    /// @return poolAddress The address of the newly created pool
    function createStakePool(
        address stakedToken,
        address rewardToken,
        uint256 rewardPerBlock,
        uint256 startBlock,
        uint256 endBlock,
        uint256 poolLimitPerUser,
        uint256 minimumDeposit
    ) external returns (address poolAddress);

    /// @notice Function that creates a galactic reserve pool for the given two tokens and fee
    /// @param stakedToken: Staked token address
    /// @param rewardToken: Reward token address
    /// @param startBlock: Start block
    /// @param endBlock: End block
    /// @param lockUpDuration: Duration for the deposit
    /// @param withdrawFee: Fee for early withdraw
    /// @param feeAddress: Address where fees for early withdraw will be send    
    /// @dev The call will revert if the fee is invalid or the token arguments are invalid.    
    /// @return poolAddress The address of the newly created pool
    function createGalacticReservePool(
        address stakedToken,
        address rewardToken,
        uint256 startBlock,
        uint256 endBlock,
        uint256 lockUpDuration,
        uint256 withdrawFee,
        address feeAddress
    ) external returns (address poolAddress);

    /// @notice Function that creates a galactic alliance pool for the given two tokens and fee
    /// @param stakedToken: Staked token address
    /// @param rewardToken1: Reward token1 address
    /// @param rewardToken2: Reward token2 address
    /// @param startBlock: Start block
    /// @param endBlock: End block
    /// @param lockUpDuration: Duration for the deposit
    /// @param withdrawFee: Fee for early withdraw
    /// @param feeAddress: Address where fees for early withdraw will be send    
    /// @dev The call will revert if the fee is invalid or the token arguments are invalid.    
    /// @return poolAddress The address of the newly created pool
    function createGalacticAlliancePool(
        address stakedToken,
        address rewardToken1,
        address rewardToken2,
        uint256 startBlock,
        uint256 endBlock,
        uint256 lockUpDuration,
        uint256 withdrawFee,
        address feeAddress
    ) external returns (address poolAddress);

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import '../libraries/PoolTypes.sol';

/// @title The interface for the Outer Ring Galactic Alliance pools
/// @notice This factory facilitates creation of the galactic alliance pools available in Outer Ring
interface IGQGalacticAllianceFactory {

    /// @notice Event emitted when a galactic alliance pool is created
    /// @param factory: The address of the factory that deployed the pool    
    /// @param pool: The address of the created pool    
    /// @param stakedToken: Staked token address
    /// @param rewardToken1: Reward token1 address
    /// @param rewardToken2: Reward token2 address
    /// @param startBlock: Start block
    /// @param endBlock: End block
    /// @param lockUpDuration: Duration for the deposit
    /// @param withdrawFee: Fee for early withdraw
    /// @param feeAddress: Address where fees for early withdraw will be send
    event GalacticAlliancePoolCreated (
        address factory,        
        address indexed pool,        
        address indexed stakedToken,
        address rewardToken1,
        address rewardToken2,
        uint256 startBlock,
        uint256 endBlock,
        uint256 lockUpDuration,
        uint256 withdrawFee,
        address feeAddress
    );

    /// @notice Function that creates a galactic alliance pool for the given two tokens and fee
    /// @param stakedToken: Staked token address
    /// @param rewardToken1: Reward token1 address
    /// @param rewardToken2: Reward token2 address
    /// @param startBlock: Start block
    /// @param endBlock: End block
    /// @param lockUpDuration: Duration for the deposit
    /// @param withdrawFee: Fee for early withdraw
    /// @param feeAddress: Address where fees for early withdraw will be send    
    /// @dev The call will revert if the fee is invalid or the token arguments are invalid.    
    /// @return poolAddress The address of the newly created pool
    function createPool(
        address stakedToken,
        address rewardToken1,
        address rewardToken2,
        uint256 startBlock,
        uint256 endBlock,
        uint256 lockUpDuration,
        uint256 withdrawFee,
        address feeAddress
    ) external returns (address poolAddress);

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import '../libraries/PoolTypes.sol';

/// @title The interface for the Outer Ring Galactic Reserve pools
/// @notice This factory facilitates creation of the galactic reserve pools available in Outer Ring
interface IGQGalacticReserveFactory {

    /// @notice Event emitted when a galactic reserve pool is created
    /// @param factory: The address of the factory that deployed the pool    
    /// @param pool: The address of the created pool    
    /// @param stakedToken: Staked token address
    /// @param rewardToken: Reward token address
    /// @param startBlock: Start block
    /// @param endBlock: End block
    /// @param lockUpDuration: Duration for the deposit
    /// @param withdrawFee: Fee for early withdraw
    /// @param feeAddress: Address where fees for early withdraw will be send
    event GalacticReservePoolCreated (
        address factory,        
        address indexed pool,        
        address indexed stakedToken,
        address rewardToken,
        uint256 startBlock,
        uint256 endBlock,
        uint256 lockUpDuration,
        uint256 withdrawFee,
        address feeAddress
    );

    /// @notice Function that creates a galactic reserve pool for the given two tokens and fee
    /// @param stakedToken: Staked token address
    /// @param rewardToken: Reward token address
    /// @param startBlock: Start block
    /// @param endBlock: End block
    /// @param lockUpDuration: Duration for the deposit
    /// @param withdrawFee: Fee for early withdraw
    /// @param feeAddress: Address where fees for early withdraw will be send    
    /// @dev The call will revert if the fee is invalid or the token arguments are invalid.    
    /// @return poolAddress The address of the newly created pool
    function createPool(
        address stakedToken,
        address rewardToken,
        uint256 startBlock,
        uint256 endBlock,
        uint256 lockUpDuration,
        uint256 withdrawFee,
        address feeAddress
    ) external returns (address poolAddress);

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import '../libraries/PoolTypes.sol';

/// @title The interface for the Outer Ring Stake pools
/// @notice This factory facilitates creation of the stake pools available in Outer Ring
interface IGQStakeFactory {

    /// @notice Event emitted when a stake pool is created
    /// @param factory: The address of the factory that deployed the pool
    /// @param pool: The address of the created pool
    /// @param stakedToken: Staked token address
    /// @param rewardToken: Reward token address
    /// @param rewardPerBlock: Reward per block (in rewardToken)
    /// @param startBlock: Start block
    /// @param endBlock: End block
    /// @param poolLimitPerUser: Pool limit per user in stakedToken (if any, else 0)
    /// @param minimumDeposit: Minimum deposit allow on the pool
    event StakePoolCreated (
        address factory,
        address indexed pool,
        address indexed stakedToken,
        address rewardToken,
        uint256 rewardPerBlock,
        uint256 startBlock,
        uint256 endBlock,
        uint256 poolLimitPerUser,
        uint256 minimumDeposit
    );

    /// @notice Function that creates a stake pool for the given two tokens and fee
    /// @param stakedToken: Staked token address
    /// @param rewardToken: Reward token address
    /// @param rewardPerBlock: Reward per block (in rewardToken)
    /// @param startBlock: Start block
    /// @param endBlock: End block
    /// @param poolLimitPerUser: Pool limit per user in stakedToken (if any, else 0)
    /// @param minimumDeposit: Minimum deposit allow on the pool    
    /// @dev The call will revert if the token arguments are invalid.    
    /// @return poolAddress The address of the newly created pool
    function createPool(
        address stakedToken,
        address rewardToken,
        uint256 rewardPerBlock,
        uint256 startBlock,
        uint256 endBlock,
        uint256 poolLimitPerUser,
        uint256 minimumDeposit
    ) external returns (address poolAddress);

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @title PoolTypes
/// @notice This library contains the available pool types for Outer Ring. 
library PoolTypes {
    
    /// @notice Struct to store the data for the GQStake pools
    struct GQStakeType {
        // Factory address
        address factory;
        // Staked token address (IERC20)
        address stakedToken;
        // Reward token address (IERC20)
        address rewardToken;
        // Reward per block (in rewardToken)
        uint256 rewardPerBlock;
        // Start block
        uint256 startBlock;
        // End block
        uint256 endBlock;
        // Pool limit per user in stakedToken (if any, else 0)
        uint256 poolLimitPerUser;
        // Minimum deposit allowed in the pool
        uint256 minimumDeposit;
    }

    /// @notice Struct to store the data for the GQGalacticReserve pools
    struct GQGalacticReserveType {
        // Factory address
        address factory;        
        // Staked token address (IERC20)
        address stakedToken;
        // Reward token address (IERC20)
        address rewardToken;
        // Start block
        uint256 startBlock;
        // End block
        uint256 endBlock;
        // Duration for the deposit
        uint256 lockUpDuration;
        // Fee for early withdraw         
        uint256 withdrawFee;
        // Address where fees for early withdraw will be send        
        address feeAddress;        
    }

    /// @notice Struct to store the data for the GQGalacticAlliance pools
    struct GQGalacticAllianceType {
        // Factory address
        address factory;        
        // Staked token address (IERC20Upgradeable)
        address stakedToken;
        // Reward token1 address
        address rewardToken1;
        // Reward token2 address
        address rewardToken2;        
        // Start block
        uint256 startBlock;
        // End block
        uint256 endBlock;
        // Duration for the deposit
        uint256 lockUpDuration;
        // Fee for early withdraw         
        uint256 withdrawFee;
        // Address where fees for early withdraw will be send        
        address feeAddress;
    }
}