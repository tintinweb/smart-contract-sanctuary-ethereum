// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// EtherBetsv2. Here I'm going to implement the following changes:
// Chainlink VRF V2: makes it so much easier to obtain random numbers and has more custom options.
// Use the Fischer-Yates shuffling algorithm to expand the random seed into n random numbers - more gas efficient.
// Let each user claim the prize by himself.

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

contract EtherBetsV2Factory{
    event NewLottery(address lottery);
    address[] public contracts;

    function newEtherBetsV2(string memory _name, uint _betCost, uint8 _maximumNumber, uint8 _picks, uint256 _timeBetweenDraws, uint64 _subscriptionId) public returns (address){
        EtherBetsV2 e = new EtherBetsV2(_name,_betCost, _maximumNumber, _picks, _timeBetweenDraws, _subscriptionId);
        contracts.push(address(e));
        emit NewLottery(address(e));
        return address(e);
    }
}

contract EtherBetsV2 is VRFConsumerBaseV2{
    event NumbersDrawn(uint8[] winningNumbers, uint256 draw);
    event BetPlaced(address indexed sender, uint8 bet, uint256 draw);
    event RandomnessRequested(uint256 draw);
    event RandomnessFulfilled(uint256 randomness, uint256 draw);

    VRFCoordinatorV2Interface COORDINATOR;

    // Your subscription ID.
    uint64 s_subscriptionId;
  
    // Goerli coordinator. For other networks,
    // see https://docs.chain.link/docs/vrf-contracts/#configurations
    address vrfCoordinator = 0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D;
  
    // The gas lane to use, which specifies the maximum gas price to bump to.
    // For a list of available gas lanes on each network,
    // see https://docs.chain.link/docs/vrf-contracts/#configurations
    bytes32 keyHash = 0x79d3d8832d904592c0bf9818b621522c988bb8b0c05cdc3b15aea1b6e8db0c15;
  
    // Depends on the number of requested values that you want sent to the
    // fulfillRandomWords() function. Storing each word costs about 20,000 gas,
    // so 100,000 is a safe default for this example contract. Test and adjust
    // this limit based on the network that you select, the size of the request,
    // and the processing of the callback request in the fulfillRandomWords()
    // function.
    uint32 callbackGasLimit = 500000;
  
    // The default is 3, but you can set this higher.
    uint16 requestConfirmations = 3;
  
    // For this example, retrieve 2 random values in one request.
    // Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.
    uint32 numWords =  1;
  
    uint256[] public s_randomWords;
    uint256 public s_requestId;
    address s_owner;

    /**
     * The name of this lottery instance.
     */
    string public name;
    
    /**
     * The cost in {native token} to place a bet.
     */
    uint256 public betCost;
    
    /**
     * The largest number that can be picked/drawn (up to 255).
     */
    uint8 public maximumNumber;

    /**
     * How many numbers must be picked in a bet. 
     */
    uint8 public picks;

    uint8[] public winningNumbers;
    
    /**
     * A number representing the draw, it is incremented after each draw.
     */
    uint256 public draw;

    /**
     * Maps an address to a draw, which maps to bets.
     * Is used to map an address to all of its bets on a specific draw.
     * Access like this: addressToBets[i][j] to get all of i's bets on the j-th draw,
     * or addressToBets[i][j][k] to get the k-th bet.
     * Note: A bet is a uint256 represented by arrayToUint([bet_numbers]).
    */
    mapping(address => mapping(uint => uint[])) public addressToBets;

    /**
     * Maps a bet to a draw, which maps to a counter.
     * Is used to keep track of how many bets were made
     * with the same number, to share the pool
     * when claiming prizes.
     * Access like this: betCounter[i][j] to get the number of bets i made on the j-th draw.
    */
    mapping(uint => mapping(uint => uint)) public betCounter;

    /**
     * Maps a draw to its accumulated prize.
    */
    mapping(uint => uint) public drawToPrize;

    /**
     * Maps an address to a draw, which maps to whether or not
     * the prize has been claimed.
     * Is used to prevent reentrancy attacks.
    */
    mapping(address => mapping(uint => bool)) public addressToClaim;

    /**
     * Stores the time in seconds of the last draw.
     */
    uint256 public lastDrawTime;

    /**
     * Stores the minimum wait time in seconds between draws.
     */
    uint256 public timeBetweenDraws;

    bool public paused;

    uint256 public randomNumber;

    uint constant decimals = 10 ** 12;

    uint constant fee = 2; // 0.2% fee on bets to pay for VRF.

    uint treasury;

    constructor(string memory _name, uint _betCost, uint8 _maximumNumber, uint8 _picks, uint256 _timeBetweenDraws, uint64 _subscriptionId) VRFConsumerBaseV2(vrfCoordinator){
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        s_owner = msg.sender;
        s_subscriptionId = _subscriptionId;
        name = _name;
        betCost = _betCost;
        maximumNumber = _maximumNumber;
        picks = _picks;
        timeBetweenDraws = _timeBetweenDraws;
        lastDrawTime = block.timestamp;
    }

    function getDetails() public view returns (string memory, uint, uint8, uint8, uint, uint, bool, uint, uint, uint8[] memory, uint256){
        return (name, betCost, maximumNumber, picks, timeBetweenDraws, lastDrawTime, paused, draw, drawToPrize[draw], winningNumbers, randomNumber);
    }
 
    /**
     * Checks if an array input matches the requirements of this contract.
     */
    function checkRequirements(uint8[] memory arr) public view{
        require(inAcceptableRange(arr), "Numbers must be larger than 0 and less than or equal to maximumNumber.");
        require(arr.length == picks, "Numbers must match expected length.");
    }
    /**
     * Checks if the numbers in the array are in the acceptable range.
     */
    function inAcceptableRange(uint8[] memory arr) public view returns (bool){
        for(uint8 i = 0; i < arr.length; i++){
            if(arr[i] == 0 || arr[i] > maximumNumber){
                return false;
            }
        }
        return true;
    }

    /**
     * Expands the random seed into n unique pseudorandom
     * numbers from 1 to m, using the Fischer Yates schuffle.
     * Conditions: m > n.
     */
    function expand(uint256 seed, uint8 n, uint8 m) public pure returns (uint8[] memory){
        uint8[] memory arr = new uint8[](m);
        for(uint8 i = 0; i < m; i++){
            arr[i] = i + 1;
        }

        uint8 last = m - 1;
        uint8[] memory nums = new uint8[](n);
        for(uint i = 0; i < n; i++){
            uint8 roll = uint8(uint256(keccak256(abi.encode(seed, i))) % (m - i));
            nums[i] = arr[roll];
            arr[roll] = arr[last];
            last--; // will break (underflow) if m == n
        }
        return nums;
    }

    /**
     * Receives a uint8 array, returns a uint256 unique to the number of that array.
     * Example: arr = [1, 2, 3] -> number = 0b000...111
     *          arr = [255, 1, 2] -> number = 0b100...011
     * Input numbers must be between 1 and 255.
     */
    function arrayToUint(uint8[] memory arr) public pure returns (uint){
        uint number = 0;
        for(uint8 i = 0; i < arr.length; i++){
            number |= (1 << (arr[i] - 1));
        }
        return number;
    }

    function beginDraw() public{
        require(block.timestamp - lastDrawTime > timeBetweenDraws, "You must wait longer before another draw is available.");
        require(paused == false, "A draw is already happening");
        paused = true; // pause bets to wait for the result.
        requestRandomWords();
        emit RandomnessRequested(draw);
    }

    function placeBet(uint8 bet) public payable{
        require(msg.value == betCost, "msg.value does not match betCost");
        require(paused == false, "Bets are paused to draw the numbers.");
        //checkRequirements(numbers);
        //uint bet = arrayToUint(numbers);
        addressToBets[msg.sender][draw].push(bet);
        betCounter[bet][draw]++;
        drawToPrize[draw] += (betCost * (1000 - fee)) / 1000;
        treasury += (betCost * fee) / 1000;
        emit BetPlaced(msg.sender, bet, draw);
    }

    function claimPrize(uint256 _draw) public{
        require(draw > _draw, "Specified draw hasn't occurred yet.");
        require(addressToClaim[msg.sender][_draw] == false, "Address has already claimed a prize.");

        addressToClaim[msg.sender][_draw] == true;
        uint prize = claimablePrize(msg.sender, _draw);
        require(prize > 0, "You did not win any prize.");

        (bool sent,) = payable(msg.sender).call{value: prize}("");
        require(sent, "Failed to send Ether.");
    }

    function claimablePrize(address user, uint256 _draw) public view returns (uint){
        if(draw <= _draw){
           return 0;
        }

        uint winningBet = arrayToUint(winningNumbers);
        uint totalWinningTickets = betCounter[winningBet][_draw];
        if(totalWinningTickets == 0){
            return 0;
        }

        uint userBetCount = addressToBets[user][_draw].length;
        uint wins = 0;

        for(uint i = 0; i < userBetCount; i++){
            if(addressToBets[user][_draw][i] == winningBet){
                wins++;
            }
        }
        
        uint prizeShare = (wins * decimals) / totalWinningTickets;
        return (prizeShare * drawToPrize[_draw]) / decimals;
    }

      // Assumes the subscription is funded sufficiently.
    function requestRandomWords() internal onlyOwner {
        // Will revert if subscription is not set and funded.
        s_requestId = COORDINATOR.requestRandomWords(
        keyHash,
        s_subscriptionId,
        requestConfirmations,
        callbackGasLimit,
        numWords
        );
    }

    function fulfillRandomWords(
        uint256, /* requestId */
        uint256[] memory randomWords
    ) internal override {
        randomNumber = randomWords[0];
        winningNumbers = expand(randomWords[0], picks, maximumNumber);
        emit NumbersDrawn(winningNumbers, draw);
        lastDrawTime = block.timestamp;
        
        if (betCounter[arrayToUint(winningNumbers)][draw] == 0){
            drawToPrize[draw + 1] = drawToPrize[draw];
        }
        else{
            drawToPrize[draw + 1] = 0;
        }
        draw++;
        paused = false;
    }

    function withdrawTreasury() external payable onlyOwner{
        treasury = 0;
        (bool sent,) = payable(msg.sender).call{value: treasury}("");
        require(sent);
    }

    modifier onlyOwner() {
        require(msg.sender == s_owner);
        _;
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