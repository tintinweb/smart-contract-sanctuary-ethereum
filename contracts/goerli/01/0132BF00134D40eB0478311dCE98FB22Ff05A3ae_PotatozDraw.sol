// SPDX-License-Identifier: MIT
// An example of a consumer contract that relies on a subscription for funding.
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/utils/Arrays.sol";

contract PotatozDraw is VRFConsumerBaseV2 {
    VRFCoordinatorV2Interface COORDINATOR;

    // Your subscription ID.
    uint64 public s_subscriptionId;

    // Goerli coordinator. For other networks,
    // see https://docs.chain.link/docs/vrf-contracts/#configurations
    address vrfCoordinator = 0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D;

    // The gas lane to use, which specifies the maximum gas price to bump to.
    // For a list of available gas lanes on each network,
    // see https://docs.chain.link/docs/vrf-contracts/#configurations
    bytes32 keyHash =
        0x79d3d8832d904592c0bf9818b621522c988bb8b0c05cdc3b15aea1b6e8db0c15;

    // Depends on the number of requested values that you want sent to the
    // fulfillRandomWords() function. Storing each word costs about 20,000 gas,
    // so 100,000 is a safe default for this example contract. Test and adjust
    // this limit based on the network that you select, the size of the request,
    // and the processing of the callback request in the fulfillRandomWords()
    // function.
    uint32 callbackGasLimit = 8000000;

    // The default is 3, but you can set this higher.
    uint16 requestConfirmations = 3;

    address public s_owner;
    mapping(address => bool) public allowedHelpers;

    string public drawID = "0";
    mapping(string => uint32) public drawNumOfWinners; // drawID => NumOfWinners
    mapping(string => uint256) public drawSetupDataSequence; // drawID => setupDataSequence
    mapping(string => mapping(uint256 => address)) public drawETOAddresses; // drawID => ending ticket ordinals => draw winner
    mapping(string => mapping(address => uint256)) public drawTicketsOfAddress; // drawID => draw participant address => tickets an address have (at that draw)
    mapping(string => uint256[]) public drawEndTicketOrdinals; // drawID => array of ending ticket ordinals.
    mapping(string => string[]) drawPrizes; // drawID => array of prizes (could be links to opensea page)

    mapping(string => uint256[]) drawRandomWords; // drawID => random uint256 array returned/set by Chainlink VRF
    mapping(uint256 => bool) isAddingExtraRandom;

    event DrawFulfilled(string indexed drawID, uint256 numWinners);
    event DrawExtraRandomAdded(string indexed drawID, uint256 numWinners);

    event NextDraw(string indexed drawID);

    constructor(uint64 subscriptionId) VRFConsumerBaseV2(vrfCoordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        s_owner = msg.sender;
        s_subscriptionId = subscriptionId;
    }

    modifier onlyOwner() {
        require(msg.sender == s_owner);
        _;
    }

    modifier onlyOwnerOrHelper() {
        require(msg.sender == s_owner || allowedHelpers[msg.sender]);
        _;
    }

    function setHelper(address helper, bool allowed) external onlyOwner {
        allowedHelpers[helper] = allowed;
    }

    function updateVRFSubscriptionID(uint64 subID) external onlyOwner {
        s_subscriptionId = subID;
    }

    function setDrawID(string memory _drawID) external onlyOwnerOrHelper {
        drawID = _drawID;
    }

    function setPrizes(string[] memory _prizes) external onlyOwnerOrHelper {
        delete drawPrizes[drawID];
        for (uint256 i = 0; i < _prizes.length; i++) {
            drawPrizes[drawID].push(_prizes[i]);
        }
    }

    function getPrizes(string memory _drawID)
        external
        view
        returns (string[] memory)
    {
        return drawPrizes[_drawID];
    }

    function setupDrawData(
        uint256[] calldata etos,
        address[] calldata addresses,
        uint256 sequence
    ) external onlyOwnerOrHelper {
        require(etos.length == addresses.length && etos.length >= 1);
        require(sequence - drawSetupDataSequence[drawID] == 1, "Invalid sequeunce");
        drawSetupDataSequence[drawID] = sequence;
        uint256[] storage etoArray = drawEndTicketOrdinals[drawID];
        mapping(uint256 => address) storage etoAddresses = drawETOAddresses[
            drawID
        ];
        mapping(address => uint256)
            storage ticketsOfAddress = drawTicketsOfAddress[drawID];
        for (uint256 i = 0; i < etos.length; i++) {
            uint256 eto = etos[i];
            uint256 tickets = 0;
            if (etoArray.length == 0) {
                tickets = eto + 1;
            } else {
                tickets = eto - etoArray[etoArray.length - 1];
            }
            require(tickets > 0, "entry must have at least 1 ticket");
            address participantAddress = addresses[i];
            etoArray.push(eto);
            etoAddresses[eto] = participantAddress;
            require(ticketsOfAddress[participantAddress] == 0, "duplicate entry");
            ticketsOfAddress[participantAddress] = tickets;
        }
    }

    function doDraw(uint32 numWinners) external onlyOwnerOrHelper {
        require(numWinners >= 1, "At least 1 winners");

        uint32 exist = drawNumOfWinners[drawID];
        require(exist == 0, "Already drawed. Call setDrawID() before doing next draw.");

        drawNumOfWinners[drawID] = numWinners;

        // Will revert if subscription is not set and funded.
        COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWinners * 3
        );
    }

    function addExtraRandom(uint32 numRandoms) external onlyOwnerOrHelper {
        uint32 exist = drawNumOfWinners[drawID];
        require(exist > 0, "doDraw not yet called");
        uint256 rid = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numRandoms
        );
        isAddingExtraRandom[rid] = true;
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
        internal
        override
    {
        uint256[] memory exist = drawRandomWords[drawID];
        if (isAddingExtraRandom[requestId]) {
            for (uint256 i = 0; i < randomWords.length; i++) {
                drawRandomWords[drawID].push(randomWords[i]);
            }
            emit DrawExtraRandomAdded(drawID, randomWords.length);
        } else if (exist.length == 0) {
            drawRandomWords[drawID] = randomWords;
            emit DrawFulfilled(drawID, drawNumOfWinners[drawID]);
        }
    }

    function mockDraw(uint32 numWinners, uint256[] memory randomWords)
        external
        onlyOwner
    {
        uint256[] memory exist = drawRandomWords[drawID];
        if (numWinners == 0) {
            for (uint256 i = 0; i < randomWords.length; i++) {
                drawRandomWords[drawID].push(randomWords[i]);
            }
            emit DrawExtraRandomAdded(drawID, randomWords.length);
        } else if (exist.length == 0) {
            drawNumOfWinners[drawID] = numWinners;
            drawRandomWords[drawID] = randomWords;
            emit DrawFulfilled(drawID, randomWords.length);
        }
    }

    /*
    If drawEndTicketOrdinals[drawID] is [1,3,7,10,15], and 0-15 (incl) random numbers are [0,14,2],
    then drawETOAddresses[drawID][0], drawETOAddresses[drawID][4], drawETOAddresses[drawID][1] are winners
    =======================================
    X = drawEndTicketOrdinals
    bisect X for i
        if RN <= X[i] && (i == 0 || RN > X[i - 1]):
            drawETOAddresses[drawID][X[i]] is winner
    */
    function getWinners(string memory _drawID)
        external
        view
        returns (address[] memory)
    {
        uint256[] storage etoArray = drawEndTicketOrdinals[_drawID];
        uint256[] storage rWords = drawRandomWords[_drawID];
        uint32 numOfWinners = drawNumOfWinners[_drawID];

        require(
            etoArray.length > 0 && rWords.length > 0 && numOfWinners > 0,
            "No winners yet for this draw"
        );

        address[] memory winners = new address[](numOfWinners);

        uint256 bound = etoArray[etoArray.length - 1] + 1;
        uint256 winnersLength = 0;
        for (uint256 i = 0; i < rWords.length; i++) {
            uint256 winningTicketOrdinal = rWords[i] % bound;
            uint256 etoIdx = Arrays.findUpperBound(
                etoArray,
                winningTicketOrdinal
            );
            uint256 winningETO = etoArray[etoIdx];
            address winner = drawETOAddresses[_drawID][winningETO];
            bool isWinnerDuplicate = false;
            for (uint256 j = 0; j < winnersLength; j++) {
                if (winner == winners[j]) {
                    isWinnerDuplicate = true;
                    break;
                }
            }
            if (!isWinnerDuplicate) {
                winners[winnersLength++] = winner;
                if (winnersLength == numOfWinners) {
                    break;
                }
            }
        }
        require(
            winnersLength == numOfWinners,
            "Out of random numbers, need call addExtraRandom()"
        );
        return winners;
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
// OpenZeppelin Contracts v4.4.1 (utils/Arrays.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev Collection of functions related to array types.
 */
library Arrays {
    /**
     * @dev Searches a sorted `array` and returns the first index that contains
     * a value greater or equal to `element`. If no such index exists (i.e. all
     * values in the array are strictly less than `element`), the array length is
     * returned. Time complexity O(log n).
     *
     * `array` is expected to be sorted in ascending order, and to contain no
     * repeated elements.
     */
    function findUpperBound(uint256[] storage array, uint256 element) internal view returns (uint256) {
        if (array.length == 0) {
            return 0;
        }

        uint256 low = 0;
        uint256 high = array.length;

        while (low < high) {
            uint256 mid = Math.average(low, high);

            // Note that mid will always be strictly less than high (i.e. it will be a valid array index)
            // because Math.average rounds down (it does integer division with truncation).
            if (array[mid] > element) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        // At this point `low` is the exclusive upper bound. We will return the inclusive upper bound.
        if (low > 0 && array[low - 1] == element) {
            return low - 1;
        } else {
            return low;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}