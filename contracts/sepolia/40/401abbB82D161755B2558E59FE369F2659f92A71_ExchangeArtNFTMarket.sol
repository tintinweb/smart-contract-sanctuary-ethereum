/*
                                                                                                                                                                                                                                                           
    ,---,.                        ,---,                                                         ,---,                    ___     
  ,'  .' |                      ,--.' |                                                        '  .' \                 ,--.'|_   
,---.'   |                      |  |  :                      ,---,                            /  ;    '.      __  ,-.  |  | :,'  
|   |   .' ,--,  ,--,           :  :  :                  ,-+-. /  |  ,----._,.               :  :       \   ,' ,'/ /|  :  : ' :  
:   :  |-, |'. \/ .`|    ,---.  :  |  |,--.  ,--.--.    ,--.'|'   | /   /  ' /   ,---.       :  |   /\   \  '  | |' |.;__,'  /   
:   |  ;/| '  \/  / ;   /     \ |  :  '   | /       \  |   |  ,"' ||   :     |  /     \      |  :  ' ;.   : |  |   ,'|  |   |    
|   :   .'  \  \.' /   /    / ' |  |   /' :.--.  .-. | |   | /  | ||   | .\  . /    /  |     |  |  ;/  \   \'  :  /  :__,'| :    
|   |  |-,   \  ;  ;  .    ' /  '  :  | | | \__\/: . . |   | |  | |.   ; ';  |.    ' / |     '  :  | \  \ ,'|  | '     '  : |__  
'   :  ;/|  / \  \  \ '   ; :__ |  |  ' | : ," .--.; | |   | |  |/ '   .   . |'   ;   /|     |  |  '  '--'  ;  : |     |  | '.'| 
|   |    \./__;   ;  \'   | '.'||  :  :_:,'/  /  ,.  | |   | |--'   `---`-'| |'   |  / |___  |  :  :        |  , ;     ;  :    ; 
|   :   .'|   :/\  \ ;|   :    :|  | ,'   ;  :   .'   \|   |/       .'__/\_: ||   :    /  .\ |  | ,'         ---'      |  ,   /  
|   | ,'  `---'  `--`  \   \  / `--''     |  ,     .-./'---'        |   :    : \   \  /\  ; |`--''                      ---`-'   
`----'                  `----'             `--`---'                  \   \  /   `----'  `--"                                     
                                                                      `--`-'                                                     

*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "./mixins/shared/Constants.sol";
import "./mixins/shared/ExchangeArtTreasuryNode.sol";
import "./mixins/shared/NFTMarketFees.sol";
import "./mixins/shared/NFTMarketSharedCore.sol";
import "./mixins/shared/SendValueWithFallbackWithdraw.sol";

import "./mixins/NFTMarketBuyNow.sol";
import "./mixins/NFTMarketCore.sol";

/**
 * @title A marketplace for NFTs on Exchange.Art.
 * @notice The Exchange Art marketplace is a contract which allows traders to buy and sell NFTs.
 * It supports buying and selling via buy now. Auctions and offers coming soon
 * @dev All sales in the Foundation market will pay the creator 10% royalties on secondary sales. This is not specific
 * to NFTs minted on Foundation, it should work for any NFT. If royalty information was not defined when the NFT was
 * originally deployed, it may be added using the [Royalty Registry](https://royaltyregistry.xyz/) which will be
 * respected by our market contract.
 * @author robeMalu
 */
