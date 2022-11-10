// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract Marketplace {
    event Listed(address indexed collection, address indexed seller, uint256 nftId, uint256 price);
    event UpdateListing(address indexed collection, address indexed seller, uint256 nftId, uint256 newPrice);
    event CancelListing(address indexed collection, address indexed seller, uint256 nftId);
    event Bought(address indexed collection, address indexed buyer, uint256 nftId, uint256 price);

    error Unauthorized();
    error Locked();
    error AlreadyListed();
    error InvalidCollection();
    error NotListed();
    error InvalidPayment();
    error IsZeroAddress();

    struct Collection {
        bool listed;
        uint8 royalties;
        address collection;
    }

    struct Listing {
        bool active;
        address seller;
        uint256 price;
    }

    bool private lock;
    uint8 public percentageFee;
    address payable public owner;

    // Listed collections on marketplace - contract addresses
    address[] private collections;
    // collection contract address -> Collection
    mapping(address => Collection) private listedCollections;
    // collection contract address -> nftId -> Listing
    mapping(address => mapping(uint256 => Listing)) private listings;

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert Unauthorized();
        }
        _;
    }

    modifier locked() {
        if (lock) {
            revert Locked();
        }
        lock = true;
        _;
        lock = false;
    }

    constructor(uint8 fee) {
        owner = payable(msg.sender);
        percentageFee = fee;
    }

    /* ---------- EXTERNAL ----------  */

    /**
     * @notice Set marketplace fee
     *
     * @param fee The new marketplace fee
     */
    function setFee(uint8 fee) external onlyOwner {
        percentageFee = fee;
    }

    /**
     * @notice Withdraw marketplace funds.
     */
    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}('');
        require(success);
    }

    /**
     * @notice Transfer ownership of the contract.
     *
     * @param newOwner The address of the new owner
     */
    function transferOwnership(address newOwner) external onlyOwner {
        _assertIsNotZeroAddress(newOwner);

        owner = payable(newOwner);
    }

    /**
     * @notice Updates `collection` creator royalties
     *
     * @param collection The contract address of the collection
     * @param royalties The new creator royalties percentage
     */
    function updateCollectionRoyalties(address collection, uint8 royalties) external onlyOwner {
        _assertIsValidCollection(collection);

        listedCollections[collection].royalties = royalties;
    }

    /**
     * @notice Allows to list a collection in marketplace
     *
     * @param collection The contract address of the collection
     * @param creator The address of the collection's creator
     * @param royalties The creator royalties percentage
     */
    function listInMarketplace(
        address collection,
        address creator,
        uint8 royalties
    ) external onlyOwner {
        _assertIsTheCollectionOwner(collection, creator);
        _assertIsNotListed(collection);

        listedCollections[collection] = Collection({listed: true, royalties: royalties, collection: collection});
        collections.push(collection);
    }

    /**
     * @notice Gets marketplace listed collections.
     *
     * @return address[] the list of collections
     */
    function getCollections() external view returns (address[] memory) {
        return collections;
    }

    /**
     * @notice Gets marketplace listed collections.
     *
     * @param collection The contract address of the collection
     *
     * @return uint8 the collection royalties percentage
     */
    function getCollectionRoyalties(address collection) external view returns (uint8) {
        _assertIsValidCollection(collection);

        return listedCollections[collection].royalties;
    }

    /**
     * @notice Allow an nft owner to list his nft
     *
     * @param collection The contract address of the collection
     * @param nftId The NFT ID
     * @param price The listing price
     */
    function list(
        address collection,
        uint256 nftId,
        uint256 price
    ) external locked {
        _assertIsValidCollection(collection);
        _assertIsNftOwner(collection, nftId);
        _assertNftIsNotListed(collection, nftId);

        _transferNftToMarketplace(collection, nftId);
        listings[collection][nftId] = Listing({active: true, seller: msg.sender, price: price});

        emit Listed(collection, msg.sender, nftId, price);
    }

    /**
     * @notice Allow an nft owner to update his listing
     *
     * @param collection The contract address of the collection
     * @param nftId The NFT ID
     * @param newPrice The listing price
     */
    function updateListing(
        address collection,
        uint256 nftId,
        uint256 newPrice
    ) external locked {
        _assertIsValidCollection(collection);
        _assertIsNftOwner(collection, nftId);
        _assertNftIsListed(collection, nftId);

        listings[collection][nftId].price = newPrice;

        emit UpdateListing(collection, msg.sender, nftId, newPrice);
    }

    /**
     * @notice Allow an nft owner to cancel the listing of his nft
     *
     * @param collection The contract address of the collection
     * @param nftId The NFT ID
     */
    function cancelListing(address collection, uint256 nftId) external locked {
        _assertIsValidCollection(collection);
        _assertIsNftOwner(collection, nftId);
        _assertNftIsListed(collection, nftId);

        delete listings[collection][nftId];
        _transferNftToUser(collection, nftId);

        emit CancelListing(collection, msg.sender, nftId);
    }

    /**
     * @notice Allow an nft owner to list his nft
     *
     * @param collection The contract address of the collection
     * @param nftId The NFT ID
     */
    function buy(address collection, uint256 nftId) external payable locked {
        _assertIsValidCollection(collection);
        _assertNftIsListed(collection, nftId);
        _assertIsNotSeller(collection, nftId);
        _assertPaymentIsCorrect(collection, nftId);

        Listing memory listing = listings[collection][nftId];
        delete listings[collection][nftId];
        _transferNftToUser(collection, nftId);

        uint256 creatorFee = _calculateFee(listing.price, listedCollections[collection].royalties);
        uint256 marketplaceFee = _calculateFee(listing.price, percentageFee);

        (bool sellerPayout, ) = payable(listing.seller).call{value: listing.price - creatorFee - marketplaceFee}('');
        require(sellerPayout);

        (bool creatorPayout, ) = payable(_getCollectionOwner(collection)).call{value: creatorFee}('');
        require(creatorPayout);

        emit Bought(collection, msg.sender, nftId, listing.price);
    }

    /* ---------- PRIVATE ---------- */

    /**
     * @notice Transfer `nftId` from `msg.sender` to marketplace
     * @dev It needs to be approved before call
     *
     * @param collection The contract address of the collection
     * @param nftId The NFT ID
     */
    function _transferNftToMarketplace(address collection, uint256 nftId) private {
        (bool success, ) = collection.call(
            abi.encodeWithSignature('transferFrom(address,address,uint256)', msg.sender, address(this), nftId)
        );
        require(success);
    }

    /**
     * @notice Transfer `nftId` from marketplace to `msg.sender`
     *
     * @param collection The contract address of the collection
     * @param nftId The NFT ID
     */
    function _transferNftToUser(address collection, uint256 nftId) private {
        (bool success, ) = collection.call(
            abi.encodeWithSignature('safeTransferFrom(address,address,uint256)', address(this), msg.sender, nftId)
        );
        require(success);
    }

    /**
     * @notice Calculate the total amount of fee for `price`
     *
     * @param price the price of the nft
     * @param fee the fee
     *
     * @return uint256 the fee value
     */
    function _calculateFee(uint256 price, uint8 fee) private pure returns (uint256) {
        return (price * fee) / 100;
    }

    /**
     * @notice Get the owner of a collection
     *
     * @param collection The contract address of the collection
     *
     * @return address the collection owner
     */
    function _getCollectionOwner(address collection) private returns (address) {
        (bool success, bytes memory result) = collection.call(abi.encodeWithSignature('owner()'));
        require(success);

        return abi.decode(result, (address));
    }

    /* ---------- PRIVATE - ASSERTIONS ---------- */

    /**
     * @notice Assert a contract owner
     * @dev Throws unless `msg.sender` is the `collection` owner
     *
     * @param collection The contract address of the collection
     * @param creator The address of the collection's creator
     */
    function _assertIsTheCollectionOwner(address collection, address creator) private {
        address result = _getCollectionOwner(collection);

        if (result == creator) {
            return;
        }

        revert Unauthorized();
    }

    /**
     * @notice Assert that a collection is still not listed in the marketplace
     * @dev Throws unless `collection` is not listed
     *
     * @param collection The contract address of the collection
     */
    function _assertIsNotListed(address collection) private view {
        if (!listedCollections[collection].listed) {
            return;
        }

        revert AlreadyListed();
    }

    /**
     * @notice Assert that a collection is valid - listed in the marketplace
     * @dev Throws unless `collection` is listed
     *
     * @param collection The contract address of the collection
     */
    function _assertIsValidCollection(address collection) private view {
        if (listedCollections[collection].listed) {
            return;
        }

        revert InvalidCollection();
    }

    /**
     * @notice Assert that `msg.sender` is the owner of `nftId` from `collecton`
     * @dev Throws unless `msg.sender` is the `nftId` owner
     *
     * @param collection The contract address of the collection
     * @param nftId The NFT ID
     */
    function _assertIsNftOwner(address collection, uint256 nftId) private {
        if (listings[collection][nftId].seller == msg.sender) {
            return;
        }

        (bool success, bytes memory result) = collection.call(abi.encodeWithSignature('ownerOf(uint256)', nftId));
        require(success);

        if (abi.decode(result, (address)) == msg.sender) {
            return;
        }

        revert Unauthorized();
    }

    /**
     * @notice Assert that `msg.sender` is not the seller of `nftId` from `collecton`
     * @dev Throws unless `msg.sender` is not the `nftId` owner
     *
     * @param collection The contract address of the collection
     * @param nftId The NFT ID
     */
    function _assertIsNotSeller(address collection, uint256 nftId) private view {
        if (listings[collection][nftId].seller != msg.sender) {
            return;
        }

        revert Unauthorized();
    }

    /**
     * @notice Assert that `nftId` is not already listed
     * @dev Throws unless `nftId` is not listed
     *
     * @param collection The contract address of the collection
     * @param nftId The NFT ID
     */
    function _assertNftIsNotListed(address collection, uint256 nftId) private view {
        if (!listings[collection][nftId].active) {
            return;
        }

        revert AlreadyListed();
    }

    /**
     * @notice Assert that `nftId` is listed
     * @dev Throws unless `nftId` is listed
     *
     * @param collection The contract address of the collection
     * @param nftId The NFT ID
     */
    function _assertNftIsListed(address collection, uint256 nftId) private view {
        if (listings[collection][nftId].active) {
            return;
        }

        revert NotListed();
    }

    /**
     * @notice Assert that `msg.value` is equal to the listing price
     * @dev Throws unless `msg.value` is equal to listing price
     *
     * @param collection The contract address of the collection
     * @param nftId The NFT ID
     */
    function _assertPaymentIsCorrect(address collection, uint256 nftId) private view {
        if (listings[collection][nftId].price == msg.value) {
            return;
        }

        revert InvalidPayment();
    }

    /**
     * @notice Assert that `target` is not the zero address
     * @dev Throws unless `target` is not the zero address
     *
     * @param target The address to verify
     */
    function _assertIsNotZeroAddress(address target) private pure {
        if (target != address(0)) {
            return;
        }

        revert IsZeroAddress();
    }
}