//SPDX-License-Identifier: Unlicense
// Copyright (c) 2022 BDE Labs LLC. All Rights Reserved
pragma solidity ^0.8.x;

import "./Executor.sol";

/**
 * 06
 *
 * TODO: What could go wrong with casting uint256 to int256???
 *
 */
contract Polygods is Executor {

    /** 
     * 
     */
    constructor(address vrfCoordinator) Executor("Polygods", "POLYGODS", vrfCoordinator) {
        _admin = msg.sender;
    }

    function withdraw() public {
        uint256 amount = uint256(pendingWithdrawals[msg.sender]);
        // Remember to zero the pending refund before
        // sending to prevent re-entrancy attacks
        pendingWithdrawals[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }
    

}

//SPDX-License-Identifier: Unlicense
// Copyright (c) 2022 BDE Labs LLC. All Rights Reserved
pragma solidity ^0.8.x;

import "./Bidder.sol";

/**
 * 05
 *
 * this is the file that moves tokens...
 *
 * DON'T ALLOW TRANSFERS W/O MONEY, 'CAUSE THEN THEY COULD CHEAT THE NGMI TAX
 *
 */
contract Executor is Bidder {

    event NoLongerForSale(uint256 indexed tokenId);
    event Bought(uint256 indexed tokenId, int256 value, address indexed from, address indexed to);

    constructor(string memory name_, string memory symbol_, address vrfCoordinator) Bidder(name_, symbol_, vrfCoordinator) { 
    }

    /**
     * ...
     */
    function purchase(uint256 tokenId) public payable {
        require(assigned, "TODO: ...");

        Ask memory offer = offeredForSale[tokenId];
        
        require(offer.isForSale, "Executor: not for sale");

        int256 value = int256(msg.value);
        require(value >= offer.minValue, "Executor: didn't send enough ETH");

        address seller = offer.seller;
        require(seller == _owners[tokenId], "Executor: seller is not owner"); 
        

        require(_exists(tokenId), "Executor: operator query for nonexistent token");
        
        address to = msg.sender;
        
        _owners[tokenId] = to;
        _balances[seller]--;
        _balances[to]++;
        emit Transfer(seller, to, tokenId);

        _noLongerForSale(tokenId);
        emit Bought(tokenId, value, seller, msg.sender);

        // Check for the case where there is a bid from the new owner and refund it.
        // Any other bid can stay in place.
        Bid memory bid = _bids[tokenId];
        if (bid.bidder == msg.sender) {
            // Kill bid and refund value
            pendingWithdrawals[msg.sender] += bid.value; //<-- problem???
            _bids[tokenId] = Bid(false, tokenId, address(0), 0);
        }
        if (!_isFloor(tokenId)){
            
            // Credit us the royalty fee, give the rest to the seller
            int256 royaltyFee = (value * _percentageRoyalty) / _percentageTotal;
            int256 sellerProceeds = value - royaltyFee;

            pendingWithdrawals[_admin] += royaltyFee;
            pendingWithdrawals[seller] += sellerProceeds;

        } else {
            _enforcePaperHandsNgmiTax(seller, value);
        }
        _extractById(tokenId);
        volumeTraded += uint256(value);
    }


    function acceptBid(uint256 tokenId, int256 minPriceInWei) public {       
        require(_exists(tokenId), "Executor: operator query for nonexistent token");

        address seller = msg.sender;

        Bid memory bid = _bids[tokenId];
        require(bid.value != 0, "bid.value != 0");
        require(bid.value >= minPriceInWei, "bid.value > minPrice");

        _owners[tokenId] = bid.bidder;
        _balances[seller]--;
        _balances[bid.bidder]++;
        emit Transfer(seller, bid.bidder, tokenId);

        offeredForSale[tokenId] = Ask(false, tokenId, bid.bidder, 0);
        int256 value = bid.value;
        _bids[tokenId] = Bid(false, tokenId, address(0), 0);
        
        emit Bought(tokenId, value, seller, bid.bidder);

        //if it's below the floor, do the thing...
        Heap.Node memory floor = _getFloor();

        if(value <= floor.priority){
            _enforcePaperHandsNgmiTax(seller, value);
        } else {

            // Credit us the royalty fee, give the rest to the seller
            int256 royaltyFee = (value * _percentageRoyalty) / _percentageTotal;
            int256 sellerProceeds = value - royaltyFee;

            pendingWithdrawals[_admin] += royaltyFee;
            pendingWithdrawals[seller] += sellerProceeds;
        }
        _extractById(tokenId);
        volumeTraded += uint256(value);
    }




    function _noLongerForSale(uint256 tokenId) internal {
        offeredForSale[tokenId] = Ask(false, tokenId, msg.sender, 0);
        emit NoLongerForSale(tokenId);
    }



}

//SPDX-License-Identifier: Unlicense
// Copyright (c) 2022 BDE Labs LLC. All Rights Reserved
pragma solidity ^0.8.x;

import "./VRF.sol";

struct Bid {
    bool hasBid;
    uint256 punkIndex;
    address bidder;
    int256 value; //in wei
}

/**
 * 04
 */
contract Bidder is VRF {

    event BidEntered(uint256 indexed tokenId, int256 value, address indexed from);
    event BidWithdrawn(uint256 indexed tokenId, int256 value, address indexed from);

    mapping(uint256 => Bid) public _bids;

    constructor(string memory name_, string memory symbol_, address vrfCoordinator) VRF(name_, symbol_, vrfCoordinator) { 
    }

    /**
     */
    function enterBid(uint256 tokenId) public payable {
        require(assigned, "TODO: ...");
        require(_exists(tokenId), "Bidder: query for nonexistent token");

        address bidder = msg.sender;
        require(_owners[tokenId] != bidder, "Bidder: you already own this nft");

        int256 value = int256(msg.value); // TODO: What could go wrong with casting uint256 to int256???
        require(value != 0, "Bidder: insufficient value");
        
        Bid memory existing = _bids[tokenId];
        require(value >= existing.value, "Bidder: insufficient bid");
        
        if (existing.value > 0) {
            // Refund the failing bid
            pendingWithdrawals[existing.bidder] += existing.value;
        }
        _bids[tokenId] = Bid(true, tokenId, bidder, value);
        emit BidEntered(tokenId, value, bidder);
    }

    /**
     */
    function withdrawBid(uint256 tokenId) public {
        require(assigned, "TODO: ...");              
        require(_exists(tokenId), "Bidder: query for nonexistent token");

        address bidder = msg.sender;
        require(_owners[tokenId] != bidder);
        
        Bid memory bid = _bids[tokenId];
        require(bid.bidder == bidder);

        emit BidWithdrawn(tokenId, bid.value, bidder);

        _bids[tokenId] = Bid(false, tokenId, address(0), 0);

        uint256 value = uint256(bid.value); // TODO: What could go wrong with casting uint256 to int256???
        
        // Refund the bid money
        payable(bidder).transfer(value); 
    }

}

//SPDX-License-Identifier: Unlicense
// Copyright (c) 2022 BDE Labs LLC. All Rights Reserved
pragma solidity ^0.8.x;

import "./Lister.sol";
import "./vrf/VRFConsumerBaseV2.sol";
import "./vrf/VRFCoordinatorV2Interface.sol";

struct PendingWithdrawal {
    address seller;
    int256 value; //in wei
}

/**
 * 03A
 */
contract VRF is VRFConsumerBaseV2, Lister {
    VRFCoordinatorV2Interface COORDINATOR;

    int256 immutable public _percentageTotal;
    int256 public _percentageRoyalty;

    mapping(address => int256) public pendingWithdrawals;

    event RandomResult(uint256 number);

    /// release the hold once we know the result of the random number, if applicable
    mapping(uint256 => PendingWithdrawal) public holdingWithdrawals; 

    constructor(string memory name_, string memory symbol_, address vrfCoordinator) VRFConsumerBaseV2(vrfCoordinator) Lister(name_, symbol_)  {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);

        _percentageTotal = 10000;
        _percentageRoyalty = 1000;
    }

    function setRoyaltyBips(int256 percentageRoyalty_) external { //onlyAdmin
        require(percentageRoyalty_ <= _percentageTotal, "VRF: Illegal argument more than 100%");
        _percentageRoyalty = percentageRoyalty_;
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        PendingWithdrawal memory pendingWithdrawal = holdingWithdrawals[requestId];
        address seller = pendingWithdrawal.seller;
        int256 value = pendingWithdrawal.value;

        // transform the result to a number between 1 and 100 inclusively
        uint256 result = (randomWords[0] % 100) + 1;
        if (result >= 35){

            // Credit us the royalty fee, give the rest to the seller
            int256 royaltyFee = (value * _percentageRoyalty) / _percentageTotal;
            int256 sellerProceeds = value - royaltyFee;

            pendingWithdrawals[_admin] += royaltyFee;
            pendingWithdrawals[seller] += sellerProceeds;


        } else {

            // Send them the consolation NFT!

            pendingWithdrawals[_admin] += value;
        }
        emit RandomResult(result);

        //send them the heaven or hell version of the 
        //non-transferable NFT
    }

    function _enforcePaperHandsNgmiTax(address seller, int256 value) internal {
        //requestId - A unique identifier of the request. Can be used to match
        //a request to a response in fulfillRandomWords.
        uint64 s_subscriptionId = 2822;
        uint32 numWords = 1;
        // FINALITY HAPPENS AFTER 65 BLOCKS IN POLYGON!!! only like 3 minutes....
        //uint16 requestConfirmations = 3; //polygon re-orgs... random number could change... in fork
        //uint16 requestConfirmations = 65;

        uint16 requestConfirmations = 666; // pergatory!!! enforced wait period...

        bytes32 keyHash = 0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc; //rinkeby testnet...
        uint32 callbackGasLimit = 100000;
        uint256 s_requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
        holdingWithdrawals[s_requestId] = PendingWithdrawal(seller, value);
    }    



}

