/**
 *Submitted for verification at Etherscan.io on 2022-07-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

abstract contract VRFConsumerBaseV2 {
  error OnlyCoordinatorCanFulfill(address have, address want);
  address private immutable vrfCoordinator;

  constructor(address _vrfCoordinator) {
    vrfCoordinator = _vrfCoordinator;
  }

  function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal virtual;


  function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external {
    if (msg.sender != vrfCoordinator) {
      revert OnlyCoordinatorCanFulfill(msg.sender, vrfCoordinator);
    }
    fulfillRandomWords(requestId, randomWords);
  }
}

pragma solidity ^0.8.0;

interface VRFCoordinatorV2Interface {

  function getRequestConfig()
    external
    view
    returns (
      uint16,
      uint32,
      bytes32[] memory
    );

  function requestRandomWords(
    bytes32 keyHash,
    uint64 subId,
    uint16 minimumRequestConfirmations,
    uint32 callbackGasLimit,
    uint32 numWords
  ) external returns (uint256 requestId);

  function createSubscription() external returns (uint64 subId);

  function getSubscription(uint64 subId)
    external
    view
    returns (
      uint96 balance,
      uint64 reqCount,
      address owner,
      address[] memory consumers
    );

  function requestSubscriptionOwnerTransfer(uint64 subId, address newOwner) external;

  function acceptSubscriptionOwnerTransfer(uint64 subId) external;

  function addConsumer(uint64 subId, address consumer) external;

  function removeConsumer(uint64 subId, address consumer) external;

  function cancelSubscription(uint64 subId, address to) external;
}

pragma solidity ^0.8.7;

contract BGFVRFDRAWS is VRFConsumerBaseV2 {

    VRFCoordinatorV2Interface COORDINATOR;    
    uint64 s_subscriptionId;
    uint64 public entries;
    uint32 public numWords = 1;
    mapping(uint256 => uint256) public picks;
    address vrfCoordinator = 0x271682DEB8C4E0901D1a1550aD2e64D568E69909;
    bytes32 s_keyHash = 0x8af398995b04c28e9951adb9721ef74c74f93e6a478f39e7e0777be13527e7ef;    
    uint32 callbackGasLimit = 20000;
    uint16 public requestConfirmations = 3;
    address s_owner;

    event PickRequested(uint256 indexed requestId, address indexed roller);
    event PickReceived(uint256 indexed requestId, uint256 indexed result);

    constructor() VRFConsumerBaseV2(vrfCoordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        s_owner = msg.sender;
    }

    function requestPick() public onlyOwner returns (uint256 requestId) {
        requestId = COORDINATOR.requestRandomWords(
            s_keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );        
        emit PickRequested(requestId, msg.sender);
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override{
        uint256 pick = (randomWords[0] % entries) + 1;
        picks[requestId] = pick;
        emit PickReceived(requestId, pick);
    }

    function setEntries(uint64 _entries) public onlyOwner{
        entries = _entries;
    }

    function setSubscriptionId(uint64 _id) public onlyOwner{
        s_subscriptionId = _id;
    }

    function setNumWords(uint32 _numWords) public onlyOwner{
        numWords = _numWords;
    }
 
    modifier onlyOwner() {
        require(msg.sender == s_owner);
        _;
    }
}