/**
 *Submitted for verification at Etherscan.io on 2022-09-29
*/

pragma solidity ^0.6.8;
library EnumerableUintSet {
    struct Set {
        bytes32[] _values;
        uint256[] _collection;
        mapping (bytes32 => uint256) _indexes;
    }
    function _add(Set storage set, bytes32 value, uint256 savedValue) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            set._collection.push(savedValue);
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        uint256 valueIndex = set._indexes[value];
        if (valueIndex != 0) { // Equivalent to contains(set, value)
            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;
            bytes32 lastValue = set._values[lastIndex];
            set._values[toDeleteIndex] = lastValue;
            set._values.pop();

            uint256 lastvalueAddress = set._collection[lastIndex];
            set._collection[toDeleteIndex] = lastvalueAddress;
            set._collection.pop();

            set._indexes[lastValue] = toDeleteIndex + 1; // All indexes are 1-based
            delete set._indexes[value];
            return true;
        } else {
            return false;
        }
    }
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }
    function _collection(Set storage set) private view returns (uint256[] memory) {
        return set._collection;    
    }

    function _at(Set storage set, uint256 index) private view returns (uint256) {
        require(set._collection.length > index, "EnumerableSet: index out of bounds");
        return set._collection[index];
    }
    struct UintSet {
        Set _inner;
    }
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(value)), value);
    }
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)));
    }
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(value)));
    }
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }
    function collection(UintSet storage set) internal view returns (uint256[] memory) {
        return _collection(set._inner);
    }
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return _at(set._inner, index);
    }
}
pragma solidity ^0.6.8;
library EnumerableSet {
    struct Set {
        bytes32[] _values;
        address[] _collection;
        mapping (bytes32 => uint256) _indexes;
    }
    function _add(Set storage set, bytes32 value, address addressValue) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            set._collection.push(addressValue);
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        uint256 valueIndex = set._indexes[value];
        if (valueIndex != 0) { // Equivalent to contains(set, value)
            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;
            bytes32 lastValue = set._values[lastIndex];
            set._values[toDeleteIndex] = lastValue;
            set._values.pop();

            address lastvalueAddress = set._collection[lastIndex];
            set._collection[toDeleteIndex] = lastvalueAddress;
            set._collection.pop();

            set._indexes[lastValue] = toDeleteIndex + 1; // All indexes are 1-based
            delete set._indexes[value];
//            for(uint256 i = 0; i < set._collection.length; i++) {
//                if (set._collection[i] == addressValue) {
//                    _removeIndexArray(i, set._collection);
//                    break;
//                }
//            }
            return true;
        } else {
            return false;
        }
    }
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }
    function _collection(Set storage set) private view returns (address[] memory) {
        return set._collection;    
    }
