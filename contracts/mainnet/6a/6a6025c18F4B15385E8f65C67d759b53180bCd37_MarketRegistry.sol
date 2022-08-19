// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/Address.sol";

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
        return !Address.isContract(address(this));
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

pragma solidity >=0.8.0 <0.9.0;
// SPDX-License-Identifier: MIT

import "../Types.sol";
import "../interfaces/IEAS.sol";
import "../interfaces/IASRegistry.sol";

/**
 * @title TellerAS - Teller Attestation Service - based on EAS - Ethereum Attestation Service
 */
contract TellerAS is IEAS {
    error AccessDenied();
    error AlreadyRevoked();
    error InvalidAttestation();
    error InvalidExpirationTime();
    error InvalidOffset();
    error InvalidRegistry();
    error InvalidSchema();
    error InvalidVerifier();
    error NotFound();
    error NotPayable();

    string public constant VERSION = "0.8";

    // A terminator used when concatenating and hashing multiple fields.
    string private constant HASH_TERMINATOR = "@";

    // The AS global registry.
    IASRegistry private immutable _asRegistry;

    // The EIP712 verifier used to verify signed attestations.
    IEASEIP712Verifier private immutable _eip712Verifier;

    // A mapping between attestations and their related attestations.
    mapping(bytes32 => bytes32[]) private _relatedAttestations;

    // A mapping between an account and its received attestations.
    mapping(address => mapping(bytes32 => bytes32[]))
        private _receivedAttestations;

    // A mapping between an account and its sent attestations.
    mapping(address => mapping(bytes32 => bytes32[])) private _sentAttestations;

    // A mapping between a schema and its attestations.
    mapping(bytes32 => bytes32[]) private _schemaAttestations;

    // The global mapping between attestations and their UUIDs.
    mapping(bytes32 => Attestation) private _db;

    // The global counter for the total number of attestations.
    uint256 private _attestationsCount;

    bytes32 private _lastUUID;

    /**
     * @dev Creates a new EAS instance.
     *
     * @param registry The address of the global AS registry.
     * @param verifier The address of the EIP712 verifier.
     */
    constructor(IASRegistry registry, IEASEIP712Verifier verifier) {
        if (address(registry) == address(0x0)) {
            revert InvalidRegistry();
        }

        if (address(verifier) == address(0x0)) {
            revert InvalidVerifier();
        }

        _asRegistry = registry;
        _eip712Verifier = verifier;
    }

    /**
     * @inheritdoc IEAS
     */
    function getASRegistry() external view override returns (IASRegistry) {
        return _asRegistry;
    }

    /**
     * @inheritdoc IEAS
     */
    function getEIP712Verifier()
        external
        view
        override
        returns (IEASEIP712Verifier)
    {
        return _eip712Verifier;
    }

    /**
     * @inheritdoc IEAS
     */
    function getAttestationsCount() external view override returns (uint256) {
        return _attestationsCount;
    }

    /**
     * @inheritdoc IEAS
     */
    function attest(
        address recipient,
        bytes32 schema,
        uint256 expirationTime,
        bytes32 refUUID,
        bytes calldata data
    ) public payable virtual override returns (bytes32) {
        return
            _attest(
                recipient,
                schema,
                expirationTime,
                refUUID,
                data,
                msg.sender
            );
    }

    /**
     * @inheritdoc IEAS
     */
    function attestByDelegation(
        address recipient,
        bytes32 schema,
        uint256 expirationTime,
        bytes32 refUUID,
        bytes calldata data,
        address attester,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public payable virtual override returns (bytes32) {
        _eip712Verifier.attest(
            recipient,
            schema,
            expirationTime,
            refUUID,
            data,
            attester,
            v,
            r,
            s
        );

        return
            _attest(recipient, schema, expirationTime, refUUID, data, attester);
    }

    /**
     * @inheritdoc IEAS
     */
    function revoke(bytes32 uuid) public virtual override {
        return _revoke(uuid, msg.sender);
    }

    /**
     * @inheritdoc IEAS
     */
    function revokeByDelegation(
        bytes32 uuid,
        address attester,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override {
        _eip712Verifier.revoke(uuid, attester, v, r, s);

        _revoke(uuid, attester);
    }

    /**
     * @inheritdoc IEAS
     */
    function getAttestation(bytes32 uuid)
        external
        view
        override
        returns (Attestation memory)
    {
        return _db[uuid];
    }

    /**
     * @inheritdoc IEAS
     */
    function isAttestationValid(bytes32 uuid)
        public
        view
        override
        returns (bool)
    {
        return _db[uuid].uuid != 0;
    }

    /**
     * @inheritdoc IEAS
     */
    function isAttestationActive(bytes32 uuid)
        public
        view
        override
        returns (bool)
    {
        return
            isAttestationValid(uuid) &&
            _db[uuid].expirationTime >= block.timestamp &&
            _db[uuid].revocationTime == 0;
    }

    /**
     * @inheritdoc IEAS
     */
    function getReceivedAttestationUUIDs(
        address recipient,
        bytes32 schema,
        uint256 start,
        uint256 length,
        bool reverseOrder
    ) external view override returns (bytes32[] memory) {
        return
            _sliceUUIDs(
                _receivedAttestations[recipient][schema],
                start,
                length,
                reverseOrder
            );
    }

    /**
     * @inheritdoc IEAS
     */
    function getReceivedAttestationUUIDsCount(address recipient, bytes32 schema)
        external
        view
        override
        returns (uint256)
    {
        return _receivedAttestations[recipient][schema].length;
    }

    /**
     * @inheritdoc IEAS
     */
    function getSentAttestationUUIDs(
        address attester,
        bytes32 schema,
        uint256 start,
        uint256 length,
        bool reverseOrder
    ) external view override returns (bytes32[] memory) {
        return
            _sliceUUIDs(
                _sentAttestations[attester][schema],
                start,
                length,
                reverseOrder
            );
    }

    /**
     * @inheritdoc IEAS
     */
    function getSentAttestationUUIDsCount(address recipient, bytes32 schema)
        external
        view
        override
        returns (uint256)
    {
        return _sentAttestations[recipient][schema].length;
    }

    /**
     * @inheritdoc IEAS
     */
    function getRelatedAttestationUUIDs(
        bytes32 uuid,
        uint256 start,
        uint256 length,
        bool reverseOrder
    ) external view override returns (bytes32[] memory) {
        return
            _sliceUUIDs(
                _relatedAttestations[uuid],
                start,
                length,
                reverseOrder
            );
    }

    /**
     * @inheritdoc IEAS
     */
    function getRelatedAttestationUUIDsCount(bytes32 uuid)
        external
        view
        override
        returns (uint256)
    {
        return _relatedAttestations[uuid].length;
    }

    /**
     * @inheritdoc IEAS
     */
    function getSchemaAttestationUUIDs(
        bytes32 schema,
        uint256 start,
        uint256 length,
        bool reverseOrder
    ) external view override returns (bytes32[] memory) {
        return
            _sliceUUIDs(
                _schemaAttestations[schema],
                start,
                length,
                reverseOrder
            );
    }

    /**
     * @inheritdoc IEAS
     */
    function getSchemaAttestationUUIDsCount(bytes32 schema)
        external
        view
        override
        returns (uint256)
    {
        return _schemaAttestations[schema].length;
    }

    /**
     * @dev Attests to a specific AS.
     *
     * @param recipient The recipient of the attestation.
     * @param schema The UUID of the AS.
     * @param expirationTime The expiration time of the attestation.
     * @param refUUID An optional related attestation's UUID.
     * @param data Additional custom data.
     * @param attester The attesting account.
     *
     * @return The UUID of the new attestation.
     */
    function _attest(
        address recipient,
        bytes32 schema,
        uint256 expirationTime,
        bytes32 refUUID,
        bytes calldata data,
        address attester
    ) private returns (bytes32) {
        if (expirationTime <= block.timestamp) {
            revert InvalidExpirationTime();
        }

        IASRegistry.ASRecord memory asRecord = _asRegistry.getAS(schema);
        if (asRecord.uuid == EMPTY_UUID) {
            revert InvalidSchema();
        }

        IASResolver resolver = asRecord.resolver;
        if (address(resolver) != address(0x0)) {
            if (msg.value != 0 && !resolver.isPayable()) {
                revert NotPayable();
            }

            if (
                !resolver.resolve{ value: msg.value }(
                    recipient,
                    asRecord.schema,
                    data,
                    expirationTime,
                    attester
                )
            ) {
                revert InvalidAttestation();
            }
        }

        Attestation memory attestation = Attestation({
            uuid: EMPTY_UUID,
            schema: schema,
            recipient: recipient,
            attester: attester,
            time: block.timestamp,
            expirationTime: expirationTime,
            revocationTime: 0,
            refUUID: refUUID,
            data: data
        });

        _lastUUID = _getUUID(attestation);
        attestation.uuid = _lastUUID;

        _receivedAttestations[recipient][schema].push(_lastUUID);
        _sentAttestations[attester][schema].push(_lastUUID);
        _schemaAttestations[schema].push(_lastUUID);

        _db[_lastUUID] = attestation;
        _attestationsCount++;

        if (refUUID != 0) {
            if (!isAttestationValid(refUUID)) {
                revert NotFound();
            }

            _relatedAttestations[refUUID].push(_lastUUID);
        }

        emit Attested(recipient, attester, _lastUUID, schema);

        return _lastUUID;
    }

    function getLastUUID() external view returns (bytes32) {
        return _lastUUID;
    }

    /**
     * @dev Revokes an existing attestation to a specific AS.
     *
     * @param uuid The UUID of the attestation to revoke.
     * @param attester The attesting account.
     */
    function _revoke(bytes32 uuid, address attester) private {
        Attestation storage attestation = _db[uuid];
        if (attestation.uuid == EMPTY_UUID) {
            revert NotFound();
        }

        if (attestation.attester != attester) {
            revert AccessDenied();
        }

        if (attestation.revocationTime != 0) {
            revert AlreadyRevoked();
        }

        attestation.revocationTime = block.timestamp;

        emit Revoked(attestation.recipient, attester, uuid, attestation.schema);
    }

    /**
     * @dev Calculates a UUID for a given attestation.
     *
     * @param attestation The input attestation.
     *
     * @return Attestation UUID.
     */
    function _getUUID(Attestation memory attestation)
        private
        view
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    attestation.schema,
                    attestation.recipient,
                    attestation.attester,
                    attestation.time,
                    attestation.expirationTime,
                    attestation.data,
                    HASH_TERMINATOR,
                    _attestationsCount
                )
            );
    }

    /**
     * @dev Returns a slice in an array of attestation UUIDs.
     *
     * @param uuids The array of attestation UUIDs.
     * @param start The offset to start from.
     * @param length The number of total members to retrieve.
     * @param reverseOrder Whether the offset starts from the end and the data is returned in reverse.
     *
     * @return An array of attestation UUIDs.
     */
    function _sliceUUIDs(
        bytes32[] memory uuids,
        uint256 start,
        uint256 length,
        bool reverseOrder
    ) private pure returns (bytes32[] memory) {
        uint256 attestationsLength = uuids.length;
        if (attestationsLength == 0) {
            return new bytes32[](0);
        }

        if (start >= attestationsLength) {
            revert InvalidOffset();
        }

        uint256 len = length;
        if (attestationsLength < start + length) {
            len = attestationsLength - start;
        }

        bytes32[] memory res = new bytes32[](len);

        for (uint256 i = 0; i < len; ++i) {
            res[i] = uuids[
                reverseOrder ? attestationsLength - (start + i + 1) : start + i
            ];
        }

        return res;
    }
}

