// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// @creator: Fixfon
// @author:  Fixfon
// https://twitter.com/fixfondev
// https://github.com/fixfon

import '@openzeppelin/contracts/utils/Counters.sol';

// Created interface for ERC721 token to be used in this contract to call NFT contract

interface IERC721 {
  function tokenURI() external view returns (string memory);

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external;

  function transferFrom(
    address,
    address,
    uint256
  ) external;
}

contract Auction {
  using Counters for Counters.Counter;

  // Creating a struct to identify an auction item
  struct AuctionItem {
    uint256 id;
    address payable seller;
    uint256 nftTokenId;
    // mapping(address => uint256) bids;
    address highestBidder;
    uint256 highestBid;
    uint256 startPrice;
    uint256 buyNowPrice;
    uint256 startedAt;
    uint256 endAt;
    bool isSold;
    bool isEnded;
    bool isCanceled;
  }

  bool private locked;
  address payable public owner;
  uint256 private ownerCut;
  uint256 private ownerBalance;
  IERC721 public immutable contractAddress;
  Counters.Counter private _auctionIdCounter;
  mapping(uint256 => AuctionItem) public auctions;
  mapping(uint256 => mapping(address => uint256)) public bidList;

  // EVENTS
  event AuctionCreated(
    uint256 indexed auctionId,
    address seller,
    uint256 nftTokenId,
    uint256 startPrice,
    uint256 buyNowPrice,
    uint256 startedAt,
    uint256 endAt
  );

  event AuctionBid(uint256 indexed auctionId, address bidder, uint256 bid);

  event AuctionBuyNow(uint256 indexed auctionId, address buyer, uint256 bid);

  event BidderWithdraw(uint256 indexed auctionId, address bidder, uint256 bid);

  event AuctionCanceled(
    uint256 indexed auctionId,
    address seller,
    uint256 nftTokenId
  );

  event AuctionEnded(uint256 indexed auctionId, bool isSold);

  event AuctionSold(
    uint256 indexed auctionId,
    bool isSold,
    address winner,
    uint256 bid
  );

  constructor(address _contractAddress) {
    owner = payable(msg.sender);
    ownerCut = 10;
    contractAddress = IERC721(_contractAddress);
    locked = false;
  }

  // PUBLIC FUNCTIONS

  function getCurrentAuctionId() public view returns (uint256) {
    return _auctionIdCounter.current();
  }

  // Returns single auction item
  function getAuction(uint256 _auctionId)
    public
    view
    returns (AuctionItem memory)
  {
    AuctionItem memory _auction = auctions[_auctionId];
    require(_auction.seller != address(0), 'Auction does not exist');
    return _auction;
  }

  // Returns all auction items
  function getAuctionList() external view returns (AuctionItem[] memory) {
    uint256 currentAuctionId = getCurrentAuctionId();
    AuctionItem[] memory _auctionList = new AuctionItem[](currentAuctionId);

    for (uint256 i = 0; i < currentAuctionId; i++) {
      _auctionList[i] = auctions[i];
    }

    return _auctionList;
  }

  // Returns all auction items for a specific seller
  function getAuctionsOfSeller(address _seller)
    external
    view
    returns (AuctionItem[] memory)
  {
    AuctionItem[] memory _auctionList = new AuctionItem[](
      _auctionIdCounter.current()
    );
    uint256 _auctionCount = 0;

    for (uint256 i = 0; i < _auctionIdCounter.current(); i++) {
      if (auctions[i].seller == _seller) {
        _auctionList[_auctionCount] = auctions[i];
        _auctionCount++;
      }
    }

    AuctionItem[] memory _auctionListTrimmed = new AuctionItem[](_auctionCount);

    for (uint256 i = 0; i < _auctionCount; i++) {
      _auctionListTrimmed[i] = _auctionList[i];
    }

    return _auctionListTrimmed;
  }

  function createAuction(
    uint256 _nftTokenId,
    uint256 _startPrice,
    uint256 _buyNowPrice
  ) external {
    require(
      _startPrice < _buyNowPrice,
      'Start price must be less than buy now price.'
    );
    require(_startPrice > 0, 'Start price must be greater than 0.');

    uint256 auctionId = _auctionIdCounter.current();
    _auctionIdCounter.increment();

    contractAddress.transferFrom(msg.sender, address(this), _nftTokenId);

    auctions[auctionId] = AuctionItem(
      auctionId,
      payable(msg.sender),
      _nftTokenId,
      address(0),
      0,
      _startPrice,
      _buyNowPrice,
      block.timestamp,
      block.timestamp + 7 days,
      false,
      false,
      false
    );

    emit AuctionCreated(
      auctionId,
      msg.sender,
      _nftTokenId,
      _startPrice,
      _buyNowPrice,
      block.timestamp,
      block.timestamp + 7 days
    );
  }

  function endAuction(uint256 _auctionId) public noRentry {
    require(
      getAuction(_auctionId).seller != address(0),
      'Auction does not exist'
    );
    AuctionItem storage _auction = auctions[_auctionId];

    if (_auction.highestBid == _auction.buyNowPrice) {
      _auction.endAt = block.timestamp;
    } else {
      require(
        msg.sender == _auction.seller,
        'You are not the seller of this auction.'
      );
      require(
        block.timestamp > _auction.endAt,
        'Auction has not ended yet. To cancel the auction, use cancelAuction function.'
      );
    }

    _auction.isEnded = true;

    if (_auction.highestBidder != address(0)) {
      uint256 _amount = _auction.highestBid;
      uint256 _sellerCut = (_amount * (100 - ownerCut)) / 100;
      uint256 _ownerCut = _amount - _sellerCut;

      ownerBalance += _ownerCut;

      _auction.isSold = true;

      contractAddress.safeTransferFrom(
        address(this),
        _auction.highestBidder,
        _auction.nftTokenId
      );
      payable(_auction.seller).transfer(_sellerCut);

      emit AuctionSold(
        _auctionId,
        _auction.isSold,
        _auction.highestBidder,
        _amount
      );
    } else {
      contractAddress.safeTransferFrom(
        address(this),
        _auction.seller,
        _auction.nftTokenId
      );

      emit AuctionEnded(_auctionId, _auction.isSold);
    }
  }

  function bid(uint256 _auctionId)
    external
    payable
    checkEnded(_auctionId)
    checkNotStarted(_auctionId)
  {
    require(
      getAuction(_auctionId).seller != address(0),
      'Auction does not exist'
    );
    AuctionItem storage _auction = auctions[_auctionId];

    require(msg.value > _auction.highestBid, 'There is already a higher bid.');
    require(
      msg.value >= _auction.startPrice,
      'Bid amount must be greater than start price.'
    );
    require(
      msg.sender != _auction.seller,
      'You cannot bid on your own auction.'
    );
    require(msg.value < _auction.buyNowPrice, 'Buy now price reached.');

    if (_auction.highestBidder != address(0)) {
      bidList[_auctionId][_auction.highestBidder] += _auction.highestBid;
    }

    _auction.highestBidder = msg.sender;
    _auction.highestBid = msg.value;

    emit AuctionBid(_auctionId, msg.sender, msg.value);
  }

  function refundBid(uint256 _auctionId)
    external
    noRentry
    checkNotEnded(_auctionId)
  {
    require(
      getAuction(_auctionId).seller != address(0),
      'Auction does not exist'
    );

    uint256 _amount = bidList[_auctionId][msg.sender];
    require(_amount > 0, 'You have no bid to withdraw.');

    bidList[_auctionId][msg.sender] = 0;

    payable(msg.sender).transfer(_amount);

    emit BidderWithdraw(_auctionId, msg.sender, _amount);
  }

  function buyNow(uint256 _auctionId)
    external
    payable
    checkEnded(_auctionId)
    checkNotStarted(_auctionId)
  {
    require(
      getAuction(_auctionId).seller != address(0),
      'Auction does not exist'
    );
    AuctionItem storage _auction = auctions[_auctionId];

    require(
      msg.sender != _auction.seller,
      'You cannot bid on your own auction.'
    );
    require(
      msg.value == _auction.buyNowPrice,
      'Bid amount must equal to buy now price.'
    );

    if (_auction.highestBidder != address(0)) {
      bidList[_auctionId][_auction.highestBidder] += _auction.highestBid;
    }

    _auction.highestBidder = msg.sender;
    _auction.highestBid = msg.value;

    emit AuctionBuyNow(_auctionId, msg.sender, msg.value);

    endAuction(_auctionId);
  }

  function cancelAuction(uint256 _auctionId)
    external
    noRentry
    onlyAuctionCreator(_auctionId)
    checkEnded(_auctionId)
    checkNotStarted(_auctionId)
  {
    require(
      getAuction(_auctionId).seller != address(0),
      'Auction does not exist'
    );
    AuctionItem storage _auction = auctions[_auctionId];
    require(_auction.isCanceled == false, 'Auction has already been canceled.');

    _auction.isCanceled = true;
    _auction.isEnded = true;
    bidList[_auctionId][_auction.highestBidder] += _auction.highestBid;
    _auction.highestBidder = address(0);
    _auction.highestBid = 0;

    contractAddress.safeTransferFrom(
      address(this),
      _auction.seller,
      _auction.nftTokenId
    );

    emit AuctionCanceled(_auctionId, _auction.seller, _auction.nftTokenId);
  }

  // OWNER FUNCTIONS

  function getOwnerBalance() external view onlyOwner returns (uint256) {
    return ownerBalance;
  }

  function withdrawCut() external onlyOwner {
    (bool success, ) = owner.call{ value: ownerBalance }('');
    require(success, 'Transfer failed.');
    ownerBalance = 0;
  }

  function getOwnerCut() external view returns (uint256) {
    return ownerCut;
  }

  function setOwnerCut(uint256 _ownerCut) external onlyOwner {
    require(_ownerCut <= 100, 'Owner cut must be less than 100.');
    ownerCut = _ownerCut;
  }

  // MODIFIERS

  modifier onlyOwner() {
    require(msg.sender == owner, 'You are not the owner.');
    _;
  }

  modifier noRentry() {
    require(!locked, 'No rentry allowed');
    locked = true;
    _;
    locked = false;
  }

  modifier checkNotStarted(uint256 _auctionId) {
    AuctionItem memory _auction = auctions[_auctionId];
    require(
      block.timestamp > _auction.startedAt,
      'Auction has not started yet.'
    );
    _;
  }

  modifier checkNotEnded(uint256 _auctionId) {
    AuctionItem memory _auction = auctions[_auctionId];
    require(
      (block.timestamp > _auction.endAt) || (_auction.isCanceled == true),
      'Auction has not ended yet.'
    );
    _;
  }

  modifier checkEnded(uint256 _auctionId) {
    AuctionItem memory _auction = auctions[_auctionId];
    require(
      (block.timestamp < _auction.endAt) || (_auction.isCanceled == false),
      'Auction has already ended.'
    );
    _;
  }

  modifier onlyAuctionCreator(uint256 _auctionId) {
    AuctionItem memory _auction = auctions[_auctionId];
    require(
      msg.sender == _auction.seller,
      'You are not the seller of this auction.'
    );
    _;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}