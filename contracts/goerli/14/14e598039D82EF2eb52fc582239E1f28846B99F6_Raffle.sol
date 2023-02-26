/**
 *Submitted for verification at Etherscan.io on 2023-02-26
*/

// File: @chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol


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

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
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

// File: docs.chain.link/Raffle.sol



pragma solidity >=0.8.4 <0.9.0;






contract Raffle is Ownable, ReentrancyGuard, VRFConsumerBaseV2{
    VRFCoordinatorV2Interface public COORDINATOR;
    LinkTokenInterface LINKTOKEN;

    //goerli
    address private constant vrfCoordinator = 0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D;
    address private constant link_token_contract = 0x326C977E6efc84E512bB9C30f76E30c160eD06FB;
    bytes32 private constant keyHash = 0x79d3d8832d904592c0bf9818b621522c988bb8b0c05cdc3b15aea1b6e8db0c15;

    uint32 private constant callbackGasLimit = 100_000;

    uint32 private constant numWords = 1;

    uint16 private constant requestConfirmations = 3;
 
    uint64 public subscriptionId;
    uint public rand;

    struct RequestRandomStatus {
        bool fulfilled; 
        bool exists;
        uint[] randomWords;
        uint raffleId;
        address raffleCreatorAddr;
    
    }
    mapping(uint256 => RequestRandomStatus) private requests;


    enum RAFFLE_STATUS{
        FINISHED,
        CLOSED,
        OPEN
        
    }

    struct RaffleStruct{

        RAFFLE_STATUS raffle_status;

        uint raffleStartTime;

        uint raffleEndTime;

        uint prizeAmount;

        address[] participantsAddrList;

        address winnerAddr;

        mapping(address => bool) participants;
        // mapping(address => prizeAmount) prize;
        
    }

    mapping(address => mapping(uint => RaffleStruct)) public raffles;

    event _createRandom(uint256 indexed requestId);


    constructor (
    ) VRFConsumerBaseV2(vrfCoordinator) {

        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        LINKTOKEN = LinkTokenInterface(link_token_contract);

        createSubscription();

        addConsumer(msg.sender);
    }

    function createSubscription() private{
        subscriptionId = COORDINATOR.createSubscription();
    }

    function createNewSubscription() external onlyOwner{
        createSubscription();
    }

    function getSubscription() external view onlyOwner returns(uint64 subId){
        subId = subscriptionId;
    }
    
    function cancelSubscription(address receivingWallet) external onlyOwner {
        // Cancel the subscription and send the remaining LINK to a wallet address.
        COORDINATOR.cancelSubscription(subscriptionId, receivingWallet);
        subscriptionId = 0;
    }

    function addConsumer(address consumerAddress) private {
        // Add a consumer contract to the subscription.
        COORDINATOR.addConsumer(subscriptionId, consumerAddress);
    }

    function removeConsumer(address consumerAddress) private {
        // Remove a consumer contract from the subscription.
        COORDINATOR.removeConsumer(subscriptionId, consumerAddress);
    }

    function topUpSubscription(uint amount) external onlyOwner {
        //send LINK to the subscription balance.
        LINKTOKEN.transferAndCall(address(COORDINATOR), amount * 10**18, abi.encode(subscriptionId));
    }

    function withdraw(uint amount, address to) external onlyOwner nonReentrant{
        //Transfer this contract's funds to an address.
        LINKTOKEN.transfer(to, amount * 10**18);
    }


    function requestRandomWords() external onlyOwner{
        uint requestId = COORDINATOR.requestRandomWords(
            keyHash,
            subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );

        // requests[requestId] = RequestRandomStatus({
        //     randomWords: new uint[](0),
        //     exists: true,
        //     fulfilled: false,
        //     raffleCreatorAddr: raffleCreatorAddr,
        //     raffleId: raffleId
        // });
    }
    

    function fulfillRandomWords(uint requestId, uint[] memory randomWords) internal override {
        // require(requests[requestId].exists, "Raffle: Request not found");
        require(randomWords[0] > 0, "Raffle: Random not found");
        rand = randomWords[0];
        //remove consumer
        // requests[requestId].fulfilled = true;
        // requests[requestId].randomWords = randomWords;

        // calculatingWinner(requestId);

    }


    function calculatingWinner(uint requestId) private{

        address raffleCreatorAddr = requests[requestId].raffleCreatorAddr;
        uint raffleId = requests[requestId].raffleId;
        uint randomness = requests[requestId].randomWords[0];

        RaffleStruct storage raffle = raffles[raffleCreatorAddr][raffleId];

        uint indexOfWinner = randomness % raffle.participantsAddrList.length;
        raffle.winnerAddr = raffle.participantsAddrList[indexOfWinner];

        removeConsumer(raffleCreatorAddr);
    }
 
 


    function createRaffle(uint deadLineToDay, uint raffleId) external payable{
        
        uint raffleStartTime = block.timestamp;
        uint raffleEndTime = raffleStartTime + (deadLineToDay * 3600 seconds);

        RaffleStruct storage newRaffle = raffles[msg.sender][raffleId];
        newRaffle.raffle_status = RAFFLE_STATUS.OPEN;
        newRaffle.raffleStartTime = raffleStartTime;
        newRaffle.raffleEndTime = raffleEndTime;
        newRaffle.prizeAmount=msg.value;

        addConsumer(msg.sender);
    
    }


    function registerInRaffle(address raffleCreatorAddr, uint raffleId) external addressAllowed(raffleId) notRegistered(raffleCreatorAddr, raffleId) isOpenRaffleStatus(raffleCreatorAddr, raffleId){
        RaffleStruct storage raffle = raffles[raffleCreatorAddr][raffleId];
       
        raffle.participants[msg.sender] = true;
        raffle.participantsAddrList.push(msg.sender);
           
    }

    
    function closeRaffle(address raffleCreatorAddr, uint raffleId) external isClosedRaffleStatus(raffleCreatorAddr, raffleId) onlyOwner onlyRaffleCreator(raffleCreatorAddr, raffleId){

        RaffleStruct storage raffle = raffles[raffleCreatorAddr][raffleId];
        raffle.raffle_status = RAFFLE_STATUS.CLOSED;

        // requestRandomWords(raffleCreatorAddr, raffleId);

    } 

    function claimPrize(address raffleCreatorAddr, uint raffleId) external isClosedRaffleStatus(raffleCreatorAddr, raffleId) onlyWinner(raffleCreatorAddr, raffleId) nonReentrant{
        RaffleStruct storage raffle = raffles[raffleCreatorAddr][raffleId];
        uint prizeAmount = raffle.prizeAmount;

        require(getContractBalance() >= prizeAmount, "Raffle: Not enough balance");

        (bool result, ) = payable(msg.sender).call{value : prizeAmount}("");

        require(result, "Failure to send");
        
        raffle.raffle_status = RAFFLE_STATUS.FINISHED;
    }


    // function getAllRaffles() public onlyOwner view returns (RaffleStruct[] memory) {
    //     RaffleStruct[] memory allRaffles;

    //     for (uint i = 0; i < raffleCreatorAddrs.length; i++) {
    //         allRaffles[i] = raffles[raffleCreatorAddrs[i]];
    //     }
    //     return allRaffles;
    // }

    function getContractBalance() public view onlyOwner returns(uint){
        return address(this).balance / 10**18;
    }

    function increaseContractBalance() external payable {}



    //modifiers
    modifier notRegistered(address raffleCreatorAddr, uint raffleId){
        require(!raffles[raffleCreatorAddr][raffleId].participants[msg.sender], "Raffle: You already participant");
        _;
    }

    modifier onlyWinner(address raffleCreatorAddr, uint raffleId){
        require(raffles[raffleCreatorAddr][raffleId].winnerAddr == msg.sender, "Raffle: You didn't won");
        _;
    }

    modifier onlyRaffleCreator(address raffleCreatorAddr, uint raffleId){
        require(raffles[msg.sender][raffleId].raffle_status == RAFFLE_STATUS.OPEN, "Raffle: Only owner or raffle creator can close raffle!");
        _;
    }

    modifier addressAllowed(uint raffleId){
        require(raffles[msg.sender][raffleId].raffle_status == RAFFLE_STATUS.FINISHED, "Raffle: Raffle creator cannot participate!");
        _;
    }

    modifier isClosedRaffleStatus(address raffleCreatorAddr, uint raffleId){
        require(raffles[raffleCreatorAddr][raffleId].raffle_status == RAFFLE_STATUS.CLOSED || 
        raffles[raffleCreatorAddr][raffleId].raffleEndTime < block.timestamp, "Raffle: The current raffle is open yet!");
        _;
    }

    modifier isOpenRaffleStatus(address raffleCreatorAddr, uint raffleId){
        require(raffles[raffleCreatorAddr][raffleId].raffle_status == RAFFLE_STATUS.OPEN || raffles[raffleCreatorAddr][raffleId].raffleEndTime > block.timestamp, "Raffle: Raffle ended!");
        _;
    }

    
}