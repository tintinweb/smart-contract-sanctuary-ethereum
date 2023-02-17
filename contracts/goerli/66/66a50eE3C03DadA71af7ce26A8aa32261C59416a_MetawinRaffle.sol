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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./VRFv2Consumer.sol";

interface IVRFv2Consumer {
  function requestRandomWords() external returns (uint256); // call every time, the VRF Consumer will determine whether to formally request the randomWords

  function getRequestStatus(uint256 requestId) external view returns (uint256[] memory); // returns the result of the requestId once the callback has been made.  Returns 0 otherwise (never use the 0 result as a result)
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./IVRFv2Consumer.sol";

contract MetawinRaffle {
    using SafeMath for uint256;

    enum RaffleStatus {
        ONGOING,
        PENDING_COMPLETION,
        COMPLETE
    }

    //NFT raffle struct
    struct NftRaffle {
        address creator;
        address nftContractAddress;
        uint256 nftId;
        uint256 ticketPrice;
        uint256 totalPrice;
        uint256 maxEntries;
        uint256 period;
        address[] tickets;
        uint256 winnerIndex;
        uint256 createdAt;
        RaffleStatus status;
    }

    //Eth Raffle struct
    struct EthRaffle {
        address creator;
        uint256 rewardEth;
        uint256 ticketPrice;
        uint256 totalPrice;
        uint256 maxEntries;
        uint256 period;
        address[] tickets;
        uint256 numWinner;
        uint256[] winners;
        uint256 createdAt;
        RaffleStatus status;
    }

    //Contract owner address
    address public owner;

    uint16 public numNftRaffles;
    uint16 public numEthRaffles;

    IVRFv2Consumer vrfConsumer;

    //NFT Raffles
    NftRaffle[] public nftRaffles;
    //Eth Raffles
    EthRaffle[] public ethRaffles;

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    constructor(address _vrfConsumer) {
        owner = msg.sender;
        vrfConsumer = IVRFv2Consumer(_vrfConsumer);
    }

    //Create a new NFT raffle
    //nftContract.approve should be called before this function
    function createNftRaffle(
        IERC721 _nftContract,
        uint256 _nftId,
        uint256 _ticketPrice,
        uint256 _numTickets,
        uint256 _rafflePeriod
    ) onlyOwner public returns (uint256) {
        //transfer the NFT from the raffle creator to this contract
        _nftContract.transferFrom(
            msg.sender,
            address(this),
            _nftId
        );

         //init tickets
        address[] memory _tickets;
        //create raffle
        NftRaffle memory _raffle = NftRaffle(
            msg.sender,
            address(_nftContract),
            _nftId,
            _ticketPrice,
            0,
            _numTickets,
            _rafflePeriod,
            _tickets,
            _numTickets,
            block.timestamp,
            RaffleStatus.ONGOING
        );

        //store raffel in state
        nftRaffles.push(_raffle);

        //increase nft raffle number
        numNftRaffles++;

        //emit event
        emit NftRaffleCreated(nftRaffles.length - 1, msg.sender);

        return nftRaffles.length;
    }

    //Cancel NFT Raffle
    function cancelNftRaffle(
        uint256 _raffleId
    ) onlyOwner public {
        require(
            block.timestamp > nftRaffles[_raffleId].createdAt + nftRaffles[_raffleId].period,
            "Raffle is not ended yet"
        );

        require(
            nftRaffles[_raffleId].totalPrice == 0, "The winner was chosen" 
        );

        //transfer the NFT from the contract to the raffle creator
        IERC721(nftRaffles[_raffleId].nftContractAddress).transferFrom(
            address(this),
            msg.sender,
            nftRaffles[_raffleId].nftId
        );
    }

    //Create a new Eth Raffle
    function createEthRaffle(
        uint256 _rewardEth,
        uint256 _ticketPrice,
        uint256 _numTickets,
        uint256 _numWinner,
        uint256 _rafflePeriod
    ) onlyOwner public payable returns (uint256) {
        require(msg.value == _rewardEth, "Raffle reward is not set exactly");

        address[] memory _tickets;
        uint256[] memory _winners;

        EthRaffle memory _raffle = EthRaffle(
            msg.sender,
            _rewardEth,
            _ticketPrice,
            0,
            _numTickets,
            _rafflePeriod,
            _tickets,
            _numWinner,
            _winners,
            block.timestamp,
            RaffleStatus.ONGOING
        );

        ethRaffles.push(_raffle);

        //increase eth raffle number
        numEthRaffles++;

        emit EthRaffleCreated(ethRaffles.length - 1, msg.sender);

        return ethRaffles.length;
    }

    //Cancel Eth raffle
    function cancelEthRaffle(uint256 _raffleId) onlyOwner public {
        require(
            block.timestamp > ethRaffles[_raffleId].createdAt + ethRaffles[_raffleId].period,
            "Raffle is not ended yet" 
        );

        require(
            ethRaffles[_raffleId].totalPrice == 0, "The winner was chosen" 
        );

        (bool sent, ) = ethRaffles[_raffleId].creator.call{value: ethRaffles[_raffleId].rewardEth}("");
            require(sent, "Failed to send Ether");
    }

    //enter a user in the draw for a given NFT raffle
    function enterNftRaffle(uint256 _raffleId, uint256 _tickets) public payable {
        require(
            uint256(nftRaffles[_raffleId].status) == uint256(RaffleStatus.ONGOING),
            "NFT Raffle no longer active"
        );

        require(block.timestamp < (nftRaffles[_raffleId].createdAt + nftRaffles[_raffleId].period), "Raffle period is over");

        require(
            _tickets.add(nftRaffles[_raffleId].tickets.length) <= nftRaffles[_raffleId].maxEntries,
            "Not enough tickets available"
        );

        require(_tickets > 0, "Not enough _tickets purchased");

        if(_tickets == 1) {
            require(msg.value == nftRaffles[_raffleId].ticketPrice, "Ticket price not paid");
        } else if(_tickets == 15) {
            require(msg.value == 0.12 ether, "Ticket price not paid");
        } else if(_tickets == 35) {
            require(msg.value == 0.24 ether, "Ticket price not paid");
        } else if(_tickets == 75) {
            require(msg.value == 0.48 ether, "Ticket price not paid");
        } else if(_tickets == 155) {
            require(msg.value == 0.96 ether, "Ticket price not paid");
        } else {
            require(msg.value == _tickets.mul(nftRaffles[_raffleId].ticketPrice), "Ticket price not paid");
        }

        //add _tickets
        for (uint256 i = 0; i < _tickets; i++) {
            nftRaffles[_raffleId].tickets.push(payable(msg.sender));
        }

        nftRaffles[_raffleId].totalPrice += msg.value;
        
        emit NftTicketPurchased(_raffleId, msg.sender, _tickets);
    }

    //enter a user in the draw for a given ETH raffle
    function enterEthRaffle(uint256 _raffleId, uint256 _tickets) public payable {
        require(
            uint256(ethRaffles[_raffleId].status) == uint256(RaffleStatus.ONGOING),
            "NFT Raffle no longer active"
        );

        require(
            _tickets.add(ethRaffles[_raffleId].tickets.length) <= ethRaffles[_raffleId].maxEntries,
            "Not enough tickets available"
        );
        
        require(_tickets > 0, "Not enough _tickets purchased");

        if(ethRaffles[_raffleId].period != 0) {
            require(block.timestamp < (ethRaffles[_raffleId].createdAt + ethRaffles[_raffleId].period), "Raffle period is over");

            if(_tickets == 1) {
                require(msg.value == ethRaffles[_raffleId].ticketPrice, "Ticket price not paid");
            } else if(_tickets == 15) {
                require(msg.value == 0.095 ether, "Ticket price not paid");
            } else if(_tickets == 35) {
                require(msg.value == 0.19 ether, "Ticket price not paid");
            } else if(_tickets == 75) {
                require(msg.value == 0.38 ether, "Ticket price not paid");
            } else if(_tickets == 155) {
                require(msg.value == 0.76 ether, "Ticket price not paid");
            } else {
                require(msg.value == _tickets.mul(nftRaffles[_raffleId].ticketPrice), "Ticket price not paid");
            }
        }
        
        for (uint256 i = 0; i < _tickets; i++) {
            ethRaffles[_raffleId].tickets.push(payable(msg.sender));
        }

        ethRaffles[_raffleId].totalPrice += msg.value;

        emit EthTicketPurchased(_raffleId, msg.sender, _tickets);
    }

    function chooseNftWinner(uint256 _raffleId) public returns (uint256) {
        NftRaffle storage raffle = nftRaffles[_raffleId];
        require(block.timestamp >= (raffle.createdAt + raffle.period), "Raffle is not ended yet");
        require(raffle.winnerIndex == raffle.maxEntries, "Winner is already chosen");

        uint256 requestId = vrfConsumer.requestRandomWords();
        // require(vrfConsumer.getRequestStatus(requestId) != 0, "Random result has not returned yet");

        // uint256 randomResult = vrfConsumer.getRequestStatus(requestId);

        // map randomness to value between 0 and raffle.tickets.length
        // (x - in_min) * (out_max - out_min) / (in_max - in_min) + out_min
        uint256 winnerIndex = requestId % raffle.tickets.length;

        //Input winnerIndex to raffle struct
        raffle.winnerIndex = winnerIndex;

        //award winner
        IERC721(raffle.nftContractAddress).transferFrom(
            address(this),
            raffle.tickets[winnerIndex],
            raffle.nftId
        );

        //pay raffle creator
        (bool sent, ) = raffle.creator.call{value: (raffle.totalPrice)}("");
        require(sent, "Failed to send Ether");

        raffle.status = RaffleStatus.COMPLETE;

        emit NftRaffleCompleted(
            _raffleId,
            raffle.tickets[winnerIndex]
        );

        return winnerIndex;
    }

    function chooseEthWinner(uint256 _raffleId) public returns (uint256) {
        EthRaffle storage raffle = ethRaffles[_raffleId];

        require(block.timestamp >= (raffle.createdAt + raffle.period), "Raffle is not ended yet");
        require(raffle.winners.length == 0, "Winner is already chosen");

        uint256 winnerIdx;
        uint256 requestId;

        for (uint8 i = 0; i < raffle.numWinner; i++) {
            requestId = vrfConsumer.requestRandomWords();
            winnerIdx = requestId % raffle.tickets.length;
            raffle.winners.push(winnerIdx);

            (bool sent, ) = raffle.tickets[winnerIdx].call{value: (raffle.rewardEth.div(raffle.numWinner))}("");
            require(sent, "Failed to send Ether");
        }


        if(raffle.totalPrice > raffle.rewardEth) {
            (bool rewardSent, ) = raffle.creator.call{value: (raffle.totalPrice - raffle.rewardEth)}("");
            require(rewardSent, "Failed to send Ether");
        }

        raffle.status = RaffleStatus.COMPLETE;

        emit EthRaffleCompleted(
            _raffleId,
            raffle.winners
        );

        return winnerIdx;
    }

    function getAllNftRaffles() external view returns (NftRaffle[] memory) {
        return nftRaffles;
    }

    function getAllEthRaffles() external view returns (EthRaffle[] memory) {
        return ethRaffles;
    }

    event NftRaffleCreated(uint256 id, address creator);
    event NftTicketPurchased(uint256 raffleId, address buyer, uint256 numTickets);
    event NftRaffleCompleted(uint256 id, address winner);

    event EthRaffleCreated(uint256 id, address creator);
    event EthTicketPurchased(uint256 raffleId, address buyer, uint256 numTickets);
    event EthRaffleCompleted(uint256 id, uint256[] winners);
}

// SPDX-License-Identifier: MIT
// An example of a consumer contract that relies on a subscription for funding.
pragma solidity ^0.8.4;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

/**
 * Request testnet LINK and ETH here: https://faucets.chain.link/
 * Find information on LINK Token Contracts and get the latest ETH and LINK faucets here: https://docs.chain.link/docs/link-token-contracts/
 */

contract VRFv2Consumer is VRFConsumerBaseV2 {
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
    // For a list of available gas lanes on each network,
    // see https://docs.chain.link/docs/vrf/v2/subscription/supported-networks/#configurations
    bytes32 keyHash =
        0x79d3d8832d904592c0bf9818b621522c988bb8b0c05cdc3b15aea1b6e8db0c15;

    // Depends on the number of requested values that you want sent to the
    // fulfillRandomWords() function. Storing each word costs about 20,000 gas,
    // so 100,000 is a safe default for this example contract. Test and adjust
    // this limit based on the network that you select, the size of the request,
    // and the processing of the callback request in the fulfillRandomWords()
    // function.
    uint32 callbackGasLimit = 100000;

    // The default is 3, but you can set this higher.
    uint16 requestConfirmations = 3;

    // For this example, retrieve 2 random values in one request.
    // Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.
    uint32 numWords = 2;

    /**
     * HARDCODED FOR GOERLI
     * COORDINATOR: 0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D
     */
    constructor(
        uint64 subscriptionId
    )
        VRFConsumerBaseV2(0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D)
    {
        COORDINATOR = VRFCoordinatorV2Interface(
            0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D
        );
        s_subscriptionId = subscriptionId;
    }

    // Assumes the subscription is funded sufficiently.
    function requestRandomWords()
        external
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
    ) internal override {
        require(s_requests[_requestId].exists, "request not found");
        s_requests[_requestId].fulfilled = true;
        s_requests[_requestId].randomWords = _randomWords;
        emit RequestFulfilled(_requestId, _randomWords);
    }

    function getRequestStatus(
        uint256 _requestId
    ) external view returns (uint256[] memory randomWords) {
        require(s_requests[_requestId].exists, "request not found");
        RequestStatus memory request = s_requests[_requestId];
        return request.randomWords;
    }
}