// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "./interfaces/IAvnNftListingsV1.sol";

contract AvnNftListingsV1 is IAvnNftListingsV1 {

  string constant private AUCTION_CONTEXT = "AVN_START_AUCTION";
  string constant private BATCH_CONTEXT = "AVN_START_BATCH";
  string constant private SALE_CONTEXT = "AVN_START_SALE";
  uint32 constant private ONE_MILLION = 1000000;
  bytes16 constant private HEX_BASE = "0123456789abcdef";

  string public clientName;
  uint256 private rId;
  bool private payingOut;
  bool private initialized;

  mapping (address => bool) public isAuthority;
  mapping (uint256 => Listing) private listing;
  mapping (uint256 => Batch) private batch;
  mapping (uint256 => Bid) private highBid;
  mapping (bytes32 => bool) private proofUsed;
  mapping (uint256 => uint256) private royaltiesId;
  mapping (uint256 => Royalty[]) private royalties;
  address[] private authorities;

  modifier isNotListed(uint256 _id) {
    require(listing[_id].state == State.Unlisted, "Listing already exists");
    _;
  }

  modifier isListedForAuction(uint256 _nftId) {
    require(listing[_nftId].state == State.Auction, "Auction not listed");
    _;
  }

  modifier isListedForBatchSale(uint256 _batchId) {
    require(listing[_batchId].state == State.Batch, "Batch not listed");
    _;
  }

  modifier isListedForSale(uint256 _nftId) {
    require(listing[_nftId].state == State.Sale, "Sale not listed");
    _;
  }

  modifier hasAvnPublicKey(bytes32 _avnPublicKey) {
    require(_avnPublicKey != 0, "Missing AVN public key");
    _;
  }

  modifier onlySeller(uint256 _nftId) {
    require(listing[_nftId].seller == msg.sender, "Only seller");
    _;
  }

  modifier onlyAuthority() {
    require(isAuthority[msg.sender], "Only authority");
    _;
  }

  modifier onlySellerOrAuthority(uint256 _batchOrNftId) {
    require(msg.sender == listing[_batchOrNftId].seller || isAuthority[msg.sender], "Only seller or authority");
    _;
  }

  function initialize(string calldata _clientName, address _initialAuthority)
    external
  {
    require(!initialized, "Already initialized");
    require(keccak256(abi.encodePacked(_clientName)) != keccak256(abi.encodePacked("")), "Missing client name");
    isAuthority[_initialAuthority] = true;
    authorities.push(_initialAuthority);
    clientName = _clientName;
    initialized = true;
  }

  function setAuthority(address _authority, bool _isAuthorised)
    external
    override
    onlyAuthority
  {
    require(_authority != msg.sender, "Cannot set self");
    require(_authority != address(0), "Cannot be zero address");

    if (_isAuthorised == isAuthority[_authority])
      return;
    else if (_isAuthorised) {
      isAuthority[_authority] = true;
      authorities.push(_authority);
    } else {
      isAuthority[_authority] = false;
      uint256 endAuthority = authorities.length - 1;
      for (uint256 i; i < endAuthority; i++) {
        if (authorities[i] == _authority) {
          authorities[i] = authorities[endAuthority];
          break;
        }
      }
      authorities.pop();
    }
  }

  function getAuthorities()
    external
    view
    override
    returns (address[] memory)
  {
    return authorities;
  }

  function getRoyalties(uint256 _id)
    external
    view
    override
    returns(Royalty[] memory)
  {
    return royalties[royaltiesId[_id]];
  }

  function startAuction(uint256 _nftId, bytes32 _avnPublicKey, uint256 _reservePrice, uint256 _endTime, uint64 _avnOpId,
      Royalty[] calldata _royalties, bytes calldata _proof)
    external
    override
    hasAvnPublicKey(_avnPublicKey)
    isNotListed(_nftId)
  {
    require(_nftId != 0, "Missing NFT ID");
    checkProof(keccak256(abi.encode(AUCTION_CONTEXT, address(this), _nftId, _avnPublicKey, msg.sender, _endTime, _avnOpId,
        _royalties)), _proof);
    setRoyalties(_nftId, _royalties);
    emit LogStartAuction(_nftId, _avnPublicKey, msg.sender, _reservePrice, _endTime);

    if (block.timestamp > _endTime) {
      emit LogAuctionCancelled(_nftId);
      emit AvnCancelNftListing(_nftId, _avnOpId);
    } else {
      listing[_nftId].state = State.Auction;
      listing[_nftId].seller = msg.sender;
      listing[_nftId].avnOpId = _avnOpId;
      listing[_nftId].endTime = _endTime;
      highBid[_nftId].amount = (_reservePrice > 0) ? _reservePrice - 1 : 0;
    }
  }

  function bid(uint256 _nftId, bytes32 _avnPublicKey)
    external
    override
    payable
    hasAvnPublicKey(_avnPublicKey)
    isListedForAuction(_nftId)
  {
    require(block.timestamp <= listing[_nftId].endTime, "Bidding has ended");
    require(msg.value > highBid[_nftId].amount, "Bid too low");

    refundAnyExistingBid(_nftId);
    highBid[_nftId].bidder = msg.sender;
    highBid[_nftId].avnPublicKey = _avnPublicKey;
    highBid[_nftId].amount = msg.value;
    emit LogBid(_nftId, highBid[_nftId].bidder, highBid[_nftId].avnPublicKey, highBid[_nftId].amount);
  }

  function endAuction(uint256 _nftId)
    external
    override
    isListedForAuction(_nftId)
    onlySeller(_nftId)
  {
    require(block.timestamp > listing[_nftId].endTime, "Cannot end auction yet");

    if (highBid[_nftId].bidder == address(0)) {
      emit LogAuctionCancelled(_nftId);
      emit AvnCancelNftListing(_nftId, listing[_nftId].avnOpId);
    } else {
      distributeFunds(royalties[royaltiesId[_nftId]], highBid[_nftId].amount, msg.sender);
      emit LogAuctionComplete(_nftId, highBid[_nftId].avnPublicKey, highBid[_nftId].bidder, highBid[_nftId].amount);
      emit AvnTransferTo(_nftId, highBid[_nftId].avnPublicKey, listing[_nftId].avnOpId);
      delete highBid[_nftId];
    }

    delete listing[_nftId];
  }

  function cancelAuction(uint256 _nftId)
    external
    override
    isListedForAuction(_nftId)
    onlySellerOrAuthority(_nftId)
  {
    refundAnyExistingBid(_nftId);
    emit LogAuctionCancelled(_nftId);
    emit AvnCancelNftListing(_nftId, listing[_nftId].avnOpId);
    delete listing[_nftId];
  }

  function startBatchSale(uint256 _batchId, bytes32 _avnPublicKey, uint256 _price, Batch calldata _batchData,
      Royalty[] calldata _royalties, bytes calldata _proof)
    external
    override
    hasAvnPublicKey(_avnPublicKey)
    isNotListed(_batchId)
  {
    checkProof(keccak256(abi.encode(BATCH_CONTEXT, address(this), _batchId, _avnPublicKey, msg.sender, _batchData, _royalties)),
        _proof);
    setRoyalties(_batchId, _royalties);
    emit LogStartBatchSale(_batchId, _avnPublicKey, msg.sender, _price, setBatchListing(_batchId, _price, _batchData), _batchData.listingNumber);
  }

  function buyFromBatch(uint256 _batchId, bytes32 _avnPublicKey)
    external
    override
    payable
    hasAvnPublicKey(_avnPublicKey)
    isListedForBatchSale(_batchId)
  {
    require(msg.value == listing[_batchId].price, "Incorrect price");
    require(batch[_batchId].supply - batch[_batchId].saleIndex > 0, "Sold out");
    batch[_batchId].saleIndex++;
    uint256 nftId = uint256(keccak256(abi.encode("B", _batchId, batch[_batchId].saleIndex)));
    royaltiesId[nftId] = royaltiesId[_batchId];
    listing[_batchId].saleFunds += msg.value;
    emit LogSold(uint256(nftId), _avnPublicKey, msg.sender);
    emit AvnMintTo(_batchId, batch[_batchId].saleIndex, _avnPublicKey, formatAsUUID(nftId));
  }

  function endBatchSale(uint256 _batchId)
    external
    override
    isListedForBatchSale(_batchId)
    onlySellerOrAuthority(_batchId)
  {
    uint256 totalSalesAmount = listing[_batchId].saleFunds;
    delete listing[_batchId];
    distributeFunds(royalties[royaltiesId[_batchId]], totalSalesAmount, msg.sender);
    emit LogBatchSaleEnded(_batchId, batch[_batchId].supply - batch[_batchId].saleIndex, batch[_batchId].listingNumber);
    emit AvnEndBatchListing(_batchId);
  }

  function startNftSale(uint256 _nftId, bytes32 _avnPublicKey, uint256 _price, uint64 _avnOpId,
      Royalty[] calldata _royalties, bytes calldata _proof)
    external
    override
    hasAvnPublicKey(_avnPublicKey)
    isNotListed(_nftId)
  {
    require(_nftId != 0, "Missing NFT ID");
    require(_price != 0, "Missing price");
    checkProof(keccak256(abi.encode(SALE_CONTEXT, address(this), _nftId, _avnPublicKey, msg.sender, _avnOpId, _royalties)),
        _proof);
    setRoyalties(_nftId, _royalties);
    listing[_nftId].state = State.Sale;
    listing[_nftId].seller = msg.sender;
    listing[_nftId].avnOpId = _avnOpId;
    listing[_nftId].price = _price;
    emit LogStartNftSale(_nftId, _avnPublicKey, msg.sender, _price);
  }

  function buyNft(uint256 _nftId, bytes32 _avnPublicKey)
    external
    override
    payable
    hasAvnPublicKey(_avnPublicKey)
    isListedForSale(_nftId)
  {
    require(msg.value == listing[_nftId].price, "Incorrect price");
    distributeFunds(royalties[royaltiesId[_nftId]], msg.value, listing[_nftId].seller);
    emit LogSold(_nftId, _avnPublicKey, msg.sender);
    emit AvnTransferTo(_nftId, _avnPublicKey, listing[_nftId].avnOpId);
    delete listing[_nftId];
  }

  function cancelNftSale(uint256 _nftId)
    external
    override
    isListedForSale(_nftId)
    onlySellerOrAuthority(_nftId)
  {
    emit LogNftSaleCancelled(_nftId);
    emit AvnCancelNftListing(_nftId, listing[_nftId].avnOpId);
    delete listing[_nftId];
  }

  function sendFunds(address _recipient, uint256 _amount)
    private
    returns (bool success_)
  {
    (success_, ) = _recipient.call{value: _amount}("");
  }

  function checkProof(bytes32 _msgHash, bytes memory _proof)
    private
  {
    require(!proofUsed[_msgHash], "Proof already used");
    proofUsed[_msgHash] = true;
    address signer = recover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _msgHash)), _proof);
    require(isAuthority[signer], "Invalid proof");
  }

  function recover(bytes32 hash, bytes memory signature)
    private
    pure
    returns (address)
  {
    if (signature.length != 65) return address(0);

    bytes32 r;
    bytes32 s;
    uint8 v;

    assembly {
      r := mload(add(signature, 0x20))
      s := mload(add(signature, 0x40))
      v := byte(0, mload(add(signature, 0x60)))
    }

    if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) return address(0);
    if (v < 27) v += 27;
    if (v != 27 && v != 28) return address(0);

    return ecrecover(hash, v, r, s);
  }

  function refundAnyExistingBid(uint256 _nftId)
    private
  {
    if (highBid[_nftId].bidder == address(0)) return;

    address bidder = highBid[_nftId].bidder;
    uint256 amount = highBid[_nftId].amount;
    delete highBid[_nftId];
    sendFunds(bidder, amount);
  }

  function distributeFunds(Royalty[] memory _royalties, uint256 _amount, address _seller)
    private
  {
    assert(!payingOut);
    payingOut = true;
    uint256 remaining = _amount;

    if (_royalties.length > 0) {
      uint256 royaltyPayment;
      for (uint256 i = 0; i < _royalties.length; i++) {
        royaltyPayment = _amount * _royalties[i].partsPerMil / ONE_MILLION;
        remaining -= royaltyPayment;
        sendFunds(_royalties[i].recipient, royaltyPayment);
      }
    }

    sendFunds(_seller, remaining);
    payingOut = false;
  }

  function setBatchListing(uint256 _batchId, uint256 _price, Batch memory _batchData)
    private
    returns (uint64 amountAvailable_)
  {
    require(_batchId != 0, "Missing batch ID");
    require(_price != 0, "Missing price");
    require(_batchData.supply != 0, "Missing supply");

    if (batch[_batchId].supply == 0) {
      batch[_batchId].supply = _batchData.supply;
    } else {
      require(batch[_batchId].supply == _batchData.supply, "Cannot alter supply");
    }

    require(batch[_batchId].supply > batch[_batchId].saleIndex, "None to sell");
    require(_batchData.saleIndex >= batch[_batchId].saleIndex, "Cannot reduce sales");
    batch[_batchId].saleIndex = _batchData.saleIndex;

    listing[_batchId].state = State.Batch;
    listing[_batchId].seller = msg.sender;
    listing[_batchId].price = _price;

    amountAvailable_ = batch[_batchId].supply - batch[_batchId].saleIndex;
  }

  function setRoyalties(uint256 _id, Royalty[] memory _royalties)
    private
  {
    if (royaltiesId[_id] != 0) return;
    royaltiesId[_id] = ++rId;
    uint64 totalRoyalties;

    for (uint256 i = 0; i < _royalties.length; i++) {
      if (_royalties[i].recipient != address(0) && _royalties[i].partsPerMil != 0) {
        totalRoyalties += _royalties[i].partsPerMil;
        require(totalRoyalties <= ONE_MILLION, "Royalties too high");
        royalties[rId].push(_royalties[i]);
      }
    }
  }

  function formatAsUUID(uint256 _nftId)
    private
    pure
    returns(string memory uuid_)
  {
    bytes16 halfNftId = bytes16(uint128(_nftId >> 128));

    uuid_ = string(abi.encodePacked(
      hexSlice(halfNftId, 0, 4), "-",
      hexSlice(halfNftId, 4, 6), "-",
      hexSlice(halfNftId, 6, 8), "-",
      hexSlice(halfNftId, 8, 10), "-",
      hexSlice(halfNftId, 10, 16)));
  }

  function hexSlice(bytes16 _halfNftId, uint256 _start, uint256 _end)
    private
    pure
    returns (bytes memory)
  {
    bytes memory result = new bytes((_end - _start) * 2);
    uint256 j;

    for (uint256 i = _start; i < _end; i++) {
      result[j * 2] = HEX_BASE[uint8(_halfNftId[i]) / 16];
      result[j * 2 + 1] = HEX_BASE[uint8(_halfNftId[i]) % 16];
      j++;
    }

    return result;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IAvnNftListingsV1 {

  enum State {
    Unlisted,
    Auction,
    Batch,
    Sale
  }

  struct Royalty {
    address recipient;
    uint32 partsPerMil;
  }

  struct Batch {
    uint64 supply;
    uint64 saleIndex;
    uint64 listingNumber;
  }

  struct Listing {
    uint256 price;
    uint256 endTime;
    uint256 saleFunds;
    address seller;
    uint64 avnOpId;
    State state;
  }

  struct Bid {
    address bidder;
    bytes32 avnPublicKey;
    uint256 amount;
  }

  event AvnTransferTo(uint256 indexed nftId, bytes32 indexed avnPublicKey, uint64 indexed avnOpId);
  event AvnMintTo(uint256 indexed batchId, uint64 indexed saleIndex, bytes32 indexed avnPublicKey, string uuid);
  event AvnEndBatchListing(uint256 indexed batchId);
  event AvnCancelNftListing(uint256 indexed nftId, uint64 indexed avnOpId);

  event LogStartAuction(uint256 indexed nftId, bytes32 indexed avnPublicKey, address indexed seller, uint256 reservePrice,
      uint256 endTime);
  event LogBid(uint256 indexed nftId, address indexed bidder, bytes32 indexed avnPublicKey, uint256 amount);
  event LogAuctionComplete(uint256 indexed nftId, bytes32 indexed avnPublicKey, address indexed winner, uint256 winningBid);
  event LogAuctionCancelled(uint256 indexed nftId);
  event LogStartBatchSale(uint256 indexed batchId, bytes32 indexed avnPublicKey, address indexed seller, uint256 price,
      uint64 amountAvailable, uint64 listingNumber);
  event LogSold(uint256 indexed nftId, bytes32 indexed avnPublicKey, address indexed buyer);
  event LogBatchSaleEnded(uint256 indexed batchId, uint64 amountRemaining, uint64 listingNumber);
  event LogStartNftSale(uint256 indexed nftId, bytes32 indexed avnPublicKey, address indexed seller, uint256 price);
  event LogNftSaleCancelled(uint256 indexed nftId);

  function setAuthority(address authority, bool isAuthorised) external; // onlyAuthority
  function getAuthorities() external view returns(address[] memory);
  function getRoyalties(uint256 id) external view returns(Royalty[] memory);
  function startAuction(uint256 nftId, bytes32 avnPublicKey, uint256 reservePrice, uint256 endTime, uint64 avnOpId,
      Royalty[] calldata royalties, bytes calldata proof) external;
  function bid(uint256 nftId, bytes32 avnPublicKey) external payable;
  function endAuction(uint256 nftId) external; // onlySeller
  function cancelAuction(uint256 nftId) external; // either Seller or Authority
  function startBatchSale(uint256 batchId, bytes32 avnPublicKey, uint256 price, Batch calldata batchData,
      Royalty[] calldata royalties, bytes calldata proof) external;
  function buyFromBatch(uint256 batchId, bytes32 avnPublicKey) external payable;
  function endBatchSale(uint256 batchId) external; // either Seller or Authority
  function startNftSale(uint256 nftId, bytes32 avnPublicKey, uint256 price, uint64 avnOpId, Royalty[] calldata royalties,
      bytes calldata proof) external;
  function buyNft(uint256 nftId, bytes32 avnPublicKey) external payable;
  function cancelNftSale(uint256 nftId) external; // either Seller or Authority
}