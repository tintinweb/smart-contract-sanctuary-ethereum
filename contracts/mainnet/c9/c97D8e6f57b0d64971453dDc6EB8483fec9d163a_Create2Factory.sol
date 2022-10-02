/**
 *Submitted for verification at Etherscan.io on 2022-10-02
*/

// Sources flattened with hardhat v2.9.9 https://hardhat.org

// File interfaces/IMailbox.sol
pragma solidity >=0.6.11;

interface IMailbox {
    function localDomain() external view returns (uint32);

    function validatorManager() external view returns (address);
}


// File interfaces/IOutbox.sol
pragma solidity >=0.6.11;

interface IOutbox is IMailbox {
    function dispatch(
        uint32 _destinationDomain,
        bytes32 _recipientAddress,
        bytes calldata _messageBody
    ) external returns (uint256);

    function cacheCheckpoint() external;

    function latestCheckpoint() external view returns (bytes32, uint256);

    function count() external returns (uint256);

    function fail() external;

    function cachedCheckpoints(bytes32) external view returns (uint256);

    function latestCachedCheckpoint()
        external
        view
        returns (bytes32 root, uint256 index);
}


// File interfaces/IAbacusConnectionManager.sol
pragma solidity >=0.6.11;

interface IAbacusConnectionManager {
    function outbox() external view returns (IOutbox);

    function isInbox(address _inbox) external view returns (bool);

    function localDomain() external view returns (uint32);
}


// File @openzeppelin/contracts/utils/[email protected]
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


// File @openzeppelin/contracts/access/[email protected]
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
}


// File @openzeppelin/contracts/utils/[email protected]
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


// File @openzeppelin/contracts/utils/structs/[email protected]
// OpenZeppelin Contracts (last updated v4.6.0) (utils/structs/EnumerableSet.sol)

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


// File contracts/AbacusConnectionManager.sol
pragma solidity >=0.8.0;
pragma abicoder v2;

// ============ Internal Imports ============


// ============ External Imports ============



/**
 * @title AbacusConnectionManager
 * @author Celo Labs Inc.
 * @notice Manages a registry of local Inbox contracts for remote Outbox
 * domains.
 */
contract AbacusConnectionManager is IAbacusConnectionManager, Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;

    // ============ Public Storage ============

    // Outbox contract
    IOutbox public override outbox;
    // local Inbox address => remote Outbox domain
    mapping(address => uint32) public inboxToDomain;
    // remote Outbox domain => local Inbox addresses
    mapping(uint32 => EnumerableSet.AddressSet) domainToInboxes;

    // ============ Events ============

    /**
     * @notice Emitted when a new Outbox is set.
     * @param outbox the address of the Outbox
     */
    event OutboxSet(address indexed outbox);

    /**
     * @notice Emitted when a new Inbox is enrolled / added
     * @param domain the remote domain of the Outbox contract for the Inbox
     * @param inbox the address of the Inbox
     */
    event InboxEnrolled(uint32 indexed domain, address inbox);

    /**
     * @notice Emitted when a new Inbox is un-enrolled / removed
     * @param domain the remote domain of the Outbox contract for the Inbox
     * @param inbox the address of the Inbox
     */
    event InboxUnenrolled(uint32 indexed domain, address inbox);

    // ============ Constructor ============

    // solhint-disable-next-line no-empty-blocks
    constructor() Ownable() {}

    // ============ External Functions ============

    /**
     * @notice Sets the address of the local Outbox contract.
     * @param _outbox The address of the new local Outbox contract.
     */
    function setOutbox(address _outbox) external onlyOwner {
        require(Address.isContract(_outbox), "outbox !contract");
        outbox = IOutbox(_outbox);
        emit OutboxSet(_outbox);
    }

    /**
     * @notice Allow Owner to enroll Inbox contract
     * @param _domain the remote domain of the Outbox contract for the Inbox
     * @param _inbox the address of the Inbox
     */
    function enrollInbox(uint32 _domain, address _inbox) external onlyOwner {
        require(Address.isContract(_inbox), "inbox !contract");
        require(!isInbox(_inbox), "already inbox");
        // add inbox and domain to two-way mapping
        inboxToDomain[_inbox] = _domain;
        domainToInboxes[_domain].add(_inbox);
        emit InboxEnrolled(_domain, _inbox);
    }

    /**
     * @notice Allow Owner to un-enroll Inbox contract
     * @param _inbox the address of the Inbox
     */
    function unenrollInbox(address _inbox) external onlyOwner {
        _unenrollInbox(_inbox);
    }

    /**
     * @notice Query local domain from Outbox
     * @return local domain
     */
    function localDomain() external view override returns (uint32) {
        return outbox.localDomain();
    }

    /**
     * @notice Returns the Inbox addresses for a given remote domain
     * @return inboxes An array of addresses of the Inboxes
     */
    function getInboxes(uint32 remoteDomain)
        external
        view
        returns (address[] memory)
    {
        EnumerableSet.AddressSet storage _inboxes = domainToInboxes[
            remoteDomain
        ];
        uint256 length = _inboxes.length();
        address[] memory ret = new address[](length);
        for (uint256 i = 0; i < length; i += 1) {
            ret[i] = _inboxes.at(i);
        }
        return ret;
    }

    // ============ Public Functions ============

    /**
     * @notice Check whether _inbox is enrolled
     * @param _inbox the inbox to check for enrollment
     * @return TRUE iff _inbox is enrolled
     */
    function isInbox(address _inbox) public view override returns (bool) {
        return inboxToDomain[_inbox] != 0;
    }

    // ============ Internal Functions ============

    /**
     * @notice Remove the inbox from the two-way mappings
     * @param _inbox inbox to un-enroll
     */
    function _unenrollInbox(address _inbox) internal {
        uint32 _currentDomain = inboxToDomain[_inbox];
        require(domainToInboxes[_currentDomain].remove(_inbox), "not enrolled");
        domainToInboxes[_currentDomain].remove(_inbox);
        inboxToDomain[_inbox] = 0;
        emit InboxUnenrolled(_currentDomain, _inbox);
    }
}


// File contracts/upgrade/Versioned.sol
pragma solidity >=0.6.11;

/**
 * @title Versioned
 * @notice Version getter for contracts
 **/
