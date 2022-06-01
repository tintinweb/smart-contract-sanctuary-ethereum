/**
 *Submitted for verification at Etherscan.io on 2022-06-01
*/

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol

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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol

// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol

// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// File: contracts/market/IMarket.sol

pragma solidity >=0.6.6 <0.9.0;

interface IMarket {
    enum OrderType {
        Public, // 0
        Private, // 1
        Event_Private //2
    }

    enum PaymentType {
        Normal // 0
    }

    struct Lending {
        address lender;
        address nftAddress;
        uint256 nftId;
        uint64 maxEndTime;
        uint64 minDuration;
        uint64 createTime;
        uint64 nonce;
        OrderType orderType;
        PaymentType paymentType;
    }

    struct PaymentNormal {
        address token;
        uint256 pricePerDay;
    }

    event CreateLendOrder(
        address lender,
        address nftAddress,
        uint256 nftId,
        uint64 maxEndTime,
        uint64 minDuration,
        uint256 pricePerDay,
        address paymentToken,
        address renter,
        OrderType orderType
    );
    event CancelLendOrder(address lender, address nftAddress, uint256 nftId);
    event FulfillOrder(
        address renter,
        address lender,
        address nftAddress,
        uint256 nftId,
        uint64 startTime,
        uint64 endTime,
        uint256 pricePerDay,
        uint256 newId,
        address paymentToken
    );
    event Paused(address account);
    event Unpaused(address account);

    function mintAndCreateLendOrder(
        address resolverAddress,
        uint256 oNftId,
        uint64 maxEndTime,
        uint64 minDuration,
        uint256 pricePerDay,
        address paymentToken
    ) external;

    function createLendOrder(
        address nftAddress,
        uint256 nftId,
        uint64 maxEndTime,
        uint64 minDuration,
        uint256 pricePerDay,
        address paymentToken
    ) external;

    function cancelLendOrder(address nftAddress, uint256 nftId) external;

    function getLendOrder(address nftAddress, uint256 nftId)
        external
        view
        returns (Lending memory);

    function getRenterOfPrivateLendOrder(address nftAddress, uint256 nftId)
        external
        view
        returns (address);

    function getPaymentNormal(address nftAddress, uint256 nftId)
        external
        view
        returns (PaymentNormal memory paymentNormal);

    function fulfillOrderNow(
        address nftAddress,
        uint256 nftId,
        uint256 durationId,
        uint64 duration,
        address user
    ) external payable returns (uint256 tid);

    function setFee(uint256 fee) external;

    function getFee() external view returns (uint256);

    function setMarketBeneficiary(address payable beneficiary) external;

    function claimFee(address[] calldata paymentTokens) external;

    function claimRoyalty(address nftAddress, address[] calldata paymentTokens)
        external;

    function isLendOrderValid(address nftAddress, uint256 nftId)
        external
        view
        returns (bool);

    function setPause(bool v) external;
}

// File: @openzeppelin/contracts/utils/structs/EnumerableSet.sol

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

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol

// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

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
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// File: contracts/IBaseDoNFT.sol

pragma solidity ^0.8.0;


interface IBaseDoNFT is IERC721Receiver {
    struct Duration {
        uint64 start;
        uint64 end;
    }

    struct DoNftInfo {
        uint256 oid;
        uint64 nonce;
        EnumerableSet.UintSet durationList;
    }

    event MetadataUpdate(uint256 tokenId);

    event DurationUpdate(
        uint256 durationId,
        uint256 tokenId,
        uint64 start,
        uint64 end
    );

    event DurationBurn(uint256[] durationIdList);

    event CheckIn(
        address opreator,
        address to,
        uint256 tokenId,
        uint256 durationId,
        uint256 oid,
        uint64 expires
    );

    function mintVNft(uint256 oid) external returns (uint256 tid);

    function mint(
        uint256 tokenId,
        uint256 durationId,
        uint64 start,
        uint64 end,
        address to,
        address user
    ) external returns (uint256 tid);

    function setMaxDuration(uint64 v) external;

    function getMaxDuration() external view returns (uint64);

    function getDurationIdList(uint256 tokenId)
        external
        view
        returns (uint256[] memory);

    function getDurationListLength(uint256 tokenId)
        external
        view
        returns (uint256);

    function getDoNftInfo(uint256 tokenId)
        external
        view
        returns (
            uint256 oid,
            uint256[] memory durationIds,
            uint64[] memory starts,
            uint64[] memory ends,
            uint64 nonce
        );

    function getNonce(uint256 tokenId) external view returns (uint64);

    function getDuration(uint256 durationId)
        external
        view
        returns (uint64 start, uint64 end);

    function getDurationByIndex(uint256 tokenId, uint256 index)
        external
        view
        returns (
            uint256 durationId,
            uint64 start,
            uint64 end
        );

    function getVNftId(uint256 originalNftId) external view returns (uint256);

