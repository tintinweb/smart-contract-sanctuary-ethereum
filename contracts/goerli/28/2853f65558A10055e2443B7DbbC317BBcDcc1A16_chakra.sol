// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

//import "hardhat/console.sol";

interface CEth {
    function balanceOf(address) external view returns (uint256);

    function exchangeRateCurrent() external returns (uint256);

    function supplyRatePerBlock() external returns (uint256);

    function mint() external payable;

    function redeemUnderlying(uint256) external returns (uint256);
}

contract chakra is VRFConsumerBaseV2 {
    // This State Variables Are Used To Get Random Number, This Are Related To Chainlink VRF.
    uint64 s_subscriptionId = 10235; // Your Have To Take Subscription Of Chain Link And Then You Will Get This Id.
    address vrfCoordinator = 0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D; // This Is Coordinator Id For Rinkeby Network.
    VRFCoordinatorV2Interface COORDINATOR =
        VRFCoordinatorV2Interface(vrfCoordinator);
    bytes32 keyHash =
        0x79d3d8832d904592c0bf9818b621522c988bb8b0c05cdc3b15aea1b6e8db0c15; // Choose Different Id For Differnt Network And This Hash Is Responsible For Gas Fee In Random Number Generation.
    uint32 callbackGasLimit = 2500000;
    uint16 requestConfirmations = 3;
    uint32 numWords = 1;
    uint256 public s_requestId;

    constructor() VRFConsumerBaseV2(vrfCoordinator) {}

    function requestRandomWords() private {
        // This Method Is Used To Get Random Value And It Will Call "fulfillRandomWords" Method.
        s_requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
    }

    // This Variable, "depositETH" And "withdrawn" Are Realated To Compound Protocol.
    CEth contractInter = CEth(0x64078a6189Bf45f80091c6Ff2fCEe1B15Ac8dbde); // Reference Variable Of CEth Interface And It Takes Contract Address For Rinkeby Network.

    receive() external payable {}

    function showBalance() public view returns (uint256) {
        return contractInter.balanceOf(address(this));
    }

    function exchangeRate() public returns (uint256) {
        return contractInter.exchangeRateCurrent();
    }

    function supplyRate() public returns (uint256) {
        return contractInter.supplyRatePerBlock();
    }

    function depositETH() public payable {
        contractInter.mint{value: msg.value, gas: 250000000}();
    }

    function withdrawn(uint256 amount) private returns (uint256) {
        return contractInter.redeemUnderlying(amount);
    }

    event ChakraCreated(
        address indexed by,
        uint256 indexed id,
        uint256 value,
        uint256 time
    );
    event ChakraJoined(
        address indexed by,
        uint256 indexed id,
        uint256 value,
        uint256 time
    );
    event ChakraEnd(
        address indexed winner,
        uint256 indexed id,
        uint256 value,
        uint256 time
    );

    struct _chakra {
        address creator;
        uint256 baseValue;
        uint256 creatorShare;
        uint256 startTime;
        uint256 endTime;
        uint256 winner;
        bool isTrulyRandom;
    }

    address public contractCreator = msgSender();
    mapping(uint256 => _chakra) public chakras; // It Will Store Information About Chakras.
    mapping(uint256 => address[]) public participants;
    int256 public lock = -1; // For Applying Locking Mechanism.

    //uint public chakraFee=1200000000000000;
    uint256 public chakraFee = 0; // Chakra Fee Is Taken For Recovering Expense Of Truly Random Number
    uint256 public minOverTime = 0; // It Refers To Minimum Time After Which User Can End Chakra
    uint256 public maxCreatorShare = 90; // It Refers To Maximum Share Value Of Chakra Creator
    uint256 private randNonce = 0;

    function msgSender() private view returns (address) {
        return msg.sender;
    }

    function fulfillRandomWords(uint256, uint256[] memory randomWords)
        internal
        override
    {
        uint256 id = uint256(lock);
        uint256 randomValue = randomWords[0] % participants[id].length;
        chakras[id].winner = randomValue + 1;
        lock = -1;
    }

    modifier onlyOwner() {
        require(
            contractCreator == msgSender(),
            "Only Contract Creator Can Access This Method"
        );
        _;
    }

    function setChakraFee(uint256 _chakraFee) public onlyOwner {
        chakraFee = _chakraFee;
    }

    function setMinOverTime(uint256 _minOverTime) public onlyOwner {
        minOverTime = _minOverTime;
    }

    function setMaxCreatorShare(uint256 _maxCreatorShare) public onlyOwner {
        maxCreatorShare = _maxCreatorShare;
    }

    function checkRandNonce() public view onlyOwner returns (uint256) {
        return randNonce;
    }

    function setRandNonce(uint256 _randNonce) public onlyOwner {
        randNonce = _randNonce;
    }

    function withdrawFunds(uint256 amount) public onlyOwner {
        contractInter.redeemUnderlying(amount);
        payable(contractCreator).transfer(amount);
    }

    function contractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function showParticipants(uint256 id)
        public
        view
        returns (address[] memory)
    {
        require(chakras[id].creator != address(0), "Chakra Not Exists");
        address[] memory _participants = participants[id];
        return _participants;
    }

    // Chakra Can Be Created Using This Method.
    // Chakra Creator Has To Use Unique Id For Creating Chakra.
    // They Can Use Id Of Chakra That Not Exists.
    function createChakra(
        uint256 id,
        uint256 _baseValue,
        uint256 _share,
        bool _isTrulyRandom
    ) public payable {
        require(chakras[id].creator == address(0), "Chakra Already Exists");
        uint256 minBaseValue = exchangeRate() / 1000000000000000000;
        require(
            (_baseValue > minBaseValue && _share < maxCreatorShare),
            "Creator Share Should Lesser Than MaxShare Value And Passed Value Should Greater Than MinBase Value."
        );
        if (_isTrulyRandom == true) {
            require(
                msg.value >= (_baseValue + chakraFee),
                "Your Passed Value Should Greater Or Equal To BaseValue + Fee"
            );
        } else {
            require(
                msg.value >= (_baseValue),
                "Your Passed Value Should Greater Or Equal To BaseValue"
            );
        }
        _chakra storage newChakra = chakras[id];
        address _creator = msgSender();
        newChakra.creator = _creator;
        participants[id] = [_creator];
        newChakra.baseValue = _baseValue;
        newChakra.creatorShare = _share;
        newChakra.startTime = block.timestamp;
        newChakra.isTrulyRandom = _isTrulyRandom;
        emit ChakraCreated(_creator, id, msg.value, block.timestamp);
        depositETH();
    }

    // This Method Will Check That Whether Participant Exists Or Not.
    function isPraticipantExists(address _participant, uint256 id)
        private
        view
        returns (bool)
    {
        address[] memory _participants = participants[id];
        uint256 totalParticipants = _participants.length;
        for (uint256 i = 0; i < totalParticipants; ) {
            unchecked {
                if (_participants[i] == _participant) {
                    return true;
                }
                i++;
            }
        }
        return false;
    }

    // Anyone Can Join Chakra By Passing Id Of Chakra In This Method.
    function joinChakra(uint256 id) public payable {
        _chakra memory tempChakra = chakras[id];
        require(tempChakra.creator != address(0), "Chakra Not Exists");
        require(tempChakra.winner == 0, "Chakra Is Ended");
        if (tempChakra.isTrulyRandom == true) {
            require(lock == -1, "Now This Method Is Lock And Chakra Is End");
        }
        require(
            msg.value >= chakras[id].baseValue,
            "Your Passed Value Should Greater Or Equal To BaseValue"
        );
        address _participant = msgSender();
        require(
            isPraticipantExists(_participant, id) == false,
            "User Already Exists"
        );
        participants[id].push(_participant);
        emit ChakraJoined(_participant, id, msg.value, block.timestamp);
        depositETH();
    }

    // Using This Method Chakra Creator Chakra Can End Or Stop.
    // Only Chakra Creator Can Access This Method.
    // Basically Here "requestRandomWords" Will Be Called Which Will Assign Random Value To Winners Mapping
    function endChakra(uint256 id) public {
        _chakra memory tempChakra = chakras[id];
        require(tempChakra.creator != address(0), "Chakra Not Exists");
        require(tempChakra.winner == 0, "Chakra Is Ended");
        require(
            tempChakra.creator == msgSender(),
            "Only Chakra Creator Can Access This Method"
        );
        require(
            tempChakra.startTime + minOverTime < block.timestamp,
            "Chakra Can End After MinOverTime"
        );
        if (tempChakra.isTrulyRandom == true) {
            require(lock == -1, "Now This Method Is Lock Try After Some Time");
            lock = int256(id);
            requestRandomWords();
        } else {
            address _creator = msgSender();
            randNonce++;
            uint256 randomNumber = uint256(
                keccak256(
                    abi.encodePacked(block.timestamp, _creator, randNonce)
                )
            ) % participants[id].length;
            chakras[id].winner = randomNumber + 1;
            chakras[id].endTime = block.timestamp;
            uint256 totalFund = participants[id].length * tempChakra.baseValue;
            withdrawn(totalFund);
            uint256 _creatorShare = (totalFund * tempChakra.creatorShare) / 100;
            totalFund -= _creatorShare;
            payable(_creator).transfer(_creatorShare);
            address winnerAddress = participants[id][randomNumber];
            payable(winnerAddress).transfer(totalFund);
            emit ChakraEnd(winnerAddress, id, totalFund, block.timestamp);
        }
    }

    // Using This Method Funds Will Be Distributed To Winner And Chakra Creator.
    // Anyone Can Access This Method.
    // Chakra Creator Will Get Funds As Per Their Share Amount And Rest Of Funds Will Sended To Winner.
    function distributeFunds(uint256 id) public {
        require(chakras[id].creator != address(0), "Chakra Not Exists");
        _chakra memory tempChakra = chakras[id];
        require(
            tempChakra.isTrulyRandom == true && tempChakra.endTime == 0,
            "Only Truly Random Chakra Can Be Accesed And Before EndTime"
        );
        require(
            tempChakra.winner != 0,
            "Winner Is Not Declared Or Random Value Is Not Obtained"
        );
        chakras[id].endTime = block.timestamp;
        address _creator = tempChakra.creator;
        address winnerAddress = participants[id][tempChakra.winner - 1];
        uint256 totalFund = participants[id].length * tempChakra.baseValue;
        withdrawn(totalFund);
        uint256 _creatorShare = (totalFund * tempChakra.creatorShare) / 100;
        totalFund -= _creatorShare;
        payable(_creator).transfer(_creatorShare);
        payable(winnerAddress).transfer(totalFund);
        emit ChakraEnd(winnerAddress, id, totalFund, block.timestamp);
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