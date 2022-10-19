// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./dependencies/openzeppelin/security/ReentrancyGuard.sol";
import "./lib/WadRayMath.sol";
import "./storage/PoolRegistryStorage.sol";
import "./interfaces/IPool.sol";
import "./utils/Pauseable.sol";

/**
 * @title PoolRegistry contract
 */
contract PoolRegistry is ReentrancyGuard, Pauseable, PoolRegistryStorageV1 {
    using WadRayMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    string public constant VERSION = "1.0.0";

    /// @notice Emitted when fee collector is updated
    event FeeCollectorUpdated(address indexed oldFeeCollector, address indexed newFeeCollector);

    /// @notice Emitted when master oracle contract is updated
    event MasterOracleUpdated(IMasterOracle indexed oldOracle, IMasterOracle indexed newOracle);

    /// @notice Emitted when a pool is registered
    event PoolRegistered(address pool);

    /// @notice Emitted when a pool is unregistered
    event PoolUnregistered(address pool);

    function initialize(IMasterOracle masterOracle_, address feeCollector_) external initializer {
        require(address(masterOracle_) != address(0), "oracle-is-null");
        require(feeCollector_ != address(0), "fee-collector-is-null");

        __ReentrancyGuard_init();
        __Pauseable_init();

        masterOracle = masterOracle_;
        feeCollector = feeCollector_;
    }

    /**
     * @notice Get all pools
     * @dev WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees.
     */
    function getPools() external view returns (address[] memory) {
        return pools.values();
    }

    /**
     * @notice Check if pool is registered
     * @param pool_ Pool to check
     * @return true if exists
     */
    function poolExists(address pool_) external view returns (bool) {
        return pools.contains(pool_);
    }

    /**
     * @notice Register pool
     */
    function registerPool(address pool_) external onlyGovernor {
        require(pool_ != address(0), "address-is-null");
        require(pools.add(pool_), "already-registered");
        emit PoolRegistered(pool_);
    }

    /**
     * @notice Unregister pool
     */
    function unregisterPool(address pool_) external onlyGovernor {
        require(pools.remove(pool_), "not-registered");
        emit PoolUnregistered(pool_);
    }

    /**
     * @notice Update fee collector
     */
    function updateFeeCollector(address newFeeCollector_) external onlyGovernor {
        require(newFeeCollector_ != address(0), "fee-collector-is-null");
        address _currentFeeCollector = feeCollector;
        require(newFeeCollector_ != _currentFeeCollector, "new-same-as-current");
        emit FeeCollectorUpdated(_currentFeeCollector, newFeeCollector_);
        feeCollector = newFeeCollector_;
    }

    /**
     * @notice Update master oracle contract
     */
    function updateMasterOracle(IMasterOracle newMasterOracle_) external override onlyGovernor {
        require(address(newMasterOracle_) != address(0), "address-is-null");
        IMasterOracle _currentMasterOracle = masterOracle;
        require(newMasterOracle_ != _currentMasterOracle, "new-same-as-current");
        emit MasterOracleUpdated(_currentMasterOracle, newMasterOracle_);
        masterOracle = newMasterOracle_;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../dependencies/openzeppelin/proxy/utils/Initializable.sol";
import "../utils/TokenHolder.sol";
import "../interfaces/IGovernable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (governor) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the governor account will be the one that deploys the contract. This
 * can later be changed with {transferGovernorship}.
 *
 */
abstract contract Governable is IGovernable, TokenHolder, Initializable {
    address public governor;
    address public proposedGovernor;

    event UpdatedGovernor(address indexed previousGovernor, address indexed proposedGovernor);

    /**
     * @dev Initializes the contract setting the deployer as the initial governor.
     */
    constructor() {
        governor = msg.sender;
        emit UpdatedGovernor(address(0), msg.sender);
    }

    /**
     * @dev If inheriting child is using proxy then child contract can use
     * __Governable_init() function to initialization this contract
     */
    // solhint-disable-next-line func-name-mixedcase
    function __Governable_init() internal initializer {
        governor = msg.sender;
        emit UpdatedGovernor(address(0), msg.sender);
    }

    /**
     * @dev Throws if called by any account other than the governor.
     */
    modifier onlyGovernor() {
        require(governor == msg.sender, "not-governor");
        _;
    }

    function _requireCanSweep() internal view override onlyGovernor {}

    /**
     * @dev Transfers governorship of the contract to a new account (`proposedGovernor`).
     * Can only be called by the current owner.
     */
    function transferGovernorship(address proposedGovernor_) external onlyGovernor {
        require(proposedGovernor_ != address(0), "proposed-governor-is-zero");
        proposedGovernor = proposedGovernor_;
    }

    /**
     * @dev Allows new governor to accept governorship of the contract.
     */
    function acceptGovernorship() external {
        address _proposedGovernor = proposedGovernor;
        require(_proposedGovernor == msg.sender, "not-the-proposed-governor");
        emit UpdatedGovernor(governor, _proposedGovernor);
        governor = _proposedGovernor;
        proposedGovernor = address(0);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
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
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

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
}

// SPDX-License-Identifier: MIT

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
abstract contract ReentrancyGuard is Initializable {
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

    function __ReentrancyGuard_init() internal initializer {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
    function transferFrom(
        address sender,
        address recipient,
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

pragma solidity ^0.8.0;

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
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../dependencies/openzeppelin/token/ERC20/extensions/IERC20Metadata.sol";
import "./ISyntheticToken.sol";

interface IDebtToken is IERC20Metadata {
    function isActive() external view returns (bool);

    function syntheticToken() external view returns (ISyntheticToken);

    function accrueInterest() external;

    function debtIndex() external returns (uint256 debtIndex_);

    function burn(address from_, uint256 amount_) external;

    function issue(uint256 amount_, address to_) external;

    function repay(address onBehalfOf_, uint256 amount_) external;

    function updateMaxTotalSupply(uint256 newMaxTotalSupply_) external;

    function updateInterestRate(uint256 newInterestRate_) external;

    function maxTotalSupply() external view returns (uint256);

    function interestRate() external view returns (uint256);

    function interestRatePerSecond() external view returns (uint256);

    function toggleIsActive() external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../dependencies/openzeppelin/token/ERC20/extensions/IERC20Metadata.sol";

interface IDepositToken is IERC20Metadata {
    function underlying() external view returns (IERC20);

    function collateralizationRatio() external view returns (uint256);

    function unlockedBalanceOf(address account_) external view returns (uint256);

    function lockedBalanceOf(address account_) external view returns (uint256);

    function deposit(uint256 amount_, address onBehalfOf_) external;

    function withdraw(uint256 amount_, address to_) external;

    function seize(
        address from_,
        address to_,
        uint256 amount_
    ) external;

    function updateCollateralizationRatio(uint128 newCollateralizationRatio_) external;

    function isActive() external view returns (bool);

    function toggleIsActive() external;

    function maxTotalSupply() external view returns (uint256);

    function updateMaxTotalSupply(uint256 newMaxTotalSupply_) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

/**
 * @notice Governable interface
 */
interface IGovernable {
    function governor() external view returns (address _governor);

    function transferGovernorship(address _proposedGovernor) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IPauseable {
    function paused() external view returns (bool);

    function everythingStopped() external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./IDepositToken.sol";
import "./ITreasury.sol";
import "./IRewardsDistributor.sol";
import "./IPoolRegistry.sol";

/**
 * @notice Pool interface
 */
interface IPool is IPauseable {
    function debtFloorInUsd() external returns (uint256);

    function depositFee() external returns (uint256);

    function issueFee() external returns (uint256);

    function withdrawFee() external returns (uint256);

    function repayFee() external returns (uint256);

    function feeCollector() external view returns (address);

    function isSyntheticTokenExists(ISyntheticToken syntheticToken_) external view returns (bool);

    function isDebtTokenExists(IDebtToken debtToken_) external view returns (bool);

    function isDepositTokenExists(IDepositToken depositToken_) external view returns (bool);

    function depositTokenOf(IERC20 underlying_) external view returns (IDepositToken);

    function debtTokenOf(ISyntheticToken syntheticToken_) external view returns (IDebtToken);

    function getDepositTokens() external view returns (address[] memory);

    function getDebtTokens() external view returns (address[] memory);

    function getRewardsDistributors() external view returns (IRewardsDistributor[] memory);

    function debtOf(address account_) external view returns (uint256 _debtInUsd);

    function depositOf(address account_) external view returns (uint256 _depositInUsd, uint256 _issuableLimitInUsd);

    function debtPositionOf(address account_)
        external
        view
        returns (
            bool _isHealthy,
            uint256 _depositInUsd,
            uint256 _debtInUsd,
            uint256 _issuableLimitInUsd,
            uint256 _issuableInUsd
        );

    function addDebtToken(IDebtToken debtToken_) external;

    function removeDebtToken(IDebtToken debtToken_) external;

    function addDepositToken(address depositToken_) external;

    function removeDepositToken(IDepositToken depositToken_) external;

    function liquidate(
        ISyntheticToken syntheticToken_,
        address account_,
        uint256 amountToRepay_,
        IDepositToken depositToken_
    ) external;

    function swap(
        ISyntheticToken syntheticTokenIn_,
        ISyntheticToken syntheticTokenOut_,
        uint256 amountIn_
    ) external returns (uint256 _amountOut);

    function updateSwapFee(uint256 newSwapFee_) external;

    function updateDebtFloor(uint256 newDebtFloorInUsd_) external;

    function updateDepositFee(uint256 newDepositFee_) external;

    function updateIssueFee(uint256 newIssueFee_) external;

    function updateWithdrawFee(uint256 newWithdrawFee_) external;

    function updateRepayFee(uint256 newRepayFee_) external;

    function updateLiquidatorLiquidationFee(uint128 newLiquidatorLiquidationFee_) external;

    function updateProtocolLiquidationFee(uint128 newProtocolLiquidationFee_) external;

    function updateMaxLiquidable(uint256 newMaxLiquidable_) external;

    function updateTreasury(ITreasury newTreasury_) external;

    function treasury() external view returns (ITreasury);

    function masterOracle() external view returns (IMasterOracle);

    function poolRegistry() external view returns (IPoolRegistry);

    function addToDepositTokensOfAccount(address account_) external;

    function removeFromDepositTokensOfAccount(address account_) external;

    function addToDebtTokensOfAccount(address account_) external;

    function removeFromDebtTokensOfAccount(address account_) external;

    function getDepositTokensOfAccount(address account_) external view returns (address[] memory);

    function getDebtTokensOfAccount(address account_) external view returns (address[] memory);

    function addRewardsDistributor(IRewardsDistributor distributor_) external;

    function toggleIsSwapActive() external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./external/IMasterOracle.sol";
import "./IPauseable.sol";
import "./IGovernable.sol";
import "./ISyntheticToken.sol";

interface IPoolRegistry is IPauseable, IGovernable {
    function poolExists(address pool_) external view returns (bool);

    function feeCollector() external view returns (address);

    function getPools() external view returns (address[] memory);

    function registerPool(address pool_) external;

    function unregisterPool(address pool_) external;

    function masterOracle() external view returns (IMasterOracle);

    function updateMasterOracle(IMasterOracle newOracle_) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../dependencies/openzeppelin/token/ERC20/IERC20.sol";

/**
 * @notice Reward Distributor interface
 */
interface IRewardsDistributor {
    function rewardToken() external view returns (IERC20);

    function tokenSpeeds(IERC20 token_) external view returns (uint256);

    function tokensAccruedOf(address account_) external view returns (uint256);

    function updateBeforeMintOrBurn(IERC20 token_, address account_) external;

    function updateBeforeTransfer(
        IERC20 token_,
        address from_,
        address to_
    ) external;

    function claimRewards(address account_) external;

    function claimRewards(address account_, IERC20[] memory tokens_) external;

    function claimRewards(address[] memory accounts_, IERC20[] memory tokens_) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../dependencies/openzeppelin/token/ERC20/extensions/IERC20Metadata.sol";
import "./IDebtToken.sol";

interface ISyntheticToken is IERC20Metadata {
    function isActive() external view returns (bool);

    function mint(address to_, uint256 amount_) external;

    function burn(address from_, uint256 amount) external;

    function toggleIsActive() external;

    function seize(
        address from_,
        address to_,
        uint256 amount_
    ) external;

    function updateMaxTotalSupply(uint256 newMaxTotalSupply_) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface ITreasury {
    function pull(address to_, uint256 amount_) external;

    function migrateTo(address newTreasury_) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IMasterOracle {
    function quoteTokenToUsd(address _asset, uint256 _amount) external view returns (uint256 _amountInUsd);

    function quoteUsdToToken(address _asset, uint256 _amountInUsd) external view returns (uint256 _amount);

    function quote(
        address _assetIn,
        address _assetOut,
        uint256 _amountIn
    ) external view returns (uint256 _amountOut);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

/**
 * @title Math library
 * @dev Provides mul and div function for wads (decimal numbers with 18 digits precision) and rays (decimals with 27 digits)
 * @dev Based on https://github.com/dapphub/ds-math/blob/master/src/math.sol
 */
library WadRayMath {
    uint256 internal constant WAD = 1e18;
    uint256 internal constant HALF_WAD = WAD / 2;

    uint256 internal constant RAY = 1e27;
    uint256 internal constant HALF_RAY = RAY / 2;

    uint256 internal constant WAD_RAY_RATIO = 1e9;

    /**
     * @dev Multiplies two wad, rounding half up to the nearest wad
     * @param a Wad
     * @param b Wad
     * @return The result of a*b, in wad
     */
    function wadMul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0 || b == 0) {
            return 0;
        }

        return (a * b + HALF_WAD) / WAD;
    }

    /**
     * @dev Divides two wad, rounding half up to the nearest wad
     * @param a Wad
     * @param b Wad
     * @return The result of a/b, in wad
     */
    function wadDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a * WAD + b / 2) / b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../dependencies/openzeppelin/utils/structs/EnumerableSet.sol";
import "../interfaces/IPoolRegistry.sol";
import "../interfaces/external/IMasterOracle.sol";

abstract contract PoolRegistryStorageV1 is IPoolRegistry {
    /**
     * @notice Pools collection
     */
    EnumerableSet.AddressSet internal pools;

    /**
     * @notice Prices oracle
     */
    IMasterOracle public masterOracle;

    /**
     * @notice Fee collector address
     */
    address public feeCollector;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../interfaces/IPauseable.sol";
import "../access/Governable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 */
abstract contract Pauseable is IPauseable, Governable {
    /// @notice Emitted when contract is turned on
    event Open(address caller);

    /// @notice Emitted when contract is paused
    event Paused(address caller);

    /// @notice Emitted when contract is shuted down
    event Shutdown(address caller);

    /// @notice Emitted when contract is unpaused
    event Unpaused(address caller);

    bool private _paused;
    bool private _everythingStopped;

    /**
     * @dev Throws if contract is paused
     */
    modifier whenNotPaused() {
        require(!paused(), "paused");
        _;
    }

    /**
     * @dev Throws if contract is shutdown
     */
    modifier whenNotShutdown() {
        require(!everythingStopped(), "shutdown");
        _;
    }

    /**
     * @dev Throws if contract is not paused
     */
    modifier whenPaused() {
        require(paused(), "not-paused");
        _;
    }

    /**
     * @dev Throws if contract is not shutdown
     */
    modifier whenShutdown() {
        require(everythingStopped(), "not-shutdown");
        _;
    }

    /**
     * @dev If inheriting child is using proxy then child contract can use
     * __Pauseable_init() function to initialization this contract
     */
    // solhint-disable-next-line func-name-mixedcase
    function __Pauseable_init() internal initializer {
        __Governable_init();
    }

    /**
     * @notice Return `true` if contract is shutdown
     */
    function everythingStopped() public view virtual returns (bool) {
        return _everythingStopped;
    }

    /**
     * @notice Return `true` if contract is paused
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Open contract operations, if contract is in shutdown state
     */
    function open() external virtual whenShutdown onlyGovernor {
        _everythingStopped = false;
        emit Open(msg.sender);
    }

    /**
     * @dev Pause contract operations, if contract is not paused.
     */
    function pause() external virtual whenNotPaused onlyGovernor {
        _paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev Shutdown contract operations, if not already shutdown.
     */
    function shutdown() external virtual whenNotShutdown onlyGovernor {
        _everythingStopped = true;
        _paused = true;
        emit Shutdown(msg.sender);
    }

    /**
     * @dev Unpause contract operations, allow only if contract is paused and not shutdown.
     */
    function unpause() external virtual whenPaused whenNotShutdown onlyGovernor {
        _paused = false;
        emit Unpaused(msg.sender);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../dependencies/openzeppelin/token/ERC20/utils/SafeERC20.sol";

/**
 * @title Utils contract that handles tokens sent to it
 */
abstract contract TokenHolder {
    using SafeERC20 for IERC20;

    /**
     * @dev Revert fallback calls
     */
    fallback() external payable {
        revert("fallback-not-allowed");
    }

    /**
     * @dev Revert when receiving by default
     */
    receive() external payable virtual {
        revert("receive-not-allowed");
    }

    /**
     * @notice ERC20 recovery in case of stuck tokens due direct transfers to the contract address.
     * @param token_ The token to transfer
     * @param to_ The recipient of the transfer
     * @param amount_ The amount to send
     */
    function sweep(
        IERC20 token_,
        address to_,
        uint256 amount_
    ) external {
        _requireCanSweep();

        if (address(token_) == address(0)) {
            Address.sendValue(payable(to_), amount_);
        } else {
            token_.safeTransfer(to_, amount_);
        }
    }

    /**
     * @notice Function that reverts if the caller isn't allowed to sweep tokens
     */
    function _requireCanSweep() internal view virtual;
}