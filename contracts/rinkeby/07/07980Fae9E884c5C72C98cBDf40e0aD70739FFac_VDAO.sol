// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";

contract VDAO is VRFConsumerBaseV2, KeeperCompatibleInterface {


    event VerificationTask( address indexed verifier, uint requestId );

    Rental rentalContract;
    address rentalContractAddress;
    address owner;

    //chainlink for rinkeby
    VRFCoordinatorV2Interface COORDINATOR;
    address vrfCoordinator = 	0x6168499c0cFfCaCD319c818142124B7A15E857ab;
    bytes32 keyHash = 0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc;
    uint32 callbackGasLimit = 200000;
    uint16 requestConfirmations = 3;
    uint32 numWords =  1;
    uint64 s_subscriptionId = 6284;
    mapping( uint => uint ) chainlinkRequestIdToRequestId;

//add events

    constructor() VRFConsumerBaseV2(vrfCoordinator) {
        COORDINATOR = VRFCoordinatorV2Interface( vrfCoordinator );

        rentalContractAddress = address( 0 );
        rentalContract = Rental( rentalContractAddress );
        owner = msg.sender;
    }

    modifier onlyOwner {
        require( owner == msg.sender, "not owner" );
        _;
    }
    //only admin function to link contract in start only
    function setRentalContractAddress( address _rentalContractAddress ) external onlyOwner {
        require( rentalContractAddress == address( 0 ), "contract already set" );
        rentalContractAddress = _rentalContractAddress;
    }

    // Add the library methods
    using EnumerableSet for EnumerableSet.AddressSet;

    // Declare a set state variable
    EnumerableSet.AddressSet private activeVerifiers;
    
    uint constant VERIFIER_STAKE = 0.001 ether; 
    uint constant ANSWER_TIME = 3 minutes;
    uint constant VERIFIER_NUMBER = 3;
    uint constant PUNISHMENT = 30; //as percent of VERIFIER_STAKE constant value

    //for establishing unique randomness
    uint constant RANDOM_PRIME = 325778765244908313467197;
    uint constant MOD_OF_RANDOM = 100000000000000000000;


    enum Answer {
        NO_ANSWER,
        NOT_HARMED,
        HARMED
    }

    struct Verifier {
        address verifierAddress;
        Answer answer;
    }

    struct Request {
        string oldImageURI;
        string newImageURI;
        uint lastAnswerTime;
        bool isEnded;
        uint yesCount;
        uint noCount;
        uint rewardPool;
        uint bicycleId;
        uint randomSeed;
        Verifier[] selectedVerifiers;

    }


    mapping( address => ActiveVerifier ) public activeVerifierInfo;
    Request[] public requests;
    uint punishmentPool;
    

    struct ActiveVerifier {
        uint activeVerificationCount;
        bool activenessRequest;
        uint balance;
    } 


    function beActiveVerifier() external payable {
        address msgSender = msg.sender; //to reduce gas fees
        require(msg.value == VERIFIER_STAKE , "not enough stake" );
        require( activeVerifierInfo[ msgSender ].balance == 0, "already have balance"  );
        require( EnumerableSet.contains( activeVerifiers, msgSender ) == false, "already verifier" );
        activeVerifierInfo[ msgSender ].activenessRequest = true;
        EnumerableSet.add( activeVerifiers, msgSender );
        activeVerifierInfo[ msgSender ].balance = VERIFIER_STAKE;

    }


    function stopRequestingVerifications() external {
        address msgSender = msg.sender;
        require( EnumerableSet.contains( activeVerifiers, msgSender ), "not verifier"  );
        EnumerableSet.remove( activeVerifiers, msgSender );
        activeVerifierInfo[ msgSender ].activenessRequest = false;
    }


    function checkStopBeingVerifierAndExecute( address verifierAddress ) internal {
        
        ActiveVerifier memory verifier = activeVerifierInfo[ verifierAddress ];
        if( verifier.activenessRequest == false ) {
            if( verifier.balance > 0 && verifier.activeVerificationCount == 0 ) {
                verifier.balance = 0;
                payable( verifierAddress ).send( verifier.balance );
            
            }
        }



    }

    modifier onlyContract {
        
        require( msg.sender == rentalContractAddress, "not rental contract" );
        _;
    }


    function addRequest(
        uint bicycleId,
        string calldata _oldImageURI,
        string calldata _newImageURI
        ) external payable onlyContract {
            Request storage newRequest = requests.push();
            newRequest.oldImageURI = _oldImageURI;
            newRequest.newImageURI = _newImageURI;
            newRequest.rewardPool = msg.value;
            newRequest.bicycleId = bicycleId;

        //random verifier seç

        uint requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );

        
    chainlinkRequestIdToRequestId[ requestId ] = requests.length - 1;


    }


    function mockAddRequest(
        string calldata _oldImageURI,
        string calldata _newImageURI
        ) external payable {
            Request storage newRequest = requests.push();
            newRequest.oldImageURI = _oldImageURI;
            newRequest.newImageURI = _newImageURI;
            newRequest.rewardPool = msg.value;
            //newRequest.bicycleId = bicycleId;

        //random verifier seç

        uint requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );

        
    chainlinkRequestIdToRequestId[ requestId ] = requests.length - 1;


    }

    function getIndex( Verifier[] memory addressArray, address addressToSearch ) internal pure returns( uint ) {
        
        for( uint i = 0; i < addressArray.length; i++ ) {
            if( addressArray[ i ].verifierAddress == addressToSearch ) {
                return i;
            }
        
        }
        require( false, "not verifier in that request" );
    }
    
    //true if not harmed false if it is harmed
    function giveAnswer( uint requestId, bool answer) external {
        require( requests[ requestId ].lastAnswerTime <= block.timestamp && requests[ requestId ].lastAnswerTime != 0, "time has not come yet" );
        address msgSender = msg.sender;
        uint index = getIndex( requests[ requestId ].selectedVerifiers, msgSender );
        if( answer == true ) {
            ++requests[ requestId ].yesCount;
            requests[ requestId ].selectedVerifiers[index].answer = Answer.NOT_HARMED;
        } else {
            ++requests[ requestId ].noCount;
            requests[ requestId ].selectedVerifiers[index].answer = Answer.HARMED;
        }

    }


    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {
        
        uint VDAORequestId = chainlinkRequestIdToRequestId[ requestId ];
        requests[ VDAORequestId ].randomSeed = randomWords[0] % MOD_OF_RANDOM;

 
  }

    function selectVerifiers( uint randomSeed, uint index ) internal {
        uint setLength = EnumerableSet.length( activeVerifiers );



        for( uint i = 0; i < VERIFIER_NUMBER; i++ ) {
            uint randomIndex = ( i * RANDOM_PRIME + randomSeed ) % setLength;
            address addedVerifierAddress = EnumerableSet.at( activeVerifiers, randomIndex );
            Verifier storage verifier = requests[index].selectedVerifiers.push();
            verifier.verifierAddress = addedVerifierAddress;
            emit VerificationTask( addedVerifierAddress, index );
            ++activeVerifierInfo[ addedVerifierAddress ].activeVerificationCount;          
        }            
        

        
    }

    function fetchVerifierAddresses( uint index ) external view returns( Verifier[] memory ) {
        return requests[index].selectedVerifiers;
    }