contract Versioned {
    uint8 public constant VERSION = 0;
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


// File @openzeppelin/contracts-upgradeable/proxy/utils/[email protected]
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

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
        bool isTopLevelCall = _setInitializedVersion(1);
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
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
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
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
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


// File contracts/Mailbox.sol
pragma solidity >=0.8.0;

// ============ Internal Imports ============

// ============ External Imports ============


/**
 * @title Mailbox
 * @author Celo Labs Inc.
 * @notice Shared utilities between Outbox and Inbox.
 */
abstract contract Mailbox is IMailbox, OwnableUpgradeable {
    // ============ Immutable Variables ============

    // Domain of chain on which the contract is deployed
    uint32 public immutable override localDomain;

    // ============ Public Variables ============

    // Address of the validator manager contract.
    address public validatorManager;

    // ============ Upgrade Gap ============

    // gap for upgrade safety
    uint256[49] private __GAP;

    // ============ Events ============

    /**
     * @notice Emitted when the validator manager contract is changed
     * @param validatorManager The address of the new validatorManager
     */
    event ValidatorManagerSet(address validatorManager);

    // ============ Modifiers ============

    /**
     * @notice Ensures that a function is called by the validator manager contract.
     */
    modifier onlyValidatorManager() {
        require(msg.sender == validatorManager, "!validatorManager");
        _;
    }

    // ============ Constructor ============

    constructor(uint32 _localDomain) {
        localDomain = _localDomain;
    }

    // ============ Initializer ============

    function __Mailbox_initialize(address _validatorManager)
        internal
        onlyInitializing
    {
        // initialize owner
        __Ownable_init();
        _setValidatorManager(_validatorManager);
    }

    // ============ External Functions ============

    /**
     * @notice Set a new validator manager contract
     * @dev Mailbox(es) will initially be initialized using a trusted validator manager contract;
     * we will progressively decentralize by swapping the trusted contract with a new implementation
     * that implements Validator bonding & slashing, and rules for Validator selection & rotation
     * @param _validatorManager the new validator manager contract
     */
    function setValidatorManager(address _validatorManager) external onlyOwner {
        _setValidatorManager(_validatorManager);
    }

    // ============ Internal Functions ============

    /**
     * @notice Set the validator manager
     * @param _validatorManager Address of the validator manager
     */
    function _setValidatorManager(address _validatorManager) internal {
        require(
            Address.isContract(_validatorManager),
            "!contract validatorManager"
        );
        validatorManager = _validatorManager;
        emit ValidatorManagerSet(_validatorManager);
    }
}


// File contracts/libs/Merkle.sol
pragma solidity >=0.6.11;

// work based on eth2 deposit contract, which is used under CC0-1.0

/**
 * @title MerkleLib
 * @author Celo Labs Inc.
 * @notice An incremental merkle tree modeled on the eth2 deposit contract.
 **/
library MerkleLib {
    uint256 internal constant TREE_DEPTH = 32;
    uint256 internal constant MAX_LEAVES = 2**TREE_DEPTH - 1;

    /**
     * @notice Struct representing incremental merkle tree. Contains current
     * branch and the number of inserted leaves in the tree.
     **/
    struct Tree {
        bytes32[TREE_DEPTH] branch;
        uint256 count;
    }

    /**
     * @notice Inserts `_node` into merkle tree
     * @dev Reverts if tree is full
     * @param _node Element to insert into tree
     **/
    function insert(Tree storage _tree, bytes32 _node) internal {
        require(_tree.count < MAX_LEAVES, "merkle tree full");

        _tree.count += 1;
        uint256 size = _tree.count;
        for (uint256 i = 0; i < TREE_DEPTH; i++) {
            if ((size & 1) == 1) {
                _tree.branch[i] = _node;
                return;
            }
            _node = keccak256(abi.encodePacked(_tree.branch[i], _node));
            size /= 2;
        }
        // As the loop should always end prematurely with the `return` statement,
        // this code should be unreachable. We assert `false` just to be safe.
        assert(false);
    }

    /**
     * @notice Calculates and returns`_tree`'s current root given array of zero
     * hashes
     * @param _zeroes Array of zero hashes
     * @return _current Calculated root of `_tree`
     **/
    function rootWithCtx(Tree storage _tree, bytes32[TREE_DEPTH] memory _zeroes)
        internal
        view
        returns (bytes32 _current)
    {
        uint256 _index = _tree.count;

        for (uint256 i = 0; i < TREE_DEPTH; i++) {
            uint256 _ithBit = (_index >> i) & 0x01;
            bytes32 _next = _tree.branch[i];
            if (_ithBit == 1) {
                _current = keccak256(abi.encodePacked(_next, _current));
            } else {
                _current = keccak256(abi.encodePacked(_current, _zeroes[i]));
            }
        }
    }

    /// @notice Calculates and returns`_tree`'s current root
    function root(Tree storage _tree) internal view returns (bytes32) {
        return rootWithCtx(_tree, zeroHashes());
    }

    /// @notice Returns array of TREE_DEPTH zero hashes
    /// @return _zeroes Array of TREE_DEPTH zero hashes
    function zeroHashes()
        internal
        pure
        returns (bytes32[TREE_DEPTH] memory _zeroes)
    {
        _zeroes[0] = Z_0;
        _zeroes[1] = Z_1;
        _zeroes[2] = Z_2;
        _zeroes[3] = Z_3;
        _zeroes[4] = Z_4;
        _zeroes[5] = Z_5;
        _zeroes[6] = Z_6;
        _zeroes[7] = Z_7;
        _zeroes[8] = Z_8;
        _zeroes[9] = Z_9;
        _zeroes[10] = Z_10;
        _zeroes[11] = Z_11;
        _zeroes[12] = Z_12;
        _zeroes[13] = Z_13;
        _zeroes[14] = Z_14;
        _zeroes[15] = Z_15;
        _zeroes[16] = Z_16;
        _zeroes[17] = Z_17;
        _zeroes[18] = Z_18;
        _zeroes[19] = Z_19;
        _zeroes[20] = Z_20;
        _zeroes[21] = Z_21;
        _zeroes[22] = Z_22;
        _zeroes[23] = Z_23;
        _zeroes[24] = Z_24;
        _zeroes[25] = Z_25;
        _zeroes[26] = Z_26;
        _zeroes[27] = Z_27;
        _zeroes[28] = Z_28;
        _zeroes[29] = Z_29;
        _zeroes[30] = Z_30;
        _zeroes[31] = Z_31;
    }

    /**
     * @notice Calculates and returns the merkle root for the given leaf
     * `_item`, a merkle branch, and the index of `_item` in the tree.
     * @param _item Merkle leaf
     * @param _branch Merkle proof
     * @param _index Index of `_item` in tree
     * @return _current Calculated merkle root
     **/
    function branchRoot(
        bytes32 _item,
        bytes32[TREE_DEPTH] memory _branch,
        uint256 _index
    ) internal pure returns (bytes32 _current) {
        _current = _item;

        for (uint256 i = 0; i < TREE_DEPTH; i++) {
            uint256 _ithBit = (_index >> i) & 0x01;
            bytes32 _next = _branch[i];
            if (_ithBit == 1) {
                _current = keccak256(abi.encodePacked(_next, _current));
            } else {
                _current = keccak256(abi.encodePacked(_current, _next));
            }
        }
    }

    // keccak256 zero hashes
    bytes32 internal constant Z_0 =
        hex"0000000000000000000000000000000000000000000000000000000000000000";
    bytes32 internal constant Z_1 =
        hex"ad3228b676f7d3cd4284a5443f17f1962b36e491b30a40b2405849e597ba5fb5";
    bytes32 internal constant Z_2 =
        hex"b4c11951957c6f8f642c4af61cd6b24640fec6dc7fc607ee8206a99e92410d30";
    bytes32 internal constant Z_3 =
        hex"21ddb9a356815c3fac1026b6dec5df3124afbadb485c9ba5a3e3398a04b7ba85";
    bytes32 internal constant Z_4 =
        hex"e58769b32a1beaf1ea27375a44095a0d1fb664ce2dd358e7fcbfb78c26a19344";
    bytes32 internal constant Z_5 =
        hex"0eb01ebfc9ed27500cd4dfc979272d1f0913cc9f66540d7e8005811109e1cf2d";
    bytes32 internal constant Z_6 =
        hex"887c22bd8750d34016ac3c66b5ff102dacdd73f6b014e710b51e8022af9a1968";
    bytes32 internal constant Z_7 =
        hex"ffd70157e48063fc33c97a050f7f640233bf646cc98d9524c6b92bcf3ab56f83";
    bytes32 internal constant Z_8 =
        hex"9867cc5f7f196b93bae1e27e6320742445d290f2263827498b54fec539f756af";
    bytes32 internal constant Z_9 =
        hex"cefad4e508c098b9a7e1d8feb19955fb02ba9675585078710969d3440f5054e0";
    bytes32 internal constant Z_10 =
        hex"f9dc3e7fe016e050eff260334f18a5d4fe391d82092319f5964f2e2eb7c1c3a5";
    bytes32 internal constant Z_11 =
        hex"f8b13a49e282f609c317a833fb8d976d11517c571d1221a265d25af778ecf892";
    bytes32 internal constant Z_12 =
        hex"3490c6ceeb450aecdc82e28293031d10c7d73bf85e57bf041a97360aa2c5d99c";
    bytes32 internal constant Z_13 =
        hex"c1df82d9c4b87413eae2ef048f94b4d3554cea73d92b0f7af96e0271c691e2bb";
    bytes32 internal constant Z_14 =
        hex"5c67add7c6caf302256adedf7ab114da0acfe870d449a3a489f781d659e8becc";
    bytes32 internal constant Z_15 =
        hex"da7bce9f4e8618b6bd2f4132ce798cdc7a60e7e1460a7299e3c6342a579626d2";
    bytes32 internal constant Z_16 =
        hex"2733e50f526ec2fa19a22b31e8ed50f23cd1fdf94c9154ed3a7609a2f1ff981f";
    bytes32 internal constant Z_17 =
        hex"e1d3b5c807b281e4683cc6d6315cf95b9ade8641defcb32372f1c126e398ef7a";
    bytes32 internal constant Z_18 =
        hex"5a2dce0a8a7f68bb74560f8f71837c2c2ebbcbf7fffb42ae1896f13f7c7479a0";
    bytes32 internal constant Z_19 =
        hex"b46a28b6f55540f89444f63de0378e3d121be09e06cc9ded1c20e65876d36aa0";
    bytes32 internal constant Z_20 =
        hex"c65e9645644786b620e2dd2ad648ddfcbf4a7e5b1a3a4ecfe7f64667a3f0b7e2";
    bytes32 internal constant Z_21 =
        hex"f4418588ed35a2458cffeb39b93d26f18d2ab13bdce6aee58e7b99359ec2dfd9";
    bytes32 internal constant Z_22 =
        hex"5a9c16dc00d6ef18b7933a6f8dc65ccb55667138776f7dea101070dc8796e377";
    bytes32 internal constant Z_23 =
        hex"4df84f40ae0c8229d0d6069e5c8f39a7c299677a09d367fc7b05e3bc380ee652";
    bytes32 internal constant Z_24 =
        hex"cdc72595f74c7b1043d0e1ffbab734648c838dfb0527d971b602bc216c9619ef";
    bytes32 internal constant Z_25 =
        hex"0abf5ac974a1ed57f4050aa510dd9c74f508277b39d7973bb2dfccc5eeb0618d";
    bytes32 internal constant Z_26 =
        hex"b8cd74046ff337f0a7bf2c8e03e10f642c1886798d71806ab1e888d9e5ee87d0";
    bytes32 internal constant Z_27 =
        hex"838c5655cb21c6cb83313b5a631175dff4963772cce9108188b34ac87c81c41e";
    bytes32 internal constant Z_28 =
        hex"662ee4dd2dd7b2bc707961b1e646c4047669dcb6584f0d8d770daf5d7e7deb2e";
    bytes32 internal constant Z_29 =
        hex"388ab20e2573d171a88108e79d820e98f26c0b84aa8b2f4aa4968dbb818ea322";
    bytes32 internal constant Z_30 =
        hex"93237c50ba75ee485f4c22adf2f741400bdf8d6a9cc7df7ecae576221665d735";
    bytes32 internal constant Z_31 =
        hex"8448818bb4ae4562849e949e17ac16e0be16688e156b5cf15e098c627c0056a9";
}


// File contracts/libs/TypeCasts.sol
pragma solidity >=0.6.11;

library TypeCasts {
    // treat it as a null-terminated string of max 32 bytes
    function coerceString(bytes32 _buf)
        internal
        pure
        returns (string memory _newStr)
    {
        uint8 _slen = 0;
        while (_slen < 32 && _buf[_slen] != 0) {
            _slen++;
        }

        // solhint-disable-next-line no-inline-assembly
        assembly {
            _newStr := mload(0x40)
            mstore(0x40, add(_newStr, 0x40)) // may end up with extra
            mstore(_newStr, _slen)
            mstore(add(_newStr, 0x20), _buf)
        }
    }

    // alignment preserving cast
    function addressToBytes32(address _addr) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(_addr)));
    }

    // alignment preserving cast
    function bytes32ToAddress(bytes32 _buf) internal pure returns (address) {
        return address(uint160(uint256(_buf)));
    }
}


// File contracts/libs/Message.sol
pragma solidity >=0.8.0;

/**
 * @title Message Library
 * @author Celo Labs Inc.
 * @notice Library for formatted messages used by Outbox and Replica.
 **/
