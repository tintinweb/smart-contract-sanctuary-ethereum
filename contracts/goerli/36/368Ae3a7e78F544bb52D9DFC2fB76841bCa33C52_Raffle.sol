// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AutomationCompatibleInterface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

/* Errors */
    error Raffle__UpkeepNotNeeded(uint256 currentBalance, uint256 numPlayers, uint8 raffleState);
    error Raffle__TransferToWinnerFailed();
    error Raffle__TransferToSafeFailed();
    error Raffle__SendMoreToEnterRaffle();
    error Raffle__RaffleNotOpen();
    error Raffle__RaffleBankIsFull();
    error Raffle__OnlyOwnerAllowed();
    error Raffle__OnlyAtMaintenanceAllowed(uint8 raffleState);

/**@title A sample Raffle Contract
 * @author Patrick Collins
 * @notice This contract is for creating a sample raffle contract
 * @dev This implements the Chainlink VRF Version 2
 */
contract Raffle is VRFConsumerBaseV2, AutomationCompatibleInterface {
    /* Type declarations */
    enum RaffleState {
        OPEN,
        DRAW_PENDING,    // pending the draw. Use this stage for data sync
        DRAW,            // CALCULATING a winner
        MAINTENANCE      // State to change contract settings, between DRAW and OPEN.
    }
    enum RaffleType {
        UNSUPPORTED,
        AMOUNT,         // If set bank (bank > 0)
        INTERVAL,       // if set interval, (interval > 0)
        SCHEDULE        // If set raffle secret (secret != 0x)
    }

    /* State variables */
    // Chainlink VRF constants
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;
    address payable private constant SAFE_ADDRESS = payable(0xdFa2DE99d854ed13B6dABF354da86315daD8FdE0);

    // Chainlink VRF Variables
    uint64 private immutable i_subscriptionId;
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    uint32 private immutable i_callbackGasLimit;
    uint256 private s_entranceFee;
    uint256 private s_raffleBank;
    uint256 private s_raffleInterval;
    bytes private s_raffleSecret;
    bool private s_autoStart;
    uint8 private s_prizePct;
    uint256 private s_protectionInterval;
    uint256 private s_lastTimeStamp;
    address private s_recentWinner;
    address payable[] private s_players;
    RaffleState private s_raffleState;
    address private immutable i_owner;

    /* Events */
    event RequestedRaffleWinner(uint256 indexed requestId);
    event RaffleEnter(address indexed player, uint256 timestamp, RaffleState raffleState);
    event WinnerPicked(address indexed player, uint256 indexOfWinner, uint256 prize, uint256 ownerIncome);
    event CheckUpkeepCall(address indexed keeper, uint256 timestamp, RaffleState raffleState, bool upkeepNeeded);
    event CronOracleCall(address indexed player);
    event RequestRandomWords(bytes32 gasLane, uint64 subId, uint16 minBlocks, uint32 callbackGasLimit, uint32 numWords);
    event Debug(RaffleState raffleState, uint8 tagId);
    event DebugCheckUpkeep(bool hasPlayers, bool isOpen, bool isDrawPending, bool getTimePassed, bool bankCollected);

    /* Functions */
    constructor(
        uint64 subscriptionId,
        address vrfCoordinatorV2,
        uint32 callbackGasLimit,
        uint256 entranceFee,
        uint256 bank,
        uint256 interval,
        bytes memory secret,
        bool autoStart,
        uint8 prizePct,
        uint256 protectionInterval
    ) VRFConsumerBaseV2(vrfCoordinatorV2) {
        i_subscriptionId = subscriptionId;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        i_callbackGasLimit = callbackGasLimit;
        s_entranceFee = entranceFee;
        s_raffleBank = bank;
        s_raffleInterval = interval;
        s_raffleSecret = secret;
        s_autoStart = autoStart;
        s_prizePct = prizePct;
        s_protectionInterval = protectionInterval;
        i_owner = msg.sender;
        s_lastTimeStamp = block.timestamp;
        s_raffleState = RaffleState.OPEN;
    }

    function enterRaffle() public payable {
        if (msg.value < s_entranceFee) {
            revert Raffle__SendMoreToEnterRaffle();
        }
        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle__RaffleNotOpen();
        }
        s_players.push(payable(msg.sender));

        if (s_raffleBank > 0 && (address(this).balance + s_entranceFee) > s_raffleBank) {
            s_raffleState = RaffleState.DRAW_PENDING;
        }

        emit RaffleEnter(msg.sender, block.timestamp, s_raffleState);
    }

    /**
     * @dev This is the function that the Chainlink Keeper nodes call
     * they look for `upkeepNeeded` to return True.
     * the following should be true for this to return true:
     * 1. The time interval has passed between raffle runs.
     * 2. The lottery is open.
     * 3. The contract has ETH.
     * 4. Implicity, your subscription is funded with LINK.
     */
    function checkUpkeep(
        bytes calldata upkeepData
    )
    public
    override
    returns (
        bool upkeepNeeded,
        bytes memory _upkeepData
    )
    {
        bool isOpen = RaffleState.OPEN == s_raffleState;
        bool isDrawPending = RaffleState.DRAW_PENDING == s_raffleState;
        bool hasPlayers = s_players.length > 0;
        bool timePassed = (s_raffleInterval > 0 && (block.timestamp - s_lastTimeStamp) > s_raffleInterval);
        bool bankCollected = (s_raffleBank > 0 && address(this).balance >= s_raffleBank);
        bool protectionTimeReached = (s_protectionInterval > 0 && (block.timestamp - s_lastTimeStamp) > s_protectionInterval);
        bool requestFromScheduler = false;
        // if protection time passed stop the raffle in any case
        if (protectionTimeReached) {
            upkeepNeeded = false;
            if (hasPlayers) {
                upkeepNeeded = true;
            } else if (s_autoStart) {
                s_raffleState = RaffleState.MAINTENANCE;
            }
        }
        // if we receive call from the scheduled oracle (with secret) we have to start the draw
        else if (s_raffleSecret.length > 0 && upkeepData.length > 0 && keccak256(upkeepData) == keccak256(s_raffleSecret)) {
            emit CronOracleCall(msg.sender);
            requestFromScheduler = true;
            upkeepNeeded = (hasPlayers && (isOpen || isDrawPending) && requestFromScheduler);
        }
        // Call from automation oracle
        else {
            upkeepNeeded = (hasPlayers && (isOpen || isDrawPending) && (timePassed || bankCollected));
        }
        emit DebugCheckUpkeep(hasPlayers, isOpen, isDrawPending, timePassed, bankCollected);

        if (upkeepNeeded) {
            s_raffleState = RaffleState.DRAW_PENDING;
        }
        _upkeepData = upkeepData;
        emit CheckUpkeepCall(msg.sender, block.timestamp, s_raffleState, upkeepNeeded);
    }

    /**
     * @dev Once `checkUpkeep` is returning `true`, this function is called
     * and it kicks off a Chainlink VRF call to get a random winner.
     */
    function performUpkeep(
        bytes calldata upkeepData
    ) external override {
        (bool upkeepNeeded, ) = checkUpkeep(upkeepData);
        if (!upkeepNeeded) {
            revert Raffle__UpkeepNotNeeded(
                address(this).balance,
                s_players.length,
                uint8(s_raffleState)
            );
        }
        s_raffleState = RaffleState.DRAW;
        emit RequestRandomWords(getGasLane(), i_subscriptionId, REQUEST_CONFIRMATIONS, i_callbackGasLimit, NUM_WORDS);
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            getGasLane(),
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );
        // Quiz... is this redundant?
        emit RequestedRaffleWinner(requestId);
    }

    /**
     * @dev This is the function that Chainlink VRF node
     * calls to send the money to the random winner.
     */
    function fulfillRandomWords(
        uint256, /* requestId */
        uint256[] memory randomWords
    ) internal override {
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable recentWinner = s_players[indexOfWinner];
        s_recentWinner = recentWinner;

        uint256 prize =  (address(this).balance * s_prizePct) / 100;
        uint256 ownerIncome = address(this).balance - prize;

        (bool winnerTxSuccess, ) = recentWinner.call{value: prize}("");
        (bool safeTxSuccess, ) = SAFE_ADDRESS.call{value: ownerIncome}("");
        if (winnerTxSuccess && safeTxSuccess) {
            s_players = new address payable[](0);
            if (s_autoStart) {
                s_raffleState = RaffleState.OPEN;
                s_lastTimeStamp = block.timestamp;
            } else {
                s_raffleState = RaffleState.MAINTENANCE;
            }
        } else {
            s_raffleState = RaffleState.MAINTENANCE;
            revert Raffle__TransferToSafeFailed();
        }
        emit WinnerPicked(recentWinner, indexOfWinner, prize, ownerIncome);
    }

    /** Getter Functions */
    function getGasLane() public view returns (bytes32) {
        // https://docs.chain.link/docs/vrf/v2/subscription/supported-networks/
        if (block.chainid == 1) {
            return 0xff8dedfbfa60af186cf3c830acbc32c05aae823045ae5ea7da1e45fbfaba4f92;  // Eth mainnet 500 gwei
        } else if (block.chainid == 5) {
            return 0x79d3d8832d904592c0bf9818b621522c988bb8b0c05cdc3b15aea1b6e8db0c15;  // Goerli 30 gwei
        } else if (block.chainid == 56) {
            return 0xba6e730de88d94a5510ae6613898bfb0c3de5d16e609c5b7da808747125506f7;  // BNB 500 gwei
        } else if (block.chainid == 137) {
            return 0xcc294a196eeeb44da2888d17c0625cc88d70d9760a69d58d853ba6581a9ab0cd;  // Polygon mainnet 500 gwei
        } else {
            return 0x0;
        }
    }

    function getRaffleSafeAddress() public pure returns (address) {
        return SAFE_ADDRESS;
    }

    function getRaffleState() public view returns (RaffleState) {
        return s_raffleState;
    }

    function getNumWords() public pure returns (uint256) {
        return NUM_WORDS;
    }

    function getRequestConfirmations() public pure returns (uint256) {
        return REQUEST_CONFIRMATIONS;
    }

    function getRecentWinner() public view returns (address) {
        return s_recentWinner;
    }

    function getPlayer(uint256 index) public view returns (address) {
        return s_players[index];
    }

    function getLastTimeStamp() public view returns (uint256) {
        return s_lastTimeStamp;
    }

    function getRaffleInterval() public view returns (uint256) {
        return s_raffleInterval;
    }

    function getTimePassed() public view returns (uint256) {
        return block.timestamp - s_lastTimeStamp;
    }

    function getEntranceFee() public view returns (uint256) {
        return s_entranceFee;
    }

    function getNumberOfPlayers() public view returns (uint256) {
        return s_players.length;
    }

    function getRaffleBank() public view returns (uint256) {
        return s_raffleBank;
    }

    function getRaffleOwner() public view returns (address) {
        return i_owner;
    }

    function getAutoStart() public view returns (bool) {
        return s_autoStart;
    }

    function getPrizePct() public view returns (uint8) {
        return s_prizePct;
    }

    function getProtectionInterval() public view returns (uint256) {
        return s_protectionInterval;
    }

    function getRaffleType() public view returns (RaffleType) {
        if (s_raffleBank > 0) {
            return RaffleType.AMOUNT;
        } else if (s_raffleInterval > 0) {
            return RaffleType.INTERVAL;
        } else if (s_raffleSecret.length > 0) {
            return RaffleType.SCHEDULE;
        } else {
            return RaffleType.UNSUPPORTED;
        }
    }

    /** Setter Functions **/
    function setAutoStart(bool autoStart) public onlyOwner {
        s_autoStart = autoStart;
    }

    function setRaffleOpen() public onlyOwner {
        if (s_raffleState == RaffleState.MAINTENANCE) {
            s_raffleState = RaffleState.OPEN;
            s_lastTimeStamp = block.timestamp;
        }
    }

    function setRaffleBank(uint256 bank) public onlyOwner atMaintenance {
        // Will change raffle type to AMOUNT
        s_raffleBank = bank;
        s_raffleInterval = 0;
        s_raffleSecret = "";
    }

    function setRaffleInterval(uint256 interval) public onlyOwner atMaintenance {
        // Will change raffle type to INTERVAL
        s_raffleBank = 0;
        s_raffleInterval = interval;
        s_raffleSecret = "";
    }

    function setRaffleSecret(bytes calldata inputData) public onlyOwner atMaintenance {
        // Will change raffle type to SCHEDULE
        s_raffleBank = 0;
        s_raffleInterval = 0;
        s_raffleSecret = inputData;
    }

    function setPrizePct(uint8 prizePct) public onlyOwner atMaintenance {
        s_prizePct = prizePct;
    }

    function setProtectionInterval(uint256 interval) public onlyOwner atMaintenance {
        s_protectionInterval = interval;
    }

    function setEntranceFee(uint256 fee) public onlyOwner {    // fee in Wei
        s_entranceFee = fee;
    }

    function resetRaffle() public onlyOwner {
        (bool success, ) = SAFE_ADDRESS.call{value: address(this).balance}("");
        if (success) {
            s_players = new address payable[](0);
            s_raffleState = RaffleState.OPEN;
        } else {
            revert Raffle__TransferToSafeFailed();
        }
    }

    /** Modifiers **/
    modifier onlyOwner() {
        if (msg.sender != i_owner) {
            revert Raffle__OnlyOwnerAllowed();
        }
        _;
    }

    modifier atMaintenance() {
        if (s_raffleState != RaffleState.MAINTENANCE) {
            revert Raffle__OnlyAtMaintenanceAllowed(uint8(s_raffleState));
        }
        _;
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