contract ExchangeArtNFTMarket is
  Initializable,
  ExchangeArtTreasuryNode,
  NFTMarketSharedCore,
  NFTMarketCore,
  ReentrancyGuardUpgradeable,
  SendValueWithFallbackWithdraw,
  NFTMarketFees,
  NFTMarketBuyNow
{
  /**
   * @notice Set immutable variables for the implementation contract.
   * @dev Using immutable instead of constants allows us to use different values on testnet.
   * @param treasury The Foundation Treasury contract address.

   */
  constructor(
    address payable treasury
  )
    ExchangeArtTreasuryNode(treasury)
    NFTMarketFees(
      /* protocolFeeInBasisPoints: */
      500
    )
    initializer // solhint-disable-next-line no-empty-blocks
  {}
    /**
   * @inheritdoc NFTMarketCore
   */
  function _transferFromEscrow(
    address nftContract,
    uint256 tokenId,
    address recipient,
    address authorizeSeller
  ) internal override(NFTMarketCore, NFTMarketBuyNow) {
    // This is a no-op function required to avoid compile errors.
    super._transferFromEscrow(nftContract, tokenId, recipient, authorizeSeller);
  }

  /**
   * @inheritdoc NFTMarketCore
   */
  function _transferFromEscrowIfAvailable(
    address nftContract,
    uint256 tokenId,
    address recipient
  ) internal override(NFTMarketCore,  NFTMarketBuyNow) {
    // This is a no-op function required to avoid compile errors.
    super._transferFromEscrowIfAvailable(nftContract, tokenId, recipient);
  }

  /**
   * @inheritdoc NFTMarketCore
   */
  function _transferToEscrow(address nftContract, uint256 tokenId)
    internal
    override(NFTMarketCore, NFTMarketBuyNow)
  {
    // This is a no-op function required to avoid compile errors.
    super._transferToEscrow(nftContract, tokenId);
  }

  /**
   * @inheritdoc NFTMarketSharedCore
   */
  function _getSellerOf(address nftContract, uint256 tokenId)
    internal
    view
    override(NFTMarketSharedCore, NFTMarketCore, NFTMarketBuyNow)

    returns (address payable seller)
  {
    // This is a no-op function required to avoid compile errors.
    seller = super._getSellerOf(nftContract, tokenId);
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.8;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./shared/NFTMarketSharedCore.sol";

error NFTMarketCore_Seller_Not_Found();

/**
 * @title A place for common modifiers and functions used by various NFTMarket mixins, if any.
 * @dev This also leaves a gap which can be used to add a new mixin to the top of the inheritance tree.
 * @author batu-inal & HardlyDifficult
 */
abstract contract NFTMarketCore is Initializable, NFTMarketSharedCore {
  using AddressUpgradeable for address;
  using AddressUpgradeable for address payable;

  /**
   * @notice Transfers the NFT from escrow and clears any state tracking this escrowed NFT.
   * @param authorizeSeller The address of the seller pending authorization.
   * Once it's been authorized by one of the escrow managers, it should be set to address(0)
   * indicated that it's no longer pending authorization.
   */
  function _transferFromEscrow(
    address nftContract,
    uint256 tokenId,
    address recipient,
    address authorizeSeller
  ) internal virtual {
    if (authorizeSeller != address(0)) {
      revert NFTMarketCore_Seller_Not_Found();
    }
    IERC721(nftContract).transferFrom(address(this), recipient, tokenId);
  }

  /**
   * @notice Transfers the NFT from escrow unless there is another reason for it to remain in escrow.
   */
  function _transferFromEscrowIfAvailable(
    address nftContract,
    uint256 tokenId,
    address recipient
  ) internal virtual {
    _transferFromEscrow(nftContract, tokenId, recipient, address(0));
  }

  /**
   * @notice Transfers an NFT into escrow,
   * if already there this requires the msg.sender is authorized to manage the sale of this NFT.
   */
  function _transferToEscrow(address nftContract, uint256 tokenId) internal virtual {
    IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);
  }

  /**
   * @inheritdoc NFTMarketSharedCore
   */
  function _getSellerOf(address nftContract, uint256 tokenId)
    internal
    view
    virtual
    override
    returns (address payable seller)
  // solhint-disable-next-line no-empty-blocks
  {
    // No-op by default
  }

  /**
   * @inheritdoc NFTMarketSharedCore
   */
  function _getSellerOrOwnerOf(address nftContract, uint256 tokenId)
    internal
    view
    override
    returns (address payable sellerOrOwner)
  {
    sellerOrOwner = _getSellerOf(nftContract, tokenId);
    if (sellerOrOwner == address(0)) {
      sellerOrOwner = payable(IERC721(nftContract).ownerOf(tokenId));
    }
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.8;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "./shared/NFTMarketSharedCore.sol";
import "./shared/ExchangeArtTreasuryNode.sol";
import "./shared/NFTMarketFees.sol";
import "./shared/SendValueWithFallbackWithdraw.sol";
import "./NFTMarketCore.sol";


/// @param buyPrice The current buy price set for this NFT.
error NFTMarketBuyPrice_Cannot_Buy_At_Lower_Price(uint256 buyPrice);
error NFTMarketBuyPrice_Cannot_Buy_Unset_Price();
error NFTMarketBuyPrice_Cannot_Cancel_Unset_Price();
/// @param owner The current owner of this NFT.
error NFTMarketBuyPrice_Only_Owner_Can_Set_Price(address owner);
error NFTMarketBuyPrice_Only_Owner_Can_Cancel_Price(address owner);
error NFTMarketBuyPrice_Price_Already_Set();
error NFTMarketBuyPrice_Price_Too_High();
/// @param seller The current owner of this NFT.
error NFTMarketBuyPrice_Seller_Mismatch(address seller);

/**
 * @title Allows sellers to set a buy price of their NFTs that may be accepted and instantly transferred to the buyer.
 * @notice NFTs with a buy price set are escrowed in the market contract.
 * @author batu-inal & HardlyDifficult
 */
abstract contract NFTMarketBuyNow is
  Initializable,
  ExchangeArtTreasuryNode,
  NFTMarketSharedCore,
  NFTMarketCore,
  ReentrancyGuardUpgradeable,
  SendValueWithFallbackWithdraw,
  NFTMarketFees
{
  using AddressUpgradeable for address payable;
  
  /// @notice Stores the buy price details for a specific NFT.
  /// @dev The struct is packed into a single slot to optimize gas.
  struct BuyNow {
    /// @notice The current owner of this NFT which set a buy price.
    /// @dev A zero price is acceptable so a non-zero address determines whether a price has been set.
    address payable seller;
    /// @notice The current buy price set for this NFT.
    uint96 price;
  }

  /// @notice Stores the current buy price for each NFT.
  mapping(address => mapping(uint256 => BuyNow)) private nftContractToTokenIdToBuyPrice;

  /**
   * @notice Emitted when an NFT is bought by accepting the buy price,
   * indicating that the NFT has been transferred and revenue from the sale distributed.
   * @dev The total buy price that was accepted is `totalFees` + `creatorRev` + `sellerRev`.
   * @param nftContract The address of the NFT contract.
   * @param tokenId The id of the NFT.
   * @param buyer The address of the collector that purchased the NFT using `buy`.
   * @param seller The address of the seller which originally set the buy price.
   * @param totalFees The amount of ETH that was sent to Exchange Art.
   * @param creatorRev The amount of ETH that was sent to the creator for this sale.
   * @param sellerRev The amount of ETH that was sent to the owner for this sale.
   */
  event BuyPriceAccepted(
    address indexed nftContract,
    uint256 indexed tokenId,
    address indexed seller,
    address buyer,
    uint256 totalFees,
    uint256 creatorRev,
    uint256 sellerRev
  );
 
  /**
   * @notice Emitted when the buy price is removed by the owner of an NFT.
   * @dev The NFT is transferred back to the owner unless it's still escrowed for another market tool,
   * e.g. listed for sale in an auction.
   * @param nftContract The address of the NFT contract.
   * @param tokenId The id of the NFT.
   */
  event BuyPriceCanceled(address indexed nftContract, uint256 indexed tokenId);

  /**
   * @notice Emitted when a buy price is set by the owner of an NFT.
   * @dev The NFT is transferred into the market contract for escrow unless it was already escrowed,
   * e.g. for auction listing.
   * @param nftContract The address of the NFT contract.
   * @param tokenId The id of the NFT.
   * @param seller The address of the NFT owner which set the buy price.
   * @param price The price of the NFT.
   */
  event BuyPriceSet(address indexed nftContract, uint256 indexed tokenId, address indexed seller, uint256 price);

  /**
   * @notice Emitted when a buy price is invalidated due to other market activity.
   * @dev This occurs when the buy price is no longer eligible to be accepted,
   * e.g. when a bid is placed in an auction for this NFT.
   * @param nftContract The address of the NFT contract.
   * @param tokenId The id of the NFT.
   */
  event BuyPriceInvalidated(address indexed nftContract, uint256 indexed tokenId);

  /**
   * @notice Buy the NFT at the set buy price.
   * `msg.value` must be <= `maxPrice` and any delta will be taken from the account's available FETH balance.
   * @dev `maxPrice` protects the buyer in case a the price is increased but allows the transaction to continue
   * when the price is reduced (and any surplus funds provided are refunded).
   * @param nftContract The address of the NFT contract.
   * @param tokenId The id of the NFT.
   * @param maxPrice The maximum price to pay for the NFT.
   */
  function buy(
    address nftContract,
    uint256 tokenId,
    uint256 maxPrice
  ) public payable {
    BuyNow storage buyPrice = nftContractToTokenIdToBuyPrice[nftContract][tokenId];
    if (buyPrice.price > maxPrice) {
      revert NFTMarketBuyPrice_Cannot_Buy_At_Lower_Price(buyPrice.price);
    } else if (buyPrice.seller == address(0)) {
      revert NFTMarketBuyPrice_Cannot_Buy_Unset_Price();
    }

    _process_buy_now(nftContract, tokenId);
  }

    /**
   * @notice Removes the buy price set for an NFT.
   * @dev The NFT is transferred back to the owner unless it's still escrowed for another market tool,
   * e.g. listed for sale in an auction.
   * @param nftContract The address of the NFT contract.
   * @param tokenId The id of the NFT.
   */
  function cancelBuyNow(address nftContract, uint256 tokenId) external nonReentrant {
    address seller = nftContractToTokenIdToBuyPrice[nftContract][tokenId].seller;
    if (seller == address(0)) {
      // This check is redundant with the next one, but done in order to provide a more clear error message.
      revert NFTMarketBuyPrice_Cannot_Cancel_Unset_Price();
    } else if (seller != msg.sender) {
      revert NFTMarketBuyPrice_Only_Owner_Can_Cancel_Price(seller);
    }

    // Remove the buy price
    delete nftContractToTokenIdToBuyPrice[nftContract][tokenId];

    // Transfer the NFT back to the owner if it is not listed in auction.
    _transferFromEscrowIfAvailable(nftContract, tokenId, msg.sender);

    emit BuyPriceCanceled(nftContract, tokenId);
  }

  /**
   * @notice Sets the buy price for an NFT and escrows it in the market contract.
   * A 0 price is acceptable and valid price you can set, enabling a giveaway to the first collector that calls `buy`.
   * @dev If there is an offer for this amount or higher, that will be accepted instead of setting a buy price.
   * @param nftContract The address of the NFT contract.
   * @param tokenId The id of the NFT.
   * @param price The price at which someone could buy this NFT.
   */
  function createBuyNowSale(
    address nftContract,
    uint256 tokenId,
    uint256 price
  ) external nonReentrant {

    if (price > type(uint96).max) {
      // This ensures that no data is lost when storing the price as `uint96`.
      revert NFTMarketBuyPrice_Price_Too_High();
    }

    BuyNow storage buyPrice = nftContractToTokenIdToBuyPrice[nftContract][tokenId];
    address seller = buyPrice.seller;

    if (buyPrice.price == price && seller != address(0)) {
      revert NFTMarketBuyPrice_Price_Already_Set();
    }

    // Store the new price for this NFT.
    buyPrice.price = uint96(price);

    if (seller == address(0)) {
      // Transfer the NFT into escrow, if it's already in escrow confirm the `msg.sender` is the owner.
      _transferToEscrow(nftContract, tokenId);

      // The price was not previously set for this NFT, store the seller.
      buyPrice.seller = payable(msg.sender);
    } else if (seller != msg.sender) {
      // Buy price was previously set by a different user
      revert NFTMarketBuyPrice_Only_Owner_Can_Set_Price(seller);
    }

    emit BuyPriceSet(nftContract, tokenId, msg.sender, price);
  }


  /**
   * @notice Process the purchase of an NFT at the current buy price.
   * @dev The caller must confirm that the seller != address(0) before calling this function.
   */
  function _process_buy_now(
    address nftContract,
    uint256 tokenId
  ) private nonReentrant {
    BuyNow memory buyPrice = nftContractToTokenIdToBuyPrice[nftContract][tokenId];

    // Remove the buy now price
    delete nftContractToTokenIdToBuyPrice[nftContract][tokenId];

    // Cancel the buyer's offer if there is one in order to free up their FETH balance
    // even if they don't need the FETH for this specific purchase.
    // _cancelSendersOffer(nftContract, tokenId);

    // todo: is this useful
    // _tryUseFETHBalance(buyPrice.price, true);

    // Transfer the NFT to the buyer.
    // The seller was already authorized when the buyPrice was set originally set.
    _transferFromEscrow(nftContract, tokenId, msg.sender, address(0));

    // Distribute revenue for this sale.
    (uint256 totalFees, uint256 creatorRev, uint256 sellerRev) = _distributeFunds(
      nftContract,
      tokenId,
      buyPrice.seller,
      buyPrice.price
    );

    emit BuyPriceAccepted(nftContract, tokenId, buyPrice.seller, msg.sender, totalFees, creatorRev, sellerRev);
  }

  /**
   * @notice Clear a buy price and emit BuyPriceInvalidated.
   * @dev The caller must confirm the buy price is set before calling this function.
   */
  function _invalidateBuyPrice(address nftContract, uint256 tokenId) private {
    delete nftContractToTokenIdToBuyPrice[nftContract][tokenId];
    emit BuyPriceInvalidated(nftContract, tokenId);
  }


  /**
   * @notice Returns the buy price details for an NFT if one is available.
   * @dev If no price is found, seller will be address(0) and price will be max uint256.
   * @param nftContract The address of the NFT contract.
   * @param tokenId The id of the NFT.
   * @return seller The address of the owner that listed a buy price for this NFT.
   * Returns `address(0)` if there is no buy price set for this NFT.
   * @return price The price of the NFT.
   * Returns max uint256 if there is no buy price set for this NFT (since a price of 0 is supported).
   */
  function getBuyPrice(address nftContract, uint256 tokenId) external view returns (address seller, uint256 price) {
    seller = nftContractToTokenIdToBuyPrice[nftContract][tokenId].seller;
    if (seller == address(0)) {
      return (seller, type(uint256).max);
    }
    price = nftContractToTokenIdToBuyPrice[nftContract][tokenId].price;
  }

  /**
   * @inheritdoc NFTMarketSharedCore
   * @dev Returns the seller if there is a buy price set for this NFT, otherwise
   * bubbles the call up for other considerations.
   */
  function _getSellerOf(address nftContract, uint256 tokenId)
    internal
    view
    virtual
    override(NFTMarketSharedCore, NFTMarketCore)
    returns (address payable seller)
  {
    seller = nftContractToTokenIdToBuyPrice[nftContract][tokenId].seller;
    if (seller == address(0)) {
      seller = super._getSellerOf(nftContract, tokenId);
    }
  }

  /**
   * @inheritdoc NFTMarketCore
   * @dev Invalidates the buy price if one is found before transferring the NFT.
   * This will revert if there is a buy price set but the `authorizeSeller` is not the owner.
   */
  function _transferFromEscrow(
    address nftContract,
    uint256 tokenId,
    address recipient,
    address authorizeSeller
  ) internal virtual override {
    address seller = nftContractToTokenIdToBuyPrice[nftContract][tokenId].seller;
    if (seller != address(0)) {
      // A buy price was set for this NFT.
      // `authorizeSeller != address(0) &&` could be added when other mixins use this flow.
      // ATM that additional check would never return false.
      if (seller != authorizeSeller) {
        // When there is a buy price set, the `buyPrice.seller` is the owner of the NFT.
        revert NFTMarketBuyPrice_Seller_Mismatch(seller);
      }
      // The seller authorization has been confirmed.
      authorizeSeller = address(0);

      // Invalidate the buy price as the NFT will no longer be in escrow.
      _invalidateBuyPrice(nftContract, tokenId);
    }

    super._transferFromEscrow(nftContract, tokenId, recipient, authorizeSeller);
  }

  /**
   * @inheritdoc NFTMarketCore
   * @dev Checks if there is a buy price set, if not then allow the transfer to proceed.
   */
  function _transferFromEscrowIfAvailable(
    address nftContract,
    uint256 tokenId,
    address recipient
  ) internal virtual override {
    address seller = nftContractToTokenIdToBuyPrice[nftContract][tokenId].seller;
    if (seller == address(0)) {
      // A buy price has been set for this NFT so it should remain in escrow.
      super._transferFromEscrowIfAvailable(nftContract, tokenId, recipient);
    }
  }

  /**
   * @inheritdoc NFTMarketCore
   * @dev Checks if the NFT is already in escrow for buy now.
   */
  function _transferToEscrow(address nftContract, uint256 tokenId) internal virtual override {
    address seller = nftContractToTokenIdToBuyPrice[nftContract][tokenId].seller;
    if (seller == address(0)) {
      // The NFT is not in escrow for buy now.
      super._transferToEscrow(nftContract, tokenId);
    } else if (seller != msg.sender) {
      // When there is a buy price set, the `seller` is the owner of the NFT.
      revert NFTMarketBuyPrice_Seller_Mismatch(seller);
    }
  }

}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.8;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

/**
 * @title A mixin for sending ETH with a fallback withdraw mechanism.
 * @notice Attempt to send ETH and if the transfer fails or runs out of gas, store the balance
 * in the FETH token contract for future withdrawal instead.
 * @dev This mixin was recently switched to escrow funds in FETH.
 * Once we have confirmed all pending balances have been withdrawn, we can remove the escrow tracking here.
 * @author batu-inal & HardlyDifficult
 */
abstract contract SendValueWithFallbackWithdraw  {
  using AddressUpgradeable for address payable;


  /**
   * @notice Attempt to send a user or contract ETH.
   * If it fails store the amount owned for later withdrawal in FETH.
   * @dev This may fail when sending ETH to a contract that is non-receivable or exceeds the gas limit specified.
   */
  function _sendValueWithFallbackWithdraw(
    address payable user,
    uint256 amount,
    uint256 gasLimit
  ) internal {
    if (amount == 0) {
      return;
    }
    // Cap the gas to prevent consuming all available gas to block a tx from completing successfully
    // solhint-disable-next-line avoid-low-level-calls
    (bool success, ) = user.call{ value: amount, gas: gasLimit }("");
    // if (!success) {
    //   // Store the funds that failed to send for the user in the FETH token
    //   feth.depositFor{ value: amount }(user);
    //   emit WithdrawalToFETH(user, amount);
    // }
  }

  /**
   * @notice This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   */
  uint256[999] private __gap;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.8;


/**
 * @title A place for common modifiers and functions used by various market mixins, if any.
 * @dev This also leaves a gap which can be used to add a new mixin to the top of the inheritance tree.
 * @author exchArt
 */
abstract contract NFTMarketSharedCore  {
  /**
   * @notice Checks who the seller for an NFT is if listed in this market.
   * @param nftContract The address of the NFT contract.
   * @param tokenId The id of the NFT.
   * @return seller The seller which listed this NFT for sale, or address(0) if not listed.
   */
  function getSellerOf(address nftContract, uint256 tokenId) external view returns (address payable seller) {
    seller = _getSellerOf(nftContract, tokenId);
  }

  /**
   * @notice Checks who the seller for an NFT is if listed in this market.
   */
  function _getSellerOf(address nftContract, uint256 tokenId) internal view virtual returns (address payable seller);

  /**
   * @notice Checks who the seller for an NFT is if listed in this market or returns the current owner.
   */
  function _getSellerOrOwnerOf(address nftContract, uint256 tokenId)
    internal
    view
    virtual
    returns (address payable sellerOrOwner);

  /**
   * @notice This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   */
  uint256[500] private __gap;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.8;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

import "./NFTMarketSharedCore.sol";
import "./SendValueWithFallbackWithdraw.sol";
import "./Constants.sol";
import "./ExchangeArtTreasuryNode.sol";


/**
 * @title A mixin to distribute funds when an NFT is sold.
 * @author exhgArt
 */
abstract contract NFTMarketFees is ExchangeArtTreasuryNode,  NFTMarketSharedCore, SendValueWithFallbackWithdraw  { 
  using AddressUpgradeable for address;

  /// @notice The fee collected by Exchange Art for sales facilitated by this market contract.
  uint256 private immutable PROTOCOL_FEE_IN_BASIS_POINTS;

  /// @notice The address of this contract's implementation.
  /// @dev This is used when making stateless external calls to this contract,
  /// saving gas over hopping through the proxy which is only necessary when accessing state.
  NFTMarketFees private immutable implementationAddress;

  /**
   * @notice Configures the registry allowing for royalty overrides to be defined.
   * @param protocolFeeInBasisPoints The protocol fee in basis points.
   * False if primary & secondary are supported.
   */
  constructor(
    uint16 protocolFeeInBasisPoints
  ) {

    // todo: add royalties logic here
    // if (
    //   protocolFeeInBasisPoints < BASIS_POINTS / BUY_REFERRER_FEE_DENOMINATOR ||
    //   protocolFeeInBasisPoints + BASIS_POINTS / CREATOR_ROYALTY_DENOMINATOR >= BASIS_POINTS
    // ) {
    //   /* If the protocol fee is invalid, revert:
    //    * Protocol fee must be greater than the buy referrer fee since referrer fees are deducted from the protocol fee.
    //    * The protocol fee must leave room for the creator royalties.
    //    */
    //   revert NFTMarketFees_Invalid_Protocol_Fee();
    // }
    PROTOCOL_FEE_IN_BASIS_POINTS = protocolFeeInBasisPoints;

    // We don't use this anywehere yet
    // In the constructor, `this` refers to the implementation address. Everywhere else it'll be the proxy.
    implementationAddress = this;
  }

  /**
   * @notice Distributes funds to Exchange Art, creator recipients, and NFT owner after a sale.
   */
  function _distributeFunds(
    address nftContract,
    uint256 tokenId,
    address payable seller,
    uint256 price
  )
    internal
    returns (
      uint256 totalFees,
      uint256 creatorRev,
      uint256 sellerRev
    )
  {
    if (price == 0) {
      // When the sale price is 0, there are no revenue to distribute.
      return (0, 0, 0);
    }

    (totalFees, sellerRev) = _getFees(
      nftContract,
      tokenId,
      seller,
      price
    );

    // todo: calculate actual creator Revenue
    creatorRev = 0;

    // Pay the creator(s)
    // // If just a single recipient was defined, use a larger gas limit in order to support in-contract split logic.
    // uint256 creatorGasLimit = creatorRecipients.length == 1
    //   ? SEND_VALUE_GAS_LIMIT_MULTIPLE_RECIPIENTS
    //   : SEND_VALUE_GAS_LIMIT_SINGLE_RECIPIENT;
    // unchecked {
    //   for (uint256 i = 0; i < creatorRecipients.length; ++i) {
    //     _sendValueWithFallbackWithdraw(creatorRecipients[i], creatorShares[i], creatorGasLimit);
    //     // Sum the total creator rev from shares
    //     // creatorShares is in ETH so creatorRev will not overflow here.
    //     creatorRev += creatorShares[i];
    //   }
    // }

    // Pay the seller
    _sendValueWithFallbackWithdraw(seller, sellerRev, SEND_VALUE_GAS_LIMIT_SINGLE_RECIPIENT);

    // Pay the protocol fee
    _sendValueWithFallbackWithdraw(getExchangeArtTreasury(), totalFees, SEND_VALUE_GAS_LIMIT_SINGLE_RECIPIENT);

  }


  /**
   * @notice Calculates how funds should be distributed for the given sale details.
   * @dev When the NFT is being sold by the `tokenCreator`, all the seller revenue will
   * be split with the royalty recipients defined for that NFT.
   */
  // solhint-disable-next-line code-complexity
  function _getFees(
    address nftContract,
    uint256 tokenId,
    address payable seller,
    uint256 price
  )
    private
    view
    returns (
      uint256 totalFees,
      uint256 sellerRev
    )
  {
    // Calculate the protocol fee
    totalFees = (price * PROTOCOL_FEE_IN_BASIS_POINTS) / BASIS_POINTS;

    // Calculate the seller fee
    sellerRev = price - totalFees;

  }


}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.8;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";


error ExchangeArtTreasuryNode_Address_Is_Not_A_Contract();
// error FoundationTreasuryNode_Caller_Not_Admin();
// error FoundationTreasuryNode_Caller_Not_Operator();

/**
 * @title A mixin that stores a reference to the Exchange Art treasury contract.
 * @notice The treasury collects fees and defines admin/operator roles.
 * @author batu-inal & HardlyDifficult
 */
abstract contract ExchangeArtTreasuryNode {
  using AddressUpgradeable for address payable;

  /// @notice The address of the treasury contract.
  address payable private immutable treasury;

  // /// @notice Requires the caller is a ExchangeArt admin.
  // modifier onlyFoundationAdmin() {
  //   if (!IAdminRole(treasury).isAdmin(msg.sender)) {
  //     revert FoundationTreasuryNode_Caller_Not_Admin();
  //   }
  //   _;
  // }

  // /// @notice Requires the caller is a ExchangeArt operator.
  // modifier onlyFoundationOperator() {
  //   if (!IOperatorRole(treasury).isOperator(msg.sender)) {
  //     revert FoundationTreasuryNode_Caller_Not_Operator();
  //   }
  //   _;
  // }

  /**
   * @notice Set immutable variables for the implementation contract.
   * @dev Assigns the treasury contract address.
   */
  constructor(address payable _treasury) {
    // todo: uncomment this when deploying to mainnet
    // if (!_treasury.isContract()) {
    //   revert ExchangeArtTreasuryNode_Address_Is_Not_A_Contract();
    // }
    treasury = _treasury;
  }

  /**
   * @notice Gets the Foundation treasury contract.
   * @dev This call is used in the royalty registry contract.
   * @return treasuryAddress The address of the ExchangeArt treasury contract.
   */
  function getExchangeArtTreasury() public view returns (address payable treasuryAddress) {
    treasuryAddress = treasury;
  }

  /**
   * @notice This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   */
  uint256[2_000] private __gap;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.8;

/**
 * @dev 100% in basis points.
 */
uint256 constant BASIS_POINTS = 10_000;


// todo: Why do we need this?
/**
 * @dev The gas limit to send ETH to a single recipient, enough for a contract with a simple receiver.
 */
uint256 constant SEND_VALUE_GAS_LIMIT_SINGLE_RECIPIENT = 20_000;

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

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

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/utils/Initializable.sol)

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
 * ```solidity
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 *
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
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
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
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
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
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized != type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/IERC721.sol)

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function setApprovalForAll(address operator, bool approved) external;

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