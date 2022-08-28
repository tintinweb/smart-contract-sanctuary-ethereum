/**
 *Submitted for verification at Etherscan.io on 2022-08-28
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

// File: contracts/lottery.sol


pragma solidity 0.8.16;




contract Lottery is VRFConsumerBaseV2 {
    VRFCoordinatorV2Interface COORDINATOR;

    uint64 s_subscriptionId;
    address vrfCoordinator = 0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D;
    bytes32 keyHash = 0x79d3d8832d904592c0bf9818b621522c988bb8b0c05cdc3b15aea1b6e8db0c15;
    uint32 callbackGasLimit = 200000;
    uint16 requestConfirmations = 3;
    uint32 numWords =  1;

    uint256 private _lotterNumber;
    uint256 public _mintBet = 3000 wei; // 投一注需要的金額
    uint256 public _minPick = 6000 wei; // 開獎需達成的金額
    uint256 public _expired = 10 minutes;

    uint256 public lotteryRound = 0;
    address _owner;
    bool isLocked = false;

    struct Participant {
        address id; // 參加者的錢包地址
        uint256 bet; // 參加者投入的金額
    }
    
    // 每一期樂透儲存的屬性
    struct LotteryData {
        uint256 random; // 產生出來的隨機數
        uint256 pot; // 總投注額
        address winner; // 幸運兒錢包地址
        uint256 totalParticipants; // 總投注人數
        mapping(uint256 => Participant) participant;
        uint256 expired; // 過期時間
        bool isActived; // 這期樂透是否為 isActived 狀態
        bool isAlreadyRandom; // 是否產生隨機數
    }
    mapping(uint256 => LotteryData) public lotterys; // 每一期樂透資料
    mapping(uint256 => uint256) public randomRequestIdWithNumbers;

    modifier onlyOwner() {
        require(msg.sender == _owner);
        _;
    }

    modifier isActive(uint256 _lotteryId) {
        LotteryData storage lottery = lotterys[_lotteryId];
        // lottery.isActive 檢查這期樂透投注狀態 isActive == true
        // require(lottery.isActived == true, "Lottery not actived");
        require(lottery.isActived, "Lottery not actived");
        _;
    }

    // 判斷這期樂透沒有過期
    modifier notExpired(uint256 _lotteryId) {
        LotteryData storage lottery = lotterys[_lotteryId];
        require(block.timestamp < lottery.expired, "Lottery is expired!");
        _;
    }

    // 本期樂透總獎金必須累積到某個金額（例：0.01 eth），owner才可開獎
    modifier potChecker(uint256 _lotteryId) {
        LotteryData storage lottery = lotterys[_lotteryId];
        require(lottery.pot >= _minPick, "not enough pot!");
        _;
    }

    modifier lock() {
        require(!isLocked, "don't do that!!");
        isLocked = true;
        _;
        isLocked = false;
    }
    
    // 紀錄 VRF 回傳的資訊，debug
    event ChainLinkGeneratorRandom(uint256 _randomNumberFormChainLink, uint256 _totalParticipants);
    // 紀錄第幾期的幸運得主、獲得的總獎金
    event LuckyWinnerBorn(uint256 _lotteryId, address _winner, uint256 _pot);
    // 若已超過開獎時間，未累積到指定開獎金額，則退款給本期所有投注者
    event ExceendTimeAndRefund(uint256 _lotteryId);

    constructor(uint64 subscriptionId) VRFConsumerBaseV2(vrfCoordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        s_subscriptionId = subscriptionId;
        _owner = msg.sender;
    }

    // 1. 先呼叫 openLottery 開啟投注
    // 2. 呼叫 entry 投注
    // 3. 呼叫 requestRandomWords 向預言機請求隨機數
    // 4. 呼叫 pickWinner 挑出幸運得主
    
    
    // 投注
    function entry(uint256 _lotteryId) public payable 
        isActive(_lotteryId)
        notExpired(_lotteryId)
    {
        // [ok] 驗證這個樂透是不是 isActive
        // [ok] 驗證這個樂透有沒有過期
        // [ok] 驗證他的金額有沒有大於最小投注額
        require(msg.value >= _mintBet, "not engouh bet value!");

        LotteryData storage lottery = lotterys[_lotteryId];
        uint256 totalParticipants = lottery.totalParticipants;
        // 增加樂透總人數
        lottery.totalParticipants++;
        // 總投注額
        // lottery.pot = lottery.po + msg.value;
        lottery.pot += msg.value;
        lottery.participant[totalParticipants].id = msg.sender;
        lottery.participant[totalParticipants].bet = msg.value;
    }

    /*
        ------------------- Owner ----------------------
    */

    // 打開當期樂透
    function openLottery() external onlyOwner {
        LotteryData storage lottery = lotterys[lotteryRound];

        // 1) 把 isActive 狀態打開
        lottery.isActived = true;

        // 2) 設定 lottery expired 
        lottery.expired = block.timestamp + _expired;

        // 3) lotteryRound 增加
        lotteryRound++;
    }

    // 挑選出幸運得主
    function pickWinner(uint256 _lotteryId) external onlyOwner
        isActive(_lotteryId)
        potChecker(_lotteryId)
        lock
    {
        LotteryData storage lottery = lotterys[_lotteryId];

        /*
            若已超過開獎時間
            未累積到指定開獎金額（例：0.01 eth），則退款給本期所有投注者
        */
        if (block.timestamp > lottery.expired) {
            for (uint256 i; i < lottery.totalParticipants; i++) {
                payable(lottery.participant[lottery.random].id).transfer(lottery.participant[lottery.random].bet);
                lottery.participant[lottery.random].bet = 0;
            }
            // 紀錄事件：退款給本期所有投注者
            emit ExceendTimeAndRefund(_lotteryId);
        } else {
            // 檢查確認已產生隨機數
            require(lottery.isAlreadyRandom, "Not Request Random");
            address winner = lottery.participant[lottery.random].id;
            lottery.winner = winner;

            // 本期投注總派彩會轉給幸運得主
            payable(winner).transfer(lottery.pot);
            // 紀錄事件：本期幸運得主
            emit LuckyWinnerBorn(_lotteryId, winner, lottery.pot);
        }

        lottery.isActived = false;
    }

    // 向預言機請求，取得隨機數
    function requestRandomWords(uint256 _lotteryId) 
        external     
        onlyOwner
        potChecker(_lotteryId)
        notExpired(_lotteryId)
    {
        LotteryData storage lottery = lotterys[_lotteryId];
        // 驗證是否已經產生隨機數
        require(!lottery.isAlreadyRandom, "already request random number!");
        // 向 chainLink 請求隨機數
        uint256 requestId = COORDINATOR.requestRandomWords(
          keyHash,
          s_subscriptionId,
          requestConfirmations,
          callbackGasLimit,
          numWords
        );

        randomRequestIdWithNumbers[requestId] = _lotteryId;
    }

    // ChainLink 產生完隨機數會 callback 回來此 function
    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {
        uint256 lotteryId = randomRequestIdWithNumbers[requestId];
        
        // 1) 取得本期的樂透資料
        LotteryData storage lottery = lotterys[lotteryId];
        
        // 2) 填寫本期樂透資料的隨機數 random
        // 返回來的隨機數 randomWords[0]
        lottery.random = randomWords[0] % lottery.totalParticipants;

        // 3) isAlreadyRandom 改為 ture
        lottery.isAlreadyRandom = true;

        // 4) 宣告事件 ChainLinkGeneratorRandom: 
        // 存入參數randowWords[0], lottery.totalParticipants
        emit ChainLinkGeneratorRandom(randomWords[0], lottery.totalParticipants);

    }
}