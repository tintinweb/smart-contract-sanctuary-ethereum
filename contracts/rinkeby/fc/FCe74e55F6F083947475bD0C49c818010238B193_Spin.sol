/**
 *Submitted for verification at Etherscan.io on 2022-06-07
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;



// Part: smartcontractkit/chainlink-brownie-c[email protected]/LinkTokenInterface

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
  function transferAndCall(address to, uint256 value, bytes calldata data) external returns (bool success);
  function transferFrom(address from, address to, uint256 value) external returns (bool success);
}

// Part: smartcontractkit/[email protected]/VRFConsumerBaseV2

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

// Part: smartcontractkit/[email protected]/VRFCoordinatorV2Interface

interface VRFCoordinatorV2Interface {

  /**
   * @notice Returns the global config that applies to all VRF requests.
   * @return minimumRequestBlockConfirmations - A minimum number of confirmation
   * blocks on VRF requests before oracles should respond.
   * @return fulfillmentFlatFeeLinkPPM - The charge per request on top of the gas fees.
   * Its flat fee specified in millionths of LINK.
   * @return maxGasLimit - The maximum gas limit supported for a fulfillRandomWords callback.
   * @return stalenessSeconds - How long we wait until we consider the ETH/LINK price
   * (used for converting gas costs to LINK) is stale and use `fallbackWeiPerUnitLink`
   * @return gasAfterPaymentCalculation - How much gas is used outside of the payment calculation,
   * i.e. the gas overhead of actually making the payment to oracles.
   * @return minimumSubscriptionBalance - The minimum subscription balance required to make a request. Its set to be about 300%
   * of the cost of a single request to handle in ETH/LINK price between request and fulfillment time.
   * @return fallbackWeiPerUnitLink - fallback ETH/LINK price in the case of a stale feed.
   */
  function getConfig()
  external
  view
  returns (
    uint16 minimumRequestBlockConfirmations,
    uint32 fulfillmentFlatFeeLinkPPM,
    uint32 maxGasLimit,
    uint32 stalenessSeconds,
    uint32 gasAfterPaymentCalculation,
    uint96 minimumSubscriptionBalance,
    int256 fallbackWeiPerUnitLink
  );

  /**
   * @notice Request a set of random words.
   * @param keyHash - Corresponds to a particular oracle job which uses
   * that key for generating the VRF proof. Different keyHash's have different gas price
   * ceilings, so you can select a specific one to bound your maximum per request cost.
   * @param subId  - The ID of the VRF subscription. Must be funded
   * with at least minimumSubscriptionBalance (see getConfig) LINK
   * before making a request.
   * @param minimumRequestConfirmations - How many blocks you'd like the
   * oracle to wait before responding to the request. See SECURITY CONSIDERATIONS
   * for why you may want to request more. The acceptable range is
   * [minimumRequestBlockConfirmations, 200].
   * @param callbackGasLimit - How much gas you'd like to receive in your
   * fulfillRandomWords callback. Note that gasleft() inside fulfillRandomWords
   * may be slightly less than this amount because of gas used calling the function
   * (argument decoding etc.), so you may need to request slightly more than you expect
   * to have inside fulfillRandomWords. The acceptable range is
   * [5000, maxGasLimit].
   * @param numWords - The number of uint256 random values you'd like to receive
   * in your fulfillRandomWords callback. Note these numbers are expanded in a
   * secure way by the VRFCoordinator from a single random value supplied by the oracle.
   * @return requestId - A unique identifier of the request. Can be used to match
   * a request to a response in fulfillRandomWords.
   */
  function requestRandomWords(
    bytes32 keyHash,
    uint64  subId,
    uint16  minimumRequestConfirmations,
    uint32  callbackGasLimit,
    uint32  numWords
  )
    external
    returns (
      uint256 requestId
    );

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
  function createSubscription()
    external
    returns (
      uint64 subId
    );

  /**
   * @notice Get a VRF subscription.
   * @param subId - ID of the subscription
   * @return balance - LINK balance of the subscription in juels.
   * @return owner - Owner of the subscription
   * @return consumers - List of consumer address which are able to use this subscription.
   */
  function getSubscription(
    uint64 subId
  )
    external
    view
    returns (
      uint96 balance,
      address owner,
      address[] memory consumers
    );

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @param newOwner - proposed new owner of the subscription
   */
  function requestSubscriptionOwnerTransfer(
    uint64 subId,
    address newOwner
  )
    external;

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @dev will revert if original owner of subId has
   * not requested that msg.sender become the new owner.
   */
  function acceptSubscriptionOwnerTransfer(
    uint64 subId
  )
    external;

  /**
   * @notice Add a consumer to a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - New consumer which can use the subscription
   */
  function addConsumer(
    uint64 subId,
    address consumer
  )
    external;

  /**
   * @notice Remove a consumer from a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - Consumer to remove from the subscription
   */
  function removeConsumer(
    uint64 subId,
    address consumer
  )
    external;

  /**
   * @notice Withdraw funds from a VRF subscription
   * @param subId - ID of the subscription
   * @param to - Where to send the withdrawn LINK to
   * @param amount - How much to withdraw in juels
   */
  function defundSubscription(
    uint64 subId,
    address to,
    uint96 amount
  )
    external;

  /**
   * @notice Cancel a subscription
   * @param subId - ID of the subscription
   * @param to - Where to send the remaining LINK to
   */
  function cancelSubscription(
    uint64 subId,
    address to
  )
    external;
}

