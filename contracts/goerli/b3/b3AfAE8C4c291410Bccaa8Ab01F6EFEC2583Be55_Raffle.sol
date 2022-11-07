// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";

error Raffle__NotEnoughFee();
error Raffle__TransferFailed();
error Raffle__ContractNotOpen();
error Raffle__UpkeepNotNeeded(uint256 currentBalance, uint256 numPlayers, uint256 raffleState);

/** @title 一個簡單的彩票合約
 *  @author kiralee.eth
 *  @notice 這個合約是建立一個不可篡改的去中心化智能合約
 *  @dev 透過導入Chainlink VRF v2 和 Chainlink keepers來完成這個合約
 */

contract Raffle is VRFConsumerBaseV2, KeeperCompatibleInterface {
  //宣告一個新的類型,用來描述合約當下的狀態是open還是計算中
  enum RaffleState {
    OPEN,
    CALCULATING
  }

  /* 狀態變數宣告 */
  uint256 private immutable i_entranceFee;
  address payable[] private s_players;
  //宣告VRFCoordinatorV2Interface合約類型變數i_COORDINATOR
  VRFCoordinatorV2Interface private immutable i_COORDINATOR;
  //以下為宣告requestRandomWords所需要的輸入變數
  bytes32 private immutable i_gasLane; //發出request時最大可支付的Gas
  uint64 private immutable i_subscriptionId; //chainLink訂閱ID
  uint32 private immutable i_callbackGasLimit; //Oracle預言機回傳隨機數時(callback),最大可接受的Gas
  uint16 private constant REQUEST_CONFIRMATIONS = 3; //Oracle預言機獲得隨機數時,需要等待的確認數
  uint32 private constant NUM_WORDS = 1; //一次產生幾個隨機數

  /* 彩票變數宣告 */
  address payable private s_recentWinner;
  RaffleState private s_raffleState; //使用新類型宣告一個變數,用來存放合約當前的狀態,是open還是計算中
  uint256 private s_lastTimeStamp; //上一個區塊時間,宣告此參數用於計算經過了多久
  uint256 private immutable i_interval; //設定時間間隔

  /* 事件宣告 */
  //宣告一個event,輸出一個地址
  event RaffleEnter(address indexed player);
  //宣告一個event,當發出請求獲得requestId時觸發
  event RequestedRaffleWinner(uint256 indexed requestId);
  //宣告一個event,當找出勝利者時觸發
  event WinnerPicked(address indexed winner);

  /* function */
  //在合約部署時決定最小輸入金額
  //在合約部署時,輸入vrfCoordinatorV2地址,塞給VRFConsumerBaseV2合約的constructor
  //因為該合約VRFConsumerBaseV2的初始化部署constructor需要vrfCoordinatorV2地址
  constructor(
    address _vrfCoordinatorV2,
    uint256 _entranceFee,
    bytes32 _gasLane,
    uint64 _subscriptionId,
    uint32 _callbackGasLimit,
    uint256 _interval
  ) VRFConsumerBaseV2(_vrfCoordinatorV2) {
    i_entranceFee = _entranceFee;
    //因為要使用VRFCoordinatorV2Interface合約內的功能,因此將ABI與合約地址做關聯,塞到i_COORDINATOR內
    i_COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinatorV2);
    i_gasLane = _gasLane;
    i_subscriptionId = _subscriptionId;
    i_callbackGasLimit = _callbackGasLimit;
    //s_raffleState = RaffleState(0);
    s_raffleState = RaffleState.OPEN; //這行與上面那行相等
    s_lastTimeStamp = block.timestamp; //初始化,先將s_lastTimeStamp設定為當前的block.timestamp,就有基準能夠比較
    i_interval = _interval; //設定時間間隔
  }

  //入金,紀錄入金帳戶地址到陣列中
  function enterRaffle() public payable {
    if (msg.value < i_entranceFee) {
      revert Raffle__NotEnoughFee();
    }
    //檢查合約是否開啟
    if (s_raffleState != RaffleState.OPEN) {
      revert Raffle__ContractNotOpen();
    }
    s_players.push(payable(msg.sender));
    //觸發event將入金的玩家地址顯示
    emit RaffleEnter(msg.sender);
  }

  //此function是給chainLink keeper node呼叫的,用來檢查條件是否滿足,然後可以執行PerformUpKeep,
  //若此function return為true就會執行PerformUpKeep function
  //perfromData內 可以寫要傳給PerformUpKeep function的變數, 這邊註解起來是因爲現在用不到performData變數
  function checkUpkeep(
    bytes memory /* checkdata */
  )
    public
    override
    returns (
      bool upkeepNeeded,
      bytes memory /* performData */
    )
  {
    //檢查合約是否為開啟狀態
    bool isOpen = (s_raffleState == RaffleState.OPEN);
    //檢查時間是否超過了指定的間隔時間
    bool timePassed = ((block.timestamp - s_lastTimeStamp) > i_interval);
    //檢查玩家是否大於0
    bool hasPlayers = (s_players.length > 0);
    //檢查合約金額是否大於0
    bool hasBalance = (address(this).balance > 0);
    //upkeepNeeded變數不用宣告是因為在returns中已經宣告過了,若前四個變數為true,才為true
    upkeepNeeded = (isOpen && timePassed && hasPlayers && hasBalance);
  }

  function performUpkeep(
    bytes calldata /* performData */
  ) external override {
    //擷取呼叫checkUpkeep function的return值,作為判斷式的條件,而我們沒有使用performData,所以留空,只留下一個逗號
    //且呼叫此function也沒有輸入參數,所以也留空,寫入雙引號
    (bool upkeepNeeded, ) = checkUpkeep("");
    //若upkeepNeeded為false
    if (!upkeepNeeded) {
      //revert 輸出的error帶入以下參數,合約的餘額,s_players陣列長度(參加人數),合約狀態(因為是特別的類型,所以轉換成uint,用index數字代表)
      revert Raffle__UpkeepNotNeeded(address(this).balance, s_players.length, uint256(s_raffleState));
    }

    //在取得隨機數前,先將合約設定為CALCULATING,暫時不允許任何人加入
    s_raffleState = RaffleState.CALCULATING;
    //使用關聯好的i_COORDINATOR,呼叫其中的requestRandomWords function,傳入宣告好的參數,製作request
    uint256 requestId = i_COORDINATOR.requestRandomWords(i_gasLane, i_subscriptionId, REQUEST_CONFIRMATIONS, i_callbackGasLimit, NUM_WORDS);
    //當呼叫requestRandomWords時 回傳取得requestId時 觸發event
    emit RequestedRaffleWinner(requestId);
  }

  //這個fulfillRandomWords宣告為override,會覆蓋掉VRFConsumerBaseV2的fulfillRandomWords的virtual
  //這個function是用來給Oracle預言機呼叫的,用來將隨機數callback給使用者,所以有兩個參數
  //_requestId,randomWords,其中randomWords是一個uint256的陣列,用來存放request回傳而來的隨機數
  //一次請求的隨機數越多該陣列長度就會變大
  function fulfillRandomWords(
    uint256, /*_requestId*/
    uint256[] memory randomWords
  ) internal override {
    //由於我們要使用取得的隨機數,來找出勝利者,且此合約一次的request只有取得一個隨機數
    //因此回傳的隨機數會存在randomWords[0]內,使用隨機數與s_players陣列長度取餘數,就能夠遍歷陣列,找出勝利者
    //將餘數,存在變數內
    uint256 indexOfWinner = randomWords[0] % s_players.length;
    //將餘數當作陣列的index找出當前勝利者的地址
    address payable recentWinner = s_players[indexOfWinner];
    //將勝利者的地址存為全域變數
    s_recentWinner = recentWinner;
    //選出勝利者後將s_players陣列歸0
    s_players = new address payable[](0);
    //將timeStamp重新reset,用來重新計算經過特定時間才選出獲勝者
    s_lastTimeStamp = block.timestamp;
    //選出勝利者後,將合約開啟,允許入金
    s_raffleState = RaffleState.OPEN;
    //將合約所有的資金轉給勝利者,使用function裡面的變數較安全,防止有人偷改全域變數
    (bool success, ) = recentWinner.call{value: address(this).balance}("");
    if (!success) {
      revert Raffle__TransferFailed();
    }
    emit WinnerPicked(recentWinner);
  }

  /* Pure / View function */
  //取得最小入金金額
  function getEntranceFee() public view returns (uint256) {
    return i_entranceFee;
  }

  //取得入金地址
  function getPlayer(uint256 _index) public view returns (address) {
    return s_players[_index];
  }

  //顯示最近獲勝者的地址
  function getRecentWinner() public view returns (address) {
    return s_recentWinner;
  }

  //顯示合約的狀態
  function getRaffleState() public view returns (RaffleState) {
    return s_raffleState;
  }

  //一次選出幾個獲勝者(一次獲得幾個隨機數)
  function getNumWords() public pure returns (uint256) {
    return NUM_WORDS;
  }

  //顯示目前幾個玩家
  function getNumberOfPlayers() public view returns (uint256) {
    return s_players.length;
  }

  //上次的區塊時間
  function getLatestTimeStamp() public view returns (uint256) {
    return s_lastTimeStamp;
  }

  //顯示隨機數需要幾次確認,pure的原因是因為該變數是constant
  function getRequestComfirmations() public pure returns (uint256) {
    return REQUEST_CONFIRMATIONS;
  }

  //中獎機率
  function getWinnerChance() public view returns (uint256) {
    uint256 chance = NUM_WORDS / s_players.length;
    return chance;
  }

  //顯示間隔時間
  function getInterval() public view returns (uint256) {
    return i_interval;
  }

  //顯示gasLane
  function getGasLane() public view returns (bytes32) {
    return i_gasLane;
  }

  function getSubId() public view returns (uint256) {
    return i_subscriptionId;
  }
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
/**
 * @notice This is a deprecated interface. Please use AutomationCompatibleInterface directly.
 */
pragma solidity ^0.8.0;
import {AutomationCompatibleInterface as KeeperCompatibleInterface} from "./AutomationCompatibleInterface.sol";

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AutomationCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}