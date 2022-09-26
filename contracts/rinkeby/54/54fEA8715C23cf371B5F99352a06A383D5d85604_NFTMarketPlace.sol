// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";

/// @title NFTMarketPlace
///
/// @dev The purpose of this contract is to provide a platform where NFTs of whitelisted 
///      contracts can be listed for sale and NFT auctions.
contract NFTMarketPlace is 
    Initializable, 
    PausableUpgradeable, 
    ReentrancyGuardUpgradeable,
    AccessControlUpgradeable, 
    UUPSUpgradeable, 
    IERC721ReceiverUpgradeable 
{
    using CountersUpgradeable for CountersUpgradeable.Counter;

    struct MarketItem {
        bool isVegasONE;
        bool soldOut;
        address nftContract;
        address seller;
        uint256 itemId;
        uint256 tokenId;
        uint256 price;
    }

    struct AuctionItem {
        bool isVegasONE;
        bool soldOut;
        address nftContract;
        address highestBidder;
        address seller;
        uint auctionStartTime;
        uint256 itemId;
        uint256 tokenId;
        uint256 highestPrice;
    }

    /**
     * Event
     */

    event CreateMarketItem(
        bool isVegasONE,
        address nftContract,
        address indexed seller,
        uint256 indexed itemId,
        uint256 tokenId,
        uint256 price
    );

    event RemoveMarketItem(
        bool isVegasONE,
        address nftContract,
        address indexed seller,
        uint256 indexed itemId,
        uint256 tokenId,
        uint256 price
    );

    event Buy(
        bool isVegasONE,
        address nftContract,
        address seller,
        address indexed buyer,
        uint256 indexed itemId,
        uint256 tokenId,
        uint256 price,
        uint256 fee
    );

    event Withdraw(
        bool isVegasONE,
        address indexed account,
        address indexed to,
        uint256 amount
    );

    event WithdrawMP(
        bool isVegasONE,
        address indexed account,
        address indexed to,
        uint256 amount
    );

    event CreateAuctionItem(
        bool isVegasONE,
        address nftContract,
        address indexed seller,
        uint auctionStartTime,
        uint256 indexed itemId,
        uint256 tokenId,
        uint256 price
    );

    event RemoveAuctionItem(
        bool isVegasONE,
        address nftContract,
        address indexed seller,
        uint auctionStartTime,
        uint256 indexed itemId,
        uint256 tokenId,
        uint256 price
    );

    event Bid(
        bool isVegasONE,
        address nftContract,
        address seller,
        address indexed buyer,
        uint256 indexed itemId,
        uint256 tokenId,
        uint256 price
    );

    event RevertBid(
        address indexed account,
        address indexed to,
        uint256 indexed itemId,
        uint256 amount
    );

    event AuctionEnd(
        bool isVegasONE,
        address nftContract,
        address seller,
        address indexed buyer,
        uint auctionEndTime,
        uint256 indexed itemId,
        uint256 tokenId,
        uint256 price,
        uint256 fee
    );

    event SetFeePercent(
        address indexed account,
        uint256 feePercent
    );

    event SetWhitelist(
        address indexed account,
        address nftContract
    );

    /**
     * Variables 
     */

    /// @dev The identifier of the role which maintains other settings.
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    uint256 constant thousand = 1000;
    address[] private _whiteliste;
    uint private _biddingTime;
    IERC20Upgradeable private _paymentToken;
    uint256 private _feePercent;
    uint256 private _totalFeeEth;
    uint256 private _totalFeeVegasONE;

    CountersUpgradeable.Counter private _itemIdCounter;
    CountersUpgradeable.Counter private _auctionItemsIdCounter;

    MarketItem[] private _items;
    AuctionItem[] private _auctionItems;

    mapping(uint256 => uint256) private _itemsIndex;
    mapping(uint256 => bool) private _itemsExist;
    mapping(address => uint256[]) private _ownedItems;
    mapping(uint256 => uint256) private _ownedItemsIndex;
    mapping(address => uint256) private _ownedEth;
    mapping(address => uint256) private _ownedVegasONE;

    mapping(address => bool) private _whitelistExist;

    mapping(uint256 => uint256) private _auctionItemsIndex;
    mapping(uint256 => bool) private _auctionItemsExist;
    mapping(address => uint256[]) private _ownedAuctionItems;
    mapping(uint256 => uint256) private _ownedAuctionItemsIndex;
    mapping(uint256 => address) private _auctionItemsHighestBidder;
    mapping(address => mapping(uint256 => uint256)) private _ownedBidEth;
    mapping(address => mapping(uint256 => uint256)) private _ownedBidVegasONE;

    /**
     * Errors
     */

    error OnlyAdminCanUse();
    error MarketItemNotFound();
    error AuctionItemNotFound();
    error AddressNotInWhitelist();
    error SelfPurchase();
    error ZeroAddress();
    error BidderNotFound();
    error HighestBidderCanNotRevertFunds();
    error AmountMustBeGreaterThanZero();
    error InvaildPaymentToken();
    error AddressExistsInWhitelist();
    error FeePercentMustBeA1To1000Number();
    error SoldOut();
    error OnlyAcceptEthForPayment();
    error OnlyAcceptVegasONEForPayment();
    error OnlyRemovedBySellerOrAdmin();
    error CanNotRemovedWhenHighestBidderExist();
    error NotEnoughFunds();
    error HighestBidderIsYou();
    error NotExceedingHighestPrice();
    error NoFundsCanBeRevert();
    error AuctionIsOver();
    error AuctionIsNotOver();
    error NoOneBid();
    error OnlyHighestBidderOrSellerCanEnd();
    error OutOfBounds();

    /**
     * Initialize
     */

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address newPaymentToken,
        uint256 newFeePercent,
        uint newBiddingTime
    ) public initializer {
        __Pausable_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();

        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(ADMIN_ROLE, _msgSender());
        _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);

        if (newPaymentToken == address(0)) {
            revert InvaildPaymentToken();
        }

        if (newFeePercent <= 0 || newFeePercent > thousand) {
            revert FeePercentMustBeA1To1000Number();
        }

        _paymentToken = IERC20Upgradeable(newPaymentToken);

        _feePercent = newFeePercent;

        _biddingTime = newBiddingTime * 1 days;
    }

    /**
     * Modifer
     */

    /// @dev A modifier which asserts the caller has the admin role.
    modifier checkAdmin() {
        if (!hasRole(ADMIN_ROLE, _msgSender())) {
            revert OnlyAdminCanUse();
        }
        _;
	}

    /// @dev A modifier which asserts that the market item Id exists.
    modifier checkItemExist(uint256 itemId) {
        if (!_isItemExist(itemId)) {
            revert MarketItemNotFound();
        }
        _;
    }

    /// @dev A modifier which asserts that the auction item Id exists.
    modifier checkAuctionItemExist(uint256 itemId) {
        if (!_isAuctionItemExist(itemId)) {
            revert AuctionItemNotFound();
        }
        _;
    }

    /// @dev A modifier which asserts that the contract address exists in the whitelist.
    modifier checkWhitelist(address nftContract) {
        if (!_isWhitelist(nftContract)) {
            revert AddressNotInWhitelist();
        }
        _;
    }

    /// @dev A modifier which asserts that the seller for the market item is the caller.
    modifier checkSeller(uint256 itemId) {
        MarketItem memory item = _getItem(itemId);
        if (item.seller == _msgSender()) {
            revert SelfPurchase();
        }
        _;
    }

    /// @dev A modifier which asserts that the perPage & pageId greater than zero.
    modifier checkPage(uint256 perPage, uint256 pageId) {
        if (perPage <= 0 || pageId <= 0) {
            revert OutOfBounds();
        }
        _;
    }

    /// @dev A modifier which asserts that the seller for the auction item is the caller.
    modifier checkAuctionSeller(uint256 itemId) {
        AuctionItem memory item = _getAuctionItem(itemId);
        if (item.seller == _msgSender()) {
            revert SelfPurchase();
        }
        _;
    }

    /// @dev A modifier which asserts that address is not a zero address.
    modifier checkAdress(address account) {
        if (account == address(0)) {
            revert ZeroAddress();
        }
        _;
    }

    /// @dev A modifier which asserts that a bidder exists or that the highest bidder for
    ///      the auction item is the caller.
    modifier checkAuctionBidder(uint256 itemId) {
        if (_auctionItemsHighestBidder[itemId] == address(0)) {
            revert BidderNotFound();
        }
        if (_msgSender() == _auctionItemsHighestBidder[itemId]) {
            revert HighestBidderCanNotRevertFunds();
        }
        _;
    }

    /// @dev A modifier which asserts that the amount greater than zero.
    modifier checkAmount(uint256 amount) {
        if (amount <= 0) {
            revert AmountMustBeGreaterThanZero();
        }
        _;
    }

    /**
     * External/Public Functions for Admin
     */


    /// @dev Set the transaction fee percentage.
    /// @notice fee = price * feePercent / thousand.
    ///
    /// This function reverts if the caller does not have the admin role or if `newFeePercent`
    /// is less than or equal than zero or greater than 999.
    ///
    /// @param newFeePercent    the percentage of transaction fee.
    function setFeePercent(uint256 newFeePercent) external checkAdmin {
        if (newFeePercent <= 0 || newFeePercent > thousand) {
            revert FeePercentMustBeA1To1000Number();
        }
        _feePercent = newFeePercent;
        
        emit SetFeePercent(_msgSender(), _feePercent);
    }

    /// @dev Set the whitelist.
    ///
    /// This function reverts if the caller does not have the admin role or if `nftContract`
    /// exists in the whitelist.
    ///
    /// @param nftContract  the address of the nft contract.
    function setWhitelist(address nftContract) external checkAdmin {
        if (_whitelistExist[nftContract]) {
            revert AddressExistsInWhitelist();
        }
        _whitelistExist[nftContract] = true;
        _whiteliste.push(nftContract);

        emit SetWhitelist(_msgSender(), nftContract);
    }

    /// @dev Set the auction duration.
    ///
    /// This function reverts if the caller does not have the admin role.
    ///
    /// @param time     the time of the auction remaining.
    function setBiddingTime(uint time) external checkAdmin {
        _biddingTime = time * 1 days;
    }

    /// @dev Withdraws the Eth net profit within the contract to the assigned address.
    ///
    /// This function reverts if the caller does not have the admin role, if either the amount does 
    /// not exceed ZERO or exceeds `_totalFeeEth`, or the assigned address is a zero address.
    ///
    /// @param account  the address to withdraw Eth to.
    /// @param amount   the amount of Eth to withdraw.
    function withdrawMPEth(address account, uint256 amount) 
        external
        checkAdmin 
        checkAmount(amount)
        checkAdress(account)
        nonReentrant 
    {
        if (amount > _totalFeeEth) {
            revert NotEnoughFunds();
        }
        _totalFeeEth -= amount;
        payable(account).transfer(amount);

        emit WithdrawMP(
            false,
            _msgSender(),
            account,
            amount
        );
    }

    /// @dev Withdraws the VegasONE net profit balance within the contract to the assigned address.
    ///
    /// This function reverts if the caller does not have the admin role, if either the amount does 
    /// not exceed ZERO or exceeds `_totalFeeVegasONE`, or the assigned address is a zero address.
    ///
    /// @param account  the address to withdraw VegasONE to.
    /// @param amount   the amount of VegasONE to withdraw.
    function withdrawMPVegasONE(address account, uint256 amount) 
        external
        checkAdmin 
        checkAmount(amount)
        checkAdress(account)
        nonReentrant
    {
        if (amount > _totalFeeVegasONE) {
            revert NotEnoughFunds();
        }
        _totalFeeVegasONE -= amount;
        require(_paymentToken.transfer(account, amount));
        
        emit WithdrawMP(
            true,
            _msgSender(),
            account,
            amount
        );
    }

    /**
     * External/Public Functions
     */

    /// @dev Create a market item.
    ///
    /// This function reverts if `nftContract` does not exist in the whitelist or if the amount does 
    /// not exceed ZERO or exceeds `_totalFeeVegasONE`.
    ///
    /// @param nftContract  the address of the nft contract.
    /// @param tokenId      The number of the token id in the nft contract.
    /// @param price        the price of the market item.
    /// @param isVegasONE   the status of VegasONE used as currency.
    function createMarketItem(
        address nftContract,
        uint256 tokenId,
        uint256 price,
        bool isVegasONE
    ) 
        external 
        checkWhitelist(nftContract) 
        checkAmount(price) 
        returns (uint256)
    {        
        address seller = _msgSender();

        _itemIdCounter.increment();
        uint256 itemId = _itemIdCounter.current();

        _addItem(
            MarketItem({
                itemId: itemId,
                nftContract: nftContract,
                tokenId: tokenId,
                seller: seller,
                isVegasONE: isVegasONE,
                price: price,
                soldOut: false
            })
        );

        emit CreateMarketItem(
            isVegasONE,
            nftContract,
            seller,
            itemId,
            tokenId,
            price
        );

        IERC721Upgradeable(nftContract).safeTransferFrom(
            seller,
            address(this),
            tokenId
        );

        return itemId;
    }

    /// @dev Cancel the sale of the `itemId` item from the market item.
    ///
    /// This function reverts if `itemId` does not exist, if either the caller does not the seller or
    /// does not have the admin role, or the item has been sold.
    ///
    /// @param itemId   the number of the selected item id.
    function removeMarketItem(uint256 itemId) external checkItemExist(itemId){
        MarketItem storage item = _getItem(itemId);
        address seller = _msgSender();
        if (!hasRole(ADMIN_ROLE, seller)){
            if (seller != item.seller) {
                revert OnlyRemovedBySellerOrAdmin();
            }
        }

        if (item.soldOut) {
            revert SoldOut();
        }

        item.soldOut = true;

        emit RemoveMarketItem(
            item.isVegasONE,
            item.nftContract,
            item.seller,
            item.itemId,
            item.tokenId,
            item.price
        );

        IERC721Upgradeable(item.nftContract).safeTransferFrom(
            address(this),
            item.seller,
            item.tokenId
        );
    }
    
    /// @dev Purchase the `itemId` item from the market item using Eth as payment.
    ///
    /// This function reverts if `itemId` does not exist, if either the caller is the seller, 
    /// or the item is uses VegasONE as the currency, or the item has been sold.
    ///
    /// @param itemId   the number of the selected item id.
    function buyE(uint256 itemId) 
        external 
        checkItemExist(itemId) 
        checkSeller(itemId)
        nonReentrant 
        payable 
    {
        MarketItem storage item = _getItem(itemId);

        address buyer = _msgSender();

        if (item.isVegasONE) {
            revert OnlyAcceptEthForPayment();
        }
        if (item.soldOut) {
            revert SoldOut();
        }
        require(msg.value == item.price);

        uint256 fee = (item.price * _feePercent) / thousand;
        uint256 realPrice = item.price - fee;

        _totalFeeEth += fee;
        _ownedEth[item.seller] += realPrice;
        
        item.soldOut = true;

        emit Buy(
            item.isVegasONE,
            item.nftContract,
            item.seller,
            buyer,
            item.itemId,
            item.tokenId,
            realPrice,
            fee
        );

        IERC721Upgradeable(item.nftContract).safeTransferFrom(
            address(this),
            buyer,
            item.tokenId
        );
    }

    /// @dev Purchase the `itemId` item from the market item using VegasONE as payment.
    ///
    /// This function reverts if `itemId` does not exist, if either the caller is the seller, 
    /// or the item is uses Eth as the currency, or the item has been sold.
    ///
    /// @param itemId   the number of the selected item id.
    function buyV(uint256 itemId) 
        external 
        checkItemExist(itemId)
        checkSeller(itemId)
        nonReentrant 
    {
        MarketItem storage item = _getItem(itemId);

        address buyer = _msgSender();

        if (!item.isVegasONE) {
            revert OnlyAcceptVegasONEForPayment();
        }
        if (item.soldOut) {
            revert SoldOut();
        }
        uint256 fee = (item.price * _feePercent) / thousand;
        uint256 realPrice = item.price - fee;

        item.soldOut = true;

        emit Buy(
            item.isVegasONE,
            item.nftContract,
            item.seller,
            buyer,
            item.itemId,
            item.tokenId,
            realPrice,
            fee
        );

        _totalFeeVegasONE += fee;
        _ownedVegasONE[item.seller] += realPrice;
        require(
            _paymentToken.transferFrom(buyer, address(this), item.price), 
            "NFTMarketPlace: transaction failed"
        );

        IERC721Upgradeable(item.nftContract).safeTransferFrom(
            address(this),
            buyer,
            item.tokenId
        );
    }

    /// @dev Withdraws the caller's Eth balance within the contract to the assigned address.
    ///
    /// This function reverts if the amount does not exceed ZERO or exceeds the caller's balance, or 
    /// if the assigned address is a zero address.
    ///
    /// @param account  the address to withdraw Eth to.
    /// @param amount   the amount of Eth to withdraw.
    function withdrawEth(address account, uint256 amount) 
        external 
        checkAmount(amount) 
        checkAdress(account)
        nonReentrant 
    {
        address buyer = _msgSender();

        if (amount > _ownedEth[buyer]) {
            revert NotEnoughFunds();
        }
        _ownedEth[buyer] -= amount;
        payable(account).transfer(amount);
        

        emit Withdraw(
            false,
            buyer,
            account,
            amount
        );
    }

    /// @dev Withdraws the caller's VegasONE balance within the contract to the assigned address.
    ///
    /// This function reverts if the amount does not exceed ZERO or exceeds the caller's balance, or 
    /// if the assigned address is a zero address.
    ///
    /// @param account  the address to withdraw VegasONE to.
    /// @param amount   the amount of VegasONE to withdraw.
    function withdrawVegasONE(address account, uint256 amount) 
        external 
        checkAmount(amount) 
        checkAdress(account)
        nonReentrant
    {
        address buyer = _msgSender();

        if (amount > _ownedVegasONE[buyer]) {
            revert NotEnoughFunds();
        }
        _ownedVegasONE[buyer] -= amount;
        require(_paymentToken.transfer(account, amount));

        emit Withdraw(
            true,
            buyer,
            account,
            amount
        );
    }

    /// @dev Create an auction item.
    ///
    /// This function reverts if `nftContract` does not exist in the whitelist.
    ///
    /// @param nftContract  the address of the nft contract.
    /// @param tokenId      The number of the token id in the nft contract.
    /// @param isVegasONE   the status of VegasONE used as currency.
    function createAuctionItem(
        address nftContract,
        uint256 tokenId,
        bool isVegasONE
    ) 
        external checkWhitelist(nftContract) 
        returns (uint256) 
    {        
        address seller = _msgSender();

        _auctionItemsIdCounter.increment();
        uint256 itemId = _auctionItemsIdCounter.current();

        uint auctionStartTime = block.timestamp;
        address highestBidder = address(0);
        uint256 highestPrice = 0;

        _addAuctionItem(
            AuctionItem({
                itemId: itemId,
                nftContract: nftContract,
                tokenId: tokenId,
                seller: seller,
                isVegasONE: isVegasONE,
                auctionStartTime: auctionStartTime,
                highestBidder: highestBidder,
                highestPrice: highestPrice,
                soldOut: false
            })
        );

        emit CreateAuctionItem(
            isVegasONE,
            nftContract,
            seller,
            auctionStartTime,
            itemId,
            tokenId,
            highestPrice
        );

        IERC721Upgradeable(nftContract).safeTransferFrom(
            seller,
            address(this),
            tokenId
        );

        return itemId;
    }

    /// @dev Cancel auction for the `itemId` item from the auction item.
    ///
    /// This function reverts if `itemId` does not exist, if either the caller does not the seller or
    /// does not have the admin role, or the auction item has been bid, or the item has been auctioned.
    ///
    /// @param itemId   the number of the selected item id.
    function removeAuctionItem(uint256 itemId) 
        external 
        checkAuctionItemExist(itemId)
    {
        AuctionItem storage item = _getAuctionItem(itemId);
        address seller = _msgSender();
        if (!hasRole(ADMIN_ROLE, seller)){
            if (seller != item.seller) {
                revert OnlyRemovedBySellerOrAdmin();
            }
        }

        if (item.soldOut){
            revert SoldOut();
        }
        
        if (item.highestBidder != address(0)) {
            revert CanNotRemovedWhenHighestBidderExist();
        }

        item.soldOut = true;

        emit RemoveAuctionItem(
            item.isVegasONE,
            item.nftContract,
            item.seller,
            item.auctionStartTime,
            item.itemId,
            item.tokenId,
            item.highestPrice
        ); 

        IERC721Upgradeable(item.nftContract).safeTransferFrom(
            address(this),
            item.seller,
            item.tokenId
        );
    }

    /// @dev Bid the `itemId` item from the auction item using VegasONE as payment, if the bidder 
    ///      has already bid on the same item, increase the bid on top of the previous bid.
    ///
    /// This function reverts if `itemId` does not exist, if either the caller is the seller, 
    /// auction has ended, the item uses Eth as currency, the caller is highest bidder, 
    /// or the privce does not exceed the highest price.
    ///
    /// @param itemId   the number of the selected item id.
    /// @param price    the price of the bid or increase.
    function bidV(uint256 itemId, uint256 price)
        external 
        checkAuctionItemExist(itemId) 
        checkAuctionSeller(itemId)
        nonReentrant 
    {
        AuctionItem storage item = _getAuctionItem(itemId);
        
        address buyer = _msgSender();

        if (block.timestamp >= item.auctionStartTime + _biddingTime) {
            revert AuctionIsOver();
        }

        if (!item.isVegasONE) {
            revert OnlyAcceptVegasONEForPayment();
        }

        if (buyer == item.highestBidder) {
            revert HighestBidderIsYou();
        }

        if (_ownedBidVegasONE[buyer][item.itemId] + price <= item.highestPrice) {
            revert NotExceedingHighestPrice();
        }

        _auctionItemsHighestBidder[item.itemId] = buyer;
        item.highestPrice = _ownedBidVegasONE[buyer][item.itemId] + price;
        item.highestBidder = buyer;

        _ownedBidVegasONE[item.highestBidder][item.itemId] = item.highestPrice;
        
        require(
            _paymentToken.transferFrom(buyer, address(this), price), 
            "NFTMarketPlace: transaction failed"
        );

        emit Bid(
            item.isVegasONE,
            item.nftContract,
            item.seller,
            buyer,
            item.itemId,
            item.tokenId,
            price
        );
    }

    /// @dev Bid the `itemId` item from the auction item using Eth as payment, if the bidder 
    ///      has already bid on the same item, increase the bid on top of the previous bid.
    ///
    /// This function reverts if `itemId` does not exist, if either the caller is the seller, 
    /// auction has ended, the item uses VegasONE as currency, the caller is highest bidder, 
    /// or the privce does not exceed the highest price.
    ///
    /// @param itemId   the number of the selected item id.
    function bidE(uint256 itemId) 
        external 
        checkAuctionItemExist(itemId) 
        checkAuctionSeller(itemId)
        nonReentrant
        payable
    {
        AuctionItem storage item = _getAuctionItem(itemId);
        
        address buyer = _msgSender();

        if (block.timestamp >= item.auctionStartTime + _biddingTime) {
            revert AuctionIsOver();
        }
        
        if (item.isVegasONE) {
            revert OnlyAcceptEthForPayment();
        }

        if (buyer == item.highestBidder) {
            revert HighestBidderIsYou();
        }

        if (_ownedBidEth[buyer][item.itemId] + msg.value <= item.highestPrice) {
            revert NotExceedingHighestPrice();
        }

        _auctionItemsHighestBidder[item.itemId] = buyer;
        item.highestPrice = _ownedBidEth[buyer][item.itemId] + msg.value;
        item.highestBidder = buyer;

        _ownedBidEth[item.highestBidder][item.itemId] = item.highestPrice;

        emit Bid(
            item.isVegasONE,
            item.nftContract,
            item.seller,
            buyer,
            item.itemId,
            item.tokenId,
            msg.value
        );
    }

    /// @dev Withdraw the caller's bidding VegasONE amount for the auction item to the assigned address.
    ///
    /// This function reverts if the caller is the highest bidder or if the caller did not bid.
    ///
    /// @param account  the address to withdraw VegasONE to.
    /// @param itemId   the number of the selected item id.
    function revertBidVegasONE(address account, uint256 itemId) 
        external 
        checkAuctionBidder(itemId) 
        nonReentrant
    {
        address buyer = _msgSender();
        uint256 _balance = _ownedBidVegasONE[buyer][itemId];

        if (_balance == 0) {
            revert NoFundsCanBeRevert();
        }

        _ownedBidVegasONE[buyer][itemId] = 0;
        require(_paymentToken.transfer(account, _balance));

        emit RevertBid(
            buyer,
            account,
            itemId,
            _balance
        );
    }

    /// @dev Withdraw the caller's bidding Eth amount for the auction item to the assigned address.
    ///
    /// This function reverts if the caller is the highest bidder or if the caller did not bid.
    ///
    /// @param account  the address to withdraw Eth to.
    /// @param itemId   the number of the selected item id.
    function revertBidEth(address account,uint256 itemId) 
        external 
        checkAuctionBidder(itemId) 
        nonReentrant 
    {
        address buyer = _msgSender();
        uint256 _balance = _ownedBidEth[buyer][itemId];

        if (_balance == 0) {
            revert NoFundsCanBeRevert();
        }

        _ownedBidEth[buyer][itemId] = 0;
        payable(account).transfer(_balance);

        emit RevertBid(
            buyer,
            account,
            itemId,
            _balance
        );
    }

    /// @dev Closing auction items after the auction time is over.
    ///
    /// This function reverts if `itemId` does not exist, if either the auction has not ended,
    /// no one has bid on the auction item, or the caller is not the seller or the highest bidder,
    /// or the item has been auctioned.
    ///
    /// @param itemId   the number of the selected item id.
    function auctionEnd(uint256 itemId) external nonReentrant checkAuctionItemExist(itemId) {
        AuctionItem storage item = _getAuctionItem(itemId);

        if (block.timestamp < item.auctionStartTime + _biddingTime) {
            revert AuctionIsNotOver();
        }

        if (item.soldOut){
            revert SoldOut();
        }

        if (item.highestBidder == address(0)) {
            revert NoOneBid();
        }

        if ((_msgSender() != item.highestBidder && _msgSender() != item.seller)) {
            revert OnlyHighestBidderOrSellerCanEnd();
        }

        uint256 fee = (item.highestPrice * _feePercent) / thousand;
        uint256 realPrice = item.highestPrice - fee;

        item.soldOut = true;

        if (item.isVegasONE)
        {   
            _totalFeeVegasONE += fee;
            _ownedBidVegasONE[item.highestBidder][item.itemId] = 0;
            require(_paymentToken.transfer(item.seller, realPrice));
        } else {
            _totalFeeEth += fee;
            _ownedBidEth[item.highestBidder][item.itemId] = 0;
            payable(item.seller).transfer(realPrice);
        }

        emit AuctionEnd(
            item.isVegasONE,
            item.nftContract,
            item.seller,
            item.highestBidder,
            item.auctionStartTime + _biddingTime,
            item.itemId,
            item.tokenId,
            realPrice,
            fee
        );

        IERC721Upgradeable(item.nftContract).safeTransferFrom(
            address(this),
            item.highestBidder,
            item.tokenId
        );
    }

    /**
     * Admin only view Functions
     */

    /// @dev Gets the net profit of Eth in market place.
    ///
    /// @return the net profit amount of Eth.
    function drawableMPEth() external view returns (uint256) {
        return _totalFeeEth;
    }

    /// @dev Gets the VegasONE's net profit balance in market place.
    ///
    /// @return the net profit amount of VegasONE.
    function drawableMPVegasONE() external view returns (uint256) {
        return _totalFeeVegasONE;
    }

    /**
     * View Functions
     */

    /// @dev Get details of market item by item id.
    ///
    /// @param itemId   the number of the selected item id.
    ///
    /// @return the details of the selected market item.
    function getMarketItem(uint256 itemId)
        external
        view
        returns (MarketItem memory)
    {
        return _getItem(itemId);
    }

    /// @dev Get a reverse list of market item details.
    ///
    /// @param perPage  the number of market items per page.
    /// @param pageId   the page number of the market item.
    ///
    /// @return list of market item details.
    function listMarketItem(uint256 perPage, uint256 pageId) 
        external 
        checkPage(perPage, pageId)
        view 
        returns (MarketItem[] memory) 
    {
        uint256 startId;
        uint256 endId;
        uint256 counter = 0;

        MarketItem[] memory ret;

        if (_items.length > (perPage * (pageId - 1))) {
            startId = _items.length - (perPage * (pageId - 1));
        } else if (_items.length == 0) {
            return ret;
        } else {
            revert OutOfBounds();
        }

        if (startId > perPage) {
            endId = startId - perPage + 1;
        } else {
            endId = 1;
        }

        ret = new MarketItem[](startId - endId + 1);

        for (uint256 i = startId; i >= endId ; i--) {
            ret[counter] = _getItem(i);
            counter++;
        }
        return ret;
    }

    /// @dev Get a reverse list of market item details owned by the address.
    ///
    /// @param seller   the address to retrieve.
    /// @param perPage  the number of market items per page.
    /// @param pageId   the page number of the market item.
    ///
    /// @return list of market item details owned by the address.
    function listMarketItemOf(address seller, uint256 perPage, uint256 pageId)
        external
        checkPage(perPage, pageId)
        view
        returns (MarketItem[] memory)
    {
        uint256 startId;
        uint256 endId;
        uint256 itemId;
        uint256 counter = 0;

        MarketItem[] memory ret;

        if (_ownedItems[seller].length > (perPage * (pageId - 1))) {
            startId = _ownedItems[seller].length - 1 - (perPage * (pageId - 1));
        } else if (_ownedItems[seller].length == 0) {
            return ret;
        } else {
            revert OutOfBounds();
        }

        if (startId + 1 > perPage) {
            endId = startId - perPage + 1;
        } else {
            endId = 0;
        }
        
        ret = new MarketItem[](startId - endId + 1);

        for (uint256 i = startId; i >= endId; i--) {
            itemId = _ownedItems[seller][i];
            ret[counter] = _getItem(itemId);
            counter++;
            if (i == endId) {
                break;
            }
        }
        
        return ret;
    }

    /// @dev Get the market item number owned by the address.
    ///
    /// @param seller   the address to retrieve.
    ///
    /// @return the number of market items owned by the address.
    function marketItemCountOf(address seller) external view returns (uint256) {
        return _ownedItems[seller].length;
    }

    /// @dev Get the number of market items.
    ///
    /// @return the number of market items.
    function marketItemCount() external view returns (uint256) {
        return _items.length;
    }

    /// @dev Get details of the auction item by item id.
    ///
    /// @param itemId   the number of the selected item id.
    ///
    /// @return the details of the selected auction item.
    function getAuctionItem(uint256 itemId)
        external
        checkAuctionItemExist(itemId)
        view
        returns (AuctionItem memory)
    {
        return _getAuctionItem(itemId);
    }

    /// @dev Get a reverse list of auction item details.
    ///
    /// @param perPage  the number of auction items per page.
    /// @param pageId   the page number of the auction item.
    ///
    /// @return list of auction item details.
    function listAuctionItem(uint256 perPage, uint256 pageId) 
        external 
        checkPage(perPage, pageId)
        view 
        returns (AuctionItem[] memory)
    {
        uint256 startId;
        uint256 endId;
        uint256 counter = 0;

        AuctionItem[] memory ret;

        if (_auctionItems.length > (perPage * (pageId - 1))) {
            startId = _auctionItems.length - (perPage * (pageId - 1));
        } else if (_auctionItems.length == 0) {
            return ret;
        } else {
            revert OutOfBounds();
        }

        if (startId > perPage) {
            endId = startId - perPage + 1;
        } else {
            endId = 1;
        }

        ret = new AuctionItem[](startId - endId + 1);

        for (uint256 i = startId; i >= endId ; i--) {
            ret[counter] = _getAuctionItem(i);
            counter++;
        }
        return ret;
    }

    /// @dev Get a reverse list of auction item details owned by the address.
    ///
    /// @param seller   the address to retrieve.
    /// @param perPage  the number of auction items per page.
    /// @param pageId   the page number of the auction item.
    ///
    /// @return list of auction item details owned by the address.
    function listAuctionItemOf(address seller, uint256 perPage, uint256 pageId)
        external
        checkPage(perPage, pageId)
        view
        returns (AuctionItem[] memory)
    {
        uint256 startId;
        uint256 endId;
        uint256 itemId;
        uint256 counter = 0;

        AuctionItem[] memory ret;

        if (_ownedAuctionItems[seller].length > (perPage * (pageId - 1))) {
            startId = _ownedAuctionItems[seller].length - (perPage * (pageId - 1)) - 1;
        } else if (_ownedAuctionItems[seller].length == 0) {
            return ret;
        } else {
            revert OutOfBounds();
        }

        if (startId + 1 > perPage) {
            endId = startId - perPage + 1;
        } else {
            endId = 0;
        }
        
        ret = new AuctionItem[](startId - endId + 1);

        for (uint256 i = startId; i >= endId ; i--) {
            itemId = _ownedAuctionItems[seller][i];
            ret[counter] = _getAuctionItem(itemId);
            counter++;
            if (i == endId) {
                break;
            }
        }
        
        return ret;
    }

    /// @dev Get the auction item number owned by the address.
    ///
    /// @param seller   the address to retrieve.
    ///
    /// @return the number of the auction items owned by the address.
    function auctionItemCountOf(address seller) external view returns (uint256) {
        return _ownedAuctionItems[seller].length;
    }

    /// @dev Get the number of auction items.
    ///
    /// @return the number of auction items.
    function auctionItemCount() external view returns (uint256) {
        return _auctionItems.length;
    }

    /// @dev Get the amount of Eth that the caller can withdraw.
    ///
    /// @return the amount of Eth that the caller can withdraw.
    function drawableEth() external view returns (uint256) {
        return _ownedEth[_msgSender()];
    }

    /// @dev Get the amount of VegasONE that the caller can withdraw.
    ///
    /// @return the amount of VegasONE that the caller can withdraw.
    function drawableVegasONE() external view returns (uint256) {
        return _ownedVegasONE[_msgSender()];
    }

    /// @dev Get the amount of Eth for the item that the caller can revert by item id.
    ///
    /// @param itemId   the number of the selected item id.
    ///
    /// @return the amount of Eth for the selected item that the caller can revert.
    function revertableEth(uint256 itemId) external view returns (uint256) {
        return _ownedBidEth[_msgSender()][itemId];
    }

    /// @dev Get the amount of VegasONE for the item that the caller can revert by item id.
    ///
    /// @param itemId   the number of the selected item id.
    ///
    /// @return the amount of VegasONE for the selected item that the caller can revert.
    function revertableVegasONE(uint256 itemId) external view returns (uint256) {
        return _ownedBidVegasONE[_msgSender()][itemId];
    }

    /// @dev Get the currency of the token.
    ///
    /// @return the currency of the token.
    function paymentToken() external view returns (IERC20Upgradeable) {
        return _paymentToken;
    }

    /// @dev Get fee percentage.
    ///
    /// @return the number of fee percentage.
    function feePercent() external view returns (uint256) {
        return _feePercent;
    }

    /// @dev Get list of whitelists in market place.
    ///
    /// @return list of whitelists.
    function whitelist() external view returns (address[] memory) {
        return _whiteliste;
    }

    /// @dev Get auction duration.
    ///
    /// @return the number of the auction durations.
    function biddingTime() external view returns (uint) {
        return _biddingTime;
    }

    /**
     * Internal Functions
     */

    /// @dev add an item to market item.
    ///
    /// @param newItem  the struct of the `MarketItem`.
    function _addItem(MarketItem memory newItem) internal {
        _itemsExist[newItem.itemId] = true;
        _addMainItem(newItem);
        _addOwnedItem(newItem.seller, newItem.itemId);
    }

    /// @dev store item details into the storage array of market item.
    ///
    /// @param newItem  the struct of the `MarketItem`.
    function _addMainItem(MarketItem memory newItem) internal {
        uint256 newIndex = _items.length;
        _items.push(newItem);
        _itemsIndex[newItem.itemId] = newIndex;
    }

    /// @dev store item details into the user's storage array of market item.
    ///
    /// @param seller       the address of the caller.
    /// @param newItemId    the number of the selected item id.
    function _addOwnedItem(address seller, uint256 newItemId) internal {
        uint256 newIndex = _ownedItems[seller].length;
        _ownedItems[seller].push(newItemId);
        _ownedItemsIndex[newItemId] = newIndex;
    }

    /// @dev add an item to auction item.
    ///
    /// @param newItem  the struct of the `AuctionItem`.
    function _addAuctionItem(AuctionItem memory newItem) internal {
        _auctionItemsExist[newItem.itemId] = true;
        _addMainAuctionItem(newItem);
        _addOwnedAuctionItem(newItem.seller, newItem.itemId);
    }

    /// @dev store item details into the storage array of auction item.
    ///
    /// @param newItem  the struct of the `AuctionItem`.
    function _addMainAuctionItem(AuctionItem memory newItem) internal {
        uint256 newIndex = _auctionItems.length;
        _auctionItems.push(newItem);
        _auctionItemsIndex[newItem.itemId] = newIndex;
    }

    /// @dev store item details into the user's auction array of auction item by item id.
    ///
    /// @param seller       the address of the caller.
    /// @param newItemId    the number of the selected item id.
    function _addOwnedAuctionItem(address seller, uint256 newItemId) internal {
        uint256 newIndex = _ownedAuctionItems[seller].length;
        _ownedAuctionItems[seller].push(newItemId);
        _ownedAuctionItemsIndex[newItemId] = newIndex;
    }

    /// @dev Get whether the item exists from market item.
    ///
    /// @param itemId   the number of the selected item id.
    ///
    /// @return ture if the item is exists, false otherwise.
    function _isItemExist(uint256 itemId) internal view returns (bool) {
        return _itemsExist[itemId];
    }

    /// @dev Get market item details by item id.
    ///
    /// @param itemId   the number of the selected item id.
    ///
    /// @return the details of the selected market item.
    function _getItem(uint256 itemId)
        internal
        view
        returns (MarketItem storage)
    {
        uint256 index = _itemsIndex[itemId];
        return _items[index];
    }

    /// @dev Get whether the item exists from auction item.
    ///
    /// @param itemId   the number of the selected item id.
    ///
    /// @return ture if the item is exists, false otherwise.
    function _isAuctionItemExist(uint256 itemId) internal view returns (bool) {
        return _auctionItemsExist[itemId];
    }

    /// @dev Get auction item details by item id.
    ///
    /// @param itemId   the number of the selected item id.
    ///
    /// @return the details of the selected auction item.
    function _getAuctionItem(uint256 itemId)
        internal
        view
        returns (AuctionItem storage)
    {
        uint256 index = _auctionItemsIndex[itemId];
        return _auctionItems[index];
    }

    /// @dev Get whether the address exists in the whitelist.
    ///
    /// @param nftContract  the address of the contract.
    ///
    /// @return ture if the address is exists, false otherwise.
    function _isWhitelist(address nftContract) internal view returns (bool) {
        return _whitelistExist[nftContract];
    }

    /**
     * Pause Fuctions
     */

    function pause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    /**
     * Upgrade
     */

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyRole(DEFAULT_ADMIN_ROLE)
        override
    {}

    /**
     * ERC721Receiver
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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

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
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

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
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
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
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
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
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate that the this implementation remains valid after an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library CountersUpgradeable {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
interface IERC165Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}