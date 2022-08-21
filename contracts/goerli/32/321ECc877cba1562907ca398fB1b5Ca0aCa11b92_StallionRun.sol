// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";

/// @title A Decentralized Horse Racing Game
/// @author Umair Mirza, John Nguyen
/// @notice This contract is for creating a decentralized horse racing game
/// @dev This contract implements Chainlink VRF and Chainlink Keepers

contract StallionRun is VRFConsumerBaseV2, KeeperCompatibleInterface {

    /* Events */
    event RaceEnter(address indexed player);
    event HorseCreated(uint16 horseId, uint256 price, uint8 level, string name);
    event RequestedRaceWinner(uint256 indexed requestId);
    event RaceCompleted(uint256 indexed raceId, address indexed winner, uint32 winnerSpeed, uint256 raceTime);

    /* Type Declarations */
    enum RaceState {
        OPEN,
        INPROGRESS
    }

    struct Horse {
        uint16 horseId;
        uint256 price;
        uint8 level;
        string name;
    }

    /* State variables */
    address public s_owner;
    address private s_recentWinner;
    address payable[] private s_players;
    uint256 private immutable i_entranceFee;
    uint16 public s_horseId;
    uint256 public s_raceId;
    uint32 private s_speedOfWinner;
    uint256 public s_raceAmount;
    RaceState private s_raceState;
    uint256[] public s_finalRamdom;
    uint256 public s_raceTime;

    Horse[] public horses;

    mapping (address => Horse) playerToHorse;

    /* Chainlink variables */

    VRFCoordinatorV2Interface private immutable i_COORDINATOR;
    // Your subscription ID.
    uint64 private immutable i_subscriptionId;
    // Goerli coordinator. For other networks,
    // see https://docs.chain.link/docs/vrf-contracts/#configurations
    // The gas lane to use, which specifies the maximum gas price to bump to.
    // For a list of available gas lanes on each network,
    // see https://docs.chain.link/docs/vrf-contracts/#configurations
    bytes32 private immutable i_keyHash;
    // Depends on the number of requested values that you want sent to the
    // fulfillRandomWords() function. Storing each word costs about 20,000 gas,
    // so 100,000 is a safe default for this example contract. Test and adjust
    // this limit based on the network that you select, the size of the request,
    // and the processing of the callback request in the fulfillRandomWords()
    // function.
    uint32 private immutable i_callbackGasLimit;
    // The default is 3, but you can set this higher.
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    // For this example, retrieve 2 random values in one request.
    // Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.
    uint32 private numWords;
    uint256[] public s_randomWords;
    //uint256 public s_requestId;


    /* Modifiers */
    modifier onlyOwner {
        require(msg.sender == s_owner, "Function caller is not Owner of the contract");
        _;
    }

    /* Functions */

    /// @notice Constructor takes an entrance fee and Chainlink Subscription ID as arguments
    /// @notice The Race state is set to OPEN in the constructor
    constructor(
        uint256 entranceFee, 
        uint64 subscriptionId,
        address vrfCoordinator,
        bytes32 keyHash,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2(vrfCoordinator) {
        i_COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        i_subscriptionId = subscriptionId;
        i_keyHash = keyHash;
        i_callbackGasLimit = callbackGasLimit;
        i_entranceFee = entranceFee;
        s_raceState = RaceState.OPEN;

        s_owner = msg.sender;
    }

    /// @notice This creates a new horse that can be purchased later
    /// @notice Only owner of the contract is able to create a horse
    /// @notice A horse can be of a different level and higher levels offer a slightly better chance of winning the race
    /// @dev There are two types of horseId variables, one in storage, other in the struct
    /// @dev Storage horseId variable is used to create unique ids for each horse incremented by 1
    function createHorse(string memory _name, uint8 _level, uint256 _price) public onlyOwner {
        s_horseId = s_horseId + 1;
        horses.push(Horse(s_horseId, _price, _level, _name));

        emit HorseCreated(s_horseId, _price, _level, _name);
    }

    /// @notice Players can buy horse at the price set by the owner of the contract
    /// @notice Each player can own only one horse and cannot change their horse afterwards
    /// @dev After successful purchase, it assigns the horse to the playerToHorse mapping
    function buyHorse(uint32 _id) external payable {
        require(horses.length > 0, "No horses exist currently");
        if(playerToHorse[msg.sender].horseId != 0) {
            revert("Player already owns a horse");
        }
        require(msg.value >= horses[_id].price, "Amount is less than Horse Price");

        playerToHorse[msg.sender] = horses[_id];
    }

    /// @notice A player can enter the race by paying the entry fee set in the constructor
    /// @notice A player can only enter the race if he / she owns a horse
    function enterRace() public payable {
        require(playerToHorse[msg.sender].horseId > 0, "Player does not own any horse");
        require(msg.value >= i_entranceFee, "Amount is less than Entrance Fee");
        require(s_raceState == RaceState.OPEN, "Race is not Open");

        s_players.push(payable(msg.sender));

        s_raceAmount = s_raceAmount + msg.value;

        emit RaceEnter(msg.sender);
    }

    /// @dev This is the function that the Chainlink keeper nodes call
    /// @dev They look for 'upkeepNeeded' to return true

    function checkUpkeep(bytes memory /* checkData */) 
    public view override returns(bool upkeepNeeded, bytes memory /* performData */) {

        bool isOpen = s_raceState == RaceState.OPEN;
        bool enoughPlayers = s_players.length == 2;
        bool hasBalance = address(this).balance > 0;

        upkeepNeeded = (isOpen && enoughPlayers && hasBalance);
        // To get rid of the warning
        return (upkeepNeeded, "0x0");
    }

    // Assumes the subscription is funded sufficiently.
    function performUpkeep(bytes calldata /* performData */) external override {
        // Will revert if subscription is not set and funded.

        (bool upkeepNeeded, ) = checkUpkeep("");
        require(upkeepNeeded, "Upkeep not needed");

        s_raceState = RaceState.INPROGRESS;

        numWords = uint32(s_players.length);

        uint256 requestId = i_COORDINATOR.requestRandomWords(
        i_keyHash,
        i_subscriptionId,
        REQUEST_CONFIRMATIONS,
        i_callbackGasLimit,
        numWords
        );

        emit RequestedRaceWinner(requestId);
    }

    /// @notice This function is an override to the virtual function in VRFConsumerBaseV2.sol contract
    /// @notice We assign the randomWords given by the fulfullRandomWords function to the storage array variable

    /// @notice This is where the real magic happens. Race will only start if there are exactly 3 players
    /// @notice Only the owner of the contract can initiate the Race and pick random winner
    /// @notice Number of random words will be equal to the number of players
    /// @notice Horse speed will be determined by the random number generated by Chainlink VRF
    /// @notice Horse speed will be between 50 and 99
    /// @notice With each higher horse level, speed will be incremented by Level * 3
    /// @notice Horse having the highest speed will be chosen as the winner of the race
    /// @notice All the combined entranceFee will be sent to the Winner address
    function fulfillRandomWords(
    uint256, /* requestId */
    uint256[] memory randomWords
    ) internal override {

        s_randomWords = randomWords;

        uint32 speedIncrement = 3;

        uint256 maxSpeed = 0;

        uint32 winnerSpeed;

        uint16 winnerIndex;

        address payable winner;

        for(uint16 i = 0; i < s_players.length; i++) {
            address playerAddress = s_players[i];

            //Generate a Pseudo Random number between 50 and 99

            uint32 randomGen = 50 + uint32(s_randomWords[i] % (99 - 50 + 1));
            s_finalRamdom.push(randomGen);
            uint32 playerSpeed = randomGen + (playerToHorse[playerAddress].level * speedIncrement);

            if(playerSpeed > maxSpeed) {
                maxSpeed = playerSpeed;
                winnerIndex = i;
                winnerSpeed = playerSpeed;
            }
        }

        winner = s_players[winnerIndex];

        s_recentWinner = winner;
        s_speedOfWinner = winnerSpeed;

        s_raceId = s_raceId + 1;

        s_raceTime = block.timestamp;

        s_players = new address payable[](0);
        s_finalRamdom = new uint256[](0);

        s_raceState = RaceState.OPEN;

        //Send the Total Collected Entry fee to the Winner
        (bool success, ) = s_recentWinner.call{value: s_raceAmount}("");
        if(success) {
            s_raceAmount = 0;
        } else {
            revert("Transaction failed");
        }

        emit RaceCompleted(s_raceId, winner, winnerSpeed, s_raceTime);
    }

    /* Getters */

    /// @notice These are getter functions that can be used to gewt values of different state veriables

    function getEntranceFee() public view returns(uint) {
        return i_entranceFee;
    }

    function getRaceState() public view returns(RaceState) {
        return s_raceState;
    }

    function getPlayerHorse(address _player) public view returns(string memory) {
        return playerToHorse[_player].name;
    }

    function getNumPlayers() public view returns(uint) {
        return s_players.length;
    }

    function getPlayerAddress(uint16 index) public view returns(address) {
        return s_players[index];
    }

    function getRaceAmount() public view returns(uint256) {
        return s_raceAmount;
    }

    function getContractBalance() public view returns(uint) {
        return address(this).balance;
    }

    function getRecentWinner() public view returns(address, uint32) {
        return (s_recentWinner, s_speedOfWinner);
    }

    function getWinnerBalance() public view returns(uint) {
        return s_recentWinner.balance;
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