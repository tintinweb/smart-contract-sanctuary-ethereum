//SPDX-License-Identifier: Unlicense
// Copyright (c) 2022 Girlboss Gatekeepers LLC. All Rights Reserved
pragma solidity ^0.8.x;

import "./Heap.sol";
import "./VRFConsumerBaseV2.sol";
import "./VRFCoordinatorV2Interface.sol";

struct Offer {
    bool isForSale;
    uint256 punkIndex;
    address seller;
    int256 minValue;          // in ether
    address onlySellTo;        // specify to sell only to a specific person
}

struct Bid {
    bool hasBid;
    uint256 punkIndex;
    address bidder;
    int256 value; //in wei
}

contract eegods is VRFConsumerBaseV2 {
    using Heap for Heap.Data;
    Heap.Data data;

    address public _admin;

    //address public _link;

    int256 public _mintPrice00;

    string private _name;
    string private _symbol;

    uint8 public decimals;
    uint256 public totalSupply;

    uint public nextPunkIndexToAssign = 0;

    bool public allPunksAssigned = false;
    uint public punksRemainingToAssign = 0;

    mapping(uint => address) public punkIndexToAddress;

    /* This creates an array with all balances */
    mapping(address => uint256) public balanceOf;

    // A record of punks that are offered for sale at a specific minimum value, and perhaps to a specific person
    mapping(uint => Offer) public punksOfferedForSale;

    // A record of the highest punk bid
    mapping(uint => Bid) public punkBids;

    mapping(address => int) public pendingWithdrawals;

    event Assign(address indexed to, uint256 punkIndex);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event PunkTransfer(address indexed from, address indexed to, uint256 punkIndex);
    event PunkOffered(uint indexed punkIndex, int256 minValue, address indexed toAddress);
    event PunkBidEntered(uint indexed punkIndex, uint value, address indexed fromAddress);
    event PunkBidWithdrawn(uint indexed punkIndex, int256 value, address indexed fromAddress);
    event PunkBought(uint indexed punkIndex, int256 value, address indexed fromAddress, address indexed toAddress);
    event PunkNoLongerForSale(uint indexed punkIndex);

    VRFCoordinatorV2Interface COORDINATOR;

    uint256 public s_requestId;

    function getRando() public {

        // Your subscription ID.
        uint64 s_subscriptionId = 2822;

        // For this example, retrieve 2 random values in one request.
        // Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.
        uint32 numWords = 1;

        // The default is 3, but you can set this higher.
        uint16 requestConfirmations = 3;

        // The gas lane to use, which specifies the maximum gas price to bump to.
        // For a list of available gas lanes on each network,
        // see https://docs.chain.link/docs/vrf-contracts/#configurations
        bytes32 keyHash = 0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc;

        // Depends on the number of requested values that you want sent to the
        // fulfillRandomWords() function. Storing each word costs about 20,000 gas,
        // so 100,000 is a safe default for this example contract. Test and adjust
        // this limit based on the network that you select, the size of the request,
        // and the processing of the callback request in the fulfillRandomWords()
        // function.
        uint32 callbackGasLimit = 100000;
        
        // fulfillRandomWords(1, randomWords);
        // you dont do fulfill randomness here - that is an async method called by CL 
        // instead we hit requestRandomness
        s_requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );

    }

   event Random(uint256 number);

   function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        // this is good 
        // transform the result to a number between 0 and 1 inclusively
        uint256 value = (randomWords[0] % 2);

        emit Random(value);

        // assign the transformed value to the address in the s_results mapping variable
        //s_results[s_rollers[requestId]] = d20Value;

        // emitting event to signal that dice landed
        //emit DiceLanded(requestId, d20Value);
    }

    /** 
     * Make sure tokenIds start at 1, not 0
     */
    constructor(address vrfCoordinator) VRFConsumerBaseV2(vrfCoordinator) {

        //_link = link_;
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);

    
        _name = "eegods";                       // Set the name for display purposes
        _symbol = "EEGODS";                     // Set the symbol for display purposes

        _admin = msg.sender;

        totalSupply = 10;
        punksRemainingToAssign = totalSupply;

        data.init(); //this or below...
        //_mintPrice00 = 1000000000000000000; // in wei
        //data.nodes.push(Heap.Node(0,_mintPrice00));
    }

