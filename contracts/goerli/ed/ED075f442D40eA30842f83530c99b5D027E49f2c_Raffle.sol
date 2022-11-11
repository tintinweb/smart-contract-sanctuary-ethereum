// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface KeeperCompatibleInterface {
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
}

// SPDX-License-Identifier: MIT
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

//进入彩票（支付一定金额）
//选出一个随机的获胜者(可验证的随机数)，希望这个不会被篡改
//每分钟选出一个获胜者 -> 部署一次，以后完全自动运行
//需要Chainlink预言机来实现->随机性,自动执行(Chainlink Keepers)

//SPDX-License-Identifier:MIT
pragma solidity ^0.8.8;

//导入chainlink的VRF消费者合约
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

//导入vrfCoordinatorV2地址使用的接口合约
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";

//导入checkUpkeep()函数所使用的接口合约
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";

error Raffle__NotEnoughETHEntered();
error Raffle__TransferFailed();
error Raffle__NotOpen();
error Raffle__UpkeepNotNeeded(uint256 currentBalnace, uint256 numPlayers, uint256 raffleState);

/**@title 一个彩票抽奖合约样本
 * @author Loop Love
 * @notice 该合约用于创建不可篡改的去中心化智能合约
 * @dev 该合约实现了 Chainlink VRF V2 和 Chainlink Keepers
 */