library Message {
    using TypeCasts for bytes32;

    /**
     * @notice Returns formatted (packed) message with provided fields
     * @dev This function should only be used in memory message construction.
     * @param _originDomain Domain of home chain
     * @param _sender Address of sender as bytes32
     * @param _destinationDomain Domain of destination chain
     * @param _recipient Address of recipient on destination chain as bytes32
     * @param _messageBody Raw bytes of message body
     * @return Formatted message
     **/
    function formatMessage(
        uint32 _originDomain,
        bytes32 _sender,
        uint32 _destinationDomain,
        bytes32 _recipient,
        bytes calldata _messageBody
    ) internal pure returns (bytes memory) {
        return
            abi.encodePacked(
                _originDomain,
                _sender,
                _destinationDomain,
                _recipient,
                _messageBody
            );
    }

    /**
     * @notice Returns leaf of formatted message with provided fields.
     * @dev hash of abi packed message and leaf index.
     * @param _message Raw bytes of message contents.
     * @param _leafIndex Index of the message in the tree
     * @return Leaf (hash) of formatted message
     */
    function leaf(bytes calldata _message, uint256 _leafIndex)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(_message, _leafIndex));
    }

    /**
     * @notice Decode raw message bytes into structured message fields.
     * @dev Efficiently slices calldata into structured message fields.
     * @param _message Raw bytes of message contents.
     * @return origin Domain of home chain
     * @return sender Address of sender as bytes32
     * @return destination Domain of destination chain
     * @return recipient Address of recipient on destination chain as bytes32
     * @return body Raw bytes of message body
     */
    function destructure(bytes calldata _message)
        internal
        pure
        returns (
            uint32 origin,
            bytes32 sender,
            uint32 destination,
            bytes32 recipient,
            bytes calldata body
        )
    {
        return (
            uint32(bytes4(_message[0:4])),
            bytes32(_message[4:36]),
            uint32(bytes4(_message[36:40])),
            bytes32(_message[40:72]),
            bytes(_message[72:])
        );
    }

    /**
     * @notice Decode raw message bytes into structured message fields.
     * @dev Efficiently slices calldata into structured message fields.
     * @param _message Raw bytes of message contents.
     * @return origin Domain of home chain
     * @return sender Address of sender as address (bytes20)
     * @return destination Domain of destination chain
     * @return recipient Address of recipient on destination chain as address (bytes20)
     * @return body Raw bytes of message body
     */
    function destructureAddresses(bytes calldata _message)
        internal
        pure
        returns (
            uint32,
            address,
            uint32,
            address,
            bytes calldata
        )
    {
        (
            uint32 _origin,
            bytes32 _sender,
            uint32 destination,
            bytes32 _recipient,
            bytes calldata body
        ) = destructure(_message);
        return (
            _origin,
            _sender.bytes32ToAddress(),
            destination,
            _recipient.bytes32ToAddress(),
            body
        );
    }
}


// File interfaces/IMessageRecipient.sol
pragma solidity >=0.6.11;

interface IMessageRecipient {
    function handle(
        uint32 _origin,
        bytes32 _sender,
        bytes calldata _message
    ) external;
}


// File interfaces/IInbox.sol
pragma solidity >=0.6.11;

interface IInbox is IMailbox {
    function remoteDomain() external returns (uint32);

    function process(
        bytes32 _root,
        uint256 _index,
        bytes calldata _message,
        bytes32[32] calldata _proof,
        uint256 _leafIndex
    ) external;
}


// File @openzeppelin/contracts-upgradeable/security/[email protected]
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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}


// File contracts/Inbox.sol
pragma solidity >=0.8.0;

// ============ Internal Imports ============







// ============ External Imports ============

/**
 * @title Inbox
 * @author Celo Labs Inc.
 * @notice Track root updates on Outbox, prove and dispatch messages to end
 * recipients.
 */
contract Inbox is IInbox, ReentrancyGuardUpgradeable, Versioned, Mailbox {
    // ============ Libraries ============

    using MerkleLib for MerkleLib.Tree;
    using Message for bytes;
    using TypeCasts for bytes32;

    // ============ Enums ============

    // Status of Message:
    //   0 - None - message has not been processed
    //   1 - Processed - message has been dispatched to recipient
    enum MessageStatus {
        None,
        Processed
    }

    // ============ Public Storage ============

    // Domain of outbox chain
    uint32 public override remoteDomain;
    // Mapping of message leaves to MessageStatus
    mapping(bytes32 => MessageStatus) public messages;

    // ============ Upgrade Gap ============

    // gap for upgrade safety
    uint256[48] private __GAP;

    // ============ Events ============

    /**
     * @notice Emitted when message is processed
     * @dev This event allows watchers to observe the merkle proof they need
     * to prove fraud on the Outbox.
     * @param messageHash Hash of message that was processed.
     */
    event Process(bytes32 indexed messageHash);

    // ============ Constructor ============

    // solhint-disable-next-line no-empty-blocks
    constructor(uint32 _localDomain) Mailbox(_localDomain) {}

    // ============ Initializer ============

    function initialize(uint32 _remoteDomain, address _validatorManager)
        external
        initializer
    {
        __ReentrancyGuard_init();
        __Mailbox_initialize(_validatorManager);
        remoteDomain = _remoteDomain;
    }

    // ============ External Functions ============

    /**
     * @notice Attempts to process the provided formatted `message`. Performs
     * verification against root of the proof
     * @dev Called by the validator manager, which is responsible for verifying a
     * quorum of validator signatures on the checkpoint.
     * @dev Reverts if verification of the message fails.
     * @param _root The merkle root of the checkpoint used to prove message inclusion.
     * @param _index The index of the checkpoint used to prove message inclusion.
     * @param _message Formatted message (refer to Mailbox.sol Message library)
     * @param _proof Merkle proof of inclusion for message's leaf
     * @param _leafIndex Index of leaf in outbox's merkle tree
     */
    function process(
        bytes32 _root,
        uint256 _index,
        bytes calldata _message,
        bytes32[32] calldata _proof,
        uint256 _leafIndex
    ) external override nonReentrant onlyValidatorManager {
        require(_index >= _leafIndex, "!index");
        bytes32 _messageHash = _message.leaf(_leafIndex);
        // ensure that message has not been processed
        require(
            messages[_messageHash] == MessageStatus.None,
            "!MessageStatus.None"
        );
        // calculate the expected root based on the proof
        bytes32 _calculatedRoot = MerkleLib.branchRoot(
            _messageHash,
            _proof,
            _leafIndex
        );
        // verify the merkle proof
        require(_calculatedRoot == _root, "!proof");
        _process(_message, _messageHash);
    }

    // ============ Internal Functions ============

    /**
     * @notice Marks a message as processed and calls handle on the recipient
     * @dev Internal function that can be called by contracts like TestInbox
     * @param _message Formatted message (refer to Mailbox.sol Message library)
     * @param _messageHash keccak256 hash of the message
     */
    function _process(bytes calldata _message, bytes32 _messageHash) internal {
        (
            uint32 origin,
            bytes32 sender,
            uint32 destination,
            bytes32 recipient,
            bytes calldata body
        ) = _message.destructure();

        // ensure message came from the correct domain
        require(origin == remoteDomain, "!origin");
        // ensure message was meant for this domain
        require(destination == localDomain, "!destination");

        // update message status as processed
        messages[_messageHash] = MessageStatus.Processed;

        IMessageRecipient(recipient.bytes32ToAddress()).handle(
            origin,
            sender,
            body
        );
        emit Process(_messageHash);
    }
}


// File interfaces/IInterchainGasPaymaster.sol
pragma solidity >=0.6.11;

/**
 * @title IInterchainGasPaymaster
 * @notice Manages payments on a source chain to cover gas costs of relaying
 * messages to destination chains.
 */
interface IInterchainGasPaymaster {
    function payGasFor(
        address _outbox,
        uint256 _leafIndex,
        uint32 _destinationDomain
    ) external payable;
}


// File contracts/InterchainGasPaymaster.sol
pragma solidity >=0.8.0;

// ============ Internal Imports ============

// ============ External Imports ============

/**
 * @title InterchainGasPaymaster
 * @notice Manages payments on a source chain to cover gas costs of relaying
 * messages to destination chains.
 */
contract InterchainGasPaymaster is IInterchainGasPaymaster, OwnableUpgradeable {
    // ============ Events ============

    /**
     * @notice Emitted when a payment is made for a message's gas costs.
     * @param outbox The address of the Outbox contract.
     * @param leafIndex The index of the message in the Outbox merkle tree.
     * @param amount The amount of native tokens paid.
     */
    event GasPayment(address indexed outbox, uint256 leafIndex, uint256 amount);

    // ============ Constructor ============

    // solhint-disable-next-line no-empty-blocks
    constructor() {
        initialize(); // allows contract to be used without proxying
    }

    // ============ External Functions ============

    function initialize() public initializer {
        __Ownable_init();
    }

    /**
     * @notice Deposits msg.value as a payment for the relaying of a message
     * to its destination chain.
     * @param _outbox The address of the Outbox contract.
     * @param _leafIndex The index of the message in the Outbox merkle tree.
     * @param _destinationDomain The domain of the message's destination chain.
     */
    function payGasFor(
        address _outbox,
        uint256 _leafIndex,
        uint32 _destinationDomain
    ) external payable override {
        // Silence compiler warning. The NatSpec @param requires the parameter to be named.
        // While not used at the moment, future versions of the paymaster may conditionally
        // forward payments depending on the destination domain.
        _destinationDomain;

        emit GasPayment(_outbox, _leafIndex, msg.value);
    }

    /**
     * @notice Transfers the entire native token balance to the owner of the contract.
     * @dev The owner must be able to receive native tokens.
     */
    function claim() external {
        // Transfer the entire balance to owner.
        (bool success, ) = owner().call{value: address(this).balance}("");
        require(success, "!transfer");
    }
}


// File contracts/MerkleTreeManager.sol
pragma solidity >=0.8.0;

// ============ Internal Imports ============

/**
 * @title MerkleTreeManager
 * @author Celo Labs Inc.
 * @notice Contains a Merkle tree instance and
 * exposes view functions for the tree.
 */
contract MerkleTreeManager {
    // ============ Libraries ============

    using MerkleLib for MerkleLib.Tree;
    MerkleLib.Tree public tree;

    // ============ Upgrade Gap ============

    // gap for upgrade safety
    uint256[49] private __GAP;

    // ============ Public Functions ============

    /**
     * @notice Calculates and returns tree's current root
     */
    function root() public view returns (bytes32) {
        return tree.root();
    }
}


