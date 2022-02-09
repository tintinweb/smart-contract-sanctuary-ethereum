//SPDX-License-Identifier: MIT

/*
    <__ / ___ 
     <_ \/ . |
    <___/\_  |

    Auction
    1.) Auction lasts for days specified at start.
    2.) Participants can bid by depositing ETH greater than the current highest bidder.
    3.) All bidders except the highest bidder can withdraw their bid

    After the auction:
    1.) Highest bidder becomes the new owner of NFT.
    2.) The seller receives the highest bid of ETH.
*/

pragma solidity 0.8.11;
pragma abicoder v2;

import "./AccessControl.sol";
import "./IERC721.sol";
import "./Address.sol";

contract MultiEnglishAuction is AccessControl
{
    // ====================================================
    // EVENTS
    // ====================================================
    event AuctionStarted(uint auctionId);
    event AuctionEnded(uint auctionId, address addr, uint value);
    event BidReceived(uint auctionId, address addr, uint value);
    event Withdraw(uint auctionId, address addr, uint value);

    // ====================================================
    // ENUMS & STRUCTS
    // ====================================================
    enum AuctionStatus { NOT_STARTED, IN_PROGRESS, ENDED }

    struct AuctionDetails {
        address nftContract;
        address payable seller;
        address payable highestBidder;
        uint tokenId;
        uint startingBid;
        uint highestBid;
        uint startTime;
        uint endTime;
        string auctionName;
        AuctionStatus auctionStatus;
        bool handbrakeOn;
    }

    // ====================================================
    // STATE
    // ====================================================
    AuctionDetails[] public auctions;
    mapping(uint => mapping(address => uint)) public bids;

    // ====================================================
    // CONSTRUCTOR
    // ====================================================
    constructor()
    {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    // ====================================================
    // ADMIN
    // ====================================================
    function setupAuction(
        address _nftContract,
        uint _tokenId,
        uint _startingBid,
        string memory _auctionName
    )
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(IERC721(_nftContract).ownerOf(_tokenId) == msg.sender, "Must be an owner to configure and NFT auction");

        auctions.push(
            AuctionDetails({
                nftContract: _nftContract,
                seller: payable(msg.sender),
                highestBidder: payable(0),
                tokenId: _tokenId,
                startingBid: _startingBid,
                highestBid: _startingBid,
                startTime: 0,
                endTime: 0,
                auctionName: _auctionName,
                auctionStatus: AuctionStatus.NOT_STARTED,
                handbrakeOn: false
            })
        );
    }

    function toggleAuctionHandbrake(uint _auctionId)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        auctions[_auctionId].handbrakeOn = !auctions[_auctionId].handbrakeOn;
    }

    function start(uint _auctionId, uint numHoursDuration)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        // ensure auction is in NOT_STARTED state
        require(auctions[_auctionId].auctionStatus == AuctionStatus.NOT_STARTED, "Auction state invalid (required NOT_STARTED)");

        require(msg.sender == auctions[_auctionId].seller, "Seller needs to start auction");
        
        auctions[_auctionId].auctionStatus = AuctionStatus.IN_PROGRESS;
        auctions[_auctionId].startTime = block.timestamp;
        auctions[_auctionId].endTime = block.timestamp + numHoursDuration * 1 hours;

        IERC721(auctions[_auctionId].nftContract).transferFrom(msg.sender, address(this), auctions[_auctionId].tokenId);

        emit AuctionStarted(_auctionId);
    }

    function end(uint _auctionId)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        // ensure auction is in NOT_STARTED state
        require(auctions[_auctionId].auctionStatus == AuctionStatus.IN_PROGRESS, "Auction state invalid (required IN_PROGRESS)");

        // check if auction time has elapsed
        require(block.timestamp >= auctions[_auctionId].endTime, "Wait for auction duration to pass");

        auctions[_auctionId].auctionStatus = AuctionStatus.ENDED;
        
        if(auctions[_auctionId].highestBidder != address(0)) {
            // higher bids received, transfer funds & nft
            auctions[_auctionId].seller.transfer(auctions[_auctionId].highestBid);
            bids[_auctionId][auctions[_auctionId].highestBidder] = 0;
            IERC721(auctions[_auctionId].nftContract).safeTransferFrom(address(this), auctions[_auctionId].highestBidder, auctions[_auctionId].tokenId);
        }
        else {
            // no bids higher than original startingBid, send nft back to seller
            IERC721(auctions[_auctionId].nftContract).safeTransferFrom(address(this), auctions[_auctionId].seller, auctions[_auctionId].tokenId);
        }

        emit AuctionEnded(_auctionId, auctions[_auctionId].highestBidder, auctions[_auctionId].highestBid);
    }

    // ====================================================
    // PUBLIC API
    // ====================================================
    function auctionDetails(uint _auctionId)
        public
        view
        returns(AuctionDetails memory _auctionDetails, uint _myBid)
    {
        _auctionDetails = auctions[_auctionId];
        _myBid = bids[_auctionId][msg.sender];
    }

    function bid(uint _auctionId)
        public
        payable
    {
        // ensure auction is in NOT_STARTED state and handbrake isn't on
        require(auctions[_auctionId].auctionStatus == AuctionStatus.IN_PROGRESS, "Auction state invalid (required IN_PROGRESS)");
        require(!auctions[_auctionId].handbrakeOn, "Auction handbrake is on");

        // ensure auction time has not expires
        require(block.timestamp < auctions[_auctionId].endTime, "Auction already ended");

        // no bidding from contracts permitted
        require(!Address.isContract(msg.sender), "Contracts forbidden from bidding");

        // ensure bid is higher than current highest bid
        require(bids[_auctionId][msg.sender] + msg.value > auctions[_auctionId].highestBid, "Bid is not high enough");

        // record state changes
        bids[_auctionId][msg.sender] += msg.value;
        auctions[_auctionId].highestBid = bids[_auctionId][msg.sender];
        auctions[_auctionId].highestBidder = payable(msg.sender);

        emit BidReceived(_auctionId, msg.sender, msg.value);
    }

    function withdraw(uint _auctionId)
        public
    {
        require(msg.sender != auctions[_auctionId].highestBidder, "Highest bidder can't withdraw");
        require(bids[_auctionId][msg.sender] > 0, "No pending bids");

        uint bal = bids[_auctionId][msg.sender];
        bids[_auctionId][msg.sender] = 0;
        payable(msg.sender).transfer(bal);

        emit Withdraw(_auctionId, msg.sender, bal);
    }
}