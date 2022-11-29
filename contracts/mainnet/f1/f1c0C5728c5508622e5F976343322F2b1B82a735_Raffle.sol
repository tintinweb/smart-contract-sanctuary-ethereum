// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/PullPayment.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

/// @notice WIN3.FUN
/// Open platform for Web3 lucky draw, anyone can create a lucky draw seamlessly & participate in one securely.
/// Have fun winning in Web3~
/// @dev This contract used ChainLink VRF to generate random number.
/// See details https://docs.chain.link/docs/vrf/v2/introduction/
contract Raffle is
    AccessControl,
    Ownable,
    ReentrancyGuard,
    Pausable,
    PullPayment,
    EIP712,
    ERC721Holder,
    ERC1155Holder,
    VRFConsumerBaseV2
{
    /// @dev Store the lastest raffle id.
    uint32 private _idCounter;
    /// @dev Store all the raffle structs.
    mapping(uint32 => RaffleInfo) private _raffles;
    /// @dev Store the discounts information of a raffle.
    mapping(uint32 => TicketDiscount[]) private _ticketDiscounts;
    /// @dev Store the ticket sales of a raffle.
    mapping(uint32 => TicketSale[]) private _ticketSales;
    /// @dev Store the sold status for a specific buyer.
    mapping(uint32 => mapping(address => TicketCounter)) private _ticketCounter;
    /// @dev Store the draw information for a specific raffle.
    mapping(uint32 => RaffleDrawInfo) private _raffleDrawInfo;
    /// @dev The global configuration of this contract. For example the basic fees.
    GlobalConfig private _globalConfig;

    /// @notice Returns the information of a raffle with a given id.
    /// @param id The id of the raffle.
    /// @return see {RaffleInfo}
    function raffles(uint32 id) external view returns (RaffleInfo memory) {
        return _raffles[id];
    }

    /// @notice Return the ticket discount offers of a raffle.
    /// @param id The id of the raffle.
    /// @return see {TicketDiscount}
    function ticketDiscounts(uint32 id)
        external
        view
        returns (TicketDiscount[] memory)
    {
        return _ticketDiscounts[id];
    }

    /// @notice Return the ticket sale records of a raffle.
    /// @param id The id of the raffle.
    /// @return see {TicketSale}
    function ticketSale(uint32 id) external view returns (TicketSale[] memory) {
        return _ticketSales[id];
    }

    /// @notice Return the ticket sale records of a raffle.
    /// @param id The id of the raffle.
    /// @param saleId The id of the ticket sale.
    /// @return see {TicketSale}
    function ticketSale(uint32 id, uint256 saleId)
        external
        view
        returns (TicketSale memory)
    {
        return _ticketSales[id][saleId];
    }

    /// @notice Return the ticket sale statistics of a raffle.
    /// @param id The id of the raffle.
    /// @param buyer The account address of the buyer.
    /// @return see {TicketCounter}
    function ticketCounter(uint32 id, address buyer)
        external
        view
        returns (TicketCounter memory)
    {
        return _ticketCounter[id][buyer];
    }

    /// @notice Return the draw information of the raffle.
    /// @param id The id of the raffle.
    /// @return see {RaffleDrawInfo}
    function raffleDrawInfo(uint32 id)
        external
        view
        returns (RaffleDrawInfo memory)
    {
        return _raffleDrawInfo[id];
    }

    /// @notice Returns the view of {GlobalConfig}.
    /// @return see {GlobalConfig}
    function globalConfig() external view returns (GlobalConfig memory) {
        return _globalConfig;
    }

    /// @notice The data struct of a raffle
    /// - tokenType see {TokenType}
    /// - status The status of the raffle.
    /// - tokenAddress The address of the token contract.
    /// - verifySignature If true, verify that the buyer is whitelisted and then able to participate that not open to everyone. Otherwise not verify.
    /// - maxTicketsPerBuyer The maximum number of tickets that a buyer can buy.
    /// - maxTicketsNum The maximum number of tickets that can be sold.
    /// - seller The seller of the raffle.
    /// - winner The winner of the raffle.
    /// - verifyBuyerHolderToken Verify that the buyer holds the token if the value is not address(0).
    /// - drawer The drawer of the raffle.
    /// - tokenId The id of the token. If the token is ERC20, the value is 0.
    /// - tokenAmount The amount of the token. If the token is ERC721, the value is 1.
    /// - pricePerTicket The price of each ticket.
    /// - releaseAt The estimated time to draw the winner.
    /// - createAt The time when the raffle is created.
    /// - drawAt The time when the raffle is drown.
    /// - endAt The time when the raffle is fulfilled.
    /// @dev 12 slots
    struct RaffleInfo {
        TokenType tokenType;
        Status status;
        address tokenAddress;
        bool verifySignature;
        uint32 maxTicketsPerBuyer;
        uint32 maxTicketsNum;
        address seller;
        address winner;
        address verifyBuyerHolderToken;
        address drawer;
        uint256 tokenId;
        uint256 tokenAmount;
        uint256 pricePerTicket;
        uint256 releaseAt;
        uint256 createdAt;
        uint256 drawAt;
        uint256 endAt;
    }

    /// @notice All the possible statuses that a raffle can be in.
    /// - Created: Seller created a raffle, open the ticket sale.
    /// - Drawing: The operator is drawing the winner.
    /// - Drawn: The raffle is drown, the winner is determined.
    /// - Ended: The raffle is settled, the winner has received the prize.
    /// - Canceled: The raffle is canceled By the seller.
    /// - RefundRequested: The seller sumbit a refund request to operator, and waiting for approval.
    /// - RefundedApproved: The operator approved the refund request, allow the seller refund the raffle.
    /// - Refunded: The seller refunded the raffle, return the tickets to the buyer and close the raffle.
    /// - Recycled: The raffle is drawn, but no one willing to claim the prize.
    /// .           Admin will recycle this raffle's asset after {recycleDays} passed.
    enum Status {
        Created,
        Drawing,
        Drawn,
        Ended,
        Canceled,
        RefundRequested,
        RefundApproved,
        Refunded,
        Recycled
    }

    /// @notice The supported protocol type of a token.
    enum TokenType {
        ERC20,
        ERC721,
        ERC1155
    }

    /// @notice The data struct of a discount offer of a raffle
    /// - minTicketsNum The minimum number of tickets that trigger the discount.
    /// - pricePerTicket The price of each ticket that offer the discount.
    struct TicketDiscount {
        uint256 minTicketsNum;
        uint256 pricePerTicket;
    }

    /// @notice The data struct of a ticket sale
    /// - isRefunded If true, the buyer refunded the tickets.
    /// - buyer The account address of the buyer.
    /// - cumulativeSoldCount The number of tickets sold.
    /// - soldAmount The amount of the buyer paid.
    /// @dev For example:
    ///   - player 1: (0, 5]
    ///   - player 2: (5, 7]
    /// @dev 2 slots
    struct TicketSale {
        bool isRefunded;
        address buyer;
        uint32 cumulativeSoldCount;
        uint256 soldAmount;
        uint256 cumulativeSoldAmount;
    }

    /// @notice The data struct of the statistics of raffle's ticket sale.
    /// - totalSoldCount The total number of tickets sold.
    /// - totalSoldAmount The total amount of the buyer paid.
    /// @dev 2 slots
    struct TicketCounter {
        uint256 totalSoldCount;
        uint256 totalSoldAmount;
    }

    /// @notice The status of the request random number for the raffle.
    /// - fulfilled: Whether the request has been fulfilled by the VRF coordinator.
    /// - drawFee The fee of the drawer.
    /// - bonus The bonus of the drawer.
    /// - requestId: The id of randomness request that VRF coordinator returns.
    /// - rawRandomNumber: The raw random numbers from the VRF coordinator.
    /// @dev 5 slots
    struct RaffleDrawInfo {
        bool fulfilled;
        uint256 drawFee;
        uint256 bonus;
        uint256 requestId;
        uint256 rawRandomNumber;
    }

    /// @notice This struct hold the global configuration about this contract.
    /// Anyone can access the values, the admin has permission to update after notice players.
    /// - cancelFee The fee to cancel a raffle. Value range in eth: [0, 0.1]
    /// - refundFee The fee to refund a raffle. Value range in eth: [0, 0.1]
    /// - drawFee The fee to draw a raffle. Value range in eth: [0, 0.1]
    /// - platformWallet The wallet to receive the commission.
    /// - vrfSubId The subscription id of chainlink.
    /// - bonusRate The bonus rate for the drawer of a raffle. Value range: [0, 5000]
    /// - commissionRate The commission rate of a raffle. Value range: [0, 2000]
    /// - vrfAddress The contract address of VRF.
    /// - vrfKeyHash The key hash of the VRF coordinator.
    /// - vrfCallbackGasLimit The gas limit send to VRF for the callback function.
    /// - recycleDays The days after drew the winner to recycle the raffle. Value range: [30, 90]
    /// - signerWallet The wallet hold by owner that generate a signature for a whitelist user.
    /// @dev 6 slots
    struct GlobalConfig {
        uint256 cancelFee;
        uint256 refundFee;
        uint256 drawFee;
        address payable platformWallet;
        uint64 vrfSubId;
        uint16 bonusRate;
        uint16 commissionRate;
        address vrfAddress;
        bytes32 vrfKeyHash;
        uint32 vrfCallbackGasLimit;
        uint32 recycleDays;
        address signerWallet;
    }

    /// @dev Raffle Events
    event RaffleCreated(uint32 id);
    event RaffleUpdated(uint32 id);
    event RaffleCanceled(uint32 id);
    event RaffleRefundRequested(uint32 id);
    event RaffleRefundApproved(uint32 id);
    event RaffleRefundRejected(uint32 id);
    event RaffleRefunded(uint32 id);
    event RaffleRefundClaimed(address indexed account, uint256 refundAmount);
    event RaffleDrawStarted(uint32 indexed id, address drawer, uint256 fee);
    event RaffleDrawFinished(
        uint32 indexed id,
        uint256 winnerNumber,
        address winner
    );
    event RaffleEnded(
        uint32 indexed id,
        address winner,
        uint256 paySeller,
        uint256 payDrawer,
        uint256 payPlatform
    );
    event RaffleRecycled(
        uint32 indexed id,
        address receiver,
        uint256 payReceiver,
        uint256 payPlatform
    );
    event RaffleStatusChanged(uint32 indexed id, Status from, Status to);
    event TicketSold(
        uint32 indexed id,
        address indexed buyer,
        uint32 soldCount,
        uint256 soldAmount
    );
    event RequestRandomSent(uint32 indexed id, uint256 requestId);
    event RequestRandomFulfilled(
        uint32 indexed id,
        uint256 indexed requestId,
        uint256 randomNumer
    );
    event GlobalConfigurationChanged();

    constructor(GlobalConfig memory globalConfig_)
        EIP712(CONTRACT_NAME, CONTRACT_VERSION)
        VRFConsumerBaseV2(globalConfig_.vrfAddress)
    {
        _setRoleAdmin(ADMIN, OWNER);
        _grantRole(OWNER, msg.sender);
        _grantRole(ADMIN, msg.sender);
        COORDINATOR = VRFCoordinatorV2Interface(globalConfig_.vrfAddress);
        _globalConfig = globalConfig_;
    }

    /// @notice Initialize a raffle, stake the token to the contract.
    /// @param tokenType_ Required. see {TokenType}
    /// @param tokenAddress_ Required. The address of the token contract.
    /// @param tokenId_ Optional. The id of the token. If the token is ERC20, the value is 0.
    /// @param tokenAmount_ Optional. The amount of the token. If the token is ERC721, the value is 0.
    /// @param pricePerTicket_ Optional. The price of each ticket. Be careful if the values is 0, the ticket is free to sell.
    /// @param maxTicketsPerBuyer_ Optional. The maximum number of tickets that a buyer can buy. If the value is 0, no limit on each person can buy.
    /// @param maxTicketsNum_ Optional. The maximum number of tickets that can be sold. If the value is 0, no limit on the raffle can sell.
    /// @param releaseAt_ The estimated time in seconds to draw the winner. If the value is 0, there is no strict drawing time.
    /// @param verifyBuyerHolderToken_ Verify that the buyer holds the token. If the value is 0, not verify.
    /// @param verifySignature_ If true, verify that the buyer hold the correct signature while buying the tickets. Otherwise not verify.
    /// @param ticketDiscounts_ Sorted array of {TicketDiscount}. If the array is empty, no discounts on this raffle.
    /// @return The id of the raffle.
    /// @dev Create a raffle struct and store it in the raffles array. Then the seller transfer the token to the contract.
    /// @dev maxTicketsNum_ or releaseAt_ can not be 0 at the same time. Draw Condition.
    ///     1. maxTicketsNum_ > 0 && releaseAt_ == 0 ---> Able to draw when the tickets sold over the maxTicketsNum_.
    ///     2. maxTicketsNum_ == 0 && releaseAt_ > 0 ---> Able to draw when the time due to the releaseAt_.
    ///     3. maxTicketsNum_ > 0 && releaseAt_ > 0 ---> Able to draw when any of above conditions are met.
    function create(
        TokenType tokenType_,
        address tokenAddress_,
        uint256 tokenId_,
        uint256 tokenAmount_,
        uint256 pricePerTicket_,
        uint32 maxTicketsPerBuyer_,
        uint32 maxTicketsNum_,
        uint256 releaseAt_,
        address verifyBuyerHolderToken_,
        bool verifySignature_,
        TicketDiscount[] calldata ticketDiscounts_
    ) external whenNotPaused returns (uint32) {
        require(
            maxTicketsNum_ != 0 || releaseAt_ != 0,
            "Raffle: Invalid draw condition"
        );

        RaffleInfo memory raffle = RaffleInfo({
            tokenType: tokenType_,
            tokenAddress: tokenAddress_,
            tokenId: tokenId_,
            tokenAmount: tokenAmount_,
            pricePerTicket: pricePerTicket_,
            maxTicketsPerBuyer: maxTicketsPerBuyer_,
            maxTicketsNum: maxTicketsNum_,
            releaseAt: releaseAt_,
            verifyBuyerHolderToken: verifyBuyerHolderToken_,
            verifySignature: verifySignature_,
            seller: msg.sender,
            drawer: address(0),
            winner: address(0),
            createdAt: block.timestamp,
            drawAt: 0,
            endAt: 0,
            status: Status.Created
        });
        /// store the raffle
        _raffles[++_idCounter] = raffle;

        // set ticket discounts
        if (ticketDiscounts_.length > 0) {
            // clear and reset the value.
            delete _ticketDiscounts[_idCounter];
            for (uint8 i = 0; i < ticketDiscounts_.length; i++) {
                _ticketDiscounts[_idCounter].push(ticketDiscounts_[i]);
            }
        }

        _tokenTransferIn(
            msg.sender,
            tokenType_,
            tokenAddress_,
            tokenId_,
            tokenAmount_
        );

        /// emit the event
        emit RaffleCreated(_idCounter);

        return _idCounter;
    }

    /// @notice Update the raffle information.
    /// @param pricePerTicket_ Optional. The price of each ticket. Be careful if the values is 0, the ticket is free to sell.
    /// @param maxTicketsPerBuyer_ Optional. The maximum number of tickets that a buyer can buy. If the value is 0, no limit on each person can buy.
    /// @param maxTicketsNum_ Optional. The maximum number of tickets that can be sold. If the value is 0, no limit on the raffle can sell.
    /// @param releaseAt_ The estimated time in seconds to draw the winner. If the value is 0, there is no strict drawing time.
    /// @param verifyBuyerHolderToken_ Verify that the buyer holds the token. If the value is 0, not verify.
    /// @param verifySignature_ If true, verify that the buyer hold the correct signature while buying the tickets. Otherwise not verify.
    /// @param ticketDiscounts_ Sorted array of {TicketDiscount}. If the array is empty, no discounts on this raffle.
    function update(
        uint32 id,
        uint256 pricePerTicket_,
        uint32 maxTicketsPerBuyer_,
        uint32 maxTicketsNum_,
        uint256 releaseAt_,
        address verifyBuyerHolderToken_,
        bool verifySignature_,
        TicketDiscount[] calldata ticketDiscounts_
    ) external onlySeller(id) ableToEdit(id) {
        _updateRaffle(
            id,
            pricePerTicket_,
            maxTicketsPerBuyer_,
            maxTicketsNum_,
            releaseAt_,
            verifyBuyerHolderToken_,
            verifySignature_,
            ticketDiscounts_
        );
    }

    /// @notice Cancel a raffle, return the token to the seller.
    /// @param id the id of the raffle need to be canceled.
    function cancel(uint32 id)
        external
        payable
        nonReentrant
        onlySeller(id)
        ableToEdit(id)
    {
        require(
            msg.value == _globalConfig.cancelFee,
            "Raffle: Wrong cancel fee"
        );

        RaffleInfo storage raffle = _raffles[id];
        raffle.endAt = block.timestamp;
        raffle.status = Status.Canceled;

        /// return the token to the seller
        _tokenTransferOut(
            raffle.seller,
            raffle.tokenType,
            raffle.tokenAddress,
            raffle.tokenId,
            raffle.tokenAmount
        );

        /// emit event
        emit RaffleCanceled(id);
    }

    /// @dev check the caller is the seller of the raffle.
    modifier onlySeller(uint32 id) {
        require(msg.sender == _raffles[id].seller, "Raffle: Only seller");
        _;
    }

    /// @dev check the raffle is on a specific status.
    modifier onlyOnStatus(uint32 id, Status status) {
        require(_raffles[id].status == status, "Raffle: Wrong status");
        _;
    }

    /// @dev Check the raffle is able to edit.
    /// @dev Raffle is able to edit if the status is Created and not sell the ticket.
    modifier ableToEdit(uint32 id) {
        require(_raffles[id].status == Status.Created, "Raffle: Wrong status");
        require(_ticketSaleTotalCount(id) == 0, "Raffle: Already sale");
        _;
    }

    /// @dev Check the raffle is able to sell.
    /// @dev Raffle is able to sell if the status is Created or RefundRequested, RefundApproved
    modifier ableToSell(uint32 id) {
        require(
            _raffles[id].status == Status.Created ||
                _raffles[id].status == Status.RefundRequested ||
                _raffles[id].status == Status.RefundApproved,
            "Raffle: Wrong status"
        );
        _;
    }

    /// @dev Update the raffle information.
    /// @param pricePerTicket_ Optional. The price of each ticket. Be careful if the values is 0, the ticket is free to sell.
    /// @param maxTicketsPerBuyer_ Optional. The maximum number of tickets that a buyer can buy. If the value is 0, no limit on each person can buy.
    /// @param maxTicketsNum_ Optional. The maximum number of tickets that can be sold. If the value is 0, no limit on the raffle can sell.
    /// @param releaseAt_ The estimated time in seconds to draw the winner. If the value is 0, there is no strict drawing time.
    /// @param verifyBuyerHolderToken_ Verify that the buyer holds the token. If the value is 0, not verify.
    /// @param verifySignature_ If true, verify that the buyer hold the correct signature while buying the tickets. Otherwise not verify.
    /// @param ticketDiscounts_ Sorted array of {TicketDiscount}. If the array is empty, no discounts on this raffle.
    function _updateRaffle(
        uint32 id,
        uint256 pricePerTicket_,
        uint32 maxTicketsPerBuyer_,
        uint32 maxTicketsNum_,
        uint256 releaseAt_,
        address verifyBuyerHolderToken_,
        bool verifySignature_,
        TicketDiscount[] calldata ticketDiscounts_
    ) internal {
        RaffleInfo storage raffle = _raffles[id];
        raffle.pricePerTicket = pricePerTicket_;
        raffle.maxTicketsPerBuyer = maxTicketsPerBuyer_;
        raffle.maxTicketsNum = maxTicketsNum_;
        raffle.releaseAt = releaseAt_;
        raffle.verifyBuyerHolderToken = verifyBuyerHolderToken_;
        raffle.verifySignature = verifySignature_;

        // set ticket discounts
        if (ticketDiscounts_.length > 0) {
            // clear and reset the value.
            delete _ticketDiscounts[id];
            for (uint8 i = 0; i < ticketDiscounts_.length; i++) {
                _ticketDiscounts[id].push(ticketDiscounts_[i]);
            }
        }

        /// emit event
        emit RaffleUpdated(id);
    }

    ///////////////////////////////////////////////////////////////////////
    /////////////////////////  Refund ////////////////////////////////////

    /// @notice Request a refund, the operator will approve the refund.
    function requestRefund(uint32 id)
        external
        onlySeller(id)
        onlyOnStatus(id, Status.Created)
    {
        _raffles[id].status = Status.RefundRequested;

        /// emit event
        emit RaffleRefundRequested(id);
    }

    /// @notice Approve the refund request, the seller can refund the raffle.
    function approveRefund(uint32 id)
        external
        onlyRole(ADMIN)
        onlyOnStatus(id, Status.RefundRequested)
    {
        _raffles[id].status = Status.RefundApproved;

        /// emit event
        emit RaffleRefundApproved(id);
    }

    /// @notice Reject the refund request, the seller can not refund the raffle.
    function rejectRefund(uint32 id)
        external
        onlyRole(ADMIN)
        onlyOnStatus(id, Status.RefundRequested)
    {
        _raffles[id].status = Status.Created;

        /// emit event
        emit RaffleRefundRejected(id);
    }

    /// @notice Refund the raffle, return the token to the seller.
    /// @dev see {PullPayment}
    function refund(uint32 id)
        external
        payable
        nonReentrant
        whenNotPaused
        onlySeller(id)
        onlyOnStatus(id, Status.RefundApproved)
    {
        require(msg.value == _globalConfig.refundFee, "Raffle: Invalid fee");

        /// change the status to refunded
        RaffleInfo storage raffle = _raffles[id];
        raffle.status = Status.Refunded;
        raffle.endAt = block.timestamp;

        // refund the ticket price to the buyer
        TicketSale[] storage sales = _ticketSales[id];
        for (uint256 i = 0; i < sales.length; i++) {
            TicketSale storage sale = sales[i];
            if (sale.isRefunded) {
                continue;
            } else {
                sale.isRefunded = true;
                _asyncTransfer(sale.buyer, sale.soldAmount);
            }
        }

        /// transfer the token to the seller
        _tokenTransferOut(
            raffle.seller,
            raffle.tokenType,
            raffle.tokenAddress,
            raffle.tokenId,
            raffle.tokenAmount
        );

        /// emit event
        emit RaffleRefunded(id);
    }

    /// @notice Return the total refund amount to the buyer.
    function claimRefund() external nonReentrant whenNotPaused {
        require(msg.sender != address(0), "Raffle: Zero address");
        uint256 amount = payments(msg.sender);
        require(amount > 0, "Raffle: No refund payments");
        withdrawPayments(payable(msg.sender));

        /// emit event
        emit RaffleRefundClaimed(msg.sender, amount);
    }

    ///////////////////////////////////////////////////////////////////////
    /////////////////////////  Ticket  ////////////////////////////////////

    /// @notice The buyer call this function to buy tickets.
    /// @param id Required. The id of the raffle.
    /// @param ticketNum Required. The number of tickets to buy.
    /// @param signature Optional. The signature of the buyer.
    /// @param expireAt Optional. The timestamp of the request expired.
    function buyTicket(
        uint32 id,
        uint32 ticketNum,
        uint256 expireAt,
        bytes calldata signature
    ) external payable nonReentrant whenNotPaused ableToSell(id) {
        require(ticketNum > 0, "Raffle: Zero tickets");
        require(msg.sender != address(0), "Raffle: Zero address");
        require(msg.sender != _raffles[id].seller, "Raffle: Seller can't buy");

        RaffleInfo storage raffle = _raffles[id];
        uint32 totalCount = _ticketSaleTotalCount(id);
        uint256 totalAmount = _ticketSaleTotalAmount(id);
        // Verify the signature
        if (raffle.verifySignature) {
            bytes32 digest = _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        BUY_TICKET_HASH,
                        msg.sender,
                        id,
                        ticketNum,
                        expireAt
                    )
                )
            );
            (address recovered, ECDSA.RecoverError error) = ECDSA.tryRecover(
                digest,
                signature
            );
            if (
                error != ECDSA.RecoverError.NoError ||
                recovered != _globalConfig.signerWallet
            ) {
                revert("Raffle: Invalid signature");
            }
            require(block.timestamp < expireAt, "Raffle: Signature expired");
        }

        // Verify the tickets is enough for this buyer.
        if (raffle.maxTicketsNum > 0) {
            require(
                totalCount + ticketNum <= raffle.maxTicketsNum,
                "Raffle: Insufficient tickets"
            );
        }

        // Verify if exceed the max tickets per buyer.
        if (raffle.maxTicketsPerBuyer > 0) {
            require(
                _ticketCounter[id][msg.sender].totalSoldCount + ticketNum <=
                    raffle.maxTicketsPerBuyer,
                "Raffle: Exceeded limit for buyer"
            );
        }

        // Verify the buyer holds the token.
        if (raffle.verifyBuyerHolderToken != address(0)) {
            require(
                raffle.verifyBuyerHolderToken._ownsAnyTokens(msg.sender),
                "Raffle: Not token owner"
            );
        }

        // Compute the price of the each ticket according to the ticket discount
        uint256 finalPrice = raffle.pricePerTicket;
        for (uint256 i = 0; i < _ticketDiscounts[id].length; i++) {
            if (ticketNum < _ticketDiscounts[id][i].minTicketsNum) {
                break;
            }
            finalPrice = _ticketDiscounts[id][i].pricePerTicket;
        }
        /// Verify the totolPrice is equal to the msg.value in the transaction.
        require(finalPrice * ticketNum == msg.value, "Raffle: Illegal price");

        /// Generate the ticket sale struct and store it in the ticketSales array.
        _ticketSales[id].push(
            TicketSale({
                isRefunded: false,
                buyer: msg.sender,
                cumulativeSoldCount: totalCount + ticketNum,
                soldAmount: msg.value,
                cumulativeSoldAmount: totalAmount + msg.value
            })
        );

        /// Increase the sold count and amount of the raffle.
        _ticketCounter[id][msg.sender].totalSoldCount += ticketNum;
        _ticketCounter[id][msg.sender].totalSoldAmount += msg.value;

        // emit ticket sold event
        emit TicketSold(id, msg.sender, ticketNum, msg.value);
    }

    ///@notice Returns the total count that tickets sales by a raffle for now.
    ///@param id the id of the raffle
    ///@return value total number of ticket sales.
    function ticketSaleTotalCount(uint32 id)
        external
        view
        returns (uint32 value)
    {
        return _ticketSaleTotalCount(id);
    }

    ///@notice Returns the total amount that raised by a raffle for now.
    ///@param id the id of the raffle
    ///@return value total number of ticket sales.
    function ticketSaleTotalAmount(uint32 id)
        external
        view
        returns (uint256 value)
    {
        return _ticketSaleTotalAmount(id);
    }

    ///@dev Returns the total count that tickets sales by a raffle for now.
    function _ticketSaleTotalCount(uint32 id) private view returns (uint32) {
        uint arrLength = _ticketSales[id].length;
        return
            arrLength == 0
                ? 0
                : _ticketSales[id][arrLength - 1].cumulativeSoldCount;
    }

    ///@dev Returns the total amount that raised by a raffle for now.
    function _ticketSaleTotalAmount(uint32 id) private view returns (uint256) {
        uint arrLength = _ticketSales[id].length;
        return
            arrLength == 0
                ? 0
                : _ticketSales[id][arrLength - 1].cumulativeSoldAmount;
    }

    ///////////////////////////////////////////////////////////////////////
    /////////////////////////  Draw Winner    /////////////////////////////
    /// @dev The mapping of vrf request id and raffle id.
    mapping(uint256 => uint32) private _requestRandomRaffleId;

    /// @notice Draw a raffle that fulfilled the draw condition.
    /// Pay a basic draw fee, and earn the bonus when the winner claim the prize.
    /// @param id The id of the raffle.
    /// @dev Request random numbers from the VRF coordinator and waiting for the reply.
    function draw(uint32 id)
        external
        payable
        nonReentrant
        whenNotPaused
        ableToSell(id)
    {
        require(msg.value == _globalConfig.drawFee, "Raffle: Invalid fee");
        RaffleInfo storage raffle = _raffles[id];

        require(_ticketSaleTotalCount(id) > 0, "Raffle: No tickets sold");
        // Check the sold ticket is greater than the max tickets for sale.
        bool isSoldOut = raffle.maxTicketsNum > 0 &&
            raffle.maxTicketsNum <= _ticketSaleTotalCount(id);
        // Check the transaction time is after the release time.
        bool isDue = raffle.releaseAt > 0 &&
            raffle.releaseAt <= block.timestamp;
        require(isSoldOut || isDue, "Raffle: Can't draw now");

        // update raffle
        raffle.drawer = msg.sender;
        raffle.status = Status.Drawing;

        // Request random number for this raffle
        // Will revert if subscription is not set and funded.
        uint256 requestId = COORDINATOR.requestRandomWords(
            _globalConfig.vrfKeyHash,
            _globalConfig.vrfSubId,
            3,
            _globalConfig.vrfCallbackGasLimit,
            1
        );
        /// take a snapshot of the current contract configuration.
        _raffleDrawInfo[id] = RaffleDrawInfo({
            drawFee: msg.value,
            bonus: (msg.value * _globalConfig.bonusRate) / 10000,
            requestId: requestId,
            fulfilled: false,
            rawRandomNumber: 0
        });
        _requestRandomRaffleId[requestId] = id;

        emit RequestRandomSent(id, requestId);
        // emit the draw event
        emit RaffleDrawStarted(id, msg.sender, msg.value);
    }

    /// @dev Received the callback from the VRF coordinator.
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
        internal
        override
    {
        uint32 id = _requestRandomRaffleId[requestId];
        require(_raffles[id].status == Status.Drawing, "Raffle: Wrong status");
        RaffleDrawInfo storage drawInfo = _raffleDrawInfo[id];
        require(!drawInfo.fulfilled, "Raffle: The random is fulfilled");

        // update info
        drawInfo.fulfilled = true;
        drawInfo.rawRandomNumber = randomWords[0];

        // compute winner number
        uint256 winnerNumber = (drawInfo.rawRandomNumber %
            _ticketSaleTotalCount(id)) + 1;
        // find winner index in the array
        uint256 winnerIndex = _findUpperBound(_ticketSales[id], winnerNumber);

        // update the raffle status
        RaffleInfo storage raffle = _raffles[id];
        raffle.winner = _ticketSales[id][winnerIndex].buyer;
        raffle.status = Status.Drawn;
        raffle.drawAt = block.timestamp;

        emit RequestRandomFulfilled(
            id,
            requestId,
            _raffleDrawInfo[id].rawRandomNumber
        );

        // emit the event
        emit RaffleDrawFinished(id, winnerNumber, raffle.winner);
    }

    /**
     * @dev Searches a sorted `array` and returns the first index that contains
     * a value greater or equal to `element`. If no such index exists (i.e. all
     * values in the array are strictly less than `element`), the array length is
     * returned. Time complexity O(log n).
     *
     * `array` is expected to be sorted in ascending order, and to contain no
     * repeated elements.
     *
     * @dev see https://docs.openzeppelin.com/contracts/3.x/api/utils#Arrays
     */
    function _findUpperBound(TicketSale[] storage array, uint256 element)
        internal
        view
        returns (uint256)
    {
        if (array.length == 0) {
            return 0;
        }

        uint256 low = 0;
        uint256 high = array.length;

        while (low < high) {
            uint256 mid = Math.average(low, high);

            // Note that mid will always be strictly less than high (i.e. it will be a valid array index)
            // because Math.average rounds down (it does integer division with truncation).
            if (array[mid].cumulativeSoldCount > element) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        // At this point `low` is the exclusive upper bound. We will return the inclusive upper bound.
        if (low > 0 && array[low - 1].cumulativeSoldCount == element) {
            return low - 1;
        } else {
            return low;
        }
    }

    /// @notice Trigger a settlment request for the raffle.
    /// 1. The caller need to pay the draw fee and bonus to the drawer.
    /// 2. Transfer the token to the winner.
    /// 3. Transfer the earning to the seller.
    /// 4. Transfer the commission fee to the contract.
    function claimPrize(uint32 id)
        external
        payable
        nonReentrant
        whenNotPaused
        onlyOnStatus(id, Status.Drawn)
    {
        uint256 payDrawer = _raffleDrawInfo[id].drawFee +
            _raffleDrawInfo[id].bonus;
        require(msg.value == payDrawer, "Raffle: Invalid fee");

        // settlement fees
        uint256 payPlatform = (_ticketSaleTotalAmount(id) *
            _globalConfig.commissionRate) / 10000;
        uint256 paySeller = _ticketSaleTotalAmount(id) - payPlatform;

        RaffleInfo storage raffle = _raffles[id];

        // Change the status of the raffle
        raffle.status = Status.Ended;
        raffle.endAt = block.timestamp;

        // Split and transfer the earning
        if (paySeller > 0) {
            (bool sent, ) = raffle.seller.call{value: paySeller}("");
            require(sent, "Raffle: Failed send ether to seller");
        }

        if (payDrawer > 0) {
            (bool sent, ) = raffle.drawer.call{value: payDrawer}("");
            require(sent, "Raffle: Failed send ether to drawer");
        }

        if (payPlatform > 0) {
            (bool sent, ) = _globalConfig.platformWallet.call{
                value: payPlatform
            }("");
            require(sent, "Raffle: Failed send ether to platform");
        }

        // Transfer the token to the winner
        _tokenTransferOut(
            raffle.winner,
            raffle.tokenType,
            raffle.tokenAddress,
            raffle.tokenId,
            raffle.tokenAmount
        );

        emit RaffleEnded(id, raffle.winner, paySeller, payDrawer, payPlatform);
    }

    ///////////////////////////////////////////////////////////////////////
    /////////////////////////  Token Transfer /////////////////////////////
    using TokenHelper for address;

    /// @dev Event emitted when a token is transferred in.
    event TokenTransferIn(
        address indexed from,
        TokenType indexed tokenType,
        address indexed tokenAddress,
        uint256 tokenId,
        uint256 tokenAmount
    );

    /// @dev Event emitted when a token is transferred out.
    event TokenTransferOut(
        address indexed to,
        TokenType indexed tokenType,
        address indexed tokenAddress,
        uint256 tokenId,
        uint256 tokenAmount
    );

    /// @notice Transfer out the token to a given address.
    /// @param from The address to transfer to.
    /// @param tokenType see {TokenType}
    /// @param tokenAddress The address of the token contract.
    /// @param tokenId The id of the token. If the token is ERC20, the value is 0.
    /// @param tokenAmount The amount of the token. If the token is ERC721, the value is 1.
    function _tokenTransferIn(
        address from,
        TokenType tokenType,
        address tokenAddress,
        uint256 tokenId,
        uint256 tokenAmount
    ) internal {
        tokenAddress._transfer(tokenId, tokenAmount, from, address(this));

        emit TokenTransferIn(
            from,
            tokenType,
            tokenAddress,
            tokenId,
            tokenAmount
        );
    }

    /// @notice Transfer out the token to a given address.
    /// @param to The address to transfer to.
    /// @param tokenType see {TokenType}
    /// @param tokenAddress The address of the token contract.
    /// @param tokenId The id of the token. If the token is ERC20, the value is 0.
    /// @param tokenAmount The amount of the token. If the token is ERC721, the value is 1.
    function _tokenTransferOut(
        address to,
        TokenType tokenType,
        address tokenAddress,
        uint256 tokenId,
        uint256 tokenAmount
    ) private {
        if (tokenType == TokenType.ERC20) {
            IERC20(tokenAddress).transfer(to, tokenAmount);
        } else {
            tokenAddress._transfer(tokenId, tokenAmount, address(this), to);
        }

        emit TokenTransferOut(
            to,
            tokenType,
            tokenAddress,
            tokenId,
            tokenAmount
        );
    }

    ///////////////////////////////////////////////////////////////////////
    /////////////////////////  Admin   ////////////////////////////////////

    /// @notice Set the global config of the contract.
    /// @param config_ see {GlobalConfig}
    /// @dev only admin has the permission to set the global config.
    function setGlobalConfig(GlobalConfig calldata config_)
        external
        onlyRole(ADMIN)
    {
        require(config_.cancelFee <= 0.1 ether, "Raffle: Invalid cancel Fee");
        require(config_.refundFee <= 0.1 ether, "Raffle: Invalid refund Fee");
        require(config_.drawFee <= 0.1 ether, "Raffle: Invalid draw Fee");
        require(
            config_.bonusRate >= 0 && config_.bonusRate <= 5000,
            "Raffle: Illegal bonusRate"
        );
        require(
            config_.commissionRate >= 0 && config_.commissionRate <= 2000,
            "Raffle: Illegal commissionRate"
        );
        require(
            config_.recycleDays >= 30 && config_.recycleDays >= 90,
            "Raffle: Illegal recycleDays"
        );
        require(
            config_.platformWallet != address(0),
            "Raffle: Illegal platformWallet"
        );
        require(config_.vrfKeyHash != bytes32(0), "Raffle: Illegal vrfKeyHash");
        require(
            config_.vrfCallbackGasLimit != 0,
            "Raffle: Illegal vrfCallbackGasLimit"
        );
        require(config_.vrfAddress != address(0), "Raffle: Illegal vrfAddress");
        require(config_.vrfSubId != 0, "Raffle: Illegal vrfSubId");
        require(
            config_.signerWallet != address(0),
            "Raffle: Illeagl signerWallet"
        );

        _globalConfig = config_;

        /// emit event
        emit GlobalConfigurationChanged();
    }

    /// @notice An emergency stop mechanism to the contract running.
    /// @dev only admin has the permission to pause the contract.
    function pause() external onlyRole(ADMIN) {
        _pause();
    }

    /// @notice Keep running when everything is ok.
    /// @dev only admin has the permission to unpause the contract.
    function unpause() external onlyRole(ADMIN) {
        _unpause();
    }

    /// @notice  An emergency mechanism to change the status of a specific raffle.
    /// @dev only admin has the permission.
    function changeStatusEmergency(uint32 id, Status status)
        external
        onlyRole(ADMIN)
    {
        Status old = _raffles[id].status;
        _raffles[id].status = status;

        emit RaffleStatusChanged(id, old, status);
    }

    /// @notice The input struct of method #issueFreeTickets
    /// - account Issue free ticket to address.
    /// - ticketNum The number of free tickets.
    /// @dev 1 slot
    struct FreeTicket {
        address account;
        uint32 ticketNum;
    }

    /// @notice Issue free tickets to some specific address. Only used for raffles which created by owner.
    /// @param id The id of the raffle.
    /// @param freeTickets see {FreeTicket}
    function issueFreeTickets(uint32 id, FreeTicket[] calldata freeTickets)
        external
        onlyRole(ADMIN)
        onlySeller(id)
        ableToSell(id)
    {
        require(freeTickets.length > 0, "Raffle: Empty array");

        for (uint32 i = 0; i < freeTickets.length; i++) {
            _ticketSales[id].push(
                TicketSale({
                    isRefunded: false,
                    buyer: freeTickets[i].account,
                    cumulativeSoldCount: _ticketSaleTotalCount(id) +
                        freeTickets[i].ticketNum,
                    soldAmount: 0,
                    cumulativeSoldAmount: _ticketSaleTotalAmount(id)
                })
            );

            _ticketCounter[id][freeTickets[i].account]
                .totalSoldCount += freeTickets[i].ticketNum;
        }
    }

    /// @notice Recycle the raffles which no one claimed the prize after the limit recycle days.
    /// @param id The id of the raffles.
    /// @param receiver The address to receive the rewards.
    function recycleRaffleNoClaim(uint32 id, address payable receiver)
        external
        nonReentrant
        onlyRole(ADMIN)
        onlyOnStatus(id, Status.Drawn)
    {
        RaffleInfo storage raffle = _raffles[id];
        require(
            raffle.drawAt + _globalConfig.recycleDays * 1 days <=
                block.timestamp,
            "Raffle: recycle too soon"
        );

        // settlement fees
        uint256 payPlatform = (_ticketSaleTotalAmount(id) *
            _globalConfig.commissionRate) / 10000;
        uint256 remainFunds = _ticketSaleTotalAmount(id) - payPlatform;

        // Change the status of the raffle
        raffle.status = Status.Recycled;
        raffle.endAt = block.timestamp;

        // Split and transfer the earning
        if (remainFunds > 0) {
            (bool sent, ) = receiver.call{value: remainFunds}("");
            require(sent, "Raffle: Failed send ether to receiver");
        }

        if (payPlatform > 0) {
            (bool sent, ) = _globalConfig.platformWallet.call{
                value: payPlatform
            }("");
            require(sent, "Raffle: Failed send ether to platform");
        }

        // Transfer the token to the winner
        _tokenTransferOut(
            receiver,
            raffle.tokenType,
            raffle.tokenAddress,
            raffle.tokenId,
            raffle.tokenAmount
        );

        emit RaffleRecycled(id, receiver, remainFunds, payPlatform);
    }

    ///////////////////////////////////////////////////////////////////////
    ///////////////////////// Internal ////////////////////////////////////

    /// @dev The instance of VRF coordinator.
    VRFCoordinatorV2Interface private immutable COORDINATOR;
    /// @dev The role name of owner.
    bytes32 public constant OWNER = keccak256("OWNER");
    /// @dev The role name of admin.
    bytes32 public constant ADMIN = keccak256("ADMIN");
    /// @dev The name of the contract.
    string public constant CONTRACT_NAME = "raffle";
    /// @dev The version of the contract.
    string public constant CONTRACT_VERSION = "0.1.0";
    /// @dev The domain hash for the buyTicket method.
    bytes32 public constant BUY_TICKET_HASH =
        keccak256(
            "BuyTicket(address caller,uint32 id,uint32 ticketNum,uint256 expireAt)"
        );

    /// @dev See {IERC165-supportsInterface}.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControl, ERC1155Receiver)
        returns (bool)
    {
        return
            interfaceId == type(IAccessControl).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}

/// @dev Helper methods for checking the token type or owner.
library TokenHelper {
    using SafeERC20 for IERC20;
    using ERC165Checker for address;

    bytes4 private constant IID_IERC1155 = type(IERC1155).interfaceId;
    bytes4 private constant IID_IERC721 = type(IERC721).interfaceId;

    /// @notice Check the account if the owner of the token.
    /// @param tokenAddress The address of the token.
    /// @param account The address of the owner.
    /// @return true If the account is the owner of the token.
    /// @dev Support ERC20, ERC721 and ERC1155.
    function _ownsAnyTokens(address tokenAddress, address account)
        internal
        view
        returns (bool)
    {
        if (_isERC721(tokenAddress)) {
            return IERC721(tokenAddress).balanceOf(account) > 0;
        } else if (_isERC1155(tokenAddress)) {
            return IERC1155(tokenAddress).balanceOf(account, 0) > 0;
        } else {
            return IERC20(tokenAddress).balanceOf(account) > 0;
        }
    }

    /// @dev Return true if the token is ERC1155.
    function _isERC1155(address tokenAddress) internal view returns (bool) {
        return tokenAddress.supportsInterface(IID_IERC1155);
    }

    /// @dev Return true if the token is ERC721.
    function _isERC721(address tokenAddress) internal view returns (bool) {
        return tokenAddress.supportsInterface(IID_IERC721);
    }

    /// @dev Transfer the token
    function _transfer(
        address tokenAddress,
        uint256 tokenId,
        uint256 tokenAmount,
        address from,
        address to
    ) internal {
        require(
            tokenAddress != address(0) &&
                from != address(0) &&
                to != address(0),
            "TokenHelper: Zero address"
        );
        if (_isERC721(tokenAddress)) {
            require(
                IERC721(tokenAddress).ownerOf(tokenId) == from,
                "TokenHelper: Token owner is not caller"
            );
            IERC721(tokenAddress).safeTransferFrom(from, to, tokenId);
        } else if (_isERC1155(tokenAddress)) {
            require(tokenAmount > 0, "TokenHelper: tokenAmount is required");
            require(
                IERC1155(tokenAddress).balanceOf(from, tokenId) >= tokenAmount,
                "TokenHelper: Insufficient balance"
            );
            IERC1155(tokenAddress).safeTransferFrom(
                from,
                to,
                tokenId,
                tokenAmount,
                ""
            );
        } else {
            require(tokenAmount > 0, "TokenHelper: tokenAmount is required");
            require(
                IERC20(tokenAddress).balanceOf(from) >= tokenAmount,
                "TokenHelper: Insufficient balance"
            );
            IERC20(tokenAddress).safeTransferFrom(from, to, tokenAmount);
        }
    }

    /// @dev Safe approve
    function _safeApproveErc20(address tokenAddress, uint256 tokenAmount)
        internal
    {
        IERC20(tokenAddress).safeIncreaseAllowance(address(this), tokenAmount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/PullPayment.sol)

pragma solidity ^0.8.0;

import "../utils/escrow/Escrow.sol";

/**
 * @dev Simple implementation of a
 * https://consensys.github.io/smart-contract-best-practices/recommendations/#favor-pull-over-push-for-external-calls[pull-payment]
 * strategy, where the paying contract doesn't interact directly with the
 * receiver account, which must withdraw its payments itself.
 *
 * Pull-payments are often considered the best practice when it comes to sending
 * Ether, security-wise. It prevents recipients from blocking execution, and
 * eliminates reentrancy concerns.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 *
 * To use, derive from the `PullPayment` contract, and use {_asyncTransfer}
 * instead of Solidity's `transfer` function. Payees can query their due
 * payments with {payments}, and retrieve them with {withdrawPayments}.
 */
abstract contract PullPayment {
    Escrow private immutable _escrow;

    constructor() {
        _escrow = new Escrow();
    }

    /**
     * @dev Withdraw accumulated payments, forwarding all gas to the recipient.
     *
     * Note that _any_ account can call this function, not just the `payee`.
     * This means that contracts unaware of the `PullPayment` protocol can still
     * receive funds this way, by having a separate account call
     * {withdrawPayments}.
     *
     * WARNING: Forwarding all gas opens the door to reentrancy vulnerabilities.
     * Make sure you trust the recipient, or are either following the
     * checks-effects-interactions pattern or using {ReentrancyGuard}.
     *
     * @param payee Whose payments will be withdrawn.
     *
     * Causes the `escrow` to emit a {Withdrawn} event.
     */
    function withdrawPayments(address payable payee) public virtual {
        _escrow.withdraw(payee);
    }

    /**
     * @dev Returns the payments owed to an address.
     * @param dest The creditor's address.
     */
    function payments(address dest) public view returns (uint256) {
        return _escrow.depositsOf(dest);
    }

    /**
     * @dev Called by the payer to store the sent amount as credit to be pulled.
     * Funds sent in this way are stored in an intermediate {Escrow} contract, so
     * there is no danger of them being spent before withdrawal.
     *
     * @param dest The destination address of the funds.
     * @param amount The amount to transfer.
     *
     * Causes the `escrow` to emit a {Deposited} event.
     */
    function _asyncTransfer(address dest, uint256 amount) internal virtual {
        _escrow.deposit{value: amount}(dest);
    }
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
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/draft-EIP712.sol)

pragma solidity ^0.8.0;

import "./ECDSA.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;
    address private immutable _CACHED_THIS;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _CACHED_THIS = address(this);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (address(this) == _CACHED_THIS && block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.2) (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface,
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            _supportsERC165Interface(account, type(IERC165).interfaceId) &&
            !_supportsERC165Interface(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && _supportsERC165Interface(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = _supportsERC165Interface(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in _interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!_supportsERC165Interface(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function _supportsERC165Interface(address account, bytes4 interfaceId) private view returns (bool) {
        // prepare call
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);

        // perform static call
        bool success;
        uint256 returnSize;
        uint256 returnValue;
        assembly {
            success := staticcall(30000, account, add(encodedParams, 0x20), mload(encodedParams), 0x00, 0x20)
            returnSize := returndatasize()
            returnValue := mload(0x00)
        }

        return success && returnSize >= 0x20 && returnValue > 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. It the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`.
        // We also know that `k`, the position of the most significant bit, is such that `msb(a) = 2**k`.
        // This gives `2**k < a <= 2**(k+1)` → `2**(k/2) <= sqrt(a) < 2 ** (k/2+1)`.
        // Using an algorithm similar to the msb conmputation, we are able to compute `result = 2**(k/2)` which is a
        // good first aproximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1;
        uint256 x = a;
        if (x >> 128 > 0) {
            x >>= 128;
            result <<= 64;
        }
        if (x >> 64 > 0) {
            x >>= 64;
            result <<= 32;
        }
        if (x >> 32 > 0) {
            x >>= 32;
            result <<= 16;
        }
        if (x >> 16 > 0) {
            x >>= 16;
            result <<= 8;
        }
        if (x >> 8 > 0) {
            x >>= 8;
            result <<= 4;
        }
        if (x >> 4 > 0) {
            x >>= 4;
            result <<= 2;
        }
        if (x >> 2 > 0) {
            result <<= 1;
        }

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        uint256 result = sqrt(a);
        if (rounding == Rounding.Up && result * result < a) {
            result += 1;
        }
        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
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
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/escrow/Escrow.sol)

pragma solidity ^0.8.0;

import "../../access/Ownable.sol";
import "../Address.sol";

/**
 * @title Escrow
 * @dev Base escrow contract, holds funds designated for a payee until they
 * withdraw them.
 *
 * Intended usage: This contract (and derived escrow contracts) should be a
 * standalone contract, that only interacts with the contract that instantiated
 * it. That way, it is guaranteed that all Ether will be handled according to
 * the `Escrow` rules, and there is no need to check for payable functions or
 * transfers in the inheritance tree. The contract that uses the escrow as its
 * payment method should be its owner, and provide public methods redirecting
 * to the escrow's deposit and withdraw.
 */
contract Escrow is Ownable {
    using Address for address payable;

    event Deposited(address indexed payee, uint256 weiAmount);
    event Withdrawn(address indexed payee, uint256 weiAmount);

    mapping(address => uint256) private _deposits;

    function depositsOf(address payee) public view returns (uint256) {
        return _deposits[payee];
    }

    /**
     * @dev Stores the sent amount as credit to be withdrawn.
     * @param payee The destination address of the funds.
     *
     * Emits a {Deposited} event.
     */
    function deposit(address payee) public payable virtual onlyOwner {
        uint256 amount = msg.value;
        _deposits[payee] += amount;
        emit Deposited(payee, amount);
    }

    /**
     * @dev Withdraw accumulated balance for a payee, forwarding all gas to the
     * recipient.
     *
     * WARNING: Forwarding all gas opens the door to reentrancy vulnerabilities.
     * Make sure you trust the recipient, or are either following the
     * checks-effects-interactions pattern or using {ReentrancyGuard}.
     *
     * @param payee The address whose funds will be withdrawn and transferred to.
     *
     * Emits a {Withdrawn} event.
     */
    function withdraw(address payable payee) public virtual onlyOwner {
        uint256 payment = _deposits[payee];

        _deposits[payee] = 0;

        payee.sendValue(payment);

        emit Withdrawn(payee, payment);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.3) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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