// File contracts/mock/MockInbox.sol
pragma solidity ^0.8.0;


contract MockInbox {
    using TypeCasts for bytes32;

    struct PendingMessage {
        bytes32 sender;
        bytes32 recipient;
        bytes messageBody;
    }

    mapping(uint256 => PendingMessage) pendingMessages;
    uint256 totalMessages = 0;
    uint256 messageProcessed = 0;

    function addPendingMessage(
        bytes32 _sender,
        bytes32 _recipient,
        bytes memory _messageBody
    ) external {
        pendingMessages[totalMessages] = PendingMessage(
            _sender,
            _recipient,
            _messageBody
        );
        totalMessages += 1;
    }

    function processNextPendingMessage() public {
        PendingMessage memory pendingMessage = pendingMessages[
            messageProcessed
        ];

        address recipient = pendingMessage.recipient.bytes32ToAddress();

        IMessageRecipient(recipient).handle(
            // This is completely arbitrary and consumers should not rely
            // on domain handling in the mock mailbox contracts.
            1,
            pendingMessage.sender,
            pendingMessage.messageBody
        );
        messageProcessed += 1;
    }
}


// File contracts/mock/MockOutbox.sol
pragma solidity ^0.8.0;


contract MockOutbox {
    MockInbox inbox;
    using TypeCasts for address;

    constructor(address _inbox) {
        inbox = MockInbox(_inbox);
    }

    function dispatch(
        uint32,
        bytes32 _recipientAddress,
        bytes calldata _messageBody
    ) external {
        inbox.addPendingMessage(
            msg.sender.addressToBytes32(),
            _recipientAddress,
            _messageBody
        );
    }
}


// File contracts/Outbox.sol
pragma solidity >=0.8.0;

// ============ Internal Imports ============







/**
 * @title Outbox
 * @author Celo Labs Inc.
 * @notice Accepts messages to be dispatched to remote chains,
 * constructs a Merkle tree of the messages,
 * and accepts signatures from a bonded Validator
 * which notarize the Merkle tree roots.
 * Accepts submissions of fraudulent signatures
 * by the Validator and slashes the Validator in this case.
 */
contract Outbox is IOutbox, Versioned, MerkleTreeManager, Mailbox {
    // ============ Libraries ============

    using MerkleLib for MerkleLib.Tree;
    using TypeCasts for address;

    // ============ Constants ============

    // Maximum bytes per message = 2 KiB
    // (somewhat arbitrarily set to begin)
    uint256 public constant MAX_MESSAGE_BODY_BYTES = 2 * 2**10;

    // ============ Enums ============

    // States:
    //   0 - UnInitialized - before initialize function is called
    //   note: the contract is initialized at deploy time, so it should never be in this state
    //   1 - Active - as long as the contract has not become fraudulent
    //   2 - Failed - after a valid fraud proof has been submitted;
    //   contract will no longer accept updates or new messages
    enum States {
        UnInitialized,
        Active,
        Failed
    }

    // ============ Public Storage Variables ============

    // Cached checkpoints, mapping root => leaf index.
    // Cached checkpoints must have index > 0 as the presence of such
    // a checkpoint cannot be distinguished from its absence.
    mapping(bytes32 => uint256) public cachedCheckpoints;
    // The latest cached root
    bytes32 public latestCachedRoot;
    // Current state of contract
    States public state;

    // ============ Upgrade Gap ============

    // gap for upgrade safety
    uint256[47] private __GAP;

    // ============ Events ============

    /**
     * @notice Emitted when a checkpoint is cached.
     * @param root Merkle root
     * @param index Leaf index
     */
    event CheckpointCached(bytes32 indexed root, uint256 indexed index);

    /**
     * @notice Emitted when a new message is dispatched via Abacus
     * @param leafIndex Index of message's leaf in merkle tree
     * @param message Raw bytes of message
     */
    event Dispatch(uint256 indexed leafIndex, bytes message);

    event Fail();

    // ============ Constructor ============

    constructor(uint32 _localDomain) Mailbox(_localDomain) {} // solhint-disable-line no-empty-blocks

    // ============ Initializer ============

    function initialize(address _validatorManager) external initializer {
        __Mailbox_initialize(_validatorManager);
        state = States.Active;
    }

    // ============ Modifiers ============

    /**
     * @notice Ensures that contract state != FAILED when the function is called
     */
    modifier notFailed() {
        require(state != States.Failed, "failed state");
        _;
    }

    // ============ External Functions  ============

    /**
     * @notice Dispatch the message it to the destination domain & recipient
     * @dev Format the message, insert its hash into Merkle tree,
     * and emit `Dispatch` event with message information.
     * @param _destinationDomain Domain of destination chain
     * @param _recipientAddress Address of recipient on destination chain as bytes32
     * @param _messageBody Raw bytes content of message
     * @return The leaf index of the dispatched message's hash in the Merkle tree.
     */
    function dispatch(
        uint32 _destinationDomain,
        bytes32 _recipientAddress,
        bytes calldata _messageBody
    ) external override notFailed returns (uint256) {
        require(_messageBody.length <= MAX_MESSAGE_BODY_BYTES, "msg too long");
        // The leaf has not been inserted yet at this point
        uint256 _leafIndex = count();
        // format the message into packed bytes
        bytes memory _message = Message.formatMessage(
            localDomain,
            msg.sender.addressToBytes32(),
            _destinationDomain,
            _recipientAddress,
            _messageBody
        );
        // insert the hashed message into the Merkle tree
        bytes32 _messageHash = keccak256(
            abi.encodePacked(_message, _leafIndex)
        );
        tree.insert(_messageHash);
        emit Dispatch(_leafIndex, _message);
        return _leafIndex;
    }

    /**
     * @notice Caches the current merkle root and index.
     * @dev emits CheckpointCached event
     */
    function cacheCheckpoint() external override notFailed {
        (bytes32 _root, uint256 _index) = latestCheckpoint();
        require(_index > 0, "!index");
        cachedCheckpoints[_root] = _index;
        latestCachedRoot = _root;
        emit CheckpointCached(_root, _index);
    }

    /**
     * @notice Set contract state to FAILED.
     * @dev Called by the validator manager when fraud is proven.
     */
    function fail() external override onlyValidatorManager {
        // set contract to FAILED
        state = States.Failed;
        emit Fail();
    }

    /**
     * @notice Returns the latest entry in the checkpoint cache.
     * @return root Latest cached root
     * @return index Latest cached index
     */
    function latestCachedCheckpoint()
        external
        view
        returns (bytes32 root, uint256 index)
    {
        root = latestCachedRoot;
        index = cachedCheckpoints[root];
    }

    /**
     * @notice Returns the number of inserted leaves in the tree
     */
    function count() public view returns (uint256) {
        return tree.count;
    }

    /**
     * @notice Returns a checkpoint representing the current merkle tree.
     * @return root The root of the Outbox's merkle tree.
     * @return index The index of the last element in the tree.
     */
    function latestCheckpoint() public view returns (bytes32, uint256) {
        return (root(), count() - 1);
    }
}


// File contracts/test/bad-recipient/BadRecipient1.sol
pragma solidity >=0.8.0;

contract BadRecipient1 is IMessageRecipient {
    function handle(
        uint32,
        bytes32,
        bytes calldata
    ) external pure override {
        assembly {
            revert(0, 0)
        }
    }
}


// File contracts/test/bad-recipient/BadRecipient3.sol
pragma solidity >=0.8.0;

contract BadRecipient3 is IMessageRecipient {
    function handle(
        uint32,
        bytes32,
        bytes calldata
    ) external pure override {
        assembly {
            mstore(0, 0xabcdef)
            revert(0, 32)
        }
    }
}


// File contracts/test/bad-recipient/BadRecipient5.sol
pragma solidity >=0.8.0;

contract BadRecipient5 is IMessageRecipient {
    function handle(
        uint32,
        bytes32,
        bytes calldata
    ) external pure override {
        require(false, "no can do");
    }
}


// File contracts/test/bad-recipient/BadRecipient6.sol
pragma solidity >=0.8.0;

contract BadRecipient6 is IMessageRecipient {
    function handle(
        uint32,
        bytes32,
        bytes calldata
    ) external pure override {
        require(false); // solhint-disable-line reason-string
    }
}


// File contracts/test/MysteryMath.sol

pragma solidity >=0.8.0;

abstract contract MysteryMath {
    uint256 public stateVar;

    function setState(uint256 _var) external {
        stateVar = _var;
    }

    function getState() external view returns (uint256) {
        return stateVar;
    }

    function doMath(uint256 a, uint256 b)
        external
        pure
        virtual
        returns (uint256 _result);
}


// File contracts/test/MysteryMathV1.sol

pragma solidity >=0.8.0;

contract MysteryMathV1 is MysteryMath {
    uint32 public immutable version;

    constructor() {
        version = 1;
    }

    function doMath(uint256 a, uint256 b)
        external
        pure
        override
        returns (uint256 _result)
    {
        _result = a + b;
    }
}


// File contracts/test/MysteryMathV2.sol

pragma solidity >=0.8.0;

contract MysteryMathV2 is MysteryMath {
    uint32 public immutable version;

    constructor() {
        version = 2;
    }

    function doMath(uint256 a, uint256 b)
        external
        pure
        override
        returns (uint256 _result)
    {
        _result = a * b;
    }
}


// File contracts/test/TestInbox.sol
pragma solidity >=0.8.0;

