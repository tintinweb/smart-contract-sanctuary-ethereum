// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

error DiffusedMarketplace__TokenNotApprovedForMarketplace();
error DiffusedMarketplace__TokenAlreadyListed();
error DiffusedMarketplace__TokenNotListed();
error DiffusedMarketplace__NotOwner();
error DiffusedMarketplace__SellerNotOwner();
error DiffusedMarketplace__TokenAlreadyClaimed();
error DiffusedMarketplace__NoProceeds();
error DiffusedMarketplace__WithdrawFailed();
error DiffusedMarketplace__NullishAddress();
error DiffusedMarketplace__AuctionClosed();
error DiffusedMarketplace__MinBidIncrementNotMet();
error DiffusedMarketplace__MinBidIncrementOuOfRange();
error DiffusedMarketplace__DurationOutRange();
error DiffusedMarketplace__InsufficientBid();
error DiffusedMarketplace__DurationActive();
error DiffusedMarketplace__InsufficientAvailableFunds(
    uint256 available,
    uint256 required
);
error DiffusedMarketplace__InsufficientBidIncrement(
    uint256 expected,
    uint256 received
);

/**
 * @title Marketplace for diffused NFTs
 * @author Uladzimir Kireyeu
 * @notice Usage is strictly devoted to ai-generated
 * pictures
 * @dev You will have to deploy copy of this contract to
 * work with other nft contracts
 */
