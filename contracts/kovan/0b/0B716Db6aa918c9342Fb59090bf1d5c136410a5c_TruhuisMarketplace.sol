// SPDX-Licence-Identifier: MIT

pragma solidity 0.8.13;

import "KeeperCompatible.sol";
import "Ownable.sol";
import "ReentrancyGuard.sol";
import "IERC20.sol";
import "IERC721.sol";
import "TruhuisAddressRegistryAdapter.sol";
import "TokenIdObserver.sol";
import "IStateGovernment.sol";
import "ICitizen.sol";

contract TruhuisMarketplace is
    Ownable,
    TruhuisAddressRegistryAdapter,
    ReentrancyGuard,
    KeeperCompatibleInterface,
    TokenIdObserver
{
    enum Stage {
        available,
        negotiation, // @dev Ontbindende voorwaarden opstellen. Vereist aparte contract.
        coolingOffPeriod,
        sold
    }

    struct Listing {
        bool exists;
        Stage status;
        address currency;
        uint256 initialPrice;
        uint256 purchasePrice;
        uint256 purchaseTime;
        uint256 initialTime;
        uint256 tokenId;
        uint256 coolingOffPeriod;
        address buyer;
        address seller;
    }

    struct Offer {
        address offerer;
        address currency;
        bool exists;
        uint256 price;
        uint256 expiry;
    }

    address public marketplaceOwner;
    uint96 public marketplaceCommissionFraction; // e.g. 100 (1%); 1000 (10%)

    /// @dev tokenId => buyer => bool
    mapping(uint256 => mapping(address => bool)) public s_isVerifiedBuyer;
    /// @dev tokenId => seller => bool
    mapping(uint256 => mapping(address => bool)) public s_isVerifiedSeller;

    /// @dev tokenId => Listing
    mapping(uint256 => Listing) public s_listings;  
    /// @dev tokenId => offerer => Offer
    mapping(uint256 => mapping(address => Offer)) public s_offers; 

    event HouseListed(
        address indexed seller,
        uint256 indexed tokenId,
        bytes3 indexed propertyCountry,
        address currency,
        uint256 initialTime,
        uint256 initialPrice,
        uint256 coolingOffPeriod,
        Stage stage
    );

    event HouseBought(
        address indexed buyer,
        address indexed seller,
        uint256 indexed tokenId,
        uint256 purchaseTime,
        uint256 purchasePrice,
        Stage stage
    );

    event HouseSold(
        address indexed buyer,
        address indexed seller,
        uint256 indexed tokenId,
        uint256 soldTime,
        uint256 soldPrice,
        Stage stage
    );

    event ListingUpdated(
        address indexed seller,
        uint256 indexed tokenId,
        address currency,
        uint256 newPrice
    );

    event ListingCanceled(
        address indexed seller,
        uint256 indexed tokenId
    );

    event OfferCreated(
        address indexed offerer,
        uint256 indexed tokenId,
        address currency,
        uint256 price,
        uint256 expiry
    );

    event OfferAccepted(
        address indexed seller,
        uint256 indexed tokenId,
        address indexed buyer,
        uint256 purchaseTime,
        uint256 purchasePrice,
        Stage stage
    );

    event OfferCanceled(
        address indexed offerer,
        uint256 indexed tokenId
    );

    event PurchaseCanceled(
        address indexed buyer,
        uint256 indexed tokenId,
        Stage stage
    );

    event MarketplaceOwnerUpdated(
        address oldOwner,
        address newOwner
    );

    event MarketplaceCommissionFractionUpdated(
        uint256 oldCommissionFraction,
        uint256 newCommissionFraction
    );

    modifier listingExists(uint256 _tokenId) {
        require(isListingExistent(_tokenId), "listing must be existent");
        _;
    }

    modifier notListed(uint256 _tokenId) {
        require(!isListingExistent(_tokenId), "listing must be nonexistent");
        _;
    }

    modifier notOffered(address _offerer, uint256 _tokenId) {
        require(!isOfferExistent(_offerer, _tokenId), "offer must be nonexistent");
        _;
    }

    modifier onlyBuyer(address _buyer, uint256 _tokenId) {
        verifyBuyer(_buyer, _tokenId);
        _;
    }

    modifier onlySeller(address _seller, uint256 _tokenId) {
        verifySeller(_seller, _tokenId);
        _;
    }

    constructor(address _addressRegistry) {
        marketplaceOwner = msg.sender;
        marketplaceCommissionFraction = 250; 
        _updateAddressRegistry(_addressRegistry);
    }

    //      *            *                 *                 *
    //          LISTING        LISTING           LISTING
    //      *            *                 *                 *
    
    function listHouse(address _currency, uint256 _tokenId, uint256 _price)
        external
        notListed(_tokenId)
        onlySeller(msg.sender, _tokenId)
    {
        require(isAllowedCurrency(_currency), "invalid currency");

        Listing storage s_listing = s_listings[_tokenId];

        s_listing.exists = true;
        s_listing.status = Stage.available;
        s_listing.currency = _currency;
        s_listing.initialPrice = _price;
        s_listing.initialTime = _getNow();
        s_listing.seller = msg.sender;
        s_listing.tokenId = _tokenId;
        s_listing.coolingOffPeriod = getCoolingOffPeriod(_tokenId);
        s_listing.buyer = address(0);
        s_listing.purchaseTime = 0;
        s_listing.purchasePrice = 0;

        bytes3 propertyCountry = getPropertyCountry(_tokenId);

        emit HouseListed(
            msg.sender,
            _tokenId,
            propertyCountry,
            _currency,
            s_listing.initialTime,
            _price,
            s_listing.coolingOffPeriod,
            Stage.available
        );

        _storeTokenId(_tokenId);
    }

    function buyHouseFrom(address _seller, address _currency, uint256 _tokenId)
        external
        nonReentrant
        onlyBuyer(msg.sender, _tokenId)
        listingExists(_tokenId)
    {
        Listing storage s_listing = s_listings[_tokenId];
        
        require(isAllowedCurrency(_currency), "invalid currency");
        require(s_listing.currency == _currency, "currencies are not equal");
        require(hasEnoughFunds(msg.sender, _currency, s_listing.initialPrice), "insufficient funds");

        s_listing.buyer = msg.sender;
        s_listing.purchasePrice = s_listing.initialPrice;
        s_listing.purchaseTime = block.timestamp;

        _purchaseHouse(msg.sender, _seller, _currency, _tokenId, s_listing.initialPrice);

        emit HouseBought(
            msg.sender,
            _seller,
            _tokenId,
            s_listing.purchaseTime,
            s_listing.purchasePrice,
            Stage.coolingOffPeriod
        );
    }

    function updateListing(address _currency, uint256 _tokenId, uint256 _newPrice)
        external
        onlySeller(msg.sender, _tokenId)
        listingExists(_tokenId)
    {
        require(_newPrice > 0, "price must be above 0");
        require(isAllowedCurrency(_currency), "invalid currency");

        Listing storage s_listing = s_listings[_tokenId];
        
        s_listing.currency = _currency;
        s_listing.initialPrice = _newPrice;

        emit ListingUpdated(
            msg.sender,
            _tokenId,
            _currency,
            _newPrice
        );
    }

    function cancelListing(uint256 _tokenId)
        external
        onlySeller(msg.sender, _tokenId)
        listingExists(_tokenId)
    {
        delete s_listings[_tokenId];

        emit ListingCanceled(
            msg.sender,
            _tokenId
        );
    }

    //      *           *               *               *
    //          OFFER         OFFER           OFFER
    //      *           *               *               *

    function createOffer(
        address _currency,
        uint256 _tokenId,
        uint256 _price,
        uint256 _expiry
    )
        external
        onlyBuyer(msg.sender, _tokenId)
        listingExists(_tokenId)
        notOffered(msg.sender, _tokenId)
    {
        require(_price > 0, "price must be greater than zero");
        require(isOfferExistent(msg.sender, _tokenId), "offer not exists");
        require(isOfferExpired(msg.sender, _tokenId), "offer is expired");
        require(isAllowedCurrency(_currency), "invalid currency");
        require(isAuctionInAction(_tokenId), "auction must be finished first");

        s_offers[_tokenId][msg.sender] = Offer({
            offerer: msg.sender,
            currency: _currency,
            exists: true,
            price: _price,
            expiry: _expiry
        });

        emit OfferCreated(
            msg.sender,
            _tokenId,
            _currency,
            _price,
            _expiry
        );
    }

    /**
     * @notice Seller accepts the offer.
     */
    function acceptOffer(uint256 _tokenId, address _offerer)
        external
        nonReentrant
        onlySeller(msg.sender, _tokenId)
    {
        require(isOfferExistent(_offerer, _tokenId), "offer not exists");
        require(isOfferExpired(_offerer, _tokenId), "offer is expired");
        require(!isAuctionInAction(_tokenId), "auction must be finished first");

        Offer memory offer = s_offers[_tokenId][_offerer];
        Listing storage s_listing = s_listings[_tokenId];

        require(isAllowedCurrency(offer.currency), "invalid offer currency");
        require(offer.currency == s_listing.currency, "offer currency is not listing currency");
        require(hasEnoughFunds(_offerer, offer.currency, offer.price), "offerer has insufficient funds");

        s_listing.buyer = _offerer;
        s_listing.purchasePrice = offer.price;
        s_listing.purchaseTime = block.timestamp;

        _purchaseHouse(_offerer, s_listing.seller, offer.currency, _tokenId, offer.price);

        emit OfferAccepted(
            s_listing.seller,
            _tokenId,
            msg.sender,
            s_listing.purchaseTime,
            s_listing.purchasePrice,
            Stage.coolingOffPeriod
        );

        delete s_offers[_tokenId][_offerer];
    }

    function cancelOffer(uint256 _tokenId)
        external
        onlyBuyer(msg.sender, _tokenId)
        listingExists(_tokenId)
    {
        Offer memory offer = s_offers[_tokenId][msg.sender];

        require(offer.offerer == msg.sender, "invalid offerer");
        require(isOfferExistent(msg.sender, _tokenId), "offer not exists");

        delete s_offers[_tokenId][msg.sender];

        emit OfferCanceled(
            msg.sender,
            _tokenId
        );
    }

    /**
     * @notice Buyer changed his/her mind during cooling-off period.
     */
    function cancelPurchase(uint256 _tokenId)
        external
        nonReentrant
        onlyBuyer(msg.sender, _tokenId)
        listingExists(_tokenId)
    {
        Listing memory listing = s_listings[_tokenId];

        require(listing.buyer == msg.sender, "invalid buyer");
        require(listing.status == Stage.coolingOffPeriod, "house wasn't purchased");
        require(listing.exists, "nonexistent listing");

        address currency = listing.currency;
        uint256 purchasePrice = listing.purchasePrice;

        delete s_listings[_tokenId].buyer;
        delete s_listings[_tokenId].purchasePrice;
        delete s_listings[_tokenId].purchaseTime;

        _sendAmount(msg.sender, currency, purchasePrice);

        emit PurchaseCanceled(
            msg.sender,
            _tokenId,
            Stage.available
        );
    }

    //          xxxxxxxxxxx                xxxxxxxxxxxxx
    // UPDATE ONLY OWNER
    //                          xxxxxxxxxxxxx               xxxxxxxxxxxxx

    function updateMarketplaceOwner(address _newOwner)
        external
        onlyOwner
    {
        address oldOwner = marketplaceOwner;
        marketplaceOwner = _newOwner;
        
        emit MarketplaceOwnerUpdated(
            oldOwner,
            _newOwner
        );
    }

    function updateMarketplaceCommissionFraction(uint96 _newCommissionFraction)
        external
        onlyOwner
    {
        uint256 oldCommissionFraction = marketplaceCommissionFraction;
        marketplaceCommissionFraction = _newCommissionFraction;

        emit MarketplaceCommissionFractionUpdated(
            oldCommissionFraction,
            _newCommissionFraction
        );
    }


    //function validateItemSold(uint256 _tokenId, address _seller, address _buyer) external onlyAuction {}

    //          xxxxxxxxxxx                xxxxxxxxxxxxx
    // PUBLIC
    //                          xxxxxxxxxxxxx               xxxxxxxxxxxxx

    /**
     * @notice Seller verification process.
     */
    function verifySeller(address _seller, uint256 _tokenId) public {
        if (!s_isVerifiedSeller[_tokenId][_seller]) {
            require(isHuman(_seller), "seller can not be a contract");
            require(isPropertyOwner(_seller, _tokenId), "seller must be the property owner");
            require(areSimilarCountries(_seller, _tokenId), "seller is not from the same country as the property");
            require(isMarketplaceApproved(_tokenId), "marketplace must be approved");
            //require(isAuctionApproved(_seller), "auction must be approved");
            s_isVerifiedSeller[_tokenId][_seller] = true;
        }
    }

    /**
     * @notice Buyer verification process.
     */
    function verifyBuyer(address _buyer, uint256 _tokenId) public {
        if (!s_isVerifiedBuyer[_tokenId][_buyer]) {
            require(isHuman(_buyer), "buyer can not be a contract");
            require(!isPropertyOwner(_buyer, _tokenId), "buyer can not be the property owner");
            require(areSimilarCountries(_buyer, _tokenId), "buyer is not from the same country as the property");
            require(isMarketplaceApproved(_tokenId), "marketplace must be approved");
            //require(isAuctionApproved(_buyer), "auction must be approved");
            s_isVerifiedBuyer[_tokenId][_buyer] = true;
        }
    }

    //          xxxxxxxxxxx                xxxxxxxxxxxxx
    // PUBLIC VIEW RETURNS
    //                          xxxxxxxxxxxxx               xxxxxxxxxxxxx

    /**
     * @notice Check whether `_account` and `_tokenId` can be relatered to the similar State Government.
     */
    function areSimilarCountries(address _account, uint256 _tokenId) public view returns (bool) {
        (address transferTaxReceiver, uint256 transferTax) = cadastre().royaltyInfo(_tokenId, uint256(1));
        bool isRegistered = IStateGovernment(transferTaxReceiver).getIsCitizenContractRegistered(_account);
        return isRegistered;
    }

    /**
     * @dev During cooling-off period the buyer can verify himself as the new potential property owner.
     */
    function getBuyer(uint256 _tokenId) public view returns (address) {
        require(isListingExistent(_tokenId), "nonexistent listing");
        return s_listings[_tokenId].buyer;
    }

    function getCoolingOffPeriod(uint256 _tokenId) public view returns (uint256) {
        (address stateGov,) = cadastre().royaltyInfo(_tokenId, uint256(1));
        uint256 coolingOffPeriod = IStateGovernment(stateGov).getCoolingOffPeriod();
        return coolingOffPeriod;
    }

    function getInitialTime(uint256 _tokenId) public view returns (uint256) {
        return s_listings[_tokenId].initialTime;
    }

    function getMarketplaceCommission(uint256 _salePrice) public view returns (uint256) {
        // price = 250000 USDT * (10**18)
        // price * 250 / 10000 = 6250 USDT * (10**18)
        return _salePrice * marketplaceCommissionFraction / 10000;
    }

    function getPropertyCountry(uint256 _tokenId) public view returns (bytes3) {
        (address stateGovernment,) = cadastre().royaltyInfo(_tokenId, uint256(1));
        bytes3 country = IStateGovernment(stateGovernment).getCountry();
        return country;
    }

    function getTransferTax(uint256 _tokenId, uint256 _salePrice) public view returns (uint256) {
        (, uint256 transferTax) = cadastre().royaltyInfo(_tokenId, _salePrice);
        return transferTax;
    }

    function getTransferTaxReceiver(uint256 _tokenId) public view returns (address) {
        (address transferTaxReceiver, uint256 transferTax) = cadastre().royaltyInfo(_tokenId, uint256(1));
        return transferTaxReceiver;
    }

    function isAuctionInAction(uint256 _tokenId) public view returns (bool) {
        return auction().getStartTime(_tokenId) > 0;
    }

    function hasEnoughFunds(address _buyer, address _currency, uint256 _salePrice) public view returns (bool) {
        return IERC20(_currency).balanceOf(_buyer) > _salePrice ? true : false;
    }

    function isHuman(address _account) public view returns (bool) {
        uint256 codeLength;
        assembly {codeLength := extcodesize(_account)}
        return codeLength == 0 && _account != address(0);
    }

    function isAllowedCurrency(address _currency) public view returns (bool) {
        return currencyRegistry().isAllowed(_currency);
    }

    //function isAuctionApproved(address _account) public view returns (bool) {
    //    return cadastre().getApproved(_tokenId) == address(auction());
    //}

    function isListingExistent(uint256 _tokenId) public view returns (bool) {
        return s_listings[_tokenId].exists;
    }
    
    function isMarketplaceApproved(uint256 _tokenId) public view returns (bool) {
        return cadastre().getApproved(_tokenId) == address(this);
    }

    function isOfferExistent(address _offerer, uint256 _tokenId) public view returns (bool) {
        return s_offers[_tokenId][_offerer].exists;
    }

    function isOfferExpired(address _offerer, uint256 _tokenId) public view returns (bool) {
        return s_offers[_tokenId][_offerer].expiry > _getNow();
    }

    function isPropertyOwner(address _account, uint256 _tokenId) public view returns (bool) {
        return cadastre().isOwner(_account, _tokenId);
    }

    function isVerifiedBuyer(address _buyer, uint256 _tokenId) public view returns (bool) {
        return s_isVerifiedBuyer[_tokenId][_buyer];
    }

    function isVerifiedSeller(address _seller, uint256 _tokenId) public view returns (bool) {
        return s_isVerifiedSeller[_tokenId][_seller];
    }

    //          xxxxxxxxxxx                xxxxxxxxxxxxx
    // INTERNAL & PRIVATE
    //                          xxxxxxxxxxxxx               xxxxxxxxxxxxx

    function _getNow() internal view returns (uint256) {
        return block.timestamp;
    }

    /**
     * @notice Buyer pays transfer tax over to his State Government.
     */
    function _sendTransferTax(address _buyer, address _currency, uint256 _tokenId, uint256 _amount) private {
        require(areSimilarCountries(_buyer, _tokenId), "buyer must be from the same country as the property");
        address transferTaxReceiver = getTransferTaxReceiver(_tokenId);
        require(transferTaxReceiver != address(0) || _amount > 0, "invalid info");
        IERC20(_currency).transfer(transferTaxReceiver, _amount);
    }

    function _sendMarketplaceCommission(address _currency, uint256 _commission) private {
        IERC20(_currency).transfer(marketplaceOwner, _commission);
    }

    function _purchaseHouse(address _buyer, address _seller, address _currency, uint256 _tokenId, uint256 _price) private {
        s_listings[_tokenId].status = Stage.coolingOffPeriod;
        IERC20(_currency).transferFrom(_buyer, address(this), _price);
    }

    function _transferNftFrom(address _seller, address _buyer, uint256 _tokenId) private {
        IERC721(cadastre()).transferFrom(_seller, _buyer, _tokenId);
    }

    function checkUpkeep(bytes calldata _checkData)
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory performData) {
        uint256 tokenId = abi.decode(_checkData, (uint256));
        Listing memory listing = s_listings[tokenId];

        upkeepNeeded = block.timestamp > (listing.purchaseTime + listing.coolingOffPeriod);

        return (
            upkeepNeeded,
            abi.encode(tokenId)
        );
    }

    /// @dev Set more powerful requirements into this function workflow!
    function performUpkeep(bytes calldata _performData) external override {
        uint256 tokenId = abi.decode(_performData, (uint256));
        Listing memory listing = s_listings[tokenId];

        require(msg.sender != address(0), "invalid caller");
        require(isListingExistent(tokenId), "invalid listing");
        require(listing.status == Stage.coolingOffPeriod, "invalid status");
        require(block.timestamp > (listing.purchaseTime + listing.coolingOffPeriod), "invalid time");

        s_listings[tokenId].status = Stage.sold;
        s_listings[tokenId].exists = false;

        uint256 marketplaceCommission = getMarketplaceCommission(listing.purchasePrice);
        _sendMarketplaceCommission(listing.currency, marketplaceCommission);

        uint256 transferTax = getTransferTax(tokenId, listing.purchasePrice - marketplaceCommission); 
        _sendTransferTax(listing.buyer, listing.currency, tokenId, transferTax);

        _transferNftFrom(listing.seller, listing.buyer, tokenId);

        uint256 amount = listing.purchasePrice - marketplaceCommission - transferTax;
        _sendAmount(listing.seller, listing.currency, amount);

        emit HouseSold(
            listing.buyer,
            listing.seller,
            listing.tokenId,
            listing.purchaseTime,
            listing.purchasePrice,
            Stage.sold
        );

        _deleteTokenId(tokenId);
        delete s_listings[tokenId];
    }

    function _sendAmount(address _to, address _currency, uint256 _amount) internal {
        require(IERC20(_currency).transfer(_to, _amount), "failed to pay out");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "KeeperBase.sol";
import "KeeperCompatibleInterface.sol";

abstract contract KeeperCompatible is KeeperBase, KeeperCompatibleInterface {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract KeeperBase {
  error OnlySimulatedBackend();

  /**
   * @notice method that allows it to be simulated via eth_call by checking that
   * the sender is the zero address.
   */
  function preventExecution() internal view {
    if (tx.origin != address(0)) {
      revert OnlySimulatedBackend();
    }
  }

  /**
   * @notice modifier that allows it to be simulated via eth_call by checking
   * that the sender is the zero address.
   */
  modifier cannotExecute() {
    preventExecution();
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface KeeperCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
    constructor() {
        _transferOwnership(_msgSender());
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
abstract contract ReentrancyGuard {
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

    constructor() {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
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

// SPDX-Licence-Identifier: MIT

pragma solidity 0.8.13;

import "Ownable.sol";
import "ICitizen.sol";
import "IStateGovernment.sol";
import "ITruhuisAddressRegistry.sol";
import "ITruhuisAuction.sol";
import "ITruhuisCurrencyRegistry.sol";
import "ITruhuisCadastre.sol";
import "ITruhuisMarketplace.sol";

abstract contract TruhuisAddressRegistryAdapter is Ownable {
    ITruhuisAddressRegistry private _addressRegistry;

    function updateAddressRegistry(address _registry) public virtual onlyOwner {
        _updateAddressRegistry(_registry);
    }

    function auction() public view virtual returns (ITruhuisAuction) {
        return ITruhuisAuction(_addressRegistry.auction());
    }

    function addressRegistry() public view virtual returns (ITruhuisAddressRegistry) {
        return _addressRegistry;
    }

    function citizen(address _citizen) public view virtual returns (ICitizen) {
        return ICitizen(_citizen);
    }

    function currencyRegistry() public view virtual returns (ITruhuisCurrencyRegistry) {
        return ITruhuisCurrencyRegistry(_addressRegistry.currencyRegistry());
    }

    function stateGovernment(bytes3 _country) public view virtual returns (IStateGovernment) {
        return IStateGovernment(_addressRegistry.stateGovernment(_country));
    }

    function cadastre() public view virtual returns (ITruhuisCadastre) {
        return ITruhuisCadastre(_addressRegistry.cadastre());
    }

    function marketplace() public view virtual returns (ITruhuisMarketplace) {
        return ITruhuisMarketplace(_addressRegistry.marketplace());
    }

    function _updateAddressRegistry(address _registry) internal virtual {
        _addressRegistry = ITruhuisAddressRegistry(_registry);
    }
}

// SPDX-Licence-Identifier: MIT
pragma solidity 0.8.13;

interface ICitizen {
    function updateFirstName(bytes32 _firstName, uint256 _txIndex) external;

    function updateLastName(bytes32 _lastName, uint256 _txIndex) external;

    function updateBirthtime(uint256 _birthtime, uint256 _txIndex) external;

    function updateBirthDay(uint256 _birthDay, uint256 _txIndex) external;

    function updateBirthMonth(uint256 _birthMonth, uint256 _txIndex) external;

    function updateBirthYear(uint256 _birthYear, uint256 _txIndex) external;

    function updateBirthCity(bytes32 _city, uint256 _txIndex) external;

    function updateBirthState(bytes32 _state, uint256 _txIndex) external;

    function updateBirthCountry(bytes3 _country, uint256 _txIndex) external;

    function updateAccount(address _account, uint256 _txIndex) external;

    function updateBiometricInfoURI(string memory _uri, uint256 _txIndex) external;

    function updatePhotoURI(string memory _uri, uint256 _txIndex) external;

    function updateCitizenship(bytes3 _citizenship, uint256 _txIndex) external;

    function fullName() external view returns (bytes32, bytes32);

    function firstName() external view returns (bytes32);

    function lastName() external view returns (bytes32);

    function birthtime() external view returns (uint256);

    function birthDay() external view returns (uint256);

    function birthMonth() external view returns (uint256);

    function birthYear() external view returns (uint256);

    function birthCity() external view returns (bytes32);

    function birthState() external view returns (bytes32);

    function birthCountry() external view returns (bytes3);

    function account() external view returns (address);

    function biometricInfoURI() external view returns (string memory);

    function photoURI() external view returns (string memory);

    function citizenship() external view returns (bytes3);
}

// SPDX-Licence-Identifier: MIT
pragma solidity 0.8.13;

interface IStateGovernment {
    function registerCitizen(
        bytes32[] memory _name,
        uint24[] memory _dateOfBirth,
        bytes32[] memory _placeOfBirth,
        address[] memory _account,
        string[] memory _uri,
        bytes3[] memory _citizenship
    ) external;
    //function registerCitizen(address _citizenAccount, address _citizenContractAddr) external;
    
    function getAddress() external view returns (address);
    function getCitizenContractAddress(address _citizen) external view returns (address);
    function getCoolingOffPeriod() external view returns (uint256);
    function getCountry() external view returns (bytes3);
    function getIsCitizenContractRegistered(address _citizen) external view returns (bool);
    function getTransferTax() external view returns (uint96);
}

// SPDX-Licence-Identifier: MIT
pragma solidity 0.8.13;

interface ITruhuisAddressRegistry {
    function auction() external view returns (address);
    function citizen(address _citizen) external view returns (address);
    function currencyRegistry() external view returns (address);
    function stateGovernment(bytes3 _country) external view returns (address);
    function cadastre() external view returns (address);
    function marketplace() external view returns (address);
}

// SPDX-Licence-Identifier: MIT
pragma solidity 0.8.13;

interface ITruhuisAuction {
    function getStartTime(uint256 _tokenId) external view returns (uint256);
    function getIsResulted(uint256 _tokenId) external view returns (bool);
    function isAuctionApproved(address _account) external view returns (bool);
}

// SPDX-Licence-Identifier: MIT
pragma solidity 0.8.13;

interface ITruhuisCurrencyRegistry {
    function isAllowed(address _tokenAddr) external view returns (bool);
}

// SPDX-Licence-Identifier: MIT
pragma solidity 0.8.13;

import "IERC721.sol";

interface ITruhuisCadastre is IERC721 {
    function getRealEstateCountry(uint256 _tokenId) external view returns (bytes3);
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address, uint256);
    function isOwner(address _account, uint256 _tokenId) external view returns (bool);
}

// SPDX-Licence-Identifier: MIT
pragma solidity 0.8.13;

interface ITruhuisMarketplace {
    function verifySeller(address _seller, uint256 _tokenId) external;
    function verifyBuyer(address _buyer, uint256 _tokenId) external;
    function getMarketplaceCommission(uint256 _salePrice) external view returns (uint256);

    function getRoyaltyCommission(uint256 _tokenId, uint256 _salePrice) external view returns (uint256);
    function getRoyaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address, uint256);
    function getRoyaltyReceiver(uint256 _tokenId) external view returns (address);

    function hasEnoughFunds(address _account, address _currency, uint256 _amount) external view returns (bool);

    function isHuman(address _account) external view returns (bool);

    function isVerifiedBuyer(address _buyer, uint256 _tokenId) external view returns (bool);

    function isVerifiedSeller(address _seller, uint256 _tokenId) external view returns (bool);

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

/**
 * @title Observes all major changes in reference to a tokenId in marketplace.
 */
contract TokenIdObserver {

    /// @dev tokenIds that are currently for listed
    uint256[] private s_forSaleTokenIds;
    /// @dev Free index of zero value (0) in s_forSaleTokenIds array
    uint256[] private s_freeIndexes;

    /// @dev tokenId => tokenId's index in s_forSaleTokenIds array
    mapping(uint256 => uint256) private _tokenIdIndexes;

    /// @notice Fetch all currently listed houses.
    function fetchListedHouses() public view returns (uint256[] memory) {
        return s_forSaleTokenIds;
    }

    /// @dev Get tokenId index assigned in s_forSaleTokenIds.
    function getTokenIdIndex(uint256 _tokenId) public view returns (uint256) {
        return _tokenIdIndexes[_tokenId];
    }

    /// @dev Called when house is listed.
    function _storeTokenId(uint256 _tokenId) internal {
        uint256 freeIndex = _retrieveFreeIndex();

        if (freeIndex == 0 && s_freeIndexes.length == 0) {
            uint256 nextIndex = s_forSaleTokenIds.length;
            s_forSaleTokenIds.push(_tokenId);
            _tokenIdIndexes[_tokenId] = nextIndex;
        } else {
            s_forSaleTokenIds[freeIndex] = _tokenId;
            _tokenIdIndexes[_tokenId] = freeIndex;

            s_freeIndexes.pop();
        }
    }

    /// @dev Called when house is sold or canceled.
    function _deleteTokenId(uint256 _tokenId) internal {
        uint256 index = _tokenIdIndexes[_tokenId];
        s_freeIndexes.push(index);

        delete s_forSaleTokenIds[index];
        delete _tokenIdIndexes[_tokenId];
    }

    function _retrieveFreeIndex() private view returns (uint256) {
        uint256[] memory freeIndexes = s_freeIndexes;

        if (freeIndexes.length != 0) {
            uint256 lastIndex = freeIndexes[freeIndexes.length - 1];
            return lastIndex;
        } else {
            return 0;
        }
    }
}