/**
 *Submitted for verification at Etherscan.io on 2023-03-04
*/

// SPDX-License-Identifier: MIT

// File: @chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol


pragma solidity ^0.8.4;

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness. It ensures 2 things:
 * @dev 1. The fulfillment came from the VRFCoordinator
 * @dev 2. The consumer contract implements fulfillRandomWords.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constructor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash). Create subscription, fund it
 * @dev and your consumer contract as a consumer of it (see VRFCoordinatorInterface
 * @dev subscription management functions).
 * @dev Call requestRandomWords(keyHash, subId, minimumRequestConfirmations,
 * @dev callbackGasLimit, numWords),
 * @dev see (VRFCoordinatorInterface for a description of the arguments).
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomWords method.
 *
 * @dev The randomness argument to fulfillRandomWords is a set of random words
 * @dev generated from your requestId and the blockHash of the request.
 *
 * @dev If your contract could have concurrent requests open, you can use the
 * @dev requestId returned from requestRandomWords to track which response is associated
 * @dev with which randomness request.
 * @dev See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ.
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request. It is for this reason that
 * @dev that you can signal to an oracle you'd like them to wait longer before
 * @dev responding to the request (however this is not enforced in the contract
 * @dev and so remains effective only in the case of unmodified oracle software).
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

// File: @chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol


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

// File: docs.chain.link/samples/VRF/CriptoLucky.sol


pragma solidity ^0.8.7;



 
interface CriptoLuckyToken{
  function _mintMinerReward(address receiver,uint256 value)external;
  function burnTokens(uint256 value) external;
}