contract TestInbox is Inbox {
    using Message for bytes32;
    using TypeCasts for bytes32;

    constructor(uint32 _localDomain) Inbox(_localDomain) {} // solhint-disable-line no-empty-blocks

    function testBranchRoot(
        bytes32 leaf,
        bytes32[32] calldata proof,
        uint256 index
    ) external pure returns (bytes32) {
        return MerkleLib.branchRoot(leaf, proof, index);
    }

    function testProcess(bytes calldata _message, uint256 leafIndex) external {
        bytes32 _messageHash = keccak256(abi.encodePacked(_message, leafIndex));
        _process(_message, _messageHash);
    }

    function testHandle(
        uint32 origin,
        bytes32 sender,
        bytes32 recipient,
        bytes calldata body
    ) external {
        IMessageRecipient(recipient.bytes32ToAddress()).handle(
            origin,
            sender,
            body
        );
    }

    function setMessageStatus(bytes32 _leaf, MessageStatus status) external {
        messages[_leaf] = status;
    }

    function getRevertMsg(bytes calldata _res)
        internal
        pure
        returns (string memory)
    {
        // If the _res length is less than 68, then the transaction failed
        // silently (without a revert message)
        if (_res.length < 68) return "Transaction reverted silently";

        // Remove the selector (first 4 bytes) and decode revert string
        return abi.decode(_res[4:], (string));
    }
}


// File contracts/test/TestMailbox.sol
pragma solidity >=0.8.0;

contract TestMailbox is Mailbox {
    constructor(uint32 _localDomain) Mailbox(_localDomain) {}

    function initialize(address _validatorManager) external initializer {
        __Mailbox_initialize(_validatorManager);
    }
}


// File contracts/test/TestMerkle.sol
pragma solidity >=0.8.0;

contract TestMerkle is MerkleTreeManager {
    using MerkleLib for MerkleLib.Tree;

    // solhint-disable-next-line no-empty-blocks
    constructor() MerkleTreeManager() {}

    function insert(bytes32 _node) external {
        tree.insert(_node);
    }

    function branchRoot(
        bytes32 _leaf,
        bytes32[32] calldata _proof,
        uint256 _index
    ) external pure returns (bytes32 _node) {
        return MerkleLib.branchRoot(_leaf, _proof, _index);
    }

    /**
     * @notice Returns the number of inserted leaves in the tree
     */
    function count() public view returns (uint256) {
        return tree.count;
    }
}


// File contracts/test/TestMessage.sol
pragma solidity >=0.6.11;

contract TestMessage {
    using Message for bytes;

    function body(bytes calldata _message)
        external
        pure
        returns (bytes calldata _body)
    {
        (, , , , _body) = _message.destructure();
    }

    function origin(bytes calldata _message)
        external
        pure
        returns (uint32 _origin)
    {
        (_origin, , , , ) = _message.destructure();
    }

    function sender(bytes calldata _message)
        external
        pure
        returns (bytes32 _sender)
    {
        (, _sender, , , ) = _message.destructure();
    }

    function destination(bytes calldata _message)
        external
        pure
        returns (uint32 _destination)
    {
        (, , _destination, , ) = _message.destructure();
    }

    function recipient(bytes calldata _message)
        external
        pure
        returns (bytes32 _recipient)
    {
        (, , , _recipient, ) = _message.destructure();
    }

    function recipientAddress(bytes calldata _message)
        external
        pure
        returns (address _recipient)
    {
        (, , , _recipient, ) = _message.destructureAddresses();
    }

    function leaf(bytes calldata _message, uint256 _leafIndex)
        external
        pure
        returns (bytes32)
    {
        return _message.leaf(_leafIndex);
    }
}


// File @openzeppelin/contracts/utils/[email protected]
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}


// File @openzeppelin/contracts/utils/cryptography/[email protected]
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}


// File interfaces/IMultisigValidatorManager.sol
pragma solidity >=0.6.0;

interface IMultisigValidatorManager {
    function domain() external view returns (uint32);

    // The domain hash of the validator set's outbox chain.
    function domainHash() external view returns (bytes32);

    function threshold() external view returns (uint256);
}


// File contracts/validator-manager/MultisigValidatorManager.sol
pragma solidity >=0.8.0;

// ============ External Imports ============



// ============ Internal Imports ============

/**
 * @title MultisigValidatorManager
 * @notice Manages an ownable set of validators that ECDSA sign checkpoints to
 * reach a quorum.
 */
abstract contract MultisigValidatorManager is
    IMultisigValidatorManager,
    Ownable,
    Versioned
{
    // ============ Libraries ============

    using EnumerableSet for EnumerableSet.AddressSet;

    // ============ Immutables ============

    // The domain of the validator set's outbox chain.
    uint32 public immutable domain;

    // The domain hash of the validator set's outbox chain.
    bytes32 public immutable domainHash;

    // ============ Mutable Storage ============

    // The minimum threshold of validator signatures to constitute a quorum.
    uint256 public threshold;

    // The set of validators.
    EnumerableSet.AddressSet private validatorSet;

    // ============ Events ============

    /**
     * @notice Emitted when a validator is enrolled in the validator set.
     * @param validator The address of the validator.
     * @param validatorCount The new number of enrolled validators in the validator set.
     */
    event ValidatorEnrolled(address indexed validator, uint256 validatorCount);

    /**
     * @notice Emitted when a validator is unenrolled from the validator set.
     * @param validator The address of the validator.
     * @param validatorCount The new number of enrolled validators in the validator set.
     */
    event ValidatorUnenrolled(
        address indexed validator,
        uint256 validatorCount
    );

    /**
     * @notice Emitted when the quorum threshold is set.
     * @param threshold The new quorum threshold.
     */
    event ThresholdSet(uint256 threshold);

    // ============ Constructor ============

    /**
     * @dev Reverts if `_validators` has any duplicates.
     * @param _domain The domain of the outbox the validator set is for.
     * @param _validators The set of validator addresses.
     * @param _threshold The quorum threshold. Must be greater than or equal
     * to the length of `_validators`.
     */
    constructor(
        uint32 _domain,
        address[] memory _validators,
        uint256 _threshold
    ) Ownable() {
        // Set immutables.
        domain = _domain;
        domainHash = _domainHash(_domain);

        // Enroll validators. Reverts if there are any duplicates.
        uint256 _numValidators = _validators.length;
        for (uint256 i = 0; i < _numValidators; i++) {
            _enrollValidator(_validators[i]);
        }

        _setThreshold(_threshold);
    }

    // ============ External Functions ============

    /**
     * @notice Enrolls a validator into the validator set.
     * @dev Reverts if `_validator` is already in the validator set.
     * @param _validator The validator to add to the validator set.
     */
    function enrollValidator(address _validator) external onlyOwner {
        _enrollValidator(_validator);
    }

    /**
     * @notice Unenrolls a validator from the validator set.
     * @dev Reverts if `_validator` is not in the validator set.
     * @param _validator The validator to remove from the validator set.
     */
    function unenrollValidator(address _validator) external onlyOwner {
        _unenrollValidator(_validator);
    }

    /**
     * @notice Sets the quorum threshold.
     * @param _threshold The new quorum threshold.
     */
    function setThreshold(uint256 _threshold) external onlyOwner {
        _setThreshold(_threshold);
    }

    /**
     * @notice Gets the addresses of the current validator set.
     * @dev There are no ordering guarantees due to the semantics of EnumerableSet.AddressSet.
     * @return The addresses of the validator set.
     */
    function validators() external view returns (address[] memory) {
        uint256 _numValidators = validatorSet.length();
        address[] memory _validators = new address[](_numValidators);
        for (uint256 i = 0; i < _numValidators; i++) {
            _validators[i] = validatorSet.at(i);
        }
        return _validators;
    }

    // ============ Public Functions ============

    /**
     * @notice Returns whether provided signatures over a checkpoint constitute
     * a quorum of validator signatures.
     * @dev Reverts if `_signatures` is not sorted in ascending order by the signer
     * address, which is required for duplicate detection.
     * @dev Does not revert if a signature's signer is not in the validator set.
     * @param _root The merkle root of the checkpoint.
     * @param _index The index of the checkpoint.
     * @param _signatures Signatures over the checkpoint to be checked for a validator
     * quorum. Must be sorted in ascending order by signer address.
     * @return TRUE iff `_signatures` constitute a quorum of validator signatures over
     * the checkpoint.
     */
    function isQuorum(
        bytes32 _root,
        uint256 _index,
        bytes[] calldata _signatures
    ) public view returns (bool) {
        uint256 _numSignatures = _signatures.length;
        // If there are fewer signatures provided than the required quorum threshold,
        // this is not a quorum.
        if (_numSignatures < threshold) {
            return false;
        }
        // To identify duplicates, the signers recovered from _signatures
        // must be sorted in ascending order. previousSigner is used to
        // enforce ordering.
        address _previousSigner = address(0);
        uint256 _validatorSignatureCount = 0;
        for (uint256 i = 0; i < _numSignatures; i++) {
            address _signer = _recoverCheckpointSigner(
                _root,
                _index,
                _signatures[i]
            );
            // Revert if the signer violates the required sort order.
            require(_previousSigner < _signer, "!sorted signers");
            // If the signer is a validator, increment _validatorSignatureCount.
            if (isValidator(_signer)) {
                _validatorSignatureCount++;
            }
            _previousSigner = _signer;
        }
        return _validatorSignatureCount >= threshold;
    }

    /**
     * @notice Returns if `_validator` is enrolled in the validator set.
     * @param _validator The address of the validator.
     * @return TRUE iff `_validator` is enrolled in the validator set.
     */
    function isValidator(address _validator) public view returns (bool) {
        return validatorSet.contains(_validator);
    }

    /**
     * @notice Returns the number of validators enrolled in the validator set.
     * @return The number of validators enrolled in the validator set.
     */
    function validatorCount() public view returns (uint256) {
        return validatorSet.length();
    }

    // ============ Internal Functions ============

    /**
     * @notice Recovers the signer from a signature of a checkpoint.
     * @param _root The checkpoint's merkle root.
     * @param _index The checkpoint's index.
     * @param _signature Signature on the the checkpoint.
     * @return The signer of the checkpoint signature.
     **/
    function _recoverCheckpointSigner(
        bytes32 _root,
        uint256 _index,
        bytes calldata _signature
    ) internal view returns (address) {
        bytes32 _digest = keccak256(
            abi.encodePacked(domainHash, _root, _index)
        );
        return ECDSA.recover(ECDSA.toEthSignedMessageHash(_digest), _signature);
    }

    /**
     * @notice Enrolls a validator into the validator set.
     * @dev Reverts if `_validator` is already in the validator set.
     * @param _validator The validator to add to the validator set.
     */
    function _enrollValidator(address _validator) internal {
        require(_validator != address(0), "zero address");
        require(validatorSet.add(_validator), "already enrolled");
        emit ValidatorEnrolled(_validator, validatorCount());
    }

    /**
     * @notice Unenrolls a validator from the validator set.
     * @dev Reverts if the resulting validator set length is less than
     * the quorum threshold.
     * @dev Reverts if `_validator` is not in the validator set.
     * @param _validator The validator to remove from the validator set.
     */
    function _unenrollValidator(address _validator) internal {
        require(validatorSet.remove(_validator), "!enrolled");
        uint256 _numValidators = validatorCount();
        require(_numValidators >= threshold, "violates quorum threshold");
        emit ValidatorUnenrolled(_validator, _numValidators);
    }

    /**
     * @notice Sets the quorum threshold.
     * @param _threshold The new quorum threshold.
     */
    function _setThreshold(uint256 _threshold) internal {
        require(_threshold > 0 && _threshold <= validatorCount(), "!range");
        threshold = _threshold;
        emit ThresholdSet(_threshold);
    }

    /**
     * @notice Hash of `_domain` concatenated with "ABACUS" and deployment version.
     * @dev Domain hash is salted with deployment version to prevent validator signature replay.
     * @param _domain The domain to hash.
     */
    function _domainHash(uint32 _domain) internal pure returns (bytes32) {
        if (VERSION > 0) {
            return keccak256(abi.encodePacked(_domain, "ABACUS", VERSION));
        } else {
            // for backwards compatibility with initial deployment (VERSION == 0)
            return keccak256(abi.encodePacked(_domain, "ABACUS"));
        }
    }
}


