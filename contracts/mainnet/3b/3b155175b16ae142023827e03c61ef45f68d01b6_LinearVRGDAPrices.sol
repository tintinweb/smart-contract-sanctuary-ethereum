// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1155.sol)

pragma solidity ^0.8.0;

import "../token/ERC1155/IERC1155Upgradeable.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981Upgradeable is IERC165Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155ReceiverUpgradeable is IERC165Upgradeable {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./ISlicer.sol";
import "./ISliceCore.sol";

interface IFundsModule {
  function JBProjectId() external view returns (uint256 projectId);

  function sliceCore() external view returns (ISliceCore sliceCoreAddress);

  function balances(address account, address currency)
    external
    view
    returns (uint128 accountBalance, uint128 protocolPayment);

  function depositEth(address account, uint256 protocolPayment)
    external
    payable;

  function depositTokenFromSlicer(
    uint256 tokenId,
    address account,
    address currency,
    uint256 amount,
    uint256 protocolPayment
  ) external;

  function withdraw(address account, address currency) external;

  function batchWithdraw(address account, address[] memory currencies) external;

  function withdrawOnRelease(
    uint256 tokenId,
    address account,
    address currency,
    uint256 amount,
    uint256 protocolPayment
  ) external payable;

  function batchReleaseSlicers(
    ISlicer[] memory slicers,
    address account,
    address currency,
    bool triggerWithdraw
  ) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "../structs/Function.sol";
import "../structs/Price.sol";
import "../structs/ProductParams.sol";
import "../structs/PurchaseParams.sol";
import "./ISliceCore.sol";
import "./IFundsModule.sol";

interface IProductsModule {
  function sliceCore() external view returns (ISliceCore sliceCoreAddress);

  function fundsModule()
    external
    view
    returns (IFundsModule fundsModuleAddress);

  function addProduct(
    uint256 slicerId,
    ProductParams memory params,
    Function memory externalCall_
  ) external;

  function setProductInfo(
    uint256 slicerId,
    uint256 productId,
    uint8 newMaxUnits,
    bool isFree,
    bool isInfinite,
    uint32 newUnits,
    CurrencyPrice[] memory currencyPrices
  ) external;

  function removeProduct(uint256 slicerId, uint256 productId) external;

  function payProducts(address buyer, PurchaseParams[] calldata purchases)
    external
    payable;

  function releaseEthToSlicer(uint256 slicerId) external;

  // function _setCategoryAddress(uint256 categoryIndex, address newCategoryAddress) external;

  function ethBalance(uint256 slicerId) external view returns (uint256);

  function productPrice(
    uint256 slicerId,
    uint256 productId,
    address currency,
    uint256 quantity,
    address buyer,
    bytes memory data
  ) external view returns (Price memory price);

  function validatePurchaseUnits(
    address account,
    uint256 slicerId,
    uint256 productId
  ) external view returns (uint256 purchases);

  function validatePurchase(uint256 slicerId, uint256 productId)
    external
    view
    returns (uint256 purchases, bytes memory purchaseData);

  function availableUnits(uint256 slicerId, uint256 productId)
    external
    view
    returns (uint256 units, bool isInfinite);

  function isProductOwner(
    uint256 slicerId,
    uint256 productId,
    address account
  ) external view returns (bool isAllowed);

  // function categoryAddress(uint256 categoryIndex) external view returns (address);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./ISlicerManager.sol";
import "../structs/SliceParams.sol";
import "../structs/SlicerParams.sol";
import "@openzeppelin-upgradeable/interfaces/IERC1155Upgradeable.sol";
import "@openzeppelin-upgradeable/interfaces/IERC2981Upgradeable.sol";

interface ISliceCore is IERC1155Upgradeable, IERC2981Upgradeable {
  function slicerManager()
    external
    view
    returns (ISlicerManager slicerManagerAddress);

  function slice(SliceParams calldata params) external;

