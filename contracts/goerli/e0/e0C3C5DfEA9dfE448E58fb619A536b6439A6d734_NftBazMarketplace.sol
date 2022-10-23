// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

error NftBazMarketplace__PriceNotMet(
    address contractAddress,
    uint256 tokenId,
    uint256 price
);
error NftBazMarketplace__NotListed(
    address contractAddress,
    uint256 tokenId,
    address seller
);
error NftBazMarketplace__AlreadyListed(
    address contractAddress,
    uint256 tokenId,
    address seller
);
error NftBazMarketplace__InvalidData();
error NftBazMarketplace__NotOwner();
error NftBazMarketplace__InvalidPaymentToken();
error NftBazMarketplace__InvalidContractAddress();
error NftBazMarketplace__ItemExpired();
error NftBazMarketplace__NotApprovedForMarketplace();
error NftBazMarketplace__NotEnoughItems();
error NftBazMarketplace__OfferNotFound(
    address contractAddress,
    uint256 tokenId,
    address offerer
);

contract NftBazMarketplace is ReentrancyGuard, Ownable {
    /// @notice Events for the contract
    event ItemListed(
        address indexed seller,
        address indexed contractAddress,
        uint256 indexed tokenId,
        uint256 quantity,
        address payToken,
        uint256 pricePerItem
    );
    event ItemSold(
        address indexed seller,
        address indexed buyer,
        address indexed contractAddress,
        uint256 tokenId,
        uint256 quantity,
        address payToken,
        uint256 pricePerItem
    );
    event ListingUpdated(
        address indexed seller,
        address indexed contractAddress,
        uint256 indexed tokenId,
        address payToken,
        uint256 newPrice
    );
    event ListingCanceled(
        address indexed seller,
        address indexed contractAddress,
        uint256 indexed tokenId
    );
    event OfferCreated(
        address indexed offerer,
        address indexed contractAddress,
        uint256 indexed tokenId,
        uint256 quantity,
        address payToken,
        uint256 totalPrice,
        uint256 deadline
    );
    event OfferCanceled(
        address indexed offerer,
        address indexed contractAddress,
        uint256 indexed tokenId
    );
    event PlatformFeeUpdated(uint16 platformFee);
    event PlatformFeeRecipientUpdated(address platformFeeRecipient);

    /// @notice Structure for listed items
    struct Listing {
        uint256 quantity;
        address payToken;
        uint256 pricePerItem;
    }

    /// @notice Structure for offer
    struct Offer {
        address payToken;
        uint256 quantity;
        uint256 totalPrice;
        uint256 deadline;
    }

    bytes4 private constant INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 private constant INTERFACE_ID_ERC1155 = 0xd9b67a26;
    bytes4 private constant INTERFACE_ID_ERC2981 = 0x2a55205a;

    /// @notice Marketplace Supported Tokens List
    address[] public s_supportedTokens;

    /// @notice NftAddress -> Token ID -> Seller -> Listing item
    mapping(address => mapping(uint256 => mapping(address => Listing)))
        public s_listings;

    /// @notice NftAddress -> Token ID -> Offerer -> Offer
    mapping(address => mapping(uint256 => mapping(address => Offer)))
        public s_offers;

    /// @notice Platform fee
    uint16 public s_platformFee;

    /// @notice Platform fee recipient
    address private s_feeRecipient;

    modifier isListed(
        address _contractAddress,
        uint256 _tokenId,
        address _seller
    ) {
        Listing memory listing = s_listings[_contractAddress][_tokenId][
            _seller
        ];
        if (listing.quantity == 0)
            revert NftBazMarketplace__NotListed(
                _contractAddress,
                _tokenId,
                _seller
            );
        _;
    }

    modifier notListed(
        address _contractAddress,
        uint256 _tokenId,
        address _seller
    ) {
        Listing memory listing = s_listings[_contractAddress][_tokenId][
            _seller
        ];
        if (listing.quantity > 0)
            revert NftBazMarketplace__AlreadyListed(
                _contractAddress,
                _tokenId,
                _seller
            );
        _;
    }

    modifier offerExists(
        address _contractAddress,
        uint256 _tokenId,
        address _offerer
    ) {
        Offer memory offer = s_offers[_contractAddress][_tokenId][_offerer];
        if (offer.quantity == 0)
            revert NftBazMarketplace__OfferNotFound(
                _contractAddress,
                _tokenId,
                _offerer
            );
        _;
    }

    modifier validPayToken(address _payToken) {
        bool notFound = true;
        for (uint256 i; i < s_supportedTokens.length; i++) {
            if (s_supportedTokens[i] == _payToken) notFound = false;
        }
        if (notFound) revert NftBazMarketplace__InvalidPaymentToken();
        _;
    }

    constructor(uint16 _platformFee, address[] memory _supportedTokens) {
        s_feeRecipient = msg.sender;
        s_platformFee = _platformFee;
        s_supportedTokens = _supportedTokens;
    }

    /// @notice Method for listing NFT
    /// @param _contractAddress Address of NFT contract
    /// @param _tokenId Token ID of NFT
    /// @param _quantity token amount to list (needed for ERC-1155 NFTs, set as 1 for ERC-721)
    /// @param _payToken Paying token
    /// @param _pricePerItem sale price for each item
    function listItem(
        address _contractAddress,
        uint256 _tokenId,
        uint256 _quantity,
        address _payToken,
        uint256 _pricePerItem
    )
        external
        notListed(_contractAddress, _tokenId, msg.sender)
        validPayToken(_payToken)
    {
        if (_quantity < 1 || _pricePerItem < 1)
            revert NftBazMarketplace__InvalidData();

        if (IERC165(_contractAddress).supportsInterface(INTERFACE_ID_ERC721)) {
            if (_quantity != 1) revert NftBazMarketplace__InvalidData();
            IERC721 nft = IERC721(_contractAddress);

            if (nft.isApprovedForAll(msg.sender, address(this)))
                revert NftBazMarketplace__NotApprovedForMarketplace();
        }

        if (IERC165(_contractAddress).supportsInterface(INTERFACE_ID_ERC1155)) {
            IERC1155 nft = IERC1155(_contractAddress);
            if (nft.isApprovedForAll(msg.sender, address(this)))
                revert NftBazMarketplace__NotApprovedForMarketplace();

            if (nft.balanceOf(msg.sender, _tokenId) >= _quantity)
                revert NftBazMarketplace__NotEnoughItems();
        }

        s_listings[_contractAddress][_tokenId][msg.sender] = Listing(
            _quantity,
            _payToken,
            _pricePerItem
        );

        emit ItemListed(
            msg.sender,
            _contractAddress,
            _tokenId,
            _quantity,
            _payToken,
            _pricePerItem
        );
    }

    /// @notice Method for canceling listed NFT
    /// @param _contractAddress Address of NFT contract
    /// @param _tokenId Token ID of NFT
    function cancelListing(address _contractAddress, uint256 _tokenId)
        external
        nonReentrant
        isListed(_contractAddress, _tokenId, msg.sender)
    {
        _deleteListing(_contractAddress, _tokenId, msg.sender);
    }

    /// @notice Method for updating listed NFT
    /// @param _contractAddress Address of NFT contract
    /// @param _tokenId Token ID of NFT
    /// @param _payToken payment token
    /// @param _newPrice New sale price for each item
    function updateListing(
        address _contractAddress,
        uint256 _tokenId,
        address _payToken,
        uint256 _newPrice
    )
        external
        nonReentrant
        isListed(_contractAddress, _tokenId, msg.sender)
        validPayToken(_payToken)
    {
        Listing storage listedItem = s_listings[_contractAddress][_tokenId][
            msg.sender
        ];

        listedItem.payToken = _payToken;
        listedItem.pricePerItem = _newPrice;
        emit ListingUpdated(
            msg.sender,
            _contractAddress,
            _tokenId,
            _payToken,
            _newPrice
        );
    }

    /// @notice Method for buying listed NFT
    /// @param _contractAddress NFT contract address
    /// @param _tokenId TokenId
    function buyItem(
        address _contractAddress,
        uint256 _tokenId,
        address _payToken,
        address _seller
    ) external nonReentrant isListed(_contractAddress, _tokenId, _seller) {
        Listing memory listedItem = s_listings[_contractAddress][_tokenId][
            _seller
        ];

        if (listedItem.payToken != _payToken)
            revert NftBazMarketplace__InvalidPaymentToken();

        uint256 buyerBalance = IERC20(listedItem.payToken).balanceOf(
            msg.sender
        );
        uint256 price = listedItem.pricePerItem * listedItem.quantity;

        if (buyerBalance < price)
            revert NftBazMarketplace__PriceNotMet(
                _contractAddress,
                _tokenId,
                price
            );

        _buyItem(_contractAddress, _tokenId, _payToken, _seller);
    }

    /// @notice Method for offering item
    /// @param _contractAddress NFT contract address
    /// @param _tokenId TokenId
    /// @param _payToken Paying token
    /// @param _quantity Quantity of items
    /// @param _totalPrice Total Price
    /// @param _deadline Offer expiration
    function createOffer(
        address _contractAddress,
        uint256 _tokenId,
        address _payToken,
        uint256 _quantity,
        uint256 _totalPrice,
        uint256 _deadline
    ) external payable nonReentrant validPayToken(_payToken) {
        if (
            !IERC165(_contractAddress).supportsInterface(INTERFACE_ID_ERC721) &&
            !IERC165(_contractAddress).supportsInterface(INTERFACE_ID_ERC1155)
        ) revert NftBazMarketplace__InvalidContractAddress();

        if (_deadline < block.timestamp)
            revert NftBazMarketplace__InvalidData();

        IERC20(_payToken).transferFrom(msg.sender, address(this), _totalPrice);

        s_offers[_contractAddress][_tokenId][msg.sender] = Offer(
            _payToken,
            _quantity,
            _totalPrice,
            _deadline
        );

        emit OfferCreated(
            msg.sender,
            _contractAddress,
            _tokenId,
            _quantity,
            _payToken,
            _totalPrice,
            _deadline
        );
    }

    /// @notice Method for canceling the offer
    /// @param _contractAddress NFT contract address
    /// @param _tokenId TokenId
    function cancelOffer(address _contractAddress, uint256 _tokenId)
        external
        nonReentrant
        offerExists(_contractAddress, _tokenId, msg.sender)
    {
        Offer memory offer = s_offers[_contractAddress][_tokenId][msg.sender];

        IERC20(offer.payToken).transfer(msg.sender, offer.totalPrice);

        delete (s_offers[_contractAddress][_tokenId][msg.sender]);
        emit OfferCanceled(msg.sender, _contractAddress, _tokenId);
    }

    /// @notice Method for accepting the offer
    /// @param _contractAddress NFT contract address
    /// @param _tokenId TokenId
    /// @param _offerer Offer creator address
    function acceptOffer(
        address _contractAddress,
        uint256 _tokenId,
        address _offerer
    ) external nonReentrant offerExists(_contractAddress, _tokenId, _offerer) {
        Offer memory offer = s_offers[_contractAddress][_tokenId][_offerer];
        Listing memory listing = s_listings[_contractAddress][_tokenId][
            msg.sender
        ];

        if (listing.quantity == 0)
            revert NftBazMarketplace__NotListed(
                _contractAddress,
                _tokenId,
                msg.sender
            );

        if (offer.deadline < block.timestamp)
            revert NftBazMarketplace__ItemExpired();

        uint256 price = offer.totalPrice;
        uint256 feeAmount = (price * s_platformFee) / 100;

        uint256 royaltyFee;
        address royaltyFeeRecipient;

        if (IERC165(_contractAddress).supportsInterface(INTERFACE_ID_ERC2981)) {
            (address royaltyRecipient, uint256 royaltyAmount) = IERC2981(
                _contractAddress
            ).royaltyInfo(_tokenId, price - feeAmount);

            royaltyFee = royaltyAmount;
            royaltyFeeRecipient = royaltyRecipient;
        }

        IERC20(offer.payToken).transfer(
            msg.sender,
            price - feeAmount - royaltyFee
        );

        IERC20(offer.payToken).transfer(s_feeRecipient, feeAmount);

        if (royaltyFee != 0)
            IERC20(offer.payToken).transfer(royaltyFeeRecipient, royaltyFee);

        // Transfer NFT to buyer
        IERC165(_contractAddress).supportsInterface(INTERFACE_ID_ERC721)
            ? IERC721(_contractAddress).safeTransferFrom(
                msg.sender,
                _offerer,
                _tokenId
            )
            : IERC1155(_contractAddress).safeTransferFrom(
                msg.sender,
                _offerer,
                _tokenId,
                offer.quantity,
                bytes("")
            );

        delete (s_listings[_contractAddress][_tokenId][msg.sender]);
        delete (s_offers[_contractAddress][_tokenId][_offerer]);

        emit ItemSold(
            msg.sender,
            _offerer,
            _contractAddress,
            _tokenId,
            offer.quantity,
            offer.payToken,
            offer.totalPrice
        );
        emit OfferCanceled(_offerer, _contractAddress, _tokenId);
    }

    ////////////////////////////
    ///   Owner Functions    ///
    ////////////////////////////

    /**
     @notice Method for updating platform fee
     @dev Only admin
     @param _platformFee uint16 the platform fee to set
     */
    function updatePlatformFee(uint16 _platformFee) external onlyOwner {
        s_platformFee = _platformFee;
        emit PlatformFeeUpdated(_platformFee);
    }

    /**
     @notice Method for updating platform fee address
     @dev Only admin
     @param _platformFeeRecipient payable address the address to sends the funds to
     */
    function updatePlatformFeeRecipient(address _platformFeeRecipient)
        external
        onlyOwner
    {
        s_feeRecipient = _platformFeeRecipient;
        emit PlatformFeeRecipientUpdated(_platformFeeRecipient);
    }

    /**
     @notice Method for updating platform supported tokens
     @dev Only admin
     @param _supportedTokens array of new supported tokens
     */
    function updateSupportedTokens(address[] memory _supportedTokens)
        external
        onlyOwner
    {
        s_supportedTokens = _supportedTokens;
    }

    ////////////////////////////
    /// Internal and Private ///
    ////////////////////////////

    function _buyItem(
        address _contractAddress,
        uint256 _tokenId,
        address _payToken,
        address _seller
    ) private {
        Listing memory listedItem = s_listings[_contractAddress][_tokenId][
            _seller
        ];

        uint256 price = listedItem.pricePerItem * listedItem.quantity;
        uint256 feeAmount = (price * s_platformFee) / 100;

        uint256 royaltyFee;
        address royaltyFeeRecipient;

        if (IERC165(_contractAddress).supportsInterface(INTERFACE_ID_ERC2981)) {
            (address royaltyRecipient, uint256 royaltyAmount) = IERC2981(
                _contractAddress
            ).royaltyInfo(_tokenId, price - feeAmount);

            royaltyFee = royaltyAmount;
            royaltyFeeRecipient = royaltyRecipient;
        }

        IERC20(listedItem.payToken).transferFrom(
            msg.sender,
            _seller,
            price - feeAmount - royaltyFee
        );

        IERC20(listedItem.payToken).transferFrom(
            msg.sender,
            s_feeRecipient,
            feeAmount
        );

        if (royaltyFee != 0)
            IERC20(listedItem.payToken).transferFrom(
                msg.sender,
                royaltyFeeRecipient,
                royaltyFee
            );

        // Transfer NFT to buyer
        IERC165(_contractAddress).supportsInterface(INTERFACE_ID_ERC721)
            ? IERC721(_contractAddress).safeTransferFrom(
                _seller,
                msg.sender,
                _tokenId
            )
            : IERC1155(_contractAddress).safeTransferFrom(
                _seller,
                msg.sender,
                _tokenId,
                listedItem.quantity,
                bytes("")
            );

        _deleteListing(_contractAddress, _tokenId, _seller);
        emit ItemSold(
            _seller,
            msg.sender,
            _contractAddress,
            _tokenId,
            listedItem.quantity,
            _payToken,
            listedItem.pricePerItem
        );
    }

    function _deleteListing(
        address _contractAddress,
        uint256 _tokenId,
        address _seller
    ) private {
        delete (s_listings[_contractAddress][_tokenId][_seller]);
        emit ListingCanceled(_seller, _contractAddress, _tokenId);
    }

    ////////////////////////////
    ///  Getter Functions   ///
    ////////////////////////////

    function getListing(
        address _contractAddress,
        uint256 _tokenId,
        address _seller
    ) external view returns (Listing memory) {
        return s_listings[_contractAddress][_tokenId][_seller];
    }

    function getOffer(
        address _contractAddress,
        uint256 _tokenId,
        address _offerer
    ) external view returns (Offer memory) {
        return s_offers[_contractAddress][_tokenId][_offerer];
    }

    function getSupportedTokens() external view returns (address[] memory) {
        return s_supportedTokens;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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