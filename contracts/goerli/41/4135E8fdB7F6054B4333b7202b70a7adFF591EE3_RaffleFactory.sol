// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./Raffle.sol";

contract RaffleFactory {
    /* State Variables */
    address private immutable i_linkAddress;
    address private immutable i_vrfCoordinatorAddress;
    bytes32 private immutable i_gasLane;
    uint32 private immutable i_callbackGasLimit;
    // address to raffle
    mapping(address => Raffle[]) private s_addressToRaffle;

    /* Events */
    event NewRaffleDeployed(address indexed raffleAddress, string contractName);

    /* Functions */
    constructor(
        address linkAddress,
        address vrfCoordinatorAddress,
        bytes32 gasLane,
        uint32 callbackGasLimit
    ) {
        i_linkAddress = linkAddress;
        i_vrfCoordinatorAddress = vrfCoordinatorAddress;
        i_gasLane = gasLane;
        i_callbackGasLimit = callbackGasLimit;
    }

    function createRaffleContract(uint32 numWords, uint256 maxParticipantCount)
        public
    {
        require(numWords > 0, "Contract has to request at least one winner!");
        require(
            maxParticipantCount > 0,
            "Contract has to add at least one participant!"
        );
        Raffle raffle = new Raffle(
            i_linkAddress,
            i_vrfCoordinatorAddress,
            i_gasLane,
            i_callbackGasLimit,
            numWords,
            maxParticipantCount
        );
        raffle.transferOwnership(msg.sender);
        s_addressToRaffle[msg.sender].push() = raffle;
        emit NewRaffleDeployed(address(raffle), "Raffle");
    }

    function getMyLatestRaffle() public view returns (Raffle) {
        return
            s_addressToRaffle[msg.sender][
                s_addressToRaffle[msg.sender].length - 1
            ];
    }

    function getMyRaffles() public view returns (Raffle[] memory) {
        return s_addressToRaffle[msg.sender];
    }

    function getLinkAddress() public view returns (address) {
        return i_linkAddress;
    }

    function getVrfCoordinatorAddress() public view returns (address) {
        return i_vrfCoordinatorAddress;
    }

    function getGasLane() public view returns (bytes32) {
        return i_gasLane;
    }

    function getCallbackGasLimit() public view returns (uint32) {
        return i_callbackGasLimit;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

error Raffle__RaffleNotOpen();
error Raffle__MaxParticipantCountReached(uint256 maxParticipants);
error Raffle__DuplicateDetected(string participant);
error Raffle__ParticipantExists(string participant);
error Raffle__RequestNotValid(uint256 numParticipants, uint256 raffleState);

contract Raffle is VRFConsumerBaseV2, Ownable {
    /* Types */
    enum RaffleState {
        OPEN,
        CALCULATING
    }

    /* State variables */
    bytes32 private immutable i_gasLane;
    uint32 private immutable i_callbackGasLimit;
    LinkTokenInterface private immutable s_linkToken;
    VRFCoordinatorV2Interface private s_vrfCoordinator;
    uint64 private s_subscriptionId;
    uint32 private s_numWords;
    uint256 private s_maxParticipantCount;
    uint256 private s_raffleId;
    string[] private s_participants;
    RaffleState private s_raffleState;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;

    // Raffle id to winners array
    mapping(uint256 => string[]) private s_raffleIdToWinners;

    /* Events */
    event NumWordsSet(uint32 indexed numWords);
    event MaxParticipantCountSet(uint256 indexed maxParticipantCount);
    event WinnersRequested(
        address indexed requestor,
        uint256 indexed requestId
    );
    event ParticipantAdded(string indexed participant);
    event WinnersPicked(string[] indexed winners);

    /* Modifiers */
    modifier noDuplicates(string memory newParticipant) {
        string[] memory participants = s_participants;
        for (uint256 i = 0; i < participants.length; i++) {
            if (
                keccak256(abi.encodePacked(participants[i])) ==
                keccak256(abi.encodePacked(newParticipant))
            ) revert Raffle__ParticipantExists(newParticipant);
        }
        _;
    }

    /* Functions */
    constructor(
        address linkAddress,
        address vrfCoordinatorV2,
        bytes32 gasLane,
        uint32 callbackGasLimit,
        uint32 numWords,
        uint256 maxParticipantCount
    ) VRFConsumerBaseV2(vrfCoordinatorV2) {
        s_linkToken = LinkTokenInterface(linkAddress);
        s_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        i_gasLane = gasLane;
        i_callbackGasLimit = callbackGasLimit;
        s_numWords = numWords;
        s_maxParticipantCount = maxParticipantCount;
        s_raffleState = RaffleState.OPEN;
        s_raffleId = 1;
        createNewSubscription();
    }

    function transferOwnership() external {
        super.transferOwnership(msg.sender);
    }

    function setNumWords(uint32 newNumWords) external onlyOwner {
        s_numWords = newNumWords;
        emit NumWordsSet(newNumWords);
    }

    function setMaxParticipantCount(uint256 maxParticipantCount)
        external
        onlyOwner
    {
        s_maxParticipantCount = maxParticipantCount;
        emit MaxParticipantCountSet(maxParticipantCount);
    }

    function addParticipant(string memory newParticipant)
        external
        onlyOwner
        noDuplicates(newParticipant)
    {
        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle__RaffleNotOpen();
        }
        if (s_maxParticipantCount == s_participants.length) {
            revert Raffle__MaxParticipantCountReached(s_maxParticipantCount);
        }
        s_participants.push(newParticipant);
        emit ParticipantAdded(newParticipant);
    }

    // Assumes this contract owns link.
    // 1000000000000000000 = 1 LINK
    function topUpSubscription(uint256 amount) external onlyOwner {
        s_linkToken.transferAndCall(
            address(s_vrfCoordinator),
            amount,
            abi.encode(s_subscriptionId)
        );
    }

    function requestWinners() external onlyOwner {
        bool requestValid = checkRequestValidity();
        if (!requestValid) {
            revert Raffle__RequestNotValid(
                s_participants.length,
                uint256(s_raffleState)
            );
        }
        s_raffleState = RaffleState.CALCULATING;
        uint256 requestId = s_vrfCoordinator.requestRandomWords(
            i_gasLane,
            s_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            s_numWords
        );
        emit WinnersRequested(msg.sender, requestId);
    }

    function fulfillRandomWords(
        uint256, /* requestId */
        uint256[] memory randomWords
    ) internal override {
        string[] memory winners = new string[](randomWords.length);
        for (uint256 i = 0; i < randomWords.length; i++) {
            uint256 indexOfWinner = randomWords[i] % s_participants.length;
            string memory recentWinner = s_participants[indexOfWinner];
            winners[i] = recentWinner;
            s_participants[indexOfWinner] = s_participants[
                s_participants.length - 1
            ];
            s_participants.pop();
        }
        s_raffleIdToWinners[s_raffleId] = winners;
        s_raffleId += 1;
        s_raffleState = RaffleState.OPEN;
        s_participants = new string[](0);
        emit WinnersPicked(winners);
    }

    // Create a new subscription when the contract is initially deployed.
    function createNewSubscription() private onlyOwner {
        s_subscriptionId = s_vrfCoordinator.createSubscription();
        // Add this contract as a consumer of its own subscription.
        s_vrfCoordinator.addConsumer(s_subscriptionId, address(this));
    }

    function addConsumer(address consumerAddress) external onlyOwner {
        // Add a consumer contract to the subscription.
        s_vrfCoordinator.addConsumer(s_subscriptionId, consumerAddress);
    }

    function removeConsumer(address consumerAddress) external onlyOwner {
        // Remove a consumer contract from the subscription.
        s_vrfCoordinator.removeConsumer(s_subscriptionId, consumerAddress);
    }

    function cancelSubscription(address receivingWallet) external onlyOwner {
        // Cancel the subscription and send the remaining LINK to a wallet address.
        s_vrfCoordinator.cancelSubscription(s_subscriptionId, receivingWallet);
        s_subscriptionId = 0;
    }

    // Transfer this contract's funds to an address.
    // 1000000000000000000 = 1 LINK
    function withdraw(uint256 amount, address to) external onlyOwner {
        s_linkToken.transfer(to, amount);
    }

    function checkRequestValidity() public view returns (bool requestValid) {
        (uint96 balance, , , ) = s_vrfCoordinator.getSubscription(
            s_subscriptionId
        );
        bool hasBalance = balance > 0;
        bool hasPlayers = s_participants.length > 0;
        bool isOpen = RaffleState.OPEN == s_raffleState;
        requestValid = (hasBalance && hasPlayers && isOpen);
        return (requestValid);
    }

    function getSubscriptionId() public view returns (uint256) {
        return s_subscriptionId;
    }

    function getRaffleId() public view returns (uint256) {
        return s_raffleId;
    }

    function getMaxParticipants() public view returns (uint256) {
        return s_maxParticipantCount;
    }

    function getParticipant(uint256 index)
        public
        view
        returns (string memory participant)
    {
        participant = s_participants[index];
        return participant;
    }

    function getNumParticipants() public view returns (uint256) {
        return s_participants.length;
    }

    function getWinners(uint256 raffleId)
        public
        view
        returns (string[] memory)
    {
        return s_raffleIdToWinners[raffleId];
    }

    function getRaffleState() public view returns (RaffleState) {
        return s_raffleState;
    }

    function getNumOfWords() public view returns (uint256) {
        return s_numWords;
    }

    function getVRFCoordinatorV2()
        public
        view
        returns (VRFCoordinatorV2Interface)
    {
        return s_vrfCoordinator;
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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT
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