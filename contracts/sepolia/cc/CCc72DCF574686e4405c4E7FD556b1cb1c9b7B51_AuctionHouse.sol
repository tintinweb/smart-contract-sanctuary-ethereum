/**
 *Submitted for verification at Etherscan.io on 2023-06-12
*/

pragma solidity ^0.8.18;
// SPDX-License-Identifier: MIT


abstract contract Asset {
    function owner(string memory _recordId) public virtual returns (address ownerAddress);

    function setOwner(string memory _recordId, address _newOwner) public virtual returns (bool success);    
}

contract AuctionHouse {

    struct Bid {
        address bidder;
        uint256 amount;
        uint timestamp;
    }

    enum AuctionStatus {Pending, Active, Inactive}

    struct Auction {
        // Location and ownership information of the item for sale
        address seller;
        address contractAddress; // Contract where the item exists
        string recordId;         // RecordID within the contract as per the Asset interface

        // Auction metadata
        string title;
        string description;      // Optionally markdown formatted?
        uint blockNumberOfDeadline;
        AuctionStatus status;

        // Distribution bonus
        uint distributionCut;    // In percent, ie 10 is a 10% cut to the distribution address
        address distributionAddress; 

        // Pricing
        uint256 startingPrice;   // In wei
        uint256 reservePrice;
        uint256 currentBid;

        Bid[] bids;
    }

    Auction[] public auctions;          // All auctions
    mapping(address => uint[]) public auctionsRunByUser; // Pointer to auctions index for auctions run by this user

    mapping(address => uint[]) public auctionsBidOnByUser; // Pointer to auctions index for auctions this user has bid on

    mapping(string => bool) activeContractRecordConcat;

    mapping(address => uint) refunds;

    address owner;

    // Events
    event AuctionCreated(uint id, string title, uint256 startingPrice, uint256 reservePrice);
    event AuctionActivated(uint id);
    event AuctionCancelled(uint id);
    event BidPlaced(uint auctionId, address bidder, uint256 amount);
    event AuctionEndedWithWinner(uint auctionId, address winningBidder, uint256 amount);
    event AuctionEndedWithoutWinner(uint auctionId, uint256 topBid, uint256 reservePrice);

    event LogFailure(string message);

    modifier onlyOwner {
        require(owner == msg.sender, "Only owner can call this function.");
        _;
    }

    modifier onlySeller(uint auctionId) {
        require(auctions[auctionId].seller == msg.sender, "Only the seller can call this function.");
        _;
    }

    modifier onlyLive(uint auctionId) {
        require(
            auctions[auctionId].status == AuctionStatus.Active &&
            block.number < auctions[auctionId].blockNumberOfDeadline,
            "Auction is either inactive or deadline has passed."
        );
        _;
    }

    constructor() {
        owner = msg.sender;
    }
    // Create an auction, transfer the item to this contract, activate the auction
    function createAuction(
                           string memory _title,
                           string memory _description,
                           address _contractAddressOfAsset,
                           string memory _recordIdOfAsset,
                           uint _deadline,   // in blocknumber
                           uint256 _startingPrice,
                           uint256 _reservePrice,
                           uint _distributionCut,
                           address _distributionCutAddress) public returns (uint auctionId) {

        // Check to see if the seller owns the asset at the contract
        if (!partyOwnsAsset(msg.sender, _contractAddressOfAsset, _recordIdOfAsset)) {
            emit LogFailure("Seller does not own this asset");
            revert();
        }

        // Check to see if the auction deadline is in the future
        if (block.number >= _deadline) {
            emit LogFailure("Block number is not in the future");
            revert();
        }

        // Price validations
        if (_startingPrice < 0 || _reservePrice < 0) {
            emit LogFailure("StartingPrice or ReservePrice was below zero");
            revert();
        }

        // Distribution validations
        if (_distributionCut < 0 || _distributionCut > 100) {
            emit LogFailure("DistributionCut is invalid");
            revert();
        }

        if (activeContractRecordConcat[strConcat(addrToString(_contractAddressOfAsset), _recordIdOfAsset)] == true) {
            emit LogFailure("Item already on auction");
            revert();
        }

        auctionId = auctions.length + 1;
        Auction storage a = auctions[auctionId];
        a.seller = msg.sender;
        a.contractAddress = _contractAddressOfAsset;
        a.recordId = _recordIdOfAsset;
        a.title = _title;
        a.description = _description;
        a.blockNumberOfDeadline = _deadline;
        a.status = AuctionStatus.Pending;
        a.distributionCut = _distributionCut;
        a.distributionAddress = _distributionCutAddress;
        a.startingPrice = _startingPrice;
        a.reservePrice = _reservePrice;
        a.currentBid = _startingPrice;

        auctionsRunByUser[a.seller].push(auctionId);
        activeContractRecordConcat[strConcat(addrToString(_contractAddressOfAsset), _recordIdOfAsset)] = true;

        emit AuctionCreated(auctionId, a.title, a.startingPrice, a.reservePrice);

        return auctionId;
    }

    function partyOwnsAsset(address _party, address _contract, string memory _recordId) public returns (bool success) {
        Asset assetContract = Asset(_contract);
        return assetContract.owner(_recordId) == _party;
    }

    /**
     * The auction fields are indexed in the return val as follows
     * [0]  -> Auction.seller
     * [1]  -> Auction.contractAddress
     * [2]  -> Auction.recordId
     * [3]  -> Auction.title
     * [4]  -> Auction.description
     * [5]  -> Auction.blockNumberOfDeadline
     * [6]  -> Auction.distributionCut
     * [7]  -> Auction.distributionAddress
     * [8]  -> Auction.startingPrice
     * [9] -> Auction.reservePrice
     * [10] -> Auction.currentBid
     * [11] -> Auction.bids.length      
     * []  -> Auction.status (Not included right now)
     */
    function getAuction(uint idx) public view returns (address, address, string memory, string memory, string memory, uint, uint, address, uint256, uint256, uint256, uint) {
        Auction storage a = auctions[idx];
        require(a.seller != address(0), "Seller address should not be zero");

        return (a.seller,
                a.contractAddress,
                a.recordId,
                a.title,
                a.description,
                a.blockNumberOfDeadline,
                a.distributionCut,
                a.distributionAddress,
                a.startingPrice,
                a.reservePrice,
                a.currentBid,
                a.bids.length
                );
    }

    function getAuctionCount() public view returns (uint) {
        return auctions.length;
    }

    function getStatus(uint idx) public view returns (uint) {
        Auction storage a = auctions[idx];
        return uint(a.status);
    }

    function getAuctionsCountForUser(address addr) public view returns (uint) {
        return auctionsRunByUser[addr].length;
    }

    function getAuctionIdForUserAndIdx(address addr, uint idx) public view returns (uint) {
        return auctionsRunByUser[addr][idx];
    }

    function getActiveContractRecordConcat(string memory _contractRecordConcat) public view returns (bool) {
        return activeContractRecordConcat[_contractRecordConcat];
    }

    // Checks if this contract address is the owner of the item for the auction
    function activateAuction(uint auctionId) onlySeller(auctionId) public returns (bool){
        Auction storage a = auctions[auctionId];

        if (!partyOwnsAsset(address(this), a.contractAddress, a.recordId)) revert();

        a.status = AuctionStatus.Active;
        emit AuctionActivated(auctionId);
        return true;
    }

    function cancelAuction(uint auctionId) onlySeller(auctionId) public returns (bool) {
        Auction storage a = auctions[auctionId];

        if (!partyOwnsAsset(address(this), a.contractAddress, a.recordId)) revert();
        if (a.currentBid >= a.reservePrice) revert();   // Can't cancel the auction if someone has already outbid the reserve.

        Asset asset = Asset(a.contractAddress);
        if(!asset.setOwner(a.recordId, a.seller)) {
            revert();
        }

        // Refund to the bidder
        uint bidsLength = a.bids.length;
        if (bidsLength > 0) {
            Bid storage topBid = a.bids[bidsLength - 1];
            refunds[topBid.bidder] += topBid.amount;

            activeContractRecordConcat[strConcat(addrToString(a.contractAddress), a.recordId)] = false;
        }

        emit AuctionCancelled(auctionId);
        a.status = AuctionStatus.Inactive;
        return true;
    }

    /* BIDS */
    function getBidCountForAuction(uint auctionId) public view returns (uint) {
        Auction storage a = auctions[auctionId];
        return a.bids.length;
    }

    function getBidForAuctionByIdx(uint auctionId, uint idx) public view returns (address bidder, uint256 amount, uint timestamp) {
        Auction storage a = auctions[auctionId];
        require(idx <= a.bids.length - 1, "Invalid index");

        Bid storage b = a.bids[idx];
        return (b.bidder, b.amount, b.timestamp);
    }

    function placeBid(uint auctionId) payable onlyLive(auctionId) public returns (bool success) {
        uint256 amount = msg.value;
        Auction storage a = auctions[auctionId];

        require(a.currentBid < amount, "Bid amount should be higher than the current bid");

        uint bidIdx = a.bids.length + 1;
        Bid storage b = a.bids[bidIdx];
        b.bidder = msg.sender;
        b.amount = amount;
        b.timestamp = block.timestamp;
        a.currentBid = amount;

        auctionsBidOnByUser[b.bidder].push(auctionId);

        // Log refunds for the previous bidder
        if (bidIdx > 0) {
            Bid storage previousBid = a.bids[bidIdx - 1];
            refunds[previousBid.bidder] += previousBid.amount;
        }

        emit BidPlaced(auctionId, b.bidder, b.amount);
        return true;
    }

    function getRefundValue() public view returns (uint) {
        return refunds[msg.sender];
    }

    function withdrawRefund() public {
        uint refund = refunds[msg.sender];
        refunds[msg.sender] = 0;
        (bool success,) = msg.sender.call{value: refund}("");
        require(success, "Refund transfer failed");
    }

    function endAuction(uint auctionId) public returns (bool success) {
        // Check if the auction is passed the end date
        Auction storage a = auctions[auctionId];
        activeContractRecordConcat[strConcat(addrToString(a.contractAddress), a.recordId)] = false;

        // Make sure auction hasn't already been ended
        require(a.status == AuctionStatus.Active, "Can only end an active auction");
        
        require(block.number >= a.blockNumberOfDeadline, "Can not end an auction that hasn't hit the deadline yet");

        Asset asset = Asset(a.contractAddress);

        // No bids, make the auction inactive
        if (a.bids.length == 0) {
            require(asset.setOwner(a.recordId, a.seller), "Asset ownership transfer failed");
            a.status = AuctionStatus.Inactive;
            return true;
        }

        Bid storage topBid = a.bids[a.bids.length - 1];

        // If the auction hit its reserve price
        if (a.currentBid >= a.reservePrice) {
            uint distributionShare = a.currentBid * a.distributionCut / 100;  // Calculate the distribution cut
            uint sellerShare = a.currentBid - distributionShare;

            require(asset.setOwner(a.recordId, topBid.bidder), "Asset ownership transfer failed"); // Set the items new owner

            refunds[a.distributionAddress] += distributionShare;
            refunds[a.seller] += sellerShare;

            emit AuctionEndedWithWinner(auctionId, topBid.bidder, a.currentBid);
        } else {
            // Return the item to the owner and the money to the top bidder
            require(asset.setOwner(a.recordId, a.seller), "Asset ownership transfer failed");

            refunds[topBid.bidder] += a.currentBid;

            emit AuctionEndedWithoutWinner(auctionId, a.currentBid, a.reservePrice);
        }

        a.status = AuctionStatus.Inactive;
        return true;
    }

    function strConcat(string memory _a, string memory _b) internal pure returns (string memory) {
        return string(abi.encodePacked(_a, _b));
    }

    function addrToString(address x) internal pure returns (string memory) {
        return string(abi.encodePacked(x));
    }
}