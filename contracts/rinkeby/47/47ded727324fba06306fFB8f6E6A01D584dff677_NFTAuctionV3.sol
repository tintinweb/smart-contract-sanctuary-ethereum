// SPDX-License-Identifier: Unlicense
// moved from https://github.com/museum-of-war/auction
pragma solidity 0.8.14;

import "IERC721.sol";
import "Ownable.sol";

/// @title An Auction Contract for bidding single NFTs with more manual control (modified version of NFTAuctionV2)
/// @notice This contract can be used for auctioning any NFTs
contract NFTAuctionV3 is Ownable {
    mapping(address => mapping(uint256 => Auction)) public nftContractAuctions;
    mapping(address => uint256) failedTransferCredits;

    //Each Auction is unique to each NFT (contract + id pairing).
    struct Auction {
        //map token ID to
        uint32 bidIncreasePercentage;
        uint32 auctionBidPeriod; //Increments the length of time the auction is open in which a new bid can be made after each bid.
        uint64 auctionStart;
        uint64 auctionEnd;
        uint128 minPrice;
        uint128 nftHighestBid;
        address nftHighestBidder;
        address feeRecipient;
    }

    uint32 public constant withdrawPeriod = 604800; //1 week

    /*в•”в•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•—
      в•‘           EVENTS            в•‘
      в•љв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ќ*/

    event NftAuctionCreated(
        address indexed nftContractAddress,
        uint256 indexed tokenId,
        uint128 minPrice,
        uint64 auctionStart,
        uint64 auctionEnd,
        uint32 auctionBidPeriod,
        uint32 bidIncreasePercentage,
        address feeRecipient
    );

    event BidMade(
        address indexed nftContractAddress,
        uint256 indexed tokenId,
        address bidder,
        uint256 ethAmount
    );

    event AuctionPeriodUpdated(
        address indexed nftContractAddress,
        uint256 indexed tokenId,
        uint64 auctionEndPeriod
    );

    event NFTTransferredAndSellerPaid(
        address indexed nftContractAddress,
        uint256 indexed tokenId,
        uint128 nftHighestBid,
        address nftHighestBidder
    );

    event AuctionSettled(
        address indexed nftContractAddress,
        uint256 indexed tokenId
    );

    event AuctionWithdrawn(
        address indexed nftContractAddress,
        uint256 indexed tokenId
    );

    event HighestBidTaken(
        address indexed nftContractAddress,
        uint256 indexed tokenId
    );
    /**********************************/
    /*в•”в•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•—
      в•‘             END             в•‘
      в•‘            EVENTS           в•‘
      в•љв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ќ*/
    /**********************************/
    /*в•”в•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•—
      в•‘          MODIFIERS          в•‘
      в•љв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ќ*/

    modifier auctionOngoing(address _nftContractAddress, uint256 _tokenId) {
        require(_isAuctionStarted(_nftContractAddress, _tokenId), "Auction has not started");
        require(_isAuctionOngoing(_nftContractAddress, _tokenId), "Auction has ended");
        _;
    }

    /*
     * The bid amount must be higher than the previous
     * bid by the specified bid increase percentage.
     */
    modifier bidAmountMeetsBidRequirements(address _nftContractAddress, uint256 _tokenId) {
        require(_doesBidMeetBidRequirements(_nftContractAddress, _tokenId), "Not enough funds to bid on NFT");
        _;
    }

    modifier notZeroAddress(address _address) {
        require(_address != address(0), "Cannot specify 0 address");
        _;
    }

    /**********************************/
    /*в•”в•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•—
      в•‘             END             в•‘
      в•‘          MODIFIERS          в•‘
      в•љв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ќ*/
    /**********************************/
    /*в•”в•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•—
      в•‘    AUCTION CHECK FUNCTIONS   в•‘
      в•љв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ќ*/
    function _isAuctionStarted(address _nftContractAddress, uint256 _tokenId) internal view returns (bool) {
        uint64 auctionStartTimestamp = nftContractAuctions[_nftContractAddress][
            _tokenId
        ].auctionStart;
        return (block.timestamp >= auctionStartTimestamp);
    }

    function _isAuctionOngoing(address _nftContractAddress, uint256 _tokenId) internal view returns (bool) {
        uint64 auctionEndTimestamp = nftContractAuctions[_nftContractAddress][_tokenId].auctionEnd;
        //if the auctionEnd is set to 0, the auction is technically on-going, however
        //the minimum bid price (minPrice) has not yet been met.
        return (auctionEndTimestamp == 0 || block.timestamp < auctionEndTimestamp);
    }

    /*
     * Check that a bid is applicable for the purchase of the NFT.
     * The bid needs to be a % higher than the previous bid.
     */
    function _doesBidMeetBidRequirements(address _nftContractAddress, uint256 _tokenId) internal view returns (bool) {
        uint256 highestBid = nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBid;
        if (highestBid > 0) {
            //if the NFT is up for auction, the bid needs to be a % higher than the previous bid
            uint256 bidIncreaseAmount = (highestBid *
                (10000 + nftContractAuctions[_nftContractAddress][_tokenId].bidIncreasePercentage)) / 10000;
            return msg.value >= bidIncreaseAmount;
        } else {
            return msg.value >= nftContractAuctions[_nftContractAddress][_tokenId].minPrice;
        }
    }

    /**********************************/
    /*в•”в•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•—
      в•‘             END              в•‘
      в•‘    AUCTION CHECK FUNCTIONS   в•‘
      в•љв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ќ*/
    /**********************************/

    /*в•”в•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•—
      в•‘ AUCTION CREATION & UPDATING  в•‘
      в•љв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ќ*/

    function createNewNftAuctions(
        address _nftContractAddress,
        uint256[] memory _tokenIds,
        uint32 _bidIncreasePercentage,
        uint32 _auctionBidPeriod,
        uint64 _auctionStart,
        uint64 _auctionEnd,
        uint128 _minPrice,
        address _feeRecipient
    )
        external
        onlyOwner
        notZeroAddress(_feeRecipient)
    {
        require(_auctionEnd >= _auctionStart, "Auction end must be after the start");

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 _tokenId = _tokenIds[i];

            require(
                nftContractAuctions[_nftContractAddress][_tokenId].feeRecipient == address(0),
                "Auction is already created"
            );
            { //Block scoping to prevent "Stack too deep"
                Auction memory auction;
                // creating auction
                auction.bidIncreasePercentage = _bidIncreasePercentage;
                auction.auctionBidPeriod = _auctionBidPeriod;
                auction.auctionStart = _auctionStart;
                auction.auctionEnd = _auctionEnd;
                auction.minPrice = _minPrice;
                auction.feeRecipient = _feeRecipient;

                nftContractAuctions[_nftContractAddress][_tokenId] = auction;
            }
            // Sending the NFT to this contract
            if (IERC721(_nftContractAddress).ownerOf(_tokenId) == msg.sender) {
                IERC721(_nftContractAddress).transferFrom(msg.sender, address(this), _tokenId);
            }
            require( IERC721(_nftContractAddress).ownerOf(_tokenId) == address(this), "NFT transfer failed");

            emit NftAuctionCreated(
                _nftContractAddress,
                _tokenId,
                _minPrice,
                _auctionStart,
                _auctionEnd,
                _auctionBidPeriod,
                _bidIncreasePercentage,
                _feeRecipient
            );
        }
    }

    /*
     * Can be used for auction prolongation.
     * New end must be a moment in future.
     */
    function updateAuctionsEnd(address _nftContractAddress, uint256[] memory _tokenIds, uint64 _auctionEnd)
        external
        onlyOwner
    {
        require(block.timestamp < _auctionEnd, "Auction end must be in the future");
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 _tokenId = _tokenIds[i];
            require(
                nftContractAuctions[_nftContractAddress][_tokenId].feeRecipient != address(0),
                "Auction is not created"
            );
            nftContractAuctions[_nftContractAddress][_tokenId].auctionEnd = _auctionEnd;
            emit AuctionPeriodUpdated(_nftContractAddress, _tokenId, _auctionEnd);
        }
    }
    /**********************************/
    /*в•”в•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•—
      в•‘             END              в•‘
      в•‘ AUCTION CREATION & UPDATING  в•‘
      в•љв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ќ*/
    /**********************************/

    /*в•”в•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•—
      в•‘        BID FUNCTIONS        в•‘
      в•љв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ќ*/

    /*
     * Make bids with ETH.
     * The auction must exist and be ongoing. A bid must meet bid requirements.
     */
    function makeBid(address _nftContractAddress, uint256 _tokenId)
        external
        payable
        auctionOngoing(_nftContractAddress, _tokenId)
        bidAmountMeetsBidRequirements(_nftContractAddress, _tokenId)
    {
        require(msg.sender == tx.origin, "Sender must be a wallet");
        require(
            nftContractAuctions[_nftContractAddress][_tokenId].feeRecipient != address(0),
            "Auction does not exist"
        );

        // Reverse previous bid and update highest bid:
        address prevNftHighestBidder = nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBidder;
        uint256 prevNftHighestBid = nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBid;

        // update highest bid
        nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBid = uint128(msg.value);
        nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBidder = msg.sender;

        if (prevNftHighestBidder != address(0)) { // payout if needed
            _payout(prevNftHighestBidder, prevNftHighestBid);
        }

        emit BidMade(_nftContractAddress, _tokenId, msg.sender, msg.value);

        // Update auction end if needed:
        if (nftContractAuctions[_nftContractAddress][_tokenId].auctionBidPeriod > 0) {
            //the auction end is set to now + the bid period (if it is greater than the previous one)
            uint64 newEnd = nftContractAuctions[_nftContractAddress][_tokenId].auctionBidPeriod +
                uint64(block.timestamp);
            if (newEnd > nftContractAuctions[_nftContractAddress][_tokenId].auctionEnd) {
                nftContractAuctions[_nftContractAddress][_tokenId].auctionEnd = newEnd;
                emit AuctionPeriodUpdated(
                    _nftContractAddress,
                    _tokenId,
                    nftContractAuctions[_nftContractAddress][_tokenId].auctionEnd
                );
            }
        }
    }

    /**********************************/
    /*в•”в•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•—
      в•‘             END              в•‘
      в•‘        BID FUNCTIONS         в•‘
      в•љв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ќ*/
    /**********************************/

    /*в•”в•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•—
      в•‘  TRANSFER NFT & PAY SELLER   в•‘
      в•љв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ќ*/

    /*
     * Transfer NFT to highest bidder and ETH to fee recipient.
     * Deletes auction information.
     */
    function _transferNftAndPayFeeRecipient(address _nftContractAddress, uint256 _tokenId) internal {
        address _feeRecipient = nftContractAuctions[_nftContractAddress][_tokenId].feeRecipient;
        address _nftHighestBidder = nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBidder;
        uint128 _nftHighestBid = nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBid;

        nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBidder = address(0);
        nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBid = 0;

        _payout(_feeRecipient, _nftHighestBid);
        IERC721(_nftContractAddress).transferFrom(address(this), _nftHighestBidder, _tokenId);

        delete nftContractAuctions[_nftContractAddress][_tokenId];
        emit NFTTransferredAndSellerPaid(_nftContractAddress, _tokenId, _nftHighestBid, _nftHighestBidder);
    }

    /*
     * Send ETH to recipient.
     * Increments failedTransferCredits on fail.
     */
    function _payout(address _recipient, uint256 _amount) internal {
        // attempt to send the funds to the recipient
        (bool success, ) = payable(_recipient).call{ value: _amount, gas: 20000 }("");
        // if it failed, update their credit balance so they can pull it later
        if (!success) failedTransferCredits[_recipient] = failedTransferCredits[_recipient] + _amount;
    }

    /**********************************/
    /*в•”в•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•—
      в•‘             END              в•‘
      в•‘  TRANSFER NFT & PAY SELLER   в•‘
      в•љв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ќ*/
    /**********************************/

    /*в•”в•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•—
      в•‘      SETTLE & WITHDRAW       в•‘
      в•љв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ќ*/
    /*
     * Transfer NFT to highest bidder and pay to fee recipient.
     * Only ended auctions with highest bidder can be settled.
     */
    function settleAuctions(address _nftContractAddress, uint256[] memory _tokenIds) external onlyOwner {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 _tokenId = _tokenIds[i];
            address _nftHighestBidder = nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBidder;
            if (!_isAuctionOngoing(_nftContractAddress, _tokenId) && _nftHighestBidder != address(0)) {
                _transferNftAndPayFeeRecipient(_nftContractAddress, _tokenId);
                emit AuctionSettled(_nftContractAddress, _tokenId);
            }
        }
    }

    /*
     * Transfer NFT to owner and return ETH to the highest bidder (if bid was made).
     * If withdrawPeriod passed, then anybody can withdraw an auction.
     */
    function withdrawAuctions(address _nftContractAddress, uint256[] memory _tokenIds) external {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 _tokenId = _tokenIds[i];
            uint64 auctionEndTimestamp = nftContractAuctions[_nftContractAddress][_tokenId].auctionEnd;
            // withdrawPeriod must pass or sender must be an owner
            require(block.timestamp >= (auctionEndTimestamp + withdrawPeriod) || msg.sender == owner(), "Only owner can withdraw before delay");

            address _nftHighestBidder = nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBidder;
            if (_nftHighestBidder != address(0)) {
                uint128 _nftHighestBid = nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBid;
                _payout(_nftHighestBidder, _nftHighestBid);
            }
            delete nftContractAuctions[_nftContractAddress][_tokenId];
            IERC721(_nftContractAddress).transferFrom(address(this), owner(), _tokenId);
            emit AuctionWithdrawn(_nftContractAddress, _tokenId);
        }
    }

    /**********************************/
    /*в•”в•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•—
      в•‘             END              в•‘
      в•‘      SETTLE & WITHDRAW       в•‘
      в•љв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ќ*/
    /**********************************/

    /*в•”в•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•—
      в•‘       UPDATE AUCTION         в•‘
      в•љв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ќ*/

    /*
     * The owner (NFT seller) can opt to end an auction by taking the current highest bid.
     */
    function takeHighestBids(address _nftContractAddress, uint256[] memory _tokenIds) external onlyOwner {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 _tokenId = _tokenIds[i];
            if (nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBid > 0) {
                _transferNftAndPayFeeRecipient(_nftContractAddress, _tokenId);
                emit HighestBidTaken(_nftContractAddress, _tokenId);
            } else {
                IERC721(_nftContractAddress).transferFrom(address(this), msg.sender, _tokenId);
                delete nftContractAuctions[_nftContractAddress][_tokenId];
            }
        }
    }

    /*
     * If the transfer of a bid has failed, allow to reclaim amount later.
     */
    function withdrawAllFailedCreditsOf(address recipient) external {
        uint256 amount = failedTransferCredits[recipient];

        require(amount != 0, "no credits to withdraw");

        failedTransferCredits[recipient] = 0;

        (bool successfulWithdraw, ) = recipient.call{ value: amount, gas: 20000 }("");
        require(successfulWithdraw, "withdraw failed");
    }

    /**********************************/
    /*в•”в•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•—
      в•‘             END              в•‘
      в•‘       UPDATE AUCTION         в•‘
      в•љв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ќ*/
    /**********************************/
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "IERC165.sol";

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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

import "Context.sol";
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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}