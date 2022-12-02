// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

interface IBiplesAddressRegistry {
    function marketplace() external view returns (address);

    function tokenRegistry() external view returns (address);

    function royaltyRegistry() external view returns (address);
}

interface IBiplesRoyaltyRegistry {
    function royaltyInfo(address _collection, uint256 _salePrice)
        external
        view
        returns (address, uint256);
}

interface IBiplesMarketplace {
    function getPrice(address) external view returns (int256);
}

interface IBiplesTokenRegistry {
    function enabled(address) external returns (bool);
}

/**
 * @notice Secondary sale auction contract for NFTs
 */
contract BiplesAuction is
    ERC721Holder,
    ERC1155Holder,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using AddressUpgradeable for address payable;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /// @notice Event emitted only on construction. To be used by indexers
    event BiplesAuctionContractDeployed();

    event PauseToggled(bool isPaused);

    event AuctionCreated(
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 quantity,
        address payToken
    );

    event UpdateAuctionReservePrice(
        address indexed nftAddress,
        uint256 indexed tokenId,
        address payToken,
        uint256 reservePrice
    );

    event UpdateServiceFee(uint256 serviceFee);

    event UpdateFeeRecipient(address payable feeRecipient);

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
        uint256 quantity,
        address indexed winner,
        address payToken,
        int256 unitPrice,
        uint256 winningBid
    );

    event AuctionCancelled(
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 quantity
    );

    /// @notice Parameters of an auction
    struct Auction {
        address owner;
        address payToken;
        uint256 quantity;
        uint256 minBid;
        uint256 reservePrice;
        uint256 startTime;
        uint256 endTime;
        bool resulted;
    }

    /// @notice Information about the sender that placed a bid on an auction
    struct HighestBid {
        address payable bidder;
        uint256 bid;
        uint256 lastBidTime;
    }

    bytes4 private constant INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 private constant INTERFACE_ID_ERC1155 = 0xd9b67a26;

    /// @notice ERC721 Address -> Token ID -> Auction Parameters
    mapping(address => mapping(uint256 => Auction)) public auctions;

    /// @notice ERC721 Address -> Token ID -> highest bidder info (if a bid has been received)
    mapping(address => mapping(uint256 => HighestBid)) public highestBids;

    /// @notice globally and across all auctions, the amount by which a bid has to increase
    uint256 public minBidIncrement;

    /// @notice global bid withdrawal lock time
    uint256 public bidWithdrawalLockTime;

    /// @notice global service fee, assumed to always be to 1 decimal place i.e. 25 = 2.5%
    uint256 public serviceFee;

    /// @notice Used to track and set the maximum allowed auction time (_startTimestamp + maxAuctionLength)
    uint256 public constant maxAuctionLength = 30 days;

    /// @notice where to send service fee funds to
    address payable public feeRecipient;

    /// @notice Address registry
    IBiplesAddressRegistry public addressRegistry;

    /// @notice for switching off auction creations, bids and withdrawals
    bool public isPaused;

    modifier whenNotPaused() {
        require(!isPaused, "contract paused");
        _;
    }

    modifier onlyMarketplace() {
        require(
            addressRegistry.marketplace() == _msgSender(),
            "not marketplace contract"
        );
        _;
    }

    modifier onlyNotContract() {
        require(_msgSender() == tx.origin);
        _;
    }

    /// @notice Contract initializer
    function initialize(address payable _feeRecipient, uint16 _serviceFee)
        public
        initializer
    {
        require(
            _feeRecipient != address(0),
            "BiplesAuction: Invalid service fee Recipient"
        );

        feeRecipient = _feeRecipient;
        serviceFee = _serviceFee;
        bidWithdrawalLockTime = 20 minutes;
        minBidIncrement = 1;
        emit BiplesAuctionContractDeployed();

        __Ownable_init();
        __ReentrancyGuard_init();
    }

    /**
     @notice Creates a new auction for a given item
     @dev Only the owner of item can create an auction and must have approved the contract
     @dev In addition to owning the item, the sender also has to have the MINTER role.
     @dev End time for the auction must be in the future.
     @param _nftAddress ERC 721 Address
     @param _tokenId Token ID of the item being auctioned
     @param _quantity This is the amount of tokens that are going to be created in auction.
     @param _payToken Paying token
     @param _reservePrice Item cannot be sold for less than this or minBidIncrement, whichever is higher
     @param _startTimestamp Unix epoch in seconds for the auction start time
     @param _endTimestamp Unix epoch in seconds for the auction end time.
     */
    function createAuction(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _quantity,
        address _payToken,
        uint256 _reservePrice,
        uint256 _startTimestamp,
        bool minBidReserve,
        uint256 _endTimestamp
    ) external whenNotPaused {
        // Ensure this contract is approved to move the token
        if (IERC165(_nftAddress).supportsInterface(INTERFACE_ID_ERC721)) {
            IERC721 nft = IERC721(_nftAddress);
            require(nft.ownerOf(_tokenId) == _msgSender(), "not owning item");
            require(
                nft.isApprovedForAll(_msgSender(), address(this)),
                "item not approved"
            );
        } else if (
            IERC165(_nftAddress).supportsInterface(INTERFACE_ID_ERC1155)
        ) {
            IERC1155 nft = IERC1155(_nftAddress);
            require(
                nft.balanceOf(_msgSender(), _tokenId) >= _quantity,
                "must hold enough nfts"
            );
            require(
                nft.isApprovedForAll(_msgSender(), address(this)),
                "item not approved"
            );
        } else {
            revert("invalid nft address");
        }

        require(
            (addressRegistry.tokenRegistry() != address(0) &&
                IBiplesTokenRegistry(addressRegistry.tokenRegistry()).enabled(
                    _payToken
                )),
            "invalid pay token"
        );

        // Adds hard limits to cap the maximum auction length
        require(
            _endTimestamp <= (_startTimestamp + maxAuctionLength),
            "Auction time exceeds maximum length"
        );

        _createAuction(
            _nftAddress,
            _tokenId,
            _quantity,
            _payToken,
            _reservePrice,
            _startTimestamp,
            minBidReserve,
            _endTimestamp
        );
    }

    /**
     @notice Places a new bid, out bidding the existing bidder if found and criteria is reached
     @dev Only callable when the auction is open
     @dev Bids from smart contracts are prohibited to prevent griefing with always reverting receiver
     @param _nftAddress ERC 721 Address
     @param _tokenId Token ID of the item being auctioned
     @param _bidPrice Bid price
     */
    function placeBid(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _bidPrice
    ) external nonReentrant whenNotPaused onlyNotContract {
        // Check the auction to see if this is a valid bid
        Auction memory auction = auctions[_nftAddress][_tokenId];

        require(auction.endTime > 0, "No auction exists");

        // Ensure auction is in flight
        require(
            _getNow() >= auction.startTime,
            "bidding before auction started"
        );

        require(_getNow() <= auction.endTime, "bidding outside auction window");

        require(
            auction.payToken != address(0),
            "ERC20 method used for auction"
        );

        _placeBid(_nftAddress, _tokenId, _bidPrice);
    }

    function _placeBid(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _bidPrice
    ) internal whenNotPaused {
        Auction storage auction = auctions[_nftAddress][_tokenId];

        if (auction.minBid == auction.reservePrice) {
            require(
                _bidPrice >= auction.reservePrice,
                "bid cannot be lower than reserve price"
            );
        }

        // Ensure bid adheres to outbid increment and threshold
        HighestBid storage highestBid = highestBids[_nftAddress][_tokenId];
        uint256 minBidRequired = highestBid.bid + minBidIncrement;

        require(_bidPrice >= minBidRequired, "failed to outbid highest bidder");

        IERC20Upgradeable payToken = IERC20Upgradeable(auction.payToken);
        require(
            payToken.transferFrom(_msgSender(), address(this), _bidPrice),
            "insufficient balance or not approved"
        );

        if (highestBid.bidder != address(0)) {
            _refundHighestBidder(
                _nftAddress,
                _tokenId,
                highestBid.bidder,
                highestBid.bid
            );
        }

        // assign top bidder and bid time
        highestBid.bidder = payable(_msgSender());
        highestBid.bid = _bidPrice;
        highestBid.lastBidTime = _getNow();

        emit BidPlaced(_nftAddress, _tokenId, _msgSender(), _bidPrice);
    }

    /**
     @notice Allows the hightest bidder to withdraw the bid (after 12 hours post auction's end) 
     @dev Only callable by the existing top bidder
     @param _nftAddress ERC 721 Address
     @param _tokenId Token ID of the item being auctioned
     */
    function withdrawBid(address _nftAddress, uint256 _tokenId)
        external
        nonReentrant
        whenNotPaused
    {
        HighestBid storage highestBid = highestBids[_nftAddress][_tokenId];

        // Ensure highest bidder is the caller
        require(
            highestBid.bidder == _msgSender(),
            "you are not the highest bidder"
        );

        Auction memory auction = auctions[_nftAddress][_tokenId];

        require(
            _getNow() > auction.endTime + 43200 ||
                (_getNow() > auction.endTime &&
                    highestBid.bid < auction.reservePrice),
            "can withdraw only after 12 hours (after auction ended)"
        );

        uint256 previousBid = highestBid.bid;

        // Clean up the existing top bid
        delete highestBids[_nftAddress][_tokenId];

        // Refund the top bidder
        _refundHighestBidder(
            _nftAddress,
            _tokenId,
            payable(_msgSender()),
            previousBid
        );

        emit BidWithdrawn(_nftAddress, _tokenId, _msgSender(), previousBid);
    }

    //////////
    // Admin /
    //////////

    /**
     @notice Closes a finished auction and rewards the highest bidder
     @dev Only admin or smart contract
     @dev Auction can only be resulted if there has been a bidder and reserve met.
     @dev If there have been no bids, the auction needs to be cancelled instead using `cancelAuction()`
     @param _nftAddress ERC 721 Address
     @param _tokenId Token ID of the item being auctioned
     */
    function resultAuction(address _nftAddress, uint256 _tokenId)
        external
        nonReentrant
    {
        // Check the auction to see if it can be resulted
        Auction storage auction = auctions[_nftAddress][_tokenId];

        // Store auction owner
        address seller = auction.owner;

        // Get info on who the highest bidder is
        HighestBid storage highestBid = highestBids[_nftAddress][_tokenId];
        address _winner = highestBid.bidder;
        uint256 _winningBid = highestBid.bid;

        // Ensure _msgSender() is either auction winner or seller
        require(
            _msgSender() == _winner || _msgSender() == seller,
            "_msgSender() must be auction winner or seller"
        );

        // Ensure this contract is the owner of the item
        if (IERC165(_nftAddress).supportsInterface(INTERFACE_ID_ERC721)) {
            require(
                IERC721(_nftAddress).ownerOf(_tokenId) == address(this),
                "address(this) must be the item owner"
            );
        } else if (
            IERC165(_nftAddress).supportsInterface(INTERFACE_ID_ERC1155)
        ) {
            require(
                IERC1155(_nftAddress).balanceOf(address(this), _tokenId) >=
                    auction.quantity,
                "address(this) must hold enough nfts"
            );
        } else {
            revert("invalid nft address");
        }

        // Check the auction real
        require(auction.endTime > 0, "no auction exists");

        // Check the auction has ended
        require(_getNow() > auction.endTime, "auction not ended");

        // Ensure auction not already resulted
        require(!auction.resulted, "auction already resulted");

        // Ensure there is a winner
        require(_winner != address(0), "no open bids");

        require(
            _winningBid >= auction.reservePrice || _msgSender() == seller,
            "highest bid is below reservePrice"
        );

        _resultAuction(_nftAddress, _tokenId, _winner, _winningBid);
    }

    function _resultAuction(
        address _nftAddress,
        uint256 _tokenId,
        address _winner,
        uint256 _winningBid
    ) internal {
        // Check the auction to see if it can be resulted
        Auction storage auction = auctions[_nftAddress][_tokenId];

        // Result the auction
        auction.resulted = true;

        // Clean up the highest bid
        delete highestBids[_nftAddress][_tokenId];

        uint256 payAmount;

        if (_winningBid > auction.reservePrice) {
            // Work out total above the reserve
            uint256 aboveReservePrice = _winningBid - auction.reservePrice;

            // Work out service fee from above reserve amount
            uint256 serviceFeeAboveReserve = (aboveReservePrice * serviceFee) /
                1e3;

            // Send service fee
            IERC20Upgradeable payToken = IERC20Upgradeable(auction.payToken);
            payToken.safeTransfer(feeRecipient, serviceFeeAboveReserve);

            // Send remaining to designer
            payAmount = _winningBid - serviceFeeAboveReserve;
        } else {
            payAmount = _winningBid;
        }

        IBiplesRoyaltyRegistry royaltyRegistry = IBiplesRoyaltyRegistry(
            addressRegistry.royaltyRegistry()
        );

        address royaltyRecipient;
        uint256 royaltyAmount;

        (royaltyRecipient, royaltyAmount) = royaltyRegistry.royaltyInfo(
            _nftAddress,
            payAmount
        );

        if (royaltyRecipient != address(0) && royaltyAmount != 0) {
            IERC20Upgradeable payToken = IERC20Upgradeable(auction.payToken);
            payToken.safeTransfer(royaltyRecipient, royaltyAmount);

            payAmount = payAmount - royaltyAmount;
        }

        if (payAmount > 0) {
            IERC20Upgradeable payToken = IERC20Upgradeable(auction.payToken);
            payToken.safeTransfer(auction.owner, payAmount);
        }

        // Transfer the token to the winner
        if (IERC165(_nftAddress).supportsInterface(INTERFACE_ID_ERC721)) {
            IERC721(_nftAddress).safeTransferFrom(
                IERC721(_nftAddress).ownerOf(_tokenId),
                _winner,
                _tokenId
            );
        } else {
            IERC1155(_nftAddress).safeTransferFrom(
                address(this),
                _winner,
                _tokenId,
                auction.quantity,
                bytes("")
            );
        }

        int256 price = IBiplesMarketplace(addressRegistry.marketplace())
            .getPrice(auction.payToken);

        emit AuctionResulted(
            _msgSender(),
            _nftAddress,
            _tokenId,
            auction.quantity,
            _winner,
            auction.payToken,
            price,
            _winningBid
        );

        // Remove auction
        delete auctions[_nftAddress][_tokenId];
    }

    /**
     @notice Results an auction that failed to meet the auction.reservePrice
     @dev Only admin or smart contract
     @dev Auction can only be fail-resulted if the auction has expired and the auction.reservePrice has not been met
     @dev If there have been no bids, the auction needs to be cancelled instead using `cancelAuction()`
     @param _nftAddress ERC 721 Address
     @param _tokenId Token ID of the item being auctioned
     */
    function resultFailedAuction(address _nftAddress, uint256 _tokenId)
        external
        nonReentrant
    {
        // Check the auction to see if it can be resulted
        Auction storage auction = auctions[_nftAddress][_tokenId];

        // Store auction owner
        address seller = auction.owner;

        // Ensure this contract is the owner of the item
        if (IERC165(_nftAddress).supportsInterface(INTERFACE_ID_ERC721)) {
            require(
                IERC721(_nftAddress).ownerOf(_tokenId) == address(this),
                "address(this) must be the item owner"
            );
        } else if (
            IERC165(_nftAddress).supportsInterface(INTERFACE_ID_ERC1155)
        ) {
            require(
                IERC1155(_nftAddress).balanceOf(address(this), _tokenId) >=
                    auction.quantity,
                "address(this) must hold enough nfts"
            );
        } else {
            revert("invalid nft address");
        }

        // Check if the auction exists
        require(auction.endTime > 0, "no auction exists");

        // Check if the auction has ended
        require(_getNow() > auction.endTime, "auction not ended");

        // Ensure auction not already resulted
        require(!auction.resulted, "auction already resulted");

        // Get info on who the highest bidder is
        HighestBid storage highestBid = highestBids[_nftAddress][_tokenId];
        address payable topBidder = highestBid.bidder;
        uint256 topBid = highestBid.bid;

        // Ensure _msgSender() is either auction topBidder or seller
        require(
            _msgSender() == topBidder || _msgSender() == seller,
            "_msgSender() must be auction topBidder or seller"
        );

        // Ensure the topBid is less than the auction.reservePrice
        require(topBidder != address(0), "no open bids");
        require(
            topBid < auction.reservePrice,
            "highest bid is >= reservePrice"
        );

        _cancelAuction(_nftAddress, _tokenId, auction.quantity, seller);
    }

    /**
     @notice Cancels and inflight and un-resulted auctions, returning the funds to the top bidder if found
     @dev Only item owner
     @param _nftAddress ERC 721 Address
     @param _tokenId Token ID of the NFT being auctioned
     */
    function cancelAuction(address _nftAddress, uint256 _tokenId)
        external
        nonReentrant
    {
        // Check valid and not resulted
        Auction memory auction = auctions[_nftAddress][_tokenId];

        require(_msgSender() == auction.owner, "sender must be owner");

        // Ensure this contract is the owner of the item
        if (IERC165(_nftAddress).supportsInterface(INTERFACE_ID_ERC721)) {
            require(
                IERC721(_nftAddress).ownerOf(_tokenId) == address(this),
                "address(this) must be the item owner"
            );
        } else if (
            IERC165(_nftAddress).supportsInterface(INTERFACE_ID_ERC1155)
        ) {
            require(
                IERC1155(_nftAddress).balanceOf(address(this), _tokenId) >=
                    auction.quantity,
                "address(this) must hold enough nfts"
            );
        } else {
            revert("invalid nft address");
        }

        // Check auction is real
        require(auction.endTime > 0, "no auction exists");

        // Check auction not already resulted
        require(!auction.resulted, "auction already resulted");

        // Gets info on auction and ensures highest bid is less than the reserve price
        HighestBid storage highestBid = highestBids[_nftAddress][_tokenId];
        require(
            highestBid.bid < auction.reservePrice,
            "Highest bid is currently above reserve price"
        );

        _cancelAuction(_nftAddress, _tokenId, auction.quantity, _msgSender());
    }

    /**
     @notice Toggling the pause flag
     @dev Only admin
     */
    function toggleIsPaused() external onlyOwner {
        isPaused = !isPaused;
        emit PauseToggled(isPaused);
    }

    /**
     @notice Update the amount by which bids have to increase, across all auctions
     @dev Only admin
     @param _minBidIncrement New bid step in WEI
     */
    function updateMinBidIncrement(uint256 _minBidIncrement)
        external
        onlyOwner
    {
        minBidIncrement = _minBidIncrement;
        emit UpdateMinBidIncrement(_minBidIncrement);
    }

    /**
     @notice Update the global bid withdrawal lockout time
     @dev Only admin
     @param _bidWithdrawalLockTime New bid withdrawal lock time
     */
    function updateBidWithdrawalLockTime(uint256 _bidWithdrawalLockTime)
        external
        onlyOwner
    {
        bidWithdrawalLockTime = _bidWithdrawalLockTime;
        emit UpdateBidWithdrawalLockTime(_bidWithdrawalLockTime);
    }

    /**
     @notice Update the current reserve price for an auction
     @dev Only admin
     @dev Auction must exist
     @dev Reserve price can only be decreased and never increased
     @param _nftAddress ERC 721 Address
     @param _tokenId Token ID of the NFT being auctioned
     @param _reservePrice New Ether reserve price (WEI value)
     */
    function updateAuctionReservePrice(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _reservePrice
    ) external {
        Auction storage auction = auctions[_nftAddress][_tokenId];
        // Store the current reservePrice
        uint256 currentReserve = auction.reservePrice;

        // Ensures the sender owns the auction and the item is currently in escrow
        require(_msgSender() == auction.owner, "Sender must be item owner");

        if (IERC165(_nftAddress).supportsInterface(INTERFACE_ID_ERC721)) {
            require(
                IERC721(_nftAddress).ownerOf(_tokenId) == address(this),
                "address(this) must be the item owner"
            );
        } else if (
            IERC165(_nftAddress).supportsInterface(INTERFACE_ID_ERC1155)
        ) {
            require(
                IERC1155(_nftAddress).balanceOf(address(this), _tokenId) >=
                    auction.quantity,
                "address(this) must hold enough nfts"
            );
        } else {
            revert("invalid nft address");
        }
        // Ensures the auction hasn't been resulted
        require(!auction.resulted, "Auction already resulted");

        // Ensures auction exists
        require(auction.endTime > 0, "No auction exists");

        // Ensures the reserve price can only be decreased and never increased
        require(
            _reservePrice < currentReserve,
            "Reserve price can only be decreased"
        );

        auction.reservePrice = _reservePrice;

        if (auction.minBid == currentReserve) {
            auction.minBid = _reservePrice;
        }

        emit UpdateAuctionReservePrice(
            _nftAddress,
            _tokenId,
            auction.payToken,
            _reservePrice
        );
    }

    /**
     @notice Method for updating service fee
     @dev Only admin
     @param _serviceFee uint256 the service fee to set
     */
    function updateServiceFee(uint256 _serviceFee) external onlyOwner {
        serviceFee = _serviceFee;
        emit UpdateServiceFee(_serviceFee);
    }

    /**
     @notice Method for updating service fee address
     @dev Only admin
     @param _feeRecipient payable address the address to sends the funds to
     */
    function updateFeeRecipient(address payable _feeRecipient)
        external
        onlyOwner
    {
        require(_feeRecipient != address(0), "zero address");

        feeRecipient = _feeRecipient;
        emit UpdateFeeRecipient(_feeRecipient);
    }

    /**
     @notice Update BiplesAddressRegistry contract
     @dev Only admin
     */
    function updateAddressRegistry(address _registry) external onlyOwner {
        addressRegistry = IBiplesAddressRegistry(_registry);
    }

    ///////////////
    // Accessors //
    ///////////////

    /**
     @notice Method for getting all info about the auction
     @param _nftAddress ERC 721 Address
     @param _tokenId Token ID of the NFT being auctioned
     */
    function getAuction(address _nftAddress, uint256 _tokenId)
        external
        view
        returns (
            address _owner,
            address _payToken,
            uint256 _reservePrice,
            uint256 _startTime,
            uint256 _endTime,
            bool _resulted,
            uint256 minBid
        )
    {
        Auction storage auction = auctions[_nftAddress][_tokenId];
        return (
            auction.owner,
            auction.payToken,
            auction.reservePrice,
            auction.startTime,
            auction.endTime,
            auction.resulted,
            auction.minBid
        );
    }

    /**
     @notice Method for getting all info about the highest bidder
     @param _tokenId Token ID of the NFT being auctioned
     */
    function getHighestBidder(address _nftAddress, uint256 _tokenId)
        external
        view
        returns (
            address payable _bidder,
            uint256 _bid,
            uint256 _lastBidTime
        )
    {
        HighestBid storage highestBid = highestBids[_nftAddress][_tokenId];
        return (highestBid.bidder, highestBid.bid, highestBid.lastBidTime);
    }

    /////////////////////////
    // Internal and Private /
    /////////////////////////

    function _getNow() internal view virtual returns (uint256) {
        return block.timestamp;
    }

    /**
     @notice Private method doing the heavy lifting of creating an auction
     @param _nftAddress ERC 721 Address
     @param _tokenId Token ID of the NFT being auctioned
     @param _quantity This is the amount of tokens that are going to be created in auction
     @param _payToken Paying token
     @param _reservePrice Item cannot be sold for less than this or minBidIncrement, whichever is higher
     @param _startTimestamp Unix epoch in seconds for the auction start time
     @param _endTimestamp Unix epoch in seconds for the auction end time.
     */
    function _createAuction(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _quantity,
        address _payToken,
        uint256 _reservePrice,
        uint256 _startTimestamp,
        bool minBidReserve,
        uint256 _endTimestamp
    ) private {
        // Ensure a token cannot be re-listed if previously successfully sold
        require(
            auctions[_nftAddress][_tokenId].endTime == 0,
            "auction already started"
        );

        // Check end time not before start time and that end is in the future
        require(
            _endTimestamp >= _startTimestamp + 300,
            "end time must be greater than start (by 5 minutes)"
        );

        require(_startTimestamp > _getNow(), "invalid start time");
        require(
            _quantity > 0,
            "createAuction: The amount of tokens to sell, needs to be greater than 0"
        );

        uint256 minimumBid = 0;

        if (minBidReserve) {
            minimumBid = _reservePrice;
        }

        // Transfer the NFT from the Tradable contract into auction contract to be held in escrow
        if (IERC165(_nftAddress).supportsInterface(INTERFACE_ID_ERC721)) {
            IERC721(_nftAddress).safeTransferFrom(
                IERC721(_nftAddress).ownerOf(_tokenId),
                address(this),
                _tokenId
            );
        } else {
            IERC1155(_nftAddress).safeTransferFrom(
                _msgSender(),
                address(this),
                _tokenId,
                _quantity,
                bytes("")
            );
        }
        // Setup the auction
        auctions[_nftAddress][_tokenId] = Auction({
            owner: _msgSender(),
            payToken: _payToken,
            quantity: _quantity,
            minBid: minimumBid,
            reservePrice: _reservePrice,
            startTime: _startTimestamp,
            endTime: _endTimestamp,
            resulted: false
        });

        emit AuctionCreated(_nftAddress, _tokenId, _quantity, _payToken);
    }

    function _cancelAuction(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _quantity,
        address owner
    ) private {
        // refund existing top bidder if found
        HighestBid memory highestBid = highestBids[_nftAddress][_tokenId];
        if (highestBid.bidder != address(0)) {
            _refundHighestBidder(
                _nftAddress,
                _tokenId,
                highestBid.bidder,
                highestBid.bid
            );

            // Clear up highest bid
            delete highestBids[_nftAddress][_tokenId];
        }

        // Remove auction and top bidder
        delete auctions[_nftAddress][_tokenId];

        // Transfer the NFT ownership back to _msgSender()
        if (IERC165(_nftAddress).supportsInterface(INTERFACE_ID_ERC721)) {
            IERC721(_nftAddress).safeTransferFrom(
                IERC721(_nftAddress).ownerOf(_tokenId),
                owner,
                _tokenId
            );
        } else {
            IERC1155(_nftAddress).safeTransferFrom(
                address(this),
                owner,
                _tokenId,
                _quantity,
                bytes("")
            );
        }

        emit AuctionCancelled(_nftAddress, _tokenId, _quantity);
    }

    /**
     @notice Used for sending back escrowed funds from a previous bid
     @param _currentHighestBidder Address of the last highest bidder
     @param _currentHighestBid Ether or Mona amount in WEI that the bidder sent when placing their bid
     */
    function _refundHighestBidder(
        address _nftAddress,
        uint256 _tokenId,
        address payable _currentHighestBidder,
        uint256 _currentHighestBid
    ) private {
        Auction memory auction = auctions[_nftAddress][_tokenId];

        IERC20Upgradeable payToken = IERC20Upgradeable(auction.payToken);
        payToken.safeTransfer(_currentHighestBidder, _currentHighestBid);

        emit BidRefunded(
            _nftAddress,
            _tokenId,
            _currentHighestBidder,
            _currentHighestBid
        );
    }

    /**
     * @notice Reclaims ERC20 Compatible tokens for entire balance
     * @dev Only access controls admin
     * @param _tokenContract The address of the token contract
     */
    function reclaimERC20(address _tokenContract) external onlyOwner {
        require(_tokenContract != address(0), "Invalid address");
        IERC20Upgradeable token = IERC20Upgradeable(_tokenContract);
        uint256 balance = token.balanceOf(address(this));
        token.safeTransfer(_msgSender(), balance);
    }
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/draft-IERC20PermitUpgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20PermitUpgradeable token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20PermitUpgradeable {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}