// SPDX-License-Identifier: MIT
//
// Marketplace from the Art101 team (https://art101.io/devs.html).
// Developed by @lza_menace
//
// This is our take on a decentralized NFT marketplace. Big thanks to those
// who came before us; CryptoPunks, CryptoPhunks, etc. Their marketplaces and
// tools were highly influential and provided the initial contract code and
// reference implementations.
//
// This implementation supports many collections/contracts to be added to it.
// The only requirements are that the contract implements `Ownable` and ERC-721
// or ERC-1155 token standards. Contract owners must submit their collection.
// This contract is free to use, but contract owners can enforce their own royalties.
//
// Teams may use this contract with an integrated frontend of their choice or
// fork this code and launch one of their own. We hope it becomes useful to the
// NFT and web3 scene and furthers the push for decentralization. Much of the
// infrastructure has been consolidated to the largest players/organizations
// which have normalized censorship, favoritism, wash trading, skimming/capital
// extraction, and supporting and enabling scams and predatory behavior. We
// believe in the need for NFT projects and teams to leverage their own
// (or community) smart contract based exchange methods and open source trading
// contracts.
//
// A frontend implementation can be found at https://gallery.art101.io. We
// intend to release a more general purpose template which teams can fork for
// their own projects.
//
// If anyone is so inclined and interested, please join us:
// @art101nft - @j_winter_m - @cartyisme - @lza_menace

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";


