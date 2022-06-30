// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.1;

import "./IBuyAndSellDecentraLandRealEstate.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract BuyAndSellDecentraLandRealEstate is IBuyAndSellDecentraLandRealEstate, AccessControl {

    // For managing the listings in the contract
    bytes32 public constant LISTING_MANAGER = keccak256("LISTING_MANAGER");

    // For changing any of the global configuration and defaults, as well as access to sensitive functions
    bytes32 public constant CONFIG_MANAGER = keccak256("CONFIG_MANAGER");

    // safer types
    using Address for address;

    // for incrementing the ids of each listing sequentially
    using Counters for Counters.Counter;
    Counters.Counter private _listingIds;

    // determines how long a listing can remain for
    uint256 private _maxSaleDuration;

    // the current address set for receiving royalties
    address payable private _royaltyReceiver;

    // mappings for tracking the tokenIds to listings and the listing struct themselves
    mapping(uint256 => uint256) private _tokenIdToListing;
    mapping(uint256 => Listing) private listingsMap;

    // values kept for referring to LANDERC721 and the default payment currency
    IERC721 public LAND;
    address public DEFAULT_ERC20;

    // events for changing the configuration
    event MaxSaleDurationUpdated(uint256 maxSaleDuration);
    event RoyaltyReceiverUpdated(address royaltyReceiver);
    event LANDUpdated(address landAddress);
    event DEFAULT_ERC20Updated(address defaultErc20Address);

    constructor(address landAddress, address defaultErc20Address, address payable royaltyReceiver, uint256 maxSaleDuration) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(CONFIG_MANAGER, msg.sender);
        _setupRole(LISTING_MANAGER, msg.sender);
        _setRoleAdmin(CONFIG_MANAGER, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(LISTING_MANAGER, CONFIG_MANAGER);
        setLAND(landAddress);
        setDEFAULT_ERC20(defaultErc20Address);
        setRoyaltyReceiver(royaltyReceiver);
        setMaxSaleDuration(maxSaleDuration);
    }

    /**
     * @dev See {IBuyAndSellDecentraLandRealEstate-createListing}
     */
    function createListing(uint256 publicDate, uint256 endTime, uint256 buyItNowPrice, uint256 idFromNft, uint256 royaltyPercentage, uint256 floorPrice, address paymentCurrency) external override onlyRole(LISTING_MANAGER) returns (uint256 listingId) {

        // grab the owner of the land check the owner has approved this contract
        address owner = LAND.ownerOf(idFromNft);
        require(
            owner == address(this) ||
            LAND.getApproved(idFromNft) == address(this) ||
            LAND.isApprovedForAll(owner, address(this)),
            "Not approved for token"
        );

        // check that the listing's public date is in the future. We do not allow for listings to be made in the past.
        require(publicDate >= block.timestamp, "public date cannot be in the past");

        // require that the ending date is in the future and not the same as the public date resulting in a listing that
        // was never active.
        require(endTime > block.timestamp && endTime > publicDate, "Invalid endtime");

        // check the royalty percentage is at least the base
        require(royaltyPercentage < 10000, "Invalid royalties");

        // require the floor price is below the buyItNowPrice if it is set. Floor price is not required, unless a buyItNowPrice
        // is passed in
        require((buyItNowPrice == 0 && floorPrice > 0) || floorPrice < buyItNowPrice, "Invalid price");

        // create reference to the sale and check if it already exists
        Listing memory existingSale = listingsMap[_tokenIdToListing[idFromNft]];
        require(
            existingSale.id == 0 || //Has no sale for nft ever
            existingSale.end < block.timestamp, //Listing expired
            "Already active listing for this NFT"
        );

        // create a new listing id
        _listingIds.increment();
        listingId = _listingIds.current();
        require(listingsMap[listingId].id == 0, "Invalid Listing id");

        // check the listing doesn't exceed the maximum listing time
        uint256 _maxEndTime = publicDate + _maxSaleDuration;
        require(endTime < _maxEndTime, "End time exceeds allowed sale duration");

        // create the listing
        Listing memory _listing = Listing({
        status: ListingStatus.OPEN_FOR_SALE,
        id: listingId,
        publicDate: publicDate,
        end: endTime,
        buyItNowPrice: buyItNowPrice,
        royaltyPercentage: royaltyPercentage,
        floorPrice: floorPrice,
        idFromNft: idFromNft,
        owner: payable(owner),
        paymentCurrency: paymentCurrency
        });

        // add listing and the id to appropriate maps
        listingsMap[listingId] = _listing;
        _tokenIdToListing[idFromNft] = listingId;

        // emit event for third party services to track
        emit ListingCreated(
            _listing.id,
            _listing.publicDate,
            _listing.end,
            _listing.buyItNowPrice,
            _listing.royaltyPercentage,
            _listing.floorPrice,
            _listing.owner,
            _listing.idFromNft,
            _listing.paymentCurrency
        );

        // for tracking outside of events, return an id
        return _listing.id;
    }

    /**
     * @dev See {IBuyAndSellDecentraLandRealEstate-buyListing}
     */
    function buyListing(uint256 listingId) external payable override {

        // grab the listing from the map
        Listing memory _listing = listingsMap[listingId];

        // get the price for later calculations
        uint256 price = _listing.buyItNowPrice;

        // check the listing is open for sale and exists
        require(_listing.id != 0 && _listing.status == ListingStatus.OPEN_FOR_SALE, "Invalid Listing");

        // if the buy it now price is 0, this means there is no buy it now on the listing
        require(price != 0, "Cannot instant buy listing");

        // check the listing is a valid time range
        require(_listing.publicDate <= block.timestamp, "Listing has not started");
        require(_listing.end >= block.timestamp, "Listing is over");

        // get the address of the token we intend to be paying with, if this value is 0, then the contract will use eth
        address paymentToken = _listing.paymentCurrency;

        // calculate the fee to be given
        uint256 buyFee = price * _listing.royaltyPercentage / 10000;

        // perform a buy it now using eth
        if (paymentToken == address(0)) {
            require(msg.value >= price, "not enough ETH sent.");

            //takeFee and send money to seller
            (bool sentO,) = _listing.owner.call{value : price - buyFee}("");
            (bool sentR,) = _royaltyReceiver.call{value : buyFee}("");

            require(sentO && sentR, "Failed to transfer payment");

            // in case too much eth was sent in, we will send a refund of the remainder
            uint256 refundAmount = msg.value - price;
            if (refundAmount > 0) {
                (bool sentS,) = msg.sender.call{value : refundAmount}("");
                require(sentS, "Failed to transfer refund");
            }
        }

        // perform a buy it now using an ERC20
        else {
            require(msg.value == 0, "Cannot buy with ETH");

            // pay the owner of the listing
            SafeERC20.safeTransferFrom(
                IERC20(paymentToken),
                msg.sender,
                _listing.owner,
                price - buyFee
            );

            // pay the royalty receiver
            SafeERC20.safeTransferFrom(
                IERC20(paymentToken),
                msg.sender,
                _royaltyReceiver,
                buyFee
            );
        }

        // transfer the LAND to the owner and sender
        LAND.safeTransferFrom(_listing.owner, msg.sender, _listing.idFromNft);

        // set the listing to a sold status and remove the id from the map
        listingsMap[listingId].status = ListingStatus.SOLD;
        _tokenIdToListing[_listing.idFromNft] = 0;

        // emit an event for off chain use
        emit ListingSold(
            _listing.id,
            _listing.owner,
            msg.sender,
            _listing.idFromNft,
            _listing.buyItNowPrice,
            _listing.paymentCurrency
        );
    }

    /**
     * @dev See {IBuyAndSellDecentraLandRealEstate-fulfillAuction}
     */
    function fulfillAuction(uint256 listingId, address buyer, uint256 price) external override onlyRole(LISTING_MANAGER) {

        // grab the listing from the map
        Listing memory _listing = listingsMap[listingId];

        // check the listing exists
        require(_listing.id != 0 && _listing.status == ListingStatus.OPEN_FOR_SALE, "Invalid Listing");

        // check the price trying to be fulfilled is at least the floor price and not 0.
        require(price >= _listing.floorPrice && price != 0, "Invalid price");

        // listing must be over in order to fulfill the auction
        require(_listing.publicDate <= block.timestamp, "Listing has not started");
        require(_listing.end < block.timestamp, "Cannot fulfill a listing that has not reached the end time");

        // if a payment currency is not determined
        address paymentToken = _listing.paymentCurrency == address(0) ? DEFAULT_ERC20 : _listing.paymentCurrency;

        // calculate the royalty
        uint256 buyFee = price * _listing.royaltyPercentage / 10000;

        // pay the proeprty owner
        SafeERC20.safeTransferFrom(IERC20(paymentToken), buyer, _listing.owner, price- buyFee);

        // send royalty to the royaltyReceiver
        SafeERC20.safeTransferFrom(IERC20(paymentToken), buyer, _royaltyReceiver, buyFee);

        // transfer the land
        LAND.safeTransferFrom(_listing.owner, buyer, _listing.idFromNft);

        // update the listing map to a sold status and remove the id from the nft map
        listingsMap[listingId].status = ListingStatus.SOLD;
        _tokenIdToListing[_listing.idFromNft] = 0;

        // emit an event for third parties to track
        emit ListingSold(
            _listing.id,
            _listing.owner,
            buyer,
            _listing.idFromNft,
            price,
            _listing.paymentCurrency
        );
    }

    /**
     * @dev See {IBuyAndSellDecentraLandRealEstate-cancelListing}
     */
    function cancelListing(uint256 listingId) external override onlyRole(LISTING_MANAGER) {

        // get the listing from the map
        Listing memory _listing = listingsMap[listingId];

        // check the listing exists
        require(_listing.id != 0 && _listing.status == ListingStatus.OPEN_FOR_SALE, "Invalid Listing");

        // set the new status on the listing
        listingsMap[listingId].status = ListingStatus.CLOSED_BY_ADMIN;

        // remove the id of the nft from the map
        _tokenIdToListing[_listing.idFromNft] = 0;

        // emit event for third party applications to track
        emit ListingCancelled(_listing.id, _listing.idFromNft, _listing.owner);
    }

    /**
     * @dev See {IBuyAndSellDecentraLandRealEstate-updateListing}
     */
    function updateListing(uint256 listingId, uint256 publicDate, uint256 end, uint256 buyItNowPrice, uint256 royaltyPercentage, uint256 floorPrice, uint256 idFromNft, address paymentCurrency) external override onlyRole(LISTING_MANAGER) {

        // check the listingId is already active
        require(listingsMap[listingId].id != 0 && listingsMap[listingId].status == ListingStatus.OPEN_FOR_SALE, "No active listing found");

        // grab the owner of the land
        address owner = LAND.ownerOf(idFromNft);
        require(
            owner == address(this) ||
            LAND.getApproved(idFromNft) == address(this) ||
            LAND.isApprovedForAll(owner, address(this)),
            "No longer approved on this id, highly suggest cancelling listing!"
        );

        // check all of the validation from the create listing
        require(publicDate >= block.timestamp, "public date cannot be in the past");
        require(end > block.timestamp && end > publicDate, "Invalid end");
        require(royaltyPercentage < 10000, "Invalid royalties");
        require((buyItNowPrice == 0 && floorPrice > 0) || floorPrice < buyItNowPrice, "Invalid price");

        // check the listing doesn't exceed the maximum listing time
        uint256 _maxEndTime = publicDate + _maxSaleDuration;
        require(end < _maxEndTime, "End time exceeds allowed sale duration");

        // add the new details to the listing
        listingsMap[listingId].publicDate = publicDate;
        listingsMap[listingId].end = end;
        listingsMap[listingId].buyItNowPrice = buyItNowPrice;
        listingsMap[listingId].royaltyPercentage = royaltyPercentage;
        listingsMap[listingId].floorPrice = floorPrice;
        listingsMap[listingId].owner = payable(owner);
        listingsMap[listingId].idFromNft = idFromNft;
        listingsMap[listingId].paymentCurrency = paymentCurrency;

        // grab the listing for the event
        Listing memory _listing = listingsMap[listingId];

        // emit all of the new details for third parties to track
        emit ListingUpdated(
            _listing.id,
            _listing.publicDate,
            _listing.end,
            _listing.buyItNowPrice,
            _listing.royaltyPercentage,
            _listing.floorPrice,
            _listing.owner,
            _listing.idFromNft,
            _listing.paymentCurrency
        );
    }

    /**
     * @dev See {IBuyAndSellDecentraLandRealEstate-getListing}
     */
    function getListing(uint256 listingId) external view override returns (Listing memory) {
        return listingsMap[listingId];
    }

    /**
     * @dev See {IBuyAndSellDecentraLandRealEstate-getActiveListingIds}
     */
    function getActiveListingIds(uint256[] memory tokenIds) external view override returns (uint256[] memory listingIds) {
        listingIds = new uint256[](tokenIds.length);

        // iterate over the tokenIds that are active
        for (uint256 i = 0; i < tokenIds.length; i++) {

            // grab the listing at the index
            Listing memory _listing = listingsMap[_tokenIdToListing[tokenIds[i]]];

            // check the listing is active, if so add to the return value
            if (_listing.id != 0 && _listing.status == ListingStatus.OPEN_FOR_SALE && _listing.end > block.timestamp) {
                listingIds[i] = _listing.id;
            }

        }
        return listingIds;
    }

    /**
     * @dev Allows a CONFIG_MANAGER to change the maximum length a listing can stay active. This only affects the new
     * listings being made, not ones already posted.
     */
    function setMaxSaleDuration(uint256 maxSaleDuration) public onlyRole(CONFIG_MANAGER) {
        require(maxSaleDuration != 0, "Invalid max sale duration");
        _maxSaleDuration = maxSaleDuration;
        emit MaxSaleDurationUpdated(maxSaleDuration);
    }

    /**
     * @dev retrieves the max sale duration that will be used as default for any new listings.
     */
    function getDefaultMaxSaleDuration() external view returns(uint256) {
        return _maxSaleDuration;
    }

    /**
     * @dev Allows a CONFIG_MANAGER to set a new royaltyReceiver address
     */
    function setRoyaltyReceiver(address payable royaltyReceiver) public onlyRole(CONFIG_MANAGER) {
        require(royaltyReceiver != address(0), "Cannot be 0 address");
        _royaltyReceiver = royaltyReceiver;
        emit RoyaltyReceiverUpdated(royaltyReceiver);
    }

    /**
     * @dev Allows a CONFIG_MANAGER to change the ERC721 that is being used for the land
     */
    function setLAND(address landAddress) public onlyRole(CONFIG_MANAGER) {
        require(landAddress != address(0), "Cannot be 0 address");
        LAND = IERC721(landAddress);
        emit LANDUpdated(landAddress);
    }

    /**
     * @dev Allows a CONFIG_MANAGER to change the default currency being used
     */
    function setDEFAULT_ERC20(address defaultErc20Address) public onlyRole(CONFIG_MANAGER) {
        require(defaultErc20Address != address(0), "Cannot be 0 address");
        DEFAULT_ERC20 = defaultErc20Address;
        emit DEFAULT_ERC20Updated(defaultErc20Address);
    }

    /**
     * @dev gets the current address receiving royalties
     */
    function getRoyaltyReceiver() external view returns (address) {
        return _royaltyReceiver;
    }

    /**
     * @dev gets the counter value for listing ids. Except for the first listing, this will always be the last listing
     * id generated.
     */
    function getCurrentListingId() external view returns (uint256) {
        return _listingIds.current();
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.1;

interface IBuyAndSellDecentraLandRealEstate {
    enum ListingStatus {
        OPEN_FOR_SALE,
        SOLD,
        CLOSED_BY_ADMIN
    }

    event ListingCreated(
        uint256 listingId,
        uint256 publicDate,
        uint256 end,
        uint256 buyItNowPrice,
        uint256 royaltyPercentage,
        uint256 floorPrice,
        address owner,
        uint256 idFromNft,
        address paymentCurrency
    );

    event ListingUpdated(
        uint256 listingId,
        uint256 publicDate,
        uint256 end,
        uint256 buyItNowPrice,
        uint256 royaltyPercentage,
        uint256 floorPrice,
        address owner,
        uint256 idFromNft,
        address paymentCurrency
    );

    event ListingCancelled(uint256 id, uint256 idFromNft, address owner);

    event ListingSold(
        uint256 listingId,
        address from,
        address to,
        uint256 idFromNft,
        uint256 buyItNowPrice,
        address paymentCurrency
    );

    struct Listing {
        ListingStatus status; // representing the managed state of a listing
        uint256 id;
        uint256 publicDate; // date when the listing will be made public, bidding/buying before this date will be impossible
        uint256 end; // date in which a listing is no longer valid
        uint256 buyItNowPrice; // price of the buy-it-now, if 0, no buy-it-now
        uint256 royaltyPercentage; // basepoints percentage - the amount to be paid to the royaltyReceiver. This is set on a per-listing basis
        uint256 floorPrice; // the value that must be bid to buy the property
        address payable owner;
        uint256 idFromNft;
        address paymentCurrency; // The payment token
    }

    /**
     * @dev submits the initial metadata for a listing. This will not make anything public, but will allow the calling
     * of submitRealEstate afterwards.
     */
    function createListing(
        uint256 publicDate,
        uint256 endTime,
        uint256 buyItNowPrice,
        uint256 idFromNft,
        uint256 royaltyPercentage,
        uint256 floorPrice,
        address paymentCurrency
    ) external returns (uint256);


    /**
     * @dev sets the cancelled bool in Listing to true. This will prevent the listing from being shown on the frontend.
     */
    function cancelListing(uint256 listingId) external;

    /**
     * @dev will get the listing, intended to be called on the frontend. Should still be able to get cancelled listings
     */
    function getListing(uint256 listingId)
        external
        view
        returns (Listing memory);

    /**
     * @dev Get all active listings for NFT Ids
     * @param tokenIds array of NFT ids
     * @return listingIds array of active liting ids
     */
    function getActiveListingIds(uint256[] memory tokenIds)
        external
        view
        returns (uint256[] memory listingIds);

    /**
     * @dev will allow adjusting of details on the listing, this will not be callable after the public date.
     */
    function updateListing(
        uint256 listingId,
        uint256 publicDate,
        uint256 end,
        uint256 buyItNowPrice,
        uint256 royaltyPercentage,
        uint256 floorPrice,
        uint256 idFromNft,
        address paymentCurrency
    ) external;

    /**
     * @dev public buy function for instant buy listing for buyItNowPrice
     */
    function buyListing(uint256 listingId) external payable;

    /**
     * @dev function for LISTING_MANAGER to fulfill an auction type listing. This is so bidding can happen off chain and
     * a trusted address can come in and fulfill the auction afterwards
     */
    function fulfillAuction(
        uint256 listingId,
        address buyer,
        uint256 price
    ) external;
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
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
        IERC20 token,
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
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
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

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

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
abstract contract AccessControl is Context, IAccessControl, ERC165 {
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
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
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
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
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
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
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
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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