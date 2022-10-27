/**
 *Submitted for verification at Etherscan.io on 2022-10-27
*/

// Sources flattened with hardhat v2.11.1 https://hardhat.org

// File @openzeppelin/contracts-upgradeable/utils/[email protected]


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


// File @openzeppelin/contracts-upgradeable/proxy/utils/[email protected]


// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

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


// File @openzeppelin/contracts-upgradeable/utils/[email protected]


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


// File @openzeppelin/contracts-upgradeable/access/[email protected]


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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




// File @openzeppelin/contracts-upgradeable/security/[email protected]


// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;


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


// File @openzeppelin/contracts-upgradeable/utils/math/[email protected]


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


// File @openzeppelin/contracts-upgradeable/token/ERC20/[email protected]


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


// File contracts/ICO.sol

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

contract AnalogInceptive is OwnableUpgradeable, PausableUpgradeable {
    using SafeMathUpgradeable for uint256;

    struct Phase {
        string name;
        uint256 startBlock;
        uint256 endBlock;
        uint256 HCAmount;
        uint256 basePrice;
        uint256 totalTokenRealesed;
        Order[] pendingQueqe;
        uint256 queqeIndex;
    }

    struct Order {
        address user;
        uint256 amount;
        uint256 pendingAmount;
    }

    struct User {
        address user;
        uint256 userId;
        address refferal;
        uint256 affiliateIncome;
        mapping(uint8 => PhaseInfo) phaseinfo;
        Deposit[] deposits;
        uint256 withdraw;
        uint256 totalBuy;
        uint256 checkpoint;
    }

    struct Deposit{
        uint256 amount;
        uint256 timestamp;
        uint256 price;
        uint8 phaseId;
    }

    struct PhaseInfo {
        uint256 totalBuyHold;
        uint256 forSellHolding;
        uint256 ttlBuyINRx;
        uint256 ttlSellINRx;
        uint256 ttlSell;
        uint256 ttlBuy;
    }

    mapping(uint8 => Phase) public phases;
    uint8[3] private affiliateShares;
    uint256 private PERCENT_DIVIDER;
    mapping(address => User) private users;
    IERC20Upgradeable public inrXToken;
    uint256 public MINIMUM_BUY;
    uint256 public BLOCKS_PER_DAY;
    uint256 public lastUserId;
    uint256 public FOR_DISCOUNT_SALE_MINIMUM_BUY;
    uint256 public FOR_DISCOUNT_SALE_TOTAL_DIST;
    uint256 private TIME_STEP;
    uint256 private LOCKING_PERIOD;
    mapping(uint256 => address) private idToAddress;

    event Registration(
        uint256 userId,
        address indexed user,
        address indexed refferal
    );

    event Buy(
        uint8 phaseId,
        uint256 price,
        address user,
        uint256 anaAmount,
        uint256 inrxAmount
    );

    event PendingOrder(uint8 phaseId, address user, uint256 amount);

    event partiallyExecuted(
        uint8 phaseId,
        address from,
        address to,
        uint256 amount,
        uint256 price
    );

    event CompletedOrder(
        uint8 phaseId,
        address from,
        address to,
        uint256 amount,
        uint256 price
    );

    event AffiliateIncome(
        address reciever,
        address sender,
        uint256 amount,
        uint8 level
    );

    event DiscountApply(
        uint8 phaseId,
        address user,
        uint256 amount,
        uint256 price,
        uint256 priceWithoutDiscount
    );

    event Withdraw(address user, uint256 roiAmount,uint256 buyedBackAmount,uint256 totalAmount);

    function initialize(IERC20Upgradeable _inrX) external initializer {
        inrXToken = _inrX;

        phases[1].name = "Gensis";
        phases[1].HCAmount = 30000 * 1e18;
        phases[1].basePrice = 1 * 1e18;

        phases[2].name = "Escaled";
        phases[2].HCAmount = 40000 * 1e18;
        phases[2].basePrice = 2 * 1e18;

        phases[3].name = "Revolt";
        phases[3].HCAmount = 50000 * 1e18;
        phases[3].basePrice = 4 * 1e18;

        phases[4].name = "Momentum";
        phases[4].HCAmount = 30000* 1e18;
        phases[4].basePrice = 8 * 1e18;

        phases[5].name = "Markle";
        phases[5].HCAmount = 40000 * 1e18;
        phases[5].basePrice = 16 * 1e18;

        phases[6].name = "Exos";
        phases[6].HCAmount = 50000 * 1e18;
        phases[6].basePrice = 32 * 1e18;

        phases[7].name = "Integration";
        phases[7].HCAmount = 60000 * 1e18;
        phases[7].basePrice = 64 * 1e18;
        
        uint256 addi;
        for(uint8 i=1; i< 8; i++) {
            phases[i].startBlock = block.number.add(addi.add(1));
            phases[i].endBlock = block.number.add(addi.add(300));
            addi=addi.add(300);
        }

        FOR_DISCOUNT_SALE_TOTAL_DIST = 15000 * 1e18;
        FOR_DISCOUNT_SALE_MINIMUM_BUY = 10000 * 1e18;
        affiliateShares = [7, 2, 1];
        PERCENT_DIVIDER = 100;
        MINIMUM_BUY = 500 * 1e18;
        lastUserId = 1;
        BLOCKS_PER_DAY = 17280;
        TIME_STEP= 60;//30 days
        LOCKING_PERIOD=300;
        __Ownable_init();
        users[_msgSender()].user = _msgSender();
        users[_msgSender()].refferal = address(0);
        users[_msgSender()].userId = lastUserId;
        idToAddress[lastUserId] = _msgSender();
        lastUserId++;
    }

    function registration(address user, address _refferal) internal {
        require(!isUserExist(_msgSender()), "ICO:: user already exist!");
        require(isUserExist(_refferal), "ICO:: refferal not already exist!");
        users[user].user = user;
        idToAddress[lastUserId] = user;
        users[user].userId = lastUserId;
        users[user].refferal = _refferal;
        lastUserId++;
        emit Registration(users[user].userId, user, _refferal);
    }

    function _buy(uint256 _amount)  internal  {
        uint8 phaseId = getCurrentPhase();
        require(phaseId != 0, "ICO:: not Started");
        uint256 crntPrice = currentPrice(phaseId);
        uint256 _inrxAmount = calculateINRxAmount(_msgSender(),_amount,crntPrice, phaseId);
        require(
            MINIMUM_BUY <= _inrxAmount,
            "ICO:: minimum buy amount 500 INRx"
        );
        require(
            phases[phaseId].totalTokenRealesed.add(_amount) <=
                phases[phaseId].HCAmount,
            "ICO:: phase Ana sold out!"
        );
        require(
            inrXToken.allowance(_msgSender(), address(this)) >= _inrxAmount,
            "ICO:: allowance Exceed!"
        );
        require(
            inrXToken.balanceOf(_msgSender()) >= _inrxAmount,
            "ICO:: balance Low!"
        );
        uint256 tempAmount = _amount;
        inrXToken.transferFrom(_msgSender(), address(this), _inrxAmount);
        uint256 __amount = excutePendingOrder(
            _msgSender(),
            _amount,
            phaseId,
            crntPrice
        );

        phases[phaseId].totalTokenRealesed = phases[phaseId]
            .totalTokenRealesed
            .add(__amount);

        for (uint8 i = phaseId + 1; i < 8; i++) {
            users[_msgSender()].phaseinfo[i].forSellHolding = users[
                _msgSender()
            ].phaseinfo[i].forSellHolding.add(_amount.mul(1).div(100));
            phases[i].pendingQueqe.push(
                Order(_msgSender(), _amount.mul(1).div(100),_amount.mul(1).div(100))
            );
            tempAmount = tempAmount.sub(tempAmount.mul(1).div(100));
            emit PendingOrder(i, _msgSender(), _amount.mul(1).div(100));
        }

        users[_msgSender()].phaseinfo[phaseId].ttlBuy = users[_msgSender()]
            .phaseinfo[phaseId]
            .ttlBuy
            .add(_amount);
        users[_msgSender()].phaseinfo[phaseId].totalBuyHold = users[
            _msgSender()
        ].phaseinfo[phaseId].totalBuyHold.add(tempAmount);
        users[_msgSender()].phaseinfo[phaseId].ttlBuyINRx = users[
            _msgSender()
        ].phaseinfo[phaseId].ttlBuyINRx.add(_inrxAmount);
        users[_msgSender()].deposits.push(Deposit(tempAmount,block.timestamp,crntPrice,phaseId));
        users[_msgSender()].totalBuy=users[_msgSender()].totalBuy.add(_amount);
        sendAffiliateIncome(_msgSender(), _inrxAmount);

        emit Buy(phaseId, crntPrice, _msgSender(), _amount, _inrxAmount);
    }

    function buyWithRefferal(address _refferal, uint256 _amount)
        external
        whenNotPaused
        returns (bool)
    {
        registration(_msgSender(), _refferal);
        _buy(_amount);
        return true;
    }

    function buy(uint256 _amount) external whenNotPaused returns (bool) {
        require(isUserExist(_msgSender()), "ICO:: user not exist !");
        _buy(_amount);
        return true;
    }

    function sendAffiliateIncome(address user, uint256 _amount) internal {
        address refferal = user;
        for (uint8 i = 0; i < 3; i++) {
            refferal = users[refferal].refferal;
            if (refferal != address(0)) {
                uint8 sharePerc = affiliateShares[i];
                uint256 share = _amount.mul(sharePerc).div(PERCENT_DIVIDER);
                users[refferal].affiliateIncome = users[refferal]
                    .affiliateIncome
                    .add(share);
                inrXToken.transfer(refferal, share);
                emit AffiliateIncome(refferal, user, share, i + 1);
            } else {
                break;
            }
        }
    }

    function getCurrentPhase() public view returns (uint8 phaseId) {
        uint blockNumber = block.number;
        for (uint8 i = 1; i <= 7; i++) {
            if (
                phases[i].startBlock <= blockNumber &&
                phases[i].endBlock >= blockNumber
            ) {
                phaseId = i;
            }
        }
    }

    function currentPrice(uint8 phaseId) public view returns (uint256) {
        uint256 percentSell = getSellPercent(phaseId);
        return
            phases[phaseId].basePrice.add(
                (phases[phaseId].basePrice).mul(percentSell).div(100).div(1e18)
            );
    }

    function getSellPercent(uint8 phaseId) public view returns (uint256) {
        uint256 ttlTokenRealsed = phases[phaseId].totalTokenRealesed;
        uint256 percentSell;
        if (ttlTokenRealsed != 0)
            percentSell = ttlTokenRealsed.mul(100).mul(1e18).div(
                phases[phaseId].HCAmount
            );
        return percentSell;
    }

    function updateStartOrEndBlock(
        uint8 phaseId,
        uint256 _newStartBlock,
        uint256 _newEndBlock
    ) external onlyOwner returns (bool) {
        require(phases[phaseId].HCAmount != 0, "invalid phaseId");
        phases[phaseId].startBlock = _newStartBlock;
        phases[phaseId].endBlock = _newEndBlock;
        return true;
    }

    function getUserPhaseInfo(address _user, uint8 phaseID)
        external
        view
        returns (PhaseInfo memory)
    {
        return users[_user].phaseinfo[phaseID];
    }

    function getUserDeposit(address user) external view returns (Deposit[] memory) {
        return users[user].deposits;
    }

    function getPhasePendingOrders(uint8 phaseId)
        external
        view
        returns (Order[] memory)
    {
        return phases[phaseId].pendingQueqe;
    }

    function getPhasePendingOrdersByIndex(uint8 phaseId, uint256 index)
        external
        view
        returns (Order memory)
    {
        return phases[phaseId].pendingQueqe[index];
    }

    function excutePendingOrder(
        address user,
        uint256 _amount,
        uint8 phaseId,
        uint256 price
    ) internal returns (uint256) {
        for (
            uint256 i = phases[phaseId].queqeIndex;
            i < phases[phaseId].pendingQueqe.length;
            i++
        ) {
            if (phases[phaseId].pendingQueqe[i].pendingAmount > _amount) {
                phases[phaseId].pendingQueqe[i].pendingAmount = phases[phaseId]
                    .pendingQueqe[i]
                    .pendingAmount
                    .sub(_amount);
                inrXToken.transfer(
                    phases[phaseId].pendingQueqe[i].user,
                    _amount.mul(price).div(1e18)
                );

            users[phases[phaseId].pendingQueqe[i].user].phaseinfo[phaseId].ttlSell = users[phases[phaseId].pendingQueqe[i].user]
            .phaseinfo[phaseId]
            .ttlSell
            .add(_amount);

                emit partiallyExecuted(
                    phaseId,
                    phases[phaseId].pendingQueqe[i].user,
                    user,
                    _amount,
                    price
                );
                _amount = 0;
                break;
            } else {
                _amount = _amount.sub(
                    phases[phaseId].pendingQueqe[i].pendingAmount
                );
                inrXToken.transfer(
                    phases[phaseId].pendingQueqe[i].user,
                    phases[phaseId].pendingQueqe[i].pendingAmount.mul(price).div(1e18)
                );
            users[phases[phaseId].pendingQueqe[i].user].phaseinfo[phaseId].ttlSell = users[phases[phaseId].pendingQueqe[i].user]
            .phaseinfo[phaseId]
            .ttlSell
            .add(phases[phaseId].pendingQueqe[i].pendingAmount);
                phases[phaseId].pendingQueqe[i].pendingAmount = 0;
                phases[phaseId].queqeIndex = i+1;
                emit CompletedOrder(
                    phaseId,
                    phases[phaseId].pendingQueqe[i].user,
                    user,
                    _amount,
                    price
                );
                if(_amount==0) break;
            }


        }
        return _amount;
    }

    function isUserExist(address user) public view returns (bool) {
        return users[user].userId != 0;
    }

    function calculateINRxAmount(address user,uint256 _anaAmount,uint256 price,uint8 phaseId) internal returns (uint256) {
        if(FOR_DISCOUNT_SALE_MINIMUM_BUY<=_anaAmount&&FOR_DISCOUNT_SALE_TOTAL_DIST>=_anaAmount){
            FOR_DISCOUNT_SALE_TOTAL_DIST=FOR_DISCOUNT_SALE_TOTAL_DIST.sub(_anaAmount);
            uint256 _newPrice = price.mul(75).div(100);
            emit DiscountApply(phaseId, user, _anaAmount,_newPrice, price);
            return _anaAmount.mul(_newPrice).div(1e18);
        } else if(FOR_DISCOUNT_SALE_MINIMUM_BUY<=_anaAmount&&FOR_DISCOUNT_SALE_TOTAL_DIST<_anaAmount){
            uint256 anaAmount = _anaAmount.sub(FOR_DISCOUNT_SALE_TOTAL_DIST);
            uint256 _newPrice = price.mul(75).div(100);
            emit DiscountApply(phaseId, user, FOR_DISCOUNT_SALE_TOTAL_DIST,_newPrice, price);
            uint256 amout = anaAmount.mul(price).div(1e18).add(FOR_DISCOUNT_SALE_TOTAL_DIST.mul(_newPrice).div(1e18));
            FOR_DISCOUNT_SALE_TOTAL_DIST=0;
            return amout;
        }
        else {
           return _anaAmount.mul(price).div(1e18);
        } 
    }

    function calculateINRxAmount(uint256 _anaAmount) external view returns (uint256) {
       uint8 phaseId =  getCurrentPhase();
       uint256 price = currentPrice(phaseId);
        if(FOR_DISCOUNT_SALE_MINIMUM_BUY<=_anaAmount&&FOR_DISCOUNT_SALE_TOTAL_DIST>=_anaAmount){
            uint256 _newPrice = price.mul(75).div(100);
            return _anaAmount.mul(_newPrice).div(1e18);
        } else if(FOR_DISCOUNT_SALE_MINIMUM_BUY<=_anaAmount&&FOR_DISCOUNT_SALE_TOTAL_DIST<_anaAmount){
            uint256 anaAmount = _anaAmount.sub(FOR_DISCOUNT_SALE_TOTAL_DIST);
            uint256 _newPrice = price.mul(75).div(100);
            uint256 amout = anaAmount.mul(price).div(1e18).add(FOR_DISCOUNT_SALE_TOTAL_DIST.mul(_newPrice).div(1e18));
            return amout;
        } else {
           return _anaAmount.mul(price).div(1e18);
        } 
    }

    function rescueToken(IERC20Upgradeable token, address to , uint256 amount) external onlyOwner {
        token.transfer(to,amount);
    }

    function rescueCoin(address payable to , uint256 amount) external onlyOwner {
        to.transfer(amount);
    }

    function setMinimumBuyAmount(uint256 _minimum) external onlyOwner {
        MINIMUM_BUY = _minimum;
    }

    function setLockingPeriod(uint256 _newLockingPeriod) external onlyOwner {
        LOCKING_PERIOD = _newLockingPeriod;
    }

    function pendingAPYReward( address user) public view returns (uint256) {
        User storage _user = users[user];
        uint256 totalAmount;
        for(uint256 i=0; i<users[user].deposits.length; i++) {
            Deposit storage deposit = _user.deposits[i];
			uint256 finish = deposit.timestamp.add(20*60);// 600 days
			if (_user.checkpoint < finish) {
				uint256 share = deposit.amount.div(BLOCKS_PER_DAY).mul(deposit.price).div(1e18);
				uint256 from = deposit.timestamp > _user.checkpoint ? deposit.timestamp : _user.checkpoint;
				uint256 to = finish < block.timestamp ? finish : block.timestamp;
                if (from < to) {
					totalAmount = totalAmount.add(share.mul(to.sub(from)).div(TIME_STEP));
				}
			}
		}

		return totalAmount;
    }

    function pendingSplitedAmount(address user)public view returns (uint256) {
        User storage _user = users[user];
        uint256 totalAmount;
        for(uint256 i=0; i<users[user].deposits.length;i++) {
            Deposit memory deposit = _user.deposits[i];
			uint256 finish = deposit.timestamp.add(20*60).add(LOCKING_PERIOD);// 600 days
			if (_user.checkpoint < finish && block.timestamp>=deposit.timestamp.add(LOCKING_PERIOD)) {
				uint256 share = deposit.amount.mul(5).div(100);
				uint256 from = deposit.timestamp > _user.checkpoint ? deposit.timestamp : _user.checkpoint;
				uint256 to = finish < block.timestamp ? finish : block.timestamp;
                if (from < to) {
					totalAmount = totalAmount.add(share.mul(to.sub(from)).div(TIME_STEP));
				}
			}
		}

		return totalAmount;
    }

    function withdraw() external whenNotPaused  {
       uint256 amount =  pendingAPYReward(_msgSender());
       uint256 _amount = pendingSplitedAmount(_msgSender());
       require(amount>0,"ICO:: Income is too low!");
        payable(_msgSender()).transfer(amount.add(_amount));
        users[_msgSender()].checkpoint=block.timestamp;
        users[_msgSender()].withdraw = users[_msgSender()].withdraw.add(amount.add(_amount));
        emit Withdraw(_msgSender(),amount,_amount,amount.add(_amount));
    }

    function reinitilize() public onlyOwner {
            uint256 addi;
            for(uint8 i=1; i< 8; i++) {
            phases[i].startBlock = block.number.add(addi.add(1));
            phases[i].endBlock = block.number.add(addi.add(300));
            addi=addi.add(300);
        }
    }

    function getIdToAddress(uint256 id) public view returns(address ) {
        return idToAddress[id];
    }

    function getUser(address user) public view returns (uint256 ,address,uint256,uint256,uint256,uint256){
        return (users[user].userId,users[user].refferal,users[user].affiliateIncome,users[user].withdraw,users[user].totalBuy,users[user].checkpoint);
    } 

    receive() external payable {}
}