/**
 *Submitted for verification at Etherscan.io on 2022-04-08
*/

// File: @chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol


pragma solidity ^0.8.0;

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

// File: @chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol


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

// File: @chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol


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

// File: contracts/raffle/RandomNumbers.sol


// Based on Chainlink VRFv2Consumer.sol
pragma solidity ^0.8.13;




contract RandomNumbers is VRFConsumerBaseV2 {
    VRFCoordinatorV2Interface COORDINATOR;
    LinkTokenInterface LINKTOKEN;

    uint256 private constant MAX_UINT256 = 2**256 - 1;

    struct Selection {
        string name;
        uint256[] selection;
        uint256 minValue;
        uint256 maxValue;
        uint32 count;
    }

    event SelectedRandomValues(string indexed name, uint256 indexed requestId, uint32 count, uint256 minValue, uint256 maxValue);
    event GotRandomValues(uint256 indexed requestId, uint256[] randomWords);
    event RequestNotFound(uint256 indexed requestId);
    event RequestAlreadyFulfilled(uint256 indexed requestId);
    event Selected(string indexed name, uint256[] selection);
    event CoordinatorChanged(address indexed newCoordinator);
    event ConfirmationsChanged(uint16 indexed newConfirmations);
    event LinkChanged(address indexed newLinkAddress);
    event GasLaneChanged(bytes32 indexed newHash);
    event SubscriptionChanged(uint64 indexed newSubscriptionId);

    //map requestId to Selection
    mapping (uint256 => Selection) public _selections;
    // Contract owner
    address public _owner;
    // VRF coordinator.
    address public _vrfCoordinator;
    // Confirmations required
    uint16 public _requestConfirmations;
    // LINK token contract
    address public _link;
    // VRF gas lane key hash
    bytes32 public _gasLaneKeyHash;
    // Chainlink VRF subscription ID.
    uint64 public _subscriptionId;

    modifier onlyOwner() {
        require(msg.sender == _owner);
        _;
    }

    constructor(uint64 subscriptionId, address vrfCoordinator, address link, bytes32 gasLaneKeyHash, uint16 requestConfirmations) VRFConsumerBaseV2(vrfCoordinator) {
        require(requestConfirmations >= 3 && requestConfirmations <= 200, "3 <= confirmations <= 200");
        _owner = msg.sender;
        _subscriptionId = subscriptionId;
        _vrfCoordinator = vrfCoordinator;
        _link = link;
        _gasLaneKeyHash = gasLaneKeyHash;
        _requestConfirmations = requestConfirmations;

        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        LINKTOKEN = LinkTokenInterface(link);
    }

    function adminSetCoordinator(address vrfCoordinator) external onlyOwner {
        _vrfCoordinator = vrfCoordinator;
        emit CoordinatorChanged(vrfCoordinator);
    }

    function adminSetConfirmations(uint16 requestConfirmations) external onlyOwner {
        _requestConfirmations = requestConfirmations;
        emit ConfirmationsChanged(requestConfirmations);
    }

    function adminSetLink(address link) external onlyOwner {
        _link = link;
        emit LinkChanged(link);
    }

    function adminSetGasLane(bytes32 gasLaneKeyHash) external onlyOwner {
        _gasLaneKeyHash = gasLaneKeyHash;
        emit GasLaneChanged(gasLaneKeyHash);
    }

    function adminSetSubscriptionId(uint64 subscriptionId) external onlyOwner {
        _subscriptionId = subscriptionId;
        emit SubscriptionChanged(subscriptionId);
    }

    // requires ChainlinkVRF subscription to have sufficient funds and have contract enabled
    // if duplicate selection occur, extra random values are used to replace duplicates
    function selectRandomValues(string calldata name, uint32 count, uint32 extra, uint256 minValue, uint256 maxValue, uint32 callbackGasLimit) external onlyOwner {
        require(minValue != 0, "minValue must be > 0");
        require(minValue < maxValue, "minValue must be < maxValue");
        
        uint256 requestId = COORDINATOR.requestRandomWords(
            _gasLaneKeyHash,
            _subscriptionId,
            _requestConfirmations,
            callbackGasLimit,
            count + extra
        );
        
        Selection storage selectionData = _selections[requestId];
        require(selectionData.minValue == 0, "requestId already used");
        selectionData.name = name;
        selectionData.minValue = minValue;
        selectionData.maxValue = maxValue;
        selectionData.count = count;

        emit SelectedRandomValues(name, requestId, count, minValue, maxValue);
    }

    // VRF callback completion function
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        emit GotRandomValues(requestId, randomWords);

        Selection storage selectionData = _selections[requestId];
        if (selectionData.minValue == 0){
            emit RequestNotFound(requestId);
            return;
        }
        if (selectionData.selection.length != 0){
            emit RequestAlreadyFulfilled(requestId);
            return;
        }

        uint count = selectionData.count;
        uint256 minValue = selectionData.minValue;
        uint256 modulus = selectionData.maxValue - minValue + 1;
        for (uint i = 0; i < count; ++i){
            selectionData.selection.push(randomWords[i] % modulus + minValue);
        }

        //check for duplicates
        uint extrasUsed = 0;
        bool recheck;
        do {
            recheck = false;            
            for (uint i = 0; i < count; ++i){
                for (uint j = i+1; j < count; ++j){
                    if (selectionData.selection[j] == selectionData.selection[i]){
                        //j is a duplicate, use extra random data to select a replacement
                        if (count + extrasUsed >= randomWords.length){
                            //not enough random data to overcome duplicates, will need to reselect ones that are 0
                            selectionData.selection[j] = 0;
                        } else {
                            selectionData.selection[j] = randomWords[count + extrasUsed++] % modulus + minValue;
                            recheck = true; //need to recheck in case new choice is a duplicate
                        }
                    }
                }                
            }
        } while(recheck);

        emit Selected(selectionData.name, selectionData.selection);
    }
}