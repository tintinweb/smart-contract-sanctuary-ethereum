/**
 *Submitted for verification at Etherscan.io on 2022-06-07
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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



/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {

    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    )
        external
        returns(bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    )
        external
        returns(bytes4);
}

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId
            || super.supportsInterface(interfaceId);
    }
}

/**
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(address, address, uint256, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}
interface IERC1155 is IERC165 {
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
     * returned by {IERC1155MetadataURI-uri}.
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
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);

    function royalty(uint256 id) external view returns(uint256);

    function miner(uint256 id) external view returns(address);
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
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
}

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



    function royalty(uint256 id) external view returns(uint256);

    function miner(uint256 id) external view returns(address);
    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
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
      * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
      *
      * Emits a {Transfer} event.
      */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
    
}


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
        mapping (bytes32 => uint256) _indexes;
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

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex

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
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
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
}

library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

interface IEnum{
    enum State{solding,saled,cancelled,nul}

    enum TradingType{trading,auction}

    enum PriceState{active,invalid}

    //发布订单事件，owner订单发布者，orderId生成的订单编号，single卡牌单价，time发布时间
    event Created(TradingType indexed tradingType,address indexed owner,uint256 orderId,uint256 single,uint256 time);
    //买入订单事件，purchaser订单买入者，orderId被买入的订单编号，price买入支付的eth数量，time买入时间
    event Purchase(address indexed purchaser,uint256 orderId,uint256 price,uint256 time);
    //取消事件，tradingType 0/1 固定价格单/拍卖单，canceller取消的操作人，orderId被取消的订单编号，time取消时间
    event Cancel(TradingType indexed tradingType,address indexed canceller,uint256 orderId,uint256 time);
    //修改事件，tradingType 0/1 固定价格单/拍卖单，moder修改人地址，orderId被修改订单编号，single被修改的卡牌单价，time修改时间
    event Modify(TradingType indexed tradingType,address indexed moder,uint256 orderId,uint256 single,uint256 time);
    //竞价事件，bidder竞价人，orderId被竞价的订单编号，price竞价价格，time竞价时间
    event Bidding(address indexed bidder,uint256 orderId,uint256 offerId,uint256 price,uint256 time);
    //交割事件，deliverer交割发起人，recever交割给中标的用户地址，orderId被交割的订单编号，price交割价格，time交割时间
    event Delivery(address indexed deliverer,address recever,uint256 orderId,uint256 offerId,uint256 price,uint256 time);
    //取消竞价事件，canceller取消竞价的用户地址，orderId被取消竞价的订单编号，offerId被取消的竞价编号，time取消竞价的时间
    event CancelBidding(address indexed canceller,uint256 orderId,uint256 offerId,uint256 time);

}

interface IData is IEnum{
    

    struct FixedOption{
        address token;
        address creator;
        uint256 id;
        uint256 amount;
        uint256 single;
        uint256 startTime;
        uint256 endTime;
        uint256 updateTime;
        State   state;
    }

    struct AuctionOption{
        address token;
        address creator;
        uint256 id;
        uint256 amount;
        uint256 single;
        uint256 expect;
        uint256 startTime;
        uint256 endTime;
        uint256 updateTime;
        address purchaser;
        uint256 purchasPrice;
        State   state;
    }

    struct User{
        uint256[] purFixedOrderIds;
        uint256[] sellFixedOrderIds;
        uint256[] purAuctionOrderIds;
        uint256[] sellAuctionOrderIds;
        mapping(uint256 => uint256[]) biddingInfo;
    }

    struct Offer{
        address bidder;
        uint256 price;
        uint256 time;
        uint256 updateTime;
        PriceState pState;
    }

}

