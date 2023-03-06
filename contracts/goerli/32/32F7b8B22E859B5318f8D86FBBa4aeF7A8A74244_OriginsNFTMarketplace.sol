// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract OriginsNFTMarketplace is Pausable, ReentrancyGuard {
    address public owner;
    uint256 public platformFee; // 250 ~ 2.5%
    uint256 public maxRoyaltyFee = 750; // 750 ~ 7.5%

    IERC20 public USDT;

    struct Collection {
        uint256 collectionId;
        address creator;
        uint256 royaltyFee; // 750 ~ 7.5%
        address walletForRoyalty;
        mapping(uint256 => uint256[]) NFTListingsByCollection;
    }

    struct NFTListing {
        uint256 collectionId;
        uint256 listingId;
        address NFTContractAddress;
        address seller;
        uint256 TokenId;
        uint256 QuantityOnSale;
        uint256 PricePerNFT;
        uint256 listingExpireTime;
        uint256 listingStatus; // 0 = inactive, 1 = active, 2 = sold
        uint256[] offers;
    }

    struct Offer {
        uint256 offerId;
        address NFTContractAddress;
        uint256 listingId;
        uint256 TokenId;
        uint256 quantityOfferedForPurchase;
        uint256 pricePerNFT;
        uint256 offerExpireTime;
        address offerCreator;
        bool isActive;
        uint256 lockedValue; // value locked into the contract
    }

    mapping(uint256 => Collection) public collections;
    mapping(uint256 => NFTListing) public NFTListings;
    mapping(uint256 => Offer) public offers;
    mapping(uint256 => mapping(uint256 => uint256)) private _offersByListing;
    mapping(uint256 => uint256[]) public NFTListingsByCollection;
    uint256 public collectionIdCounter;
    uint256 public listingIdCounter;
    uint256 public offerIdCounter;

    event CollectionCreated(
        uint256 collectionId,
        uint256 royaltyFee,
        address walletForRoyalty
    );

    event CollectionEdited(
        uint256 collectionId,
        uint256 royaltyFee,
        address walletForRoyalty
    );
    event NFTListed(
        uint256 collectionId,
        uint256 listingId,
        address NFTContractAddress,
        uint256 TokenId,
        uint256 QuantityOnSale,
        uint256 PricePerNFT,
        uint256 listingExpireTime
    );
    event ListingUpdated(
        uint256 listingId,
        address NFTContractAddress,
        uint256 TokenId,
        uint256 listingExpireTime
    );
    event ListingStatusUpdated(uint256 lisitngId, uint256 statusCode);
    event OfferCreated(
        uint256 offerId,
        uint256 collectionId,
        uint256 TokenId,
        uint256 quantityOfferedForPurchase,
        uint256 pricePerNFT,
        uint256 offerExpireTime
    );
    event OfferModified(
        uint256 offerId,
        uint256 pricePerNFT,
        uint256 offerExpireTime
    );
    event OfferCancelled(uint256 offerId);
    event OfferAccepted(uint256 offerId, address buyer);
    event NFTBought(uint256 listingId, uint256 quantity, address buyer);
    event TokenRecovery(address indexed tokenAddress, uint256 indexed amount);
    event NFTRecovery(
        address indexed collectionAddress,
        uint256 indexed tokenId
    );
    event Pause(string reason);
    event Unpause(string reason);

    constructor(uint256 _platformFee, IERC20 _USDT) {
        owner = msg.sender;
        platformFee = _platformFee;
        USDT = _USDT;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    /* COllections */

    function getCollectionsByOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 count = 0;

        // Loop through all collections to count the number owned by the specified user
        for (uint256 i = 1; i <= collectionIdCounter; i++) {
            if (collections[i].creator == _owner) {
                count++;
            }
        }

        // Create an array of the correct size to store the collection IDs
        uint256[] memory collectionIds = new uint256[](count);

        // Loop through all collections to populate the array with the IDs owned by the specified user
        uint256 index = 0;
        for (uint256 i = 1; i <= collectionIdCounter; i++) {
            if (collections[i].creator == _owner) {
                collectionIds[index] = i;
                index++;
            }
        }

        return collectionIds;
    }

    function addCollection(uint256 _royaltyFee, address _walletForRoyalty)
        external
        onlyOwner
    {
        require(_royaltyFee <= maxRoyaltyFee, "Royalty fee too high");
        require(
            _walletForRoyalty != address(0),
            "Invalid royalty wallet address"
        );

        collectionIdCounter++;
        Collection storage newCollection = collections[collectionIdCounter];
        newCollection.collectionId = collectionIdCounter;
        newCollection.creator = msg.sender;
        newCollection.royaltyFee = _royaltyFee;
        newCollection.walletForRoyalty = _walletForRoyalty;

        emit CollectionCreated(
            collectionIdCounter,
            _royaltyFee,
            _walletForRoyalty
        );
    }

    function editCollection(
        uint256 _collectionId,
        uint256 _royaltyFee,
        address _walletForRoyalty
    ) external whenNotPaused nonReentrant {
        Collection storage collection = collections[_collectionId];

        require(
            collection.creator == msg.sender,
            "Only the collection creator can edit the collection"
        );
        require(
            _royaltyFee <= maxRoyaltyFee,
            "Royalty fee exceeds maximum allowed"
        );
        require(
            _walletForRoyalty != address(0),
            "Invalid royalty wallet address"
        );

        collection.royaltyFee = _royaltyFee;
        collection.walletForRoyalty = _walletForRoyalty;

        emit CollectionEdited(_collectionId, _royaltyFee, _walletForRoyalty);
    }

    /* NFT listing functions */

    function getNFTListingsBySeller(address _seller)
        public
        view
        returns (uint256[] memory)
    {
        uint256 count = 0;

        // Loop through all NFT listings to count the number listed by the specified user
        for (uint256 i = 1; i <= listingIdCounter; i++) {
            if (NFTListings[i].seller == _seller) {
                count++;
            }
        }

        // Create an array of the correct size to store the NFT listing IDs
        uint256[] memory listingIds = new uint256[](count);

        // Loop through all NFT listings to populate the array with the IDs listed by the specified user
        uint256 index = 0;
        for (uint256 i = 1; i <= listingIdCounter; i++) {
            if (NFTListings[i].seller == _seller) {
                listingIds[index] = i;
                index++;
            }
        }

        return listingIds;
    }

    function listNFT(
        uint256 collectionId,
        address NFTContractAddress,
        uint256 TokenId,
        uint256 QuantityOnSale,
        uint256 PricePerNFT,
        uint256 listingExpireTime
    ) external whenNotPaused nonReentrant {
        Collection storage collection = collections[collectionId];
        require(
            collection.creator == msg.sender,
            "Only the collection creator can list NFTs"
        );
        require(
            NFTContractAddress != address(0),
            "Invalid NFT contract address"
        );
        require(
            IERC165(NFTContractAddress).supportsInterface(0xd9b67a26), // ERC1155Receiver
            "NFT contract must support ERC1155 standard"
        );
        require(
            QuantityOnSale > 0,
            "Quantity on sale should be greater than zero"
        );
        require(PricePerNFT > 0, "Price per NFT should be greater than zero");
        require(
            listingExpireTime > block.timestamp,
            "Listing expire time should be in the future"
        );
        require(
            IERC1155(NFTContractAddress).balanceOf(msg.sender, TokenId) >=
                QuantityOnSale,
            "Seller does not own enough NFTs"
        );
        require(
            IERC1155(NFTContractAddress).isApprovedForAll(
                msg.sender,
                address(this)
            ),
            "Marketplace contract is not approved to transfer NFTs"
        );

        listingIdCounter++;
        NFTListing storage newListing = NFTListings[listingIdCounter];
        newListing.listingId = listingIdCounter;
        newListing.NFTContractAddress = NFTContractAddress;
        newListing.seller = msg.sender;
        newListing.TokenId = TokenId;
        newListing.QuantityOnSale = QuantityOnSale;
        newListing.PricePerNFT = PricePerNFT;
        newListing.listingExpireTime = listingExpireTime;
        newListing.listingStatus = 1; // active

        collection.NFTListingsByCollection[TokenId].push(listingIdCounter);
        NFTListingsByCollection[collectionId].push(listingIdCounter);
        _offersByListing[listingIdCounter][0] = 0;

        emit NFTListed(
            collectionId,
            listingIdCounter,
            NFTContractAddress,
            TokenId,
            QuantityOnSale,
            PricePerNFT,
            listingExpireTime
        );
    }

    function extendListingTime(uint256 _listingId, uint256 _listingExpireTime)
        external
        whenNotPaused
        nonReentrant
    {
        NFTListing storage listing = NFTListings[_listingId];

        require(
            msg.sender == listing.seller,
            "Only the seller can update the listing"
        );
        require(
            listing.listingStatus == 1,
            "Listing is not active and cannot be updated"
        );
        require(
            _listingExpireTime > block.timestamp &&
                _listingExpireTime > listing.listingExpireTime,
            "Invalid expire time"
        );

        listing.listingExpireTime = _listingExpireTime;

        emit ListingUpdated(
            _listingId,
            listing.NFTContractAddress,
            listing.TokenId,
            _listingExpireTime
        );
    }

    function updateListingStatus(uint256 _listingId, uint256 _listingStatus)
        external
    {
        NFTListing storage listing = NFTListings[_listingId];
        // Check that the caller is the owner of the listing
        require(
            msg.sender == listing.seller,
            "Only the owner of the listing can update the status"
        );
        // check that listing is not being set to sold status
        require(_listingStatus < 2, "Wrong status code");

        // Check that the listing is not already in the requested status
        require(
            listing.listingStatus != _listingStatus,
            "The listing is already in the requested status"
        );

        // Update the listing status
        listing.listingStatus = _listingStatus;

        // Emit an event to indicate that the status has been updated
        emit ListingStatusUpdated(_listingId, _listingStatus);
    }

    /* Offers */

    function getOffersByOfferCreator(address _offerCreator)
        public
        view
        returns (Offer[] memory)
    {
        uint256 count = 0;

        // Loop through all offers to count the number made by the specified user
        for (uint256 i = 1; i <= offerIdCounter; i++) {
            if (offers[i].offerCreator == _offerCreator) {
                count++;
            }
        }

        // Create an array of the correct size to store the offers made by the specified user
        Offer[] memory offersByUser = new Offer[](count);

        // Loop through all offers to populate the array with the offers made by the specified user
        uint256 index = 0;
        for (uint256 i = 1; i <= offerIdCounter; i++) {
            if (offers[i].offerCreator == _offerCreator) {
                offersByUser[index] = offers[i];
                index++;
            }
        }

        return offersByUser;
    }

    function getOffersByListing(uint256 _listingId)
        public
        view
        returns (Offer[] memory)
    {
        uint256 count = 0;

        // Loop through all offers to count the number made on the specified listing
        for (uint256 i = 0; i < NFTListings[_listingId].offers.length; i++) {
            if (
                offers[NFTListings[_listingId].offers[i]].listingId ==
                _listingId
            ) {
                count++;
            }
        }

        // Create an array of the correct size to store the offers made on the specified listing
        Offer[] memory offersOnListing = new Offer[](count);

        // Loop through all offers to populate the array with the offers made on the specified listing
        uint256 index = 0;
        for (uint256 i = 0; i < NFTListings[_listingId].offers.length; i++) {
            uint256 offerId = NFTListings[_listingId].offers[i];
            if (offers[offerId].listingId == _listingId) {
                offersOnListing[index] = offers[offerId];
                index++;
            }
        }

        return offersOnListing;
    }

    function createOffer(
        uint256 _listingId,
        uint256 _quantityOfferedForPurchase,
        uint256 _pricePerNFT,
        uint256 _offerExpireTime
    ) external whenNotPaused nonReentrant {
        NFTListing storage listing = NFTListings[_listingId];
        require(listing.listingStatus == 1, "Listing not active");
        require(
            _quantityOfferedForPurchase > 0 &&
                _quantityOfferedForPurchase <= listing.QuantityOnSale,
            "Invalid quantity of NFTs offered for purchase"
        );
        require(_pricePerNFT > 0, "Price per NFT must be greater than 0");
        require(
            _offerExpireTime > block.timestamp,
            "Offer expiration time must be in the future"
        );
        require(
            listing.NFTContractAddress != address(0),
            "Invalid NFT contract address"
        );
        require(
            IERC1155(listing.NFTContractAddress).isApprovedForAll(
                listing.seller,
                address(this)
            ),
            "Contract not approved to transfer NFTs"
        );

        uint256 offerAmount = _quantityOfferedForPurchase * _pricePerNFT;
        if (offerAmount > 0) {
            require(
                USDT.transferFrom(msg.sender, address(this), offerAmount),
                "Transfer to contract failed!"
            );
        }

        uint256 offerId = ++offerIdCounter;
        Offer storage offer = offers[offerId];
        offer.offerId = offerId;
        offer.NFTContractAddress = listing.NFTContractAddress;
        offer.listingId = _listingId;
        offer.TokenId = listing.TokenId;
        offer.quantityOfferedForPurchase = _quantityOfferedForPurchase;
        offer.pricePerNFT = _pricePerNFT;
        offer.offerExpireTime = _offerExpireTime;
        offer.offerCreator = msg.sender;
        offer.isActive = true;
        offer.lockedValue = offerAmount;

        _offersByListing[_listingId][offerId] = offerId;

        emit OfferCreated(
            offerId,
            _listingId,
            listing.TokenId,
            _quantityOfferedForPurchase,
            _pricePerNFT,
            _offerExpireTime
        );
    }

    // Function to cancel an offer
    function cancelOffer(uint256 offerId) public {
        // Verify that the offer exists
        require(
            offers[offerId].offerCreator != address(0),
            "Offer does not exist"
        );
        // Verify that the offer has not been cancelled or completed
        require(
            offers[offerId].isActive,
            "Offer has already been cancelled or completed"
        );
        // Verify that the caller is the seller of the offer
        require(
            msg.sender == offers[offerId].offerCreator,
            "Only the seller can cancel the offer"
        );

        // Update the offer to indicate that it has been cancelled
        offers[offerId].isActive = false;

        require(
            USDT.balanceOf(address(this)) >= offers[offerId].lockedValue,
            "Contract doesn't have enough balance for refund!"
        );
        require(
            USDT.transfer(msg.sender, offers[offerId].lockedValue),
            "Refund failed!"
        );

        // Emit an event to notify the frontend of the cancellation
        emit OfferCancelled(offerId);
    }

    // Function to modify an offer
    function modifyOffer(
        uint256 offerId,
        uint256 newPricePerNFT,
        uint256 newExpireTime
    ) public {
        // Verify that the offer exists
        require(
            offers[offerId].offerCreator != address(0),
            "Offer does not exist"
        );
        // Verify that the offer has not been cancelled or completed
        require(
            offers[offerId].isActive,
            "Offer has already been cancelled or completed"
        );
        // Verify that the caller is the seller of the offer
        require(
            msg.sender == offers[offerId].offerCreator,
            "Only the seller can modify the offer"
        );

        // Update the offer with the new price
        offers[offerId].pricePerNFT = newPricePerNFT;
        offers[offerId].offerExpireTime = newExpireTime;

        // Emit an event to notify the frontend of the modification
        emit OfferModified(offerId, newPricePerNFT, newExpireTime);
    }

    function acceptOffer(uint256 _offerId) public nonReentrant {
        Offer storage offer = offers[_offerId];
        NFTListing storage listing = NFTListings[offer.listingId];

        require(msg.sender == listing.seller, "Only seller can accept offers");
        require(offer.isActive == true, "Offer must be active");
        require(offer.offerExpireTime >= block.timestamp, "Offer has expired");

        // Transfer USDT from buyer to seller
        require(
            USDT.transferFrom(
                offer.offerCreator,
                listing.seller,
                offer.lockedValue
            ),
            "Failed to transfer USDT"
        );

        // Transfer NFT from seller to buyer
        IERC1155 NFTContract = IERC1155(listing.NFTContractAddress);
        NFTContract.safeTransferFrom(
            listing.seller,
            offer.offerCreator,
            listing.TokenId,
            offer.quantityOfferedForPurchase,
            ""
        );

        // Mark listing as sold
        listing.listingStatus = 2;

        // Mark offer as inactive
        offer.isActive = false;

        // Distribute fees
        uint256 platformFeeValue = (offer.lockedValue * platformFee) / 10000;
        uint256 royaltyFeeValue = (offer.lockedValue *
            collections[listing.collectionId].royaltyFee) / 10000;
        uint256 sellerValue = offer.lockedValue -
            platformFeeValue -
            royaltyFeeValue;

        // Transfer platform fee to marketplace owner
        require(
            USDT.transfer(owner, platformFeeValue),
            "Failed to transfer platform fee"
        );

        // Transfer royalty fee to collection creator
        require(
            USDT.transfer(
                collections[listing.collectionId].walletForRoyalty,
                royaltyFeeValue
            ),
            "Failed to transfer royalty fee"
        );

        // Transfer sale amount to seller
        require(
            USDT.transfer(listing.seller, sellerValue),
            "Failed to transfer sale amount"
        );

        // Remove offer from listing's offer list
        uint256[] storage offerList = listing.offers;
        uint256 i;
        for (i = 0; i < offerList.length; i++) {
            if (offerList[i] == _offerId) {
                break;
            }
        }
        for (uint256 j = i; j < offerList.length - 1; j++) {
            offerList[j] = offerList[j + 1];
        }
        offerList.pop();

        // Emit event
        emit OfferAccepted(_offerId, offer.offerCreator);
    }

    /* buy NFT */

    function buyNFT(uint256 _listingId, uint256 _quantity) public nonReentrant {
        NFTListing storage listing = NFTListings[_listingId];

        require(listing.listingStatus == 1, "Listing is not active");
        require(
            listing.listingExpireTime >= block.timestamp,
            "Listing has expired"
        );
        require(
            _quantity > 0 && _quantity <= listing.QuantityOnSale,
            "Invalid quantity"
        );

        // Calculate the total purchase amount
        uint256 purchaseAmount = listing.PricePerNFT * _quantity;

        // Transfer USDT from buyer to contract
        require(
            USDT.transferFrom(msg.sender, address(this), purchaseAmount),
            "Failed to transfer USDT"
        );

        // Transfer NFT from seller to buyer
        IERC1155 NFTContract = IERC1155(listing.NFTContractAddress);
        NFTContract.safeTransferFrom(
            listing.seller,
            msg.sender,
            listing.TokenId,
            _quantity,
            ""
        );

        // Mark listing as sold if all tokens are sold
        if (_quantity == listing.QuantityOnSale) {
            listing.listingStatus = 2;
        } else {
            listing.QuantityOnSale -= _quantity;
        }

        // Distribute fees
        uint256 platformFeeValue = (purchaseAmount * platformFee) / 10000;
        uint256 royaltyFeeValue = (purchaseAmount *
            collections[listing.collectionId].royaltyFee) / 10000;
        uint256 sellerValue = purchaseAmount -
            platformFeeValue -
            royaltyFeeValue;

        // Transfer platform fee to marketplace owner
        require(
            USDT.transfer(owner, platformFeeValue),
            "Failed to transfer platform fee"
        );

        // Transfer royalty fee to collection creator
        require(
            USDT.transfer(
                collections[listing.collectionId].walletForRoyalty,
                royaltyFeeValue
            ),
            "Failed to transfer royalty fee"
        );

        // Transfer sale amount to seller
        require(
            USDT.transfer(listing.seller, sellerValue),
            "Failed to transfer sale amount"
        );

        // Emit event
        emit NFTBought(_listingId, _quantity, msg.sender);
    }

    /**
        Admin functions
        -------------------------------------------------------------------
    **/

    /** 
        @notice recover any ERC20 token sent to the contract
        @param _token address of the token to recover
        @param _amount amount of the token to recover
    */
    function recoverToken(address _token, uint256 _amount)
        external
        whenPaused
        onlyOwner
    {
        IERC20(_token).transfer(address(msg.sender), _amount);
        emit TokenRecovery(_token, _amount);
    }

    /** 
        @notice recover any ERC721 token sent to the contract
        @param _NFTContract of the collection to recover
        @param _tokenId uint256 of the tokenId to recover
    */
    function recoverNFT(address _NFTContract, uint256 _tokenId)
        external
        whenPaused
        onlyOwner
    {
        IERC721 nft = IERC721(_NFTContract);
        nft.safeTransferFrom(address(this), address(msg.sender), _tokenId);
        emit NFTRecovery(_NFTContract, _tokenId);
    }

    /** 
        @notice recover any ERC721 token sent to the contract
        @param _NFTContract of the collection to recover
        @param _tokenId uint256 of the tokenId to recover
    */
    function recover1155NFT(
        address _NFTContract,
        uint256 _tokenId,
        uint256 _quantity
    ) external whenPaused onlyOwner {
        IERC1155 nft = IERC1155(_NFTContract);
        nft.safeTransferFrom(
            address(this),
            address(msg.sender),
            _tokenId,
            _quantity,
            ""
        );
        emit NFTRecovery(_NFTContract, _tokenId);
    }

    /** 
        @notice pause the marketplace
        @param _reason string of the reason for pausing the marketplace
    */
    function pauseMarketplace(string calldata _reason)
        external
        whenNotPaused
        onlyOwner
    {
        _pause();
        emit Pause(_reason);
    }

    /** 
        @notice unpause the marketplace
        @param _reason string of the reason for unpausing the marketplace
    */
    function unpauseMarketplace(string calldata _reason)
        external
        whenPaused
        onlyOwner
    {
        _unpause();
        emit Unpause(_reason);
    }

    /**
        Admin functions
        -------------------------------------------------------------------
    **/
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
    constructor() {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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