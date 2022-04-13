/**
 *Submitted for verification at Etherscan.io on 2022-04-13
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;



// Part: OpenZeppelin/[email protected]/IERC165

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

// Part: OpenZeppelin/[email protected]/IERC20

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
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

// Part: OpenZeppelin/[email protected]/ReentrancyGuard

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

// Part: OpenZeppelin/[email protected]/IERC721

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

// File: Marketplace.sol

contract Marketplace is ReentrancyGuard {
    IERC20 public weth;
    address payable public immutable feeAccount;
    uint256 public immutable feePercent;
    uint256 public listingCount;

    struct Listing {
        uint256 listingId;
        uint256 tokenId;
        uint256 reservePrice;
        uint256 currentPrice;
        address payable seller;
        IERC721 nft;
        uint256 auctionState;
        uint256 closingTime;
        address payable buyer;
        uint256 bidCounter;
    }

    // auctionState legend: 1 = Open, 2 = Closed, 3 = Reverted

    mapping(uint256 => Listing) public listings;
    mapping(uint256 => IERC721) public listingNFT;
    mapping(uint256 => uint256) public listingTokenId;

    event Listed(uint256 indexed listingId, address indexed seller);

    event Bid(
        uint256 indexed listingId,
        uint256 bidPrice,
        address indexed seller,
        address indexed bidder
    );

    event Bought(
        uint256 indexed listingId,
        uint256 salePrice,
        address indexed seller,
        address indexed buyer
    );

    event Closed(uint256 indexed listingId, address seller, address buyer);
    event Reverted(
        uint256 listingId,
        address indexed seller,
        address indexed buyer
    );

    constructor(uint256 _feePercent, address _weth) {
        weth = IERC20(_weth);
        feeAccount = payable(msg.sender);
        feePercent = _feePercent;
    }

    function createListing(
        uint256 _reservePrice,
        uint256 _startPrice,
        uint256 _closingTime,
        uint256 _tokenId,
        IERC721 _nft
    ) external nonReentrant {
        require(_reservePrice >= 0, "Invalid reserve price");
        require(
            _reservePrice >= _startPrice,
            "Start price cannot be higher than reserve"
        );
        require(_closingTime >= (1), "Auction length must be at least 1 day");
        listingCount++;
        _nft.setApprovalForAll(address(this), true);
        _nft.safeTransferFrom(msg.sender, address(this), _tokenId);
        listings[listingCount] = Listing(
            listingCount,
            _tokenId,
            (_reservePrice * (10**16)),
            (_startPrice * (10**16)),
            payable(msg.sender),
            _nft,
            1,
            (block.timestamp + (_closingTime * 1 days)),
            payable(address(0)),
            0
        );
        emit Listed(listingCount, msg.sender);
    }

    function bid(uint256 _listingId, uint256 _bidPrice) external nonReentrant {
        uint256 bidPrice = _bidPrice * (10**16);
        Listing storage listing = listings[_listingId];
        require(
            weth.balanceOf(msg.sender) > listing.currentPrice,
            "You don't have enough ETH to cover this bid!"
        );
        require(
            bidPrice > listing.currentPrice,
            "Bid must be more than the current price, duh!"
        );
        require(listing.auctionState == 1, "This item is not open for bidding");
        listing.buyer = payable(msg.sender);
        weth.approve(address(this), bidPrice);
        listing.currentPrice = bidPrice;
        listing.bidCounter++;
        emit Bid(_listingId, bidPrice, listing.seller, listing.buyer);
    }

    function endAuction(uint256 _listingId) external nonReentrant {
        Listing memory listing = listings[_listingId];
        IERC721 nft = listing.nft;
        require(msg.sender == listing.buyer, "Action not authorized");
        require(
            block.timestamp > listing.closingTime,
            "Auction is still running"
        );
        if (weth.balanceOf(listing.buyer) < listing.currentPrice) {
            revert(
                "Buyer does not wETH balance to cover the sale price, sale reverted"
            );
            listing.auctionState = 3;
            emit Reverted(_listingId, listing.seller, listing.buyer);
        } else {
            weth.transferFrom(
                listing.buyer,
                listing.seller,
                listing.currentPrice * (1 - (feePercent / 100))
            );
            weth.transferFrom(
                listing.buyer,
                feeAccount,
                listing.currentPrice * (feePercent / 100)
            );
            nft.safeTransferFrom(address(this), listing.buyer, listing.tokenId);
            listing.auctionState = 2;
            emit Closed(listing.listingId, listing.seller, listing.seller);
        }
    }

    function cancelListing(uint256 _listingId) external nonReentrant {
        Listing memory listing = listings[_listingId];
        IERC721 nft = listing.nft;
        require(
            listing.auctionState == 1 || listing.auctionState == 3,
            "Action is not authorized"
        );
        uint256 feeAmount = listing.currentPrice * (feePercent / 100);
        weth.approve(address(this), feeAmount);
        require(
            weth.transferFrom(listing.seller, feeAccount, feeAmount),
            "Not enough funds to cancel listing"
        );
        nft.safeTransferFrom(address(this), listing.seller, listing.tokenId);
        listing.auctionState = 2;
    }
}