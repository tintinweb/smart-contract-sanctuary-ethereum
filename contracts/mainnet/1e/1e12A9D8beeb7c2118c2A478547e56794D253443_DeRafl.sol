// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "./interface/IRoyaltyFeeRegistry.sol";

/// @title DeRafl
/// @author 0xCappy
/// @notice This contract is used by DeRafl to hold raffles for any erc721 token
/// @dev Designed to be as trustless as possible.
/// Chainlink VRF is used to determine a winning ticket of a raffle.
/// A refund for a raffle can be initiated 2 days after a raffles expiry date if not already released.
/// LooksRare royaltyFeeRegistry is used to determine royalty rates for collections.
/// Collection royalties are honoured with a max payout of 5%

contract DeRafl is VRFConsumerBaseV2, Ownable, ERC1155Holder {
    error InvalidRaffleState();
    error InvalidExpiryTimestamp();
    error CreateNotEnabled();
    error EthInputTooSmall();
    error EthInputInvalid();
    error TicketAmountInvalid();
    error MsgValueInvalid();
    error RaffleBatchNotWinner();
    error SendEthFailed();
    error TimeSinceExpiryInsufficientForRefund();
    error TicketsAlreadyRefunded();
    error RaffleOwnerCannotPurchaseTickets();
    error InsufficientTicketsSold();

    // CONSTANTS
    /// @dev ERC721 interface
    bytes4 public constant INTERFACE_ID_ERC721 = 0x80ac58cd;
    /// @dev ERC2981 interface
    bytes4 public constant INTERFACE_ID_ERC2981 = 0x2a55205a;
    /// @dev Maximum seconds a raffle can be active
    uint256 internal constant MAX_RAFFLE_DURATION_SECONDS = 30 days;
    /// @dev Minimum amount of Eth
    uint256 internal constant MIN_ETH = 0.1 ether;
    /// @dev Denominator for fee calculations
    uint256 internal constant FEE_DENOMINATOR = 10000;
    /// @dev Maximum royalty fee percentage (5%)
    uint64 internal constant MAX_ROYALTY_FEE_PERCENTAGE = 500;
    /// @dev DeRafl protocol fee (0.5%)
    uint256 internal constant DERAFL_FEE_PERCENTAGE = 50;
    /// @dev Price per ticket
    uint96 internal constant TICKET_PRICE = 0.001 ether;

    // CHAINLINK
    uint64 internal subscriptionId;
    address internal vrfCoordinator;
    bytes32 internal keyHash = 0x8af398995b04c28e9951adb9721ef74c74f93e6a478f39e7e0777be13527e7ef;
    uint32 internal callbackGasLimit = 40000;
    uint16 internal requestConfirmations = 3;
    uint32 internal numWords = 1;
    VRFCoordinatorV2Interface internal COORDINATOR;

    /// @dev Emitted when a raffle is created
    /// @param raffleId The id of the raffle created
    /// @param nftAddress The address of the NFT being raffled
    /// @param tokenId The tokenId of the NFT being raffled
    /// @param tickets Maximum amount of tickets to be sold
    /// @param expires The timestamp when the raffle expires
    event RaffleOpened(
        uint64 indexed raffleId,
        address indexed nftAddress,
        uint256 tokenId,
        uint96 tickets,
        uint64 expires
    );

    /// @dev Emitted when a raffle is closed
    /// @param raffleId The id of the raffle being closed
    event RaffleClosed(uint64 indexed raffleId);

    /// @dev Emitted when a raffle is drawn and winning ticket determined
    /// @param raffleId The id of the raffle being drawn
    /// @param winningTicket The winning ticket of the raffle being drawn
    event RaffleDrawn(uint64 indexed raffleId, uint96 winningTicket);

    /// @dev Emitted when a raffle is released
    /// @param raffleId The id of the raffle being released
    /// @param winner The address of the winning ticket holder
    /// @param royaltiesPaid Collection royalties paid in wei
    /// @param ethPaid Ethereum paid to the raffle owner in wei
    event RaffleReleased(uint64 indexed raffleId, address indexed winner, uint256 royaltiesPaid, uint256 ethPaid);

    /// @dev Emitted when a raffle has been changed to a refunded state
    /// @param raffleId The id of the raffle being refunded
    event RaffleRefunded(uint64 indexed raffleId);

    /// @dev Emitted when tickets are purchased
    /// @param raffleId The raffle id of the tickets being purchased
    /// @param batchId The batch id of the ticket purchase
    /// @param purchaser The address of the account making the purchase
    /// @param ticketFrom The first ticket of the ticket batch
    /// @param ticketAmount The amount of tickets being purchased
    event TicketPurchased(
        uint64 indexed raffleId,
        uint96 batchId,
        address indexed purchaser,
        uint96 ticketFrom,
        uint96 ticketAmount
    );

    /// @dev Emitted when a refund has been placed
    /// @param raffleId The raffle id of the raffle being refunded
    /// @param refundee The account being issued a refund
    /// @param ethAmount The ethereum amount being refunded in wei
    event TicketRefunded(uint64 indexed raffleId, address indexed refundee, uint256 ethAmount);

    /// @dev Emitted when create raffle is toggled
    /// @param enabled next state of createEnabled
    event CreateEnabled(bool enabled);

    enum RaffleState {
        NONE,
        ACTIVE,
        CLOSED,
        REFUNDED,
        PENDING_DRAW,
        DRAWN,
        RELEASED
    }

    enum TokenType {
        ERC721,
        ERC1155
    }

    /// @dev Ticket Owner represents a participants total input in a raffle (sum of all ticket batches)
    struct TicketOwner {
        uint128 ticketsOwned;
        bool isRefunded;
    }

    /// @dev TicketBatch represents a batch of tickets purchased for a raffle
    struct TicketBatch {
        address owner;
        uint96 startTicket;
        uint96 endTicket;
    }

    struct Raffle {
        address royaltyRecipient;
        uint96 winningTicket;
        address nftAddress;
        uint96 ticketsAvailable;
        address payable raffleOwner;
        uint96 ticketsSold;
        address winner;
        uint96 batchIndex;
        uint256 chainlinkRequestId;
        uint256 tokenId;
        uint64 royaltyPercentage;
        uint64 raffleId;
        RaffleState raffleState;
        uint64 expiryTimestamp;
        TokenType tokenType;
    }

    /// @dev LooksRare royaltyFeeRegistry
    IRoyaltyFeeRegistry royaltyFeeRegistry;
    /// @dev mapping of raffleId => raffle
    mapping(uint64 => Raffle) raffles;
    /// @dev maps a participants TOTAL tickets bought for a raffle
    mapping(uint64 => mapping(address => TicketOwner)) ticketOwners;
    /// @dev maps ticketBatches purchased for a raffle
    mapping(uint64 => mapping(uint96 => TicketBatch)) ticketBatches;
    /// @dev maps raffleId to a chainlink VRF request
    mapping(uint256 => uint64) chainlinkRequestIdMap;
    /// @dev incremented raffleId
    uint64 raffleNonce = 1;
    /// @dev address to collect protocol fee
    address payable deraflFeeCollector;
    /// @dev indicates if a raffle can be created
    bool createEnabled = true;

    constructor(
        uint64 _subscriptionId,
        address _vrfCoordinator,
        address royaltyFeeRegistryAddress,
        address feeCollector
    ) VRFConsumerBaseV2(_vrfCoordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
        subscriptionId = _subscriptionId;
        royaltyFeeRegistry = IRoyaltyFeeRegistry(royaltyFeeRegistryAddress);
        deraflFeeCollector = payable(feeCollector);
    }

    /// @notice DeRafl Returns information about a particular raffle
    /// @dev Returns the Raffle struct of the specified Id
    /// @param raffleId a parameter just like in doxygen (must be followed by parameter name)
    /// @return raffle the Raffle struct at the specified raffleId
    function getRaffle(uint64 raffleId) external view returns (Raffle memory raffle) {
        raffle = raffles[raffleId];
        bool soldOut = raffle.ticketsSold == raffle.ticketsAvailable;
        bool isExpired = block.timestamp > raffle.expiryTimestamp;
        if (raffle.raffleState == RaffleState.ACTIVE && (soldOut || isExpired)) {
            raffle.raffleState = RaffleState.CLOSED;
        }
    }

    /// @notice DeRafl Returns an accounts particiaption for a raffle
    /// @dev TicketOwner contains the total amount of tickets bought for a raffle (sum of all ticket batches)
    /// and the refund status of a participant in the raffle
    /// @param raffleId The raffle Id of the raffle being queried
    /// @param ticketOwner The address of the participant being queried
    /// @return TicketOwner
    function getUserInfo(uint64 raffleId, address ticketOwner) external view returns (TicketOwner memory) {
        return ticketOwners[raffleId][ticketOwner];
    }

    /// @notice DeRafl Information about a specific TicketBatch for a raffle
    /// @dev Finds the TicketBatch for a specific raffle via the ticketBatches mapping
    /// @param raffleId The raffle Id of the TicketBatch being queried
    /// @param batchId The batchId for the TicketBatch being queried
    /// @return TicketBatch
    function getBatchInfo(uint64 raffleId, uint96 batchId) external view returns (TicketBatch memory) {
        return ticketBatches[raffleId][batchId];
    }

    /// @notice toggles the ability for users to create raffles
    function toggleCreateEnabled() external onlyOwner {
        createEnabled = !createEnabled;
        emit CreateEnabled(createEnabled);
    }

    /// @notice DeRafl Creates a new raffle
    /// @dev Creates a new raffle and adds it to the raffles mapping
    /// @param nftAddress The address of the NFT being raffled
    /// @param tokenId The token id of the NFT being raffled
    /// @param expiryTimestamp How many days until the raffle expires
    /// @param ethInput The maximum amount of Eth to be raised for the raffle
    function createRaffle(address nftAddress, uint256 tokenId, uint64 expiryTimestamp, uint96 ethInput, TokenType tokenType) external {
        if (!createEnabled) revert CreateNotEnabled();
        uint256 duration = expiryTimestamp - block.timestamp;
        if (duration > MAX_RAFFLE_DURATION_SECONDS) revert InvalidExpiryTimestamp();
        if (ethInput % TICKET_PRICE != 0) revert EthInputInvalid();
        if (ethInput < MIN_ETH) revert EthInputTooSmall();

        Raffle storage raffle = raffles[raffleNonce];
        raffle.raffleState = RaffleState.ACTIVE;
        raffle.raffleId = raffleNonce;
        raffleNonce++;
        raffle.raffleOwner = payable(msg.sender);
        raffle.nftAddress = nftAddress;
        raffle.tokenId = tokenId;
        raffle.ticketsAvailable = ethInput / TICKET_PRICE;
        raffle.expiryTimestamp = expiryTimestamp;
        raffle.tokenType = tokenType;

        // set royalty info at creation to avoid unexpected changes in royalties when raffle is closed
        (address royaltyRecipient, uint64 royaltyPercentage) = getRoyaltyInfo(nftAddress, tokenId);
        raffle.royaltyPercentage = royaltyPercentage;
        raffle.royaltyRecipient = royaltyRecipient;
        transferNft(nftAddress, msg.sender, address(this), tokenId, tokenType);
        emit RaffleOpened(raffle.raffleId, nftAddress, tokenId, raffle.ticketsAvailable, raffle.expiryTimestamp);
    }

    /// @notice DeRafl Purchase tickets for a raffle
    /// @dev Allows a user to purchase a ticket batch for a raffle.
    /// Validates the raffle state.
    /// Creates a new ticketBatch and adds to ticketBatches mapping.
    /// Increments ticketOwner in ticketOwners mapping.
    /// Update state of Raffle with specified raffleId.
    /// Emit TicketsPurchased event.
    /// @param raffleId The address of the NFT being raffled
    /// @param ticketAmount The amount of tickets to purchase
    function buyTickets(uint64 raffleId, uint96 ticketAmount) external payable {
        Raffle storage raffle = raffles[raffleId];
        if (msg.sender == raffle.raffleOwner) revert RaffleOwnerCannotPurchaseTickets();
        if (raffle.raffleState != RaffleState.ACTIVE || block.timestamp > raffle.expiryTimestamp)
            revert InvalidRaffleState();
        uint256 ticketsRemaining = raffle.ticketsAvailable - raffle.ticketsSold;
        if (ticketAmount == 0 || ticketAmount > ticketsRemaining) revert TicketAmountInvalid();

        uint256 ethAmount = ticketAmount * TICKET_PRICE;
        if (ethAmount != msg.value) revert MsgValueInvalid();

        // increment the total tickets bought for this raffle by this address
        TicketOwner storage ticketData = ticketOwners[raffleId][msg.sender];
        ticketData.ticketsOwned += ticketAmount;

        uint96 batchId = raffle.batchIndex;
        // create a new batch purchase
        TicketBatch storage batch = ticketBatches[raffleId][batchId];
        batch.owner = msg.sender;
        batch.startTicket = raffle.ticketsSold + 1;
        batch.endTicket = raffle.ticketsSold + ticketAmount;

        raffle.ticketsSold += ticketAmount;
        raffle.batchIndex++;
        emit TicketPurchased(raffleId, batchId, msg.sender, batch.startTicket, ticketAmount);
    }

    /// @notice DeRafl starts the drawing process for a raffle
    /// @dev Sends a request to chainlink VRF for a random number used to draw a winner.
    /// Validates raffleState is closed (sold out), or raffle is expired.
    /// Validates tickets sold > 5 to enusre fees can be covered.
    /// Stores the chainlinkRequestId in chainlinkRequestIdMap against the raffleId.
    /// emits raffle closed event.
    /// @param raffleId The raffleId of the raffle being drawn
    function drawRaffle(uint64 raffleId) external {
        Raffle storage raffle = raffles[raffleId];
        if (raffle.raffleState != RaffleState.ACTIVE) revert InvalidRaffleState();
        if (raffle.ticketsSold < 6) revert InsufficientTicketsSold();

        bool soldOut = raffle.ticketsSold == raffle.ticketsAvailable;
        bool isExpired = block.timestamp > raffle.expiryTimestamp;
        if (!soldOut && !isExpired) revert InvalidRaffleState();

        uint256 chainlinkRequestId = requestRandomNumber();
        chainlinkRequestIdMap[chainlinkRequestId] = raffleId;

        raffle.raffleState = RaffleState.PENDING_DRAW;
        raffle.chainlinkRequestId = chainlinkRequestId;
        emit RaffleClosed(raffleId);
    }

    /// @notice Completes a raffle, releases prize and accumulated Eth to relevant stake holders
    /// @dev Validates that the batch referenced includes the winning ticket. Releases
    /// the nft and Ethereum
    /// @param raffleId The raffle Id of the raffle being released
    /// @param batchId The batch Id of the batch including the winning ticket
    function release(uint64 raffleId, uint96 batchId) external {
        Raffle storage raffle = raffles[raffleId];
        if (raffle.raffleState != RaffleState.DRAWN) revert InvalidRaffleState();

        TicketBatch storage batch = ticketBatches[raffleId][batchId];
        uint256 winningTicket = raffle.winningTicket;

        // confirm that the batch passed in includes the winning ticket
        if (winningTicket < batch.startTicket || winningTicket > batch.endTicket) revert RaffleBatchNotWinner();
        address winner = batch.owner;

        // update state before making any transfers
        raffle.raffleState = RaffleState.RELEASED;

        // send the nft to the winner
        transferNft(raffle.nftAddress, address(this), winner, raffle.tokenId, raffle.tokenType);
        raffle.winner = winner;

        // allocate and send the Eth
        uint256 ethRaised = raffle.ticketsSold * TICKET_PRICE;
        uint256 protocolEth = ethRaised * DERAFL_FEE_PERCENTAGE / FEE_DENOMINATOR;
        uint256 royaltyEth = raffle.royaltyPercentage == 0
            ? 0
            : (ethRaised * raffle.royaltyPercentage) / FEE_DENOMINATOR;
        uint256 ownerEth = ethRaised - protocolEth - royaltyEth;

        (bool feeCallSuccess, ) = deraflFeeCollector.call{value: protocolEth}("");
        if (!feeCallSuccess) revert SendEthFailed();

        (bool ownerCallSuccess, ) = raffle.raffleOwner.call{value: ownerEth}("");
        if (!ownerCallSuccess) revert SendEthFailed();

        if (royaltyEth > 0) {
            (bool royaltyCallSuccess, ) = payable(raffle.royaltyRecipient).call{value: royaltyEth}("");
            if (!royaltyCallSuccess) revert SendEthFailed();
        }

        emit RaffleReleased(raffleId, winner, royaltyEth, ownerEth);
    }

    /// @dev Changes a raffles state to REFUNDED, allowing participants to be issued refunds.
    /// A raffle can be refunded 2 days after it has expired, and is not in a RELEASED state
    /// @param raffleId The raffle id of the raffle being refunded
    function refundRaffle(uint64 raffleId) external {
        Raffle storage raffle = raffles[raffleId];
        if (raffle.raffleState == RaffleState.RELEASED || raffle.raffleState == RaffleState.REFUNDED)
            revert InvalidRaffleState();
        if (block.timestamp < raffle.expiryTimestamp + 2 days) revert TimeSinceExpiryInsufficientForRefund();
        raffle.raffleState = RaffleState.REFUNDED;
        emit RaffleRefunded(raffleId);
    }

    /// @dev Issues a refund to an individual participant for all tickets purchased (sum of all ticket batches)
    /// @param raffleId The raffle id of the raffle being refunded
    function refundTickets(uint64 raffleId) external {
        Raffle storage raffle = raffles[raffleId];
        if (raffle.raffleState != RaffleState.REFUNDED) revert InvalidRaffleState();
        TicketOwner storage ticketData = ticketOwners[raffleId][msg.sender];
        if (ticketData.isRefunded) revert TicketsAlreadyRefunded();

        // update refunded before sending any eth
        ticketData.isRefunded = true;
        uint256 refundAmount = ticketData.ticketsOwned * TICKET_PRICE;
        (bool success, ) = payable(msg.sender).call{value: refundAmount}("");
        if (!success) revert SendEthFailed();
        emit TicketRefunded(raffleId, msg.sender, refundAmount);
    }

    /// @dev Returns the NFT of a refunded raffle to the raffle owner
    /// @param raffleId The raffle id of the raffle
    function claimRefundedNft(uint64 raffleId) external {
        Raffle storage raffle = raffles[raffleId];
        if (raffle.raffleState != RaffleState.REFUNDED) revert InvalidRaffleState();
        transferNft(raffle.nftAddress, address(this), raffle.raffleOwner, raffle.tokenId, raffle.tokenType);
    }

    /// @notice Gets the royalty fee percentage of an nft. Returns a maximum of 10%
    /// @dev checks for erc2981 as a priority for royalties, followed by looksrare royaltyFeeRegistry
    /// @dev maximum 5% royalties
    /// @param nftAddress The address of the token being queried
    function getRoyaltyInfo(
        address nftAddress,
        uint256 tokenId
    ) public view returns (address feeReceiver, uint64 royaltyFee) {
        bool isErc2981 = IERC165(nftAddress).supportsInterface(INTERFACE_ID_ERC2981);
        if (isErc2981) {
            (bool status, bytes memory data) = nftAddress.staticcall(
                abi.encodeWithSelector(IERC2981.royaltyInfo.selector, tokenId, FEE_DENOMINATOR)
            );
            if (status) {
                (feeReceiver, royaltyFee) = abi.decode(data, (address, uint64));
            }
        } else {
            try royaltyFeeRegistry.royaltyFeeInfoCollection(nftAddress) returns (
                address,
                address _feeReceiver,
                uint256 _royaltyFee
            ) {
                feeReceiver = _feeReceiver;
                royaltyFee = uint64(_royaltyFee);
            } catch {
                return (address(0), 0);
            }
        }
        royaltyFee = royaltyFee > MAX_ROYALTY_FEE_PERCENTAGE ? MAX_ROYALTY_FEE_PERCENTAGE : royaltyFee;
        return (feeReceiver, royaltyFee);
    }

    /// @dev Requests a random number from chainlink VRF
    /// @return chainlinkRequestId of the request
    function requestRandomNumber() internal returns (uint256) {
        return
            COORDINATOR.requestRandomWords(keyHash, subscriptionId, requestConfirmations, callbackGasLimit, numWords);
    }

    /// @notice DeRafl Callable by chainlink VRF to receive a random number
    /// @dev Generates a winning ticket number between 0 - tickets sold for a raffle
    /// @param requestId The chainlinkRequestId which maps to raffle id
    /// @param randomWords random words sent by chainlink
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        uint64 raffleId = chainlinkRequestIdMap[requestId];
        Raffle storage raffle = raffles[raffleId];
        uint96 winningTicket = uint96(randomWords[0] % raffle.ticketsSold) + 1;
        raffle.winningTicket = winningTicket;
        raffle.raffleState = RaffleState.DRAWN;
        emit RaffleDrawn(raffleId, winningTicket);
    }

    /// @notice DeRafl transfers a erc721 or erc1155 token
    /// @dev uses the required interface depending on tokenType
    /// @param tokenAddress the address of the token
    /// @param from the owner transferring the token
    /// @param to the recipient of the token
    /// @param tokenId tokenId of the token being transfered
    /// @param tokenType the type of the token being transferred
    function transferNft(address tokenAddress, address from, address to, uint256 tokenId, TokenType tokenType) internal {
        if (tokenType == TokenType.ERC721) {
            IERC721 nftContract = IERC721(tokenAddress);
            nftContract.transferFrom(from, to, tokenId);
        } else {
            IERC1155 nftContract = IERC1155(tokenAddress);
            nftContract.safeTransferFrom(from, to, tokenId, 1, "");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
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
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IRoyaltyFeeRegistry {
    function royaltyFeeInfoCollection(address collection) external view returns (address, address, uint256);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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