contract DiffusedMarketplace is ReentrancyGuard, Ownable {
    struct Bid {
        address bidder;
        uint256 amount;
        uint256 bidAt;
    }

    struct Listing {
        address seller;
        uint256 minimumBidIncrement;
        uint256 endDate;
        uint256 listedAt;
        Bid lastBid;
    }

    event TokenListed(
        uint256 indexed tokenId,
        address indexed seller,
        uint256 minimumBidIncrement,
        uint256 endDate,
        uint256 indexed listedAt,
        Bid lastBid
    );

    event ListingClosed(uint256 indexed tokenId, uint256 listedAt, Bid lastBid);

    event ListingBid(
        uint256 indexed tokenId,
        address indexed bidder,
        uint256 amount,
        uint256 indexed bidAt
    );

    mapping(uint256 => Listing) private s_listings;
    mapping(address => uint256) private s_funds;
    mapping(address => uint256) private s_lockedFunds;
    mapping(uint256 => address) private s_claims;
    IERC721 private immutable i_diffusedNfts;
    address private immutable i_diffusedNftsAddress;

    uint256 constant MINIMUM_MINIMUM_BID_INCREMENT = 2;
    uint256 constant MAXIMUM_MINIMUM_BID_INCREMENT = 15;
    uint256 constant MIN_DURATION = 10;
    uint256 constant MAX_DURATION = 57_600;
    uint256 constant MIN_OPENING_BID = 1000 gwei;

    constructor(address diffusedNftsAddress) {
        // Check that contract address is not nullish
        if (diffusedNftsAddress == address(0)) {
            revert DiffusedMarketplace__NullishAddress();
        }

        i_diffusedNftsAddress = diffusedNftsAddress;
        i_diffusedNfts = IERC721(i_diffusedNftsAddress);
    }

    /**
     * @notice Checks if token is listed already
     * @param tokenId TokenId in the DiffusedNfts
     * @return If token is listed true, if not - false
     */
    function ifListed(uint256 tokenId) private view returns (bool) {
        Listing memory listing = s_listings[tokenId];

        if (listing.seller == address(0) && s_claims[tokenId] == address(0)) {
            return false;
        }

        return true;
    }

    /**
     * @notice Transfers ownership to the marketplace
     * to avoid approving tokens due to the possibilty of
     * approving token to the new owner in the middle of auction.
     * Ownership will be transferred in the end of auction
     */
    function transferWithClaim(uint256 tokenId) private {
        s_claims[tokenId] = msg.sender;
        i_diffusedNfts.transferFrom(msg.sender, address(this), tokenId);
    }

    /**
     * @notice Lists item in the marketplace
     * @dev Token must be approved to the contract in advance
     * @param tokenId Token ID derived from the nft contract
     * @param openingBid Starting price of the listing
     * @param duration Amount of blocks until auction is closed
     * @param minimumBidIncrement Minimum percentag of bid increment (5% - 5)
     */
    function listToken(
        uint256 tokenId,
        uint256 openingBid,
        uint256 duration,
        uint256 minimumBidIncrement
    ) public {
        if (i_diffusedNfts.getApproved(tokenId) != address(this)) {
            revert DiffusedMarketplace__TokenNotApprovedForMarketplace();
        }

        if (i_diffusedNfts.ownerOf(tokenId) != msg.sender) {
            revert DiffusedMarketplace__SellerNotOwner();
        }

        if (openingBid < MIN_OPENING_BID) {
            revert DiffusedMarketplace__InsufficientBid();
        }

        if (MIN_DURATION > duration || MAX_DURATION < duration) {
            revert DiffusedMarketplace__DurationOutRange();
        }

        if (ifListed(tokenId)) {
            revert DiffusedMarketplace__TokenAlreadyListed();
        }

        if (
            minimumBidIncrement < MINIMUM_MINIMUM_BID_INCREMENT ||
            minimumBidIncrement > MAXIMUM_MINIMUM_BID_INCREMENT
        ) {
            revert DiffusedMarketplace__MinBidIncrementOuOfRange();
        }

        s_listings[tokenId] = Listing(
            msg.sender,
            minimumBidIncrement,
            block.number + duration,
            block.number,
            Bid(address(0), openingBid, block.number)
        );

        emit TokenListed(
            tokenId,
            msg.sender,
            minimumBidIncrement,
            block.number + duration,
            block.number,
            Bid(address(0), openingBid, block.number)
        );

        /**
         * Token is transferred to contract posession until
         * the auction is closed and user call callEndDate
         */
        transferWithClaim(tokenId);
    }

    /**
     * @notice Lists item in the marketplace
     * @dev Minimum bid increment is set as default
     * @param tokenId Token ID derived from the nft contract
     * @param openingBid Starting price of the listing
     * @param duration Amount of blocks until auction is closed
     */
    function listToken(
        uint256 tokenId,
        uint256 openingBid,
        uint256 duration
    ) public {
        if (ifListed(tokenId)) {
            revert DiffusedMarketplace__TokenAlreadyListed();
        }

        if (i_diffusedNfts.getApproved(tokenId) != address(this)) {
            revert DiffusedMarketplace__TokenNotApprovedForMarketplace();
        }

        if (i_diffusedNfts.ownerOf(tokenId) != msg.sender) {
            revert DiffusedMarketplace__SellerNotOwner();
        }

        if (openingBid < MIN_OPENING_BID) {
            revert DiffusedMarketplace__InsufficientBid();
        }

        if (MIN_DURATION > duration || MAX_DURATION < duration) {
            revert DiffusedMarketplace__DurationOutRange();
        }

        s_listings[tokenId] = Listing(
            msg.sender,
            MINIMUM_MINIMUM_BID_INCREMENT,
            block.number + duration,
            block.number,
            Bid(address(0), openingBid, 0)
        );

        emit TokenListed(
            tokenId,
            msg.sender,
            MINIMUM_MINIMUM_BID_INCREMENT,
            block.number + duration,
            block.number,
            Bid(address(0), openingBid, block.number)
        );

        /**
         * Token is transferred to contract posession until
         * the auction is closed and user call callEndDate
         */
        transferWithClaim(tokenId);
    }

    /**
     * @notice Makes a bid on the listing
     * @dev Initial price is set in the form of bid
     * @param tokenId Token ID derived from the nft contract
     * @param amount Amount of wei to stake
     */
    function bid(uint256 tokenId, uint256 amount) public payable {
        if (!ifListed(tokenId)) {
            revert DiffusedMarketplace__TokenNotListed();
        }

        if (amount < getMinBid(tokenId)) {
            revert DiffusedMarketplace__InsufficientBidIncrement({
                expected: getMinBid(tokenId),
                received: amount
            });
        }

        Listing memory listing = s_listings[tokenId];

        s_funds[msg.sender] += msg.value;
        uint256 availableFunds = s_funds[msg.sender];

        if (availableFunds < amount) {
            revert DiffusedMarketplace__InsufficientAvailableFunds({
                available: availableFunds,
                required: amount
            });
        }

        if (listing.endDate < block.number) {
            revert DiffusedMarketplace__AuctionClosed();
        }

        // Unlock balance of the previous bidder
        if (listing.lastBid.bidder != address(0)) {
            s_lockedFunds[listing.lastBid.bidder] -= listing.lastBid.amount;
        }

        emit ListingBid(tokenId, msg.sender, amount, block.number);

        // Amount is locked, available funds are decreased
        s_lockedFunds[msg.sender] += amount;
        s_funds[msg.sender] -= amount;
        s_listings[tokenId].lastBid = Bid(msg.sender, amount, block.number);
    }

    /**
     * @notice Check if end date has come and finishes exchange
     * or returns nft to the user
     * @dev Everybody will be able to run this function
     * on behalf of others
     * @param tokenId Token ID derived from the nft contract
     */
    function callEndDate(uint256 tokenId) public nonReentrant {
        Listing memory listing = s_listings[tokenId];

        if (!ifListed(tokenId)) {
            revert DiffusedMarketplace__TokenNotListed();
        }

        if (listing.endDate >= block.number) {
            revert DiffusedMarketplace__DurationActive();
        }

        if (listing.lastBid.bidder != address(0)) {
            // Unblock bidder's funds and withdraw it
            s_lockedFunds[listing.lastBid.bidder] -= listing.lastBid.amount;

            // Increase funds of the seller and remove listing with claim
            s_funds[listing.seller] += listing.lastBid.amount;
            delete s_claims[tokenId];
            delete s_listings[tokenId];

            emit ListingClosed(tokenId, listing.listedAt, listing.lastBid);
            i_diffusedNfts.transferFrom(
                address(this),
                listing.lastBid.bidder,
                tokenId
            );
        } else {
            delete s_claims[tokenId];
            delete s_listings[tokenId];

            emit ListingClosed(tokenId, listing.listedAt, listing.lastBid);
            i_diffusedNfts.transferFrom(address(this), listing.seller, tokenId);
        }
    }

    /**
     * @notice Allows user to withdraw their
     * proceeds locked in the  contract
     * @dev Fee of approximately 3.33% is payed for the service
     */
    function withdrawFunds() public nonReentrant {
        if (s_funds[msg.sender] <= 0) {
            revert DiffusedMarketplace__NoProceeds();
        }

        uint256 availableFunds = s_funds[msg.sender];
        uint256 totalFee = availableFunds / 30;
        uint256 finalSum;

        // Set user's funds to zero to prevent double-spending
        s_funds[msg.sender] = 0;

        // If user withdraws proceeds - fee of 3.33% is taken
        if (msg.sender != owner()) {
            s_funds[owner()] += totalFee;
            finalSum = availableFunds - totalFee;
        } else {
            finalSum = availableFunds;
        }

        // Fee of 3.33% gets locked in the contract
        (bool success, ) = address(msg.sender).call{value: finalSum}('');

        if (!success) {
            revert DiffusedMarketplace__WithdrawFailed();
        }
    }

    /**
     * @notice When user makes a bid they must know how much
     * wei they should transfer despite their locked balance. They
     * can always pay the full price with just msg.value, or combine it with their
     * existing balance
     * @param tokenId Token ID derived from the nft contract
     */
    function getAdditionalMsgValue(
        uint256 tokenId
    ) external view returns (int256) {
        if (!ifListed(tokenId)) {
            revert DiffusedMarketplace__TokenNotListed();
        }

        uint256 minBid = getMinBid(tokenId);
        // How much additional wei to send despite funds locked in the contract
        int256 difference = int256(s_funds[msg.sender]) - int256(minBid);

        if (difference < 0) {
            return -difference;
        } else {
            return 0;
        }
    }

    /**
     * @notice Gets minimum bid user must do if they want to stake some value
     * @param tokenId Token ID derived from the nft contract
     */
    function getMinBid(uint256 tokenId) public view returns (uint256) {
        Listing memory listing = s_listings[tokenId];

        // minBid = 100$ * 0.02
        return
            listing.lastBid.amount +
            (listing.lastBid.amount * listing.minimumBidIncrement) /
            100;
    }

    /**
     * @notice Allows user to increase their funds
     * @dev Created primarily for testing :)
     */
    function cashIn() public payable {
        s_funds[msg.sender] += msg.value;
    }

    // Removed due to the absence of need
    function renounceOwnership() public pure override {}

    function getListing(
        uint256 tokenId
    ) external view returns (Listing memory) {
        return s_listings[tokenId];
    }

    function getNftAddress() external view returns (address) {
        return i_diffusedNftsAddress;
    }

    function getFunds(address user) external view returns (uint256) {
        return s_funds[user];
    }

    function getLockedBalance(address user) external view returns (uint256) {
        return s_lockedFunds[user];
    }

    function getClaim(uint256 tokenId) external view returns (address) {
        return s_claims[tokenId];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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