//    function _removeIndexArray(uint256 index, address[] storage array) internal virtual {
//        for(uint256 i = index; i < array.length-1; i++) {
//            array[i] = array[i+1];
//        }
//        array.pop();
//    }
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }
    struct AddressSet {
        Set _inner;
    }
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(value)), value);
    }
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)));
    }
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(value)));
    }
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }
    function collection(AddressSet storage set) internal view returns (address[] memory) {
        return _collection(set._inner);
    }
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint256(_at(set._inner, index)));
    }
}
pragma solidity ^0.6.8;
library SafeMath {
     function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

pragma solidity >=0.6.0 <0.8.0;

/**
 * @title BEP721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from BEP721 asset contracts.
 */
interface IBEP721Receiver {
    /**
     * @dev Whenever an {IBEP721} `tokenId` token is transferred to this contract via {IBEP721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IBEP721.onBEP721Received.selector`.
     */
    function onBEP721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

pragma solidity ^0.6.8;
interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function decimals() external view returns (uint8);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
pragma solidity ^0.6.8;

/**
 * @dev Interface of the BEP165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({BEP165Checker}).
 *
 * For an implementation, see {BEP165}.
 */
interface IBEP165 {
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


pragma solidity ^0.6.8;

/**
 * @dev Required interface of an BEP721 compliant contract.
 */
interface IBEP721 is IBEP165 {
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
     * are aware of the BEP721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IBEP721Receiver-onBEP721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
      * - If `to` refers to a smart contract, it must implement {IBEP721Receiver-onBEP721Received}, which is called upon a safe transfer.
      *
      * Emits a {Transfer} event.
      */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

pragma solidity >=0.6.0 <0.8.0;
/**
 * _Available since v3.1._
 */
interface IBEP1155Receiver is IBEP165 {

    /**
        @dev Handles the receipt of a single BEP1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onBEP1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onBEP1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onBEP1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    )
        external
        returns(bytes4);

    /**
        @dev Handles the receipt of a multiple BEP1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onBEP1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onBEP1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onBEP1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    )
        external
        returns(bytes4);
}

pragma solidity >=0.6.2 <0.8.0;
/**
 * @dev Required interface of an BEP1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IBEP1155 is IBEP165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

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
     * returned by {IBEP1155MetadataURI-uri}.
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
     * @dev xref:ROOT:BEP1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);

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
     * - If `to` refers to a smart contract, it must implement {IBEP1155Receiver-onBEP1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

    /**
     * @dev xref:ROOT:BEP1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IBEP1155Receiver-onBEP1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
}

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

pragma solidity ^0.6.8;

// SPDX-License-Identifier: UNLICENSED

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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

library SafeBEP20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IBEP20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IBEP20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IBEP20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeBEP20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IBEP20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IBEP20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeBEP20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IBEP20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeBEP20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeBEP20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeBEP20: BEP20 operation did not succeed");
        }
    }
}

interface POMNFT {
	function mint(string memory tokenUri, uint256 royalties) external returns(uint256);
	function getNFTData(uint _tokenId) external view returns (address,uint256);
}

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

contract POMAuction is IBEP721Receiver,IBEP1155Receiver,Ownable {
	 using SafeBEP20 for IBEP20;
	 
	uint256 private _weiDecimal = 18;
	uint256 private _divRate = 10000;
	
	bool private withMint = false;
	
	address private _WBNB;
	
    uint256 public platform_fee = 150; //1.5%
    address public feeReceiver;
	
    using SafeMath for uint256;
	
    using EnumerableUintSet for EnumerableUintSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;

    struct Auction {
        address tokenAddress;
        address seller;
        address latestBidder;
        uint256 latestBidTime;
        uint256 deadline;
        uint256 price;
        uint256 amountReceive;
        uint256 bidCount;
        uint256 latestBidPrice;
    }
	
	struct SendTransaction {
        uint256 balanceBeforeSend;
        uint256 balanceAfterSend;
        uint256 amountReceive;
        uint256 sellerAmount;
        uint256 platformFeeAmount;
        uint256 royaltiesFeeAmount;
        uint256 royaltiesFee;
        address royaltiesFeeAddress;
    }

    mapping(uint256 => Auction) private _contractsPlusTokenIdsAuction;
    mapping(address => EnumerableUintSet.UintSet) private _contractsTokenIdsList;
    mapping(address => uint256) private _consumersDealFirstDate;
    mapping(uint256 => address) private _auctionIDtoSellerAddress;
	mapping(address => bool) public registeredToken;
	
	event TokenStatus(address tokenAddress, bool tokenStatus);
	event ListingSell(address seller, address tokenAddress, address contractNFT, uint tokenId, uint256 price, uint256 datetime);
	event SaleBuy(address buyer, address tokenAddress, address seller, address contractNFT, uint tokenId, uint256 price, uint256 datetime);
	event SaleBuy(address buyer,address seller, address contractNFT, uint tokenId, uint256 price, uint256 datetime);
	event ListingAuction(address seller, address tokenAddress, address contractNFT, uint256 tokenId,uint256 price,uint256 deadline, bool isBEP1155, uint256 datetime);
	event BidAuction(address buyer,address tokenAddress, address contractNFT, uint256 tokenId,uint256 price,uint256 deadline, bool isBEP1155,address seller, bool isDeal, uint256 datetime);
	event ListingAuctionCanceled(address seller, address tokenAddress, address contractNFT, uint256 tokenId,uint256 price,uint256 deadline, bool isBEP1155, uint256 datetime);
	event ListingAuctionFinished(address seller, address tokenAddress, address contractNFT, uint256 tokenId, uint256 datetime);
	
	receive() external payable {}
	
	constructor (
        address wbnb
		,address _feeReceiver
		,uint256 _platform_fee
    ) public {
        require(_platform_fee <= 500, "Max 5%");
		_WBNB = wbnb;
		platform_fee = _platform_fee;
		feeReceiver = _feeReceiver;
		
		registeredToken[_WBNB] = true;
    }
	
	function setRegisterdTokenStatus(address _tokenAddress, bool _tokenStatus) external onlyOwner{
		registeredToken[_tokenAddress] = _tokenStatus;
		
		emit TokenStatus(
			_tokenAddress
			, _tokenStatus
		);
	}
	
    function getNFTsAuctionList( address _contractNFT) public view returns (uint256[] memory) {
        return _contractsTokenIdsList[_contractNFT].collection();
    }
	
    function sellerAddressFor( uint256 _auctionID) public view returns (address) {
        return _auctionIDtoSellerAddress[_auctionID];
    }
	
    function getAuction(
        address _contractNFT,
        uint256 _tokenId
    ) public view returns
    (
        address tokenAddress,
        address seller,
        address latestBidder,
        uint256 latestBidTime,
        uint256 deadline,
        uint price,
        uint latestBidPrice
    ) {
        uint256 index = uint256(_contractNFT).add(_tokenId);
        return 
        (
            _contractsPlusTokenIdsAuction[index].tokenAddress,
            _contractsPlusTokenIdsAuction[index].seller,
            _contractsPlusTokenIdsAuction[index].latestBidder,
            _contractsPlusTokenIdsAuction[index].latestBidTime,
            _contractsPlusTokenIdsAuction[index].deadline,
            _contractsPlusTokenIdsAuction[index].price,
            _contractsPlusTokenIdsAuction[index].latestBidPrice
        );
    }

    function sellWithMint(
		string memory tokenUri
		, address _tokenAddress
		, address _contractNFT
		, uint256 _royalties
		, uint256 _price
		, bool _isBEP1155
	) public {
		require(registeredToken[_tokenAddress], "Token are not Active or not registered");
		
		POMNFT _POMNFT = POMNFT(_contractNFT);
		uint256 _tokenId = _POMNFT.mint(tokenUri,_royalties);
		
		withMint = true;
		sell(_tokenAddress, _contractNFT, _tokenId, _price,_isBEP1155);
		withMint = false;
	}
	
    function sell(
		address _tokenAddress
		, address _contractNFT
		, uint256 _tokenId
		, uint256 _price
		, bool _isBEP1155
	) public {
        require(!_contractsTokenIdsList[_contractNFT].contains(uint256(msg.sender).add(_tokenId)), "Auction is already created");
        require(registeredToken[_tokenAddress], "Token are not Active or not registered");
		
		if(!withMint){
			if (_isBEP1155) {
				IBEP1155(_contractNFT).safeTransferFrom( msg.sender, address(this), _tokenId,1, "0x0");
			} else {
				IBEP721(_contractNFT).transferFrom( msg.sender, address(this), _tokenId);
			}
		}
		
        Auction memory _auction = Auction({
            tokenAddress: _tokenAddress,
            seller: msg.sender,
            latestBidder: address(0),
            latestBidTime: 0,
            deadline: 0,
            price:_price,
            amountReceive:0,
			bidCount:0,
			latestBidPrice:0
        });
		
        _contractsPlusTokenIdsAuction[uint256(_contractNFT).add(_tokenId)] = _auction;
        _auctionIDtoSellerAddress[uint256(msg.sender).add(_tokenId)] = msg.sender;
        _contractsTokenIdsList[_contractNFT].add(uint256(msg.sender).add(_tokenId));
		
		emit ListingSell(
			msg.sender
			, _tokenAddress
			, _contractNFT
			, _tokenId
			, _price
			, block.timestamp
		);
    }
		
    function buy (
        bool _isBEP1155
		, address _contractNFT
		, uint256 _tokenId
    ) external payable  {
        Auction storage auction = _contractsPlusTokenIdsAuction[uint256(_contractNFT).add(_tokenId)];
        require(auction.seller != address(0), "Wrong seller address");
        require(auction.deadline == 0, "Item is on auction");
        SendTransaction memory safeSend;
        
		require(_contractsTokenIdsList[_contractNFT].contains(uint256(auction.seller).add(_tokenId)), "Auction is not created"); // BEP1155 can have more than 1 auction with same ID and , need mix tokenId with seller address
        
		if (_isBEP1155) {
            IBEP1155(_contractNFT).safeTransferFrom( address(this), msg.sender, _tokenId, 1, "0x0");
        } else {
            IBEP721(_contractNFT).safeTransferFrom( address(this), msg.sender, _tokenId);
        }
        
		POMNFT _POMNFT = POMNFT(_contractNFT);
		
		(safeSend.royaltiesFeeAddress, safeSend.royaltiesFee) = _POMNFT.getNFTData(_tokenId);
		
		if(auction.tokenAddress == _WBNB) {
			require(msg.value >= auction.price, "Price rate changed");
			if(msg.value > auction.price){
				payable(msg.sender).transfer(msg.value.sub(auction.price));
			}
			safeSend.amountReceive = auction.price;
		} else {
			safeSend.balanceBeforeSend = IBEP20(auction.tokenAddress).balanceOf(address(this));
			IBEP20(auction.tokenAddress).transferFrom(msg.sender, address(this), _getTokenAmount(auction.tokenAddress,auction.price));
			safeSend.balanceAfterSend = IBEP20(auction.tokenAddress).balanceOf(address(this));
			safeSend.amountReceive = safeSend.balanceAfterSend - safeSend.balanceBeforeSend;
			safeSend.amountReceive = _getReverseTokenAmount(auction.tokenAddress, safeSend.amountReceive);
		}
	
		safeSend.sellerAmount = safeSend.amountReceive;
		safeSend.platformFeeAmount = 0;
		safeSend.royaltiesFeeAmount = 0;
		
		if(platform_fee > 0){
			safeSend.platformFeeAmount = safeSend.amountReceive * platform_fee / _divRate;
			safeSend.sellerAmount -= safeSend.platformFeeAmount;
		}
		
		if(safeSend.royaltiesFee > 0){
			safeSend.royaltiesFeeAmount = safeSend.amountReceive  * safeSend.royaltiesFee / _divRate;
			safeSend.sellerAmount -= safeSend.royaltiesFeeAmount;
		}
		
		if(auction.tokenAddress == _WBNB) {
			payable(feeReceiver).transfer(safeSend.platformFeeAmount);
			payable(safeSend.royaltiesFeeAddress).transfer(safeSend.royaltiesFeeAmount);
			payable(auction.seller).transfer(safeSend.sellerAmount);
		} else {
			IBEP20(auction.tokenAddress).transfer(feeReceiver, _getTokenAmount(auction.tokenAddress, safeSend.platformFeeAmount));
			IBEP20(auction.tokenAddress).transfer(safeSend.royaltiesFeeAddress, _getTokenAmount(auction.tokenAddress, safeSend.royaltiesFeeAmount));
			IBEP20(auction.tokenAddress).transfer(auction.seller, _getTokenAmount(auction.tokenAddress, safeSend.sellerAmount));
		}
		
		emit SaleBuy(msg.sender,auction.tokenAddress,auction.seller, _contractNFT, _tokenId, auction.price, block.timestamp);
		
        _contractsTokenIdsList[_contractNFT].remove(uint256(auction.seller).add(_tokenId));
        delete _auctionIDtoSellerAddress[uint256(auction.seller).add(_tokenId)];
        delete _contractsPlusTokenIdsAuction[ uint256(_contractNFT).add(_tokenId)];
	}
    	
	function createAuctionWithMint(
		string memory tokenUri
		, address _tokenAddress
		, address _contractNFT
		, uint256 _royalties
		, uint256 _price
		, uint256 _deadline
		, bool _isBEP1155
	) public {
		require(registeredToken[_tokenAddress], "Token are not Active or not registered");
		
		POMNFT _POMNFT = POMNFT(_contractNFT);
		uint256 _tokenId = _POMNFT.mint(tokenUri,_royalties);
		
		withMint = true;
		createAuction(_tokenAddress, _contractNFT, _tokenId, _price, _deadline, _isBEP1155);
		withMint = false;
	}
	
    function createAuction(
		address _tokenAddress
		, address _contractNFT
		, uint256 _tokenId
		, uint256 _price
		, uint256 _deadline
		, bool _isBEP1155 
	) public {
        require(!_contractsTokenIdsList[_contractNFT].contains(uint256(msg.sender).add(_tokenId)), "Auction is already created");
		require(registeredToken[_tokenAddress], "Token are not Active or not registered");
		
		if(!withMint){
			if (_isBEP1155) {
				IBEP1155(_contractNFT).safeTransferFrom( msg.sender, address(this), _tokenId,1, "0x0");
			} else {
				IBEP721(_contractNFT).transferFrom( msg.sender, address(this), _tokenId);
			}
		}
		
        Auction memory _auction = Auction({
            tokenAddress: _tokenAddress,
            seller: msg.sender,
            latestBidder: address(0),
            latestBidTime: 0,
            deadline: _deadline,
            price:_price,
            amountReceive:0,
			bidCount:0,
			latestBidPrice:_price
        });
        _contractsPlusTokenIdsAuction[uint256(_contractNFT).add(_tokenId)] = _auction;
        _auctionIDtoSellerAddress[uint256(msg.sender).add(_tokenId)] = msg.sender;
        _contractsTokenIdsList[_contractNFT].add(uint256(msg.sender).add(_tokenId));
        emit ListingAuction( msg.sender,  _tokenAddress, _contractNFT, _tokenId, _price, _deadline, _isBEP1155, block.timestamp);
    }
	
    function _bidWin (
        bool _isBEP1155,
        address _contractNFT,
        uint256 _tokenId
    ) private  {
		Auction storage auction = _contractsPlusTokenIdsAuction[uint256(_contractNFT).add(_tokenId)];
        SendTransaction memory safeSend;
		
		POMNFT _POMNFT = POMNFT(_contractNFT);
		
		(safeSend.royaltiesFeeAddress, safeSend.royaltiesFee) = _POMNFT.getNFTData(_tokenId);
		
		safeSend.sellerAmount = auction.amountReceive;
		safeSend.platformFeeAmount = 0;
		safeSend.royaltiesFeeAmount = 0;
		
		if(platform_fee > 0){
			safeSend.platformFeeAmount = safeSend.amountReceive * platform_fee / _divRate;
			safeSend.sellerAmount -= safeSend.platformFeeAmount;
		}
		
		if(safeSend.royaltiesFee > 0){
			safeSend.royaltiesFeeAmount = safeSend.amountReceive  * safeSend.royaltiesFee / _divRate;
			safeSend.sellerAmount -= safeSend.royaltiesFeeAmount;
		}
		
		if(auction.tokenAddress == _WBNB) {
			payable(feeReceiver).transfer(safeSend.platformFeeAmount);
			payable(safeSend.royaltiesFeeAddress).transfer(safeSend.royaltiesFeeAmount);
			payable(auction.seller).transfer(safeSend.sellerAmount);
		} else {
			IBEP20(auction.tokenAddress).transfer(feeReceiver, _getTokenAmount(auction.tokenAddress, safeSend.platformFeeAmount));
			IBEP20(auction.tokenAddress).transfer(safeSend.royaltiesFeeAddress, _getTokenAmount(auction.tokenAddress, safeSend.royaltiesFeeAmount));
			IBEP20(auction.tokenAddress).transfer(auction.seller, _getTokenAmount(auction.tokenAddress, safeSend.sellerAmount));
		}
		
		if (_isBEP1155) {
            IBEP1155(_contractNFT).safeTransferFrom( address(this), auction.latestBidder, _tokenId, 1, "0x0");
        } else {
            IBEP721(_contractNFT).safeTransferFrom( address(this), auction.latestBidder, _tokenId);
        }
		
		emit SaleBuy(auction.latestBidder,auction.tokenAddress,auction.seller, _contractNFT, _tokenId, auction.latestBidPrice, block.timestamp);
		emit ListingAuctionFinished(auction.seller,auction.tokenAddress, _contractNFT,_tokenId, block.timestamp);
        
        _contractsTokenIdsList[_contractNFT].remove(uint256(auction.seller).add(_tokenId));
        delete _auctionIDtoSellerAddress[uint256(auction.seller).add(_tokenId)];
		delete _contractsPlusTokenIdsAuction[ uint256(_contractNFT).add(_tokenId)];
	}

    function bid(
		address _contractNFT
		,uint256 _tokenId
		,uint256 _price
		,bool _isBEP1155 
	) external payable returns (bool, uint256, address) {
        Auction storage auction = _contractsPlusTokenIdsAuction[uint256(_contractNFT).add(_tokenId)];
        
		require(auction.seller != address(0), "Wrong seller address");
        require(block.timestamp <= auction.deadline, "Auction is ended");
        require(_contractsTokenIdsList[_contractNFT].contains(uint256(auction.seller).add(_tokenId)), "Auction is not created"); // BEP1155 can have more than 1 auction with same ID and , need mix tokenId with seller address
        
		uint256 balanceBeforeSendPrice = 0;
		uint256 balanceAfterSendPrice = 0;
		uint256 amountReceive = 0;
		
		if(auction.tokenAddress == _WBNB) {
			require(msg.value >= auction.latestBidPrice, "Price must be more than previous bid");
			IWETH(_WBNB).deposit{value: msg.value}();
		} else {
			balanceBeforeSendPrice = IBEP20(auction.tokenAddress).balanceOf(address(this));
			IBEP20(auction.tokenAddress).transferFrom(msg.sender, address(this), _getTokenAmount(auction.tokenAddress,auction.price));
			balanceAfterSendPrice = IBEP20(auction.tokenAddress).balanceOf(address(this));
			amountReceive = balanceAfterSendPrice - balanceBeforeSendPrice;
			amountReceive = _getReverseTokenAmount(auction.tokenAddress, amountReceive);
		}
				
		if(auction.bidCount > 0){
			if(auction.tokenAddress == _WBNB) {
				IWETH(_WBNB).withdraw(auction.amountReceive);
				payable(auction.latestBidder).transfer(auction.amountReceive);
			} else {
				IBEP20(auction.tokenAddress).transfer(auction.latestBidder, auction.amountReceive);
			}			
		}
		
		auction.latestBidPrice = _price;
		auction.latestBidder = msg.sender;
		auction.latestBidTime = block.timestamp;
		auction.bidCount += 1;
		auction.amountReceive = amountReceive;
		
		emit BidAuction(msg.sender, auction.tokenAddress, _contractNFT,_tokenId,_price,auction.deadline,_isBEP1155,auction.seller, false, block.timestamp);
		if (auction.latestBidder != address(0)) {
			return (false,auction.price,auction.latestBidder);
		}        
    }
    
    function _cancelAuction( address _contractNFT, uint256 _tokenId, address _sender, bool _isBEP1155, bool _isAdmin ) private {
        uint256 index = uint256(_contractNFT).add(_tokenId);
        Auction storage auction = _contractsPlusTokenIdsAuction[index];
        if (!_isAdmin) require(auction.seller == _sender, "Only seller can cancel");
        
		if(auction.bidCount > 0){
			if(auction.tokenAddress == _WBNB) {
				IWETH(_WBNB).withdraw(auction.amountReceive);
				payable(auction.latestBidder).transfer(auction.amountReceive);
			} else {
				IBEP20(auction.tokenAddress).transfer(auction.latestBidder, auction.amountReceive);
			}			
		}
			
		if (_isBEP1155) {
            IBEP1155(_contractNFT).safeTransferFrom(address(this),auction.seller, _tokenId,1,"0x0");
        } else {
            IBEP721(_contractNFT).safeTransferFrom(address(this),auction.seller, _tokenId);
        }
		
        address auctionSeller = address(auction.seller);
        emit ListingAuctionCanceled(auction.seller, auction.tokenAddress, _contractNFT,_tokenId,auction.price,auction.deadline,_isBEP1155, block.timestamp);
        delete _contractsPlusTokenIdsAuction[index];
        delete _auctionIDtoSellerAddress[uint256(auctionSeller).add(_tokenId)];
        _contractsTokenIdsList[_contractNFT].remove(uint256(auctionSeller).add(_tokenId));
    }

    function adminCancelAuction( address _contractNFT, uint256 _tokenId, bool _isBEP1155) external onlyOwner {
        _cancelAuction( _contractNFT, _tokenId, msg.sender, _isBEP1155, true );
    }
	
    function cancelAuction( address _contractNFT, uint256 _tokenId, bool _isBEP1155) public {
        require(_contractsTokenIdsList[_contractNFT].contains(uint256(msg.sender).add(_tokenId)), "Auction is not created");
        _cancelAuction( _contractNFT, _tokenId, msg.sender, _isBEP1155, false );
    }
	
    function finishAuction( address _contractNFT, uint256 _tokenId, bool _isBEP1155 ) public {
        Auction storage auction = _contractsPlusTokenIdsAuction[uint256(_contractNFT).add(_tokenId)];

		require(msg.sender == auction.seller || msg.sender == auction.latestBidder, "Auction is not seller or winner");

		if(msg.sender == auction.latestBidder){
			require(block.timestamp > auction.deadline && msg.sender == auction.latestBidder, "Auction still running");
		}
		
		require(auction.bidCount > 0, "No Bid, use cancel auction");
		
		_bidWin(
			_isBEP1155,
			_contractNFT,
			_tokenId
		);
    }
	
    function onBEP721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onBEP721Received.selector;
    }

    function onBEP1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata 
    )
    external
    override
    returns(bytes4)
    {
        return this.onBEP1155Received.selector;
    }

    function onBEP1155BatchReceived(
        address ,
        address ,
        uint256[] calldata,
        uint256[] calldata ,
        bytes calldata 
    )
    external
    override
    returns(bytes4)
    {
        return this.onBEP1155BatchReceived.selector;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return this.supportsInterface(interfaceId);
    }
	
	function setPlatformFee(uint256 _platform_fee, address _feeReceiver) external onlyOwner{
		require(_platform_fee <= 500, "Max 5%");
		platform_fee = _platform_fee;
		feeReceiver = _feeReceiver;
	}
	
	function _getTokenAmount(address _tokenAddress, uint256 _amount) internal view returns (uint256 quotient) {
		IBEP20 tokenAddress = IBEP20(_tokenAddress);
		uint256 tokenDecimal = tokenAddress.decimals();
		uint256 decimalDiff;
		uint256 decimalDiffConverter;
		uint256 amount;
			
		if(_weiDecimal != tokenDecimal){
			if(_weiDecimal > tokenDecimal){
				decimalDiff = _weiDecimal - tokenDecimal;
				decimalDiffConverter = 10**decimalDiff;
				amount = _amount.div(decimalDiffConverter);
			} else {
				decimalDiff = tokenDecimal - _weiDecimal;
				decimalDiffConverter = 10**decimalDiff;
				amount = _amount.mul(decimalDiffConverter);
			}		
		} else {
			amount = _amount;
		}
		
		uint256 _quotient = amount;
		
		return (_quotient);
    }
	
	function _getReverseTokenAmount(address _tokenAddress, uint256 _amount) internal view returns (uint256 quotient) {
		IBEP20 tokenAddress = IBEP20(_tokenAddress);
		uint256 tokenDecimal = tokenAddress.decimals();
		uint256 decimalDiff;
		uint256 decimalDiffConverter;
		uint256 amount;
			
		if(_weiDecimal != tokenDecimal){
			if(_weiDecimal > tokenDecimal){
				decimalDiff = _weiDecimal - tokenDecimal;
				decimalDiffConverter = 10**decimalDiff;
				amount = _amount.mul(decimalDiffConverter);
			} else {
				decimalDiff = tokenDecimal - _weiDecimal;
				decimalDiffConverter = 10**decimalDiff;
				amount = _amount.div(decimalDiffConverter);
			}		
		} else {
			amount = _amount;
		}
		
		uint256 _quotient = amount;
		
		return (_quotient);
    }
}