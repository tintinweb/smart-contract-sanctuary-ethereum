/**
 *Submitted for verification at Etherscan.io on 2023-06-13
*/

// File @openzeppelin/contracts/utils/introspection/[email protected]

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


// File @openzeppelin/contracts/token/ERC721/[email protected]

// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function setApprovalForAll(address operator, bool approved) external;

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




pragma solidity ^0.8.4;

contract NFTAuction {
    enum Status {Pending, Active, Inactive}

    struct Bid {
        address bidder;
        uint256 amount;
    }

    struct Auction {
        uint256 auctionRecordId;
        string title;
        string description;
        address assetAddress;
        uint256 assetRecordId;
        uint256 startingPrice;
        uint256 maximumPrice;
        uint256 minimumIncrement;
        uint256 expiryTime;
        uint8 distributionCut;
        Status status;
        address sellerAddress;
        Bid[] bids;
    }

    address public contractOwner;
    uint256 public auctionCount;
    mapping(uint256 => Auction) public auctions;
    mapping(address => uint256) public pendingReturns;

    event AuctionCreated(uint256 id, string title, uint256 startingPrice, uint256 reservePrice);
    event AuctionActivated(uint256 id);
    event AuctionCancelled(uint256 id);
    event BidPlaced(uint256 auctionId, address bidder, uint256 amount);
    event AuctionEndedWithWinner(uint256 auctionId, address winningBidder, uint256 amount);
    event AuctionEndedWithoutWinner(uint256 auctionId, uint256 topBid, uint256 reservePrice);
    event LogFailure(string message);

    modifier auctionExists(uint256 auctionId) {
        require(auctionId < auctionCount, "Auction does not exist");
        _;
    }

    modifier onlyAuctionOwner(uint256 auctionId) {
        require(msg.sender == auctions[auctionId].sellerAddress, "Only auction owner can perform this operation");
        _;
    }

    modifier onlyContractOwner() {
        require(msg.sender == contractOwner, "Only contract owner can perform this operation");
        _;
    }

    constructor() {
        contractOwner = msg.sender;
    }

    function createAuction(
        string memory title,
        string memory description,
        address assetAddress,
        uint256 assetRecordId,
        uint256 startingPrice,
        uint256 maximumPrice,
        uint256 minimumIncrement,
        uint256 duration,
        uint8 distributionCut
    ) public {
        Auction storage newAuction = auctions[auctionCount];

        newAuction.auctionRecordId = auctionCount;
        newAuction.title = title;
        newAuction.description = description;
        newAuction.assetAddress = assetAddress;
        newAuction.assetRecordId = assetRecordId;
        newAuction.startingPrice = startingPrice;
        newAuction.maximumPrice = maximumPrice;
        newAuction.minimumIncrement = minimumIncrement;
        newAuction.expiryTime = block.timestamp + duration;
        newAuction.distributionCut = distributionCut;
        newAuction.status = Status.Pending;
        newAuction.sellerAddress = msg.sender;

        auctionCount++;

        emit AuctionCreated(newAuction.auctionRecordId, newAuction.title, newAuction.startingPrice, newAuction.maximumPrice);
    }

    function activateAuction(uint256 auctionId) public onlyAuctionOwner(auctionId) {
        Auction storage auction = auctions[auctionId];
        require(auction.status == Status.Pending, "Auction is not in Pending state");
        require(block.timestamp < auction.expiryTime, "Auction has expired");

        IERC721 token = IERC721(auction.assetAddress);
        require(token.ownerOf(auction.assetRecordId) == msg.sender, "Must own the asset to auction it");

        token.transferFrom(msg.sender, address(this), auction.assetRecordId);

        auction.status = Status.Active;
        emit AuctionActivated(auctionId);
    }

    function placeBid(uint256 auctionId) public payable auctionExists(auctionId) {
        Auction storage auction = auctions[auctionId];
        require(auction.status == Status.Active, "Auction is not active");

        if (auction.bids.length > 0) {
            Bid memory lastBid = auction.bids[auction.bids.length - 1];
            require(msg.value >= lastBid.amount + auction.minimumIncrement, "Must increment bid by the minimum amount");
            pendingReturns[lastBid.bidder] += lastBid.amount;
        } else {
            require(msg.value >= auction.startingPrice, "Must place bid of at least the starting price");
        }

        Bid memory newBid = Bid({bidder: msg.sender, amount: msg.value});
        auction.bids.push(newBid);

        emit BidPlaced(auctionId, msg.sender, msg.value);
    }

    function endAuction(uint256 auctionId) public onlyAuctionOwner(auctionId) {
        Auction storage auction = auctions[auctionId];
        require(auction.status == Status.Active, "Auction is not active");

        if (auction.bids.length > 0) {
            Bid memory highestBid = auction.bids[auction.bids.length - 1];

            if (highestBid.amount >= auction.maximumPrice) {
                uint256 cut = (highestBid.amount * auction.distributionCut) / 100;
                pendingReturns[auction.sellerAddress] += highestBid.amount - cut;
                pendingReturns[contractOwner] += cut;

                IERC721 token = IERC721(auction.assetAddress);
                token.transferFrom(address(this), highestBid.bidder, auction.assetRecordId);

                emit AuctionEndedWithWinner(auctionId, highestBid.bidder, highestBid.amount);
            } else {
                pendingReturns[highestBid.bidder] += highestBid.amount;
                emit AuctionEndedWithoutWinner(auctionId, highestBid.amount, auction.maximumPrice);
            }
        } else {
            emit AuctionEndedWithoutWinner(auctionId, 0, auction.maximumPrice);
        }

        auction.status = Status.Inactive;
    }

    function cancelAuction(uint256 auctionId) public onlyAuctionOwner(auctionId) {
        Auction storage auction = auctions[auctionId];
        require(auction.status != Status.Inactive, "Auction is already inactive");

        if (auction.bids.length > 0) {
            Bid memory lastBid = auction.bids[auction.bids.length - 1];
            pendingReturns[lastBid.bidder] += lastBid.amount;
        }

        IERC721 token = IERC721(auction.assetAddress);
        token.transferFrom(address(this), msg.sender, auction.assetRecordId);

        auction.status = Status.Inactive;
        emit AuctionCancelled(auctionId);
    }

    function withdraw() public {
        uint amount = pendingReturns[msg.sender];
        if (amount > 0) {
            pendingReturns[msg.sender] = 0;

            (bool success,) = msg.sender.call{value: amount}("");
            require(success, "Transfer failed.");
        }
    }
}