contract Marketplace is ReentrancyGuard, Ownable {
    using SafeMath for uint256;

    // Define offers, bids, and collection details
    struct Offer {
        bool isForSale;
        uint256 tokenIndex;
        address seller;
        uint256 minValue;
        address onlySellTo;
    }

    struct Bid {
        bool hasBid;
        uint256 tokenIndex;
        address bidder;
        uint256 value;
    }

    struct Collection {
        bool status;
        bool erc1155;
        uint256 royaltyPercent;
        string metadataURL;
    }

    // Nested mappings for each collection's offers and bids
    mapping (address => mapping(uint256 => Offer)) public tokenOffers;
    mapping (address => mapping(uint256 => Bid)) public tokenBids;

    // Mapping of collection status and details
    mapping (address => Collection) public collectionState;

    // Mapping of each wallet's pending balances
    mapping (address => uint256) public pendingBalance;

    // Log events
    event TokenTransfer(address indexed collectionAddress, address indexed from, address indexed to, uint256 tokenIndex);
    event TokenOffered(address indexed collectionAddress, uint256 indexed tokenIndex, uint256 minValue, address indexed toAddress);
    event TokenBidEntered(address indexed collectionAddress, uint256 indexed tokenIndex, uint256 value, address indexed fromAddress);
    event TokenBidWithdrawn(address indexed collectionAddress, uint256 indexed tokenIndex, uint256 value, address indexed fromAddress);
    event TokenBought(address indexed collectionAddress, uint256 indexed tokenIndex, uint256 value, address fromAddress, address toAddress);
    event TokenNoLongerForSale(address indexed collectionAddress, uint256 indexed tokenIndex);
    event CollectionUpdated(address indexed collectionAddress);
    event CollectionDisabled(address indexed collectionAddress);

    constructor() {
        // do stuff...
    }

    /*************************
    Modifiers
    **************************/

    modifier onlyIfTokenOwner(
        address contractAddress,
        uint256 tokenIndex
    ) {
        if (collectionState[contractAddress].erc1155) {
            require(IERC1155(contractAddress).balanceOf(msg.sender, tokenIndex) > 0, "You must own the token.");
        } else {
            require(msg.sender == IERC721(contractAddress).ownerOf(tokenIndex), "You must own the token.");
        }
        _;
    }

    modifier notIfTokenOwner(
        address contractAddress,
        uint256 tokenIndex
    ) {
        if (collectionState[contractAddress].erc1155) {
            require(IERC1155(contractAddress).balanceOf(msg.sender, tokenIndex) == 0, "Token owner cannot enter bid to self.");
        } else {
            require(msg.sender != IERC721(contractAddress).ownerOf(tokenIndex), "Token owner cannot enter bid to self.");
        }
        _;
    }

    modifier onlyIfContractOwner(
        address contractAddress
    ) {
        require(msg.sender == Ownable(contractAddress).owner(), "You must own the contract.");
        _;
    }

    modifier collectionMustBeEnabled(
        address contractAddress
    ) {
        require(true == collectionState[contractAddress].status, "Collection must be enabled on this contract by project owner.");
        _;
    }

    /*************************
    Administration
    **************************/

    // Allow owners of contracts to update their collection details
    function updateCollection(
        address contractAddress,
        bool erc1155,
        uint256 royaltyPercent,
        string memory metadataURL
    ) external onlyIfContractOwner(contractAddress) {
        require(royaltyPercent >= 0, "Must be greater than or equal to 0.");
        require(royaltyPercent <= 100, "Cannot exceed 100%");
        collectionState[contractAddress] = Collection(true, erc1155, royaltyPercent, metadataURL);
        emit CollectionUpdated(contractAddress);
    }

    // Allow owners of contracts to remove their collections
    function disableCollection(
        address contractAddress
    ) external collectionMustBeEnabled(contractAddress) onlyIfContractOwner(contractAddress) {
        collectionState[contractAddress] = Collection(false, false, 0, "");
        emit CollectionDisabled(contractAddress);
    }

    /*************************
    Offering
    **************************/

    // List (offer) token
    function offerTokenForSale(
        address contractAddress,
        uint256 tokenIndex,
        uint256 minSalePriceInWei
    ) external collectionMustBeEnabled(contractAddress) onlyIfTokenOwner(contractAddress, tokenIndex) nonReentrant() {
        if (collectionState[contractAddress].erc1155) {
            require(IERC1155(contractAddress).isApprovedForAll(msg.sender, address(this)), "Marketplace not approved to spend token on seller behalf.");
        } else {
            require(IERC721(contractAddress).getApproved(tokenIndex) == address(this), "Marketplace not approved to spend token on seller behalf.");
        }
        tokenOffers[contractAddress][tokenIndex] = Offer(true, tokenIndex, msg.sender, minSalePriceInWei, address(0x0));
        emit TokenOffered(contractAddress, tokenIndex, minSalePriceInWei, address(0x0));
    }

    // List (offer) token for specific address
    function offerTokenForSaleToAddress(
        address contractAddress,
        uint256 tokenIndex,
        uint256 minSalePriceInWei,
        address toAddress
    ) external collectionMustBeEnabled(contractAddress) onlyIfTokenOwner(contractAddress, tokenIndex) nonReentrant() {
        if (collectionState[contractAddress].erc1155) {
            require(IERC1155(contractAddress).isApprovedForAll(msg.sender, address(this)), "Marketplace not approved to spend token on seller behalf.");
        } else {
            require(IERC721(contractAddress).getApproved(tokenIndex) == address(this), "Marketplace not approved to spend token on seller behalf.");
        }
        tokenOffers[contractAddress][tokenIndex] = Offer(true, tokenIndex, msg.sender, minSalePriceInWei, toAddress);
        emit TokenOffered(contractAddress, tokenIndex, minSalePriceInWei, toAddress);
    }

    // Remove token listing (offer)
    function tokenNoLongerForSale(
        address contractAddress,
        uint256 tokenIndex
    ) public collectionMustBeEnabled(contractAddress) onlyIfTokenOwner(contractAddress, tokenIndex) nonReentrant() {
        tokenOffers[contractAddress][tokenIndex] = Offer(false, tokenIndex, msg.sender, 0, address(0x0));
        emit TokenNoLongerForSale(contractAddress, tokenIndex);
    }

    /*************************
    Bidding
    **************************/

    // Open bid on a token
    function enterBidForToken(
        address contractAddress,
        uint256 tokenIndex
    ) external payable collectionMustBeEnabled(contractAddress) notIfTokenOwner(contractAddress, tokenIndex) nonReentrant() {
        require(msg.value > 0, "Must bid some amount of Ether.");
        Bid memory existing = tokenBids[contractAddress][tokenIndex];
        require(msg.value > existing.value, "Must bid higher than current bid.");
        // Refund the failing bid
        pendingBalance[existing.bidder] = pendingBalance[existing.bidder].add(existing.value);
        tokenBids[contractAddress][tokenIndex] = Bid(true, tokenIndex, msg.sender, msg.value);
        emit TokenBidEntered(contractAddress, tokenIndex, msg.value, msg.sender);
    }

    // Remove an open bid on a token
    function withdrawBidForToken(
        address contractAddress,
        uint256 tokenIndex
    ) external payable collectionMustBeEnabled(contractAddress) notIfTokenOwner(contractAddress, tokenIndex) nonReentrant() {
        Bid memory bid = tokenBids[contractAddress][tokenIndex];
        require(msg.sender == bid.bidder, "Only original bidder can withdraw this bid.");
        emit TokenBidWithdrawn(contractAddress, tokenIndex, bid.value, msg.sender);
        uint256 amount = bid.value;
        tokenBids[contractAddress][tokenIndex] = Bid(false, tokenIndex, address(0x0), 0);
        // Refund the bid money
        payable(msg.sender).transfer(amount);
    }

    /*************************
    Sales
    **************************/

    // Buyer accepts an offer to buy the token
    function acceptOfferForToken(
        address contractAddress,
        uint256 tokenIndex
    ) external payable collectionMustBeEnabled(contractAddress) notIfTokenOwner(contractAddress, tokenIndex) nonReentrant() {
        Offer memory offer = tokenOffers[contractAddress][tokenIndex];
        address seller = offer.seller;
        address buyer = msg.sender;
        uint256 amount = msg.value;

        // Checks
        require(amount >= offer.minValue, "Not enough Ether sent.");
        require(offer.isForSale, "Token must be for sale by owner.");
        if (offer.onlySellTo != address(0x0)) {
            require(buyer == offer.onlySellTo, "Offer applies to other address.");
        }

        // Confirm ownership then transfer the token from seller to buyer
        if (collectionState[contractAddress].erc1155) {
            require(IERC1155(contractAddress).balanceOf(seller, tokenIndex) > 0, "Seller is no longer the owner, cannot accept offer.");
            require(IERC1155(contractAddress).isApprovedForAll(seller, address(this)), "Marketplace not approved to spend token on seller behalf.");
            IERC1155(contractAddress).safeTransferFrom(seller, buyer, tokenIndex, 1, bytes(""));
        } else {
            require(seller == IERC721(contractAddress).ownerOf(tokenIndex), "Seller is no longer the owner, cannot accept offer.");
            require(IERC721(contractAddress).getApproved(tokenIndex) == address(this), "Marketplace not approved to spend token on seller behalf.");
            IERC721(contractAddress).safeTransferFrom(seller, buyer, tokenIndex);
        }

        // Remove token offers
        tokenOffers[contractAddress][tokenIndex] = Offer(false, tokenIndex, buyer, 0, address(0x0));

        // Take cut for the project if royalties
        collectRoyalties(contractAddress, seller, amount);

        // Check for the case where there is a bid from the new owner and refund it.
        // Any other bid can stay in place.
        Bid memory bid = tokenBids[contractAddress][tokenIndex];
        if (bid.bidder == buyer) {
            // Kill bid and refund value
            pendingBalance[buyer] = pendingBalance[buyer].add(bid.value);
            tokenBids[contractAddress][tokenIndex] = Bid(false, tokenIndex, address(0x0), 0);
        }

        // Emit token events
        emit TokenTransfer(contractAddress, seller, buyer, tokenIndex);
        emit TokenNoLongerForSale(contractAddress, tokenIndex);
        emit TokenBought(contractAddress, tokenIndex, amount, seller, buyer);
    }

    // Seller accepts a bid to sell the token
    function acceptBidForToken(
        address contractAddress,
        uint256 tokenIndex,
        uint256 minPrice
    ) external payable collectionMustBeEnabled(contractAddress) onlyIfTokenOwner(contractAddress, tokenIndex) nonReentrant() {
        Bid memory bid = tokenBids[contractAddress][tokenIndex];
        address seller = msg.sender;
        address buyer = bid.bidder;
        uint256 amount = bid.value;

        // Checks
        require(bid.hasBid == true, "Bid must be active.");
        require(amount > 0, "Bid must be greater than 0.");
        require(amount >= minPrice, "Bid must be greater than minimum price.");

        // Confirm ownership then transfer the token from seller to buyer
        if (collectionState[contractAddress].erc1155) {
            require(IERC1155(contractAddress).balanceOf(seller, tokenIndex) > 0, "Seller is no longer the owner, cannot accept offer.");
            require(IERC1155(contractAddress).isApprovedForAll(seller, address(this)), "Marketplace not approved to spend token on seller behalf.");
            IERC1155(contractAddress).safeTransferFrom(seller, buyer, tokenIndex, 1, bytes(""));
        } else {
            require(seller == IERC721(contractAddress).ownerOf(tokenIndex), "Seller is no longer the owner, cannot accept offer.");
            require(IERC721(contractAddress).getApproved(tokenIndex) == address(this), "Marketplace not approved to spend token on seller behalf.");
            IERC721(contractAddress).safeTransferFrom(seller, buyer, tokenIndex);
        }

        // Remove token offers
        tokenOffers[contractAddress][tokenIndex] = Offer(false, tokenIndex, buyer, 0, address(0x0));

        // Take cut for the project if royalties
        collectRoyalties(contractAddress, seller, amount);

        // Clear bid
        tokenBids[contractAddress][tokenIndex] = Bid(false, tokenIndex, address(0x0), 0);

        // Emit token events
        emit TokenTransfer(contractAddress, seller, buyer, tokenIndex);
        emit TokenNoLongerForSale(contractAddress, tokenIndex);
        emit TokenBought(contractAddress, tokenIndex, amount, seller, buyer);
    }

    /*************************
    Fund management
    **************************/

    function withdraw() external nonReentrant() {
        uint256 amount = pendingBalance[msg.sender];
        // Zero the pending refund before
        // sending to prevent re-entrancy attacks
        pendingBalance[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }

    /*************************
    Internal
    **************************/

    // Take cut for the project if royalties
    function collectRoyalties(address contractAddress, address seller, uint256 amount) private {
        // ownerRoyalty = amount / (100 / royalty)
        // sellerReceives = amount - ownerRoyalty
        // amount = ownerRoyalty + sellerReceives
        if (collectionState[contractAddress].royaltyPercent > 0) {
            uint256 hundo = 100;
            address owner = Ownable(contractAddress).owner();
            uint256 collectionRoyalty = amount.div(hundo.div(collectionState[contractAddress].royaltyPercent));
            uint256 sellerAmount = amount.sub(collectionRoyalty);
            pendingBalance[seller] = pendingBalance[seller].add(sellerAmount);
            pendingBalance[owner] = pendingBalance[owner].add(collectionRoyalty);
        }
    }

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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

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
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

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
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

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