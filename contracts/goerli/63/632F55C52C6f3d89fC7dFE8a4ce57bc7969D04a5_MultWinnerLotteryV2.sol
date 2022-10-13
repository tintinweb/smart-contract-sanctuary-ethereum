/**
 *Submitted for verification at Etherscan.io on 2022-10-13
*/

// File: @openzeppelin/contracts/utils/Counters.sol


// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

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

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: Lottery.sol

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;





/**
    @title This is a lottery realization contract with multiple winners.
    @author Cryptoflu.
 */
contract MultWinnerLotteryV2 is Ownable, VRFConsumerBaseV2 {
    using Counters for Counters.Counter;
    Counters.Counter private currentLotteryId;

    bytes32 internal keyHash; // identifies which chainlink oracle to use
    VRFCoordinatorV2Interface COORDINATOR;
    uint64 s_subscriptionId;
    uint32 callbackGasLimit = 500000;
    uint16 requestConfirmations = 3;

    mapping(uint256 => Lottery) private lotteries;
    mapping(uint256 => mapping(address => bool)) isAddressParticipateInLottery;   // map to check if address participate in lottery by id

    struct Lottery {
        uint256 lotteryId;
        uint256 participantsCount;  // current participants count  
        uint256 currentLot;         // current lottery lot 
        uint256 lotteryStartAt;        // lottery start time
        uint256 lotteryDuration;       // lottery duration time
        uint256 lotteryEntryPrice;     // amount of native currency to participate in lottery
        uint256 lotteryAwardFee;       // fee to get award (percentage) 
        uint256 maxParticipantsCount;  // maximum participants count in lottery
        uint256 winnersCount;          // number of winners in current lottery 
        uint256 lotteryWinnerAward;              // amount of native currency to send to the each winner
        uint256 randomRange;            // range var to selects a number between two values
        LotteryStatus lotteryStatus;                 
        address[] participants;                  // array of participant's addresses
        address[] winners;                       // array of winner's addresses
    }

    enum LotteryStatus {
        INITIALIZED,
        STOPPED,
        COMPLETE,
        AWARDING
    }

    event LotteryAdded(
        uint256 lotteryId,
        uint256 lotteryStartAt,
        uint256 lotteryEntryPrice
    );

    event LotteryCompleted(
        uint256 lotteryId,
        address[] winners
    );

    /**
        Initialize immutable params and params for chainlink vrf.
     */
    constructor(address _vrfCoordinator,
                uint64 subscriptionId,
                bytes32 _keyHash) VRFConsumerBaseV2(_vrfCoordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
        keyHash = _keyHash;
        s_subscriptionId = subscriptionId;
    }

    receive() external payable {}
    
    /**
        @notice Owner can add a new lottery.
     */
    function addLottery(
                uint256 _lotteryDuration, 
                uint256 _lotteryEntryPrice, 
                uint256 _lotteryStartAt, 
                uint256 _lotteryAwardFee,
                uint256 _maxParticipantsCount,
                uint256 _winnersCount) public onlyOwner {
        require(_lotteryAwardFee < 100 && _lotteryEntryPrice > 0 && _lotteryStartAt > block.timestamp 
                    && _lotteryDuration > 0 && _maxParticipantsCount > 0 && _winnersCount < _maxParticipantsCount,
                    "incorrect param(s)");
        if (currentLotteryId.current() > 0){
            Lottery storage prevLottery = lotteries[currentLotteryId.current()];
            require(prevLottery.lotteryStartAt + prevLottery.lotteryDuration < block.timestamp, "previous lottery is active");
            require(prevLottery.winners.length > 0 || prevLottery.lotteryStatus == LotteryStatus.STOPPED, "previous lottery has not winners");
        }
        currentLotteryId.increment();
        Lottery storage lottery = lotteries[currentLotteryId.current()];
        lottery.lotteryId = currentLotteryId.current();
        lottery.lotteryStartAt = _lotteryStartAt;
        lottery.lotteryDuration = _lotteryDuration;
        lottery.lotteryEntryPrice = _lotteryEntryPrice;
        lottery.lotteryAwardFee = _lotteryAwardFee;
        lottery.maxParticipantsCount = _maxParticipantsCount;
        lottery.winnersCount = _winnersCount;

        emit LotteryAdded(currentLotteryId.current(), _lotteryStartAt, _lotteryEntryPrice);
    }

    /**
        @notice Any user can participate in a lottery
    */
    function participate() public payable {
        Lottery storage lottery = lotteries[currentLotteryId.current()];
        require(block.timestamp >= lottery.lotteryStartAt 
                    && block.timestamp < lottery.lotteryStartAt + lottery.lotteryDuration, "lottery not active");
        require(lottery.participantsCount < lottery.maxParticipantsCount, "participants limit");
        require(msg.value == lottery.lotteryEntryPrice, "incorrect funds");
        require(!isAddressParticipateInLottery[currentLotteryId.current()][msg.sender], "multiple participation");
        lottery.participants.push(msg.sender);
        isAddressParticipateInLottery[currentLotteryId.current()][msg.sender] = true;
        lottery.participantsCount++;
        lottery.currentLot += msg.value;
    }

    /**
        @notice Finish the lottery if time is over and required participants count not achieved.
     */
    function finish() public onlyOwner {
        Lottery storage lottery = lotteries[currentLotteryId.current()];
        require(block.timestamp >= lottery.lotteryStartAt + lottery.lotteryDuration, "lottery is active");
        require(lottery.participantsCount <= lottery.winnersCount, "valid participants count");
        lottery.lotteryStatus = LotteryStatus.STOPPED;   
        for(uint256 i = 0; i < lottery.participants.length; i++){
            payable(lottery.participants[i]).transfer(lottery.lotteryEntryPrice);  // return entry price to participants
        }
    }

    function awardWinners() public onlyOwner {
        Lottery storage lottery = lotteries[currentLotteryId.current()];
        require(block.timestamp >= lottery.lotteryStartAt + lottery.lotteryDuration, "lottery is active");
        require(lottery.participantsCount > lottery.winnersCount, "not enough participants");
        require(lottery.lotteryStatus == LotteryStatus.INITIALIZED, "awarding unreachable");
        lottery.lotteryWinnerAward = (100 - lottery.lotteryAwardFee) * lottery.currentLot / 100 / lottery.winnersCount;   // calculate winner award considering the fee
        lottery.randomRange = lottery.participantsCount;
        lottery.lotteryStatus = LotteryStatus.AWARDING;
        getRandomNumbers(uint32(lottery.winnersCount));
    }

    /**
     * Requests randomness
     */
    function getRandomNumbers(uint32 numWords) private returns (uint256  requestId) {
        requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
        return requestId;
    }

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal override {
        for(uint256 i = 0; i < _randomWords.length; i++){
            payToWinner(_randomWords[i]);
        }
        lotteries[currentLotteryId.current()].lotteryStatus = LotteryStatus.COMPLETE;
        emit LotteryCompleted(currentLotteryId.current(), lotteries[currentLotteryId.current()].winners);
    }

    function payToWinner(uint256 randomness) private {
        Lottery storage lottery = lotteries[currentLotteryId.current()];
        require(lottery.lotteryStatus == LotteryStatus.AWARDING, "awarding is not started");
        uint256 randomResult = randomness % lottery.randomRange;
        address winnerAddress = lottery.participants[randomResult];
        lottery.winners.push(winnerAddress);
        deleteElFromArrayByIndex(randomResult, lottery.participants);
        lottery.randomRange--;
        payable(winnerAddress).transfer(lottery.lotteryWinnerAward);
    }

    function deleteElFromArrayByIndex(uint256 index, address[] storage array) private {
        for(uint256 i = index; i < array.length-1; i++){
            array[i] = array[i + 1];      
        }
        array.pop();
    }

    /**
        @notice Withdraw funds from Contract only when lottery is not active.
        @notice Users funds must not be affected.
     */
    function withdrawFund(address _recipient, uint256 _amount) public onlyOwner {
        Lottery storage lottery = lotteries[currentLotteryId.current()];
        require(lottery.winners.length > 0, "lottery is not finished");
        payable(_recipient).transfer(_amount);
    }

    function getBalance() public view onlyOwner returns(uint256){
        return address(this).balance;
    }

    function getLotteryById(uint256 _lotteryId) public view returns(Lottery memory){
        return lotteries[_lotteryId];
    }

    /**
        @notice Get the last lottery. 
     */
    function getLastLottery() public view returns (Lottery memory){
        return lotteries[currentLotteryId.current()];
    }
}