// File contracts/test/TestMultisigValidatorManager.sol
pragma solidity >=0.8.0;

/**
 * This contract exists to test MultisigValidatorManager.sol, which is abstract
 * and cannot be deployed directly.
 */
contract TestMultisigValidatorManager is MultisigValidatorManager {
    // solhint-disable-next-line no-empty-blocks
    constructor(
        uint32 _domain,
        address[] memory _validators,
        uint256 _threshold
    ) MultisigValidatorManager(_domain, _validators, _threshold) {}

    /**
     * @notice Hash of domain concatenated with "ABACUS".
     * @dev This is a public getter of _domainHash to test with.
     * @param _domain The domain to hash.
     */
    function getDomainHash(uint32 _domain) external pure returns (bytes32) {
        return _domainHash(_domain);
    }
}


// File contracts/test/TestOutbox.sol
pragma solidity >=0.8.0;

// ============ Internal Imports ============


contract TestOutbox is Outbox {
    constructor(uint32 _localDomain) Outbox(_localDomain) {} // solhint-disable-line no-empty-blocks

    /**
     * @notice Set the validator manager
     * @param _validatorManager Address of the validator manager
     */
    function testSetValidatorManager(address _validatorManager) external {
        validatorManager = _validatorManager;
    }

    function proof() external view returns (bytes32[32] memory) {
        bytes32[32] memory _zeroes = MerkleLib.zeroHashes();
        uint256 _index = tree.count - 1;
        bytes32[32] memory _proof;

        for (uint256 i = 0; i < 32; i++) {
            uint256 _ithBit = (_index >> i) & 0x01;
            if (_ithBit == 1) {
                _proof[i] = tree.branch[i];
            } else {
                _proof[i] = _zeroes[i];
            }
        }
        return _proof;
    }

    function branch() external view returns (bytes32[32] memory) {
        return tree.branch;
    }

    function branchRoot(
        bytes32 _item,
        bytes32[32] memory _branch,
        uint256 _index
    ) external pure returns (bytes32) {
        return MerkleLib.branchRoot(_item, _branch, _index);
    }
}


// File contracts/test/TestRecipient.sol
pragma solidity >=0.8.0;

contract TestRecipient is IMessageRecipient {
    bytes32 public lastSender;
    bytes public lastData;

    address public lastCaller;
    string public lastCallMessage;

    event ReceivedMessage(
        uint32 indexed origin,
        bytes32 indexed sender,
        string message
    );

    event ReceivedCall(address indexed caller, uint256 amount, string message);

    function handle(
        uint32 _origin,
        bytes32 _sender,
        bytes calldata _data
    ) external override {
        emit ReceivedMessage(_origin, _sender, string(_data));
        lastSender = _sender;
        lastData = _data;
    }

    function fooBar(uint256 amount, string calldata message) external {
        emit ReceivedCall(msg.sender, amount, message);
        lastCaller = msg.sender;
        lastCallMessage = message;
    }
}


// File contracts/test/TestSendReceiver.sol
pragma solidity >=0.8.0;



contract TestSendReceiver is IMessageRecipient {
    using TypeCasts for address;

    event Handled(bytes32 blockHash);

    function dispatchToSelf(
        IOutbox _outbox,
        IInterchainGasPaymaster _paymaster,
        uint32 _destinationDomain,
        bytes calldata _messageBody
    ) external payable {
        uint256 _leafIndex = _outbox.dispatch(
            _destinationDomain,
            address(this).addressToBytes32(),
            _messageBody
        );
        uint256 _blockHashNum = uint256(previousBlockHash());
        uint256 _value = msg.value;
        if (_blockHashNum % 5 == 0) {
            // Pay in two separate calls, resulting in 2 distinct events
            uint256 _half = _value / 2;
            _paymaster.payGasFor{value: _half}(
                address(_outbox),
                _leafIndex,
                _destinationDomain
            );
            _paymaster.payGasFor{value: _value - _half}(
                address(_outbox),
                _leafIndex,
                _destinationDomain
            );
        } else {
            // Pay the entire msg.value in one call
            _paymaster.payGasFor{value: _value}(
                address(_outbox),
                _leafIndex,
                _destinationDomain
            );
        }
    }

    function handle(
        uint32,
        bytes32,
        bytes calldata
    ) external override {
        bytes32 blockHash = previousBlockHash();
        bool isBlockHashEven = uint256(blockHash) % 2 == 0;
        require(isBlockHashEven, "block hash is odd");
        emit Handled(blockHash);
    }

    function previousBlockHash() internal view returns (bytes32) {
        return blockhash(block.number - 1);
    }
}


// File contracts/test/TestValidatorManager.sol
pragma solidity >=0.8.0;

/**
 * Intended for testing Inbox.sol, which requires its validator manager
 * to be a contract.
 */
contract TestValidatorManager {
    function process(
        IInbox _inbox,
        bytes32 _root,
        uint256 _index,
        bytes calldata _message,
        bytes32[32] calldata _proof,
        uint256 _leafIndex
    ) external {
        _inbox.process(_root, _index, _message, _proof, _leafIndex);
    }
}


// File contracts/upgrade/UpgradeBeacon.sol
pragma solidity >=0.8.0;

// ============ External Imports ============

/**
 * @title UpgradeBeacon
 * @notice Stores the address of an implementation contract
 * and allows a controller to upgrade the implementation address
 * @dev This implementation combines the gas savings of having no function selectors
 * found in 0age's implementation:
 * https://github.com/dharma-eng/dharma-smart-wallet/blob/master/contracts/proxies/smart-wallet/UpgradeBeaconProxyV1.sol
 * With the added niceties of a safety check that each implementation is a contract
 * and an Upgrade event emitted each time the implementation is changed
 * found in OpenZeppelin's implementation:
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/proxy/beacon/BeaconProxy.sol
 */
contract UpgradeBeacon {
    // ============ Immutables ============

    // The controller is capable of modifying the implementation address
    address private immutable controller;

    // ============ Private Storage Variables ============

    // The implementation address is held in storage slot zero.
    address private implementation;

    // ============ Events ============

    // Upgrade event is emitted each time the implementation address is set
    // (including deployment)
    event Upgrade(address indexed implementation);

    // ============ Constructor ============

    /**
     * @notice Validate the initial implementation and store it.
     * Store the controller immutably.
     * @param _initialImplementation Address of the initial implementation contract
     * @param _controller Address of the controller who can upgrade the implementation
     */
    constructor(address _initialImplementation, address _controller) payable {
        _setImplementation(_initialImplementation);
        controller = _controller;
    }

    // ============ External Functions ============

    /**
     * @notice For all callers except the controller, return the current implementation address.
     * If called by the Controller, update the implementation address
     * to the address passed in the calldata.
     * Note: this requires inline assembly because Solidity fallback functions
     * do not natively take arguments or return values.
     */
    fallback() external payable {
        if (msg.sender != controller) {
            // if not called by the controller,
            // load implementation address from storage slot zero
            // and return it.
            assembly {
                mstore(0, sload(0))
                return(0, 32)
            }
        } else {
            // if called by the controller,
            // load new implementation address from the first word of the calldata
            address _newImplementation;
            assembly {
                _newImplementation := calldataload(0)
            }
            // set the new implementation
            _setImplementation(_newImplementation);
        }
    }

    // ============ Private Functions ============

    /**
     * @notice Perform checks on the new implementation address
     * then upgrade the stored implementation.
     * @param _newImplementation Address of the new implementation contract which will replace the old one
     */
    function _setImplementation(address _newImplementation) private {
        // Require that the new implementation is different from the current one
        require(implementation != _newImplementation, "!upgrade");
        // Require that the new implementation is a contract
        require(
            Address.isContract(_newImplementation),
            "implementation !contract"
        );
        // set the new implementation
        implementation = _newImplementation;
        emit Upgrade(_newImplementation);
    }
}


// File contracts/upgrade/UpgradeBeaconController.sol
pragma solidity >=0.8.0;

// ============ Internal Imports ============

// ============ External Imports ============


/**
 * @title UpgradeBeaconController
 * @notice Set as the controller of UpgradeBeacon contract(s),
 * capable of changing their stored implementation address.
 * @dev This implementation is a minimal version inspired by 0age's implementation:
 * https://github.com/dharma-eng/dharma-smart-wallet/blob/master/contracts/upgradeability/DharmaUpgradeBeaconController.sol
 */