//EDIT
    function endRequest( uint requstIndex ) public {
        Request memory request = requests[ requstIndex ];
        Request storage requestToChange = requests[ requstIndex ];
        Verifier[] memory verifiers = request.selectedVerifiers;
        require( request.isEnded == false, "request already ended" );
        require( request.lastAnswerTime <= block.timestamp && request.lastAnswerTime != 0, "time has not come yet" );
        requestToChange.isEnded = true;
        Answer result;
        uint trueAnswerCount;

        if( request.yesCount > request.noCount ) {
            result = Answer.NOT_HARMED;
            trueAnswerCount = request.yesCount;
        } else {
            result = Answer.HARMED;
            trueAnswerCount = request.noCount;
        }
        uint toBeAddedToPunishmentPool;
        uint currentPunishmentPool = request.rewardPool;
        uint removedFromPunishmentPool;
        uint rewardPool = request.rewardPool;
        for( uint i = 0; i < verifiers.length; i++ ) {

            address currentAddress = verifiers[i].verifierAddress;
            --activeVerifierInfo[ currentAddress ].activeVerificationCount;
            if(verifiers[i].answer == result) {
                uint balanceToAdd;
                balanceToAdd += rewardPool / trueAnswerCount;
                balanceToAdd += currentPunishmentPool / trueAnswerCount;
                removedFromPunishmentPool += currentPunishmentPool / trueAnswerCount;

                activeVerifierInfo[ currentAddress ].balance += balanceToAdd;
            } else {
                uint punishment = VERIFIER_STAKE * PUNISHMENT / 100 / (VERIFIER_NUMBER - trueAnswerCount);
                uint balanceValue = activeVerifierInfo[ currentAddress ].balance;
                if( punishment > balanceValue ) {
                    punishment = balanceValue;
                }
                activeVerifierInfo[ currentAddress ].balance -= punishment;
                toBeAddedToPunishmentPool += punishment;
            }

            checkStopBeingVerifierAndExecute( currentAddress );
        }

        punishmentPool = currentPunishmentPool + toBeAddedToPunishmentPool - removedFromPunishmentPool;
        
        if( result == Answer.NOT_HARMED ) {
            rentalContract.transferDeposit( request.bicycleId, true );
        } else {
            rentalContract.transferDeposit( request.bicycleId, false );
        }

        

//run constructor
//keeper ekle
        
    }

        function mockEndRequest( uint requstIndex ) public {
        Request memory request = requests[ requstIndex ];
        Request storage requestToChange = requests[ requstIndex ];
        Verifier[] memory verifiers = request.selectedVerifiers;
        require( request.isEnded == false, "request already ended" );
        require( request.lastAnswerTime <= block.timestamp && request.lastAnswerTime != 0, "time has not come yet" );
        requestToChange.isEnded = true;
        Answer result;
        uint trueAnswerCount;

        if( request.yesCount > request.noCount ) {
            result = Answer.NOT_HARMED;
            trueAnswerCount = request.yesCount;
        } else {
            result = Answer.HARMED;
            trueAnswerCount = request.noCount;
        }
        uint toBeAddedToPunishmentPool;
        uint currentPunishmentPool = request.rewardPool;
        uint removedFromPunishmentPool;
        uint rewardPool = request.rewardPool;
        for( uint i = 0; i < verifiers.length; i++ ) {

            address currentAddress = verifiers[i].verifierAddress;
            --activeVerifierInfo[ currentAddress ].activeVerificationCount;
            if(verifiers[i].answer == result) {
                uint balanceToAdd;
                balanceToAdd += rewardPool / trueAnswerCount;
                balanceToAdd += currentPunishmentPool / trueAnswerCount;
                removedFromPunishmentPool += currentPunishmentPool / trueAnswerCount;

                activeVerifierInfo[ currentAddress ].balance += balanceToAdd;
            } else {
                uint punishment = VERIFIER_STAKE * PUNISHMENT / 100 / (VERIFIER_NUMBER - trueAnswerCount);
                uint balanceValue = activeVerifierInfo[ currentAddress ].balance;
                if( punishment > balanceValue ) {
                    punishment = balanceValue;
                }
                activeVerifierInfo[ currentAddress ].balance -= punishment;
                toBeAddedToPunishmentPool += punishment;
            }

            checkStopBeingVerifierAndExecute( currentAddress );
        }

        punishmentPool = currentPunishmentPool + toBeAddedToPunishmentPool - removedFromPunishmentPool;
        


        

//run constructor
//keeper ekle
        
    }


