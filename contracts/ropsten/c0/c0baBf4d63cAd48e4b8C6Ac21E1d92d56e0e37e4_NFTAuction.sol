// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;
import "./SafeMath.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IERC721.sol";
import "./OwnableUpgradeable.sol";
import "./ReentrancyGuard.sol";
interface IAddressRegistry {
    function artion() external view returns (address);
    function marketplace() external view returns (address);
    function bundleMarketplace() external view returns (address);
    function tokenRegistry() external view returns (address);
}
interface IMarketplace {
    function minters(address, uint256) external view returns (address);
    function royalties(address, uint256) external view returns (uint16);
    function collectionRoyalties(address)external view returns (uint16,address,address );
    function getPrice(address) external view returns (int256);
}
interface IBundleMarketplace {
    function validateItemSold(
        address,
        uint256,
        uint256
    ) external;
}
interface ITokenRegistry {
    function enabled(address) external returns (bool);
}
contract NFTAuction is OwnableUpgradeable, ReentrancyGuard {
    using SafeMath for uint256;
    using AddressUpgradeable for address payable;
    using SafeERC20 for IERC20;
    // Event emitted only on construction. To be used by indexers
    event AuctionContractDeployed();
    event PauseToggled(bool isPaused);
    event AuctionCreated(address indexed nftAddress,uint256 indexed tokenId,address payToken);
    event UpdateAuctionEndTime(address indexed nftAddress,uint256 indexed tokenId,uint256 endTime);
    event UpdateAuctionStartTime(address indexed nftAddress,uint256 indexed tokenId,uint256 startTime);
    event UpdateAuctionReservePrice(address indexed nftAddress,uint256 indexed tokenId,address payToken,uint256 reservePrice);
    event UpdatePlatformFee(uint256 platformFee);
    event UpdatePlatformFeeRecipient(address payable platformFeeRecipient);
    event UpdateMinBidIncrement(uint256 minBidIncrement);
    event UpdateBidWithdrawalLockTime(uint256 bidWithdrawalLockTime);
    event BidPlaced(
        address indexed nftAddress,
        uint256 indexed tokenId,
        address indexed bidder,
        uint256 bid
    );

    event BidWithdrawn(
        address indexed nftAddress,
        uint256 indexed tokenId,
        address indexed bidder,
        uint256 bid
    );

    event BidRefunded(
        address indexed nftAddress,
        uint256 indexed tokenId,
        address indexed bidder,
        uint256 bid
    );

    event AuctionResulted(
        address oldOwner,
        address indexed nftAddress,
        uint256 indexed tokenId,
        address indexed winner,
        address payToken,
        int256 unitPrice,
        uint256 winningBid
    );

    event AuctionCancelled(address indexed nftAddress, uint256 indexed tokenId);

    /// @notice Parameters of an auction
    struct Auction {
        address owner;
        address payToken;
        uint256 minBid;
        uint256 reservePrice;
        uint256 startTime;
        uint256 endTime;
        bool resulted;
    }

    /// @notice Information about the sender that placed a bit on an auction
    struct HighestBid {
        address payable bidder;
        uint256 bid;
        uint256 lastBidTime;
    }

    /// @notice ERC721 Address -> Token ID -> Auction Parameters
    mapping(address => mapping(uint256 => Auction)) public auctions;

    /// @notice ERC721 Address -> Token ID -> highest bidder info (if a bid has been received)
    mapping(address => mapping(uint256 => HighestBid)) public highestBids;

    /// @notice globally and across all auctions, the amount by which a bid has to increase
    uint256 public minBidIncrement = 1;

    /// @notice global bid withdrawal lock time
    uint256 public bidWithdrawalLockTime = 20 minutes;

    /// @notice global platform fee, assumed to always be to 1 decimal place i.e. 25 = 2.5%
    uint256 public platformFee = 25;

    /// @notice where to send platform fee funds to
    address payable public platformFeeRecipient;

    /// @notice Address registry
    IAddressRegistry public addressRegistry;

    /// @notice for switching off auction creations, bids and withdrawals
    bool public isPaused;

    modifier whenNotPaused() {
        require(!isPaused, "contract paused");
        _;
    }

    modifier onlyMarketplace() {
        require(
            addressRegistry.marketplace() == _msgSender() ||
                addressRegistry.bundleMarketplace() == _msgSender(),
            "not marketplace contract"
        );
        _;
    }
    /// @notice Contract initializer
    function initialize(address payable _platformFeeRecipient)
        public
        initializer
    {
        require(
            _platformFeeRecipient != address(0),
            "NFTAuction: Invalid Platform Fee Recipient"
        );
        platformFeeRecipient = _platformFeeRecipient;
        emit AuctionContractDeployed();
        __Ownable_init();
    }
    function createAuction(address _nftAddress,uint256 _tokenId,address _payToken,uint256 _reservePrice,uint256 _startTimestamp,bool minBidReserve,uint256 _endTimestamp) external whenNotPaused {
        // Ensure this contract is approved to move the token
        require(
            IERC721(_nftAddress).ownerOf(_tokenId) == _msgSender() &&
                IERC721(_nftAddress).isApprovedForAll(_msgSender(),address(this)),"not owner and or contract not approved");
        require(
            _payToken == address(0) || (addressRegistry.tokenRegistry() != address(0) &&
                    ITokenRegistry(addressRegistry.tokenRegistry()).enabled(_payToken)),"invalid pay token");
        _createAuction(_nftAddress,_tokenId, _payToken,_reservePrice, _startTimestamp,minBidReserve, _endTimestamp);
    }
    function placeBid(address _nftAddress,uint256 _tokenId,uint256 _bidAmount) external nonReentrant whenNotPaused {
        require(_msgSender().isContract() == false, "no contracts permitted");
        // Check the auction to see if this is a valid bid
        Auction memory auction = auctions[_nftAddress][_tokenId];
        // Ensure auction is in flight
        require(_getNow() >= auction.startTime && _getNow() <= auction.endTime, "bidding outside of the auction window");
        require(auction.payToken != address(0),"ERC20 method used for FTM auction");
        _placeBid(_nftAddress, _tokenId, _bidAmount);
    }
    function _placeBid(address _nftAddress,uint256 _tokenId,uint256 _bidAmount) internal whenNotPaused {
        Auction storage auction = auctions[_nftAddress][_tokenId];
        if (auction.minBid == auction.reservePrice) {
            require(_bidAmount >= auction.reservePrice,"bid cannot be lower than reserve price");
        }
        // Ensure bid adheres to outbid increment and threshold
        HighestBid storage highestBid = highestBids[_nftAddress][_tokenId];
        uint256 minBidRequired = highestBid.bid.add(minBidIncrement);
        require(_bidAmount >= minBidRequired, "failed to outbid highest bidder");
        if (auction.payToken != address(0)) {
            IERC20 payToken = IERC20(auction.payToken);
            require(payToken.transferFrom(_msgSender(), address(this), _bidAmount),"insufficient balance or not approved");
        }
        // Refund existing top bidder if found
        if (highestBid.bidder != address(0)) {
            _refundHighestBidder(_nftAddress,_tokenId,highestBid.bidder,highestBid.bid);
        }
        // assign top bidder and bid time
        highestBid.bidder = _msgSender();
        highestBid.bid = _bidAmount;
        highestBid.lastBidTime = _getNow();
        emit BidPlaced(_nftAddress, _tokenId, _msgSender(), _bidAmount);
    }
    function withdrawBid(address _nftAddress, uint256 _tokenId)external nonReentrant whenNotPaused{
        HighestBid storage highestBid = highestBids[_nftAddress][_tokenId];
        // Ensure highest bidder is the caller
        require(highestBid.bidder == _msgSender(),"you are not the highest bidder");
        uint256 _endTime = auctions[_nftAddress][_tokenId].endTime;
        require( _getNow() > _endTime && (_getNow() - _endTime >= 43200),"can withdraw only after 12 hours (after auction ended)");
        uint256 previousBid = highestBid.bid;
        // Clean up the existing top bid
        delete highestBids[_nftAddress][_tokenId];
        // Refund the top bidder
        _refundHighestBidder(_nftAddress, _tokenId, _msgSender(), previousBid);
        emit BidWithdrawn(_nftAddress, _tokenId, _msgSender(), previousBid);
    }
    // Admin 
    function resultAuction(address _nftAddress, uint256 _tokenId) external nonReentrant{
        // Check the auction to see if it can be resulted
        Auction storage auction = auctions[_nftAddress][_tokenId];
        require(
            IERC721(_nftAddress).ownerOf(_tokenId) == _msgSender() &&
                _msgSender() == auction.owner,"sender must be item owner");
        // Check the auction real
        require(auction.endTime > 0, "no auction exists");
        // Check the auction has ended
        require(_getNow() > auction.endTime, "auction not ended");
        // Ensure auction not already resulted
        require(!auction.resulted, "auction already resulted");
        // Get info on who the highest bidder is
        HighestBid storage highestBid = highestBids[_nftAddress][_tokenId];
        address winner = highestBid.bidder;
        uint256 winningBid = highestBid.bid;
        // Ensure there is a winner
        require(winner != address(0), "no open bids");
        require(winningBid >= auction.reservePrice,"highest bid is below reservePrice");
        // Ensure this contract is approved to move the token
        require(IERC721(_nftAddress).isApprovedForAll(_msgSender(), address(this)),"auction not approved");
        // Result the auction
        auction.resulted = true;
        // Clean up the highest bid
        delete highestBids[_nftAddress][_tokenId];
        uint256 payAmount;
        if (winningBid > auction.reservePrice) {
            // Work out total above the reserve
            uint256 aboveReservePrice = winningBid.sub(auction.reservePrice);
            // Work out platform fee from above reserve amount
            uint256 platformFeeAboveReserve = aboveReservePrice.mul(platformFee).div(1000);
            if (auction.payToken == address(0)) {
                // Send platform fee
                (bool platformTransferSuccess, ) = platformFeeRecipient.call{
                    value: platformFeeAboveReserve
                }("");
                require(platformTransferSuccess, "failed to send platform fee");
            } else {
                IERC20 payToken = IERC20(auction.payToken);
                require(payToken.transfer(platformFeeRecipient,platformFeeAboveReserve),"failed to send platform fee");
            }
            // Send remaining to designer
            payAmount = winningBid.sub(platformFeeAboveReserve);
        } else {
            payAmount = winningBid;
        }
        IMarketplace marketplace = IMarketplace(addressRegistry.marketplace());
        address minter = marketplace.minters(_nftAddress, _tokenId);
        uint16 royalty = marketplace.royalties(_nftAddress, _tokenId);
        if (minter != address(0) && royalty != 0) {
            uint256 royaltyFee = payAmount.mul(royalty).div(10000);
            if (auction.payToken == address(0)) {
                (bool royaltyTransferSuccess, ) = payable(minter).call{
                    value: royaltyFee
                }("");
                require(royaltyTransferSuccess,"failed to send the owner their royalties");
            } else {
                IERC20 payToken = IERC20(auction.payToken);
                require(payToken.transfer(minter, royaltyFee),"failed to send the owner their royalties");
            }
            payAmount = payAmount.sub(royaltyFee);
        } else {
            (royalty, , minter) = marketplace.collectionRoyalties(_nftAddress);
            if (minter != address(0) && royalty != 0) {
                uint256 royaltyFee = payAmount.mul(royalty).div(10000);
                if (auction.payToken == address(0)) {
                    (bool royaltyTransferSuccess, ) = payable(minter).call{
                        value: royaltyFee
                    }("");
                    require(royaltyTransferSuccess,"failed to send the royalties");
                } else {
                    IERC20 payToken = IERC20(auction.payToken);
                    require(payToken.transfer(minter, royaltyFee),"failed to send the royalties");
                }
                payAmount = payAmount.sub(royaltyFee);
            }
        }
        if (payAmount > 0) {
            if (auction.payToken == address(0)) {
                (bool ownerTransferSuccess, ) = auction.owner.call{
                    value: payAmount
                }("");
                require(ownerTransferSuccess,"failed to send the owner the auction balance");
            } else {
                IERC20 payToken = IERC20(auction.payToken);
                require(payToken.transfer(auction.owner, payAmount),"failed to send the owner the auction balance");
            }
        }
        // Transfer the token to the winner
        IERC721(_nftAddress).safeTransferFrom(IERC721(_nftAddress).ownerOf(_tokenId),winner,_tokenId);
        IBundleMarketplace(addressRegistry.bundleMarketplace()).validateItemSold(_nftAddress, _tokenId, uint256(1));
        emit AuctionResulted(_msgSender(),_nftAddress,_tokenId, winner,auction.payToken,IMarketplace(addressRegistry.marketplace()).getPrice(auction.payToken),winningBid);
        // Remove auction
        delete auctions[_nftAddress][_tokenId];
    }
    function cancelAuction(address _nftAddress, uint256 _tokenId) external nonReentrant{
        // Check valid and not resulted
        Auction memory auction = auctions[_nftAddress][_tokenId];
        require(IERC721(_nftAddress).ownerOf(_tokenId) == _msgSender() && _msgSender() == auction.owner,"sender must be owner");
        // Check auction is real
        require(auction.endTime > 0, "no auction exists");
        // Check auction not already resulted
        require(!auction.resulted, "auction already resulted");
        _cancelAuction(_nftAddress, _tokenId);
    }
    function toggleIsPaused() external onlyOwner {
        isPaused = !isPaused;
        emit PauseToggled(isPaused);
    }
    function updateMinBidIncrement(uint256 _minBidIncrement)external onlyOwner{
        minBidIncrement = _minBidIncrement;
        emit UpdateMinBidIncrement(_minBidIncrement);
    }
    function updateBidWithdrawalLockTime(uint256 _bidWithdrawalLockTime)external onlyOwner{
        bidWithdrawalLockTime = _bidWithdrawalLockTime;
        emit UpdateBidWithdrawalLockTime(_bidWithdrawalLockTime);
    }
    function updateAuctionReservePrice(address _nftAddress,uint256 _tokenId,uint256 _reservePrice) external {
        Auction storage auction = auctions[_nftAddress][_tokenId];
        require(_msgSender() == auction.owner, "sender must be item owner");
        // Ensure auction not already resulted
        require(!auction.resulted, "auction already resulted");
        require(auction.endTime > 0, "no auction exists");
        auction.reservePrice = _reservePrice;
        emit UpdateAuctionReservePrice(_nftAddress,_tokenId,auction.payToken,_reservePrice);
    }
    function updateAuctionStartTime(address _nftAddress,uint256 _tokenId,uint256 _startTime) external {
        Auction storage auction = auctions[_nftAddress][_tokenId];
        require(_msgSender() == auction.owner, "sender must be owner");
        require(_startTime > 0, "invalid start time");
        require(auction.startTime + 60 > _getNow(), "auction already started");
        require(_startTime + 300 < auction.endTime,"start time should be less than end time (by 5 minutes)");
        // Ensure auction not already resulted
        require(!auction.resulted, "auction already resulted");
        require(auction.endTime > 0, "no auction exists");
        auction.startTime = _startTime;
        emit UpdateAuctionStartTime(_nftAddress, _tokenId, _startTime);
    }
    function updateAuctionEndTime(address _nftAddress,uint256 _tokenId,uint256 _endTimestamp) external {
        Auction storage auction = auctions[_nftAddress][_tokenId];
        require(_msgSender() == auction.owner, "sender must be owner");
        // Check the auction has not ended
        require(_getNow() < auction.endTime, "auction already ended");
        require(auction.endTime > 0, "no auction exists");
        require(auction.startTime < _endTimestamp,"end time must be greater than start");
        require(_endTimestamp > _getNow() + 300,"auction should end after 5 minutes");
        auction.endTime = _endTimestamp;
        emit UpdateAuctionEndTime(_nftAddress, _tokenId, _endTimestamp);
    }
    function updatePlatformFee(uint256 _platformFee) external onlyOwner {
        platformFee = _platformFee;
        emit UpdatePlatformFee(_platformFee);
    }
    function updatePlatformFeeRecipient(address payable _platformFeeRecipient)external onlyOwner{
        require(_platformFeeRecipient != address(0), "zero address");
        platformFeeRecipient = _platformFeeRecipient;
        emit UpdatePlatformFeeRecipient(_platformFeeRecipient);
    }
    function updateAddressRegistry(address _registry) external onlyOwner {
        addressRegistry = IAddressRegistry(_registry);
    }
    // Accessors 
    function getAuction(address _nftAddress, uint256 _tokenId) external view 
        returns (address _owner,address _payToken,uint256 _reservePrice,uint256 _startTime,uint256 _endTime,bool _resulted,uint256 minBid){
        Auction storage auction = auctions[_nftAddress][_tokenId];
        return (auction.owner,auction.payToken,auction.reservePrice,auction.startTime,auction.endTime,auction.resulted,auction.minBid);
    }
    function getHighestBidder(address _nftAddress, uint256 _tokenId)external view returns (address payable _bidder,uint256 _bid,uint256 _lastBidTime){
        HighestBid storage highestBid = highestBids[_nftAddress][_tokenId];
        return (highestBid.bidder, highestBid.bid, highestBid.lastBidTime);
    }
    // Internal and Private 
    function _getNow() internal view virtual returns (uint256) {
        return block.timestamp;
    }
    function _createAuction(address _nftAddress,uint256 _tokenId,address _payToken,uint256 _reservePrice, uint256 _startTimestamp,bool minBidReserve,uint256 _endTimestamp) private {
        // Ensure a token cannot be re-listed if previously successfully sold
        require(auctions[_nftAddress][_tokenId].endTime == 0,"auction already started");
        // Check end time not before start time and that end is in the future
        require(_endTimestamp >= _startTimestamp + 300,"end time must be greater than start (by 5 minutes)");
        require(_startTimestamp > _getNow(), "invalid start time");
        uint256 minimumBid = 0;
        if (minBidReserve) {
            minimumBid = _reservePrice;
        }
        // Setup the auction
        auctions[_nftAddress][_tokenId] = Auction({
            owner: _msgSender(),
            payToken: _payToken,
            minBid: minimumBid,
            reservePrice: _reservePrice,
            startTime: _startTimestamp,
            endTime: _endTimestamp,
            resulted: false
        });
        emit AuctionCreated(_nftAddress, _tokenId, _payToken);
    }
    function _cancelAuction(address _nftAddress, uint256 _tokenId) private {
        // refund existing top bidder if found
        HighestBid storage highestBid = highestBids[_nftAddress][_tokenId];
        if (highestBid.bidder != address(0)) {
            _refundHighestBidder(_nftAddress,_tokenId,highestBid.bidder,highestBid.bid);
            // Clear up highest bid
            delete highestBids[_nftAddress][_tokenId];
        }
        // Remove auction and top bidder
        delete auctions[_nftAddress][_tokenId];
        emit AuctionCancelled(_nftAddress, _tokenId);
    }
    function _refundHighestBidder(address _nftAddress,uint256 _tokenId,address payable _currentHighestBidder,uint256 _currentHighestBid) private {
        Auction memory auction = auctions[_nftAddress][_tokenId];
        if (auction.payToken == address(0)) {
            // refund previous best (if bid exists)
            (bool successRefund, ) = _currentHighestBidder.call{
                value: _currentHighestBid
            }("");
            require(successRefund, "failed to refund previous bidder");
        } else {
            IERC20 payToken = IERC20(auction.payToken);
            require(payToken.transfer(_currentHighestBidder, _currentHighestBid),"failed to refund previous bidder");
        }
        emit BidRefunded(_nftAddress,_tokenId,_currentHighestBidder,_currentHighestBid);
    }
    function reclaimERC20(address _tokenContract) external onlyOwner {
        require(_tokenContract != address(0), "Invalid address");
        IERC20 token = IERC20(_tokenContract);
        uint256 balance = token.balanceOf(address(this));
        require(token.transfer(_msgSender(), balance), "Transfer failed");
    }
}