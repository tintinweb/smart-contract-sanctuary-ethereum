/**
 *Submitted for verification at Etherscan.io on 2023-06-14
*/

pragma solidity ^0.8.4;


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

// SPDX-License-Identifier: MIT
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
        uint128 startingPrice;
        uint128 reservePrice;
        uint128 minimumIncrement;
        uint8 distributionCut;
        uint256 expiryTime;
        Status status;
        address sellerAddress;
        Bid highestBid;
        Bid[] bids;
    }

    address public contractOwner;
    uint256 public auctionCount;

    mapping(IERC721 => uint256[]) public auctionsByNFT; // Stores auction IDs for each NFT
    mapping(uint256 => Bid[]) public bidsByAuctionId; // Stores bids for each auction ID
    mapping(uint256 => Auction) public auctions;
    mapping(uint256 => uint256) public bidsCountByAuction;
    mapping(address => uint256) public pendingReturns;

    event AuctionCreated(uint256 id, string title, uint128 startingPrice, uint128 reservePrice, uint256 expiryTime);
    event AuctionCancelled(uint256 id);
    event BidPlaced(uint256 auctionId, address bidder, uint256 amount);
    event AuctionEndedWithWinner(uint256 auctionId, address winningBidder, uint256 amount);
    event AuctionEndedWithoutWinner(uint256 auctionId, uint256 topBid, uint128 reservePrice);
    event LogFailure(string message);
    event AuctionExtended(uint256 auctionId, uint256 newExpiryTime);
    event AuctionWithdrawn(address withdrawer, uint256 amount);
    event NFTTransferred(address from, address to, uint256 tokenId);


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
        uint128 startingPrice,
        uint128 reservePrice,
        uint128 minimumIncrement,
        uint128 duration,
        uint8 distributionCut
    ) public {
        IERC721 token = IERC721(assetAddress);

        require(token.ownerOf(assetRecordId) == msg.sender, "You must own the NFT to create an auction");
        token.approve(address(this), assetRecordId);
        
        Auction storage newAuction = auctions[auctionCount];

        newAuction.auctionRecordId = auctionCount;
        newAuction.title = title;
        newAuction.description = description;
        newAuction.assetAddress = assetAddress;
        newAuction.assetRecordId = assetRecordId;
        newAuction.startingPrice = startingPrice;
        newAuction.reservePrice = reservePrice;
        newAuction.minimumIncrement = minimumIncrement;
        newAuction.expiryTime = block.timestamp + duration;
        newAuction.distributionCut = distributionCut;
        newAuction.status = Status.Pending;
        newAuction.sellerAddress = msg.sender;

        auctionCount++;

        token.transferFrom(msg.sender, address(this), newAuction.assetRecordId);
        newAuction.status = Status.Active;
        auctionsByNFT[token].push(newAuction.auctionRecordId);

        emit AuctionCreated(newAuction.auctionRecordId, newAuction.title, newAuction.startingPrice, newAuction.reservePrice, newAuction.expiryTime);
    }

    function placeBid(uint256 auctionId) public payable auctionExists(auctionId) {
        Auction storage auction = auctions[auctionId];
        require(msg.sender != auction.sellerAddress, "Owner cannot bid on their own NFT");
        require(auction.status == Status.Active, "Auction is not active");

        if (auction.bids.length > 0) {
            require(msg.value >= auction.highestBid.amount + auction.minimumIncrement, "Must increment bid by the minimum amount");
            pendingReturns[auction.highestBid.bidder] += auction.highestBid.amount;
        } else {
            require(msg.value >= auction.startingPrice, "Must place bid of at least the starting price");
        }
    
        auction.highestBid = Bid({bidder: msg.sender, amount: msg.value});
        auction.bids.push(auction.highestBid);
    
        bidsByAuctionId[auctionId].push(auction.highestBid);
        bidsCountByAuction[auctionId]++;

        emit BidPlaced(auctionId, msg.sender, msg.value);
    }

    function endAuction(uint256 auctionId) public onlyAuctionOwner(auctionId) {
        Auction storage auction = auctions[auctionId];
        require(auction.status == Status.Active, "Auction is not active");

        if (auction.bids.length > 0) {
            Bid memory highestBid = auction.highestBid;

            if (highestBid.amount >= auction.reservePrice) {
                uint256 cut = (highestBid.amount * auction.distributionCut) / 100;
                pendingReturns[auction.sellerAddress] += highestBid.amount - cut;
                pendingReturns[contractOwner] += cut;

                IERC721 token = IERC721(auction.assetAddress);
                token.transferFrom(address(this), highestBid.bidder, auction.assetRecordId);
                emit NFTTransferred(address(this), highestBid.bidder, auction.assetRecordId);

                emit AuctionEndedWithWinner(auctionId, highestBid.bidder, highestBid.amount);
            } else {
                pendingReturns[highestBid.bidder] += highestBid.amount;
                emit AuctionEndedWithoutWinner(auctionId, highestBid.amount, auction.reservePrice);
            }
        } else {
            emit AuctionEndedWithoutWinner(auctionId, 0, auction.reservePrice);
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

    function getAuctionStatus(uint256 auctionId) public view returns (Status) {
        return auctions[auctionId].status;
    }

    function getAuctionsByUser(address user) public view returns (uint256[] memory) {
        uint256[] memory userAuctions = new uint256[](auctionCount);
        uint256 counter = 0;

        for (uint256 i = 0; i < auctionCount; i++) {
            if (auctions[i].sellerAddress == user) {
                userAuctions[counter] = i;
                counter++;
            }
        }
        
        // resize memory array to save space
        uint256[] memory result = new uint256[](counter);
        for(uint256 i = 0; i < counter; i++){
            result[i] = userAuctions[i];
        }
        return result;
    }

    function extendAuctionTime(uint256 auctionId, uint256 additionalTime) public onlyAuctionOwner(auctionId) {
        auctions[auctionId].expiryTime += additionalTime;
        emit AuctionExtended(auctionId, auctions[auctionId].expiryTime);
    }

    function withdraw() public {
        uint amount = pendingReturns[msg.sender];
        if (amount > 0) {
            pendingReturns[msg.sender] = 0;

            (bool success,) = msg.sender.call{value: amount}("");
            require(success, "Transfer failed.");
            emit AuctionWithdrawn(msg.sender, amount);
        }
    }

    function getAuctionsByNFT(IERC721 _nftAddress) external view returns (uint256[] memory) {
        return auctionsByNFT[_nftAddress];
    }

    function getBidByAuctionId(uint256 _auctionId) external view returns (Bid[] memory) {
        return bidsByAuctionId[_auctionId];
    }
}