function bytesToUint(bytes memory b) internal pure returns (uint){
        uint number;
        for(uint i=0;i<b.length;i++){
            number = number + uint(uint8(b[i]))*(2**(8*(b.length-(i+1))));
        }
    return number;
}


function checkUpkeep(bytes calldata /* checkData */) external view override returns (bool upkeepNeeded, bytes memory performData ) {
        upkeepNeeded = false;
        for( uint i = 0; i < requests.length; i++ ) {
            Request memory request = requests[ i ];

            if( (request.isEnded == false && request.lastAnswerTime <= block.timestamp && request.lastAnswerTime != 0) || (request.lastAnswerTime == 0 && request.randomSeed != 0) ) {
                upkeepNeeded = true;
                performData = new bytes(32);
                assembly { mstore(add(performData, 32), i) }
                break;
            }
        } 
    }

function performUpkeep(bytes calldata performData) external override {
     uint requestIndex = bytesToUint( performData );
     Request memory request = requests[ requestIndex ];
        if( request.isEnded == false && request.lastAnswerTime <= block.timestamp && request.lastAnswerTime != 0 ) {
            mockEndRequest( requestIndex );
        }
        if( request.lastAnswerTime == 0 && request.randomSeed != 0 ) {
        selectVerifiers( request.randomSeed, requestIndex );
        requests[ requestIndex ].lastAnswerTime = block.timestamp + ANSWER_TIME;
        }
     
    }

function viewAllActiveVerifiers() external view returns ( address[] memory ) {
    return EnumerableSet.values( activeVerifiers );
}




}

interface Rental {
    function transferDeposit(uint bicycleId, bool result ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./KeeperBase.sol";
import "./interfaces/KeeperCompatibleInterface.sol";

abstract contract KeeperCompatible is KeeperBase, KeeperCompatibleInterface {}

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface KeeperCompatibleInterface {
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract KeeperBase {
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