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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import { IChainRep } from "./IChainRep.sol";
import { Context } from "@openzeppelin/contracts/utils/Context.sol";
import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract ChainRep is IChainRep, Context {

    using EnumerableSet for EnumerableSet.UintSet;

    uint256 private _certificateId;
    uint256 private _reportId;

    mapping(uint256 => mapping(address => bool)) private _certificateIssued;
    mapping(uint256 => Certificate) private _certificateMap;
    mapping(uint256 => Report) private _reportMap;
    mapping(address => EnumerableSet.UintSet) private _contractReports;

    constructor() { }

    modifier _isAuthority(uint256 certificateId) {
        require(_certificateMap[certificateId].authority == _msgSender(), "not authority");
        _;
    }

    modifier _isReviewer(uint256 reportId) {
        require(_reportMap[reportId].reviewer == _msgSender(), "not reviewer");
        _;
    }

    function numCertificates () external view returns(uint256) {
        return _certificateId;
    }

    function issueCertificate (uint256 certificateId, address reviewer) external _isAuthority(certificateId) {
        require(!_certificateIssued[certificateId][reviewer], "already issued");
        _certificateIssued[certificateId][reviewer] = true;
        emit IssueCertificate(certificateId, _msgSender(), reviewer);
    }

    function revokeCertificate (uint256 certificateId, address reviewer) external _isAuthority(certificateId) {
        require(_certificateIssued[certificateId][reviewer], "not issued");
        delete _certificateIssued[certificateId][reviewer];
        emit RevokeCertificate(certificateId, _msgSender(), reviewer);
    }

    function createCertificate (string calldata name) external returns(uint256) {
        uint256 id = _certificateId++;
        _certificateMap[id].name = name;
        _certificateMap[id].authority = _msgSender();
        emit CreateCertificate(id, _msgSender(), name);
        return id;
    }

    function transferCertificateAuthority (uint256 certificateId, address to) external _isAuthority(certificateId) {
        _certificateMap[certificateId].authority = to;
        emit TransferCertificateAuthority(certificateId, _msgSender(), to);
    }

    function numReports () external view returns(uint256) {
        return _reportId;
    }

    function publishReport (address[] calldata contractAddresses, string[] calldata domains, string[] calldata tags, string calldata uri) external returns(uint256) {

        // Get report ID:
        uint256 id = _reportId++;

        // Set report data:
        _reportMap[id].reportId = id;
        _reportMap[id].reviewer = _msgSender();
        _reportMap[id].uri = uri;
        _reportMap[id].published = true;

        // Add reportId to contract address mapping set:
        for(uint i = 0; i < contractAddresses.length; i++) {
            _contractReports[contractAddresses[i]].add(id);
            emit ContractReported(id, contractAddresses[i]);
        }

        // Emit additional indexed report references:
        for(uint i = 0; i < domains.length; i++) {
            emit DomainReported(id, domains[i]);
        }
        for(uint i = 0; i < tags.length; i++) {
            emit TagReported(id, tags[i]);
        }

        // Emit Report Publish event:
        emit PublishReport(id, _msgSender());

        return id;
    }

    function unPublishReport (uint256 reportId) external _isReviewer(reportId) {
        _reportMap[reportId].published = false;
        emit UnPublishReport(reportId, _msgSender());
    }

    function getReport (uint256 reportId) external view returns(Report memory) {
        require(reportId < _reportId, "report dne");
        return (_reportMap[reportId]);
    }

    function isReviewer (address reviewer, uint256 reportId) public view returns(bool) {
        require(reportId < _reportId, "report dne");
        return reviewer == _reportMap[reportId].reviewer;
    }

    /**
    * @dev NOTE: O(n*m) time where n is # of reports and m is # of certificates searched
    */
    function getCertifiedContractReports (address contractAddress, uint256[] memory certificateIds) external view returns(Report[] memory) {
        uint256 maxLength = _contractReports[contractAddress].length();
        uint256 numCertified;
        Report[] memory res = new Report[](maxLength);
        for(uint256 i = 0; i < maxLength; i++) {
            uint256 reportId = _contractReports[contractAddress].at(i);
            if(_reportMap[reportId].published) {
                if(certificateIds.length > 0) {
                    for(uint256 j = 0; j < certificateIds.length; j++) {
                        if(isCertified(_reportMap[reportId].reviewer, certificateIds[j])) {
                            res[numCertified++] = _reportMap[reportId];
                            break;
                        }
                    }
                } else {
                    res[numCertified++] = _reportMap[reportId];
                }
            }
        }
        if(numCertified < maxLength) {
            Report[] memory resTrimmed = new Report[](numCertified);
            for(uint256 i = 0; i < numCertified; i++) {
                resTrimmed[i] = res[i];
            }
            res = resTrimmed;
        }
        return res;
    }

    function isCertificateAuthority (address authority, uint256 certificateId) public view returns(bool) {
        return authority == _certificateMap[certificateId].authority;
    }

    function isCertified (address reviewer, uint256 certificateId) public view returns(bool) {
        return _certificateIssued[certificateId][reviewer];
    }

}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IChainRep {

    struct Report {
        uint256 reportId;
        address reviewer;
        string uri;
        bool published;
    }

    struct Certificate {
        address authority;
        string name;
    }

    event IssueCertificate(uint256 indexed certificateId, address indexed authority, address indexed reviewer);

    event RevokeCertificate(uint256 indexed certificateId, address indexed authority, address indexed reviewer);

    event CreateCertificate(uint256 indexed certificateId, address indexed authority, string name);

    event TransferCertificateAuthority(uint256 indexed certificateId, address indexed from, address indexed to);

    event PublishReport(uint256 indexed reportId, address indexed reviewer);

    event ContractReported(uint256 indexed reportId, address indexed contractAddress);

    event DomainReported(uint256 indexed reportId, string indexed domain);

    event TagReported(uint256 indexed reportId, string indexed tag);

    event UnPublishReport(uint256 indexed reportId, address indexed reviewer);

    function numCertificates () external view returns(uint256);

    function issueCertificate (uint256 certificateId, address reviewer) external;

    function revokeCertificate (uint256 certificateId, address reviewer) external;

    function createCertificate (string calldata name) external returns(uint256);

    function transferCertificateAuthority (uint256 certificateId, address to) external;

    function numReports () external view returns(uint256);

    function publishReport (address[] calldata contractAddresses, string[] calldata domains, string[] calldata tags, string calldata uri) external returns(uint256);

    function unPublishReport (uint256 reportId) external;

    function getReport (uint256 reportId) external view returns(Report memory);

    function isReviewer (address reviewer, uint256 reportId) external view returns(bool);

    function getCertifiedContractReports (address contractAddress, uint256[] memory certificateIds) external view returns(Report[] memory);

    function isCertificateAuthority (address authority, uint256 certificateId) external view returns(bool);

    function isCertified (address reviewer, uint256 certificateId) external view returns(bool);

    // listCertificates
}