// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


error PriceNotMet(address nftAddress, uint256 tokenId, uint256 price);
error ItemNotForSale(address nftAddress, uint256 tokenId);
error NotListed(address nftAddress, uint256 tokenId);
error AlreadyListed(address nftAddress, uint256 tokenId);
error NoProceeds();
error NotOwner();
error NotApprovedForMarketplace();
error PriceMustBeAboveZero();
error PriceMustBeAbovePlatformFee();
error NFTIsNotInAuctioned();
error NFTIsAlreadyAuctioned();
error NewBidMustBeHigher(uint256 previousBid, uint256 newBid);
error ReservedPriceMustBeAboveZero();
error AuctionHasNotEndedYet();
error AuctionIsNotInProgress();
error OnlyContractOwnerCanSetPlatformFee();



contract NftMarketplace is ReentrancyGuard {


    enum AuctionState{
        AuctionInProgress,
        AuctionEnded
    }

    struct Listing {
        uint256 price;
        address seller;
    }

    struct Auction{
        address bidder;
        uint256 bid;
        uint256 endTime;
        AuctionState state;
    }

    event ItemListed(
        address indexed seller,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 price
    );

    event ItemCanceled(
        address indexed seller,
        address indexed nftAddress,
        uint256 indexed tokenId
    );

    event ItemBought(
        address indexed buyer,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 price
    );

    event AuctionCreated(
        uint256 indexed endTime,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 reservedPrice

    );

    event AuctionBiddedSuccessfully(
        
        address indexed nftAddress,
        uint256 indexed tokenId,
        address indexed bidder,
        uint256  bid

    );
    event AuctionEndedSuccessfully(
        address indexed nftAddress,
        uint256 indexed tokenId,
        address indexed bidder,
        uint256 bid
    );
    event AuctionEndedUnSuccessfully(
        address indexed nftAddress,
        uint256 indexed tokenId
       
    );

    mapping(address => mapping(uint256 => Listing)) private s_listings;
    mapping(address => uint256) private s_proceeds;

    // NftAddress => TokenId => Auction
    mapping(address => mapping(uint256 => Auction)) private s_auctions;


    modifier isListed(address nftAddress, uint256 tokenId) {
        if (s_listings[nftAddress][tokenId].price <= 0) {
            revert NotListed(nftAddress, tokenId);
        }
        _;
    }

    modifier isOwner(
        address nftAddress,
        uint256 tokenId,
        address spender
    ) {
        address owner = IERC721(nftAddress).ownerOf(tokenId);
        if (spender != owner) {
            revert NotOwner();
        }
        _;
    }

    modifier isAuctioned(
        address nftAddress,
        uint256 tokenId
    ){
        if (s_auctions[nftAddress][tokenId].bid <= 0){
            revert NFTIsNotInAuctioned();
        }
        _;
    }
    modifier notAuctionedOrListed(
        address nftAddress,
        uint256 tokenId
    ){
        if (s_auctions[nftAddress][tokenId].bid > 0){
            revert NFTIsAlreadyAuctioned();
        }
       
        if (s_listings[nftAddress][tokenId].price > 0) {
            revert AlreadyListed(nftAddress, tokenId);
        }
        _;
    }



    // Storage Variable //
    address public immutable contractOwner;
    uint256 private s_platformFee;

    //Constructor///
    constructor (uint256 _platformFee){
        s_platformFee = _platformFee;
        contractOwner = msg.sender;
    }

    /////////////////////
    // Main Functions //
    /////////////////////

    function listItem(
        address nftAddress,
        uint256 tokenId,
        uint256 price
    )
        external
        notAuctionedOrListed(nftAddress, tokenId)
        isOwner(nftAddress, tokenId, msg.sender)
       
    {
        if (price <= 0) {
            revert PriceMustBeAboveZero();
        }
        if (IERC721(nftAddress).getApproved(tokenId) != address(this)) {
            revert NotApprovedForMarketplace();
        }
        s_listings[nftAddress][tokenId] = Listing(price, msg.sender);
        emit ItemListed(msg.sender, nftAddress, tokenId, price);
    }


    function cancelListing(address nftAddress, uint256 tokenId)
        external
        isOwner(nftAddress, tokenId, msg.sender)
        isListed(nftAddress, tokenId)
    {
        delete (s_listings[nftAddress][tokenId]);
        emit ItemCanceled(msg.sender, nftAddress, tokenId);
    }


    function buyItem(address nftAddress, uint256 tokenId)
        external
        payable
        isListed(nftAddress, tokenId)
        nonReentrant
    {
       
        Listing memory listedItem = s_listings[nftAddress][tokenId];
        if (msg.value < listedItem.price) {
            revert PriceNotMet(nftAddress, tokenId, listedItem.price);
        }
        s_proceeds[listedItem.seller] += msg.value;
        delete (s_listings[nftAddress][tokenId]);
        IERC721(nftAddress).safeTransferFrom(listedItem.seller, msg.sender, tokenId);
        emit ItemBought(msg.sender, nftAddress, tokenId, listedItem.price);
    }


    function updateListing(
        address nftAddress,
        uint256 tokenId,
        uint256 newPrice
    )
        external
        isListed(nftAddress, tokenId)
        nonReentrant
        isOwner(nftAddress, tokenId, msg.sender)
    {
        s_listings[nftAddress][tokenId].price = newPrice;
        emit ItemListed(msg.sender, nftAddress, tokenId, newPrice);
    }

   
    function withdrawProceeds() external {
        uint256 proceeds = s_proceeds[msg.sender];
        if (proceeds <= 0) {
            revert NoProceeds();
        }
        s_proceeds[msg.sender] = 0;
        (bool success, ) = payable(msg.sender).call{value: proceeds}("");
        require(success, "Transfer failed");
    }

    // 1- Not allow auction of NFT if it is already listed on the marketplace.✅
    // 2- Not allow auction of NFT if it is not approved for the marketplace.✅
    // 3- Not allow auction of NFT if it is not owned by the caller.✅
    // 4- Not allow auction of NfT if the price is less then platform fee.✅
    // 5- Add the platform fee to the owners account✅
    // --> Create a mapping for nft auction with nftAddress => tokenId => Auction
    // 6- set the time for Auction.

    // ---------> Minimun Auction Time Can be set
  
    function createAuction(address nftAddress, uint256 tokenID, uint256 timeInterval, uint256 reservedPrice) external payable isOwner(nftAddress , tokenID, msg.sender) 
      notAuctionedOrListed(nftAddress, tokenID) {

        if(msg.value < s_platformFee) {
            revert PriceMustBeAbovePlatformFee();
        }
        if(reservedPrice <= 0){
            revert ReservedPriceMustBeAboveZero();
        }
        if (IERC721(nftAddress).getApproved(tokenID) != address(this)) {
            revert NotApprovedForMarketplace();
        }
        s_proceeds[contractOwner] = s_proceeds[contractOwner] + msg.value;
        s_auctions[nftAddress][tokenID] = Auction(msg.sender, reservedPrice, (block.timestamp + timeInterval), AuctionState.AuctionInProgress );
        emit AuctionCreated((block.timestamp + timeInterval), nftAddress, tokenID, reservedPrice);

    }

  // 7- Create a mapping for the highest bidder and update if anyone bids higher then the previous highest bidder.
  // 8 - Create a modifier to check nft is in auction or not. isAuction(nftAddress, tokenID)
  // 9 - Revert if the bid is less then the previous bid✅
  // 10- If someone bids higher then the previous highest bidder, update the highest bidder. and also update the proceeds for the previous bidder with his bidding amount.
   function bidAuction(address nftAddress, uint256 tokenId, uint256 newBid) external payable isAuctioned(nftAddress, tokenId){
    Auction memory m_auction = s_auctions[nftAddress][tokenId];
    if(m_auction.bid > newBid){
        revert NewBidMustBeHigher(m_auction.bid, newBid);
    }
    if(m_auction.state != AuctionState.AuctionInProgress){
        revert AuctionIsNotInProgress();
    }
    address previousBidder = m_auction.bidder;
    uint256 previousBid = m_auction.bid;
    s_auctions[nftAddress][tokenId].bid = newBid;
    s_auctions[nftAddress][tokenId].bidder = msg.sender;

    s_proceeds[previousBidder] = s_proceeds[previousBidder] + previousBid;
    emit AuctionBiddedSuccessfully(nftAddress, tokenId, msg.sender, newBid);

   }


    // Using Chainlink Keeper Create a function that will execute the when the auction ends and transfer the Nft to the highest bidder.\
    //  ----------------------> For Implementing Chainlink  Keepers I need to create a seprate contract for the auction which will handle all the function of auction and also the checkup keep function and perform upkeep function of chainlink keepers.

    // ------------> New Way --> Create a function to end the auction that can only be called when the auction is ended.
    /*
    1 - Check if the auction is ended.
    2 - Check if the highest bidder is the same as the owner of the NFT.
    3 - Send the bid money to the nft owner
    3 - In Frontednd make sure that you are only showning end auction option when the auction is ended.
     */
    function endAuction(address nftAddress, uint256 tokenId) external isAuctioned(nftAddress, tokenId) nonReentrant{
        Auction memory m_auction = s_auctions[nftAddress][tokenId];
        if(m_auction.endTime > block.timestamp){
            revert AuctionHasNotEndedYet();
        }
        IERC721 nft = IERC721(nftAddress);
        address nftOwner = nft.ownerOf(tokenId);
        s_auctions[nftAddress][tokenId].state = AuctionState.AuctionEnded;
        delete(s_auctions[nftAddress][tokenId]);
        
        if(m_auction.bidder == nftOwner){
            emit AuctionEndedUnSuccessfully(nftAddress, tokenId);
        }
        else{
                s_proceeds[nftOwner] = s_proceeds[nftOwner] + m_auction.bid;
        nft.safeTransferFrom(nftOwner, m_auction.bidder, tokenId);

        emit AuctionEndedSuccessfully(nftAddress, tokenId, m_auction.bidder, m_auction.bid);

        }
    
    }


    

    /////////////////////
    // Getter Functions //
    /////////////////////
    function getListing(address nftAddress, uint256 tokenId)
        external
        view
        returns (Listing memory)
    {
        return s_listings[nftAddress][tokenId];
    }

    function getProceeds(address seller) external view returns (uint256) {
        return s_proceeds[seller];
    }

    function getPlatformFee() external view returns (uint256) {
        return s_platformFee;
    }

    //Setter Functions//

    function setPlatformFee(uint256 _platformFee) external {
        if(msg.sender != contractOwner){
            revert OnlyContractOwnerCanSetPlatformFee();
        }
        s_platformFee = _platformFee;
    }

    function getAuctionList (address nftAddress, uint256 tokenID) public view returns (Auction memory) {
        return s_auctions[nftAddress][tokenID];
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