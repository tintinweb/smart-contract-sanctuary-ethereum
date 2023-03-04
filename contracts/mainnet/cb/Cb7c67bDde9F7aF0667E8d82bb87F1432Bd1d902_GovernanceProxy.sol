// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import "Address.sol";

import "SimpleAccessControl.sol";
import "IGovernanceProxy.sol";

contract GovernanceProxy is IGovernanceProxy, SimpleAccessControl {
    using Address for address;

    bytes32 public constant GOVERNANCE_ROLE = "GOVERNANCE";
    bytes32 public constant VETO_ROLE = "VETO";

    uint64 public nextChangeId;

    /// @notice mapping from function selector to delay in seconds
    /// NOTE: For simplicity, delays are only based on selectors and not on the
    /// contract address, which means that if two functions in different
    /// contracts have the exact same name and arguments, they will share the same delay
    mapping(bytes4 => uint64) public override delays;

    /// @dev array of pending changes to execute
    /// We perform linear searches through this using the change ID, so in theory
    /// this could run out of gas. However, in practice, the number of pending
    /// changes should never become large enough for this to become an issue
    Change[] internal pendingChanges;

    /// @dev this is an array of all changes that have ended, regardless of their status
    /// this is only used to make it easier to query but should not be used from within
    /// any contract as the length is completely unbounded
    Change[] internal endedChanges;

    constructor(address governance, address veto) {
        _grantRole(GOVERNANCE_ROLE, governance);
        _grantRole(VETO_ROLE, veto);
    }

    /// @return change the pending change with the given id if found
    /// this reverts if the change is not found
    function getPendingChange(uint64 changeId) external view returns (Change memory change) {
        (change, ) = _findPendingChange(changeId);
    }

    /// @return all the pending changes
    /// this should typically be quite small so no need for pagination
    function getPendingChanges() external view returns (Change[] memory) {
        return pendingChanges;
    }

    /// @return total number of ended changes
    function getEndedChangesCount() external view returns (uint256) {
        return endedChanges.length;
    }

    /// @return all the ended changes
    /// this can become large so `getEndedChanges(uint256 offset, uint256 n)`
    /// is the preferred way to query
    function getEndedChanges() external view returns (Change[] memory) {
        return endedChanges;
    }

    /// @return `n` ended changes starting from offset
    /// This is useful is you want to paginate through the changes
    /// note that the changes are in chronological order of execution/cancelation
    /// which means that it might be useful to start paginatign from the end of the array
    function getEndedChanges(uint256 offset, uint256 n) external view returns (Change[] memory) {
        Change[] memory paginated = new Change[](n);
        for (uint256 i; i < n; i++) {
            paginated[i] = endedChanges[offset + i];
        }
        return paginated;
    }

    /// @notice Requests a list of function calls to be executed as a change
    /// @dev If the change requires no delay, it will be executed immediately
    /// @param calls the calls to be executed
    /// this should be fully encoded including the selectors and the abi-encoded arguments
    /// Changes can only be requested by governance
    function requestChange(Call[] calldata calls) external onlyRole(GOVERNANCE_ROLE) {
        // Calculating the maximum delay for all calls
        uint64 maxDelay;
        for (uint256 i; i < calls.length; i++) {
            uint64 delay = _computeDelay(calls[i].data);
            if (delay > maxDelay) maxDelay = delay;
        }

        (Change storage change, uint256 index) = _requestChange(maxDelay, calls);

        // If the change requires no delay, execute it immediately
        if (maxDelay == 0) {
            _executeChange(change, index);
        }
    }

    /// @notice Executes a change
    /// The deadline of the change must be past
    /// Anyone can execute a pending change but in practice, this will be called by governance too
    function executeChange(uint64 id) external {
        (Change storage change, uint256 index) = _findPendingChange(id);
        _executeChange(change, index);
    }

    /// @notice Cancels a pending change
    /// Both governance and users having veto power can cancel a pending change
    function cancelChange(uint64 id) external {
        require(
            hasRole(GOVERNANCE_ROLE, msg.sender) || hasRole(VETO_ROLE, msg.sender),
            "not authorized"
        );

        (Change storage change, uint256 index) = _findPendingChange(id);
        emit ChangeCanceled(id);
        _endChange(change, index, Status.Canceled);
    }

    // the following functions should be called through `executeChange`

    function updateDelay(bytes4 selector, uint64 delay) external override {
        require(msg.sender == address(this), "not authorized");
        delays[selector] = delay;
        emit DelayUpdated(selector, delay);
    }

    function grantRole(bytes32 role, address account) external override {
        require(msg.sender == address(this), "not authorized");
        require(role == GOVERNANCE_ROLE || role == VETO_ROLE, "invalid role");
        _grantRole(role, account);
    }

    function revokeRole(bytes32 role, address account) external override {
        require(msg.sender == address(this), "not authorized");
        require(
            role != GOVERNANCE_ROLE || getRoleMemberCount(role) > 1,
            "need at least one governor"
        );
        _revokeRole(role, account);
    }

    // internal helpers

    function _requestChange(uint64 delay, Call[] calldata calls)
        internal
        returns (Change storage change, uint256 index)
    {
        uint64 id = nextChangeId++;
        change = pendingChanges.push();
        change.id = id;
        change.requestedAt = uint64(block.timestamp);
        change.endedAt = 0;
        change.delay = delay;
        change.status = Status.Pending;
        for (uint256 i; i < calls.length; i++) {
            change.calls.push(calls[i]);
        }

        index = pendingChanges.length - 1;

        emit ChangeRequested(calls, delay, id);
    }

    function _executeChange(Change storage change, uint256 index) internal {
        require(
            change.requestedAt + change.delay <= block.timestamp,
            "deadline has not been reached"
        );

        for (uint256 i; i < change.calls.length; i++) {
            change.calls[i].target.functionCall(change.calls[i].data);
        }

        emit ChangeExecuted(change.id);
        _endChange(change, index, Status.Executed);
    }

    function _endChange(
        Change storage change,
        uint256 index,
        Status status
    ) internal {
        change.status = status;
        change.endedAt = uint64(block.timestamp);
        endedChanges.push(change);
        _removePendingChange(index);
    }

    function _removePendingChange(uint256 index) internal {
        pendingChanges[index] = pendingChanges[pendingChanges.length - 1];
        pendingChanges.pop();
    }

    function _findPendingChange(uint64 id) internal view returns (Change storage, uint256 index) {
        for (uint256 i; i < pendingChanges.length; i++) {
            if (pendingChanges[i].id == id) {
                return (pendingChanges[i], i);
            }
        }
        revert("change not found");
    }

    function _computeDelay(bytes calldata data) internal view returns (uint64) {
        bytes4 selector = bytes4(data[:4]);

        // special case for `updateDelay`, we want to set the delay
        // as the delay for the current function for which the delay
        // will be changed, rather than a generic delay for `updateDelay` itself
        // for all the other functions, we use their actual delay
        if (selector == GovernanceProxy.updateDelay.selector) {
            bytes memory callData = data[4:];
            (selector, ) = abi.decode(callData, (bytes4, uint256));
        }

        return delays[selector];
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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import "EnumerableSet.sol";

import "ISimpleAccessControl.sol";

contract SimpleAccessControl is ISimpleAccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(bytes32 => EnumerableSet.AddressSet) internal roles;

    modifier onlyRole(bytes32 role) {
        require(hasRole(role, msg.sender), "not authorized");
        _;
    }

    function _grantRole(bytes32 role, address account) internal {
        roles[role].add(account);
    }

    function _revokeRole(bytes32 role, address account) internal {
        roles[role].remove(account);
    }

    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return roles[role].contains(account);
    }

    function getRoleMemberCount(bytes32 role) public view virtual override returns (uint256) {
        return roles[role].length();
    }

    function accountsWithRole(bytes32 role) external view override returns (address[] memory) {
        return roles[role].values();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

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
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
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
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
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

        /// @solidity memory-safe-assembly
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
     * @dev Returns the number of values in the set. O(1).
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

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

interface ISimpleAccessControl {
    function accountsWithRole(bytes32 role)
        external
        view
        returns (address[] memory);

    function hasRole(bytes32 role, address account)
        external
        view
        returns (bool);

    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import "ISimpleAccessControl.sol";

interface IGovernanceProxy is ISimpleAccessControl {
    /// @notice emitted when a change is requested by governance
    event ChangeRequested(Call[] calls, uint64 delay, uint64 changeId);

    /// @notice emitted when a change is executed
    /// this can be in the same block as `ChangeRequested` if there is no
    /// delay for the given function
    event ChangeExecuted(uint64 indexed changeId);

    /// @notice emitted when a change is canceled
    event ChangeCanceled(uint64 indexed changeId);

    /// @notice emitted when a function's delay is updated
    event DelayUpdated(bytes4 indexed selector, uint64 delay);

    /// @notice status of a change
    enum Status {
        Pending,
        Canceled,
        Executed
    }

    /// @notice this represents a function call as part of a Change
    /// The target is the contract to execute the function on
    /// The data is the function signature and the abi-encoded arguments
    struct Call {
        address target;
        bytes data;
    }

    /// @notice this represents a change to execute a set of function calls
    /// The ID is an unique auto-incrementing id that will be generated for each change
    /// The status is one of pending, canceled or executed and is pending when the change is created
    /// The requestedAt is the timestamp when the change was requested
    /// The delay is the delay in seconds before the change can be executed
    /// The endedAt is the timestamp when the change was executed or canceled
    /// The calls are the function calls to execute as part of the change
    struct Change {
        Status status;
        uint64 id;
        uint64 requestedAt;
        uint64 delay;
        uint64 endedAt;
        Call[] calls;
    }

    function delays(bytes4 selector) external view returns (uint64);

    function getPendingChange(uint64 changeId) external view returns (Change memory change);

    function getPendingChanges() external view returns (Change[] memory);

    function getEndedChangesCount() external view returns (uint256);

    function getEndedChanges() external view returns (Change[] memory);

    function getEndedChanges(uint256 offset, uint256 n) external view returns (Change[] memory);

    function requestChange(Call[] calldata calls) external;

    function executeChange(uint64 id) external;

    function cancelChange(uint64 id) external;

    function updateDelay(bytes4 selector, uint64 delay) external;

    function grantRole(bytes32 role, address account) external;

    function revokeRole(bytes32 role, address account) external;
}