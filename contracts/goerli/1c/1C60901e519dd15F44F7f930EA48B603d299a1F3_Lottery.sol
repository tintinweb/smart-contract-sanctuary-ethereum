// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Automated} from './Automated.sol';
import {RandomnessConsumer} from './RandomnessConsumer.sol';

/**
 * @title - An open and verifiably random lottery
 * @author - Roman Scher
 */
contract Lottery is RandomnessConsumer, Automated {
    error NotOpen();
    error EntryFeeNotPaid();
    error NotReadyToPickWinner();

    string public constant NAME = 'Lottery';
    bool public isOpen;
    uint public round;
    address[] public players;
    address public lastWinner;
    uint public immutable entranceFee;
    uint public immutable roundInterval;
    uint public lastWinnerPickedAt;

    event PlayerEntered(address indexed players);
    event WinnerRequested(uint indexed requestId);
    event WinnerPicked(address indexed winner);
    event NewRoundStarted(uint indexed round);

    modifier lotteryIsOpen() {
        if (!isOpen) {
            revert NotOpen();
        }
        _;
    }

    modifier entryFeeRequired() {
        if (msg.value < entranceFee) {
            revert EntryFeeNotPaid();
        }
        _;
    }

    modifier readyToPickWinner() {
        if (!checkIfReadyToPickWinner()) {
            revert NotReadyToPickWinner();
        }
        _;
    }

    constructor(
        uint _entranceFee,
        uint _roundInterval,
        address randomnessCoodinatorAddress,
        bytes32 randomnessGasLane,
        uint32 randomnessCallbackGasLimit,
        uint16 randomnessNumberOfRequestConfirmations,
        address automationRegistryAddress,
        address automationRegistrarAddress,
        address linkTokenAddress
    )
        RandomnessConsumer(
            randomnessCoodinatorAddress,
            randomnessGasLane,
            randomnessCallbackGasLimit,
            randomnessNumberOfRequestConfirmations,
            linkTokenAddress
        )
        Automated(
            NAME,
            automationRegistryAddress,
            automationRegistrarAddress,
            linkTokenAddress
        )
    {
        isOpen = true;
        round = 1;
        roundInterval = _roundInterval;
        entranceFee = _entranceFee;
        lastWinnerPickedAt = block.timestamp;

        emit NewRoundStarted(round);
    }

    /**
     * @notice Allows a player to enter the lottery
     */
    function enter() external payable lotteryIsOpen entryFeeRequired {
        players.push(msg.sender);

        emit PlayerEntered(msg.sender);
    }

    /**
     * @notice Chainlink Automation function called periodically to decide when to request a winner
     * @return upkeepNeeded - true if a winner should be requested, false otherwise
     */
    function checkUpkeep(
        bytes calldata /* checkData */
    ) public view returns (bool upkeepNeeded, bytes memory performData) {
        upkeepNeeded = checkIfReadyToPickWinner();
        performData = '';
    }

    /**
     * @notice Chainlink Automation callback that requests a winner
     */
    function performUpkeep(
        bytes calldata /* performData */
    ) external override {
        requestWinner();
    }

    /**
     * @notice Requests a random winner by making an asynchronous call out to Chainlink VRF
     */
    function requestWinner()
        internal
        lotteryIsOpen
        readyToPickWinner
        returns (uint requestId)
    {
        isOpen = false;
        requestId = requestRandomWords();
        emit WinnerRequested(requestId);
    }

    /**
     * @notice Chainlink VRF callback that returns a random value
     */
    function fulfillRandomWords(
        uint, /* requestId */
        uint[] memory randomWords
    ) internal override {
        pickWinner(randomWords[0]);
    }

    /**
     * @notice Picks a random winner and sends them their reward
     */
    function pickWinner(uint randomValue) internal {
        uint indexOfWinner = randomValue % players.length;
        address winner = players[indexOfWinner];
        lastWinner = winner;
        lastWinnerPickedAt = block.timestamp;

        emit WinnerPicked(winner);
        startNewRound();

        (bool success, ) = winner.call{value: address(this).balance}('');
        if (!success) {
            revert('Failed to reward winner');
        }
    }

    /**
     * @notice Checks whether a winner should be requested
     * @dev All the following should be true in order to return true:
     * 1. The lottery is open
     * 2. The round interval has passed
     * 3. The lottery has a balance
     * 4. There is at least one player who has entered
     * 5. Our subscription is funded with LINK
     * @return shouldRequestWinner - true if a winner should be requested, false otherwise
     */
    function checkIfReadyToPickWinner()
        internal
        view
        returns (bool shouldRequestWinner)
    {
        bool roundIntervalHasPassed = block.timestamp - lastWinnerPickedAt >
            roundInterval;
        bool hasBalance = address(this).balance > 0;
        bool hasPlayers = players.length > 0;
        shouldRequestWinner =
            isOpen &&
            roundIntervalHasPassed &&
            hasBalance &&
            hasPlayers;
    }

    function startNewRound() internal {
        players = new address[](0);
        round += 1;
        isOpen = true;

        emit NewRoundStarted(round);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {VRFConsumerBaseV2} from '@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol';
import {VRFCoordinatorV2Interface} from '@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol';
import {LinkTokenInterface} from '@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol';

abstract contract RandomnessConsumer is VRFConsumerBaseV2 {
    VRFCoordinatorV2Interface public immutable randomnessCoordinator;
    uint64 public immutable randomnessSubscriptionId;
    bytes32 private immutable randomnessGasLane;
    uint32 private immutable randomnessCallbackGasLimit;
    uint16 private immutable randomnessNumberOfRequestConfirmations;
    uint32 private constant NUMBER_OF_RANDOM_VALUES_NEEDED = 1;
    LinkTokenInterface private immutable linkToken;

    uint public lastRandomnessRequestId;

    constructor(
        address randomnessCoodinatorAddress,
        bytes32 gasLane,
        uint32 callbackGasLimit,
        uint16 numberOfRequestConfirmations,
        address linkTokenAddress
    ) VRFConsumerBaseV2(randomnessCoodinatorAddress) {
        randomnessCoordinator = VRFCoordinatorV2Interface(
            randomnessCoodinatorAddress
        );
        randomnessSubscriptionId = randomnessCoordinator.createSubscription();
        randomnessCoordinator.addConsumer(
            randomnessSubscriptionId,
            address(this)
        );
        linkToken = LinkTokenInterface(linkTokenAddress);

        randomnessGasLane = gasLane;
        randomnessCallbackGasLimit = callbackGasLimit;
        randomnessNumberOfRequestConfirmations = numberOfRequestConfirmations;
    }

    function randomnessBalance() external view returns (uint96 balance) {
        (balance, , , ) = randomnessCoordinator.getSubscription(
            randomnessSubscriptionId
        );
    }

    function fundRandomness(uint amount) external {
        linkToken.transferFrom(msg.sender, address(this), amount);
        linkToken.transferAndCall(
            address(randomnessCoordinator),
            amount,
            abi.encode(randomnessSubscriptionId)
        );
    }

    function requestRandomWords() internal returns (uint requestId) {
        requestId = randomnessCoordinator.requestRandomWords(
            randomnessGasLane,
            randomnessSubscriptionId,
            randomnessNumberOfRequestConfirmations,
            randomnessCallbackGasLimit,
            NUMBER_OF_RANDOM_VALUES_NEEDED
        );
        lastRandomnessRequestId = requestId;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {AutomationRegistryInterface, State, Config} from '@chainlink/contracts/src/v0.8/interfaces/AutomationRegistryInterface1_2.sol';
import {AutomationCompatibleInterface} from '@chainlink/contracts/src/v0.8/AutomationCompatible.sol';
import {LinkTokenInterface} from '@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol';

interface AutomationRegistrarInterface {
    function register(
        string memory name,
        bytes calldata encryptedEmail,
        address upkeepContract,
        uint32 gasLimit,
        address adminAddress,
        bytes calldata checkData,
        uint96 amount,
        uint8 source,
        address sender
    ) external;
}

abstract contract Automated is AutomationCompatibleInterface {
    string private automationName;
    AutomationRegistryInterface public immutable automationRegistry;
    AutomationRegistrarInterface private immutable automationRegistrar;
    uint public automationUpkeepId;
    LinkTokenInterface private immutable linkToken;

    uint public MINIMUM_INITIAL_AUTOMATION_FUNDING_AMOUNT = 5000000000000000000;

    constructor(
        string memory name,
        address automationRegistryAddress,
        address automationRegistrarAddress,
        address linkTokenAddress
    ) {
        automationRegistry = AutomationRegistryInterface(
            automationRegistryAddress
        );
        automationRegistrar = AutomationRegistrarInterface(
            automationRegistrarAddress
        );
        automationName = name;
        linkToken = LinkTokenInterface(linkTokenAddress);
    }

    function automationBalance() external view returns (uint96 balance) {
        (, , , balance, , , , ) = automationRegistry.getUpkeep(
            automationUpkeepId
        );
    }

    function fundAutomation(uint96 amount) external {
        if (automationUpkeepId == 0) {
            require(
                amount >= MINIMUM_INITIAL_AUTOMATION_FUNDING_AMOUNT,
                'Not enough LINK provided for initial funding'
            );
        }

        linkToken.transferFrom(msg.sender, address(this), amount);

        if (automationUpkeepId != 0) {
            automationRegistry.addFunds(automationUpkeepId, amount);
        } else {
            registerAndFundUpkeep(automationName, amount);
        }
    }

    function registerAndFundUpkeep(string memory name, uint96 amount)
        private
        returns (uint upkeepId)
    {
        (State memory initialRegistryState, , ) = automationRegistry.getState();

        bytes memory payload = abi.encode(
            name,
            '0x', // encryptedEmail
            address(this), // upkeepContract
            200000, // gasLimit
            address(this), // adminAddress
            '0x', // checkData
            amount,
            0, // source
            address(this) // sender
        );

        linkToken.transferAndCall(
            address(automationRegistrar),
            amount,
            bytes.concat(
                AutomationRegistrarInterface.register.selector,
                payload
            )
        );

        (State memory newRegistryState, , ) = automationRegistry.getState();
        if (newRegistryState.nonce == initialRegistryState.nonce + 1) {
            upkeepId = uint(
                keccak256(
                    abi.encodePacked(
                        blockhash(block.number - 1),
                        address(automationRegistry),
                        uint32(initialRegistryState.nonce)
                    )
                )
            );
        } else {
            revert('Automation registry auto-approve disabled');
        }
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

import "./AutomationBase.sol";
import "./interfaces/AutomationCompatibleInterface.sol";

abstract contract AutomationCompatible is AutomationBase, AutomationCompatibleInterface {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @notice config of the registry
 * @dev only used in params and return values
 * @member paymentPremiumPPB payment premium rate oracles receive on top of
 * being reimbursed for gas, measured in parts per billion
 * @member flatFeeMicroLink flat fee paid to oracles for performing upkeeps,
 * priced in MicroLink; can be used in conjunction with or independently of
 * paymentPremiumPPB
 * @member blockCountPerTurn number of blocks each oracle has during their turn to
 * perform upkeep before it will be the next keeper's turn to submit
 * @member checkGasLimit gas limit when checking for upkeep
 * @member stalenessSeconds number of seconds that is allowed for feed data to
 * be stale before switching to the fallback pricing
 * @member gasCeilingMultiplier multiplier to apply to the fast gas feed price
 * when calculating the payment ceiling for keepers
 * @member minUpkeepSpend minimum LINK that an upkeep must spend before cancelling
 * @member maxPerformGas max executeGas allowed for an upkeep on this registry
 * @member fallbackGasPrice gas price used if the gas price feed is stale
 * @member fallbackLinkPrice LINK price used if the LINK price feed is stale
 * @member transcoder address of the transcoder contract
 * @member registrar address of the registrar contract
 */
struct Config {
  uint32 paymentPremiumPPB;
  uint32 flatFeeMicroLink; // min 0.000001 LINK, max 4294 LINK
  uint24 blockCountPerTurn;
  uint32 checkGasLimit;
  uint24 stalenessSeconds;
  uint16 gasCeilingMultiplier;
  uint96 minUpkeepSpend;
  uint32 maxPerformGas;
  uint256 fallbackGasPrice;
  uint256 fallbackLinkPrice;
  address transcoder;
  address registrar;
}

/**
 * @notice state of the registry
 * @dev only used in params and return values
 * @member nonce used for ID generation
 * @member ownerLinkBalance withdrawable balance of LINK by contract owner
 * @member expectedLinkBalance the expected balance of LINK of the registry
 * @member numUpkeeps total number of upkeeps on the registry
 */
struct State {
  uint32 nonce;
  uint96 ownerLinkBalance;
  uint256 expectedLinkBalance;
  uint256 numUpkeeps;
}

interface AutomationRegistryBaseInterface {
  function registerUpkeep(
    address target,
    uint32 gasLimit,
    address admin,
    bytes calldata checkData
  ) external returns (uint256 id);

  function performUpkeep(uint256 id, bytes calldata performData) external returns (bool success);

  function cancelUpkeep(uint256 id) external;

  function addFunds(uint256 id, uint96 amount) external;

  function setUpkeepGasLimit(uint256 id, uint32 gasLimit) external;

  function getUpkeep(uint256 id)
    external
    view
    returns (
      address target,
      uint32 executeGas,
      bytes memory checkData,
      uint96 balance,
      address lastKeeper,
      address admin,
      uint64 maxValidBlocknumber,
      uint96 amountSpent
    );

  function getActiveUpkeepIDs(uint256 startIndex, uint256 maxCount) external view returns (uint256[] memory);

  function getKeeperInfo(address query)
    external
    view
    returns (
      address payee,
      bool active,
      uint96 balance
    );

  function getState()
    external
    view
    returns (
      State memory,
      Config memory,
      address[] memory
    );
}

/**
 * @dev The view methods are not actually marked as view in the implementation
 * but we want them to be easily queried off-chain. Solidity will not compile
 * if we actually inherit from this interface, so we document it here.
 */
interface AutomationRegistryInterface is AutomationRegistryBaseInterface {
  function checkUpkeep(uint256 upkeepId, address from)
    external
    view
    returns (
      bytes memory performData,
      uint256 maxLinkPayment,
      uint256 gasLimit,
      int256 gasWei,
      int256 linkEth
    );
}

interface AutomationRegistryExecutableInterface is AutomationRegistryBaseInterface {
  function checkUpkeep(uint256 upkeepId, address from)
    external
    returns (
      bytes memory performData,
      uint256 maxLinkPayment,
      uint256 gasLimit,
      uint256 adjustedGasWei,
      uint256 linkEth
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AutomationBase {
  error OnlySimulatedBackend();

  /**
   * @notice method that allows it to be simulated via eth_call by checking that
   * the sender is the zero address.
   */
  function preventExecution() internal view {
    if (tx.origin != address(0)) {
      revert OnlySimulatedBackend();
    }
  }

  /**
   * @notice modifier that allows it to be simulated via eth_call by checking
   * that the sender is the zero address.
   */
  modifier cannotExecute() {
    preventExecution();
    _;
  }
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