contract UpgradeBeaconController is Ownable {
    // ============ Events ============

    event BeaconUpgraded(address indexed beacon, address implementation);

    // ============ External Functions ============

    /**
     * @notice Modify the implementation stored in the UpgradeBeacon,
     * which will upgrade the implementation used by all
     * Proxy contracts using that UpgradeBeacon
     * @param _beacon Address of the UpgradeBeacon which will be updated
     * @param _implementation Address of the Implementation contract to upgrade the Beacon to
     */
    function upgrade(address _beacon, address _implementation)
        external
        onlyOwner
    {
        // Require that the beacon is a contract
        require(Address.isContract(_beacon), "beacon !contract");
        // Call into beacon and supply address of new implementation to update it.
        (bool _success, ) = _beacon.call(abi.encode(_implementation));
        // Revert with message on failure (i.e. if the beacon is somehow incorrect).
        if (!_success) {
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
        emit BeaconUpgraded(_beacon, _implementation);
    }
}


// File contracts/upgrade/UpgradeBeaconProxy.sol
pragma solidity >=0.8.0;

// ============ External Imports ============

/**
 * @title UpgradeBeaconProxy
 * @notice
 * Proxy contract which delegates all logic, including initialization,
 * to an implementation contract.
 * The implementation contract is stored within an Upgrade Beacon contract;
 * the implementation contract can be changed by performing an upgrade on the Upgrade Beacon contract.
 * The Upgrade Beacon contract for this Proxy is immutably specified at deployment.
 * @dev This implementation combines the gas savings of keeping the UpgradeBeacon address outside of contract storage
 * found in 0age's implementation:
 * https://github.com/dharma-eng/dharma-smart-wallet/blob/master/contracts/proxies/smart-wallet/UpgradeBeaconProxyV1.sol
 * With the added safety checks that the UpgradeBeacon and implementation are contracts at time of deployment
 * found in OpenZeppelin's implementation:
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/proxy/beacon/BeaconProxy.sol
 */
contract UpgradeBeaconProxy {
    // ============ Immutables ============

    // Upgrade Beacon address is immutable (therefore not kept in contract storage)
    address private immutable upgradeBeacon;

    // ============ Constructor ============

    /**
     * @notice Validate that the Upgrade Beacon is a contract, then set its
     * address immutably within this contract.
     * Validate that the implementation is also a contract,
     * Then call the initialization function defined at the implementation.
     * The deployment will revert and pass along the
     * revert reason if the initialization function reverts.
     * @param _upgradeBeacon Address of the Upgrade Beacon to be stored immutably in the contract
     * @param _initializationCalldata Calldata supplied when calling the initialization function
     */
    constructor(address _upgradeBeacon, bytes memory _initializationCalldata)
        payable
    {
        // Validate the Upgrade Beacon is a contract
        require(Address.isContract(_upgradeBeacon), "beacon !contract");
        // set the Upgrade Beacon
        upgradeBeacon = _upgradeBeacon;
        // Validate the implementation is a contract
        address _implementation = _getImplementation(_upgradeBeacon);
        require(
            Address.isContract(_implementation),
            "beacon implementation !contract"
        );
        // Call the initialization function on the implementation
        if (_initializationCalldata.length > 0) {
            _initialize(_implementation, _initializationCalldata);
        }
    }

    // ============ External Functions ============

    /**
     * @notice Forwards all calls with data to _fallback()
     * No public functions are declared on the contract, so all calls hit fallback
     */
    fallback() external payable {
        _fallback();
    }

    /**
     * @notice Forwards all calls with no data to _fallback()
     */
    receive() external payable {
        _fallback();
    }

    // ============ Private Functions ============

    /**
     * @notice Call the initialization function on the implementation
     * Used at deployment to initialize the proxy
     * based on the logic for initialization defined at the implementation
     * @param _implementation - Contract to which the initalization is delegated
     * @param _initializationCalldata - Calldata supplied when calling the initialization function
     */
    function _initialize(
        address _implementation,
        bytes memory _initializationCalldata
    ) private {
        // Delegatecall into the implementation, supplying initialization calldata.
        (bool _ok, ) = _implementation.delegatecall(_initializationCalldata);
        // Revert and include revert data if delegatecall to implementation reverts.
        if (!_ok) {
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
    }

    /**
     * @notice Delegates function calls to the implementation contract returned by the Upgrade Beacon
     */
    function _fallback() private {
        _delegate(_getImplementation());
    }

    /**
     * @notice Delegate function execution to the implementation contract
     * @dev This is a low level function that doesn't return to its internal
     * call site. It will return whatever is returned by the implementation to the
     * external caller, reverting and returning the revert data if implementation
     * reverts.
     * @param _implementation - Address to which the function execution is delegated
     */
    function _delegate(address _implementation) private {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())
            // Delegatecall to the implementation, supplying calldata and gas.
            // Out and outsize are set to zero - instead, use the return buffer.
            let result := delegatecall(
                gas(),
                _implementation,
                0,
                calldatasize(),
                0,
                0
            )
            // Copy the returned data from the return buffer.
            returndatacopy(0, 0, returndatasize())
            switch result
            // Delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @notice Call the Upgrade Beacon to get the current implementation contract address
     * @return _implementation Address of the current implementation.
     */
    function _getImplementation()
        private
        view
        returns (address _implementation)
    {
        _implementation = _getImplementation(upgradeBeacon);
    }

    /**
     * @notice Call the Upgrade Beacon to get the current implementation contract address
     * @dev _upgradeBeacon is passed as a parameter so that
     * we can also use this function in the constructor,
     * where we can't access immutable variables.
     * @param _upgradeBeacon Address of the UpgradeBeacon storing the current implementation
     * @return _implementation Address of the current implementation.
     */
    function _getImplementation(address _upgradeBeacon)
        private
        view
        returns (address _implementation)
    {
        // Get the current implementation address from the upgrade beacon.
        (bool _ok, bytes memory _returnData) = _upgradeBeacon.staticcall("");
        // Revert and pass along revert message if call to upgrade beacon reverts.
        require(_ok, string(_returnData));
        // Set the implementation to the address returned from the upgrade beacon.
        _implementation = abi.decode(_returnData, (address));
    }
}


// File contracts/validator-manager/InboxValidatorManager.sol
pragma solidity >=0.8.0;

// ============ Internal Imports ============


/**
 * @title InboxValidatorManager
 * @notice Verifies checkpoints are signed by a quorum of validators and submits
 * them to an Inbox.
 */
contract InboxValidatorManager is MultisigValidatorManager {
    // ============ Constructor ============

    /**
     * @dev Reverts if `_validators` has any duplicates.
     * @param _remoteDomain The remote domain of the outbox chain.
     * @param _validators The set of validator addresses.
     * @param _threshold The quorum threshold. Must be greater than or equal
     * to the length of `_validators`.
     */
    // solhint-disable-next-line no-empty-blocks
    constructor(
        uint32 _remoteDomain,
        address[] memory _validators,
        uint256 _threshold
    ) MultisigValidatorManager(_remoteDomain, _validators, _threshold) {}

    // ============ External Functions ============

    /**
     * @notice Verifies a signed checkpoint and submits a message for processing.
     * @dev Reverts if `_signatures` is not a quorum of validator signatures.
     * @dev Reverts if `_signatures` is not sorted in ascending order by the signer
     * address, which is required for duplicate detection.
     * @param _inbox The inbox to submit the message to.
     * @param _root The merkle root of the signed checkpoint.
     * @param _index The index of the signed checkpoint.
     * @param _signatures Signatures over the checkpoint to be checked for a validator
     * quorum. Must be sorted in ascending order by signer address.
     * @param _message The message to process.
     * @param _proof Merkle proof of inclusion for message's leaf
     * @param _leafIndex Index of leaf in outbox's merkle tree
     */
    function process(
        IInbox _inbox,
        bytes32 _root,
        uint256 _index,
        bytes[] calldata _signatures,
        bytes calldata _message,
        bytes32[32] calldata _proof,
        uint256 _leafIndex
    ) external {
        require(isQuorum(_root, _index, _signatures), "!quorum");
        _inbox.process(_root, _index, _message, _proof, _leafIndex);
    }
}


// File contracts/validator-manager/OutboxValidatorManager.sol
pragma solidity >=0.8.0;

// ============ Internal Imports ============



/**
 * @title OutboxValidatorManager
 * @notice Verifies if an premature or fraudulent checkpoint has been signed by a quorum of
 * validators and reports it to an Outbox.
 */
contract OutboxValidatorManager is MultisigValidatorManager {
    // ============ Events ============

    /**
     * @notice Emitted when a checkpoint is proven premature.
     * @dev Observers of this event should filter by the outbox address.
     * @param outbox The outbox.
     * @param signedRoot Root of the premature checkpoint.
     * @param signedIndex Index of the premature checkpoint.
     * @param signatures A quorum of signatures on the premature checkpoint.
     * May include non-validator signatures.
     * @param count The number of messages in the Outbox.
     */
    event PrematureCheckpoint(
        address indexed outbox,
        bytes32 signedRoot,
        uint256 signedIndex,
        bytes[] signatures,
        uint256 count
    );

    /**
     * @notice Emitted when a checkpoint is proven fraudulent.
     * @dev Observers of this event should filter by the outbox address.
     * @param outbox The outbox.
     * @param signedRoot Root of the fraudulent checkpoint.
     * @param signedIndex Index of the fraudulent checkpoint.
     * @param signatures A quorum of signatures on the fraudulent checkpoint.
     * May include non-validator signatures.
     * @param fraudulentLeaf The leaf in the fraudulent tree.
     * @param fraudulentProof Proof of inclusion of fraudulentLeaf.
     * @param actualLeaf The leaf in the Outbox's tree.
     * @param actualProof Proof of inclusion of actualLeaf.
     * @param leafIndex The index of the leaves that are being proved.
     */
    event FraudulentCheckpoint(
        address indexed outbox,
        bytes32 signedRoot,
        uint256 signedIndex,
        bytes[] signatures,
        bytes32 fraudulentLeaf,
        bytes32[32] fraudulentProof,
        bytes32 actualLeaf,
        bytes32[32] actualProof,
        uint256 leafIndex
    );

    // ============ Constructor ============

    /**
     * @dev Reverts if `_validators` has any duplicates.
     * @param _localDomain The local domain.
     * @param _validators The set of validator addresses.
     * @param _threshold The quorum threshold. Must be greater than or equal
     * to the length of `_validators`.
     */
    // solhint-disable-next-line no-empty-blocks
    constructor(
        uint32 _localDomain,
        address[] memory _validators,
        uint256 _threshold
    ) MultisigValidatorManager(_localDomain, _validators, _threshold) {}

    // ============ External Functions ============

    /**
     * @notice Determines if a quorum of validators have signed a premature checkpoint,
     * failing the Outbox if so.
     * A checkpoint is premature if it commits to more messages than are present in the
     * Outbox's merkle tree.
     * @dev Premature checkpoints signed by individual validators are not handled to prevent
     * a single byzantine validator from failing the Outbox.
     * @param _outbox The outbox.
     * @param _signedRoot The root of the signed checkpoint.
     * @param _signedIndex The index of the signed checkpoint.
     * @param _signatures Signatures over the checkpoint to be checked for a validator
     * quorum. Must be sorted in ascending order by signer address.
     * @return True iff prematurity was proved.
     */
    function prematureCheckpoint(
        IOutbox _outbox,
        bytes32 _signedRoot,
        uint256 _signedIndex,
        bytes[] calldata _signatures
    ) external returns (bool) {
        require(isQuorum(_signedRoot, _signedIndex, _signatures), "!quorum");
        // Checkpoints are premature if the checkpoint commits to more messages
        // than the Outbox has in its merkle tree.
        uint256 count = _outbox.count();
        require(_signedIndex >= count, "!premature");
        _outbox.fail();
        emit PrematureCheckpoint(
            address(_outbox),
            _signedRoot,
            _signedIndex,
            _signatures,
            count
        );
        return true;
    }

    /**
     * @notice Determines if a quorum of validators have signed a fraudulent checkpoint,
     * failing the Outbox if so.
     * A checkpoint is fraudulent if the leaf it commits to at index I differs
     * from the leaf the Outbox committed to at index I, where I is less than or equal
     * to the index of the checkpoint.
     * This difference can be proved by comparing two merkle proofs for leaf
     * index J >= I. One against the fraudulent checkpoint, and one against a
     * checkpoint cached on the Outbox.
     * @dev Fraudulent checkpoints signed by individual validators are not handled to prevent
     * a single byzantine validator from failing the Outbox.
     * @param _outbox The outbox.
     * @param _signedRoot The root of the signed checkpoint.
     * @param _signedIndex The index of the signed checkpoint.
     * @param _signatures Signatures over the checkpoint to be checked for a validator
     * quorum. Must be sorted in ascending order by signer address.
     * @param _fraudulentLeaf The leaf in the fraudulent tree.
     * @param _fraudulentProof Proof of inclusion of `_fraudulentLeaf`.
     * @param _actualLeaf The leaf in the Outbox's tree.
     * @param _actualProof Proof of inclusion of `_actualLeaf`.
     * @param _leafIndex The index of the leaves that are being proved.
     * @return True iff fraud was proved.
     */
    function fraudulentCheckpoint(
        IOutbox _outbox,
        bytes32 _signedRoot,
        uint256 _signedIndex,
        bytes[] calldata _signatures,
        bytes32 _fraudulentLeaf,
        bytes32[32] calldata _fraudulentProof,
        bytes32 _actualLeaf,
        bytes32[32] calldata _actualProof,
        uint256 _leafIndex
    ) external returns (bool) {
        // Check the signed checkpoint commits to _fraudulentLeaf at _leafIndex.
        require(isQuorum(_signedRoot, _signedIndex, _signatures), "!quorum");
        bytes32 _fraudulentRoot = MerkleLib.branchRoot(
            _fraudulentLeaf,
            _fraudulentProof,
            _leafIndex
        );
        require(_fraudulentRoot == _signedRoot, "!root");
        require(_signedIndex >= _leafIndex, "!index");

        // Check the cached checkpoint commits to _actualLeaf at _leafIndex.
        bytes32 _cachedRoot = MerkleLib.branchRoot(
            _actualLeaf,
            _actualProof,
            _leafIndex
        );
        uint256 _cachedIndex = _outbox.cachedCheckpoints(_cachedRoot);
        require(_cachedIndex > 0 && _cachedIndex >= _leafIndex, "!cache");

        // Check that the two roots commit to at least one differing leaf
        // with index <= _leafIndex.
        require(
            impliesDifferingLeaf(
                _fraudulentLeaf,
                _fraudulentProof,
                _actualLeaf,
                _actualProof,
                _leafIndex
            ),
            "!fraud"
        );

        // Fail the Outbox.
        _outbox.fail();
        emit FraudulentCheckpoint(
            address(_outbox),
            _signedRoot,
            _signedIndex,
            _signatures,
            _fraudulentLeaf,
            _fraudulentProof,
            _actualLeaf,
            _actualProof,
            _leafIndex
        );
        return true;
    }

    /**
     * @notice Returns true if the implied merkle roots commit to at least one
     * differing leaf with index <= `_leafIndex`.
     * Given a merkle proof for leaf index J, we can determine whether an
     * element in the proof is an internal node whose terminal children are leaves
     * with index <= J.
     * Given two merkle proofs for leaf index J, if such elements do not match,
     * these two proofs necessarily commit to at least one differing leaf with
     * index I <= J.
     * @param _leafA The leaf in tree A.
     * @param _proofA Proof of inclusion of `_leafA` in tree A.
     * @param _leafB The leaf in tree B.
     * @param _proofB Proof of inclusion of `_leafB` in tree B.
     * @param _leafIndex The index of `_leafA` and `_leafB`.
     * @return differ True if the implied trees differ, false if not.
     */
    function impliesDifferingLeaf(
        bytes32 _leafA,
        bytes32[32] calldata _proofA,
        bytes32 _leafB,
        bytes32[32] calldata _proofB,
        uint256 _leafIndex
    ) public pure returns (bool) {
        // The implied merkle roots commit to at least one differing leaf
        // with index <= _leafIndex, if either:

        // 1. If the provided leaves differ.
        if (_leafA != _leafB) {
            return true;
        }

        // 2. If the branches contain internal nodes whose subtrees are full
        // (as implied by _leafIndex) that differ from one another.
        for (uint8 i = 0; i < 32; i++) {
            uint256 _ithBit = (_leafIndex >> i) & 0x01;
            // If the i'th is 1, the i'th element in the proof is an internal
            // node whose subtree is full.
            // If these nodes differ, at least one leaf that they commit to
            // must differ as well.
            if (_ithBit == 1) {
                if (_proofA[i] != _proofB[i]) {
                    return true;
                }
            }
        }
        return false;
    }
}


// File contracts/Create2Factory.sol
// Copied from https://github.com/axelarnetwork/axelar-utils-solidity/commits/main/contracts/ConstAddressDeployer.sol

pragma solidity ^0.8.0;

contract Create2Factory {
    error EmptyBytecode();
    error FailedDeploy();
    error FailedInit();

    event Deployed(
        bytes32 indexed bytecodeHash,
        bytes32 indexed salt,
        address indexed deployedAddress
    );

    /**
     * @dev Deploys a contract using `CREATE2`. The address where the contract
     * will be deployed can be known in advance via {deployedAddress}.
     *
     * The bytecode for a contract can be obtained from Solidity with
     * `type(contractName).creationCode`.
     *
     * Requirements:
     *
     * - `bytecode` must not be empty.
     * - `salt` must have not been used for `bytecode` already by the same `msg.sender`.
     */
    function deploy(bytes memory bytecode, bytes32 salt)
        external
        returns (address deployedAddress_)
    {
        deployedAddress_ = _deploy(
            bytecode,
            keccak256(abi.encode(msg.sender, salt))
        );
    }

    /**
     * @dev Deploys a contract using `CREATE2` and initialize it. The address where the contract
     * will be deployed can be known in advance via {deployedAddress}.
     *
     * The bytecode for a contract can be obtained from Solidity with
     * `type(contractName).creationCode`.
     *
     * Requirements:
     *
     * - `bytecode` must not be empty.
     * - `salt` must have not been used for `bytecode` already by the same `msg.sender`.
     * - `init` is used to initialize the deployed contract
     *    as an option to not have the constructor args affect the address derived by `CREATE2`.
     */
    function deployAndInit(
        bytes memory bytecode,
        bytes32 salt,
        bytes calldata init
    ) external returns (address deployedAddress_) {
        deployedAddress_ = _deploy(
            bytecode,
            keccak256(abi.encode(msg.sender, salt))
        );

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = deployedAddress_.call(init);
        if (!success) revert FailedInit();
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy} or {deployAndInit} by `sender`.
     * Any change in the `bytecode`, `sender`, or `salt` will result in a new destination address.
     */
    function deployedAddress(
        bytes calldata bytecode,
        address sender,
        bytes32 salt
    ) external view returns (address deployedAddress_) {
        bytes32 newSalt = keccak256(abi.encode(sender, salt));
        deployedAddress_ = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            address(this),
                            newSalt,
                            keccak256(bytecode) // init code hash
                        )
                    )
                )
            )
        );
    }

    function _deploy(bytes memory bytecode, bytes32 salt)
        internal
        returns (address deployedAddress_)
    {
        if (bytecode.length == 0) revert EmptyBytecode();

        // solhint-disable-next-line no-inline-assembly
        assembly {
            deployedAddress_ := create2(
                0,
                add(bytecode, 32),
                mload(bytecode),
                salt
            )
        }

        if (deployedAddress_ == address(0)) revert FailedDeploy();

        emit Deployed(keccak256(bytecode), salt, deployedAddress_);
    }
}


// File contracts/test/bad-recipient/BadRecipient2.sol
pragma solidity >=0.8.0;

contract BadRecipient2 {
    function handle(uint32, bytes32) external pure {} // solhint-disable-line no-empty-blocks
}