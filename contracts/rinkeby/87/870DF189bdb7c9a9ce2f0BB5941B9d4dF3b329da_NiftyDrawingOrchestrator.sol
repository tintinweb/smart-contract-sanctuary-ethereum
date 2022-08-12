// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

//                ,|||||<              ~|||||'         `_+7ykKD%RDqmI*~`          
//                [email protected]@@@@@8'           `[email protected]@@@@`     `^[email protected]@@@@@@@@@@@@@@@@R|`       
//               [email protected]@@@@@@@Q;          [email protected]@@@@J    '}[email protected]@@@@@[email protected]@@@@@@Q,      
//               [email protected]@@@@@@@@@j        `[email protected]@@@Q`  `[email protected]@@@@@h^`         `[email protected]@@@@*      
//              [email protected]@@@@@@@@@@@D.      [email protected]@@@@i  [email protected]@@@@w'              ^@@@@@*      
//              [email protected]@@@@[email protected]@@@@@@Q!    `@@@@@Q  ;@@@@@@;                .txxxx:      
//             |@@@@@u *@@@@@@@@z   [email protected]@@@@* `[email protected]@@@@^                              
//            `[email protected]@@@Q`  '[email protected]@@@@@@R.'@@@@@B  [email protected]@@@@%        :DDDDDDDDDDDDDD5       
//            [email protected]@@@@7    `[email protected]@@@@@@[email protected]@@@@+  [email protected]@@@@K        [email protected]@@@@@@*       
//           `@@@@@Q`      ^[email protected]@@@@@@@@@@W   [email protected]@@@@@;             ,[email protected]@@@@@#        
//           [email protected]@@@@L        ,[email protected]@@@@@@@@@!   '[email protected]@@@@@u,        [email protected]@@@@@@@^        
//          [email protected]@@@@Q           }@@@@@@@@D     '[email protected]@@@@@@@gUwwU%[email protected]@@@@@@@@@g         
//          [email protected]@@@@<            [email protected]@@@@@@;       ;[email protected]@@@@@@@@@@@@@@Wf;[email protected]@@;         
//          ~;;;;;              .;;;;;~           '!Lx5mEEmyt|!'    ;;;~          
//
// Powered By:    @niftygateway
// Author:        @niftynathang

import "../interfaces/INiftyDrawing.sol";
import "../interfaces/INiftyEntityCloneable.sol";
import "../libraries/Clones.sol";
import "../structs/DrawingResult.sol";
import "../utils/NiftyPermissions.sol";

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

contract NiftyDrawingOrchestrator is NiftyPermissions, VRFConsumerBaseV2 {
    
    event ClonedNiftyDrawing(address newToken);        

    VRFCoordinatorV2Interface COORDINATOR;

    mapping (bytes32 => address) public nftContractAndNiftyTypeToDrawingLookup;
    mapping (uint256 => address) public requestDrawingLookup;
    mapping (address => uint256) public drawingRequestLookup;
    
    constructor(address niftyRegistryContract_, address vrfCoordinator_)
    VRFConsumerBaseV2(vrfCoordinator_) {
        initializeNiftyEntity(niftyRegistryContract_);
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator_);
    }   

    function requestRandomNumberForDrawing(uint64 subscriptionId_, address nftContract_, uint256 niftyType_, bytes32 keyHash_) external {
        _requireOnlyValidSender();

        address drawingContractAddress = locateDrawing(nftContract_, niftyType_);
        require(drawingContractAddress != address(0), "No drawing contract found");
        require(drawingRequestLookup[drawingContractAddress] == 0, "Request already scheduled");
        
        uint256 requestId = COORDINATOR.requestRandomWords(
            keyHash_,
            subscriptionId_,
            25, // Request Confirmations
            200000, // Callback Gas Limit
            1 // Num Random Words
        );

        requestDrawingLookup[requestId] = drawingContractAddress;
        drawingRequestLookup[drawingContractAddress] == requestId;
    }  
        
    function createNiftyDrawing(
        address implementation, 
        address niftyRegistryContract_, 
        address nftContract_, 
        uint256 niftyType_, 
        uint256 numberOfEntries_, 
        uint256 prizeTokenIdBegin_, 
        uint256 prizeTokenIdEnd_) external returns (address) {

        _requireOnlyValidSender();
        require(IERC165(implementation).supportsInterface(type(INiftyDrawing).interfaceId), "Not a valid Nifty Drawing");        
        require(IERC165(implementation).supportsInterface(type(INiftyEntityCloneable).interfaceId), "Not a valid Nifty Drawing");

        bytes32 hashOfContractAndNiftyType = keccak256(abi.encodePacked(nftContract_, niftyType_));
        require(nftContractAndNiftyTypeToDrawingLookup[hashOfContractAndNiftyType] == address(0), "Drawing already created");

        address clone = Clones.clone(implementation);
        nftContractAndNiftyTypeToDrawingLookup[hashOfContractAndNiftyType] = clone;
        emit ClonedNiftyDrawing(clone);

        INiftyEntityCloneable(clone).initializeNiftyEntity(niftyRegistryContract_);
        INiftyDrawing(clone).initializeDrawing(address(this), nftContract_, niftyType_, numberOfEntries_, prizeTokenIdBegin_, prizeTokenIdEnd_);

        return clone;
    }

    function listWinners(address nftContract_, uint256 niftyType_) public view returns (DrawingResult[] memory) {
        address drawingContractAddress = locateDrawing(nftContract_, niftyType_);
        require(drawingContractAddress != address(0), "No drawing contract found");        
        INiftyDrawing drawingContract = INiftyDrawing(drawingContractAddress);
        return drawingContract.listWinners();        
    }

    function locateDrawing(address nftContract_, uint256 niftyType_) public view returns (address) {
        bytes32 hashOfContractAndNiftyType = keccak256(abi.encodePacked(nftContract_, niftyType_));        
        return nftContractAndNiftyTypeToDrawingLookup[hashOfContractAndNiftyType];        
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        require(requestDrawingLookup[requestId] != address(0));
        INiftyDrawing drawingContract = INiftyDrawing(requestDrawingLookup[requestId]);
        drawingContract.onDrawingRandomnessFulfilled(randomWords[0]);
    } 
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./IERC165.sol";
import "../structs/DrawingResult.sol";