contract Data is IData,ERC1155Holder{

    using SafeMath for uint256;

    AuctionOption[] public auctionOptions;
    FixedOption[]   public fixedOptions;

    mapping(uint256 => uint256) public fixedOptionIndex;
    uint256[] activeFixedOptionIds;
    uint256[] invalidFixedOptionIds;

    mapping(uint256 => uint256) public auctionOptionIndex;
    uint256[] activeAuctionOptionIds;
    uint256[] invalidAuctionOptionIds;

    Offer[] public offers;
    mapping(uint256 => uint256[]) offerInfo;

    mapping(uint256 => uint256) public offerIndex;

    mapping(address => User) userInfo;

    address public sync;

    address manager;

    constructor(){
        manager = msg.sender;
        Offer memory offer = Offer(address(0),0,block.timestamp,block.timestamp,PriceState.invalid);
        offers.push(offer);
    }
    
    modifier OnlySync(){
        require(sync == msg.sender,"Data: Not permit");
        _;
    }

    modifier OnlyManager(){
        require(manager == msg.sender,"Data: Not permit");
        _;
    }

    function changeManager(address manage) public OnlyManager{
        manager = manage;
    }

    function setSyncAddress(address operate) public OnlyManager{
        sync = operate;
    }

    function createOrder(TradingType tType,address token,address creator,uint256 id,uint256 amount,uint256 single,uint256 startTime,
        uint256 endTime,uint256 expect) public OnlySync returns(uint256 orderId){
        if(tType == TradingType.trading){
            orderId = fixedOptions.length;
            FixedOption memory option = FixedOption(token,creator,id,amount,single,startTime,endTime,block.timestamp,State.solding);
            fixedOptions.push(option);
            activeFixedOptionIds.push(orderId);
            fixedOptionIndex[orderId] = activeFixedOptionIds.length - 1;
            User storage user = userInfo[creator];
            user.sellFixedOrderIds.push(orderId);
        }
        if(tType == TradingType.auction){
            orderId = auctionOptions.length;
            AuctionOption memory auction = AuctionOption(token,creator,id,amount,single,amount.mul(expect),startTime,endTime,block.timestamp,address(0),amount.mul(single),State.solding);
            auctionOptions.push(auction);
            activeAuctionOptionIds.push(orderId);
            auctionOptionIndex[orderId] = activeAuctionOptionIds.length - 1;
            User storage user = userInfo[creator];
            user.sellAuctionOrderIds.push(orderId); 
        }
    }

    function modifyInfo(TradingType tType,uint256 orderId,uint256 start,uint256 end,uint256 single,uint256 expect) public OnlySync{
        if(tType == TradingType.trading){
            FixedOption storage fix = fixedOptions[orderId];
            fix.startTime = start;
            fix.endTime = end;
            fix.single = single;
            fix.updateTime = block.timestamp;
        }
        if(tType == TradingType.auction){
            AuctionOption storage auction = auctionOptions[orderId];
            auction.startTime = start;
            auction.endTime = end;
            auction.single = single;
            auction.expect = auction.amount.mul(expect);
            auction.purchasPrice = auction.amount.mul(single);
            auction.updateTime = block.timestamp;
        }
    }

    function purchaseOrder(address buyer,uint256 orderId) public OnlySync{
        FixedOption storage fix = fixedOptions[orderId];
        safeTransferFor(fix.token, fix.id, address(this), buyer, fix.amount);
        fix.state = State.saled;
        fix.endTime = block.timestamp;
        fix.updateTime = block.timestamp;
        if(activeFixedOptionIds.length>1){
            fixedOptionIndex[activeFixedOptionIds[activeFixedOptionIds.length -1]] = fixedOptionIndex[orderId];
            activeFixedOptionIds[fixedOptionIndex[orderId]] = activeFixedOptionIds[activeFixedOptionIds.length - 1];
        }
        invalidFixedOptionIds.push(orderId);
        activeFixedOptionIds.pop();
        User storage user = userInfo[buyer];
        user.purFixedOrderIds.push(orderId);
    }

    function cancelOrder(TradingType tType,uint256 orderId) public OnlySync{
        if(tType == TradingType.trading){
            FixedOption storage fix = fixedOptions[orderId];
            safeTransferFor(fix.token, fix.id, address(this), fix.creator, fix.amount);
            if(activeFixedOptionIds.length>1){
                fixedOptionIndex[activeFixedOptionIds[activeFixedOptionIds.length -1]] = fixedOptionIndex[orderId];
                activeFixedOptionIds[fixedOptionIndex[orderId]] = activeFixedOptionIds[activeFixedOptionIds.length - 1];
            }
            activeFixedOptionIds.pop();
            invalidFixedOptionIds.push(orderId);
            fix.state = State.cancelled;
            fix.endTime = block.timestamp;
            fix.updateTime = block.timestamp;
        }
        if(tType == TradingType.auction){
            AuctionOption storage auction = auctionOptions[orderId];
            safeTransferFor(auction.token, auction.id, address(this), auction.creator, auction.amount);
            if(activeAuctionOptionIds.length>1){
                auctionOptionIndex[activeAuctionOptionIds[activeAuctionOptionIds.length -1]] = auctionOptionIndex[orderId];
                activeAuctionOptionIds[auctionOptionIndex[orderId]] = activeAuctionOptionIds[activeAuctionOptionIds.length - 1];
            }
            activeAuctionOptionIds.pop();
            invalidAuctionOptionIds.push(orderId);
            auction.state = State.cancelled;
            auction.endTime = block.timestamp;
            auction.updateTime = block.timestamp;
        }
    }

    function joinBidding(uint256 orderId,address customer,uint256 price) public OnlySync returns(uint256 offerId){
        offerId = offers.length;
        Offer memory offer = Offer(customer,price,block.timestamp,block.timestamp,PriceState.active);
        offers.push(offer);
        offerInfo[orderId].push(offerId);
        offerIndex[offerId] = offerInfo[orderId].length - 1;
        AuctionOption storage auction = auctionOptions[orderId];
        auction.purchaser = customer;
        auction.purchasPrice = price;
    }

    function cancelBidding(uint256 orderId,uint256 offerId) public OnlySync{
        uint256 index = offerIndex[offerId];
        Offer storage offer = offers[offerId];
        offer.pState = PriceState.invalid;
        offer.updateTime = block.timestamp;
        delete offerInfo[orderId][index];

        AuctionOption storage auction = auctionOptions[orderId];

        if(offerIndex[offerId] == offerInfo[orderId].length.sub(1)){

            uint256 offId = getActiveBid(orderId);

            if(offId > 0){
                Offer storage off = offers[offId];
                auction.purchaser = off.bidder;
                auction.purchasPrice = off.price;
            }else{
                auction.purchaser = address(0);
                auction.purchasPrice = auction.single;
            }
            auction.updateTime = block.timestamp;
        }
    }

    function deliveryOrder(uint256 orderId,address customer,uint256 price) public OnlySync{
        AuctionOption storage auction = auctionOptions[orderId];
        safeTransferFor(auction.token, auction.id, address(this), customer, auction.amount);
        auction.purchaser = customer;
        auction.purchasPrice = price;
        auction.endTime = block.timestamp;
        auction.state = State.saled;
        auction.updateTime = block.timestamp;
        User storage user = userInfo[customer];
        user.purAuctionOrderIds.push(orderId);
        if(activeAuctionOptionIds.length>1){
            auctionOptionIndex[activeAuctionOptionIds[activeAuctionOptionIds.length -1]] = auctionOptionIndex[orderId];
            activeAuctionOptionIds[auctionOptionIndex[orderId]] = activeAuctionOptionIds[activeAuctionOptionIds.length - 1];
        }
    }

    function manageAllOrders(TradingType tradingType,uint256 limit) public OnlyManager{
        if(tradingType == TradingType.trading){
            for(uint i=0; i<activeFixedOptionIds.length; i++){
                FixedOption storage fix = fixedOptions[activeFixedOptionIds[i]];
                if(fix.state == State.solding && block.timestamp >= fix.endTime){
                    cancelOrder(tradingType, activeFixedOptionIds[i]);
                }
            }
        }
        if(tradingType == TradingType.auction){
            for(uint i=0; i<activeAuctionOptionIds.length; i++){
                AuctionOption storage auction = auctionOptions[activeAuctionOptionIds[i]];
                if(auction.state == State.solding && block.timestamp.sub(auction.endTime) >= limit){
                    cancelOrder(tradingType, activeAuctionOptionIds[i]);
                }
            }
        }
    }

    // function manageBatchOrders(TradingType tradingType,uint256[] memory orderIds,uint256 limit) public OnlyManager{
        
    // }
    
    function safeTransferFor(address token,uint256 id,address from,address to,uint256 amount) internal{
        if(IERC165(token).supportsInterface(0xd9b67a26) != false){
            IERC1155(token).safeTransferFrom(from, to, id, amount, new bytes(0));
        }else{
            IERC721(token).transferFrom(from, to, id);
        }
    }

    function getOrders() public view returns(uint256[] memory activeFixed,uint256[] memory invalidFixed,uint256[] memory activeAuction,
        uint256[] memory invalidAuction){
            activeFixed = activeFixedOptionIds;
            invalidFixed = invalidFixedOptionIds;
            activeAuction = activeAuctionOptionIds;
            invalidAuction = invalidAuctionOptionIds;
    }

    function getUserOrders(address customer) public view returns(uint256[] memory sellFixed,uint256[] memory purFixed,uint256[]
        memory sellAuction,uint256[] memory purAuction){
            User storage user = userInfo[customer];
            sellFixed = user.sellFixedOrderIds;
            purFixed = user.purFixedOrderIds;
            sellAuction = user.sellAuctionOrderIds;
            purAuction = user.purAuctionOrderIds;
    }

    function getUserBidding(address customer,uint256 orderId) public view returns(uint256[] memory){
        User storage user = userInfo[customer];
        return user.biddingInfo[orderId];
    }

    function offerInfos(uint256 orderId) public view returns(uint256[] memory){
        return offerInfo[orderId];
    }

    function getActiveBid(uint256 orderId) public view returns(uint256){

        uint256[] memory offs = offerInfo[orderId];
        uint256 offId = 0;
        for(uint i = offs.length.sub(1); i > 0; i--){
            if(offs[i] > 0){
                Offer storage offer = offers[offs[i]];
                if(offer.pState == PriceState.active){
                    offId = offs[i];
                    break;
                }
            }
            
        }
        return offId;
    }
    
}

