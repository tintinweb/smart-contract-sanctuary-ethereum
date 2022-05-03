/**
 *Submitted for verification at Etherscan.io on 2022-05-03
*/

// SPDX-License-Identifier: MIT
// File: @chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol


pragma solidity ^0.8.0;

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
}

// File: docs.chain.link/samples/VRF/VRFv2Consumer.sol


// An example of a consumer contract that relies on a subscription for funding.
pragma solidity ^0.8.7;

contract Betlify is VRFConsumerBaseV2 {
  //using SafeMath for uint256;
  VRFCoordinatorV2Interface COORDINATOR;

  // Your subscription ID.
  uint64 s_subscriptionId;

  // Rinkeby coordinator. For other networks,
  // see https://docs.chain.link/docs/vrf-contracts/#configurations
  address vrfCoordinator = 	0x6A2AAd07396B36Fe02a22b33cf443582f682c82f;

  // The gas lane to use, which specifies the maximum gas price to bump to.
  // For a list of available gas lanes on each network,
  // see https://docs.chain.link/docs/vrf-contracts/#configurations
  bytes32 keyHash = 0xd4bb89654db74673a187bd804519e65e3f71a52bc55f11da7601a13dcf505314;

  // Depends on the number of requested values that you want sent to the
  // fulfillRandomWords() function. Storing each word costs about 20,000 gas,
  // so 100,000 is a safe default for this example contract. Test and adjust
  // this limit based on the network that you select, the size of the request,
  // and the processing of the callback request in the fulfillRandomWords()
  // function.
  uint32 callbackGasLimit = 2500000;

  // The default is 3, but you can set this higher.
  uint16 requestConfirmations = 3;

  // For this example, retrieve 2 random values in one request.
  // Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.
  uint32 numWords =  2;

  uint256[] public s_randomWords;
  uint256 public s_requestId;
  address s_owner;
 
  uint256 public totalBets;
  uint256 public totalStakeLockedValue;
  

  uint256 public rewardPoolFees;
  uint256 public unstakeFees;
  uint256 public devFees;
  uint256 public marketingFees;
  uint256 public referralFees;
  
  uint256 public maxBetPercentage;

  uint256 public devWalletBalance;
  uint256 public markeitngWalletBalance;
  uint256 public rewardPoolBalance;

  address public devAddress;
  address public marketingAddress;
  
  mapping (address => uint256) public userBet;
  mapping (uint256 => uint256) public betValue;
  mapping (address => uint256) public playerCurrentResult1;
  mapping (address => uint256) public playerCurrentResult2;
  mapping (address => uint256) public playerTotalBets;
  mapping (address => address) public playerReferrer;
  mapping (address => uint256) public referralUnclaimedBalance;
  mapping (address => uint256) public referralEarnings;

  mapping (address => bool) public roundStatus;
  mapping (address => uint256) public unclaimedWinning;
  mapping (address => uint256) public userLostBalance;
  mapping (address => uint256) public userStakes;
  mapping (address => uint256) public totalRewardsClaimed;
  mapping (uint256 => address) public requesterAddress;

  struct Bet{
    uint256 requestId;
    uint256 amount;
    uint256 bet;
    uint256 dice1Result;
    uint256 dice2Result;
    bool isWon;
    uint256 createdTime;
  }

  Bet bet;
  mapping (address => Bet[]) public userBets;

  constructor() VRFConsumerBaseV2(vrfCoordinator) {
    COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
    s_owner = msg.sender;
    //s_subscriptionId = subscriptionId;
    setSubscriptionId(687);
    //setWinningBonus(25);
    setRewardPoolFees(5);
    setUnstakeFees(5);
    setDevFees(5);
    setMarketingFees(5);
    setReferralFees(5);
    setDevAddress(0xA2a295E49e262226F152681bc9c7A719Cb8d23C5);
    setMarketingAddress(0xA2a295E49e262226F152681bc9c7A719Cb8d23C5);
    setMaxBetPercentage(10);
  }

  function setSubscriptionId(uint64 _setSubscriptionId) public onlyOwner {
    s_subscriptionId = _setSubscriptionId;
  }

  /*
  function setWinningBonus(uint256 _winningBonus) public onlyOwner {
    winningBonus = _winningBonus;
  }
  */

  function setRewardPoolFees(uint256 _rewardPoolFees) public onlyOwner {
    rewardPoolFees = _rewardPoolFees;
  }

  function setUnstakeFees(uint256 _unstakeFees) public onlyOwner {
    unstakeFees = _unstakeFees;
  }

  function setDevFees(uint256 _devFees) public onlyOwner {
    devFees = _devFees;
  }

  function setMarketingFees(uint256 _marketingFees) public onlyOwner {
    marketingFees = _marketingFees;
  }

  function setReferralFees(uint256 _referralFees) public onlyOwner {
    referralFees = _referralFees;
  }
  

  function setDevAddress(address _devAddress) public onlyOwner {
    devAddress = _devAddress;
  }

  function setMarketingAddress(address _marketingAddress) public onlyOwner {
    marketingAddress = _marketingAddress;
  }

  function setMaxBetPercentage(uint256 _maxBetPercentage) public onlyOwner {
    maxBetPercentage = _maxBetPercentage;
  }

  function betUp(address _referrer) public payable{
    rollDice(1,_referrer);
  }

  function betDown(address _referrer) public payable{
    rollDice(0,_referrer);
  }

  // Assumes the subscription is funded sufficiently.
  function rollDice(uint16 _bet, address _referrer) internal {
    // Will revert if subscription is not set and funded.
    require(roundStatus[msg.sender] == false,"Your game round is already in progress, Please wait till round is finished");
    
    if(playerReferrer[msg.sender] == address(0x0)) {
      playerReferrer[msg.sender] = _referrer;
    }
    
    //playerBetAmount[msg.sender] = msg.value;
    playerCurrentResult1[msg.sender] = 0;
    playerCurrentResult2[msg.sender] = 0;
    playerTotalBets[msg.sender]++;

    s_requestId = COORDINATOR.requestRandomWords(
      keyHash,
      s_subscriptionId,
      requestConfirmations,
      callbackGasLimit,
      numWords
    );
    
    userBet[msg.sender] = _bet;
    requesterAddress[s_requestId] = msg.sender;
    totalBets += msg.value;
    betValue[s_requestId] = msg.value;
    roundStatus[msg.sender] = true;
  }
  
  function getRoundStatus() public view returns (bool){
      return roundStatus[msg.sender];
  }

  function getRoundStatusByAddress(address _address) public view returns (bool){
      return roundStatus[_address];
  }

  function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords ) internal override {
  
    address playerAddress = requesterAddress[requestId];
    bool isWon;

    playerCurrentResult1[playerAddress] = (randomWords[0] % 5) + 1;
    playerCurrentResult2[playerAddress] = (randomWords[1] % 5) + 1;

    roundStatus[playerAddress] = false;
    
    if(userBet[playerAddress] == 1){
      if((playerCurrentResult1[playerAddress]+playerCurrentResult2[playerAddress]) >= 7){
          addBets(playerAddress, requestId, userBet[playerAddress], betValue[requestId], playerCurrentResult1[playerAddress],playerCurrentResult2[playerAddress],true);
          //unclaimedWinning[playerAddress] += betValue[requestId];
          isWon = true;
      }else{
          addBets(playerAddress, requestId, userBet[playerAddress], betValue[requestId], playerCurrentResult1[playerAddress],playerCurrentResult2[playerAddress],false);
          userLostBalance[playerAddress] += betValue[requestId];
      }
    }else {
      if((playerCurrentResult1[playerAddress]+playerCurrentResult2[playerAddress]) < 7){
        addBets(playerAddress, requestId, userBet[playerAddress], betValue[requestId], playerCurrentResult1[playerAddress],playerCurrentResult2[playerAddress],true);
        //unclaimedWinning[playerAddress] += betValue[requestId];
        isWon = true;
      }else{
        addBets(playerAddress, requestId, userBet[playerAddress], betValue[requestId], playerCurrentResult1[playerAddress],playerCurrentResult2[playerAddress],false);
        userLostBalance[playerAddress] += betValue[requestId];
      }
    }
    //autoStake(playerAddress, betValue[requestId]);
    processBetDistribution(playerAddress,betValue[requestId],isWon);
  }

  function processBetDistribution(address _playerAddress, uint256 _amount, bool _isWon) public {
    devWalletBalance += (_amount * devFees)/100;
    markeitngWalletBalance += (_amount * marketingFees)/100;
    rewardPoolBalance += (_amount * rewardPoolFees)/100;

    address referrerPlayer = playerReferrer[_playerAddress];

    if(referrerPlayer != address(0)){
      referralUnclaimedBalance[referrerPlayer] += (_amount * referralFees)/100;
    }
    
    if(_isWon){
      unclaimedWinning[_playerAddress] += (_amount - (_amount * getTotalFees())/100);
    }
    //uint256 stakeAmount = (_amount - (_amount * getTotalFees())/100);
    autoStake(_playerAddress, _amount);
  }

  function processUnstaketDistribution(address _playerAddress, uint256 _amount) public {
    devWalletBalance += (_amount * devFees)/100;
    markeitngWalletBalance += (_amount * marketingFees)/100;
    rewardPoolBalance += (_amount * rewardPoolFees)/100;

    address referrerPlayer = playerReferrer[_playerAddress];

    if(referrerPlayer != address(0)){
      referralUnclaimedBalance[referrerPlayer] += (_amount * referralFees)/100;
    }
  
    //userStakes[_playerAddress] -= (_amount - (_amount * getTotalFees())/100);
    //unstake(unstakeAmount);
  }

  function getTotalFees() public view returns(uint256){
    return (devFees + marketingFees + rewardPoolFees + referralFees);
  }

  function addBets(address _playerAddress, uint256 _requestId, uint256 _bet, uint256 _amount, uint256 _dice1Result, uint256 _dice2Result, bool _isWon) internal {
    bet =  Bet(_requestId, _amount, _bet, _dice1Result, _dice2Result, _isWon, block.timestamp);
    userBets[_playerAddress].push(bet);
  }

  function getBets() public view returns (Bet[] memory){
      return userBets[msg.sender];
  }

  function getResult() public view returns (uint256, uint256, bool){
    bool isWon;
    if(userBet[msg.sender] == 1){
      if((playerCurrentResult1[msg.sender]+playerCurrentResult2[msg.sender]) >= 7){
        isWon = true;
      }
    }else {
      if((playerCurrentResult1[msg.sender]+playerCurrentResult2[msg.sender]) < 7){
        isWon = true;
      }
    }
    return(playerCurrentResult1[msg.sender],playerCurrentResult2[msg.sender],isWon);
  }

  function getResultByAddress(address _address) public view returns (uint256, uint256, bool){
    bool isWon;
    if(userBet[_address] == 1){
      if((playerCurrentResult1[_address]+playerCurrentResult2[_address]) >= 7){
        isWon = true;
      }
    }else {
      if((playerCurrentResult1[_address]+playerCurrentResult2[_address]) < 7){
        isWon = true;
      }
    }
    return(playerCurrentResult1[_address],playerCurrentResult2[_address],isWon);
  }

  function stake() public payable{
    userStakes[msg.sender] += msg.value;
    totalStakeLockedValue += msg.value;
  }

  function autoStake(address _playerAddress, uint256 _amount) internal {
    userStakes[_playerAddress] += _amount;
    totalStakeLockedValue += msg.value;
  }

  function unstake(uint256 _amount) public {
      //uint256 unstakableBalance = userStakes[msg.sender];
      require(_amount <= userStakes[msg.sender],"Unstaking balance is greater than staked balance");
      processUnstaketDistribution(msg.sender,_amount);
      userStakes[msg.sender] -= _amount;
      totalStakeLockedValue -= _amount;

      uint256 unstakeblaeAmount = (_amount - (_amount * getTotalFees())/100);
      (bool success, ) = msg.sender.call{value: unstakeblaeAmount}("");
      require(success, "Transfer failed.");
  }

  function claimRewards() public {
    uint256 claimableRewards = 0.0001 ether;
    (bool success, ) = msg.sender.call{value: claimableRewards}("");
    require(success, "Transfer failed.");
  }

  function claimWinnings() public {
    uint256 claimableWinnings = unclaimedWinning[msg.sender];
    unclaimedWinning[msg.sender] = 0;
    (bool success, ) = msg.sender.call{value: claimableWinnings}("");
    require(success, "Transfer failed.");
  }

  function getUnclaimedRewards() public view returns (uint256){
    return (userStakes[msg.sender] + 10);
  }

  function getUnclaimedRewardsByAddress() public view returns (uint256){
    return (userStakes[msg.sender] + 10);
  }

  modifier onlyOwner() {
    require(msg.sender == s_owner);
    _;
  }

  receive() external payable {
    stake();
  }
}