contract Raffle is VRFConsumerBaseV2, KeeperCompatibleInterface {
    /* 枚举类型声明 */
    //彩票状态
    enum RaffleState {
        OPEN,
        CALCULATING
    } //当我们创建这样的枚举时,我们其实是在创建这样的常量值规则:uint256 0 = OPEN, 1 = CALCULATING

    /* State Variables */
    uint256 private immutable i_entranceFee; //入场费(不可变)
    address payable[] private s_players; //玩家(玩家获胜我们需要付钱给他们)
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator; //创建接口对象
    bytes32 private immutable i_gasLane; //Gas通道
    uint64 private immutable i_subscriptionId; //订阅id
    uint32 private immutable i_callbackGasLimit; //回调请求Gas费限制
    uint16 private constant REQUEST_CONFIRMATIONS = 3; //区块确认次数
    uint32 private constant NUM_WORDS = 1; //随机数 数量

    //彩票变量
    address private s_recentWinner; //新决出的获胜者
    RaffleState private s_raffleState; //彩票合约状态
    uint256 private s_lastTimeStamp; //上一轮彩票的结束时间
    uint256 private immutable i_interval; //自定义彩票区间(开局定义,永不再变)

    /* Events */
    //函数名称颠倒的事件名称
    event RaffleEnter(address indexed player); //参与的玩家的事件
    event RequestedRaffleWinner(uint256 indexed requestId); //随机数事件
    event WinnerPicked(address indexed winner); //历届获奖名单事件

    /* 函数 */

    //做随机数验证的合同地址也要加入构造函数(模仿的是VRFConsumerBasV2这个合约)
    constructor(
        address vrfCoordinatorV2, //合约地址(这其实是提示我们应该给这个地址部署一些模拟合约，因为我们需要与外部的VRF协调器合约交互)
        uint256 entranceFee,
        bytes32 gasLane,
        uint64 subscriptonId,
        uint32 callbackGasLimit,
        uint256 interval
    ) VRFConsumerBaseV2(vrfCoordinatorV2) {
        i_entranceFee = entranceFee;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2); //初始化构造接口对象,这个合约地址的对象拥有接口的全部功能
        i_gasLane = gasLane;
        i_subscriptionId = subscriptonId;
        i_callbackGasLimit = callbackGasLimit;
        s_raffleState = RaffleState.OPEN;
        s_lastTimeStamp = block.timestamp;
        i_interval = interval;
    }

    //进入彩票
    function enterRaffle() public payable {
        //require (msg.value > i_entranceFee, "Not enough ETH!")
        //下面这种写法比较节省Gas费
        //入场费小于最低金额的话恢复错误
        if (msg.value < i_entranceFee) {
            revert Raffle__NotEnoughETHEntered();
        }
        //彩票不打开的话也是恢复错误
        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle__NotOpen();
        }

        s_players.push(payable(msg.sender)); //加入应付帐款地址作为新的玩家
        //Events
        emit RaffleEnter(msg.sender); //发送参与玩家事件
    }

    /**
     * @dev 这是chainlink keeper节点调用的函数，他们寻找“upkeepNeeded”以返回true
     * 如果upkeepNeeded为true,这意味着是时候获取一个新的随机数了
     * 返回true的条件为:
     * 1.我们的时间间隔已经过去了
     * 2.彩票合约至少有一位参与者,并且有一些ETH在合约账户上
     * 3.我们的订阅由 LINK 资助
     * 4.彩票应处于“打开”状态(需要一些状态变量)
     */
    function checkUpkeep(
        bytes memory /*checkData*/
    )
        public
        override
        returns (
            bool upkeepNeeded,
            bytes memory /* performData(执行数据) */
        )
    {
        //上述四个条件都通过后,该函数返回真,我们将触发Chainlink Keepers去调用performUpkeep()函数
        bool isOpen = (RaffleState.OPEN == s_raffleState); //彩票应处于"打开"状态
        bool timePassed = ((block.timestamp - s_lastTimeStamp) > i_interval); //检查时间间隔;要求 (block.timestamp - last block timestamp) > 区间间隔(在两轮不同彩票运行之间我们想等待多久)
        bool hasPlayers = (s_players.length > 0); //检查我们是否有足够的玩家
        bool hasBalance = address(this).balance > 0; //彩票合约里是否有足够的钱
        upkeepNeeded = (isOpen && timePassed && hasPlayers && hasBalance); //以上所有条件满足后才开始触发调用
    }

    //选出随机的获胜者(这就是我们需要在 Chainlin Keepers 中使用 Chainlink VRF 的地方)
    //以编程的方式自动去选择可验证的获胜者(checkUpkeep)
    //我们要确保该函数只会被触发函数checkUpkeep调用
    function performUpkeep(
        bytes calldata /* performData */
    ) external override {
        (bool upkeepNeeded, ) = checkUpkeep(""); //calldata不适用于字符串
        //if（!a）和if(a==0)等价
        //确保彩票合约真正"打开"
        if (!upkeepNeeded) {
            revert Raffle__UpkeepNotNeeded(
                address(this).balance,
                s_players.length,
                uint256(s_raffleState)
            ); //往此错误中传递一些变量,这样无论谁遇到这个错误,可以清晰地看到为什么他们得到这个错误
        }
        //请求随机数(首先在vrfCoordinatorV2地址上调用这个函数)
        s_raffleState = RaffleState.CALCULATING; //在获得随机数的时候暂时中断彩票合约以便没有人可以进入我们的彩票并且没有人可以触发新的更新
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane, //Gas通道
            i_subscriptionId, //订阅ID(用于资助请求)我们需要订阅id来请求随机数并支付link币来作为预言机的Gas费
            REQUEST_CONFIRMATIONS, //Chainlink节点在响应之前应该等待多少次确认。节点等待的时间越长，随机值就越安全。它必须大于coordinator合约的REQUEST_CONFIRMATIONS
            i_callbackGasLimit, //对合约的fulfillRandomWords() 函数的回调请求使用多少gas 的限制,必须小于callbackGasLimit限制。
            NUM_WORDS //我们想得到多少随机数
        );
        //得到随机数后要做的事
        emit RequestedRaffleWinner(requestId); //发送随机数事件(这个事件的发出是多余的,因为导入的chainlink合约里已经发过一次了)
        //Chainlink VRT是两个交易过程(如果只是一个交易过程人们可以用蛮力尝试模拟调用此事务)
    }

    //重写Chanlink VRF合约中的这个函数
    //Chainlink节点调用此函数,得到获胜者
    function fulfillRandomWords(
        uint256, /*requestId*/
        uint256[] memory randomWords
    ) internal override {
        //我们可以使用Modulo函数从我们的玩家数组中获取一个随机数
        //Modulo函数的原理是什么样子的呢?
        //假设s_player数组的长度大小是10,随机数是202
        // 202 % 10 = 2,我们使用索引2作为胜利者索引

        uint256 indexOfWinner = randomWords[0] % s_players.length; //获得胜利者在玩家数组中的索引
        address payable recentWinner = s_players[indexOfWinner]; //获得胜利者的地址(可验证的随机获胜者)
        s_recentWinner = recentWinner; //把获胜者放入storage中
        s_raffleState = RaffleState.OPEN; //挑选出获胜者之后重新开启新一轮彩票
        s_players = new address payable[](0); //挑选出获胜者后需要重置我们的s_players数组
        s_lastTimeStamp = block.timestamp; //挑选出获胜者后需要重置上一轮彩票的结束时间
        (bool success, ) = recentWinner.call{value: address(this).balance}(""); //把余额里的钱汇给获胜者
        //require(success)
        if (!success) {
            revert Raffle__TransferFailed(); //如果不成功的话我们将恢复一个新的传输失败错误
        }
        emit WinnerPicked(recentWinner); //发送一个事件用来查询历届获奖名单
    }

    /* View/Pure 函数 */
    //其他用户查看入场费
    function getEntranceFee() public view returns (uint256) {
        return i_entranceFee;
    }

    //查看用户
    function getPlayer(uint256 index) public view returns (address) {
        return s_players[index];
    }

    //获取赢家
    function getRecentWinner() public view returns (address) {
        return s_recentWinner;
    }

    //获取彩票状态
    function getRaffleState() public view returns (RaffleState) {
        return s_raffleState;
    }

    //获取随机数 数量
    function getNumWords() public pure returns (uint256) {
        return NUM_WORDS; //常量变量
    }

    //获取玩家的数量
    function getNumberOfPlayers() public view returns (uint256) {
        return s_players.length;
    }

    //获取最新的时间
    function getLatestTimeStamp() public view returns (uint256) {
        return s_lastTimeStamp;
    }

    //获取区块确认次数
    function getRequestConfirmations() public pure returns (uint256) {
        return REQUEST_CONFIRMATIONS;
    }

    //获取自定义彩票区间
    function getInterval() public view returns (uint256) {
        return i_interval;
    }
}