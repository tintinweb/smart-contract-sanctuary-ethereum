// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract RaffleBurn {
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
        uint96 seed;
        uint48 startTimestamp;
        uint48 endTimestamp;
        uint256 ticketPrice;
        bytes32 requestId;
    }

    /*
    GLOBAL STATE
    */

    uint256 public raffleCount;

    mapping(uint256 => Raffle) public raffles;
    mapping(uint256 => Prize[]) public rafflePrizes;
    mapping(uint256 => Ticket[]) public raffleTickets;
    mapping(bytes32 => uint256) public requestIdToRaffleId;

    /*
    WRITE FUNCTIONS
    */

    /**
     * @notice initializes the raffle
     * @param prizeToken the address of the ERC721 token to raffle off
     * @param tokenIds the list of token ids to raffle off
     * @param paymentToken address of the ERC20 token used to buy tickets. Null address uses ETH
     * @param startTimestamp the timestamp at which the raffle starts
     * @param endTimestamp the timestamp at which the raffle ends
     * @param ticketPrice the price of each ticket
     * @return raffleId the id of the raffle
     */
    function createRaffle(
        address prizeToken,
        uint96[] calldata tokenIds,
        address paymentToken,
        uint48 startTimestamp,
        uint48 endTimestamp,
        uint256 ticketPrice
    ) public returns (uint256 raffleId) {
        require(prizeToken != address(0), "prizeToken cannot be null");
        require(
            endTimestamp > block.timestamp,
            "endTimestamp must be in the future"
        );
        require(ticketPrice > 0, "ticketPrice must be greater than 0");

        raffleId = raffleCount++;

        raffles[raffleId] = Raffle({
            paymentToken: paymentToken,
            startTimestamp: startTimestamp,
            endTimestamp: endTimestamp,
            ticketPrice: ticketPrice,
            requestId: bytes32(0),
            seed: 0
        });

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
        }
    }

    /**
     * @notice buy ticket with erc20
     * @param raffleId the id of the raffle to buy ticket for
     * @param ticketCount the number of tickets to buy
     */
    function buyTickets(uint256 raffleId, uint96 ticketCount) public {
        // transfer payment token from account
        uint256 cost = raffles[raffleId].ticketPrice * ticketCount;
        IERC20(raffles[raffleId].paymentToken).transferFrom(
            msg.sender,
            address(0xdead),
            cost
        );
        // give tickets to account
        _sendTicket(msg.sender, raffleId, ticketCount);
    }

    /**
     * @notice claim prize
     * @param to the winner address to send the prize to
     * @param prizeIndex the index of the prize to claim
     * @param ticketPurchaseIndex the index of the ticket purchase to claim prize for
     */
    function claimPrize(
        address to,
        uint256 raffleId,
        uint256 prizeIndex,
        uint256 ticketPurchaseIndex
    ) public {
        require(raffles[raffleId].seed != 0, "Winner not set");
        require(
            to == raffleTickets[raffleId][ticketPurchaseIndex].owner,
            "Not ticket owner"
        );
        uint256 ticketId = getWinnerTicketId(raffleId, prizeIndex);
        uint96 startId = ticketPurchaseIndex > 0
            ? raffleTickets[raffleId][ticketPurchaseIndex - 1].endId
            : 0;
        uint96 endId = raffleTickets[raffleId][ticketPurchaseIndex].endId;
        require(
            ticketId >= startId && ticketId < endId,
            "Ticket id out of winner range"
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
    function initializeSeed(uint256 raffleId) public {
        Raffle memory raffle = raffles[raffleId];
        require(raffle.endTimestamp < block.timestamp, "Raffle has not ended");
        require(raffle.seed == 0, "Seed already initialized");
        // uint224 royaltyAmount = uint224(getRoyaltyAmount(raffleId));
        // accumulateRoyalty(raffle.paymentToken, royaltyAmount);
        fakeRequestRandomWords(raffleId);
    }

    /**
     * Fake chainlink request
     */
    function fakeRequestRandomWords(uint256 raffleId) internal {
        // generate pseudo random words
        bytes32 requestId = bytes32(abi.encodePacked(block.number));
        requestIdToRaffleId[requestId] = raffleId;
        uint256[] memory randomWords = new uint256[](1);
        randomWords[0] = uint256(keccak256(abi.encodePacked(block.timestamp)));
        fulfillRandomWords(requestId, randomWords);
    }

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomWords(bytes32 requestId, uint256[] memory randomWords)
        internal
    {
        // TODO replace with chainlink
        uint256 raffleId = requestIdToRaffleId[requestId];
        raffles[raffleId].seed = uint96(randomWords[0]);
    }

    /**
     * @dev sends ticket to account
     * @param to the account to send ticket to
     * @param raffleId the id of the raffle to send ticket for
     * @param ticketCount the number of tickets to send
     */
    function _sendTicket(
        address to,
        uint256 raffleId,
        uint96 ticketCount
    ) internal {
        uint256 purchases = raffleTickets[raffleId].length;
        uint96 ticketEndId = purchases > 0
            ? raffleTickets[raffleId][purchases - 1].endId + ticketCount
            : ticketCount;
        Ticket memory ticket = Ticket({owner: to, endId: ticketEndId});
        raffleTickets[raffleId].push(ticket);
    }

    /*
    READ FUNCTIONS
    */

    /**
     * @dev binary search for winner address
     * @param raffleId the id of the raffle to get winner for
     * @param prizeIndex the index of the prize to get winner for
     * @return winner the winner address
     */
    function getWinner(uint256 raffleId, uint256 prizeIndex)
        public
        view
        returns (address winner)
    {
        uint256 ticketId = getWinnerTicketId(raffleId, prizeIndex);
        uint256 ticketPurchaseIndex = getTicketPurchaseIndex(
            raffleId,
            ticketId
        );
        return raffleTickets[raffleId][ticketPurchaseIndex].owner;
    }

    function getTotalSales(uint256 raffleId)
        public
        view
        returns (uint256 totalSales)
    {
        return
            raffleTickets[raffleId][raffleTickets[raffleId].length - 1].endId *
            raffles[raffleId].ticketPrice;
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
            rafflePrizes[raffleId].length;
    }

    /*
    MODIFIERS
    */
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