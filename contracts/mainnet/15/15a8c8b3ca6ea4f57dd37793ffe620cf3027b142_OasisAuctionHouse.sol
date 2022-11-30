// SPDX-License-Identifier: GPL-3.0

// The Wildxyz auctionhouse.sol

// AuctionHouse.sol is a modified version of the original code from the
// NounsAuctionHouse.sol which is a modified version of Zora's AuctionHouse.sol:
// https://github.com/ourzora/auction-house/
// licensed under the GPL-3.0 license.

pragma solidity ^0.8.4;

import './Pausable.sol';
import './ReentrancyGuard.sol';
import './Ownable.sol';
import './IOasis.sol';
import './IAuctionHouse.sol';

contract OasisAuctionHouse is
    IAuctionHouse,
    Pausable,
    ReentrancyGuard,
    Ownable
{

    // auction variables
    uint256 public timeBuffer = 120; // min amount of time left in an auction after last bid
    uint256 public minimumBid = .1 ether; // The minimum price accepted in an auction
    uint256 public duration = 86400; // 86400 == 1 day /The duration of a single auction in seconds
    uint8 public minBidIncrementPercentage = 2; // The minimum bid increment percentage
    address payable public payee; // The address that receives funds from the auction

    Oasis public oasis; // The oasis contract

    uint256 public currentTokenId; // The current token ID being auctioned

    // The active auction
    IAuctionHouse.Auction public auction;

    // Only allow the auction functions to be active when not paused
    modifier onlyUnpaused() {
        require(!paused(), 'AuctionHouse: paused');
        _;
    }

    // Bids Struct
    struct Bid {
        address payable bidder; // The address of the bidder
        uint256 amount; // The amount of the bid
        bool minted; // has the bid been minted
        uint256 timestamp; // timestamp of the bid
        bool refunded; // refund difference between winning_bid and max_bid for winner; and all for losers // enter reentrancy guard
        bool winner; // is the bid the winner
    }

    // mapping of Bid structs
    mapping(address => Bid) public Bids;

    constructor(Oasis _oasis) {
        oasis = _oasis;
        // set the payee to the contract owner
        payee = payable(msg.sender);
        _pause();
    }

    /* ADMIN VARIABLE SETTERS FUNCTIONS */

    // set the 721 contract address
    function set721ContractAddress(Oasis _newOasis) public onlyOwner {
        oasis = _newOasis;
    }

    // set the time buffer
    function setTimeBuffer(uint256 _timeBuffer) external onlyOwner override {
        timeBuffer = _timeBuffer;
        emit AuctionTimeBufferUpdated(_timeBuffer);
    }

    // set the minimum bid
    function setMinimumBid(uint256 _minimumBid) external onlyOwner {
        minimumBid = _minimumBid;
    }

    // set the duration
    function setDuration(uint256 _duration) external onlyOwner override {
        duration = _duration;
        emit AuctionDurationUpdated(_duration);
    }

    // set the min bid increment percentage
    function setMinBidIncrementPercentage(uint8 _minBidIncrementPercentage)
        external
        onlyOwner
        override
    {
        minBidIncrementPercentage = _minBidIncrementPercentage;
        emit AuctionMinBidIncrementPercentageUpdated(_minBidIncrementPercentage);
    }

    // promo mint
    function promoMint(address _to, uint256 _qty) external onlyOwner {
        oasis.promoMint(_to, _qty);
    }

    // pause
    function pause() external onlyOwner override {
        _pause();
    }

    // unpause
    function unpause() external onlyOwner override {
        _unpause();

        if (auction.startTime == 0 || auction.settled) {
            _createAuction();
        }
    }

    // Settle the current auction (only when paused)
    function settleAuction() external whenPaused onlyOwner nonReentrant override {
        _settleAuction();
    }

    // withdraw
    function withdraw() public {
        (bool success, ) = payee.call{value: address(this).balance}("");
        require(success, "Failed to send to payee.");
    }

    // update payee for withdraw
    function setPayee(address payable _payee) public onlyOwner {
        payee = _payee;
    }

    /* END ADMIN VARIABLE SETTERS FUNCTIONS */

    /* PUBLIC FUNCTIONS */

    // Settles and creates a new auction
    function settleCurrentAndCreateNewAuction() external nonReentrant override {
        _settleAuction();
        _createAuction();
        require(block.timestamp >= auction.startTime, 'AuctionHouse: auction not started');
    }

    // Creates bids for the current auction
    function createBid(uint256 _currentTokenId) external payable nonReentrant override onlyUnpaused {

        // Query the auction state
        IAuctionHouse.Auction memory _auction = auction; 

        // Check that the auction is live
        require(_currentTokenId == _auction.tokenId, 'Bid on wrong tokenId.');
        require(block.timestamp < _auction.endTime, "Auction has ended");
        require(block.timestamp > _auction.startTime, "Auction has not started");
        require(msg.value >= minimumBid, "Bid is too low.");
        require(
            msg.value >= _auction.amount + ((_auction.amount * minBidIncrementPercentage) / 100), 
            "Bid is too low."
        );

        // A reference to benchmark the new bid against
        address payable lastBidder = _auction.bidder;

        // Refund the previous highest bidder,
        if (lastBidder != address(0) ) {
            _safeTransferETH(lastBidder, _auction.amount);
            Bids[lastBidder].refunded = true;
        }

        Bid memory new_bid;
        new_bid.bidder = payable(msg.sender);
        new_bid.amount = msg.value;
        new_bid.timestamp = block.timestamp;
        new_bid.winner = false;
        new_bid.refunded = false;
        Bids[msg.sender] = new_bid;

        // Update the auction state with the new bid bidder and the new amount
        auction.bidder = payable(msg.sender);
        auction.amount = msg.value;


        // Extend the auction if the bid was received within the time buffer
        bool extended = _auction.endTime - block.timestamp < timeBuffer;
        if (extended) {
            auction.endTime = _auction.endTime = block.timestamp + timeBuffer;
            auction.extendedTime = _auction.extendedTime + timeBuffer;
        }

        emit AuctionBid(currentTokenId, msg.sender, Bids[msg.sender].amount, extended);

        if (extended) {
            emit AuctionExtended(currentTokenId, _auction.endTime);
        }

    }
    

    /* END PUBLIC FUNCTIONS */

    /* INTERNAL FUNCTIONS */

    /**
     * @notice Create an auction.
     * @dev Store the auction details in the `auction` state variable and emit an AuctionCreated event.
     * If the mint reverts, the minter was updated without pausing this contract first. To remedy this,
     * catch the revert and pause this contract.
     */
    function _createAuction() internal {
        try oasis.mint(address(this)) returns (uint256 tokenId) {
            require(auction.endTime < block.timestamp, "AuctionHouse: auction not ended");

            IAuctionHouse.Auction memory _auction = auction;

            auction = Auction({
                tokenId: tokenId,
                amount: 0,
                startTime: block.timestamp,
                endTime: block.timestamp + duration - _auction.extendedTime,
                bidder: payable(0),
                settled: false,
                extendedTime: 0
            });

            currentTokenId = tokenId;

            emit AuctionCreated(tokenId, auction.startTime, auction.endTime);
        } catch Error(string memory) {
            _pause();
        }
    }

    /**
     * Settle an auction, finalizing the bid and paying out to the owner.
     * If there are no bids, the Oasis is burned.
     */
    function _settleAuction() internal {
        require(auction.startTime != 0, "Auction hasn't begun");
        IAuctionHouse.Auction memory _auction = auction;

        Bid storage winning_bid = Bids[msg.sender];

        require(_auction.startTime != 0, "Auction hasn't begun");
        require(!_auction.settled, "Auction has already been settled");
        require(
            block.timestamp >= _auction.endTime,
            "Auction hasn't completed"
        );

        auction.settled = true;

        if (_auction.bidder == address(0)) {
            oasis.burn(_auction.tokenId);
        } else {
            oasis.transferFrom(
                address(this),
                _auction.bidder,
                _auction.tokenId
            );
             winning_bid.winner = true;
             winning_bid.minted = true;
        }

        if (_auction.amount > 0) {
            _safeTransferETH(payee, _auction.amount);
        }

        emit AuctionSettled(_auction.tokenId, _auction.bidder, _auction.amount);
    }

    /**
     * Transfer ETH and return the success status.
     * This function only forwards 30,000 gas to the callee.
     */
    function _safeTransferETH(address to, uint256 value)
        internal
        returns (bool)
    {
        (bool success, ) = to.call{value: value, gas: 30_000}(new bytes(0));
        return success;
    }
}