    function isVNft(uint256 tokenId) external view returns (bool);

    function isValidNow(uint256 tokenId) external view returns (bool isValid);

    function getOriginalNftAddress() external view returns (address);

    function getOriginalNftId(uint256 tokenId) external view returns (uint256);

    function checkIn(
        address to,
        uint256 tokenId,
        uint256 durationId
    ) external;

    function getUser(uint256 orignalNftId) external view returns (address);

    function exists(uint256 tokenId) external view returns (bool);
}

// File: contracts/royalty/IRoyalty.sol

pragma solidity >=0.6.6 <0.9.0;

interface IRoyalty {
    event ClaimRoyaltyAdmin(address operator);

    event SetBeneficiary(address operator, address beneficiary);

    event SetRoyaltyFee(address operator, uint256 fee);

    event ClaimRoyaltyBalance(address operator, uint256 balance);

    function claimRoyaltyAdmin() external;

    function setBeneficiary(address payable beneficiary_) external;

    function getBeneficiary() external view returns (address payable);

    function setRoyaltyFee(uint256 fee_) external;

    function getRoyaltyFee() external view returns (uint256);
}

// File: contracts/IComplexDoNFT.sol

pragma solidity ^0.8.0;


interface IComplexDoNFT is IBaseDoNFT, IRoyalty {
    function initialize(
        string memory name_,
        string memory symbol_,
        address nftAddress_,
        address market_,
        address owner_,
        address admin_,
        address royaltyAdmin_
    ) external;
}

// File: contracts/MiddleWare.sol

pragma solidity ^0.8.0;



interface IDoNFT is IComplexDoNFT, IERC721Metadata {}

