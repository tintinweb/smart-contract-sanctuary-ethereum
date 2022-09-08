/**
 *Submitted for verification at Etherscan.io on 2022-09-08
*/

// File: contracts/interfaces/ICryptoPageCommunity.sol



pragma solidity 0.8.15;

interface IPageCommunity {

    function version() external pure returns (string memory);

    function addCommunity(string memory desc) external;

    function readCommunity(uint256 communityId) external view returns(
        string memory name,
        address creator,
        address[] memory moderators,
        uint256[] memory postIds,
        address[] memory users,
        address[] memory bannedUsers,
        uint256 usersCount,
        bool isActive,
        bool isPrivate,
        bool isPostOwner
    );

    function getCommunityDaysInCommunityToVote(uint256 communityId) external view returns (uint256);

    function getCommunityUpPostsInCommunityToVote(uint256 communityId) external view returns (uint256);

    function addModerator(uint256 communityId, address moderator) external;

    function removeModerator(uint256 communityId, address moderator) external;

    function setPostOwner(uint256 communityId) external;

    function transferPost(uint256 communityId, uint256 postId, address wallet) external returns(bool);

    function addBannedUser(uint256 communityId, address user) external;

    function removeBannedUser(uint256 communityId, address user) external;

    function join(uint256 communityId) external;

    function quit(uint256 communityId) external;

    function writePost(
        uint256 communityId,
        string memory ipfsHash,
        address _owner
    ) external;

    function readPost(uint256 postId) external view returns(
        string memory ipfsHash,
        address creator,
        uint64 upCount,
        uint64 downCount,
        uint256 price,
        uint256 commentCount,
        address[] memory upDownUsers,
        bool isView
    );

    function burnPost(uint256 postId) external;

    function setPostVisibility(uint256 postId, bool newVisible) external;

    function changeCommunityActive(uint256 communityId) external;

    function setCommunityPrivate(uint256 communityId, bool newPrivate) external;

    function getPostPrice(uint256 postId) external view returns (uint256);

    function getPostsIdsByCommunityId(uint256 communityId) external view returns (uint256[] memory);

    function writeComment(
        uint256 postId,
        string memory ipfsHash,
        bool isUp,
        bool isDown,
        address _owner
    ) external;

    function readComment(uint256 postId, uint256 commentId) external view returns(
        string memory ipfsHash,
        address creator,
        address _owner,
        uint256 price,
        bool isUp,
        bool isDown,
        bool isView
    );

    function burnComment(uint256 postId, uint256 commentId) external;

    function setCommunityUpPostsInCommunityToVote(uint256 communityId, uint256 newUpPostsInCommunityToVote) external;

    function setCommunityDaysInCommunityToVote(uint256 communityId, uint256 newDaysInCommunityToVote) external;

    function setVisibilityComment(
        uint256 postId,
        uint256 commentId,
        bool newVisible
    ) external;

    function setMaxModerators(uint256 newValue) external;

    function setDefaultDaysInCommunityToVote(uint256 newValue) external;

    function setDefaultUpPostsInCommunityToVote(uint256 newValue) external;

    function addVoterContract(address newContract) external;

    function changeSupervisor(address newUser) external;

    function getCommentCount(uint256 postId) external view returns(uint256);

    function isCommunityCreator(uint256 communityId, address user) external view returns(bool);

    function isCommunityActiveUser(uint256 communityId, address user) external returns(bool);

    function isCommunityJoinedUser(uint256 communityId, address user) external returns(bool);

    function isCommunityPostOwner(uint256 communityId) external view returns(bool);

    function isBannedUser(uint256 communityId, address user) external view returns(bool);

    function isCommunityModerator(uint256 communityId, address user) external view returns(bool);

    function getCommunityIdByPostId(uint256 postId) external view returns(uint256);

    function OPEN_FORUM_ID() external returns(uint256);

    function isUpDownUser(uint256 postId, address user) external view returns(bool);

    function isActiveCommunity(uint256 communityId) external view returns(bool);

    function isActiveCommunityByPostId(uint256 postId) external view returns(bool);

    function isPrivateCommunity(uint256 communityId) external view returns(bool);

    function isEligibleToVoting(uint256 communityId, address user) external view returns(bool);
}

// File: contracts/interfaces/ICryptoPageBank.sol



pragma solidity 0.8.15;

interface IPageBank {

    function version() external pure returns (string memory);

    function definePostFeeForNewCommunity(uint256 communityId) external returns(bool);

    function readPostFee(uint256 communityId) external view returns(
        uint64 createPostOwnerFee,
        uint64 createPostCreatorFee,
        uint64 removePostOwnerFee,
        uint64 removePostCreatorFee
    );

    function defineCommentFeeForNewCommunity(uint256 communityId) external returns(bool);

    function readCommentFee(uint256 communityId) external view returns(
        uint64 createCommentOwnerFee,
        uint64 createCommentCreatorFee,
        uint64 removeCommentOwnerFee,
        uint64 removeCommentCreatorFee
    );

    function updatePostFee(
        uint256 communityId,
        uint64 newCreatePostOwnerFee,
        uint64 newCreatePostCreatorFee,
        uint64 newRemovePostOwnerFee,
        uint64 newRemovePostCreatorFee
    ) external;

    function updateCommentFee(
        uint256 communityId,
        uint64 newCreateCommentOwnerFee,
        uint64 newCreateCommentCreatorFee,
        uint64 newRemoveCommentOwnerFee,
        uint64 newRemoveCommentCreatorFee
    ) external;


    function mintTokenForNewPost(
        uint256 communityId,
        address _owner,
        address creator,
        uint256 gas,
        bool mintOwnerTokensToCommunityBalance
    ) external returns (uint256 amount);

