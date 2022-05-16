// SPDX-License-Identifier: MIT

// ########     ###    ######## ##    ##    ########   #######  ##     ## #### ##    ##  ######   
// ##     ##   ## ##        ##  ###   ##    ##     ## ##     ##  ##   ##   ##  ###   ## ##    ##  
// ##     ##  ##   ##      ##   ####  ##    ##     ## ##     ##   ## ##    ##  ####  ## ##        
// ##     ## ##     ##    ##    ## ## ##    ########  ##     ##    ###     ##  ## ## ## ##   #### 
// ##     ## #########   ##     ##  ####    ##     ## ##     ##   ## ##    ##  ##  #### ##    ##  
// ##     ## ##     ##  ##      ##   ###    ##     ## ##     ##  ##   ##   ##  ##   ### ##    ##  
// ########  ##     ## ######## ##    ##    ########   #######  ##     ## #### ##    ##  ######     
//                                                                         Powered by Quandefi

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./MarketplaceListingHelper.sol";

contract MarketplaceListing is Ownable,  MarketplaceListingHelper {
    using Counters for Counters.Counter;
    using EnumerableSet for EnumerableSet.UintSet;

    // Counters for listings & offers
    Counters.Counter private _listingId;
    Counters.Counter private _offerId;

        
    // Tracking active listings & offers
    EnumerableSet.UintSet private openListings;
    EnumerableSet.UintSet private openOffers;


    // LISTING MAPPINGS
    mapping(address => EnumerableSet.UintSet) private addrToActiveListings;
    mapping(uint256 => uint256) private tokenIdToListingId;
    mapping(uint256 => Listing) private listingIdToListing;

    // OFFER MAPPINGS
    mapping(uint256 => Offer) private offerIdToOffer;
    mapping(uint256 => EnumerableSet.UintSet) private tokenIdToActiveOffers;
    mapping(address => EnumerableSet.UintSet) private addrToActiveOffers;

    constructor(address _nftAddress, address _usdcAddress, uint256 _royalty, address _royaltyAddress) {
        nftAddress = _nftAddress;
        usdcAddress = _usdcAddress;
        royalty = _royalty;
        royaltyAddress = _royaltyAddress;
    }

    // Offer functions

     /**
     * @dev Create new offer on an NFT token.
     * @param tokenId - ID of the token to place offer on
     * @param price - Price to bid on the specified token
     * @param duration - Duration of offer
     */
    function createOffer(uint256 tokenId, uint256 price, uint256 duration) public { 
        require(getBalanceForERC20(msg.sender) >= price , "You don't have enough balance to make this offer.");
        require(getAllowanceForERC20(msg.sender) >= price , "Please approve tokens before transferring");
        //add check to ensure offerer != token owner
        // ensure token Id specified is valid
        
        _offerId.increment();

        Offer memory offer = Offer({
            offerId: _offerId.current(),
            offerAmount: price,
            tokenId: tokenId,
            offerTime: block.timestamp,
            expiration: block.timestamp + duration,
            creator: msg.sender,
            seller: address(0),
            state: State.OPEN
        });
        
        // Store the market
        _addOfferStorage(offer);

        emit OfferCreated(
            nftAddress,
            tokenId,
            _offerId.current(),
            price
        );
    }

    /**
     * @dev Cancel existing offer on an NFT token. Must be creator of OPEN offer.
     * @param offerId - ID of the offter to cancel
     */
    function cancelOffer(uint256 offerId) public { 
        require(offerIdToOffer[offerId].creator == msg.sender, "You did not create this offer!");
        require(offerIdToOffer[offerId].state == State.OPEN,"Offer already ended." );

        // Make the removal
        offerIdToOffer[offerId].state = State.CANCELLED;
        _removeOfferStorage(offerId);

        // Emit the event
        emit OfferCancelled(offerId);
    }

     /**
     * @dev Accept existing offer on an NFT token. Must be owner of token.
     * @param offerId - ID of the offter to accept
     */
    function acceptOffer(uint256 offerId) public { 
        Offer memory offer = offerIdToOffer[offerId];

        require(IERC721(nftAddress).ownerOf(offer.tokenId) == msg.sender, "You must own the token");
        require(IERC721(nftAddress).isApprovedForAll(msg.sender, address(this)),"Must approve this contract for transfers.");

        offerIdToOffer[offerId].state = State.COMPLETED;
        offerIdToOffer[offerId].seller = msg.sender;
        _removeOfferStorage(offerId);

        uint256 fee = (offer.offerAmount * royalty) / 100000000;

        // Payment
        IERC20(usdcAddress).transferFrom(
            offer.creator,
            msg.sender,
            royalty > 0 ? offer.offerAmount - fee : offer.offerAmount
        );

        // Royalty
        if(royalty > 0){
            IERC20(usdcAddress).transferFrom(
                offer.creator,
                royaltyAddress,
                fee
            );
        }

        emit OfferAccepted(offerId, offer.offerAmount, offer.tokenId);
    }

    /**
     * @dev Cancel all offers for user address
     * @param _addr - Address to cancel all offers for
     */
    function cancelAllUserOffers(address _addr) public { 
        require(_addr == msg.sender, "You did not create this offer!");

        uint256[] memory userOfferIds = addrToActiveOffers[_addr].values();

        for(uint  i = 0; i < userOfferIds.length; i++){
             offerIdToOffer[userOfferIds[i]].state = State.CANCELLED;
            _removeOfferStorage(userOfferIds[i]);
            emit OfferCancelled(userOfferIds[i]);
        }
   
    }

    /**
     * @dev Remove offer from storage
     * @param offerId - Offer ID to remove 
    */
    function _removeOfferStorage(uint256 offerId) internal {     
        addrToActiveOffers[msg.sender].remove(offerId);
        tokenIdToActiveOffers[offerIdToOffer[offerId].tokenId].remove(offerId);
        openOffers.remove(offerId);
    }

    /**
     * @dev Add offer to storage
     * @param offer - Offer to add
    */
    function _addOfferStorage(Offer memory offer) internal {
        offerIdToOffer[offer.offerId] = offer;
        addrToActiveOffers[msg.sender].add(offer.offerId);
        tokenIdToActiveOffers[offer.tokenId].add(offer.offerId);
        openOffers.add(offer.offerId);
    }

    // Listing Functions

     /**
     * @dev Create new listing for NFT token. Token must be approved prior to creating listing.
     * @param tokenId - ID of the token to create listing for.
     * @param price - Listing price of token.
     * @param duration - Duration of listing.
     */
    function createListing(uint256 tokenId, uint256 price, uint256 duration) public { 
        IERC721 token = IERC721(nftAddress);
        require(token.ownerOf(tokenId) == msg.sender, "You must own the token");
        require(IERC721(nftAddress).isApprovedForAll(msg.sender, address(this)),"Must approve this contract for transfers.");

        if(listingIdToListing[tokenIdToListingId[tokenId]].state == State.OPEN && listingIdToListing[tokenIdToListingId[tokenId]].seller != token.ownerOf(tokenId)){
            //Existing listing is previous owner
             // Make the removal
            listingIdToListing[tokenIdToListingId[tokenId]].state = State.CANCELLED;
            _removeListingStorage(listingIdToListing[tokenIdToListingId[tokenId]].listingId);

            // Emit the event
            emit ListingCancelled(listingIdToListing[tokenIdToListingId[tokenId]].listingId);
        }

        require(
            listingIdToListing[tokenIdToListingId[tokenId]].state != State.OPEN,
            "First cancel the active market."
        );

        _listingId.increment();

        Listing memory listing = Listing({
            buyer: address(0),
            seller: msg.sender,
            createdTime: block.timestamp,
            expiration: block.timestamp + duration,
            listingId: _listingId.current(),
            buyTime: 0,
            tokenId: tokenId,
            price: price,
            state: State.OPEN
        });
        
        // Store the market
        _addListingStorage(listing);

        emit ListingCreated(
            nftAddress,
            tokenId,
            _listingId.current(),
            price
        );
    }

     /**
     * @dev Buy open listing.
     * @param listingId - ID of the listing to purchase
     */
    function buyFromListing(uint256 listingId) public {
        Listing memory listing = listingIdToListing[listingId];
         require(
            listing.state == State.OPEN,
            "Listing is not open for purchase."
        ); 

        require(IERC721(nftAddress).ownerOf(listing.tokenId) == listing.seller, "Seller no longer owns token.");
        require(getAllowanceForERC20(msg.sender) >= listing.price , "Please approve tokens before transferring");
        
        // Update market object
        listing.state = State.COMPLETED;
        listing.buyTime = block.timestamp;
        listing.buyer = msg.sender;

        listingIdToListing[listingId] = listing; 

        // Remove active
        listingIdToListing[listingId].state = State.COMPLETED;
        _removeListingStorage(listingId);

        // Transfer the NFT
        IERC721(nftAddress).safeTransferFrom(
            listing.seller,
            msg.sender,
            listing.tokenId
        );

        
        uint256 fee = (listing.price * royalty) / 100000000;

        // Payment
        IERC20(usdcAddress).transferFrom(
            msg.sender,
            listingIdToListing[listingId].seller,
            royalty > 0 ? listingIdToListing[listingId].price - fee : listingIdToListing[listingId].price
        );

        // Royalty
        if(royalty > 0){
            IERC20(usdcAddress).transferFrom(
                msg.sender,
                royaltyAddress,
                fee
            );
        }

        emit ListingSold(msg.sender, listingId);
    }

    /**
    * @dev Cancel open listing. Must be creator of listing.
    * @param listingId - ID of the listing to cancel
    */
    function cancelListing(uint256 listingId)
        external
        onlyNftOwner(
            nftAddress,
            listingIdToListing[listingId].tokenId
        ){
        require(
            listingIdToListing[listingId].state == State.OPEN,
            "Listing already ended."
        );

        // Make the removal
        listingIdToListing[listingId].state = State.CANCELLED;
        _removeListingStorage(listingId);

        // Emit the event
        emit ListingCancelled(listingId);
    }

    /**
     * @dev Remove listing from storage
     * @param listingId - ID of the listing to remove
     */
    function _removeListingStorage(uint256 listingId) internal {
        addrToActiveListings[msg.sender].remove(listingId);
        delete tokenIdToListingId[listingIdToListing[listingId].tokenId];
        openListings.remove(listingId);
    }

    /**
     * @dev Add listing to storage
     * @param listing - Listing to add
    */
    function _addListingStorage(Listing memory listing) internal {
        listingIdToListing[listing.listingId] = listing;
        addrToActiveListings[msg.sender].add(listing.listingId);
        tokenIdToListingId[listing.tokenId] = listing.listingId;
        openListings.add(listing.listingId);
    }

    // Get functions
    function getAllowanceForERC20(address _address) public view returns (uint256) {
        return IERC20(usdcAddress).allowance(_address, address(this));
    }

    function getBalanceForERC20(address _address) public view returns (uint256) {
        return IERC20(usdcAddress).balanceOf(_address);
    }

    function getActiveListings() external view returns (Listing[] memory) {
        uint256[] memory activeListingIds = openListings.values();
        Listing[] memory activeListings = new Listing[](openListings.values().length);

        for(uint i = 0; i < activeListingIds.length; i++){
            activeListings[i] = listingIdToListing[activeListingIds[i]];
        }

        return activeListings;
    }

    function getListingIdsByUser(address userAddress) external view returns (uint256[] memory){
        return addrToActiveListings[userAddress].values();
    }    

    function getListingsByUser(address userAddress) external view returns (Listing[] memory){
        
        uint256[] memory userActiveListings = addrToActiveListings[userAddress].values();
        Listing[] memory userListings = new Listing[](userActiveListings.length);

        for(uint i = 0; i < userActiveListings.length; i++){
            userListings[i] = listingIdToListing[userActiveListings[i]];
        }

        return userListings;
    }    

    function getActiveListingByTokenId(uint256 _tokenId) external view returns (Listing memory){
        Listing memory listing = listingIdToListing[tokenIdToListingId[_tokenId]];
        return listing;
    }

    // Use listing ID and return offers array
    function getOffersByTokenId(uint256 _tokenId) external view returns (Offer[] memory){
        uint256[] memory tokenIdToActiveOfferIds = tokenIdToActiveOffers[_tokenId].values();
        Offer[] memory userOffers = new Offer[](tokenIdToActiveOffers[_tokenId].values().length);

        for(uint i = 0; i < tokenIdToActiveOfferIds.length; i++){
            userOffers[i] = offerIdToOffer[tokenIdToActiveOfferIds[i]];
        }

        return userOffers;

    }


    function getOffersByUser(address userAddress) external view returns (Offer[] memory){
        uint256[] memory userActiveOffers = addrToActiveOffers[userAddress].values();
        Offer[] memory userOffers = new Offer[](userActiveOffers.length);

        for(uint i = 0; i < userActiveOffers.length; i++){
            userOffers[i] = offerIdToOffer[userActiveOffers[i]];
        }

        return userOffers;
    }    

    function getActiveOffers() external view returns (Offer[] memory){
        uint256[] memory activeOfferIds = openOffers.values();
        Offer[] memory activeOffers = new Offer[](openOffers.values().length);

        for(uint i = 0; i < activeOfferIds.length; i++){
            activeOffers[i] = offerIdToOffer[activeOfferIds[i]];
        }

        return activeOffers;
    }    

    // Set functions
    function setUSDCaddress(address _address) public onlyOwner {
        usdcAddress = _address;
    }

    function setRoyalties(uint256 _royalty) public onlyOwner {
        royalty = _royalty;
    }

    function setNFTaddress(address _address) public onlyOwner {
        nftAddress = _address;
    }
}

