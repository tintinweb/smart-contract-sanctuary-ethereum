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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

import {
    EnumerableSet
} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {Gelatofied} from "./vendor/gelato/Gelatofied.sol";
import {GelatoBytes} from "./vendor/gelato/GelatoBytes.sol";
import {Proxied} from "./vendor/proxy/EIP173/Proxied.sol";
import {OpsStorage} from "./OpsStorage.sol";
import {LibDataTypes} from "./libraries/LibDataTypes.sol";
import {LibEvents} from "./libraries/LibEvents.sol";
import {LibLegacyTask} from "./libraries/LibLegacyTask.sol";
import {LibTaskId} from "./libraries/LibTaskId.sol";
import {LibTaskModule} from "./libraries/LibTaskModule.sol";
import {
    ITaskTreasuryUpgradable
} from "./interfaces/ITaskTreasuryUpgradable.sol";
import {IOps} from "./interfaces/IOps.sol";

/**
 * @notice Ops enables everyone to have Gelato monitor and execute transactions.
 * @notice ExecAddress refers to the contract that has the function which Gelato will call.
 * @notice Modules allow users to customise conditions and specifications when creating a task.
 */
contract Ops is Gelatofied, Proxied, OpsStorage, IOps {
    using GelatoBytes for bytes;
    using EnumerableSet for EnumerableSet.Bytes32Set;

    // solhint-disable const-name-snakecase
    string public constant version = "5";
    ITaskTreasuryUpgradable public immutable override taskTreasury;

    constructor(address payable _gelato, ITaskTreasuryUpgradable _taskTreasury)
        Gelatofied(_gelato)
    {
        taskTreasury = _taskTreasury;
    }

    // prettier-ignore
    fallback(bytes calldata _callData) external returns(bytes memory returnData){
        returnData = _handleLegacyTaskCreation(_callData);
    }

    ///@inheritdoc IOps
    function createTask(
        address _execAddress,
        bytes calldata _execDataOrSelector,
        LibDataTypes.ModuleData calldata _moduleData,
        address _feeToken
    ) external override returns (bytes32 taskId) {
        address taskCreator;

        (taskCreator, _execAddress) = LibTaskModule.preCreateTask(
            msg.sender,
            _execAddress,
            taskModuleAddresses
        );

        taskId = _createTask(
            taskCreator,
            _execAddress,
            _execDataOrSelector,
            _moduleData,
            _feeToken
        );
    }

    ///@inheritdoc IOps
    function cancelTask(bytes32 _taskId) external {
        address _taskCreator = LibTaskModule.preCancelTask(
            _taskId,
            msg.sender,
            taskModuleAddresses
        );

        _cancelTask(_taskCreator, _taskId);
    }

    ///@inheritdoc IOps
    function exec(
        address _taskCreator,
        address _execAddress,
        bytes memory _execData,
        LibDataTypes.ModuleData calldata _moduleData,
        uint256 _txFee,
        address _feeToken,
        bool _useTaskTreasuryFunds,
        bool _revertOnFailure
    ) external onlyGelato {
        bytes32 taskId = LibTaskId.getTaskId(
            _taskCreator,
            _execAddress,
            _execData.memorySliceSelector(),
            _moduleData,
            _useTaskTreasuryFunds ? address(0) : _feeToken
        );

        _exec(
            taskId,
            _taskCreator,
            _execAddress,
            _execData,
            _moduleData.modules,
            _txFee,
            _feeToken,
            _useTaskTreasuryFunds,
            _revertOnFailure
        );
    }

    ///@inheritdoc IOps
    function setModule(
        LibDataTypes.Module[] calldata _modules,
        address[] calldata _moduleAddresses
    ) external onlyProxyAdmin {
        uint256 length = _modules.length;
        for (uint256 i; i < length; i++) {
            taskModuleAddresses[_modules[i]] = _moduleAddresses[i];
        }
    }

    ///@inheritdoc IOps
    function getFeeDetails() external view returns (uint256, address) {
        return (fee, feeToken);
    }

    ///@inheritdoc IOps
    function getTaskIdsByUser(address _taskCreator)
        external
        view
        returns (bytes32[] memory)
    {
        bytes32[] memory taskIds = _createdTasks[_taskCreator].values();

        return taskIds;
    }

    ///@inheritdoc IOps
    function getTaskId(
        address taskCreator,
        address execAddress,
        bytes4 execSelector,
        LibDataTypes.ModuleData memory moduleData,
        address feeToken
    ) external pure returns (bytes32 taskId) {
        taskId = LibTaskId.getTaskId(
            taskCreator,
            execAddress,
            execSelector,
            moduleData,
            feeToken
        );
    }

    ///@inheritdoc IOps
    function getTaskId(
        address taskCreator,
        address execAddress,
        bytes4 execSelector,
        bool useTaskTreasuryFunds,
        address feeToken,
        bytes32 resolverHash
    ) external pure returns (bytes32 taskId) {
        taskId = LibTaskId.getLegacyTaskId(
            taskCreator,
            execAddress,
            execSelector,
            useTaskTreasuryFunds,
            feeToken,
            resolverHash
        );
    }

    function _createTask(
        address _taskCreator,
        address _execAddress,
        bytes memory _execDataOrSelector,
        LibDataTypes.ModuleData memory _moduleData,
        address _feeToken
    ) private returns (bytes32 taskId) {
        taskId = LibTaskId.getTaskId(
            _taskCreator,
            _execAddress,
            _execDataOrSelector.memorySliceSelector(),
            _moduleData,
            _feeToken
        );

        require(
            !_createdTasks[_taskCreator].contains(taskId),
            "Ops.createTask: Duplicate task"
        );

        LibTaskModule.onCreateTask(
            taskId,
            _taskCreator,
            _execAddress,
            _execDataOrSelector,
            _moduleData,
            taskModuleAddresses
        );

        _createdTasks[_taskCreator].add(taskId);

        emit LibEvents.TaskCreated(
            _taskCreator,
            _execAddress,
            _execDataOrSelector,
            _moduleData,
            _feeToken,
            taskId
        );
    }

    function _cancelTask(address _taskCreator, bytes32 _taskId) private {
        require(
            _createdTasks[_taskCreator].contains(_taskId),
            "Ops.cancelTask: Task not found"
        );

        _createdTasks[_taskCreator].remove(_taskId);

        emit LibEvents.TaskCancelled(_taskId, _taskCreator);
    }

    // solhint-disable function-max-lines
    function _exec(
        bytes32 _taskId,
        address _taskCreator,
        address _execAddress,
        bytes memory _execData,
        LibDataTypes.Module[] memory _modules,
        uint256 _txFee,
        address _feeToken,
        bool _useTaskTreasuryFunds,
        bool _revertOnFailure
    ) private {
        require(
            _createdTasks[_taskCreator].contains(_taskId),
            "Ops.exec: Task not found"
        );

        if (!_useTaskTreasuryFunds) {
            fee = _txFee;
            feeToken = _feeToken;
        }

        bool success = LibTaskModule.onExecTask(
            _taskId,
            _taskCreator,
            _execAddress,
            _execData,
            _modules,
            _revertOnFailure,
            taskModuleAddresses
        );

        if (_useTaskTreasuryFunds) {
            taskTreasury.useFunds(_taskCreator, _feeToken, _txFee);
        } else {
            delete fee;
            delete feeToken;
        }

        emit LibEvents.ExecSuccess(
            _txFee,
            _feeToken,
            _execAddress,
            _execData,
            _taskId,
            success
        );
    }

    function _handleLegacyTaskCreation(bytes calldata _callData)
        private
        returns (bytes memory returnData)
    {
        bytes4 funcSig = _callData.calldataSliceSelector();

        (
            address execAddress,
            bytes memory execData,
            LibDataTypes.ModuleData memory moduleData,
            address feeToken_
        ) = LibLegacyTask.getCreateTaskArg(funcSig, _callData);

        bytes32 taskId = _createTask(
            msg.sender,
            execAddress,
            execData,
            moduleData,
            feeToken_
        );

        returnData = abi.encodePacked(taskId);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;
import {
    EnumerableSet
} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {LibDataTypes} from "./libraries/LibDataTypes.sol";

/**
 * @notice Storage layout of Ops smart contract.
 */
// solhint-disable max-states-count
abstract contract OpsStorage {
    mapping(bytes32 => address) public taskCreator; ///@dev Deprecated
    mapping(bytes32 => address) public execAddresses; ///@dev Deprecated
    mapping(address => EnumerableSet.Bytes32Set) internal _createdTasks;

    uint256 public fee;
    address public feeToken;

    ///@dev Appended State
    mapping(bytes32 => LibDataTypes.Time) public timedTask;
    mapping(LibDataTypes.Module => address) public taskModuleAddresses;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {GelatoBytes} from "../vendor/gelato/GelatoBytes.sol";

// solhint-disable private-vars-leading-underscore
// solhint-disable func-visibility

function _call(
    address _add,
    bytes memory _data,
    uint256 _value,
    bool _revertOnFailure,
    string memory _tracingInfo
) returns (bool success, bytes memory returnData) {
    (success, returnData) = _add.call{value: _value}(_data);

    if (!success && _revertOnFailure)
        GelatoBytes.revertWithError(returnData, _tracingInfo);
}

function _delegateCall(
    address _add,
    bytes memory _data,
    string memory _tracingInfo
) returns (bool success, bytes memory returnData) {
    (success, returnData) = _add.delegatecall(_data);

    if (!success) GelatoBytes.revertWithError(returnData, _tracingInfo);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

import {
    SafeERC20,
    IERC20
} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

address constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

// solhint-disable private-vars-leading-underscore
// solhint-disable func-visibility
function _transfer(
    address payable _to,
    address _paymentToken,
    uint256 _amount
) {
    if (_paymentToken == ETH) {
        (bool success, ) = _to.call{value: _amount}("");
        require(success, "_transfer: ETH transfer failed");
    } else {
        SafeERC20.safeTransfer(IERC20(_paymentToken), _to, _amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ITaskTreasuryUpgradable} from "./ITaskTreasuryUpgradable.sol";

/**
 * @notice Legacy Ops interface with individual create task function for each task type.
 * @notice These function signatures are still supported via fallback. {See Ops.sol-fallback}
 */
interface ILegacyOps {
    function createTask(
        address _execAddress,
        bytes4 _execSelector,
        address _resolverAddress,
        bytes calldata _resolverData
    ) external returns (bytes32 taskId);

    function createTaskNoPrepayment(
        address _execAddress,
        bytes4 _execSelector,
        address _resolverAddress,
        bytes calldata _resolverData,
        address _feeToken
    ) external returns (bytes32 taskId);

    function createTimedTask(
        uint128 _startTime,
        uint128 _interval,
        address _execAddress,
        bytes4 _execSelector,
        address _resolverAddress,
        bytes calldata _resolverData,
        address _feeToken,
        bool _useTreasury
    ) external returns (bytes32 taskId);

    function cancelTask(bytes32 _taskId) external;

    function exec(
        uint256 _txFee,
        address _feeToken,
        address _taskCreator,
        bool _useTaskTreasuryFunds,
        bool _revertOnFailure,
        bytes32 _resolverHash,
        address _execAddress,
        bytes calldata _execData
    ) external;

    function getFeeDetails() external view returns (uint256, address);

    function getTaskIdsByUser(address _taskCreator)
        external
        view
        returns (bytes32[] memory);

    function taskTreasury() external view returns (ITaskTreasuryUpgradable);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {LibDataTypes} from "../libraries/LibDataTypes.sol";
import {ITaskTreasuryUpgradable} from "./ITaskTreasuryUpgradable.sol";

// solhint-disable max-line-length
interface IOps {
    /**
     * @notice Initiates a task with conditions which Gelato will monitor and execute when conditions are met.
     *
     * @param execAddress Address of contract that should be called by Gelato.
     * @param execData Execution data to be called with / function selector if execution data is yet to be determined.
     * @param moduleData Conditional modules that will be used. {See LibDataTypes-ModuleData}
     * @param feeToken Address of token to be used as payment. Use address(0) if TaskTreasury is being used, 0xeeeeee... for ETH or native tokens.
     *
     * @return taskId Unique hash of the task created.
     */
    function createTask(
        address execAddress,
        bytes calldata execData,
        LibDataTypes.ModuleData calldata moduleData,
        address feeToken
    ) external returns (bytes32 taskId);

    /**
     * @notice Terminates a task that was created and Gelato can no longer execute it.
     *
     * @param taskId Unique hash of the task that is being cancelled. {See LibTaskId-getTaskId}
     */
    function cancelTask(bytes32 taskId) external;

    /**
     * @notice Execution API called by Gelato.
     *
     * @param taskCreator The address which created the task.
     * @param execAddress Address of contract that should be called by Gelato.
     * @param execData Execution data to be called with / function selector if execution data is yet to be determined.
     * @param moduleData Conditional modules that will be used. {See LibDataTypes-ModuleData}
     * @param txFee Fee paid to Gelato for execution, deducted on the TaskTreasury or transfered to Gelato.
     * @param feeToken Token used to pay for the execution. ETH = 0xeeeeee...
     * @param useTaskTreasuryFunds If taskCreator's balance on TaskTreasury should pay for the tx.
     * @param revertOnFailure To revert or not if call to execAddress fails. (Used for off-chain simulations)
     */
    function exec(
        address taskCreator,
        address execAddress,
        bytes memory execData,
        LibDataTypes.ModuleData calldata moduleData,
        uint256 txFee,
        address feeToken,
        bool useTaskTreasuryFunds,
        bool revertOnFailure
    ) external;

    /**
     * @notice Sets the address of task modules. Only callable by proxy admin.
     *
     * @param modules List of modules to be set
     * @param moduleAddresses List of addresses for respective modules.
     */
    function setModule(
        LibDataTypes.Module[] calldata modules,
        address[] calldata moduleAddresses
    ) external;

    /**
     * @notice Helper function to query fee and feeToken to be used for payment. (For executions which pays itself)
     *
     * @return uint256 Fee amount to be paid.
     * @return address Token to be paid. (Determined and passed by taskCreator during createTask)
     */
    function getFeeDetails() external view returns (uint256, address);

    /**
     * @notice Helper func to query all open tasks by a task creator.
     *
     * @param taskCreator Address of task creator to query.
     *
     * @return bytes32[] List of taskIds created.
     */
    function getTaskIdsByUser(address taskCreator)
        external
        view
        returns (bytes32[] memory);

    /**
     * @notice Helper function to compute task id with module arguments
     *
     * @param taskCreator The address which created the task.
     * @param execAddress Address of contract that will be called by Gelato.
     * @param execSelector Signature of the function which will be called by Gelato.
     * @param moduleData  Conditional modules that will be used. {See LibDataTypes-ModuleData}
     * @param feeToken Address of token to be used as payment. Use address(0) if TaskTreasury is being used, 0xeeeeee... for ETH or native tokens.
     */
    function getTaskId(
        address taskCreator,
        address execAddress,
        bytes4 execSelector,
        LibDataTypes.ModuleData memory moduleData,
        address feeToken
    ) external pure returns (bytes32 taskId);

    /**
     * @notice (Legacy) Helper function to compute task id.
     *
     * @param taskCreator The address which created the task.
     * @param execAddress Address of contract that will be called by Gelato.
     * @param execSelector Signature of the function which will be called by Gelato.
     * @param useTaskTreasuryFunds Wether fee should be deducted from TaskTreasury.
     * @param feeToken Address of token to be used as payment. Use address(0) if TaskTreasury is being used, 0xeeeeee... for ETH or native tokens.
     * @param resolverHash Hash of resolverAddress and resolverData {See getResolverHash}
     */
    function getTaskId(
        address taskCreator,
        address execAddress,
        bytes4 execSelector,
        bool useTaskTreasuryFunds,
        address feeToken,
        bytes32 resolverHash
    ) external pure returns (bytes32);

    /**
     * @notice TaskTreasury contract where user deposit funds to be used for fee payments.
     *
     * @return ITaskTreasuryUpgradable TaskTreasury contract interface
     */
    function taskTreasury() external view returns (ITaskTreasuryUpgradable);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

// solhint-disable max-line-length
interface ITaskModule {
    /**
     * @notice Called before generating taskId.
     * @dev Modules can override execAddress or taskCreator. {See ProxyModule-preCreateTask}
     *
     * @param taskCreator The address which created the task.
     * @param execAddress Address of contract that should be called.
     *
     * @return address Overriden or original taskCreator.
     * @return address Overriden or original execAddress.
     */
    function preCreateTask(address taskCreator, address execAddress)
        external
        returns (address, address);

    /**
     * @notice Initiates task module whenever `createTask` is being called.
     *
     * @param taskId Unique hash of the task created.
     * @param taskCreator The address which created the task.
     * @param execAddress Address of contract that should be called.
     * @param execData Execution data to be called with / function selector if execution data is yet to be determined.
     * @param initModuleArg Encoded arguments for module if any.
     */
    function onCreateTask(
        bytes32 taskId,
        address taskCreator,
        address execAddress,
        bytes calldata execData,
        bytes calldata initModuleArg
    ) external;

    /**
     * @notice Called before taskId is removed from _createdTasks[].
     * @dev Modules can override taskCreator.
     *
     * @param taskId Unique hash of the task created.
     * @param taskCreator The address which created the task.
     *
     * @return address Overriden or original taskCreator.
     */
    function preCancelTask(bytes32 taskId, address taskCreator)
        external
        returns (address);

    /**
     * @notice Called during `exec` and before execAddress is called.
     *
     * @param taskId Unique hash of the task created.
     * @param taskCreator The address which created the task.
     * @param execAddress Address of contract that should be called.
     * @param execData Execution data to be called with / function selector if execution data is yet to be determined.
     *
     * @return address Overriden or original execution address.
     * @return bytes Overriden or original execution data.
     */
    function preExecCall(
        bytes32 taskId,
        address taskCreator,
        address execAddress,
        bytes calldata execData
    ) external returns (address, bytes memory);

    /**
     * @notice Called during `exec` and after execAddress is called.
     *
     * @param taskId Unique hash of the task created.
     * @param taskCreator The address which created the task.
     * @param execAddress Address of contract that should be called.
     * @param execData Execution data to be called with / function selector if execution data is yet to be determined.
     */
    function postExecCall(
        bytes32 taskId,
        address taskCreator,
        address execAddress,
        bytes calldata execData
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITaskTreasuryUpgradable {
    /// @notice Events ///

    event FundsDeposited(
        address indexed sender,
        address indexed token,
        uint256 indexed amount
    );

    event FundsWithdrawn(
        address indexed receiver,
        address indexed initiator,
        address indexed token,
        uint256 amount
    );

    event LogDeductFees(
        address indexed user,
        address indexed executor,
        address indexed token,
        uint256 fees,
        address service
    );

    event UpdatedService(address indexed service, bool add);

    event UpdatedMaxFee(uint256 indexed maxFee);

    /// @notice External functions ///

    function depositFunds(
        address receiver,
        address token,
        uint256 amount
    ) external payable;

    function withdrawFunds(
        address payable receiver,
        address token,
        uint256 amount
    ) external;

    function useFunds(
        address user,
        address token,
        uint256 amount
    ) external;

    function updateMaxFee(uint256 _newMaxFee) external;

    function updateWhitelistedService(address service, bool isWhitelist)
        external;

    /// @notice External view functions ///

    function getCreditTokensByUser(address user)
        external
        view
        returns (address[] memory);

    function getTotalCreditTokensByUser(address user)
        external
        view
        returns (address[] memory);

    function getWhitelistedServices() external view returns (address[] memory);

    function totalUserTokenBalance(address user, address token)
        external
        view
        returns (uint256);

    function userTokenBalance(address user, address token)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

// solhint-disable max-line-length
library LibDataTypes {
    /**
     * @notice Whitelisted modules that are available for users to customise conditions and specifications of their tasks.
     *
     * @param RESOLVER Use dynamic condition & input data for execution. {See ResolverModule.sol}
     * @param TIME Repeated execution of task at a specified timing and interval. {See TimeModule.sol}
     * @param PROXY Creates a dedicated caller (msg.sender) to be used when executing the task. {See ProxyModule.sol}
     * @param SINGLE_EXEC Task is cancelled after one execution. {See SingleExecModule.sol}
     */
    enum Module {
        RESOLVER,
        TIME,
        PROXY,
        SINGLE_EXEC
    }

    /**
     * @notice Struct to contain modules and their relative arguments that are used for task creation.
     *
     * @param modules List of selected modules.
     * @param args Arguments of modules if any. Pass "0x" for modules which does not require args {See encodeModuleArg}
     */
    struct ModuleData {
        Module[] modules;
        bytes[] args;
    }

    /**
     * @notice Struct for time module.
     *
     * @param nextExec Time when the next execution should occur.
     * @param interval Time interval between each execution.
     */
    struct Time {
        uint128 nextExec;
        uint128 interval;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import {LibDataTypes} from "./LibDataTypes.sol";

library LibEvents {
    /**
     * @notice Emitted when `createTask` is called.
     *
     * @param taskCreator The address which created the task.
     * @param execAddress Address of contract that is called by Gelato.
     * @param execDataOrSelector Execution data / function selector.
     * @param moduleData Conditional modules used. {See LibDataTypes-ModuleData}
     * @param feeToken Token used to pay for the execution. ETH = 0xeeeeee...
     * @param taskId Unique hash of the task. {See LibTaskId-getTaskId}
     */
    event TaskCreated(
        address indexed taskCreator,
        address indexed execAddress,
        bytes execDataOrSelector,
        LibDataTypes.ModuleData moduleData,
        address feeToken,
        bytes32 indexed taskId
    );

    /**
     * @notice Emitted when `cancelTask` is called.
     *
     * @param taskId Unique hash of the task. {See LibTaskId-getTaskId}
     * @param taskCreator The address which owned the task.
     */
    event TaskCancelled(bytes32 taskId, address taskCreator);

    /**
     * @notice Emitted when `exec` is called.
     *
     * @param txFee Fee paid to Gelato for execution
     * @param feeToken Token used to pay for the execution. ETH = 0xeeeeee...
     * @param execAddress Address of contract that will be called by Gelato.
     * @param execData Execution data / function selector.
     * @param taskId Unique hash of the task. {See LibTaskId-getTaskId}
     * @param callSuccess Status of the call to execAddress.
     */
    event ExecSuccess(
        uint256 indexed txFee,
        address indexed feeToken,
        address indexed execAddress,
        bytes execData,
        bytes32 taskId,
        bool callSuccess
    );

    /**
     * @notice Emitted when TimeModule is initialised.
     *
     * @param taskId Unique hash of the task. {See LibTaskId-getTaskId}
     * @param nextExec Time when the next execution will occur.
     * @param interval Time interval between each execution.
     */
    event TimerSet(
        bytes32 indexed taskId,
        uint128 indexed nextExec,
        uint128 indexed interval
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {LibDataTypes} from "./LibDataTypes.sol";
import {ILegacyOps} from "../interfaces/ILegacyOps.sol";

/**
 * @notice Library to keep task creation methods backwards compatible.
 * @notice Legacy create task methods can be found in ILegacyOps.sol
 */
library LibLegacyTask {
    /**
     * @notice Use legacy ops create task calldata to construct
     * arguments that conforms to current create task format.
     *
     * @param _funcSig Function signature of calldata.
     * @param _callData Calldata that was passed from fallback function.
     */
    function getCreateTaskArg(bytes4 _funcSig, bytes calldata _callData)
        internal
        pure
        returns (
            address execAddress,
            bytes memory execData,
            LibDataTypes.ModuleData memory moduleData,
            address feeToken
        )
    {
        if (_funcSig == ILegacyOps.createTask.selector) {
            (execAddress, execData, moduleData, feeToken) = _resolveCreateTask(
                _callData[4:]
            );
        } else if (_funcSig == ILegacyOps.createTaskNoPrepayment.selector) {
            (
                execAddress,
                execData,
                moduleData,
                feeToken
            ) = _resolveCreateTaskNoPrepayment(_callData[4:]);
        } else if (_funcSig == ILegacyOps.createTimedTask.selector) {
            (
                execAddress,
                execData,
                moduleData,
                feeToken
            ) = _resolveCreateTimedTask(_callData[4:]);
        } else revert("Ops.createTask: Function not found");
    }

    function _resolveCreateTask(bytes calldata _callDataSliced)
        private
        pure
        returns (
            address execAddress,
            bytes memory execData,
            LibDataTypes.ModuleData memory moduleData,
            address feeToken
        )
    {
        bytes4 execSelector;
        address resolverAddress;
        bytes memory resolverData;

        (execAddress, execSelector, resolverAddress, resolverData) = abi.decode(
            _callDataSliced,
            (address, bytes4, address, bytes)
        );

        LibDataTypes.Module[] memory modules = new LibDataTypes.Module[](1);
        modules[0] = LibDataTypes.Module.RESOLVER;

        bytes[] memory args = new bytes[](1);
        args[0] = abi.encode(resolverAddress, resolverData);

        moduleData = LibDataTypes.ModuleData(modules, args);

        execData = abi.encodePacked(execSelector);
        feeToken = address(0);
    }

    function _resolveCreateTaskNoPrepayment(bytes calldata _callDataSliced)
        private
        pure
        returns (
            address execAddress,
            bytes memory execData,
            LibDataTypes.ModuleData memory moduleData,
            address feeToken
        )
    {
        bytes4 execSelector;
        address resolverAddress;
        bytes memory resolverData;

        (
            execAddress,
            execSelector,
            resolverAddress,
            resolverData,
            feeToken
        ) = abi.decode(
            _callDataSliced,
            (address, bytes4, address, bytes, address)
        );

        LibDataTypes.Module[] memory modules = new LibDataTypes.Module[](1);
        modules[0] = LibDataTypes.Module.RESOLVER;

        bytes[] memory args = new bytes[](1);
        args[0] = abi.encode(resolverAddress, resolverData);

        moduleData = LibDataTypes.ModuleData(modules, args);

        execData = abi.encodePacked(execSelector);
    }

    function _resolveCreateTimedTask(bytes calldata _callDataSliced)
        private
        pure
        returns (
            address execAddress,
            bytes memory execData,
            LibDataTypes.ModuleData memory moduleData,
            address feeToken
        )
    {
        bytes memory resolverModuleArgs;
        bytes memory timeModuleArgs;
        (
            execAddress,
            execData,
            feeToken,
            resolverModuleArgs,
            timeModuleArgs
        ) = _decodeTimedTaskCallData(_callDataSliced);
        LibDataTypes.Module[] memory modules = new LibDataTypes.Module[](2);
        modules[0] = LibDataTypes.Module.RESOLVER;
        modules[1] = LibDataTypes.Module.TIME;

        bytes[] memory args = new bytes[](2);
        args[0] = resolverModuleArgs;
        args[1] = timeModuleArgs;

        moduleData = LibDataTypes.ModuleData(modules, args);
    }

    function _decodeTimedTaskCallData(bytes calldata _callDataSliced)
        private
        pure
        returns (
            address,
            bytes memory,
            address,
            bytes memory,
            bytes memory
        )
    {
        (
            uint128 startTime,
            uint128 interval,
            address execAddress,
            bytes4 execSelector,
            address resolverAddress,
            bytes memory resolverData,
            address feeToken,
            bool useTreasury
        ) = abi.decode(
                _callDataSliced,
                (
                    uint128,
                    uint128,
                    address,
                    bytes4,
                    address,
                    bytes,
                    address,
                    bool
                )
            );

        return (
            execAddress,
            abi.encodePacked(execSelector),
            feeToken = useTreasury ? address(0) : feeToken,
            abi.encode(resolverAddress, resolverData),
            abi.encode(startTime, interval)
        );
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {LibDataTypes} from "./LibDataTypes.sol";

/**
 * @notice Library to compute taskId of legacy and current tasks.
 */
// solhint-disable max-line-length
library LibTaskId {
    /**
     * @notice Returns taskId of taskCreator.
     * @notice To maintain the taskId of legacy tasks, if
     * resolver module or resolver and time module is used,
     * we will compute task id the legacy way.
     *
     * @param taskCreator The address which created the task.
     * @param execAddress Address of contract that will be called by Gelato.
     * @param execSelector Signature of the function which will be called by Gelato.
     * @param moduleData  Conditional modules that will be used. {See LibDataTypes-ModuleData}
     * @param feeToken Address of token to be used as payment. Use address(0) if TaskTreasury is being used, 0xeeeeee... for ETH or native tokens.
     */
    function getTaskId(
        address taskCreator,
        address execAddress,
        bytes4 execSelector,
        LibDataTypes.ModuleData memory moduleData,
        address feeToken
    ) internal pure returns (bytes32 taskId) {
        if (_shouldGetLegacyTaskId(moduleData.modules)) {
            bytes32 resolverHash = _getResolverHash(moduleData.args[0]);

            taskId = getLegacyTaskId(
                taskCreator,
                execAddress,
                execSelector,
                feeToken == address(0),
                feeToken,
                resolverHash
            );
        } else {
            taskId = keccak256(
                abi.encode(
                    taskCreator,
                    execAddress,
                    execSelector,
                    moduleData,
                    feeToken
                )
            );
        }
    }

    /**
     * @notice Returns taskId of taskCreator.
     * @notice Legacy way of computing taskId.
     *
     * @param taskCreator The address which created the task.
     * @param execAddress Address of contract that will be called by Gelato.
     * @param execSelector Signature of the function which will be called by Gelato.
     * @param useTaskTreasuryFunds Wether fee should be deducted from TaskTreasury.
     * @param feeToken Address of token to be used as payment. Use address(0) if TaskTreasury is being used, 0xeeeeee... for ETH or native tokens.
     * @param resolverHash Hash of resolverAddress and resolverData {See getResolverHash}
     */
    function getLegacyTaskId(
        address taskCreator,
        address execAddress,
        bytes4 execSelector,
        bool useTaskTreasuryFunds,
        address feeToken,
        bytes32 resolverHash
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    taskCreator,
                    execAddress,
                    execSelector,
                    useTaskTreasuryFunds,
                    feeToken,
                    resolverHash
                )
            );
    }

    /**
     * @dev For legacy tasks, resolvers are compulsory. Time tasks were also introduced.
     * The sequence of Module is enforced in {LibTaskModule-_validModules}
     */
    function _shouldGetLegacyTaskId(LibDataTypes.Module[] memory _modules)
        private
        pure
        returns (bool)
    {
        uint256 length = _modules.length;

        if (
            (length == 1 && _modules[0] == LibDataTypes.Module.RESOLVER) ||
            (length == 2 &&
                _modules[0] == LibDataTypes.Module.RESOLVER &&
                _modules[1] == LibDataTypes.Module.TIME)
        ) return true;

        return false;
    }

    /**
     * @dev Acquire resolverHash which is required to compute legacyTaskId.
     *
     * @param _resolverModuleArg Encoded value of resolverAddress and resolverData
     */
    function _getResolverHash(bytes memory _resolverModuleArg)
        private
        pure
        returns (bytes32)
    {
        return keccak256(_resolverModuleArg);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import {_call, _delegateCall} from "../functions/FExec.sol";
import {LibDataTypes} from "./LibDataTypes.sol";
import {LibTaskModuleConfig} from "./LibTaskModuleConfig.sol";
import {ITaskModule} from "../interfaces/ITaskModule.sol";

/**
 * @notice Library to call task modules on task creation and execution.
 */
library LibTaskModule {
    using LibTaskModuleConfig for LibDataTypes.Module;

    /**
     * @notice Delegate calls task modules before generating taskId.
     *
     * @param _execAddress Address of contract that will be called by Gelato.
     * @param _taskCreator The address which created the task.
     * @param taskModuleAddresses The storage reference to the mapping of modules to their address.
     */
    function preCreateTask(
        address _taskCreator,
        address _execAddress,
        mapping(LibDataTypes.Module => address) storage taskModuleAddresses
    ) internal returns (address, address) {
        uint256 length = uint256(type(LibDataTypes.Module).max);

        for (uint256 i; i <= length; i++) {
            LibDataTypes.Module module = LibDataTypes.Module(i);
            if (!module.requirePreCreate()) continue;

            address moduleAddress = taskModuleAddresses[module];
            _moduleInitialised(moduleAddress);

            bytes memory delegatecallData = abi.encodeWithSelector(
                ITaskModule.preCreateTask.selector,
                _taskCreator,
                _execAddress
            );

            (, bytes memory returnData) = _delegateCall(
                moduleAddress,
                delegatecallData,
                "Ops.preCreateTask: "
            );

            (_taskCreator, _execAddress) = abi.decode(
                returnData,
                (address, address)
            );
        }

        return (_taskCreator, _execAddress);
    }

    /**
     * @notice Delegate calls task modules on create task to initialise them.
     *
     * @param _taskId Unique hash of the task. {See LibTaskId-getTaskId}
     * @param _taskCreator The address which created the task.
     * @param _execAddress Address of contract that will be called by Gelato.
     * @param _execData Execution data to be called with / function selector.
     * @param _moduleData Modules that will be used for the task. {See LibDataTypes-ModuleData}
     * @param taskModuleAddresses The storage reference to the mapping of modules to their address.
     */
    function onCreateTask(
        bytes32 _taskId,
        address _taskCreator,
        address _execAddress,
        bytes memory _execData,
        LibDataTypes.ModuleData memory _moduleData,
        mapping(LibDataTypes.Module => address) storage taskModuleAddresses
    ) internal {
        uint256 length = _moduleData.modules.length;

        _validModules(length, _moduleData.modules);

        for (uint256 i; i < length; i++) {
            LibDataTypes.Module module = _moduleData.modules[i];
            if (!module.requireOnCreate()) continue;

            address moduleAddress = taskModuleAddresses[module];
            _moduleInitialised(moduleAddress);

            bytes memory delegatecallData = abi.encodeWithSelector(
                ITaskModule.onCreateTask.selector,
                _taskId,
                _taskCreator,
                _execAddress,
                _execData,
                _moduleData.args[i]
            );

            _delegateCall(
                moduleAddress,
                delegatecallData,
                "Ops.onCreateTask: "
            );
        }
    }

    /**
     * @notice Delegate calls task modules before removing task.
     *
     * @param _taskId Unique hash of the task. {See LibTaskId-getTaskId}
     * @param _taskCreator The address which created the task.
     * @param taskModuleAddresses The storage reference to the mapping of modules to their address.
     */
    function preCancelTask(
        bytes32 _taskId,
        address _taskCreator,
        mapping(LibDataTypes.Module => address) storage taskModuleAddresses
    ) internal returns (address) {
        uint256 length = uint256(type(LibDataTypes.Module).max);

        for (uint256 i; i <= length; i++) {
            LibDataTypes.Module module = LibDataTypes.Module(i);

            if (!module.requirePreCancel()) continue;

            address moduleAddress = taskModuleAddresses[module];
            _moduleInitialised(moduleAddress);

            bytes memory delegatecallData = abi.encodeWithSelector(
                ITaskModule.preCancelTask.selector,
                _taskId,
                _taskCreator
            );

            (, bytes memory returnData) = _delegateCall(
                moduleAddress,
                delegatecallData,
                "Ops.preCancelTask: "
            );

            (_taskCreator) = abi.decode(returnData, (address));
        }

        return _taskCreator;
    }

    /**
     * @notice Delegate calls task modules on exec.
     *
     * @param _taskId Unique hash of the task. {See LibTaskId-getTaskId}
     * @param _taskCreator The address which created the task.
     * @param _execAddress Address of contract that will be called by Gelato.
     * @param _execData Execution data to be called with / function selector.
     * @param _modules Modules that is used for the task. {See LibDataTypes-Module}
     * @param _revertOnFailure To revert or not if call to execAddress fails.
     * @param taskModuleAddresses The storage reference to the mapping of modules to their address.
     */
    function onExecTask(
        bytes32 _taskId,
        address _taskCreator,
        address _execAddress,
        bytes memory _execData,
        LibDataTypes.Module[] memory _modules,
        bool _revertOnFailure,
        mapping(LibDataTypes.Module => address) storage taskModuleAddresses
    ) internal returns (bool callSuccess) {
        address[] memory moduleAddresses = _getModuleAddresses(
            _modules,
            taskModuleAddresses
        );

        (_execAddress, _execData) = _preExecCall(
            _taskId,
            _taskCreator,
            _execAddress,
            _execData,
            _modules,
            moduleAddresses
        );

        (callSuccess, ) = _call(
            _execAddress,
            abi.encodePacked(_execData, _taskCreator),
            0,
            _revertOnFailure,
            "Ops.exec: "
        );

        _postExecCall(
            _taskId,
            _taskCreator,
            _execAddress,
            _execData,
            _modules,
            moduleAddresses
        );
    }

    function _preExecCall(
        bytes32 _taskId,
        address _taskCreator,
        address _execAddress,
        bytes memory _execData,
        LibDataTypes.Module[] memory _modules,
        address[] memory _moduleAddresses
    ) private returns (address, bytes memory) {
        uint256 length = _modules.length;

        for (uint256 i; i < length; i++) {
            if (!_modules[i].requirePreExec()) continue;

            bytes memory delegatecallData = abi.encodeWithSelector(
                ITaskModule.preExecCall.selector,
                _taskId,
                _taskCreator,
                _execAddress,
                _execData
            );

            (, bytes memory returnData) = _delegateCall(
                _moduleAddresses[i],
                delegatecallData,
                "Ops.preExecCall: "
            );

            (_execAddress, _execData) = abi.decode(
                returnData,
                (address, bytes)
            );
        }
        return (_execAddress, _execData);
    }

    function _postExecCall(
        bytes32 _taskId,
        address _taskCreator,
        address _execAddress,
        bytes memory _execData,
        LibDataTypes.Module[] memory _modules,
        address[] memory _moduleAddresses
    ) private {
        uint256 length = _moduleAddresses.length;

        for (uint256 i; i < length; i++) {
            if (!_modules[i].requirePostExec()) continue;

            bytes memory delegatecallData = abi.encodeWithSelector(
                ITaskModule.postExecCall.selector,
                _taskId,
                _taskCreator,
                _execAddress,
                _execData
            );

            _delegateCall(
                _moduleAddresses[i],
                delegatecallData,
                "Ops.postExecCall: "
            );
        }
    }

    function _getModuleAddresses(
        LibDataTypes.Module[] memory _modules,
        mapping(LibDataTypes.Module => address) storage taskModuleAddresses
    ) private view returns (address[] memory) {
        uint256 length = _modules.length;
        address[] memory moduleAddresses = new address[](length);

        for (uint256 i; i < length; i++) {
            moduleAddresses[i] = taskModuleAddresses[_modules[i]];
        }

        return moduleAddresses;
    }

    function _moduleInitialised(address _moduleAddress) private pure {
        require(
            _moduleAddress != address(0),
            "Ops._moduleInitialised: Not init"
        );
    }

    ///@dev Check for duplicate modules.
    function _validModules(
        uint256 _length,
        LibDataTypes.Module[] memory _modules
    ) private pure {
        if (_length > 1)
            for (uint256 i; i < _length - 1; i++)
                require(
                    _modules[i + 1] > _modules[i],
                    "Ops._validModules: Asc only"
                );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import {LibDataTypes} from "./LibDataTypes.sol";

/**
 * @notice Library to determine wether to call task modules to reduce unnecessary calls.
 */
library LibTaskModuleConfig {
    function requirePreCreate(LibDataTypes.Module _module)
        internal
        pure
        returns (bool)
    {
        if (_module == LibDataTypes.Module.PROXY) return true;

        return false;
    }

    function requirePreCancel(LibDataTypes.Module _module)
        internal
        pure
        returns (bool)
    {
        if (
            _module == LibDataTypes.Module.TIME ||
            _module == LibDataTypes.Module.PROXY
        ) return true;

        return false;
    }

    function requireOnCreate(LibDataTypes.Module _module)
        internal
        pure
        returns (bool)
    {
        if (
            _module == LibDataTypes.Module.TIME ||
            _module == LibDataTypes.Module.PROXY
        ) return true;

        return false;
    }

    function requirePreExec(LibDataTypes.Module _module)
        internal
        pure
        returns (bool)
    {
        if (
            _module == LibDataTypes.Module.TIME ||
            _module == LibDataTypes.Module.PROXY
        ) return true;

        return false;
    }

    function requirePostExec(LibDataTypes.Module _module)
        internal
        pure
        returns (bool)
    {
        if (_module == LibDataTypes.Module.SINGLE_EXEC) return true;

        return false;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

library GelatoBytes {
    function calldataSliceSelector(bytes calldata _bytes)
        internal
        pure
        returns (bytes4 selector)
    {
        selector =
            _bytes[0] |
            (bytes4(_bytes[1]) >> 8) |
            (bytes4(_bytes[2]) >> 16) |
            (bytes4(_bytes[3]) >> 24);
    }

    function memorySliceSelector(bytes memory _bytes)
        internal
        pure
        returns (bytes4 selector)
    {
        selector =
            _bytes[0] |
            (bytes4(_bytes[1]) >> 8) |
            (bytes4(_bytes[2]) >> 16) |
            (bytes4(_bytes[3]) >> 24);
    }

    function revertWithError(bytes memory _bytes, string memory _tracingInfo)
        internal
        pure
    {
        // 68: 32-location, 32-length, 4-ErrorSelector, UTF-8 err
        if (_bytes.length % 32 == 4) {
            bytes4 selector;
            assembly {
                selector := mload(add(0x20, _bytes))
            }
            if (selector == 0x08c379a0) {
                // Function selector for Error(string)
                assembly {
                    _bytes := add(_bytes, 68)
                }
                revert(string(abi.encodePacked(_tracingInfo, string(_bytes))));
            } else {
                revert(
                    string(abi.encodePacked(_tracingInfo, "NoErrorSelector"))
                );
            }
        } else {
            revert(
                string(abi.encodePacked(_tracingInfo, "UnexpectedReturndata"))
            );
        }
    }

    function returnError(bytes memory _bytes, string memory _tracingInfo)
        internal
        pure
        returns (string memory)
    {
        // 68: 32-location, 32-length, 4-ErrorSelector, UTF-8 err
        if (_bytes.length % 32 == 4) {
            bytes4 selector;
            assembly {
                selector := mload(add(0x20, _bytes))
            }
            if (selector == 0x08c379a0) {
                // Function selector for Error(string)
                assembly {
                    _bytes := add(_bytes, 68)
                }
                return string(abi.encodePacked(_tracingInfo, string(_bytes)));
            } else {
                return
                    string(abi.encodePacked(_tracingInfo, "NoErrorSelector"));
            }
        } else {
            return
                string(abi.encodePacked(_tracingInfo, "UnexpectedReturndata"));
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

import {
    SafeERC20,
    IERC20
} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {_transfer, ETH} from "../../functions/FUtils.sol";

abstract contract Gelatofied {
    address payable public immutable gelato;

    modifier gelatofy(uint256 _amount, address _paymentToken) {
        require(msg.sender == gelato, "Gelatofied: Only gelato");
        _;
        _transfer(gelato, _paymentToken, _amount);
    }

    modifier onlyGelato() {
        require(msg.sender == gelato, "Gelatofied: Only gelato");
        _;
    }

    constructor(address payable _gelato) {
        gelato = _gelato;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

abstract contract Proxied {
    /// @notice to be used by initialisation / postUpgrade function so that only the proxy's admin can execute them
    /// It also allows these functions to be called inside a contructor
    /// even if the contract is meant to be used without proxy
    modifier proxied() {
        address proxyAdminAddress = _proxyAdmin();
        // With hardhat-deploy proxies
        // the proxyAdminAddress is zero only for the implementation contract
        // if the implementation contract want to be used as a standalone/immutable contract
        // it simply has to execute the `proxied` function
        // This ensure the proxyAdminAddress is never zero post deployment
        // And allow you to keep the same code for both proxied contract and immutable contract
        if (proxyAdminAddress == address(0)) {
            // ensure can not be called twice when used outside of proxy : no admin
            // solhint-disable-next-line security/no-inline-assembly
            assembly {
                sstore(
                    0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103,
                    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
                )
            }
        } else {
            require(msg.sender == proxyAdminAddress);
        }
        _;
    }

    modifier onlyProxyAdmin() {
        require(msg.sender == _proxyAdmin(), "NOT_AUTHORIZED");
        _;
    }

    function _proxyAdmin() internal view returns (address adminAddress) {
        // solhint-disable-next-line security/no-inline-assembly
        assembly {
            adminAddress := sload(
                0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103
            )
        }
    }
}