    function mintTokenForNewComment(
        uint256 communityId,
        address _owner,
        address creator,
        uint256 gas
    ) external returns (uint256 amount);

    function addUpDownActivity(
        uint256 communityId,
        address postCreator,
        bool isUp
    ) external;

    function burnTokenForPost(
        uint256 communityId,
        address _owner,
        address creator,
        uint256 gas
    ) external returns (uint256 amount);

    function burnTokenForComment(
        uint256 communityId,
        address _owner,
        address creator,
        uint256 gas
    ) external returns (uint256 amount);

    function withdraw(uint256 amount) external;

    function addBalance(uint256 amount) external;

    function setPriceForPrivacyAccess(uint256 communityId, uint256 newValue) external;

    function transferFromCommunity(uint256 communityId, uint256 amount, address wallet) external returns(bool);

    function payForPrivacyAccess(uint256 amount, uint256 communityId) external;

    function balanceOf(address user) external view returns (uint256);

    function balanceOfCommunity(uint256 communityId) external view returns (uint256);

    function setDefaultFee(uint256 index, uint64 newValue) external;

    function setMintGasAmount(uint256 newValue) external;

    function setBurnGasAmount(uint256 newValue) external;

    function setMaxPostCreateFee(uint256 newValue) external;

    function MAX_POST_CREATE_FEE() external view returns (uint256);

    function setMaxCommentCreateFee(uint256 newValue) external;

    function MAX_COMMENT_CREATE_FEE() external view returns (uint256);

    function setOracle(address newOracle) external;

    function setToken(address newToken) external;

    function setTreasuryFee(uint256 newTreasuryFee ) external;