contract MiddleWare {
    struct DoNftMarketInfo {
        uint256 originalNftId;
        uint128 orderPricePerDay;
        uint64 startTime;
        uint64 endTime;
        uint32 orderCreateTime;
        uint32 orderMinDuration;
        uint32 orderMaxEndTime;
        uint32 orderFee; //   ratio = fee / 1e5 , orderFee = 1000 means 1%
        uint8 orderType; // 0: Public, 1: Private, 2: Event_Private
        bool orderIsValid;
        address originalNftAddress;
        address owner;
        address user;
        address orderPrivateRenter;
        address orderPaymentToken;
    }

    struct DoNftMarketInfo2 {
        uint256 originalNftId;
        uint128 orderPricePerDay;
        uint64 startTime;
        uint64 endTime;
        uint32 orderCreateTime;
        uint32 orderMinDuration;
        uint32 orderMaxEndTime;
        uint32 orderFee; //   ratio = fee / 1e5 , orderFee = 1000 means 1%
        uint8 orderType; // 0: Public, 1: Private, 2: Event_Private
        bool orderIsValid;
        bool isVNft;
        address originalNftAddress;
        address owner;
        address user;
        address orderPrivateRenter;
        address orderPaymentToken;
    }

    function getNftOwnerAndUser(
        address originalNftAddr,
        uint256 orginalNftId,
        address doNftAddr
    ) public view returns (address owner, address user) {
        IBaseDoNFT doNft = IBaseDoNFT(doNftAddr);
        IERC721Metadata oNft = IERC721Metadata(originalNftAddr);

        try oNft.ownerOf(orginalNftId) returns (address ownerAddr) {
            owner = ownerAddr;
        } catch {}

        try doNft.getUser(orginalNftId) returns (address userAddr) {
            user = userAddr;
        } catch {}
    }

    function getNftOwner(address nftAddr, uint256 nftId)
        public
        view
        returns (address owner)
    {
        IERC721Metadata nft = IERC721Metadata(nftAddr);
        try nft.ownerOf(nftId) returns (address ownerAddr) {
            owner = ownerAddr;
        } catch {}
    }

    function getNftOwnerAndTokenURI(address nftAddr, uint256 nftId)
        public
        view
        returns (address owner, string memory uri)
    {
        IERC721Metadata nft = IERC721Metadata(nftAddr);
        try nft.ownerOf(nftId) returns (address ownerAddr) {
            owner = ownerAddr;
        } catch {}

        try nft.tokenURI(nftId) returns (string memory tokenURI) {
            uri = tokenURI;
        } catch {}
    }

    function getDoNftMarketInfo(
        address nftAddr,
        uint256 nftId,
        address marketAddr
    ) public view returns (DoNftMarketInfo memory doNftInfo) {
        IDoNFT doNft = IDoNFT(nftAddr);
        IMarket market = IMarket(marketAddr);

        doNftInfo.originalNftAddress = doNft.getOriginalNftAddress();
        doNftInfo.orderFee =
            uint32(market.getFee()) +
            uint32(doNft.getRoyaltyFee());

        if (doNft.exists(nftId)) {
            (
                uint256 oid,
                ,
                uint64[] memory starts,
                uint64[] memory ends,

            ) = doNft.getDoNftInfo(nftId);

            doNftInfo.owner = doNft.ownerOf(nftId);
            doNftInfo.originalNftId = oid;
            doNftInfo.user = doNft.getUser(oid);
            doNftInfo.startTime = starts[0];
            doNftInfo.endTime = ends[0];
            doNftInfo.orderIsValid = market.isLendOrderValid(nftAddr, nftId);
            if (doNftInfo.orderIsValid) {
                IMarket.Lending memory order = market.getLendOrder(
                    nftAddr,
                    nftId
                );
                IMarket.PaymentNormal memory pNormal = market.getPaymentNormal(
                    nftAddr,
                    nftId
                );
                if (
                    order.orderType == IMarket.OrderType.Private ||
                    order.orderType == IMarket.OrderType.Event_Private
                ) {
                    doNftInfo.orderPrivateRenter = market
                        .getRenterOfPrivateLendOrder(nftAddr, nftId);
                }
                doNftInfo.orderType = uint8(order.orderType);
                doNftInfo.orderMinDuration = uint32(order.minDuration);
                doNftInfo.orderMaxEndTime = uint32(order.maxEndTime);
                doNftInfo.orderCreateTime = uint32(order.createTime);
                doNftInfo.orderPricePerDay = uint128(pNormal.pricePerDay);
                doNftInfo.orderPaymentToken = pNormal.token;
            }
        }
    }

    function getDoNftMarketInfo2(
        address nftAddr,
        uint256 nftId,
        address marketAddr
    ) public view returns (DoNftMarketInfo2 memory doNftInfo) {
        IDoNFT doNft = IDoNFT(nftAddr);
        IMarket market = IMarket(marketAddr);

        doNftInfo.originalNftAddress = doNft.getOriginalNftAddress();
        doNftInfo.orderFee =
            uint32(market.getFee()) +
            uint32(doNft.getRoyaltyFee());

        if (doNft.exists(nftId)) {
            (
                uint256 oid,
                ,
                uint64[] memory starts,
                uint64[] memory ends,

            ) = doNft.getDoNftInfo(nftId);

            doNftInfo.owner = doNft.ownerOf(nftId);
            doNftInfo.originalNftId = oid;
            doNftInfo.user = doNft.getUser(oid);
            doNftInfo.startTime = starts[0];
            doNftInfo.endTime = ends[0];
            doNftInfo.orderIsValid = market.isLendOrderValid(nftAddr, nftId);
            doNftInfo.isVNft = doNft.isVNft(nftId);
            if (doNftInfo.orderIsValid) {
                IMarket.Lending memory order = market.getLendOrder(
                    nftAddr,
                    nftId
                );
                IMarket.PaymentNormal memory pNormal = market.getPaymentNormal(
                    nftAddr,
                    nftId
                );
                if (
                    order.orderType == IMarket.OrderType.Private ||
                    order.orderType == IMarket.OrderType.Event_Private
                ) {
                    doNftInfo.orderPrivateRenter = market
                        .getRenterOfPrivateLendOrder(nftAddr, nftId);
                }
                doNftInfo.orderType = uint8(order.orderType);
                doNftInfo.orderMinDuration = uint32(order.minDuration);
                doNftInfo.orderMaxEndTime = uint32(order.maxEndTime);
                doNftInfo.orderCreateTime = uint32(order.createTime);
                doNftInfo.orderPricePerDay = uint128(pNormal.pricePerDay);
                doNftInfo.orderPaymentToken = pNormal.token;
            }
        }
    }

    function batchIsApprovedForAll(address owner, address[] calldata operators, address[] calldata erc721Array) external view returns (bool[] memory results) {
        results = new bool[](erc721Array.length);
        for(uint i = 0; i < erc721Array.length; i++) {
            results[i] = IERC721(erc721Array[i]).isApprovedForAll(owner, operators[i]);
        }
    }

    function batchGetDoNftIdByONftId(address[] calldata doNftAddressArray, uint256[] calldata oNftIdArray) external view returns (uint256[] memory doNftIdArray) {
        require(doNftAddressArray.length == oNftIdArray.length, "invalid input data");
        doNftIdArray = new uint256[](doNftAddressArray.length);
        for(uint i = 0; i < doNftAddressArray.length; i++) {
            doNftIdArray[i] = IDoNFT(doNftAddressArray[i]).getVNftId(oNftIdArray[i]);
        }
    }

    function batchGetNftOwner(address nftAddress, uint256[] calldata nftIdArray) external view returns (address[] memory results) {
        results = new address[](nftIdArray.length);
        IERC721 nft = IERC721(nftAddress);
        for(uint i = 0; i < nftIdArray.length; i++) {
            try nft.ownerOf(nftIdArray[i]) returns (address ownerAddr) {
                results[i] = ownerAddr;
            } catch {}
        }
    }
}