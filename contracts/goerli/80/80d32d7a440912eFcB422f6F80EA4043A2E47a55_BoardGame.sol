// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

contract BoardGame is VRFConsumerBaseV2 {
    struct Profile {
        uint32 fieldPosition;
        uint32 happiness;
        uint32 speed;
        uint32 wealth;
        bool isYourTurnInProgress;
        string name;
    }

    VRFCoordinatorV2Interface internal immutable i_vrfCoordinator;
    uint64 internal immutable i_subscriptionId;
    bytes32 internal immutable i_keyHash;
    uint32 internal immutable i_callbackGasLimit;
    uint16 internal immutable i_requestConfirmations;
    uint32 internal immutable i_numWords;

    mapping(address => Profile) internal players;
    mapping(uint256 => address) internal requestIds;
    address[] internal playerAddresses;

    event NewPlayer(address indexed player, string indexed name);
    event NewTurn(address indexed player);
    event Moved(address indexed player, uint32 indexed newFieldPosition);

    constructor(
        uint64 subscriptionId,
        address vrfCoordinator,
        bytes32 keyHash,
        uint32 callbackGasLimit,
        uint16 requestConfirmations
    ) VRFConsumerBaseV2(vrfCoordinator) {
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator);
        i_subscriptionId = subscriptionId;
        i_keyHash = keyHash;
        i_callbackGasLimit = callbackGasLimit;
        i_requestConfirmations = requestConfirmations;
        i_numWords = 1;
    }

    function register(string memory name) external {
        require(
            bytes(players[msg.sender].name).length == 0,
            "Already registered"
        );

        players[msg.sender].name = name;
        playerAddresses.push(msg.sender);

        emit NewPlayer(msg.sender, name);
    }

    function roleDice() external {
        require(
            !players[msg.sender].isYourTurnInProgress,
            "Your previous turn is still in progress"
        );
        require(players[msg.sender].fieldPosition < 40, "Game over");

        players[msg.sender].isYourTurnInProgress = true;

        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_keyHash,
            i_subscriptionId,
            i_requestConfirmations,
            i_callbackGasLimit,
            i_numWords
        );

        requestIds[requestId] = msg.sender;

        emit NewTurn(msg.sender);
    }

    function getScore(address player)
        external
        view
        returns (
            uint32 happiness,
            uint32 speed,
            uint32 wealth,
            uint32 fieldPosition,
            string memory name
        )
    {
        Profile memory playersProfile = players[player];
        return (
            playersProfile.happiness,
            playersProfile.speed,
            playersProfile.wealth,
            playersProfile.fieldPosition,
            playersProfile.name
        );
    }

    function getAllPlayers() external view returns (Profile[] memory) {
        uint256 length = playerAddresses.length;
        Profile[] memory _players = new Profile[](length);

        for (uint256 i = 0; i < length; ) {
            _players[i] = players[playerAddresses[i]];
            unchecked {
                ++i;
            }
        }

        return _players;
    }

    function getReward(uint32 fieldPosition)
        public
        pure
        returns (
            uint32 happiness,
            uint32 speed,
            uint32 wealth
        )
    {
        if (fieldPosition == 0) {
            return (0, 0, 0);
        } else if (fieldPosition == 1) {
            return (10, 0, 0);
        } else if (fieldPosition == 2) {
            return (0, 10, 0);
        } else if (fieldPosition == 3) {
            return (0, 0, 10);
        } else if (fieldPosition == 4) {
            return (10, 10, 0);
        } else if (fieldPosition == 5) {
            return (10, 0, 10);
        } else if (fieldPosition == 6) {
            return (0, 10, 10);
        } else if (fieldPosition == 7) {
            return (10, 10, 10);
        } else if (fieldPosition == 8) {
            return (10, 0, 0);
        } else if (fieldPosition == 9) {
            return (0, 10, 0);
        } else if (fieldPosition == 10) {
            return (0, 0, 10);
        } else if (fieldPosition == 11) {
            return (10, 10, 0);
        } else if (fieldPosition == 12) {
            return (10, 0, 10);
        } else if (fieldPosition == 13) {
            return (0, 10, 10);
        } else if (fieldPosition == 14) {
            return (10, 10, 10);
        } else if (fieldPosition == 15) {
            return (10, 0, 0);
        } else if (fieldPosition == 16) {
            return (0, 10, 0);
        } else if (fieldPosition == 17) {
            return (0, 0, 10);
        } else if (fieldPosition == 18) {
            return (10, 10, 0);
        } else if (fieldPosition == 19) {
            return (10, 0, 10);
        } else if (fieldPosition == 20) {
            return (0, 10, 10);
        } else if (fieldPosition == 21) {
            return (10, 10, 10);
        } else if (fieldPosition == 22) {
            return (10, 0, 0);
        } else if (fieldPosition == 23) {
            return (0, 10, 0);
        } else if (fieldPosition == 24) {
            return (0, 0, 10);
        } else if (fieldPosition == 25) {
            return (10, 10, 0);
        } else if (fieldPosition == 26) {
            return (10, 0, 10);
        } else if (fieldPosition == 27) {
            return (0, 10, 10);
        } else if (fieldPosition == 28) {
            return (10, 10, 10);
        } else if (fieldPosition == 29) {
            return (10, 0, 0);
        } else if (fieldPosition == 30) {
            return (0, 10, 0);
        } else if (fieldPosition == 31) {
            return (0, 0, 10);
        } else if (fieldPosition == 32) {
            return (10, 10, 0);
        } else if (fieldPosition == 33) {
            return (10, 0, 10);
        } else if (fieldPosition == 34) {
            return (0, 10, 10);
        } else if (fieldPosition == 35) {
            return (10, 10, 10);
        } else if (fieldPosition == 36) {
            return (10, 0, 0);
        } else if (fieldPosition == 37) {
            return (0, 10, 0);
        } else if (fieldPosition == 38) {
            return (0, 0, 10);
        } else if (fieldPosition == 39) {
            return (10, 10, 0);
        } else if (fieldPosition == 40) {
            return (10, 0, 10);
        } else {
            return (0, 0, 0);
        }
    }

    // @inheritdoc
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
        internal
        override
    {
        uint256 diceValue = (randomWords[0] % 6) + 1;
        address player = requestIds[requestId];

        players[player].fieldPosition += uint32(diceValue);
        (uint32 happiness, uint32 speed, uint32 wealth) = getReward(
            players[player].fieldPosition
        );
        players[player].happiness = happiness;
        players[player].speed = speed;
        players[player].wealth = wealth;
        players[player].isYourTurnInProgress = false;

        emit Moved(player, players[player].fieldPosition);
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