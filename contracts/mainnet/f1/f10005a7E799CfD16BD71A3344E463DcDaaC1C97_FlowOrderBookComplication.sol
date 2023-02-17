// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1271.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC1271 standard signature validation method for
 * contracts as defined in https://eips.ethereum.org/EIPS/eip-1271[ERC-1271].
 *
 * _Available since v4.1._
 */
interface IERC1271 {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param hash      Hash of the data to be signed
     * @param signature Signature byte array associated with _data
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
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

// SPDX-License-Identifier: MIT
// solhint-disable not-rely-on-time
pragma solidity 0.8.14;

// external imports
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

// internal imports
import { OrderTypes, SignatureChecker } from "../libs/SignatureChecker.sol";
import { IFlowComplication } from "../interfaces/IFlowComplication.sol";

/**
 * @title FlowOrderBookComplication
 * @author nneverlander. Twitter @nneverlander
 * @notice Complication to execute orderbook orders
 */
contract FlowOrderBookComplication is
    IFlowComplication,
    Ownable,
    SignatureChecker
{
    using EnumerableSet for EnumerableSet.AddressSet;
    uint256 public constant PRECISION = 1e4; // precision for division; similar to bps

    /// @dev WETH address of the chain being used
    // solhint-disable-next-line var-name-mixedcase
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    // keccak256('Order(bool isSellOrder,address signer,uint256[] constraints,OrderItem[] nfts,address[] execParams,bytes extraParams)OrderItem(address collection,TokenInfo[] tokens)TokenInfo(uint256 tokenId,uint256 numTokens)')
    bytes32 public constant ORDER_HASH =
        0x7bcfb5a29031e6b8d34ca1a14dd0a1f5cb11b20f755bb2a31ee3c4b143477e4a;

    // keccak256('OrderItem(address collection,TokenInfo[] tokens)TokenInfo(uint256 tokenId,uint256 numTokens)')
    bytes32 public constant ORDER_ITEM_HASH =
        0xf73f37e9f570369ceaab59cef16249ae1c0ad1afd592d656afac0be6f63b87e0;

    // keccak256('TokenInfo(uint256 tokenId,uint256 numTokens)')
    bytes32 public constant TOKEN_INFO_HASH =
        0x88f0bd19d14f8b5d22c0605a15d9fffc285ebc8c86fb21139456d305982906f1;

    /// @dev Used in order signing with EIP-712
    // solhint-disable-next-line var-name-mixedcase
    bytes32 public immutable DOMAIN_SEPARATOR;

    /// @dev Storage variable that keeps track of valid currencies used for payment (tokens)
    EnumerableSet.AddressSet private _currencies;

    bool public trustedExecEnabled = false;

    event CurrencyAdded(address currency);
    event CurrencyRemoved(address currency);
    event TrustedExecutionChanged(bool oldVal, bool newVal);

    constructor() {
        // Calculate the domain separator
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256("FlowComplication"),
                keccak256(bytes("1")), // for versionId = 1
                block.chainid,
                address(this)
            )
        );

