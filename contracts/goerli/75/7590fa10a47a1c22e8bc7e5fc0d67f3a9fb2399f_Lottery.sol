/**
 *Submitted for verification at Etherscan.io on 2022-08-29
*/

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
}

// File: LotteryNew.sol


// An example of a consumer contract that relies on a subscription for funding.
pragma solidity ^0.8.16;



contract Lottery is VRFConsumerBaseV2 {
  VRFCoordinatorV2Interface COORDINATOR;
  uint64 s_subscriptionId;
  address vrfCoordinator = 0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D;
  bytes32 keyHash = 0x79d3d8832d904592c0bf9818b621522c988bb8b0c05cdc3b15aea1b6e8db0c15;
  uint32 callbackGasLimit = 200000;
  uint16 requestConfirmations = 3; //chainlink節點確認數量
  uint32 numWords =  1; //產生幾個隨機數

  uint256[] public s_randomWords;
  uint256 public s_requestId;
  address s_owner;

  uint256 private _lotteryNumber;
  uint256 public _minBet=3000 wei; //最低投注金額
  uint256 public _mintPick = 6000 wei; //最低開講門檻
  uint256 public _expired = 4 minutes; //開獎時間限制,最慢N分鐘開獎
  uint256 public lotteryRound = 0 ; //第N期樂透
  address _owner;
  bool public isLocked=false;

  event ChainLinkGeneratorRandom(uint256 randomWords,uint256 totalParticipants);
  event LuckyWinner(uint256 _lotteryId,address winner,uint256 lotteryPot);
  event ExceedTimeRefund(uint256 _lotteryId);

  constructor(uint64 subscriptionId) VRFConsumerBaseV2(vrfCoordinator) {
    COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
    _owner = msg.sender;
    s_subscriptionId = subscriptionId;
  }

  struct Participant{
    address id; //錢包地址
    uint256 bet; //投注金額
  }

  struct LotteryData{
    uint256 pot; //總投注金額
    uint256 random; //該期樂透號碼
    address winner; //樂透得主錢包地址
    uint256 totalParticipants; //樂透總參與人數
    mapping(uint256=>Participant) participant;
    uint256 expired; //過期時間
    bool isActived; //是否active
    bool isAlreadyRandom; //是否已經產生隨機數,因為產生隨機數需要時間等待
  }

  mapping(uint256=>LotteryData) lotterys; //每期樂透資料(第N期=>第N期樂透資料)
  mapping(uint256=>uint256) public randomRequestIdWithNumbers;

  modifier onlyOwner() {
    require(msg.sender == _owner);
    _;
  }

  modifier isActive(uint256 _lotteryId){
    LotteryData storage lottery=lotterys[_lotteryId];
    require(lottery.isActived==true,"Lottery is not actived");
    _;
  }

  modifier isExpired(uint256 _lotteryId){
    LotteryData storage lottery=lotterys[_lotteryId];
    require(lottery.expired>block.timestamp,"Lottery is expired");
    _;
  }

  modifier potChecker(uint256 _lotteryId){
    LotteryData storage lottery=lotterys[_lotteryId];
    require(lottery.pot>=_mintPick,"not enough pot!");
    _;
  }

  // 避免pickWiner被重入攻擊
  modifier lock(){
    require(isLocked==false,"Error");
    isLocked=true;
    _;
    isLocked=false;
  }

  // 檢查樂透是否active
  // 檢查樂透是否過期
  function entery(uint256 _lotteryId) public payable 
    isActive(_lotteryId) 
    isExpired(_lotteryId)
  {
    // 檢查投注金額是否>=最小投注金額
    require(msg.value>=_minBet,"not enough bet value");
    // 取得第N期的樂透資料
    LotteryData storage lottery=lotterys[_lotteryId];
    uint256 totalParticipants=lottery.totalParticipants;
    // 參與人數,第N個參與人
    lottery.totalParticipants++;
    // 更新總投注金額
    lottery.pot+=msg.value;
    // 更新第N個參與者的錢包地址與投注金額
    lottery.participant[totalParticipants].id=msg.sender;
    lottery.participant[totalParticipants].bet=msg.value;
  }

  function openLottery(uint256 _lotteryId) public onlyOwner{
    LotteryData storage lottery=lotterys[_lotteryId];
    // 1.打開isActive
    lottery.isActived=true;

    // 2.設定lottery expired time
    lottery.expired=block.timestamp+_expired;

    // 3.lotteryRound++
    lotteryRound++;
  }

  function pickWinner(uint256 _lotteryId) public 
    onlyOwner
    lock
    isActive(_lotteryId)
    potChecker(_lotteryId)
  {
    LotteryData storage lottery=lotterys[_lotteryId];
    if(block.timestamp>lottery.expired){
      // 超過開獎期限,則退款每個人
      for(uint256 i=0;i<lottery.totalParticipants;i++){
        payable(lottery.participant[i].id).transfer(lottery.participant[i].bet);
        lottery.participant[i].bet=0;
      }
      emit ExceedTimeRefund(_lotteryId);
    }else{
      // 在開獎期限內,則選出幸運兒並轉獎金給他
      lottery.winner=lottery.participant[lottery.random].id;
      payable(lottery.winner).transfer(lottery.pot);
      emit LuckyWinner(_lotteryId,lottery.winner,lottery.pot);
    }
    lottery.isActived=false;
  }

  // 產生隨機數(不是立即產生,需要等待)
  function requestRandomWords(uint256 _lotteryId) external onlyOwner {
    // 判斷該期樂透是否已經產生過隨機數
    LotteryData storage lottery=lotterys[_lotteryId];
    require(lottery.isAlreadyRandom==false,"Already generate random number!");

    s_requestId = COORDINATOR.requestRandomWords(
      keyHash,
      s_subscriptionId,
      requestConfirmations,
      callbackGasLimit,
      numWords
    );

    // 將requestID跟_lotteryID對應起來
    require(lottery.isAlreadyRandom,"Wait until random number generated");
    randomRequestIdWithNumbers[s_requestId]=_lotteryId;

  }

  // fulfillRandomWords()該函數不是給我們呼叫的,是給chainlink使用的
  // requestRandomWords()產生隨機數後,會自動呼叫fulfillRandomWords()
  function fulfillRandomWords(
    uint256 requestId, /* requestId */
    uint256[] memory randomWords
  ) internal override {
    s_randomWords = randomWords;
    uint256 lotteryId=randomRequestIdWithNumbers[requestId];
    // 1.取得本期樂透資料
    LotteryData storage lottery=lotterys[lotteryId];
    // 2.本期樂透資料的隨機數
    lottery.random=randomWords[0]/lottery.totalParticipants;
    // 3.將isAlreadyRandom改為true
    lottery.isAlreadyRandom=true;
    // 4.宣告事件,有時chainlink會有狀況,方便debug
    emit ChainLinkGeneratorRandom(randomWords[0],lottery.totalParticipants);
  }

}