// SPDX-License-Identifier: MIT

// ########     ###    ######## ##    ##    ########   #######  ##     ## #### ##    ##  ######   
// ##     ##   ## ##        ##  ###   ##    ##     ## ##     ##  ##   ##   ##  ###   ## ##    ##  
// ##     ##  ##   ##      ##   ####  ##    ##     ## ##     ##   ## ##    ##  ####  ## ##        
// ##     ## ##     ##    ##    ## ## ##    ########  ##     ##    ###     ##  ## ## ## ##   #### 
// ##     ## #########   ##     ##  ####    ##     ## ##     ##   ## ##    ##  ##  #### ##    ##  
// ##     ## ##     ##  ##      ##   ###    ##     ## ##     ##  ##   ##   ##  ##   ### ##    ##  
// ########  ##     ## ######## ##    ##    ########   #######  ##     ## #### ##    ##  ######     
//                                                                         Powered by Quandefi

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import '@openzeppelin/contracts/utils/Address.sol';
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract MarketplaceListingHelper {
    using Address for address;


    // STORE
    address internal usdcAddress;
    address internal nftAddress;
    address internal royaltyAddress;
    uint256 internal royalty;
 
    // ENUMS
    enum State {
        CANCELLED,
        COMPLETED,
        OPEN
    }

    struct Listing {
        address buyer;
        address seller;
        uint256 createdTime;
        uint256 expiration;
        uint256 listingId;
        uint256 buyTime;
        uint256 tokenId;
        uint256 price;
        State state;
    }

    struct Offer {
        uint256 offerId;
        uint256 offerAmount;
        uint256 tokenId;
        uint256 offerTime;
        uint256 expiration;
        address creator;     
        address seller;   
        State state;
    }

    // EVENTS
    event ListingCreated(
        address indexed nftAddress, 
        uint256 indexed tokenId,
        uint256 listingId,
        uint256 price
    );
    event ListingSold(
        address indexed buyer,
         uint256 listingId
    );
    event ListingCancelled(
        uint256 listingId
    );

    event OfferCreated(
        address indexed from,
        uint256 indexed tokenId,
        uint256  _offerId,
        uint256 indexed amount
        
    );

    event OfferCancelled(uint256 indexed offerId);

    event OfferAccepted(
        uint256 indexed offerId,
        uint256 indexed amount,
        uint256 indexed tokenId
    );

    // Extend listing, if bid placed
    // with under this amount remaining
    uint256 internal bidTimeExt = 600;
    
    modifier onlyNftOwner(address _nftAddress, uint256 nftId) {
        // Get the owner
        address nftOwner = IERC721(_nftAddress).ownerOf(nftId);

        // Make the check
        require(nftOwner == msg.sender, "Must be Nft owner.");

        //  Cont.
        _;
    }

    
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
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
library Counters {
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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