pragma solidity >=0.8.0 <0.9.0;
// SPDX-License-Identifier: MIT

import "../interfaces/IASResolver.sol";

/**
 * @title A base resolver contract
 */
abstract contract TellerASResolver is IASResolver {
    error NotPayable();

    function isPayable() public pure virtual override returns (bool) {
        return false;
    }

    receive() external payable virtual {
        if (!isPayable()) {
            revert NotPayable();
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Contracts
import "./EAS/TellerAS.sol";
import "./EAS/TellerASResolver.sol";

//must continue to use this so storage slots are not broken
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/Context.sol";

// Interfaces
import "./interfaces/IMarketRegistry.sol";

// Libraries
import {
    EnumerableSet
} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract MarketRegistry is
    IMarketRegistry,
    Initializable,
    Context,
    TellerASResolver
{
    using EnumerableSet for EnumerableSet.AddressSet;

    /** Constant Variables **/

    uint256 public constant CURRENT_CODE_VERSION = 5;

    /* Storage Variables */

    struct Marketplace {
        address owner;
        string metadataURI;
        uint16 marketplaceFeePercent; // 10000 is 100%
        bool lenderAttestationRequired;
        EnumerableSet.AddressSet verifiedLendersForMarket;
        mapping(address => bytes32) lenderAttestationIds;
        uint32 paymentCycleDuration; //unix time
        uint32 paymentDefaultDuration; //unix time
        uint32 bidExpirationTime; //unix time
        bool borrowerAttestationRequired;
        EnumerableSet.AddressSet verifiedBorrowersForMarket;
        mapping(address => bytes32) borrowerAttestationIds;
        address feeRecipient;
    }

    bytes32 public lenderAttestationSchemaId;

    mapping(uint256 => Marketplace) internal markets;
    mapping(bytes32 => uint256) internal _uriToId;
    uint256 public marketCount;
    bytes32 private _attestingSchemaId;
    bytes32 public borrowerAttestationSchemaId;

    uint256 public version;

    mapping(uint256 => bool) private marketIsClosed;

    TellerAS public tellerAS;

    /* Modifiers */

    modifier ownsMarket(uint256 _marketId) {
        require(markets[_marketId].owner == _msgSender(), "Not the owner");
        _;
    }

    modifier withAttestingSchema(bytes32 schemaId) {
        _attestingSchemaId = schemaId;
        _;
        _attestingSchemaId = bytes32(0);
    }

    /* Events */

    event MarketCreated(address indexed owner, uint256 marketId);
    event SetMarketURI(uint256 marketId, string uri);
    event SetPaymentCycleDuration(uint256 marketId, uint32 duration);
    event SetPaymentDefaultDuration(uint256 marketId, uint32 duration);
    event SetBidExpirationTime(uint256 marketId, uint32 duration);
    event SetMarketFee(uint256 marketId, uint16 feePct);
    event LenderAttestation(uint256 marketId, address lender);
    event BorrowerAttestation(uint256 marketId, address borrower);
    event LenderRevocation(uint256 marketId, address lender);
    event BorrowerRevocation(uint256 marketId, address borrower);
    event MarketClosed(uint256 marketId);
    event LenderExitMarket(uint256 marketId, address lender);
    event BorrowerExitMarket(uint256 marketId, address borrower);
    event SetMarketOwner(uint256 marketId, address newOwner);
    event SetMarketFeeRecipient(uint256 marketId, address newRecipient);

    /* External Functions */

    function initialize(TellerAS _tellerAS) external initializer {
        tellerAS = _tellerAS;

        lenderAttestationSchemaId = tellerAS.getASRegistry().register(
            "(uint256 marketId, address lenderAddress)",
            this
        );
        borrowerAttestationSchemaId = tellerAS.getASRegistry().register(
            "(uint256 marketId, address borrowerAddress)",
            this
        );
    }

    /**
     * @notice Sets the new tellerAS on upgrade
     */
    function onUpgrade() external {
        require(
            version != CURRENT_CODE_VERSION,
            "Contract already upgraded to latest version!"
        );
        version = CURRENT_CODE_VERSION;
    }

    /**
     * @notice Creates a new market.
     * @param _initialOwner Address who will initially own the market.
     * @param _paymentCycleDuration Length of time in seconds before a bid's next payment is required to be made.
     * @param _paymentDefaultDuration Length of time in seconds before a loan is considered in default for non-payment.
     * @param _bidExpirationTime Length of time in seconds before pending bids expire.
     * @param _requireLenderAttestation Boolean that indicates if lenders require attestation to join market.
     * @param _requireBorrowerAttestation Boolean that indicates if borrowers require attestation to join market.
     * @param _uri URI string to get metadata details about the market.
     */
    function createMarket(
        address _initialOwner,
        uint32 _paymentCycleDuration,
        uint32 _paymentDefaultDuration,
        uint32 _bidExpirationTime,
        uint16 _feePercent,
        bool _requireLenderAttestation,
        bool _requireBorrowerAttestation,
        string calldata _uri
    ) external {
        require(_initialOwner != address(0), "Invalid owner address");
        // Increment market ID counter
        uint256 marketId = ++marketCount;

        // Set the market owner
        markets[marketId].owner = _initialOwner;

        setMarketURI(marketId, _uri);
        setPaymentCycleDuration(marketId, _paymentCycleDuration);
        setPaymentDefaultDuration(marketId, _paymentDefaultDuration);
        setMarketFeePercent(marketId, _feePercent);
        setBidExpirationTime(marketId, _bidExpirationTime);

        // Check if market requires lender attestation to join
        if (_requireLenderAttestation) {
            markets[marketId].lenderAttestationRequired = true;
        }
        // Check if market requires borrower attestation to join
        if (_requireBorrowerAttestation) {
            markets[marketId].borrowerAttestationRequired = true;
        }

        emit MarketCreated(_initialOwner, marketId);
    }

    /**
     * @notice Closes a market so new bids cannot be added.
     * @param _marketId The market ID for the market to close.
     */

    function closeMarket(uint256 _marketId) public ownsMarket(_marketId) {
        if (!marketIsClosed[_marketId]) {
            marketIsClosed[_marketId] = true;

            emit MarketClosed(_marketId);
        }
    }

    /**
     * @notice Returns the status of a market being open or closed for new bids.
     * @param _marketId The market ID for the market to check.
     */
    function isMarketClosed(uint256 _marketId)
        public
        view
        override
        returns (bool)
    {
        return marketIsClosed[_marketId];
    }

    /**
     * @notice Adds a lender to a market.
     * @dev See {_attestStakeholder}.
     */
    function attestLender(
        uint256 _marketId,
        address _lenderAddress,
        uint256 _expirationTime
    ) external {
        _attestStakeholder(_marketId, _lenderAddress, _expirationTime, true);
    }

    /**
     * @notice Adds a lender to a market via delegated attestation.
     * @dev See {_attestStakeholderViaDelegation}.
     */
    function attestLender(
        uint256 _marketId,
        address _lenderAddress,
        uint256 _expirationTime,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external {
        _attestStakeholderViaDelegation(
            _marketId,
            _lenderAddress,
            _expirationTime,
            true,
            _v,
            _r,
            _s
        );
    }

    /**
     * @notice Removes a lender from an market.
     * @dev See {_revokeStakeholder}.
     */
    function revokeLender(uint256 _marketId, address _lenderAddress) external {
        _revokeStakeholder(_marketId, _lenderAddress, true);
    }

    /**
     * @notice Removes a borrower from a market via delegated revocation.
     * @dev See {_revokeStakeholderViaDelegation}.
     */
    function revokeLender(
        uint256 _marketId,
        address _lenderAddress,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external {
        _revokeStakeholderViaDelegation(
            _marketId,
            _lenderAddress,
            true,
            _v,
            _r,
            _s
        );
    }

    /**
     * @notice Allows a lender to voluntarily leave a market.
     * @param _marketId The market ID to leave.
     */
    function lenderExitMarket(uint256 _marketId) external {
        // Remove lender address from market set
        bool response = markets[_marketId].verifiedLendersForMarket.remove(
            _msgSender()
        );
        if (response) {
            emit LenderExitMarket(_marketId, _msgSender());
        }
    }

    /**
     * @notice Adds a borrower to a market.
     * @dev See {_attestStakeholder}.
     */
    function attestBorrower(
        uint256 _marketId,
        address _borrowerAddress,
        uint256 _expirationTime
    ) external {
        _attestStakeholder(_marketId, _borrowerAddress, _expirationTime, false);
    }

    /**
     * @notice Adds a borrower to a market via delegated attestation.
     * @dev See {_attestStakeholderViaDelegation}.
     */
    function attestBorrower(
        uint256 _marketId,
        address _borrowerAddress,
        uint256 _expirationTime,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external {
        _attestStakeholderViaDelegation(
            _marketId,
            _borrowerAddress,
            _expirationTime,
            false,
            _v,
            _r,
            _s
        );
    }

    /**
     * @notice Removes a borrower from an market.
     * @dev See {_revokeStakeholder}.
     */
    function revokeBorrower(uint256 _marketId, address _borrowerAddress)
        external
    {
        _revokeStakeholder(_marketId, _borrowerAddress, false);
    }

    /**
     * @notice Removes a borrower from a market via delegated revocation.
     * @dev See {_revokeStakeholderViaDelegation}.
     */
    function revokeBorrower(
        uint256 _marketId,
        address _borrowerAddress,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external {
        _revokeStakeholderViaDelegation(
            _marketId,
            _borrowerAddress,
            false,
            _v,
            _r,
            _s
        );
    }

    /**
     * @notice Allows a borrower to voluntarily leave a market.
     * @param _marketId The market ID to leave.
     */
    function borrowerExitMarket(uint256 _marketId) external {
        // Remove borrower address from market set
        bool response = markets[_marketId].verifiedBorrowersForMarket.remove(
            _msgSender()
        );
        if (response) {
            emit BorrowerExitMarket(_marketId, _msgSender());
        }
    }

    /**
     * @notice Verifies an attestation is valid.
     * @dev This function must only be called by the `attestLender` function above.
     * @param recipient Lender's address who is being attested.
     * @param schema The schema used for the attestation.
     * @param data Data the must include the market ID and lender's address
     * @param
     * @param attestor Market owner's address who signed the attestation.
     * @return Boolean indicating the attestation was successful.
     */
    function resolve(
        address recipient,
        bytes calldata schema,
        bytes calldata data,
        uint256, /* expirationTime */
        address attestor
    ) external payable override returns (bool) {
        bytes32 attestationSchemaId = keccak256(
            abi.encodePacked(schema, address(this))
        );
        (uint256 marketId, address lenderAddress) = abi.decode(
            data,
            (uint256, address)
        );
        return
            (_attestingSchemaId == attestationSchemaId &&
                recipient == lenderAddress &&
                attestor == markets[marketId].owner) ||
            attestor == address(this);
    }

    /**
     * @notice Transfers ownership of a marketplace.
     * @param _marketId The ID of a market.
     * @param _newOwner Address of the new market owner.
     *
     * Requirements:
     * - The caller must be the current owner.
     */
    function transferMarketOwnership(uint256 _marketId, address _newOwner)
        public
        ownsMarket(_marketId)
    {
        markets[_marketId].owner = _newOwner;
        emit SetMarketOwner(_marketId, _newOwner);
    }

    /**
     * @notice Updates multiple market settings for a given market.
     * @param _marketId The ID of a market.
     * @param _paymentCycleDuration Delinquency duration for new loans
     * @param _paymentDefaultDuration Default duration for new loans
     * @param _bidExpirationTime Duration of time before a bid is considered out of date
     * @param _metadataURI A URI that points to a market's metadata.
     *
     * Requirements:
     * - The caller must be the current owner.
     */
    function updateMarketSettings(
        uint256 _marketId,
        uint32 _paymentCycleDuration,
        uint32 _paymentDefaultDuration,
        uint32 _bidExpirationTime,       
        uint16 _feePercent,
        bool _borrowerAttestationRequired,
        bool _lenderAttestationRequired,
        string calldata _metadataURI     
    ) public ownsMarket(_marketId) {
        setMarketURI(_marketId, _metadataURI);
        setPaymentCycleDuration(_marketId, _paymentCycleDuration);
        setPaymentDefaultDuration(_marketId, _paymentDefaultDuration);
        setBidExpirationTime(_marketId, _bidExpirationTime);
        setMarketFeePercent(_marketId, _feePercent);

        markets[_marketId].borrowerAttestationRequired = _borrowerAttestationRequired;
        markets[_marketId].lenderAttestationRequired = _lenderAttestationRequired;
    }

    /**
     * @notice Sets the fee recipient address for a market.
     * @param _marketId The ID of a market.
     * @param _recipient Address of the new fee recipient.
     *
     * Requirements:
     * - The caller must be the current owner.
     */
    function setMarketFeeRecipient(uint256 _marketId, address _recipient)
        public
        ownsMarket(_marketId)
    {
        markets[_marketId].feeRecipient = _recipient;
        emit SetMarketFeeRecipient(_marketId, _recipient);
    }

    /**
     * @notice Sets the metadata URI for a market.
     * @param _marketId The ID of a market.
     * @param _uri A URI that points to a market's metadata.
     *
     * Requirements:
     * - The caller must be the current owner.
     */
    function setMarketURI(uint256 _marketId, string calldata _uri)
        public
        ownsMarket(_marketId)
    {
        // Check if URI is already used
        bytes32 uriId = keccak256(abi.encode(_uri));
        require(_uriToId[uriId] == 0, "non-unique market URI");

        // Update market counter & store reverse lookup
        _uriToId[uriId] = _marketId;
        markets[_marketId].metadataURI = _uri;

        emit SetMarketURI(_marketId, _uri);
    }

    /**
     * @notice Sets the duration of new loans for this market before they turn delinquent.
     * @notice Changing this value does not change the terms of existing loans for this market.
     * @param _marketId The ID of a market.
     * @param _duration Delinquency duration for new loans
     */
    function setPaymentCycleDuration(uint256 _marketId, uint32 _duration)
        public
        ownsMarket(_marketId)
    {
        markets[_marketId].paymentCycleDuration = _duration;

        emit SetPaymentCycleDuration(_marketId, _duration);
    }

    /**
     * @notice Sets the duration of new loans for this market before they turn defaulted.
     * @notice Changing this value does not change the terms of existing loans for this market.
     * @param _marketId The ID of a market.
     * @param _duration Default duration for new loans
     */
    function setPaymentDefaultDuration(uint256 _marketId, uint32 _duration)
        public
        ownsMarket(_marketId)
    {
        markets[_marketId].paymentDefaultDuration = _duration;

        emit SetPaymentDefaultDuration(_marketId, _duration);
    }

    function setBidExpirationTime(uint256 marketId, uint32 duration)
        public
        ownsMarket(marketId)
    {
        markets[marketId].bidExpirationTime = duration;

        emit SetBidExpirationTime(marketId, duration);
    }

    /**
     * @notice Sets the fee for the market.
     * @param _marketId The ID of a market.
     * @param _newPercent The percentage fee in basis points.
     *
     * Requirements:
     * - The caller must be the current owner.
     */
    function setMarketFeePercent(uint256 _marketId, uint16 _newPercent)
        public
        ownsMarket(_marketId)
    {
        require(_newPercent >= 0 && _newPercent <= 10000, "invalid percent");
        markets[_marketId].marketplaceFeePercent = _newPercent;
        emit SetMarketFee(_marketId, _newPercent);
    }

    /**
     * @notice Gets the data associated with a market.
     * @param _marketId The ID of a market.
     */
    function getMarketData(uint256 _marketId)
        public
        view
        returns (
            address owner,
            uint32 paymentCycleDuration,
            uint32 paymentDefaultDuration,
            uint32 loanExpirationTime,
            string memory metadataURI,
            uint16 marketplaceFeePercent,
            bool lenderAttestationRequired
        )
    {
        return (
            markets[_marketId].owner,
            markets[_marketId].paymentCycleDuration,
            markets[_marketId].paymentDefaultDuration,
            markets[_marketId].bidExpirationTime,
            markets[_marketId].metadataURI,
            markets[_marketId].marketplaceFeePercent,
            markets[_marketId].lenderAttestationRequired
        );
    }

    /**
     * @notice Gets the attestation requirements for a given market.
     * @param _marketId The ID of the market.
     */
    function getMarketAttestationRequirements(uint256 _marketId)
        public
        view
        returns (
            bool lenderAttestationRequired,
            bool borrowerAttestationRequired
        )
    {
        return (
            markets[_marketId].lenderAttestationRequired,
            markets[_marketId].borrowerAttestationRequired
        );
    }

    /**
     * @notice Gets the address of a market's owner.
     * @param _marketId The ID of a market.
     * @return The address of a market's owner.
     */
    function getMarketOwner(uint256 _marketId)
        public
        view
        override
        returns (address)
    {
        return markets[_marketId].owner;
    }

    /**
     * @notice Gets the fee recipient of a market.
     * @param _marketId The ID of a market.
     * @return The address of a market's fee recipient.
     */
    function getMarketFeeRecipient(uint256 _marketId)
        public
        view
        override
        returns (address)
    {
        address recipient = markets[_marketId].feeRecipient;

        if (recipient == address(0)) {
            return markets[_marketId].owner;
        }

        return recipient;
    }

    /**
     * @notice Gets the metadata URI of a market.
     * @param _marketId The ID of a market.
     * @return URI of a market's metadata.
     */
    function getMarketURI(uint256 _marketId)
        public
        view
        override
        returns (string memory)
    {
        return markets[_marketId].metadataURI;
    }

    /**
     * @notice Gets the loan delinquent duration of a market.
     * @param _marketId The ID of a market.
     * @return Duration of a loan until it is delinquent.
     */
    function getPaymentCycleDuration(uint256 _marketId)
        public
        view
        override
        returns (uint32)
    {
        return markets[_marketId].paymentCycleDuration;
    }

    /**
     * @notice Gets the loan default duration of a market.
     * @param _marketId The ID of a market.
     * @return Duration of a loan repayment interval until it is default.
     */
    function getPaymentDefaultDuration(uint256 _marketId)
        public
        view
        override
        returns (uint32)
    {
        return markets[_marketId].paymentDefaultDuration;
    }

    function getBidExpirationTime(uint256 marketId)
        public
        view
        override
        returns (uint32)
    {
        return markets[marketId].bidExpirationTime;
    }

    /**
     * @notice Gets the marketplace fee in basis points
     * @param _marketId The ID of a market.
     * @return fee in basis points
     */
    function getMarketplaceFee(uint256 _marketId)
        public
        view
        override
        returns (uint16 fee)
    {
        return markets[_marketId].marketplaceFeePercent;
    }

    /**
     * @notice Checks if a lender has been attested and added to a market.
     * @param _marketId The ID of a market.
     * @param _lenderAddress Address to check.
     * @return isVerified_ Boolean indicating if a lender has been added to a market.
     * @return uuid_ Bytes32 representing the UUID of the lender.
     */
    function isVerifiedLender(uint256 _marketId, address _lenderAddress)
        public
        view
        override
        returns (bool isVerified_, bytes32 uuid_)
    {
        return
            _isVerified(
                _lenderAddress,
                markets[_marketId].lenderAttestationRequired,
                markets[_marketId].lenderAttestationIds,
                markets[_marketId].verifiedLendersForMarket
            );
    }

    /**
     * @notice Checks if a borrower has been attested and added to a market.
     * @param _marketId The ID of a market.
     * @param _borrowerAddress Address of the borrower to check.
     * @return isVerified_ Boolean indicating if a borrower has been added to a market.
     * @return uuid_ Bytes32 representing the UUID of the borrower.
     */
    function isVerifiedBorrower(uint256 _marketId, address _borrowerAddress)
        public
        view
        override
        returns (bool isVerified_, bytes32 uuid_)
    {
        return
            _isVerified(
                _borrowerAddress,
                markets[_marketId].borrowerAttestationRequired,
                markets[_marketId].borrowerAttestationIds,
                markets[_marketId].verifiedBorrowersForMarket
            );
    }

    /**
     * @notice Gets addresses of all attested lenders.
     * @param _marketId The ID of a market.
     * @param _page Page index to start from.
     * @param _perPage Number of items in a page to return.
     * @return Array of addresses that have been added to a market.
     */
    function getAllVerifiedLendersForMarket(
        uint256 _marketId,
        uint256 _page,
        uint256 _perPage
    ) public view returns (address[] memory) {
        EnumerableSet.AddressSet storage set = markets[_marketId]
            .verifiedLendersForMarket;

        return _getStakeholdersForMarket(set, _page, _perPage);
    }

    /**
     * @notice Gets addresses of all attested borrowers.
     * @param _marketId The ID of the market.
     * @param _page Page index to start from.
     * @param _perPage Number of items in a page to return.
     * @return Array of addresses that have been added to a market.
     */
    function getAllVerifiedBorrowersForMarket(
        uint256 _marketId,
        uint256 _page,
        uint256 _perPage
    ) public view returns (address[] memory) {
        EnumerableSet.AddressSet storage set = markets[_marketId]
            .verifiedBorrowersForMarket;
        return _getStakeholdersForMarket(set, _page, _perPage);
    }

    /**
     * @notice Gets addresses of all attested relevant stakeholders.
     * @param _set The stored set of stakeholders to index from.
     * @param _page Page index to start from.
     * @param _perPage Number of items in a page to return.
     * @return stakeholders_ Array of addresses that have been added to a market.
     */
    function _getStakeholdersForMarket(
        EnumerableSet.AddressSet storage _set,
        uint256 _page,
        uint256 _perPage
    ) internal view returns (address[] memory stakeholders_) {
        uint256 len = _set.length();

        uint256 start = _page * _perPage;
        if (start <= len) {
            uint256 end = start + _perPage;
            // Ensure we do not go out of bounds
            if (end > len) {
                end = len;
            }

            stakeholders_ = new address[](end - start);
            for (uint256 i = start; i < end; i++) {
                stakeholders_[i] = _set.at(i);
            }
        }
    }

    /* Internal Functions */

    /**
     * @notice Sets the metadata URI for a market.
     * @param _marketId The ID of a market.
     * @param _uri A URI that points to a market's metadata.
     */
    function _setMarketUri(uint256 _marketId, string calldata _uri) internal {
        require(_marketId > 0, "Market ID 0");

        // Check if URI is already used
        bytes32 uriId = keccak256(abi.encode(_uri));
        require(_uriToId[uriId] == 0, "non-unique market URI");

        // Update market counter & store reverse lookup
        _uriToId[uriId] = _marketId;
        markets[_marketId].metadataURI = _uri;

        emit SetMarketURI(_marketId, _uri);
    }

    /**
     * @notice Adds a stakeholder (lender or borrower) to a market.
     * @param _marketId The market ID to add a borrower to.
     * @param _stakeholderAddress The address of the stakeholder to add to the market.
     * @param _expirationTime The expiration time of the attestation.
     * @param _expirationTime The expiration time of the attestation.
     * @param _isLender Boolean indicating if the stakeholder is a lender. Otherwise it is a borrower.
     */
    function _attestStakeholder(
        uint256 _marketId,
        address _stakeholderAddress,
        uint256 _expirationTime,
        bool _isLender
    )
        internal
        withAttestingSchema(
            _isLender ? lenderAttestationSchemaId : borrowerAttestationSchemaId
        )
    {
        require(
            _msgSender() == markets[_marketId].owner,
            "Not the market owner"
        );

        // Submit attestation for borrower to join a market
        bytes32 uuid = tellerAS.attest(
            _stakeholderAddress,
            _attestingSchemaId, // set by the modifier
            _expirationTime,
            0,
            abi.encode(_marketId, _stakeholderAddress)
        );
        _attestStakeholderVerification(
            _marketId,
            _stakeholderAddress,
            uuid,
            _isLender
        );
    }

    /**
     * @notice Adds a stakeholder (lender or borrower) to a market via delegated attestation.
     * @dev The signature must match that of the market owner.
     * @param _marketId The market ID to add a lender to.
     * @param _stakeholderAddress The address of the lender to add to the market.
     * @param _expirationTime The expiration time of the attestation.
     * @param _isLender Boolean indicating if the stakeholder is a lender. Otherwise it is a borrower.
     * @param _v Signature value
     * @param _r Signature value
     * @param _s Signature value
     */
    function _attestStakeholderViaDelegation(
        uint256 _marketId,
        address _stakeholderAddress,
        uint256 _expirationTime,
        bool _isLender,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    )
        internal
        withAttestingSchema(
            _isLender ? lenderAttestationSchemaId : borrowerAttestationSchemaId
        )
    {
        // NOTE: block scope to prevent stack too deep!
        bytes32 uuid;
        {
            bytes memory data = abi.encode(_marketId, _stakeholderAddress);
            address attestor = markets[_marketId].owner;
            // Submit attestation for stakeholder to join a market (attestation must be signed by market owner)
            uuid = tellerAS.attestByDelegation(
                _stakeholderAddress,
                _attestingSchemaId, // set by the modifier
                _expirationTime,
                0,
                data,
                attestor,
                _v,
                _r,
                _s
            );
        }
        _attestStakeholderVerification(
            _marketId,
            _stakeholderAddress,
            uuid,
            _isLender
        );
    }

    /**
     * @notice Adds a stakeholder (borrower/lender) to a market.
     * @param _marketId The market ID to add a stakeholder to.
     * @param _stakeholderAddress The address of the stakeholder to add to the market.
     * @param _uuid The UUID of the attestation created.
     * @param _isLender Boolean indicating if the stakeholder is a lender. Otherwise it is a borrower.
     */
    function _attestStakeholderVerification(
        uint256 _marketId,
        address _stakeholderAddress,
        bytes32 _uuid,
        bool _isLender
    ) internal {
        if (_isLender) {
            // Store the lender attestation ID for the market ID
            markets[_marketId].lenderAttestationIds[
                _stakeholderAddress
            ] = _uuid;
            // Add lender address to market set
            markets[_marketId].verifiedLendersForMarket.add(
                _stakeholderAddress
            );

            emit LenderAttestation(_marketId, _stakeholderAddress);
        } else {
            // Store the lender attestation ID for the market ID
            markets[_marketId].borrowerAttestationIds[
                _stakeholderAddress
            ] = _uuid;
            // Add lender address to market set
            markets[_marketId].verifiedBorrowersForMarket.add(
                _stakeholderAddress
            );

            emit BorrowerAttestation(_marketId, _stakeholderAddress);
        }
    }

    /**
     * @notice Removes a stakeholder from an market.
     * @dev The caller must be the market owner.
     * @param _marketId The market ID to remove the borrower from.
     * @param _stakeholderAddress The address of the borrower to remove from the market.
     * @param _isLender Boolean indicating if the stakeholder is a lender. Otherwise it is a borrower.
     */
    function _revokeStakeholder(
        uint256 _marketId,
        address _stakeholderAddress,
        bool _isLender
    ) internal {
        require(
            _msgSender() == markets[_marketId].owner,
            "Not the market owner"
        );

        bytes32 uuid = _revokeStakeholderVerification(
            _marketId,
            _stakeholderAddress,
            _isLender
        );
        // NOTE: Disabling the call to revoke the attestation on EAS contracts
        //        tellerAS.revoke(uuid);
    }

    /**
     * @notice Removes a stakeholder from an market via delegated revocation.
     * @param _marketId The market ID to remove the borrower from.
     * @param _stakeholderAddress The address of the borrower to remove from the market.
     * @param _isLender Boolean indicating if the stakeholder is a lender. Otherwise it is a borrower.
     * @param _v Signature value
     * @param _r Signature value
     * @param _s Signature value
     */
    function _revokeStakeholderViaDelegation(
        uint256 _marketId,
        address _stakeholderAddress,
        bool _isLender,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) internal {
        bytes32 uuid = _revokeStakeholderVerification(
            _marketId,
            _stakeholderAddress,
            _isLender
        );
        // NOTE: Disabling the call to revoke the attestation on EAS contracts
        //        address attestor = markets[_marketId].owner;
        //        tellerAS.revokeByDelegation(uuid, attestor, _v, _r, _s);
    }

    /**
     * @notice Removes a stakeholder (borrower/lender) from a market.
     * @param _marketId The market ID to remove the lender from.
     * @param _stakeholderAddress The address of the stakeholder to remove from the market.
     * @param _isLender Boolean indicating if the stakeholder is a lender. Otherwise it is a borrower.
     * @return uuid_ The ID of the previously verified attestation.
     */
    function _revokeStakeholderVerification(
        uint256 _marketId,
        address _stakeholderAddress,
        bool _isLender
    ) internal returns (bytes32 uuid_) {
        if (_isLender) {
            uuid_ = markets[_marketId].lenderAttestationIds[
                _stakeholderAddress
            ];
            // Remove lender address from market set
            markets[_marketId].verifiedLendersForMarket.remove(
                _stakeholderAddress
            );

            emit LenderRevocation(_marketId, _stakeholderAddress);
        } else {
            uuid_ = markets[_marketId].borrowerAttestationIds[
                _stakeholderAddress
            ];
            // Remove borrower address from market set
            markets[_marketId].verifiedBorrowersForMarket.remove(
                _stakeholderAddress
            );

            emit BorrowerRevocation(_marketId, _stakeholderAddress);
        }
    }

    /**
     * @notice Checks if a stakeholder has been attested and added to a market.
     * @param _stakeholderAddress Address of the stakeholder to check.
     * @param _attestationRequired Stored boolean indicating if attestation is required for the stakeholder class.
     * @param _stakeholderAttestationIds Mapping of attested Ids for the stakeholder class.
     */
    function _isVerified(
        address _stakeholderAddress,
        bool _attestationRequired,
        mapping(address => bytes32) storage _stakeholderAttestationIds,
        EnumerableSet.AddressSet storage _verifiedStakeholderForMarket
    ) internal view returns (bool isVerified_, bytes32 uuid_) {
        if (_attestationRequired) {
            isVerified_ =
                _verifiedStakeholderForMarket.contains(_stakeholderAddress) &&
                tellerAS.isAttestationActive(
                    _stakeholderAttestationIds[_stakeholderAddress]
                );
            uuid_ = _stakeholderAttestationIds[_stakeholderAddress];
        } else {
            isVerified_ = true;
        }
    }
}

pragma solidity >=0.8.0 <0.9.0;
// SPDX-License-Identifier: MIT

// A representation of an empty/uninitialized UUID.
bytes32 constant EMPTY_UUID = 0;

pragma solidity >=0.8.0 <0.9.0;
// SPDX-License-Identifier: MIT

import "./IASResolver.sol";

/**
 * @title The global AS registry interface.
 */
interface IASRegistry {
    /**
     * @title A struct representing a record for a submitted AS (Attestation Schema).
     */
    struct ASRecord {
        // A unique identifier of the AS.
        bytes32 uuid;
        // Optional schema resolver.
        IASResolver resolver;
        // Auto-incrementing index for reference, assigned by the registry itself.
        uint256 index;
        // Custom specification of the AS (e.g., an ABI).
        bytes schema;
    }

    /**
     * @dev Triggered when a new AS has been registered
     *
     * @param uuid The AS UUID.
     * @param index The AS index.
     * @param schema The AS schema.
     * @param resolver An optional AS schema resolver.
     * @param attester The address of the account used to register the AS.
     */
    event Registered(
        bytes32 indexed uuid,
        uint256 indexed index,
        bytes schema,
        IASResolver resolver,
        address attester
    );

    /**
     * @dev Submits and reserve a new AS
     *
     * @param schema The AS data schema.
     * @param resolver An optional AS schema resolver.
     *
     * @return The UUID of the new AS.
     */
    function register(bytes calldata schema, IASResolver resolver)
        external
        returns (bytes32);

    /**
     * @dev Returns an existing AS by UUID
     *
     * @param uuid The UUID of the AS to retrieve.
     *
     * @return The AS data members.
     */
    function getAS(bytes32 uuid) external view returns (ASRecord memory);

    /**
     * @dev Returns the global counter for the total number of attestations
     *
     * @return The global counter for the total number of attestations.
     */
    function getASCount() external view returns (uint256);
}

pragma solidity >=0.8.0 <0.9.0;

// SPDX-License-Identifier: MIT

/**
 * @title The interface of an optional AS resolver.
 */
interface IASResolver {
    /**
     * @dev Returns whether the resolver supports ETH transfers
     */
    function isPayable() external pure returns (bool);

    /**
     * @dev Resolves an attestation and verifier whether its data conforms to the spec.
     *
     * @param recipient The recipient of the attestation.
     * @param schema The AS data schema.
     * @param data The actual attestation data.
     * @param expirationTime The expiration time of the attestation.
     * @param msgSender The sender of the original attestation message.
     *
     * @return Whether the data is valid according to the scheme.
     */
    function resolve(
        address recipient,
        bytes calldata schema,
        bytes calldata data,
        uint256 expirationTime,
        address msgSender
    ) external payable returns (bool);
}

pragma solidity >=0.8.0 <0.9.0;
// SPDX-License-Identifier: MIT

import "./IASRegistry.sol";
import "./IEASEIP712Verifier.sol";

/**
 * @title EAS - Ethereum Attestation Service interface
 */
interface IEAS {
    /**
     * @dev A struct representing a single attestation.
     */
    struct Attestation {
        // A unique identifier of the attestation.
        bytes32 uuid;
        // A unique identifier of the AS.
        bytes32 schema;
        // The recipient of the attestation.
        address recipient;
        // The attester/sender of the attestation.
        address attester;
        // The time when the attestation was created (Unix timestamp).
        uint256 time;
        // The time when the attestation expires (Unix timestamp).
        uint256 expirationTime;
        // The time when the attestation was revoked (Unix timestamp).
        uint256 revocationTime;
        // The UUID of the related attestation.
        bytes32 refUUID;
        // Custom attestation data.
        bytes data;
    }

    /**
     * @dev Triggered when an attestation has been made.
     *
     * @param recipient The recipient of the attestation.
     * @param attester The attesting account.
     * @param uuid The UUID the revoked attestation.
     * @param schema The UUID of the AS.
     */
    event Attested(
        address indexed recipient,
        address indexed attester,
        bytes32 uuid,
        bytes32 indexed schema
    );

    /**
     * @dev Triggered when an attestation has been revoked.
     *
     * @param recipient The recipient of the attestation.
     * @param attester The attesting account.
     * @param schema The UUID of the AS.
     * @param uuid The UUID the revoked attestation.
     */
    event Revoked(
        address indexed recipient,
        address indexed attester,
        bytes32 uuid,
        bytes32 indexed schema
    );

    /**
     * @dev Returns the address of the AS global registry.
     *
     * @return The address of the AS global registry.
     */
    function getASRegistry() external view returns (IASRegistry);

    /**
     * @dev Returns the address of the EIP712 verifier used to verify signed attestations.
     *
     * @return The address of the EIP712 verifier used to verify signed attestations.
     */
    function getEIP712Verifier() external view returns (IEASEIP712Verifier);

    /**
     * @dev Returns the global counter for the total number of attestations.
     *
     * @return The global counter for the total number of attestations.
     */
    function getAttestationsCount() external view returns (uint256);

    /**
     * @dev Attests to a specific AS.
     *
     * @param recipient The recipient of the attestation.
     * @param schema The UUID of the AS.
     * @param expirationTime The expiration time of the attestation.
     * @param refUUID An optional related attestation's UUID.
     * @param data Additional custom data.
     *
     * @return The UUID of the new attestation.
     */
    function attest(
        address recipient,
        bytes32 schema,
        uint256 expirationTime,
        bytes32 refUUID,
        bytes calldata data
    ) external payable returns (bytes32);

    /**
     * @dev Attests to a specific AS using a provided EIP712 signature.
     *
     * @param recipient The recipient of the attestation.
     * @param schema The UUID of the AS.
     * @param expirationTime The expiration time of the attestation.
     * @param refUUID An optional related attestation's UUID.
     * @param data Additional custom data.
     * @param attester The attesting account.
     * @param v The recovery ID.
     * @param r The x-coordinate of the nonce R.
     * @param s The signature data.
     *
     * @return The UUID of the new attestation.
     */
    function attestByDelegation(
        address recipient,
        bytes32 schema,
        uint256 expirationTime,
        bytes32 refUUID,
        bytes calldata data,
        address attester,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable returns (bytes32);

    /**
     * @dev Revokes an existing attestation to a specific AS.
     *
     * @param uuid The UUID of the attestation to revoke.
     */
    function revoke(bytes32 uuid) external;

    /**
     * @dev Attests to a specific AS using a provided EIP712 signature.
     *
     * @param uuid The UUID of the attestation to revoke.
     * @param attester The attesting account.
     * @param v The recovery ID.
     * @param r The x-coordinate of the nonce R.
     * @param s The signature data.
     */
    function revokeByDelegation(
        bytes32 uuid,
        address attester,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns an existing attestation by UUID.
     *
     * @param uuid The UUID of the attestation to retrieve.
     *
     * @return The attestation data members.
     */
    function getAttestation(bytes32 uuid)
        external
        view
        returns (Attestation memory);

    /**
     * @dev Checks whether an attestation exists.
     *
     * @param uuid The UUID of the attestation to retrieve.
     *
     * @return Whether an attestation exists.
     */
    function isAttestationValid(bytes32 uuid) external view returns (bool);

    /**
     * @dev Checks whether an attestation is active.
     *
     * @param uuid The UUID of the attestation to retrieve.
     *
     * @return Whether an attestation is active.
     */
    function isAttestationActive(bytes32 uuid) external view returns (bool);

    /**
     * @dev Returns all received attestation UUIDs.
     *
     * @param recipient The recipient of the attestation.
     * @param schema The UUID of the AS.
     * @param start The offset to start from.
     * @param length The number of total members to retrieve.
     * @param reverseOrder Whether the offset starts from the end and the data is returned in reverse.
     *
     * @return An array of attestation UUIDs.
     */
    function getReceivedAttestationUUIDs(
        address recipient,
        bytes32 schema,
        uint256 start,
        uint256 length,
        bool reverseOrder
    ) external view returns (bytes32[] memory);

    /**
     * @dev Returns the number of received attestation UUIDs.
     *
     * @param recipient The recipient of the attestation.
     * @param schema The UUID of the AS.
     *
     * @return The number of attestations.
     */
    function getReceivedAttestationUUIDsCount(address recipient, bytes32 schema)
        external
        view
        returns (uint256);

    /**
     * @dev Returns all sent attestation UUIDs.
     *
     * @param attester The attesting account.
     * @param schema The UUID of the AS.
     * @param start The offset to start from.
     * @param length The number of total members to retrieve.
     * @param reverseOrder Whether the offset starts from the end and the data is returned in reverse.
     *
     * @return An array of attestation UUIDs.
     */
    function getSentAttestationUUIDs(
        address attester,
        bytes32 schema,
        uint256 start,
        uint256 length,
        bool reverseOrder
    ) external view returns (bytes32[] memory);

    /**
     * @dev Returns the number of sent attestation UUIDs.
     *
     * @param recipient The recipient of the attestation.
     * @param schema The UUID of the AS.
     *
     * @return The number of attestations.
     */
    function getSentAttestationUUIDsCount(address recipient, bytes32 schema)
        external
        view
        returns (uint256);

    /**
     * @dev Returns all attestations related to a specific attestation.
     *
     * @param uuid The UUID of the attestation to retrieve.
     * @param start The offset to start from.
     * @param length The number of total members to retrieve.
     * @param reverseOrder Whether the offset starts from the end and the data is returned in reverse.
     *
     * @return An array of attestation UUIDs.
     */
    function getRelatedAttestationUUIDs(
        bytes32 uuid,
        uint256 start,
        uint256 length,
        bool reverseOrder
    ) external view returns (bytes32[] memory);

    /**
     * @dev Returns the number of related attestation UUIDs.
     *
     * @param uuid The UUID of the attestation to retrieve.
     *
     * @return The number of related attestations.
     */
    function getRelatedAttestationUUIDsCount(bytes32 uuid)
        external
        view
        returns (uint256);

    /**
     * @dev Returns all per-schema attestation UUIDs.
     *
     * @param schema The UUID of the AS.
     * @param start The offset to start from.
     * @param length The number of total members to retrieve.
     * @param reverseOrder Whether the offset starts from the end and the data is returned in reverse.
     *
     * @return An array of attestation UUIDs.
     */
    function getSchemaAttestationUUIDs(
        bytes32 schema,
        uint256 start,
        uint256 length,
        bool reverseOrder
    ) external view returns (bytes32[] memory);

    /**
     * @dev Returns the number of per-schema  attestation UUIDs.
     *
     * @param schema The UUID of the AS.
     *
     * @return The number of attestations.
     */
    function getSchemaAttestationUUIDsCount(bytes32 schema)
        external
        view
        returns (uint256);
}

pragma solidity >=0.8.0 <0.9.0;

// SPDX-License-Identifier: MIT

/**
 * @title EIP712 typed signatures verifier for EAS delegated attestations interface.
 */
interface IEASEIP712Verifier {
    /**
     * @dev Returns the current nonce per-account.
     *
     * @param account The requested accunt.
     *
     * @return The current nonce.
     */
    function getNonce(address account) external view returns (uint256);

    /**
     * @dev Verifies signed attestation.
     *
     * @param recipient The recipient of the attestation.
     * @param schema The UUID of the AS.
     * @param expirationTime The expiration time of the attestation.
     * @param refUUID An optional related attestation's UUID.
     * @param data Additional custom data.
     * @param attester The attesting account.
     * @param v The recovery ID.
     * @param r The x-coordinate of the nonce R.
     * @param s The signature data.
     */
    function attest(
        address recipient,
        bytes32 schema,
        uint256 expirationTime,
        bytes32 refUUID,
        bytes calldata data,
        address attester,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Verifies signed revocations.
     *
     * @param uuid The UUID of the attestation to revoke.
     * @param attester The attesting account.
     * @param v The recovery ID.
     * @param r The x-coordinate of the nonce R.
     * @param s The signature data.
     */
    function revoke(
        bytes32 uuid,
        address attester,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMarketRegistry {
    function isVerifiedLender(uint256 _marketId, address _lender)
        external
        returns (bool, bytes32);

    function isMarketClosed(uint256 _marketId) external returns (bool);

    function isVerifiedBorrower(uint256 _marketId, address _borrower)
        external
        returns (bool, bytes32);

    function getMarketOwner(uint256 _marketId) external returns (address);

    function getMarketFeeRecipient(uint256 _marketId)
        external
        returns (address);

    function getMarketURI(uint256 _marketId) external returns (string memory);

    function getPaymentCycleDuration(uint256 _marketId)
        external
        returns (uint32);

    function getPaymentDefaultDuration(uint256 _marketId)
        external
        returns (uint32);

    function getBidExpirationTime(uint256 _marketId) external returns (uint32);

    function getMarketplaceFee(uint256 _marketId) external returns (uint16);
}