//actually min...
  function getMax() public view returns(Heap.Node memory){
    Heap.Node memory node = data.getMax();
    return node;
  }

  function getById(uint256 id) public view returns(Heap.Node memory){
    return data.getById(id);
  }

    // this gets replaced by a mint function
    function setInitialOwner(address to, uint punkIndex) public {
        if (punkIndexToAddress[punkIndex] != to) {
            if (punkIndexToAddress[punkIndex] != address(0)) {
                balanceOf[punkIndexToAddress[punkIndex]]--;
            } else {
                punksRemainingToAssign--;
            }
            punkIndexToAddress[punkIndex] = to;
            balanceOf[to]++;
            emit Assign(to, punkIndex);
        }
    }

    // this gets replaced by a mint function
    function setInitialOwners(address[] calldata addresses, uint256[] calldata indices) public {
        uint n = addresses.length;
        for (uint256 i = 0; i < n; i++) {
            setInitialOwner(addresses[i], indices[i]);
        }
    }

    // lock the sales until they've all been minted...
    function allInitialOwnersAssigned() public {
        allPunksAssigned = true;
    }

    // this gets replaced by a mint function
    function getPunk(uint256 punkIndex) public {
        punkIndexToAddress[punkIndex] = msg.sender;
        balanceOf[msg.sender]++;
        punksRemainingToAssign--;
        emit Assign(msg.sender, punkIndex);
    }

    // Transfer ownership of a punk to another user without requiring payment
    function transferPunk(address to, uint punkIndex) public {
        if (punksOfferedForSale[punkIndex].isForSale) {
            punkNoLongerForSale(punkIndex);
        }
        punkIndexToAddress[punkIndex] = to;
        balanceOf[msg.sender]--;
        balanceOf[to]++;
        emit Transfer(msg.sender, to, 1);
        emit PunkTransfer(msg.sender, to, punkIndex);
        // Check for the case where there is a bid from the new owner and refund it.
        // Any other bid can stay in place.
        Bid memory bid = punkBids[punkIndex];
        if (bid.bidder == to) {
            // Kill bid and refund value
            pendingWithdrawals[to] += bid.value;
            punkBids[punkIndex] = Bid(false, punkIndex, address(0), 0);
        }
    }

    function punkNoLongerForSale(uint punkIndex) public {
        punksOfferedForSale[punkIndex] = Offer(false, punkIndex, msg.sender, 0, address(0));
        emit PunkNoLongerForSale(punkIndex);
    }

    function offerPunkForSale(uint punkIndex, int256 minSalePriceInWei) public {

        data.insert(minSalePriceInWei, punkIndex);

        punksOfferedForSale[punkIndex] = Offer(true, punkIndex, msg.sender, minSalePriceInWei, address(0));
        emit PunkOffered(punkIndex, minSalePriceInWei, address(0));
    }

    function offerPunkForSaleToAddress(uint punkIndex, int128 minSalePriceInWei, address toAddress) public {

        data.insert(minSalePriceInWei, punkIndex);

        punksOfferedForSale[punkIndex] = Offer(true, punkIndex, msg.sender, minSalePriceInWei, toAddress);
        emit PunkOffered(punkIndex, minSalePriceInWei, toAddress);
    }

    function buyPunk(uint256 punkIndex) payable public {
        Offer memory offer = punksOfferedForSale[punkIndex];
        require(offer.isForSale);                // punk not actually for sale
        require(int(msg.value) >= offer.minValue);      // Didn't send enough ETH
        require(offer.seller == punkIndexToAddress[punkIndex]); // Seller is owner of punk

        address seller = offer.seller;

        punkIndexToAddress[punkIndex] = msg.sender;
        balanceOf[seller]--;
        balanceOf[msg.sender]++;
        emit Transfer(seller, msg.sender, 1);

        punkNoLongerForSale(punkIndex);
        pendingWithdrawals[seller] += int(msg.value);
        emit PunkBought(punkIndex, int(msg.value), seller, msg.sender);

        // Check for the case where there is a bid from the new owner and refund it.
        // Any other bid can stay in place.
        Bid memory bid = punkBids[punkIndex];
        if (bid.bidder == msg.sender) {
            // Kill bid and refund value
            pendingWithdrawals[msg.sender] += bid.value;
            punkBids[punkIndex] = Bid(false, punkIndex, address(0), 0);
        }

        /* * */
        data.extractById(punkIndex);
    }

    function withdraw() public {
        uint256 amount = uint256(pendingWithdrawals[msg.sender]);
        // Remember to zero the pending refund before
        // sending to prevent re-entrancy attacks
        pendingWithdrawals[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }

    function enterBidForPunk(uint punkIndex) public payable {
        require(punkIndexToAddress[punkIndex] != msg.sender);
        require(msg.value != 0);
        Bid memory existing = punkBids[punkIndex];
        require(int256(msg.value) >= existing.value);
        if (existing.value > 0) {
            // Refund the failing bid
            pendingWithdrawals[existing.bidder] += existing.value;
        }
        punkBids[punkIndex] = Bid(true, punkIndex, msg.sender, int256(msg.value));
        emit PunkBidEntered(punkIndex, msg.value, msg.sender);
    }

    function acceptBidForPunk(uint256 punkIndex, int256 minPriceInWei) public {        
        require(punkIndexToAddress[punkIndex] == msg.sender, "not your punk");
        address seller = msg.sender;
        Bid memory bid = punkBids[punkIndex];
        require(bid.value != 0, "bid.value != 0");
        require(bid.value >= minPriceInWei, "bid.value > minPrice");

        punkIndexToAddress[punkIndex] = bid.bidder;
        balanceOf[seller]--;
        balanceOf[bid.bidder]++;
        emit Transfer(seller, bid.bidder, 1);

        punksOfferedForSale[punkIndex] = Offer(false, punkIndex, bid.bidder, 0, address(0));
        int amount = bid.value;
        punkBids[punkIndex] = Bid(false, punkIndex, address(0), 0);
        pendingWithdrawals[seller] += amount;
        emit PunkBought(punkIndex, bid.value, seller, bid.bidder);

        //if it's below the floor, do the thing...
    }

    function withdrawBidForPunk(uint256 punkIndex) public {               
        require(punkIndexToAddress[punkIndex] == address(0));
        require(punkIndexToAddress[punkIndex] != msg.sender);
        Bid memory bid = punkBids[punkIndex];
        require(bid.bidder == msg.sender);
        emit PunkBidWithdrawn(punkIndex, bid.value, msg.sender);
        int amount = bid.value;
        punkBids[punkIndex] = Bid(false, punkIndex, address(0), 0);
        // Refund the bid money
        payable(msg.sender).transfer(uint(amount));
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

  function getMax(Data storage self) internal view returns(Node memory){

    Node memory node = getByIndex(self, ROOT_INDEX);

    int256 priority = node.priority;
    node.priority  = priority * -1;

    return node;
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.x;

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