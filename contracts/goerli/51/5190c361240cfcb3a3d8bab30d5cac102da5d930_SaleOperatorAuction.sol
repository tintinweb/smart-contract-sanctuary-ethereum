// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.15;

import "fount-contracts/auth/Auth.sol";
import "fount-contracts/sales/Auction.sol";
import "fount-contracts/community/FountCardCheck.sol";
import "fount-contracts/utils/Withdraw.sol";
import "solmate/utils/ReentrancyGuard.sol";
import "../interfaces/IOperatorCollectable.sol";

/**
 * @author Sam King (samkingstudio.eth) for Fount Gallery
 * @title  Auction sale operator example
 * @notice Can be deployed as a "sale operator" for an NFT contract
 */
contract SaleOperatorAuction is Auction, FountCardCheck, Withdraw, Auth, ReentrancyGuard {
    /* ------------------------------------------------------------------------
                                    E R R O R S
    ------------------------------------------------------------------------ */

    error CannotWithdrawWithActiveAuctions();

    /* ------------------------------------------------------------------------
                                      I N I T
    ------------------------------------------------------------------------ */

    /**
     * @param owner_ The owner of the contract
     * @param admin_ The admin of the contract
     * @param nft_ The address of the NFT contract to transfer tokens from
     * @param fountCard_ The address of the Fount Gallery Patron Card NFT
     * @param auctionReservePrice Reserve price of each auction
     * @param auctionDuration How long each auction should run for
     * @param auctionTimeBuffer Time buffer for extending the auction
     * @param auctionIncrementPercentage Percentage each bid should increase by
     */
    constructor(
        address owner_,
        address admin_,
        address nft_,
        address fountCard_,
        uint256 auctionReservePrice,
        uint32 auctionDuration,
        uint32 auctionTimeBuffer,
        uint32 auctionIncrementPercentage
    )
        Auction(
            nft_,
            AuctionConfig({
                reservePrice: auctionReservePrice,
                duration: auctionDuration,
                timeBuffer: auctionTimeBuffer,
                incrementPercentage: auctionIncrementPercentage
            })
        )
        FountCardCheck(fountCard_)
        Auth(owner_, admin_)
    {}

    /* ------------------------------------------------------------------------
                             A U C T I O N   S E T U P
    ------------------------------------------------------------------------ */

    /**
     * @notice Creates an auction for a given token id
     * @dev Stores the token in this contract as escrow so it can be transferred to the winner,
     * and also prevents it being sold to someone else while an active auction is ongoing.
     *
     * Reverts if:
     *   - The auction already exists.
     *   - The caller is not the contract owner.
     *
     * @param id The token id to create the auction for
     * @param startTime The unix timestamp of when the auction should start allowing bids
     */
    function createAuction(uint256 id, uint256 startTime) public onlyOwner {
        _createAuction(id, startTime);
    }

    /**
     * @notice Cancels a given auction. Can only be cancelled when there are no bids.
     * @dev Transfers the token back to the original owner so a subsequent auction can be created.
     *
     * Reverts if:
     *   - The auction has already started.
     *   - The caller is not the contract owner
     *
     * @param id The token id used to create the auction
     */
    function cancelAuction(uint256 id) public onlyOwner {
        _cancelAuction(id);
    }

    /* ------------------------------------------------------------------------
                                      B I D S
    ------------------------------------------------------------------------ */

    /**
     * @notice Place a bid specific token id
     * @param id The token id to place a bid on (same as auction id)
     */
    function placeBid(uint256 id) public payable nonReentrant {
        _placeBid(id);
    }

    /**
     * @notice Place a bid specific token id as a Fount Card Holder
     * @param id The token id to place a bid on (same as auction id)
     */
    function placeBidForFountHolders(uint256 id)
        public
        payable
        onlyWhenFountCardHolder
        nonReentrant
    {
        _placeBid(id);
    }

    /**
     * @notice Place a bid specific token id as a holder of 10 Fount Cards
     * @param id The token id to place a bid on (same as auction id)
     */
    function placeBidForLoyalFountHolders(uint256 id)
        public
        payable
        onlyWhenHoldingMinFountCards(10)
        nonReentrant
    {
        _placeBid(id);
    }

    /**
     * @notice Allows the winner to settle the auction, taking ownership of their new NFT
     * @dev Transfers the NFT to the highest bidder (winner) only once the auction is over.
     * Can be called by anyone so the artist, or the team can pay the gas if needed.
     *
     * Reverts if:
     *   - The auction hasn't started yet
     *   - The auction is not over
     *
     * @param id The token id of the auction to settle
     */
    function settleAuction(uint256 id) public nonReentrant {
        // Settle the auction and transfer the token to the highest bidder
        _settleAuction(id);

        // Mark the token as collected since `_settleAuction` handles the transfer
        IOperatorCollectable(address(nft)).markAsCollected(id);
    }

    /* ------------------------------------------------------------------------
                                  W I T H D R A W
    ------------------------------------------------------------------------ */

    /**
     * @notice Admin function to withdraw ETH from this contract
     * @dev Withdraws to the `owner` address. Reverts if there are active auctions.
     * @param to The address to withdraw ETH to
     */
    function withdrawETH(address to) public override onlyAdmin {
        // Check there are no active auctions
        if (_activeAuctionCount > 0) revert CannotWithdrawWithActiveAuctions();

        // Go ahead and attempt to withdraw
        _withdrawETH(to);
    }

    /**
     * @notice Admin function to withdraw ERC-20 tokens from this contract
     * @dev Withdraws to the `owner` address. Reverts if there are active auctions.
     * @param token The address of the ERC-20 token to withdraw
     * @param to The address to withdraw tokens to
     */
    function withdrawToken(address token, address to) public override onlyAdmin {
        // Check there are no active auctions
        if (_activeAuctionCount > 0) revert CannotWithdrawWithActiveAuctions();

        // Go ahead and attempt to withdraw
        _withdrawToken(token, to);
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.15;

/**
 * @author Sam King (samkingstudio.eth) for Fount Gallery
 * @title  Simple owner and admin authentication
 * @notice Allows the management of a contract by using simple ownership and admin modifiers.
 */
abstract contract Auth {
    /* ------------------------------------------------------------------------
                                   S T O R A G E
    ------------------------------------------------------------------------ */

    /// @notice Current owner of the contract
    address public owner;

    /// @notice Current admins of the contract
    mapping(address => bool) public admins;

    /* ------------------------------------------------------------------------
                                    E V E N T S
    ------------------------------------------------------------------------ */

    /**
     * @notice When the contract owner is updated
     * @param user The account that updated the new owner
     * @param newOwner The new owner of the contract
     */
    event OwnerUpdated(address indexed user, address indexed newOwner);

    /**
     * @notice When an admin is added to the contract
     * @param user The account that added the new admin
     * @param newAdmin The admin that was added
     */
    event AdminAdded(address indexed user, address indexed newAdmin);

    /**
     * @notice When an admin is removed from the contract
     * @param user The account that removed an admin
     * @param prevAdmin The admin that got removed
     */
    event AdminRemoved(address indexed user, address indexed prevAdmin);

    /* ------------------------------------------------------------------------
                                 M O D I F I E R S
    ------------------------------------------------------------------------ */

    /**
     * @dev Only the owner can call
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "UNAUTHORIZED");
        _;
    }

    /**
     * @dev Only an admin can call
     */
    modifier onlyAdmin() {
        require(admins[msg.sender], "UNAUTHORIZED");
        _;
    }

    /**
     * @dev Only the owner or an admin can call
     */
    modifier onlyOwnerOrAdmin() {
        require((msg.sender == owner || admins[msg.sender]), "UNAUTHORIZED");
        _;
    }

    /* ------------------------------------------------------------------------
                                      I N I T
    ------------------------------------------------------------------------ */

    /**
     * @dev Sets the initial owner and a first admin upon creation.
     * @param owner_ The initial owner of the contract
     * @param admin_ An initial admin of the contract
     */
    constructor(address owner_, address admin_) {
        owner = owner_;
        emit OwnerUpdated(address(0), owner_);

        admins[admin_] = true;
        emit AdminAdded(address(0), admin_);
    }

    /* ------------------------------------------------------------------------
                                     A D M I N
    ------------------------------------------------------------------------ */

    /**
     * @notice Transfers ownership of the contract to `newOwner`
     * @dev Can only be called by the current owner or an admin
     * @param newOwner The new owner of the contract
     */
    function setOwner(address newOwner) public virtual onlyOwnerOrAdmin {
        owner = newOwner;
        emit OwnerUpdated(msg.sender, newOwner);
    }

    /**
     * @notice Adds `newAdmin` as an amdin of the contract
     * @dev Can only be called by the current owner or an admin
     * @param newAdmin A new admin of the contract
     */
    function addAdmin(address newAdmin) public virtual onlyOwnerOrAdmin {
        admins[newAdmin] = true;
        emit AdminAdded(address(0), newAdmin);
    }

    /**
     * @notice Removes `prevAdmin` as an amdin of the contract
     * @dev Can only be called by the current owner or an admin
     * @param prevAdmin The admin to remove
     */
    function removeAdmin(address prevAdmin) public virtual onlyOwnerOrAdmin {
        admins[prevAdmin] = false;
        emit AdminRemoved(address(0), prevAdmin);
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.15;

import "openzeppelin/token/ERC721/IERC721.sol";

/**
 * @author Sam King (samkingstudio.eth) for Fount Gallery
 * @title  Auction sale module
 * @notice TBD
 */
abstract contract Auction {
    /* ------------------------------------------------------------------------
                                   S T O R A G E
    ------------------------------------------------------------------------ */

    /// @notice Address of the NFT contract
    IERC721 public nft;

    /// @notice Tracks currently active auctions so withdrawals can be processed
    uint256 internal _activeAuctionCount;

    struct AuctionConfig {
        uint256 reservePrice;
        uint32 duration;
        uint32 timeBuffer;
        uint32 incrementPercentage;
    }

    /// @notice Configuration for all auctions
    AuctionConfig public auctionConfig;

    struct AuctionData {
        address listingOwner;
        uint32 startTime;
        uint32 firstBidTime;
        uint32 duration;
        uint96 highestBid;
        address highestBidder;
    }

    /// @notice Token id to auction config if one exists
    mapping(uint256 => AuctionData) public auctionForTokenId;

    /* ------------------------------------------------------------------------
                                    E R R O R S
    ------------------------------------------------------------------------ */

    error NonExistentToken();
    error AuctionNotStarted();
    error AuctionAlreadyExists();
    error AuctionAlreadyStarted();
    error AuctionReserveNotMet(uint256 reserve, uint256 sent);
    error AuctionMinimumBidNotMet(uint256 minBid, uint256 sent);
    error AuctionNotOver();
    error AuctionRefundFailed();
    error AuctionEnded();

    /* ------------------------------------------------------------------------
                                    E V E N T S
    ------------------------------------------------------------------------ */

    event AuctionCreated(uint256 indexed id, AuctionData auction);
    event AuctionCancelled(uint256 indexed id, AuctionData auction);
    event AuctionBid(uint256 indexed id, AuctionData auction);
    event AuctionSettled(uint256 indexed id, AuctionData auction);

    /* ------------------------------------------------------------------------
                                      I N I T
    ------------------------------------------------------------------------ */

    constructor(address nft_, AuctionConfig memory config) {
        nft = IERC721(nft_);
        auctionConfig = config;
    }

    /* ------------------------------------------------------------------------
                             A U C T I O N   S E T U P
    ------------------------------------------------------------------------ */

    /**
     * @notice Creates an auction for a given token id
     * @dev Stores the token in this contract as escrow so it can be transferred to the winner,
     * and also prevents it being sold to someone else while an active auction is ongoing.
     *
     * Reverts if the auction already exists.
     *
     * @param id The token id to create the auction for
     * @param startTime The unix timestamp of when the auction should start allowing bids
     */
    function _createAuction(uint256 id, uint256 startTime) internal {
        AuctionData storage auction = auctionForTokenId[id];

        // Check there's no auction already
        if (auction.startTime > 0) revert AuctionAlreadyExists();

        // Check the token exists
        address nftOwner = nft.ownerOf(id);
        if (nftOwner == address(0)) revert NonExistentToken();

        // Create the auction in storage
        auction.startTime = uint32(startTime);
        auction.duration = uint32(auctionConfig.duration);
        auction.listingOwner = nftOwner;

        // Increment the number of active auctions
        unchecked {
            ++_activeAuctionCount;
        }

        // Transfer the token to this address as escrow
        nft.transferFrom(nftOwner, address(this), id);

        // Emit event
        emit AuctionCreated(id, auction);
    }

    /**
     * @notice Cancels a given auction. Can only be cancelled when there are no bids.
     * @dev Transfers the token back to the original minter so a subsequent auction can be created
     * @param id The token id used to create the auction
     */
    function _cancelAuction(uint256 id) internal {
        AuctionData storage auction = auctionForTokenId[id];

        // Check if the auction hasn't started
        if (auction.firstBidTime != 0) revert AuctionAlreadyStarted();

        // Transfer NFT back to the listing owner
        nft.transferFrom(address(this), auction.listingOwner, id);

        // Clean up the auction
        delete auctionForTokenId[id];
        unchecked {
            --_activeAuctionCount;
        }

        // Emit event
        emit AuctionCancelled(id, auction);
    }

    /* ------------------------------------------------------------------------
                            B I D   A N D   S E T T L E
    ------------------------------------------------------------------------ */

    /**
     * @notice Places a bid on a given auction
     * @dev Takes the amount of ETH sent as the bid.
     * - If the bid is the new highest bid, then the previous highest bidder is refunded.
     * - If a bid comes within the auction time buffer then the buffer is added to the
     *   time remaining on the auction e.g. extends by `AUCTION_TIME_BUFFER`.
     *
     * Reverts if:
     *   - The auction has not yet started
     *   - The auction has ended
     *   - The auction reserve bid has not been met if it's the first bid
     *   - The bid does not meet the minimum (increment percentage of current highest bid)
     *   - The ETH refund to the previous highest bidder fails
     *
     * @param id The token id of the auction to place a bid on
     */
    function _placeBid(uint256 id) internal {
        AuctionData storage auction = auctionForTokenId[id];

        // Check auction is ready to accept bids
        if (auction.startTime > block.timestamp) revert AuctionNotStarted();

        // If first bid, start the auction
        if (auction.firstBidTime == 0) {
            // Check the first bid meets the reserve
            if (auctionConfig.reservePrice > msg.value) {
                revert AuctionReserveNotMet(auctionConfig.reservePrice, msg.value);
            }

            // Save the bid time
            auction.firstBidTime = uint32(block.timestamp);
        } else {
            // Check it hasn't ended
            if (block.timestamp > (auction.firstBidTime + auction.duration)) revert AuctionEnded();

            // Check the value sent meets the minimum price increase
            uint256 highestBid = auction.highestBid;
            uint256 minBid;
            unchecked {
                minBid = highestBid + ((highestBid * auctionConfig.incrementPercentage) / 100);
            }
            if (minBid > msg.value) revert AuctionMinimumBidNotMet(minBid, msg.value);

            // Refund the previous highest bid
            (bool refunded, ) = payable(auction.highestBidder).call{value: highestBid}("");
            if (!refunded) revert AuctionRefundFailed();
        }

        // Save the highest bid and bidder
        auction.highestBid = uint96(msg.value);
        auction.highestBidder = msg.sender;

        // Calculate the time remaining
        uint256 timeRemaining;
        unchecked {
            timeRemaining = auction.firstBidTime + auction.duration - block.timestamp;
        }

        // If bid is placed within the time buffer of the auction ending, increase the duration
        if (timeRemaining < auctionConfig.timeBuffer) {
            unchecked {
                auction.duration += uint32(auctionConfig.timeBuffer - timeRemaining);
            }
        }

        // Emit event
        emit AuctionBid(id, auction);
    }

    /**
     * @notice Allows the winner to settle the auction, taking ownership of their new NFT
     * @dev Transfers the NFT to the highest bidder (winner) only once the auction is over.
     * Can be called by anyone so the artist, or the team can pay the gas if needed.
     *
     * Reverts if:
     *   - The auction hasn't started yet
     *   - The auction is not over
     *
     * @param id The token id of the auction to settle
     */
    function _settleAuction(uint256 id) internal {
        AuctionData storage auction = auctionForTokenId[id];

        // Check auction has started
        if (auction.firstBidTime == 0) revert AuctionNotStarted();

        // Check auction has ended
        if (auction.firstBidTime + auction.duration > block.timestamp) revert AuctionNotOver();

        // Transfer NFT to highest bidder
        nft.transferFrom(address(this), auction.highestBidder, id);

        // Clean up the auction
        delete auctionForTokenId[id];
        unchecked {
            --_activeAuctionCount;
        }

        // Emit event
        emit AuctionSettled(id, auction);
    }

    /* ------------------------------------------------------------------------
                                   G E T T E R S
    ------------------------------------------------------------------------ */

    function auctionHasStarted(uint256 id) external view returns (bool) {
        return auctionForTokenId[id].firstBidTime > 0;
    }

    function auctionStartTime(uint256 id) external view returns (uint256) {
        return auctionForTokenId[id].startTime;
    }

    function auctionHasEnded(uint256 id) external view returns (bool) {
        AuctionData memory auction = auctionForTokenId[id];
        return block.timestamp > auction.firstBidTime + auction.duration;
    }

    function auctionEndTime(uint256 id) external view returns (uint256) {
        AuctionData memory auction = auctionForTokenId[id];
        return auction.startTime + auction.duration;
    }

    function auctionHighestBidder(uint256 id) external view returns (address) {
        return auctionForTokenId[id].highestBidder;
    }

    function auctionHighestBid(uint256 id) external view returns (uint256) {
        return auctionForTokenId[id].highestBid;
    }

    function auctionListingOwner(uint256 id) external view returns (address) {
        return auctionForTokenId[id].listingOwner;
    }

    function totalActiveAuctions() external view returns (uint256) {
        return _activeAuctionCount;
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.15;

import "openzeppelin/token/ERC1155/IERC1155.sol";

/**
 * @author Sam King (samkingstudio.eth) for Fount Gallery
 * @title  Fount Gallery Card Check
 * @notice Utility functions to check ownership of a Fount Gallery Patron Card NFT
 */
contract FountCardCheck {
    /// @dev Address of the Fount Gallery Patron Card contract
    IERC1155 internal _fountCard;

    /// @dev Does not own a Fount Gallery Patron Card
    error NotFountCardHolder();

    /**
     * @dev Does not own enough Fount Gallery Patron Cards
     * @param required The minimum amount of cards that need to be owned
     * @param owned The actualy amount of cards owned
     */
    error DoesNotHoldEnoughFountCards(uint256 required, uint256 owned);

    /**
     * @dev Init with the Fount Gallery Patron Card contract address
     * @param fountCard The Fount Gallery Patron Card contract address
     */
    constructor(address fountCard) {
        _fountCard = IERC1155(fountCard);
    }

    /**
     * @dev Modifier that only allows the caller to do something if they hold
     * a Fount Gallery Patron Card
     */
    modifier onlyWhenFountCardHolder() {
        if (_getFountCardBalance(msg.sender) < 1) revert NotFountCardHolder();
        _;
    }

    /**
     * @dev Modifier that only allows the caller to do something if they hold
     * at least a specific amount Fount Gallery Patron Cards
     * @param minAmount The minimum amount of cards that need to be owned
     */
    modifier onlyWhenHoldingMinFountCards(uint256 minAmount) {
        uint256 balance = _getFountCardBalance(msg.sender);
        if (minAmount > balance) revert DoesNotHoldEnoughFountCards(minAmount, balance);
        _;
    }

    /**
     * @dev Get the number of Fount Gallery Patron Cards an address owns
     * @param owner The owner address to query
     * @return balance The balance of the owner
     */
    function _getFountCardBalance(address owner) internal view returns (uint256 balance) {
        balance = _fountCard.balanceOf(owner, 1);
    }

    /**
     * @dev Check if an address holds at least one Fount Gallery Patron Card
     * @param owner The owner address to query
     * @return isHolder If the owner holds at least one card
     */
    function _isFountCardHolder(address owner) internal view returns (bool isHolder) {
        isHolder = _getFountCardBalance(owner) > 0;
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.15;

import "openzeppelin/token/ERC20/IERC20.sol";

/**
 * @author Sam King (samkingstudio.eth) for Fount Gallery
 * @title  Withdraw ETH and tokens module
 * @notice Allows the withdrawal of ETH and ERC20 tokens
 */
abstract contract Withdraw {
    /* ------------------------------------------------------------------------
                                    E R R O R S
    ------------------------------------------------------------------------ */

    error CannotWithdrawToZeroAddress();
    error WithdrawFailed();
    error ZeroBalance();

    /* ------------------------------------------------------------------------
                                  W I T H D R A W
    ------------------------------------------------------------------------ */

    function withdrawETH(address to) public virtual;

    function _withdrawETH(address to) internal {
        // Prevent withdrawing to the zero address
        if (to == address(0)) revert CannotWithdrawToZeroAddress();

        // Check there is eth to withdraw
        uint256 balance = address(this).balance;
        if (balance == 0) revert ZeroBalance();

        // Transfer funds
        (bool success, ) = payable(to).call{value: balance}("");
        if (!success) revert WithdrawFailed();
    }

    function withdrawToken(address tokenAddress, address to) public virtual;

    function _withdrawToken(address tokenAddress, address to) internal {
        // Prevent withdrawing to the zero address
        if (to == address(0)) revert CannotWithdrawToZeroAddress();

        // Check there are tokens to withdraw
        uint256 balance = IERC20(tokenAddress).balanceOf(address(this));
        if (balance == 0) revert ZeroBalance();

        // Transfer tokens
        bool success = IERC20(tokenAddress).transfer(to, balance);
        if (!success) revert WithdrawFailed();
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Gas optimized reentrancy protection for smart contracts.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/ReentrancyGuard.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
    uint256 private locked = 1;

    modifier nonReentrant() virtual {
        require(locked == 1, "REENTRANCY");

        locked = 2;

        _;

        locked = 1;
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.15;

interface IOperatorCollectable {
    function collect(uint256 id, address to) external;

    function markAsCollected(uint256 id) external;
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