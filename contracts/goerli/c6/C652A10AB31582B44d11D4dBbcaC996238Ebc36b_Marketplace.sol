// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

interface ICNFT {
    /**
     *  @dev Gets the site operator's address
     */
    function getSiteOperator() external view returns (address);

    /**
     *  @dev Gets the curriculum's author's address
     */
    function getAuthor() external view returns (address);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./ICNFT.sol";

error Marketplace__NotNftOwner();
error Marketplace__NoWithdrawableFunds();
error Marketplace__MarketplaceHasNoApprovalToList();
error Marketplace__PriceTooLow();
error Marketplace__TransactionFailed();
error Marketplace__ItemAlreadyListed(address nftAddress, uint256 tokenId);
error Marketplace__ItemNotListed(address nftAddress, uint256 tokenId);
error Marketplace__PaymentAmountTooSmall(address nftAddress, uint256 tokenId, uint256 price);

contract Marketplace is ReentrancyGuard {
    struct MarketplaceListing {
        uint256 price;
        address seller;
    }

    uint256 private constant OWNER_COMMISSION = 2;
    uint256 private constant AUTHOR_COMMISSION = 20;
    uint256 private constant STUDENT_COMMISSION = 78;

    /**
     * ======================
     * = STATES             =
     * ======================
     */

    // Keeps track of all the marketplace listings (including prices and sellers)
    mapping(address => mapping(uint256 => MarketplaceListing)) private s_marketplaceListing;

    // Keeps track of all the seller's proceeds
    mapping(address => uint256) private s_sellerProceeds;

    /**
     * ======================
     * = EVENTS             =
     * ======================
     */

    // Emitted, when a user creates a new marketpalce listing
    event ListingCreated(
        address indexed seller,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 price
    );

    // Emitted, when a user updates a listed items price
    event ListingUpdated(
        address indexed seller,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 price
    );

    // Emitted, when a user deletes a marketplace listing
    event ListingDeleted(
        address indexed seller,
        address indexed nftAddress,
        uint256 indexed tokenId
    );

    // Emitted, when a users buys a marketplace listing
    event ListingBought(
        address indexed buyer,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 price
    );

    /**
     * ======================
     * = MODIFIERS          =
     * ======================
     */

    //  Proceeds with the listing, if the NFT is not listed on the marketplace
    modifier notListed(
        address nftAddress,
        uint256 tokenId,
        address tokenOwner
    ) {
        if (s_marketplaceListing[nftAddress][tokenId].price > 0) {
            revert Marketplace__ItemAlreadyListed(nftAddress, tokenId);
        }

        _;
    }

    // Proceeds with the purchasing, if the NFT is listed on the marketplace
    modifier listed(address nftAddress, uint256 tokenId) {
        if (s_marketplaceListing[nftAddress][tokenId].price <= 0) {
            revert Marketplace__ItemNotListed(nftAddress, tokenId);
        }

        _;
    }

    // Proceeds with the listing, if the NFT is owned by the msg.sender
    modifier hasOwnership(
        address nftAddress,
        uint256 tokenId,
        address sender
    ) {
        if (sender != IERC721(nftAddress).ownerOf(tokenId)) {
            revert Marketplace__NotNftOwner();
        }

        _;
    }

    // Proceeds with the listing, if the NFT's listing price is correct
    modifier hasValidPrice(uint256 price) {
        if (price <= 0) {
            revert Marketplace__PriceTooLow();
        }

        _;
    }

    // Proceeds with the purchase, if the payment amount is enough
    modifier hasEnoughFunds(
        address nftAddress,
        uint256 tokenId,
        uint256 value
    ) {
        uint256 listingPrice = s_marketplaceListing[nftAddress][tokenId].price;

        if (msg.value < listingPrice) {
            revert Marketplace__PaymentAmountTooSmall(nftAddress, tokenId, listingPrice);
        }

        _;
    }

    // Proceeds with the withdrawal, if any proceeds have been collected
    modifier hasWithdrawableFunds(uint256 proceeds) {
        if (proceeds <= 0) {
            revert Marketplace__NoWithdrawableFunds();
        }

        _;
    }

    /**
     * ======================
     * = MAIN METHODS       =
     * ======================
     */

    /**
     * @notice Creates a new listing on the marketplace
     * @param nftAddress: The address of the curriculum NFT
     * @param tokenId: The TokenID of the curriculum NFT
     * @param price: Listing price for the curriculum NFT
     */
    function createListing(
        address nftAddress,
        uint256 tokenId,
        uint256 price
    )
        external
        hasOwnership(nftAddress, tokenId, msg.sender)
        hasValidPrice(price)
        notListed(nftAddress, tokenId, msg.sender)
    {
        // Checking whether the marketplace has the approval to list the NFT
        IERC721 curriculumNft = IERC721(nftAddress);
        if (curriculumNft.getApproved(tokenId) != address(this)) {
            revert Marketplace__MarketplaceHasNoApprovalToList();
        }

        // Creating a new marketplace listing, and firing the corresponding event
        s_marketplaceListing[nftAddress][tokenId] = MarketplaceListing(price, msg.sender);
        emit ListingCreated(msg.sender, nftAddress, tokenId, price);
    }

    /**
     * @notice Updates a listed item's price on the marketplace
     * @param nftAddress: The address of the curriculum NFT
     * @param tokenId: The TokenID of the curriculum NFT
     * @param price: The new listing price for the curriculum NFT
     */
    function updateListing(
        address nftAddress,
        uint256 tokenId,
        uint256 price
    )
        external
        hasOwnership(nftAddress, tokenId, msg.sender)
        hasValidPrice(price)
        listed(nftAddress, tokenId)
    {
        s_marketplaceListing[nftAddress][tokenId].price = price;

        emit ListingUpdated(msg.sender, nftAddress, tokenId, price);
    }

    /**
     * @notice Deletes a listing from the marketplace
     * @param nftAddress: The address of the curriculum NFT
     * @param tokenId: The TokenID of the curriculum NFT
     */
    function deleteListing(address nftAddress, uint256 tokenId)
        external
        hasOwnership(nftAddress, tokenId, msg.sender)
        listed(nftAddress, tokenId)
    {
        delete (s_marketplaceListing[nftAddress][tokenId]);

        emit ListingDeleted(msg.sender, nftAddress, tokenId);
    }

    /**
     * @notice Purchase a listing from the marketplace.
     * @param nftAddress: The address of the curriculum NFT
     * @param tokenId: The TokenID of the curriculum NFT
     */
    function buyListing(address nftAddress, uint256 tokenId)
        external
        payable
        nonReentrant
        listed(nftAddress, tokenId)
        hasEnoughFunds(nftAddress, tokenId, msg.value)
    {
        // Getting all of the transaction participants
        address siteOwner = ICNFT(nftAddress).getSiteOperator();
        address author = ICNFT(nftAddress).getAuthor();

        // Updating the participants proceeds based on fixed percentages
        MarketplaceListing memory item = s_marketplaceListing[nftAddress][tokenId];

        s_sellerProceeds[siteOwner] =
            s_sellerProceeds[siteOwner] +
            calculateCommission(msg.value, OWNER_COMMISSION);

        s_sellerProceeds[author] =
            s_sellerProceeds[author] +
            calculateCommission(msg.value, AUTHOR_COMMISSION);

        s_sellerProceeds[item.seller] =
            s_sellerProceeds[item.seller] +
            calculateCommission(msg.value, STUDENT_COMMISSION);

        // Deleting the listing from the marketplace
        delete (s_marketplaceListing[nftAddress][tokenId]);

        // Transfering the curriculum NFT to the new owner,
        // using the safeTransferFrom to make sure the owner receives the NFT and minimize the risk to lose it
        IERC721(nftAddress).safeTransferFrom(item.seller, msg.sender, tokenId);
        emit ListingBought(msg.sender, nftAddress, tokenId, item.price);
    }

    /**
     * @notice Withdraw proceeds from the marketplace
     */
    function withdraw() external nonReentrant hasWithdrawableFunds(s_sellerProceeds[msg.sender]) {
        uint256 proceeds = s_sellerProceeds[msg.sender];
        s_sellerProceeds[msg.sender] = 0;
        (bool success, ) = payable(msg.sender).call{value: proceeds}("");

        if (!success) {
            revert Marketplace__TransactionFailed();
        }
    }

    /**
     * ======================
     * = GETTERS            =
     * ======================
     */

    function getListing(address nftAddress, uint256 tokenId)
        external
        view
        returns (MarketplaceListing memory)
    {
        return s_marketplaceListing[nftAddress][tokenId];
    }

    function getProceeds(address seller) external view returns (uint256) {
        return s_sellerProceeds[seller];
    }

    /**
     * ======================
     * = PRIVATE METHODS    =
     * ======================
     */

    /**
     * @dev Calculates the commission based on a given value and percantage.
     * We have to calculate with basis points, since solidity doesn't support floating point numbers.
     */
    function calculateCommission(uint256 value, uint256 percentage) private pure returns (uint256) {
        return (value * (percentage * 100)) / 10000;
    }
}