interface INiftyDrawing is IERC165 {    
    function initializeDrawing(
        address drawingOrchestrator_,
        address nftContract_,
        uint256 niftyType_,
        uint256 numberOfEntries_, 
        uint256 prizeTokenIdBegin_, 
        uint256 prizeTokenIdEnd_) external;

    function onDrawingRandomnessFulfilled(uint256 randomWord_) external;
    function listWinners() external view returns (DrawingResult[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./IERC165.sol";

interface INiftyEntityCloneable is IERC165 {
    function initializeNiftyEntity(address niftyRegistryContract_) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

struct DrawingResult {
    uint256 ticketNumber;
    uint256 tokenId;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./ERC165.sol";
import "./GenericErrors.sol";
import "../interfaces/INiftyEntityCloneable.sol";
import "../interfaces/INiftyRegistry.sol";
import "../libraries/Context.sol";

abstract contract NiftyPermissions is Context, ERC165, GenericErrors, INiftyEntityCloneable {    

    event AdminTransferred(address indexed previousAdmin, address indexed newAdmin);

    // Only allow Nifty Entity to be initialized once
    bool internal initializedNiftyEntity;

    // If address(0), use enable Nifty Gateway permissions - otherwise, specifies the address with permissions
    address public admin;

    // To prevent a mistake, transferring admin rights will be a two step process
    // First, the current admin nominates a new admin
    // Second, the nominee accepts admin
    address public nominatedAdmin;

    // Nifty Registry Contract
    INiftyRegistry internal permissionsRegistry;    

    function initializeNiftyEntity(address niftyRegistryContract_) public {
        require(!initializedNiftyEntity, ERROR_REINITIALIZATION_NOT_PERMITTED);
        permissionsRegistry = INiftyRegistry(niftyRegistryContract_);
        initializedNiftyEntity = true;
    }       
    
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return         
        interfaceId == type(INiftyEntityCloneable).interfaceId ||
        super.supportsInterface(interfaceId);
    }        

    function renounceAdmin() external {
        _requireOnlyValidSender();
        _transferAdmin(address(0));
    }    

    function nominateAdmin(address nominee) external {
        _requireOnlyValidSender();
        nominatedAdmin = nominee;
    }

    function acceptAdmin() external {
        address nominee = nominatedAdmin;
        require(_msgSender() == nominee, ERROR_INVALID_MSG_SENDER);
        _transferAdmin(nominee);
    }
    
    function _requireOnlyValidSender() internal view {       
        address currentAdmin = admin;     
        if(currentAdmin == address(0)) {
            require(permissionsRegistry.isValidNiftySender(_msgSender()), ERROR_INVALID_MSG_SENDER);
        } else {
            require(_msgSender() == currentAdmin, ERROR_INVALID_MSG_SENDER);
        }
    }        

    function _transferAdmin(address newAdmin) internal {
        address oldAdmin = admin;
        admin = newAdmin;
        delete nominatedAdmin;        
        emit AdminTransferred(oldAdmin, newAdmin);
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

pragma solidity 0.8.9;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../interfaces/IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

abstract contract GenericErrors {
    string internal constant ERROR_INPUT_ARRAY_EMPTY = "Input array empty";
    string internal constant ERROR_INPUT_ARRAY_SIZE_MISMATCH = "Input array size mismatch";
    string internal constant ERROR_INVALID_MSG_SENDER = "Invalid msg.sender";
    string internal constant ERROR_UNEXPECTED_DATA_SIGNER = "Unexpected data signer";
    string internal constant ERROR_INSUFFICIENT_BALANCE = "Insufficient balance";
    string internal constant ERROR_WITHDRAW_UNSUCCESSFUL = "Withdraw unsuccessful";
    string internal constant ERROR_CONTRACT_IS_FINALIZED = "Contract is finalized";
    string internal constant ERROR_CANNOT_CHANGE_DEFAULT_OWNER = "Cannot change default owner";
    string internal constant ERROR_UNCLONEABLE_REFERENCE_CONTRACT = "Uncloneable reference contract";
    string internal constant ERROR_BIPS_OVER_100_PERCENT = "Bips over 100%";
    string internal constant ERROR_NO_ROYALTY_RECEIVER = "No royalty receiver";
    string internal constant ERROR_REINITIALIZATION_NOT_PERMITTED = "Re-initialization not permitted";
    string internal constant ERROR_ZERO_ETH_TRANSFER = "Zero ETH Transfer";
    string internal constant ERROR_IPFS_HASH_ALREADY_SET = "IPFS hash already set";
    string internal constant ERROR_INVALID_METADATA_GENERATOR = "Invalid Metadata Generator";
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface INiftyRegistry {
   function isValidNiftySender(address sendingKey) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

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