interface ISynchron is IEnum{
    //下述uint256 update代表当前订单状态更新的最新时间
    //token卡牌合约地址，creator订单发布者地址，id卡牌的tokenId，amount售卖数量，single单价，expect期望单价，startTime开始时间，endTime结束时间，
    //purchaser最高出价者地址，purchasPrice最高出价，state订单状态 0/1/2 出售中/已出售/已取消
    function auctionOptions(uint256 orderId) external view returns(address token,address creator,uint256 id,uint256 amount,uint256 single,
        uint256 expect,uint256 startTime,uint256 endTime,uint256 update,address purchaser,uint256 purchasPrice,State state);
    //token卡牌合约地址，creator订单发布者地址，id卡牌的tokenId，amount售卖数量，single单价，startTime开始时间，endTime结束时间，
    //state订单状态 0/1/2 出售中/已出售/已取消
    function fixedOptions(uint256 orderId) external view returns(address token,address creator,uint256 id,uint256 amount,uint256 single,
        uint256 startTime,uint256 endTime,uint256 update,State state);
    //bidder出价者地址，price出价价格，time出价时间，pState出价状态 0/1 有效/无效
    function offers(uint256 offerId) external view returns(address bidder,uint256 price,uint256 time,uint256 update,PriceState pState);
    //更新后增加的出价数组
    function offerInfos(uint256 orderId) external view returns(uint256[] memory);
    
