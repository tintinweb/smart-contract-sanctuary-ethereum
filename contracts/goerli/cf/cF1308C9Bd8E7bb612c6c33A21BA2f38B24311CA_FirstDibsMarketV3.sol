// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.13;

import { IERC721 } from '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import { IERC1155 } from '@openzeppelin/contracts/token/ERC1155/IERC1155.sol';
import { AccessControlUpgradeable } from '@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol';
import { ContextUpgradeable } from '@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol';
import { Initializable } from '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import { ERC165Checker } from '@openzeppelin/contracts/utils/introspection/ERC165Checker.sol';
import { ReentrancyGuardUpgradeable } from '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';
import { FirstDibsFeeSupport } from './FirstDibsFeeSupport.sol';
import { FirstDibsTokenTransferManager } from './FirstDibsTokenTransferManager.sol';

error ListingDoesNotExist(uint256 listingId);
error UnauthorizedCaller(uint256 listingId);
error InvalidSupply(uint256 listingId);
error UnsupportedAssetType();
error NoZeroAddress();
error ListingNotLive(uint256 listingId);
error InvalidTime(uint256 startTime, uint256 endTime);
error IndexOutOfBounds(uint256 index);
error TransferManagerNeedsApproval();

contract FirstDibsMarketV3 is
    Initializable,
    ReentrancyGuardUpgradeable,
    AccessControlUpgradeable,
    FirstDibsFeeSupport
{
    /// @custom:oz-upgrades-unsafe-allow constructor
    // See https://docs.openzeppelin.com/contracts/4.x/api/proxy#Initializable-_disableInitializers--
    constructor() {
        Initializable._disableInitializers();
    }

    /**
     * ========================
     * #Public state variables
     * ========================
     */

    /// @dev The Token Transfer Helper will transfer tokens for registered contracts
    FirstDibsTokenTransferManager public firstDibsTokenTransferHelper;

    /// @dev May cancel listings
    bytes32 public constant CANCEL_LISTING_ROLE = keccak256('CANCEL_LISTING_ROLE');

    /// @dev May create, update, cancel listings
    bytes32 public constant ADMIN_LISTING_ROLE = keccak256('ADMIN_LISTING_ROLE');

    /**
     * ========================
     * #Structs
     * ========================
     */

    /**
     * @dev A Listing for a token
     * @param tokenContract The address of the token contract for a listing
     * @param tokenId The ID of the token for a listing
     * @param seller The address of the seller
     * @param fundsRecipient The address of the funds recipient of the sale
     * @param buyer The address of the buyer (optional; used for private sale)
     * @param quantity The number of tokens for sale (ignored for ERC721 tokens)
     * @param price The price per token
     * @param assetClass The type of asset (ERC721 or ERC1155)
     */
    struct Listing {
        address tokenContract;
        uint256 tokenId;
        address seller;
        address fundsRecipient;
        address buyer;
        uint256 quantity;
        uint256 price;
        bytes4 assetClass;
        uint256 startTime;
        uint256 endTime;
    }

    /**
     * ========================
     * #Private state variables
     * ========================
     */
    /// @dev A counter which increases each time a listing is created
    uint256 private _listingIdCounter;

    /// @dev A counter which increases each time an order is submitted.
    // for ERC1155, there could be muliple orders per listing.
    // Incremented in purchaseFromListing
    uint256 private _orderIdCounter;

    /// @dev Maps listing ID to Listing struct
    mapping(uint256 => Listing) private _listings;

    /// @dev Mapping from seller address to a count of seller's listings
    mapping(address => uint256) private _sellerListingsCount;

    /// @dev Mapping from seller address to index of listing ID to listing ID
    mapping(address => mapping(uint256 => uint256)) private _sellerListings;

    /// @dev Mapping from listing ID to index of the owner tokens list
    mapping(uint256 => uint256) private _sellerListingsIndex;

    /// @dev Supported token standards
    bytes4 private constant _ERC721_INTERFACE_ID = 0x80ac58cd;
    bytes4 private constant _ERC1155_INTERFACE_ID = 0xd9b67a26;
    bytes4[] private interfaceIds;

    /**
     * ========================
     * #Events
     * ========================
     */

    /**
     * @notice This event is emitted when a Listing is created
     * @param tokenContract indexed; address of the token contract of the token to be listed
     * @param tokenId indexed; the token id of the token to be listed
     * @param seller indexed; the address of the seller of the token
     * @param listingId the ID of the listing (used for lookups)
     * @param fundsRecipient the address of the funds recipient of the token sale
     * @param buyer the address of the buyer of the token (optional; used for private sales)
     * @param quantity the number of tokens for sale
     * @param price the price per token
     * @param assetClass the type of token for sale (ERC721 or ERC1155)
     * @param startTime the start time of the listing
     * @param endTime the end time of the listing
     */
    event ListingCreated(
        address indexed tokenContract,
        uint256 indexed tokenId,
        address indexed seller,
        uint256 listingId,
        address fundsRecipient,
        address buyer,
        uint256 quantity,
        uint256 price,
        bytes4 assetClass,
        uint256 startTime,
        uint256 endTime
    );

    /**
     * @notice This event is emitted when a Listing is updated
     * @param listingId the ID of the listing
     * @param fundsRecipient the address of the funds recipient of the token sale
     * @param buyer the address of the buyer of the token (optional; used for private sales)
     * @param quantity the number of tokens for sale
     * @param price the price per token
     * @param startTime the start time of the listing
     * @param endTime the end time of the listing
     */
    event ListingUpdated(
        uint256 listingId,
        address fundsRecipient,
        address buyer,
        uint256 quantity,
        uint256 price,
        uint256 startTime,
        uint256 endTime
    );

    /**
     * @notice This event is emitted when a Listing is canceled
     * @param listingId The ID of the listing
     */
    event ListingCanceled(uint256 listingId);

    /**
     * @notice This event is emitted when a Listing or part of a listing is purchased
     * @param listingId The ID of the listing
     * @param orderId The ID of the individual order on the listing
     * @param buyer address; the buyer of the listing
     * @param quantityPurchased the quantity of tokens purchased from the listing
     * @param quantityRemaining the quantity of tokens remaining on the listing
     * @param platformFee Fee paid by buyer above purchase price
     * @param adminCommissionFee Commission paid
     * @param sellerPayment payment to seller subtract royalties, commission fee
     */
    event ListingPurchased(
        uint256 listingId,
        uint256 orderId,
        address buyer,
        uint256 quantityPurchased,
        uint256 quantityRemaining,
        uint256 platformFee,
        uint256 adminCommissionFee,
        uint256 sellerPayment
    );

    /**
     * ========================
     * #Modifiers
     * ========================
     */
    modifier listingExists(uint256 listingId) {
        if (_listings[listingId].seller == address(0)) {
            revert ListingDoesNotExist({ listingId: listingId });
        }
        _;
    }

    /**
     * ========================
     * initializer
     * ========================
     */
    function initialize(
        address _firstDibsTokenTransferHelper,
        address _royaltyEngine,
        address _marketSettings
    ) public initializer {
        FirstDibsFeeSupport.__FirstDibsFeeSupport_init(_royaltyEngine, _marketSettings);
        firstDibsTokenTransferHelper = FirstDibsTokenTransferManager(_firstDibsTokenTransferHelper);

        /// @dev note: DEFAULT_ADMIN_ROLE is set in __FirstDibsFeeSupport_init
        AccessControlUpgradeable._grantRole(ADMIN_LISTING_ROLE, ContextUpgradeable._msgSender());

        /// @dev This contract supports these token standards
        interfaceIds = [_ERC721_INTERFACE_ID, _ERC1155_INTERFACE_ID];
    }

    /**
     * @notice Retrieve a Listing
     * @param _listingId The ID of the listing
     */
    function getListing(uint256 _listingId)
        public
        view
        listingExists(_listingId)
        returns (Listing memory)
    {
        return _listings[_listingId];
    }

    /**
     * @notice Retrieve count of listings
     * @param _seller Address of the seller
     */
    function listingsOf(address _seller) public view returns (uint256) {
        return _sellerListingsCount[_seller];
    }

    /**
     * @notice Retrieve listing ID of seller by index
     * @param _seller Address of the seller
     * @param _index Index of listing ID in the seller's listing array
     */
    function listingsOfSellerByIndex(address _seller, uint256 _index)
        public
        view
        returns (uint256)
    {
        if (_index >= listingsOf(_seller)) {
            revert IndexOutOfBounds(_index);
        }
        return _sellerListings[_seller][_index];
    }

    /**
     * @notice Creates a listing for a given token
     * @param _tokenContract The address of the token
     * @param _tokenId The id of the token
     * @param _fundsRecipient The address of the funds recipient from the token sale
     * @param _buyer The private buyer of the token; optional, may be 0x0 if there is no private buyer
     * @param _seller The seller (current owner of the token)
     * @param _quantity The quantity of tokens to be sold; note: must be `1` for ERC721
     * @param _price The price per token
     * @param _startTime The start time of the listing
     * @param _endTime The end time of the listing
     */
    function createListing(
        address _tokenContract,
        uint256 _tokenId,
        address _fundsRecipient,
        address _seller,
        address _buyer,
        uint256 _quantity,
        uint256 _price,
        uint256 _startTime,
        uint256 _endTime
    ) external nonReentrant {
        // increment listing id
        _listingIdCounter++;

        // set listing in state
        bytes4 assetClass = _getInterfaceId(_tokenContract);
        (uint256 startTime, uint256 endTime) = _getValidTimes(_startTime, _endTime);
        address validSeller = _validateSeller(
            _tokenContract,
            _tokenId,
            _seller,
            _quantity,
            assetClass
        );
        _listings[_listingIdCounter].tokenContract = _tokenContract;
        _listings[_listingIdCounter].tokenId = _tokenId;
        _listings[_listingIdCounter].price = _price;
        _listings[_listingIdCounter].buyer = _buyer;
        _listings[_listingIdCounter].seller = validSeller;
        _listings[_listingIdCounter].fundsRecipient = _getValidRecipient(_fundsRecipient);
        _listings[_listingIdCounter].assetClass = assetClass;
        // When creating a listing if startTime is 0 that indicates that the startTime
        // is now, so we set it to the current timestamp
        _listings[_listingIdCounter].startTime = startTime == 0 ? block.timestamp : startTime;
        _listings[_listingIdCounter].endTime = endTime;
        _listings[_listingIdCounter].quantity = _getValidQuantity(
            _tokenContract,
            _tokenId,
            validSeller,
            _quantity,
            assetClass,
            0
        );

        // update enumeration data structures
        _addSellerListing(_listings[_listingIdCounter].seller, _listingIdCounter);

        emit ListingCreated(
            _listings[_listingIdCounter].tokenContract,
            _listings[_listingIdCounter].tokenId,
            _listings[_listingIdCounter].seller,
            _listingIdCounter,
            _listings[_listingIdCounter].fundsRecipient,
            _listings[_listingIdCounter].buyer,
            _listings[_listingIdCounter].quantity,
            _listings[_listingIdCounter].price,
            _listings[_listingIdCounter].assetClass,
            _listings[_listingIdCounter].startTime,
            _listings[_listingIdCounter].endTime
        );
    }

    /**
     * @notice Update a listing; note: the seller may not be updated
     * @param _fundsRecipient The address of the funds recipient from the sale
     * @param _buyer The private buyer of the token; note: 0x0 will remove private buyer if one exists on the listing
     * @param _quantity The quantity of tokens to be sold; must be `1` for ERC721
     * @param _price The price per token
     * @param _startTime The start time of the listing
     * @param _endTime The end time of the listing
     */
    function updateListing(
        uint256 _listingId,
        address _fundsRecipient,
        address _buyer,
        uint256 _quantity,
        uint256 _price,
        uint256 _startTime,
        uint256 _endTime
    ) external nonReentrant listingExists(_listingId) {
        Listing storage listing = _listings[_listingId];
        bool approved = listing.assetClass == _ERC721_INTERFACE_ID
            ? IERC721(listing.tokenContract).isApprovedForAll(
                listing.seller,
                ContextUpgradeable._msgSender()
            )
            : IERC1155(listing.tokenContract).isApprovedForAll(
                listing.seller,
                ContextUpgradeable._msgSender()
            );
        if (
            // The sender must be the seller, approved, or have ADMIN_LISTING_ROLE
            // to update a listing
            !approved &&
            ContextUpgradeable._msgSender() != listing.seller &&
            !AccessControlUpgradeable.hasRole(ADMIN_LISTING_ROLE, ContextUpgradeable._msgSender())
        ) {
            revert UnauthorizedCaller({ listingId: 0 });
        }

        listing.fundsRecipient = _getValidRecipient(_fundsRecipient);
        // It's valid for buyer to be zero address because that
        // indicates that the listing may be purchased by anyone
        listing.buyer = _buyer;
        listing.quantity = _getValidQuantity(
            listing.tokenContract,
            listing.tokenId,
            listing.seller,
            _quantity,
            listing.assetClass,
            _listingId
        );
        // 0 is a valid price
        listing.price = _price;

        (uint256 startTime, uint256 endTime) = _getValidTimes(_startTime, _endTime);
        // startTime being 0 indicates that the user does not want to update the starTime
        // so the listing isnt't updated
        if (startTime != 0) {
            listing.startTime = startTime;
        }
        listing.endTime = endTime;

        emit ListingUpdated(
            _listingId,
            listing.fundsRecipient,
            listing.buyer,
            listing.quantity,
            listing.price,
            listing.startTime,
            listing.endTime
        );
    }

    /**
     * @notice Cancel a listing. The seller, the owner of an ERC721, admins,
     * and approved are allowed to cancel listings.
     * @param _listingId The id of the listing
     */
    function cancelListing(uint256 _listingId) external nonReentrant listingExists(_listingId) {
        Listing memory listing = _listings[_listingId];
        address msgSender = ContextUpgradeable._msgSender();
        if (
            !AccessControlUpgradeable.hasRole(ADMIN_LISTING_ROLE, msgSender) &&
            !AccessControlUpgradeable.hasRole(CANCEL_LISTING_ROLE, msgSender)
        ) {
            if (listing.assetClass == _ERC721_INTERFACE_ID) {
                // For ERC721, the owner is allowed to cancel the listing
                // even if they're not the seller. It covers the case where
                // the token is transferred to a new owner after the listing
                // has been created. Approved operators may also cancel.
                if (
                    msgSender != listing.seller &&
                    msgSender != IERC721(listing.tokenContract).ownerOf(listing.tokenId) &&
                    !IERC721(listing.tokenContract).isApprovedForAll(listing.seller, msgSender)
                ) {
                    revert UnauthorizedCaller({ listingId: _listingId });
                }
            } else {
                // For ERC1155, Seller and Approved are allowed to cancel
                if (
                    msgSender != listing.seller &&
                    !IERC1155(listing.tokenContract).isApprovedForAll(listing.seller, msgSender)
                ) {
                    revert UnauthorizedCaller({ listingId: _listingId });
                }
            }
        }

        emit ListingCanceled(_listingId);

        _removeSellerListing(listing.seller, _listingId);
    }

    /**
     * @notice Purchases a given quantity of tokens from a listing
     * @param _listingId The id of the listing
     * @param _quantity The quantity of tokens to purchase
     * @param _recipient The recipient of the token
     */
    function purchaseFromListing(
        uint256 _listingId,
        uint256 _quantity,
        address _recipient
    ) external payable nonReentrant listingExists(_listingId) {
        Listing memory listing = _listings[_listingId];

        if (block.timestamp < listing.startTime) {
            revert ListingNotLive({ listingId: _listingId });
        }
        if (listing.endTime > 0 && block.timestamp > listing.endTime) {
            revert ListingNotLive({ listingId: _listingId });
        }
        if (listing.buyer != address(0) && ContextUpgradeable._msgSender() != listing.buyer) {
            revert UnauthorizedCaller({ listingId: _listingId });
        }
        if (_quantity > listing.quantity) {
            revert InvalidSupply({ listingId: _listingId });
        }

        _orderIdCounter++;

        (uint256 platformFee, uint256 commissionFee, uint256 sellerPayment) = FirstDibsFeeSupport
            ._handlePayouts(
                _listingId,
                _orderIdCounter,
                listing.tokenContract,
                listing.fundsRecipient,
                listing.tokenId,
                listing.price * _quantity,
                300000
            );

        // TRANSFER TOKEN
        if (listing.assetClass == _ERC721_INTERFACE_ID) {
            // Transfer the NFT to the buyer
            // Reverts if FirstDibsTokenManager is not approved by the seller
            // or the seller longer owns the token
            firstDibsTokenTransferHelper.erc721SafeTransferFrom(
                listing.tokenContract,
                listing.seller,
                _recipient,
                listing.tokenId
            );
            // Remove the listing from state
            _removeSellerListing(listing.seller, _listingId);
        } else if (listing.assetClass == _ERC1155_INTERFACE_ID) {
            // Transfer the 1155s to the buyer
            // Reverts if FirstDibsTokenManager is not approved by the seller
            // or the seller longer owns a balance of the token
            firstDibsTokenTransferHelper.erc1155SafeTransferFrom(
                listing.tokenContract,
                listing.seller,
                _recipient,
                listing.tokenId,
                _quantity,
                ''
            );
            _listings[_listingId].quantity -= _quantity;
            if (IERC1155(listing.tokenContract).balanceOf(listing.seller, listing.tokenId) == 0) {
                // Remove the listing from state if there are no more tokens left for sale by this
                // seller in this listing
                _removeSellerListing(listing.seller, _listingId);
            }
        }

        emit ListingPurchased(
            _listingId,
            _orderIdCounter,
            _recipient,
            _quantity,
            _listings[_listingId].quantity,
            platformFee,
            commissionFee,
            sellerPayment
        );
    }

    /**
     * @dev Returns one of ERC721 or ERC1155 interface IDs or reverts
     * @param _tokenContract The address of the contract to check
     */
    function _getInterfaceId(address _tokenContract) private view returns (bytes4 assetClass) {
        bool[] memory supportedInterfaces = ERC165Checker.getSupportedInterfaces(
            _tokenContract,
            interfaceIds
        );
        if (!supportedInterfaces[0] && !supportedInterfaces[1]) {
            revert UnsupportedAssetType();
        }
        assetClass = supportedInterfaces[0] == true ? interfaceIds[0] : interfaceIds[1];
    }

    /**
     * @dev Ensures the seller can fulfill the listing and has approved the listing
     * @param _tokenContract Address of the token contract
     * @param _tokenId Id of the token to be listed
     * @param _seller Address of a seller that has a balance of tokens to sell; required if _assetClass is ERC1155
     * @param _quantity Quantity of tokens to list; Ignored for ERC721 _assetClass
     * @param _assetClass The type of asset, either ERC721 (0x80ac58cd) or ERC1155 (0xd9b67a26)
     */
    function _validateSeller(
        address _tokenContract,
        uint256 _tokenId,
        address _seller,
        uint256 _quantity,
        bytes4 _assetClass
    ) private view returns (address) {
        address msgSender = ContextUpgradeable._msgSender();
        address seller;
        if (_assetClass == _ERC721_INTERFACE_ID) {
            address tokenOwner = IERC721(_tokenContract).ownerOf(_tokenId);
            if (
                // The sender must be the owner, approved, or have ADMIN_LISTING_ROLE
                // to create a listing
                msgSender != tokenOwner &&
                !IERC721(_tokenContract).isApprovedForAll(tokenOwner, msgSender) &&
                !AccessControlUpgradeable.hasRole(ADMIN_LISTING_ROLE, msgSender)
            ) {
                revert UnauthorizedCaller({ listingId: 0 });
            }
            // the owner is always the seller
            seller = tokenOwner;
        } else {
            // ERC1155 case
            if (_seller == address(0)) {
                revert NoZeroAddress();
            }
            // The seller must be the sender, approved by the seller,
            // or have ADMIN_LISTING_ROLE to create a listing
            if (
                _seller != msgSender &&
                !IERC1155(_tokenContract).isApprovedForAll(_seller, msgSender) &&
                !AccessControlUpgradeable.hasRole(ADMIN_LISTING_ROLE, msgSender)
            ) {
                revert UnauthorizedCaller({ listingId: 0 });
            }
            // If the seller does not have balance required, then revert.
            // We've already asserted that the txn sender has perms to list
            if (IERC1155(_tokenContract).balanceOf(_seller, _tokenId) < _quantity) {
                revert InvalidSupply({ listingId: 0 });
            }
            seller = _seller;
        }
        // The listing is not valid if the seller has not approved the transfer manager
        if (
            !IERC1155(_tokenContract).isApprovedForAll(
                seller,
                address(firstDibsTokenTransferHelper)
            )
        ) {
            revert TransferManagerNeedsApproval();
        }
        return seller;
    }

    /**
     * @dev Ensures the funds recipient is not the zero address
     * @param _fundsRecipient the funds recipient address
     */
    function _getValidRecipient(address _fundsRecipient) private pure returns (address) {
        if (_fundsRecipient == address(0)) {
            revert NoZeroAddress();
        }
        return _fundsRecipient;
    }

    /**
     * @dev Get valid times; reverts if start time > 0 but in the past;
     * if end time > 0 but in the past; or if start time > 0 and > end time
     * @param _startTime The time to validate
     * @param _endTime The time to validate
     * @return Valid times
     */
    function _getValidTimes(uint256 _startTime, uint256 _endTime)
        private
        view
        returns (uint256, uint256)
    {
        if (_startTime > 0 && block.timestamp > _startTime) {
            revert InvalidTime({ startTime: _startTime, endTime: 0 });
        } else if (_endTime > 0 && block.timestamp > _endTime) {
            revert InvalidTime({ startTime: 0, endTime: _endTime });
        } else if (_startTime > 0 && _startTime >= _endTime) {
            revert InvalidTime({ startTime: _startTime, endTime: _endTime });
        }
        return (_startTime, _endTime);
    }

    /**
     * @dev Validates the quantity of tokens for sale on a listing
     * @param _tokenContract Helps to determine that quantity is valid
     * @param _tokenId Helps to determine that quantity is valid
     * @param _seller The seller of the token - MUST be validated first
     * @param _quantity The quantity
     * @param _assetClass Helps validate the quantity is correct
     * @param _listingId When updating we'll want to log the listing id if it reverts
     */
    function _getValidQuantity(
        address _tokenContract,
        uint256 _tokenId,
        address _seller,
        uint256 _quantity,
        bytes4 _assetClass,
        uint256 _listingId
    ) private view returns (uint256) {
        // Ensure the quantity is non-zero
        if (_quantity == 0) {
            revert InvalidSupply({ listingId: _listingId });
        }

        if (_assetClass == _ERC721_INTERFACE_ID) {
            if (_quantity != 1) {
                revert InvalidSupply({ listingId: _listingId });
            }
            return 1;
        }
        // ERC1155 case
        // Ensure the seller has sufficient balance
        if (IERC1155(_tokenContract).balanceOf(_seller, _tokenId) < _quantity) {
            revert InvalidSupply({ listingId: _listingId });
        }
        return _quantity;
    }

    /**
     * @dev Add a listing to seller's enumeration
     * @param _seller Seller to add listing to
     * @param _listingId The ID of the listing
     */
    function _addSellerListing(address _seller, uint256 _listingId) private {
        // Update the the seller's index to point listing ID to index of listing
        uint256 length = listingsOf(_seller);
        _sellerListings[_seller][length] = _listingId;
        _sellerListingsIndex[_listingId] = length;

        unchecked {
            // Update the count of seller's listings
            // Will not overflow unless all 2**256 listing ids are assigned to the same seller.
            // Given that listings are created one by one, it is impossible in practice for that
            // to happen.
            _sellerListingsCount[_seller] += 1;
        }
    }

    /**
     * @dev Reomve a listing from seller's enumeration
     * @param _seller Seller to add listing to
     * @param _listingId The ID of the listing
     */
    function _removeSellerListing(address _seller, uint256 _listingId) private {
        uint256 lastListingIndex = listingsOf(_seller) - 1;
        uint256 listingIndex = _sellerListingsIndex[_listingId];

        if (listingIndex != lastListingIndex) {
            uint256 lastListingId = _sellerListings[_seller][lastListingIndex];
            // move last listing to index where we want to delete the listing
            _sellerListings[_seller][listingIndex] = lastListingId;
            // update moved listing's index
            _sellerListingsIndex[lastListingId] = listingIndex;
        }

        unchecked {
            // Update seller's listing count
            // Cannot overflow, as that would require more listings to be
            // purchased/canceled than the seller initially created
            _sellerListingsCount[_seller] -= 1;
        }

        // remove from seller's listing index => listing ID mapping
        delete _sellerListings[_seller][lastListingIndex];

        // remove sellers Listing ID => index mapping
        delete _sellerListingsIndex[_listingId];

        // remove listing from listings mapping
        delete _listings[_listingId];
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.13;

import { IERC20 } from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import { ERC165Checker } from '@openzeppelin/contracts/utils/introspection/ERC165Checker.sol';
import { ContextUpgradeable } from '@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol';
import { PullPaymentUpgradeable } from '@openzeppelin/contracts-upgradeable/security/PullPaymentUpgradeable.sol';
import { AccessControlUpgradeable } from '@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol';
import { Initializable } from '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';

import { IOwnable } from '../interfaces/IOwnable.sol';
import { IFirstDibsMarketSettingsV2 } from '../v2/IFirstDibsMarketSettingsV2.sol';
import { IRoyaltyEngineV1 } from '../royaltyEngine/IRoyaltyEngineV1.sol';

error Unauthorized();
error UnsupportedInterface();
error InsufficientFunds();

contract FirstDibsFeeSupport is Initializable, AccessControlUpgradeable, PullPaymentUpgradeable {
    IFirstDibsMarketSettingsV2 public iFirstDibsMarketSettings;
    address public manifoldRoyaltyEngineAddress; // address of the manifold royalty engine https://royaltyregistry.xyz

    /**
     * @notice This event is emitted when a royalty is paid
     * @param listingId The listing associated with the royalty
     * @param orderId The order associated with the royalty
     * @param tokenContract The address of the NFT contract
     * @param tokenId The token id of the NFT
     * @param recipients The recipients of the royalty
     * @param amounts The amounts of royalty paid
     */
    event RoyaltyPayout(
        uint256 listingId,
        uint256 orderId,
        address tokenContract,
        uint256 tokenId,
        address payable[] recipients,
        uint256[] amounts
    );

    /**
     * @notice This event is emitted when a value transfer fails
     * @param to The address where the value was meant to be transferred
     * @param amount The value of the failed transfer
     */
    event TransferFailed(address to, uint256 amount);

    function __FirstDibsFeeSupport_init(address _royaltyEngine, address _marketSettings)
        public
        onlyInitializing
    {
        PullPaymentUpgradeable.__PullPayment_init();
        AccessControlUpgradeable.__AccessControl_init();
        AccessControlUpgradeable._grantRole(DEFAULT_ADMIN_ROLE, ContextUpgradeable._msgSender()); // deployer of the contract gets admin permissions
        iFirstDibsMarketSettings = IFirstDibsMarketSettingsV2(_marketSettings);
        manifoldRoyaltyEngineAddress = _royaltyEngine;
    }

    modifier onlyAdmin() {
        if (!hasRole(DEFAULT_ADMIN_ROLE, ContextUpgradeable._msgSender())) {
            revert Unauthorized();
        }
        _;
    }

    /**
     * @notice Update the address of the Royalty Engine, in case of unexpected update on Manifold's Proxy
     *
     * @dev emergency use only – requires a frozen RoyaltyEngineV1 at commit 4ae77a73a8a73a79d628352d206fadae7f8e0f74
     *  to be deployed elsewhere, or a contract matching that ABI
     * @param _royaltyEngine The address for the new royalty engine
     */
    function setRoyaltyEngineAddress(address _royaltyEngine) public onlyAdmin {
        if (!ERC165Checker.supportsInterface(_royaltyEngine, type(IRoyaltyEngineV1).interfaceId)) {
            revert UnsupportedInterface();
        }
        manifoldRoyaltyEngineAddress = _royaltyEngine;
    }

    /**
     * @notice Update the address of the Market Settings Contract
     *
     * @param _marketSettings The address for the new market settings contract
     */
    function setMarketSettings(address _marketSettings) public onlyAdmin {
        iFirstDibsMarketSettings = IFirstDibsMarketSettingsV2(_marketSettings);
    }

    /**
     * @notice Pays protocol fees, royalty fees, and send remaining amount to the funds recipient
     *
     * @param _listingId The listing associated with the fee payout
     * @param _orderId The order associated with the fee payout
     * @param _tokenContract The address of the token contract
     * @param _fundsRecipient The address of the funds recipient
     * @param _tokenId The id of the token for sale
     * @param _expectedAmount The funds required to complete a purchase. Excludes buyer premium.
     * @param _gasLimit The gas limit to use when attempting to payout royalties. Uses gasleft() if not provided.
     */
    function _handlePayouts(
        uint256 _listingId,
        uint256 _orderId,
        address _tokenContract,
        address _fundsRecipient,
        uint256 _tokenId,
        uint256 _expectedAmount,
        uint256 _gasLimit
    )
        internal
        returns (
            uint256 platformFee,
            uint256 commissionFee,
            uint256 sellerFee
        )
    {
        (uint256 _sentFunds, uint256 _platformFee) = _getSentFundsAndPlatformFee(msg.value);
        // Ensure the attached ETH matches the cost of the bulk price
        if (_sentFunds != _expectedAmount) {
            revert InsufficientFunds();
        }

        // PAYOUTS
        platformFee = _platformFee;
        // send protocol fee & buyer premium to commission address
        commissionFee = _handleCommissionFeePayout(_sentFunds, platformFee);
        (uint256 royaltyAmount, ) = _handleRoyaltyPayout(
            _listingId,
            _orderId,
            _tokenContract,
            _tokenId,
            _sentFunds,
            _gasLimit
        );
        sellerFee = _sentFunds - royaltyAmount - commissionFee;
        _sendFunds(_fundsRecipient, sellerFee);
    }

    /**
     * @notice Pays out the protocol fee to its fee recipient
     *
     * @param _sentFunds The sale amount
     * @param _platformFee The buyer premium amount
     * @return commissionFee The amount paid as commission
     */
    function _handleCommissionFeePayout(uint256 _sentFunds, uint256 _platformFee)
        internal
        returns (uint256 commissionFee)
    {
        commissionFee = (_sentFunds * iFirstDibsMarketSettings.globalMarketCommission()) / 10000;
        // don't attempt to transfer fees if there are none
        if (commissionFee + _platformFee > 0) {
            _tryTransferThenEscrow(
                iFirstDibsMarketSettings.commissionAddress(),
                commissionFee + _platformFee
            );
        }
    }

    /**
     * @notice Pays out royalties for given NFTs
     *
     * @param _listingId The listing associated with the royalty payout
     * @param _orderId The order associated with the royalty payout
     * @param _tokenContract The NFT contract address to get royalty information from
     * @param _tokenId, The Token ID to get royalty information from
     * @param _sentFunds The total sale amount
     * @param _gasLimit The gas limit to use when attempting to payout royalties. Uses gasleft() if not provided.
     * @return (The amount paid as royalty, the success of the)
     */
    function _handleRoyaltyPayout(
        uint256 _listingId,
        uint256 _orderId,
        address _tokenContract,
        uint256 _tokenId,
        uint256 _sentFunds,
        uint256 _gasLimit
    ) internal returns (uint256, bool) {
        // If no gas limit was provided or provided gas limit greater than gas left, just pass the remaining gas.
        uint256 gas = (_gasLimit == 0 || _gasLimit > gasleft()) ? gasleft() : _gasLimit;

        // External call ensuring contract doesn't run out of gas paying royalties
        try
            this._handleRoyaltyEnginePayout{ gas: gas }(
                _listingId,
                _orderId,
                _tokenContract,
                _tokenId,
                _sentFunds
            )
        returns (uint256 royaltyAmount) {
            // Return royalty amount if royalties payout succeeded
            return (royaltyAmount, true);
        } catch {
            // Return zero if royalties payout failed
            return (0, false);
        }
    }

    /**
     * @notice Pays out royalties for NFTs based on the information returned by the royalty engine
     *
     * @dev This method is external to enable setting a gas limit when called - see `_handleRoyaltyPayout`.
     * @param _listingId The listing associated with the royalty payout
     * @param _orderId The order associated with the royalty payout
     * @param _tokenContract The NFT Contract to get royalty information from
     * @param _tokenId, The Token ID to get royalty information from
     * @param _sentFunds The total sale amount
     * @return royaltyAmount The remaining funds after paying out royalties
     */
    function _handleRoyaltyEnginePayout(
        uint256 _listingId,
        uint256 _orderId,
        address _tokenContract,
        uint256 _tokenId,
        uint256 _sentFunds
    ) external payable returns (uint256 royaltyAmount) {
        royaltyAmount = 0;
        // get royalty information from manifold royalty engine
        // https://royaltyregistry.xyz/
        (address payable[] memory royaltyRecipients, uint256[] memory amounts) = IRoyaltyEngineV1(
            manifoldRoyaltyEngineAddress
        ).getRoyalty(_tokenContract, _tokenId, _sentFunds);
        uint256 arrLength = royaltyRecipients.length;
        for (uint256 i = 0; i < arrLength; ) {
            if (amounts[i] != 0 && royaltyRecipients[i] != address(0)) {
                royaltyAmount += amounts[i];
                _sendFunds(royaltyRecipients[i], amounts[i]);
            }
            unchecked {
                ++i;
            }
        }
        emit RoyaltyPayout(
            _listingId,
            _orderId,
            _tokenContract,
            _tokenId,
            royaltyRecipients,
            amounts
        );
    }

    /**
     * @dev Retrieves the sale and buyer premium amount from the _amount based on the current BP rate
     *
     * @param _amount The entire amount (sale amount + buyer premium amount)
     * @return The bid sent and the premium sent
     */
    function _getSentFundsAndPlatformFee(uint256 _amount)
        internal
        view
        returns (
            uint256, /*sentFunds*/
            uint256 /*sentPremium*/
        )
    {
        uint256 bpRate = iFirstDibsMarketSettings.globalBuyerPremium() + 10000;
        uint256 _sentFunds = uint256((_amount * 10000) / bpRate);
        uint256 _platformFee = uint256(_amount - _sentFunds);
        return (_sentFunds, _platformFee);
    }

    /**
     * @dev Sending ether is not guaranteed complete, and the method used here will
     * escrow the value if it fails. For example, a contract can block transfer, or might use
     * an excessive amount of gas, thereby griefing a bidder.
     * We limit the gas used in transfers, and handle failure with escrowing.
     * @param _to address to transfer ETH to
     * @param _amount uint256 WEI amount to transfer
     */
    function _tryTransferThenEscrow(address _to, uint256 _amount) internal {
        // increase the gas limit a reasonable amount above the default, and try
        // to send ether to the recipient.
        (bool success, ) = _to.call{ value: _amount, gas: 30000 }('');
        if (!success) {
            emit TransferFailed(_to, _amount);
            _asyncTransfer(_to, _amount);
        }
    }

    /**
     * @dev check if funds recipient is a contract. If it is, transfer ETH directly. If not, store in escrow on this contract.
     */
    function _sendFunds(address _to, uint256 _amount) internal {
        // check if address is contract
        // see reference implementation at https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol#L41
        if (_to.code.length > 0) {
            // _to is a contract if _to.code.length > 0, so first try to transfer funds directly
            _tryTransferThenEscrow(_to, _amount);
        } else {
            _asyncTransfer(_to, _amount);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.13;

import { IERC1155 } from '@openzeppelin/contracts/token/ERC1155/IERC1155.sol';
import { IERC721 } from '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import { AccessControl } from '@openzeppelin/contracts/access/AccessControl.sol';

error ModuleNotRegistered(address module);
error Unauthorized();

contract FirstDibsTokenTransferManager is AccessControl {
    /**
     * @dev mapping of module address => to registration status
     * Modules are FirstDibs controlled contracts (e.g. Marketplace contracts) that can call transfer methods on this contract
     * By approving this contract, users will allow all registered 1stDibs modules to handle token transfers for them
     */
    mapping(address => bool) moduleRegistrations;

    constructor(address[] memory _modulesToRegister) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender()); // deployer of the contract gets admin permissions
        for (uint256 i = 0; i < _modulesToRegister.length; i++) {
            moduleRegistrations[_modulesToRegister[i]] = true;
        }
    }

    modifier onlyAdmin() {
        if (!hasRole(DEFAULT_ADMIN_ROLE, _msgSender())) {
            revert Unauthorized();
        }
        _;
    }

    /**
     * @dev ensures only registered modules can invoke the transfer manager
     */
    modifier onlyRegisteredModules() {
        if (!moduleRegistrations[_msgSender()]) {
            revert ModuleNotRegistered(_msgSender());
        }
        _;
    }

    /**
     * @notice register/deregister a transfer module
     * @param _module address of the module to be set as registered / unregistered
     * @param _isRegistered whether or not the module can transfer tokens
     */
    function setRegisteredModule(address _module, bool _isRegistered) external onlyAdmin {
        moduleRegistrations[_module] = _isRegistered;
    }

    /**
     * @notice wrapper function for ERC1155 safe transfer
     * @param _token address of the ERC1155 contract
     * @param _from address to transfer tokens from
     * @param _to address to transfer tokens to
     * @param _tokenId id of the token to transfer
     * @param _amount number of tokens to transfer
     * @param _data calldata
     */
    function erc1155SafeTransferFrom(
        address _token,
        address _from,
        address _to,
        uint256 _tokenId,
        uint256 _amount,
        bytes memory _data
    ) public onlyRegisteredModules {
        IERC1155(_token).safeTransferFrom(_from, _to, _tokenId, _amount, _data);
    }

    /**
     * @notice wrapper function for ERC1155 safe batch transfer
     * @param _token address of the ERC1155 contract
     * @param _from address to transfer tokens from
     * @param _to address to transfer tokens to
     * @param _tokenIds ids of the tokens to transfer
     * @param _amounts respective number of tokens to transfer
     * @param _data calldata
     */
    function erc1155SafeBatchTransferFrom(
        address _token,
        address _from,
        address _to,
        uint256[] memory _tokenIds,
        uint256[] memory _amounts,
        bytes memory _data
    ) public onlyRegisteredModules {
        IERC1155(_token).safeBatchTransferFrom(_from, _to, _tokenIds, _amounts, _data);
    }

    /**
     * @notice wrapper function for ERC721 safe transfer
     * @param _token address of the ERC721 contract
     * @param _from address to transfer tokens from
     * @param _to address to transfer tokens to
     * @param _tokenId id of the token to transfer
     */
    function erc721SafeTransferFrom(
        address _token,
        address _from,
        address _to,
        uint256 _tokenId
    ) public onlyRegisteredModules {
        IERC721(_token).safeTransferFrom(_from, _to, _tokenId);
    }

    /**
     * @notice wrapper function for ERC721 transfer
     * @param _token address of the ERC721 contract
     * @param _from address to transfer tokens from
     * @param _to address to transfer tokens to
     * @param _tokenId id of the token to transfer
     */
    function erc721TransferFrom(
        address _token,
        address _from,
        address _to,
        uint256 _tokenId
    ) public onlyRegisteredModules {
        IERC721(_token).transferFrom(_from, _to, _tokenId);
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts (last updated v4.7.2) (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface,
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            _supportsERC165Interface(account, type(IERC165).interfaceId) &&
            !_supportsERC165Interface(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && _supportsERC165Interface(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = _supportsERC165Interface(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in _interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!_supportsERC165Interface(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function _supportsERC165Interface(address account, bytes4 interfaceId) private view returns (bool) {
        // prepare call
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);

        // perform static call
        bool success;
        uint256 returnSize;
        uint256 returnValue;
        assembly {
            success := staticcall(30000, account, add(encodedParams, 0x20), mload(encodedParams), 0x00, 0x20)
            returnSize := returndatasize()
            returnValue := mload(0x00)
        }

        return success && returnSize >= 0x20 && returnValue > 0;
    }
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

pragma solidity ^0.8.0;

interface IOwnable {
    /**
     * @dev Returns the address of the current owner.
     */
    function owner() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

/// @author: manifold.xyz

import '@openzeppelin/contracts/utils/introspection/IERC165.sol';

/**
 * @dev Lookup engine interface
 */
interface IRoyaltyEngineV1 is IERC165 {
    /**
     * Get the royalty for a given token (address, id) and value amount.  Does not cache the bps/amounts.  Caches the spec for a given token address
     *
     * @param tokenAddress - The address of the token
     * @param tokenId      - The id of the token
     * @param value        - The value you wish to get the royalty of
     *
     * returns Two arrays of equal length, royalty recipients and the corresponding amount each recipient should get
     */
    function getRoyalty(
        address tokenAddress,
        uint256 tokenId,
        uint256 value
    ) external returns (address payable[] memory recipients, uint256[] memory amounts);

    /**
     * View only version of getRoyalty
     *
     * @param tokenAddress - The address of the token
     * @param tokenId      - The id of the token
     * @param value        - The value you wish to get the royalty of
     *
     * returns Two arrays of equal length, royalty recipients and the corresponding amount each recipient should get
     */
    function getRoyaltyView(
        address tokenAddress,
        uint256 tokenId,
        uint256 value
    ) external view returns (address payable[] memory recipients, uint256[] memory amounts);
}

//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.13;

interface IFirstDibsMarketSettingsV2 {
    function globalBuyerPremium() external view returns (uint32);

    function globalMarketCommission() external view returns (uint32);

    function globalMinimumBidIncrement() external view returns (uint32);

    function globalTimeBuffer() external view returns (uint32);

    function globalAuctionDuration() external view returns (uint32);

    function commissionAddress() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/PullPayment.sol)

pragma solidity ^0.8.0;

import "../utils/escrow/EscrowUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Simple implementation of a
 * https://consensys.github.io/smart-contract-best-practices/recommendations/#favor-pull-over-push-for-external-calls[pull-payment]
 * strategy, where the paying contract doesn't interact directly with the
 * receiver account, which must withdraw its payments itself.
 *
 * Pull-payments are often considered the best practice when it comes to sending
 * Ether, security-wise. It prevents recipients from blocking execution, and
 * eliminates reentrancy concerns.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 *
 * To use, derive from the `PullPayment` contract, and use {_asyncTransfer}
 * instead of Solidity's `transfer` function. Payees can query their due
 * payments with {payments}, and retrieve them with {withdrawPayments}.
 *
 * @custom:storage-size 51
 */
abstract contract PullPaymentUpgradeable is Initializable {
    EscrowUpgradeable private _escrow;

    function __PullPayment_init() internal onlyInitializing {
        __PullPayment_init_unchained();
    }

    function __PullPayment_init_unchained() internal onlyInitializing {
        _escrow = new EscrowUpgradeable();
        _escrow.initialize();
    }

    /**
     * @dev Withdraw accumulated payments, forwarding all gas to the recipient.
     *
     * Note that _any_ account can call this function, not just the `payee`.
     * This means that contracts unaware of the `PullPayment` protocol can still
     * receive funds this way, by having a separate account call
     * {withdrawPayments}.
     *
     * WARNING: Forwarding all gas opens the door to reentrancy vulnerabilities.
     * Make sure you trust the recipient, or are either following the
     * checks-effects-interactions pattern or using {ReentrancyGuard}.
     *
     * @param payee Whose payments will be withdrawn.
     *
     * Causes the `escrow` to emit a {Withdrawn} event.
     */
    function withdrawPayments(address payable payee) public virtual {
        _escrow.withdraw(payee);
    }

    /**
     * @dev Returns the payments owed to an address.
     * @param dest The creditor's address.
     */
    function payments(address dest) public view returns (uint256) {
        return _escrow.depositsOf(dest);
    }

    /**
     * @dev Called by the payer to store the sent amount as credit to be pulled.
     * Funds sent in this way are stored in an intermediate {Escrow} contract, so
     * there is no danger of them being spent before withdrawal.
     *
     * @param dest The destination address of the funds.
     * @param amount The amount to transfer.
     *
     * Causes the `escrow` to emit a {Deposited} event.
     */
    function _asyncTransfer(address dest, uint256 amount) internal virtual {
        _escrow.deposit{value: amount}(dest);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/escrow/Escrow.sol)

pragma solidity ^0.8.0;

import "../../access/OwnableUpgradeable.sol";
import "../AddressUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @title Escrow
 * @dev Base escrow contract, holds funds designated for a payee until they
 * withdraw them.
 *
 * Intended usage: This contract (and derived escrow contracts) should be a
 * standalone contract, that only interacts with the contract that instantiated
 * it. That way, it is guaranteed that all Ether will be handled according to
 * the `Escrow` rules, and there is no need to check for payable functions or
 * transfers in the inheritance tree. The contract that uses the escrow as its
 * payment method should be its owner, and provide public methods redirecting
 * to the escrow's deposit and withdraw.
 */
contract EscrowUpgradeable is Initializable, OwnableUpgradeable {
    function __Escrow_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Escrow_init_unchained() internal onlyInitializing {
    }
    function initialize() public virtual initializer {
        __Escrow_init();
    }
    using AddressUpgradeable for address payable;

    event Deposited(address indexed payee, uint256 weiAmount);
    event Withdrawn(address indexed payee, uint256 weiAmount);

    mapping(address => uint256) private _deposits;

    function depositsOf(address payee) public view returns (uint256) {
        return _deposits[payee];
    }

    /**
     * @dev Stores the sent amount as credit to be withdrawn.
     * @param payee The destination address of the funds.
     *
     * Emits a {Deposited} event.
     */
    function deposit(address payee) public payable virtual onlyOwner {
        uint256 amount = msg.value;
        _deposits[payee] += amount;
        emit Deposited(payee, amount);
    }

    /**
     * @dev Withdraw accumulated balance for a payee, forwarding all gas to the
     * recipient.
     *
     * WARNING: Forwarding all gas opens the door to reentrancy vulnerabilities.
     * Make sure you trust the recipient, or are either following the
     * checks-effects-interactions pattern or using {ReentrancyGuard}.
     *
     * @param payee The address whose funds will be withdrawn and transferred to.
     *
     * Emits a {Withdrawn} event.
     */
    function withdraw(address payable payee) public virtual onlyOwner {
        uint256 payment = _deposits[payee];

        _deposits[payee] = 0;

        payee.sendValue(payment);

        emit Withdrawn(payee, payment);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
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
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
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