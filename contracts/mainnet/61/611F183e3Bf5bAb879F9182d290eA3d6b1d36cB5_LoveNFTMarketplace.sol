// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.18;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/common/ERC2981.sol';
import './LoveRoles.sol';

/* Love NFT Marketplace
    List NFT,
    Buy NFT,
    Offer NFT,
    Accept offer,
    Create auction,
    Bid place,
    & support Royalty
*/
contract LoveNFTMarketplace is LoveRoles, ReentrancyGuard {
  uint256 public platformFee = 50;
  uint256 public platformListingFee = 1 ether;
  uint256 public constant MINIMUM_BUYING_FEE = 5 ether;
  IERC20 private loveToken;
  address private feeReceiver;
  uint256 public reservedBalance;

  constructor(address _loveToken, address tokenOwner) {
    transferOwnership(tokenOwner);
    loveToken = IERC20(_loveToken);
  }

  struct NFT {
    address addr;
    uint256 tokenId;
  }

  struct ListingParams {
    NFT nft;
    uint256 price;
    uint256 startTime;
    uint256 endTime;
  }

  struct ListNFT {
    NFT nft;
    address seller;
    uint256 price;
    uint256 startTime;
    uint256 endTime;
  }

  struct OfferNFT {
    NFT nft;
    address offerer;
    uint256 offerPrice;
    TokenRoyaltyInfo royaltyInfo;
    bool accepted;
  }

  struct OfferNFTParams {
    NFT nft;
    address offerer;
    uint256 price;
  }

  struct AuctionParams {
    NFT nft;
    uint256 initialPrice;
    uint256 minBidStep;
    uint256 startTime;
    uint256 endTime;
  }

  struct AuctionNFT {
    NFT nft;
    address creator;
    uint256 initialPrice;
    uint256 minBidStep;
    uint256 startTime;
    uint256 endTime;
    address lastBidder;
    uint256 highestBid;
    TokenRoyaltyInfo royaltyInfo;
    address winner;
    bool success;
  }

  struct TokenRoyaltyInfo {
    address royaltyReceiver;
    uint256 royaltyAmount;
  }

  // NFT => list struct
  mapping(bytes => ListNFT) private listNfts;

  // NFT => offerer address => offer price => offer struct
  mapping(bytes => mapping(address => mapping(uint256 => OfferNFT))) private offerNfts;

  // NFT => action struct
  mapping(bytes => AuctionNFT) private auctionNfts;

  // events
  event ChangedPlatformFee(uint256 newValue);
  event RewardSent(address[] addresses, uint[] amounts);
  event ChangedFeeReceiver(address newFeeReceiver);

  event ListedNFT(
    address indexed nftAddress,
    uint256 indexed tokenId,
    uint256 price,
    address indexed seller,
    uint256 startTime,
    uint256 endTime
  );

  event UpdateListedNFT(
    address indexed nftAddress,
    uint256 indexed tokenId,
    uint256 price,
    uint256 startTime,
    uint256 endTime
  );

  event CanceledListedNFT(
    address indexed nftAddress,
    uint256 indexed tokenId,
    uint256 price,
    address indexed seller,
    uint256 startTime,
    uint256 endTime
  );

  event BoughtNFT(
    address indexed nftAddress,
    uint256 indexed tokenId,
    uint256 price,
    address seller,
    address indexed buyer
  );
  event OfferedNFT(address indexed nftAddress, uint256 indexed tokenId, uint256 offerPrice, address indexed offerer);
  event CanceledOfferedNFT(
    address indexed nftAddress,
    uint256 indexed tokenId,
    uint256 offerPrice,
    address indexed offerer
  );
  event AcceptedNFT(
    address indexed nftAddress,
    uint256 indexed tokenId,
    uint256 offerPrice,
    address offerer,
    address indexed nftOwner
  );
  event CreatedAuction(
    address indexed nftAddress,
    uint256 indexed tokenId,
    uint256 price,
    uint256 minBidStep,
    uint256 startTime,
    uint256 endTime,
    address indexed creator
  );
  event PlacedBid(address indexed nftAddress, uint256 indexed tokenId, uint256 bidPrice, address indexed bidder);
  event CanceledAuction(address indexed nftAddress, uint256 indexed tokenId);

  event ResultedAuction(
    address indexed nftAddress,
    uint256 indexed tokenId,
    address creator,
    address indexed winner,
    uint256 price,
    address caller
  );

  modifier onlyListedNFT(NFT calldata nft) {
    ListNFT memory listedNFT = listNfts[abi.encode(nft)];
    require(
      listedNFT.seller != address(0) && listedNFT.price > 0 && block.timestamp <= listedNFT.endTime,
      'not listed'
    );
    _;
  }

  modifier onlyNotListed(NFT calldata nft) {
    ListNFT memory listedNFT = listNfts[abi.encode(nft)];
    require(listedNFT.seller == address(0) && listedNFT.price == 0, 'already listed');
    _;
  }

  modifier onAuction(NFT memory nft) {
    NFT memory auctionNft = auctionNfts[abi.encode(nft)].nft;
    require(auctionNft.addr == nft.addr && auctionNft.tokenId == nft.tokenId, 'auction is not created');
    _;
  }

  modifier notOnAuction(NFT calldata nft) {
    AuctionNFT memory auction = auctionNfts[abi.encode(nft)];
    require(auction.nft.addr == address(0) || auction.success, 'auction already created');
    _;
  }

  modifier onlyOfferedNFT(OfferNFTParams calldata params) {
    OfferNFT memory offer = offerNfts[abi.encode(params.nft)][params.offerer][params.price];
    require(offer.offerer == params.offerer && offer.offerPrice == params.price, 'not offered');
    require(!offer.accepted, 'already accepted');
    _;
  }

  /**
   * @notice List NFT on Marketplace
   * @param params The listing parameters (nft, tokenId, price, startTime, endTime)
   */
  function listNft(ListingParams calldata params) external returns (uint256) {
    require(block.timestamp <= params.startTime && params.endTime > params.startTime, 'invalid time range');
    require(params.price > MINIMUM_BUYING_FEE, 'less than minimum buying fee');

    IERC721 nftContract = IERC721(params.nft.addr);
    bytes memory encodedNft = abi.encode(params.nft);
    ListNFT memory listedNFT = listNfts[encodedNft];

    // If the NFT is already listed, the seller must be the same as the caller.
    if (listedNFT.seller != address(0)) {
      require(listedNFT.seller == msg.sender, 'not seller');
    } else {
      // Otherwise, the caller must be the owner of the NFT.
      require(nftContract.ownerOf(params.nft.tokenId) == msg.sender, 'not nft owner');
      // The caller must have enough tokens for the platform fee.
      require(loveToken.balanceOf(msg.sender) >= platformListingFee, 'no tokens for platform fee');
      // The caller must transfer the NFT to the marketplace contract.
      nftContract.transferFrom(msg.sender, address(this), params.nft.tokenId);
      // The caller must transfer the platform fee to the marketplace contract.
      loveToken.transferFrom(msg.sender, address(this), platformListingFee);
    }

    // Update the listing.
    listNfts[encodedNft] = ListNFT({
      nft: params.nft,
      price: params.price,
      seller: msg.sender,
      startTime: params.startTime,
      endTime: params.endTime
    });
    emit ListedNFT(params.nft.addr, params.nft.tokenId, params.price, msg.sender, params.startTime, params.endTime);
    return platformListingFee;
  }

  function getListedNFT(NFT calldata nft) external view returns (ListNFT memory) {
    return listNfts[abi.encode(nft)];
  }

  /**
   * @notice Cancel listed NFT
   * @param nft NFT address
   */
  function cancelListedNFT(NFT calldata nft) external onlyListedNFT(nft) {
    bytes memory encodedNft = abi.encode(nft);
    ListNFT memory listedNFT = listNfts[encodedNft];
    // Ensure the sender is the seller
    require(listedNFT.seller == msg.sender, 'not seller');

    delete listNfts[encodedNft];
    // Transfer the NFT back to the seller
    IERC721(nft.addr).safeTransferFrom(address(this), msg.sender, nft.tokenId);

    emit CanceledListedNFT(
      listedNFT.nft.addr,
      listedNFT.nft.tokenId,
      listedNFT.price,
      listedNFT.seller,
      listedNFT.startTime,
      listedNFT.endTime
    );
  }

  /**
   * @notice Buy NFT on Marketplace
   * @param nft NFT address
   * @param price listed price
   * @return priceWithRoyalty price with fees
   */
  function buyNFT(NFT calldata nft, uint256 price) external onlyListedNFT(nft) returns (uint256 priceWithRoyalty) {
    bytes memory encodedNft = abi.encode(nft);
    ListNFT memory listedNft = listNfts[encodedNft];
    require(price >= listedNft.price, 'less than listed price');

    delete listNfts[encodedNft];
    TokenRoyaltyInfo memory royaltyInfo = tryGetRoyaltyInfo(nft, price);
    transferRoyalty(royaltyInfo, msg.sender);
    // remove nft from listing
    (uint256 amount, uint256 buyingFee) = calculateFeeAndAmount(price);
    // transfer platform fee to marketplace contract
    loveToken.transferFrom(msg.sender, address(this), buyingFee);

    // Transfer payment to nft owner
    loveToken.transferFrom(msg.sender, listedNft.seller, amount);

    // Transfer NFT to buyer
    IERC721(nft.addr).safeTransferFrom(address(this), msg.sender, nft.tokenId);

    emit BoughtNFT(nft.addr, nft.tokenId, price, listedNft.seller, msg.sender);
    return price + royaltyInfo.royaltyAmount;
  }

  /**
   * @notice Offer NFT on Marketplace
   * @param params OfferNFTParams
   * @return offerPriceWithRoyalty offer price with royalty
   */
  function offerNFT(OfferNFTParams calldata params) external notOnAuction(params.nft) returns (uint256) {
    require(params.price > MINIMUM_BUYING_FEE, 'price less minimum commission');
    TokenRoyaltyInfo memory royaltyInfo = tryGetRoyaltyInfo(params.nft, params.price);
    uint256 offerPriceWithRoyalty = params.price + royaltyInfo.royaltyAmount;

    reservedBalance += offerPriceWithRoyalty;

    loveToken.transferFrom(msg.sender, address(this), offerPriceWithRoyalty);

    offerNfts[abi.encode(params.nft)][msg.sender][params.price] = OfferNFT({
      nft: params.nft,
      offerer: msg.sender,
      offerPrice: params.price,
      accepted: false,
      royaltyInfo: royaltyInfo
    });

    emit OfferedNFT(params.nft.addr, params.nft.tokenId, params.price, msg.sender);
    return offerPriceWithRoyalty;
  }

  /**
   * @notice Cancel offer
   * @param params The offer parameters (nft, tokenId, offerer, price)
   * @return offerPriceWithRoyalty offer price with royalty
   */
  function cancelOfferNFT(OfferNFTParams calldata params) external onlyOfferedNFT(params) returns (uint256) {
    require(params.offerer == msg.sender, 'not offerer');

    bytes memory encodedNft = abi.encode(params.nft);
    OfferNFT memory offer = offerNfts[encodedNft][params.offerer][params.price];
    delete offerNfts[encodedNft][params.offerer][params.price];

    uint256 offerPriceWithRoyalty = offer.offerPrice + offer.royaltyInfo.royaltyAmount;
    reservedBalance -= offerPriceWithRoyalty;

    loveToken.transfer(offer.offerer, offerPriceWithRoyalty);

    emit CanceledOfferedNFT(offer.nft.addr, offer.nft.tokenId, offer.offerPrice, params.offerer);
    return offerPriceWithRoyalty;
  }

  /**
   * @notice Accept offer
   * @param params The offer parameters (nft, tokenId, offerer, price)
   * @return amount amount transfer to seller
   */
  function acceptOfferNFT(
    OfferNFTParams calldata params
  ) external onlyOfferedNFT(params) nonReentrant returns (uint256) {
    bytes memory encodedNft = abi.encode(params.nft);
    OfferNFT storage offer = offerNfts[encodedNft][params.offerer][params.price];
    ListNFT memory list = listNfts[encodedNft];
    address from = address(this);
    // If the NFT is listed, the seller is the owner of the contract
    if (list.seller != address(0)) {
      require(msg.sender == list.seller, 'not listed owner');
      delete listNfts[encodedNft];
    } else {
      // If not, the seller is the owner of the NFT
      require(IERC721(params.nft.addr).ownerOf(params.nft.tokenId) == msg.sender, 'not nft owner');
      from = msg.sender;
    }

    TokenRoyaltyInfo memory royaltyInfo = offer.royaltyInfo;
    uint256 offerPriceWithRoyalty = params.price + royaltyInfo.royaltyAmount;

    // Release reserved balance
    reservedBalance -= offerPriceWithRoyalty;
    offer.accepted = true;

    transferRoyalty(royaltyInfo, address(this));

    // Calculate & Transfer platform fee
    (uint256 amount, ) = calculateFeeAndAmount(params.price);

    // Transfer LOVE to seller
    loveToken.transfer(msg.sender, amount);
    // Transfer NFT to offerer
    IERC721(params.nft.addr).safeTransferFrom(from, params.offerer, params.nft.tokenId);

    emit AcceptedNFT(params.nft.addr, params.nft.tokenId, params.price, params.offerer, msg.sender);
    return amount;
  }

  /**
   * @notice Create auction for NFT
   * @dev This function allows users to create an auction for an NFT
   * @param params The auction parameters (nft, tokenId, initialPrice, minBidStep, startTime, endTime)
   */
  function createAuction(AuctionParams calldata params) external notOnAuction(params.nft) {
    // Cast the nftAddress to the IERC721 interface
    IERC721 nft = IERC721(params.nft.addr);

    // Check if the caller is the owner of the NFT
    require(nft.ownerOf(params.nft.tokenId) == msg.sender, 'not nft owner');
    require(loveToken.balanceOf(msg.sender) >= platformListingFee, 'no tokens for platform fee');
    // The caller must transfer the platform fee to the marketplace contract.
    loveToken.transferFrom(msg.sender, address(this), platformListingFee);
    // Transfer the NFT from the caller to the contract
    nft.transferFrom(msg.sender, address(this), params.nft.tokenId);

    // Store the auction details in the auctionNfts mapping
    auctionNfts[abi.encode(params.nft)] = AuctionNFT({
      nft: params.nft,
      creator: msg.sender,
      initialPrice: params.initialPrice,
      minBidStep: params.minBidStep,
      startTime: params.startTime,
      endTime: params.endTime,
      lastBidder: address(0),
      highestBid: params.initialPrice,
      royaltyInfo: TokenRoyaltyInfo(address(0), 0),
      winner: address(0),
      success: false
    });

    emit CreatedAuction(
      params.nft.addr,
      params.nft.tokenId,
      params.initialPrice,
      params.minBidStep,
      params.startTime,
      params.endTime,
      msg.sender
    );
  }

  /**
   * @notice Cancel auction
   * @param nft NFT address
   */
  function cancelAuction(NFT calldata nft) external onAuction(nft) {
    bytes memory encodedNft = abi.encode(nft);
    AuctionNFT memory auction = auctionNfts[encodedNft];
    require(auction.creator == msg.sender, 'not auction creator');
    require(!auction.success, 'auction already success');
    require(auction.lastBidder == address(0), 'already have bidder');

    delete auctionNfts[encodedNft];
    IERC721(nft.addr).safeTransferFrom(address(this), msg.sender, nft.tokenId);

    emit CanceledAuction(nft.addr, nft.tokenId);
  }

  /**
   * @notice Place bid on auction
   * @param nft NFT address
   * @param bidPrice bid price (must be greater than highest bid + min bid step)
   * @return bidPriceWithRoyalty bid price with royalty
   */
  function bidPlace(NFT calldata nft, uint256 bidPrice) external onAuction(nft) nonReentrant returns (uint256) {
    AuctionNFT storage auction = auctionNfts[abi.encode(nft)];
    require(block.timestamp >= auction.startTime, 'auction not started');
    require(block.timestamp <= auction.endTime, 'auction ended');
    require(bidPrice >= auction.highestBid + auction.minBidStep, 'less than min bid price');

    TokenRoyaltyInfo memory royaltyInfo = tryGetRoyaltyInfo(nft, bidPrice);
    uint256 lastBidPriceWithRoyalty = 0;
    uint256 bidPriceWithRoyalty = bidPrice + royaltyInfo.royaltyAmount;

    if (auction.lastBidder != address(0)) {
      address lastBidder = auction.lastBidder;
      uint256 lastBidPrice = auction.highestBid;
      // Transfer back to last bidder
      lastBidPriceWithRoyalty = lastBidPrice + auction.royaltyInfo.royaltyAmount;
      loveToken.transfer(lastBidder, lastBidPriceWithRoyalty);
    }

    reservedBalance += bidPriceWithRoyalty - lastBidPriceWithRoyalty;
    // Set new highest bid price & bidder
    auction.lastBidder = msg.sender;
    auction.highestBid = bidPrice;
    auction.royaltyInfo = royaltyInfo;

    loveToken.transferFrom(msg.sender, address(this), bidPriceWithRoyalty);

    emit PlacedBid(nft.addr, nft.tokenId, bidPrice, msg.sender);
    return bidPriceWithRoyalty;
  }

  /**
   * @notice Result auctions
   * @param nft NFT
   */
  function resultAuction(NFT calldata nft) external returns (uint256) {
    uint amount = _resultAuction(nft);
    reservedBalance -= amount;
    return amount;
  }

  /**
   * @notice Result multiple auctions
   * @param nfts NFT (nftAddres, tokenId)
   */
  function resultAuctions(NFT[] calldata nfts) external returns (uint256) {
    uint256 totalAmount = 0;

    for (uint256 i = 0; i < nfts.length; i++) {
      // Result each auction and accumulate the amount transferred to the auction creator
      uint256 amount = _resultAuction(nfts[i]);
      totalAmount += amount;
    }
    reservedBalance -= totalAmount;
    return totalAmount;
  }

  /**
   * @notice Get auction info by NFT address and token id
   * @param nft NFT address
   * @return AuctionNFT struct
   */
  function getAuction(NFT calldata nft) external view returns (AuctionNFT memory) {
    return auctionNfts[abi.encode(nft)];
  }

  /**
   * @notice Transfer fee to fee receiver contract
   * @dev should set feeReceiver (updateFeeReceiver()) address before call this function
   * @param amount Fee amount
   */
  function transferFee(uint256 amount) external hasRole('admin') {
    require(feeReceiver != address(0), 'invalid feeReceiver address');
    require(getAvailableBalance() >= amount, 'insufficient balance (reserved)');
    require(loveToken.transfer(feeReceiver, amount), 'unable to transfer token');
  }

  /**
   * @notice Set platform fee
   * @param newPlatformFee new platform fee
   */
  function setPlatformFee(uint256 newPlatformFee) external onlyOwner {
    platformFee = newPlatformFee;
    emit ChangedPlatformFee(newPlatformFee);
  }

  /**
   * @notice Set platform fee contract (LoveDrop)
   * @param newFeeReceiver new fee receiver address
   */
  function updateFeeReceiver(address newFeeReceiver) external onlyOwner {
    require(newFeeReceiver != address(0), 'invalid address');
    feeReceiver = newFeeReceiver;

    emit ChangedFeeReceiver(newFeeReceiver);
  }

  /**
   * @notice Calculate fee and amount
   * @param price price
   * @return amount amount transfer to seller
   * @return fee fee transfer to marketplace contract
   */
  function calculateFeeAndAmount(uint256 price) public view returns (uint256 amount, uint256 fee) {
    uint256 fee1e27 = (price * platformFee * 1e27) / 100;
    uint256 fee = fee1e27 / 1e27;
    if (fee < MINIMUM_BUYING_FEE) {
      fee = MINIMUM_BUYING_FEE;
    }
    return (price - fee, fee);
  }

  /**
   * @notice Get available balance
   * @return availableBalance available balance (not reserved)
   */
  function getAvailableBalance() public view returns (uint256 availableBalance) {
    return loveToken.balanceOf(address(this)) - reservedBalance;
  }

  function _resultAuction(NFT calldata nft) internal onAuction(nft) returns (uint256) {
    AuctionNFT storage auction = auctionNfts[abi.encode(nft)];
    require(!auction.success, 'already resulted');
    require(block.timestamp > auction.endTime, 'auction not ended');
    address creator = auction.creator;
    address winner = auction.lastBidder;
    uint256 highestBid = auction.highestBid;
    if (winner == address(0)) {
      // If no one bid, transfer NFT back to creator
      delete auctionNfts[abi.encode(nft)];
      IERC721(nft.addr).safeTransferFrom(address(this), creator, nft.tokenId);
      emit CanceledAuction(nft.addr, nft.tokenId);
      return 0;
    }
    auction.success = true;
    auction.winner = winner;
    TokenRoyaltyInfo memory royaltyInfo = auction.royaltyInfo;
    // Calculate royalty fee and transfer to recipient
    transferRoyalty(royaltyInfo, address(this));

    // Calculate platform fee
    (uint256 amount, ) = calculateFeeAndAmount(highestBid);

    // Transfer to auction creator
    require(loveToken.transfer(creator, amount), 'transfer to creator failed');
    // Transfer NFT to the winner
    IERC721(nft.addr).safeTransferFrom(address(this), winner, nft.tokenId);

    emit ResultedAuction(nft.addr, nft.tokenId, creator, winner, highestBid, msg.sender);
    return highestBid + royaltyInfo.royaltyAmount;
  }

  function tryGetRoyaltyInfo(NFT calldata nft, uint256 price) internal view returns (TokenRoyaltyInfo memory) {
    TokenRoyaltyInfo memory royaltyInfo;
    if (ERC2981(nft.addr).supportsInterface(type(IERC2981).interfaceId)) {
      (address royaltyRecipient, uint256 amount) = IERC2981(nft.addr).royaltyInfo(nft.tokenId, price);
      if (amount > price / 5) amount = price / 5;
      royaltyInfo = TokenRoyaltyInfo(royaltyRecipient, amount);
    }
    return royaltyInfo;
  }

  function transferRoyalty(TokenRoyaltyInfo memory royaltyInfo, address from) internal {
    bool result;
    if (royaltyInfo.royaltyReceiver != address(0) && royaltyInfo.royaltyAmount > 0) {
      if (from == address(this)) {
        result = loveToken.transfer(royaltyInfo.royaltyReceiver, royaltyInfo.royaltyAmount);
      } else {
        result = loveToken.transferFrom(from, royaltyInfo.royaltyReceiver, royaltyInfo.royaltyAmount);
      }
      require(result, 'royalty transfer failed');
    }
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
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/common/ERC2981.sol)

pragma solidity ^0.8.0;

import "../../interfaces/IERC2981.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the NFT Royalty Standard, a standardized way to retrieve royalty payment information.
 *
 * Royalty information can be specified globally for all token ids via {_setDefaultRoyalty}, and/or individually for
 * specific token ids via {_setTokenRoyalty}. The latter takes precedence over the first.
 *
 * Royalty is specified as a fraction of sale price. {_feeDenominator} is overridable but defaults to 10000, meaning the
 * fee is specified in basis points by default.
 *
 * IMPORTANT: ERC-2981 only specifies a way to signal royalty information and does not enforce its payment. See
 * https://eips.ethereum.org/EIPS/eip-2981#optional-royalty-payments[Rationale] in the EIP. Marketplaces are expected to
 * voluntarily pay royalties together with sales, but note that this standard is not yet widely supported.
 *
 * _Available since v4.5._
 */
abstract contract ERC2981 is IERC2981, ERC165 {
    struct RoyaltyInfo {
        address receiver;
        uint96 royaltyFraction;
    }

    RoyaltyInfo private _defaultRoyaltyInfo;
    mapping(uint256 => RoyaltyInfo) private _tokenRoyaltyInfo;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @inheritdoc IERC2981
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) public view virtual override returns (address, uint256) {
        RoyaltyInfo memory royalty = _tokenRoyaltyInfo[_tokenId];

        if (royalty.receiver == address(0)) {
            royalty = _defaultRoyaltyInfo;
        }

        uint256 royaltyAmount = (_salePrice * royalty.royaltyFraction) / _feeDenominator();

        return (royalty.receiver, royaltyAmount);
    }

    /**
     * @dev The denominator with which to interpret the fee set in {_setTokenRoyalty} and {_setDefaultRoyalty} as a
     * fraction of the sale price. Defaults to 10000 so fees are expressed in basis points, but may be customized by an
     * override.
     */
    function _feeDenominator() internal pure virtual returns (uint96) {
        return 10000;
    }

    /**
     * @dev Sets the royalty information that all ids in this contract will default to.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setDefaultRoyalty(address receiver, uint96 feeNumerator) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: invalid receiver");

        _defaultRoyaltyInfo = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Removes default royalty information.
     */
    function _deleteDefaultRoyalty() internal virtual {
        delete _defaultRoyaltyInfo;
    }

    /**
     * @dev Sets the royalty information for a specific token id, overriding the global default.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: Invalid parameters");

        _tokenRoyaltyInfo[tokenId] = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Resets royalty information for the token id back to the global default.
     */
    function _resetTokenRoyalty(uint256 tokenId) internal virtual {
        delete _tokenRoyaltyInfo[tokenId];
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import '@openzeppelin/contracts/access/Ownable.sol';

contract LoveRoles is Ownable {
  mapping(address => mapping(string => bool)) private users;

  event RoleGranted(address indexed account, string role);
  event RoleRevoked(address indexed account, string role);

  modifier hasRole(string memory role) {
    require(users[msg.sender][role] || msg.sender == owner(), 'account doesnt have this role');
    _;
  }

  function grantRole(address account, string calldata role) external onlyOwner {
    require(!users[account][role], 'role already granted');
    users[account][role] = true;

    emit RoleGranted(account, role);
  }

  function revokeRole(address account, string calldata role) external onlyOwner {
    require(users[account][role], 'role already revoked');
    users[account][role] = false;

    emit RoleRevoked(account, role);
  }

  function checkRole(address accountToCheck, string calldata role) external view returns (bool) {
    return users[accountToCheck][role];
  }
}