    function createOrder(TradingType tType,address token,address creator,uint256 id,uint256 amount,uint256 single,uint256 startTime,
        uint256 endTime,uint256 expect) external  returns(uint256 orderId);

    function modifyInfo(TradingType tType,uint256 orderId,uint256 start,uint256 end,uint256 single,uint256 expect) external;

    function purchaseOrder(address buyer,uint256 orderId) external;

    function cancelOrder(TradingType tType,uint256 orderId) external;

    function joinBidding(uint256 orderId,address customer,uint256 price) external returns(uint256 offerId);

    function cancelBidding(uint256 orderId,uint256 offerId) external;

    function deliveryOrder(uint256 orderId,address customer,uint256 price) external;
    //获取所有订单，activeFixed固定价格所有有效订单，invalidFixed固定价格所有无效订单，activeAuction所有有效拍卖订单编号，invalidAuction所有无效拍卖订单编号
    function getOrders() external view returns(uint256[] memory activeFixed,uint256[] memory invalidFixed,uint256[] memory activeAuction,
        uint256[] memory invalidAuction);
    //获取用户信息，sellFixed当前用户发布的所有固定售卖订单，purFixed当前用户买入的所有固定价格订单编号，sellAuction当前用户发布的所有拍卖订单编号，
    //purAuction当前用户参与竞价的所有拍卖订单
    function getUserOrders(address customer) external view returns(uint256[] memory sellFixed,uint256[] memory purFixed,uint256[]
        memory sellAuction,uint256[] memory purAuction);
    //获取用户竞价信息，提供用户地址与订单编号，读取当前用户对该订单参与的所有竞价编号
    function getUserBidding(address customer,uint256 orderId) external view returns(uint256[] memory);
    //获取当前订单可以交割的offerId
    function getActiveBid(uint256 orderId) external view returns(uint256);
}