contract CriptoLucky is VRFConsumerBaseV2 {
  VRFCoordinatorV2Interface COORDINATOR;
  struct PastLottery{
    mapping(uint=>bool)  WithdrawWinners;
    mapping(uint=>address)  winners;
    uint  prize;
    uint  percentageWithdrawal;  
    uint  Nwinners;
  }
  struct ActualLottery{
    uint  idGame;
    uint  prize;
    uint  pool;
    uint  costTicket;
    mapping(uint=>address)  TicketOwner;
    //Number of tickets bought by a wallet
    mapping(address=> uint) NTicketsOwner;
    //Max tickets that a single wallet can own 
    uint  maxTicketsPlayer;
    bool  active;
    //total tickets already sold
    uint  totalTickets;
    //total tickets on sale
    uint  maxTickets;
    uint32  Nwinners;
  }

  address hub;
  uint public withdrawal=0; 
  mapping(uint=>PastLottery)public PastLotteries;
  ActualLottery public _ActualLottery;
  uint public aeth= 10000000000000000;
  // Your subscription ID.
  uint64 s_subscriptionId;

  // Goerli coordinator. For other networks,
  // see https://docs.chain.link/docs/vrf-contracts/#configurations
  address vrfCoordinator = 0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D;

  // The gas lane to use, which specifies the maximum gas price to bump to.
  // For a list of available gas lanes on each network,
  // see https://docs.chain.link/docs/vrf-contracts/#configurations
  bytes32 keyHash = 0x79d3d8832d904592c0bf9818b621522c988bb8b0c05cdc3b15aea1b6e8db0c15;


  uint32 callbackGasLimit = 1000000;

  // The default is 3, but you can set this higher.
  uint16 requestConfirmations = 3;
  //Percentage of prize that each winner get.
  mapping(uint => mapping(uint=>uint)) public PercentageWinners;

  //Amount on randomNumber that we will ask to the Oracle to decide the winner,always will be +3 Nwinners to avoid that the same wallet wins twice
  mapping(uint=>uint32) NRandNum;


  uint256[] public s_randomWords;
  uint256 public s_requestId;
  address s_owner;
  uint256[] public prueba_randomWords;


  CriptoLuckyToken tokenReward;

  constructor(uint64 subscriptionId,address _tokenReward,address _hub) VRFConsumerBaseV2(vrfCoordinator) {
    COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
    s_owner = msg.sender;
    s_subscriptionId = subscriptionId;
    _ActualLottery.active=false;
    _ActualLottery.idGame=0;
    PercentageWinners[1][1]=100;
    PercentageWinners[2][1]=70;
    PercentageWinners[2][2]=30;
    PercentageWinners[3][1]=60;
    PercentageWinners[3][2]=30;
    PercentageWinners[3][3]=10;
    PercentageWinners[5][1]=60;
    PercentageWinners[5][2]=15;
    PercentageWinners[5][3]=15;
    PercentageWinners[5][4]=5;
    PercentageWinners[5][5]=5;
    tokenReward = CriptoLuckyToken(_tokenReward);
    hub=_hub;
  }
  
  function setPercentageWinners(uint _Nwinners,uint _place,uint _percentage)public onlyOwner{
      PercentageWinners[_Nwinners][_place]=_percentage;
  }
  function createLottery(uint _cost,uint _maxTicketsPlayer,uint32 _Nwinners,uint _maxTickets,uint _percentage)public onlyHubAndOwner{
    require(!_ActualLottery.active,"The lottery is still active");
    _ActualLottery.idGame++;
    cleanData();
    _ActualLottery.Nwinners=_Nwinners;
    PastLotteries[_ActualLottery.idGame].Nwinners=_Nwinners;
    _ActualLottery.costTicket=_cost*aeth;
    _ActualLottery.pool=_ActualLottery.costTicket*_maxTickets;
    PastLotteries[_ActualLottery.idGame].percentageWithdrawal=_percentage;
    _ActualLottery.prize=(_ActualLottery.pool)*(100-PastLotteries[_ActualLottery.idGame].percentageWithdrawal)/100;
    PastLotteries[_ActualLottery.idGame].prize=_ActualLottery.prize;
    _ActualLottery.maxTicketsPlayer=_maxTicketsPlayer;
    NRandNum[_ActualLottery.idGame]=_ActualLottery.Nwinners + 3;
    _ActualLottery.maxTickets=_maxTickets;
    _ActualLottery.active=true;
    

    }
    function setGaslimit(uint32 gas) public onlyOwner{
      callbackGasLimit=gas;
    }
  function joinFromHub(address _wallet,uint tickets)  public payable{
    require(_ActualLottery.active,"The lottery is not active");
    require(msg.value==tickets*_ActualLottery.costTicket,"Wrong ammount of eth");
    require(_ActualLottery.NTicketsOwner[_wallet]+tickets<= _ActualLottery.maxTicketsPlayer,"you exceeded the limit of tickets of your account");
    require(_ActualLottery.totalTickets+tickets<=_ActualLottery.maxTickets,"No enought tickets available");

    for(uint i=_ActualLottery.totalTickets;i<_ActualLottery.totalTickets+tickets;i++){
      _ActualLottery.TicketOwner[i]=_wallet;
    }
    _ActualLottery.totalTickets+=tickets;
    _ActualLottery.NTicketsOwner[_wallet]+=tickets;
    withdrawal+=msg.value*PastLotteries[_ActualLottery.idGame].percentageWithdrawal/100;
    uint256 ticketsRewarded =tickets*_ActualLottery.costTicket/aeth;
    tokenReward._mintMinerReward(_wallet,ticketsRewarded);
  }
  function join(uint tickets)public payable{
    joinFromHub(msg.sender,tickets);
  }



  function cleanData() private onlyHubAndOwner{
    require(!_ActualLottery.active,"The lottery is still active");
    for(uint i=0;i<_ActualLottery.totalTickets;i++){
      _ActualLottery.NTicketsOwner[_ActualLottery.TicketOwner[i]]=0;
      _ActualLottery.TicketOwner[i]=0x8B66676696E61EE8748e30AA5a07D18BaD0810D8;
    }
    
    _ActualLottery.totalTickets=0;

  }

  // Assumes the subscription is funded sufficiently.
  function endGame() external onlyHubAndOwner {
    // Will revert if subscription is not set and funded.
    require(_ActualLottery.active,"The lottery is not active");
    s_requestId = COORDINATOR.requestRandomWords(
      keyHash,
      s_subscriptionId,
      requestConfirmations,
      callbackGasLimit,
      NRandNum[_ActualLottery.idGame]
    );
  }
  function fulfillRandomWords(
    uint256, /* requestId */
    uint256[] memory randomWords
  ) internal override {
    s_randomWords = randomWords;
    for(uint32 i=0;i<NRandNum[_ActualLottery.idGame];i++){
      s_randomWords[i] = randomWords[i]%_ActualLottery.totalTickets;
    }
    _ActualLottery.active=false;
  }
 function setWinners() public onlyHubAndOwner {
    require(!_ActualLottery.active,"The lottery is still active");
    uint j=0;
    for(uint i=0;i<_ActualLottery.Nwinners;){
      if(i==0){
        PastLotteries[_ActualLottery.idGame].winners[i]=_ActualLottery.TicketOwner[s_randomWords[j]];
        j+=1;
        i++;
      }else if(compareRand(_ActualLottery.TicketOwner[s_randomWords[j]],i)){
        PastLotteries[_ActualLottery.idGame].winners[i]=_ActualLottery.TicketOwner[s_randomWords[j]];
        j+=1;
        i++;
      }else{
        j+=1;
      }
    }
  }
  
  //compareRand(s_randomWords[j]%totalTickets,i)
  function compareRand(address NumTocompare,uint positionInList) private view returns(bool) {
      bool different=true;
      for(uint i=0;i<positionInList;i++){
        if(NumTocompare==PastLotteries[_ActualLottery.idGame].winners[i]){
          different= false;
        }
      }
      return different;
    }
  function withdrawByWinner(uint _idGame)public{
    withdrawByWinnerFromHub(msg.sender,_idGame);
  }
    function withdrawByWinnerFromHub(address _address,uint _idGame)public {
    bool isWinner=false;
    uint place;
    for(uint i=0;i<PastLotteries[_idGame].Nwinners;i++){
      if(_address==PastLotteries[_idGame].winners[i] && !PastLotteries[_idGame].WithdrawWinners[i]){
        isWinner=true;
        place=i;
        PastLotteries[_idGame].WithdrawWinners[i]=true;
      }
    }
    require(isWinner,"You must be a winner");
    (bool success,)=_address.call{value:PastLotteries[_idGame].prize*(PercentageWinners[PastLotteries[_idGame].Nwinners][place+1])/100}("");
    require(success, "Transfer failed!");
  }


  function withdraw() public onlyOwner{
    (bool success,)=s_owner.call{value:withdrawal}("");
    require(success, "Transfer failed!");
    withdrawal=0;
  }
  function ProbWithdraw()public onlyOwner{
    (bool success,)=msg.sender.call{value:address(this).balance}("");
    require(success, "Transfer failed!");
  }
  function changeHub(address _hub)public onlyOwner{
    hub=_hub;
  }
  function getPlayers()public view returns (address[] memory){
    address[] memory ret = new address[](_ActualLottery.totalTickets);
    for (uint i = 0; i <_ActualLottery.totalTickets; i++) {
        ret[i] = _ActualLottery.TicketOwner[i];
    }
    return ret;
  }
  function getWinners(uint256 id)public view returns (address[] memory){
    address[] memory ret = new address[](PastLotteries[id].Nwinners);
    for (uint i = 0; i <PastLotteries[id].Nwinners; i++) {
        ret[i] = PastLotteries[id].winners[i];
    }
    return ret;
  }
  function getIfWinners(uint256 id)public view returns (bool[] memory){
    bool[] memory ret = new bool[](PastLotteries[id].Nwinners);
    for (uint i = 0; i <PastLotteries[id].Nwinners; i++) {
        ret[i] = PastLotteries[id].WithdrawWinners[i];
    }
    return ret;
  }
  function getNmofTicketsBought(address addr)public view returns (uint){
    
    return _ActualLottery.NTicketsOwner[addr];
  }

  modifier onlyOwner() {
    require(msg.sender == s_owner);
    _;
  }
  modifier onlyHubAndOwner(){
    require(msg.sender == s_owner|| msg.sender==hub);
    _;
  }
  
}