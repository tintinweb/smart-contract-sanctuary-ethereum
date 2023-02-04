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

// 彩票合约
// 玩家向合约内转入一定资金参与活动
// 合约每隔一定时间自动完全随机的选出一位参与者成为赢家,得到合约内的所有资金
// 选出赢家后一轮活动结束,进入下一轮活动
// 实现:从外部使用Chainlink预言机,来得到 完全随机数 和 让合约自动执行(Chainlink Keeper)
// 获得完全随机数参考: https://docs.chain.link/vrf/v2/subscription/examples/get-a-random-number
// 合约自动化参考: https://docs.chain.link/chainlink-automation/compatible-contracts/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// 导入前要先yarn导入包 @chainlink/contracts
// 导入Chainlink VRF
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
// 导入VRFCoordinatorV2Interface接口
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
// 导入自动化合约接口
import "@chainlink/contracts/src/v0.8/interfaces/AutomationCompatibleInterface.sol";

// 继承"@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol",调用其变量及覆盖使用其内部的一些函数,如fulfillRandomWords()
// 继承"@chainlink/contracts/src/v0.8/AutomationCompatible.sol",调用其变量及覆盖使用其内部的一些函数,如checkUpkeep()
contract Raffle is VRFConsumerBaseV2, AutomationCompatibleInterface {
    // 定义枚举类型,表示当前活动状态
    enum RaffleState {
        OPEN, // 开放活动
        CALCULATING // 清算获胜玩家中
    }
    // RaffleState内被字符串化时,"0" == RaffleState.OPEN,"1" == RaffleState.CALCULATING

    // 定义参与活动的金额
    uint256 private immutable i_entranceFee;
    // 定义玩家,并支持合约向该地址转账
    address payable[] private s_players;
    // 定义VRFCoordinatorV2Interface合约接口对象
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;

    // 定义获取随机数,传入requestRandomWords()中的参数
    // 参考: https://docs.chain.link/vrf/v2/subscription/examples/get-a-random-number
    bytes32 private immutable i_gasLane;
    // 订阅ID 和 等待区块确认数 和 最大gas数量限制 和 得到随机数个数 都不需要uint256这么大来存储
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;

    // 关于彩票活动的变量
    address private s_recentWinner; // 当前赢家
    RaffleState private s_raffleState; // 当前活动状态
    uint256 private s_lastTimeStamp; // 记录当前的区块链时间戳
    uint256 private immutable i_interval; // 前后两轮开奖时间间隔(单位:秒)

    // 定义玩家参与活动的金额过少提示错误
    error Raffle__NotEnoughETHEntered();
    // 定义合约向获胜玩家转账失败错误
    error Raffle__TransferFailed();
    // 定义活动未开放提示错误
    error Raffle__NotOpen();
    // 定义自动执行的布尔判断不通过错误,并向错误传入参数:当前合约余额、玩家人数、当前活动状态
    error Raffle__UpkeepNotNeeded(
        uint256 currentBalance,
        uint256 numPlayers,
        uint256 raffleState
    );

    // 事件、日志
    // 在介绍事件前，我们先明确事件，日志这两个概念。事件发生后被记录到区块链上成为了日志。总的来说，事件强调功能，一种行为；日志强调存储，内容。
    // 事件是以太坊EVM虚拟机提供的一种日志基础设施。事件可以用来做操作记录，存储为日志。也可以用来实现一些交互功能，比如通知UI，返回函数调用结果等1。
    // 当定义的事件触发时，我们可以将事件存储到EVM的交易日志中，日志是区块链中的一种特殊数据结构。日志与合约关联，与合约的存储合并存入区块链中。
    // 只要某个区块可以访问，其相关的日志就可以访问。但在合约中，我们不能直接访问日志和事件数据（即便是创建日志的合约）
    // 一个事件中最多存在 3 个 indexed 量,indexed量可以在日志log上具体查看,而非indexed量会被一起打包为一个编码,只有持有合约abi才可以对其解码查看
    // 在合约中定义的事件,可以在js上监听
    // 事件起名一般为函数名掉转一下
    // event关键词,定义事件
    event RaffleEnter(address indexed player); // 确认参与Raffle活动事件
    event RequestedRaffleWinner(uint256 indexed requestId); // 开始确认一轮获胜玩家事件
    event WinnerPicked(address indexed winner); // 确认一轮最终获胜玩家事件

    // 构造函数
    // 传入协调器合约地址vrfCoordinatorV2做随机数验证
    constructor(
        address vrfCoordinatorV2,
        uint256 entranceFee,
        bytes32 gasLane,
        uint64 subscriptionId,
        uint32 callbackGasLimit,
        uint256 interval
    ) VRFConsumerBaseV2(vrfCoordinatorV2) {
        // 通过协调器合约地址vrfCoordinatorV2得到协调器合约
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        // 设置requestRandomWords()传入参数外部接口
        i_entranceFee = entranceFee;
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        // 开启合约时即开启活动
        // 等同于: s_raffleState = RaffleState(0);
        s_raffleState = RaffleState.OPEN;
        // 开启合约时,记录更新当前的区块链时间戳
        s_lastTimeStamp = block.timestamp;
        // 设置开奖时间间隔外部接口
        i_interval = interval;
    }

    // 实现函数,转入一定资金并参与活动
    function enterRaffle() public payable {
        // 不使用require(msg.value > i_entranceFee,"Don't enough ETH")
        // 因为相当于存储了字符串"Don't enough ETH"到storage区,浪费gas
        if (msg.value < i_entranceFee) {
            // 如果发送价值少于规定最低金额,就调出Raffle__NotEnoughETHEntered()错误,并取消转账
            revert Raffle__NotEnoughETHEntered();
        }
        if (s_raffleState != RaffleState.OPEN) {
            // 活动只有在开放期间才能参与
            revert Raffle__NotOpen();
        }
        // 将信息发出的可支付账号地址加入到s_players[]
        s_players.push(payable(msg.sender));
        // emit关键词,触发事件
        emit RaffleEnter(msg.sender);
    }

    // 参考: https://docs.chain.link/chainlink-automation/compatible-contracts/
    // 覆盖"@chainlink/contracts/src/v0.8/AutomationCompatible.sol"中的cheakUpkeep()
    // 实现函数,检查是否自动调用合约函数
    // cheakUpkeep()需要传入参数 (检查数据)cheakData (此处不需要使用,注释起来),
    // 返回参数 (布尔判断是否要自动化执行)upkeepNeeded 和 (执行数据)performData (此处不需要使用,注释起来)
    function checkUpkeep(
        bytes memory /* checkData */
    )
        public
        view
        override
        returns (bool upkeepNeeded, bytes memory /* performData */)
    {
        // 自动化调用生成随机数来确定获胜玩家前提:
        // 1.活动当前处于开放状态
        bool isOpen = (s_raffleState == RaffleState.OPEN);
        // 2.时间间隔足够
        // block.timestamp 具有全区块链时间戳的全局变量
        // 当前时间戳减去上次记录的时间戳要大于设置的时间间隔
        bool timePassd = ((block.timestamp - s_lastTimeStamp) > i_interval);
        // 3.存在玩家和合约账户上存有ETH
        bool hasPlayers = (s_players.length > 0);
        bool hasBalance = (address(this).balance > 0);
        // 4.
        // 前提总结,并作为返回参数
        upkeepNeeded = (isOpen && timePassd && hasPlayers && hasBalance);
        return (upkeepNeeded, "0x0");
    }

    // 实现函数,完全随机挑选出赢家
    // external 要比 public 节约gas
    // checkUpkeep()确定自动调用返回true后,要跑下面这个函数,故将原函数名requestRandomWinner()改为performUpkeep()
    // 覆盖"@chainlink/contracts/src/v0.8/AutomationCompatible.sol"中的performUpkeep()
    // 在checkUpkeep()返回true后,就调用performUpkeep(),开始自动执行
    // 传入参数为checkUpkeep()中返回的执行数据performData (此处不需要使用,注释起来)
    function performUpkeep(bytes calldata /* performData */) external override {
        // 通过调用checkUpkeep(),此处调用时是传入的空字符参数即"",从返回值中得到了upkeepNeeded布尔参数
        (bool upkeepNeeded, ) = checkUpkeep("");
        // 一旦自动调用的布尔判断参数不为true,则取消自动执行,并报出错误
        if (!upkeepNeeded) {
            revert Raffle__UpkeepNotNeeded(
                address(this).balance,
                s_players.length,
                uint256(s_raffleState)
            );
        }

        // 更新活动状态,进入清算获胜玩家环节
        s_raffleState = RaffleState.CALCULATING;

        // 调用vrf协调器合约上的随机数方法requestRandomWords(),返回请求的id requestId ,表示该随机数是第几轮产生的
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane, // 也称为keyHash,设置gas单价1wei价格的最高接受值,超出则取消获得随机数
            i_subscriptionId, // chainlink上调用方法的订阅id,记录id为了支付调用chainlink上的方法后在测试网上收取相应的gas费用
            REQUEST_CONFIRMATIONS, // 设置chainlink上方法调用后等待的区块确认数,通常设置为常数 3 个
            i_callbackGasLimit, // 限制用于向合约的 fulfillRandomWords() 函数的回调请求使用的gas数量,当gas数量超出则停止随机数响应,官方示例给出的值是 100000
            NUM_WORDS // 想要得到的随机数个数,上限是500
        );
        // 触发请求得到Raffle赢家事件
        emit RequestedRaffleWinner(requestId);
        // 其实在requestRandomWords()内就会触发事件 RandomWordsRequested ,且返回参数中包含了requestId
    }

    // fulfillRandomWords()在"@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol"合约文件中已经定义为内部虚函数了
    // 继承VRFConsumerBaseV2后,此处用关键词 override 覆盖原fulfillRandomWords()
    // fulfillRandomWords()需要传入requestId参数,但这次在此函数中不使用requestId,因此注释掉
    // 实现函数,根据随机数,确定赢家并打款
    function fulfillRandomWords(
        uint256 /* requestId */,
        uint256[] memory randomWords
    ) internal override {
        // 通过随机数与玩家数量取余来确定最后的获胜玩家的索引
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        // 获得获胜玩家的账户地址
        address payable recentWinner = s_players[indexOfWinner];
        // 更新获胜玩家的账户地址
        s_recentWinner = recentWinner;
        // 向获胜玩家账户转账,转账金额为当前合约账户内的所有资金
        (bool success, ) = recentWinner.call{value: address(this).balance}("");
        // 比require(success)节约gas
        if (!success) {
            // 提示转账失败错误,并取消转账
            revert Raffle__TransferFailed();
        }
        // 触发确认此轮最终获胜玩家事件
        emit WinnerPicked(recentWinner);

        // 清算完成,更新活动状态
        s_raffleState = RaffleState.OPEN;
        // 重置参与玩家名单
        s_players = new address payable[](0);
        // 重置记录的区块链时间戳
        s_lastTimeStamp = block.timestamp;
    }

    // getter函数,给外部访问接口
    function getEntranceFee() public view returns (uint256) {
        return i_entranceFee;
    }

    function getPlayer(uint256 index) public view returns (address) {
        return s_players[index];
    }

    function getRecentWinner() public view returns (address) {
        return s_recentWinner;
    }

    function getRaffleState() public view returns (RaffleState) {
        return s_raffleState;
    }

    // NUM_WORDS为常数变量,不是从storage区读取的,view可以改为pure,并直接返回常数
    function getNumWords() public pure returns (uint256) {
        return 1;
    }

    function getNumberOfPlayers() public view returns (uint256) {
        return s_players.length;
    }

    function getLatestTimeStamp() public view returns (uint256) {
        return s_lastTimeStamp;
    }

    function getRequestConfirmations() public pure returns (uint256) {
        return REQUEST_CONFIRMATIONS;
    }

    function getInterval() public view returns (uint256) {
        return i_interval;
    }
}