        // add default currencies
        _currencies.add(WETH);
        _currencies.add(address(0)); // ETH
    }

    // ======================================================= EXTERNAL FUNCTIONS ==================================================

    /**
   * @notice Checks whether one to one matches can be executed
   * @dev This function is called by the main exchange to check whether one to one matches can be executed.
          It checks whether orders have the right constraints - i.e they have one specific NFT only, whether time is still valid,
          prices are valid and whether the nfts intersect.
   * @param makerOrder1 first makerOrder
   * @param makerOrder2 second makerOrder
   * @return returns whether the order can be executed, orderHashes and the execution price
   */
    function canExecMatchOneToOne(
        OrderTypes.MakerOrder calldata makerOrder1,
        OrderTypes.MakerOrder calldata makerOrder2
    ) external view override returns (bool, bytes32, bytes32, uint256) {
        // check if the orders are valid
        bool _isPriceValid;
        uint256 makerOrder1Price = _getCurrentPrice(makerOrder1);
        uint256 makerOrder2Price = _getCurrentPrice(makerOrder2);
        uint256 execPrice;
        if (makerOrder1.isSellOrder) {
            _isPriceValid = makerOrder2Price >= makerOrder1Price;
            execPrice = makerOrder1Price;
        } else {
            _isPriceValid = makerOrder1Price >= makerOrder2Price;
            execPrice = makerOrder2Price;
        }

        bytes32 sellOrderHash = _hash(makerOrder1);
        bytes32 buyOrderHash = _hash(makerOrder2);

        if (trustedExecEnabled) {
            bool trustedExec = makerOrder2.constraints.length == 8 &&
                makerOrder2.constraints[7] == 1 &&
                makerOrder1.constraints.length == 8 &&
                makerOrder1.constraints[7] == 1;
            if (trustedExec) {
                bool sigValid = SignatureChecker.verify(
                    sellOrderHash,
                    makerOrder1.signer,
                    makerOrder1.sig,
                    DOMAIN_SEPARATOR
                ) &&
                    SignatureChecker.verify(
                        buyOrderHash,
                        makerOrder2.signer,
                        makerOrder2.sig,
                        DOMAIN_SEPARATOR
                    );
                return (sigValid, sellOrderHash, buyOrderHash, execPrice);
            }
        }

        require(
            verifyMatchOneToOneOrders(
                sellOrderHash,
                buyOrderHash,
                makerOrder1,
                makerOrder2
            ),
            "order not verified"
        );

        // check constraints
        bool numItemsValid = makerOrder2.constraints[0] ==
            makerOrder1.constraints[0] &&
            makerOrder2.constraints[0] == 1 &&
            makerOrder2.nfts.length == 1 &&
            makerOrder2.nfts[0].tokens.length == 1 &&
            makerOrder1.nfts.length == 1 &&
            makerOrder1.nfts[0].tokens.length == 1;

        bool _isTimeValid = makerOrder2.constraints[3] <= block.timestamp &&
            makerOrder2.constraints[4] >= block.timestamp &&
            makerOrder1.constraints[3] <= block.timestamp &&
            makerOrder1.constraints[4] >= block.timestamp;

        return (
            numItemsValid &&
                _isTimeValid &&
                doItemsIntersect(makerOrder1.nfts, makerOrder2.nfts) &&
                _isPriceValid,
            sellOrderHash,
            buyOrderHash,
            execPrice
        );
    }

    /**
     * @dev This function is called by an offline checker to verify whether matches can be executed
     * irrespective of the trusted execution constraint
     */
    function verifyCanExecMatchOneToOne(
        OrderTypes.MakerOrder calldata makerOrder1,
        OrderTypes.MakerOrder calldata makerOrder2
    ) external view returns (bool, bytes32, bytes32, uint256) {
        // check if the orders are valid
        bool _isPriceValid;
        uint256 makerOrder1Price = _getCurrentPrice(makerOrder1);
        uint256 makerOrder2Price = _getCurrentPrice(makerOrder2);
        uint256 execPrice;
        if (makerOrder1.isSellOrder) {
            _isPriceValid = makerOrder2Price >= makerOrder1Price;
            execPrice = makerOrder1Price;
        } else {
            _isPriceValid = makerOrder1Price >= makerOrder2Price;
            execPrice = makerOrder2Price;
        }

        bytes32 sellOrderHash = _hash(makerOrder1);
        bytes32 buyOrderHash = _hash(makerOrder2);

        require(
            verifyMatchOneToOneOrders(
                sellOrderHash,
                buyOrderHash,
                makerOrder1,
                makerOrder2
            ),
            "order not verified"
        );

        // check constraints
        bool numItemsValid = makerOrder2.constraints[0] ==
            makerOrder1.constraints[0] &&
            makerOrder2.constraints[0] == 1 &&
            makerOrder2.nfts.length == 1 &&
            makerOrder2.nfts[0].tokens.length == 1 &&
            makerOrder1.nfts.length == 1 &&
            makerOrder1.nfts[0].tokens.length == 1;

        bool _isTimeValid = makerOrder2.constraints[3] <= block.timestamp &&
            makerOrder2.constraints[4] >= block.timestamp &&
            makerOrder1.constraints[3] <= block.timestamp &&
            makerOrder1.constraints[4] >= block.timestamp;

        return (
            numItemsValid &&
                _isTimeValid &&
                doItemsIntersect(makerOrder1.nfts, makerOrder2.nfts) &&
                _isPriceValid,
            sellOrderHash,
            buyOrderHash,
            execPrice
        );
    }

    /**
   * @notice Checks whether one to many matches can be executed
   * @dev This function is called by the main exchange to check whether one to many matches can be executed.
          It checks whether orders have the right constraints - i.e they have the right number of items, whether time is still valid,
          prices are valid and whether the nfts intersect. All orders are expected to contain specific items.
   * @param makerOrder the one makerOrder
   * @param manyMakerOrders many maker orders
   * @return returns whether the order can be executed and orderHash of the one side order
   */
    function canExecMatchOneToMany(
        OrderTypes.MakerOrder calldata makerOrder,
        OrderTypes.MakerOrder[] calldata manyMakerOrders
    ) external view override returns (bool, bytes32) {
        bytes32 makerOrderHash = _hash(makerOrder);

        if (trustedExecEnabled) {
            bool isTrustedExec = makerOrder.constraints.length == 8 &&
                makerOrder.constraints[7] == 1;
            for (uint256 i; i < manyMakerOrders.length; ) {
                isTrustedExec =
                    isTrustedExec &&
                    manyMakerOrders[i].constraints.length == 8 &&
                    manyMakerOrders[i].constraints[7] == 1;
                if (!isTrustedExec) {
                    break; // short circuit
                }
                unchecked {
                    ++i;
                }
            }

            if (isTrustedExec) {
                bool sigValid = SignatureChecker.verify(
                    makerOrderHash,
                    makerOrder.signer,
                    makerOrder.sig,
                    DOMAIN_SEPARATOR
                );
                return (sigValid, makerOrderHash);
            }
        }

        require(
            isOrderValid(makerOrder, makerOrderHash),
            "invalid maker order"
        );

        // check the constraints of the 'one' maker order
        uint256 numNftsInOneOrder;
        for (uint256 i; i < makerOrder.nfts.length; ) {
            numNftsInOneOrder =
                numNftsInOneOrder +
                makerOrder.nfts[i].tokens.length;
            unchecked {
                ++i;
            }
        }

        // check the constraints of many maker orders
        uint256 totalNftsInManyOrders;
        bool numNftsPerManyOrderValid = true;
        bool isOrdersTimeValid = true;
        bool itemsIntersect = true;
        for (uint256 i; i < manyMakerOrders.length; ) {
            uint256 nftsLength = manyMakerOrders[i].nfts.length;
            uint256 numNftsPerOrder;
            for (uint256 j; j < nftsLength; ) {
                numNftsPerOrder =
                    numNftsPerOrder +
                    manyMakerOrders[i].nfts[j].tokens.length;
                unchecked {
                    ++j;
                }
            }
            numNftsPerManyOrderValid =
                numNftsPerManyOrderValid &&
                manyMakerOrders[i].constraints[0] == numNftsPerOrder;
            totalNftsInManyOrders = totalNftsInManyOrders + numNftsPerOrder;

            isOrdersTimeValid =
                isOrdersTimeValid &&
                manyMakerOrders[i].constraints[3] <= block.timestamp &&
                manyMakerOrders[i].constraints[4] >= block.timestamp;

            itemsIntersect =
                itemsIntersect &&
                doItemsIntersect(makerOrder.nfts, manyMakerOrders[i].nfts);

            if (!numNftsPerManyOrderValid) {
                return (false, makerOrderHash); // short circuit
            }

            unchecked {
                ++i;
            }
        }

        bool _isTimeValid = isOrdersTimeValid &&
            makerOrder.constraints[3] <= block.timestamp &&
            makerOrder.constraints[4] >= block.timestamp;

        uint256 currentMakerOrderPrice = _getCurrentPrice(makerOrder);
        uint256 sumCurrentOrderPrices = _sumCurrentPrices(manyMakerOrders);

        bool _isPriceValid;
        if (makerOrder.isSellOrder) {
            _isPriceValid = sumCurrentOrderPrices >= currentMakerOrderPrice;
        } else {
            _isPriceValid = sumCurrentOrderPrices <= currentMakerOrderPrice;
        }

        return (
            numNftsInOneOrder == makerOrder.constraints[0] &&
                numNftsInOneOrder == totalNftsInManyOrders &&
                _isTimeValid &&
                itemsIntersect &&
                _isPriceValid,
            makerOrderHash
        );
    }

    /**
     * @dev This function is called by an offline checker to verify whether matches can be executed
     * irrespective of the trusted execution constraint
     */
    function verifyCanExecMatchOneToMany(
        OrderTypes.MakerOrder calldata makerOrder,
        OrderTypes.MakerOrder[] calldata manyMakerOrders
    ) external view returns (bool, bytes32) {
        bytes32 makerOrderHash = _hash(makerOrder);
        require(
            isOrderValid(makerOrder, makerOrderHash),
            "invalid maker order"
        );

        // check the constraints of the 'one' maker order
        uint256 numNftsInOneOrder;
        for (uint256 i; i < makerOrder.nfts.length; ) {
            numNftsInOneOrder =
                numNftsInOneOrder +
                makerOrder.nfts[i].tokens.length;
            unchecked {
                ++i;
            }
        }

        // check the constraints of many maker orders
        uint256 totalNftsInManyOrders;
        bool numNftsPerManyOrderValid = true;
        bool isOrdersTimeValid = true;
        bool itemsIntersect = true;
        for (uint256 i; i < manyMakerOrders.length; ) {
            uint256 nftsLength = manyMakerOrders[i].nfts.length;
            uint256 numNftsPerOrder;
            for (uint256 j; j < nftsLength; ) {
                numNftsPerOrder =
                    numNftsPerOrder +
                    manyMakerOrders[i].nfts[j].tokens.length;
                unchecked {
                    ++j;
                }
            }
            numNftsPerManyOrderValid =
                numNftsPerManyOrderValid &&
                manyMakerOrders[i].constraints[0] == numNftsPerOrder;
            totalNftsInManyOrders = totalNftsInManyOrders + numNftsPerOrder;

            isOrdersTimeValid =
                isOrdersTimeValid &&
                manyMakerOrders[i].constraints[3] <= block.timestamp &&
                manyMakerOrders[i].constraints[4] >= block.timestamp;

            itemsIntersect =
                itemsIntersect &&
                doItemsIntersect(makerOrder.nfts, manyMakerOrders[i].nfts);

            if (!numNftsPerManyOrderValid) {
                return (false, makerOrderHash); // short circuit
            }

            unchecked {
                ++i;
            }
        }

        bool _isTimeValid = isOrdersTimeValid &&
            makerOrder.constraints[3] <= block.timestamp &&
            makerOrder.constraints[4] >= block.timestamp;

        uint256 currentMakerOrderPrice = _getCurrentPrice(makerOrder);
        uint256 sumCurrentOrderPrices = _sumCurrentPrices(manyMakerOrders);

        bool _isPriceValid;
        if (makerOrder.isSellOrder) {
            _isPriceValid = sumCurrentOrderPrices >= currentMakerOrderPrice;
        } else {
            _isPriceValid = sumCurrentOrderPrices <= currentMakerOrderPrice;
        }

        return (
            numNftsInOneOrder == makerOrder.constraints[0] &&
                numNftsInOneOrder == totalNftsInManyOrders &&
                _isTimeValid &&
                itemsIntersect &&
                _isPriceValid,
            makerOrderHash
        );
    }

    /**
   * @notice Checks whether match orders with a higher level intent can be executed
   * @dev This function is called by the main exchange to check whether one to one matches can be executed.
          It checks whether orders have the right constraints - i.e they have the right number of items, whether time is still valid,
          prices are valid and whether the nfts intersect
   * @param sell sell order
   * @param buy buy order
   * @param constructedNfts - nfts constructed by the off chain matching engine
   * @return returns whether the order can be execute, orderHashes and the execution price
   */
    function canExecMatchOrder(
        OrderTypes.MakerOrder calldata sell,
        OrderTypes.MakerOrder calldata buy,
        OrderTypes.OrderItem[] calldata constructedNfts
    ) external view override returns (bool, bytes32, bytes32, uint256) {
        // check if orders are valid
        (bool _isPriceValid, uint256 execPrice) = isPriceValid(sell, buy);

        bytes32 sellOrderHash = _hash(sell);
        bytes32 buyOrderHash = _hash(buy);

        if (trustedExecEnabled) {
            bool trustedExec = sell.constraints.length == 8 &&
                sell.constraints[7] == 1 &&
                buy.constraints.length == 8 &&
                buy.constraints[7] == 1;
            if (trustedExec) {
                bool sigValid = SignatureChecker.verify(
                    sellOrderHash,
                    sell.signer,
                    sell.sig,
                    DOMAIN_SEPARATOR
                ) &&
                    SignatureChecker.verify(
                        buyOrderHash,
                        buy.signer,
                        buy.sig,
                        DOMAIN_SEPARATOR
                    );
                return (sigValid, sellOrderHash, buyOrderHash, execPrice);
            }
        }

        require(
            verifyMatchOrders(sellOrderHash, buyOrderHash, sell, buy),
            "order not verified"
        );

        return (
            isTimeValid(sell, buy) &&
                _isPriceValid &&
                areNumMatchItemsValid(sell, buy, constructedNfts) &&
                doItemsIntersect(sell.nfts, constructedNfts) &&
                doItemsIntersect(buy.nfts, constructedNfts),
            sellOrderHash,
            buyOrderHash,
            execPrice
        );
    }

    /**
     * @dev This function is called by an offline checker to verify whether matches can be executed
     * irrespective of the trusted execution constraint
     */
    function verifyCanExecMatchOrder(
        OrderTypes.MakerOrder calldata sell,
        OrderTypes.MakerOrder calldata buy,
        OrderTypes.OrderItem[] calldata constructedNfts
    ) external view returns (bool, bytes32, bytes32, uint256) {
        // check if orders are valid
        (bool _isPriceValid, uint256 execPrice) = isPriceValid(sell, buy);

        bytes32 sellOrderHash = _hash(sell);
        bytes32 buyOrderHash = _hash(buy);

        require(
            verifyMatchOrders(sellOrderHash, buyOrderHash, sell, buy),
            "order not verified"
        );

        return (
            isTimeValid(sell, buy) &&
                _isPriceValid &&
                areNumMatchItemsValid(sell, buy, constructedNfts) &&
                doItemsIntersect(sell.nfts, constructedNfts) &&
                doItemsIntersect(buy.nfts, constructedNfts),
            sellOrderHash,
            buyOrderHash,
            execPrice
        );
    }

    /**
   * @notice Checks whether one to one taker orders can be executed
   * @dev This function is called by the main exchange to check whether one to one taker orders can be executed.
          It checks whether orders have the right constraints - i.e they have one NFT only and whether time is still valid
   * @param makerOrder the makerOrder
   * @return returns whether the order can be executed and makerOrderHash
   */
    function canExecTakeOneOrder(
        OrderTypes.MakerOrder calldata makerOrder
    ) external view override returns (bool, bytes32) {
        // check if makerOrder is valid
        bytes32 makerOrderHash = _hash(makerOrder);
        require(
            isOrderValid(makerOrder, makerOrderHash),
            "invalid maker order"
        );

        bool numItemsValid = makerOrder.constraints[0] == 1 &&
            makerOrder.nfts.length == 1 &&
            makerOrder.nfts[0].tokens.length == 1;
        bool _isTimeValid = makerOrder.constraints[3] <= block.timestamp &&
            makerOrder.constraints[4] >= block.timestamp;

        return (numItemsValid && _isTimeValid, makerOrderHash);
    }

    /**
   * @notice Checks whether take orders with a higher level intent can be executed
   * @dev This function is called by the main exchange to check whether take orders with a higher level intent can be executed.
          It checks whether orders have the right constraints - i.e they have the right number of items, whether time is still valid
          and whether the nfts intersect
   * @param makerOrder the maker order
   * @param takerItems the taker items specified by the taker
   * @return returns whether order can be executed and the makerOrderHash
   */
    function canExecTakeOrder(
        OrderTypes.MakerOrder calldata makerOrder,
        OrderTypes.OrderItem[] calldata takerItems
    ) external view override returns (bool, bytes32) {
        // check if makerOrder is valid
        bytes32 makerOrderHash = _hash(makerOrder);
        require(
            isOrderValid(makerOrder, makerOrderHash),
            "invalid maker order"
        );

        return (
            makerOrder.constraints[3] <= block.timestamp &&
                makerOrder.constraints[4] >= block.timestamp &&
                areNumTakerItemsValid(makerOrder, takerItems) &&
                doItemsIntersect(makerOrder.nfts, takerItems),
            makerOrderHash
        );
    }

    // ======================================================= PUBLIC FUNCTIONS ==================================================

    /**
     * @notice Checks whether orders are valid
     * @dev Checks whether currencies match, sides match, complications match and if each order is valid (see isOrderValid)
     * @param sellOrderHash hash of the sell order
     * @param buyOrderHash hash of the buy order
     * @param sell the sell order
     * @param buy the buy order
     * @return whether orders are valid
     */
    function verifyMatchOneToOneOrders(
        bytes32 sellOrderHash,
        bytes32 buyOrderHash,
        OrderTypes.MakerOrder calldata sell,
        OrderTypes.MakerOrder calldata buy
    ) public view returns (bool) {
        bool currenciesMatch = sell.execParams[1] == buy.execParams[1] ||
            (sell.execParams[1] == address(0) && buy.execParams[1] == WETH);

        return (sell.isSellOrder &&
            !buy.isSellOrder &&
            sell.execParams[0] == buy.execParams[0] &&
            sell.signer != buy.signer &&
            currenciesMatch &&
            isOrderValid(sell, sellOrderHash) &&
            isOrderValid(buy, buyOrderHash));
    }

    /**
     * @notice Checks whether orders are valid
     * @dev Checks whether currencies match, sides match, complications match and if each order is valid (see isOrderValid)
     * @param sell the sell order
     * @param buy the buy order
     * @return whether orders are valid and orderHash
     */
    function verifyMatchOneToManyOrders(
        bool verifySellOrder,
        OrderTypes.MakerOrder calldata sell,
        OrderTypes.MakerOrder calldata buy
    ) public view override returns (bool, bytes32) {
        bool currenciesMatch = sell.execParams[1] == buy.execParams[1] ||
            (sell.execParams[1] == address(0) && buy.execParams[1] == WETH);

        bool _orderValid;
        bytes32 orderHash;

        if (verifySellOrder) {
            orderHash = _hash(sell);
            _orderValid = isOrderValid(sell, orderHash);
        } else {
            orderHash = _hash(buy);
            _orderValid = isOrderValid(buy, orderHash);
        }
        return (
            sell.isSellOrder &&
                !buy.isSellOrder &&
                sell.execParams[0] == buy.execParams[0] &&
                sell.signer != buy.signer &&
                currenciesMatch &&
                _orderValid,
            orderHash
        );
    }

    /**
   * @notice Checks whether orders are valid
   * @dev Checks whether currencies match, sides match, complications match and if each order is valid (see isOrderValid)
          Also checks if the given complication can execute this order
   * @param sellOrderHash hash of the sell order
   * @param buyOrderHash hash of the buy order
   * @param sell the sell order
   * @param buy the buy order
   * @return whether orders are valid
   */
    function verifyMatchOrders(
        bytes32 sellOrderHash,
        bytes32 buyOrderHash,
        OrderTypes.MakerOrder calldata sell,
        OrderTypes.MakerOrder calldata buy
    ) public view returns (bool) {
        bool currenciesMatch = sell.execParams[1] == buy.execParams[1] ||
            (sell.execParams[1] == address(0) && buy.execParams[1] == WETH);

        return (sell.isSellOrder &&
            !buy.isSellOrder &&
            sell.execParams[0] == buy.execParams[0] &&
            sell.signer != buy.signer &&
            currenciesMatch &&
            isOrderValid(sell, sellOrderHash) &&
            isOrderValid(buy, buyOrderHash));
    }

    /**
     * @notice Verifies the validity of the order
     * @dev checks if signature is valid and if the complication and currency are valid
     * @param order the order
     * @param orderHash computed hash of the order
     * @return whether the order is valid
     */
    function isOrderValid(
        OrderTypes.MakerOrder calldata order,
        bytes32 orderHash
    ) public view returns (bool) {
        // Verify the validity of the signature
        bool sigValid = SignatureChecker.verify(
            orderHash,
            order.signer,
            order.sig,
            DOMAIN_SEPARATOR
        );

        return (sigValid &&
            order.execParams[0] == address(this) &&
            _currencies.contains(order.execParams[1]));
    }

    /// @dev checks whether the orders are expired
    function isTimeValid(
        OrderTypes.MakerOrder calldata sell,
        OrderTypes.MakerOrder calldata buy
    ) public view returns (bool) {
        return
            sell.constraints[3] <= block.timestamp &&
            sell.constraints[4] >= block.timestamp &&
            buy.constraints[3] <= block.timestamp &&
            buy.constraints[4] >= block.timestamp;
    }

    /// @dev checks whether the price is valid; a buy order should always have a higher price than a sell order
    function isPriceValid(
        OrderTypes.MakerOrder calldata sell,
        OrderTypes.MakerOrder calldata buy
    ) public view returns (bool, uint256) {
        (uint256 currentSellPrice, uint256 currentBuyPrice) = (
            _getCurrentPrice(sell),
            _getCurrentPrice(buy)
        );
        return (currentBuyPrice >= currentSellPrice, currentSellPrice);
    }

    /// @dev sanity check to make sure the constructed nfts conform to the user signed constraints
    function areNumMatchItemsValid(
        OrderTypes.MakerOrder calldata sell,
        OrderTypes.MakerOrder calldata buy,
        OrderTypes.OrderItem[] calldata constructedNfts
    ) public pure returns (bool) {
        uint256 numConstructedItems;
        for (uint256 i; i < constructedNfts.length; ) {
            unchecked {
                numConstructedItems =
                    numConstructedItems +
                    constructedNfts[i].tokens.length;
                ++i;
            }
        }
        return
            numConstructedItems >= buy.constraints[0] &&
            numConstructedItems <= sell.constraints[0];
    }

    /// @dev sanity check to make sure that a taker is specifying the right number of items
    function areNumTakerItemsValid(
        OrderTypes.MakerOrder calldata makerOrder,
        OrderTypes.OrderItem[] calldata takerItems
    ) public pure returns (bool) {
        uint256 numTakerItems;
        for (uint256 i; i < takerItems.length; ) {
            unchecked {
                numTakerItems = numTakerItems + takerItems[i].tokens.length;
                ++i;
            }
        }
        return makerOrder.constraints[0] == numTakerItems;
    }

    /**
     * @notice Checks whether nfts intersect
     * @dev This function checks whether there are intersecting nfts between two orders
     * @param order1Nfts nfts in the first order
     * @param order2Nfts nfts in the second order
     * @return returns whether items intersect
     */
    function doItemsIntersect(
        OrderTypes.OrderItem[] calldata order1Nfts,
        OrderTypes.OrderItem[] calldata order2Nfts
    ) public pure returns (bool) {
        uint256 order1NftsLength = order1Nfts.length;
        uint256 order2NftsLength = order2Nfts.length;
        // case where maker/taker didn't specify any items
        if (order1NftsLength == 0 || order2NftsLength == 0) {
            return true;
        }

        uint256 numCollsMatched;
        unchecked {
            for (uint256 i; i < order2NftsLength; ) {
                for (uint256 j; j < order1NftsLength; ) {
                    if (order1Nfts[j].collection == order2Nfts[i].collection) {
                        // increment numCollsMatched
                        ++numCollsMatched;
                        // check if tokenIds intersect
                        bool tokenIdsIntersect = doTokenIdsIntersect(
                            order1Nfts[j],
                            order2Nfts[i]
                        );
                        require(tokenIdsIntersect, "tokenIds dont intersect");
                        // short circuit
                        break;
                    }
                    ++j;
                }
                ++i;
            }
        }

        return numCollsMatched == order2NftsLength;
    }

    /**
     * @notice Checks whether tokenIds intersect
     * @dev This function checks whether there are intersecting tokenIds between two order items
     * @param item1 first item
     * @param item2 second item
     * @return returns whether tokenIds intersect
     */
    function doTokenIdsIntersect(
        OrderTypes.OrderItem calldata item1,
        OrderTypes.OrderItem calldata item2
    ) public pure returns (bool) {
        uint256 item1TokensLength = item1.tokens.length;
        uint256 item2TokensLength = item2.tokens.length;
        // case where maker/taker didn't specify any tokenIds for this collection
        if (item1TokensLength == 0 || item2TokensLength == 0) {
            return true;
        }
        uint256 numTokenIdsPerCollMatched;
        unchecked {
            for (uint256 k; k < item2TokensLength; ) {
                // solhint-disable-next-line use-forbidden-name
                for (uint256 l; l < item1TokensLength; ) {
                    if (item1.tokens[l].tokenId == item2.tokens[k].tokenId) {
                        // increment numTokenIdsPerCollMatched
                        ++numTokenIdsPerCollMatched;
                        // short circuit
                        break;
                    }
                    ++l;
                }
                ++k;
            }
        }

        return numTokenIdsPerCollMatched == item2TokensLength;
    }

    // ======================================================= UTILS ============================================================

    /// @dev hashes the given order with the help of _nftsHash and _tokensHash
    function _hash(
        OrderTypes.MakerOrder calldata order
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    ORDER_HASH,
                    order.isSellOrder,
                    order.signer,
                    keccak256(abi.encodePacked(order.constraints)),
                    _nftsHash(order.nfts),
                    keccak256(abi.encodePacked(order.execParams)),
                    keccak256(order.extraParams)
                )
            );
    }

    function _nftsHash(
        OrderTypes.OrderItem[] calldata nfts
    ) internal pure returns (bytes32) {
        bytes32[] memory hashes = new bytes32[](nfts.length);
        for (uint256 i; i < nfts.length; ) {
            bytes32 hash = keccak256(
                abi.encode(
                    ORDER_ITEM_HASH,
                    nfts[i].collection,
                    _tokensHash(nfts[i].tokens)
                )
            );
            hashes[i] = hash;
            unchecked {
                ++i;
            }
        }
        bytes32 nftsHash = keccak256(abi.encodePacked(hashes));
        return nftsHash;
    }

    function _tokensHash(
        OrderTypes.TokenInfo[] calldata tokens
    ) internal pure returns (bytes32) {
        bytes32[] memory hashes = new bytes32[](tokens.length);
        for (uint256 i; i < tokens.length; ) {
            bytes32 hash = keccak256(
                abi.encode(
                    TOKEN_INFO_HASH,
                    tokens[i].tokenId,
                    tokens[i].numTokens
                )
            );
            hashes[i] = hash;
            unchecked {
                ++i;
            }
        }
        bytes32 tokensHash = keccak256(abi.encodePacked(hashes));
        return tokensHash;
    }

    /// @dev returns the sum of current order prices; used in match one to many orders
    function _sumCurrentPrices(
        OrderTypes.MakerOrder[] calldata orders
    ) internal view returns (uint256) {
        uint256 sum;
        uint256 ordersLength = orders.length;
        for (uint256 i; i < ordersLength; ) {
            sum = sum + _getCurrentPrice(orders[i]);
            unchecked {
                ++i;
            }
        }
        return sum;
    }

    /// @dev Gets current order price for orders that vary in price over time (dutch and reverse dutch auctions)
    function _getCurrentPrice(
        OrderTypes.MakerOrder calldata order
    ) internal view returns (uint256) {
        (uint256 startPrice, uint256 endPrice) = (
            order.constraints[1],
            order.constraints[2]
        );
        if (startPrice == endPrice) {
            return startPrice;
        }

        uint256 duration = order.constraints[4] - order.constraints[3];
        if (duration == 0) {
            return startPrice;
        }

        uint256 elapsedTime = block.timestamp - order.constraints[3];
        unchecked {
            uint256 portionBps = elapsedTime > duration
                ? PRECISION
                : ((elapsedTime * PRECISION) / duration);
            if (startPrice > endPrice) {
                uint256 priceDiff = ((startPrice - endPrice) * portionBps) /
                    PRECISION;
                return startPrice - priceDiff;
            } else {
                uint256 priceDiff = ((endPrice - startPrice) * portionBps) /
                    PRECISION;
                return startPrice + priceDiff;
            }
        }
    }

    // ======================================================= VIEW FUNCTIONS ============================================================

    /// @notice returns the number of currencies supported by the exchange
    function numCurrencies() external view returns (uint256) {
        return _currencies.length();
    }

    /// @notice returns the currency at the given index
    function getCurrencyAt(uint256 index) external view returns (address) {
        return _currencies.at(index);
    }

    /// @notice returns whether a given currency is valid
    function isValidCurrency(address currency) external view returns (bool) {
        return _currencies.contains(currency);
    }

    // ======================================================= OWNER FUNCTIONS ============================================================

    /// @dev adds a new transaction currency to the exchange
    function addCurrency(address _currency) external onlyOwner {
        _currencies.add(_currency);
        emit CurrencyAdded(_currency);
    }

    /// @dev removes a transaction currency from the exchange
    function removeCurrency(address _currency) external onlyOwner {
        _currencies.remove(_currency);
        emit CurrencyRemoved(_currency);
    }

    /// @dev enables/diables trusted execution
    function setTrustedExecStatus(bool newVal) external onlyOwner {
        bool oldVal = trustedExecEnabled;
        require(oldVal != newVal, "no value change");
        trustedExecEnabled = newVal;
        emit TrustedExecutionChanged(oldVal, newVal);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import { OrderTypes } from "../libs/OrderTypes.sol";

/**
 * @title IFlowComplication
 * @author nneverlander. Twitter @nneverlander
 * @notice Complication interface that must be implemented by all complications (execution strategies)
 */
interface IFlowComplication {
    function canExecMatchOneToOne(
        OrderTypes.MakerOrder calldata makerOrder1,
        OrderTypes.MakerOrder calldata makerOrder2
    ) external view returns (bool, bytes32, bytes32, uint256);

    function canExecMatchOneToMany(
        OrderTypes.MakerOrder calldata makerOrder,
        OrderTypes.MakerOrder[] calldata manyMakerOrders
    ) external view returns (bool, bytes32);

    function canExecMatchOrder(
        OrderTypes.MakerOrder calldata sell,
        OrderTypes.MakerOrder calldata buy,
        OrderTypes.OrderItem[] calldata constructedNfts
    ) external view returns (bool, bytes32, bytes32, uint256);

    function canExecTakeOneOrder(
        OrderTypes.MakerOrder calldata makerOrder
    ) external view returns (bool, bytes32);

    function canExecTakeOrder(
        OrderTypes.MakerOrder calldata makerOrder,
        OrderTypes.OrderItem[] calldata takerItems
    ) external view returns (bool, bytes32);

    function verifyMatchOneToManyOrders(
        bool verifySellOrder,
        OrderTypes.MakerOrder calldata sell,
        OrderTypes.MakerOrder calldata buy
    ) external view returns (bool, bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

uint256 constant FreeMemoryPointerSlot = 0x40;
uint256 constant OneWord = 0x20;
uint256 constant OneWordShift = 0x5;
uint256 constant ThirtyOneBytes = 0x1f;
bytes32 constant EIP2098_allButHighestBitMask = (
    0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
);
uint256 constant ExtraGasBuffer = 0x20;
uint256 constant CostPerWord = 0x3;
uint256 constant MemoryExpansionCoefficientShift = 0x9;

uint256 constant BulkOrder_Typehash_Height_One = (
    0x25f1d312acdce9bb5f11c5585e941709b8456695fe5aacf9998bd3acadfd7fec
);
uint256 constant BulkOrder_Typehash_Height_Two = (
    0xb7870d22600c57d01e7ff46f87ea8741898e43ce73f7d5bfb269c715ea8d4242
);
uint256 constant BulkOrder_Typehash_Height_Three = (
    0xe9ccc656222762d6d2e94ef74311f23818493f907cde851440e6d8773f56c5fe
);
uint256 constant BulkOrder_Typehash_Height_Four = (
    0x14300c4bb2d1850e661a7bb2347e8ac0fa0736fa434a6d0ae1017cb485ce1a7c
);
uint256 constant BulkOrder_Typehash_Height_Five = (
    0xd2a9fdbc6e34ad83660cd4ad49310a663134bbdaea7c34c7c6a95cf9aa8618b1
);
uint256 constant BulkOrder_Typehash_Height_Six = (
    0x4c2c782f8c9daf12d0ec87e76fc496ffeed835292ca7ff04ac92375bbc0f4cc7
);
uint256 constant BulkOrder_Typehash_Height_Seven = (
    0xab5bd2a739337f6f3d8743b51df07f176805bae22da4b25be5d8cdd688498382
);
uint256 constant BulkOrder_Typehash_Height_Eight = (
    0x96596fb6c680230945bae686c1776a9920c438436a98dba61ca767f370b6ef0c
);
uint256 constant BulkOrder_Typehash_Height_Nine = (
    0x40d250b9c55bcc275a49429cae143a873752d755dfa1072e47e10d5252fb8d3b
);
uint256 constant BulkOrder_Typehash_Height_Ten = (
    0xeaf49b43e05b65ffed9bd664ee39555b22fa8ba157aa058f19fc7fee92d386f4
);
uint256 constant BulkOrder_Typehash_Height_Eleven = (
    0x9d5d1c872408322fe8c431a1b66583d09e5dd77e0ac5f99b55131b3fe8363ffb
);
uint256 constant BulkOrder_Typehash_Height_Twelve = (
    0xdb50e721ad63671fc79a925f372d22d69adfe998243b341129c4ef29a20c7a74
);
uint256 constant BulkOrder_Typehash_Height_Thirteen = (
    0x908c5a945faf8d6b1d5aba44fc097fb8c22cca14f60bf75bf680224813809637
);
uint256 constant BulkOrder_Typehash_Height_Fourteen = (
    0x7968127d641eabf208fbdc9d69f10fed718855c94a809679d41b7bcf18104b74
);
uint256 constant BulkOrder_Typehash_Height_Fifteen = (
    0x814b44e912b2ccd234edcf03da0b9d37c459baf9d512034ed96bc93032c37bab
);
uint256 constant BulkOrder_Typehash_Height_Sixteen = (
    0x3a8ceb52e9851a307cf6bd49c73a2ec0d37712e6c4d68c4dcf84df0ad574f59a
);
uint256 constant BulkOrder_Typehash_Height_Seventeen = (
    0xdd2197b5843051f931afa0a534e25a1d824e11ccb5e100c716e9e40406c68b3a
);
uint256 constant BulkOrder_Typehash_Height_Eighteen = (
    0x84b50d02c0d7ec2a815ec27a71290ad861c7cd3addd94f5f7c0736df33fe1827
);
uint256 constant BulkOrder_Typehash_Height_Nineteen = (
    0xdaa31608975cb535532462ce63bbb075b6d81235cd756da2117e745baed067c1
);
uint256 constant BulkOrder_Typehash_Height_Twenty = (
    0x5089f7eef268ce27189a0f19e64dd8210ecadff4be5176a5bd4fd1f176f483a1
);
uint256 constant BulkOrder_Typehash_Height_TwentyOne = (
    0x907e1899005168c54e8279a0e7fc8f890b1de622a79e1ea1447bde837732da56
);
uint256 constant BulkOrder_Typehash_Height_TwentyTwo = (
    0x73ea6321c43a7d88f2d0f797219c7dd3405b1208e89c6d00c6df5c2cc833aa1d
);
uint256 constant BulkOrder_Typehash_Height_TwentyThree = (
    0xb2036d7869c41d1588416aba4ce6e52b45a330fd934c05995b14653db5db9293
);
uint256 constant BulkOrder_Typehash_Height_TwentyFour = (
    0x99e8d8ff7ddc6198258cce0fe5930c7fe7799405517eca81dbf14c1707c163ad
);

// SPDX-License-Identifier: MIT
// solhint-disable no-inline-assembly
pragma solidity 0.8.14;

import { CostPerWord, ExtraGasBuffer, FreeMemoryPointerSlot, MemoryExpansionCoefficientShift, OneWord, OneWordShift, ThirtyOneBytes } from "./Constants.sol";

/**
 * @title LowLevelHelpers
 * @author 0age
 * @notice LowLevelHelpers contains logic for performing various low-level
 *         operations.
 */
contract LowLevelHelpers {
    /**
     * @dev Internal view function to revert and pass along the revert reason if
     *      data was returned by the last call and that the size of that data
     *      does not exceed the currently allocated memory size.
     */
    function _revertWithReasonIfOneIsReturned() internal view {
        assembly {
            // If it returned a message, bubble it up as long as sufficient gas
            // remains to do so:
            if returndatasize() {
                // Ensure that sufficient gas is available to copy returndata
                // while expanding memory where necessary. Start by computing
                // the word size of returndata and allocated memory.
                let returnDataWords := shr(
                    OneWordShift,
                    add(returndatasize(), ThirtyOneBytes)
                )

                // Note: use the free memory pointer in place of msize() to work
                // around a Yul warning that prevents accessing msize directly
                // when the IR pipeline is activated.
                let msizeWords := shr(
                    OneWordShift,
                    mload(FreeMemoryPointerSlot)
                )

                // Next, compute the cost of the returndatacopy.
                let cost := mul(CostPerWord, returnDataWords)

                // Then, compute cost of new memory allocation.
                if gt(returnDataWords, msizeWords) {
                    cost := add(
                        cost,
                        add(
                            mul(sub(returnDataWords, msizeWords), CostPerWord),
                            shr(
                                MemoryExpansionCoefficientShift,
                                sub(
                                    mul(returnDataWords, returnDataWords),
                                    mul(msizeWords, msizeWords)
                                )
                            )
                        )
                    )
                }

                // Finally, add a small constant and compare to gas remaining;
                // bubble up the revert data if enough gas is still available.
                if lt(add(cost, ExtraGasBuffer), gas()) {
                    // Copy returndata to memory; overwrite existing memory.
                    returndatacopy(0, 0, returndatasize())

                    // Revert, specifying memory region with copied returndata.
                    revert(0, returndatasize())
                }
            }
        }
    }

    /**
     * @dev Internal view function to branchlessly select either the caller (if
     *      a supplied recipient is equal to zero) or the supplied recipient (if
     *      that recipient is a nonzero value).
     *
     * @param recipient The supplied recipient.
     *
     * @return updatedRecipient The updated recipient.
     */
    function _substituteCallerForEmptyRecipient(
        address recipient
    ) internal view returns (address updatedRecipient) {
        // Utilize assembly to perform a branchless operation on the recipient.
        assembly {
            // Add caller to recipient if recipient equals 0; otherwise add 0.
            updatedRecipient := add(recipient, mul(iszero(recipient), caller()))
        }
    }

    /**
     * @dev Internal pure function to cast a `bool` value to a `uint256` value.
     *
     * @param b The `bool` value to cast.
     *
     * @return u The `uint256` value.
     */
    function _cast(bool b) internal pure returns (uint256 u) {
        assembly {
            u := b
        }
    }

    /**
     * @dev Internal pure function to compare two addresses without first
     *      masking them. Note that dirty upper bits will cause otherwise equal
     *      addresses to be recognized as unequal.
     *
     * @param a The first address.
     * @param b The second address
     *
     * @return areEqual A boolean representing whether the addresses are equal.
     */
    function _unmaskedAddressComparison(
        address a,
        address b
    ) internal pure returns (bool areEqual) {
        // Utilize assembly to perform the comparison without masking.
        assembly {
            areEqual := eq(a, b)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

/**
 * @title OrderTypes
 * @author nneverlander. Twitter @nneverlander
 * @notice This library contains the order types used by the main exchange and complications
 */
library OrderTypes {
    /// @dev the tokenId and numTokens (==1 for ERC721)
    struct TokenInfo {
        uint256 tokenId;
        uint256 numTokens;
    }

    /// @dev an order item is a collection address and tokens from that collection
    struct OrderItem {
        address collection;
        TokenInfo[] tokens;
    }

    struct MakerOrder {
        ///@dev is order sell or buy
        bool isSellOrder;
        ///@dev signer of the order (maker address)
        address signer;
        ///@dev Constraints array contains the order constraints. Total constraints: 7. In order:
        // numItems - min (for buy orders) / max (for sell orders) number of items in the order
        // start price in wei
        // end price in wei
        // start time in block.timestamp
        // end time in block.timestamp
        // nonce of the order
        // max tx.gasprice in wei that a user is willing to pay for gas
        // 1 for trustedExecution, 0 or non-existent for not trustedExecution
        uint256[] constraints;
        ///@dev nfts array contains order items where each item is a collection and its tokenIds
        OrderItem[] nfts;
        ///@dev address of complication for trade execution (e.g. FlowOrderBookComplication), address of the currency (e.g., WETH)
        address[] execParams;
        ///@dev additional parameters like traits for trait orders, private sale buyer for OTC orders etc
        bytes extraParams;
        ///@dev the order signature uint8 v: parameter (27 or 28), bytes32 r, bytes32 s
        bytes sig;
    }
}

// SPDX-License-Identifier: MIT
// solhint-disable no-inline-assembly
pragma solidity 0.8.14;

import { Address } from "@openzeppelin/contracts/utils/Address.sol";

import { LowLevelHelpers } from "./LowLevelHelpers.sol";

import { IERC1271 } from "@openzeppelin/contracts/interfaces/IERC1271.sol";
import { OrderTypes } from "../libs/OrderTypes.sol";
import { EIP2098_allButHighestBitMask,
    OneWord, 
    OneWordShift, 
    BulkOrder_Typehash_Height_One,
    BulkOrder_Typehash_Height_Two,
    BulkOrder_Typehash_Height_Three,
    BulkOrder_Typehash_Height_Four,
    BulkOrder_Typehash_Height_Five,
    BulkOrder_Typehash_Height_Six,
    BulkOrder_Typehash_Height_Seven,
    BulkOrder_Typehash_Height_Eight,
    BulkOrder_Typehash_Height_Nine,
    BulkOrder_Typehash_Height_Ten,
    BulkOrder_Typehash_Height_Eleven,
    BulkOrder_Typehash_Height_Twelve,
    BulkOrder_Typehash_Height_Thirteen,
    BulkOrder_Typehash_Height_Fourteen,
    BulkOrder_Typehash_Height_Fifteen,
    BulkOrder_Typehash_Height_Sixteen,
    BulkOrder_Typehash_Height_Seventeen,
    BulkOrder_Typehash_Height_Eighteen,
    BulkOrder_Typehash_Height_Nineteen,
    BulkOrder_Typehash_Height_Twenty,
    BulkOrder_Typehash_Height_TwentyOne,
    BulkOrder_Typehash_Height_TwentyTwo,
    BulkOrder_Typehash_Height_TwentyThree,
    BulkOrder_Typehash_Height_TwentyFour } from "./Constants.sol";

/**
 * @title SignatureChecker
 * @notice This library allows verification of signatures for both EOAs and contracts
 */
contract SignatureChecker is LowLevelHelpers {
    /**
     * @dev Revert with an error when a signature that does not contain a v
     *      value of 27 or 28 has been supplied.
     *
     * @param v The invalid v value.
     */
    error BadSignatureV(uint8 v);

    /**
     * @dev Revert with an error when the signer recovered by the supplied
     *      signature does not match the offerer or an allowed EIP-1271 signer
     *      as specified by the offerer in the event they are a contract.
     */
    error InvalidSigner();

    /**
     * @dev Revert with an error when a signer cannot be recovered from the
     *      supplied signature.
     */
    error InvalidSignature();

    /**
     * @dev Revert with an error when an EIP-1271 call to an account fails.
     */
    error BadContractSignature();

    /**
     * @notice Returns whether the signer matches the signed message
     * @param orderHash the hash containing the signed message
     * @param signer the signer address to confirm message validity
     * @param sig the signature
     * @param domainSeparator parameter to prevent signature being executed in other chains and environments
     * @return true --> if valid // false --> if invalid
     */
    function verify(
        bytes32 orderHash,
        address signer,
        bytes calldata sig,
        bytes32 domainSeparator
    ) internal view returns (bool) {
        bytes32 originalDigest = keccak256(
            abi.encodePacked("\x19\x01", domainSeparator, orderHash)
        );
        bytes32 digest;

        bytes memory extractedSignature;
        if (_isValidBulkOrderSize(sig)) {
            (orderHash, extractedSignature) = _computeBulkOrderProof(
                sig,
                orderHash
            );
            digest = keccak256(
                abi.encodePacked("\x19\x01", domainSeparator, orderHash)
            );
        } else {
            digest = originalDigest;
            extractedSignature = sig;
        }

        _assertValidSignature(
            signer,
            digest,
            originalDigest,
            sig,
            extractedSignature
        );

        return true;
    }

    /**
     * @dev Determines whether the specified bulk order size is valid.
     *
     * @param signature The signature of the bulk order to check.
     *
     * @return validLength True if bulk order size is valid, false otherwise.
     */
    function _isValidBulkOrderSize(
        bytes memory signature
    ) internal pure returns (bool validLength) {
        validLength =
            signature.length < 837 &&
            signature.length > 98 &&
            ((signature.length - 67) % 32) < 2;
    }

    /**
     * @dev Computes the bulk order hash for the specified proof and leaf. Note
     *      that if an index that exceeds the number of orders in the bulk order
     *      payload will instead "wrap around" and refer to an earlier index.
     *
     * @param proofAndSignature The proof and signature of the bulk order.
     * @param leaf              The leaf of the bulk order tree.
     *
     * @return bulkOrderHash The bulk order hash.
     * @return signature     The signature of the bulk order.
     */
    function _computeBulkOrderProof(
        bytes memory proofAndSignature,
        bytes32 leaf
    ) internal pure returns (bytes32 bulkOrderHash, bytes memory signature) {
        bytes32 root = leaf;

        // proofAndSignature with odd length is a compact signature (64 bytes).
        uint256 length = proofAndSignature.length % 2 == 0 ? 65 : 64;

        // Create a new array of bytes equal to the length of the signature.
        signature = new bytes(length);

        // Iterate over each byte in the signature.
        for (uint256 i = 0; i < length; ++i) {
            // Assign the byte from the proofAndSignature to the signature.
            signature[i] = proofAndSignature[i];
        }

        // Compute the key by extracting the next three bytes from the
        // proofAndSignature.
        uint256 key = (((uint256(uint8(proofAndSignature[length])) << 16) |
            ((uint256(uint8(proofAndSignature[length + 1]))) << 8)) |
            (uint256(uint8(proofAndSignature[length + 2]))));

        uint256 height = (proofAndSignature.length - length) / 32;

        // Create an array of bytes32 to hold the proof elements.
        bytes32[] memory proofElements = new bytes32[](height);

        // Iterate over each proof element.
        for (uint256 elementIndex = 0; elementIndex < height; ++elementIndex) {
            // Compute the starting index for the current proof element.
            uint256 start = (length + 3) + (elementIndex * 32);

            // Create a new array of bytes to hold the current proof element.
            bytes memory buffer = new bytes(32);

            // Iterate over each byte in the proof element.
            for (uint256 i = 0; i < 32; ++i) {
                // Assign the byte from the proofAndSignature to the buffer.
                buffer[i] = proofAndSignature[start + i];
            }

            // Decode the current proof element from the buffer and assign it to
            // the proofElements array.
            proofElements[elementIndex] = abi.decode(buffer, (bytes32));
        }

        // Iterate over each proof element.
        for (uint256 i = 0; i < proofElements.length; ++i) {
            // Retrieve the proof element.
            bytes32 proofElement = proofElements[i];

            // Check if the current bit of the key is set.
            if ((key >> i) % 2 == 0) {
                // If the current bit is not set, then concatenate the root and
                // the proof element, and compute the keccak256 hash of the
                // concatenation to assign it to the root.
                root = keccak256(abi.encodePacked(root, proofElement));
            } else {
                // If the current bit is set, then concatenate the proof element
                // and the root, and compute the keccak256 hash of the
                // concatenation to assign it to the root.
                root = keccak256(abi.encodePacked(proofElement, root));
            }
        }

        // Compute the bulk order hash and return it.
        bulkOrderHash = keccak256(
            abi.encodePacked(_lookupBulkOrderTypehash(height), root)
        );

        // Return the signature.
        return (bulkOrderHash, signature);
    }



    /**
     * @dev Internal pure function to look up one of twenty-four potential bulk
     *      order typehash constants based on the height of the bulk order tree.
     *      Note that values between one and twenty-four are supported, which is
     *      enforced by _isValidBulkOrderSize.
     *
     * @param _treeHeight The height of the bulk order tree. The value must be
     *                    between one and twenty-four.
     *
     * @return _typeHash The EIP-712 typehash for the bulk order type with the
     *                   given height.
     */
    function _lookupBulkOrderTypehash(uint256 _treeHeight)
        internal
        pure
        returns (bytes32 _typeHash)
    {
        // Utilize assembly to efficiently retrieve correct bulk order typehash.
        assembly {
            // Use a Yul function to enable use of the `leave` keyword
            // to stop searching once the appropriate type hash is found.
            function lookupTypeHash(treeHeight) -> typeHash {
                // Handle tree heights one through eight.
                if lt(treeHeight, 9) {
                    // Handle tree heights one through four.
                    if lt(treeHeight, 5) {
                        // Handle tree heights one and two.
                        if lt(treeHeight, 3) {
                            // Utilize branchless logic to determine typehash.
                            typeHash := ternary(
                                eq(treeHeight, 1),
                                BulkOrder_Typehash_Height_One,
                                BulkOrder_Typehash_Height_Two
                            )

                            // Exit the function once typehash has been located.
                            leave
                        }

                        // Handle height three and four via branchless logic.
                        typeHash := ternary(
                            eq(treeHeight, 3),
                            BulkOrder_Typehash_Height_Three,
                            BulkOrder_Typehash_Height_Four
                        )

                        // Exit the function once typehash has been located.
                        leave
                    }

                    // Handle tree height five and six.
                    if lt(treeHeight, 7) {
                        // Utilize branchless logic to determine typehash.
                        typeHash := ternary(
                            eq(treeHeight, 5),
                            BulkOrder_Typehash_Height_Five,
                            BulkOrder_Typehash_Height_Six
                        )

                        // Exit the function once typehash has been located.
                        leave
                    }

                    // Handle height seven and eight via branchless logic.
                    typeHash := ternary(
                        eq(treeHeight, 7),
                        BulkOrder_Typehash_Height_Seven,
                        BulkOrder_Typehash_Height_Eight
                    )

                    // Exit the function once typehash has been located.
                    leave
                }

                // Handle tree height nine through sixteen.
                if lt(treeHeight, 17) {
                    // Handle tree height nine through twelve.
                    if lt(treeHeight, 13) {
                        // Handle tree height nine and ten.
                        if lt(treeHeight, 11) {
                            // Utilize branchless logic to determine typehash.
                            typeHash := ternary(
                                eq(treeHeight, 9),
                                BulkOrder_Typehash_Height_Nine,
                                BulkOrder_Typehash_Height_Ten
                            )

                            // Exit the function once typehash has been located.
                            leave
                        }

                        // Handle height eleven and twelve via branchless logic.
                        typeHash := ternary(
                            eq(treeHeight, 11),
                            BulkOrder_Typehash_Height_Eleven,
                            BulkOrder_Typehash_Height_Twelve
                        )

                        // Exit the function once typehash has been located.
                        leave
                    }

                    // Handle tree height thirteen and fourteen.
                    if lt(treeHeight, 15) {
                        // Utilize branchless logic to determine typehash.
                        typeHash := ternary(
                            eq(treeHeight, 13),
                            BulkOrder_Typehash_Height_Thirteen,
                            BulkOrder_Typehash_Height_Fourteen
                        )

                        // Exit the function once typehash has been located.
                        leave
                    }
                    // Handle height fifteen and sixteen via branchless logic.
                    typeHash := ternary(
                        eq(treeHeight, 15),
                        BulkOrder_Typehash_Height_Fifteen,
                        BulkOrder_Typehash_Height_Sixteen
                    )

                    // Exit the function once typehash has been located.
                    leave
                }

                // Handle tree height seventeen through twenty.
                if lt(treeHeight, 21) {
                    // Handle tree height seventeen and eighteen.
                    if lt(treeHeight, 19) {
                        // Utilize branchless logic to determine typehash.
                        typeHash := ternary(
                            eq(treeHeight, 17),
                            BulkOrder_Typehash_Height_Seventeen,
                            BulkOrder_Typehash_Height_Eighteen
                        )

                        // Exit the function once typehash has been located.
                        leave
                    }

                    // Handle height nineteen and twenty via branchless logic.
                    typeHash := ternary(
                        eq(treeHeight, 19),
                        BulkOrder_Typehash_Height_Nineteen,
                        BulkOrder_Typehash_Height_Twenty
                    )

                    // Exit the function once typehash has been located.
                    leave
                }

                // Handle tree height twenty-one and twenty-two.
                if lt(treeHeight, 23) {
                    // Utilize branchless logic to determine typehash.
                    typeHash := ternary(
                        eq(treeHeight, 21),
                        BulkOrder_Typehash_Height_TwentyOne,
                        BulkOrder_Typehash_Height_TwentyTwo
                    )

                    // Exit the function once typehash has been located.
                    leave
                }

                // Handle height twenty-three & twenty-four w/ branchless logic.
                typeHash := ternary(
                    eq(treeHeight, 23),
                    BulkOrder_Typehash_Height_TwentyThree,
                    BulkOrder_Typehash_Height_TwentyFour
                )

                // Exit the function once typehash has been located.
                leave
            }

            // Implement ternary conditional using branchless logic.
            function ternary(cond, ifTrue, ifFalse) -> c {
                c := xor(ifFalse, mul(cond, xor(ifFalse, ifTrue)))
            }

            // Look up the typehash using the supplied tree height.
            _typeHash := lookupTypeHash(_treeHeight)
        }
    }

    /**
     * @dev Internal view function to verify the signature of an order. An
     *      ERC-1271 fallback will be attempted if either the signature length
     *      is not 64 or 65 bytes or if the recovered signer does not match the
     *      supplied signer. Note that in cases where a 64 or 65 byte signature
     *      is supplied, only standard ECDSA signatures that recover to a
     *      non-zero address are supported.
     *
     * @param signer            The signer for the order.
     * @param digest            The digest to verify signature against.
     * @param originalDigest    The original digest to verify signature against.
     * @param originalSignature The original signature.
     * @param signature         A signature from the signer indicating that the
     *                          order has been approved.
     */
    function _assertValidSignature(
        address signer,
        bytes32 digest,
        bytes32 originalDigest,
        bytes memory originalSignature,
        bytes memory signature
    ) internal view {
        if (signer.code.length > 0) {
            // If signer is a contract, try verification via EIP-1271.
            if (
                IERC1271(signer).isValidSignature(
                    originalDigest,
                    originalSignature
                ) != 0x1626ba7e
            ) {
                revert BadContractSignature();
            }

            // Return early if the ERC-1271 signature check succeeded.
            return;
        } else {
            _assertValidSignatureHelper(signer, digest, signature);
        }
    }

    function _assertValidSignatureHelper(
        address signer,
        bytes32 digest,
        bytes memory signature
    ) internal pure {
        // Declare r, s, and v signature parameters.
        bytes32 r;
        bytes32 s;
        uint8 v;

        if (signature.length == 64) {
            // If signature contains 64 bytes, parse as EIP-2098 sig. (r+s&v)
            // Declare temporary vs that will be decomposed into s and v.
            bytes32 vs;

            // Decode signature into r, vs.
            (r, vs) = abi.decode(signature, (bytes32, bytes32));

            // Decompose vs into s and v.
            s = vs & EIP2098_allButHighestBitMask;

            // If the highest bit is set, v = 28, otherwise v = 27.
            v = uint8(uint256(vs >> 255)) + 27;
        } else if (signature.length == 65) {
            (r, s) = abi.decode(signature, (bytes32, bytes32));
            v = uint8(signature[64]);

            // Ensure v value is properly formatted.
            if (v != 27 && v != 28) {
                revert BadSignatureV(v);
            }
        } else {
            revert InvalidSignature();
        }

        // Attempt to recover signer using the digest and signature parameters.
        address recoveredSigner = ecrecover(digest, v, r, s);

        // Disallow invalid signers.
        if (recoveredSigner == address(0) || recoveredSigner != signer) {
            revert InvalidSigner();
        }
    }
}