// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./NFTAuction.sol";

contract MetaSpacecyAuction is NFTAuction {
  constructor(
    address _metaspacecyAccessControls,
    uint16 _minimumSettableIncreasePercentage,
    uint16 _protocolFeePercentage,
    address _protocolFeeRecipient
  ) {
    metaspacecyAccessControls = MetaSpacecyAccessControls(_metaspacecyAccessControls);
    minimumSettableIncreasePercentage = _minimumSettableIncreasePercentage;
    protocolFeePercentage = _protocolFeePercentage;
    protocolFeeRecipient = _protocolFeeRecipient;
  }

  function name() public pure returns (string memory) {
    return "MetaSpacecy Auction";
  }

  function symbol() public pure returns (string memory) {
    return "MSA";
  }

  function factorySchemaName() public pure returns (string memory) {
    return "ERC721";
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../interfaces/IERC721.sol";
import "../token/ERC20/IERC20.sol";
import "../utils/Context.sol";
import "../utils/ReentrancyGuard.sol";
import "../access/MetaSpacecyAccessControls.sol";

contract NFTAuction is Context, ReentrancyGuard {
  MetaSpacecyAccessControls public metaspacecyAccessControls;

  struct Auction {
    uint256 minPrice;
    uint256 startTime;
    uint256 endTime;
    uint256 nftHighestBid;
    uint256[] batchTokenIds;
    uint16 bidIncreasePercentage;
    address nftHighestBidder;
    address nftSeller;
    address nftRecipient;
    address paymentToken;
  }

  uint16 public minimumSettableIncreasePercentage;
  address public protocolFeeRecipient;
  uint16 public protocolFeePercentage;
  uint16 public constant DELAY_SETTLE_TIME = 60*60;
  bool public allAllowedCreate = true;

  mapping(address => mapping(uint256 => Auction)) public nftContractAuctions;
  mapping(address => uint256) public failedTransferCredits;
  
  event NftAuctionCreated(
    address indexed nftContractAddress,
    uint256 indexed tokenId,
    address nftSeller,
    address paymentToken,
    uint256 minPrice,
    uint256 startTime,
    uint256 indexed endTime,
    uint16 bidIncreasePercentage
  );

  event NftBatchAuctionCreated(
    address indexed nftContractAddress,
    uint256 indexed masterTokenId,
    uint256[] batchTokens,
    address nftSeller,
    address paymentToken,
    uint256 minPrice,
    uint256 startTime,
    uint256 indexed endTime,
    uint16 bidIncreasePercentage
  );

  event BidMade(
    address indexed nftContractAddress,
    uint256 indexed tokenId,
    address bidder,
    address paymentToken,
    uint256 amount
  );

  event NFTTransferredAndSellerPaid(
    address nftContractAddress,
    uint256 tokenId,
    uint256 nftHighestBid,
    address nftHighestBidder,
    address nftSeller,
    address nftRecipient
  );

  event AuctionSettled(
    address indexed nftContractAddress,
    uint256 indexed tokenId,
    uint256 nftHighestBid,
    address auctionSettler
  );

  event AuctionCancelled(
    address nftContractAddress,
    uint256 tokenId,
    address nftSeller
  );

  event BidWithdrawn(
    address nftContractAddress,
    uint256 tokenId,
    address highestBidder
  );

  event MinimumPriceUpdated(
    address nftContractAddress,
    uint256 tokenId,
    uint256 newMinPrice
  );

  event HighestBidTaken(
    address nftContractAddress,
    uint256 tokenId
  );

  modifier onlyAdmin() {
    require(metaspacecyAccessControls.hasAdminRole(_msgSender()), "only admin");
    _;
  }

  modifier canCreateAuction() {
    if (!allAllowedCreate) {
      require(metaspacecyAccessControls.hasAdminRole(_msgSender()) || metaspacecyAccessControls.hasMinterRole(_msgSender()), "only admin or minter");
    }
    _;
  }

  modifier auctionOngoing(address _nftContractAddress, uint256 _tokenId) {
    require(
      _isAuctionOngoing(_nftContractAddress, _tokenId),
      "Auction has ended"
    );
    _;
  }

  modifier priceGreaterThanZero(uint256 _price) {
    require(_price > 0, "Price cannot be 0");
    _;
  }

  modifier notNftSeller(address _nftContractAddress, uint256 _tokenId) {
    require(
      _msgSender() != nftContractAuctions[_nftContractAddress][_tokenId].nftSeller,
      "Owner cannot bid on own NFT"
    );
    _;
  }

  modifier onlyNftSeller(address _nftContractAddress, uint256 _tokenId) {
    require(
      _msgSender() == nftContractAuctions[_nftContractAddress][_tokenId].nftSeller,
      "Only nft seller"
    );
    _;
  }

  modifier settleAuctionMeetsRequirements(address _nftContractAddress, uint256 _tokenId) {
    require(
      _doesSettleMeetRequirements(_nftContractAddress, _tokenId),
      "Only nft seller or contract owner"
    );
    _;
  }

  modifier bidAmountMeetsBidRequirements(
    address _nftContractAddress,
    uint256 _tokenId,
    uint256 _tokenAmount
  ) {
    require(
      _doesBidMeetBidRequirements(
        _nftContractAddress,
        _tokenId,
        _tokenAmount
      ),
      "Not enough funds to bid on NFT"
    );
    _;
  }

  modifier minimumBidNotMade(address _nftContractAddress, uint256 _tokenId) {
    require(
      !_isMinimumBidMade(_nftContractAddress, _tokenId),
      "The auction has a valid bid made"
    );
    _;
  }

  modifier paymentAccepted(
    address _nftContractAddress,
    uint256 _tokenId,
    address _paymentToken,
    uint256 _amount
  ) {
    require(
      _isPaymentAccepted(
        _nftContractAddress,
        _tokenId,
        _paymentToken,
        _amount
      )
    );
    _;
  }

  modifier isAuctionOver(address _nftContractAddress, uint256 _tokenId) {
    require(
      !_isAuctionOngoing(_nftContractAddress, _tokenId),
      "Auction is not yet over"
    );
    _;
  }

  modifier increasePercentageAboveMinimum(uint16 _bidIncreasePercentage) {
    require(
      _bidIncreasePercentage >= minimumSettableIncreasePercentage,
      "Bid increase percentage too low"
    );
    _;
  }

  /**********************************
    *        Check functions
    **********************************/

  /**
    * @notice Check the status of an auction
    * @param _nftContractAddress The address of NFT collectible
    * @param _tokenId Token id of NFT item in collectible
    * @return True if the auction is still going on and vice versa 
    */
  function _isAuctionOngoing(address _nftContractAddress, uint256 _tokenId)
    internal
    view
    returns (bool)
  {
    return (
      nftContractAuctions[_nftContractAddress][_tokenId].startTime <= block.timestamp &&
      nftContractAuctions[_nftContractAddress][_tokenId].endTime >= block.timestamp
    );
  }

  /**
    * @notice Check if a bid has been made. This is applicable in the early bid scenario
    * to ensure that if an auction is created after an early bid, the auction
    * begins appropriately or is settled if the buy now price is met.
    * @param _nftContractAddress The address of NFT collectible
    * @param _tokenId Token id of NFT item in collectible
    * @return True if there is a bid
    */
  function _isABidMade(address _nftContractAddress, uint256 _tokenId)
    internal
    view 
    returns (bool)
  {
    return (nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBid > 0);
  }

  /**
    * @notice if the minPrice is set by the seller, check that the highest bid meets or exceeds that price.
    * @param _nftContractAddress The address of NFT collectible
    * @param _tokenId Token id of NFT item in collectible
    */
  function _isMinimumBidMade(address _nftContractAddress, uint256 _tokenId)
    internal
    view
    returns (bool)
  {
    uint256 minPrice = nftContractAuctions[_nftContractAddress][_tokenId].minPrice;
    return minPrice > 0 &&
      (nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBid >= minPrice);
  }

  /**
    * @notice Check that a bid is applicable for the purchase of the NFT. The bid needs to be a % higher than the previous bid.
    * @param _nftContractAddress The address of NFT collectible
    * @param _tokenId Token id of NFT item in collectible
    */
  function _doesBidMeetBidRequirements(
    address _nftContractAddress,
    uint256 _tokenId,
    uint256 _tokenAmount
  ) internal view returns (bool) {
    uint256 nextBidAmount;
    if (nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBid == 0) {
      nextBidAmount = nftContractAuctions[_nftContractAddress][_tokenId].minPrice;
    } else {
      nextBidAmount = (nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBid * 
        (10000 + nftContractAuctions[_nftContractAddress][_tokenId].bidIncreasePercentage)) / 10000;
    }
    return (msg.value >= nextBidAmount || _tokenAmount >= nextBidAmount);
  }

  function _doesSettleMeetRequirements(address _nftContractAddress, uint256 _tokenId) internal view returns(bool) {
    if (_msgSender() == nftContractAuctions[_nftContractAddress][_tokenId].nftSeller) {
      return true;
    }
    if (metaspacecyAccessControls.hasAdminRole(_msgSender()) && nftContractAuctions[_nftContractAddress][_tokenId].endTime + DELAY_SETTLE_TIME <= block.timestamp) {
      return true;
    }
    return false;
  }

  function _isPaymentAccepted(
    address _nftContractAddress,
    uint256 _tokenId,
    address _paymentToken,
    uint256 _amount
  ) internal view returns (bool) {
    address paymentToken = nftContractAuctions[_nftContractAddress][_tokenId].paymentToken;
    if (paymentToken == address(0)) {
      return 
        _paymentToken == address(0) &&
        msg.value != 0 &&
        _amount == 0;
    } else {
      return
        msg.value == 0 &&
        paymentToken == _paymentToken &&
        _amount > 0;
    }
  }


  /**
    * @param _totalBid the total bid
    * @param _percentage percent of each bid
    * @return the percentage of the total bid (used to calculate fee payments)
    */
  function _getPortionOfBid(uint256 _totalBid, uint16 _percentage)
    internal
    pure
    returns (uint256)
  {
    return (_totalBid * _percentage) / 10000;
  }

  /**
    * @param _nftContractAddress The address of NFT collectible
    * @param _tokenId Token id of NFT item in collectible
    * @return Nft recipient when auction is finished
    */
  function _getNftRecipient(address _nftContractAddress, uint256 _tokenId)
    internal
    view
    returns (address)
  {
    address nftRecipient = nftContractAuctions[_nftContractAddress][_tokenId].nftRecipient;

    if (nftRecipient == address(0)) {
      return nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBidder;
    } else {
      return nftRecipient;
    }
  }

  /*************************************
    *      Transfer NFTs to Contract
    *************************************/

  /**
    * @notice Transfer an NFT to auction's contract
    * @param _nftContractAddress The address of NFT collectible
    * @param _tokenId Token id of NFT item in collectible
    */
  function _transferNftToAuctionContract(
    address _nftContractAddress,
    uint256 _tokenId
  ) internal {
    require(IERC721(_nftContractAddress).ownerOf(_tokenId) == _msgSender(), "Only owner can call this");
    IERC721(_nftContractAddress).transferFrom(_msgSender(), address(this), _tokenId);
  }

  /**
    * @notice Transfer batch of NFTs to auction's contract
    * @param _nftContractAddress The address of NFT collectible
    * @param _batchTokenIds Token id of NFT item in collectible
    */
  function _transferNftBatchToAuctionContract(
    address _nftContractAddress,
    uint256[] memory _batchTokenIds
  ) internal {
    for (uint256 i = 0; i < _batchTokenIds.length; i++) {
      require(IERC721(_nftContractAddress).ownerOf(_batchTokenIds[i]) == _msgSender(), "Only owner can call this");
      IERC721(_nftContractAddress).transferFrom(_msgSender(), address(this), _batchTokenIds[i]);
    }
    _reverseAndResetPreviousBid(_nftContractAddress, _batchTokenIds[0]);
    nftContractAuctions[_nftContractAddress][_batchTokenIds[0]].batchTokenIds = _batchTokenIds;
  }

  /****************************
    *     Auction creation
    ****************************/

  /**
    * @notice Set up primary parameters of an auction
    * @param _nftContractAddress The address of NFT collectible
    * @param _tokenId Token id of NFT item in collectible
    * @param _minPrice Minimum price
    * @param _startTime Time at chich auction started 
    * @param _endTime Time at which auction will be expired
    * @param _bidIncreasePercentage Increased percentage of each bid
    */
  function _setupAuction(
    address _nftContractAddress,
    uint256 _tokenId,
    address _paymentToken,
    uint256 _minPrice,
    uint256 _startTime,
    uint256 _endTime,
    uint16 _bidIncreasePercentage
  )
    internal
  {
    require(_startTime > block.timestamp && _startTime < _endTime, "invalid timestamp");
    nftContractAuctions[_nftContractAddress][_tokenId].paymentToken = _paymentToken;
    nftContractAuctions[_nftContractAddress][_tokenId].minPrice = _minPrice;
    nftContractAuctions[_nftContractAddress][_tokenId].startTime = _startTime;
    nftContractAuctions[_nftContractAddress][_tokenId].endTime = _endTime;
    nftContractAuctions[_nftContractAddress][_tokenId].bidIncreasePercentage = _bidIncreasePercentage;
    nftContractAuctions[_nftContractAddress][_tokenId].nftSeller = _msgSender();
  }

  /**
    * @notice Create an auction
    * @param _nftContractAddress The address of NFT collectible
    * @param _tokenId Token id of NFT item in collectible
    * @param _minPrice Minimum price
    * @param _startTime Time at chich auction started 
    * @param _endTime Time at which auction will be expired
    * @param _bidIncreasePercentage Increased percentage of each bid
    */
  function _createNewNftAuction(
    address _nftContractAddress,
    uint256 _tokenId,
    address _paymentToken,
    uint256 _minPrice,
    uint256 _startTime,
    uint256 _endTime,
    uint16 _bidIncreasePercentage
  ) internal {
    _transferNftToAuctionContract(_nftContractAddress, _tokenId);
    _setupAuction(
      _nftContractAddress,
      _tokenId,
      _paymentToken,
      _minPrice,
      _startTime,
      _endTime,
      _bidIncreasePercentage
    );
    emit NftAuctionCreated(
      _nftContractAddress,
      _tokenId,
      _msgSender(),
      _paymentToken,
      _minPrice,
      _startTime,
      _endTime,
      _bidIncreasePercentage
    );
  }

  function createNewNftAuction(
    address nftContractAddress,
    uint256 tokenId,
    address paymentToken,
    uint256 minPrice,
    uint256 startTime,
    uint256 endTime,
    uint16 bidIncreasePercentage
  )
    public
    canCreateAuction()
    priceGreaterThanZero(minPrice)
    increasePercentageAboveMinimum(bidIncreasePercentage)
  {
    _createNewNftAuction(
      nftContractAddress,
      tokenId,
      paymentToken,
      minPrice,
      startTime,
      endTime,
      bidIncreasePercentage
    );
  }

  /**
    * @notice Create an batch of NFTs auction
    * @param _nftContractAddress The address of NFT collectible
    * @param _batchTokenIds Batch of token id of NFT items in collectible
    * @param _minPrice Minimum price
    * @param _startTime Time at chich auction started 
    * @param _endTime Time at which auction will be expired
    * @param _bidIncreasePercentage Increased percentage of each bid
    */
  function _createBatchNftAuction(
    address _nftContractAddress,
    uint256[] memory _batchTokenIds,
    address _paymentToken,
    uint256 _minPrice,
    uint256 _startTime,
    uint256 _endTime,
    uint16 _bidIncreasePercentage
  ) internal {
    _transferNftBatchToAuctionContract(_nftContractAddress, _batchTokenIds);
    _setupAuction(
      _nftContractAddress,
      _batchTokenIds[0],
      _paymentToken,
      _minPrice,
      _startTime,
      _endTime,
      _bidIncreasePercentage
    );
    emit NftBatchAuctionCreated(
      _nftContractAddress,
      _batchTokenIds[0],
      _batchTokenIds,
      _msgSender(),
      _paymentToken,
      _minPrice,
      _startTime,
      _endTime,
      _bidIncreasePercentage
    );
  }

  function createBatchNftAuction(
    address nftContractAddress,
    uint256[] memory batchTokenIds,
    address paymentToken,
    uint256 minPrice,
    uint256 startTime,
    uint256 endTime,
    uint16 bidIncreasePercentage
  )
    public
    canCreateAuction()
    priceGreaterThanZero(minPrice)
    increasePercentageAboveMinimum(bidIncreasePercentage)
  {
    _createBatchNftAuction(
      nftContractAddress,
      batchTokenIds,
      paymentToken,
      minPrice,
      startTime,
      endTime,
      bidIncreasePercentage
    );
  }

  /*******************************
    *       Bid Functions
    *******************************/
  
  /**
    * @notice Make bid on ongoing auction
    * @param _nftContractAddress The address of NFT collectible
    * @param _tokenId Token id of NFT item in collectible
    */
  function _makeBid(
    address _nftContractAddress,
    uint256 _tokenId,
    address _paymentToken,
    uint256 _tokenAmount
  )
    internal
    notNftSeller(_nftContractAddress, _tokenId)
    paymentAccepted(_nftContractAddress, _tokenId, _paymentToken, _tokenAmount)
    bidAmountMeetsBidRequirements(_nftContractAddress, _tokenId, _tokenAmount)
  {
    _reversePreviousBidAndUpdateHighestBid(_nftContractAddress, _tokenId, _tokenAmount);
    uint256 amount = _paymentToken == address(0) ? msg.value : _tokenAmount;
    emit BidMade(_nftContractAddress, _tokenId, _msgSender(), _paymentToken, amount);
  }

  function makeBid(
    address nftContractAddress,
    uint256 tokenId,
    address paymentToken,
    uint256 tokenAmount
  )
    public
    payable
    auctionOngoing(nftContractAddress, tokenId)
  {
    _makeBid(nftContractAddress, tokenId, paymentToken, tokenAmount);
  }

  /**
    * @notice Make a custom bid on ongoing auction that lets bidder set up a NFT recipient as the auction is finished
    * @param nftContractAddress The address of NFT collectible
    * @param tokenId Token id of NFT item in collectible
    * @param nftRecipient A recipient when the auction is finished
    */
  function makeCustomBid(
    address nftContractAddress,
    uint256 tokenId,
    address nftRecipient,
    address paymentToken,
    uint256 tokenAmount
  )
    public
    payable
    auctionOngoing(nftContractAddress, tokenId)
  {
    require(nftRecipient != address(0));
    nftContractAuctions[nftContractAddress][tokenId].nftRecipient = nftRecipient;
    _makeBid(nftContractAddress, tokenId, paymentToken, tokenAmount);
  }

  /********************************
   *        Reset Functions
   ********************************/
  
  /**
    * @notice Reset an auction
    * @param _nftContractAddress The address of NFT collectible
    * @param _tokenId Token id of NFT item in collectible
    */
  function _resetAuction(address _nftContractAddress, uint256 _tokenId) internal {
    nftContractAuctions[_nftContractAddress][_tokenId].paymentToken = address(0);
    nftContractAuctions[_nftContractAddress][_tokenId].minPrice = 0;
    nftContractAuctions[_nftContractAddress][_tokenId].startTime = 0;
    nftContractAuctions[_nftContractAddress][_tokenId].endTime = 0;
    nftContractAuctions[_nftContractAddress][_tokenId].bidIncreasePercentage = 0;
    nftContractAuctions[_nftContractAddress][_tokenId].nftSeller = address(0);
  }

  /**
    * @notice Reset a bid
    * @param _nftContractAddress The address of NFT collectible
    * @param _tokenId Token id of NFT item in collectible
    */
  function _resetBids(address _nftContractAddress, uint256 _tokenId) internal {
    nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBidder = address(0);
    nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBid = 0;
    nftContractAuctions[_nftContractAddress][_tokenId].nftRecipient = address(0);
  }

  /********************************
    *         Update Bids
    ********************************/
  
  /**
    * @notice Update highest bid
    * @param _nftContractAddress The address of NFT collectible
    * @param _tokenId Token id of NFT item in collectible
    */
  function _updateHighestBid(
    address _nftContractAddress,
    uint256 _tokenId,
    uint256 _tokenAmount
  ) internal {
    address paymentToken = nftContractAuctions[_nftContractAddress][_tokenId].paymentToken;
    if (paymentToken == address(0)) {
      nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBid = msg.value;
    } else {
      IERC20(paymentToken).transferFrom(_msgSender(), address(this), _tokenAmount);
      nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBid = _tokenAmount;
    }
    nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBidder = _msgSender();
  }

  /**
    * @notice Set up new highest bid and reverse previous onw
    * @param _nftContractAddress The address of NFT collectible
    * @param _tokenId Token id of NFT item in collectible
    */
  function _reverseAndResetPreviousBid(
    address _nftContractAddress,
    uint256 _tokenId
  ) internal {
    address nftHighestBidder = nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBidder;
    uint256 nftHighestBid = nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBid;
    _resetBids(_nftContractAddress, _tokenId);
    _payout(_nftContractAddress, _tokenId , nftHighestBidder, nftHighestBid);
  }

  /**
    * @notice Set up new highest bid and reverse previous onw
    * @param _nftContractAddress The address of NFT collectible
    * @param _tokenId Token id of NFT item in collectible
    */
  function _reversePreviousBidAndUpdateHighestBid(
    address _nftContractAddress,
    uint256 _tokenId,
    uint256 _tokenAmount
  ) internal {
    address prevNftHighestBidder = nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBidder;
    uint256 prevNftHighestBid = nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBid;
    _updateHighestBid(_nftContractAddress, _tokenId, _tokenAmount);

    if (prevNftHighestBidder != address(0)) {
      _payout(_nftContractAddress, _tokenId, prevNftHighestBidder, prevNftHighestBid);
    }
  }

  /************************************
    *   Transfer NFT and Pay Seller
    ************************************/
  
  /**
    * @notice Set up new highest bid and reverse previous one
    * @param _nftContractAddress The address of NFT collectible
    * @param _tokenId Token id of NFT item in collectible
    */
  function _transferNftAndPaySeller(
    address _nftContractAddress,
    uint256 _tokenId
  ) internal {
    address _nftSeller = nftContractAuctions[_nftContractAddress][_tokenId].nftSeller;
    address _nftHighestBidder = nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBidder;
    address _nftRecipient = _getNftRecipient(_nftContractAddress, _tokenId);
    uint256 _nftHighestBid = nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBid;
    _resetBids(_nftContractAddress, _tokenId);
    _payFeesAndSeller(_nftContractAddress, _tokenId, _nftSeller, _nftHighestBid);
    //reset bid and transfer nft last to avoid reentrancy
    uint256[] memory batchTokenIds = nftContractAuctions[_nftContractAddress][_tokenId].batchTokenIds;
    uint256 numberOfTokens = batchTokenIds.length;
    if (numberOfTokens > 0) {
      for (uint256 i = 0; i < numberOfTokens; i++) {
        IERC721(_nftContractAddress).transferFrom(
          address(this),
          _nftRecipient,
          batchTokenIds[i]
        );
      }
    } else {
      IERC721(_nftContractAddress).transferFrom(
        address(this),
        _nftRecipient,
        _tokenId
      );
    }
    _resetAuction(_nftContractAddress, _tokenId);
    emit NFTTransferredAndSellerPaid(
      _nftContractAddress,
      _tokenId,
      _nftHighestBid,
      _nftHighestBidder,
      _nftSeller,
      _nftRecipient
    );
  }

  /**
    * @notice Pay fees and seller
    * @param _nftContractAddress The address of NFT collectible
    * @param _tokenId Token id of NFT item in collectible
    * @param _nftSeller Address of NFT's seller
    * @param _highestBid The highest bid 
    */
  function _payFeesAndSeller(
    address _nftContractAddress,
    uint256 _tokenId,
    address _nftSeller,
    uint256 _highestBid
  ) internal {
    uint256 serviceFee = _getPortionOfBid(_highestBid, protocolFeePercentage);
    _payout(_nftContractAddress, _tokenId , protocolFeeRecipient, serviceFee);
    _payout(_nftContractAddress, _tokenId ,_nftSeller, (_highestBid - serviceFee));
  }

  function _payout(
    address _nftContractAddress,
    uint256 _tokenId,
    address _recipient,
    uint256 _amount
  ) internal nonReentrant() {
    address paymentToken = nftContractAuctions[_nftContractAddress][_tokenId].paymentToken;
    if (paymentToken == address(0)) {
      (bool success, ) = payable(_recipient).call{value: _amount}("");
      if (!success) {
        failedTransferCredits[_recipient] = failedTransferCredits[_recipient] + _amount;
      }
    } else {
      IERC20(paymentToken).transfer(_recipient, _amount);
    }
  }

  /*********************************
    *      Settle and Withdraw
    *********************************/
  
  /**
    * @notice Settle auction when it is finished
    * @param nftContractAddress The address of NFT collectible
    * @param tokenId Token id of NFT item in collectible
    */
  function settleAuction(address nftContractAddress, uint256 tokenId)
    public
    isAuctionOver(nftContractAddress, tokenId)
    settleAuctionMeetsRequirements(nftContractAddress, tokenId)
  {
    //when no bider could trasfer nft in seller
    uint256 nftHighestBid;
    if (nftContractAuctions[nftContractAddress][tokenId].nftHighestBid == 0) {
      IERC721(nftContractAddress).transferFrom(
        address(this),
        nftContractAuctions[nftContractAddress][tokenId].nftSeller,
        tokenId
      );
      nftHighestBid = nftContractAuctions[nftContractAddress][tokenId].nftHighestBid;
      _resetAuction(nftContractAddress, tokenId);
    } else {
      nftHighestBid = nftContractAuctions[nftContractAddress][tokenId].nftHighestBid;
      _transferNftAndPaySeller(nftContractAddress, tokenId);
    }
    emit AuctionSettled(nftContractAddress, tokenId, nftHighestBid, _msgSender());
  }

  /**
    * @notice Cancel auction and withdraw NFT before a bid is made
    * @param nftContractAddress The address of NFT collectible
    * @param tokenId Token id of NFT item in collectible
    */
  function cancelAuction(address nftContractAddress, uint256 tokenId)
    public
    minimumBidNotMade(nftContractAddress, tokenId)
    onlyNftSeller(nftContractAddress, tokenId)
  {
    uint256[] memory batchTokenIds = nftContractAuctions[nftContractAddress][tokenId].batchTokenIds;
    uint256 numberOfTokens = batchTokenIds.length;
    if (numberOfTokens > 0) {
      for (uint256 i = 0; i < numberOfTokens; i++) {
        IERC721(nftContractAddress).transferFrom(
          address(this),
          nftContractAuctions[nftContractAddress][tokenId].nftSeller,
          batchTokenIds[i]
        );
      }
    } else {
      IERC721(nftContractAddress).transferFrom(
        address(this),
        nftContractAuctions[nftContractAddress][tokenId].nftSeller,
        tokenId
      );
    }
    _resetAuction(nftContractAddress, tokenId);
    emit AuctionCancelled(nftContractAddress, tokenId, _msgSender());
  }

  /**********************************
    *        Update Auction
    **********************************/
  
  /**
    * @notice Update minimum price
    * @param nftContractAddress The address of NFT collectible
    * @param tokenId Token id of NFT item in collectible
    * @param newMinPrice New min price
    */
  function updateMinimumPrice(
    address nftContractAddress,
    uint256 tokenId,
    uint256 newMinPrice
  )
    public
    onlyNftSeller(nftContractAddress, tokenId)
    minimumBidNotMade(nftContractAddress, tokenId)
    priceGreaterThanZero(newMinPrice)
  {
    nftContractAuctions[nftContractAddress][tokenId].minPrice = newMinPrice;
    emit MinimumPriceUpdated(nftContractAddress, tokenId, newMinPrice);
  }

  /**
    * @notice Owner of NFT can take the highest bid and end the auction
    * @param nftContractAddress The address of NFT collectible
    * @param tokenId Token id of NFT item in collectible
    */
  function takeHighestBid(address nftContractAddress, uint256 tokenId)
    public
    onlyNftSeller(nftContractAddress, tokenId)
  {
    require(
      _isABidMade(nftContractAddress, tokenId),
      "Cannot payout 0 bid"
    );
    uint256 nftHighestBid = nftContractAuctions[nftContractAddress][tokenId].nftHighestBid;
    _transferNftAndPaySeller(nftContractAddress, tokenId);
    emit HighestBidTaken(nftContractAddress, tokenId);
    emit AuctionSettled(nftContractAddress, tokenId, nftHighestBid, _msgSender());
  }

  /****************************************
    *         Other useful functions
    ****************************************/
  
  /**
    * @notice Read owner of a NFT item
    * @param _nftContractAddress The address of NFT collectible
    * @param _tokenId Token id of NFT item in collectible
    */
  function ownerOfNFT(address _nftContractAddress, uint256 _tokenId)
    public
    view
    returns (address)
  {
    address nftSeller = nftContractAuctions[_nftContractAddress][_tokenId].nftSeller;
    require(nftSeller != address(0), "NFT not deposited");

    return nftSeller;
  }

  /**
    * @notice Withdraw failed credits of bidder
    */
  function withdrawAllFailedCredits() public nonReentrant {
    uint256 amount = failedTransferCredits[_msgSender()];

    require(amount != 0, "no credits to withdraw");
    failedTransferCredits[_msgSender()] = 0;

    (bool successfulWithdraw, ) = _msgSender().call{
      value: amount,
      gas: 20000
    }("");
    require(successfulWithdraw, "withdraw failed");
  }

  /**
    * @notice Set up protocol fee
    * @param _protocolFeeRecipient Protocol's fee recipient
    * @param _protocolFeePercentage Protocol's fee percentage 
    */
  function setProtocolFee(address _protocolFeeRecipient, uint16 _protocolFeePercentage) public onlyAdmin {
    protocolFeeRecipient = _protocolFeeRecipient;
    protocolFeePercentage = _protocolFeePercentage;
  }

  /**
    *@notice Set all allowed create auction or retrict create auction
   */
  function setAllAllowedCreate() public onlyAdmin {
    allAllowedCreate = !allAllowedCreate;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

/**
 * @dev Interface of the ERC721 standard as defined in the EIP.
 */
interface IERC721 is IERC165 {
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApproveForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 */

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./MetaSpacecyAdminAccess.sol";

contract MetaSpacecyAccessControls is MetaSpacecyAdminAccess {
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
  bytes32 public constant TOKEN_MINTER_ROLE = keccak256("TOKEN_MINTER_ROLE");
  bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

  event MinterRoleGranted(address indexed beneficiary, address indexed caller);
  event MinterRoleRemoved(address indexed beneficiary, address indexed caller);
  event OperatorRoleGranted(address indexed beneficiary, address indexed caller);
  event OperatorRoleRemoved(address indexed beneficiary, address indexed caller);
  event TokenMinterRoleGranted(address indexed beneficiary, address indexed caller);
  event TokenMinterRoleRemoved(address indexed beneficiary, address indexed caller);

  function hasMinterRole(address _address) public view returns (bool) {
    return hasRole(MINTER_ROLE, _address);
  }

  function hasTokenMinterRole(address _address) public view returns (bool) {
    return hasRole(TOKEN_MINTER_ROLE, _address);
  }

  function hasOperatorRole(address _address) public view returns (bool) {
    return hasRole(OPERATOR_ROLE, _address);
  }

  function addMinterRole(address _beneficiary) external {
    grantRole(MINTER_ROLE, _beneficiary);
    emit MinterRoleGranted(_beneficiary, _msgSender());
  }

  function removeMinterRole(address _beneficiary) external {
    revokeRole(MINTER_ROLE, _beneficiary);
    emit MinterRoleRemoved(_beneficiary, _msgSender());
  }

  function addTokenMinterRole(address _beneficiary) external {
    grantRole(TOKEN_MINTER_ROLE, _beneficiary);
    emit TokenMinterRoleGranted(_beneficiary, _msgSender());
  }

  function removeTokenMinterRole(address _beneficiary) external {
    revokeRole(TOKEN_MINTER_ROLE, _beneficiary);
    emit TokenMinterRoleRemoved(_beneficiary, _msgSender());
  }

  function addOperatorRole(address _beneficiary) external {
    grantRole(OPERATOR_ROLE, _beneficiary);
    emit OperatorRoleGranted(_beneficiary, _msgSender());
  }

  function removeOperatorRole(address _beneficiary) external {
    revokeRole(OPERATOR_ROLE, _beneficiary);
    emit OperatorRoleRemoved(_beneficiary, _msgSender());
  }
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

import "./AccessControl.sol";

contract MetaSpacecyAdminAccess is AccessControl {
  bool private initAccess;

  event AdminRoleGranted(address indexed beneficiary, address indexed caller);
  event AdminRoleRemoved(address indexed beneficiary, address indexed caller);

  function initAccessControls(address _admin) public {
    require(!initAccess, "MSA: Already initialised");
    require(_admin != address(0), "MSA: zero address");
    _setupRole(DEFAULT_ADMIN_ROLE, _admin);
    initAccess = true;
  }

  function hasAdminRole(address _address) public view returns (bool) {
    return hasRole(DEFAULT_ADMIN_ROLE, _address);
  }

  function addAdminRole(address _beneficiary) external {
    grantRole(DEFAULT_ADMIN_ROLE, _beneficiary);
    emit AdminRoleGranted(_beneficiary, _msgSender());
  }

  function removeAdminRole(address _beneficiary) external {
    revokeRole(DEFAULT_ADMIN_ROLE, _beneficiary);
    emit AdminRoleRemoved(_beneficiary, _msgSender());
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";
import "../utils/libraries/EnumerableSet.sol";
import "../utils/introspection/ERC165.sol";
import "../interfaces/IAccessControl.sol";

abstract contract AccessControl is Context, IAccessControl, ERC165 {
  using EnumerableSet for EnumerableSet.AddressSet;

  struct RoleData {
    EnumerableSet.AddressSet members;
    bytes32 adminRole;
  }

  mapping(bytes32 => RoleData) private _roles;
  bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
  }

  function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
    return _roles[role].members.contains(account);
  }

  function getRoleMemberCount(bytes32 role) public view returns (uint256) {
    return _roles[role].members.length();
  }

  function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
    return _roles[role].members.at(index);
  }

  function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
    return _roles[role].adminRole;
  }

  function grantRole(bytes32 role, address account) public virtual override {
    require(hasRole(_roles[role].adminRole, _msgSender()), "AC: must be an admin");
    _grantRole(role, account);
  }

  function revokeRole(bytes32 role, address account) public virtual override {
    require(hasRole(_roles[role].adminRole, _msgSender()), "AC: must be an admin");
    _revokeRole(role, account);
  }

  function renounceRole(bytes32 role, address account) public virtual override {
    require(account == _msgSender(), "AC: must renounce yourself");
    _revokeRole(role, account);
  }

  function _setupRole(bytes32 role, address account) internal virtual {
    _grantRole(role, account);
  }

  function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
    emit RoleAdminChanged(role, _roles[role].adminRole, adminRole);
    _roles[role].adminRole = adminRole;
  }

  function _grantRole(bytes32 role, address account) private {
    if (_roles[role].members.add(account)) {
      emit RoleGranted(role, account, _msgSender());
    }
  }

  function _revokeRole(bytes32 role, address account) private {
    if (_roles[role].members.remove(account)) {
      emit RoleRevoked(role, account, _msgSender());
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library EnumerableSet {
  struct Set {
    bytes32[] _values;
    mapping (bytes32 => uint256) _indexes;
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

    if (valueIndex != 0) { // Equivalent to contains(set, value)
      // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
      // the array, and then remove the last element (sometimes called as 'swap and pop').
      // This modifies the order of the array, as noted in {at}.

      uint256 toDeleteIndex = valueIndex - 1;
      uint256 lastIndex = set._values.length - 1;

      // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
      // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

      bytes32 lastvalue = set._values[lastIndex];

      // Move the last value to the index where the value to delete is
      set._values[toDeleteIndex] = lastvalue;
      // Update the index for the moved value
      set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

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
    require(set._values.length > index, "EnumerableSet: index out of bounds");
    return set._values[index];
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
}

// SPDX-License-Identifier: MIT

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
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IAccessControl {
  /**
    * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
    *
    * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
    * {RoleAdminChanged} not being emitted signaling this.
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