    function isPrivacyAvailable(address user, uint256 communityId) external view returns(bool);

}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/v4.5.1/contracts/utils/structs/EnumerableSetUpgradeable.sol


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
library EnumerableSetUpgradeable {
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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/v4.5.1/contracts/utils/introspection/IERC165Upgradeable.sol


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
interface IERC165Upgradeable {
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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/v4.5.1/contracts/token/ERC721/IERC721Upgradeable.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/v4.5.1/contracts/token/ERC721/extensions/IERC721EnumerableUpgradeable.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;


/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721EnumerableUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// File: contracts/interfaces/ICryptoPageNFT.sol



pragma solidity 0.8.15;


interface IPageNFT is IERC721EnumerableUpgradeable {

    function version() external pure returns (string memory);

    function setCommunity(address communityContract) external;

    function setBaseTokenURI(string memory baseTokenURI) external;

    function mint(address owner, string memory ipfsHash) external returns (uint256);

    function burn(uint256 tokenId) external;

    function ipfsHashOf(uint256 tokenId) external view returns (string memory);

    function tokensOfOwner(address user) external view returns (uint256[] memory);

    function approveTransfer(address from, address to, uint256 tokenId) external;

    function disapproveTransfer(address from, address to, uint256 tokenId) external;

    function transferVoting(address from, address to, uint256 tokenId) external;

}


// File: https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/v4.5.1/contracts/utils/StringsUpgradeable.sol


// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/v4.5.1/contracts/access/IAccessControlUpgradeable.sol


// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/v4.5.1/contracts/utils/AddressUpgradeable.sol


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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/v4.5.1/contracts/proxy/utils/Initializable.sol


// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;


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
        return !AddressUpgradeable.isContract(address(this));
    }
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/v4.5.1/contracts/utils/introspection/ERC165Upgradeable.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;



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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/v4.5.1/contracts/utils/ContextUpgradeable.sol


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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/v4.5.1/contracts/access/AccessControlUpgradeable.sol


// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;






/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/v4.5.1/contracts/access/OwnableUpgradeable.sol


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

// File: contracts/CryptoPageCommunity.sol



pragma solidity 0.8.15;








     /**
     * @dev The contract for manage community
     *
     */
contract PageCommunity is
    Initializable,
    OwnableUpgradeable,
    AccessControlUpgradeable,
    IPageCommunity
{
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

    IPageNFT public nft;
    IPageBank public bank;

    uint256 public MAX_MODERATORS;
    string constant EMPTY_STRING = '';

    address public supervisor;
    address[] public voterContracts;

    uint256 public communityCount;

    uint256 constant public OPEN_FORUM_ID = 1;
    uint256 public DEFAULT_DAYS_IN_COMMUNITY_TO_VOTE;
    uint256 public DEFAULT_UP_POSTS_IN_COMMUNITY_TO_VOTE;

    struct Community {
        string name;
        address creator;
        EnumerableSetUpgradeable.AddressSet moderators;
        EnumerableSetUpgradeable.UintSet postIds;
        EnumerableSetUpgradeable.AddressSet users;
        EnumerableSetUpgradeable.AddressSet bannedUsers;
        mapping(address => uint256) userJoiningTime;
        mapping(address => EnumerableSetUpgradeable.UintSet) userUpPostIds;
        uint256 usersCount;
        bool isActive;
        bool isPrivate;
        bool isPostOwner;
        uint256 daysInCommunityToVote;
        uint256 upPostsInCommunityToVote;
        uint256 creationTime;
    }

    struct Post {
        address creator;
        uint64 upCount;
        uint64 downCount;
        uint256 price;
        uint256 commentCount;
        EnumerableSetUpgradeable.AddressSet upDownUsers;
        bool isView;
    }

    struct Comment {
        string ipfsHash;
        address creator;
        address owner;
        bool isUp;
        bool isDown;
        uint256 price;
        bool isView;
    }

    mapping(uint256 => Community) private community;

    //postId -> Post
    mapping(uint256 => Post) private post;
    //postId -> communityId
    mapping(uint256 => uint256) private communityIdByPostId;
    //postId -> commentId -> Comment
    mapping(uint256 => mapping(uint256 => Comment)) private comment;


    event AddedCommunity(address indexed creator, uint256 indexed number, string name, uint256 time);

    event AddedModerator(address indexed admin, uint256 number, address moderator);
    event RemovedModerator(address indexed admin, uint256 number, address moderator);
    event SetPostOwner(address indexed admin, uint256 communityId, bool isCommunity);

    event AddedBannedUser(address indexed admin, uint256 number, address user);
    event RemovedBannedUser(address indexed admin, uint256 number, address user);

    event JoinUser(uint256 indexed communityId, address user);
    event QuitUser(uint256 indexed communityId, address user);

    event WritePost(uint256 indexed communityId, uint256 postId, address indexed creator, address indexed owner);
    event BurnPost(uint256 indexed communityId, uint256 postId, address creator, address owner);
    event ChangePostVisible(uint256 indexed communityId, uint256 postId, bool isVisible);
    event ChangeCommunityActive(uint256 indexed communityId, bool isActive);
    event ChangeCommunityPrivate(uint256 indexed communityId, bool isPrivate);
    event ChangeCommunityDaysInCommunityToVote(uint256 indexed communityId, uint256 daysInCommunityToVote);
    event ChangeCommunityUpPostsInCommunityToVote(uint256 indexed communityId, uint256 upPostsInCommunityToVote);

    event WriteComment(uint256 indexed communityId, uint256 indexed postId, uint256 commentId, address indexed creator, address owner);
    event BurnComment(uint256 indexed communityId, uint256 postId, uint256 commentId, address creator, address owner);
    event ChangeVisibleComment(uint256 indexed communityId, uint256 postId, uint256 commentId, bool isVisible);

    event SetMaxModerators(uint256 oldValue, uint256 newValue);
    event ChangeSupervisor(address oldValue, address newValue);
    event SetDefaultDaysInCommunityToVote(uint256 oldValue, uint256 newValue);
    event SetDefaultUpPostsInCommunityToVote(uint256 oldValue, uint256 newValue);

    modifier validCommunityId(uint256 id) {
        validateCommunity(id);
        require(isActiveCommunity(id), "PageCommunity: wrong active community");
        _;
    }

    modifier onlyCommunityUser(uint256 id) {
        validateCommunity(id);
        require(isCommunityActiveUser(id, _msgSender()), "PageCommunity: wrong user");
        _;
    }

    modifier onlyVoterContract(uint256 id) {
        require(_msgSender() == voterContracts[id], "PageCommunity: wrong user");
        _;
    }

    modifier onlyCommunityActiveByPostId(uint256 postId) {
        require(isActiveCommunityByPostId(postId), "PageCommunity: wrong active community by post ID");
        _;
    }

     /**
     * @dev check that the address passed is not 0.
     */
    modifier notAddress0(address _address) {
        require(_address != address(0), "PageCommunity: Address 0 is not valid");
        _;
    }

    /**
     * @dev Makes the initialization of the initial values for the smart contract
     *
     * @param _nft NFT contract address
     * @param _bank Bank contract address
     * @param _admin Address of admin
     */
    function initialize(address _nft, address _bank, address _admin) external initializer {
        require(_nft != address(0), "PageCommunity: Wrong _nft address");
        require(_bank != address(0), "PageCommunity: Wrong _bank address");
        require(_admin != address(0), "PageCommunity: Wrong _admin address");

        __Ownable_init();
        nft = IPageNFT(_nft);
        bank = IPageBank(_bank);

        _setupRole(DEFAULT_ADMIN_ROLE, _admin);

        DEFAULT_DAYS_IN_COMMUNITY_TO_VOTE = 30;
        DEFAULT_UP_POSTS_IN_COMMUNITY_TO_VOTE = 2;
        MAX_MODERATORS = 40;

        communityCount = OPEN_FORUM_ID;
        Community storage newCommunity = community[OPEN_FORUM_ID];
        require(bank.definePostFeeForNewCommunity(OPEN_FORUM_ID), "PageCommunity: wrong define post fee");
        require(bank.defineCommentFeeForNewCommunity(OPEN_FORUM_ID), "PageCommunity: wrong define comment fee");
        newCommunity.creator = address(0);
        newCommunity.isActive = true;
        newCommunity.name = "Open forum";
        newCommunity.creationTime = block.timestamp;

        emit AddedCommunity(address(0), OPEN_FORUM_ID, newCommunity.name, newCommunity.creationTime);
    }

    /**
     * @dev Returns the smart contract version
     *
     */
    function version() external pure override returns (string memory) {
        return "1";
    }

    /**
     * @dev Accepts ether to the balance of the contract
     * Required for testing
     *
     */
    receive() external payable {
        // React to receiving ether
        // Uncomment for production
        //revert("PageBank: asset transfer prohibited");
    }

    /**
     * @dev Creates a new community.
     *
     * @param desc Text description for the community
     */
    function addCommunity(string memory desc) external override {
        communityCount++;
        Community storage newCommunity = community[communityCount];
        newCommunity.creator = _msgSender();
        newCommunity.isActive = true;
        newCommunity.name = desc;
        newCommunity.daysInCommunityToVote = DEFAULT_DAYS_IN_COMMUNITY_TO_VOTE;
        newCommunity.upPostsInCommunityToVote = DEFAULT_UP_POSTS_IN_COMMUNITY_TO_VOTE;
        newCommunity.creationTime = block.timestamp;

        require(bank.definePostFeeForNewCommunity(communityCount), "PageCommunity: wrong define post fee");
        require(bank.defineCommentFeeForNewCommunity(communityCount), "PageCommunity: wrong define comment fee");


        emit AddedCommunity(_msgSender(), communityCount, desc, block.timestamp);

        join(communityCount);
    }

    /**
     * @dev Returns information about the community.
     *
     * @param communityId ID of community
     */
    function readCommunity(uint256 communityId) external view override validCommunityId(communityId) returns(
        string memory name,
        address creator,
        address[] memory moderators,
        uint256[] memory postIds,
        address[] memory users,
        address[] memory bannedUsers,
        uint256 usersCount,
        bool isActive,
        bool isPrivate,
        bool isPostOwner
    ) {

        Community storage currentCommunity = community[communityId];

        name = currentCommunity.name;
        creator = currentCommunity.creator;
        moderators = currentCommunity.moderators.values();
        postIds = currentCommunity.postIds.values();
        users = currentCommunity.users.values();
        bannedUsers = currentCommunity.bannedUsers.values();
        usersCount = currentCommunity.usersCount;
        isActive = currentCommunity.isActive;
        isPrivate = currentCommunity.isPrivate;
        isPostOwner = currentCommunity.isPostOwner;
    }

    function getCommunityDaysInCommunityToVote(uint256 communityId) external view override validCommunityId(communityId) returns (uint256) {
        Community storage currentCommunity = community[communityId];
        return currentCommunity.daysInCommunityToVote;
    }

    function getCommunityUpPostsInCommunityToVote(uint256 communityId) external view override validCommunityId(communityId) returns (uint256) {
        Community storage currentCommunity = community[communityId];
        return currentCommunity.upPostsInCommunityToVote;
    }

    /**
     * @dev Adds a moderator for the community.
     * Can only be done by voting.
     *
     * @param communityId ID of community
     * @param moderator User address
     */
    function addModerator(uint256 communityId, address moderator) external override validCommunityId(communityId) onlyVoterContract(0) {
        Community storage currentCommunity = community[communityId];

        require(communityId != OPEN_FORUM_ID, "PageCommunity: Wrong community");
        require(moderator != address(0), "PageCommunity: Wrong moderator");
        require(currentCommunity.moderators.length() < MAX_MODERATORS, "PageCommunity: The limit on the number of moderators");
        require(isCommunityActiveUser(communityId, moderator), "PageCommunity: wrong user");

        currentCommunity.moderators.add(moderator);
        emit AddedModerator(_msgSender(), communityId, moderator);
    }

    /**
     * @dev Removes a moderator for the community.
     * Can only be done by voting.
     *
     * @param communityId ID of community
     * @param moderator User address
     */
    function removeModerator(uint256 communityId, address moderator) external override validCommunityId(communityId) onlyVoterContract(0) notAddress0(moderator){
        Community storage currentCommunity = community[communityId];

        require(isCommunityModerator(communityId, moderator), "PageCommunity: wrong moderator");

        currentCommunity.moderators.remove(moderator);
        emit RemovedModerator(_msgSender(), communityId, moderator);
    }

    /**
     * @dev Sets a new status for the community.
     * Can only be done by voting.
     *
     * @param communityId ID of community
     */
    function setPostOwner(uint256 communityId) external override validCommunityId(communityId) onlyVoterContract(0) {
        Community storage currentCommunity = community[communityId];
        bool newValue = !currentCommunity.isPostOwner;
        currentCommunity.isPostOwner = newValue;
        if(!currentCommunity.users.contains(address(this))) {
            currentCommunity.users.add(address(this));
            currentCommunity.usersCount++;
            community[communityId].userJoiningTime[address(this)] = block.timestamp;
        }
        emit SetPostOwner(_msgSender(), communityId, newValue);
    }

    /**
     * @dev Transfers post.
     * Can only be done by voting.
     *
     * @param communityId ID of community
     */
    function transferPost(uint256 communityId, uint256 postId, address wallet)
        external override validCommunityId(communityId) onlyVoterContract(1) returns(bool)
    {
        Community storage currentCommunity = community[communityId];
        require(wallet != address(0), "PageCommunity: wrong wallet");
        require(nft.ownerOf(postId) == address(this), "PageCommunity: wrong owner");
        require(community[communityId].postIds.contains(postId), "PageCommunity: wrong postId");

        nft.transferVoting(address(this), wallet, postId);
        return true;
    }

    /**
     * @dev Adds a banned user for the community.
     * Can only be done by moderator.
     *
     * @param communityId ID of community
     * @param user User address
     */
    function addBannedUser(uint256 communityId, address user) external override notAddress0(user) validCommunityId(communityId) {
        Community storage currentCommunity = community[communityId];

        require(isCommunityModerator(communityId, _msgSender()), "PageCommunity: access denied");
        require(isCommunityActiveUser(communityId, user), "PageCommunity: wrong user");
        // We are not checking for above code takes care of it
        // require(!isBannedUser(communityId, user), "PageCommunity: user is already banned");

        currentCommunity.bannedUsers.add(user);
        emit AddedBannedUser(_msgSender(), communityId, user);
    }

    /**
     * @dev Removes a banned user for the community.
     * Can only be done by moderator.
     *
     * @param communityId ID of community
     * @param user User address
     */
    function removeBannedUser(uint256 communityId, address user) external override validCommunityId(communityId) notAddress0(user) {
        Community storage currentCommunity = community[communityId];

        require(isCommunityModerator(communityId, _msgSender()), "PageCommunity: access denied");
        require(isBannedUser(communityId, user), "PageCommunity: user is not banned");

        currentCommunity.bannedUsers.remove(user);
        emit RemovedBannedUser(_msgSender(), communityId, user);
    }

    /**
     * @dev Entry of a new user into the community.
     *
     * @param communityId ID of community
     */
    function join(uint256 communityId) public override validCommunityId(communityId) {
        require(!isCommunityJoinedUser(communityId,_msgSender()),"PageCommunity: user already in the community");
        require(communityId != OPEN_FORUM_ID,"PageCommunity: wrong community");
        community[communityId].users.add(_msgSender());
        community[communityId].usersCount++;
        community[communityId].userJoiningTime[_msgSender()] = block.timestamp;
        emit JoinUser(communityId, _msgSender());
    }

    /**
     * @dev Exit of a user from the community.
     *
     * @param communityId ID of community
     */
    function quit(uint256 communityId) external override validCommunityId(communityId) {
        require(isCommunityJoinedUser(communityId,_msgSender()),"PageCommunity: wrong user");
        require(communityId != OPEN_FORUM_ID,"PageCommunity: wrong community");
        community[communityId].users.remove(_msgSender());
        community[communityId].usersCount--;
        emit QuitUser(communityId, _msgSender());
    }

    /**
     * @dev Create a new community post.
     *
     * @param communityId ID of community
     * @param ipfsHash Link to the message in IPFS
     * @param _owner Post owner address
     */
    function writePost(
        uint256 communityId,
        string memory ipfsHash,
        address _owner
    ) external override validCommunityId(communityId) onlyCommunityUser(communityId) notAddress0(_owner) {
        uint256 gasBefore = gasleft();
        bool mintToCommunityBalance = false;
        if (isCommunityPostOwner(communityId)) {
            _owner = address(this);
            mintToCommunityBalance = true;
        }
        // We are not checking for onlyCommunityUser as modifier takes care of it
        // require(isCommunityActiveUser(communityId, _msgSender()), "PageCommunity: wrong user");
        require(isCommunityActiveUser(communityId, _owner), "PageCommunity: wrong user");
        require(isPrivacyAccess(_msgSender(), communityId), "PageCommunity: wrong time for privacy access");

        uint256 postId = nft.mint(_owner, ipfsHash);

        createPost(postId);

        community[communityId].postIds.add(postId);
        communityIdByPostId[postId] = communityId;
        emit WritePost(communityId, postId, _msgSender(), _owner);

        uint256 gas = gasBefore - gasleft();
        uint256 price = bank.mintTokenForNewPost(communityId, _owner, _msgSender(), gas, mintToCommunityBalance);
        setPostPrice(postId, price);
    }

    /**
     * @dev Returns information about the post.
     *
     * @param postId ID of post
     */
    function readPost(uint256 postId) external view override onlyCommunityActiveByPostId(postId) returns(
        string memory ipfsHash,
        address creator,
        uint64 upCount,
        uint64 downCount,
        uint256 price,
        uint256 commentCount,
        address[] memory upDownUsers,
        bool isView
    ) {
        if(isPrivacyAccess(_msgSender(), getCommunityIdByPostId(postId))) {
            Post storage readed = post[postId];
            ipfsHash = nft.ipfsHashOf(postId);
            creator = readed.creator;
            upCount = readed.upCount;
            downCount = readed.downCount;
            price = readed.price;
            commentCount = readed.commentCount;
            upDownUsers = readed.upDownUsers.values();
            isView = readed.isView;
        }
    }

    /**
     * @dev Removes information about the post.
     *
     * @param postId ID of post
     */
    function burnPost(uint256 postId) external override onlyCommunityActiveByPostId(postId) {
        uint256 gasBefore = gasleft();
        uint256 communityId = getCommunityIdByPostId(postId);
        address postOwner = nft.ownerOf(postId);

        require(isCommunityActiveUser(communityId, _msgSender()) , "PageCommunity: wrong user");
        require(community[communityId].postIds.contains(postId), "PageCommunity: wrong post");
        require(postOwner == _msgSender(), "PageCommunity: wrong owner");

        nft.burn(postId);
        erasePost(postId);
        communityIdByPostId[postId] = 0;
        community[communityId].postIds.remove(postId);

        emit BurnPost(communityId, postId, _msgSender(), postOwner);

        uint256 gas = gasBefore - gasleft();
        bank.burnTokenForPost(communityId, postOwner, _msgSender(), gas);
    }

    /**
     * @dev Change post visibility.
     *
     * @param postId ID of post
     * @param newVisible Boolean value for post visibility
     */
    function setPostVisibility(uint256 postId, bool newVisible) external override onlyCommunityActiveByPostId(postId) {
        uint256 communityId = getCommunityIdByPostId(postId);
        require(isCommunityModerator(communityId, _msgSender()) || _msgSender() == supervisor, "PageCommunity: access denied");
        require(community[communityId].postIds.contains(postId), "PageCommunity: wrong post");
        require(isPrivacyAccess(_msgSender(), communityId), "PageCommunity: wrong time for privacy access");

        bool oldVisible = post[postId].isView;
        require(oldVisible != newVisible, "PageCommunity: wrong new visible");
        post[postId].isView = newVisible;

        emit ChangePostVisible(communityId, postId, newVisible);
    }

    /**
     * @dev Change community active.
     *
     * @param communityId ID of community
     */
    function changeCommunityActive(uint256 communityId) external override {
        require(supervisor == _msgSender() || voterContracts[0] == _msgSender(), "PageCommunity: wrong super user");

        bool oldActive = community[communityId].isActive;
        bool newActive = !oldActive;
        community[communityId].isActive = newActive;

        emit ChangeCommunityActive(communityId, newActive);
    }

    /**
     * @dev Change community private.
     *
     * @param communityId ID of community
     * @param newPrivate Boolean value for community private
     */
    function setCommunityPrivate(uint256 communityId, bool newPrivate) external override validCommunityId(communityId) {
        require(communityId != OPEN_FORUM_ID, "PageCommunity: wrong community");
        require(isCommunityModerator(communityId, _msgSender())
            || _msgSender() == community[communityId].creator, "PageCommunity: access denied");

        bool oldPrivate = community[communityId].isPrivate;
        require(oldPrivate != newPrivate, "PageCommunity: wrong new private status");
        community[communityId].isPrivate = newPrivate;

        emit ChangeCommunityPrivate(communityId, newPrivate);
    }

    /**
     * @dev Change community daysInCommunityToVote.
     *
     * @param communityId ID of community
     * @param newDaysInCommunityToVote new value for community daysInCommunityToVote
     */
    function setCommunityDaysInCommunityToVote(uint256 communityId, uint256 newDaysInCommunityToVote) public validCommunityId(communityId) {
        require(supervisor == _msgSender() || voterContracts[0] == _msgSender(), "PageCommunity: wrong supervisor");

        uint256 oldDaysInCommunityToVote = community[communityId].daysInCommunityToVote;
        require(oldDaysInCommunityToVote != newDaysInCommunityToVote, "PageCommunity: wrong new daysInCommunityToVote");
        community[communityId].daysInCommunityToVote = newDaysInCommunityToVote;

        emit ChangeCommunityDaysInCommunityToVote(communityId, newDaysInCommunityToVote);
    }

    /**
     * @dev Change community upPostsInCommunityToVote.
     *
     * @param communityId ID of community
     * @param newUpPostsInCommunityToVote new value for community upPostsInCommunityToVote
     */
    function setCommunityUpPostsInCommunityToVote(uint256 communityId, uint256 newUpPostsInCommunityToVote) public validCommunityId(communityId) {
        require(supervisor == _msgSender() || voterContracts[0] == _msgSender(), "PageCommunity: wrong supervisor");

        uint256 oldUpPostsInCommunityToVote = community[communityId].upPostsInCommunityToVote;
        require(oldUpPostsInCommunityToVote != newUpPostsInCommunityToVote, "PageCommunity: wrong new upPostsInCommunityToVote");
        community[communityId].upPostsInCommunityToVote = newUpPostsInCommunityToVote;

        emit ChangeCommunityUpPostsInCommunityToVote(communityId, newUpPostsInCommunityToVote);
    }

    /**
     * @dev Returns the cost of a post in Page tokens.
     *
     * @param postId ID of post
     */
    function getPostPrice(uint256 postId) external view override returns (uint256) {
        return post[postId].price;
    }

    /**
     * @dev Returns an array of post IDs created in the community.
     *
     * @param communityId ID of community
     */
    function getPostsIdsByCommunityId(uint256 communityId) external view override returns (uint256[] memory) {
        return community[communityId].postIds.values();
    }

    /**
     * @dev Create a new post comment.
     *
     * @param postId ID of post
     * @param ipfsHash Link to the message in IPFS
     * @param isUp If true, then adds a rating for the post
     * @param isDown If true, then removes a rating for the post
     * @param _owner Comment owner address
     */
    function writeComment(
        uint256 postId,
        string memory ipfsHash,
        bool isUp,
        bool isDown,
        address _owner
    ) external override onlyCommunityActiveByPostId(postId) notAddress0(_owner){
        uint256 gasBefore = gasleft();
        uint256 communityId = getCommunityIdByPostId(postId);

        require(isCommunityActiveUser(communityId, _msgSender()), "PageCommunity: wrong user");
        require(isCommunityActiveUser(communityId, _owner), "PageCommunity: wrong user");
        require(post[postId].isView, "PageCommunity: wrong view post");
        require(isPrivacyAccess(_msgSender(), communityId), "PageCommunity: wrong time for privacy access");

        setPostUpDown(postId, isUp, isDown);
        incCommentCount(postId);
        createComment(postId, ipfsHash, _owner, isUp, isDown);
        uint256 commentId = getCommentCount(postId);

        emit WriteComment(communityId, postId, commentId, _msgSender(), _owner);

        uint256 gas = gasBefore - gasleft();
        uint256 price = bank.mintTokenForNewComment(communityId, _owner, _msgSender(), gas);
        setCommentPrice(postId, commentId, price);
    }

    /**
     * @dev Returns information about the comment.
     *
     * @param postId ID of post
     * @param commentId ID of comment
     */
    function readComment(uint256 postId, uint256 commentId) external view override onlyCommunityActiveByPostId(postId) returns(
        string memory ipfsHash,
        address creator,
        address _owner,
        uint256 price,
        bool isUp,
        bool isDown,
        bool isView
    ) {
        if (isPrivacyAccess(_msgSender(), getCommunityIdByPostId(postId))) {
            Comment memory readed = comment[postId][commentId];
            ipfsHash = readed.ipfsHash;
            creator = readed.creator;
            _owner = readed.owner;
            price = readed.price;
            isUp = readed.isUp;
            isDown = readed.isDown;
            isView = readed.isView;
        }
    }

    /**
     * @dev Removes information about the comment.
     *
     * @param postId ID of post
     * @param commentId ID of comment
     */
    function burnComment(uint256 postId, uint256 commentId) external override onlyCommunityActiveByPostId(postId) {
        uint256 gasBefore = gasleft();
        uint256 communityId = getCommunityIdByPostId(postId);

        require(post[postId].isView, "PageCommunity: wrong post");
        require(isCommunityModerator(communityId, _msgSender()) || _msgSender() == supervisor, "PageCommunity: access denied");
        address commentOwner = comment[postId][commentId].owner;
        address commentCreator = comment[postId][commentId].creator;
        eraseComment(postId, commentId);
        emit BurnComment(communityId, postId, commentId, commentCreator, commentOwner);

        uint256 gas = gasBefore - gasleft();
        bank.burnTokenForComment(communityId, commentOwner, commentCreator, gas);
    }

    /**
     * @dev Change comment visibility.
     *
     * @param postId ID of post
     * @param commentId ID of comment
     * @param newVisible Boolean value for comment visibility
     */
    function setVisibilityComment(
        uint256 postId,
        uint256 commentId,
        bool newVisible
    ) external override onlyCommunityActiveByPostId(postId) {
        uint256 communityId = getCommunityIdByPostId(postId);
        require(isCommunityModerator(communityId, _msgSender()) || _msgSender() == supervisor, "PageCommunity: access denied");
        require(community[communityId].postIds.contains(postId), "PageCommunity: wrong post");
        require(isPrivacyAccess(_msgSender(), communityId), "PageCommunity: wrong time for privacy access");

        bool oldVisible = comment[postId][commentId].isView;
        require(oldVisible != newVisible, "PageCommunity: wrong new visible");
        comment[postId][commentId].isView = newVisible;

        emit ChangeVisibleComment(communityId, postId, commentId, newVisible);
    }

    /**
     * @dev Changes MAX_MODERATORS value for all new communities.
     *
     * @param newValue New MAX_MODERATORS value
     */
    function setMaxModerators(uint256 newValue) external override onlyOwner {
        require(MAX_MODERATORS != newValue, "PageCommunity: wrong new value");
        emit SetMaxModerators(MAX_MODERATORS, newValue);
        MAX_MODERATORS = newValue;
    }

    /**
     * @dev Changes DEFAULT_DAYS_IN_COMMUNITY_TO_VOTE value for all new communities.
     *
     * @param newValue New DEFAULT_DAYS_IN_COMMUNITY_TO_VOTE value
     */
    function setDefaultDaysInCommunityToVote(uint256 newValue) external override onlyOwner {
        require(DEFAULT_DAYS_IN_COMMUNITY_TO_VOTE != newValue, "PageCommunity: wrong new value");
        emit SetDefaultDaysInCommunityToVote(DEFAULT_DAYS_IN_COMMUNITY_TO_VOTE, newValue);
        DEFAULT_DAYS_IN_COMMUNITY_TO_VOTE = newValue;
    }

    /**
     * @dev Changes DEFAULT_UP_POSTS_IN_COMMUNITY_TO_VOTE value for all new communities.
     *
     * @param newValue New DEFAULT_UP_POSTS_IN_COMMUNITY_TO_VOTE value
     */
    function setDefaultUpPostsInCommunityToVote(uint256 newValue) external override onlyOwner {
        require(DEFAULT_UP_POSTS_IN_COMMUNITY_TO_VOTE != newValue, "PageCommunity: wrong new value");
        emit SetDefaultUpPostsInCommunityToVote(DEFAULT_UP_POSTS_IN_COMMUNITY_TO_VOTE, newValue);
        DEFAULT_UP_POSTS_IN_COMMUNITY_TO_VOTE = newValue;
    }

    /**
     * @dev Adds address for voter contracts array
     *
     * @param newContract New voter contract address
     */
    function addVoterContract(address newContract) external override onlyOwner {
        require(newContract != address(0), "PageCommunity: value is zero");
        voterContracts.push(newContract);
    }

    /**
     * @dev Changes address for supervisor user
     *
     * @param newUser New supervisor address
     */
    function changeSupervisor(address newUser) external override onlyVoterContract(2) {
        emit ChangeSupervisor(supervisor, newUser);
        supervisor = newUser;
    }

    /**
     * @dev Returns the number of comments for a post.
     *
     * @param postId ID of post
     */
    function getCommentCount(uint256 postId) public view override returns(uint256) {
        return post[postId].commentCount;
    }

    /**
     * @dev Returns a boolean value about checking the address of the creator of the community.
     *
     * @param communityId ID of community
     * @param user Community creator address
     */
    function isCommunityCreator(uint256 communityId, address user) public view override returns(bool) {
        return community[communityId].creator == user;
    }

    /**
     * @dev Returns a boolean value about checking the address of the user of the community and is if is not banned
     *
     * @param communityId ID of community
     * @param user Community user address
     */
    function isCommunityActiveUser(uint256 communityId, address user) public view override returns(bool) {
        return community[communityId].users.contains(user) &&
            !isBannedUser(communityId, user) ||
            communityId == OPEN_FORUM_ID;
    }


    /**
     * @dev Returns a boolean value about checking the address of the user of the community.
     *
     * @param communityId ID of community
     * @param user Community user address
     */
    function isCommunityJoinedUser(uint256 communityId, address user) public view override returns(bool) {
        return community[communityId].users.contains(user) || communityId == OPEN_FORUM_ID;
    }


    /**
     * @dev Returns a boolean about checking that the community is the owner of the posts.
     *
     * @param communityId ID of community
     */
    function isCommunityPostOwner(uint256 communityId) public view override returns(bool) {
        return community[communityId].isPostOwner;
    }

    /**
     * @dev Returns a boolean value about checking the address of the user of the banned.
     *
     * @param communityId ID of community
     * @param user Community user address
     */
    function isBannedUser(uint256 communityId, address user) public view override returns(bool) {
        return community[communityId].bannedUsers.contains(user);
    }

    /**
     * @dev Returns a boolean value about checking the address of the moderator of the community.
     *
     * @param communityId ID of community
     * @param user Community moderator address
     */
    function isCommunityModerator(uint256 communityId, address user) public view override returns(bool) {
        return community[communityId].moderators.contains(user) && communityId != OPEN_FORUM_ID;
    }

    /**
     * @dev Returns the community ID given the post ID.
     *
     * @param postId ID of post
     */
    function getCommunityIdByPostId(uint256 postId) public view override returns(uint256) {
        return communityIdByPostId[postId];
    }

    /**
     * @dev Returns a boolean indicating that the user has already upvoted or downvoted the post.
     *
     * @param postId ID of post
     * @param user Community user address
     */
    function isUpDownUser(uint256 postId, address user) public view override returns(bool) {
        return post[postId].upDownUsers.contains(user);
    }

    /**
     * @dev Returns a boolean indicating that the community is active.
     *
     * @param communityId ID of community
     */
    function isActiveCommunity(uint256 communityId) public view override returns(bool) {
        return community[communityId].isActive;
    }

    /**
     * @dev Returns a boolean indicating that the community is active for this post.
     *
     * @param postId ID of post
     */
    function isActiveCommunityByPostId(uint256 postId) public view override returns(bool) {
        uint256 communityId = getCommunityIdByPostId(postId);
        return isActiveCommunity(communityId);
    }

    /**
     * @dev Returns a boolean indicating that the community is private.
     *
     * @param communityId ID of community
     */
    function isPrivateCommunity(uint256 communityId) external view override returns(bool) {
        return community[communityId].isPrivate;
    }

    /**
     * @dev Checks for voting eligibility.
     *
     * @param user Address of user
     * @param communityId ID of community
     */
    function isEligibleToVoting(uint256 communityId, address user) external view override validCommunityId(communityId) returns(bool) {
        require(isCommunityActiveUser(communityId, user), "PageCommunity: wrong user");
        Community storage curCommunity = community[communityId];
        if (
            (curCommunity.daysInCommunityToVote <= (block.timestamp - curCommunity.userJoiningTime[user]) / 1 days) &&
            (curCommunity.upPostsInCommunityToVote <= curCommunity.userUpPostIds[user].length())
        ) {
            return true;
        }
        return false;
    }

    // *** --- Private area --- ***

    /**
     * @dev Checks if such an ID can exist for the community.
     *
     * @param communityId ID of community
     */
    function validateCommunity(uint256 communityId) private view {
        require(communityId <= communityCount, "PageCommunity: wrong community number");
    }

    /**
     * @dev Create a new community post.
     *
     * @param postId ID of post
     */
    function createPost(uint256 postId) private {
        Post storage newPost = post[postId];
        newPost.creator = _msgSender();
        newPost.isView = true;
    }

    /**
     * @dev Erase info for the community post.
     *
     * @param postId ID of post
     */
    function erasePost(uint256 postId) private {
        Post storage oldPost = post[postId];
        oldPost.creator = address(0);
        oldPost.downCount = 0;
        oldPost.upCount = 0;
        oldPost.commentCount = 0;
        oldPost.isView = false;
    }

    /**
     * @dev Erase info for the post comment.
     *
     * @param postId ID of post
     * @param commentId ID of comment
     */
    function eraseComment(uint256 postId, uint256 commentId) private {
        Comment storage burned = comment[postId][commentId];
        burned.ipfsHash = EMPTY_STRING;
        burned.creator = address(0);
        burned.owner = address(0);
        burned.price = 0;
        burned.isUp = false;
        burned.isDown = false;
        burned.isView = false;
    }

    /**
     * @dev Sets price for post.
     *
     * @param postId ID of post
     * @param price The price value
     */
    function setPostPrice(uint256 postId, uint256 price) private {
        Post storage curPost = post[postId];
        curPost.price = price;
    }

    /**
     * @dev Increases the comment count for a post.
     *
     * @param postId ID of post
     */
    function incCommentCount(uint256 postId) private {
        Post storage curPost = post[postId];
        curPost.commentCount++;
    }

    /**
     * @dev Sets rating for post.
     *
     * @param postId ID of post
     * @param isUp If true, then adds a rating for the post
     * @param isDown If true, then removes a rating for the post
     */
    function setPostUpDown(uint256 postId, bool isUp, bool isDown) private {
        if (!isUp && !isDown) {
            return;
        }
        require(!(isUp && isUp == isDown), "PageCommunity: wrong values for Up/Down");
        require(!isUpDownUser(postId, _msgSender()), "PageCommunity: wrong user for Up/Down");

        Post storage curPost = post[postId];
        uint256 communityId = getCommunityIdByPostId(postId);
        if (isUp) {
            curPost.upCount++;
            bank.addUpDownActivity(communityId, curPost.creator, true);
            if (!community[communityId].userUpPostIds[curPost.creator].contains(postId)) {
                community[communityId].userUpPostIds[curPost.creator].add(postId);
            }
        }
        if (isDown) {
            curPost.downCount++;
            bank.addUpDownActivity(communityId, curPost.creator, false);
        }
        curPost.upDownUsers.add(_msgSender());
    }

    /**
     * @dev Create a new post comment.
     *
     * @param postId ID of post
     * @param ipfsHash Link to the message in IPFS
     * @param _owner Post owner address
     * @param isUp If true, then adds a rating for the post
     * @param isDown If true, then removes a rating for the post
     */
    function createComment(uint256 postId, string memory ipfsHash, address _owner, bool isUp, bool isDown) private {
        uint256 commentId = post[postId].commentCount;
        Comment storage newComment = comment[postId][commentId];
        newComment.ipfsHash = ipfsHash;
        newComment.creator = _msgSender();
        newComment.owner = _owner;
        newComment.isUp = isUp;
        newComment.isDown = isDown;
        newComment.isView = true;
    }

    /**
     * @dev Sets price for comment.
     *
     * @param postId ID of post
     * @param commentId ID of comment
     * @param price The price value
     */
    function setCommentPrice(uint256 postId, uint256 commentId, uint256 price) private {
        Comment storage curComment = comment[postId][commentId];
        curComment.price = price;
    }

    /**
     * @dev Checks for privacy access.
     *
     * @param user Address of user
     * @param communityId ID of community
     */
    function isPrivacyAccess(address user, uint256 communityId) private view returns(bool) {
        if (!community[communityId].isPrivate || user == supervisor) {
            return true;
        }
        if (bank.isPrivacyAvailable(user, communityId)) {
            return true;
        }
        return false;
    }
}