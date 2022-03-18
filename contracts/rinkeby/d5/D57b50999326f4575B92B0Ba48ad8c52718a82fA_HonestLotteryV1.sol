// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "AggregatorV3Interface.sol";
import "Ownable.sol";
import "LinkTokenInterface.sol";
import "VRFCoordinatorV2Interface.sol";
import "VRFConsumerBaseV2.sol";

contract HonestLotteryV1 is Ownable,VRFConsumerBaseV2{
  // Chainlink Verifiable Random Function Coordinator.
  VRFCoordinatorV2Interface COORDINATOR;
  //Link token interface for paying for using VRF.
  LinkTokenInterface LINKTOKEN;
  // Number of confirmations (3-200).
  uint16 requestConfirmations = 5;
  //Number of random numbers generated.
  uint32 numWords =  1;
  // Gas limit.
  uint32 callbackGasLimit = 100000;
  // Address of the onlyOwner
  address payable ownerAddress;
  // Fee for using VRF.
  uint256 public fee;
  // The gas lane to use, which specifies the maximum gas price to bump to.
  bytes32 public keyHash;
  // An id of VRF request.
  uint256 public requestId;
  // Id of VRF subsrciption used to generate random values.
  uint64 public subscriptionId;

  // Lottery type, used to properly display all parameters on the website (URL_HERE!!!!!!!!!!!!!!!!!!!!!!!!!!!);
  uint256 public lotteryType = 1;
  // Lottery name.
  string public name;
  // Lottery description.
  string public description;
  // Array of all players.
  address payable[] public players;
  // Winner of the last lottery.
  address payable public recentWinner;
  // Ticket price.
  uint256 public usdEntryFee;
  // Chainlink exchange rate provider.
  AggregatorV3Interface internal ethUsdPriceFeed;
  // Possible lottery states.
  enum LOTTERY_STATE {OPEN,CLOSED,CALCULATING_WINNER}// respectively 0,1,2
  // Lottery state (0/1/2)
  LOTTERY_STATE public lotteryState;

  event RequestedRandomWords(uint256 requestId);

  constructor(
    string memory _name,
    string memory _description,
    address _priceFeedAddress,// Chainlink price feed address on current blockchain.
    address _vrfCoordinator,// Chainlink VRF coordinator address on current blockchain.
    address _link,// Link token node address on current blockchain.
    uint256 _fee,// current fee for using VRF.
    bytes32 _keyhash,
    uint256 _usdEntryFee// Ticket cost specified when creating a lottery.
    )
    VRFConsumerBaseV2(_vrfCoordinator)
  {
    ownerAddress = payable(msg.sender);
    usdEntryFee = _usdEntryFee;
    ethUsdPriceFeed = AggregatorV3Interface(_priceFeedAddress);
    lotteryState = LOTTERY_STATE.CLOSED;
    COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
    LINKTOKEN = LinkTokenInterface(_link);
    fee = _fee;
    keyHash = _keyhash;
    name = _name;
    description = _description;
    // Creates a new subscription to the VRF coordinator.
    createNewSubscription();
  }

  // Function automatically called after previous lottery has ended
  function startLottery() public onlyOwner {
    require(lotteryState == LOTTERY_STATE.CLOSED, "Cant start a new lottery yet!");//Don't start a new lottery if previous one didn't end.
    lotteryState = LOTTERY_STATE.OPEN;
  }

  // Returns ticket price in eth according to chainlink price feed.
  function getEntranceFee() public view returns (uint256){
    (,int256 price,,,)= ethUsdPriceFeed.latestRoundData();
    uint256 adjustedPrice = uint256(price)*1e10; //18 decimals
    uint256 costToEnter = (usdEntryFee *1e18)/adjustedPrice;
    return costToEnter;//Ticket price in ether equal to ticket price in USD per current exchange rate.
  }

  // Returns ticket price in USD
  function getEntranceFeeUsd() public view returns (uint256){
    return usdEntryFee;//Ticket price in USD.
  }

  // Function for users to enter the lotteryState.
  // Transaction must include a ticket price.
  function enter() public payable{
    require(lotteryState == LOTTERY_STATE.OPEN);//only allow to enter if the lottery has started
    require(msg.value >= getEntranceFee(), "Not enough ETH!");
    players.push(payable(msg.sender));
  }

  // Function executed by the website server automatically after
  // a set amount of time has passed.
  // Sends a request for a random number to the
  // Verifiable Rrandom Function corrdinator.
  function endLottery() external onlyOwner {
    lotteryState = LOTTERY_STATE.CALCULATING_WINNER;
    requestId = COORDINATOR.requestRandomWords(
      keyHash,
      subscriptionId,
      requestConfirmations,
      callbackGasLimit,
      numWords
    );
    emit RequestedRandomWords(requestId);
  }

  // Function triggered automaticaly by VRF coordinator after a random number
  // has been generated and confirmed by VRF.
  // The winner is picked based on the generated number and
  // funds are automatically transferred.
  function fulfillRandomWords(
    uint256,/*request_id*/
    uint256[] memory randomWords
  ) internal override {
    require(lotteryState == LOTTERY_STATE.CALCULATING_WINNER,"Lottery in progress!");
    require(randomWords[0] > 0,"Random number not found! Ending lottery failed!");
    uint256 indexOfWinner = randomWords[0] % players.length;
    recentWinner = players[indexOfWinner];
    // Transfer 90% of the pool to the winner
    // (10% goes for the contract and website maintnance).
    recentWinner.transfer((address(this).balance/10)*9);
    ownerAddress.transfer(address(this).balance);
    //Reset the lottery
    players = new address payable[](0);
    lotteryState = LOTTERY_STATE.CLOSED;
  }

  // Create a new subscription when the contract is initially deployed.
  function createNewSubscription() private onlyOwner {
   // Create a subscription with a new subscription ID.
   address[] memory consumers = new address[](1);
   consumers[0] = address(this);
   subscriptionId = COORDINATOR.createSubscription();
   // Add this contract as a consumer of its own subscription.
   COORDINATOR.addConsumer(subscriptionId, consumers[0]);
 }

 // Funds the subscription to pay for the random number generation.
 // Executed by the owner to keep the lottery running and
 // random winners being generated.
 function topUpSubscription(uint256 amount) public onlyOwner {
   LINKTOKEN.transferAndCall(address(COORDINATOR),amount, abi.encode(subscriptionId));
 }

 // Returns the amount of players.
 function getAmountOfPlayers() public view returns(uint256){
   return players.length;
 }

 // Returns the array of all players.
 function getPlayers() public view returns(address payable[] memory){
   return players;
 }

 // Returns address of a player with specified index.
 function getPlayer(uint256 index) public view returns(address payable){
  require(index<players.length,"Index out of range! Call getAmountOfPlayers() first!");
  return players[index];
 }

 // Returns the win pool which is 90% of the contract funds
 // ( 10% goes towards lottery maintnance ).
 function getWinPoolEth() public view returns(uint256){
   return ((address(this).balance/10)*9);//amount in wei
 }

 // Returns the win pool in USD.
 function getWinPoolUsd() public view returns(uint256){
   (,int256 price,,,)= ethUsdPriceFeed.latestRoundData();
   uint256 adjustedPrice = uint256(price)*1e10; //18 decimals
   return ((address(this).balance/10)*9*adjustedPrice)/1e18;
 }

 // Returns the amount of link token left(for the owner to
 // know when to send more link).
 function getLinkBalance() public view returns(uint256){
   return LINKTOKEN.balanceOf(address(this));
 }

 // Returns the amount of link token left in the subscription
 // If too little left then fulfillRandomWords() will not execute
 // and winner will not be chosen until owner funds subscription and
 // calls endLottery() again ).
 // Balance has to be more than 0.01 link for the lottery to conclude successfully.
 function getSubscriptionBalance() public view returns(uint256){
   return LINKTOKEN.balanceOf(address(COORDINATOR));
 }

// Function for the owner refunding excess link tokens.
 function refundLink() public onlyOwner{
   LINKTOKEN.transfer(ownerAddress,LINKTOKEN.balanceOf(address(this)));
 }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);

  function approve(address spender, uint256 value) external returns (bool success);

  function balanceOf(address owner) external view returns (uint256 balance);

  function decimals() external view returns (uint8 decimalPlaces);

  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);

  function increaseApproval(address spender, uint256 subtractedValue) external;

  function name() external view returns (string memory tokenName);

  function symbol() external view returns (string memory tokenSymbol);

  function totalSupply() external view returns (uint256 totalTokensIssued);

  function transfer(address to, uint256 value) external returns (bool success);

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool success);
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