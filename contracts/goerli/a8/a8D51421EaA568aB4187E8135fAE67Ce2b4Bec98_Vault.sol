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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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

//SPDX-License-Identifier: Unlicense

pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract Vault is Ownable {
    using EnumerableSet for EnumerableSet.UintSet;

    struct Borrow {
        uint256 id;
        uint256 tokenId;
        uint256 created;
        uint256 currentBalance; // Current borrow balance of user
        uint256 approvedBorrowAmount; // Approved nft price from back end
        address contractAddress;
        address owner;
    }

    struct Deal {
        uint256 id;
        uint256 borrowId;
        uint256 amount;
        uint256 created;
        address poolAddress; // GMX, CLP, PANCAKE
    }

    string public constant NOT_ENOUGH_BALANCE_TO_OPEN_DEAL = "Not enough available balance";
    string public constant NOT_ENOUGH_BALANCE_TO_WITHDRAW_NFT = "Not enough available balance to withdraw NFT";
    string public constant PERMISSION_DENIED_BORROW_OWNERSHIP = "Permission denied";
    string public constant USER_HAVE_OPENED_DEALS = "You have opened deals";
    string public constant WRONG_LIQUIDITY_POOL_ADDRESS = "Incorrect liquidity pool address";


    //                             ** Borrows tree structure **

    //*                                      U S E R
    //*                                         |
    //*        [Borrow-1]                   [Borrow-2]                           [Borrow-3]
    //*            |                            |                                    |
    //* [Deal-1] [Deal-2] [Deal-3]    [Deal-4] [Deal-5] [Deal-6]          [Deal-7] [Deal-8] [Deal-9]


    uint256 public borrowCounter;
    uint256 public dealCounter;

    address public usdcContractAddress; //USDC address for example
    address public lendingPoolAddress;

    // BorrowID => Borrow
    mapping(uint256 => Borrow) public borrows;

    mapping(uint256 => Deal) public deals;

    mapping(address => bool) public liquidityPoolAddressesWhiteList;

    // USer address => BorrowsID[1,4,6,8]
    mapping(address => EnumerableSet.UintSet) internal _borrowIds;

    // BorrowId => deals [1,6,7,8...]
    mapping(uint256 => EnumerableSet.UintSet) internal _dealIds;

    event DepositNft(
        address indexed from,
        address indexed contractAddress,
        uint256 indexed tokenId,
        uint256 borrowId
    );

    event OpenBorrow(
        uint256 indexed borrowId,
        uint256 indexed approvedAmount,
        address indexed owner
    );

    event OpenDeal(
        uint256 indexed dealId,
        address indexed owner,
        address indexed poolAddress,
        uint256 amount
    );

    event CloseDeal(uint256 indexed dealId, address indexed owner);

    event CloseBorrow(
        uint256 indexed borrowId,
        address indexed owner,
        uint256 indexed closedAmount
    );

    event WithdrawBalance(
        uint256 indexed borrowId,
        address indexed owner,
        uint256 indexed amount
    );

    /// @notice Setup Initial Values
    /// @param lendingPoolAddress_ Lending pool from where we will borrow money (USDC)
    constructor(address lendingPoolAddress_, address usdcContractAddress_) {
        lendingPoolAddress = lendingPoolAddress_;
        usdcContractAddress = usdcContractAddress_;
    }

    /// @notice Deposit NFT (not collaterized)
    /// @param nftContract NFT contract address
    /// @param tokenId NFT Token Id within mentioned contract
    function depositNft(address nftContract, uint256 tokenId) public {
        borrowCounter++;

        Borrow storage newBorrow = borrows[borrowCounter];
        newBorrow.tokenId = tokenId;
        newBorrow.id = borrowCounter;
        newBorrow.created = block.timestamp;
        newBorrow.contractAddress = nftContract;
        newBorrow.owner = _msgSender();

        _borrowIds[_msgSender()].add(newBorrow.id);

        // send nft to this
        IERC721(nftContract).transferFrom(_msgSender(), address(this), tokenId);

        emit DepositNft(_msgSender(), nftContract, tokenId, newBorrow.id);
    }

    /// @notice Borrow tokens(USDC) for a deposited NFT and make this NFT collaterized
    /// @param borrowId actually deposit Id which is returned from the `DepositNft` event
    /// @param borrowedAmount Borrowed amount
    /// @param signature Signature
    function borrowTopkens(
        uint256 borrowId,
        uint256 borrowedAmount,
        bytes calldata signature
    ) public {
        // verify signature
        Borrow storage borrow = borrows[borrowId];

        require(borrow.owner == _msgSender(), PERMISSION_DENIED_BORROW_OWNERSHIP);
        borrow.currentBalance = borrowedAmount;
        borrow.approvedBorrowAmount = borrowedAmount;

        IERC20(usdcContractAddress).transferFrom(
            lendingPoolAddress,
            address(this),
            borrowedAmount
        );

        emit OpenBorrow(borrowId, borrowedAmount, _msgSender());
    }

    /// @notice Open a new deal by transfering borrowed amount or its part to the specified pool like GLP and so on.
    /// @param borrowId actually deposit Id of the deposited nft
    /// @param amount Amount to transfer on the pool
    function openDeal(
        uint256 borrowId,
        address poolAddress,
        uint256 amount
    ) public {
        unchecked {
            dealCounter++;
        }

        require(
            liquidityPoolAddressesWhiteList[poolAddress],
            WRONG_LIQUIDITY_POOL_ADDRESS
        );
        require(borrows[borrowId].owner == _msgSender(), PERMISSION_DENIED_BORROW_OWNERSHIP);

        require(
            borrows[borrowId].currentBalance >= amount,
            NOT_ENOUGH_BALANCE_TO_OPEN_DEAL
        );

        Deal storage newDeal = deals[dealCounter];
        newDeal.id = dealCounter;
        newDeal.borrowId = borrowId;
        newDeal.amount = amount;
        newDeal.created = block.timestamp;
        newDeal.poolAddress = lendingPoolAddress; // vvvfix

        borrows[borrowId].currentBalance -= amount;
        _dealIds[borrowId].add(dealCounter);

        // send erc20 to pool
        IERC20(usdcContractAddress).transfer(poolAddress, amount);

        emit OpenDeal(dealCounter, _msgSender(), poolAddress,  amount);
    }

    /// @notice Close opened deal. Will be called by Backend agent at the end of the process. 
    /// Amount will be returned to the deposited NFT.
    /// @param dealId id of the deal
    /// @param finishAmount Amount eventually taken after the investment, 
    /// considering percentage rate and tokens price changes.
    /// @param signature For security purposes to allow user approve this "deal close".
    /// So that Backend can not sign whatever he wants.
    function closeDeal(
        uint256 dealId,
        uint256 finishAmount,
        bytes calldata signature
    ) public onlyOwner {
        // verify signature

        Deal storage deal = deals[dealId];
        Borrow storage borrow = borrows[deal.borrowId];

        borrow.currentBalance += finishAmount;
        _dealIds[borrow.id].remove(deal.id);

        delete deals[dealId];

        emit CloseDeal(dealId, _msgSender());
    }

    /// @notice Withdraw NFT. However, firstly extracting borrowed money and all fees. 
    /// Will be successful in case the current balance above the borrowed balance plus all fees.
    /// @param borrowId id of the borrow, deposit Id actually
    function withdrawNft(uint256 borrowId) public {
        Borrow storage borrow = borrows[borrowId];

        require(borrow.owner == _msgSender(), PERMISSION_DENIED_BORROW_OWNERSHIP);
        require(_dealIds[borrowId].length() == 0, USER_HAVE_OPENED_DEALS);

        // check balance before close borrow
        require(borrow.currentBalance > borrow.approvedBorrowAmount, NOT_ENOUGH_BALANCE_TO_WITHDRAW_NFT);

        IERC20(usdcContractAddress).transfer(
            lendingPoolAddress,
            borrow.approvedBorrowAmount // + %
        );

        // vvvfix - add fees transfer
        // vvvfix add settings
        IERC721(borrow.contractAddress).safeTransferFrom(
            address(this),
            _msgSender(),
            borrow.tokenId
        );

        borrow.currentBalance -= borrow.approvedBorrowAmount;
        borrow.approvedBorrowAmount = 0;

        delete _dealIds[borrowId];
        delete _borrowIds[_msgSender()];

        emit CloseBorrow(borrowId, borrow.owner, borrow.approvedBorrowAmount);
    }

    /// @notice Adding balance for a deposited NFT. 
    /// In case user willing to withdraw NFT however its current balance is less than borrowed.
    /// @param borrowId id of the borrow, deposit Id actually
    /// @param amount added amount
    function addBalance(uint256 borrowId, uint256 amount) public {
        IERC20(usdcContractAddress).transferFrom(
            _msgSender(),
            address(this),
            amount
        );
        borrows[borrowId].currentBalance += amount;
    }

    /// @notice Withdraw the free earned user balance
    /// @param borrowId id of the borrow, deposit Id of the NFT actually
    function withdrawBalance(uint256 borrowId) public {
        require(borrows[borrowId].owner == _msgSender(), PERMISSION_DENIED_BORROW_OWNERSHIP);

        Borrow storage borrow = borrows[borrowId];

        uint256 amount = borrow.currentBalance -
            borrow.approvedBorrowAmount;
        // vvvfix - consider fees
        require(amount > 0, NOT_ENOUGH_BALANCE_TO_OPEN_DEAL);

        IERC20(usdcContractAddress).transfer(_msgSender(), amount);
        borrow.currentBalance -= amount;
        delete borrows[borrowId];

        emit WithdrawBalance(borrowId, _msgSender(), amount);
    }

    /// @notice Get list of user borrows
    /// @param userAddress The address of user to get it's borrows
    /// @param fromPosition Limitatin/pagination purpose parameter
    /// @param toPosition Limitatin/pagination purpose parameter
    /// @return Borrows by user
    function getUserBorrows(
        address userAddress,
        uint256 fromPosition,
        uint256 toPosition
    ) public view returns (Borrow[] memory) {
        require(fromPosition < toPosition, "Incorrect positions");

        if (_borrowIds[userAddress].length() < toPosition) {
            toPosition = _borrowIds[userAddress].length();
        }
        Borrow[] memory returnedBorrows;

        uint256 j;
        uint256 i;
        for (; i < toPosition - fromPosition; i++) {
            returnedBorrows[j] = borrows[i];
            unchecked {
                i++;
                j++;
            }
        }
        return returnedBorrows;
    }

    /// @notice Get list of deals by specified borrow
    /// @param borrowId The id of the borrows
    /// @param fromPosition Limitatin/pagination purpose parameter
    /// @param toPosition Limitatin/pagination purpose parameter
    /// @return Deals by borrow
    function getDealsByBorrow(
        uint256 borrowId,
        uint256 fromPosition,
        uint256 toPosition
    ) public view returns (Deal[] memory) {
        require(fromPosition < toPosition, "Incorrect positions");

        if (_dealIds[borrowId].length() < toPosition) {
            toPosition = _dealIds[borrowId].length();
        }
        Deal[] memory returnedDeals;

        uint256 j;
        uint256 i;
        for (; i < toPosition - fromPosition; i++) {
            returnedDeals[j] = deals[i];
            unchecked {
                i++;
                j++;
            }
        }
        return returnedDeals;
    }
}