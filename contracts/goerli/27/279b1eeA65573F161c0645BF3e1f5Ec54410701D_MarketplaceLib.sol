// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

import "@manifoldxyz/libraries-solidity/contracts/access/IAdminControl.sol";

import "../IIdentityVerifier.sol";
import "../ILazyDelivery.sol";
import "../IPriceEngine.sol";

import "./TokenLib.sol";

/**
 * Interface for Ownable contracts
 */
interface IOwnable {
    function owner() external view returns(address);
}

/**
 * @dev Marketplace libraries
 */
library MarketplaceLib {
    using AddressUpgradeable for address;

    // Events
    event CreateListing(uint40 indexed listingId, uint16 marketplaceBPS, uint16 referrerBPS, uint8 listingType, uint24 totalAvailable, uint24 totalPerSale, uint48 startTime, uint48 endTime, uint256 initialAmount, uint16 extensionInterval, uint16 minIncrementBPS, address erc20, address identityVerifier);
    event CreateListingTokenDetails(uint40 indexed listingId, uint256 id, address address_, uint8 spec, bool lazy);

    event PurchaseEvent(uint40 indexed listingId, address referrer, address buyer, uint24 count, uint256 amount);
    event BidEvent(uint40 indexed listingId, address referrer, address bidder, uint256 amount);
    event ModifyListing(uint40 indexed listingId, uint256 initialAmount, uint48 startTime, uint48 endTime);
    event CompleteListing(uint40 indexed listingId, uint16 deliverDeciBPS, address deliverAddress);
    event CancelListing(uint40 indexed listingId, address requestor, uint16 holdbackBPS);

    // Listing types
    enum ListingType {
        INVALID,
        INDIVIDUAL_AUCTION,
        FIXED_PRICE,
        DYNAMIC_PRICE,
        RANKED_AUCTION
    }

    /**
     * @dev Listing structure
     *
     * @param seller          - the selling party
     * @param flags           - bit flag (hasBid, finalized, tokenCreator).  See FLAG_MASK_*
     * @param totalSold       - total number of items sold.  This IS NOT the number of sales.  Number of sales is totalSold/details.totalPerSale.
     * @param marketplaceBPS  - Marketplace fee BPS
     * @param referrerBPS     - Fee BPS for referrer if there is one
     * @param details         - ListingDetails.  Contains listing configuration
     * @param token           - TokenDetails.  Contains the details of token being sold
     * @param receivers       - Array of ListingReceiver structs.  If provided, will distribute sales proceeds to receivers accordingly.
     * @param bid             - Active bid.  Only valid for INDIVIDUAL_AUCTION (1 bid)
     * @param fees            - DeliveryFees.  Contains the delivery fee configuration for the listing
     */
    struct Listing {
        address payable seller;
        uint8 flags;
        uint24 totalSold;
        uint16 marketplaceBPS;
        uint16 referrerBPS;
        ListingDetails details;
        TokenDetails token;
        ListingReceiver[] receivers;
        Bid bid;
        DeliveryFees fees;
    }

    uint8 internal constant FLAG_MASK_HAS_BID = 0x1;
    uint8 internal constant FLAG_MASK_FINALIZED = 0x2;
    uint8 internal constant FLAG_MASK_COMPLETABLE = 0x4;

    /**
     * @dev Listing details structure
     *
     * @param initialAmount     - The initial amount of the listing. For auctions, it represents the reserve price.  For DYNAMIC_PRICE listings, it must be 0.
     * @param type_             - Listing type
     * @param totalAvailable    - Total number of tokens available.  Must be divisible by totalPerSale. For INDIVIDUAL_AUCTION, totalAvailable must equal totalPerSale
     * @param totalPerSale      - Number of tokens the buyer will get per purchase.  Must be 1 if it is a lazy token
     * @param extensionInterval - Only valid for *_AUCTION types. Indicates how long an auction will extend if a bid is made within the last <extensionInterval> seconds of the auction.
     * @param minIncrementBPS   - Only valid for *_AUCTION types. Indicates the minimum bid increase required
     * @param erc20             - If not 0x0, it indicates the erc20 token accepted for this sale
     * @param identityVerifier  - If not 0x0, it indicates the buyers should be verified before any bid or purchase
     * @param startTime         - The start time of the sale.  If set to 0, startTime will be set to the first bid/purchase.
     * @param endTime           - The end time of the sale.  If startTime is 0, represents the duration of the listing upon first bid/purchase.
     */
    struct ListingDetails {
        uint256 initialAmount;
        ListingType type_;
        uint24 totalAvailable;
        uint24 totalPerSale;
        uint16 extensionInterval;
        uint16 minIncrementBPS;
        address erc20;
        address identityVerifier;
        uint48 startTime;
        uint48 endTime;
    }

    /**
     * @dev Token detail structure
     *
     * @param address_  - The contract address of the token
     * @param id        - The token id (or for a lazy asset, the asset id)
     * @param spec      - The spec of the token.  If it's a lazy token, it must be blank.
     * @param lazy      - True if token is to be lazy minted, false otherwise.  If lazy, the contract address must support ILazyDelivery
     */
    struct TokenDetails {
        uint256 id;
        address address_;
        TokenLib.Spec spec;
        bool lazy;
    }

    /**
     * @dev Fee configuration for listing
     *
     * @param deliverDeciBPS         - Additional fee needed to deliver the token (BPS)
     * @param deliverAddress     - Additional fee delivery address
     */
    struct DeliveryFees {
        uint16 deliverDeciBPS;
        address payable deliverAddress;
    }

    /**
     * Listing receiver.  The array of listing receivers must add up to 10000 BPS if provided.
     */
    struct ListingReceiver {
        address payable receiver;
        uint16 receiverBPS;
    }

    /**
     * Represents an active bid
     *
     * @param referrer     - The referrer
     * @param bidder       - The bidder
     * @param delivered    - Whether or not the token has been delivered.
     * @param settled      - Whether or not the seller has been paid
     * @param refunded     - Whether or not the bid has been refunded
     */
    struct Bid {
        uint256 amount;
        address payable bidder;
        bool delivered;
        bool settled;
        bool refunded;
        uint48 timestamp;
        address payable referrer;
    }

    /**
     * Construct a marketplace listing
     */
    function constructListing(uint40 listingId, Listing storage listing, ListingDetails calldata listingDetails, TokenDetails calldata tokenDetails, ListingReceiver[] calldata listingReceivers) public {
        require(tokenDetails.address_.isContract(), "Token address must be a contract");
        require(listingDetails.endTime > listingDetails.startTime, "End time must be after start time");
        require(listingDetails.startTime == 0 || listingDetails.startTime > block.timestamp, "Start and end time cannot occur in the past");
        require(listingDetails.totalAvailable % listingDetails.totalPerSale == 0, "Invalid token config");
        
        if (listingDetails.identityVerifier != address(0)) {
            require(ERC165Checker.supportsInterface(listingDetails.identityVerifier, type(IIdentityVerifier).interfaceId), "Misconfigured verifier");
        }
        
        if (listingReceivers.length > 0) {
            uint256 totalBPS;
            for (uint i = 0; i < listingReceivers.length; i++) {
                listing.receivers.push(listingReceivers[i]);
                totalBPS += listingReceivers[i].receiverBPS;
            }
            require(totalBPS == 10000, "Invalid receiver config");
        }

        if (listingDetails.type_ == ListingType.INDIVIDUAL_AUCTION) {
            require(listingDetails.totalAvailable == listingDetails.totalPerSale, "Invalid token config");
        } else if (listingDetails.type_ == ListingType.DYNAMIC_PRICE) {
            require(tokenDetails.lazy && listingDetails.initialAmount == 0, "Invalid listing config");
            require(ERC165Checker.supportsInterface(tokenDetails.address_, type(IPriceEngine).interfaceId), "Lazy delivered dynamic price items requires token address to implement IPriceEngine");
        } else if (listingDetails.type_ == ListingType.RANKED_AUCTION) {
            require(tokenDetails.lazy && listingDetails.totalAvailable <= 256, "Invalid listing config");
        }

        // Purchase types        
        if (listingDetails.type_ == ListingType.FIXED_PRICE || listingDetails.type_ == ListingType.DYNAMIC_PRICE) {
            require(listingDetails.extensionInterval == 0 && listingDetails.minIncrementBPS == 0, "Invalid listing config");
        } else if (listingDetails.type_ == ListingType.INDIVIDUAL_AUCTION) {
            // Pre-initialize values to reduce cost of first bid
            listing.bid.amount = 1;
            listing.bid.timestamp = 1;
        }

        if (tokenDetails.lazy) {
            require(listingDetails.totalPerSale == 1, "Invalid token config");
            require(ERC165Checker.supportsInterface(tokenDetails.address_, type(ILazyDelivery).interfaceId), "Lazy delivery requires token address to implement ILazyDelivery");
        } else {
            require(listingDetails.type_ == ListingType.INDIVIDUAL_AUCTION || listingDetails.type_ == ListingType.FIXED_PRICE, "Invalid type");
            _intakeToken(tokenDetails.spec, tokenDetails.address_, tokenDetails.id, listingDetails.totalAvailable, listing.seller);
        }

        // Set Listing Data
        listing.details = listingDetails;
        listing.token = tokenDetails;
        
        _emitCreateListing(listingId, listing);

    }

    function _emitCreateListing(uint40 listingId, Listing storage listing) private {
        emit CreateListing(listingId, listing.marketplaceBPS, listing.referrerBPS, uint8(listing.details.type_), listing.details.totalAvailable, listing.details.totalPerSale, listing.details.startTime, listing.details.endTime, listing.details.initialAmount, listing.details.extensionInterval, listing.details.minIncrementBPS, listing.details.erc20, listing.details.identityVerifier);
        emit CreateListingTokenDetails(listingId, listing.token.id, listing.token.address_, uint8(listing.token.spec), listing.token.lazy);
    }

    function _intakeToken(TokenLib.Spec tokenSpec, address tokenAddress, uint256 tokenId, uint256 tokensToTransfer, address from) private {
        if (tokenSpec == TokenLib.Spec.ERC721) {
            require(tokensToTransfer == 1, "ERC721 invalid number of tokens to transfer");
            TokenLib._erc721Transfer(tokenAddress, tokenId, from, address(this));
        } else if (tokenSpec == TokenLib.Spec.ERC1155) {
            TokenLib._erc1155Transfer(tokenAddress, tokenId, tokensToTransfer, from, address(this));
        } else {
            revert("Unsupported token spec");
        }
    }

    function modifyListing(uint40 listingId, Listing storage listing, uint256 initialAmount, uint48 startTime, uint48 endTime) public {
        require(endTime > startTime, "End time must be after start time");
        require(startTime == 0 || startTime > block.timestamp, "Start and end time cannot occur in the past");
        require(listing.details.startTime == 0 || (block.timestamp < listing.details.startTime && (listing.flags & MarketplaceLib.FLAG_MASK_FINALIZED) == 0), "Cannot modify listing that has already started or completed");
        require(listing.details.type_ != MarketplaceLib.ListingType.DYNAMIC_PRICE || initialAmount == 0, "Invalid listing config");
        listing.details.initialAmount = initialAmount;
        listing.details.startTime = startTime;
        listing.details.endTime = endTime;

        emit ModifyListing(listingId, initialAmount, startTime, endTime);
    }

    function completeListing(uint40 listingId, Listing storage listing, DeliveryFees calldata fees) public {
        require((listing.flags & MarketplaceLib.FLAG_MASK_FINALIZED) == 0, "Listing not found");
        require(listing.details.startTime != 0 && listing.details.endTime < block.timestamp, "Listing still active");
        listing.fees = fees;
        listing.flags  |= MarketplaceLib.FLAG_MASK_COMPLETABLE;

        emit CompleteListing(listingId, fees.deliverDeciBPS, fees.deliverAddress);
    }

}

