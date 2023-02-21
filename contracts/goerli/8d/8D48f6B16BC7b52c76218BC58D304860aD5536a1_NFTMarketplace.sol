// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract NFTMarketplace is Pausable, ReentrancyGuard {
    address public owner;
    uint256 public platformFee; // 250 ~ 2.5%
    uint256 public maxRoyaltyFee = 750; // 750 ~ 7.5%

    IERC20 public USDT;

    struct Collection {
        uint256 collectionId;
        address creator;
        uint256 royaltyFee; // 750 ~ 7.5%
        address walletForRoyalty;
        mapping(address => mapping(uint256 => NFTListing)) nftsListed;
    }

    struct NFTListing {
        uint256 listingId;
        address NFTContractAddress;
        bool NFTStandard; // true for ERC721, false for ERC1155
        uint256 TokenId;
        uint256 QuantityOnSale;
        uint256 PricePerNFT;
        uint256 listingExpireTime;
    }

    struct Offer {
        uint256 offerId;
        address NFTContractAddress;
        uint256 collectionId;
        uint256 TokenId;
        uint256 quantityOfferedForPurchase;
        uint256 pricePerNFT;
        uint256 offerExpireTime;
        address offerCreator;
        bool isActive;
        uint256 lockedValue; // value locked into the contract
    }

    mapping(uint256 => Collection) public collections;
    mapping(uint256 => Offer) public offers;
    mapping(uint256 => mapping(uint256 => uint256)) private _offersByListing;
    // Mapping of user addresses
    // mapping(address => uint256[]) private collectionIds;
    // mapping(address => uint256[]) private offerIds;
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
        bool NFTStandard,
        uint256 TokenId,
        uint256 QuantityOnSale,
        uint256 PricePerNFT,
        uint256 listingExpireTime
    );
    event NFTDelisted(
        uint256 collectionId,
        uint256 listingId,
        address NFTContractAddress,
        bool NFTStandard,
        uint256 TokenId,
        uint256 QuantityOnSale,
        uint256 PricePerNFT,
        uint256 listingExpireTime
    );
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
        uint256 quantityOfferedForPurchase,
        uint256 pricePerNFT,
        uint256 offerExpireTime
    );
    event OfferCancelled(uint256 offerId);
    event OfferAccepted(uint256 offerId, address buyer);
    event NFTBought(uint256 listingId, address buyer);
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

    // All getter funcions
    /**
    ----------------------------------------------------------------------------
    **/

    function getOffersByUser(address _user)
        external
        view
        returns (uint256[] memory)
    {
        uint256 numOffers = 0;
        for (uint256 i = 0; i < offerIdCounter; i++) {
            if (offers[i].offerCreator == _user && offers[i].isActive) {
                numOffers++;
            }
        }
        uint256[] memory result = new uint256[](numOffers);
        uint256 index = 0;
        for (uint256 i = 0; i < offerIdCounter; i++) {
            if (offers[i].offerCreator == _user && offers[i].isActive) {
                result[index] = i;
                index++;
            }
        }
        return result;
    }

    function getCollectionsByUser(address _user)
        external
        view
        returns (uint256[] memory)
    {
        uint256 numCollections = 0;
        for (uint256 i = 0; i < collectionIdCounter; i++) {
            if (collections[i].creator == _user) {
                numCollections++;
            }
        }
        uint256[] memory result = new uint256[](numCollections);
        uint256 index = 0;
        for (uint256 i = 0; i < collectionIdCounter; i++) {
            if (collections[i].creator == _user) {
                result[index] = i;
                index++;
            }
        }
        return result;
    }

    function getNFTsListedByUser(uint256 _collectionId, address _user)
        external
        view
        returns (NFTListing[] memory)
    {
        uint256 numListings = 0;
        for (uint256 i = 0; i < offerIdCounter; i++) {
            if (
                collections[_collectionId]
                .nftsListed[_user][i].NFTContractAddress != address(0)
            ) {
                numListings++;
            }
        }
        NFTListing[] memory result = new NFTListing[](numListings);
        uint256 index = 0;
        for (uint256 i = 0; i < offerIdCounter; i++) {
            NFTListing storage listing = collections[_collectionId].nftsListed[
                _user
            ][i];
            if (listing.NFTContractAddress != address(0)) {
                result[index] = listing;
                index++;
            }
        }
        return result;
    }

    function getAllNFTsListedByUser(address _user)
        external
        view
        returns (NFTListing[] memory)
    {
        uint256 numListings = 0;
        for (uint256 i = 0; i < collectionIdCounter; i++) {
            for (uint256 j = 0; j < offerIdCounter; j++) {
                if (
                    collections[i].nftsListed[_user][j].NFTContractAddress !=
                    address(0)
                ) {
                    numListings++;
                }
            }
        }
        NFTListing[] memory result = new NFTListing[](numListings);
        uint256 index = 0;
        for (uint256 i = 0; i < collectionIdCounter; i++) {
            for (uint256 j = 0; j < offerIdCounter; j++) {
                NFTListing storage listing = collections[i].nftsListed[_user][
                    j
                ];
                if (listing.NFTContractAddress != address(0)) {
                    result[index] = listing;
                    index++;
                }
            }
        }
        return result;
    }

    function getOffersForNFT(uint256 collectionId, uint256 TokenId)
        public
        view
        returns (Offer[] memory)
    {
        uint256 numOffers = 0;

        // First, count the number of offers made on this NFT listing
        for (uint256 i = 0; i < offerIdCounter; i++) {
            Offer memory offer = offers[i];
            if (
                offer.isActive &&
                offer.collectionId == collectionId &&
                offer.TokenId == TokenId
            ) {
                numOffers++;
            }
        }

        // Create an array to hold the offers
        Offer[] memory result = new Offer[](numOffers);

        // Fill in the array with the offers
        uint256 j = 0;
        for (uint256 i = 0; i < offerIdCounter; i++) {
            Offer memory offer = offers[i];
            if (
                offer.isActive &&
                offer.collectionId == collectionId &&
                offer.TokenId == TokenId
            ) {
                result[j] = offer;
                j++;
            }
        }

        return result;
    }

    function getOffersByListing(uint256 listingId) public view returns (Offer[] memory) {
        uint256 numOffers = 0;
        for (uint256 i = 1; i <= offerIdCounter; i++) {
            Offer storage offer = offers[i];
            if (offer.isActive && _offersByListing[listingId][i] > 0) {
                numOffers++;
            }
        }
        Offer[] memory result = new Offer[](numOffers);
        uint256 index = 0;
        for (uint256 i = 1; i <= offerIdCounter; i++) {
            Offer storage offer = offers[i];
            if (offer.isActive && _offersByListing[listingId][i] > 0) {
                result[index] = offer;
                index++;
            }
        }
        return result;
    }

    // All getter funcions
    /**
    ----------------------------------------------------------------------------
    **/

    function addCollection(uint256 royaltyFee, address walletForRoyalty) external {
        require(royaltyFee <= maxRoyaltyFee, "Royalty fee is too high");
        require(walletForRoyalty != address(0), "Wallet address cannot be zero");

        collectionIdCounter++;

        Collection storage newCollection = collections[collectionIdCounter];
        newCollection.collectionId = collectionIdCounter;
        newCollection.creator = msg.sender;
        newCollection.royaltyFee = royaltyFee;
        newCollection.walletForRoyalty = walletForRoyalty;

        emit CollectionCreated(collectionIdCounter, royaltyFee, walletForRoyalty);
    }

    function editCollection(
    uint256 collectionId,
    uint256 royaltyFee,
    address walletForRoyalty
    ) external {
        Collection storage collection = collections[collectionId];
        require(msg.sender == collection.creator, "Only the collection owner can edit it");
        require(royaltyFee <= maxRoyaltyFee, "Royalty fee is too high");
        require(walletForRoyalty != address(0), "Wallet address cannot be zero");

        collection.royaltyFee = royaltyFee;
        collection.walletForRoyalty = walletForRoyalty;

        emit CollectionCreated(collectionIdCounter, royaltyFee, walletForRoyalty);
    }

    function listNFT(
    uint256 _collectionId,
    address _NFTContractAddress,
    bool _NFTStandard,
    uint256 _TokenId,
    uint256 _QuantityOnSale,
    uint256 _PricePerNFT,
    uint256 _listingExpireTime
    ) external whenNotPaused {
        Collection storage collection = collections[_collectionId];
        require(_collectionId != 0, "Invalid Collection ID");
        require(msg.sender == collection.creator, "Only the collection owner can list NFT");
        require(_TokenId != 0, "Invalid Token ID");
        require(_QuantityOnSale > 0, "Invalid Quantity");
        require(_PricePerNFT > 0, "Invalid Price");
        require(_listingExpireTime > block.timestamp, "Invalid Expiry Time");

        require(collection.collectionId != 0, "Collection not found");
        require(
            collection.nftsListed[msg.sender][_TokenId].listingId == 0,
            "Token already listed"
        );

        // Check if user has approved the marketplace contract to spend the NFT
        if (_NFTStandard) {
            require(
                IERC721(_NFTContractAddress).getApproved(_TokenId) == address(this),
                "Marketplace not approved to spend ERC721"
            );
        } else {
            require(
                IERC1155(_NFTContractAddress).isApprovedForAll(
                    msg.sender,
                    address(this)
                ),
                "Marketplace not approved to spend ERC1155"
            );
        }

        NFTListing memory listing = NFTListing({
            listingId: ++listingIdCounter,
            NFTContractAddress: _NFTContractAddress,
            NFTStandard: _NFTStandard,
            TokenId: _TokenId,
            QuantityOnSale: _QuantityOnSale,
            PricePerNFT: _PricePerNFT,
            listingExpireTime: _listingExpireTime
        });

        collection.nftsListed[msg.sender][_TokenId] = listing;
        emit NFTListed(
            _collectionId,
            listing.listingId,
            _NFTContractAddress,
            _NFTStandard,
            _TokenId,
            _QuantityOnSale,
            _PricePerNFT,
            _listingExpireTime
        );
    }

    function cancelListing(uint256 _collectionId, uint256 _listingId) external nonReentrant {
        Collection storage collection = collections[_collectionId];
        NFTListing storage listing = collection.nftsListed[msg.sender][_listingId];
        require(listing.PricePerNFT > 0, "The listing does not exist");
        require(listing.QuantityOnSale > 0, "The listing has already been cancelled");
        require(listing.listingExpireTime < block.timestamp, "The listing has not expired yet");
        
        // Mark the listing as cancelled
        listing.QuantityOnSale = 0;

        emit NFTDelisted(
            _collectionId,
            _listingId,
            listing.NFTContractAddress,
            listing.NFTStandard,
            listing.TokenId,
            0, // Set QuantityOnSale to 0
            listing.PricePerNFT,
            listing.listingExpireTime
        );
    }

    function createOffer(
    uint256 _collectionId,
    address _NFTContractAddress,
    uint256 _TokenId,
    uint256 _quantityOfferedForPurchase,
    uint256 _pricePerNFT,
    uint256 _offerExpireTime
    ) external nonReentrant whenNotPaused {
        require(_quantityOfferedForPurchase > 0, "Quantity must be greater than 0");
        require(_pricePerNFT > 0, "Price must be greater than 0");

        Collection storage collection = collections[_collectionId];
        require(collection.royaltyFee <= maxRoyaltyFee, "Invalid royalty fee");
        require(_NFTContractAddress != address(0), "Invalid contract address");
        require(collection.nftsListed[msg.sender][_TokenId].listingId == 0, "Cannot create offer on own listing");

        // Calculate and lock the value to be transferred on offer acceptance
        uint256 lockedValue = _quantityOfferedForPurchase * _pricePerNFT;
        require(USDT.allowance(msg.sender, address(this)) >= lockedValue, "Insufficient allowance");
        require(USDT.transferFrom(msg.sender, address(this), lockedValue), "Transfer failed");

        // Create and store the new offer
        offerIdCounter++;
        Offer storage offer = offers[offerIdCounter];
        offer.offerId = offerIdCounter;
        offer.NFTContractAddress = _NFTContractAddress;
        offer.collectionId = _collectionId;
        offer.TokenId = _TokenId;
        offer.quantityOfferedForPurchase = _quantityOfferedForPurchase;
        offer.pricePerNFT = _pricePerNFT;
        offer.offerExpireTime = _offerExpireTime;
        offer.offerCreator = msg.sender;
        offer.isActive = true;
        offer.lockedValue = lockedValue;

        // Update mappings for easy lookup
        _offersByListing[_collectionId][_TokenId] = offer.offerId;

        emit OfferCreated(offer.offerId, offer.collectionId, offer.TokenId, offer.quantityOfferedForPurchase, offer.pricePerNFT, offer.offerExpireTime);
    }

    function cancelOffer(uint256 _offerId) external nonReentrant {
        Offer storage offer = offers[_offerId];
        require(offer.offerCreator == msg.sender, "Only the offer creator can cancel the offer");
        require(offer.isActive, "The offer has already been cancelled or accepted");
        
        // Mark offer as cancelled and unlock the locked value
        offer.isActive = false;
        uint256 amountToRefund = offer.lockedValue;
        offer.lockedValue = 0;
        USDT.transfer(msg.sender, amountToRefund);

        emit OfferCancelled(_offerId);
    }

    function acceptOffer(uint256 _offerId) external {
        Offer storage offer = offers[_offerId];
        require(offer.isActive, "Offer is not active");
        require(offer.offerExpireTime >= block.timestamp, "Offer has expired");
        address nftOwner = IERC721(offer.NFTContractAddress).ownerOf(
            offer.TokenId
        );
        require(msg.sender == nftOwner, "Only NFT owner can accept an offer");

        Collection storage collection = collections[offer.collectionId];
        NFTListing storage listing = collection.nftsListed[offer.offerCreator][
            offer.TokenId
        ];

        require(
            listing.QuantityOnSale >= offer.quantityOfferedForPurchase,
            "Not enough quantity available for sale"
        );

        uint256 totalPrice = offer.pricePerNFT *
            (offer.quantityOfferedForPurchase);
        uint256 royaltyAmnt = (totalPrice * collection.royaltyFee) / 10000;
        uint256 platformFeeAmnt = (totalPrice * platformFee) / 10000;
        uint256 sellerAmnt = totalPrice - royaltyAmnt - platformFeeAmnt;

        // Transfer the payment to the seller
        USDT.transfer(msg.sender, sellerAmnt);

        // Transfer NFT from seller to buyer
        if (offer.quantityOfferedForPurchase == 1) {
            IERC721(offer.NFTContractAddress).safeTransferFrom(
                nftOwner,
                offer.offerCreator,
                offer.TokenId
            );
        } else {
            IERC1155(offer.NFTContractAddress).safeTransferFrom(
                nftOwner,
                offer.offerCreator,
                offer.TokenId,
                offer.quantityOfferedForPurchase,
                ""
            );
        }

        // Update the quantities
        listing.QuantityOnSale -= offer.quantityOfferedForPurchase;
        offer.quantityOfferedForPurchase = 0;
        offer.isActive = false;

        // Transfer the platform fee to the owner
        if (platformFee > 0) {
            USDT.transfer(owner, platformFeeAmnt);
        }

        // Transfer the royalty fee to the collection owner
        if (collection.royaltyFee > 0) {
            USDT.transfer(collection.walletForRoyalty, royaltyAmnt);
        }

        emit OfferAccepted(_offerId, msg.sender);
    }

    function buyNFT(
        uint256 _collectionId,
        uint256 _listingId,
        uint256 _quantity
    ) external payable {
        Collection storage collection = collections[_collectionId];
        NFTListing storage listing = collections[_collectionId].nftsListed[
            msg.sender
        ][_listingId];

        require(
            listing.NFTContractAddress != address(0),
            "Invalid NFT listing"
        );
        require(
            listing.listingExpireTime >= block.timestamp,
            "Listing has expired"
        );

        uint256 totalPrice = listing.PricePerNFT * _quantity;
        require(
            USDT.balanceOf(msg.sender) == totalPrice,
            "Insufficient payment amount"
        );
        require(USDT.transferFrom(msg.sender, address(this), totalPrice), "Transfer Failed");

        uint256 royaltyAmnt = (totalPrice * collection.royaltyFee) / 10000;
        uint256 platformFeeAmnt = (totalPrice * platformFee) / 10000;
        uint256 sellerAmnt = totalPrice - royaltyAmnt - platformFeeAmnt;

        // Transfer the platform fee to the owner
        if (platformFee > 0) {
            USDT.transfer(owner, platformFeeAmnt);
        }

        // Transfer the royalty fee to the collection owner
        if (collection.royaltyFee > 0) {
            USDT.transfer(collection.walletForRoyalty, royaltyAmnt);
        }

        address nftOwner = IERC721(listing.NFTContractAddress).ownerOf(
            listing.TokenId
        );

        // Transfer seller amount to seller
        USDT.transfer(nftOwner, sellerAmnt);

        // Transfer NFT from seller to buyer
        if (_quantity == 1) {
            IERC721(listing.NFTContractAddress).safeTransferFrom(
                nftOwner,
                msg.sender,
                listing.TokenId
            );
        } else {
            IERC1155(listing.NFTContractAddress).safeTransferFrom(
                nftOwner,
                msg.sender,
                listing.TokenId,
                _quantity,
                ""
            );
        }

        listing.QuantityOnSale -= _quantity;

        emit NFTBought(_listingId, msg.sender);
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