interface ITrading is IEnum{
    //传入拍卖订单orderId，返回startCount距离开始时间倒计时，endCount距离结束时间倒计时
    function getAuctionOptionInfo(uint256 orderId) external view returns(uint256 startCount,uint256 endCount);
    //传入固定价格订单orderId，返回startCount距离开始时间倒计时，endCount距离结束时间倒计时
    function getFixedOptionInfo(uint256 orderId) external view returns(uint256 startCount,uint256 endCount);
    //创建固定价格或拍卖订单,tradingType 0/1 固定价格订单/拍卖订单，token当前订单售卖的卡牌合约地址，creator当前订单的拥有者，id卡牌tokenId，amount售卖数量
    //single卡牌单价，start开始售卖时间，end售卖时间，expect期望单价
    function createOrder(TradingType tradingType,address token,address creator,uint256 id,uint256 amount,uint256 single,uint256 start,
        uint256 end,uint256 expect) external returns(uint256 orderId);
    //tradingType 0/1 固定价格/拍卖订单，订单类型；orderId对应订单类型的订单编号，返回price代表要支付的金额，expectPrice是拍卖单返回的期望价格，如果是固定价格
    //订单或没有期望价格则会返回0
    function getPayment(TradingType tradingType, uint256 orderId) external view returns(uint256 price,uint256 expectPrice);
    //买入固定价格订单的订单编号，根据getPayment获取固定价格订单的价格
    function purchase(uint256 orderId) external payable;
    //tradingType 订单类型 0/1，orderId订单编号，true表示可以取消，false表示不可取消
    function getCancelInfo(TradingType tradingType,uint256 orderId) external view returns(bool whether);
    //tradingType 订单类型 0/1，orderId订单编号,进行取消
    function cancel(TradingType tradingType,uint256 orderId) external;
    //参与竞价，orderId代表拍卖订单编号，price代表要出的价格
    function bidding(uint256 orderId,uint256 price) external;
    //取消对应订单编号的竞价编号，orderId拍卖订单编号，offerId竞价信息编号，进行出价取消
    function cancelOffer(uint256 orderId,uint256 offerId) external;
    //orderId订单，返回可以交付的出价订单编号
    function getActiveOffers(uint256 orderId) external view returns(uint256);
    //获取订单是否可以修改，tradingType 0/1 固定价格/拍卖，orderId订单编号，price要把价格修改成多少？返回false代表不可以修改，true表示可修改
    function getModifyBool(TradingType tradingType,uint256 orderId,uint256 price) external view returns(bool isSupport);
    //进行交割
    function delivery(uint256 orderId) external;
    //修改价格,price代表单价
    function modify(TradingType tradingType,uint256 orderId,uint256 price) external;
    //获取订单是否支持重置，false代表不可重置，true代表可重置
    function getResetBool(TradingType tradingType,uint256 orderId) external view returns(bool isSupport);
    //进行订单重置
    function reSet(TradingType tradingType,uint256 orderId,uint256 sin,uint256 exp,uint256 start,uint256 end) external;
    //判断订单是否可以拒绝交割
    function getRefuseBool(uint256 orderId) external view returns(bool isSupport);
    //拒绝交割
    function refuseDelivery(uint256 orderId) external;
    
}

