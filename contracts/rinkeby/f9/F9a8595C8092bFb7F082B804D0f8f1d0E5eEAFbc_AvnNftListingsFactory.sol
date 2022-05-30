// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import "./AvnNftListingsV1.sol";

contract AvnNftListingsFactory {
  address immutable beacon;
  event LogNewClient(address clientAddress);

  constructor(address _beacon) {
    beacon = _beacon;
  }

  function addNewClient(string calldata _clientName, address _initialAuthority)
    external
    returns
    (address)
  {
    BeaconProxy proxy =
        new BeaconProxy(beacon, abi.encodeWithSelector(AvnNftListingsV1.initialize.selector, _clientName, _initialAuthority));
    emit LogNewClient(address(proxy));
    return address(proxy);
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
  // TODO: MAKE ME PRIVATE
  bool public initialized;

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

  // Only runs to lock the implementation
  constructor() {
    initialized = true;
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

  // TODO REMOVE ME
  function testFunction()
    external
    pure
    returns(string memory)
  {
    return "VERSION 1";
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
// OpenZeppelin Contracts v4.4.1 (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/BeaconProxy.sol)

pragma solidity ^0.8.0;

import "./IBeacon.sol";
import "../Proxy.sol";
import "../ERC1967/ERC1967Upgrade.sol";

/**
 * @dev This contract implements a proxy that gets the implementation address for each call from a {UpgradeableBeacon}.
 *
 * The beacon address is stored in storage slot `uint256(keccak256('eip1967.proxy.beacon')) - 1`, so that it doesn't
 * conflict with the storage layout of the implementation behind the proxy.
 *
 * _Available since v3.4._
 */
contract BeaconProxy is Proxy, ERC1967Upgrade {
    /**
     * @dev Initializes the proxy with `beacon`.
     *
     * If `data` is nonempty, it's used as data in a delegate call to the implementation returned by the beacon. This
     * will typically be an encoded function call, and allows initializating the storage of the proxy like a Solidity
     * constructor.
     *
     * Requirements:
     *
     * - `beacon` must be a contract with the interface {IBeacon}.
     */
    constructor(address beacon, bytes memory data) payable {
        assert(_BEACON_SLOT == bytes32(uint256(keccak256("eip1967.proxy.beacon")) - 1));
        _upgradeBeaconToAndCall(beacon, data, false);
    }

    /**
     * @dev Returns the current beacon address.
     */
    function _beacon() internal view virtual returns (address) {
        return _getBeacon();
    }

    /**
     * @dev Returns the current implementation address of the associated beacon.
     */
    function _implementation() internal view virtual override returns (address) {
        return IBeacon(_getBeacon()).implementation();
    }

    /**
     * @dev Changes the proxy to use a new beacon. Deprecated: see {_upgradeBeaconToAndCall}.
     *
     * If `data` is nonempty, it's used as data in a delegate call to the implementation returned by the beacon.
     *
     * Requirements:
     *
     * - `beacon` must be a contract.
     * - The implementation returned by `beacon` must be a contract.
     */
    function _setBeacon(address beacon, bytes memory data) internal virtual {
        _upgradeBeaconToAndCall(beacon, data, false);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/Proxy.sol)

pragma solidity ^0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overridden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overridden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeacon.sol";
import "../../interfaces/draft-IERC1822.sol";
import "../../utils/Address.sol";
import "../../utils/StorageSlot.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967Upgrade {
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlot.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822Proxiable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlot.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlot.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlot.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(Address.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            Address.isContract(IBeacon(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlot.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(IBeacon(newBeacon).implementation(), data);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822Proxiable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}