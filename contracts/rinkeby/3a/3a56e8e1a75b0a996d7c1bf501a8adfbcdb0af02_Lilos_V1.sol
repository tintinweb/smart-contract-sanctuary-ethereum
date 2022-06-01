// SPDX-License-Identifier: MIT

// LILOS is a P2P NFT Rental Contract. User can rent
// NFT using tokens or another NFT as collateral. LILO
// transactions are acceptable in LILOS.

// Lilos_V1 contract only realized P2P lease using $ETH
// as collateral. Stable coins collateralized lease
// agreement and NFT collateralized lease agreement
// will be implemented in Lilos_StableCoin_V1 contract
// and Lilos_NFT_V1 contract so as to save gas. LILO
// transactions will be realized in Lilos_V2 contract.

// Lease in/ lease out (“LILO”) mechanism is not realized in this version yet.
// Each item can only be leased once in the leasing term.
// The repayer is not limited to be the original lessee.
// Thus, please do not lease for shorting or your collateral may be withdrawn.
// Ultimate LILO structure: https://drive.google.com/file/d/1K5gECGqXFBeFQl89Y8XbJqIvNvmPQv7-/view?usp=sharing
// Learn more about LILOs: https://assets.kpmg/content/dam/kpmg/au/pdf/2017/foreign-resident-vessels-cross-border-leasing-april-2017.pdf
// LILO transactions: https://papers.ssrn.com/sol3/papers.cfm?abstract_id=975112
// http://www.woodllp.com/Publications/Articles/pdf/SILOs_and_LILOs_Demystified.pdf

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Lilos_V1 {
    using SafeMath for uint256;
    address private owner;
    // Platform charges 5% of the rental.
    uint256 private platformFeeRate = 95;

    constructor() {
        owner = msg.sender;
    }

    enum ListingStatus {
        Active,
        Leased,
        Delisted
    }

    struct ListingItem {
        uint256 listingId;
        ListingStatus status;
        address lessor;
        address lessee;
        address collection;
        uint256 tokenId;
        uint256 collateral_value;     // in wei
        uint256 rental_value;         // in wei
        uint256 lease_term;           // in seconds(timestamp)
        uint256 lease_start_date;
        uint256 lease_end_date;
    }

    /* Events */
    event Listed(
        uint256 indexed listingId,
        ListingStatus status,
        address indexed lessor,
        address collection,
        uint256 tokenId,
        uint256 collateral_value,
        uint256 rental_value,
        uint256 lease_term
    );

    event Delisted(uint256 listingId, address lessor);

    event Leased(
        uint256 indexed listingId,
        address indexed lessor,
        address indexed lessee,
        address collection,
        uint256 tokenId,
        uint256 collateral_value,
        uint256 rental_value,
        uint256 lease_term,
        uint256 lease_start_date,
        uint256 lease_end_date
    );

    event Repayed(
        uint256 indexed listingId,
        address lessor,
        address indexed lessee,
        address collection,
        uint256 tokenId,
        uint256 collateral_value,
        uint256 lease_term,
        uint256 lease_start_date,
        uint256 lease_end_date,
        uint256 repay_date
    );

    event Liquidated(
        uint256 indexed listingId,
        address indexed lessor,
        address indexed lessee,
        address collection,
        uint256 tokenId,
        uint256 collateral_value,
        uint256 lease_term,
        uint256 lease_start_date,
        uint256 lease_end_date,
        uint256 Liquidated_date
    );

    /* Main functions */
    uint256 private _listingId;
    uint256 private _max_listingId = 10000;
    // If we use collection and tokenId as index, we cannot query all tokens not knowing the collection and tokenId.
    // Thus we set _listingId as index for ListingItem structure and make another mapping for checking out the statue while listing.
    mapping(address => mapping(uint256 => bool)) private isTokenListed;
    mapping(uint256 => ListingItem) private _listingItems;
    uint256 private _max_lease_term = 10 days;          // 10 days = 864000 seconds(timestamp)
    uint256 private _min_lease_term = 1 minutes;        // 1 mins = 60 seconds(timestamp)
    uint256 private _lease_date_zero;

    function listToken(
        address collection_,
        uint256 tokenId_,
        uint256 collateral_value_,
        uint256 rental_value_,
        uint256 lease_term_
    ) external {
        require(_listingId <= _max_listingId, "The listing number reached the limit.");
        require(isTokenListed[collection_][tokenId_] == false, "This token is already listed.");
        require(IERC721(collection_).isApprovedForAll(msg.sender, address(this)),"Lessor should approve Lilos contract to access all tokens of the collection.");
        require(IERC721(collection_).ownerOf(tokenId_) == msg.sender,"Lessor must be the token owner.");
        require(collateral_value_ > 0, "Collateral value should be larger than zero.");
        require(rental_value_ > 0, "Rent value should be larger than zero.");
        require(lease_term_ > _min_lease_term, "Lease term should be longer than 1 minutes.");
        require(lease_term_ < _max_lease_term, "Lease term should be shorter than 10 days.");

        ListingItem memory listingItem = ListingItem(
            _listingId,
            ListingStatus.Active,
            msg.sender,
            address(0),         // default lessee is 0x00000...
            collection_,
            tokenId_,
            collateral_value_,
            rental_value_,
            lease_term_,
            _lease_date_zero,
            _lease_date_zero
        );

        isTokenListed[listingItem.collection][listingItem.tokenId] = true;
        _listingItems[_listingId] = listingItem;

        emit Listed(
            _listingId,
            listingItem.status,
            msg.sender,
            listingItem.collection,
            listingItem.tokenId,
            listingItem.collateral_value,
            listingItem.rental_value,
            listingItem.lease_term
        );

        _listingId = _listingId.add(1);
    }

    function delist(uint256 listingId_) public {
        ListingItem storage listingItem = _listingItems[listingId_];

        require(msg.sender == listingItem.lessor, "Only lessor can cancel listing.");
        require(listingItem.status == ListingStatus.Active, "Listing is not active.");

        isTokenListed[listingItem.collection][listingItem.tokenId] = false;
        listingItem.status = ListingStatus.Delisted;

        emit Delisted(listingId_, msg.sender);
    }

    function leaseIn(uint256 listingId_) external payable {
        ListingItem storage listingItem = _listingItems[listingId_];

        require(msg.sender != listingItem.lessor, "Lessor cannot be lessee.");
        require(listingItem.status == ListingStatus.Active,  "Listing is not active.");

        // This is a precaution to protect lessor.
        // Once the lessor removed the approval to the contract, the lease of the item would be disabled.
        bool isLessorApprovalActive = IERC721(listingItem.collection).isApprovedForAll(listingItem.lessor, address(this));
        if (!isLessorApprovalActive) {
            listingItem.status = ListingStatus.Delisted;
        }
        require(isLessorApprovalActive, "Lessor removed the approval of the token to the contract.");
        require(msg.value == (listingItem.collateral_value.add(listingItem.rental_value)), "msg.value dose not match the total spending.");

        IERC721(listingItem.collection).transferFrom(listingItem.lessor, msg.sender, listingItem.tokenId);
        payable(listingItem.lessor).transfer(listingItem.rental_value.mul(platformFeeRate).div(100));
        listingItem.status = ListingStatus.Leased;
        listingItem.lessee = msg.sender;
        listingItem.lease_start_date = block.timestamp;
        listingItem.lease_end_date = listingItem.lease_start_date.add( listingItem.lease_term);

        emit Leased(
            listingId_,
            listingItem.lessor,
            listingItem.lessee,
            listingItem.collection,
            listingItem.tokenId,
            listingItem.collateral_value,
            listingItem.rental_value,
            listingItem.lease_term,
            listingItem.lease_start_date,
            listingItem.lease_end_date
        );
    }

    // If the lessee dose not repay the lease and the leasor dose not liquidate the lease, repay function remains executable.
    function repay(uint256 listingId_) public {
        ListingItem storage listingItem = _listingItems[listingId_];

        require(listingItem.status == ListingStatus.Leased, "Token is not leased.");
        require(msg.sender == listingItem.lessee, "Only lessee can repay.");
        require(IERC721(listingItem.collection).ownerOf(listingItem.tokenId) == address(this), "Token is not in the contract vault.");

        payable(msg.sender).transfer(listingItem.collateral_value);
        isTokenListed[listingItem.collection][listingItem.tokenId] = false;
        listingItem.status = ListingStatus.Delisted;
        IERC721(listingItem.collection).transferFrom(address(this), listingItem.lessor, listingItem.tokenId);

        emit Repayed(
            listingId_,
            listingItem.lessor,
            listingItem.lessee,
            listingItem.collection,
            listingItem.tokenId,
            listingItem.collateral_value,
            listingItem.lease_term,
            listingItem.lease_start_date,
            listingItem.lease_end_date,
            block.timestamp
        );
    }

    function liquidate(uint256 listingId_) public {
        ListingItem storage listingItem = _listingItems[listingId_];
        require(listingItem.status == ListingStatus.Leased, "Token is not leased.");
        require(listingItem.lessor == msg.sender, "Liquidation can only be implemented by lessor.");
        require(block.timestamp > listingItem.lease_end_date, "Lease is not expired.");

        payable(listingItem.lessor).transfer(listingItem.collateral_value);
        isTokenListed[listingItem.collection][listingItem.tokenId] = false;
        listingItem.status = ListingStatus.Delisted;

        emit Liquidated(
            listingId_,
            listingItem.lessor,
            listingItem.lessee,
            listingItem.collection,
            listingItem.tokenId,
            listingItem.collateral_value,
            listingItem.lease_term,
            listingItem.lease_start_date,
            listingItem.lease_end_date,
            block.timestamp
        );
    }

    /* Getter functions */
    // Turn the mapping into a struct array to return.
    function getAllItems() public view returns (ListingItem[] memory) {
        ListingItem[] memory items = new ListingItem[](_listingId);
        for (uint256 i = 0; i < _listingId; i++) {
            items[i] = _listingItems[i];
        }
        return items;
    }

    function getItemByListingId(uint256 listingId_) public view returns (ListingItem memory) {
        return _listingItems[listingId_];
    }

    function getItemByCollctionAndTokenId(address collection_, uint256 tokenId_) public view returns (ListingItem memory) {
        ListingItem memory items;
        for (uint256 i = 0; i < _listingId; i++) {
            if (_listingItems[i].collection == collection_ && _listingItems[i].tokenId == tokenId_) {
                items = _listingItems[i];
            }
        }
        return items;
    }

    function getActiveItems() public view returns (ListingItem[] memory) {
        uint256 itemCount;
        uint256 currentFilterIndex;
        for (uint256 i = 0; i < _listingId; i++) {
            if (_listingItems[i].status == ListingStatus.Active) {
                itemCount++;
            }
        }
        ListingItem[] memory items = new ListingItem[](itemCount);
        for (uint256 i = 0; i < _listingId; i++) {
            if (_listingItems[i].status == ListingStatus.Active) {
                items[currentFilterIndex] = _listingItems[i];
                currentFilterIndex++;
            }
        }
        return items;
    }

    function getLeasedItems() public view returns (ListingItem[] memory) {
        uint256 itemCount;
        uint256 currentFilterIndex;
        for (uint256 i = 0; i < _listingId + 1; i++) {
            if (_listingItems[i].status == ListingStatus.Leased) {
                itemCount++;
            }
        }
        ListingItem[] memory items = new ListingItem[](itemCount);
        for (uint256 i = 0; i < _listingId + 1; i++) {
            if (_listingItems[i].status == ListingStatus.Leased) {
                items[currentFilterIndex] = _listingItems[i];
                currentFilterIndex++;
            }
        }
        return items;
    }

    function getItemsByLessor(address lessor_) public view returns (ListingItem[] memory) {
        uint256 itemCount;
        uint256 currentFilterIndex;
        for (uint256 i = 0; i < _listingId + 1; i++) {
            if (_listingItems[i].lessor == lessor_) {
                itemCount++;
            }
        }
        ListingItem[] memory items = new ListingItem[](itemCount);
        for (uint256 i = 0; i < _listingId + 1; i++) {
            if (_listingItems[i].lessor == lessor_) {
                items[currentFilterIndex] = _listingItems[i];
                currentFilterIndex++;
            }
        }
        return items;
    }

    function getItemsByLessee(address lessee_) public view returns (ListingItem[] memory) {
        uint256 itemCount;
        uint256 currentFilterIndex;
        for (uint256 i = 0; i < _listingId + 1; i++) {
            if (_listingItems[i].lessee == lessee_) {
                itemCount++;
            }
        }
        ListingItem[] memory items = new ListingItem[](itemCount);
        for (uint256 i = 0; i < _listingId + 1; i++) {
            if (_listingItems[i].lessee == lessee_) {
                items[currentFilterIndex] = _listingItems[i];
                currentFilterIndex++;
            }
        }
        return items;
    }

    function getListingId() public view returns (uint256) {
        return _listingId;
    }

    function getIsExpiredByListingId(uint256 listingId_) public view returns (bool) {
        bool isExpired;
        if (_listingItems[listingId_].status == ListingStatus.Leased) {
            if (block.timestamp > _listingItems[listingId_].lease_end_date) {
                isExpired = true;
            }
        }
        return isExpired;
    }

    function getTime() public view returns (uint256) {
        return block.timestamp;
    }
}

/* Reference */
// https://mantlefi.com/
// https://github.com/dabit3/polygon-ethereum-nextjs-marketplace/blob/main/contracts/NFTMarketplace.sol
// https://opensea.io/
// https://nftfi.com/
// https://looksrare.org/
// https://moralis.io/

// gh-repo: https://github.com/wesleytw/LILOS_SmartContract
// The Difference Between a Lease and a Rental Agreement: https://www.mysmartmove.com/SmartMove/blog/difference-between-lease-and-rental-agreement.page

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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
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
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
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