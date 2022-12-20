/**
 *Submitted for verification at Etherscan.io on 2022-12-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

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


/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);
    function mint(address account, uint amount) external;
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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
     */
    function isContractt(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}


/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(SELECTOR, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'SafeERC20: TRANSFER_FAILED');
    }
    // function safeTransfer(IERC20 token, address to, uint256 value) internal {
    //     callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    // }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContractt(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

contract PlayerBook is OwnableUpgradeable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    //Record
    uint public inviteAccountsTotal;
    struct RegisteInfo {
        address addr;
        uint256 _time;
    }
    RegisteInfo[] public inviteAccounts;

    struct Player {
        address laff;
        uint256 reward;
        uint256 hasReward;
    }

    mapping (address => bool) public _pools;
    mapping (address => Player) public _plyr;

    address public _teamWallet;
    mapping (address => bool) public addrExist;
    mapping (address => uint) public hasInvite;

    address public constant _usdt = 0x55d398326f99059fF775485246999027B3197955;
    uint256 public constant _baseRate = 10000;

    mapping(uint => address[3]) public arrange;
    uint256 public curFloor;
    uint256 public curRow;
    mapping(address => uint[2]) public _position;
    mapping(address => uint) public _leftRewardAmount;
    uint256 public _basePrc;
    mapping(address => uint) public _numberOfGroups;
    mapping(address => uint) public _pos2ref;
    uint public _firStakeRate;
    uint public _reStakeRate;

    address public teamAddr_1;
    address public teamAddr_2;

    struct skItem {
        address account;
        uint256 amount;
        uint256 sktime;
        uint256 skrate;
    }
    skItem[] public _skRecord;
    mapping(address => uint) public _skAmounts;

    mapping(address => uint) public accountLevel;
    mapping(address => uint) public whiteList;
    mapping(address => uint) public _hasRewardwhiteList;

    struct feeItem {
        address account;
        uint256 Num;
        uint256 time;
    }
    feeItem[] public _feeWithdrawRecord;
    feeItem[] public _feeRestakeRecord;
    feeItem[] public _levelRecord;

    function initialize(address new_teamAddr_1,address new_teamAddr_2) external initializer {
        __Ownable_init();

        _teamWallet = _msgSender();
        addrExist[_teamWallet] = true;
        teamAddr_1 = new_teamAddr_1;
        teamAddr_2 = new_teamAddr_2;
        feeItem memory itemRecord;
        _feeWithdrawRecord.push(itemRecord);
        _feeRestakeRecord.push(itemRecord);

        curFloor = 1;
        _basePrc = 100*1e18;
        _firStakeRate = 30000;
        _reStakeRate = 22000;
    }

    modifier isRegisteredPool(){
        require(_pools[msg.sender],"invalid pool address!");
        _;
    }

    modifier validAddress( address addr ) {
        require(addr != address(0x0));
        _;
    }

    function addPool(address poolAddr)
        onlyOwner
        public
    {
        require( !_pools[poolAddr], "derp, that pool already been registered");

        _pools[poolAddr] = true;
    }

    function removePool(address poolAddr)
        onlyOwner
        public
    {
        require( _pools[poolAddr], "derp, that pool must be registered");

        _pools[poolAddr] = false;
    }


    function register(address affCode)
        public
    {
        require(addrExist[affCode],"not exist");
        address addr = msg.sender;
        require(_plyr[addr].laff == address(0), "sorry already register");

        _plyr[addr].laff = affCode;
        addrExist[addr] = true;

        hasInvite[affCode] = hasInvite[affCode].add(1);
        _pos2ref[addr] = hasInvite[affCode];
        if(hasInvite[affCode].mod(3)==0)
        {
            _numberOfGroups[affCode] = _numberOfGroups[affCode].add(1);
        }

        inviteAccountsTotal = inviteAccountsTotal.add(1);
        RegisteInfo memory itemRecord;
        itemRecord.addr = msg.sender;
        itemRecord._time = block.timestamp;
        inviteAccounts.push(itemRecord);
    }

    function stake(uint _amount) 
        external
    {
        require(_amount>0,"_amount zero");
        bool fsk = false;
        //distribute pos
        if(_position[msg.sender][0] == 0)
        {
            fsk = true;
            arrange[curFloor][curRow] = msg.sender;
            _position[msg.sender][0] = curFloor;
            _position[msg.sender][1] = curRow;
            curRow = curRow.add(1);
            if(curRow>2)
            {
                curRow = 0;
                curFloor = curFloor.add(1);
            }
        }

        skItem memory itemRecord;
        itemRecord.account = msg.sender;
        itemRecord.amount = _amount.mul(_basePrc);
        itemRecord.sktime = block.timestamp;
        itemRecord.skrate = fsk?_firStakeRate:_reStakeRate;
        _skRecord.push(itemRecord);
        
        IERC20(_usdt).safeTransferFrom(msg.sender,address(this),_amount.mul(_basePrc));
        _skAmounts[msg.sender]= _skAmounts[msg.sender].add(_amount.mul(_basePrc));
        _stake(_amount.mul(_basePrc),fsk);
    }

    function _stake(uint _amount ,bool firStk) 
        internal
    {
        address curaddr = msg.sender;
        require(msg.sender != _teamWallet,"_teamWallet err");
        require(addrExist[curaddr] && _plyr[curaddr].laff != address(0),"regist first");
        address affID = _plyr[curaddr].laff;
        uint stakeAmount = _amount;

        _leftRewardAmount[curaddr] += firStk?stakeAmount.mul(_firStakeRate).div(_baseRate):stakeAmount.mul(_reStakeRate).div(_baseRate);

        //reward stake amount
        if(_pos2ref[curaddr].mod(3) == 0)
        {
            _plyr[affID].reward = _plyr[affID].reward.add(stakeAmount.mul(1000).div(_baseRate));
            _plyr[_teamWallet].reward = _plyr[_teamWallet].reward.add(stakeAmount.mul(4000).div(_baseRate));
        }else{
            _plyr[affID].reward = _plyr[affID].reward.add(stakeAmount.mul(5000).div(_baseRate));
        }
        uint rewardTotal = stakeAmount.mul(5000).div(_baseRate);

        for(uint i=0;i<10;i++)
        {
            if(curaddr == _teamWallet)
            {
                break;
            }
            if(_numberOfGroups[affID] >= 3 || (_numberOfGroups[affID] >= 2 && i < 6 ) || (_numberOfGroups[affID] >= 1 && i < 3))
            {
                _plyr[affID].reward = _plyr[affID].reward.add(stakeAmount.mul(100).div(_baseRate));
                rewardTotal = rewardTotal.add(stakeAmount.mul(100).div(_baseRate));
            }
        }

        curaddr = msg.sender;
        affID = _plyr[curaddr].laff;
        for(uint k=0;k<5;k++)
        {
            curaddr = affID;
            affID = _plyr[curaddr].laff;
            if(curaddr == _teamWallet)
            {
                break;
            }

            if(_position[curaddr][0] == 0)
            {
                continue;
            }
            for(uint e = 0;e<3;e++)
            {
                address rewardAddr1 = arrange[_position[curaddr][0] + 1][e];
                address rewardAddr2 = arrange[_position[curaddr][0] + 2][e];
                if(rewardAddr1 != address(0))
                {
                    _plyr[rewardAddr1].reward = _plyr[rewardAddr1].reward.add(stakeAmount.mul(100).div(_baseRate));
                    rewardTotal = rewardTotal.add(stakeAmount.mul(100).div(_baseRate));
                }
                if(rewardAddr2 != address(0))
                {
                    _plyr[rewardAddr2].reward = _plyr[rewardAddr2].reward.add(stakeAmount.mul(100).div(_baseRate));
                    rewardTotal = rewardTotal.add(stakeAmount.mul(100).div(_baseRate));
                } 
                if(k < 3 && _position[curaddr][0] > 1)
                {
                    address rewardAddr3 = arrange[_position[curaddr][0] - 1][e];
                    if(rewardAddr3 != address(0))
                    {
                        _plyr[rewardAddr3].reward = _plyr[rewardAddr3].reward.add(stakeAmount.mul(100).div(_baseRate));
                        rewardTotal = rewardTotal.add(stakeAmount.mul(100).div(_baseRate));
                    }
                }
            }
        }

        _plyr[_teamWallet].reward = _plyr[_teamWallet].reward.add(stakeAmount.sub(rewardTotal));
    }

    function claim() 
        external
    {
        address addr = msg.sender;
        uint256 reward = _plyr[addr].reward;
        reward = _leftRewardAmount[addr] < reward?_leftRewardAmount[addr]:reward;

        require(reward > 0 ,"amount zero");

        uint _fee = reward.mul(1000).div(_baseRate);

        _plyr[addr].reward = 0;
        _plyr[addr].hasReward = _plyr[addr].hasReward.add(reward.sub(_fee));

        feeItem memory itemRecord;
        itemRecord.account = msg.sender;
        itemRecord.Num = _fee;
        itemRecord.time = block.timestamp;
        _feeWithdrawRecord.push(itemRecord);

        IERC20(_usdt).safeTransfer(teamAddr_1,_fee);
        IERC20(_usdt).safeTransfer(msg.sender,reward.sub(_fee));
        
    }

    function restake() 
        external
    {
        require(_position[msg.sender][0] != 0,"not stake");
        address addr = msg.sender;
        uint256 reward = _plyr[addr].reward;
        reward = _leftRewardAmount[addr] < reward?_leftRewardAmount[addr]:reward;

        require(reward > 0 ,"amount zero");

        uint _fee = reward.mul(500).div(_baseRate);

        _plyr[addr].reward = 0;

        feeItem memory itemRecord;
        itemRecord.account = msg.sender;
        itemRecord.Num = _fee;
        itemRecord.time = block.timestamp;
        _feeRestakeRecord.push(itemRecord);

        IERC20(_usdt).safeTransfer(teamAddr_2,_fee);

        _stake(reward.sub(_fee),false);
        
    }

    function skRecordLength()
        external
        view
        returns (uint256)
    {
        return _skRecord.length;
    }

    function _feeWithdrawRecordLength()
        external
        view
        returns (uint256)
    {
        return _feeWithdrawRecord.length - 1;
    }

    function _feeRestakeRecordLength()
        external
        view
        returns (uint256)
    {
        return _feeRestakeRecord.length - 1;
    }

    function _levelRecordLength()
        external
        view
        returns (uint256)
    {
        return _levelRecord.length - 1;
    }

    function getPlayerInfo(address from)
        external
        view
        returns (address,uint256,uint256)
    {
        return (_plyr[from].laff,_plyr[from].reward,_plyr[from].hasReward);
    }

    function govWithdraw(address tokenAddr,uint256 amount)
        public onlyOwner
    {
        require(amount > 0, "Cannot withdraw 0");
        IERC20(tokenAddr).safeTransfer(msg.sender,amount);
    }

    function setteamAddr_1(address new_teamAddr_1)
        public onlyOwner
    {
        teamAddr_1 = new_teamAddr_1;
    }

    function setteamAddr_2(address new_teamAddr_2)
        public onlyOwner
    {
        teamAddr_2 = new_teamAddr_2;
    }

    function set_basePrc(uint new_basePrc)
        public onlyOwner
    {
        _basePrc = new_basePrc;
    }

    function set_firStakeRate(uint new_firStakeRate)
        public onlyOwner
    {
        _firStakeRate = new_firStakeRate;
    }

    function set_reStakeRate(uint new_reStakeRate)
        public onlyOwner
    {
        _reStakeRate = new_reStakeRate;
    }

    function setLevel(address[] calldata ac,uint[] calldata _whitelist)
        external onlyOwner
    {
        require(ac.length <= _whitelist.length && ac.length > 0);

        feeItem memory itemRecord;
        for(uint i=0;i<ac.length;i++)
        {
            itemRecord.account = ac[i];
            itemRecord.Num = _whitelist[i];
            itemRecord.time = block.timestamp;
            _levelRecord.push(itemRecord);
            accountLevel[ac[i]] = _whitelist[i];
        }
    }

    function setwhiteList(address[] calldata ac,uint[] calldata _whitelist)
        external onlyOwner
    {
        require(ac.length <= _whitelist.length && ac.length > 0);

        for(uint i=0;i<ac.length;i++)
        {
            whiteList[ac[i]] = whiteList[ac[i]].add(_whitelist[i]);
        }
    }

    function withdrawWhitelist()
        external 
    {
        require(whiteList[msg.sender] > 0,"whiteList err");
        uint rewardamounts = whiteList[msg.sender];
        whiteList[msg.sender] = 0;

        IERC20(_usdt).safeTransfer(msg.sender,rewardamounts);
        _hasRewardwhiteList[msg.sender] = _hasRewardwhiteList[msg.sender].add(rewardamounts);
    }

}