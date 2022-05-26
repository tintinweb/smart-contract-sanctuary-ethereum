/**
 *Submitted for verification at Etherscan.io on 2022-05-26
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

// File: contracts/finalproject/final_project2.sol


pragma solidity ^0.8.7;



contract VRFv2Consumer is VRFConsumerBaseV2 {
    VRFCoordinatorV2Interface COORDINATOR;

    uint64 s_subscriptionId;

    // Rinkeby coordinator. For other networks,
    address vrfCoordinator = 0x6168499c0cFfCaCD319c818142124B7A15E857ab;
    bytes32 keyHash = 0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc;
    uint32 callbackGasLimit = 100000;

    uint16 requestConfirmations = 3;

    uint32 numWords =  1;

    bool public seedGenerated;
    uint256 internal randomseed;
    uint256 s_requestId;
    address generator;

    enum _genstate {
        generating,
        pause
    }
    _genstate genstate;

    constructor(uint64 subscriptionId) VRFConsumerBaseV2(vrfCoordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        s_subscriptionId = subscriptionId;
        genstate = _genstate.pause;
    }

    event randomGenerated(address executor, uint blocknum);

    // Assumes the subscription is funded sufficiently.
    function requestRandomWords() internal {
        // Will revert if subscription is not set and funded.
        s_requestId = COORDINATOR.requestRandomWords(
        keyHash,
        s_subscriptionId,
        requestConfirmations,
        callbackGasLimit,
        numWords
        );
        genstate = _genstate.generating;
        generator = msg.sender;
    }
    
    function fulfillRandomWords(
        uint256, /* requestId */
        uint256[] memory randomWords
    ) internal override {
        randomseed = randomWords[0];
        seedGenerated = true;
        genstate = _genstate.pause;
        emit randomGenerated(generator, block.number);
    }

}


contract Lottery is VRFv2Consumer {

    address [] public drawlist;
    address payable public recentWinner;
    address payable public donationaddr;
    address public owner;

    mapping(address => uint256) public donationfund;

    uint256 public entranceFee;       // Current entrance fee
    uint256 public currentPrize;      // Current prize pool

    uint256 public totalLottery;      // previous total lotteries
    uint256 public totalPrize;        // previous total lottery prize
    uint256 public totalEntries;      // previous total lottery participant

    // Lottery State
    enum state{
        ongoing,
        drawing,
        pause
    }
    state lotterystate;

    // Lottery History
    struct _history{
        uint256 entries;
        address winner;
        uint256 prize;
    }
    _history[] history;

    event withdrawLog (address to, uint256 value);
    event entrylog(address addrm, uint256 value);

    constructor(uint64 subscriptionId) VRFv2Consumer(subscriptionId){
        owner = msg.sender;
        lotterystate = state.pause;
    }

    // onlyOwner Modifier
    modifier onlyOwner {
        require(owner == msg.sender, "This function can only be used by owner");
        _;
    }


    // transfer owner function
    function transfer(address to) public onlyOwner {
        owner = to;
    }

    // enter function
        // Check if there is ongoing lottery
        // Check if entrance fee is valid
        // Add sender to drawlist array
        // Add fund to donation and prize pool

    function enterLottery() public payable {
        require(lotterystate == state.ongoing, "No ongoing lottery");
        require(msg.value == entranceFee, "Invalid entrance fee");
        emit entrylog(msg.sender, msg.value);
        drawlist.push(msg.sender);
        currentPrize += msg.value / 10 * 9;
        donationfund[donationaddr] += msg.value / 10;
    }

    // startLottery function (Only owner can execute)
        // Check if no lottery is ongoing
        // Set entraceFee
        // Set donation address
        // Set state to ONGOING

    function startLottery(address payable donateaddr, uint256 fee) public onlyOwner{
        require(lotterystate == state.pause, "Lottery ongoing");
        entranceFee = fee;
        donationaddr = donateaddr;
        lotterystate = state.ongoing;
    }

    // endlottery function
        // Set state to DRAWING
        // Check if any player entered
        // Generate random winner
        // Add lottery info to total records
        // Add lottery info to history
        // Send prize to winner
        // Initialize data 
        // Set state to PAUSE

    function endLottery() public onlyOwner {
        lotterystate = state.drawing;
        require(seedGenerated, "Random seed not generated");
        require(drawlist.length != 0, "No player entered");
        uint256 indexOfWinner = 
            uint256(keccak256(abi.encodePacked(msg.sender, block.difficulty, block.timestamp, randomseed))) % drawlist.length;

        totalLottery += 1;
        totalPrize += currentPrize;
        totalEntries += drawlist.length;

        _history memory lot;
        lot.entries = drawlist.length;
        lot.winner = drawlist[indexOfWinner];
        lot.prize = address(this).balance / 10 * 9;

        history.push(lot);

        recentWinner = payable(drawlist[indexOfWinner]);
        (bool sent, ) = recentWinner.call{value: currentPrize}("");
        require(sent, "send failed");

        delete drawlist;
        currentPrize = 0;
        lotterystate = state.pause;
    }

    // withdrawDonation Function
        // Check if there's fund to withdraw
        // Send fund to target
        // Set donation fund to 0

    function withdrawDonation() public {
        require(donationfund[msg.sender] != 0, "No fund to be withdraw.");
        emit withdrawLog(msg.sender, donationfund[msg.sender]);
        (bool sent, ) = payable(msg.sender).call{value: donationfund[msg.sender]}("");
        require(sent, "send failed");
        donationfund[msg.sender] = 0;
    }

    // getLotteryHistory Function

    function getLotteryHistory(uint256 index) public view 
        returns (uint256 participants, address winner, uint256 prize)
    {
        participants = history[index].entries;
        winner = history[index].winner;
        prize = history[index].prize;
    }

    function getEntries(address addr) public view returns (uint256 entries) {
        for(uint256 i=0; i<drawlist.length; i++){
            if(addr == drawlist[i]){
                entries++;
            }
        }
    }

    function generateRandom() public onlyOwner {
        require(genstate == _genstate.pause, "Generating random...");
        requestRandomWords();
    }

}