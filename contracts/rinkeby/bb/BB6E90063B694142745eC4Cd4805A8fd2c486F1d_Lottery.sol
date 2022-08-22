/**
 *Submitted for verification at Etherscan.io on 2022-08-22
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

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


contract Lottery is VRFConsumerBaseV2 {
  // using SafeMath for uint256;

  uint256 public prizeLimit = 100_000_000_000_000_000; // 0.1ETH
  uint256 public MAX_HOLDER_COUNT = 100000;
  uint256 public MSB = 65536; // 2 ^ 16
  uint256 public holderCount = 0;
  uint256 public totalSum = 0;
  mapping(uint256 => uint256) public BITree;
  mapping(address => uint256) public balances;
  mapping(address => bool) public registered;
  mapping(address => uint256) public holderIndexes;
  address[] public holders;
  uint256 public winnerIndex;
  address public s_owner;

  // vars for chainlink
  VRFCoordinatorV2Interface COORDINATOR;

  // Your subscription ID.
  uint64 s_subscriptionId;
  address vrfCoordinator = 0x6168499c0cFfCaCD319c818142124B7A15E857ab;
  bytes32 keyHash = 0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc;

  uint32 callbackGasLimit = 100000;
  uint16 requestConfirmations = 3;
  uint32 numWords = 2;

  uint256 public randomSum;
  uint256 public randomWord;
  uint256 public s_requestId;

  event WinnerSelected();
  event WinnerPrized(
    address indexed winner,
    uint256 ethReceived
  );

  constructor(uint64 subscriptionId) VRFConsumerBaseV2(vrfCoordinator) {
    COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
    s_subscriptionId = subscriptionId;
    s_owner = msg.sender;
  }

  function updateBIT(uint256 index, uint256 val, bool increased) internal {
    uint256 tIndex = index + 1;
    while(tIndex <= MAX_HOLDER_COUNT) {

      if(increased)
        BITree[tIndex] += val;
      else  
        BITree[tIndex] -= val;

      int256 sIndex = int256(tIndex);
      tIndex += uint256(sIndex & (-sIndex));
    }
  }

  function getSum(uint256 index) public view returns (uint256) {
    uint256 sum = 0;
    int256 tIndex = int256(index) + 1;

    while(tIndex > 0) {
      sum += BITree[uint256(tIndex)];
      tIndex -= tIndex & (-tIndex);
    }
    return sum;
  }

  function updateBalance(address holder, uint256 amount) external onlyOwner {
    if(registered[holder]) {
      if(balances[holder] > amount) {
        uint256 delta = balances[holder] - amount;
        updateBIT(holderIndexes[holder], delta, false);
        totalSum -= delta;
      } else {
        uint256 delta = amount - balances[holder];
        updateBIT(holderIndexes[holder], delta, true);
        totalSum += delta;
      }
    } else {
      holders.push(holder);
      holderIndexes[holder] = holderCount;
      registered[holder] = true;
      updateBIT(holderCount, amount, true);
      holderCount ++;
      totalSum += amount;
    }
    balances[holder] = amount;
  }

  function draw() external onlyOwner {
    uint256 ethAmount = address(this).balance;
    if(ethAmount < prizeLimit || holderCount == 0) {  
      emit WinnerPrized(address(0xdead), 0);
    } else {
      requestRandomWords();
    }
  }

  function getWinnerIndex(uint256 givenSum) public view returns (uint256) {
    uint256 idx = 0;
    uint256 cumFre = givenSum;
    uint256 bitMask = MSB;
    while(bitMask != 0) {
      uint256 tIdx = idx + bitMask;
      bitMask >>= 1;

      if(tIdx > MAX_HOLDER_COUNT)
        continue;

      if(cumFre > BITree[tIdx]) {
        idx = tIdx;
        cumFre -= BITree[tIdx];
      }
    }

    return idx;
  }

  function isRegistered(address holder) external view returns (bool) {
    return registered[holder];
  }

  // chainlink functions
  // Assumes the subscription is funded sufficiently.
  function requestRandomWords() internal {
    // Will revert if subscription is not set and funded.
    s_requestId = COORDINATOR.requestRandomWords(
      keyHash,
      s_subscriptionId,
      requestConfirmations,
      callbackGasLimit,
      numWords
    );
  }

  function fulfillRandomWords(
    uint256, /* requestId */
    uint256[] memory randomWords
  ) internal override {
    randomWord = randomWords[0];
    randomSum = randomWords[0] % totalSum + 1;
    
    emit WinnerSelected();
  }

  function payPrize() external onlyOwner {
    require(randomSum > 0, "Lottery: Random words are not fulfilled.");
    uint256 ethAmount = address(this).balance;
    
    winnerIndex = getWinnerIndex(randomSum);
    bool success;
    address winner = holders[winnerIndex];

    (success, ) = address(winner).call{value: ethAmount}("");
    require(success == true, "Lottery: Prize transfer failed");
    randomSum = 0;

    emit WinnerPrized(winner, ethAmount);
  }

  function setPrizeLimit(uint256 value) external onlyOwner {
    prizeLimit = value;
  }

  receive() external payable {}

  modifier onlyOwner() {
    require(msg.sender == s_owner);
    _;
  }
}