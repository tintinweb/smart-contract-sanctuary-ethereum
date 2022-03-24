/**
 *Submitted for verification at Etherscan.io on 2022-03-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

/*********************************************
 *********************************************
 *  H e l p e r   c o n t r a c t s
 */

abstract contract ReentrancyGuard {
    uint8 private constant _NOT_ENTERED = 1;
    uint8 private constant _ENTERED = 2;
    uint8 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "Reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

abstract contract Adminable {
    address private _admin1;
    address private _admin2;

    constructor() {
        _set(1, msg.sender);
    }

    function admin(uint8 idx) public view returns (address) {
        if (idx == 1) {
            return _admin1;
        } else if (idx == 2) {
            return _admin2;
        }
        return address(0);
    }

    modifier onlyAdmin() {
        require(
            _admin1 == msg.sender || _admin2 == msg.sender,
            "Caller not admin"
        );
        _;
    }

    function addAdmin(uint8 idx, address addr) public onlyAdmin {
        require(addr != address(0), "Invalid address");
        require(addr != _admin1 && addr != _admin2, "Already admin");
        require(idx == 1 || idx == 2, "Invalid index");
        _set(idx, addr);
    }

    function isAdmin(address addr) public view returns (bool) {
        return addr == _admin1 || addr == _admin2;
    }

    function _set(uint8 idx, address addr) private {
        if (idx == 1) {
            _admin1 = addr;
        } else {
            _admin2 = addr;
        }
    }
}

/*********************************************
 *********************************************
 *  I n t e r f a c e s
 */

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC2981 {
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

interface IERC721 {
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function approve(address to, uint256 tokenId) external;

    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

    function setApprovalForAll(address operator, bool _approved) external;

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);
}

contract NFTAuction is ReentrancyGuard, Adminable, IERC721Receiver {
    /*********************************************
     *********************************************
     *  E v e n t s
     *
     */

    struct Auction {
        address nft;
        address bidder;
        address seller;
        uint256 tokenId;
        uint256 amount;
        uint64 startAt;
        uint64 endAt;
        uint64 minOutbid;
        uint16 extensionDuration;
        uint16 extensionTrigger;
        uint16 hostFee;
    }

    event AuctionCreated(
        address indexed seller,
        address indexed nft,
        uint256 indexed tokenId,
        uint256 startPrice,
        uint256 auctionId,
        uint64 startAt,
        uint64 endAt
    );

    event AuctionUpdated(uint256 indexed auctionId, uint256 startPrice);

    event AuctionCancelled(uint256 indexed auctionId);

    event AuctionCanceledByAdmin(uint256 indexed auctionId, string reason);

    event AuctionFinalized(
        uint256 indexed auctionId,
        address seller,
        address bidder,
        uint64 endAt,
        uint256 amount
    );

    event BidPlaced(
        uint256 indexed auctionId,
        address indexed bidder,
        uint256 amount,
        uint64 endTime
    );

    event WithdrawFailed(address indexed user, uint256 amount);
    event WithdrawSuccess(address indexed user, uint256 amount);

    /*********************************************
     *********************************************
     *  P r i v a t e
     *      m e m b e r s
     *
     */
    mapping(address => mapping(uint256 => uint256))  private _nftToTokenIdToAuctionId;
    mapping(uint256 => Auction) private _auctionIdToAuction;
    mapping(address => uint256) private _pendingWithdraws;
    uint256 private _auctionId;
    uint256 private _minStartPrice;
    uint32 private _minAuctionDuration;
    uint32 private _minDurationExt;
    uint32 private _maxDurationExt;
    uint32 private _readGasLimit;
    uint32 private _lowGasLimit;
    uint32 private _mediumGasLimit;
    uint16 private _royaltyLimit;
    uint16 private _hostFee;
    address private _hostTreasury;

    constructor() ReentrancyGuard() Adminable() {}

    /*********************************************
     *********************************************
     *  P u b l i c
     *      m e t h o d s
     *
     */

    function setHostTreasury(address addr) public onlyAdmin {
        require(addr != address(0), "Invalid address");
        _hostTreasury = addr;
    }

    function setHostFee(uint16 fee) public onlyAdmin {
        require(fee > 0, "Invalid fee");
        _hostFee = fee;
    }

    function setHostFeeForAuction(uint256 auctionId, uint16 fee)
        public
        onlyAdmin
    {
        require(fee > 0, "Invalid fee");
        _auctionIdToAuction[auctionId].hostFee = fee;
    }

    function updateConfig(
        uint256 minStartPrice,
        uint32 minAuctionDuration,
        uint32 minDurationExt,
        uint32 maxDurationExt,
        uint16 royaltyLimit,
        uint32 lowGasLimit,
        uint32 mediumGasLimit,
        uint32 readGasLimit
    ) public onlyAdmin {
        if (minStartPrice > 0) {
            _minStartPrice = minStartPrice;
        }

        if (minAuctionDuration > 0) {
            _minAuctionDuration = minAuctionDuration;
        }

        if (minDurationExt > 0) {
            _minDurationExt = minDurationExt;
        }

        if (maxDurationExt > 0) {
            _maxDurationExt = maxDurationExt;
        }

        if (royaltyLimit > 0) {
            _royaltyLimit = royaltyLimit;
        }

        if (lowGasLimit > 0) {
            _lowGasLimit = lowGasLimit;
        }

        if (mediumGasLimit > 0) {
            _mediumGasLimit = mediumGasLimit;
        }

        if (readGasLimit > 0) {
            _readGasLimit = readGasLimit;
        }
    }

    function getConfig()
        public
        view
        returns (
            uint256,
            uint32,
            uint32,
            uint32,
            uint16,
            uint32,
            uint32,
            address,
            uint16
        )
    {
        return (
            _minStartPrice,
            _minAuctionDuration,
            _minDurationExt,
            _maxDurationExt,
            _royaltyLimit,
            _lowGasLimit,
            _mediumGasLimit,
            _hostTreasury,
            _hostFee
        );
    }

    function getAuctionId(address nft, uint256 tokenId)
        public
        view
        returns (uint256)
    {
        return _nftToTokenIdToAuctionId[nft][tokenId];
    }

    function getAuctionDetails(uint256 auctionId)
        public
        view
        returns (
            address,
            uint256,
            uint256,
            uint256,
            address,
            uint256,
            uint256,
            uint16
        )
    {
        Auction memory auction = _auctionIdToAuction[auctionId];
        require(auction.nft != address(0), "Auction not found");
        return (
            auction.seller,
            auction.startAt,
            auction.endAt,
            auction.extensionDuration,
            auction.bidder,
            auction.amount,
            auction.minOutbid,
            auction.hostFee == 1
                ? 0
                : (auction.hostFee > 1 ? auction.hostFee : _hostFee)
        );
    }

    /**
     * @notice Contract owner could create auction on behalf of seller
     */
    function createAuctionFor(
        address nft,
        address seller,
        uint256 tokenId,
        uint256 startPrice,
        uint64 startAt,
        uint64 endAt,
        uint64 minOutbid,
        uint16 extensionDuration,
        uint16 extensionTrigger,
        uint16 hostFee
    ) public nonReentrant onlyAdmin {
        _createAuction(
            nft,
            seller,
            tokenId,
            startPrice,
            startAt,
            endAt,
            minOutbid,
            extensionDuration,
            extensionTrigger,
            hostFee
        );
    }

    /**
     * @notice Creates an auction for the given NFT.
     * The NFT is held in escrow until the auction is finalized or cancelled.
     */
    function createAuction(
        address nft,
        uint256 tokenId,
        uint256 startPrice,
        uint64 startAt,
        uint64 endAt,
        uint64 minOutbid,
        uint16 extensionDuration,
        uint16 extensionTrigger
    ) public nonReentrant {
        _createAuction(
            nft,
            msg.sender,
            tokenId,
            startPrice,
            startAt,
            endAt,
            minOutbid,
            extensionDuration,
            extensionTrigger,
            0
        );
    }

    /**
     * @notice If an auction has been created but has not yet received bids, the configuration
     * such as the startPrice may be changed by the seller or admin.
     */
    function updateAuction(uint256 auctionId, uint256 startPrice) public {
        Auction storage auction = _auctionIdToAuction[auctionId];
        require(auction.bidder == address(0), "Auction in progress");
        require(
            auction.seller == msg.sender || isAdmin(msg.sender),
            "Unauthorized"
        );

        auction.amount = startPrice;

        emit AuctionUpdated(auctionId, startPrice);
    }

    /**
     * @notice If an auction has been created but has not yet received bids, it may be cancelled by the seller or admin.
     * The NFT is returned to the seller from escrow.
     */
    function cancelAuction(uint256 auctionId) public nonReentrant {
        Auction memory auction = _auctionIdToAuction[auctionId];
        require(auction.bidder == address(0), "Auction in progress");
        require(
            auction.seller == msg.sender || isAdmin(msg.sender),
            "Unauthorized"
        );

        delete _nftToTokenIdToAuctionId[auction.nft][auction.tokenId];
        delete _auctionIdToAuction[auctionId];

        IERC721(auction.nft).transferFrom(
            address(this),
            auction.seller,
            auction.tokenId
        );

        emit AuctionCancelled(auctionId);
    }

    /**
     * @notice Allows Platform to cancel an auction, refunding the bidder and returning the NFT to the seller.
     * This should only be used for extreme cases such as DMCA takedown requests. The reason should always be provided.
     */
    function adminCancelAuction(uint256 auctionId, string memory reason)
        public
        onlyAdmin
    {
        require(bytes(reason).length > 0, "Reason required");
        Auction memory auction = _auctionIdToAuction[auctionId];
        require(auction.amount != 0, "Auction not found");

        delete _nftToTokenIdToAuctionId[auction.nft][auction.tokenId];
        delete _auctionIdToAuction[auctionId];

        IERC721(auction.nft).transferFrom(
            address(this),
            auction.seller,
            auction.tokenId
        );

        if (auction.bidder != address(0)) {
            _trySendAmount(auction.bidder, auction.amount, _mediumGasLimit);
        }

        emit AuctionCanceledByAdmin(auctionId, reason);
    }

    /**
     * @notice A bidder may place a bid which is at least the value defined by `getMinBidAmount`.
     * If there is already an outstanding bid, the previous bidder will be refunded at this time
     * and if the bid is placed in the final moments of the auction, the countdown may be extended.
     */
    function placeBid(uint256 auctionId) public payable nonReentrant {
        Auction storage auction = _auctionIdToAuction[auctionId];
        require(auction.amount != 0, "Auction not found");
        require(auction.endAt >= block.timestamp, "Auction is over");
        require(auction.startAt <= block.timestamp, "Auction not started");

        if (auction.bidder == address(0)) {
            // This is first bid
            require(msg.value >= auction.amount, "Bid amount too low");

            auction.amount = msg.value;
            auction.bidder = payable(msg.sender);
        } else {
            // This is outbid attempt
            require(msg.value > auction.amount, "Bid amount too low");
            uint256 outbid;
            unchecked {
                outbid = msg.value - auction.amount;
            }
            require(outbid >= auction.minOutbid, "Bid amount too low");

            uint256 prevAmount = auction.amount;
            address prevBidder = auction.bidder;
            auction.amount = msg.value;
            auction.bidder = payable(msg.sender);

            // When a bid outbids another, check to see if a time extension should apply.
            unchecked {
                if (
                    auction.endAt - block.timestamp < auction.extensionTrigger
                ) {
                    auction.endAt = auction.endAt + auction.extensionDuration;
                }
            }

            _trySendAmount(prevBidder, prevAmount, _lowGasLimit);
        }

        emit BidPlaced(auctionId, msg.sender, msg.value, auction.endAt);
    }

    /**
     * @notice When auction end date is reached it should be finalized using transaction calling this function.
     * NFT is transferred to the winner and funds are distributed between - seller, host and creator
     */
    function finalizeAuction(uint256 auctionId) public nonReentrant {
        Auction memory auction = _auctionIdToAuction[auctionId];
        require(auction.amount != 0, "Auction not found");
        require(auction.endAt < block.timestamp, "Auction in progress");

        delete _nftToTokenIdToAuctionId[auction.nft][auction.tokenId];
        delete _auctionIdToAuction[auctionId];

        if (auction.bidder == address(0)) {
            // There were no bidders on this auction.
            // Just return the NFT to the seller
            IERC721(auction.nft).transferFrom(
                address(this),
                auction.seller,
                auction.tokenId
            );

            return;
        }

        // Transfer the NFT to the winner
        IERC721(auction.nft).transferFrom(
            address(this),
            auction.bidder,
            auction.tokenId
        );

        address creatorAddress;
        uint256 hostCut;
        uint256 creatorCut;
        uint256 sellerCut;

        // Calculate all the cuts - seller, host, creator(respecting IERC2981)
        if (IERC165(auction.nft).supportsInterface(type(IERC2981).interfaceId)) {
            (
                address creatorRoyaltyAddress,
                uint256 creatorRoyaltyAmount
            ) = IERC2981(auction.nft).royaltyInfo{gas: _readGasLimit}(
                    auction.tokenId,
                    auction.amount
                );

            if (creatorRoyaltyAddress != auction.seller) {
                // Make sure that creatorRoyaltyAmount is reasonable
                uint256 royatlyLimit = (auction.amount * _royaltyLimit) /
                    10000;

                creatorCut = royatlyLimit >= creatorRoyaltyAmount
                    ? creatorRoyaltyAmount
                    : royatlyLimit;
                creatorAddress = creatorRoyaltyAddress;
            }
        }

        uint16 hostFee = auction.hostFee == 1
            ? 0
            : (auction.hostFee > 1 ? auction.hostFee : _hostFee);
        hostCut = (auction.amount * hostFee) / 10000;
        sellerCut = auction.amount - hostCut - creatorCut;

        // Send funds to the parties
        _trySendAmount(_hostTreasury, hostCut, _lowGasLimit);
        _trySendAmount(auction.seller, sellerCut, _mediumGasLimit);
        _trySendAmount(creatorAddress, creatorCut, _mediumGasLimit);

        emit AuctionFinalized(
            auctionId,
            auction.seller,
            auction.bidder,
            auction.endAt,
            auction.amount
        );
    }

    /**
     * @notice Allows anyone to manually trigger a withdraw of funds which originally failed to transfer for a user.
     */
    function withdrawFor(address user) public nonReentrant {
        uint256 amount = _pendingWithdraws[user];
        require(amount > 0, "Nothing to withdraw");
        require(address(this).balance >= amount, "Insufficient balance");

        _pendingWithdraws[user] = 0;

        (bool success, ) = payable(user).call{value: amount}("");
        require(success, "Withdraw failed");

        emit WithdrawSuccess(user, amount);
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes memory data
    ) public pure returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /*********************************************
     *********************************************
     *  P r i v a t e
     *      m e t h o d s
     *
     */
    function _createAuction(
        address nft,
        address seller,
        uint256 tokenId,
        uint256 startPrice,
        uint64 startAt,
        uint64 endAt,
        uint64 minOutbid,
        uint16 extensionDuration,
        uint16 extensionTrigger,
        uint16 hostFee
    ) private {
        require(startPrice > _minStartPrice, "Starting price too low");
        require(
            _nftToTokenIdToAuctionId[nft][tokenId] == 0,
            "NFT already on auction"
        );
        require(
            startAt < endAt && (endAt - startAt) >= _minAuctionDuration,
            "Invalid auction duration"
        );
        require(
            extensionDuration >= _minDurationExt &&
                extensionDuration <= _maxDurationExt,
            "Extension duration out of bounds"
        );

        uint256 auctionId = _getNextAuctionId();
        _nftToTokenIdToAuctionId[nft][tokenId] = auctionId;
        _auctionIdToAuction[auctionId] = Auction(
            nft,
            address(0),
            seller,
            tokenId,
            startPrice,
            startAt,
            endAt,
            minOutbid,
            extensionDuration,
            extensionTrigger,
            hostFee
        );

        IERC721(nft).transferFrom(seller, address(this), tokenId);

        emit AuctionCreated(
            seller,
            nft,
            tokenId,
            startPrice,
            auctionId,
            startAt,
            endAt
        );
    }

    function _getNextAuctionId() private returns (uint256) {
        return ++_auctionId;
    }

    /**
     * @dev Attempt to send a user or contract ETH and if it fails store the amount owned for later withdraw.
     */
    function _trySendAmount(
        address user,
        uint256 amount,
        uint256 gasLimit
    ) private {
        if (amount == 0 || address(0) == user) {
            return;
        }

        // Cap the gas to prevent consuming all available gas to block a tx from completing successfully
        (bool success, ) = payable(user).call{value: amount, gas: gasLimit}("");
        if (!success) {
            // Record failed sends for a withdraw later
            // Transfers could fail if sent to a multisig with non-trivial receiver logic
            _pendingWithdraws[user] += amount;
            emit WithdrawFailed(user, amount);
        }
    }
}