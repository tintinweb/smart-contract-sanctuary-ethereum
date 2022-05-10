pragma solidity ^0.8.7;
// SPDX-License-Identifier: MIT

// @godmodeinvestor => 0x70B674D9220aC9022420023A8C1034EcfaDc0E3B -> 308399202
// @decentrewardbot => 0x06b911ACca1000823054D9f17424198b076faF86 -> 1518535984320851968

import "../openzeppelin-contracts/contracts/access/Ownable.sol";
import "../openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";


//import "./IDPairing.sol";
// VRF
import "../chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "../chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

contract DRewards is Ownable {
   //inherit VRFConsumerBaseV2
   //VRFCoordinatorV2Interface COORDINATOR;
   address public linkTokenAddress;

   // Your subscription ID.
   uint64 s_subscriptionId;
   // Rinkeby coordinator. For other networks,
   // see https://docs.chain.link/docs/vrf-contracts/#configurations
   address vrfCoordinator = 0x6168499c0cFfCaCD319c818142124B7A15E857ab;
   // The gas lane to use, which specifies the maximum gas price to bump to.
   // For a list of available gas lanes on each network,
   // see https://docs.chain.link/docs/vrf-contracts/#configurations
   bytes32 keyHash = 0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc;
   // Depends on the number of requested values that you want sent to the
   // fulfillRandomWords() function. Storing each word costs about 20,000 gas,
   // so 100,000 is a safe default for this example contract. Test and adjust
   // this limit based on the network that you select, the size of the request,
   // and the processing of the callback request in the fulfillRandomWords()
   // function.
   uint32 callbackGasLimit = 100000;
   // The default is 3, but you can set this higher.
   uint16 requestConfirmations = 3;

   uint256 latestContestID = 1;

   event TransferReceived(address _from, uint _amount);
   event TransferSent(address _from, address _destAddr, uint _amount);

   enum EContestState
   {
       CONTEST_EMPTY,
       CONTEST_CREATED, /* CONTEST ID, REWARDS, CONTEST OWNER */
       CONTEST_CANDICATES_DELIVERED, /* candicates ids delivered */
       CONTEST_RANDOM_REQUESTED, /* RANDOM REQUEST */
       CONTEST_RANDOM_GENERATED, /* RANDOM GENERATED */
       CONTEST_WINNER_LOTTERY_DONE, /* WINNER ANNOUNCED */
       CONTEST_REWARDS_DISTRIBUTED, /* REWARDS DISTRIBUTED */
       CONTEST_END
   }

   // rewards
   struct DReward {
      uint256 contestID;
      address contestOwner;
      uint256 contestWinner;
      uint256 rewardAmount;
      uint256 vrfRequestID;
      uint256 randomSeed;
      EContestState contestState;
      uint256 rewardsDone;
      uint256[] candicatesIDs;
   }

   mapping(uint256 => uint256) contestRandomTable; // requestID -> contest ID

    // userAddress => tokenAddress => token amount
    mapping(address => mapping (address => uint256)) userDeposits;

   // userAdress => eth amount
   mapping(address => uint) userEthDeposits; 

   // userAddress => twitterID
   mapping(address => uint256) addressTwitterID;
   mapping(uint256 => address) twitterIDAdress;

   constructor(address _linkTokenAddress)
   {
       linkTokenAddress = _linkTokenAddress;
   }
   /*constructor(uint64 subscriptionId) VRFConsumerBaseV2(vrfCoordinator) {
      COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
      s_subscriptionId = subscriptionId;
   }*/


    // ERC20 all
    event tokenDepositComplete(address tokenAddress, uint256 amount);
    event tokenWithdrawComplete(address tokenAddress, uint256 amount);
    event updateContestState(uint256 contestID, EContestState state);

   // eth deposit

   event ethDepositComplete(address user, uint amount);

   /* erc20 deposit disabled */
    function approveToken(uint256 amount) public onlyOwner
    {

    }

      /* erc20 deposit disabled */
    function depositToken(uint256 amount) public onlyOwner
    {
        require(IERC20(linkTokenAddress).balanceOf(msg.sender) >= amount, 
            "Your token amount must be greater then you are trying to deposit");

        require(IERC20(linkTokenAddress).approve(address(this), amount));
        require(IERC20(linkTokenAddress).transferFrom(msg.sender, address(this), amount));

        userDeposits[msg.sender][linkTokenAddress] += amount;
        emit tokenDepositComplete(linkTokenAddress, amount);
    }

    function depositEther() public payable returns(uint)
    {
      userEthDeposits[msg.sender] += msg.value;
      emit ethDepositComplete(msg.sender, msg.value);
      return userEthDeposits[msg.sender];
    }

    function depositFakeEther(address user, uint amount) public onlyOwner
    {
      userEthDeposits[user] += amount;
      emit ethDepositComplete(user, amount);
    }

   function getEtherBalanceWithAdress(address user) public view returns(uint)
   {
      return userEthDeposits[user];
   }

   mapping(uint256 => DReward) contest;
   
   event candicatesDelivered(DReward indexed contest);

  function setTwitterID(address userAddress, uint256 twitterID)
   public
   onlyOwner
   {
      require(twitterID > 0);
      addressTwitterID[userAddress] = twitterID;
      twitterIDAdress[twitterID] = userAddress;
   }

   function readTwitterID(address userAddress) public view returns(uint256)
   {
      return addressTwitterID[userAddress];
   }

   function readAddressFromTwitterID(uint256 twitterID) public view returns(address)
   {
      return twitterIDAdress[twitterID];
   }

  function u_createNewContest(uint256 rewardAmount) 
        public 
        onlyEmptyContest(latestContestID)
        {
      require(rewardAmount > 0);
      /*require(userDeposits[msg.sender][linkTokenAddress] <= rewardAmount, 
                "Your reward amount must be greater then you already deposit.");
      */
      require(userEthDeposits[msg.sender] <= rewardAmount, 
         "Your reward amount must be greater then you already deposit.");
      contest[latestContestID].contestOwner = msg.sender;
      contest[latestContestID].contestID = latestContestID;
      contest[latestContestID].rewardAmount += rewardAmount; // sum amount
      contest[latestContestID].contestState = EContestState.CONTEST_CREATED;
      //userDeposits[msg.sender][linkTokenAddress] -= rewardAmount;
      userEthDeposits[msg.sender] -= rewardAmount;
      emit updateContestState(latestContestID, contest[latestContestID].contestState);
      
      latestContestID++;
   }

   function bot_createNewContest(uint256 contestID, address contestOwner, uint256 rewardAmount) 
        public 
        onlyOwner
        onlyEmptyContest(contestID)
        {
      require(rewardAmount > 0);
      require(userEthDeposits[contestOwner] <= rewardAmount, 
         "Your reward amount must be greater then you already deposit.");
      
      contest[contestID].contestOwner = contestOwner;
      contest[contestID].contestID = contestID;
      contest[contestID].rewardAmount += rewardAmount; // sum amount
      contest[contestID].contestState = EContestState.CONTEST_CREATED;
      //userDeposits[contestOwner][linkTokenAddress] -= rewardAmount;
      userEthDeposits[contestOwner] -= rewardAmount;
      latestContestID++;

      emit updateContestState(contestID, contest[contestID].contestState);
   }
   
   function deliverCandicates(uint256 contestID, uint256[] memory candicatesIDs) 
        public onlyOwner
        onlyContestState(contestID, EContestState.CONTEST_CREATED)
    {
      require(contestID > 0);
      require(contest[contestID].rewardAmount > 0);
      require(candicatesIDs.length > 0);
      
      contest[contestID].candicatesIDs = candicatesIDs;
      contest[contestID].contestState = EContestState.CONTEST_CANDICATES_DELIVERED;
      
      emit updateContestState(contestID, contest[contestID].contestState);
   }
   
   function getRewardAmount(uint256 contestID) 
    public 
    view 
    onlyValidContest(contestID) 
    returns(uint256)
   {
      return contest[contestID].rewardAmount;
   }
   
   function getCandicates(uint256 contestID) 
      public 
      view 
      onlyValidContest(contestID) 
      returns(uint256[] memory)
   {
      return contest[contestID].candicatesIDs;
   }
   
   function triggerRewardDistrobution(uint256 contestID) 
      public  
      onlyValidContest(contestID)
      onlyContestState(contestID, EContestState.CONTEST_RANDOM_GENERATED)
   {
      uint256 winnerIndex = contest[contestID].randomSeed % contest[contestID].candicatesIDs.length;
      
      require(winnerIndex <= contest[contestID].candicatesIDs.length - 1);
      
      contest[contestID].contestState = EContestState.CONTEST_WINNER_LOTTERY_DONE;
      contest[contestID].contestWinner = contest[contestID].candicatesIDs[winnerIndex];

      emit updateContestState(contestID, contest[contestID].contestState);
   }
   
   function getWinnerID(uint256 contestID)
    public
    view
    onlyValidContest(contestID)
    onlyContestState(contestID, EContestState.CONTEST_WINNER_LOTTERY_DONE)
    returns(uint256)
    {
        return contest[contestID].contestWinner;
    }
    
    function getWinnerRewardAmount(uint256 contestID)
        public
        view
        onlyValidContest(contestID)
        onlyContestState(contestID, EContestState.CONTEST_WINNER_LOTTERY_DONE)
        returns(uint256)
    {
        return contest[contestID].rewardAmount;
    }

    function withdrawWinnerReward(uint256 contestID, address payable contestWinner)
        public
        onlyOwner
        onlyValidContest(contestID)
        onlyContestState(contestID, EContestState.CONTEST_WINNER_LOTTERY_DONE)
    {
        /*require(IERC20(linkTokenAddress).transfer(contestWinner, contest[contestID].rewardAmount), 
            "transfer failed.");
        */
        contestWinner.transfer(contest[contestID].rewardAmount);
        contest[contestID].contestState = EContestState.CONTEST_END;
        emit updateContestState(contestID, contest[contestID].contestState);
    }

   // VRF
   // Assumes the subscription is funded sufficiently.
   function requestRandomSeed(uint256 contestID) 
    external 
    onlyValidContest(contestID) 
    onlyOwner
    onlyContestState(contestID, EContestState.CONTEST_CANDICATES_DELIVERED)
    { 
      contest[contestID].randomSeed = uint256(keccak256(abi.encodePacked(block.timestamp,block.difficulty, msg.sender)));
      contest[contestID].contestState = EContestState.CONTEST_RANDOM_REQUESTED; /* vrf is not available now. */
      contest[contestID].contestState = EContestState.CONTEST_RANDOM_GENERATED;
      emit updateContestState(contestID, contest[contestID].contestState);
      /* VRF have problems.
      // Will revert if subscription is not set and funded.
      contest[contestID].vrfRequestID = COORDINATOR.requestRandomWords(
         keyHash,
         s_subscriptionId,
         requestConfirmations,
         callbackGasLimit,
         1
      );
      contestRandomTable[contest[contestID].vrfRequestID] = contestID;
      */
   }

   function fulfillRandomWords(
    uint256 requestID, /* requestId */
    uint256[] memory randomWords
   ) internal  
   {
       /* override */
      contest[contestRandomTable[requestID]].randomSeed = randomWords[0];
      contest[contestRandomTable[requestID]].contestState = EContestState.CONTEST_RANDOM_GENERATED;
      emit updateContestState(contestRandomTable[requestID], contest[contestRandomTable[requestID]].contestState);
   }
   
   modifier onlyEmptyContest(uint256 newContestID) {
        require(newContestID > 0);
        require(contest[newContestID].contestOwner > address(0));
        _;
   }

   modifier onlyContestState(uint256 contestID, EContestState state) {
        require(contest[contestID].contestState == state);
        _;
   }
   
    modifier onlyLink(address tokenAddress)
    {
        require(tokenAddress == linkTokenAddress);
        _;
    }
    
   modifier onlyValidContest(uint256 contestID) {
      require(contest[contestID].candicatesIDs.length > 0);
      require(contest[contestID].contestID != 0);
      require(contest[contestID].rewardAmount != 0);
      _;
   }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
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

// SPDX-License-Identifier: MIT
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