// File: suck.sol

contract Spin is VRFConsumerBaseV2 {
    //RED & Black
    uint8 constant BET_RED = 0;
    uint8 constant BET_BLACK = 1;
    // EVEN and ODD
    uint8 constant BET_ODD = 2;
    uint8 constant BET_EVEN = 3;
    // 1-18 19-36
    uint8 constant BET_ONE_EIGHTTEEN = 4;
    uint8 constant BET_NINETEEN_THIRTYSIX = 5;
    // DOZENS
    uint8 constant BET_ONE_TWELVE = 6;
    uint8 constant BET_THIRTEEN_TWENTYFOUR = 7;
    uint8 constant BET_TWENTYFIVE_THIRTYSIX = 8;
    // COLUMNS
    uint8 constant BET_FIRST_COLUMN = 9;
    uint8 constant BET_SECOND_COLUMN = 10;
    uint8 constant BET_THIRD_COLUMN = 11;
    // DoubleStreets
    uint8 constant BET_ONE_TO_SIX = 12;
    uint8 constant BET_FOUR_TO_NINE = 13;
    uint8 constant BET_SEVEN_TO_TWELVE = 14;
    uint8 constant BET_TEN_TO_FIFTEEN = 15;
    uint8 constant BET_THIRTEEN_TO_EIGHTTEEN = 16;
    uint8 constant BET_SIXTEEN_TO_TWENTYONE = 17;
    uint8 constant BET_NINETEEN_TO_TWENTYFOUR = 18;
    uint8 constant BET_TWENTYTWO_TO_TWENTYSEVEN = 19;
    uint8 constant BET_TWENTYFIVE_TO_THIRTY = 20;
    uint8 constant BET_TWENTYEIGHT_TO_THIRTYTHREE = 21;
    uint8 constant BET_THIRTYONE_TO_THIRTYSIX = 22;
    // Cor NERS
    uint8 constant BET_C_ONE_TWO_FOUR_FIVE = 23;
    uint8 constant BET_C_FOUR_FIVE_SEVEN_EIGHT = 24;
    uint8 constant BET_C_SEVEN_EIGHT_TEN_ELEVEN = 25;
    uint8 constant BET_C_TEN_ELEVEN_THIRTEEN_FOURTEEN = 26;
    uint8 constant BET_C_THIRTEEN_FOURTEEN_SIXTEEN_SEVENTEEN = 27;
    uint8 constant BET_C_SIXTEEN_SEVENTEEN_NINETEEN_TWENTY = 28;
    uint8 constant BET_C_NINETEEN_TWENTY_TWENTYTWO_TWENTYTHREE = 29;
    uint8 constant BET_C_TWENTYTWO_TWENTYTHREE_TWENTYFIVE_TWENTYSIX = 30;
    uint8 constant BET_C_TWENTYFIVE_TWENTYSIX_TWENTYEIGHT_TWENTYNINE = 31;
    uint8 constant BET_C_TWENTYEIGHT_TWENTYNINE_THIRTYONE_THIRTYTWO = 32;
    uint8 constant BET_C_THIRTYONE_THIRTYTWO_THIRTYTHREE_THIRTYFOUR = 33;
    uint8 constant BET_C_TWO_THREE_FIVE_SIX = 34;
    uint8 constant BET_C_FIVE_SIX_EIGHT_NINE = 35;
    uint8 constant BET_C_EIGHT_NINE_ELEVEN_TWELVE = 36;
    uint8 constant BET_C_ELEVEN_TWELVE_FOURTEEN_FIFTEEN = 37;
    uint8 constant BET_C_FOURTEEN_FIFTEEN_SEVENTEEN_EIGHTTEEN = 38;
    uint8 constant BET_C_SEVENTEEN_EIGHTTEEN_TWENTY_TWENTYONE = 39;
    uint8 constant BET_C_TWENTY_TWENTYONE_TWENTYTHREE_TWENTYFOUR = 40;
    uint8 constant BET_C_TWENTYTHREE_TWENTYFOUR_TWENTYSIX_TWENTYSEVEN = 41;
    uint8 constant BET_C_TWENTYSIX_TWENTYSEVEN_TWENTYNINE_THIRTY = 42;
    uint8 constant BET_C_TWENTYNINE_THIRTY_THIRTYTWO_THIRTYTHREE = 43;
    uint8 constant BET_C_THIRTYTWO_THIRTYTHREE_THIRTYFIVE_THIRTYSIX = 44;
    // STREETS
    uint8 constant BET_STREET_ONE_TWO_THREE = 45;
    uint8 constant BET_STREET_FOUR_FIVE_SIX = 46;
    uint8 constant BET_STREET_SEVEN_EIGHT_NINE = 47;
    uint8 constant BET_STREET_TEN_ELEVEN_TWELVE = 48;
    uint8 constant BET_STREET_THIRTEEN_FOURTEEN_FIFTEEN = 49;
    uint8 constant BET_STREET_SIXTEEN_SEVENTEEN_EIGHTTEEN = 50;
    uint8 constant BET_STREET_NINETEEN_TWENTY_TWENTYONE = 51;
    uint8 constant BET_STREET_TWENTYTWO_TWENTYTHREE_TWENTYFOUR = 52;
    uint8 constant BET_STREET_TWENTYFIVE_TWENTYSIX_TWENTYSEVEN = 53;
    uint8 constant BET_STREET_TWENTYEIGHT_TWENTYNINE_THIRTY = 54;
    uint8 constant BET_STREET_THIRTYONE_THIRTYTWO_THIRTYTHREE = 55;
    uint8 constant BET_STREET_THIRTYFOUR_THIRTYFIVE_THIRTYSIX = 56;
    // SPLITS
    uint8 constant BET_SPLIT_ONE_TWO = 57;
    uint8 constant BET_SPLIT_FOUR_FIVE = 58;
    uint8 constant BET_SPLIT_SEVEN_EIGHT = 59;
    uint8 constant BET_SPLIT_TEN_ELEVEN = 60;
    uint8 constant BET_SPLIT_THIRTEEN_FOURTEEN = 61;
    uint8 constant BET_SPLIT_SIXTEEN_SEVENTEEN = 62;
    uint8 constant BET_SPLIT_NINETEEN_TWENTY = 63;
    uint8 constant BET_SPLIT_TWENTYTWO_TWENTYTHREE = 64;
    uint8 constant BET_SPLIT_TWENTYFIVE_TWENTYSIX = 65;
    uint8 constant BET_SPLIT_TWENTYEIGHT_TWENTYNINE = 66;
    uint8 constant BET_SPLIT_THIRTYONE_THIRTYTWO = 67;
    uint8 constant BET_SPLIT_THIRTYFOUR_THIRTYFIVE = 68;
    uint8 constant BET_SPLIT_TWO_THREE = 69;
    uint8 constant BET_SPLIT_FIVE_SIX = 70;
    uint8 constant BET_SPLIT_EIGHT_NINE = 71;
    uint8 constant BET_SPLIT_ELEVEN_TWELVE = 72;
    uint8 constant BET_SPLIT_FOURTEEN_FIFTEEN = 73;
    uint8 constant BET_SPLIT_SEVENTEEN_EIGHTTEEN = 74;
    uint8 constant BET_SPLIT_TWENTY_TWENTYONE = 75;
    uint8 constant BET_SPLIT_TWENTYTHREE_TWENTYFOUR = 76;
    uint8 constant BET_SPLIT_TWENTYSIX_TWENTYSEVEN = 77;
    uint8 constant BET_SPLIT_TWENTYNINE_THIRTY = 78;
    uint8 constant BET_SPLIT_THIRTYTWO_THIRTYTHREE = 79;
    uint8 constant BET_SPLIT_THIRTYFIVE_THIRTYSIX = 80;
    uint8 constant BET_SPLIT_ONE_FOUR = 81;
    uint8 constant BET_SPLIT_FOUR_SEVEN = 82;
    uint8 constant BET_SPLIT_SEVEN_TEN = 83;
    uint8 constant BET_SPLIT_TEN_THIRTEEN = 84;
    uint8 constant BET_SPLIT_THIRTEEN_SIXTEEN = 85;
    uint8 constant BET_SPLIT_SIXTEEN_NINETEEN = 86;
    uint8 constant BET_SPLIT_NINETEEN_TWENTYTWO = 87;
    uint8 constant BET_SPLIT_TWENTYTWO_TWENTYFIVE = 88;
    uint8 constant BET_SPLIT_TWENTYFIVE_TWENTYEIGHT = 89;
    uint8 constant BET_SPLIT_TWENTYEIGHT_THIRTYONE = 90;
    uint8 constant BET_SPLIT_THIRTYONE_THIRTYFOUR = 91;
    uint8 constant BET_SPLIT_TWO_FIVE = 92;
    uint8 constant BET_SPLIT_FIVE_EIGHT = 93;
    uint8 constant BET_SPLIT_EIGHT_ELEVEN = 94;
    uint8 constant BET_SPLIT_ELEVEN_FOURTEEN = 95;
    uint8 constant BET_SPLIT_FOURTEEN_SEVENTEEN = 96;
    uint8 constant BET_SPLIT_SEVENTEEN_TWENTY = 97;
    uint8 constant BET_SPLIT_TWENTY_TWENTYTHREE = 98;
    uint8 constant BET_SPLIT_TWENTYTHREE_TWENTYSIX = 99;
    uint8 constant BET_SPLIT_TWENTYSIX_TWENTYNINE = 100;
    uint8 constant BET_SPLIT_TWENTYNINE_THIRTYTWO = 101;
    uint8 constant BET_SPLIT_THIRTYTWO_THIRTYFIVE = 102;
    uint8 constant BET_SPLIT_THREE_SIX = 103;
    uint8 constant BET_SPLIT_SIX_NINE = 104;
    uint8 constant BET_SPLIT_NINE_TWELVE = 105;
    uint8 constant BET_SPLIT_TWELVE_FIFTEEN = 106;
    uint8 constant BET_SPLIT_FIFTEEN_EIGHTTEEN = 107;
    uint8 constant BET_SPLIT_EIGHTTEEN_TWENTYONE = 108;
    uint8 constant BET_SPLIT_TWENTYONE_TWENTYFOUR = 109;
    uint8 constant BET_SPLIT_TWENTYFOUR_TWENTYSEVEN = 110;
    uint8 constant BET_SPLIT_TWENTYSEVEN_THIRTY = 111;
    uint8 constant BET_SPLIT_THIRTY_THIRTYTHREE = 112;
    uint8 constant BET_SPLIT_THIRTYTHREE_THIRTYSIX = 113;
    // Numbers
    uint8 constant BET_NUMBER_ONE = 114;
    uint8 constant BET_NUMBER_TWO = 115;
    uint8 constant BET_NUMBER_THREE = 116;
    uint8 constant BET_NUMBER_FOUR = 117;
    uint8 constant BET_NUMBER_FIVE = 118;
    uint8 constant BET_NUMBER_SIX = 119;
    uint8 constant BET_NUMBER_SEVEN = 120;
    uint8 constant BET_NUMBER_EIGHT = 121;
    uint8 constant BET_NUMBER_NINE = 122;
    uint8 constant BET_NUMBER_TEN = 123;
    uint8 constant BET_NUMBER_ELEVEN = 124;
    uint8 constant BET_NUMBER_TWELVE = 125;
    uint8 constant BET_NUMBER_THIRTEEN = 126;
    uint8 constant BET_NUMBER_FOURTEEN = 127;
    uint8 constant BET_NUMBER_FIVETEEN = 128;
    uint8 constant BET_NUMBER_SIXTEEN = 129;
    uint8 constant BET_NUMBER_SEVENTEEN = 130;
    uint8 constant BET_NUMBER_EIGHTTEEN = 131;
    uint8 constant BET_NUMBER_NINETEEN = 132;
    uint8 constant BET_NUMBER_TWENTY = 133;
    uint8 constant BET_NUMBER_TWENTYONE = 134;
    uint8 constant BET_NUMBER_TWENTYTWO = 135;
    uint8 constant BET_NUMBER_TWENTYTHREE = 136;
    uint8 constant BET_NUMBER_TWENTYFOUR = 137;
    uint8 constant BET_NUMBER_TWENTYFIVE = 138;
    uint8 constant BET_NUMBER_TWENTYSIX = 139;
    uint8 constant BET_NUMBER_TWENTYSEVEN = 140;
    uint8 constant BET_NUMBER_TWENTYEIGHT = 141;
    uint8 constant BET_NUMBER_TWENTYNINE = 142;
    uint8 constant BET_NUMBER_THIRTY = 143;
    uint8 constant BET_NUMBER_THIRTYONE = 144;
    uint8 constant BET_NUMBER_THIRTYTWO = 145;
    uint8 constant BET_NUMBER_THIRTYTHREE = 146;
    uint8 constant BET_NUMBER_THIRTYFOUR = 147;
    uint8 constant BET_NUMBER_THIRTYFIVE = 148;
    uint8 constant BET_NUMBER_THIRTYSIX = 149;

    //Coordinator manages subscriptions to the Chainlink VRF and verify every random number alongside its proof
    VRFCoordinatorV2Interface COORDINATOR;
    LinkTokenInterface LINKTOKEN;

    address vrfCoordinator = 0x6168499c0cFfCaCD319c818142124B7A15E857ab;
    address link_token_contract = 0x01BE23585060835E02B77ef475b0Cc51aA1e0709;
    bytes32 keyHash =
        0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc;
    uint32 callbackGasLimit = 600000;
    uint16 requestConfirmations = 3;
    uint32 numWords = 1;

    uint64 public s_subscriptionId = 5529; //storage variables
    address s_owner;
    bool private randomlink = true;
    event GotNumbers(uint256);

    //mapping(uint256 => uint256[]) public giveIdgetsWords; //give id, gets the random words
    mapping(uint256 => address) public giveIdgetsAddress; //give Id, gets address
    mapping(address => bool) public PendingForAddress; //PROBABLY NOT NEEDED .. USE IF THERE IS A BET IN THE NEXT MAPPING ?????
    //mapping(address => Results[]) public giveAddressGetResults; // should it be a mapping? or event thingy.. more like it
    mapping(address => uint256[10]) public giveAddressgetsBets;

    struct Onebet {
        uint256 betamount;
        uint8 bet_on;
    }

    /*
    struct Results {
        uint8 Number;
        Onebet[] Bets; 
        uint256 WonAmount;
    }*/

    constructor() VRFConsumerBaseV2(vrfCoordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator); //sets op coordinator, link, and sets creator as contract owner
        LINKTOKEN = LinkTokenInterface(link_token_contract);
        s_owner = msg.sender;
    }

    /* Tibet gets list of struct bets --> on what + the money */
    /* Number of plays */
    function Tibet(uint8 NumberOfPlays) external {
        require(NumberOfPlays <= 10 && NumberOfPlays > 0);
        if (!PendingForAddress[msg.sender]) {
            uint256 s_requestId = 0;
            ////THIS GIVES AN ERROR////// giveAddressgetsBets[msg.sender] = Titbets; // maybe only now, takes or asks the money for only Okay bets
            numWords = NumberOfPlays; //implement the bitch
            s_requestId = COORDINATOR.requestRandomWords(
                keyHash,
                s_subscriptionId,
                requestConfirmations,
                callbackGasLimit,
                numWords
            );
            giveIdgetsAddress[s_requestId] = msg.sender;
            PendingForAddress[msg.sender] = true;
        }
    }

    function readthepend() public view returns (bool) {
        return PendingForAddress[msg.sender];
    }

    function readtheWords() public view returns (uint256[10] memory) {
        // uint256[10] temptramp=PendingForAddress[msg.sender];
        return giveAddressgetsBets[msg.sender];
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
        internal
        override
    {
        address Address_dude = giveIdgetsAddress[requestId];

        //giveAddressgetsBets[Address_dude] = uint256[10];

        for (uint256 i = 0; i < randomWords.length; i++) {
            giveAddressgetsBets[Address_dude][i] = randomWords[i];
        }

        PendingForAddress[Address_dude] = false;

        //and gets the bets back.. check the bets he made, and resolve the shit
        //learn about gas // and learn abou testing locally.. !
        //emit GotNumbers(Address_dude, results);
    }
}