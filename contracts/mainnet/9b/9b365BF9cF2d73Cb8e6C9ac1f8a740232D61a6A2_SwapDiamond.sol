// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@dlsl/dev-modules/diamond/presets/OwnableDiamond/OwnableDiamond.sol";

import "./SwapDiamondStorage.sol";

contract SwapDiamond is OwnableDiamond, SwapDiamondStorage {
    receive() external payable {}

    function addFacet(address facet_, bytes4[] calldata selectors_) public override {
        super.addFacet(facet_, selectors_);

        _setType(selectors_, SelectorType.SwapDiamond);
    }

    function removeFacet(address facet_, bytes4[] calldata selectors_) public override {
        super.removeFacet(facet_, selectors_);

        _setType(selectors_, SelectorType.Undefined);
    }

    function updateFacet(
        address facet_,
        bytes4[] calldata fromSelectors_,
        bytes4[] calldata toSelectors_
    ) public override {
        super.updateFacet(facet_, fromSelectors_, toSelectors_);

        _setType(fromSelectors_, SelectorType.Undefined);
        _setType(toSelectors_, SelectorType.SwapDiamond);
    }

    function addFacet(
        address facet_,
        bytes4[] calldata selectors_,
        SelectorType[] calldata types_
    ) external {
        super.addFacet(facet_, selectors_);

        _setTypes(selectors_, types_);
    }

    function updateFacet(
        address facet_,
        bytes4[] calldata fromSelectors_,
        bytes4[] calldata toSelectors_,
        SelectorType[] calldata toTypes_
    ) external {
        super.updateFacet(facet_, fromSelectors_, toSelectors_);

        _setType(fromSelectors_, SelectorType.Undefined);
        _setTypes(toSelectors_, toTypes_);
    }

    function _setType(bytes4[] calldata selectors_, SelectorType type_) internal {
        for (uint256 i = 0; i < selectors_.length; ++i) {
            _getSwapDiamondStorage().selectorTypes[selectors_[i]] = type_;
        }
    }

    function _setTypes(bytes4[] calldata selectors_, SelectorType[] calldata types_) internal {
        require(selectors_.length == types_.length, "SwapDiamond: lengths mismatch");

        for (uint256 i = 0; i < selectors_.length; ++i) {
            _getSwapDiamondStorage().selectorTypes[selectors_[i]] = types_[i];
        }
    }

    function _beforeFallback(address facet_, bytes4 selector_) internal override {
        super._beforeFallback(facet_, selector_);

        require(
            _getSwapDiamondStorage().selectorTypes[selector_] == SelectorType.SwapDiamond,
            "SwapDiamond: wrong selector type"
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import {DiamondStorage} from "./DiamondStorage.sol";

/**
 *  @notice The Diamond standard module
 *
 *  This is a custom implementation of a Diamond Proxy standard (https://eips.ethereum.org/EIPS/eip-2535).
 *  This contract acts as a highest level contract of that standard. What is different from the EIP2535,
 *  in order to use the DiamondStorage, storage is defined in a separate contract that the facets have to inherit from,
 *  not an internal library.
 *
 *  As a convention, view and pure function should be defined in the storage contract while function that modify state, in
 *  the facet itself.
 *
 *  If you wish to add a receive() function, you can attach a "0x00000000" selector to a facet that has such function.
 */
contract Diamond is DiamondStorage {
    using Address for address;
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using EnumerableSet for EnumerableSet.AddressSet;

    /**
     *  @notice The payable fallback function that delegatecall's the facet with associated selector
     */
    // solhint-disable-next-line
    fallback() external payable virtual {
        address facet_ = getFacetBySelector(msg.sig);

        require(facet_ != address(0), "Diamond: selector is not registered");

        _beforeFallback(facet_, msg.sig);

        assembly {
            calldatacopy(0, 0, calldatasize())
            let result_ := delegatecall(gas(), facet_, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())

            switch result_
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     *  @notice The internal function to add facets to a diamond (aka diamondCut())
     *  @param facet_ the implementation address
     *  @param selectors_ the function selectors the implementation has
     */
    function _addFacet(address facet_, bytes4[] memory selectors_) internal {
        require(facet_.isContract(), "Diamond: facet is not a contract");
        require(selectors_.length > 0, "Diamond: no selectors provided");

        DStorage storage _ds = _getDiamondStorage();

        for (uint256 i = 0; i < selectors_.length; i++) {
            require(
                _ds.selectorToFacet[selectors_[i]] == address(0),
                "Diamond: selector already added"
            );

            _ds.selectorToFacet[selectors_[i]] = facet_;
            _ds.facetToSelectors[facet_].add(bytes32(selectors_[i]));
        }

        _ds.facets.add(facet_);
    }

    /**
     *  @notice The internal function to remove facets from the diamond
     *  @param facet_ the implementation to be removed. The facet itself will be removed only if there are no selectors left
     *  @param selectors_ the selectors of that implementation to be removed
     */
    function _removeFacet(address facet_, bytes4[] memory selectors_) internal {
        require(selectors_.length > 0, "Diamond: no selectors provided");

        DStorage storage _ds = _getDiamondStorage();

        for (uint256 i = 0; i < selectors_.length; i++) {
            require(
                _ds.selectorToFacet[selectors_[i]] == facet_,
                "Diamond: selector from another facet"
            );

            _ds.selectorToFacet[selectors_[i]] = address(0);
            _ds.facetToSelectors[facet_].remove(bytes32(selectors_[i]));
        }

        if (_ds.facetToSelectors[facet_].length() == 0) {
            _ds.facets.remove(facet_);
        }
    }

    /**
     *  @notice The internal function to update the facets of the diamond
     *  @param facet_ the facet to update
     *  @param fromSelectors_ the selectors to remove from the facet
     *  @param toSelectors_ the selectors to add to the facet
     */
    function _updateFacet(
        address facet_,
        bytes4[] memory fromSelectors_,
        bytes4[] memory toSelectors_
    ) internal {
        _addFacet(facet_, toSelectors_);
        _removeFacet(facet_, fromSelectors_);
    }

    function _beforeFallback(address facet_, bytes4 selector_) internal virtual {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/**
 *  @notice The Diamond standard module
 *
 *  This is the storage contract for the diamond proxy
 */
contract DiamondStorage {
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using EnumerableSet for EnumerableSet.AddressSet;

    /**
     *  @notice The struct slot where the storage is
     */
    bytes32 public constant DIAMOND_STORAGE_SLOT = keccak256("diamond.standard.diamond.storage");

    /**
     *  @notice The storage of the Diamond proxy
     */
    struct DStorage {
        mapping(bytes4 => address) selectorToFacet;
        mapping(address => EnumerableSet.Bytes32Set) facetToSelectors;
        EnumerableSet.AddressSet facets;
    }

    /**
     *  @notice The internal function to get the diamond proxy storage
     *  @return _ds the struct from the DIAMOND_STORAGE_SLOT
     */
    function _getDiamondStorage() internal pure returns (DStorage storage _ds) {
        bytes32 slot_ = DIAMOND_STORAGE_SLOT;

        assembly {
            _ds.slot := slot_
        }
    }

    /**
     *  @notice The function to get all the facets of this diamond
     *  @return facets_ the array of facets' addresses
     */
    function getFacets() public view returns (address[] memory facets_) {
        return _getDiamondStorage().facets.values();
    }

    /**
     *  @notice The function to get all the selectors assigned to the facet
     *  @param facet_ the facet to get assigned selectors of
     *  @return selectors_ the array of assigned selectors
     */
    function getFacetSelectors(address facet_) public view returns (bytes4[] memory selectors_) {
        EnumerableSet.Bytes32Set storage _f2s = _getDiamondStorage().facetToSelectors[facet_];

        selectors_ = new bytes4[](_f2s.length());

        for (uint256 i = 0; i < selectors_.length; i++) {
            selectors_[i] = bytes4(_f2s.at(i));
        }
    }

    /**
     *  @notice The function to get associated facet by the selector
     *  @param selector_ the selector
     *  @return facet_ the associated facet address
     */
    function getFacetBySelector(bytes4 selector_) public view returns (address facet_) {
        return _getDiamondStorage().selectorToFacet[selector_];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Diamond} from "../../Diamond.sol";
import {OwnableDiamondStorage} from "./OwnableDiamondStorage.sol";

/**
 *  @notice The Ownable preset of Diamond proxy
 */
contract OwnableDiamond is Diamond, OwnableDiamondStorage {
    constructor() {
        transferOwnership(msg.sender);
    }

    function transferOwnership(address newOwner_) public onlyOwner {
        require(newOwner_ != address(0), "OwnableDiamond: zero address owner");

        _getOwnableDiamondStorage().owner = newOwner_;
    }

    function addFacet(address facet_, bytes4[] memory selectors_) public virtual onlyOwner {
        _addFacet(facet_, selectors_);
    }

    function removeFacet(address facet_, bytes4[] memory selectors_) public virtual onlyOwner {
        _removeFacet(facet_, selectors_);
    }

    function updateFacet(
        address facet_,
        bytes4[] memory fromSelectors_,
        bytes4[] memory toSelectors_
    ) public virtual onlyOwner {
        _updateFacet(facet_, fromSelectors_, toSelectors_);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 *  @notice The storage contract of Ownable Diamond preset
 */
contract OwnableDiamondStorage {
    bytes32 public constant OWNABLE_DIAMOND_STORAGE_SLOT =
        keccak256("diamond.standard.ownablediamond.storage");

    struct ODStorage {
        address owner;
    }

    modifier onlyOwner() {
        address diamondOwner_ = owner();

        require(
            diamondOwner_ == address(0) || diamondOwner_ == msg.sender,
            "ODStorage: not an owner"
        );
        _;
    }

    function _getOwnableDiamondStorage() internal pure returns (ODStorage storage _ods) {
        bytes32 slot_ = OWNABLE_DIAMOND_STORAGE_SLOT;

        assembly {
            _ods.slot := slot_
        }
    }

    function owner() public view returns (address) {
        return _getOwnableDiamondStorage().owner;
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract SwapDiamondStorage {
    bytes32 public constant SWAP_DIAMOND_STORAGE_SLOT =
        keccak256("diamond.standard.swapdiamond.storage");

    enum SelectorType {
        Undefined,
        SwapDiamond,
        MasterRouter
    }

    struct SDStorage {
        mapping(bytes4 => SelectorType) selectorTypes;
    }

    function getSelectorType(bytes4 selector_) public view returns (SelectorType selectorType_) {
        return _getSwapDiamondStorage().selectorTypes[selector_];
    }

    function _getSwapDiamondStorage() internal pure returns (SDStorage storage _ds) {
        bytes32 slot_ = SWAP_DIAMOND_STORAGE_SLOT;

        assembly {
            _ds.slot := slot_
        }
    }
}