//SPDX-License-Identifier: Unlicense
// Copyright (c) 2022 BDE Labs LLC. All Rights Reserved
pragma solidity ^0.8.x;

import "./MintBurn.sol";
import "./DataStructure.sol";

struct Ask { //Ask
    bool isForSale;
    uint256 punkIndex;
    address seller;
    int256 minValue;          // in ether? <-- no, look below. it's in wei
}

/**
 * 02A
 */
contract Lister is MintBurn, DataStructure {

    event Offered(uint indexed punkIndex, int256 minValue);

    mapping(uint256 => Ask) public offeredForSale;

    constructor(string memory name_, string memory symbol_) MintBurn(name_, symbol_) {
    }

    function offerForSale(uint256 tokenId, int256 minSalePriceInWei) public {
        require(assigned, "Lister: mint still in progress...");
        require(_exists(tokenId), "Lister: nonexistent token");
        
        require(_owners[tokenId] == msg.sender, "Lister: not your punk");

        _insert(minSalePriceInWei, tokenId);
        
        offeredForSale[tokenId] = Ask(true, tokenId, msg.sender, minSalePriceInWei);
        
        emit Offered(tokenId, minSalePriceInWei);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.x;

/**
 * 03B
 */
abstract contract VRFConsumerBaseV2 {
  error OnlyCoordinatorCanFulfill(address have, address want);
  address private immutable vrfCoordinator;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   */
  constructor(address _vrfCoordinator) {
    vrfCoordinator = _vrfCoordinator;
  }

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBaseV2 expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomWords the VRF output expanded to the requested number of words
   */
  function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal virtual;

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external {
    if (msg.sender != vrfCoordinator) {
      revert OnlyCoordinatorCanFulfill(msg.sender, vrfCoordinator);
    }
    fulfillRandomWords(requestId, randomWords);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface VRFCoordinatorV2Interface {
  /**
   * @notice Get configuration relevant for making requests
   * @return minimumRequestConfirmations global min for request confirmations
   * @return maxGasLimit global max for request gas limit
   * @return s_provingKeyHashes list of registered key hashes
   */
  function getRequestConfig()
    external
    view
    returns (
      uint16,
      uint32,
      bytes32[] memory
    );

  /**
   * @notice Request a set of random words.
   * @param keyHash - Corresponds to a particular oracle job which uses
   * that key for generating the VRF proof. Different keyHash's have different gas price
   * ceilings, so you can select a specific one to bound your maximum per request cost.
   * @param subId  - The ID of the VRF subscription. Must be funded
   * with the minimum subscription balance required for the selected keyHash.
   * @param minimumRequestConfirmations - How many blocks you'd like the
   * oracle to wait before responding to the request. See SECURITY CONSIDERATIONS
   * for why you may want to request more. The acceptable range is
   * [minimumRequestBlockConfirmations, 200].
   * @param callbackGasLimit - How much gas you'd like to receive in your
   * fulfillRandomWords callback. Note that gasleft() inside fulfillRandomWords
   * may be slightly less than this amount because of gas used calling the function
   * (argument decoding etc.), so you may need to request slightly more than you expect
   * to have inside fulfillRandomWords. The acceptable range is
   * [0, maxGasLimit]
   * @param numWords - The number of uint256 random values you'd like to receive
   * in your fulfillRandomWords callback. Note these numbers are expanded in a
   * secure way by the VRFCoordinator from a single random value supplied by the oracle.
   * @return requestId - A unique identifier of the request. Can be used to match
   * a request to a response in fulfillRandomWords.
   */
  function requestRandomWords(
    bytes32 keyHash,
    uint64 subId,
    uint16 minimumRequestConfirmations,
    uint32 callbackGasLimit,
    uint32 numWords
  ) external returns (uint256 requestId);

  /**
   * @notice Create a VRF subscription.
   * @return subId - A unique subscription id.
   * @dev You can manage the consumer set dynamically with addConsumer/removeConsumer.
   * @dev Note to fund the subscription, use transferAndCall. For example
   * @dev  LINKTOKEN.transferAndCall(
   * @dev    address(COORDINATOR),
   * @dev    amount,
   * @dev    abi.encode(subId));
   */
  function createSubscription() external returns (uint64 subId);

  /**
   * @notice Get a VRF subscription.
   * @param subId - ID of the subscription
   * @return balance - LINK balance of the subscription in juels.
   * @return reqCount - number of requests for this subscription, determines fee tier.
   * @return owner - owner of the subscription.
   * @return consumers - list of consumer address which are able to use this subscription.
   */
  function getSubscription(uint64 subId)
    external
    view
    returns (
      uint96 balance,
      uint64 reqCount,
      address owner,
      address[] memory consumers
    );

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @param newOwner - proposed new owner of the subscription
   */
  function requestSubscriptionOwnerTransfer(uint64 subId, address newOwner) external;

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @dev will revert if original owner of subId has
   * not requested that msg.sender become the new owner.
   */
  function acceptSubscriptionOwnerTransfer(uint64 subId) external;

  /**
   * @notice Add a consumer to a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - New consumer which can use the subscription
   */
  function addConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Remove a consumer from a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - Consumer to remove from the subscription
   */
  function removeConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Cancel a subscription
   * @param subId - ID of the subscription
   * @param to - Where to send the remaining LINK to
   */
  function cancelSubscription(uint64 subId, address to) external;

  /*
   * @notice Check to see if there exists a request commitment consumers
   * for all consumers and keyhashes for a given sub.
   * @param subId - ID of the subscription
   * @return true if there exists at least one unfulfilled request for the subscription, false
   * otherwise.
   */
  function pendingRequestExists(uint64 subId) external view returns (bool);
}

//SPDX-License-Identifier: Unlicense
// Copyright (c) 2022 BDE Labs LLC. All Rights Reserved
pragma solidity ^0.8.x;

import "./Core.sol";

/**
 * 01
// TODO: implement gas race mechanism!!! 
// white list open for a week, degen score
// then flip a switch and turns public
// degen score??? already rich
// fight club energia
 */
contract MintBurn is Core {

    bool public active;
    bool public assigned;

    uint256 public countMax;
    uint256 public countMint;
    uint256 public countBurn;
    uint256 public countTotal;

    uint256 public startingIndexBlock;
    uint256 public startingIndex;
    
    uint256 public mintPrice;
    uint256 public volumeTraded;
    
    uint256 public REVEAL_TIMESTAMP;

    constructor(string memory name_, string memory symbol_) Core(name_, symbol_) {

        uint256 saleStart = 1619060439;

        REVEAL_TIMESTAMP = saleStart + (86400 * 9);

        countMax = 20; 
        countMint = 1; /// make sure tokenIds start at 1, not 0
        countTotal = 10000;

        active = false;
        assigned = false;

        mintPrice = 80000000000000000; //0.08 ETH
    }

    /**
     */
    function totalSupply() public view virtual returns (uint256) {
        return countMint - countBurn;
    }

    /**
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        countMint++;
        if(countMint == countTotal){
            assigned = true;
        }
        volumeTraded += mintPrice;

        require(
            _checkOnERC721Received(address(0), to, tokenId, ""),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     */
    function mint(uint256 countCreate) public payable {
        require(active, "Polygods: sale inactive");
        require(countCreate <= countMax, "Polygods: exceeds mint txn limit");
        require(countMint + countCreate <= countTotal, "Polygods: exceeds token limit");
        require(mintPrice * countCreate <= msg.value, "Polygods: eth value insufficient");
        
        for(uint i = 0; i < countCreate; i++) {
            uint mintIndex = totalSupply();
            if (totalSupply() < countTotal) {
                _mint(msg.sender, mintIndex);
            }
        }

        // If we haven't set the starting index and this is either 1) the last saleable token or 2) the first token to be sold after
        // the end of pre-sale, set the starting index block
        if (startingIndexBlock == 0 && (countMint == countTotal || block.timestamp >= REVEAL_TIMESTAMP)) {
            startingIndexBlock = block.number;
        } 
    }


    /**
     * Set the starting index for the collection
     */
    function setStartingIndex() public {
        require(startingIndex == 0, "Starting index is already set");
        require(startingIndexBlock != 0, "Starting index block must be set");
        
        startingIndex = uint256(blockhash(startingIndexBlock)) % countTotal;
        // Just a sanity case in the worst case if this function is called late (EVM only stores last 256 block hashes)
        if (block.number - startingIndexBlock > 255) {
            startingIndex = uint256(blockhash(block.number - 1)) % countTotal;
        }
        // Prevent default sequence
        if (startingIndex == 0) {
            startingIndex = startingIndex + 1;
        }
    }


   /**
    * Pause sale if active, make active if paused
    */
    function flipSaleState() public { //onlyOwner
        active = !active;
    }

    /**
     * Set the starting index block for the collection, essentially unblocking
     * setting starting index
     */
    function emergencySetStartingIndexBlock() public { //onlyOwner
        require(startingIndex == 0, "Starting index is already set");
        startingIndexBlock = block.number;
    }

    /**
     * TODO: also prolly need to remove bids, offers, etc..
     * but also prolly not that important, 'cause it'll just
     * fail when it gets to `_exists()` <-- yeah, this
     so we don't need to call _noLongerForSale
     */
    function burn(uint256 tokenId) public virtual {
        require(assigned, "MintBurn: tokens unassigned");

        address owner = ownerOf(tokenId); 

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

}

//SPDX-License-Identifier: Unlicense
// Copyright (c) 2022 BDE Labs LLC. All Rights Reserved
pragma solidity ^0.8.x;

import "./heap/Heap.sol";

/**
 * 02B
 */
contract DataStructure {
    using Heap for Heap.Data;
    Heap.Data internal data;

    constructor() {
        data.init();
    }

    function getFloor() external view returns(Heap.Node memory){
        return _getFloor();
    }

    function _getFloor() internal view returns(Heap.Node memory){
        Heap.Node memory node = data.getFloorNode();
        return node;
    }

    function _insert(int256 minSalePriceInWei, uint256 punkIndex) internal {
        data.insert(minSalePriceInWei, punkIndex);
    }

    function _getById(uint256 tokenId) internal view returns(Heap.Node memory){
        return data.getById(tokenId);
    }

    function _extractById(uint256 tokenId) internal returns(Heap.Node memory){
        return data.extractById(tokenId);
    }

    function _isFloor(uint256 tokenId) internal view returns(bool){
        return data.isFloor(tokenId);
    }

}

//SPDX-License-Identifier: Unlicense
// Copyright (c) 2022 BDE Labs LLC. All Rights Reserved
pragma solidity ^0.8.x;

interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

interface IERC165 {
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

interface IERC721Metadata {
    function name() external view returns (string memory _name);
    function symbol() external view returns (string memory _symbol);
    function tokenURI(uint256 _tokenId) external view returns (string memory);
}

interface ERC721 {
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
    function balanceOf(address _owner) external view returns (uint256);
    function ownerOf(uint256 _tokenId) external view returns (address);
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata data) external;
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;
    function transferFrom(address _from, address _to, uint256 _tokenId) external;
    function approve(address _approved, uint256 _tokenId) external;
    function setApprovalForAll(address _operator, bool _approved) external;
    function getApproved(uint256 _tokenId) external view returns (address);
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

/**
 * 00
 */
contract Core is ERC721, IERC165, IERC721Metadata {
    string private _name;
    string private _symbol;

    mapping(uint256 => address) internal _owners;
    mapping(address => uint256) internal _balances;

    address public _admin;

    string internal constant UNSUPPORTED_OPERATION = "ERC721: unsupported operation";

    modifier onlyAdmin() {
        require(msg.sender == _admin, "Polygods: invalid msg.sender");
        _;
    }
    
    /**
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * TODO: copy doodles, but use aarweave
     */
    function tokenURI(uint256 tokenId) public view virtual returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        // TODO: upload image and metadata to aarweave
        string memory baseURI = "";
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId)) : "";
    }

    /**
     */
    function balanceOf(address owner) public view virtual returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     */
    function ownerOf(uint256 tokenId) public view virtual returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * Do we still need this even???
     */
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data) internal returns (bool) {
        if (to.code.length == 0) {
            return true;
        }
        try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data) returns (bytes4 retval) {
            return retval == IERC721Receiver.onERC721Received.selector;
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                revert("ERC721: transfer to non ERC721Receiver implementer");
            } else {
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
        }
    }

    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        if (
            interfaceId == 0x01ffc9a7 || // ERC165
            interfaceId == 0x80ac58cd || // ERC721
            interfaceId == 0x5b5e139f    // ERC721Metadata
        ) {
            return true;
        }
        return false;
    }

    function safeTransferFrom(address /*_from*/, address /*_to*/, uint256 /*_tokenId*/, bytes calldata /*data*/) public virtual override {
        revert(UNSUPPORTED_OPERATION);
    }

    function safeTransferFrom(address /*_from*/, address /*_to*/, uint256 /*_tokenId*/) public virtual override {
        revert(UNSUPPORTED_OPERATION);
    }

    function transferFrom(address /*_from*/, address /*_to*/, uint256 /*_tokenId*/) public virtual override {
        revert(UNSUPPORTED_OPERATION);
    }

    function approve(address /*_approved*/, uint256 /*_tokenId*/) public virtual override {
        revert(UNSUPPORTED_OPERATION);
    }

    function setApprovalForAll(address /*_operator*/, bool /*_approved*/) public virtual override {
        revert(UNSUPPORTED_OPERATION);
    }

    function getApproved(uint256 /*_tokenId*/) public view virtual override returns (address) {
        revert(UNSUPPORTED_OPERATION);
    }

    function isApprovedForAll(address /*_owner*/, address /*_operator*/) public view virtual override returns (bool) {
        revert(UNSUPPORTED_OPERATION);
    }

}

