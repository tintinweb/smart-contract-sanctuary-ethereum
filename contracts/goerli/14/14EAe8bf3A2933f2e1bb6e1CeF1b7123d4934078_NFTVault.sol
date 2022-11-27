/**
 *Submitted for verification at Etherscan.io on 2022-11-27
*/

// Sources flattened with hardhat v2.12.1 https://hardhat.org

// File contracts/clink/IERC20BurnMintable.sol

// : MIT
pragma solidity ^0.8.4;

interface IERC20BurnMintable  {
    function mint(address to, uint256 amount) external;

    function burn(uint256 amount) external;

    function burnFrom(address account, uint256 amount) external;
}


// File contracts/nft-collateral/interfaces/IPriceHelper.sol

// : MIT
pragma solidity ^0.8.4;

interface IPriceHelper {
    function getNFTValueUSD(address _nftContract, uint256 _tokenId) external view returns (uint256);

    function isOpen(address _nftContract, uint256 _tokenId) external view returns (bool);
}


// File contracts/nft-collateral/interfaces/IUniV3Swapper.sol

// : MIT
pragma solidity ^0.8.0;

interface IUniV3Swapper {
    function swap(
        address nft,
        uint256 tokenId,
        uint256 debtAmount
    ) external returns (uint256 extraAmount);
}


// File contracts/nft-collateral/interfaces/IInitialization.sol

// : MIT
pragma solidity ^0.8.0;

interface IInitialization {
    /// @notice Init function that gets called from `BoringFactory.deploy`.
    /// Also kown as the constructor for cloned contracts.
    /// Any ETH send to `BoringFactory.deploy` ends up here.
    /// @param data Can be abi encoded arguments or anything else.
    function init(bytes calldata data) external payable;
}


// File @openzeppelin/contracts/utils/[email protected]

// : MIT
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

// : MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
}


// File @openzeppelin/contracts/security/[email protected]

// : MIT
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
abstract contract ReentrancyGuard {
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

    constructor() {
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
}


// File @openzeppelin/contracts/utils/[email protected]

// : MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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


// File @openzeppelin/contracts/utils/[email protected]

// : MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Multicall.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides a function to batch together multiple calls in a single external call.
 *
 * _Available since v4.1._
 */
abstract contract Multicall {
    /**
     * @dev Receives and executes a batch of function calls on this contract.
     */
    function multicall(bytes[] calldata data) external virtual returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            results[i] = Address.functionDelegateCall(address(this), data[i]);
        }
        return results;
    }
}


// File @openzeppelin/contracts/utils/introspection/[email protected]

// : MIT
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
interface IERC165 {
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


// File @openzeppelin/contracts/token/ERC721/[email protected]

// : MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
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

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}


// File @openzeppelin/contracts/utils/structs/[email protected]

// : MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

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
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
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

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}


// File @openzeppelin/contracts/token/ERC20/[email protected]

// : MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}


// File @openzeppelin/contracts/token/ERC20/extensions/[email protected]

// : MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}


// File @openzeppelin/contracts/token/ERC20/utils/[email protected]

// : MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

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

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
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


// File contracts/nft-collateral/NFTVault.sol

