// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "./IERC20Burnable.sol";

contract RaffleBurn is VRFConsumerBaseV2 {
    event RaffleCreated(
        uint256 indexed raffleId,
        address indexed from,
        address indexed paymentToken,
        uint256 ticketPrice,
        uint256 startTimestamp,
        uint256 endTimestamp
    );

    event PrizeAdded(
        uint256 indexed raffleId,
        address indexed from,
        address indexed prizeToken,
        uint256 tokenId
    );

    event TicketsPurchased(
        uint256 indexed raffleId,
        address indexed to,
        uint256 startId,
        uint256 amount
    );

    event SeedInitialized(uint256 indexed raffleId, uint256 indexed requestId);

    struct Prize {
        address tokenAddress;
        uint96 tokenId;
        address owner;
        bool claimed;
    }

    struct Ticket {
        address owner;
        uint96 endId;
    }

    struct Raffle {
        address paymentToken;
        bool burnable;
        uint40 startTimestamp;
        uint40 endTimestamp;
        uint160 ticketPrice;
        uint96 seed;
    }

    /*
    GLOBAL STATE
    */

    VRFCoordinatorV2Interface COORDINATOR;

    uint256 public raffleCount;

    mapping(uint256 => Raffle) public raffles;
    mapping(uint256 => Prize[]) public rafflePrizes;
    mapping(uint256 => Ticket[]) public raffleTickets;
    mapping(uint256 => uint256) public requestIdToRaffleId;

    constructor(address vrfCoordinator) VRFConsumerBaseV2(vrfCoordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
    }

    /*
    WRITE FUNCTIONS
    */

    /**
     * @notice initializes the raffle
     * @param prizeToken the address of the ERC721 token to raffle off
     * @param tokenIds the list of token ids to raffle off
     * @param paymentToken address of the ERC20 token used to buy tickets. Null address uses ETH
     * @param burnable whether payment token can be burned with `burnFrom(address account, uint256 amount)`
     * @param startTimestamp the timestamp at which the raffle starts
     * @param endTimestamp the timestamp at which the raffle ends
     * @param ticketPrice the price of each ticket
     * @return raffleId the id of the raffle
     */
    function createRaffle(
        address prizeToken,
        uint96[] calldata tokenIds,
        address paymentToken,
        bool burnable,
        uint40 startTimestamp,
        uint40 endTimestamp,
        uint160 ticketPrice
    ) external returns (uint256 raffleId) {
        require(prizeToken != address(0), "prizeToken cannot be null");
        require(paymentToken != address(0), "paymentToken cannot be null");
        require(
            endTimestamp > block.timestamp,
            "endTimestamp must be in the future"
        );
        require(ticketPrice > 0, "ticketPrice must be greater than 0");

        raffleId = raffleCount++;

        raffles[raffleId] = Raffle({
            paymentToken: paymentToken,
            burnable: burnable,
            startTimestamp: startTimestamp,
            endTimestamp: endTimestamp,
            ticketPrice: ticketPrice,
            seed: 0
        });

        emit RaffleCreated(
            raffleId,
            msg.sender,
            paymentToken,
            ticketPrice,
            startTimestamp,
            endTimestamp
        );

        addPrizes(raffleId, prizeToken, tokenIds);
    }

    /**
     * @notice add prizes to raffle. Must have transfer approval from contract
     *  owner or token owner
     * @param raffleId the id of the raffle
     * @param prizeToken the address of the ERC721 token to raffle off
     * @param tokenIds the list of token ids to raffle off
     */
    function addPrizes(
        uint256 raffleId,
        address prizeToken,
        uint96[] calldata tokenIds
    ) public {
        require(tokenIds.length > 0, "tokenIds must be non-empty");
        for (uint256 i = 0; i < tokenIds.length; i++) {
            IERC721(prizeToken).transferFrom(
                msg.sender,
                address(this),
                tokenIds[i]
            );
            rafflePrizes[raffleId].push(
                Prize({
                    tokenAddress: prizeToken,
                    tokenId: tokenIds[i],
                    owner: msg.sender,
                    claimed: false
                })
            );
            emit PrizeAdded(raffleId, msg.sender, prizeToken, tokenIds[i]);
        }
    }

    /**
     * @notice buy ticket with erc20
     * @param raffleId the id of the raffle to buy ticket for
     * @param ticketCount the number of tickets to buy
     */
    function buyTickets(uint256 raffleId, uint96 ticketCount) external {
        require(raffleStarted(raffleId), "Raffle not started");
        require(!raffleEnded(raffleId), "Raffle ended");
        // transfer payment token from account
        uint256 cost = uint256(raffles[raffleId].ticketPrice) * ticketCount;
        _burnTokens(raffleId, msg.sender, cost);
        // give tickets to account
        _mintTickets(msg.sender, raffleId, ticketCount);
    }

    /**
     * @notice claim prize
     * @param raffleId the id of the raffle to buy ticket for
     * @param prizeIndex the index of the prize to claim
     * @param ticketPurchaseIndex the index of the ticket purchase to claim prize for
     */
    function claimPrize(
        uint256 raffleId,
        uint256 prizeIndex,
        uint256 ticketPurchaseIndex
    ) external {
        require(raffles[raffleId].seed != 0, "Seed not set");
        require(
            rafflePrizes[raffleId][prizeIndex].claimed == false,
            "Prize already claimed"
        );

        address to = raffleTickets[raffleId][ticketPurchaseIndex].owner;
        uint256 winnerTicketId = getWinnerTicketId(raffleId, prizeIndex);
        uint96 purchaseStartId = _getPurchaseStartId(
            raffleId,
            ticketPurchaseIndex
        );
        uint96 purchaseEndId = _getPurchaseEndId(raffleId, ticketPurchaseIndex);
        require(
            purchaseStartId <= winnerTicketId && winnerTicketId < purchaseEndId,
            "Not winner ticket"
        );

        rafflePrizes[raffleId][prizeIndex].claimed = true;
        IERC721(rafflePrizes[raffleId][prizeIndex].tokenAddress).transferFrom(
            address(this),
            to,
            rafflePrizes[raffleId][prizeIndex].tokenId
        );
    }

    /**
     * Initialize seed for raffle
     */
    function initializeSeed(
        uint256 raffleId,
        bytes32 keyHash,
        uint64 subscriptionId
    ) external {
        require(raffleEnded(raffleId), "Raffle not ended");
        require(raffles[raffleId].seed == 0, "Seed already requested");
        // Will revert if subscription is not set and funded.
        uint256 requestId = COORDINATOR.requestRandomWords(
            keyHash,
            subscriptionId,
            3,
            300000,
            1
        );
        requestIdToRaffleId[requestId] = raffleId;
    }

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
        internal
        override
    {
        uint256 raffleId = requestIdToRaffleId[requestId];
        require(raffles[raffleId].seed == 0, "Seed already initialized");
        raffles[raffleId].seed = uint96(randomWords[0]);
        emit SeedInitialized(raffleId, requestId);
    }

    /**
     * @dev mints tickets to account
     * @param to the account to send ticket to
     * @param raffleId the id of the raffle to send ticket for
     * @param ticketCount the number of tickets to send
     */
    function _mintTickets(
        address to,
        uint256 raffleId,
        uint96 ticketCount
    ) internal {
        uint96 purchaseStartId = _getPurchaseStartId(
            raffleId,
            raffleTickets[raffleId].length
        );
        uint96 purchaseEndId = purchaseStartId + ticketCount;
        Ticket memory ticket = Ticket({owner: to, endId: purchaseEndId});
        raffleTickets[raffleId].push(ticket);
        emit TicketsPurchased(
            raffleId,
            msg.sender,
            purchaseStartId,
            ticketCount
        );
    }

    function _burnTokens(
        uint256 raffleId,
        address from,
        uint256 amount
    ) internal {
        if (raffles[raffleId].burnable) {
            IERC20Burnable(raffles[raffleId].paymentToken).burnFrom(
                from,
                amount
            );
        } else {
            IERC20(raffles[raffleId].paymentToken).transferFrom(
                from,
                address(0xdead),
                amount
            );
        }
    }

    /*
    READ FUNCTIONS
    */

    /**
     * @dev binary search for winner address
     * @param raffleId the id of the raffle to get winner for
     * @param prizeIndex the index of the prize to get winner for
     * @return account the winner address
     * @return ticketPurchaseIndex the index of the winner ticket purchase
     * @return ticketId the id of the winner ticket
     */
    function getWinner(uint256 raffleId, uint256 prizeIndex)
        public
        view
        returns (
            address account,
            uint256 ticketPurchaseIndex,
            uint256 ticketId
        )
    {
        ticketId = getWinnerTicketId(raffleId, prizeIndex);
        ticketPurchaseIndex = getTicketPurchaseIndex(raffleId, ticketId);
        account = raffleTickets[raffleId][ticketPurchaseIndex].owner;
    }

    /**
     * @dev binary search for ticket purchase index of ticketId
     * @param raffleId the id of the raffle to get winner for
     * @param ticketId the id of the ticket to get index for
     * @return ticketPurchaseIndex the purchase index of the ticket
     */
    function getTicketPurchaseIndex(uint256 raffleId, uint256 ticketId)
        public
        view
        returns (uint256 ticketPurchaseIndex)
    {
        // binary search for winner
        uint256 left = 0;
        uint256 right = raffleTickets[raffleId].length - 1;
        while (left < right) {
            uint256 mid = (left + right) / 2;
            if (raffleTickets[raffleId][mid].endId < ticketId) {
                left = mid + 1;
            } else {
                right = mid;
            }
        }
        ticketPurchaseIndex = left;
    }

    /**
     * @dev salt the seed with prize index and get the winner ticket id
     * @param raffleId the id of the raffle to get winner for
     * @param prizeIndex the index of the prize to get winner for
     * @return ticketId the id of the ticket that won
     */
    function getWinnerTicketId(uint256 raffleId, uint256 prizeIndex)
        public
        view
        returns (uint256 ticketId)
    {
        // add salt to seed
        ticketId =
            uint256(keccak256((abi.encode(raffleId, prizeIndex)))) %
            getTicketCount(raffleId);
    }

    /**
     * @notice get total number of tickets for a purchase
     * @param raffleId the id of the raffle to get number of tickets for
     * @param ticketPurchaseIndex the index of the ticket purchase to get number of tickets for
     * @return ticketCount the number of tickets
     */
    function getPurchaseTicketCount(
        uint256 raffleId,
        uint256 ticketPurchaseIndex
    ) public view returns (uint256 ticketCount) {
        return
            _getPurchaseEndId(raffleId, ticketPurchaseIndex) -
            _getPurchaseStartId(raffleId, ticketPurchaseIndex);
    }

    /**
     * @notice get total number of tickets purchased by an account
     * @param raffleId the id of the raffle to get number of tickets for
     * @param account the account to get number of tickets for
     * @return ticketCount the number of tickets
     */
    function getAccountTicketCount(uint256 raffleId, address account)
        public
        view
        returns (uint256 ticketCount)
    {
        for (uint256 i = 0; i < raffleTickets[raffleId].length; i++) {
            if (raffleTickets[raffleId][i].owner == account) {
                ticketCount += getPurchaseTicketCount(raffleId, i);
            }
        }
        return ticketCount;
    }

    /**
     * @notice get total number of prizes for raffle
     * @param raffleId the id of the raffle to get number of prizes for
     * @return prizeCount the number of prizes
     */
    function getPrizeCount(uint256 raffleId)
        public
        view
        returns (uint256 prizeCount)
    {
        return rafflePrizes[raffleId].length;
    }

    /**
     * @notice get total number of purchases for raffle
     * @param raffleId the id of the raffle to get number of purchases for
     * @return purchaseCount the number of tickets
     */
    function getPurchaseCount(uint256 raffleId)
        public
        view
        returns (uint256 purchaseCount)
    {
        return raffleTickets[raffleId].length;
    }

    /**
     * @notice get total number of tickets sold for raffle
     * @param raffleId the id of the raffle to get number of tickets for
     * @return ticketCount the number of tickets
     */
    function getTicketCount(uint256 raffleId)
        public
        view
        returns (uint256 ticketCount)
    {
        uint256 length = raffleTickets[raffleId].length;
        return length > 0 ? raffleTickets[raffleId][length - 1].endId : 0;
    }

    /**
     * @notice get total ticket sales for raffle
     * @param raffleId the id of the raffle to get number of tickets for
     * @return ticketSales the number of tickets
     */
    function getTicketSales(uint256 raffleId)
        public
        view
        returns (uint256 ticketSales)
    {
        return
            getTicketCount(raffleId) * uint256(raffles[raffleId].ticketPrice);
    }

    /**
     * @notice check if raffle ended
     * @param raffleId the id of the raffle to check
     * @return ended true if ended
     */
    function raffleEnded(uint256 raffleId) public view returns (bool ended) {
        return raffles[raffleId].endTimestamp <= block.timestamp;
    }

    /**
     * @notice check if raffle started
     * @param raffleId the id of the raffle to check
     * @return started true if started
     */
    function raffleStarted(uint256 raffleId)
        public
        view
        returns (bool started)
    {
        return raffles[raffleId].startTimestamp <= block.timestamp;
    }

    function _getPurchaseStartId(uint256 raffleId, uint256 ticketPurchaseIndex)
        private
        view
        returns (uint96 endId)
    {
        return
            ticketPurchaseIndex > 0
                ? raffleTickets[raffleId][ticketPurchaseIndex - 1].endId
                : 0;
    }

    function _getPurchaseEndId(uint256 raffleId, uint256 ticketPurchaseIndex)
        private
        view
        returns (uint96 startId)
    {
        return raffleTickets[raffleId][ticketPurchaseIndex].endId;
    }

    /*
    MODIFIERS
    */
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

abstract contract IERC20Burnable is IERC20 {
    function burn(uint256 amount) public virtual;

    function burnFrom(address account, uint256 amount) public virtual;
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