  function reslice(
    uint256 tokenId,
    address payable[] calldata accounts,
    int32[] calldata tokensDiffs
  ) external;

  function slicerBatchTransfer(
    address from,
    address[] memory recipients,
    uint256 id,
    uint256[] memory amounts,
    bool release
  ) external;

  function safeTransferFromUnreleased(
    address from,
    address to,
    uint256 id,
    uint256 amount,
    bytes memory data
  ) external;

  function setController(uint256 id, address newController) external;

  function setRoyalty(
    uint256 tokenId,
    bool isSlicer,
    bool isActive,
    uint256 royaltyPercentage
  ) external;

  function slicers(uint256 id) external view returns (address);

  function controller(uint256 id) external view returns (address);

  function totalSupply(uint256 id) external view returns (uint256);

  function supply() external view returns (uint256);

  function exists(uint256 id) external view returns (bool);

  function owner() external view returns (address owner);

  function _setBasePath(string calldata basePath_) external;

  function _togglePause() external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin-upgradeable/token/ERC1155/IERC1155ReceiverUpgradeable.sol";
import "@openzeppelin-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";

interface ISlicer is IERC721ReceiverUpgradeable, IERC1155ReceiverUpgradeable {
  function release(
    address account,
    address currency,
    bool withdraw
  ) external;

  function batchReleaseAccounts(
    address[] memory accounts,
    address currency,
    bool withdraw
  ) external;

  function unreleased(address account, address currency)
    external
    view
    returns (uint256 unreleasedAmount);

  function getFee() external view returns (uint256 fee);

  function getFeeForAccount(address account)
    external
    view
    returns (uint256 fee);

  function slicerInfo()
    external
    view
    returns (
      uint256 tokenId,
      uint256 minimumShares,
      address creator,
      bool isImmutable,
      bool currenciesControlled,
      bool productsControlled,
      bool acceptsAllCurrencies,
      address[] memory currencies
    );

  function isPayeeAllowed(address payee) external view returns (bool);

  function acceptsCurrency(address currency) external view returns (bool);

  function _updatePayees(
    address payable sender,
    address receiver,
    bool toRelease,
    uint256 senderShares,
    uint256 transferredShares
  ) external;

  function _updatePayeesReslice(
    address payable[] memory accounts,
    int32[] memory tokensDiffs,
    uint32 totalSupply
  ) external;

  function _setChildSlicer(uint256 id, bool addChildSlicerMode) external;

  function _setTotalShares(uint256 totalShares) external;

  function _addCurrencies(address[] memory currencies) external;

  function _setCustomFee(bool customFeeActive, uint256 customFee) external;

  function _releaseFromSliceCore(
    address account,
    address currency,
    uint256 accountSlices
  ) external;

  function _releaseFromFundsModule(address account, address currency)
    external
    returns (uint256 amount, uint256 protocolPayment);

  function _handle721Purchase(
    address buyer,
    address contractAddress,
    uint256 tokenId
  ) external;

  function _handle1155Purchase(
    address buyer,
    address contractAddress,
    uint256 quantity,
    uint256 tokenId
  ) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
import "../structs/SliceParams.sol";

interface ISlicerManager {
  function implementation() external view returns (address);

  function _createSlicer(
    address creator,
    uint256 id,
    SliceParams calldata params
  ) external returns (address);

