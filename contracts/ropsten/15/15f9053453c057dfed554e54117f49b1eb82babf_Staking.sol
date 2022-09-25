/**
 *Submitted for verification at Etherscan.io on 2022-09-25
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)



// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)



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
}// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)



// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)



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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)



// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)



/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)



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
interface IGum {
    function mint(address, uint256) external;

    function decimals() external returns (uint8);
}

error NotStarted();
error TokenNotDeposited();
error UnknownBGContract();

/**
 * @notice Accept deposits of Bubblegum Kid and Bubblegum Puppy NFTs
 * ("staking") in exchange for GUM token rewards. Thanks to the Sappy Seals team:
 * this contract is largely based on their staking contract at
 * 0xdf8A88212FF229446e003f8f879e263D3616b57A.
 * @dev Contract defines a "day" as 7200 ethereum blocks.
 */
contract Staking is ERC721Holder, Ownable {
    using EnumerableSet for EnumerableSet.UintSet;

    address public constant BGK = 0xf48415039913DBdF17e337e681de922A9cb04010;
    address public constant BGP = 0xeb856faBa11a7590Cb347816Db8F8C08D30FB0fA;
    enum BGContract {
        BGK,
        BGP
    }

    uint256 public constant GUM_TOKEN_DECIMALS = 18;

    address public gumToken;

    bool public started;

    mapping(address => mapping(BGContract => EnumerableSet.UintSet))
        private _deposits;
    mapping(BGContract => mapping(uint256 => uint256)) public depositBlocks;
    uint256 public stakeRewardRate;

    event GumTokenUpdated(address _gumToken);
    event Started();
    event Stopped();
    event Deposited(address from, uint256[] tokenIds, uint8[] bgContracts);
    event Withdrawn(address to, uint256[] tokenIds, uint8[] bgContracts);
    event StakeRewardRateUpdated(uint256 _stakeRewardRate);
    event RewardClaimed(address to, uint256 amount);

    constructor(address _gumToken) {
        gumToken = _gumToken;
        stakeRewardRate = 1;
        started = false;
    }

    modifier onlyStarted() {
        if (!started) revert NotStarted();
        _;
    }

    function start() public onlyOwner {
        started = true;
        emit Started();
    }

    function stop() public onlyOwner {
        started = false;
        emit Stopped();
    }

    function unsafe_inc(uint256 x) private pure returns (uint256) {
        unchecked {
            return x + 1;
        }
    }

    /**
     * @dev Change the address of the reward token contract (must
     * support ERC20 functions named in IGum interface and conform
     * to hardcoded GUM_TOKEN_DECIMALS constant).
     */
    function updateGumToken(address _gumToken) public onlyOwner {
        gumToken = _gumToken;
        emit GumTokenUpdated(_gumToken);
    }

    function updateStakeRewardRate(uint256 _stakeRewardRate) public onlyOwner {
        stakeRewardRate = _stakeRewardRate;
        emit StakeRewardRateUpdated(_stakeRewardRate);
    }

    /**
     * @dev Mint GUM token rewards
     * @param to The recipient's ethereum address
     * @param amount The amount to mint
     */
    function _reward(address to, uint256 amount) internal {
        IGum(gumToken).mint(to, amount);
    }

    /**
     * @dev Calculate accrued GUM token rewards for a given
     * BGK or BGP NFT
     * @param account The user's ethereum address
     * @param tokenId The NFT's id
     * @param _bgContract Kids (0) or Puppies (1)
     * @return rewards
     */
    function getRewardsForToken(
        address account,
        uint256 tokenId,
        uint8 _bgContract
    ) internal view returns (uint256) {
        BGContract bgContract = BGContract(_bgContract);
        // the user has not staked this nft
        if (!_deposits[account][bgContract].contains(tokenId)) {
            return 0;
        }
        // when was the NFT deposited?
        uint256 depositBlock = depositBlocks[bgContract][tokenId];
        // how many days have elapsed since the NFT was deposited or
        // rewards were claimed?
        uint256 depositDaysElapsed = (block.number - depositBlock) / 7200;
        return stakeRewardRate * depositDaysElapsed * 10**GUM_TOKEN_DECIMALS;
    }

    /**
     * @dev Calculate accrued GUM token rewards for a set
     * of BGK and BGP NFTs
     * @param account The user's ethereum address
     * @param tokenIds The NFTs' ids
     * @param bgContracts The NFTs' contracts -- Kids (0)
     * or Puppies (1) -- with indices corresponding to those
     * of `tokenIds`
     * @return rewards
     */
    function calculateRewards(
        address account,
        uint256[] calldata tokenIds,
        uint8[] calldata bgContracts
    ) public view returns (uint256[] memory rewards) {
        rewards = new uint256[](tokenIds.length);
        for (uint256 i; i < tokenIds.length; i = unsafe_inc(i)) {
            rewards[i] = getRewardsForToken(
                account,
                tokenIds[i],
                bgContracts[i]
            );
        }
    }

    /**
     * @dev Claim accrued GUM token rewards for all
     * staked BGK and BGP NFTs -- if caller's rewards are
     * greater than 0, balance will be transferred to
     * caller's address
     */
    function claimRewards() public {
        address account = msg.sender;
        uint256 amount;
        for (uint8 i; i < 2; i++) {
            BGContract bgContract = BGContract(i);
            for (
                uint256 j;
                j < _deposits[account][bgContract].length();
                j = unsafe_inc(j)
            ) {
                uint256 tokenId = _deposits[account][bgContract].at(j);
                uint256 thisAmount = (getRewardsForToken(account, tokenId, i));
                if (thisAmount > 0) {
                    amount += thisAmount;
                    depositBlocks[bgContract][tokenId] = block.number;
                }
            }
        }
        if (amount > 0) {
            _reward(account, amount);
            emit RewardClaimed(account, amount);
        }
    }

    /**
     * @dev Deposit ("stake") a set of BGK and BGP NFTs. Caller
     * must be the owner of the NFTs supplied as arguments.
     * @param tokenIds The NFTs' ids
     * @param bgContracts The NFTs' contracts -- Kids (0)
     * or Puppies (1) -- with indices corresponding to those
     * of `tokenIds`
     */
    function deposit(uint256[] calldata tokenIds, uint8[] calldata bgContracts)
        external
        onlyStarted
    {
        address account = msg.sender;
        for (uint256 i; i < tokenIds.length; i = unsafe_inc(i)) {
            uint256 tokenId = tokenIds[i];
            BGContract bgContract = BGContract(bgContracts[i]);
            address bgContractAddress;
            if (bgContract == BGContract.BGK) {
                bgContractAddress = BGK;
            } else if (bgContract == BGContract.BGP) {
                bgContractAddress = BGP;
            } else {
                revert UnknownBGContract();
            }
            IERC721(bgContractAddress).safeTransferFrom(
                account,
                address(this),
                tokenId,
                ""
            );
            _deposits[account][bgContract].add(tokenId);
            depositBlocks[bgContract][tokenId] = block.number;
        }
        emit Deposited(account, tokenIds, bgContracts);
    }

    /**
     * @dev Withdraw ("unstake") a set of deposited BGK and BGP
     * NFTs. Calling `withdraw` automatically claims accrued
     * rewards on the NFTs supplied as arguments. Caller must
     * have deposited the NFTs.
     * @param tokenIds The NFTs' ids
     * @param bgContracts The NFTs' contracts -- Kids (0)
     * or Puppies (1) -- with indices corresponding to those
     * of `tokenIds`
     */
    function withdraw(uint256[] calldata tokenIds, uint8[] calldata bgContracts)
        external
    {
        claimRewards();
        address account = msg.sender;
        for (uint256 i; i < tokenIds.length; i = unsafe_inc(i)) {
            uint256 tokenId = tokenIds[i];
            BGContract bgContract = BGContract(bgContracts[i]);
            if (!_deposits[account][bgContract].contains(tokenId)) {
                revert TokenNotDeposited();
            }
            _deposits[account][bgContract].remove(tokenId);
            address nftAddress;
            if (bgContract == BGContract.BGK) {
                nftAddress = BGK;
            } else if (bgContract == BGContract.BGP) {
                nftAddress = BGP;
            } else {
                revert UnknownBGContract();
            }
            IERC721(nftAddress).safeTransferFrom(
                address(this),
                account,
                tokenId,
                ""
            );
        }
        emit Withdrawn(account, tokenIds, bgContracts);
    }

    /**
     * @dev Get the ids of Kid and Puppy NFTs staked by the
     * user supplied in the `account` argument
     * @param account The depositor's ethereum address
     * @return bgContracts The ids of the deposited NFTs,
     * as an array: the first item is an array of Kid ids,
     * the second an array of Pup ids
     */
    function depositsOf(address account)
        external
        view
        returns (uint256[][2] memory)
    {
        EnumerableSet.UintSet storage bgkDepositSet = _deposits[account][
            BGContract.BGK
        ];
        uint256[] memory bgkIds = new uint256[](bgkDepositSet.length());
        for (uint256 i; i < bgkDepositSet.length(); i = unsafe_inc(i)) {
            bgkIds[i] = bgkDepositSet.at(i);
        }
        EnumerableSet.UintSet storage bgpDepositSet = _deposits[account][
            BGContract.BGP
        ];
        uint256[] memory bgpIds = new uint256[](bgpDepositSet.length());
        for (uint256 i; i < bgpDepositSet.length(); i = unsafe_inc(i)) {
            bgpIds[i] = bgpDepositSet.at(i);
        }
        return [bgkIds, bgpIds];
    }
}