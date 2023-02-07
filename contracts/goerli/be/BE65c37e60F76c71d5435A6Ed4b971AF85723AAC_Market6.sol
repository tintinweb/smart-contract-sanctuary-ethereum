/**
 *Submitted for verification at Etherscan.io on 2023-02-07
*/

// Sources flattened with hardhat v2.9.5 https://hardhat.org

// File @openzeppelin/contracts-upgradeable/utils/math/[email protected]


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


// File @openzeppelin/contracts-upgradeable/token/ERC20/[email protected]


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


// File @openzeppelin/contracts-upgradeable/utils/[email protected]


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


// File @openzeppelin/contracts-upgradeable/token/ERC20/utils/[email protected]


// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;


/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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


// File @openzeppelin/contracts-upgradeable/proxy/utils/[email protected]


// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

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


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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


// File @openzeppelin/contracts-upgradeable/utils/introspection/[email protected]


// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}


// File @openzeppelin/contracts-upgradeable/token/ERC721/[email protected]


// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}


// File @openzeppelin/contracts-upgradeable/token/ERC721/[email protected]


// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}


// File @openzeppelin/contracts-upgradeable/token/ERC721/utils/[email protected]


// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;


/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721HolderUpgradeable is Initializable, IERC721ReceiverUpgradeable {
    function __ERC721Holder_init() internal onlyInitializing {
    }

    function __ERC721Holder_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}


// File @openzeppelin/contracts-upgradeable/token/ERC1155/[email protected]


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}


// File @openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155ReceiverUpgradeable.[email protected]


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @dev _Available since v3.1._
 */
interface IERC1155ReceiverUpgradeable is IERC165Upgradeable {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}


// File @openzeppelin/contracts-upgradeable/utils/introspection/[email protected]


// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;


/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}


// File @openzeppelin/contracts-upgradeable/token/ERC1155/utils/[email protected]


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;



/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155ReceiverUpgradeable is Initializable, ERC165Upgradeable, IERC1155ReceiverUpgradeable {
    function __ERC1155Receiver_init() internal onlyInitializing {
    }

    function __ERC1155Receiver_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return interfaceId == type(IERC1155ReceiverUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}


// File @openzeppelin/contracts-upgradeable/token/ERC1155/utils/[email protected]


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;


/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155HolderUpgradeable is Initializable, ERC1155ReceiverUpgradeable {
    function __ERC1155Holder_init() internal onlyInitializing {
    }

    function __ERC1155Holder_init_unchained() internal onlyInitializing {
    }
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}


// File @openzeppelin/contracts-upgradeable/security/[email protected]


// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

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
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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


// File @openzeppelin/contracts-upgradeable/utils/structs/[email protected]


// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

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
library EnumerableSetUpgradeable {
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
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
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


// File @uniswap/lib/contracts/libraries/[email protected]

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }
}


// File contracts/IMarket6.sol


pragma solidity >=0.6.2;

interface IMarket6 {
    function buyToken(address _nft, uint256 _tokenId, address _seller, uint256 _quantity, uint256 _amount, uint256 _maximumPrice, address _quote) external;

    function buyTokenTo(address _nft, uint256 _tokenId, address _to, address _seller, uint256 _quantity, uint256 _amount, uint256 _maximumPrice, address _quote) external;

    function buyTokenETH(address _nft, uint256 _tokenId, address _seller, uint256 _quantity, uint256 _amount, uint256 _price) external payable;

    function buyTokenToETH(address _nft, uint256 _tokenId, address _to, address _seller, uint256 _quantity, uint256 _amount, uint256 _price, uint256 _maximumPrice) external payable;

//    function setCurrentPrice(
//        address _nft,
//        uint256 _tokenId,
//        uint256 _quantity,
//        uint256 _oldPrice,
//        address _oldQuote,
//        uint256 _newPrice,
//        address _newQuote
//    ) external;

    function readyToSellToken(address _nft, uint _nftType, uint256 _tokenId, uint256 _quantity, uint256 _price, address _quote, address _creator, uint256 _rate) external;

    function readyToSellTokenTo(
        address _nft,
        uint    _nftType,
        uint256 _tokenId,
        uint256 _quantity,
        uint256 _price,
        address _quote,
        address _to,
        address _creator,
        uint256 _rate
    ) external;