  function _upgradeSlicers(address newLogicImpl) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface ISliceProductPrice {
  function productPrice(
    uint256 slicerId,
    uint256 productId,
    address currency,
    uint256 quantity,
    address buyer,
    bytes memory data
  ) external view returns (uint256 ethPrice, uint256 currencyPrice);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct CurrencyPrice {
    uint248 value;
    bool dynamicPricing;
    address externalAddress;
    address currency;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @param data data sent to `externalAddress`
 * @param value Amount or percentage of ETH / token forwarded to `externalAddress`
 * @param externalAddress Address to be called during external call
 * @param checkFunctionSignature The timestamp when the slicer becomes releasable
 * @param execFunctionSignature The timestamp when the slicer becomes transferable
 */

struct Function {
    bytes data;
    uint256 value;
    address externalAddress;
    bytes4 checkFunctionSignature;
    bytes4 execFunctionSignature;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct Payee {
    address account;
    uint32 shares;
    bool transfersAllowedWhileLocked;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct Price {
    uint256 eth;
    uint256 currency;
    uint256 ethExternalCall;
    uint256 currencyExternalCall;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SubSlicerProduct.sol";
import "./CurrencyPrice.sol";

struct ProductParams {
    SubSlicerProduct[] subSlicerProducts;
    CurrencyPrice[] currencyPrices;
    bytes data;
    bytes purchaseData;
    uint32 availableUnits;
    // uint32 categoryIndex;
    uint8 maxUnitsPerBuyer;
    bool isFree;
    bool isInfinite;
    bool isExternalCallPaymentRelative;
    bool isExternalCallPreferredToken;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct PurchaseParams {
    uint128 slicerId;
    uint32 quantity;
    address currency;
    uint32 productId;
    bytes buyerCustomData;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../structs/Payee.sol";

/**
 * @param payees Addresses and shares of the initial payees
 * @param minimumShares Amount of shares that gives an account access to restricted
 * @param currencies Array of tokens accepted by the slicer
 * @param releaseTimelock The timestamp when the slicer becomes releasable
 * @param transferTimelock The timestamp when the slicer becomes transferable
 * @param controller The address of the slicer controller
 * @param slicerFlags See `_flags` in {Slicer}
 * @param sliceCoreFlags See `flags` in {SlicerParams} struct
 */
struct SliceParams {
    Payee[] payees;
    uint256 minimumShares;
    address[] currencies;
    uint256 releaseTimelock;
    uint40 transferTimelock;
    address controller;
    uint8 slicerFlags;
    uint8 sliceCoreFlags;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/ISlicer.sol";

/**
 * @param slicer ISlicer instance
 * @param controller Address of slicer controller
 * @param transferTimelock The timestamp when the slicer becomes transferable
 * @param totalSupply Total supply of slices
 * @param royaltyPercentage Percentage of royalty to claim (up to 100, ie 10%)
 * @param flags Boolean flags in the following order from the right: [isCustomRoyaltyActive, isRoyaltyReceiverSlicer,
 * isResliceAllowed, isControlledTransferAllowed]
 * @param transferAllowlist Mapping from address to permission to transfer slices during transferTimelock period
 */
struct SlicerParams {
    ISlicer slicer;
    address controller;
    uint40 transferTimelock;
    uint32 totalSupply;
    uint8 royaltyPercentage;
    uint8 flags;
    uint8 FREE_SLOT_1;
    mapping(address => bool) transferAllowlist;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct SubSlicerProduct {
    uint128 subSlicerId;
    uint32 subProductId;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { wadLn, unsafeWadDiv, toDaysWadUnsafe } from "../utils/SignedWadMath.sol";
import { IProductsModule } from "../Slice/interfaces/IProductsModule.sol";
import { LinearProductParams } from "./structs/LinearProductParams.sol";
import { LinearVRGDAParams } from "./structs/LinearVRGDAParams.sol";

import { VRGDAPrices } from "./VRGDAPrices.sol";

/// @title Linear Variable Rate Gradual Dutch Auction - Slice pricing strategy
/// @author jacopo <[email protected]>
/// @notice VRGDA with a linear issuance curve - Price library with different params for each Slice product.
contract LinearVRGDAPrices is VRGDAPrices {
  /*//////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/

  // Mapping from slicerId to productId to ProductParams
  mapping(uint256 => mapping(uint256 => LinearProductParams))
    private _productParams;

  /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

  constructor(address productsModuleAddress)
    VRGDAPrices(productsModuleAddress)
  {}

  /*//////////////////////////////////////////////////////////////
                            VRGDA PARAMETERS
    //////////////////////////////////////////////////////////////*/

  /// @notice Set LinearProductParams for product.
  /// @param slicerId ID of the slicer to set the price params for.
  /// @param productId ID of the product to set the price params for.
  /// @param currencies currencies of the product to set the price params for.
  /// @param linearParams see `LinearVRGDAParams`.
  /// @param priceDecayPercent The percent price decays per unit of time with no sales, scaled by 1e18.
  function setProductPrice(
    uint256 slicerId,
    uint256 productId,
    address[] calldata currencies,
    LinearVRGDAParams[] calldata linearParams,
    int256 priceDecayPercent
  ) external onlyProductOwner(slicerId, productId) {
    require(linearParams.length == currencies.length, "INVALID_INPUTS");

    int256 decayConstant = wadLn(1e18 - priceDecayPercent);
    // The decay constant must be negative for VRGDAs to work.
    require(decayConstant < 0, "NON_NEGATIVE_DECAY_CONSTANT");
    require(decayConstant >= type(int184).min, "MIN_DECAY_CONSTANT_EXCEEDED");

    /// Get product availability and isInfinite
    /// @dev available units is a uint32
    (uint256 availableUnits, bool isInfinite) = IProductsModule(
      _productsModuleAddress
    ).availableUnits(slicerId, productId);

    // Product must not have infinite availability
    require(!isInfinite, "NOT_FINITE_AVAILABILITY");

    // Set product params
    _productParams[slicerId][productId].startTime = uint40(block.timestamp);
    _productParams[slicerId][productId].startUnits = uint32(availableUnits);
    _productParams[slicerId][productId].decayConstant = int184(decayConstant);

    // Set currency params
    for (uint256 i; i < currencies.length; ) {
      _productParams[slicerId][productId].pricingParams[
        currencies[i]
      ] = linearParams[i];

      unchecked {
        ++i;
      }
    }
  }

  /*//////////////////////////////////////////////////////////////
                              PRICING LOGIC
    //////////////////////////////////////////////////////////////*/

  /// @dev Given a number of products sold, return the target time that number of products should be sold by.
  /// @param sold A number of products sold, scaled by 1e18, to get the corresponding target sale time for.
  /// @param timeFactor Time-dependent factor used to calculate target sale time.
  /// @return The target time the products should be sold by, scaled by 1e18, where the time is
  /// relative, such that 0 means the products should be sold immediately when the VRGDA begins.
  function getTargetSaleTime(int256 sold, int256 timeFactor)
    public
    pure
    override
    returns (int256)
  {
    return unsafeWadDiv(sold, timeFactor);
  }

  /**
   * @notice Function called by Slice protocol to calculate current product price.
   * @param slicerId ID of the slicer being queried
   * @param productId ID of the product being queried
   * @param currency Currency chosen for the purchase
   * @param quantity Number of units purchased
   * @return ethPrice and currencyPrice of product.
   */
  function productPrice(
    uint256 slicerId,
    uint256 productId,
    address currency,
    uint256 quantity,
    address,
    bytes memory
  ) public view override returns (uint256 ethPrice, uint256 currencyPrice) {
    // Add reference for product and pricing params
    LinearProductParams storage productParams = _productParams[slicerId][
      productId
    ];
    LinearVRGDAParams memory pricingParams = productParams.pricingParams[
      currency
    ];

    require(productParams.startTime != 0, "PRODUCT_UNSET");

    // Get available units
    (uint256 availableUnits, ) = IProductsModule(_productsModuleAddress)
      .availableUnits(slicerId, productId);

    // Calculate sold units from availableUnits
    uint256 soldUnits = productParams.startUnits - availableUnits;

    // Set ethPrice or currencyPrice based on chosen currency
    if (currency == address(0)) {
      ethPrice = getAdjustedVRGDAPrice(
        pricingParams.targetPrice,
        productParams.decayConstant,
        toDaysWadUnsafe(block.timestamp - productParams.startTime),
        soldUnits,
        pricingParams.perTimeUnit,
        pricingParams.min,
        quantity
      );
    } else {
      currencyPrice = getAdjustedVRGDAPrice(
        pricingParams.targetPrice,
        productParams.decayConstant,
        toDaysWadUnsafe(block.timestamp - productParams.startTime),
        soldUnits,
        pricingParams.perTimeUnit,
        pricingParams.min,
        quantity
      );
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { wadExp, wadMul, unsafeWadMul, toWadUnsafe } from "../utils/SignedWadMath.sol";
import { ISliceProductPrice } from "../Slice/interfaces/utils/ISliceProductPrice.sol";
import { IProductsModule } from "../Slice/interfaces/IProductsModule.sol";

/// @title Variable Rate Gradual Dutch Auction - Slice pricing strategy
/// @author jacopo <[email protected]>
/// @notice Price library with configurable params for each Slice product.

abstract contract VRGDAPrices is ISliceProductPrice {
  /*//////////////////////////////////////////////////////////////
                                 STORAGE
    //////////////////////////////////////////////////////////////*/

  address internal immutable _productsModuleAddress;

  /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

  constructor(address productsModuleAddress) {
    _productsModuleAddress = productsModuleAddress;
  }

  /*//////////////////////////////////////////////////////////////
                                MODIFIERS
    //////////////////////////////////////////////////////////////*/

  /// @notice Check if msg.sender is owner of a product. Used to manage access of `setProductPrice`
  /// in implementations of this contract.
  modifier onlyProductOwner(uint256 slicerId, uint256 productId) {
    require(
      IProductsModule(_productsModuleAddress).isProductOwner(
        slicerId,
        productId,
        msg.sender
      ),
      "NOT_PRODUCT_OWNER"
    );
    _;
  }

  /*//////////////////////////////////////////////////////////////
                              PRICING LOGIC
    //////////////////////////////////////////////////////////////*/

  /// @notice Calculate the price of a product according to the VRGDA formula.
  /// @param targetPrice The target price for a product if sold on pace, scaled by 1e18.
  /// @param decayConstant Precomputed constant that allows us to rewrite a pow() as an exp().
  /// @param timeSinceStart Time passed since the VRGDA began, scaled by 1e18.
  /// @param sold The total number of products sold so far.
  /// @param timeFactor Time-dependent factor used to calculate target sale time.
  /// @param min minimum price to be paid for a token, scaled by 1e18
  /// @return The price of a product according to VRGDA, scaled by 1e18.
  function getVRGDAPrice(
    int256 targetPrice,
    int256 decayConstant,
    int256 timeSinceStart,
    uint256 sold,
    int256 timeFactor,
    uint256 min
  ) public view virtual returns (uint256) {
    unchecked {
      // prettier-ignore
      uint256 VRGDAPrice = uint256(wadMul(targetPrice, wadExp(unsafeWadMul(decayConstant,
                // We use sold + 1 as the VRGDA formula's n param represents the nth product and sold is the 
                // n-1th product.
                timeSinceStart - getTargetSaleTime(
                  toWadUnsafe(sold + 1), timeFactor
                )
            ))));

      return VRGDAPrice > min ? VRGDAPrice : min;
    }
  }

  /// @dev Given a number of products sold, return the target time that number of products should be sold by.
  /// @param sold A number of products sold, scaled by 1e18, to get the corresponding target sale time for.
  /// @param timeFactor Time-dependent factor used to calculate target sale time.
  /// @return The target time the products should be sold by, scaled by 1e18, where the time is
  /// relative, such that 0 means the products should be sold immediately when the VRGDA begins.
  function getTargetSaleTime(int256 sold, int256 timeFactor)
    public
    view
    virtual
    returns (int256)
  {}

  /// @notice Get product price adjusted to quantity purchased.
  /// @param targetPrice The target price for a product if sold on pace, scaled by 1e18.
  /// @param decayConstant Precomputed constant that allows us to rewrite a pow() as an exp().
  /// @param timeSinceStart Time passed since the VRGDA began, scaled by 1e18.
  /// @param sold The total number of products sold so far.
  /// @param timeFactor Time-dependent factor used to calculate target sale time.
  /// @param min minimum price to be paid for a token, scaled by 1e18
  /// @param quantity Number of units purchased
  /// @return price of product * quantity according to VRGDA, scaled by 1e18.
  function getAdjustedVRGDAPrice(
    int256 targetPrice,
    int256 decayConstant,
    int256 timeSinceStart,
    uint256 sold,
    int256 timeFactor,
    uint256 min,
    uint256 quantity
  ) public view virtual returns (uint256 price) {
    for (uint256 i; i < quantity; ) {
      price += getVRGDAPrice(
        targetPrice,
        decayConstant,
        timeSinceStart,
        sold + i,
        timeFactor,
        min
      );

      unchecked {
        ++i;
      }
    }
  }

  /**
   * @notice Function called by Slice protocol to calculate current product price.
   * @param slicerId ID of the slicer being queried
   * @param productId ID of the product being queried
   * @param currency Currency chosen for the purchase
   * @param quantity Number of units purchased
   * @param buyer Address of the buyer
   * @param data Custom data sent along with the purchase transaction by the buyer
   * @return ethPrice and currencyPrice of product.
   */
  function productPrice(
    uint256 slicerId,
    uint256 productId,
    address currency,
    uint256 quantity,
    address buyer,
    bytes memory data
  )
    public
    view
    virtual
    override
    returns (uint256 ethPrice, uint256 currencyPrice)
  {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { LinearVRGDAParams } from "./LinearVRGDAParams.sol";

/// @param startTime Time when the VRGDA began.
/// @param startUnits Units available at the time when product is set up.
/// @param decayConstant Precomputed constant that allows us to rewrite a pow() as an exp().
/// @param pricingParams See `LinearVRGDAParams`
struct LinearProductParams {
  uint40 startTime;
  uint32 startUnits;
  int184 decayConstant;
  mapping(address => LinearVRGDAParams) pricingParams;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @param targetPrice Target price for a product, to be scaled according to sales pace.
/// @param min minimum price to be paid for a token, scaled by 1e18
/// @param perTimeUnit The total number of products to target selling every full unit of time.
struct LinearVRGDAParams {
  int128 targetPrice;
  uint128 min;
  int256 perTimeUnit;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @title Signed Wad Math
/// @author transmissions11 <[email protected]>
/// @author FrankieIsLost <[email protected]>
/// @author Remco Bloemen <[email protected]>
/// @notice Efficient signed wad arithmetic.

/// @dev Will not revert on overflow, only use where overflow is not possible.
function toWadUnsafe(uint256 x) pure returns (int256 r) {
    assembly {
        // Multiply x by 1e18.
        r := mul(x, 1000000000000000000)
    }
}

/// @dev Takes an integer amount of seconds and converts it to a wad amount of days.
/// @dev Will not revert on overflow, only use where overflow is not possible.
function toDaysWadUnsafe(uint256 x) pure returns (int256 r) {
    assembly {
        // Multiply x by 1e18 and then divide it by 86400.
        r := div(mul(x, 1000000000000000000), 86400)
    }
}

/// @dev Takes a wad amount of days and converts it to an integer amount of seconds.
/// @dev Will not revert on overflow, only use where overflow is not possible.
/// @dev Not compatible with negative day amounts, it assumes x is positive.
function fromDaysWadUnsafe(int256 x) pure returns (uint256 r) {
    assembly {
        // Multiply x by 86400 and then divide it by 1e18.
        r := div(mul(x, 86400), 1000000000000000000)
    }
}

/// @dev Will not revert on overflow, only use where overflow is not possible.
function unsafeWadMul(int256 x, int256 y) pure returns (int256 r) {
    assembly {
        // Multiply x by y and divide by 1e18.
        r := sdiv(mul(x, y), 1000000000000000000)
    }
}

/// @dev Will return 0 instead of reverting if y is zero and will
/// not revert on overflow, only use where overflow is not possible.
function unsafeWadDiv(int256 x, int256 y) pure returns (int256 r) {
    assembly {
        // Multiply x by 1e18 and divide it by y.
        r := sdiv(mul(x, 1000000000000000000), y)
    }
}

function wadMul(int256 x, int256 y) pure returns (int256 r) {
    assembly {
        // Store x * y in r for now.
        r := mul(x, y)

        // Equivalent to require(x == 0 || (x * y) / x == y)
        if iszero(or(iszero(x), eq(sdiv(r, x), y))) {
            revert(0, 0)
        }

        // Scale the result down by 1e18.
        r := sdiv(r, 1000000000000000000)
    }
}

function wadDiv(int256 x, int256 y) pure returns (int256 r) {
    assembly {
        // Store x * 1e18 in r for now.
        r := mul(x, 1000000000000000000)

        // Equivalent to require(y != 0 && ((x * 1e18) / 1e18 == x))
        if iszero(and(iszero(iszero(y)), eq(sdiv(r, 1000000000000000000), x))) {
            revert(0, 0)
        }

        // Divide r by y.
        r := sdiv(r, y)
    }
}

function wadExp(int256 x) pure returns (int256 r) {
    unchecked {
        // When the result is < 0.5 we return zero. This happens when
        // x <= floor(log(0.5e18) * 1e18) ~ -42e18
        if (x <= -42139678854452767551) return 0;

        // When the result is > (2**255 - 1) / 1e18 we can not represent it as an
        // int. This happens when x >= floor(log((2**255 - 1) / 1e18) * 1e18) ~ 135.
        if (x >= 135305999368893231589) revert("EXP_OVERFLOW");

        // x is now in the range (-42, 136) * 1e18. Convert to (-42, 136) * 2**96
        // for more intermediate precision and a binary basis. This base conversion
        // is a multiplication by 1e18 / 2**96 = 5**18 / 2**78.
        x = (x << 78) / 5**18;

        // Reduce range of x to (-½ ln 2, ½ ln 2) * 2**96 by factoring out powers
        // of two such that exp(x) = exp(x') * 2**k, where k is an integer.
        // Solving this gives k = round(x / log(2)) and x' = x - k * log(2).
        int256 k = ((x << 96) / 54916777467707473351141471128 + 2**95) >> 96;
        x = x - k * 54916777467707473351141471128;

        // k is in the range [-61, 195].

        // Evaluate using a (6, 7)-term rational approximation.
        // p is made monic, we'll multiply by a scale factor later.
        int256 y = x + 1346386616545796478920950773328;
        y = ((y * x) >> 96) + 57155421227552351082224309758442;
        int256 p = y + x - 94201549194550492254356042504812;
        p = ((p * y) >> 96) + 28719021644029726153956944680412240;
        p = p * x + (4385272521454847904659076985693276 << 96);

        // We leave p in 2**192 basis so we don't need to scale it back up for the division.
        int256 q = x - 2855989394907223263936484059900;
        q = ((q * x) >> 96) + 50020603652535783019961831881945;
        q = ((q * x) >> 96) - 533845033583426703283633433725380;
        q = ((q * x) >> 96) + 3604857256930695427073651918091429;
        q = ((q * x) >> 96) - 14423608567350463180887372962807573;
        q = ((q * x) >> 96) + 26449188498355588339934803723976023;

        assembly {
            // Div in assembly because solidity adds a zero check despite the unchecked.
            // The q polynomial won't have zeros in the domain as all its roots are complex.
            // No scaling is necessary because p is already 2**96 too large.
            r := sdiv(p, q)
        }

        // r should be in the range (0.09, 0.25) * 2**96.

        // We now need to multiply r by:
        // * the scale factor s = ~6.031367120.
        // * the 2**k factor from the range reduction.
        // * the 1e18 / 2**96 factor for base conversion.
        // We do this all at once, with an intermediate result in 2**213
        // basis, so the final right shift is always by a positive amount.
        r = int256((uint256(r) * 3822833074963236453042738258902158003155416615667) >> uint256(195 - k));
    }
}

function wadLn(int256 x) pure returns (int256 r) {
    unchecked {
        require(x > 0, "UNDEFINED");

        // We want to convert x from 10**18 fixed point to 2**96 fixed point.
        // We do this by multiplying by 2**96 / 10**18. But since
        // ln(x * C) = ln(x) + ln(C), we can simply do nothing here
        // and add ln(2**96 / 10**18) at the end.

        assembly {
            r := shl(7, lt(0xffffffffffffffffffffffffffffffff, x))
            r := or(r, shl(6, lt(0xffffffffffffffff, shr(r, x))))
            r := or(r, shl(5, lt(0xffffffff, shr(r, x))))
            r := or(r, shl(4, lt(0xffff, shr(r, x))))
            r := or(r, shl(3, lt(0xff, shr(r, x))))
            r := or(r, shl(2, lt(0xf, shr(r, x))))
            r := or(r, shl(1, lt(0x3, shr(r, x))))
            r := or(r, lt(0x1, shr(r, x)))
        }

        // Reduce range of x to (1, 2) * 2**96
        // ln(2^k * x) = k * ln(2) + ln(x)
        int256 k = r - 96;
        x <<= uint256(159 - k);
        x = int256(uint256(x) >> 159);

        // Evaluate using a (8, 8)-term rational approximation.
        // p is made monic, we will multiply by a scale factor later.
        int256 p = x + 3273285459638523848632254066296;
        p = ((p * x) >> 96) + 24828157081833163892658089445524;
        p = ((p * x) >> 96) + 43456485725739037958740375743393;
        p = ((p * x) >> 96) - 11111509109440967052023855526967;
        p = ((p * x) >> 96) - 45023709667254063763336534515857;
        p = ((p * x) >> 96) - 14706773417378608786704636184526;
        p = p * x - (795164235651350426258249787498 << 96);

        // We leave p in 2**192 basis so we don't need to scale it back up for the division.
        // q is monic by convention.
        int256 q = x + 5573035233440673466300451813936;
        q = ((q * x) >> 96) + 71694874799317883764090561454958;
        q = ((q * x) >> 96) + 283447036172924575727196451306956;
        q = ((q * x) >> 96) + 401686690394027663651624208769553;
        q = ((q * x) >> 96) + 204048457590392012362485061816622;
        q = ((q * x) >> 96) + 31853899698501571402653359427138;
        q = ((q * x) >> 96) + 909429971244387300277376558375;
        assembly {
            // Div in assembly because solidity adds a zero check despite the unchecked.
            // The q polynomial is known not to have zeros in the domain.
            // No scaling required because p is already 2**96 too large.
            r := sdiv(p, q)
        }

        // r is in the range (0, 0.125) * 2**96

        // Finalization, we need to:
        // * multiply by the scale factor s = 5.549…
        // * add ln(2**96 / 10**18)
        // * add k * ln(2)
        // * multiply by 10**18 / 2**96 = 5**18 >> 78

        // mul s * 5e18 * 2**96, base is now 5**18 * 2**192
        r *= 1677202110996718588342820967067443963516166;
        // add ln(2) * k * 5e18 * 2**192
        r += 16597577552685614221487285958193947469193820559219878177908093499208371 * k;
        // add ln(2**96 / 10**18) * 5e18 * 2**192
        r += 600920179829731861736702779321621459595472258049074101567377883020018308;
        // base conversion: mul 2**18 / 2**192
        r >>= 174;
    }
}

/// @dev Will return 0 instead of reverting if y is zero.
function unsafeDiv(int256 x, int256 y) pure returns (int256 r) {
    assembly {
        // Divide x by y.
        r := sdiv(x, y)
    }
}