// SPDX-License-Identifier: MIT

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
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);
        (bool success, bytes memory result) = account.staticcall{gas: 30000}(encodedParams);
        if (result.length < 32) return false;
        return success && abi.decode(result, (bool));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @dev Interface for admin control
 */
interface IAdminControl is IERC165 {

    event AdminApproved(address indexed account, address indexed sender);
    event AdminRevoked(address indexed account, address indexed sender);

    /**
     * @dev gets address of all admins
     */
    function getAdmins() external view returns (address[] memory);

    /**
     * @dev add an admin.  Can only be called by contract owner.
     */
    function approveAdmin(address admin) external;

    /**
     * @dev remove an admin.  Can only be called by contract owner.
     */
    function revokeAdmin(address admin) external;

    /**
     * @dev checks whether or not given address is an admin
     * Returns True if they are
     */
    function isAdmin(address admin) external view returns (bool);

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IIdentityVerifier is IERC165 {

    /**
     *  @dev Verify that the buyer can purchase/bid
     *
     *  @param listingId      The listingId associated with this verification
     *  @param identity       The identity to verify
     *  @param tokenAddress   The tokenAddress associated with this verification
     *  @param tokenId        The tokenId associated with this verification
     *  @param requestCount   The number of items being requested to purchase/bid
     *  @param requestAmount  The amount being requested
     *  @param requestERC20   The erc20 token address of the amount (0x0 if ETH)
     *  @param data           Additional data needed to verify
     *
     */
    function verify(uint40 listingId, address identity, address tokenAddress, uint256 tokenId, uint24 requestCount, uint256 requestAmount, address requestERC20, bytes calldata data) external returns (bool);

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface ILazyDelivery is IERC165 {

    /**
     *  @dev Deliver an asset and deliver to the specified party
     *  When implementing this interface, please ensure you restrict access.
     *  If using LazyDeliver.sol, you can use authorizedDelivererRequired modifier to restrict access. 
     *  Delivery can be for an existing asset or newly minted assets.
     * 
     *  @param listingId      The listingId associated with this delivery.  Useful for permissioning.
     *  @param to             The address to deliver the asset to
     *  @param assetId        The assetId to deliver
     *  @param payableCount   The number of assets to deliver
     *  @param payableAmount  The amount seller will receive upon delivery of asset
     *  @param payableERC20   The erc20 token address of the amount (0x0 if ETH)
     *  @param index          (Optional): Index value for certain sales methods, such as ranked auctions
     *
     *  @return any Only used for Ranked Auctions and represents the refund amount you want to give.
     *              Value is unused for all other listing types
     *
     *  Suggestion: If determining a refund amount based on total sales data, do not enable this function
     *              until the sales data is finalized and recorded in contract
     *
     *  Exploit Prevention for dynamic/random assignment
     *  1. Ensure attributes are not assigned until AFTER underlying mint if using _safeMint.
     *     This is to ensure a receiver cannot check attribute values on receive and revert transaction.
     *     However, even if this is the case, the recipient can wrap its mint in a contract that checks 
     *     post mint completion and reverts if unsuccessful.
     *  2. Ensure that "to" is not a contract address. This prevents a contract from doing the lazy 
     *     mint, which could exploit random assignment by reverting if they do not receive the desired
     *     item post mint.
     */
    function deliver(uint40 listingId, address to, uint256 assetId, uint24 payableCount, uint256 payableAmount, address payableERC20, uint256 index) external returns(uint256);

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IPriceEngine is IERC165 {

    /**
     *  @dev Determine price of an asset given the number
     *  already minted.
     */
    function price(uint256 assetId, uint256 alreadyMinted, uint24 count) view external returns (uint256);

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

/**
 * @dev Token specs and functions
 */
library TokenLib {
    // Spec types
    enum Spec {
        NONE,
        ERC721,
        ERC1155
    }

    function _getSpecString(Spec spec) internal pure returns (string memory) {
        if (spec == Spec.ERC721) {
           return "erc721";
        } else if (spec == Spec.ERC1155) {
            return "erc1155";
        } else {
            return "";
        }
    }

    function _erc721Transfer(address tokenAddress, uint256 tokenId, address from, address to) internal {
        // Transfer token
        IERC721(tokenAddress).transferFrom(from, to, tokenId);
    }

    function _erc1155Transfer(address tokenAddress, uint256 tokenId, uint256 value, address from, address to) internal {
        // Transfer token
        IERC1155(tokenAddress).safeTransferFrom(from, to, tokenId, value, "");
    }

}

// SPDX-License-Identifier: MIT

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
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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