// SPDX-License-Identifier: MIT
// Shoutout Zac Mitton! @VoltzRoad
pragma solidity 0.8.x;

library Heap {

  struct Data {
      Node[] nodes; // root is index 1; index 0 not used
      mapping(uint256 => uint256) indices; // unique id => node index
  }

  struct Node {
      uint256 tokenId;
      int256 priority;
  }

  uint constant ROOT_INDEX = 1;

  //call init before anything else
  function init(Data storage self) internal{
    self.nodes.push(Node(0,0));
  }

  function insert(Data storage self, int256 priority, uint256 tokenId) internal returns(Node memory) {
    require(!isNode(getById(self, tokenId)), "exists already");

    int256 minimize = priority * -1;

    Node memory n = Node(tokenId, minimize);
    
    self.nodes.push(n);
    _bubbleUp(self, n, self.nodes.length-1);

    return n;
  }

  function extractMax(Data storage self) internal returns(Node memory){
    return _extract(self, ROOT_INDEX);
  }

  function extractById(Data storage self, uint256 tokenId) internal returns(Node memory){
    return _extract(self, self.indices[tokenId]);
  }

  //view
  function dump(Data storage self) internal view returns(Node[] memory){
    //note: Empty set will return `[Node(0,0)]`. uninitialized will return `[]`.
    return self.nodes;
  }

  function getById(Data storage self, uint256 tokenId) internal view returns(Node memory){
    return getByIndex(self, self.indices[tokenId]);//test that all these return the emptyNode
  }

  function getByIndex(Data storage self, uint256 i) internal view returns(Node memory){
    return self.nodes.length > i ? self.nodes[i] : Node(0,0);
  }

  function getFloorNode(Data storage self) internal view returns(Node memory){
    Node memory node = getByIndex(self, ROOT_INDEX);
    int256 priority = node.priority;
    node.priority  = priority * -1;
    return node;
  }

  function isFloor(Data storage self, uint256 tokenId) internal view returns(bool){
    Node memory node00 = getByIndex(self, ROOT_INDEX);
    Node memory node01 = getByIndex(self, self.indices[tokenId]);
    return node00.tokenId == node01.tokenId;
  }

  function size(Data storage self) internal view returns(uint256){
    return self.nodes.length > 0 ? self.nodes.length-1 : 0;
  }
  
  function isNode(Node memory n) internal pure returns(bool){ return n.tokenId > 0; }

  //private
  function _extract(Data storage self, uint256 i) private returns(Node memory){//√
    if(self.nodes.length <= i || i <= 0){ return Node(0,0); }

    Node memory extractedNode = self.nodes[i];
    delete self.indices[extractedNode.tokenId];

    Node memory tailNode = self.nodes[self.nodes.length-1];
    self.nodes.pop();

    if(i < self.nodes.length){ // if extracted node was not tail
      _bubbleUp(self, tailNode, i);
      _bubbleDown(self, self.nodes[i], i); // then try bubbling down
    }
    return extractedNode;
  }
  function _bubbleUp(Data storage self, Node memory n, uint256 i) private{//√
    if(i==ROOT_INDEX || n.priority <= self.nodes[i/2].priority){
      _insert(self, n, i);
    }else{
      _insert(self, self.nodes[i/2], i);
      _bubbleUp(self, n, i/2);
    }
  }
  function _bubbleDown(Data storage self, Node memory n, uint256 i) private{//
    uint256 length = self.nodes.length;
    uint256 cIndex = i*2; // left child index

    if(length <= cIndex){
      _insert(self, n, i);
    }else{
      Node memory largestChild = self.nodes[cIndex];

      if(length > cIndex+1 && self.nodes[cIndex+1].priority > largestChild.priority ){
        largestChild = self.nodes[++cIndex];// TEST ++ gets executed first here
      }

      if(largestChild.priority <= n.priority){ //TEST: priority 0 is valid! negative ints work
        _insert(self, n, i);
      }else{
        _insert(self, largestChild, i);
        _bubbleDown(self, n, cIndex);
      }
    }
  }

  function _insert(Data storage self, Node memory n, uint256 i) private{//√
    self.nodes[i] = n;
    self.indices[n.tokenId] = i;
  }
}