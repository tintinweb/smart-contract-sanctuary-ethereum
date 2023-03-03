// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./TimeLibrary.sol";

import "./IAuctionBidCore.sol";
import "./IAuctionCore.sol";

import "./ReentrancyGuard.sol";
import "./Errors.sol";

// TODO: Add events
contract AuctionCore is IAuctionBidCore, IAuctionCore, ReentrancyGuard {
    /// @dev The gas limit to send ETH to a single recipient, enough for a contract with a simple receiver.
    uint256 constant SEND_VALUE_GAS_LIMIT_SINGLE_RECIPIENT = 26_000;

    /// @notice The window for auction extensions, any bid placed in the final 15 mins
    /// of an auction will reset the time remaining to 15 minutes.
    uint256 constant EXTENSION_DURATION = 15 minutes;

    using TimeLibrary for uint256;

    /// @notice A global id for auctions of any type.
    uint256 private nextAuctionId = 1;

    /// @notice The auction configuration for a specific auction id.
    /// @dev This is deleted when an auction is finalized or canceled.
    mapping(address => mapping(uint256 => uint256))
        private contractToTokenIdToAuctionId;

    /// @notice The auction id for a specific Auction.
    /// @dev This is deleted when an auction is finalized or canceled.
    mapping(uint256 => Auction) private auctionIdToAuction;

    function createAuction(
        AuctionDetails calldata auctionDetails,
        TokenDetails calldata tokenDatails
    ) external returns (uint256 auctionId) {
        if (
            contractToTokenIdToAuctionId[tokenDatails.address_][
                tokenDatails.id
            ] != 0
        ) {
            revert Errors.TokenAlreadyListed(
                contractToTokenIdToAuctionId[tokenDatails.address_][
                    tokenDatails.id
                ]
            );
        }

        auctionId = _getNextAndIncrementAuctionId();
        _transferToEscrow(tokenDatails);

        address payable seller = payable(msg.sender);

        // TODO: - Add all parametr checkes

        Auction storage auction = auctionIdToAuction[auctionId];
        auction.tokenDetails = tokenDatails;
        auction.auctionDetails = auctionDetails;
        auction.seller = seller;

        contractToTokenIdToAuctionId[tokenDatails.address_][
            tokenDatails.id
        ] = auctionId;
    }

    function bid(uint256 auctionId) external payable lock {
        Auction storage auction = auctionIdToAuction[auctionId];

        if (auction.seller == address(0)) {
            revert Errors.AuctionNotFound();
        }

        if (msg.value < minimalPrice(auctionId)) {
            revert Errors.ValueLessThanMinimalPrice();
        }

        if (msg.sender == auction.lastBid.bidder) {
            revert Errors.YouCanNotRebid();
        }

        _startAuctionIfNeeded(auction);
        uint256 endTime = auction.endTime;

        if (endTime.hasExpired()) {
            revert Errors.AuctionHasFinished();
        }

        address payable sender = payable(msg.sender);

        address payable originalBidder = auction.lastBid.bidder;
        uint256 originalAmount = auction.lastBid.amount;

        auction.lastBid.bidder = sender;
        auction.lastBid.amount = msg.value;

        uint256 endTimeWithExtension = block.timestamp + EXTENSION_DURATION;
        if (endTime < endTimeWithExtension) {
            endTime = endTimeWithExtension;
            auction.endTime = endTime;
        }

        if (originalBidder != address(0)) {
            _sendValueWithFallbackWithdraw({
                user: originalBidder,
                amount: originalAmount,
                gasLimit: SEND_VALUE_GAS_LIMIT_SINGLE_RECIPIENT
            });
        }        
    }

    function finalizeAuction(uint256 auctionId) external lock {
        Auction memory auction = auctionIdToAuction[auctionId];

        if (auction.seller == address(0)) {
            revert Errors.AuctionNotFound();
        }

        if (auction.endTime == 0) {
            revert Errors.AuctionHasNoBid();
        }

        if (!auction.endTime.hasExpired()) {
            revert Errors.AuctionHasNotFinished();
        }

        _transferFromEscrow(auction.tokenDetails, auction.lastBid.bidder);

        _sendValueWithFallbackWithdraw({
            user: auction.seller,
            amount: auction.lastBid.amount,
            gasLimit: SEND_VALUE_GAS_LIMIT_SINGLE_RECIPIENT
        });

        delete contractToTokenIdToAuctionId[auction.tokenDetails.address_][auction.tokenDetails.id];
        delete auctionIdToAuction[auctionId];
    }

    function isAuctionStarted(uint256 auctionId) public view returns (bool) {
        Auction memory auction = auctionIdToAuction[auctionId];

        if (
            auction.auctionDetails.startType ==
            IAuctionCore.AuctionStartType.ON_FIRST_BID
        ) {
            return auction.endTime != 0;
        } else {
            return auction.auctionDetails.startTime.hasBeenReached();
        }
    }

    function isAuctionFinished(uint256 auctionId) public view returns (bool) {
        Auction memory auction = auctionIdToAuction[auctionId];
        
        if (isAuctionStarted(auctionId)) {
            return auction.endTime.hasBeenReached();
        } else {
            if (
                auction.auctionDetails.startType ==
                IAuctionCore.AuctionStartType.ON_FIRST_BID
            ) {
                return false;
            } else {
                return
                    (auction.auctionDetails.startTime +
                        auction.auctionDetails.duration).hasBeenReached();
            }
        }
    }

    function minimalPrice(uint256 auctionId) public view returns (uint256) {
        Auction memory auction = auctionIdToAuction[auctionId];
        if (auction.lastBid.amount == 0) {
            return auction.auctionDetails.reservePrice;
        } else {
            return _getMinIncrement(auction.lastBid.amount, auction.auctionDetails.minIncrementBPS);
        }
    }

    function _startAuctionIfNeeded(Auction storage auction) internal {
        if (auction.endTime == 0) {
            if (!auction.auctionDetails.startTime.hasBeenReached()) {
                revert Errors.AuctionHaveNotStarted();
            }

            if (
                auction.auctionDetails.startType ==
                IAuctionCore.AuctionStartType.ON_FIRST_BID
            ) {
                auction.endTime =
                    block.timestamp +
                    auction.auctionDetails.duration;
            } else {
                auction.endTime =
                    auction.auctionDetails.startTime +
                    auction.auctionDetails.duration;
                if (auction.endTime.hasExpired()) {
                    revert Errors.AuctionFinishedBeforeFirstBid();
                }
            }
        }
    }


    function _getMinIncrement(uint256 currentAmount, uint16 minIncrementBPS) internal pure returns (uint256) {
        uint256 minIncrement = currentAmount * minIncrementBPS / 10000;
        if (minIncrement == 0) {
            return currentAmount + 1;
        }
        return currentAmount + minIncrement;
    }

    function _getNextAndIncrementAuctionId() internal returns (uint256) {
        unchecked {
            return nextAuctionId++;
        }
    }

    function _transferFromEscrow(TokenDetails memory tokenDatails, address newOwner) internal virtual {
        if (tokenDatails.type_ == TokenLib.TokenType.ERC721) {
            TokenLib._erc721Transfer(
                address(this),
                tokenDatails.id,
                msg.sender,
                newOwner
            );
        } else {
            TokenLib._erc1155Transfer(
                address(this),
                tokenDatails.id,
                1,
                msg.sender,
                newOwner
            );
        }
    }

    function _transferToEscrow(TokenDetails calldata tokenDatails)
        internal
        virtual
    {
        if (tokenDatails.type_ == TokenLib.TokenType.ERC721) {
            TokenLib._erc721Transfer(
                tokenDatails.address_,
                tokenDatails.id,
                msg.sender,
                address(this)
            );
        } else {
            TokenLib._erc1155Transfer(
                tokenDatails.address_,
                tokenDatails.id,
                1,
                msg.sender,
                address(this)
            );
        }
    }

    function _sendValueWithFallbackWithdraw(address payable user, uint256 amount, uint256 gasLimit) internal {
        if (amount == 0) {
            return;
        }

        (bool success, ) = user.call{ value: amount, gas: gasLimit }("");
        if (!success) {
            // Store the funds that failed to send for the user in the FETH token
            // feth.depositFor{ value: amount }(user);
            // TODO: Do anything
        }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4;

library Errors {
    error TokenAlreadyListed(uint256 auctionId);
    error AuctionNotFound();
    error AuctionHaveNotStarted();
    error AuctionFinishedBeforeFirstBid();
    error AuctionHasFinished();
    error ValueLessThanMinimalPrice();
    error YouCanNotRebid();
    error AuctionHasNoBid();
    error AuctionHasNotFinished();

    /* ReentrancyGuard.sol */
    error ContractLocked();
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4;

import "./Errors.sol";

abstract contract ReentrancyGuard {
    uint256 private unlocked = 1;
    modifier lock() {
        if (unlocked == 0) revert Errors.ContractLocked();

        unlocked = 0;
        _;
        unlocked = 1;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./TokenLib.sol";

interface IAuctionCore {
    struct Bid {
        uint256 amount;
        address payable bidder;
    }

    enum AuctionStartType {
        ON_FIRST_BID,
        AFTER_DEADLINE
    }

    struct TokenDetails {
        uint256 id;
        address address_;
        TokenLib.TokenType type_;
    }
    
    struct AuctionDetails {
        uint256 reservePrice;
        uint256 duration;
        uint16 minIncrementBPS;
        AuctionStartType startType;
        uint256 startTime;
    }

    struct Auction {
        address payable seller;
        AuctionDetails auctionDetails;
        TokenDetails tokenDetails;
        uint256 endTime;
        Bid lastBid;
    }

    function createAuction(AuctionDetails calldata auctionDetails, TokenDetails calldata tokenDatails) external returns (uint256 auctionId);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IAuctionBidCore {
    function bid(uint256 auctionId) external payable;
    function finalizeAuction(uint256 auctionId) external;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.12;

/**
 * @title Helpers for working with time.
 * @author batu-inal & HardlyDifficult
 */
library TimeLibrary {
    /**
     * @notice Checks if the given timestamp is in the past.
     * @dev This helper ensures a consistent interpretation of expiry across the codebase.
     * This is different than `hasBeenReached` in that it will return false if the expiry is now.
     */
    function hasExpired(uint256 expiry) internal view returns (bool) {
        return expiry < block.timestamp;
    }

    /**
     * @notice Checks if the given timestamp is now or in the past.
     * @dev This helper ensures a consistent interpretation of expiry across the codebase.
     * This is different from `hasExpired` in that it will return true if the timestamp is now.
     */
    function hasBeenReached(uint256 timestamp) internal view returns (bool) {
        return timestamp <= block.timestamp;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

library TokenLib {
    enum TokenType {
        ERC721,
        ERC1155
    }

    function _erc721Transfer(address tokenAddress, uint256 tokenId, address from, address to) internal {
        IERC721(tokenAddress).transferFrom(from, to, tokenId);
    }

    function _erc1155Transfer(address tokenAddress, uint256 tokenId, uint256 value, address from, address to) internal {
        IERC1155(tokenAddress).safeTransferFrom(from, to, tokenId, value, "");
    }
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