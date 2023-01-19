// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ConfirmedOwnerWithProposal.sol";

/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwner is ConfirmedOwnerWithProposal {
  constructor(address newOwner) ConfirmedOwnerWithProposal(newOwner, address(0)) {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/OwnableInterface.sol";

/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwnerWithProposal is OwnableInterface {
  address private s_owner;
  address private s_pendingOwner;

  event OwnershipTransferRequested(address indexed from, address indexed to);
  event OwnershipTransferred(address indexed from, address indexed to);

  constructor(address newOwner, address pendingOwner) {
    require(newOwner != address(0), "Cannot set owner to zero");

    s_owner = newOwner;
    if (pendingOwner != address(0)) {
      _transferOwnership(pendingOwner);
    }
  }

  /**
   * @notice Allows an owner to begin transferring ownership to a new address,
   * pending.
   */
  function transferOwnership(address to) public override onlyOwner {
    _transferOwnership(to);
  }

  /**
   * @notice Allows an ownership transfer to be completed by the recipient.
   */
  function acceptOwnership() external override {
    require(msg.sender == s_pendingOwner, "Must be proposed owner");

    address oldOwner = s_owner;
    s_owner = msg.sender;
    s_pendingOwner = address(0);

    emit OwnershipTransferred(oldOwner, msg.sender);
  }

  /**
   * @notice Get the current owner
   */
  function owner() public view override returns (address) {
    return s_owner;
  }

  /**
   * @notice validate, transfer ownership, and emit relevant events
   */
  function _transferOwnership(address to) private {
    require(to != msg.sender, "Cannot transfer to self");

    s_pendingOwner = to;

    emit OwnershipTransferRequested(s_owner, to);
  }

  /**
   * @notice validate access
   */
  function _validateOwnership() internal view {
    require(msg.sender == s_owner, "Only callable by owner");
  }

  /**
   * @notice Reverts if called by anyone other than the contract owner.
   */
  modifier onlyOwner() {
    _validateOwnership();
    _;
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

interface OwnableInterface {
  function owner() external returns (address);

  function transferOwnership(address recipient) external;

  function acceptOwnership() external;
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
pragma solidity 0.8.13;

/// @dev Interface for ERC721Like
interface ERC721Like {
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function setApprovalForAll(address operator, bool approved) external;
    
    function totalSupply() external returns (uint256);

}

/// @dev Interface for NounsVisionBatchTransfer
interface INFTBatchTransfer {
    function getStartId(ERC721Like nftAddress, uint256 suggStartId) external view returns (uint256 startId);

    function getStartIdAndBatchAmount(address receiver, uint256 suggStartId) external
        returns (uint256 startId, uint256 amount);

    function claimNFTs(uint256 startId, uint256 amount) external;

    function sendNFTs(ERC721Like nftAddress, uint256 startId, address recipient) external;

    function sendManyNFTs(ERC721Like nftAddress, uint256 startId, address[] calldata recipients) external;

    function allowanceFor(address nftAddress, address receiver) external view
        returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

struct ProposalCondensed {
        /// @notice Unique id for looking up a proposal
        uint256 id;
        /// @notice Creator of the proposal
        address proposer;
        /// @notice The number of votes needed to create a proposal at the time of proposal creation. *DIFFERS from GovernerBravo
        uint256 proposalThreshold;
        /// @notice The minimum number of votes in support of a proposal required in order for a quorum to be reached and for a vote to succeed at the time of proposal creation. *DIFFERS from GovernerBravo
        uint256 quorumVotes;
        /// @notice The timestamp that the proposal will be available for execution, set once the vote succeeds
        uint256 eta;
        /// @notice The block at which voting begins: holders must delegate their votes prior to this block
        uint256 startBlock;
        /// @notice The block at which voting ends: votes must be cast prior to this block
        uint256 endBlock;
        /// @notice Current number of votes in favor of this proposal
        uint256 forVotes;
        /// @notice Current number of votes in opposition to this proposal
        uint256 againstVotes;
        /// @notice Current number of votes for abstaining for this proposal
        uint256 abstainVotes;
        /// @notice Flag marking whether the proposal has been canceled
        bool canceled;
        /// @notice Flag marking whether the proposal has been vetoed
        bool vetoed;
        /// @notice Flag marking whether the proposal has been executed
        bool executed;
        /// @notice The total supply at the time of proposal creation
        uint256 totalSupply;
        /// @notice The block at which this proposal was created
        uint256 creationBlock;
}

/// @dev Interface for ERC721Like
interface INounsDAOProxy {

        function proposals(uint256 proposalId) external view returns (ProposalCondensed memory);

        function getActions(uint256 proposalId)
            external
            view
            returns (
                address[] memory targets,
                uint256[] memory values,
                string[] memory signatures,
                bytes[] memory calldatas
            );

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./VRFv2Consumer.sol";
import "./INFTBatchTransfer.sol";
import "./INounsDAOProxy.sol";

// crafted with ❤️ by @0xDigitalOil for Nouns DAO ⌐◨-◨
contract NFTVRFDistributor is VRFv2Consumer {
    
    /**
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
      EVENTS
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
    **/

    /// @dev Event log for when a round is requested
    /// @param requestId request id generated by Chainlink
    /// @param nftAddress address of the NFT collection being distributed
    event RoundRequested(uint256 requestId, address nftAddress);

    /// @dev Event log for when a round is fulfilled
    /// @param nftAddress address of the NFT collection being distributed
    /// @param roundId id of the claimRound
    /// @param numberWon number of NFTs claimable in this round
    /// @param randomness block at which the claim ends    
    event RoundFulfilled(address nftAddress, uint8 roundId, uint8 numberWon, uint152 randomness);

    /// @dev Event log for when a round is requested
    /// @param nftAddress address of the NFT collection being distributed
    /// @param roundId id of the claimRound
    /// @param index claimed NFTs index (in the claim round's context)
    /// @param winner address that claimed the NFTs
    event NFTClaimed(address nftAddress, uint8 roundId, uint8 index, address winner);    


    /**
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
      CONSTANTS & IMMUTABLE
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
    **/

    ERC721Like public constant NOUNS_TOKEN =
        ERC721Like(0x312a72C4Fc5E4Ea9D9ae0d21739130B9CF2758aC);       

    INounsDAOProxy public constant NOUNS_DAO_PROXY = 
        INounsDAOProxy(0x7A1BF7E1f799151Fb60eCdb9290e907c73e6F67C);

    INFTBatchTransfer public immutable NFT_BATCH_TRANSFER;       
    

    uint256 public constant CLAIM_WINDOW = 108_000; // 15 days in blocks

 
    /**
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
      STRUCTS & STORAGE VARIABLES
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
    **/

    struct ClaimRound {
        uint8 id;
        uint8 numberWon;
        uint8 numberClaimed;
        uint16 nounSupply;
        uint32 startBlock;
        uint32 endBlock;
        uint152 randomness;
        uint256 claimedBitmap;
    } 

    mapping (address => ClaimRound[]) public claimRounds;
    mapping (address => uint8) public currentRounds;

    mapping (uint256 => address) requestIdToNFT;
    mapping (uint256 => uint24) requestIdToPropId;
    mapping (uint256 => bool) requestIdToDynamic;  
    mapping (uint24 => bool) servedProp;  

    /**
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
      ERRORS
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
    **/

    error AvailNFTsZero();   
    error ClaimPeriodNotFinished(); 
    error NoClaimRoundsOpen();
    error OnlyTokenOwnerCanClaim();
    error InvalidIndex();
    error InvalidRound();
    error ClaimPeriodEnded();
    error AlreadyClaimed();    
    error RoundIsTooBig(); // maximum round size is 256 NFTs
    error MustHaveAtLeastOneWinner();
    error PropIdMismatch();
    error CantReplayProp();

    /**
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
      CONSTRUCTOR
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
    **/

    constructor(uint64 subscriptionId, INFTBatchTransfer batchTransferAddress) VRFv2Consumer(subscriptionId) {
      NFT_BATCH_TRANSFER = batchTransferAddress;
    }    

    /**
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
      INTERNAL FUNCTIONS
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
    **/

    /// @notice Receives randomness; determines which wallets and quantities will have claimable NFTs. The more tokens are in the wallet, the more likely it is that it will get each individual NFTs awarded.
    /// @param _requestId Id of the VRF request
    /// @param _randomWords array of random numbers returned from VRF
    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override {

        super.fulfillRandomWords(_requestId, _randomWords);

        address nftAddress = requestIdToNFT[_requestId];
        uint24 propId = requestIdToPropId[_requestId];
        bool isDynamicDistribution = requestIdToDynamic[_requestId];
        uint8 currentRound = currentRounds[nftAddress];

        if ((claimRounds[nftAddress].length > 0) && (block.number <= claimRounds[nftAddress][currentRound].endBlock)) {
          revert ClaimPeriodNotFinished();
        }        

        uint256 availNFTs = remainingAllowance(nftAddress);
        if (availNFTs > 256) {
          revert RoundIsTooBig();
        }

        if (availNFTs == 0) {
          revert AvailNFTsZero(); 
        }     

        if (claimRounds[nftAddress].length > 0) {
          currentRound++;
        }
        claimRounds[nftAddress].push();
        ClaimRound storage round = claimRounds[nftAddress][currentRound];
        round.id = currentRound;
        round.startBlock = uint32(block.number);
        round.endBlock = uint32(block.number + CLAIM_WINDOW);
        uint256 nounSupply = NOUNS_TOKEN.totalSupply();
        round.nounSupply = uint16(nounSupply);     
        if (isDynamicDistribution) {
          ProposalCondensed memory proposal = NOUNS_DAO_PROXY.proposals(propId);
          round.numberWon = calcNumWinners(nounSupply, proposal.forVotes, proposal.againstVotes, proposal.abstainVotes, availNFTs);
        }
        else {
          round.numberWon = uint8(availNFTs);   
        }
        round.randomness = uint152(_randomWords[0]);

        emit RoundFulfilled(nftAddress, currentRound, uint8(availNFTs), uint152(_randomWords[0]));

    }

    function _isClaimed(address nftAddress, uint8 index) internal view returns (bool) {
        uint8 currentRound = currentRounds[nftAddress];
        return claimRounds[nftAddress][currentRound].claimedBitmap & 1 << index != 0;
    }

    function _setClaimed(address nftAddress, uint8 index) internal {
        uint8 currentRound = currentRounds[nftAddress];
        claimRounds[nftAddress][currentRound].claimedBitmap |= 1 << index;
    }  

    function calcNumWinners(uint256 nounSupply, uint256 forVotes, uint256 againstVotes, uint256 abstainVotes, uint256 maxWinners) internal pure returns (uint8) {
        // PENDING: implement this        
        return uint8((forVotes + againstVotes + abstainVotes) / nounSupply * maxWinners);
    }  

    function findTargetId(address[] memory targets) internal view returns (uint256) {
        for (uint256 i; i < targets.length; i++) {
          if (targets[i] == address(this)) {
            return (i+1);
          }
        }
        return 0;
    }

    function compareProps(uint24 propId) internal view {
        (
          address[] memory targets, 
          uint256[] memory values,
          string[] memory signatures,
          bytes[] memory calldatas
        ) = NOUNS_DAO_PROXY.getActions(propId);

        if (targets.length == 0) {
          revert PropIdMismatch();
        }
        
        uint256 targetId = findTargetId(targets);
        if (targetId == 0) {
          revert PropIdMismatch();
        }
        targetId--;

        if (values[targetId] > 0) {
          revert PropIdMismatch();
        }

        if (keccak256(abi.encodePacked((signatures[targetId]))) != keccak256(abi.encodePacked(("requestRound(address,uint24,bool)")))) {
          revert PropIdMismatch();
        }

        if (keccak256(abi.encodePacked(msg.data)) != keccak256(abi.encodePacked(calldatas[targetId]))) {
          revert PropIdMismatch();
        }      
    }

    /**
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
      PUBLIC & EXTERNAL VIEW FUNCTIONS
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
    **/

    /// @notice Get number of claimed NFTs per round
    /// @param round round number
    function numberClaimedNFTs(address nftAddress, uint256 round) external view returns (uint256) {
      return (claimRounds[nftAddress].length > 0) ? claimRounds[nftAddress][round].numberClaimed : 0;
    }

    /// @notice Get remaining NFTs allowance for this contract
    /// @param nftAddress address of NFT collection
    function remainingAllowance(address nftAddress) public view returns (uint256) {    
      return NFT_BATCH_TRANSFER.allowanceFor(nftAddress, address(this));
    }

    /// @notice Get remaining claimable number of NFTs this round. First check if this contract's allowance was taken away and in this case, return 0.
    function remainingClaimableCurrentRound(address nftAddress) external view returns (uint256) { 
      uint8 currentRound = currentRounds[nftAddress];
      if (remainingAllowance(nftAddress) == 0) {
        return 0;
      }   
      else if ((claimRounds[nftAddress].length > 0) && block.number <= claimRounds[nftAddress][currentRound].endBlock) {
        return claimRounds[nftAddress][currentRound].numberWon - claimRounds[nftAddress][currentRound].numberClaimed;
      }
      else {
        return 0;
      }
    }

    /// @notice Expired NFTs that were not claimed in the last expired round. 
    function expiredNFTsLastRound(address nftAddress) public view returns (uint256) { 
      uint8 currentRound = currentRounds[nftAddress];    
      if ((claimRounds[nftAddress].length > 0) && block.number > claimRounds[nftAddress][currentRound].endBlock) {
        return claimRounds[nftAddress][currentRound].numberWon - claimRounds[nftAddress][currentRound].numberClaimed;
      }
      else if ((claimRounds[nftAddress].length > 1) && block.number <= claimRounds[nftAddress][currentRound].endBlock) { // Current round still alive but previous round exists
        return claimRounds[nftAddress][currentRound-1].numberWon - claimRounds[nftAddress][currentRound-1].numberClaimed;
      }
      else {
        return 0;
      }
    }   

    /// @notice Returns number of NFTs that should be allocated for new round taking into account current allowance and number of NFTs desired to distributed in new round. If there is a round currently open, will return 0.
    /// @param numberToDistribute the number of NFTs looking to distribute
    function additionalAllowanceRequiredFor(address nftAddress, uint256 numberToDistribute) external view returns (uint256) { 
      uint8 currentRound = currentRounds[nftAddress];       
      if ((claimRounds[nftAddress].length == 0) || (block.number > claimRounds[nftAddress][currentRound].endBlock)) {
        return (numberToDistribute >= remainingAllowance(nftAddress)) ? (numberToDistribute - remainingAllowance(nftAddress)) : 0;
      }
      else {
        return 0;
      }
    }

    /// @notice Returns number of NFTs that are claimable by an address
    /// @param receiver address that would claim NFTs
    function claimableNFTs(address nftAddress, address receiver) external view returns (uint256 numNFTs) {    
      uint8 currentRound = currentRounds[nftAddress];
      // First check if there is a current claim round open
      if ((claimRounds[nftAddress].length == 0) || (block.number > claimRounds[nftAddress][currentRound].endBlock)) {
        return 0;
      }

      ClaimRound memory round = claimRounds[nftAddress][currentRound];

      for (uint8 i = 0; i < round.numberWon; ) {
            if (_isClaimed(nftAddress, i)) {
                continue;
            }

            if (receiver == NOUNS_TOKEN.ownerOf(uint256(keccak256(abi.encode(round.randomness, i))) % round.nounSupply)) {
                numNFTs++;
            }

            unchecked {
                ++i;
            }
      }
    }      

    /// @notice Returns remaining number of blocks until current claim period expires
    function blocksUntilClaimExpires(address nftAddress) external view returns (uint256) 
    {        
      uint8 currentRound = currentRounds[nftAddress];
      if ((claimRounds[nftAddress].length == 0) || (block.number > claimRounds[nftAddress][currentRound].endBlock)) {
        return 0;
      }

      return claimRounds[nftAddress][currentRound].endBlock + 1 - block.number; // adding one because expiry will be the block after endBlock
    }

    /**
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
      PUBLIC & EXTERNAL FUNCTIONS
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
    **/


    /// @notice Request randomness for a new glasses distribution round
    /// @param nftAddress address of the NFT collection being distributed
    /// @param propId id of the prop that corresponds to this distribution round
    /// @param isDynamicDistribution Informs if the NFTs are to be distributed dynamically according to the number of for votes. Any non-zero value indicates 'yes'
    function requestRound(address nftAddress, uint24 propId, bool isDynamicDistribution) external onlyOwner returns (uint256 requestId) {
        uint256 availNFTs = remainingAllowance(nftAddress);
        if (availNFTs > 256) {
          revert RoundIsTooBig();
        }

        // Prevent replay attack
        if (servedProp[propId]) {
          revert CantReplayProp();
        }        

        // Verify prop being executed corresponds to propId in calldata
        compareProps(propId);
        servedProp[propId] = true;

        requestId = requestRandomWords();
        requestIdToNFT[requestId] = nftAddress;
        requestIdToPropId[requestId] = propId;
        requestIdToDynamic[requestId] = isDynamicDistribution;

        emit RoundRequested(requestId, nftAddress);
    }

    /// @notice Claim NFTs
    /// @param nftAddress address of the NFT being claimed
    /// @param index The winning index
    /// @param suggStartId Option to save gas by suggesting a starting search point for the NFT startId. Optionally, could be set to zero.
    function claim(address nftAddress, uint8 index, uint256 suggStartId) external {
        uint8 currentRound = currentRounds[nftAddress];
        ClaimRound memory round = claimRounds[nftAddress][currentRound];
        if (round.randomness == 0) {
            revert InvalidRound();
        }
        if (index >= round.numberWon) {
            revert InvalidIndex();
        }
        if (block.number > round.endBlock) {
            revert ClaimPeriodEnded();
        }
        if (_isClaimed(nftAddress, index)) {
            revert AlreadyClaimed();
        }

        uint256 startId = NFT_BATCH_TRANSFER.getStartId(ERC721Like(nftAddress), suggStartId);

        address owner = NOUNS_TOKEN.ownerOf(
            uint256(keccak256(abi.encode(round.randomness, index))) % round.nounSupply
        );
        if (msg.sender != owner) {
            revert OnlyTokenOwnerCanClaim();
        }

        _setClaimed(nftAddress, index);

        NFT_BATCH_TRANSFER.sendNFTs(ERC721Like(nftAddress), startId, owner);

        emit NFTClaimed(nftAddress, currentRound, index, owner);
    }

    /// @notice Claim many NFTs
    /// @param nftAddress address of the NFT being claimed
    /// @param indexes The winning indexes
    /// @param suggStartId Option to save gas by suggesting a starting search point for the NFT startId. Optionally, could be set to zero.
    function claimMany(address nftAddress, uint8[] calldata indexes, uint256 suggStartId) external {
        uint8 currentRound = currentRounds[nftAddress];
        ClaimRound memory round = claimRounds[nftAddress][currentRound];
        if (round.randomness == 0) {
            revert InvalidRound();
        }
        if (block.number > round.endBlock) {
            revert ClaimPeriodEnded();
        }

        // It is assumed that this contract has a sufficient allowance
        uint256 startId = NFT_BATCH_TRANSFER.getStartId(ERC721Like(nftAddress), suggStartId);

        uint256 indexCount = indexes.length;
        address[] memory recipients = new address[](indexCount);
        for (uint256 i = 0; i < indexCount; ) {
            uint8 index = indexes[i];
            if (index >= round.numberWon) {
                revert InvalidIndex();
            }
            if (_isClaimed(nftAddress, index)) {
                revert AlreadyClaimed();
            }

            recipients[i] = NOUNS_TOKEN.ownerOf(
                uint256(keccak256(abi.encode(round.randomness, index))) % round.nounSupply
            );
            if (msg.sender != recipients[i]) {
                revert OnlyTokenOwnerCanClaim();
            }

            _setClaimed(nftAddress, index);

            emit NFTClaimed(nftAddress, currentRound, index, recipients[i]);

            unchecked {
                ++i;
            }
        }
        NFT_BATCH_TRANSFER.sendManyNFTs(ERC721Like(nftAddress), startId, recipients);
    }

   
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";

contract VRFv2Consumer is VRFConsumerBaseV2, ConfirmedOwner {
    event RequestSent(uint256 requestId, uint32 numWords);
    event RequestFulfilled(uint256 requestId, uint256[] randomWords);

    struct RequestStatus {
        bool fulfilled; // whether the request has been successfully fulfilled
        bool exists; // whether a requestId exists
        uint256[] randomWords;
    }
    mapping(uint256 => RequestStatus)
        public s_requests; /* requestId --> requestStatus */
    VRFCoordinatorV2Interface COORDINATOR;

    // Your subscription ID.
    uint64 s_subscriptionId;

    // past requests Id.
    uint256[] public requestIds;
    uint256 public lastRequestId;

    // The gas lane to use, which specifies the maximum gas price to bump to.
    bytes32 keyHash =
        0x79d3d8832d904592c0bf9818b621522c988bb8b0c05cdc3b15aea1b6e8db0c15;

    uint32 callbackGasLimit = 2_500_000;

    // The default is 3
    uint16 requestConfirmations = 3;

    // Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.
    uint32 numWords = 1;

    /**
     * HARDCODED FOR MAINNET
     * COORDINATOR: 0x271682DEB8C4E0901D1a1550aD2e64D568E69909
     */
    constructor(
        uint64 subscriptionId
    )
        VRFConsumerBaseV2(0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D)
        ConfirmedOwner(0x74C6431E6Ea58398202aAfD5D1F57032dDFFf390) // Nouns DAO Executor address
    {
        COORDINATOR = VRFCoordinatorV2Interface(
            0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D
        );
        s_subscriptionId = subscriptionId;
    }

    // Assumes the subscription is funded sufficiently.
    function requestRandomWords()
        internal
        returns (uint256 requestId)
    {
        // Will revert if subscription is not set and funded.
        requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
        s_requests[requestId] = RequestStatus({
            randomWords: new uint256[](0),
            exists: true,
            fulfilled: false
        });
        requestIds.push(requestId);
        lastRequestId = requestId;
        emit RequestSent(requestId, numWords);
        return requestId;
    }

    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) virtual internal override {
        require(s_requests[_requestId].exists, "request not found");
        s_requests[_requestId].fulfilled = true;
        s_requests[_requestId].randomWords = _randomWords;
        emit RequestFulfilled(_requestId, _randomWords);
    }

    function getRequestStatus(
        uint256 _requestId
    ) external view returns (bool fulfilled, uint256[] memory randomWords) {
        require(s_requests[_requestId].exists, "request not found");
        RequestStatus memory request = s_requests[_requestId];
        return (request.fulfilled, request.randomWords);
    }
}