// : MIT
pragma solidity ^0.8.4;
/// @title NFT lending vault
/// @notice This contracts allows users to borrow CLK using NFTs as collateral.
contract NFTVault is Ownable, ReentrancyGuard, IInitialization, Multicall {
    using SafeERC20 for IERC20;
    using SafeERC20 for IERC20Permit;
    using EnumerableSet for EnumerableSet.UintSet;

    event PositionOpened(address indexed owner, uint256 indexed index);
    event Borrowed(address indexed owner, uint256 indexed index, uint256 amount);
    event Repaid(address indexed owner, uint256 indexed index, uint256 amount);
    event PositionClosed(address indexed owner, uint256 indexed index);
    event Liquidated(address indexed liquidator, address indexed owner, uint256 indexed index);
    event LogFeeTo(address indexed newFeeTo);

    struct Position {
        uint256 debtPrincipal;
        uint256 debtPortion; //
    }

    struct Rate {
        uint128 numerator;
        uint128 denominator;
    }

    struct VaultSettings {
        Rate debtInterestApr;
        Rate creditLimitRate;
        Rate liquidationLimitRate;
        Rate organizationFeeRate;
    }

    address public immutable clink;
    NFTVault public immutable masterContract;

    // MasterContract variables
    address public feeTo;

    IERC721 public nftContract;
    IPriceHelper public priceHelper;

    /// @notice Total outstanding debt
    uint256 public totalDebtAmount;
    /// @dev Last time debt was accrued. See {accrue} for more info
    uint256 public totalDebtAccruedAt;
    uint256 public totalFeeCollected;
    uint256 public totalDebtPortion;

    VaultSettings public settings;

    /// @dev Keeps track of all the NFTs used as collateral for positions
    EnumerableSet.UintSet private positionIndexes;

    mapping(uint256 => Position) private positions;
    mapping(uint256 => address) public positionOwner;

    /// @dev Checks if the provided NFT index is valid
    /// @param nftIndex The index to check
    modifier validNFTIndex(uint256 nftIndex) {
        //The standard OZ ERC721 implementation of ownerOf reverts on a non existing nft isntead of returning address(0)
        require(nftContract.ownerOf(nftIndex) != address(0), "invalid_nft");
        _;
    }

    constructor(address _clink, address _owner) {
        clink = _clink;
        masterContract = this;
        transferOwnership(_owner);
    }

    /// @notice Serves as the constructor for clones, as clones can't have a regular constructor
    /// @dev `data` is abi encoded in the format
    function init(bytes calldata data) public payable override {
        require(address(nftContract) == address(0), "NFTVault: already initialized");

        (VaultSettings memory _settings, IERC721 _nftContract, IPriceHelper _priceHelper) = abi.decode(
            data,
            (VaultSettings, IERC721, IPriceHelper)
        );

        _validateRate(_settings.debtInterestApr);
        _validateRate(_settings.creditLimitRate);
        _validateRate(_settings.liquidationLimitRate);
        _validateRate(_settings.organizationFeeRate);

        require(_greaterThan(_settings.liquidationLimitRate, _settings.creditLimitRate), "invalid_liquidation_limit");

        nftContract = _nftContract;
        priceHelper = _priceHelper;
        settings = _settings;
        require(address(nftContract) != address(0), "NFTVault: bad pair");
    }

    /// @dev The {accrue} function updates the contract's state by calculating
    /// the additional interest accrued since the last state update
    function accrue() public {
        uint256 additionalInterest = _calculateAdditionalInterest();

        totalDebtAccruedAt = block.timestamp;

        totalDebtAmount += additionalInterest;
        totalFeeCollected += additionalInterest;
    }

    /// @dev Checks if `r1` is greater than `r2`.
    function _greaterThan(Rate memory _r1, Rate memory _r2) internal pure returns (bool) {
        return _r1.numerator * _r2.denominator > _r2.numerator * _r1.denominator;
    }

    /// @dev Validates a rate. The denominator must be greater than zero and greater than or equal to the numerator.
    /// @param rate The rate to validate
    function _validateRate(Rate memory rate) internal pure {
        require(rate.denominator != 0 && rate.denominator >= rate.numerator, "invalid_rate");
    }

    struct NFTInfo {
        uint256 index;
        address owner;
        uint256 nftValueUSD;
    }

    /// @notice Returns data relative to the NFT at index `_tokenId`
    /// @param _tokenId The NFT index
    /// @return nftInfo The data relative to the NFT
    function getNFTInfo(uint256 _tokenId) external view returns (NFTInfo memory nftInfo) {
        nftInfo = NFTInfo(_tokenId, nftContract.ownerOf(_tokenId), _getNFTValueUSD(_tokenId));
    }

    /// @dev Returns the credit limit of an NFT
    /// @param _tokenId The NFT to return credit limit of
    /// @return The NFT credit limit
    function _getCreditLimit(uint256 _tokenId) internal view returns (uint256) {
        uint256 value = _getNFTValueUSD(_tokenId);
        return (value * settings.creditLimitRate.numerator) / settings.creditLimitRate.denominator;
    }

    /// @dev Returns the minimum amount of debt necessary to liquidate an NFT
    /// @param _tokenId The index of the NFT
    /// @return The minimum amount of debt to liquidate the NFT
    function _getLiquidationLimit(uint256 _tokenId) internal view returns (uint256) {
        uint256 value = _getNFTValueUSD(_tokenId);
        return (value * settings.liquidationLimitRate.numerator) / settings.liquidationLimitRate.denominator;
    }

    /// @dev Calculates current outstanding debt of an NFT
    /// @param _tokenId The NFT to calculate the outstanding debt of
    /// @return The outstanding debt value
    function _getDebtAmount(uint256 _tokenId) internal view returns (uint256) {
        uint256 calculatedDebt = _calculateDebt(totalDebtAmount, positions[_tokenId].debtPortion, totalDebtPortion);

        uint256 principal = positions[_tokenId].debtPrincipal;

        //_calculateDebt is prone to rounding errors that may cause
        //the calculated debt amount to be 1 or 2 units less than
        //the debt principal when the accrue() function isn't called
        //in between the first borrow and the _calculateDebt call.
        return principal > calculatedDebt ? principal : calculatedDebt;
    }

    /// @dev Calculates the total debt of a position given the global debt, the user's portion of the debt and the total user portions
    /// @param total The global outstanding debt
    /// @param userPortion The user's portion of debt
    /// @param totalPortion The total user portions of debt
    /// @return The outstanding debt of the position
    function _calculateDebt(
        uint256 total,
        uint256 userPortion,
        uint256 totalPortion
    ) internal pure returns (uint256) {
        return totalPortion == 0 ? 0 : (total * userPortion) / totalPortion;
    }

    /// @dev Opens a position
    /// Emits a {PositionOpened} event
    /// @param _owner The owner of the position to open
    /// @param _tokenId The NFT used as collateral for the position
    function _openPosition(address _owner, uint256 _tokenId) internal {
        positionOwner[_tokenId] = _owner;
        positionIndexes.add(_tokenId);

        nftContract.transferFrom(_owner, address(this), _tokenId);

        emit PositionOpened(_owner, _tokenId);
    }

    /// @dev Calculates the additional global interest since last time the contract's state was updated by calling {accrue}
    /// @return The additional interest value
    function _calculateAdditionalInterest() internal view returns (uint256) {
        // Number of seconds since {accrue} was called
        uint256 elapsedTime = block.timestamp - totalDebtAccruedAt;
        if (elapsedTime == 0) {
            return 0;
        }

        uint256 totalDebt = totalDebtAmount;
        if (totalDebt == 0) {
            return 0;
        }

        // Accrue interest
        return
            (elapsedTime * totalDebt * settings.debtInterestApr.numerator) /
            settings.debtInterestApr.denominator /
            365 days;
    }

    /// @notice Returns the number of open positions
    /// @return The number of open positions
    function totalPositions() external view returns (uint256) {
        return positionIndexes.length();
    }

    /// @notice Returns all open position NFT indexes
    /// @return The open position NFT indexes
    function openPositionsIndexes() external view returns (uint256[] memory) {
        return positionIndexes.values();
    }

    function _getNFTValueUSD(uint256 _tokenId) public view returns (uint256) {
        return priceHelper.getNFTValueUSD(address(nftContract), _tokenId);
    }

    struct PositionPreview {
        address owner;
        uint256 nftIndex;
        uint256 nftValueUSD;
        VaultSettings vaultSettings;
        uint256 creditLimit;
        uint256 debtPrincipal;
        uint256 debtPortion;
        uint256 debtInterest;
        bool liquidatable;
    }

    /// @notice Returns data relative to a postition, existing or not
    /// @param _tokenId The index of the NFT used as collateral for the position
    /// @return preview See assignment below
    function showPosition(uint256 _tokenId)
        external
        view
        validNFTIndex(_tokenId)
        returns (PositionPreview memory preview)
    {
        address posOwner = positionOwner[_tokenId];

        Position storage position = positions[_tokenId];
        uint256 debtPrincipal = position.debtPrincipal;
        //calculate updated debt
        uint256 debtAmount = _calculateDebt(
            totalDebtAmount + _calculateAdditionalInterest(),
            position.debtPortion,
            totalDebtPortion
        );

        //_calculateDebt is prone to rounding errors that may cause
        //the calculated debt amount to be 1 or 2 units less than
        //the debt principal if no time has elapsed in between the first borrow
        //and the _calculateDebt call.
        if (debtPrincipal > debtAmount) debtAmount = debtPrincipal;

        unchecked {
            preview = PositionPreview({
                owner: posOwner, //the owner of the position, `address(0)` if the position doesn't exists
                nftIndex: _tokenId, //the NFT used as collateral for the position
                nftValueUSD: _getNFTValueUSD(_tokenId), //the value in USD of the NFT
                vaultSettings: settings, //the current vault's settings
                creditLimit: _getCreditLimit(_tokenId), //the NFT's credit limit
                debtPrincipal: debtPrincipal, //the debt principal for the position, `0` if the position doesn't exists
                debtPortion: position.debtPortion,
                debtInterest: debtAmount - debtPrincipal, //the interest of the position
                liquidatable: debtAmount >= _getLiquidationLimit(_tokenId) //if the position can be liquidated
            });
        }
    }

    /// @notice Allows users to open positions and borrow using an NFT
    /// @dev emits a {Borrowed} event
    /// @param _tokenId The index of the NFT to be used as collateral
    /// @param _amount The amount of PUSD to be borrowed. Note that the user will receive less than the amount requested,
    /// the borrow fee automatically get removed from the amount borrowed
    function borrow(uint256 _tokenId, uint256 _amount) external validNFTIndex(_tokenId) nonReentrant {
        accrue();

        require(msg.sender == positionOwner[_tokenId] || address(0) == positionOwner[_tokenId], "unauthorized");
        require(_amount != 0, "invalid_amount");

        Position storage position = positions[_tokenId];

        uint256 creditLimit = _getCreditLimit(_tokenId);
        uint256 debtAmount = _getDebtAmount(_tokenId);
        require(debtAmount + _amount <= creditLimit, "insufficient_credit");

        //calculate the borrow fee
        uint256 organizationFee = (_amount * settings.organizationFeeRate.numerator) /
            settings.organizationFeeRate.denominator;

        uint256 feeAmount = organizationFee;
        totalFeeCollected += feeAmount;

        uint256 debtPortion = totalDebtPortion;
        // update debt portion
        if (debtPortion == 0) {
            totalDebtPortion = _amount;
            position.debtPortion = _amount;
        } else {
            //debtPortion =100,totalDebtAmount=200,_amount=100,
            //plusPortion = (100 * 100) / 200 = 50
            // plusPortion :debtPortion = _amount:totalDebtAmount = 1/2
            uint256 plusPortion = (debtPortion * _amount) / totalDebtAmount;
            totalDebtPortion = debtPortion + plusPortion;
            position.debtPortion += plusPortion;
        }
        position.debtPrincipal += _amount;
        totalDebtAmount += _amount;

        if (positionOwner[_tokenId] == address(0)) {
            _openPosition(msg.sender, _tokenId);
        }

        IERC20BurnMintable(clink).mint(msg.sender, _amount - feeAmount);

        emit Borrowed(msg.sender, _tokenId, _amount);
    }

    /// @notice Allows users to repay a portion/all of their debt. Note that since interest increases every second,
    /// a user wanting to repay all of their debt should repay for an amount greater than their current debt to account for the
    /// additional interest while the repay transaction is pending, the contract will only take what's necessary to repay all the debt
    /// @dev Emits a {Repaid} event
    /// @param _tokenId The NFT used as collateral for the position
    /// @param _amount The amount of debt to repay. If greater than the position's outstanding debt, only the amount necessary to repay all the debt will be taken
    function repay(uint256 _tokenId, uint256 _amount) external validNFTIndex(_tokenId) nonReentrant {
        accrue();

        require(msg.sender == positionOwner[_tokenId], "unauthorized");
        require(_amount != 0, "invalid_amount");

        Position storage position = positions[_tokenId];

        uint256 debtAmount = _getDebtAmount(_tokenId);
        require(debtAmount != 0, "position_not_borrowed");

        uint256 debtPrincipal = position.debtPrincipal;
        uint256 debtInterest = debtAmount - debtPrincipal;
        _amount = _amount > debtAmount ? debtAmount : _amount;
        uint256 paidPrincipal;
        unchecked {
            paidPrincipal = _amount > debtInterest ? _amount - debtInterest : 0;
        }

        IERC20(clink).safeTransferFrom(msg.sender, address(this), _amount);

        // burn only paidPrincipal, the interest will be collected
        if (paidPrincipal > 0) {
            IERC20BurnMintable(clink).burn(paidPrincipal);
        }

        uint256 totalPortion = totalDebtPortion;
        uint256 totalDebt = totalDebtAmount;
        uint256 minusPortion = paidPrincipal == debtPrincipal
            ? position.debtPortion
            : (totalPortion * _amount) / totalDebt;

        totalDebtPortion = totalPortion - minusPortion;
        position.debtPortion -= minusPortion;
        position.debtPrincipal -= paidPrincipal;
        totalDebtAmount = totalDebt - _amount;

        emit Repaid(msg.sender, _tokenId, _amount);
    }

    /// @notice Allows a user to close a position and get their collateral back, if the position's outstanding debt is 0
    /// @dev Emits a {PositionClosed} event
    /// @param _tokenId The index of the NFT used as collateral
    function closePosition(uint256 _tokenId) external validNFTIndex(_tokenId) nonReentrant {
        accrue();

        require(msg.sender == positionOwner[_tokenId], "unauthorized");
        require(_getDebtAmount(_tokenId) == 0, "position_not_repaid");

        positionOwner[_tokenId] = address(0);
        delete positions[_tokenId];
        positionIndexes.remove(_tokenId);

        // transfer nft back to owner if nft was deposited
        if (nftContract.ownerOf(_tokenId) == address(this)) {
            nftContract.safeTransferFrom(address(this), msg.sender, _tokenId);
        }

        emit PositionClosed(msg.sender, _tokenId);
    }

    /// @notice Positions can only be liquidated
    /// once their debt amount exceeds the minimum liquidation debt to collateral value rate.
    /// In order to liquidate a position, the liquidator needs to repay the user's outstanding debt.
    /// If the position is not insured, it's closed immediately and the collateral is sent to `_recipient`.
    /// If the position is insured, the position remains open (interest doesn't increase) and the owner of the position has a certain amount of time
    /// (`insuranceRepurchaseTimeLimit`) to fully repay the liquidator and pay an additional liquidation fee (`insuranceLiquidationPenaltyRate`), if this
    /// is done in time the user gets back their collateral and their position is automatically closed. If the user doesn't repurchase their collateral
    /// before the time limit passes, the liquidator can claim the liquidated NFT and the position is closed
    /// @dev Emits a {Liquidated} event
    /// @param _tokenId The NFT to liquidate
    /// @param swapper The address to send the NFT to swap for CLK
    function liquidate(
        uint256 _tokenId,
        IUniV3Swapper swapper,
        address receiver
    ) external validNFTIndex(_tokenId) nonReentrant {
        accrue();

        address posOwner = positionOwner[_tokenId];
        require(posOwner != address(0), "position_not_exist");

        Position storage position = positions[_tokenId];

        uint256 debtAmount = _getDebtAmount(_tokenId);
        require(debtAmount >= _getLiquidationLimit(_tokenId), "position_not_liquidatable");

        // transfer nft to swapper
        uint256 before = IERC20(clink).balanceOf(address(this));

        nftContract.transferFrom(address(this), address(swapper), _tokenId);
        swapper.swap(address(nftContract), _tokenId, debtAmount);
        uint256 _after = IERC20(clink).balanceOf(address(this));
        require(_after >= before + debtAmount, "no enough");
        // burn all debtPrincipal
        // the interest fee (debtAmount - debtPrincipal) will be collected
        if (position.debtPrincipal > 0) {
            IERC20BurnMintable(clink).burn(position.debtPrincipal);
        }
        if (_after > before + debtAmount) {
            IERC20(clink).transfer(receiver, _after - before - debtAmount);
        }

        // update debt portion
        totalDebtPortion -= position.debtPortion;
        totalDebtAmount -= debtAmount;
        position.debtPortion = 0;

        positionOwner[_tokenId] = address(0);
        delete positions[_tokenId];
        positionIndexes.remove(_tokenId);
        emit Liquidated(msg.sender, posOwner, _tokenId);
    }

    function getDebtAmount(uint256 _tokenId) public view returns (uint256) {
        return _getDebtAmount(_tokenId);
    }

    function liquidatable(uint256 _tokenId) public view returns (bool) {
        return _getDebtAmount(_tokenId) >= _getLiquidationLimit(_tokenId);
    }

    function collect() external nonReentrant {
        address _feeTo = masterContract.feeTo();
        require(_feeTo != address(0), "addr err");
        accrue();
        IERC20(clink).transfer(_feeTo, IERC20(clink).balanceOf(address(this)));
        totalFeeCollected = 0;
    }

    /// @notice Sets the beneficiary of interest accrued.
    /// MasterContract Only Admin function.
    /// @param newFeeTo The address of the receiver.
    function setFeeTo(address newFeeTo) public onlyOwner {
        feeTo = newFeeTo;
        emit LogFeeTo(newFeeTo);
    }

    function approveClick(
        address owner_,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        IERC20Permit(clink).safePermit(owner_, spender, value, deadline, v, r, s);
    }

    function tokenIds(uint256 start, uint256 limit) public view returns (uint256[] memory ids) {
        uint256 length = positionIndexes.length();
        if (start >= length) {
            return ids;
        }
        if (length > start + limit) {
            limit = length - start;
        }
        ids = new uint256[](limit);
        for (uint256 i = 0; i < limit; i++) {
            ids[i] = positionIndexes.at(i + start);
        }
    }
}