    function cancelSellToken(address _nft, uint256 _tokenId, uint256 _quantity, uint256 _price, address _quote) external;

    function onERC1155Received(address operator, address from, uint256 id, uint256 value, bytes calldata data) external returns(bytes4);

    function bidToken(address _nft, uint _nftType, uint256 _tokenId, uint256 _quantity, uint256 _price, address _quote) external;

    function bidTokenETH(address _nft, uint _nftType, uint256 _tokenId, uint256 _quantity, uint256 _price) external payable;

    function cancelBidToken(address _nft, uint256 _tokenId, uint256 _quantity, uint256 _price, address _quote) external;

    function updateBidPrice(address _nft, uint256 _tokenId, uint256 _quantity, uint256 _price, uint256 _newPrice, address _quote) external;

    function updateBidPriceETH(address _nft, uint256 _tokenId, uint256 _quantity, uint256 _price, uint256 _newPrice, address _quote) external payable;

    function sellTokenTo(address _nft, uint256 _tokenId, address _to, uint256 _quantity, uint256 _price, address _quote, address _creator, uint256 _rate) external;
}


// File contracts/Market6.sol














// File: contracts/Market.sol

pragma solidity >=0.6.6;
// pragma experimental ABIEncoderV2;

contract Market6 is IMarket6, ERC721HolderUpgradeable, OwnableUpgradeable, PausableUpgradeable {
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using AddressUpgradeable for address;
    // using EnumerableMap for EnumerableMap.UintToUintMap;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

    struct AskEntry {
        uint    nftType;
        address seller;
        uint256 quantity;
        uint256 price;
        address quote;
        uint256 sold;
        address creator;
        uint256 rate;
    }

//    struct AsksMap {
//        uint    nftType;
//        uint256 tokenId;
//        address seller;
//        uint256 quantity;
//        uint256 price;
//        address quote;
//        uint256 sold;
//        address creator;
//        uint256 rate;
//    }

    struct BidEntry {
        uint    nftType;
        address bidder;
        uint256 quantity;
        uint256 price;
        address quote;
    }

    struct UserBidEntry {
        uint256 tokenId;
        uint256 price;
    }

    IERC20Upgradeable public quoteErc20;
    address public feeAddr;
    uint256 public feePercent;

    mapping(address => mapping(uint256 => mapping(bytes32 => AskEntry[]))) private _askTokens;
//    mapping(address => AsksMap[]) private _asksMap;

    mapping(address => mapping(uint256 => mapping(bytes32 => BidEntry[]))) private _tokenBids;
    // TokenId 별로 단 한번의 Bid 만 등록이 가능함. 가격 업데이트는 가능.
    mapping(address => mapping(address => mapping(uint256 => uint256))) private _userBids;

    // NFT 거래
    event Trade(address indexed seller, address indexed buyer, address indexed nft, uint256 tokenId, uint256 quantity, uint256 amount, uint256 price, uint256 fee);

    // NFT 판매 등록
    event Ask(address indexed seller, address indexed nft, uint256 indexed tokenId, uint256 quantity, uint256 price, address quote);

    // NFT 판매 등록 취소
    event CancelSellToken(address indexed seller, address indexed nft, uint256 indexed tokenId, uint256 quantity, uint256 price, address quote);

    // NFT Bidding
    event Bid(address indexed bidder, address indexed nft, uint256 indexed tokenId, uint256 quantity, uint256 price, address quote);

    // NFT Bidding 취소
    event CancelBidToken(address indexed bidder, address indexed nft, uint256 indexed tokenId, uint256 quantity, uint256 price, address quote);

    function initialize(
        address _quoteErc20Address,
        address _feeAddr,
        uint256 _feePercent
    ) initializer public
    {
        require(_quoteErc20Address != address(0) && _quoteErc20Address != address(this));

        __Ownable_init_unchained();
        __Pausable_init_unchained();
        __ERC721Holder_init_unchained();

        quoteErc20 = IERC20Upgradeable(_quoteErc20Address);
        feeAddr = _feeAddr;
        feePercent = _feePercent;
    }

    function buyTokenETH(
        address _nft,
        uint256 _tokenId,
        address _seller,
        uint256 _quantity,
        uint256 _amount,
        uint256 _price
    ) public payable override whenNotPaused
    {
        buyTokenToETH(_nft, _tokenId, _msgSender(), _seller, _quantity, _amount, _price, msg.value);
    }

    function buyTokenToETH(
        address _nft,
        uint256 _tokenId,
        address _to,
        address _seller,
        uint256 _quantity,
        uint256 _amount,
        uint256 _price,
        uint256 _maximumPrice
    ) public payable override whenNotPaused
    {
        require(_msgSender() != address(0) && _msgSender() != address(this), 'Wrong msg sender');

        require(_amount > 0, 'Invalid buying amount');

        bytes32 _ix = keccak256(abi.encodePacked(_seller, _quantity, _price, address(0)));
        uint256 len = _askTokens[_nft][_tokenId][_ix].length;
        require(len > 0, 'Token not in sell book');

        AskEntry memory selected = _askTokens[_nft][_tokenId][_ix][0];
        require(selected.quantity.sub(selected.sold) >= _amount, 'Not enough stocks in this sell book');

        if (selected.nftType == 721) {
            IERC721Upgradeable(_nft).safeTransferFrom(address(this), _to, _tokenId);
        } else if (selected.nftType == 1155) {
            IERC1155Upgradeable(_nft).safeTransferFrom(address(this), _to, _tokenId, _amount, '0x');
        }

        require(selected.price.mul(_amount) <= _maximumPrice, 'invalid price');

        uint256 feeAmount = _maximumPrice.mul(feePercent).div(1000);
        uint256 earning = _maximumPrice.mul(selected.rate).div(1000);
        if (feeAmount != 0) {
            TransferHelper.safeTransferETH(feeAddr, feeAmount);
        }
        if (earning != 0 && selected.creator != address(0)) {
            TransferHelper.safeTransferETH(selected.creator, earning);
        }
        TransferHelper.safeTransferETH(selected.seller, _maximumPrice.sub(feeAmount.add(earning)));

        // delete the ask
        delAskTokensByTokenId(_nft, _tokenId, _ix, _amount);

        emit Trade(selected.seller, _to, _nft, _tokenId, _quantity, _amount, _maximumPrice, feeAmount);
    }

    function buyToken(
        address _nft,
        uint256 _tokenId,
        address _seller,
        uint256 _quantity,
        uint256 _amount,
        uint256 _maximumPrice,
        address _quote
    ) public override whenNotPaused
    {
        buyTokenTo(_nft, _tokenId, _msgSender(), _seller, _quantity, _amount, _maximumPrice, _quote);
    }

    function buyTokenTo(
        address _nft,
        uint256 _tokenId,
        address _to,
        address _seller,
        uint256 _quantity,
        uint256 _amount,
        uint256 _maximumPrice,
        address _quote)
    public override whenNotPaused
    {
        require(_msgSender() != address(0) && _msgSender() != address(this), 'Wrong msg sender');

        require(_amount > 0, 'Invalid buying amount');

        bytes32 _ix = keccak256(abi.encodePacked(_seller, _quantity, _maximumPrice, _quote));
        require(_askTokens[_nft][_tokenId][_ix].length > 0, 'Token not in sell book');

        AskEntry memory selected = _askTokens[_nft][_tokenId][_ix][0];
        require(selected.quantity.sub(selected.sold) >= _amount, 'Not enough stocks in this sell book');

        if (selected.nftType == 721) {
            IERC721Upgradeable(_nft).safeTransferFrom(address(this), _to, _tokenId);
        } else if (selected.nftType == 1155) {
            IERC1155Upgradeable(_nft).safeTransferFrom(address(this), _to, _tokenId, _amount, '0x');
        }

        require(selected.price <= _maximumPrice, 'invalid price');

        uint256 totalPrice = selected.price.mul(_amount);
        uint256 feeAmount = totalPrice.mul(feePercent).div(1000);
        uint256 earning = totalPrice.mul(selected.rate).div(1000);
        if (feeAmount != 0) {
            // quoteErc20.safeTransferFrom(_msgSender(), feeAddr, feeAmount);
            IERC20Upgradeable(selected.quote).safeTransferFrom(_msgSender(), feeAddr, feeAmount);
        }
        if (earning != 0 && selected.creator != address(0)) {
            IERC20Upgradeable(selected.quote).safeTransferFrom(_msgSender(), selected.creator, earning);
        }
        IERC20Upgradeable(selected.quote).safeTransferFrom(_msgSender(), selected.seller, totalPrice.sub(feeAmount.add(earning)));

        // delete the ask
        delAskTokensByTokenId(_nft, _tokenId, _ix, _amount);

        emit Trade(selected.seller, _to, _nft, _tokenId, _quantity, _amount, totalPrice, feeAmount);
    }

//    // NFT 판매를 올려놓은 것의 가격을 수정
//    // nft: NFT 토큰 주소
//    // tokenId: NFT 토큰 아이디
//    // price: Wei단위 가격
//    function setCurrentPrice(
//        address _nft,
//        uint256 _tokenId,
//        uint256 _quantity,
//        uint256 _oldPrice,
//        address _oldQuote,
//        uint256 _newPrice,
//        address _newQuote
//    ) public override whenNotPaused
//    {
//        bytes32 _ix = keccak256(abi.encodePacked(_msgSender(), _quantity, _oldPrice, _oldQuote));
//        uint256 len = _askTokens[_nft][_tokenId][_ix].length;
//        require(len > 0, 'Token not in sell book');
//
//        require(_newPrice != 0, 'Price must be granter than zero');
//
//        AskEntry memory selected = _askTokens[_nft][_tokenId][_ix][0];
//        selected.price = _newPrice;
//        selected.quote = _newQuote;
//
//        uint256 length = _asksMap[_nft].length;
//        for (uint256 i = 0; i < length ; i++) {
//            if (_asksMap[_nft][i].tokenId == _tokenId &&
//            _asksMap[_nft][i].seller == _msgSender() &&
//            _asksMap[_nft][i].quantity == _quantity &&
//            _asksMap[_nft][i].price == _oldPrice &&
//                _asksMap[_nft][i].quote == _oldQuote
//            ) {
//                _asksMap[_nft][i].price = _newPrice;
//                _asksMap[_nft][i].quote = _newQuote;
//                break;
//            }
//        }
//
//        emit Ask(_msgSender(), _nft, _tokenId, _quantity, _newPrice, _newQuote);
//    }

    // NFT 판매
    // nft: NFT 토큰 주소
    // tokenId: NFT 토큰 아이디
    // price: Wei단위 가격
    function readyToSellToken(
        address _nft,
        uint _nftType,
        uint256 _tokenId,
        uint256 _quantity,
        uint256 _price,
        address _quote,
        address _creator,
        uint256 _rate
    ) public override whenNotPaused
    {
        readyToSellTokenTo(_nft, _nftType, _tokenId, _quantity, _price, _quote, address(_msgSender()), _creator, _rate);
    }

    // 특정 유저에 한정해서 NFT를 판매
    // nft: NFT 토큰 주소
    // tokenId: NFT 토큰 아이디
    // price: Wei단위 가격
    // to: 특정 유저
    function readyToSellTokenTo(
        address _nft,
        uint    _nftType,
        uint256 _tokenId,
        uint256 _quantity,
        uint256 _price,
        address _quote,
        address _to,
        address _creator,
        uint256 _rate
    ) public override whenNotPaused
    {
        if (_nftType == 721) {
            require(_msgSender() == IERC721Upgradeable(_nft).ownerOf(_tokenId), 'Only Token Owner can sell token');
        } else if (_nftType == 1155) {
            require(IERC1155Upgradeable(_nft).balanceOf(_msgSender(), _tokenId) >= _quantity, 'Only Token Owner can sell token');
        }
        require(_price != 0, 'Price must be granter than zero');

        if (_nftType == 721) {
            IERC721Upgradeable(_nft).safeTransferFrom(_msgSender(), address(this), _tokenId);
        } else if (_nftType == 1155) {
            IERC1155Upgradeable(_nft).safeTransferFrom(_msgSender(), address(this), _tokenId, _quantity, '0x');
        }

        bytes32 _ix = keccak256(abi.encodePacked(_to, _quantity, _price, _quote));

        // add the ask
        _askTokens[_nft][_tokenId][_ix].push(AskEntry({nftType: _nftType, seller: _to, quantity: _quantity, price: _price, quote: _quote, sold: 0, creator: _creator, rate: _rate}));

        emit Ask(_to, _nft, _tokenId, _quantity, _price, _quote);
    }

    // NFT 판매 취소
    // nft: NFT 토큰 주소
    // tokenId: NFT 토큰 아이디
    function cancelSellToken(
        address _nft,
        uint256 _tokenId,
        uint256 _quantity,
        uint256 _price,
        address _quote
    ) public override whenNotPaused
    {
        bytes32 _ix = keccak256(abi.encodePacked(_msgSender(), _quantity, _price, _quote));
        uint256 len = _askTokens[_nft][_tokenId][_ix].length;
        require(len > 0, 'Only Seller can cancel sell token');

        AskEntry memory selected = _askTokens[_nft][_tokenId][_ix][0];

        if (selected.nftType == 721) {
            IERC721Upgradeable(_nft).safeTransferFrom(address(this), _msgSender(), _tokenId);
        } else if (selected.nftType == 1155) {
            uint256 _left = selected.quantity.sub(selected.sold);
            IERC1155Upgradeable(_nft).safeTransferFrom(address(this), _msgSender(), _tokenId, _left, '0x');
        }

        // remove the ask
        delAskTokensByTokenId(_nft, _tokenId, _ix, 0);

        emit CancelSellToken(_msgSender(), _nft, _tokenId, _quantity, _price, _quote);
    }

    // 컨트랙트 기능 정지
    function pause() public onlyOwner whenNotPaused
    {
        _pause();
    }

    // 컨트랙트 기능 정지 해제
    function unpause() public onlyOwner whenPaused
    {
        _unpause();
    }

    // 거래 수수료 받는 주소 변경
    function transferFeeAddress(
        address _feeAddr
    ) public
    {
        require(_msgSender() == feeAddr, 'FORBIDDEN');
        feeAddr = _feeAddr;
    }

    // 거래 수수료 퍼센트 변경
    function setFeePercent(
        uint256 _feePercent
    ) public onlyOwner
    {
        require(feePercent != _feePercent, 'Not need update');
        feePercent = _feePercent;
    }

    // NFT Ask 리스트애서 특정 TokenId를 삭제
    function delAskTokensByTokenId(
        address _nft,
        uint256 _tokenId,
        bytes32 _ix,
        uint256 _amount
    ) private
    {
        AskEntry memory selected = _askTokens[_nft][_tokenId][_ix][0];

//        uint256 length = _asksMap[_nft].length;
//        for (uint256 i = 0; i < length ; i++) {
//            if (_asksMap[_nft][i].tokenId == _tokenId &&
//            _asksMap[_nft][i].seller == selected.seller &&
//            _asksMap[_nft][i].quantity == selected.quantity &&
//            _asksMap[_nft][i].price == selected.price &&
//                _asksMap[_nft][i].quote == selected.quote
//            ) {
//                if (selected.sold.add(_amount) == selected.quantity ||
//                    _amount == 0
//                ) {
//                    for (uint256 j = i; j < length - 1; j++) {
//                        _asksMap[_nft][j] = _asksMap[_nft][j + 1];
//                    }
//                    _asksMap[_nft].pop();
//                } else {
//                    _asksMap[_nft][i].sold = _asksMap[_nft][i].sold.add(_amount);
//                }
//                break;
//            }
//        }

        // delete the ask
        if (selected.sold.add(_amount) == selected.quantity ||
            _amount == 0
        ) {
            uint256 len = _askTokens[_nft][_tokenId][_ix].length;

            for (uint256 i = 0; i < len - 1 ; i++) {
                _askTokens[_nft][_tokenId][_ix][i] = _askTokens[_nft][_tokenId][_ix][i + 1];
            }
            _askTokens[_nft][_tokenId][_ix].pop();
        } else {
            _askTokens[_nft][_tokenId][_ix][0].sold = _askTokens[_nft][_tokenId][_ix][0].sold.add(_amount);
        }
    }

    function emergencyWithdraw() public onlyOwner
    {
        uint256 balance = quoteErc20.balanceOf(address(this));
        require(balance > 0, 'no balance');
        quoteErc20.safeTransfer(owner(), balance);
    }

//    function getNftAllAsks(
//        address _nft
//    ) external view returns (AsksMap[] memory)
//    {
//        return _asksMap[_nft];
//    }

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external override returns(bytes4)
    {
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }

    function bidToken(
        address _nft,
        uint _nftType,
        uint256 _tokenId,
        uint256 _quantity,
        uint256 _price,
        address _quote
    ) public override whenNotPaused
    {
        require(_msgSender() != address(0) && _msgSender() != address(this), 'Wrong msg sender');
        require(_price != 0, 'Price must be granter than zero');

        address _bidder = address(_msgSender());
        if (_nftType == 721) {
            require(IERC721Upgradeable(_nft).ownerOf(_tokenId) != _bidder, 'Owner cannot bid');
        } else if (_nftType == 1155) {
            require(IERC1155Upgradeable(_nft).balanceOf(_bidder, _tokenId) == 0, 'Owner cannot bid');
        }

        require(_userBids[_nft][_bidder][_tokenId] == 0, 'Bidder already exists');

        IERC20Upgradeable(_quote).safeTransferFrom(_msgSender(), address(this), _price.mul(_quantity));

        // When ?
        _userBids[_nft][_bidder][_tokenId] = _price.mul(_quantity);

        bytes32 _ix = keccak256(abi.encodePacked(_bidder, _quantity, _price, _quote));
        _tokenBids[_nft][_tokenId][_ix].push(BidEntry({nftType: _nftType, bidder: _bidder, quantity: _quantity, price: _price, quote: _quote}));
        emit Bid(_msgSender(), _nft, _tokenId, _quantity, _price, _quote);
    }

    function bidTokenETH(
        address _nft,
        uint _nftType,
        uint256 _tokenId,
        uint256 _quantity,
        uint256 _price
    ) public payable override whenNotPaused
    {
        require(_msgSender() != address(0) && _msgSender() != address(this), 'Wrong msg sender');
        require(_price != 0, 'Price must be granter than zero');
        require(msg.value >= _price.mul(_quantity), 'Fund is not enough');

        address _bidder = address(_msgSender());
        if (_nftType == 721) {
            require(IERC721Upgradeable(_nft).ownerOf(_tokenId) != _bidder, 'Owner cannot bid');
        } else if (_nftType == 1155) {
            require(IERC1155Upgradeable(_nft).balanceOf(_bidder, _tokenId) == 0, 'Owner cannot bid');
        }

        require(_userBids[_nft][_bidder][_tokenId] == 0, 'Bidder already exists');

        // When ?
        _userBids[_nft][_bidder][_tokenId] = _price.mul(_quantity);

        bytes32 _ix = keccak256(abi.encodePacked(_bidder, _quantity, _price, address(0)));
        _tokenBids[_nft][_tokenId][_ix].push(BidEntry({nftType: _nftType, bidder: _bidder, quantity: _quantity, price: _price, quote: address(0)}));
        emit Bid(_msgSender(), _nft, _tokenId, _quantity, _price, address(0));
    }

    function cancelBidToken(
        address _nft,
        uint256 _tokenId,
        uint256 _quantity,
        uint256 _price,
        address _quote
    ) public override whenNotPaused
    {
        require(_userBids[_nft][_msgSender()][_tokenId] > 0, 'Only Bidder can cancel the bid');
        address _bidder = address(_msgSender());
        // find bid and the index
        (BidEntry memory bidEntry, uint256 _index) = getBidByBidInfo(_nft, _tokenId, _bidder, _quantity, _price, _quote);
        require(bidEntry.price != 0, 'Bidder does not exist');
        require(bidEntry.bidder == _bidder, 'Only Bidder can cancel the bid');

        IERC20Upgradeable(_quote).safeTransferFrom(address(this), _bidder, bidEntry.price.mul(bidEntry.quantity));
        delBidByBidInfo(_bidder, _nft, _tokenId, _quantity, _price, _quote, _index);
        emit CancelBidToken(_msgSender(), _nft, _tokenId, _quantity, _price, _quote);
    }

    function getBidByBidInfo(
        address _nft,
        uint256 _tokenId,
        address _bidder, // bidder
        uint256 _quantity,
        uint256 _price,
        address _quote
    ) private view returns (BidEntry memory, uint256)
    {
        // find the index of the bid
        bytes32 _ix = keccak256(abi.encodePacked(_bidder, _quantity, _price, _quote));
        BidEntry[] memory bidEntries = _tokenBids[_nft][_tokenId][_ix];
        uint256 len = bidEntries.length;
        uint256 _index;
        BidEntry memory bidEntry;
        for (uint256 i = 0; i < len; i++) {
            if (_bidder == bidEntries[i].bidder) {
                _index = i;
                bidEntry = BidEntry({
                    nftType: bidEntries[i].nftType,
                    bidder: bidEntries[i].bidder,
                    quantity: bidEntries[i].quantity,
                    price: bidEntries[i].price,
                    quote: bidEntries[i].quote
                });
                break;
            }
        }
        return (bidEntry, _index);
    }

    function delBidByBidInfo(
        address _bidder,
        address _nft,
        uint256 _tokenId,
        uint256 _quantity,
        uint256 _price,
        address _quote,
        uint256 _index
    ) private
    {
        bytes32 _ix = keccak256(abi.encodePacked(_bidder, _quantity, _price, _quote));
        _userBids[_nft][_tokenBids[_nft][_tokenId][_ix][_index].bidder][_tokenId] = 0;
        // delete the bid
        uint256 len = _tokenBids[_nft][_tokenId][_ix].length;
        for (uint256 i = _index; i < len - 1; i++) {
            _tokenBids[_nft][_tokenId][_ix][i] = _tokenBids[_nft][_tokenId][_ix][i + 1];
        }
        _tokenBids[_nft][_tokenId][_ix].pop();
    }

    function shareProfits(
        address _nft,
        uint256 _tokenId,
        address _bidder,
        uint256 _quantity,
        uint256 _price,
        address _quote,
        address _creator,
        uint256 _rate
    ) private
    {
        address _seller = address(_msgSender());

        // Share profits
        uint256 totalPrice = _price.mul(_quantity);
        uint256 feeAmount = totalPrice.mul(feePercent).div(1000);
        uint256 earning = totalPrice.mul(_rate).div(1000);
        if (feeAmount != 0) {
            if (_quote == address(0)) {
                TransferHelper.safeTransferETH(feeAddr, feeAmount);
            } else {
                TransferHelper.safeTransfer(_quote, feeAddr, feeAmount);
                // IERC20Upgradeable(_quote).transfer(feeAddr, feeAmount);
            }
        }
        if (earning != 0 && _creator != address(0)) {
            if (_quote == address(0)) {
                TransferHelper.safeTransferETH(_creator, earning);
            } else {
                TransferHelper.safeTransfer(_quote, _creator, earning);
                // IERC20Upgradeable(_quote).transfer(_creator, earning);
            }
        }
        if (_quote == address(0)) {
            TransferHelper.safeTransferETH(_seller, totalPrice.sub(feeAmount.add(earning)));
        } else {
            TransferHelper.safeTransfer(_quote, _seller, totalPrice.sub(feeAmount.add(earning)));
            // IERC20Upgradeable(_quote).transfer(_seller, totalPrice.sub(feeAmount.add(earning)));
        }

        emit Trade(_seller, _bidder, _nft, _tokenId, _quantity, _quantity, totalPrice, feeAmount);
    }

    function sellTokenTo(
        address _nft,
        uint256 _tokenId,
        address _bidder,
        uint256 _quantity,
        uint256 _price,
        address _quote,
        address _creator,
        uint256 _rate
    ) public override whenNotPaused
    {
        address _seller = address(_msgSender());

        // find bid and the index
        (BidEntry memory bidEntry, uint256 _index) = getBidByBidInfo(_nft, _tokenId, _bidder, _quantity, _price, _quote);
        uint256 price = bidEntry.price;
        require(bidEntry.price != 0, 'Bidder does not exist');
        require(_quantity == bidEntry.quantity, 'Wrong quantity');

        if (bidEntry.nftType == 721) {
            require(IERC721Upgradeable(_nft).ownerOf(_tokenId) == _seller, 'Cancel NFT selling in advance');
            IERC721Upgradeable(_nft).safeTransferFrom(_seller, _bidder, _tokenId);
        } else if (bidEntry.nftType == 1155) {
            require(IERC1155Upgradeable(_nft).balanceOf(_seller, _tokenId) >= _quantity, 'Cancel NFT selling in advance');
            IERC1155Upgradeable(_nft).safeTransferFrom(_seller, _bidder, _tokenId, _quantity, '0x');
        }

        // Separate into another function because of "CompilerError: Stack Too Deep"
        shareProfits(_nft, _tokenId, _bidder, _quantity, _price, _quote, _creator, _rate);

        // Remove Offer
        delBidByBidInfo(_bidder, _nft, _tokenId, _quantity, _price, _quote, _index);
    }

    function updateBidPrice(
        address _nft,
        uint256 _tokenId,
        uint256 _quantity,
        uint256 _price,
        uint256 _newPrice,
        address _quote
    ) public override whenNotPaused
    {
        require(_userBids[_nft][_msgSender()][_tokenId] > 0, 'Only Bidder can update the bid price');
        require(_price != 0, 'Price must be granter than zero');
        address _bidder = address(_msgSender()); // find bid and the index
        (BidEntry memory bidEntry, uint256 _index) = getBidByBidInfo(_nft, _tokenId, _bidder, _quantity, _price, _quote);
        require(bidEntry.price != 0, 'Bidder does not exist');
        require(bidEntry.price != _newPrice, 'The bid price cannot be the same');

        if (_newPrice > bidEntry.price) {
            IERC20Upgradeable(_quote).safeTransferFrom(_bidder, address(this), _newPrice.sub(bidEntry.price));
        } else {
            IERC20Upgradeable(_quote).safeTransferFrom(address(this), _bidder, bidEntry.price.sub(_newPrice));
        }

        bytes32 _ix = keccak256(abi.encodePacked(_bidder, _quantity, _price, _quote));
        _userBids[_nft][_bidder][_tokenId] = _newPrice;
        _tokenBids[_nft][_tokenId][_ix][_index] = BidEntry({
            nftType: bidEntry.nftType,
            bidder: bidEntry.bidder,
            quantity: bidEntry.quantity,
            price: _newPrice,
            quote: bidEntry.quote
        });
        emit Bid(_msgSender(), _nft, _tokenId, _quantity, _newPrice, _quote);
    }

    function updateBidPriceETH(
        address _nft,
        uint256 _tokenId,
        uint256 _quantity,
        uint256 _price,
        uint256 _newPrice,
        address _quote
    ) public payable override whenNotPaused
    {
        require(_userBids[_nft][_msgSender()][_tokenId] > 0, 'Only Bidder can update the bid price');
        require(_price != 0, 'Price must be granter than zero');
        address _bidder = address(_msgSender()); // find bid and the index
        (BidEntry memory bidEntry, uint256 _index) = getBidByBidInfo(_nft, _tokenId, _bidder, _quantity, _price, _quote);
        require(bidEntry.price != 0, 'Bidder does not exist');
        require(bidEntry.price != _newPrice, 'The bid price cannot be the same');

        if (_newPrice > bidEntry.price) {
            require(msg.value >= _newPrice.sub(bidEntry.price));
        } else {
            TransferHelper.safeTransferETH(_bidder, bidEntry.price.sub(_newPrice));
        }

        bytes32 _ix = keccak256(abi.encodePacked(_bidder, _quantity, _price, _quote));
        _userBids[_nft][_bidder][_tokenId] = _newPrice;
        _tokenBids[_nft][_tokenId][_ix][_index] = BidEntry({
        nftType: bidEntry.nftType,
        bidder: bidEntry.bidder,
        quantity: bidEntry.quantity,
        price: _newPrice,
        quote: bidEntry.quote
        });
        emit Bid(_msgSender(), _nft, _tokenId, _quantity, _newPrice, _quote);
    }
}