contract Trading is IEnum,ERC1155Holder{
    using SafeMath for uint256;

    mapping(address => bool) nftPermit;

    uint256 taxFixedFee = 2;

    uint256 taxAuctionFee = 25;

    address fee;

    address weth = 0xc778417E063141139Fce010982780140Aa0cD5Ab;

    address data;

    address manager;

    constructor(address _data){
        manager = msg.sender;
        fee = msg.sender;
        data = _data;
    }

    modifier OnlyManager(){
        require(manager == msg.sender,"Trading:No permit");
        _;
    }

    function addPermit(address token,bool isSupport) public OnlyManager{
        nftPermit[token] = isSupport;
    }
    
    function setFee(address _fee,address _weth) public OnlyManager{
        fee = _fee;
        weth = _weth;
    }

    function safeTransferFor(address token,uint256 id,address from,address to,uint256 amount) internal{

        if(IERC165(token).supportsInterface(0xd9b67a26) != false){
            IERC1155(token).safeTransferFrom(from, to, id, amount, new bytes(0));
        }else{
            IERC721(token).transferFrom(from, to, id);
        }
    }

    function getAuctionOptionInfo(uint256 orderId) public view returns(uint256 startCount,uint256 endCount){
            
            (,,,,,,uint256 startTime,uint256 endTime,,,,State state) = ISynchron(data).auctionOptions(orderId);

            if(block.timestamp <= startTime && state == State.solding){
                startCount = startTime.sub(block.timestamp);
            }
            if(block.timestamp <= endTime && state == State.solding){
                endCount = endTime.sub(block.timestamp);
            }
    }

    function getFixedOptionInfo(uint256 orderId) public view returns(uint256 startCount,uint256 endCount){
            (,,,,,uint256 startTime,uint256 endTime,,State state) = ISynchron(data).fixedOptions(orderId);
            if(block.timestamp >= startTime && state == State.solding){
                startCount = block.timestamp.sub(startTime);
            }
            if(block.timestamp <= endTime && state == State.solding){
                endCount = endTime.sub(block.timestamp);
            }
    }

    function createOrder(TradingType tradingType,address token,address creator,uint256 id,uint256 amount,uint256 single,uint256 start,
        uint256 end,uint256 expect) public returns(uint256 orderId){
            require(creator != address(0) && amount >0 && single > 0,"Trading:Data wrong");
            require(start >= block.timestamp && end > start && start.sub(block.timestamp) <= 90 days,"Trading:Time wrong");
            if(nftPermit[msg.sender] != true){
                safeTransferFor(token, id, msg.sender, data, amount);
            }else{
                safeTransferFor(token, id, address(this), data, amount);
            }
            
            if(tradingType == TradingType.trading){
                require(end.sub(start) <= 180 days,"Trading:Time limit wrong");
                orderId = ISynchron(data).createOrder(tradingType, token, creator, id, amount, single, start, end, 0);
            }
            if(tradingType == TradingType.auction){
                require(end.sub(start) <= 30 days,"Trading:Time limit wrong");
                orderId = ISynchron(data).createOrder(tradingType, token, creator, id, amount, single, start, end, expect);
            }
            emit Created(tradingType,creator, orderId, single, block.timestamp);
    }

    function getPayment(TradingType tradingType, uint256 orderId) public view returns(uint256 price,uint256 expectPrice){
        if(tradingType == TradingType.trading){
            (,,,uint256 amount,uint256 single,,uint256 endTime,,State state) = ISynchron(data).fixedOptions(orderId);
            if(block.timestamp < endTime && state == State.solding){
                price = amount.mul(single);
                expectPrice = 0;
            }
        }
        if(tradingType == TradingType.auction){
            (,,,uint256 amount,,uint256 expect,,uint256 endTime,,,uint256 purchasPrice,
                State state) = ISynchron(data).auctionOptions(orderId);
            if(block.timestamp < endTime && state == State.solding){
                price = purchasPrice.add(purchasPrice.mul(5).div(100));
                expectPrice = amount.mul(expect);
            }
        }
    }

    function getNftInfo(address token,uint256 id) public view returns(uint256 royal,address mine){
        if(IERC165(token).supportsInterface(0xd9b67a26) != false){
            royal = IERC1155(token).royalty(id);
            mine = IERC1155(token).miner(id);
        }else{
            royal = IERC721(token).royalty(id);
            mine = IERC721(token).miner(id);
        }
    }

    function purchase(uint256 orderId) public payable{
        (address token,address creator,uint256 id,,,uint256 startTime,uint256 endTime,,State state) = ISynchron(data).fixedOptions(orderId);
        require(msg.sender != creator,"Trading:Data duplication");
        require(block.timestamp >= startTime && block.timestamp < endTime && state == State.solding,"Trading:State wronf");
        (uint256 price,) = getPayment(TradingType.trading, orderId);
        require(msg.value >= price,"Trading:Payment wrong");
        (uint256 royal,address miner) = getNftInfo(token, id);
        uint256 payFee = msg.value.mul(taxFixedFee).div(100);
        uint256 royalty = msg.value.mul(royal).div(10000);
        uint256 reward = msg.value.sub(payFee).sub(royalty);
        TransferHelper.safeTransferETH(creator, reward);
        TransferHelper.safeTransferETH(miner, royalty);
        TransferHelper.safeTransferETH(fee, payFee);
        ISynchron(data).purchaseOrder(msg.sender, orderId);
        emit Purchase(msg.sender, orderId, msg.value, block.timestamp);
    }

    function getCancelInfo(TradingType tradingType,uint256 orderId) public view returns(bool whether){
        if(tradingType == TradingType.trading){
            (,address creator,,,,,,,State state) = ISynchron(data).fixedOptions(orderId);
            if(state == State.solding && creator == msg.sender){
                whether = true;
            }
        }

        if(tradingType == TradingType.auction){
            (,address creator,,,,,,,,address purchaser,,State state) = ISynchron(data).auctionOptions(orderId);
            if(state == State.solding && purchaser == address(0) && creator == msg.sender){
                whether = true;
            }
        }
    }

    function cancel(TradingType tradingType,uint256 orderId) public{
        require(getCancelInfo(tradingType,orderId) == true,"Trading:State wrong");
        ISynchron(data).cancelOrder(tradingType, orderId);
        emit Cancel(tradingType, msg.sender, orderId, block.timestamp);
    }

    function getWEthBool(address customer,uint256 price) public view returns(bool isAppr){
        uint256 haves = IERC20(weth).balanceOf(customer);
        uint256 allow = IERC20(weth).allowance(customer,address(this));
        if(haves >= price && allow >= price){
            isAppr = true;
        }
    }

    function bidding(uint256 orderId,uint256 price) public {
        (,address creator,,,uint256 single,uint256 expect,uint256 startTime,uint256 endTime,,,,State state) = ISynchron(data).auctionOptions(orderId);
        require(msg.sender != creator,"Trading:Data duplication");
        require(block.timestamp >= startTime && block.timestamp <= endTime && state == State.solding,"Trading:State wrong");
        (uint256 currentPrice,uint256 currentExpect) = getPayment(TradingType.auction, orderId);
        require(price >= currentPrice,"Trading:Price wrong");

        require(getWEthBool(msg.sender,price) == true,"Trading:Asset not enough");

        if(endTime.sub(block.timestamp) <= 600){
            commitTime(orderId,startTime,endTime+600,single,expect);
        }
        uint256 offerId = commitBidding(orderId,price);
        if(price >= currentExpect && currentExpect > 0){
            commitDelivery(orderId,price,offerId);
        }
    }

    function commitBidding(uint256 orderId,uint256 price) internal returns(uint256 offerId){
        offerId = ISynchron(data).joinBidding(orderId, msg.sender, price);
        emit Bidding(msg.sender, orderId, offerId, price, block.timestamp);
    }

    function commitTime(uint256 orderId,uint256 start,uint256 end,uint256 single,uint256 expect) internal{
        ISynchron(data).modifyInfo(TradingType.auction, orderId, start, end, single, expect);
        emit Modify(TradingType.auction, msg.sender, orderId, single, block.timestamp);
    }

    function commitDelivery(uint256 orderId,uint256 price,uint256 offerId) internal{
        (address token,address creator,uint256 id,,,,,,,,,) = ISynchron(data).auctionOptions(orderId);
        (uint256 royal,address miner) = getNftInfo(token, id);
        uint256 payFee = price.mul(taxAuctionFee).div(1000);
        uint256 royalty = price.mul(royal).div(10000);
        uint256 reward = price.sub(payFee).sub(royalty);
        require(IERC20(weth).transferFrom(msg.sender, creator, reward),"Trading:TransferFrom failed");

        require(IERC20(weth).transferFrom(msg.sender, miner, royalty),"Trading:TransferFrom failed");

        require(IERC20(weth).transferFrom(msg.sender, fee, payFee),"Trading:TransferFrom failed");

        ISynchron(data).deliveryOrder(orderId, msg.sender, price);

        emit Delivery(msg.sender, msg.sender, orderId, offerId, price, block.timestamp);
    }

    function getCancelOfferBool(uint256 orderId,uint256 offerId) public view returns(bool isSupp){
        (,,,,,,,uint256 endTime,,,,State state) = ISynchron(data).auctionOptions(orderId);
        (address purer,,,,PriceState pState) = ISynchron(data).offers(offerId);
        if(block.timestamp < endTime && state == State.solding && purer == msg.sender && pState == PriceState.active){
            isSupp = true;
        }
    }

    //取消出价
    function cancelOffer(uint256 orderId,uint256 offerId) public {
        require(getCancelOfferBool(orderId,offerId),"Trading:State wrong");
        ISynchron(data).cancelBidding(orderId, offerId);
        emit CancelBidding(msg.sender, orderId, offerId, block.timestamp);
    }

    //获取可交割的出价id
    function getActiveOffers(uint256 orderId) public view returns(uint256){
        return ISynchron(data).getActiveBid(orderId);
    }

    //进行交割函数
    function delivery(uint256 orderId) public {
        (address token,address creator,uint256 id,,,,,uint256 endTime,,address purchaser,,State state) = ISynchron(data).auctionOptions(orderId);
        require(msg.sender == creator && purchaser != creator && purchaser != address(0),"Trading:Not permit");
        require(block.timestamp >= endTime && state == State.solding,"Trading:State wrong");
        uint256 offerId = getActiveOffers(orderId);
        (address bidder,uint256 price,,,PriceState pState) = ISynchron(data).offers(offerId);
        require(pState == PriceState.active && price > 0 && bidder != address(0),"Trading:Price state wrong");
        (uint256 royal,address miner) = getNftInfo(token, id);     
        pay(creator,miner,price,royal);
        ISynchron(data).deliveryOrder(orderId, bidder, price);

        emit Delivery(msg.sender, msg.sender, orderId, offerId, price, block.timestamp);
    }
    
    function pay(address owner,address miner,uint256 price,uint256 royal) internal{
        uint256 payFee = price.mul(taxAuctionFee).div(1000);
        uint256 royalty = price.mul(royal).div(10000);
        uint256 reward = price.sub(payFee).sub(royalty);
        require(IERC20(weth).transferFrom(msg.sender, owner, reward),"Trading:TransferFrom failed");
        require(IERC20(weth).transferFrom(msg.sender, miner, royalty),"Trading:TransferFrom failed");
        require(IERC20(weth).transferFrom(msg.sender, fee, payFee),"Trading:TransferFrom failed");
    }

    function getModifyBool(TradingType tradingType,uint256 orderId,uint256 price) public view returns(bool isSupport){
        if(tradingType == TradingType.trading){
            (,address creator,,,,,uint256 endTime,,State state) = ISynchron(data).fixedOptions(orderId);
            if(block.timestamp < endTime && state == State.solding && creator == msg.sender){
                isSupport = true;
            }
        }

        if(tradingType == TradingType.auction){
            (,address creator,,,uint256 single,,,uint256 endTime,,address purchaser,,State state) = ISynchron(data).auctionOptions(orderId);
            if(creator == msg.sender && block.timestamp < endTime && purchaser == address(0) && state == State.solding && price < single){
                isSupport = true;
            }
        }
        
    }

    function modify(TradingType tradingType,uint256 orderId,uint256 price) public{
        require(getModifyBool(tradingType,orderId, price) == true,"Trading:State wrong");
        if(tradingType == TradingType.trading){
            (,,,,, uint256 startTime,uint256 endTime,,) = ISynchron(data).fixedOptions(orderId);
            ISynchron(data).modifyInfo(tradingType, orderId, startTime, endTime, price, 0);
        }else{
            (,,,,,uint256 expect,uint256 startTime,uint256 endTime,,,,) = ISynchron(data).auctionOptions(orderId);
            ISynchron(data).modifyInfo(tradingType, orderId, startTime, endTime, price, expect);
        }
        emit Modify(tradingType, msg.sender, orderId, price, block.timestamp);
    }

    function getResetBool(TradingType tradingType,uint256 orderId) public view returns(bool isSupport){
        if(tradingType == TradingType.trading){
            (,address creator,,,,,uint256 endTime,,State state) = ISynchron(data).fixedOptions(orderId);
            if(block.timestamp >= endTime && state == State.solding && creator == msg.sender){
                isSupport = true;
            }
        }

        if(tradingType == TradingType.auction){
            (,address creator,,,,,,uint256 endTime,,address purchaser,,State state) = ISynchron(data).auctionOptions(orderId);
            if(creator == msg.sender && block.timestamp >= endTime && purchaser == address(0) && state == State.solding){
                isSupport = true;
            }
        }
    }


    function reSet(TradingType tradingType,uint256 orderId,uint256 sin,uint256 exp,uint256 start,uint256 end) public{
        require(getResetBool(tradingType, orderId) == true,"Trading:State wrong");
        ISynchron(data).modifyInfo(tradingType, orderId, start, end, sin, exp);
        emit Modify(tradingType, msg.sender, orderId, sin, block.timestamp);
    }

    function getRefuseBool(uint256 orderId) public view returns(bool isSupport){
        (,address creator,,,,,,uint256 endTime,,address purchaser,,State state) = ISynchron(data).auctionOptions(orderId);
        if(creator == msg.sender && purchaser != address(0) && state == State.solding && block.timestamp >= endTime){
            isSupport = true;
        }
    }

    function refuseDelivery(uint256 orderId) public {
        require(getRefuseBool(orderId) == true,"Trading:State wrong");
        ISynchron(data).cancelOrder(TradingType.auction, orderId);
        emit Cancel(TradingType.auction, msg.sender, orderId, block.timestamp);
    }

    
}

//token721:0x29F966e8b5d5043B7E7DE93ed1bEA5F38C48CCa8
//token1155:0x2BCb906e8BE8758334eb99ef042aDAEAbC932Fc0
//data:0xcd85f574324D74CE011A225f60326edEF4fb3B13
//trading:0x5885674d36075A5B8ae75A39D993E6F7A2AD2B8A