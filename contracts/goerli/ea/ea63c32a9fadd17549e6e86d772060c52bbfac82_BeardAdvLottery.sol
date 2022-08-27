/**
 *Submitted for verification at Etherscan.io on 2022-08-27
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

// File: contracts/BeardLottery.sol



pragma solidity ^0.8.7;




// 遊戲方式與規則：
// 1. 可投注號碼 1 ~ 10
// 2. 一次只有一個樂透會啟用
// 3. 若未達到最低標準，進行退費
// 4. 沒中獎，獎金累積到下一期，有中獎則根據當期中獎的投注人數平分

contract BeardAdvLottery is VRFConsumerBaseV2 {

    VRFCoordinatorV2Interface COORDINATOR;

    uint64 s_subscriptionId;
    address vrfCoordinator = 0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D;
    bytes32 keyHash = 0x79d3d8832d904592c0bf9818b621522c988bb8b0c05cdc3b15aea1b6e8db0c15;
    uint32 callbackGasLimit = 200000;
    uint16 requestConfirmations = 3;
    uint32 numWords =  1;

    address private _owner;
    uint256 public _mintBet = 30000 wei; // 30000 wei 單注金額
    uint256 public _minPick = 60000 wei; // 60000 wei 開獎需達成的金額
    uint256 public _expired = 5 minutes;

    uint256 public lotterRound = 0; /* 目前第幾期 */
    uint256 public s_requestId; /* chainlink 的隨機數請求ID */

    mapping(uint256 => LotterData) public lotterys; // 每一期樂透資料
    mapping(uint256 => uint256) public randomRequestIdWithNumbers; // 紀錄 req -> 中獎號碼
    uint256 public potPool = 0; // 滯留彩金
    uint256 public maxBallNum; // 彩球範圍最大數字  1 ~ maxBallNum


    event ChainLinkGeneratorRandom(uint256 _randomNumberFormChainLink, uint256 s_requestId); // event - 紀錄回傳數值 / req_id
    event EntryLottery(uint256 _round, address _sender, uint256 _no, uint256 _amount);

    // 投注表結構 , 1~maxBallNum 任選
    struct LotterData {
        uint256 pot;   // 目前投注總額
        uint256 winnerNumber; // 中獎號碼
        uint256 expired; // 過期時間
        bool isActived; // 是否開放投注
        bool isReward; // 是否已經開獎
        bool isReqRandom; // 是否已經發送隨機數請求
        bool isAlreadyRandom; // 是否產生隨機數

        mapping(uint256 => uint256) betAmountMapping; // 彩球號碼 => 本次投入總組數 （當成是否有人投注此數字 / 計算單位獎金）
        mapping(uint256 => address[]) participants;   // 彩球號碼 => 紀錄投注參與者地址
        mapping(uint256 => mapping(address => uint256)) betAddressAmountMapping ; // 彩球號碼 => 投注參與者地址 => 投注數量

    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "Only Owner.");
        _;
    }

    modifier isActive() {
        LotterData storage currentLottery = lotterys[lotterRound];
        require(currentLottery.isActived, "The Lottery is not Actived."); // 驗證這個樂透是不是 isActive
        require(currentLottery.expired > block.timestamp, "The Lottery is Expired."); // 驗證這個樂透有沒有過期
        _;
    }


    constructor(uint64 subscriptionId, uint8 _maxBallNum) VRFConsumerBaseV2(vrfCoordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        s_subscriptionId = subscriptionId;
        _owner = msg.sender;
        maxBallNum = _maxBallNum; // 設定最大可選擇的數字

        // 預設第0期直接開始可以投注！ 若想要單純管理者控制，備註掉即可
        lotterys[lotterRound].isActived = true; // 啟用活動
        lotterys[lotterRound].expired = block.timestamp + _expired; // 設定過期時間
    }

    // 進行投注
    function entry(uint256 _no, uint256 _betCount) public payable isActive() {
        require( _no >= 1 && _no <= maxBallNum, "Your Lottery Number is out of range" ); // 投注區間錯誤
        require( msg.value == _betCount * _mintBet, "$ is not match!" ); // 投注金額 與 組數不合

        LotterData storage currentLottery = lotterys[lotterRound];
        currentLottery.pot += msg.value; // 總投注加入獎金池
        currentLottery.betAmountMapping[_no] += _betCount; // 紀錄號碼投注數量


        // 合併下注資訊
        if(currentLottery.betAddressAmountMapping[_no][msg.sender] == 0) {
          // 無資料，表示新參與者，加入清單紀錄
          currentLottery.participants[_no].push(msg.sender);
        }
        currentLottery.betAddressAmountMapping[_no][msg.sender] += _betCount; // 增加投注數

        // 投注完成，emit 事件
        emit EntryLottery(lotterRound, msg.sender, _no, _betCount);
    }


    // 啟用新樂透
    function startNewLottery() public onlyOwner {
        if(lotterys[lotterRound].pot == 0 && lotterys[lotterRound].expired < block.timestamp){
          // 如果完全過期，而且沒人投注，可以新建立遊戲
        }else{
          require( lotterys[lotterRound].isReward, "Current Lottery Game is not completed." );
        }

        lotterRound = lotterRound + 1;
        lotterys[lotterRound].isActived = true; // 啟用活動
        lotterys[lotterRound].expired = block.timestamp + _expired; // 設定過期時間
    }


    // 管理員操作 - 開獎作業 : 取得中獎號碼 or 流標退費
    function getWinnerProcess() public onlyOwner {
        LotterData storage currentLottery = lotterys[lotterRound];

        if (currentLottery.pot < _minPick) {

            // 逐筆退費 ... 這數量大就會有問題！ 應該有優化方式，或是...不退延續到下一期
            uint256 refund_uint = _mintBet; // 只退 2/3
            for(uint256 idx = 1; idx <= maxBallNum; idx++){
                for(uint256 pidx = 0; pidx < currentLottery.participants[idx].length; pidx++) {
                    address betAddress = currentLottery.participants[idx][pidx];
                    payable(betAddress).transfer(currentLottery.betAddressAmountMapping[idx][betAddress] * refund_uint); // 退還投注地址 投注數 * 基底金額
                }
            }
        } else {
            // 抵達底標，發出取得中獎號（亂數）請求
            requestRandomWords();
        }
    }

    // 分潤發錢
    function reward() public onlyOwner {
        LotterData storage currentLottery = lotterys[lotterRound];
        require(currentLottery.isAlreadyRandom, "It doesn't get the winnerNumber yet.");
        if(currentLottery.betAmountMapping[currentLottery.winnerNumber] > 0) {
            // 有人中獎，分錢 (把剩餘的錢都放進來分！)
            uint256 rewardUnitPrice =  (currentLottery.pot + potPool) / currentLottery.betAmountMapping[currentLottery.winnerNumber];
            address[] memory rewardAdds = currentLottery.participants[currentLottery.winnerNumber];
            for (uint256 idx=0; idx < rewardAdds.length; idx++){
                //  currentLottery.betAddressAmountMapping[currentLottery.winnerNumber][rewardAdds[idx]] : 下注組數
                payable(rewardAdds[idx]).transfer(currentLottery.betAddressAmountMapping[currentLottery.winnerNumber][rewardAdds[idx]] * rewardUnitPrice);
            }
        } else {
            // 沒人中獎，錢吐到獎金池，等待下次init新的樂透活動
            potPool += currentLottery.pot;
        }

        // 結束，清空資訊並且關閉本次樂透資訊
        currentLottery.pot = 0;
        currentLottery.isReward = true;

    }

    // 像預言機請求隨機數
    function requestRandomWords() private {
        LotterData storage currentLottery = lotterys[lotterRound];
        require(!currentLottery.isReqRandom, "Already request random number!");
        // Will revert if subscription is not set and funded.
        s_requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        ); // Chainlink 請求變數，回傳req_id
        currentLottery.isReqRandom = true; // 設定已經發送請求
    }

    // 預言機callback
    function fulfillRandomWords(uint256, uint256[] memory randomWords) internal override {
        LotterData storage currentLottery = lotterys[lotterRound];
        // 設定進入
        currentLottery.winnerNumber = (randomWords[0] % maxBallNum) + 1;
        currentLottery.isAlreadyRandom = true;

        emit ChainLinkGeneratorRandom(randomWords[0] , s_requestId);
    }

    //*  可查看數字彩球投注數量 與 投注的 address  *//
    /* uint256: _lotterRoundId 期數 */
    /* uint256: _no 彩球編號 */
    function viewParticipantsList(uint256 _lotterRoundId, uint _no) public view returns(uint256, address[] memory) {
        LotterData storage currentLottery = lotterys[_lotterRoundId];
        return (currentLottery.betAmountMapping[_no], currentLottery.participants[_no]);
    }

    //*  可查看使用者的投注數量  *//
    /* uint256: _lotterRoundId 期數 */
    /* uint256: _no 彩球編號   */
    /* address: _addr 投注地址 */
    function viewParticipantsBetUnit(uint256 _lotterRoundId, uint _no, address _addr ) public view returns (uint256) {
        LotterData storage currentLottery = lotterys[_lotterRoundId];
        return currentLottery.betAddressAmountMapping[_no][_addr];
    }
}