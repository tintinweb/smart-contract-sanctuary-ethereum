// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

/**
 * @title Clover
 * @author Milad Green @5r33n
 *
 * This contract receives predetermined amounts of ETH, matches those that are the same,
 * flips a coin (VRF) between this pair, and finally the winner gets his share back, plus
 * the loser's.
 * 0.1x of the winning amount is deposited to the owner (deployer) as profit.
 * @dev We use Chainlink's VRF <https://vrf.chain.link> to get those random numbers.
 */

import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";

/* Errors */
error Clover__InvalidChoice();
error Clover__WinnerTransferFailed();
error Clover__InvalidFee();
error Clover__InterestTransferFailed();
error Clover__WithdrawFailed();
error Clover__EmptyBalance();

contract Clover is VRFConsumerBaseV2 {
    /* State Variables */
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subId;
    uint32 private immutable i_callbackGasLimit;
    address private immutable i_deployer;
    address private s_recentWinner;
    uint256 private immutable i_minimumFee;
    uint256 private s_coinFlip;
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;

    /* Enums */
    enum choice {
        HEADS,
        TAILS
    }
    enum step {
        ONE,
        TWO,
        THREE,
        FOUR,
        FIVE,
        SIX,
        SEVEN
    }

    /* Maps */
    mapping(uint256 => address) headsPlayers;
    mapping(uint256 => address) tailsPlayers;
    mapping(address => choice) choiceMap;
    mapping(address => uint256) playerToAmount;
    mapping(step => address) stepToPlayer;

    /* Events */
    event CloverPlayer(address indexed player);
    event RequestedRandNum(uint256 indexed requestId);
    event WinnerPicked(address indexed winner);
    event StepNotEmpty(address occupyingPlayer);
    event StepEmpty();

    /* Functions */
    constructor(
        uint256 _minimumFee,
        address _vrfCoordinatorV2,
        bytes32 _gasLane,
        uint64 _subId,
        uint32 _callbackGasLimit
    ) VRFConsumerBaseV2(_vrfCoordinatorV2) {
        i_minimumFee = _minimumFee;
        i_vrfCoordinator = VRFCoordinatorV2Interface(_vrfCoordinatorV2);
        i_gasLane = _gasLane;
        i_subId = _subId;
        i_callbackGasLimit = _callbackGasLimit;
        i_deployer = msg.sender;
    }

    function enterClover() public payable {
        if (msg.value < i_minimumFee) {
            revert Clover__InvalidFee();
        }
        playerToAmount[msg.sender] = msg.value;
        if (msg.value == i_minimumFee) {
            // 0.1 ETH
            findMatch(msg.sender, step.ONE);
        } else if (msg.value == 200000000000000000) {
            // 0.2 ETH
            findMatch(msg.sender, step.TWO);
        } else if (msg.value == 500000000000000000) {
            // 0.5 ETH
            findMatch(msg.sender, step.THREE);
        } else if (msg.value == 1000000000000000000) {
            // 1.0 ETH
            findMatch(msg.sender, step.FOUR);
        } else if (msg.value == 5000000000000000000) {
            // 5.0 ETH
            findMatch(msg.sender, step.FIVE);
        } else if (msg.value == 10000000000000000000) {
            // 10.0 ETH
            findMatch(msg.sender, step.SIX);
        } else if (msg.value == 100000000000000000000) {
            // 100.0 ETH
            findMatch(msg.sender, step.SEVEN);
        } else {
            playerToAmount[msg.sender] = 0;
            revert Clover__InvalidFee();
        }
        emit CloverPlayer(msg.sender);
    }

    /**
     * @dev Gets players 1 and 2, and the flip result. The winner gets 1.9x of
     * @dev what he had entered. The 0.1x is transferred to the developer as
     * @dev profit.
     *
     * @param headsPlayer the heads player
     * @param tailsPlayer the tails player
     * @param flipResult the result of the coin flip in fulfillRandomWords
     *
     * It emits WinnerPicked
     * It reverts if transfer doesn't take place correctly.
     */
    function rewardWinner(
        address payable headsPlayer,
        address payable tailsPlayer,
        choice flipResult
    ) public returns (bool) {
        address payable winner;
        address payable loser;
        uint256 deposit = getPlayerToAmount(headsPlayer);
        uint256 interest = deposit / 10;
        uint256 award = deposit * 2 - interest;

        if (flipResult == choice.HEADS) {
            winner = headsPlayer;
            loser = tailsPlayer;
        } else if (flipResult == choice.TAILS) {
            winner = tailsPlayer;
            loser = headsPlayer;
        } else {
            revert Clover__InvalidChoice();
        }
        (bool success, ) = winner.call{value: award}("");
        if (!success) {
            revert Clover__WinnerTransferFailed();
        }
        (bool deployerSuccess, ) = i_deployer.call{value: interest}("");
        if (!deployerSuccess) {
            revert Clover__InterestTransferFailed();
        }
        playerToAmount[winner] = 0;
        playerToAmount[loser] = 0;
        s_recentWinner = winner;
        emit WinnerPicked(winner);
        return true;
    }

    function findMatch(address _player, step _step) public {
        if (stepToPlayer[_step] == address(0)) {
            stepToPlayer[_step] = _player;
        } else {
            address playerInQueue = stepToPlayer[_step];
            stepToPlayer[_step] = address(0);
            requestRand();
            choice coinFlip = getCoinFlip();
            rewardWinner(payable(playerInQueue), payable(_player), coinFlip);
        }
    }

    /**
     * @dev Picking a random number with VRFCoordinator:
     * @dev Step 1: Request
     * @dev Step 2: Fulfill
     */

    // Step 1: Request
    function requestRand() public {
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane,
            i_subId,
            3,
            i_callbackGasLimit,
            1
        );
        emit RequestedRandNum(requestId);
    }

    // Step 2: Fulfill
    function fulfillRandomWords(
        uint256, /*requestId*/
        uint256[] memory randomWords
    ) internal override {
        s_coinFlip = randomWords[0] % 2;
    }

    function withdraw() external returns (bool) {
        uint256 balance = playerToAmount[msg.sender];
        if (balance == 0) {
            revert Clover__EmptyBalance();
        }
        (bool success, ) = payable(msg.sender).call{value: balance}("");
        if (!success) {
            revert Clover__WithdrawFailed();
        }
        if (balance == i_minimumFee) {
            stepToPlayer[step.ONE] = address(0);
        } else if (balance == 200000000000000000) {
            stepToPlayer[step.TWO] = address(0);
        } else if (balance == 500000000000000000) {
            stepToPlayer[step.THREE] = address(0);
        } else if (balance == 1000000000000000000) {
            stepToPlayer[step.FOUR] = address(0);
        } else if (balance == 5000000000000000000) {
            stepToPlayer[step.FIVE] = address(0);
        } else if (balance == 10000000000000000000) {
            stepToPlayer[step.SIX] = address(0);
        } else if (balance == 100000000000000000000) {
            stepToPlayer[step.SEVEN] = address(0);
        }
        playerToAmount[msg.sender] = 0;
        return true;
    }

    /* View/Pure Functions */
    function getMinimumFee() public view returns (uint256) {
        return i_minimumFee;
    }

    function getPlayerToAmount(address _address) public view returns (uint256) {
        return playerToAmount[_address];
    }

    function getStepToPlayer(step _step) public view returns (address) {
        return stepToPlayer[_step];
    }

    function getCoinFlip() public view returns (choice) {
        if (s_coinFlip == 0) return choice.HEADS;
        else return choice.TAILS;
    }

    function getRecentWinner() public view returns (address) {
        return s_recentWinner;
    }

    function getPlayerBalance() public view returns (uint256) {
        return msg.sender.balance;
    }

    receive() external payable {
        enterClover();
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
}