// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol';
import '@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol';

import './IToffeePetsCollectible.sol';

error GeneCrossover__InvalidConstructorParams();
error GeneCrossover__GeneNotCompatible();
error GeneCrossover__CollectibleNotSet();

contract GeneCrossover is VRFConsumerBaseV2 {
    VRFCoordinatorV2Interface public s_vrfCoordinatorV2;
    IToffeePetsCollectible public s_toffePetsCollectible;

    string public s_fatherGene;
    string public s_motherGene;

    uint8 public constant NUM_LIMIT_VALUES_PER_TRAIT = 10;
    uint8 public constant NUM_TRAITS = 8;
    uint16 public constant REQUEST_CONFIRMATIONS = 3;
    uint32 public constant NUM_WORDS = 3;

    uint64 public immutable s_subscriptionId;
    uint32 public immutable s_callbackGasLimit;

    uint8[] public s_limitValuesPerTraitList;

    uint8 public s_mutationChance;

    uint256 public s_toffeePetsId;

    bytes32 public s_gasLane;

    event RequestRandomness(uint256 requestId);
    event MixGene(uint256 tokenId, string newGene, bool isMutation);

    constructor(
        uint8[] memory _limitValuesPerTraitList,
        uint8 _mutationChance,
        address _vrfCoordinatorV2,
        uint64 _subscriptionId,
        uint32 _callbackGasLimit,
        bytes32 _gasLane,
        address _toffePetsCollectible
    ) VRFConsumerBaseV2(_vrfCoordinatorV2) {
        for (uint8 i = 0; i < _limitValuesPerTraitList.length; i++) {
            if (_limitValuesPerTraitList[i] > NUM_LIMIT_VALUES_PER_TRAIT) {
                revert GeneCrossover__InvalidConstructorParams();
            }
        }

        if (_limitValuesPerTraitList.length < 2 || _limitValuesPerTraitList.length > NUM_TRAITS) {
            revert GeneCrossover__InvalidConstructorParams();
        }

        s_limitValuesPerTraitList = _limitValuesPerTraitList;
        s_mutationChance = _mutationChance;
        s_vrfCoordinatorV2 = VRFCoordinatorV2Interface(_vrfCoordinatorV2);
        s_subscriptionId = _subscriptionId;
        s_callbackGasLimit = _callbackGasLimit;
        s_gasLane = _gasLane;
        s_toffePetsCollectible = IToffeePetsCollectible(_toffePetsCollectible);
    }

    function mixGeneRunner(
        uint256 _toffeePetsId,
        string memory _fatherGene,
        string memory _motherGene
    ) external {
        if (!isGeneCompatible(_fatherGene)) {
            revert GeneCrossover__GeneNotCompatible();
        }

        if (!isGeneCompatible(_motherGene)) {
            revert GeneCrossover__GeneNotCompatible();
        }

        s_toffeePetsId = _toffeePetsId;
        s_fatherGene = _fatherGene;
        s_motherGene = _motherGene;
        requestRandomness();
    }

    function mixGene(int8 mutatedTrait, int8 mutatedValue) internal {
        bytes memory fatherGeneBytes = bytes(s_fatherGene);
        bytes memory motherGeneBytes = bytes(s_motherGene);
        bytes memory crossoveredGeneBytes = new bytes(NUM_TRAITS);

        unchecked {
            // We assume that the genes are in even length
            uint8 divider = NUM_TRAITS / 2;

            for (uint8 i = 0; i < divider; i++) {
                crossoveredGeneBytes[i + divider] = fatherGeneBytes[i];
            }

            for (uint8 i = divider; i < NUM_TRAITS; i++) {
                crossoveredGeneBytes[i - divider] = motherGeneBytes[i];
            }
        }

        bool isMutation = false;
        if (mutatedTrait != -1 && mutatedValue != -1) {
            isMutation = true;
            string memory typeString = uint2str(uint256(uint8(mutatedValue)));
            bytes memory typeStringBytes = bytes(typeString);
            crossoveredGeneBytes[uint8(mutatedTrait)] = typeStringBytes[0];
        }

        if (address(s_toffePetsCollectible) != address(0x0)) {
            s_toffePetsCollectible.finishBreed(s_toffeePetsId, string(crossoveredGeneBytes), isMutation);
        } else {
            revert GeneCrossover__CollectibleNotSet();
        }

        emit MixGene(s_toffeePetsId, string(crossoveredGeneBytes), isMutation);
    }

    function requestRandomness() internal {
        uint256 requestId = s_vrfCoordinatorV2.requestRandomWords(
            s_gasLane,
            s_subscriptionId,
            REQUEST_CONFIRMATIONS,
            s_callbackGasLimit,
            NUM_WORDS
        );

        emit RequestRandomness(requestId);
    }

    /**
     * @dev Callback function used by VRF Coordinator
     */
    function fulfillRandomWords(uint256, uint256[] memory randomWords) internal override {
        uint8 hundred = 100;
        uint8 randomNumber;

        unchecked {
            randomNumber = uint8(randomWords[0] % hundred);
        }

        bool isMutation = randomNumber < s_mutationChance;

        if (isMutation) {
            uint8 randomTrait = uint8(randomWords[1]);
            uint8 randomValue = uint8(randomWords[2]);

            int8 trait = int8(randomTrait % NUM_TRAITS);
            int8 value = int8(randomValue % s_limitValuesPerTraitList[uint8(trait)]);

            mixGene(trait, value);
        } else {
            mixGene(-1, -1);
        }
    }

    function isGeneCompatible(string memory gene) private pure returns (bool) {
        bytes memory byteGenes = bytes(gene);

        if (byteGenes.length != NUM_TRAITS) {
            return false;
        }
        return true;
    }

    // https://github.com/provable-things/ethereum-api/blob/master/provableAPI_0.6.sol
    function uint2str(uint256 _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return '0';
        }

        uint256 j = _i;
        uint256 len;

        while (j != 0) {
            len++;
            j /= 10;
        }

        bytes memory bstr = new bytes(len);
        uint256 k = len;

        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }

        return string(bstr);
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
pragma solidity ^0.8.4;

interface IToffeePetsCollectible {
    function finishBreed(
        uint256 tokenId,
        string memory gene,
        bool isMutation
    ) external;
}